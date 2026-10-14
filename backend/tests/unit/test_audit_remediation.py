from __future__ import annotations

import base64
import hashlib
import json
import uuid
from pathlib import Path
from unittest.mock import Mock, patch

import pytest
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
from flask import Flask
from flask.testing import FlaskClient
from sqlalchemy import select

from app.api.app import INTERNAL_ROLE_CODES
from app.errors import APIError
from app.extensions import db
from app.models.contracts import Contract, ContractTemplate
from app.models.files import FileAsset
from app.models.identity import NotificationPreference, Role, User, UserRole
from app.models.marketplace import City, Country, MarketplaceListing, UserProfile
from app.models.projects import Project, ProjectMember
from app.models.trust_safety import NotificationDelivery, PushDevice
from app.services.booking_terms import validate_payment_schedule
from app.services.file_processing import mark_file_scan_clean
from app.services.notifications import notify_user
from app.services.private_fields import decrypt_private_value, encrypt_private_value
from app.services.web_push import (
    deliver_web_push_batch,
    receipt_signer,
    validate_subscription,
)


@pytest.fixture(autouse=True)
def catalogue(app: Flask) -> None:
    with app.app_context():
        for code in {"actor_talent", "director_producer", *INTERNAL_ROLE_CODES}:
            db.session.add(Role(code=code, name=code, portal_route="/test"))
        country = Country(
            iso2="PK", name="Pakistan", currency_code="PKR", phone_prefix="+92"
        )
        db.session.add(country)
        db.session.flush()
        db.session.add(
            City(
                public_id="CITY-QA",
                country_id=country.id,
                name="QA City",
                timezone="Asia/Karachi",
            )
        )
        db.session.commit()


def register(client: FlaskClient, **fields):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"audit-{uuid.uuid4().hex}@example.com",
            "password": "StrongPass123!",
            "display_name": "Audit QA",
            "initial_role": "actor_talent",
            "terms_version": "2026-10",
            **fields,
        },
    )
    assert response.status_code == 201, response.text
    data = response.json["data"]
    return {"Authorization": "Bearer " + data["tokens"]["access_token"]}, data["user"]


def grant_admin(app, public_id):
    with app.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == public_id)
        ).scalar_one()
        role = db.session.execute(
            select(Role).where(Role.code == "super_admin")
        ).scalar_one()
        db.session.add(UserRole(user_id=user.id, role_id=role.id, status="active"))
        db.session.commit()


@pytest.mark.parametrize("code", sorted(INTERNAL_ROLE_CODES))
def test_internal_roles_cannot_be_self_granted(client, code):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "forbidden@example.com",
            "password": "StrongPass123!",
            "display_name": "Forbidden",
            "initial_role": code,
            "terms_version": "2026-10",
        },
    )
    assert response.status_code == 403
    headers, _ = register(client)
    assert (
        client.post(
            "/api/v1/me/roles", headers=headers, json={"role": code}
        ).status_code
        == 403
    )
    assert code not in {r["code"] for r in client.get("/api/v1/roles").json["data"]}


def test_registration_fields_persist_without_claiming_phone_verification(client, app):
    headers, user = register(
        client, phone="+923001234567", city_id="CITY-QA", referral_code="REF-QA"
    )
    assert user["phone"] == "+923001234567" and user["phone_verified"] is False
    with app.app_context():
        row = db.session.execute(
            select(User).where(User.public_id == user["public_id"])
        ).scalar_one()
        assert row.referral_code == "REF-QA" and row.phone_verified_at is None
        profile = db.session.execute(
            select(UserProfile).where(UserProfile.user_id == row.id)
        ).scalar_one()
        assert profile.city.public_id == "CITY-QA"
        row.roles[0].status = "suspended"
        db.session.commit()
    assert (
        client.post(
            "/api/v1/me/roles", headers=headers, json={"role": "actor_talent"}
        ).status_code
        == 403
    )


def test_runtime_settings_require_admin_and_round_trip(client, app):
    headers, user = register(client)
    value = {
        "maintenance": {
            "enabled": True,
            "message": "QA maintenance",
            "return_at": "2026-11-01T18:00:00+05:00",
        }
    }
    assert (
        client.patch(
            "/api/v1/admin/app-settings", headers=headers, json=value
        ).status_code
        == 403
    )
    grant_admin(app, user["public_id"])
    assert (
        client.patch(
            "/api/v1/admin/app-settings", headers=headers, json=value
        ).status_code
        == 200
    )
    assert (
        client.get("/api/v1/app/bootstrap").json["data"]["maintenance"]
        == value["maintenance"]
    )
    for invalid in [
        {"force_update": {"required": True}},
        {"maintenance": {"enabled": True, "message": True}},
        {"maintenance": {"enabled": True, "return_at": "soon"}},
    ]:
        assert (
            client.patch(
                "/api/v1/admin/app-settings", headers=headers, json=invalid
            ).status_code
            == 422
        )


def test_production_payout_rejects_sandbox_and_retains_bank_metadata(client, app):
    headers, _ = register(client)
    app.config["APP_ENV"] = "production"
    payload = {
        "provider": "sandbox",
        "account_name": "QA User",
        "account_token": "PK123456",
    }
    assert (
        client.post(
            "/api/v1/payout-accounts", headers=headers, json=payload
        ).status_code
        == 422
    )
    payload.update(
        provider="bank",
        bank_name="QA Bank",
        receiving_name="QA User",
        ownership_confirmed=True,
    )
    response = client.post("/api/v1/payout-accounts", headers=headers, json=payload)
    assert response.status_code == 201, response.text
    account = response.json["data"]["account"]
    assert (
        account["status"] == "pending" and account["details"]["bank_name"] == "QA Bank"
    )
    assert "PK123456" not in response.text
    assert (
        client.get("/api/v1/app/public-config").json["data"]["support"]["payments"][
            "mode"
        ]
        == "sandbox"
    )
    app.config["PAYMENT_MODE"] = "manual_bank_transfer"
    assert "Demo" not in client.get("/api/v1/app/public-config").text


def make_file(app, user, data=b"QA document", scan="pending", public=False):
    root = Path(
        app.config[
            "LOCAL_STORAGE_PUBLIC_ROOT" if public else "LOCAL_STORAGE_PRIVATE_ROOT"
        ]
    )
    key = f"qa/{uuid.uuid4().hex}.txt"
    (root / key).parent.mkdir(parents=True, exist_ok=True)
    (root / key).write_bytes(data)
    row = FileAsset(
        owner_user_id=user.id,
        storage_key=key,
        bucket="public" if public else "private",
        mime_type="text/plain",
        size_bytes=len(data),
        checksum_sha256=hashlib.sha256(data).hexdigest(),
        visibility="public" if public else "private",
        scan_status=scan,
        processing_status="ready" if scan == "clean" else "pending",
        original_name="qa.txt",
    )
    db.session.add(row)
    db.session.flush()
    return row


@pytest.mark.parametrize("verdict", [True, False])
def test_file_scan_uses_real_verdict_and_public_media_gate(client, app, verdict):
    _, user_data = register(client)
    with app.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_data["public_id"])
        ).scalar_one()
        row = make_file(app, user, public=True)
        public_id, key = row.public_id, row.storage_key
        db.session.commit()
    assert client.get("/api/v1/media/" + key).status_code == 404
    with (
        app.app_context(),
        patch(
            "app.services.file_processing.scan_file", return_value=verdict
        ) as scanner,
    ):
        result = mark_file_scan_clean(public_id)
        scanner.assert_called_once()
    assert result["scan_status"] == ("clean" if verdict else "infected")
    assert client.get("/api/v1/media/" + key).status_code == (200 if verdict else 404)


def test_scanner_failure_does_not_mark_clean_and_integrity_failure_is_rejected(
    client, app
):
    _, data = register(client)
    with app.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == data["public_id"])
        ).scalar_one()
        row = make_file(app, user)
        db.session.commit()
        with (
            patch("app.services.file_processing.scan_file", side_effect=OSError()),
            pytest.raises(RuntimeError),
        ):
            mark_file_scan_clean(row.public_id)
        assert row.scan_status == "pending"
        row.size_bytes += 1
        db.session.commit()
        assert mark_file_scan_clean(row.public_id)["scan_status"] == "integrity_failed"


def test_kyc_requires_scanned_documents_and_encrypts_metadata(client, app):
    headers, data = register(client)
    with app.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == data["public_id"])
        ).scalar_one()
        row = make_file(app, user)
        file_id = row.public_id
        db.session.commit()
    documents = [
        {"document_type": kind, "file_id": file_id}
        for kind in ["national_id_front", "national_id_back", "selfie_liveness"]
    ]
    documents[0].update(document_number="QA-IDENTITY", expires_on="2030-01-01")
    response = client.post(
        "/api/v1/kyc/submissions",
        headers=headers,
        json={"role": "actor_talent", "documents": documents},
    )
    assert response.status_code == 201, response.text
    submission = response.json["data"]["submission"]
    assert "QA-IDENTITY" not in response.text
    path = f"/api/v1/kyc/submissions/{submission['public_id']}/submit"
    assert client.post(path, headers=headers).status_code == 422
    with app.app_context():
        row = db.session.execute(
            select(FileAsset).where(FileAsset.public_id == file_id)
        ).scalar_one()
        row.scan_status = "clean"
        row.processing_status = "ready"
        db.session.commit()
    assert client.post(path, headers=headers).status_code == 200
    assert client.post(path, headers=headers).status_code == 200


@pytest.mark.parametrize(
    "schedule",
    [
        [{"name": "Deposit", "percent": 90}],
        [{"name": "Bad", "percent": "NaN"}],
        [{"name": "Bad", "percent": -1}],
    ],
)
def test_invalid_payment_portions_are_rejected(schedule):
    with pytest.raises(APIError):
        validate_payment_schedule(schedule)


def test_booking_draft_terms_counter_contract_qr_and_milestones(client, app):
    requester, ru = register(client, initial_role="director_producer")
    provider, pu = register(client)
    with app.app_context():
        r = db.session.execute(
            select(User).where(User.public_id == ru["public_id"])
        ).scalar_one()
        p = db.session.execute(
            select(User).where(User.public_id == pu["public_id"])
        ).scalar_one()
        project = Project(owner_user_id=r.id, title="QA Project", project_type="tvc")
        listing = MarketplaceListing(
            owner_user_id=p.id,
            listing_type="talent",
            profile_entity_id="TAL-QA",
            verification_status="verified",
            title="QA Talent",
            summary="QA",
            visibility="public",
            moderation_status="approved",
            pricing_mode="negotiable",
        )
        db.session.add_all([project, listing])
        db.session.flush()
        db.session.add(
            ProjectMember(
                project_id=project.id, user_id=r.id, role_label="Owner", status="active"
            )
        )
        project_id, listing_id = project.public_id, listing.public_id
        db.session.commit()
    terms = {
        "deliverables": "One scene",
        "usage_rights": "PK TV for one year",
        "conditions": "Eight hour day",
        "category_fields": {"Wardrobe": "Client supplied"},
        "payment_schedule": [
            {"name": "Deposit", "percent": 25},
            {"name": "Final", "percent": 75},
        ],
    }
    payload = {
        "project_id": project_id,
        "listing_id": listing_id,
        "start_at": "2027-01-01T09:00:00Z",
        "end_at": "2027-01-01T17:00:00Z",
        "fee_minor": 10001,
        "terms": terms,
    }
    response = client.post("/api/v1/bookings", headers=requester, json=payload)
    assert response.status_code == 201, response.text
    booking_id = response.json["data"]["booking"]["public_id"]
    path = "/api/v1/bookings/" + booking_id
    assert client.get(path, headers=provider).status_code == 404
    assert (
        client.patch(
            path, headers=requester, json={"fee_minor": 10003, "terms": terms}
        ).status_code
        == 200
    )
    assert client.get(path, headers=requester).json["data"]["booking"]["terms"] == terms
    sent = client.post(path + "/send", headers=requester, json={})
    assert sent.status_code == 200, sent.text
    offer = sent.json["data"]["booking"]["offers"][0]
    assert offer["payment_schedule"] == terms["payment_schedule"]
    counter_schedule = [
        {"name": "Deposit", "percent": 50},
        {"name": "Final", "percent": 50},
    ]
    counter = client.post(
        path + "/offers",
        headers=provider,
        json={
            "fee_minor": 13003,
            "conditions": "Ten hour day",
            "payment_schedule": counter_schedule,
        },
    )
    assert counter.status_code == 201, counter.text
    offer_id = counter.json["data"]["offer"]["public_id"]
    accepted = client.post(
        "/api/v1/offers/" + offer_id + "/accept", headers=requester, json={}
    )
    assert accepted.status_code == 200, accepted.text
    with app.app_context():
        db.session.add(
            ContractTemplate(
                public_id="TPL-QA",
                name="QA",
                category="talent",
                body_schema_json="{}",
                status="published",
            )
        )
        db.session.commit()
    created_contract = client.post(path + "/contracts", headers=requester, json={})
    assert created_contract.status_code == 201, created_contract.text
    contract_id = created_contract.json["data"]["contract"]["public_id"]
    with app.app_context():
        contract = db.session.execute(
            select(Contract).where(Contract.public_id == contract_id)
        ).scalar_one()
        snapshot = json.loads(contract.content_snapshot_json)
        assert snapshot["booking_terms"]["payment_schedule"] == counter_schedule
        assert snapshot["booking_terms"]["deliverables"] == "One scene"
        assert any(c.clause_key == "agreed_usage_rights" for c in contract.clauses)
        from app.services.payments import ensure_payment_schedule_for_contract

        schedule = ensure_payment_schedule_for_contract(contract)
        db.session.commit()
        assert [m.amount_minor for m in schedule.milestones] == [6501, 6502]
    verification = client.get(
        f"/api/v1/contracts/{contract_id}/verification", headers=requester
    )
    assert verification.status_code == 200, verification.text
    verified = verification.json["data"]
    assert base64.b64decode(verified["qr_png_base64"]).startswith(b"\x89PNG")
    token = verified["url"].split("/verify/")[1]
    assert (
        client.get(
            "/api/v1/contracts/verify/" + token, headers={"Accept": "application/json"}
        ).json["data"]["record_verified"]
        is True
    )
    assert client.get("/api/v1/contracts/verify/" + token + "bad").status_code == 403


def subscription():
    public = (
        ec.generate_private_key(ec.SECP256R1())
        .public_key()
        .public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)
    )

    def enc(data):
        return base64.urlsafe_b64encode(data).decode().rstrip("=")

    return {
        "endpoint": "https://fcm.googleapis.com/fcm/send/QA",
        "keys": {"p256dh": enc(public), "auth": enc(b"a" * 16)},
    }


def test_push_queue_provider_acceptance_receipt_and_opt_out(client, app, tmp_path):
    headers, data = register(client)
    key = tmp_path / "vapid.pem"
    key.write_text("mocked transport key")
    app.config.update(VAPID_PUBLIC_KEY="test", VAPID_PRIVATE_KEY_FILE=str(key))
    response = client.post(
        "/api/v1/push-devices",
        headers=headers,
        json={
            "device_id": "web-qa",
            "platform": "web",
            "subscription": subscription(),
            "enabled": True,
        },
    )
    assert response.status_code == 201, response.text
    with app.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == data["public_id"])
        ).scalar_one()
        device = db.session.execute(select(PushDevice)).scalar_one()
        assert "fcm.googleapis.com" not in device.subscription_encrypted
        notify_user(user.id, category="qa", title="QA", body="QA")
        db.session.commit()
        delivery = db.session.execute(
            select(NotificationDelivery).where(NotificationDelivery.channel == "push")
        ).scalar_one()
        assert delivery.status == "queued" and delivery.sent_at is None
        with patch("app.services.web_push.webpush", return_value=Mock(status_code=201)):
            assert deliver_web_push_batch() == {"sent": 1, "failed": 0}
        assert delivery.status == "sent"
        token = receipt_signer().dumps({"delivery_id": str(delivery.id)})
    assert client.post("/api/v1/push/receipts/" + token).status_code == 200
    assert client.post("/api/v1/push/receipts/" + token + "bad").status_code == 403
    with app.app_context():
        assert (
            db.session.get(NotificationDelivery, uuid.UUID(str(delivery.id))).status
            == "delivered"
        )
        pref = db.session.execute(select(NotificationPreference)).scalar_one()
        pref.push_enabled = False
        notify_user(pref.user_id, category="qa", title="Disabled", body="QA")
        db.session.commit()
        assert (
            len(
                db.session.execute(
                    select(NotificationDelivery).where(
                        NotificationDelivery.channel == "push"
                    )
                )
                .scalars()
                .all()
            )
            == 1
        )


def test_untrusted_push_endpoint_rejected():
    value = subscription()
    value["endpoint"] = "https://127.0.0.1/private"
    with pytest.raises(APIError):
        validate_subscription(value)


def test_private_fields_survive_key_rotation(app):
    with app.app_context():
        old_key = app.config["SECRET_KEY"]
        encrypted = encrypt_private_value("private QA")
        app.config.update(
            SECRET_KEY="new-secret",
            FIELD_ENCRYPTION_KEY="new-field",
            LEGACY_FIELD_ENCRYPTION_KEYS=old_key,
        )
        assert decrypt_private_value(encrypted) == "private QA"
        assert decrypt_private_value(encrypt_private_value("new QA")) == "new QA"


def test_travel_preferences_persist_and_validate_city(client):
    headers, _ = register(client)
    value = {"willing_to_travel": True, "radius_km": 250, "city_ids": ["CITY-QA"]}
    response = client.patch(
        "/api/v1/talent/travel-preferences", headers=headers, json=value
    )
    assert response.status_code == 200, response.text
    assert (
        client.get("/api/v1/talent/travel-preferences", headers=headers).json["data"]
        == response.json["data"]
    )
    assert (
        client.patch(
            "/api/v1/talent/travel-preferences",
            headers=headers,
            json={**value, "city_ids": ["CITY-MISSING"]},
        ).status_code
        == 422
    )


def test_browser_subscription_moves_to_new_account_without_leaking_old_push(
    client, app, tmp_path
):
    key = tmp_path / "vapid.pem"
    key.write_text("mocked transport key")
    app.config.update(VAPID_PUBLIC_KEY="test", VAPID_PRIVATE_KEY_FILE=str(key))
    first, _ = register(client)
    second, _ = register(client)
    payload = {
        "device_id": "web-shared",
        "platform": "web",
        "subscription": subscription(),
        "enabled": True,
    }
    for headers in [first, second]:
        assert (
            client.post(
                "/api/v1/push-devices", headers=headers, json=payload
            ).status_code
            == 201
        )
    with app.app_context():
        devices = db.session.execute(select(PushDevice)).scalars().all()
        assert len(devices) == 2
        assert sum(d.enabled for d in devices) == 1


def test_distribution_csv_contains_only_owned_reports_and_escapes_formulas(client, app):
    from datetime import date

    from app.models.specialist import (
        DistributionPartnerProfile,
        DistributionProject,
        DistributionReport,
    )

    first, first_user = register(client)
    second, second_user = register(client)
    with app.app_context():
        for user_data, territory in [
            (first_user, "=QA_FORMULA"),
            (second_user, "OTHER-PRIVATE"),
        ]:
            user = db.session.execute(
                select(User).where(User.public_id == user_data["public_id"])
            ).scalar_one()
            partner = DistributionPartnerProfile(user_id=user.id, name="QA Distributor")
            project = Project(
                owner_user_id=user.id, title="QA Release", project_type="film"
            )
            db.session.add_all([partner, project])
            db.session.flush()
            release = DistributionProject(
                project_id=project.id, partner_profile_id=partner.id
            )
            db.session.add(release)
            db.session.flush()
            db.session.add(
                DistributionReport(
                    distribution_project_id=release.id,
                    partner_profile_id=partner.id,
                    territory=territory,
                    channel="QA",
                    period_start=date(2026, 10, 1),
                    period_end=date(2026, 10, 2),
                    revenue_minor=12345,
                )
            )
        db.session.commit()
    path = "/api/v1/distribution-reports/export.csv"
    assert client.get(path).status_code == 401
    response = client.get(path, headers=first)
    assert response.status_code == 200, response.text
    assert "'=QA_FORMULA" in response.text and "12345" in response.text
    assert "OTHER-PRIVATE" not in response.text
    assert "OTHER-PRIVATE" in client.get(path, headers=second).text
