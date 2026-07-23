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
            "email": f"ops-{uuid.uuid4().hex[:12]}@example.com",
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
        client, "actor_talent", name="Ops Actor"
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
            "screen_name": "Ops Actor",
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
            "title": "Ops Actor — Talent",
            "summary": "Experienced actor available for operations tests.",
            "city_id": lahore["public_id"],
        },
    )
    assert listing.status_code == 201, listing.text
    return actor_headers, listing.json["data"]["listing"]["public_id"]


def _accepted_booking(
    client: FlaskClient,
) -> tuple[dict[str, str], dict[str, str], str, str]:
    producer_headers, _producer_user_id = _register_role(
        client, "director_producer", name="Ops Producer"
    )
    actor_headers, listing_id = _publish_actor_listing(client)
    project = client.post(
        "/api/v1/projects",
        headers=producer_headers,
        json={"title": "Ops Flow TVC", "project_type": "tvc"},
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
            "fee_minor": 17000000,
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
        json={"fee_minor": 17000000, "message": "Ops offer."},
    )
    assert sent.status_code == 200, sent.text
    offer_id = sent.json["data"]["booking"]["offers"][0]["public_id"]
    accepted = client.post(
        f"/api/v1/offers/{offer_id}/accept", headers=actor_headers, json={}
    )
    assert accepted.status_code == 200, accepted.text
    return producer_headers, actor_headers, project_id, booking_id


def test_location_equipment_and_safety_operations_flow(client: FlaskClient) -> None:
    producer_headers, actor_headers, project_id, booking_id = _accepted_booking(client)
    location_headers, _location_user_id = _register_role(
        client, "location_owner", name="Ops Location Owner"
    )
    equipment_headers, _equipment_user_id = _register_role(
        client, "equipment_provider", name="Ops Equipment Provider"
    )
    cities = client.get("/api/v1/cities")
    lahore = next(
        city
        for city in cities.json["data"]["cities"]
        if city["public_id"] == "CITY-LHE"
    )

    location = client.post(
        "/api/v1/location-properties",
        headers=location_headers,
        json={
            "name": "Gulberg Heritage House",
            "property_type": "house",
            "city_id": lahore["public_id"],
            "area_name": "Gulberg",
            "public_address": "Gulberg Lahore",
            "private_address": "Exact private address hidden until secured booking.",
            "capacity": 35,
            "parking_spaces": 8,
            "power_backup": True,
            "accessible": True,
            "status": "published",
        },
    )
    assert location.status_code == 201, location.text
    property_id = location.json["data"]["property"]["public_id"]
    assert "private_address" not in location.json["data"]["property"]

    space = client.post(
        f"/api/v1/location-properties/{property_id}/spaces",
        headers=location_headers,
        json={"name": "Main drawing room", "space_type": "interior", "capacity": 20},
    )
    assert space.status_code == 201, space.text
    pricing = client.post(
        f"/api/v1/location-properties/{property_id}/pricing",
        headers=location_headers,
        json={"label": "Day shoot", "amount_minor": 18000000},
    )
    assert pricing.status_code == 201, pricing.text
    pricing_id = pricing.json["data"]["pricing"]["public_id"]
    rule = client.post(
        f"/api/v1/location-properties/{property_id}/rules",
        headers=location_headers,
        json={"rule_type": "noise", "label": "Night shoots", "allowed": True},
    )
    assert rule.status_code == 201, rule.text
    rule_id = rule.json["data"]["rule"]["public_id"]

    updated_location = client.patch(
        f"/api/v1/location-properties/{property_id}",
        headers=location_headers,
        json={
            "description": "Production-ready heritage property with controlled access.",
            "capacity": 40,
        },
    )
    assert updated_location.status_code == 200, updated_location.text
    updated_property = updated_location.json["data"]["property"]
    assert updated_property["capacity"] == 40
    assert updated_property["power_backup"] is True
    assert updated_property["status"] == "published"
    assert len(updated_property["pricing"]) == 1
    assert len(updated_property["rules"]) == 1

    updated_pricing = client.patch(
        f"/api/v1/location-pricing/{pricing_id}",
        headers=location_headers,
        json={"amount_minor": 19500000, "conditions": "Twelve-hour day."},
    )
    assert updated_pricing.status_code == 200, updated_pricing.text
    assert updated_pricing.json["data"]["pricing"]["amount_minor"] == 19500000
    updated_rule = client.patch(
        f"/api/v1/location-rules/{rule_id}",
        headers=location_headers,
        json={"allowed": False, "note": "Written approval is required."},
    )
    assert updated_rule.status_code == 200, updated_rule.text
    assert updated_rule.json["data"]["rule"]["allowed"] is False

    published_location = client.post(
        "/api/v1/marketplace/listings",
        headers=location_headers,
        json={
            "listing_type": "location",
            "profile_entity_id": property_id,
            "title": "Gulberg Heritage House",
            "summary": "Production-ready heritage property with controlled access.",
        },
    )
    assert published_location.status_code == 201, published_location.text
    assert published_location.json["data"]["listing"]["listing_type"] == "location"
    assert published_location.json["data"]["listing"]["price_from_minor"] == 19500000

    inspection = client.post(
        "/api/v1/location-inspections",
        headers=producer_headers,
        json={
            "booking_id": booking_id,
            "property_id": property_id,
            "inspection_type": "check_in",
            "meter_reading": "7842",
        },
    )
    assert inspection.status_code == 201, inspection.text
    inspection_id = inspection.json["data"]["inspection"]["public_id"]
    item = client.post(
        f"/api/v1/location-inspections/{inspection_id}/items",
        headers=producer_headers,
        json={
            "area_label": "Main drawing room",
            "note": "Clean",
            "issue_severity": "none",
        },
    )
    assert item.status_code == 201, item.text
    owner_confirm = client.post(
        f"/api/v1/location-inspections/{inspection_id}/confirm",
        headers=location_headers,
        json={},
    )
    assert owner_confirm.status_code == 200, owner_confirm.text
    renter_confirm = client.post(
        f"/api/v1/location-inspections/{inspection_id}/confirm",
        headers=producer_headers,
        json={},
    )
    assert renter_confirm.status_code == 200, renter_confirm.text
    assert renter_confirm.json["data"]["inspection"]["status"] == "confirmed"
    inspection_history = client.get(
        f"/api/v1/location-inspections?property_id={property_id}",
        headers=location_headers,
    )
    assert inspection_history.status_code == 200, inspection_history.text
    assert len(inspection_history.json["data"]["inspections"]) == 1

    claim = client.post(
        "/api/v1/damage-claims",
        headers=producer_headers,
        json={
            "booking_id": booking_id,
            "inspection_id": inspection_id,
            "description": "Minor scuff near window.",
            "claimed_minor": 350000,
        },
    )
    assert claim.status_code == 201, claim.text
    claim_id = claim.json["data"]["claim"]["public_id"]
    evidence = client.post(
        f"/api/v1/damage-claims/{claim_id}/evidence",
        headers=producer_headers,
        json={"evidence_type": "note", "caption": "Logged without photo."},
    )
    assert evidence.status_code == 201, evidence.text
    claim_history = client.get(
        f"/api/v1/damage-claims?booking_id={booking_id}",
        headers=producer_headers,
    )
    assert claim_history.status_code == 200, claim_history.text
    assert len(claim_history.json["data"]["claims"]) == 1

    profile = client.patch(
        "/api/v1/equipment/provider-profile",
        headers=equipment_headers,
        json={
            "name": "LensHouse Rentals",
            "provider_type": "rental_house",
            "city_id": lahore["public_id"],
            "coverage": "Nationwide",
            "service_categories": "Camera lighting grip",
        },
    )
    assert profile.status_code == 200, profile.text
    profile_payload = profile.json["data"]["profile"]
    provider_profile_id = profile_payload["public_id"]
    assert profile_payload["listing_id"]
    assert profile_payload["visibility"] == "public"
    equipment = client.post(
        "/api/v1/equipment/items",
        headers=equipment_headers,
        json={
            "category": "camera",
            "brand": "Sony",
            "model_name": "Venice 2",
            "serial": "private-serial",
            "day_rate_minor": 12000000,
            "deposit_minor": 50000000,
        },
    )
    assert equipment.status_code == 201, equipment.text
    equipment_item_id = equipment.json["data"]["item"]["public_id"]
    equipment_rows = client.get(
        "/api/v1/equipment/items",
        headers=equipment_headers,
    )
    assert equipment_rows.status_code == 200, equipment_rows.text
    assert equipment_rows.json["data"]["items"][0]["public_id"] == equipment_item_id
    equipment_update = client.patch(
        f"/api/v1/equipment/items/{equipment_item_id}",
        headers=equipment_headers,
        json={"condition": "excellent", "status": "maintenance"},
    )
    assert equipment_update.status_code == 200, equipment_update.text
    assert equipment_update.json["data"]["item"]["condition"] == "excellent"
    assert equipment_update.json["data"]["item"]["status"] == "maintenance"
    package = client.post(
        "/api/v1/equipment/packages",
        headers=equipment_headers,
        json={"name": "Cinema Camera Package", "price_minor": 18500000},
    )
    assert package.status_code == 201, package.text
    package_id = package.json["data"]["package"]["public_id"]
    package_item = client.post(
        f"/api/v1/equipment/packages/{package_id}/items",
        headers=equipment_headers,
        json={"equipment_item_id": equipment_item_id, "quantity": 1},
    )
    assert package_item.status_code == 201, package_item.text
    package_update = client.patch(
        f"/api/v1/equipment/packages/{package_id}",
        headers=equipment_headers,
        json={"status": "published", "operator_included": True},
    )
    assert package_update.status_code == 200, package_update.text
    assert package_update.json["data"]["package"]["status"] == "published"
    package_rows = client.get(
        "/api/v1/equipment/packages",
        headers=equipment_headers,
    )
    assert package_rows.status_code == 200, package_rows.text
    assert (
        package_rows.json["data"]["packages"][0]["items"][0]["equipment_item"][
            "public_id"
        ]
        == equipment_item_id
    )
    term = client.post(
        "/api/v1/equipment/terms",
        headers=equipment_headers,
        json={"label": "Late return", "term_type": "late_fee", "amount_minor": 1500000},
    )
    assert term.status_code == 201, term.text
    term_id = term.json["data"]["term"]["public_id"]
    term_update = client.patch(
        f"/api/v1/equipment/terms/{term_id}",
        headers=equipment_headers,
        json={"enabled": False, "note": "Waived for approved long rentals."},
    )
    assert term_update.status_code == 200, term_update.text
    assert term_update.json["data"]["term"]["enabled"] is False
    term_rows = client.get(
        "/api/v1/equipment/terms",
        headers=equipment_headers,
    )
    assert term_rows.status_code == 200, term_rows.text
    assert term_rows.json["data"]["terms"][0]["public_id"] == term_id

    equipment_inspection = client.post(
        "/api/v1/equipment-inspections",
        headers=producer_headers,
        json={
            "booking_id": booking_id,
            "provider_profile_id": provider_profile_id,
            "inspection_type": "handover",
        },
    )
    assert equipment_inspection.status_code == 201, equipment_inspection.text
    equipment_inspection_id = equipment_inspection.json["data"]["inspection"][
        "public_id"
    ]
    equipment_inspection_item = client.post(
        f"/api/v1/equipment-inspections/{equipment_inspection_id}/items",
        headers=producer_headers,
        json={
            "equipment_item_id": equipment_item_id,
            "accessories": ["battery x4", "case"],
            "stage": "captured",
            "note": "No marks.",
        },
    )
    assert equipment_inspection_item.status_code == 201, equipment_inspection_item.text
    equipment_inspection_update = client.post(
        f"/api/v1/equipment-inspections/{equipment_inspection_id}/items",
        headers=equipment_headers,
        json={
            "equipment_item_id": equipment_item_id,
            "accessories": ["battery x4", "case", "charger"],
            "stage": "verified",
            "note": "Condition verified by provider.",
        },
    )
    assert equipment_inspection_update.status_code == 201
    inspection_items = equipment_inspection_update.json["data"]["inspection"]["items"]
    assert len(inspection_items) == 1
    assert inspection_items[0]["stage"] == "verified"
    inspection_rows = client.get(
        "/api/v1/equipment-inspections?inspection_type=handover",
        headers=equipment_headers,
    )
    assert inspection_rows.status_code == 200, inspection_rows.text
    assert (
        inspection_rows.json["data"]["inspections"][0]["public_id"]
        == equipment_inspection_id
    )
    provider_sign = client.post(
        f"/api/v1/equipment-inspections/{equipment_inspection_id}/confirm",
        headers=equipment_headers,
        json={},
    )
    assert provider_sign.status_code == 200, provider_sign.text
    renter_sign = client.post(
        f"/api/v1/equipment-inspections/{equipment_inspection_id}/confirm",
        headers=producer_headers,
        json={},
    )
    assert renter_sign.status_code == 200, renter_sign.text
    assert renter_sign.json["data"]["inspection"]["status"] == "confirmed"

    safety = client.post(
        "/api/v1/safety-checks",
        headers=producer_headers,
        json={"project_id": project_id, "risk_level": "medium"},
    )
    assert safety.status_code == 201, safety.text
    safety_id = safety.json["data"]["safety_check"]["public_id"]
    safety_item = client.post(
        f"/api/v1/safety-checks/{safety_id}/items",
        headers=producer_headers,
        json={"label": "Fire exit marked", "detail": "Confirm clear exits"},
    )
    assert safety_item.status_code == 201, safety_item.text

    incident = client.post(
        "/api/v1/incidents",
        headers=producer_headers,
        json={
            "project_id": project_id,
            "title": "Minor trip hazard",
            "severity": "low",
            "occurred_at": "2026-08-01T08:00:00Z",
            "parties": "Crew",
            "description": "Cable crossed walkway.",
            "corrective_action": "Cable ramp installed.",
        },
    )
    assert incident.status_code == 201, incident.text

    check_in = client.post(
        "/api/v1/safety-check-ins",
        headers=actor_headers,
        json={"booking_id": booking_id, "scheduled_at": "2026-08-01T02:30:00Z"},
    )
    assert check_in.status_code == 201, check_in.text
    check_in_id = check_in.json["data"]["check_in"]["public_id"]
    completed = client.post(
        f"/api/v1/safety-check-ins/{check_in_id}/complete",
        headers=actor_headers,
        json={"latitude": "31.5204", "longitude": "74.3587"},
    )
    assert completed.status_code == 200, completed.text
    assert completed.json["data"]["check_in"]["status"] == "checked_in"
