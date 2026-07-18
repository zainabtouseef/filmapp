from __future__ import annotations

import csv
import io
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
            "email": f"analytics-{uuid.uuid4().hex[:12]}@example.com",
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


def _grant_role(client: FlaskClient, user_public_id: str, role_code: str) -> None:
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        role = db.session.execute(
            select(Role).where(Role.code == role_code)
        ).scalar_one()
        db.session.add(
            UserRole(
                user_id=user.id, role_id=role.id, status="active", is_primary=False
            )
        )
        db.session.commit()


def _register_admin(
    client: FlaskClient, role_code: str, *, name: str
) -> tuple[dict[str, str], str]:
    headers, user_id = _register_role(client, "director_producer", name=name)
    _grant_role(client, user_id, role_code)
    return headers, user_id


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


def _accepted_and_secured_booking(
    client: FlaskClient,
) -> tuple[dict[str, str], str, dict[str, str], str, str]:
    producer_headers, producer_user_id = _register_role(
        client, "director_producer", name="Analytics Flow Producer"
    )
    actor_headers, actor_user_id = _register_role(
        client, "actor_talent", name="Analytics Flow Actor"
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
        json={"screen_name": "Analytics Flow Actor", "day_rate_minor": 15000000},
    )
    assert profile.status_code == 200, profile.text
    listing = client.post(
        "/api/v1/marketplace/listings",
        headers=actor_headers,
        json={
            "listing_type": "talent",
            "title": "Analytics Flow Actor — Talent",
            "summary": "Talent available for analytics flow tests.",
            "city_id": lahore["public_id"],
        },
    )
    assert listing.status_code == 201, listing.text
    listing_id = listing.json["data"]["listing"]["public_id"]
    project = client.post(
        "/api/v1/projects",
        headers=producer_headers,
        json={"title": "Analytics Flow TVC", "project_type": "tvc"},
    )
    assert project.status_code == 201, project.text
    project_id = project.json["data"]["project"]["public_id"]
    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=producer_headers,
        json={"category": "talent", "title": "Lead talent"},
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
            "fee_minor": 15000000,
            "currency": "PKR",
            "start_at": "2026-08-01T02:30:00Z",
            "end_at": "2026-08-01T14:30:00Z",
        },
    )
    assert booking.status_code == 201, booking.text
    booking_id = booking.json["data"]["booking"]["public_id"]
    sent = client.post(
        f"/api/v1/bookings/{booking_id}/send",
        headers=producer_headers,
        json={"fee_minor": 15000000, "message": "Analytics flow offer."},
    )
    assert sent.status_code == 200, sent.text
    offer_id = sent.json["data"]["booking"]["offers"][0]["public_id"]
    accepted = client.post(
        f"/api/v1/offers/{offer_id}/accept", headers=actor_headers, json={}
    )
    assert accepted.status_code == 200, accepted.text

    contract = client.post(
        f"/api/v1/bookings/{booking_id}/contracts", headers=producer_headers, json={}
    )
    assert contract.status_code == 201, contract.text
    contract_id = contract.json["data"]["contract"]["public_id"]
    client.post(
        f"/api/v1/contracts/{contract_id}/signatures",
        headers=producer_headers,
        json={},
    )
    client.post(
        f"/api/v1/contracts/{contract_id}/signatures", headers=actor_headers, json={}
    )

    schedules = client.get("/api/v1/payment-schedules", headers=producer_headers)
    schedule = next(
        row
        for row in schedules.json["data"]["schedules"]
        if row["contract_id"] == contract_id
    )
    milestone_id = schedule["milestones"][0]["public_id"]

    proof = client.post(
        "/api/v1/payment-proofs",
        headers=producer_headers,
        json={
            "milestone_id": milestone_id,
            "method": "bank_transfer",
            "claimed_amount_minor": schedule["total_minor"],
            "transaction_reference": "SANDBOX-BANK-002",
            "idempotency_key": uuid.uuid4().hex,
        },
    )
    assert proof.status_code == 201, proof.text
    proof_id = proof.json["data"]["proof"]["public_id"]

    finance_headers, _finance_id = _register_admin(
        client, "finance_admin", name="Analytics Flow Finance"
    )
    decision = client.post(
        f"/api/v1/admin/payment-proofs/{proof_id}/decision",
        headers=finance_headers,
        json={"decision": "approved"},
    )
    assert decision.status_code == 200, decision.text

    return producer_headers, producer_user_id, actor_headers, actor_user_id, booking_id


def test_personal_and_admin_dashboards(client: FlaskClient) -> None:
    producer_headers, _producer_id, actor_headers, _actor_id, booking_id = (
        _accepted_and_secured_booking(client)
    )

    my_dashboard = client.get("/api/v1/me/dashboard", headers=producer_headers)
    assert my_dashboard.status_code == 200, my_dashboard.text
    data = my_dashboard.json["data"]
    assert data["secured_value_minor"] == 15000000
    assert data["pending_offers"] == 0

    review = client.post(
        "/api/v1/reviews",
        headers=producer_headers,
        json={"booking_id": booking_id, "rating": 5},
    )
    assert review.status_code == 201, review.text

    actor_dashboard = client.get("/api/v1/me/dashboard", headers=actor_headers)
    assert actor_dashboard.status_code == 200, actor_dashboard.text
    assert actor_dashboard.json["data"]["rating_average"] == 5.0
    assert actor_dashboard.json["data"]["review_count"] == 1

    non_admin_attempt = client.get("/api/v1/admin/dashboard", headers=producer_headers)
    assert non_admin_attempt.status_code == 403, non_admin_attempt.text

    reviewer_headers, _reviewer_id = _register_admin(
        client, "reviewer", name="Analytics Flow Reviewer"
    )
    admin_dashboard = client.get("/api/v1/admin/dashboard", headers=reviewer_headers)
    assert admin_dashboard.status_code == 200, admin_dashboard.text
    admin_data = admin_dashboard.json["data"]
    assert admin_data["secured_bookings"] >= 1
    assert admin_data["total_users"] >= 3
    assert "calculated_platform_fees_minor" in admin_data

    analytics = client.get("/api/v1/admin/analytics?days=7", headers=reviewer_headers)
    assert analytics.status_code == 200, analytics.text
    assert analytics.json["data"]["range_days"] == 7
    assert isinstance(analytics.json["data"]["new_bookings_by_day"], dict)


def test_export_jobs_flow(client: FlaskClient) -> None:
    producer_headers, _producer_id, actor_headers, _actor_id, booking_id = (
        _accepted_and_secured_booking(client)
    )

    unsupported = client.post(
        "/api/v1/exports",
        headers=producer_headers,
        json={"export_type": "not-a-real-type"},
    )
    assert unsupported.status_code == 422, unsupported.text

    ledger_export = client.post(
        "/api/v1/exports",
        headers=producer_headers,
        json={"export_type": "ledger"},
    )
    assert ledger_export.status_code == 201, ledger_export.text
    ledger_data = ledger_export.json["data"]["export"]
    assert ledger_data["status"] == "completed"
    assert ledger_data["row_count"] >= 1
    reader = csv.reader(io.StringIO(ledger_data["csv_content"]))
    rows = list(reader)
    assert rows[0] == [
        "public_id",
        "entry_type",
        "direction",
        "amount_minor",
        "currency",
        "status",
        "occurred_at",
    ]
    assert len(rows) - 1 == ledger_data["row_count"]

    bookings_export = client.post(
        "/api/v1/exports",
        headers=actor_headers,
        json={"export_type": "bookings"},
    )
    assert bookings_export.status_code == 201, bookings_export.text
    assert bookings_export.json["data"]["export"]["row_count"] >= 1

    forbidden = client.post(
        "/api/v1/exports",
        headers=actor_headers,
        json={"export_type": "admin_disputes"},
    )
    assert forbidden.status_code == 403, forbidden.text

    reviewer_headers, _reviewer_id = _register_admin(
        client, "reviewer", name="Export Flow Reviewer"
    )
    dispute = client.post(
        "/api/v1/disputes",
        headers=producer_headers,
        json={
            "booking_id": booking_id,
            "type": "damage",
            "description": "Equipment returned damaged.",
        },
    )
    assert dispute.status_code == 201, dispute.text

    admin_export = client.post(
        "/api/v1/exports",
        headers=reviewer_headers,
        json={"export_type": "admin_disputes"},
    )
    assert admin_export.status_code == 201, admin_export.text
    assert admin_export.json["data"]["export"]["row_count"] >= 1

    export_list = client.get("/api/v1/exports", headers=producer_headers)
    assert export_list.status_code == 200, export_list.text
    assert len(export_list.json["data"]["exports"]) == 1
    assert export_list.json["data"]["exports"][0]["csv_content"] is None

    export_id = ledger_data["public_id"]
    export_detail = client.get(f"/api/v1/exports/{export_id}", headers=producer_headers)
    assert export_detail.status_code == 200, export_detail.text
    assert export_detail.json["data"]["export"]["csv_content"] is not None

    other_user_headers, _other_id = _register_role(
        client, "director_producer", name="Other Export Viewer"
    )
    denied = client.get(f"/api/v1/exports/{export_id}", headers=other_user_headers)
    assert denied.status_code == 404, denied.text
