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
            "email": f"booking-{uuid.uuid4().hex[:12]}@example.com",
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


def _publish_actor_listing(client: FlaskClient) -> tuple[dict[str, str], str, str]:
    actor_headers, actor_user_id = _register_role(
        client, "actor_talent", name="Booking Actor"
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
            "screen_name": "Booking Actor",
            "day_rate_minor": 18000000,
            "currency": "PKR",
        },
    )
    assert profile.status_code == 200, profile.text
    published = client.post(
        "/api/v1/marketplace/listings",
        headers=actor_headers,
        json={
            "listing_type": "talent",
            "title": "Booking Actor — Talent",
            "summary": "Experienced actor available for TVC booking tests.",
            "city_id": lahore["public_id"],
        },
    )
    assert published.status_code == 201, published.text
    return actor_headers, actor_user_id, published.json["data"]["listing"]["public_id"]


def _create_project_and_requirement(
    client: FlaskClient, headers: dict[str, str]
) -> tuple[str, str]:
    project = client.post(
        "/api/v1/projects",
        headers=headers,
        json={"title": "Booking Flow TVC", "project_type": "tvc"},
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


def test_booking_offer_counter_accept_chat_and_availability(
    client: FlaskClient,
) -> None:
    producer_headers, _producer_user_id = _register_role(
        client, "director_producer", name="Booking Producer"
    )
    actor_headers, actor_user_id, listing_id = _publish_actor_listing(client)
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
            "start_at": "2026-07-19T02:30:00Z",
            "end_at": "2026-07-19T14:30:00Z",
        },
    )
    assert created.status_code == 201, created.text
    booking = created.json["data"]["booking"]
    booking_id = booking["public_id"]
    conversation_id = booking["conversation_id"]

    sent = client.post(
        f"/api/v1/bookings/{booking_id}/send",
        headers=producer_headers,
        json={
            "fee_minor": 17000000,
            "conditions": "Wardrobe included.",
            "message": "Initial offer for the TVC.",
        },
    )
    assert sent.status_code == 200, sent.text
    first_offer_id = sent.json["data"]["booking"]["offers"][0]["public_id"]
    assert sent.json["data"]["booking"]["status"] == "sent"

    actor_detail = client.get(f"/api/v1/bookings/{booking_id}", headers=actor_headers)
    assert actor_detail.status_code == 200
    assert actor_detail.json["data"]["booking"]["public_id"] == booking_id

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

    negotiations = client.get("/api/v1/negotiations", headers=producer_headers)
    assert negotiations.status_code == 200
    negotiation_id = negotiations.json["data"]["negotiations"][0]["public_id"]
    negotiation = client.get(
        f"/api/v1/negotiations/{negotiation_id}", headers=producer_headers
    )
    assert negotiation.status_code == 200
    assert len(negotiation.json["data"]["negotiation"]["rounds"]) == 2

    accepted = client.post(
        f"/api/v1/offers/{counter_offer_id}/accept",
        headers=producer_headers,
        json={},
    )
    assert accepted.status_code == 200, accepted.text
    assert accepted.json["data"]["booking"]["status"] == "accepted"
    assert accepted.json["data"]["booking"]["agreed_amount_minor"] == 18000000

    producer_bookings = client.get(
        "/api/v1/bookings?role=requester", headers=producer_headers
    )
    assert producer_bookings.status_code == 200
    assert any(
        row["public_id"] == booking_id
        for row in producer_bookings.json["data"]["bookings"]
    )

    actor_opportunities = client.get(
        "/api/v1/talent/opportunities", headers=actor_headers
    )
    assert actor_opportunities.status_code == 200
    assert any(
        row["public_id"] == booking_id
        for row in actor_opportunities.json["data"]["bookings"]
    )

    old_offer_accept = client.post(
        f"/api/v1/offers/{first_offer_id}/accept",
        headers=actor_headers,
        json={},
    )
    assert old_offer_accept.status_code == 409

    conflict = client.post(
        "/api/v1/availability/check",
        json={
            "owner_user_id": actor_user_id,
            "start_at": "2026-07-19T04:00:00Z",
            "end_at": "2026-07-19T06:00:00Z",
        },
    )
    assert conflict.status_code == 200
    assert conflict.json["data"]["available"] is False
    assert conflict.json["data"]["conflicts"][0]["source_booking_id"] == booking_id

    actor_calendar = client.get("/api/v1/availability", headers=actor_headers)
    assert actor_calendar.status_code == 200
    booking_block_id = actor_calendar.json["data"]["availability"][0]["public_id"]

    cannot_delete_booking_block = client.delete(
        f"/api/v1/availability/{booking_block_id}", headers=actor_headers
    )
    assert cannot_delete_booking_block.status_code == 409

    manual_overlap = client.post(
        "/api/v1/availability",
        headers=actor_headers,
        json={
            "resource_type": "talent",
            "resource_id": actor_user_id,
            "start_at": "2026-07-19T05:00:00Z",
            "end_at": "2026-07-19T07:00:00Z",
            "status": "hold",
            "note": "Should conflict with accepted booking.",
        },
    )
    assert manual_overlap.status_code == 409

    manual_block = client.post(
        "/api/v1/availability",
        headers=actor_headers,
        json={
            "resource_type": "talent",
            "resource_id": actor_user_id,
            "start_at": "2026-07-22T05:00:00Z",
            "end_at": "2026-07-22T07:00:00Z",
            "status": "hold",
            "note": "Audition hold.",
        },
    )
    assert manual_block.status_code == 201, manual_block.text
    manual_block_id = manual_block.json["data"]["entry"]["public_id"]

    updated_block = client.patch(
        f"/api/v1/availability/{manual_block_id}",
        headers=actor_headers,
        json={"status": "blocked", "note": "Personal block."},
    )
    assert updated_block.status_code == 200
    assert updated_block.json["data"]["entry"]["status"] == "blocked"

    deleted_block = client.delete(
        f"/api/v1/availability/{manual_block_id}", headers=actor_headers
    )
    assert deleted_block.status_code == 200
    assert deleted_block.json["data"]["deleted"] is True

    message = client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=producer_headers,
        json={
            "body": "Call time confirmed at 7:30 AM.",
            "decision_type": "final_call_time",
        },
    )
    assert message.status_code == 201, message.text
    message_id = message.json["data"]["message"]["public_id"]

    pinned = client.post(
        f"/api/v1/messages/{message_id}/pin",
        headers=actor_headers,
        json={"decision_key": "final_call_time"},
    )
    assert pinned.status_code == 201
    assert pinned.json["data"]["pinned"] is True

    conversation = client.get(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=actor_headers,
    )
    assert conversation.status_code == 200
    assert (
        conversation.json["data"]["conversation"]["messages"][0]["public_id"]
        == message_id
    )
