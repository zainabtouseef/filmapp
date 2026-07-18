from __future__ import annotations

import os
import uuid

import pytest
from flask.testing import FlaskClient
from sqlalchemy import select

from app.extensions import db
from app.models.identity import Role, User, UserRole
from app.models.kyc import KycSubmission

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        os.getenv("RUN_INTEGRATION_TESTS") != "1",
        reason="Set RUN_INTEGRATION_TESTS=1 with MySQL and Redis running.",
    ),
]


def _register_role(
    client: FlaskClient, role: str, *, name: str
) -> tuple[dict[str, str], str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"payment-{uuid.uuid4().hex[:12]}@example.com",
            "password": "StrongPass123!",
            "display_name": name,
            "initial_role": role,
            "terms_version": "2026-07",
        },
    )
    assert response.status_code == 201, response.text
    token = response.json["data"]["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}, response.json["data"]["user"][
        "public_id"
    ]


def _approve_actor_kyc(client: FlaskClient, user_public_id: str) -> None:
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        role = db.session.execute(
            select(Role).where(Role.code == "actor_talent")
        ).scalar_one()
        db.session.add(
            KycSubmission(
                user_id=user.id,
                role_id=role.id,
                status="approved",
                risk_level="low",
            )
        )
        db.session.commit()


def _grant_finance_admin(client: FlaskClient, user_public_id: str) -> None:
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        role = db.session.execute(
            select(Role).where(Role.code == "finance_admin")
        ).scalar_one()
        db.session.add(
            UserRole(
                user_id=user.id,
                role_id=role.id,
                status="active",
                is_primary=False,
            )
        )
        db.session.commit()


def _publish_actor_listing(client: FlaskClient) -> tuple[dict[str, str], str]:
    actor_headers, actor_user_id = _register_role(
        client, "actor_talent", name="Payment Actor"
    )
    _approve_actor_kyc(client, actor_user_id)
    cities = client.get("/api/v1/cities")
    lahore = next(
        city
        for city in cities.json["data"]["cities"]
        if city["public_id"] == "CITY-LHE"
    )
    profile = client.patch(
        "/api/v1/talent/profile",
        headers=actor_headers,
        json={
            "screen_name": "Payment Actor",
            "day_rate_minor": 18000000,
            "currency": "PKR",
        },
    )
    assert profile.status_code == 200, profile.text
    listing = client.post(
        "/api/v1/marketplace/listings",
        headers=actor_headers,
        json={
            "listing_type": "talent",
            "title": "Payment Actor — Talent",
            "summary": "Experienced actor available for payment tests.",
            "city_id": lahore["public_id"],
        },
    )
    assert listing.status_code == 201, listing.text
    return actor_headers, listing.json["data"]["listing"]["public_id"]


def _signed_contract(
    client: FlaskClient,
) -> tuple[dict[str, str], dict[str, str], str, str]:
    producer_headers, _producer_user_id = _register_role(
        client, "director_producer", name="Payment Producer"
    )
    actor_headers, listing_id = _publish_actor_listing(client)
    project = client.post(
        "/api/v1/projects",
        headers=producer_headers,
        json={"title": "Payment Flow TVC", "project_type": "tvc"},
    )
    assert project.status_code == 201, project.text
    project_id = project.json["data"]["project"]["public_id"]
    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=producer_headers,
        json={
            "category": "talent",
            "title": "Lead talent",
            "budget_min_minor": 15000000,
            "budget_max_minor": 20000000,
        },
    )
    assert requirement.status_code == 201, requirement.text
    booking = client.post(
        "/api/v1/bookings",
        headers=producer_headers,
        json={
            "project_id": project_id,
            "requirement_id": requirement.json["data"]["requirement"]["public_id"],
            "listing_id": listing_id,
            "category": "talent",
            "fee_minor": 17000000,
            "currency": "PKR",
            "start_at": "2026-07-28T02:30:00Z",
            "end_at": "2026-07-28T14:30:00Z",
        },
    )
    assert booking.status_code == 201, booking.text
    booking_id = booking.json["data"]["booking"]["public_id"]
    sent = client.post(
        f"/api/v1/bookings/{booking_id}/send",
        headers=producer_headers,
        json={"fee_minor": 18000000, "message": "Payment flow offer."},
    )
    assert sent.status_code == 200, sent.text
    offer_id = sent.json["data"]["booking"]["offers"][0]["public_id"]
    accepted = client.post(
        f"/api/v1/offers/{offer_id}/accept",
        headers=actor_headers,
        json={},
    )
    assert accepted.status_code == 200, accepted.text
    contract = client.post(
        f"/api/v1/bookings/{booking_id}/contracts",
        headers=producer_headers,
        json={},
    )
    assert contract.status_code == 201, contract.text
    contract_id = contract.json["data"]["contract"]["public_id"]
    producer_signature = client.post(
        f"/api/v1/contracts/{contract_id}/signatures",
        headers=producer_headers,
        json={},
    )
    assert producer_signature.status_code == 200, producer_signature.text
    actor_signature = client.post(
        f"/api/v1/contracts/{contract_id}/signatures",
        headers=actor_headers,
        json={},
    )
    assert actor_signature.status_code == 200, actor_signature.text
    assert actor_signature.json["data"]["contract"]["status"] == "signed"
    return producer_headers, actor_headers, booking_id, contract_id


def test_payment_proof_review_ledger_receipt_and_payout_account_flow(
    client: FlaskClient,
) -> None:
    producer_headers, actor_headers, booking_id, contract_id = _signed_contract(client)

    schedules = client.get("/api/v1/payment-schedules", headers=producer_headers)
    assert schedules.status_code == 200
    schedule = next(
        row
        for row in schedules.json["data"]["schedules"]
        if row["contract_id"] == contract_id
    )
    assert schedule["total_minor"] == 18000000
    milestone_id = schedule["milestones"][0]["public_id"]

    idempotency_key = f"payment-{uuid.uuid4().hex}"
    proof = client.post(
        "/api/v1/payment-proofs",
        headers=producer_headers,
        json={
            "milestone_id": milestone_id,
            "method": "bank_transfer",
            "claimed_amount_minor": 18000000,
            "transaction_reference": "SANDBOX-BANK-001",
            "idempotency_key": idempotency_key,
        },
    )
    assert proof.status_code == 201, proof.text
    proof_id = proof.json["data"]["proof"]["public_id"]
    duplicate = client.post(
        "/api/v1/payment-proofs",
        headers=producer_headers,
        json={
            "milestone_id": milestone_id,
            "method": "bank_transfer",
            "claimed_amount_minor": 18000000,
            "transaction_reference": "SANDBOX-BANK-001",
            "idempotency_key": idempotency_key,
        },
    )
    assert duplicate.status_code == 200
    assert duplicate.json["data"]["proof"]["public_id"] == proof_id

    finance_headers, finance_user_id = _register_role(
        client, "director_producer", name="Payment Finance"
    )
    _grant_finance_admin(client, finance_user_id)
    queue = client.get("/api/v1/admin/payment-proofs", headers=finance_headers)
    assert queue.status_code == 200
    assert any(row["public_id"] == proof_id for row in queue.json["data"]["proofs"])

    decision = client.post(
        f"/api/v1/admin/payment-proofs/{proof_id}/decision",
        headers=finance_headers,
        json={"decision": "approved", "reason": "Sandbox reference matched."},
    )
    assert decision.status_code == 200, decision.text
    assert decision.json["data"]["proof"]["status"] == "verified"
    receipt = decision.json["data"]["receipt"]
    assert receipt["amount_minor"] == 18000000

    booking = client.get(f"/api/v1/bookings/{booking_id}", headers=producer_headers)
    assert booking.status_code == 200
    assert booking.json["data"]["booking"]["status"] == "secured"

    producer_ledger = client.get("/api/v1/ledger", headers=producer_headers)
    assert producer_ledger.status_code == 200
    assert any(
        row["status"] == "posted" and row["direction"] == "debit"
        for row in producer_ledger.json["data"]["entries"]
    )

    actor_dashboard = client.get("/api/v1/payments/dashboard", headers=actor_headers)
    assert actor_dashboard.status_code == 200
    assert actor_dashboard.json["data"]["totals"]["pending_release_minor"] == 18000000

    receipt_detail = client.get(
        f"/api/v1/receipts/{receipt['public_id']}", headers=producer_headers
    )
    assert receipt_detail.status_code == 200

    payout_account = client.post(
        "/api/v1/payout-accounts",
        headers=actor_headers,
        json={
            "provider": "sandbox",
            "account_name": "Payment Actor",
            "account_masked": "****8842",
            "account_token": "sandbox-payout-token",
        },
    )
    assert payout_account.status_code == 201, payout_account.text
    assert payout_account.json["data"]["account"]["status"] == "verified"
