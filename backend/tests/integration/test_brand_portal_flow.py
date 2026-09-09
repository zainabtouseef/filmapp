from __future__ import annotations

import os
import uuid

import pytest
from flask.testing import FlaskClient
from sqlalchemy import select

from app.extensions import db
from app.models.identity import Role, User
from app.models.kyc import KycSubmission
from app.models.marketplace import MarketplaceListing, TalentProfile

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        os.getenv("RUN_INTEGRATION_TESTS") != "1",
        reason="Set RUN_INTEGRATION_TESTS=1 with MySQL and Redis running.",
    ),
]


def _ensure_roles(client: FlaskClient, *codes: str) -> None:
    with client.application.app_context():
        for index, code in enumerate(codes):
            existing = db.session.execute(
                select(Role).where(Role.code == code)
            ).scalar_one_or_none()
            if existing is None:
                db.session.add(
                    Role(
                        code=code,
                        name=code.replace("_", " ").title(),
                        portal_route=f"/{code}",
                        requires_kyc=True,
                        display_order=100 + index,
                        is_active=True,
                    )
                )
        db.session.commit()


def _register_role(
    client: FlaskClient,
    role: str,
    *,
    name: str,
) -> tuple[dict[str, str], str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"brand-portal-{uuid.uuid4().hex[:12]}@example.com",
            "password": "StrongPass123!",
            "display_name": name,
            "initial_role": role,
            "terms_version": "2026-07",
        },
    )
    assert response.status_code == 201, response.text
    return (
        {
            "Authorization": (
                f"Bearer {response.json['data']['tokens']['access_token']}"
            )
        },
        response.json["data"]["user"]["public_id"],
    )


def _approve_role_kyc(
    client: FlaskClient,
    user_public_id: str,
    role_code: str,
) -> None:
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        role = db.session.execute(
            select(Role).where(Role.code == role_code)
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


def test_complete_brand_project_shortlist_request_and_cancel_flow(
    client: FlaskClient,
) -> None:
    _ensure_roles(client, "brand_sponsor", "actor_talent")
    brand_headers, _brand_user_id = _register_role(
        client,
        "brand_sponsor",
        name="Noor Summer Campaign",
    )
    actor_headers, actor_user_id = _register_role(
        client,
        "actor_talent",
        name="Areeba Khan",
    )
    _approve_role_kyc(client, actor_user_id, "actor_talent")

    profile = client.patch(
        "/api/v1/brands/profile",
        headers=brand_headers,
        json={
            "name": "Noor Apparel",
            "category": "fashion",
            "representative": "Maham Noor",
            "description": "Fashion campaigns and commercial productions in Pakistan.",
        },
    )
    assert profile.status_code == 200, profile.text

    project_response = client.post(
        "/api/v1/projects",
        headers=brand_headers,
        json={
            "title": "Summer Clothing Campaign",
            "project_type": "fashion_shoot",
            "description": "Editorial, video and social campaign production.",
            "start_date": "2027-05-10",
            "end_date": "2027-05-12",
            "estimated_budget_minor": 250000000,
            "status": "active",
        },
    )
    assert project_response.status_code == 201, project_response.text
    project = project_response.json["data"]["project"]
    project_id = project["public_id"]

    requirement_response = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=brand_headers,
        json={
            "category": "talent",
            "title": "Lead campaign actor",
            "summary": "Warm, confident screen presence for the hero film.",
            "quantity": 1,
            "budget_max_minor": 30000000,
            "start_date": "2027-05-10",
            "end_date": "2027-05-12",
        },
    )
    assert requirement_response.status_code == 201, requirement_response.text
    requirement_id = requirement_response.json["data"]["requirement"]["public_id"]

    duplicate = client.post(
        f"/api/v1/projects/{project_id}/duplicate",
        headers=brand_headers,
        json={},
    )
    assert duplicate.status_code == 201, duplicate.text
    duplicate_project = duplicate.json["data"]["project"]
    assert duplicate_project["status"] == "draft"
    assert len(duplicate_project["requirements"]) == 1

    actor_profile = client.patch(
        "/api/v1/talent/profile",
        headers=actor_headers,
        json={
            "screen_name": "Areeba Khan",
            "availability_status": "available",
            "day_rate_minor": 22000000,
            "currency": "PKR",
        },
    )
    assert actor_profile.status_code == 200, actor_profile.text
    listing = client.post(
        "/api/v1/marketplace/listings",
        headers=actor_headers,
        json={
            "listing_type": "talent",
            "title": "Areeba Khan — Commercial Actor",
            "summary": (
                "Commercial actor available for fashion and lifestyle campaigns."
            ),
        },
    )
    assert listing.status_code == 201, listing.text
    listing_id = listing.json["data"]["listing"]["public_id"]

    discovery = client.get(
        "/api/v1/brands/discovery?category=Actors&q=Areeba",
        headers=brand_headers,
    )
    assert discovery.status_code == 200, discovery.text
    discovered = discovery.json["data"]["discovery"]["items"]
    assert any(row["listing_id"] == listing_id for row in discovered), discovered

    # Imported production data can legitimately contain an older `actor`
    # listing and a newer `talent` alias for the same profile. That must not
    # make discovery fail with MultipleResultsFound.
    with client.application.app_context():
        actor_user = db.session.execute(
            select(User).where(User.public_id == actor_user_id)
        ).scalar_one()
        talent_profile = db.session.execute(
            select(TalentProfile).where(TalentProfile.user_id == actor_user.id)
        ).scalar_one()
        db.session.add(
            MarketplaceListing(
                owner_user_id=actor_user.id,
                listing_type="actor",
                profile_entity_id=talent_profile.public_id,
                title="Areeba Khan — Imported Actor Alias",
                summary="Historical actor alias retained during marketplace migration.",
                price_from_minor=22000000,
                currency="PKR",
                verification_status="approved",
                moderation_status="approved",
                visibility="public",
            )
        )
        db.session.commit()
    duplicate_safe_discovery = client.get(
        "/api/v1/brands/discovery?category=Actors&q=Areeba",
        headers=brand_headers,
    )
    assert duplicate_safe_discovery.status_code == 200, duplicate_safe_discovery.text

    shortlist = client.post(
        "/api/v1/shortlists",
        headers=brand_headers,
        json={
            "name": "Summer Clothing Campaign shortlist",
            "project_id": project_id,
            "requirement_id": requirement_id,
        },
    )
    assert shortlist.status_code == 201, shortlist.text
    shortlist_id = shortlist.json["data"]["shortlist"]["public_id"]
    shortlist_item = client.post(
        f"/api/v1/shortlists/{shortlist_id}/items",
        headers=brand_headers,
        json={"listing_id": listing_id, "status": "selected"},
    )
    assert shortlist_item.status_code == 201, shortlist_item.text
    assert shortlist_item.json["data"]["item"]["listing"]["public_id"] == listing_id

    booking_response = client.post(
        "/api/v1/bookings",
        headers=brand_headers,
        json={
            "project_id": project_id,
            "requirement_id": requirement_id,
            "listing_id": listing_id,
            "category": "talent",
            "fee_minor": 22000000,
            "currency": "PKR",
            "start_at": "2027-05-10T04:00:00Z",
            "end_at": "2027-05-10T13:00:00Z",
        },
    )
    assert booking_response.status_code == 201, booking_response.text
    booking_id = booking_response.json["data"]["booking"]["public_id"]
    sent = client.post(
        f"/api/v1/bookings/{booking_id}/send",
        headers=brand_headers,
        json={
            "fee_minor": 22000000,
            "currency": "PKR",
            "message": "Hero-film request for Noor Apparel summer campaign.",
        },
    )
    assert sent.status_code == 200, sent.text
    assert sent.json["data"]["booking"]["status"] == "sent"

    actor_requests = client.get(
        "/api/v1/talent/opportunities",
        headers=actor_headers,
    )
    assert actor_requests.status_code == 200, actor_requests.text
    assert any(
        row["public_id"] == booking_id
        for row in actor_requests.json["data"]["bookings"]
    )

    cancelled = client.post(
        f"/api/v1/bookings/{booking_id}/cancel",
        headers=brand_headers,
        json={"reason": "Campaign shoot dates changed."},
    )
    assert cancelled.status_code == 200, cancelled.text
    assert cancelled.json["data"]["booking"]["status"] == "cancelled"

    actor_notifications = client.get(
        "/api/v1/notifications",
        headers=actor_headers,
    )
    assert actor_notifications.status_code == 200, actor_notifications.text
    assert any(
        "cancelled" in row["title"].lower()
        for row in actor_notifications.json["data"]["notifications"]
    )

    dashboard = client.get("/api/v1/brands/dashboard", headers=brand_headers)
    assert dashboard.status_code == 200, dashboard.text
    assert dashboard.json["data"]["dashboard"]["summary"]["project_count"] == 2


def test_brand_profile_rejects_non_brand_role(client: FlaskClient) -> None:
    _ensure_roles(client, "actor_talent")
    actor_headers, _actor_id = _register_role(
        client,
        "actor_talent",
        name="Actor Without Brand Role",
    )
    blocked = client.patch(
        "/api/v1/brands/profile",
        headers=actor_headers,
        json={"name": "Should Not Exist"},
    )
    assert blocked.status_code == 403
    assert blocked.json["error"]["code"] == "brand.role_required"
