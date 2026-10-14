"""Private form inputs survive save/reload and are encrypted at rest."""

from sqlalchemy import select

from app.extensions import db
from app.models.insurance import InsurancePartnerProfile
from app.models.operations import EquipmentItem, LocationProperty, SafetyCheckIn
from app.models.specialist import AgencyInvitation, BrandProfile, DistributorContact
from app.services.private_fields import decrypt_private_value
from tests.unit.test_admin_workflows import admin_world as admin_world
from tests.unit.test_missing_workflow_records import (
    workflow_headers as workflow_headers,
)


def api(client, headers, method, path, payload=None, expected=200):
    response = client.open(
        "/api/v1" + path, method=method, headers=headers, json=payload
    )
    assert response.status_code == expected, response.text
    return response.json.get("data")


def test_private_location_address_round_trip_and_space_updates(
    client, app, admin_world
):
    h = admin_world["actor"]["headers"]
    address = "Building 47, private entrance. " * 30
    row = api(
        client,
        h,
        "POST",
        "/location-properties",
        {"name": "QA studio", "private_address": address},
        201,
    )["property"]
    path = "/location-properties/" + row["public_id"]
    assert row["private_address"] == address.strip()
    assert (
        api(client, h, "GET", "/location-properties")["properties"][0][
            "private_address"
        ]
        == address.strip()
    )
    api(
        client,
        admin_world["support"]["headers"],
        "PATCH",
        path,
        {"name": "Intruder"},
        404,
    )
    with app.app_context():
        saved = db.session.scalar(select(LocationProperty))
        assert saved.private_address_token.startswith("fernet:v2:")
        assert address.strip() == decrypt_private_value(saved.private_address_token)
    row = api(
        client,
        h,
        "PATCH",
        path,
        {
            "name": "Updated studio",
            "property_type": "studio",
            "area_name": "QA area",
            "public_address": "Public area",
            "description": "Updated",
            "capacity": 20,
            "parking_spaces": 2,
            "power_backup": True,
            "accessible": True,
            "status": "published",
        },
    )["property"]
    assert row["capacity"] == 20 and row["power_backup"] is True
    space = api(
        client, h, "POST", path + "/spaces", {"name": "Main floor", "capacity": 10}, 201
    )["space"]
    changed = api(
        client,
        h,
        "PATCH",
        "/location-spaces/" + space["public_id"],
        {
            "name": "Upstairs",
            "space_type": "interior",
            "capacity": 15,
            "area_sqft": 300,
            "description": "Daylight",
        },
    )["space"]
    assert changed["capacity"] == 15 and changed["area_sqft"] == 300
    api(client, h, "PATCH", "/location-spaces/" + space["public_id"], {"name": ""}, 422)
    rate = api(
        client,
        h,
        "POST",
        path + "/pricing",
        {"label": "Day rate", "amount_minor": 1000},
        201,
    )["pricing"]
    changed = api(
        client,
        h,
        "PATCH",
        "/location-pricing/" + rate["public_id"],
        {
            "label": "Half day",
            "amount_minor": 500,
            "currency": "PKR",
            "unit": "half_day",
            "enabled": False,
            "conditions": "Four hours",
        },
    )["pricing"]
    assert changed["amount_minor"] == 500 and changed["enabled"] is False
    api(
        client,
        h,
        "PATCH",
        "/location-pricing/" + rate["public_id"],
        {"amount_minor": -1},
        422,
    )
    rule = api(client, h, "POST", path + "/rules", {"label": "Night shoots"}, 201)[
        "rule"
    ]
    changed = api(
        client,
        h,
        "PATCH",
        "/location-rules/" + rule["public_id"],
        {
            "label": "No night shoots",
            "rule_type": "noise",
            "note": "Residential",
            "allowed": False,
        },
    )["rule"]
    assert changed["allowed"] is False
    api(client, h, "PATCH", "/location-rules/" + rule["public_id"], {"label": ""}, 422)
    assert (
        api(client, h, "PATCH", path, {"private_address": ""})["property"][
            "private_address"
        ]
        is None
    )


def test_equipment_serial_survives_edit_and_is_owner_scoped(client, app, admin_world):
    h = admin_world["actor"]["headers"]
    api(client, h, "PATCH", "/equipment/provider-profile", {"name": "QA rental"})
    row = api(
        client,
        h,
        "POST",
        "/equipment/items",
        {
            "model_name": "QA camera",
            "category": "Camera",
            "serial": "PRIVATE-SERIAL-01",
        },
        201,
    )["item"]
    assert row["serial"] == "PRIVATE-SERIAL-01"
    row = api(
        client,
        h,
        "PATCH",
        "/equipment/items/" + row["public_id"],
        {
            "serial": "PRIVATE-SERIAL-02",
            "condition": "good",
            "day_rate_minor": 1000,
            "deposit_minor": 2000,
            "status": "maintenance",
        },
    )["item"]
    assert row["serial"] == "PRIVATE-SERIAL-02"
    assert (
        api(client, h, "GET", "/equipment/items")["items"][0]["serial"]
        == "PRIVATE-SERIAL-02"
    )
    with app.app_context():
        saved = db.session.scalar(select(EquipmentItem))
        assert saved.serial_token.startswith("fernet:v2:")
    assert (
        api(client, admin_world["support"]["headers"], "GET", "/equipment/items")[
            "items"
        ]
        == []
    )


def test_licence_billing_contacts_and_invitation_values_persist(
    client, app, workflow_headers
):
    h = workflow_headers
    licence = "QA-LICENCE-123"
    profile = api(
        client,
        h,
        "PATCH",
        "/insurance/profile",
        {"name": "QA insurer", "license_number": licence},
    )["profile"]
    assert profile["license_number"] == licence
    assert (
        api(client, h, "GET", "/insurance/profile")["profile"]["license_number"]
        == licence
    )
    billing = "Private billing address " * 40
    assert (
        api(
            client,
            h,
            "PATCH",
            "/brands/profile",
            {"name": "QA Brand", "billing_details": billing},
        )["brand"]["billing_details"]
        == billing.strip()
    )
    assert (
        api(client, h, "GET", "/brands/profile")["brand"]["billing_details"]
        == billing.strip()
    )
    api(client, h, "PATCH", "/distribution/profile", {"name": "QA Distributor"})
    contact = api(
        client,
        h,
        "POST",
        "/distributor-contacts",
        {"name": "QA Contact", "email": "qa@example.com", "phone": "+923001234567"},
        201,
    )["contact"]
    assert contact["email"] == "qa@example.com" and contact["phone"] == "+923001234567"
    updated = api(
        client,
        h,
        "PATCH",
        "/distributor-contacts/" + contact["public_id"],
        {"email": "updated@example.com", "phone": ""},
    )["contact"]
    assert updated["email"] == "updated@example.com" and updated["phone"] is None
    assert (
        api(client, h, "GET", "/distributor-contacts")["contacts"][0]["email"]
        == "updated@example.com"
    )
    api(client, h, "PATCH", "/agencies/profile", {"name": "QA Agency"})
    invite = api(
        client, h, "POST", "/agency-invitations", {"contact": "talent@example.com"}, 201
    )["invitation"]
    assert invite["contact"] == "talent@example.com"
    assert (
        api(client, h, "GET", "/agency-invitations")["invitations"][0]["contact"]
        == "talent@example.com"
    )
    with app.app_context():
        for model, field, plain in [
            (InsurancePartnerProfile, "license_number_token", licence),
            (BrandProfile, "billing_token", billing.strip()),
            (DistributorContact, "email_token", "updated@example.com"),
            (AgencyInvitation, "contact_token", "talent@example.com"),
        ]:
            saved = db.session.scalar(select(model))
            cipher = getattr(saved, field)
            assert cipher.startswith("fernet:v2:") and plain == decrypt_private_value(
                cipher
            )


def test_zero_coordinates_are_stored_and_invalid_location_is_rejected(
    client, app, admin_world
):
    h = admin_world["admin"]["headers"]
    row = api(
        client,
        h,
        "POST",
        "/safety-check-ins",
        {"booking_id": admin_world["booking"], "scheduled_at": "2026-11-01T10:00:00Z"},
        201,
    )["check_in"]
    path = "/safety-check-ins/" + row["public_id"] + "/complete"
    for payload in [
        {"latitude": 91},
        {"longitude": 181},
        {"latitude": "NaN"},
        {"latitude": "bad"},
        {"latitude": True},
    ]:
        api(client, h, "POST", path, payload, 422)
    api(client, admin_world["support"]["headers"], "POST", path, {}, 404)
    api(client, h, "POST", path, {"latitude": 0, "longitude": 0})
    with app.app_context():
        saved = db.session.scalar(select(SafetyCheckIn))
        assert decrypt_private_value(saved.latitude_token) == "0.0"
        assert decrypt_private_value(saved.longitude_token) == "0.0"


def test_legacy_placeholder_requires_reentry_and_oversize_input_is_rejected(
    client, app, admin_world
):
    h = admin_world["actor"]["headers"]
    row = api(client, h, "POST", "/location-properties", {"name": "QA location"}, 201)[
        "property"
    ]
    with app.app_context():
        saved = db.session.scalar(select(LocationProperty))
        saved.private_address_token = "encrypted:pending"
        db.session.commit()
    assert (
        api(client, h, "GET", "/location-properties")["properties"][0][
            "private_address"
        ]
        is None
    )
    for invalid in ["x" * 4001, ["invalid"]]:
        api(
            client,
            h,
            "PATCH",
            "/location-properties/" + row["public_id"],
            {"private_address": invalid},
            422,
        )
