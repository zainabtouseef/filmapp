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
            "email": f"trust-{uuid.uuid4().hex[:12]}@example.com",
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
        client, "director_producer", name="Trust Flow Producer"
    )
    actor_headers, actor_user_id = _register_role(
        client, "actor_talent", name="Trust Flow Actor"
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
        json={"screen_name": "Trust Flow Actor", "day_rate_minor": 15000000},
    )
    assert profile.status_code == 200, profile.text
    listing = client.post(
        "/api/v1/marketplace/listings",
        headers=actor_headers,
        json={
            "listing_type": "talent",
            "title": "Trust Flow Actor — Talent",
            "summary": "Talent available for trust and safety tests.",
            "city_id": lahore["public_id"],
        },
    )
    assert listing.status_code == 201, listing.text
    listing_id = listing.json["data"]["listing"]["public_id"]
    project = client.post(
        "/api/v1/projects",
        headers=producer_headers,
        json={"title": "Trust Flow TVC", "project_type": "tvc"},
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
        json={"fee_minor": 15000000, "message": "Trust flow offer."},
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
    producer_signature = client.post(
        f"/api/v1/contracts/{contract_id}/signatures",
        headers=producer_headers,
        json={},
    )
    assert producer_signature.status_code == 200, producer_signature.text
    actor_signature = client.post(
        f"/api/v1/contracts/{contract_id}/signatures", headers=actor_headers, json={}
    )
    assert actor_signature.status_code == 200, actor_signature.text
    assert actor_signature.json["data"]["contract"]["status"] == "signed"

    schedules = client.get("/api/v1/payment-schedules", headers=producer_headers)
    assert schedules.status_code == 200, schedules.text
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
            "transaction_reference": "SANDBOX-BANK-001",
            "idempotency_key": uuid.uuid4().hex,
        },
    )
    assert proof.status_code == 201, proof.text
    proof_id = proof.json["data"]["proof"]["public_id"]

    finance_headers, _finance_id = _register_admin(
        client, "finance_admin", name="Trust Flow Finance"
    )
    decision = client.post(
        f"/api/v1/admin/payment-proofs/{proof_id}/decision",
        headers=finance_headers,
        json={"decision": "approved"},
    )
    assert decision.status_code == 200, decision.text
    assert decision.json["data"]["proof"]["status"] == "verified"

    return producer_headers, producer_user_id, actor_headers, actor_user_id, booking_id


def test_review_report_and_block_flow(client: FlaskClient) -> None:
    producer_headers, producer_id, actor_headers, actor_id, booking_id = (
        _accepted_and_secured_booking(client)
    )

    eligibility = client.get(
        f"/api/v1/bookings/{booking_id}/review-eligibility", headers=producer_headers
    )
    assert eligibility.status_code == 200, eligibility.text
    assert eligibility.json["data"]["eligible"] is True

    review = client.post(
        "/api/v1/reviews",
        headers=producer_headers,
        json={
            "booking_id": booking_id,
            "rating": 5,
            "text": "Professional and punctual.",
            "dimensions": [{"dimension": "punctuality", "score": 5}],
        },
    )
    assert review.status_code == 201, review.text

    duplicate = client.post(
        "/api/v1/reviews",
        headers=producer_headers,
        json={"booking_id": booking_id, "rating": 4},
    )
    assert duplicate.status_code == 409, duplicate.text

    user_reviews = client.get(f"/api/v1/users/{actor_id}/reviews")
    assert user_reviews.status_code == 200, user_reviews.text
    assert user_reviews.json["data"]["review_count"] == 1
    assert user_reviews.json["data"]["rating_average"] == 5.0

    review_request = client.post(
        "/api/v1/review-requests",
        headers=actor_headers,
        json={"booking_id": booking_id},
    )
    assert review_request.status_code == 201, review_request.text

    producer_notifications = client.get(
        "/api/v1/notifications", headers=producer_headers
    )
    assert producer_notifications.status_code == 200, producer_notifications.text
    assert producer_notifications.json["data"]["unread_count"] >= 1

    reasons = client.get("/api/v1/reports/reasons")
    assert reasons.status_code == 200, reasons.text
    assert "harassment" in reasons.json["data"]["reasons"]

    report = client.post(
        "/api/v1/reports",
        headers=actor_headers,
        json={
            "reported_user_id": producer_id,
            "entity_type": "user",
            "entity_id": producer_id,
            "reason": "harassment",
            "description": "Repeated unsafe messages.",
        },
    )
    assert report.status_code == 201, report.text

    block = client.post(
        "/api/v1/blocked-users",
        headers=actor_headers,
        json={"user_id": producer_id, "reason": "harassment"},
    )
    assert block.status_code == 201, block.text

    blocked_list = client.get("/api/v1/blocked-users", headers=actor_headers)
    assert blocked_list.status_code == 200, blocked_list.text
    assert len(blocked_list.json["data"]["blocked_users"]) == 1

    unblock = client.delete(
        f"/api/v1/blocked-users/{producer_id}", headers=actor_headers
    )
    assert unblock.status_code == 200, unblock.text
    assert unblock.json["data"]["unblocked"] is True


def test_moderation_case_flow(client: FlaskClient) -> None:
    reporter_headers, _reporter_id = _register_role(
        client, "actor_talent", name="Moderation Flow Reporter"
    )
    reviewer_headers, _reviewer_id = _register_admin(
        client, "reviewer", name="Moderation Flow Reviewer"
    )

    report = client.post(
        "/api/v1/reports",
        headers=reporter_headers,
        json={
            "entity_type": "portfolio_item",
            "entity_id": "PORT-0001",
            "reason": "inappropriate_content",
            "description": "Explicit content in showreel.",
        },
    )
    assert report.status_code == 201, report.text

    cases = client.get("/api/v1/admin/moderation-cases", headers=reviewer_headers)
    assert cases.status_code == 200, cases.text
    auto_case = next(
        row for row in cases.json["data"]["cases"] if row["entity_id"] == "PORT-0001"
    )
    assert auto_case["source"] == "user_report"

    manual = client.post(
        "/api/v1/admin/moderation-cases",
        headers=reviewer_headers,
        json={"entity_type": "listing", "entity_id": "LST-0002", "risk_level": "high"},
    )
    assert manual.status_code == 201, manual.text
    case_id = manual.json["data"]["case"]["public_id"]

    detail = client.get(
        f"/api/v1/admin/moderation-cases/{case_id}", headers=reviewer_headers
    )
    assert detail.status_code == 200, detail.text
    assert len(detail.json["data"]["case"]["events"]) == 1

    decision = client.post(
        f"/api/v1/admin/moderation-cases/{case_id}/decision",
        headers=reviewer_headers,
        json={"decision": "approved", "reason": "No policy violation found."},
    )
    assert decision.status_code == 200, decision.text
    assert decision.json["data"]["case"]["status"] == "resolved"
    assert len(decision.json["data"]["case"]["events"]) == 2


def test_dispute_flow(client: FlaskClient) -> None:
    producer_headers, _producer_id, actor_headers, _actor_id, booking_id = (
        _accepted_and_secured_booking(client)
    )

    dispute = client.post(
        "/api/v1/disputes",
        headers=producer_headers,
        json={
            "booking_id": booking_id,
            "type": "damage",
            "description": "Equipment returned damaged.",
            "value_minor": 350000,
        },
    )
    assert dispute.status_code == 201, dispute.text
    dispute_id = dispute.json["data"]["dispute"]["public_id"]

    evidence = client.post(
        f"/api/v1/disputes/{dispute_id}/evidence",
        headers=actor_headers,
        json={"evidence_type": "note", "description": "Item was fine at handover."},
    )
    assert evidence.status_code == 201, evidence.text
    assert len(evidence.json["data"]["dispute"]["evidence"]) == 1

    actor_view = client.get(f"/api/v1/disputes/{dispute_id}", headers=actor_headers)
    assert actor_view.status_code == 200, actor_view.text

    reviewer_headers, _reviewer_id = _register_admin(
        client, "reviewer", name="Dispute Flow Reviewer"
    )
    admin_list = client.get("/api/v1/admin/disputes", headers=reviewer_headers)
    assert admin_list.status_code == 200, admin_list.text
    assert any(
        row["public_id"] == dispute_id for row in admin_list.json["data"]["disputes"]
    )

    decision = client.post(
        f"/api/v1/admin/disputes/{dispute_id}/decision",
        headers=reviewer_headers,
        json={"decision": "resolved", "note": "Damage confirmed, deposit applied."},
    )
    assert decision.status_code == 200, decision.text
    assert decision.json["data"]["dispute"]["status"] == "resolved"
    assert decision.json["data"]["dispute"]["resolved_at"] is not None

    producer_notifications = client.get(
        "/api/v1/notifications", headers=producer_headers
    )
    assert producer_notifications.status_code == 200, producer_notifications.text
    assert any(
        row["category"] == "disputes"
        for row in producer_notifications.json["data"]["notifications"]
    )


def test_support_ticket_flow(client: FlaskClient) -> None:
    user_headers, _user_id = _register_role(
        client, "director_producer", name="Support Flow User"
    )
    agent_headers, _agent_id = _register_admin(
        client, "support_agent", name="Support Flow Agent"
    )

    ticket = client.post(
        "/api/v1/support-tickets",
        headers=user_headers,
        json={
            "category": "payment",
            "priority": "high",
            "subject": "Proof needs review",
            "message": "Please review my clearer receipt.",
        },
    )
    assert ticket.status_code == 201, ticket.text
    ticket_id = ticket.json["data"]["ticket"]["public_id"]

    own_list = client.get("/api/v1/support-tickets", headers=user_headers)
    assert own_list.status_code == 200, own_list.text
    assert len(own_list.json["data"]["tickets"]) == 1

    reply = client.post(
        f"/api/v1/support-tickets/{ticket_id}/messages",
        headers=agent_headers,
        json={"body": "Internal: escalate to finance.", "internal_note": True},
    )
    assert reply.status_code == 201, reply.text

    public_reply = client.post(
        f"/api/v1/support-tickets/{ticket_id}/messages",
        headers=agent_headers,
        json={"body": "Thanks, reviewing now."},
    )
    assert public_reply.status_code == 201, public_reply.text

    owner_view = client.get(
        f"/api/v1/support-tickets/{ticket_id}", headers=user_headers
    )
    assert owner_view.status_code == 200, owner_view.text
    owner_messages = owner_view.json["data"]["ticket"]["messages"]
    assert len(owner_messages) == 2
    assert all(not row["internal_note"] for row in owner_messages)

    admin_view = client.get(
        f"/api/v1/support-tickets/{ticket_id}", headers=agent_headers
    )
    assert admin_view.status_code == 200, admin_view.text
    assert len(admin_view.json["data"]["ticket"]["messages"]) == 3

    admin_queue = client.get("/api/v1/admin/support-tickets", headers=agent_headers)
    assert admin_queue.status_code == 200, admin_queue.text
    assert any(
        row["public_id"] == ticket_id for row in admin_queue.json["data"]["tickets"]
    )

    updated = client.patch(
        f"/api/v1/admin/support-tickets/{ticket_id}",
        headers=agent_headers,
        json={"status": "resolved"},
    )
    assert updated.status_code == 200, updated.text
    assert updated.json["data"]["ticket"]["status"] == "resolved"


def test_announcement_and_push_device_flow(client: FlaskClient) -> None:
    admin_headers, _admin_id = _register_admin(
        client, "super_admin", name="Announcement Flow Admin"
    )
    recipient_headers, _recipient_id = _register_role(
        client, "actor_talent", name="Announcement Flow Recipient"
    )

    device = client.post(
        "/api/v1/push-devices",
        headers=recipient_headers,
        json={"device_id": "device-1", "platform": "android", "token": "raw-token"},
    )
    assert device.status_code == 201, device.text

    announcement = client.post(
        "/api/v1/admin/announcements",
        headers=admin_headers,
        json={
            "title": "Planned maintenance",
            "body": "Service unavailable Sunday 2 AM.",
            "audience": {"roles": ["all"]},
            "channels": ["in_app", "push"],
        },
    )
    assert announcement.status_code == 201, announcement.text
    announcement_id = announcement.json["data"]["announcement"]["public_id"]

    listing = client.get("/api/v1/admin/announcements", headers=admin_headers)
    assert listing.status_code == 200, listing.text
    assert any(
        row["public_id"] == announcement_id
        for row in listing.json["data"]["announcements"]
    )

    published = client.post(
        f"/api/v1/admin/announcements/{announcement_id}/publish",
        headers=admin_headers,
        json={},
    )
    assert published.status_code == 200, published.text
    assert published.json["data"]["announcement"]["status"] == "published"

    notifications = client.get("/api/v1/notifications", headers=recipient_headers)
    assert notifications.status_code == 200, notifications.text
    assert any(
        row["category"] == "announcements"
        for row in notifications.json["data"]["notifications"]
    )

    unread = notifications.json["data"]["notifications"][0]
    mark_read = client.patch(
        f"/api/v1/notifications/{unread['public_id']}/read",
        headers=recipient_headers,
    )
    assert mark_read.status_code == 200, mark_read.text
    assert mark_read.json["data"]["notification"]["read_at"] is not None

    mark_all = client.post("/api/v1/notifications/read-all", headers=recipient_headers)
    assert mark_all.status_code == 200, mark_all.text
