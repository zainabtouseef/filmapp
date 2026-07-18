from __future__ import annotations

import os
import uuid

import pytest
from flask.testing import FlaskClient
from sqlalchemy import select

from app.extensions import db
from app.models.identity import Role, User
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
            "email": f"contract-{uuid.uuid4().hex[:12]}@example.com",
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


def _publish_actor_listing(client: FlaskClient) -> tuple[dict[str, str], str]:
    actor_headers, actor_user_id = _register_role(
        client, "actor_talent", name="Contract Actor"
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
            "screen_name": "Contract Actor",
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
            "title": "Contract Actor — Talent",
            "summary": "Experienced actor available for contract tests.",
            "city_id": lahore["public_id"],
        },
    )
    assert listing.status_code == 201, listing.text
    return actor_headers, listing.json["data"]["listing"]["public_id"]


def _create_project_and_requirement(
    client: FlaskClient, headers: dict[str, str]
) -> tuple[str, str]:
    project = client.post(
        "/api/v1/projects",
        headers=headers,
        json={"title": "Contract Flow TVC", "project_type": "tvc"},
    )
    assert project.status_code == 201, project.text
    project_id = project.json["data"]["project"]["public_id"]
    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=headers,
        json={
            "category": "talent",
            "title": "Lead talent",
            "budget_min_minor": 15000000,
            "budget_max_minor": 20000000,
        },
    )
    assert requirement.status_code == 201, requirement.text
    return project_id, requirement.json["data"]["requirement"]["public_id"]


def _accepted_booking(
    client: FlaskClient,
) -> tuple[dict[str, str], dict[str, str], str]:
    producer_headers, _producer_user_id = _register_role(
        client, "director_producer", name="Contract Producer"
    )
    actor_headers, listing_id = _publish_actor_listing(client)
    project_id, requirement_id = _create_project_and_requirement(
        client, producer_headers
    )
    created = client.post(
        "/api/v1/bookings",
        headers=producer_headers,
        json={
            "project_id": project_id,
            "requirement_id": requirement_id,
            "listing_id": listing_id,
            "category": "talent",
            "fee_minor": 17000000,
            "currency": "PKR",
            "start_at": "2026-07-24T02:30:00Z",
            "end_at": "2026-07-24T14:30:00Z",
        },
    )
    assert created.status_code == 201, created.text
    booking_id = created.json["data"]["booking"]["public_id"]
    sent = client.post(
        f"/api/v1/bookings/{booking_id}/send",
        headers=producer_headers,
        json={
            "fee_minor": 17000000,
            "conditions": "Wardrobe included.",
            "message": "Initial offer for contract test.",
        },
    )
    assert sent.status_code == 200, sent.text
    counter = client.post(
        f"/api/v1/bookings/{booking_id}/offers",
        headers=actor_headers,
        json={
            "fee_minor": 18000000,
            "currency": "PKR",
            "conditions": "PKR 180k with a 10-hour day.",
            "message": "Can do 180k with a 10-hour day.",
        },
    )
    assert counter.status_code == 201, counter.text
    counter_offer_id = counter.json["data"]["offer"]["public_id"]
    accepted = client.post(
        f"/api/v1/offers/{counter_offer_id}/accept",
        headers=producer_headers,
        json={},
    )
    assert accepted.status_code == 200, accepted.text
    return producer_headers, actor_headers, booking_id


def test_contract_signature_legal_review_and_addendum_flow(
    client: FlaskClient,
) -> None:
    producer_headers, actor_headers, booking_id = _accepted_booking(client)

    templates = client.get("/api/v1/contract-templates")
    assert templates.status_code == 200
    assert any(
        row["public_id"] == "TPL-TALENT-001"
        for row in templates.json["data"]["templates"]
    )

    generated = client.post(
        f"/api/v1/bookings/{booking_id}/contracts",
        headers=producer_headers,
        json={},
    )
    assert generated.status_code == 201, generated.text
    contract = generated.json["data"]["contract"]
    contract_id = contract["public_id"]
    assert contract["status"] == "pending_signature"
    assert contract["value_minor"] == 18000000
    assert len(contract["parties"]) == 2
    assert {row["clause_key"] for row in contract["clauses"]} >= {
        "scope",
        "payment_schedule",
        "usage_rights",
        "cancellation",
        "safety",
    }

    listed = client.get("/api/v1/contracts", headers=producer_headers)
    assert listed.status_code == 200
    assert any(
        row["public_id"] == contract_id for row in listed.json["data"]["contracts"]
    )

    actor_detail = client.get(f"/api/v1/contracts/{contract_id}", headers=actor_headers)
    assert actor_detail.status_code == 200

    producer_signature = client.post(
        f"/api/v1/contracts/{contract_id}/signatures",
        headers=producer_headers,
        json={},
    )
    assert producer_signature.status_code == 200, producer_signature.text
    assert producer_signature.json["data"]["contract"]["signature_progress"] == "0.500"

    actor_signature = client.post(
        f"/api/v1/contracts/{contract_id}/signatures",
        headers=actor_headers,
        json={},
    )
    assert actor_signature.status_code == 200, actor_signature.text
    assert actor_signature.json["data"]["contract"]["status"] == "signed"
    assert actor_signature.json["data"]["contract"]["signature_progress"] == "1.000"

    review = client.post(
        "/api/v1/legal-reviews",
        headers=producer_headers,
        json={"contract_id": contract_id, "risk": "medium"},
    )
    assert review.status_code == 201, review.text
    review_id = review.json["data"]["review"]["public_id"]

    legal_headers, _legal_user_id = _register_role(
        client, "legal_partner", name="Contract Lawyer"
    )
    legal_queue = client.get("/api/v1/legal/reviews", headers=legal_headers)
    assert legal_queue.status_code == 200
    assert any(
        row["public_id"] == review_id for row in legal_queue.json["data"]["reviews"]
    )

    legal_detail = client.get(
        f"/api/v1/legal-reviews/{review_id}", headers=legal_headers
    )
    assert legal_detail.status_code == 200

    decision = client.post(
        f"/api/v1/legal-reviews/{review_id}/decision",
        headers=legal_headers,
        json={
            "status": "approved",
            "decision_notes": "Template terms approved for this booking.",
            "minutes": 25,
            "amount_minor": 750000,
        },
    )
    assert decision.status_code == 200, decision.text
    assert decision.json["data"]["review"]["status"] == "approved"

    addendum = client.post(
        f"/api/v1/contracts/{contract_id}/addendums",
        headers=actor_headers,
        json={
            "reason": "Extend usage rights",
            "content": "Allow the final TVC to be used on owned social channels.",
        },
    )
    assert addendum.status_code == 201, addendum.text
    assert addendum.json["data"]["addendum"]["status"] == "review_requested"
