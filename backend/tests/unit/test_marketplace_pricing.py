from __future__ import annotations

import uuid

import pytest
from flask import Flask
from flask.testing import FlaskClient
from sqlalchemy import select

from app.api.app import ROLES
from app.extensions import db
from app.models.identity import Role, User
from app.models.kyc import KycSubmission
from app.models.marketplace import City, Country


@pytest.fixture(autouse=True)
def _seed_reference_data(app: Flask) -> None:
    """Unit tests build a schema-only SQLite DB (no migration data seeds).

    Role and City rows normally come from Alembic data migrations that only
    run against the real MySQL database, so mirror the same rows here.
    """
    with app.app_context():
        for index, role in enumerate(ROLES):
            db.session.add(
                Role(
                    code=role["code"],
                    name=role["name"],
                    portal_route=role["portal_route"],
                    requires_kyc=role["requires_kyc"],
                    display_order=index,
                    is_active=True,
                )
            )
        pakistan = Country(
            iso2="PK", name="Pakistan", currency_code="PKR", phone_prefix="+92"
        )
        db.session.add(pakistan)
        db.session.flush()
        for public_id, name, province in [
            ("CITY-LHE", "Lahore", "Punjab"),
            ("CITY-KHI", "Karachi", "Sindh"),
            ("CITY-ISB", "Islamabad", "ICT"),
            ("CITY-RWP", "Rawalpindi", "Punjab"),
        ]:
            db.session.add(
                City(
                    public_id=public_id,
                    country_id=pakistan.id,
                    name=name,
                    province=province,
                    timezone="Asia/Karachi",
                    active=True,
                )
            )
        db.session.commit()


def _register_role(
    client: FlaskClient, role: str, *, name: str
) -> tuple[dict[str, str], str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"pricing-{uuid.uuid4().hex[:12]}@example.com",
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


def _lahore_city_id(client: FlaskClient) -> str:
    cities = client.get("/api/v1/cities")
    assert cities.status_code == 200
    return next(
        city
        for city in cities.json["data"]["cities"]
        if city["public_id"] == "CITY-LHE"
    )["public_id"]


def _publish_actor_listing(
    client: FlaskClient,
    *,
    pricing_mode: str | None = None,
) -> tuple[dict[str, str], str, str]:
    actor_headers, actor_user_id = _register_role(
        client, "actor_talent", name="Pricing Actor"
    )
    _approve_actor_kyc(client, actor_user_id)
    city_id = _lahore_city_id(client)
    profile = client.patch(
        "/api/v1/talent/profile",
        headers=actor_headers,
        json={
            "screen_name": "Pricing Actor",
            "day_rate_minor": 18000000,
            "currency": "PKR",
        },
    )
    assert profile.status_code == 200, profile.text
    payload = {
        "listing_type": "talent",
        "title": "Pricing Actor — Talent",
        "summary": "Actor listing used to test provider pricing controls.",
        "city_id": city_id,
    }
    if pricing_mode is not None:
        payload["pricing_mode"] = pricing_mode
    published = client.post(
        "/api/v1/marketplace/listings",
        headers=actor_headers,
        json=payload,
    )
    assert published.status_code == 201, published.text
    return actor_headers, actor_user_id, published.json["data"]["listing"]["public_id"]


def _create_project_and_requirement(
    client: FlaskClient, headers: dict[str, str]
) -> tuple[str, str]:
    project = client.post(
        "/api/v1/projects",
        headers=headers,
        json={"title": "Pricing Flow TVC", "project_type": "tvc"},
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


def test_fixed_pricing_hides_bargaining_and_enforces_listed_amount(
    client: FlaskClient,
) -> None:
    actor_headers, _actor_user_id, listing_id = _publish_actor_listing(
        client, pricing_mode="fixed"
    )

    listing = client.get(f"/api/v1/marketplace/listings/{listing_id}")
    assert listing.status_code == 200, listing.text
    listing_data = listing.json["data"]["listing"]
    assert listing_data["pricing_mode"] == "fixed"
    assert listing_data["shows_price"] is True
    assert listing_data["allows_bargaining"] is False
    assert listing_data["price_from_minor"] == 18000000

    producer_headers, _ = _register_role(
        client, "director_producer", name="Pricing Producer"
    )
    project_id, requirement_id = _create_project_and_requirement(
        client, producer_headers
    )

    wrong_amount = client.post(
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
    assert wrong_amount.status_code == 409, wrong_amount.text
    assert wrong_amount.json["error"]["code"] == "booking.fixed_price_required"

    created = client.post(
        "/api/v1/bookings",
        headers=producer_headers,
        json={
            "project_id": project_id,
            "requirement_id": requirement_id,
            "listing_id": listing_id,
            "category": "talent",
            "fee_minor": 18000000,
            "currency": "PKR",
            "start_at": "2026-07-19T02:30:00Z",
            "end_at": "2026-07-19T14:30:00Z",
        },
    )
    assert created.status_code == 201, created.text
    booking_id = created.json["data"]["booking"]["public_id"]
    assert created.json["data"]["booking"]["pricing_mode"] == "fixed"
    assert created.json["data"]["booking"]["allows_bargaining"] is False

    sent = client.post(
        f"/api/v1/bookings/{booking_id}/send",
        headers=producer_headers,
        json={
            "fee_minor": 18000000,
            "conditions": "Standard terms.",
            "message": "Fixed-price offer.",
        },
    )
    assert sent.status_code == 200, sent.text

    blocked_counter = client.post(
        f"/api/v1/bookings/{booking_id}/offers",
        headers=actor_headers,
        json={
            "fee_minor": 19000000,
            "currency": "PKR",
            "conditions": "Trying to counter a fixed-price listing.",
            "message": "Can we do 190k?",
        },
    )
    assert blocked_counter.status_code == 409, blocked_counter.text
    assert blocked_counter.json["error"]["code"] == "booking.bargaining_disabled"


def test_on_request_pricing_hides_amount_and_allows_bargaining(
    client: FlaskClient,
) -> None:
    actor_headers, _actor_user_id, listing_id = _publish_actor_listing(
        client, pricing_mode="on_request"
    )

    listing = client.get(f"/api/v1/marketplace/listings/{listing_id}")
    assert listing.status_code == 200, listing.text
    listing_data = listing.json["data"]["listing"]
    assert listing_data["pricing_mode"] == "on_request"
    assert listing_data["shows_price"] is False
    assert listing_data["allows_bargaining"] is True
    assert listing_data["price_from_minor"] is None
    assert listing_data["price_label"] == "Open to offers"

    producer_headers, _ = _register_role(
        client, "director_producer", name="Pricing Producer Two"
    )
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
            "fee_minor": 15000000,
            "currency": "PKR",
            "start_at": "2026-07-19T02:30:00Z",
            "end_at": "2026-07-19T14:30:00Z",
        },
    )
    assert created.status_code == 201, created.text
    booking_id = created.json["data"]["booking"]["public_id"]
    assert created.json["data"]["booking"]["pricing_mode"] == "on_request"
    assert created.json["data"]["booking"]["allows_bargaining"] is True

    sent = client.post(
        f"/api/v1/bookings/{booking_id}/send",
        headers=producer_headers,
        json={
            "fee_minor": 15000000,
            "conditions": "Open to offers.",
            "message": "Initial private offer.",
        },
    )
    assert sent.status_code == 200, sent.text

    counter = client.post(
        f"/api/v1/bookings/{booking_id}/offers",
        headers=actor_headers,
        json={
            "fee_minor": 16000000,
            "currency": "PKR",
            "conditions": "Countering the private offer.",
            "message": "Can we do 160k?",
        },
    )
    assert counter.status_code == 201, counter.text


def test_owner_can_change_pricing_mode_and_it_is_enforced(
    client: FlaskClient,
) -> None:
    actor_headers, _actor_user_id, listing_id = _publish_actor_listing(client)

    mine = client.get("/api/v1/marketplace/my-listings", headers=actor_headers)
    assert mine.status_code == 200, mine.text
    own_listing = next(
        row for row in mine.json["data"]["listings"] if row["public_id"] == listing_id
    )
    assert own_listing["pricing_mode"] == "negotiable"
    assert own_listing["configured_price_from_minor"] == 18000000

    switched = client.patch(
        f"/api/v1/marketplace/listings/{listing_id}/pricing",
        headers=actor_headers,
        json={"pricing_mode": "fixed", "price_from_minor": 20000000},
    )
    assert switched.status_code == 200, switched.text
    switched_listing = switched.json["data"]["listing"]
    assert switched_listing["pricing_mode"] == "fixed"
    assert switched_listing["allows_bargaining"] is False
    assert switched_listing["price_from_minor"] == 20000000

    invalid_mode = client.patch(
        f"/api/v1/marketplace/listings/{listing_id}/pricing",
        headers=actor_headers,
        json={"pricing_mode": "invisible"},
    )
    assert invalid_mode.status_code == 422, invalid_mode.text

    producer_headers, _ = _register_role(
        client, "director_producer", name="Pricing Producer Three"
    )
    project_id, requirement_id = _create_project_and_requirement(
        client, producer_headers
    )
    mismatched = client.post(
        "/api/v1/bookings",
        headers=producer_headers,
        json={
            "project_id": project_id,
            "requirement_id": requirement_id,
            "listing_id": listing_id,
            "category": "talent",
            "fee_minor": 18000000,
            "currency": "PKR",
            "start_at": "2026-07-19T02:30:00Z",
            "end_at": "2026-07-19T14:30:00Z",
        },
    )
    assert mismatched.status_code == 409, mismatched.text
    assert mismatched.json["error"]["code"] == "booking.fixed_price_required"
