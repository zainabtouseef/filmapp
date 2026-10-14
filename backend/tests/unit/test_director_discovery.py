"""Discovery exposes published records and preserves privacy across detail routes."""

import json

import pytest
from sqlalchemy import select

from app.extensions import db
from app.models.identity import User
from app.models.marketplace import (
    MarketplaceListing,
    ModelProfile,
    TalentProfile,
    UserProfile,
)
from app.models.operations import (
    EquipmentItem,
    EquipmentPackage,
    EquipmentProviderProfile,
    EquipmentTerm,
    LocationPricing,
    LocationProperty,
    LocationRule,
    LocationSpace,
)
from app.models.specialist import CastingAgency, DistributionPartnerProfile
from tests.unit.test_admin_workflows import admin_world as admin_world


@pytest.fixture
def discovery_world(app, admin_world):
    with app.app_context():
        user = db.session.scalar(
            select(User).where(User.public_id == admin_world["actor"]["id"])
        )
        talent = TalentProfile(
            user_id=user.id,
            screen_name="QA Talent",
            day_rate_minor=987654,
            availability_categories_json=json.dumps(["actor", "model", "influencer"]),
            social_links_json='{"instagram":"qa"}',
            skills_json='["Acting"]',
            age_range="25-35",
            height_cm=175,
            experience_years=3,
        )
        profile = UserProfile(
            user_id=user.id, bio="QA discovery profile", profile_visibility="public"
        )
        location = LocationProperty(
            owner_user_id=user.id,
            name="QA Studio",
            property_type="studio",
            status="published",
            private_address_token="PRIVATE-ADDRESS",
            public_address="Public Area",
            capacity=40,
        )
        equipment = EquipmentProviderProfile(
            user_id=user.id,
            name="QA Camera Rental",
            service_categories="Cameras, Lighting",
        )
        agency = CastingAgency(owner_user_id=user.id, name="QA Agency")
        distribution = DistributionPartnerProfile(
            user_id=user.id, name="QA Distributor", channels="Cinema", territories="PK"
        )
        db.session.add_all([talent, profile, location, equipment, agency, distribution])
        db.session.flush()
        model = ModelProfile(user_id=user.id, talent_profile_id=talent.id)
        db.session.add(model)
        db.session.flush()
        db.session.add_all(
            [
                LocationSpace(
                    property_id=location.id,
                    name="Main floor",
                    space_type="interior",
                    capacity=40,
                    area_sqft=2000,
                ),
                LocationPricing(
                    property_id=location.id, label="Day hire", amount_minor=10000
                ),
                LocationRule(
                    property_id=location.id,
                    rule_type="noise",
                    label="Quiet after 10",
                    allowed=False,
                ),
                EquipmentItem(
                    provider_profile_id=equipment.id,
                    category="Camera",
                    model_name="Camera A",
                    day_rate_minor=10000,
                ),
                EquipmentPackage(
                    provider_profile_id=equipment.id,
                    name="Camera kit",
                    price_minor=20000,
                    operator_included=True,
                ),
                EquipmentTerm(
                    provider_profile_id=equipment.id,
                    label="Deposit",
                    term_type="deposit",
                    amount_minor=1000,
                ),
            ]
        )
        ids = {
            "actor": talent.public_id,
            "influencer": talent.public_id,
            "model": model.public_id,
            "location": location.public_id,
            "equipment": equipment.public_id,
            "agency": agency.public_id,
            "distribution": distribution.public_id,
            "crew": "QA-CREW",
        }
        listings = {}
        for kind, public_id in ids.items():
            listing = MarketplaceListing(
                owner_user_id=user.id,
                listing_type=kind,
                profile_entity_id=public_id,
                title="QA " + kind,
                summary="QA service",
                visibility="public",
                moderation_status="approved",
                verification_status="unverified",
                price_from_minor=987654,
                pricing_mode="negotiable",
            )
            db.session.add(listing)
            db.session.flush()
            listings[kind] = listing.public_id
        db.session.commit()
        return {**admin_world, "profiles": ids, "listings": listings}


def test_all_discovery_details_use_live_profiles_and_private_rates(
    client, discovery_world
):
    w = discovery_world
    headers = w["admin"]["headers"]
    result = client.get("/api/v1/director/discovery?q=QA", headers=headers)
    assert result.status_code == 200, result.text
    items = result.json["data"]["discovery"]["items"]
    assert {r["kind"] for r in items} == set(w["profiles"])
    for kind, profile in w["profiles"].items():
        result = client.get(
            "/api/v1/director/discovery/" + kind + "/" + profile, headers=headers
        )
        assert result.status_code == 200, result.text
        item = result.json["data"]["item"]
        assert item["listing_id"] == w["listings"][kind] and item["sections"]
        assert item["verification_status"] == "unverified"
        assert "PRIVATE-ADDRESS" not in result.text
        if kind in {"actor", "model", "influencer"}:
            assert item["rate_from_minor"] is None and "987654" not in result.text
    assert (
        client.get("/api/v1/director/discovery?q=ZZZ-NO-MATCH", headers=headers).json[
            "data"
        ]["discovery"]["items"]
        == []
    )


@pytest.mark.parametrize(
    "kind",
    [
        "actor",
        "model",
        "influencer",
        "location",
        "equipment",
        "agency",
        "distribution",
        "crew",
    ],
)
def test_private_listing_cannot_be_recovered_through_profile_detail(
    client, app, discovery_world, kind
):
    w = discovery_world
    with app.app_context():
        row = db.session.scalar(
            select(MarketplaceListing).where(
                MarketplaceListing.public_id == w["listings"][kind]
            )
        )
        row.visibility = "private"
        db.session.commit()
    headers = w["admin"]["headers"]
    result = client.get("/api/v1/director/discovery?category=" + kind, headers=headers)
    assert result.status_code == 200, result.text
    assert result.json["data"]["discovery"]["items"] == []
    for identifier in [w["profiles"][kind], w["listings"][kind]]:
        result = client.get(
            "/api/v1/director/discovery/" + kind + "/" + identifier, headers=headers
        )
        assert result.status_code == 404, result.text


@pytest.mark.parametrize(
    "kind",
    [
        "actor",
        "model",
        "influencer",
        "location",
        "equipment",
        "agency",
        "distribution",
        "crew",
        "unknown",
    ],
)
def test_missing_discovery_details_return_404(client, admin_world, kind):
    result = client.get(
        "/api/v1/director/discovery/" + kind + "/MISSING",
        headers=admin_world["admin"]["headers"],
    )
    assert result.status_code == 404


def test_director_schedule_persists_and_rejects_invalid_dates(client, admin_world):
    headers = admin_world["admin"]["headers"]
    response = client.post(
        "/api/v1/projects",
        headers=headers,
        json={"title": "QA Schedule", "project_type": "film"},
    )
    assert response.status_code == 201, response.text
    project = response.json["data"]["project"]["public_id"]
    valid = {
        "project_id": project,
        "title": "Planning",
        "event_type": "meeting",
        "starts_at": "2026-11-01T10:00:00Z",
        "ends_at": "2026-11-01T11:00:00Z",
        "location": "QA office",
    }
    for change in [
        {"project_id": "missing"},
        {"title": "x"},
        {"event_type": "bad"},
        {"starts_at": "bad"},
        {"ends_at": "2026-11-01T09:00:00Z"},
        {"ends_at": "2026-11-02T11:00:00Z"},
    ]:
        response = client.post(
            "/api/v1/director/schedule", headers=headers, json={**valid, **change}
        )
        assert response.status_code == 422, response.text
    for title in ["Planning", "Follow-up"]:
        response = client.post(
            "/api/v1/director/schedule", headers=headers, json={**valid, "title": title}
        )
        assert response.status_code == 201, response.text
        assert response.json["data"]["event"]["title"] == title
    result = client.get("/api/v1/director/schedule", headers=headers)
    assert result.status_code == 200 and "Follow-up" in result.text


def test_public_buyer_cannot_alias_equipment_as_actor(client, app, discovery_world):
    from app.models.identity import Role, UserRole

    w = discovery_world
    with app.app_context():
        role = Role(
            code="general_public", name="Public buyer", portal_route="/marketplace"
        )
        db.session.add(role)
        db.session.flush()
        user = db.session.scalar(select(User).where(User.public_id == w["actor"]["id"]))
        db.session.add(UserRole(user_id=user.id, role_id=role.id, status="active"))
        db.session.commit()
    response = client.get(
        "/api/v1/director/discovery/actor/" + w["listings"]["equipment"],
        headers=w["actor"]["headers"],
    )
    assert response.status_code == 403
    response = client.get("/api/v1/director/discovery", headers=w["actor"]["headers"])
    assert {r["kind"] for r in response.json["data"]["discovery"]["items"]} <= {
        "actor",
        "model",
        "influencer",
    }
