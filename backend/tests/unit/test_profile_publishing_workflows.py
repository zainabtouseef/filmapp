"""Saved profile edits and publishing are gated by ownership and verification."""

import pytest
from sqlalchemy import select

from app.errors import APIError
from app.extensions import db
from app.models.files import FileAsset
from app.models.identity import Role, User, UserRole
from app.models.kyc import KycSubmission
from app.models.operations import EquipmentProviderProfile
from app.security import hash_password, issue_token_pair
from tests.unit.test_admin_workflows import admin_world as admin_world
from tests.unit.test_private_workflow_fields import api


def test_role_covers_are_independent_and_survive_profile_edits(
    client, app, admin_world
):
    headers = admin_world["actor"]["headers"]
    with app.app_context():
        actor = db.session.scalar(
            select(User).where(User.public_id == admin_world["actor"]["id"])
        )
        assert actor is not None
        file = FileAsset(
            owner_user_id=actor.id,
            storage_key="role-covers/actor.jpg",
            bucket="public",
            mime_type="image/jpeg",
            size_bytes=300,
            visibility="public",
            scan_status="clean",
            processing_status="ready",
            original_name="actor.jpg",
        )
        db.session.add(file)
        db.session.commit()
        file_id = file.public_id
    cover = api(
        client, headers, "PATCH", "/me/role-covers/actor_talent", {"file_id": file_id}
    )["cover"]
    assert cover["public_id"] == file_id
    assert "actor_talent" in api(client, headers, "GET", "/me/role-covers")["covers"]
    api(
        client,
        headers,
        "PATCH",
        "/me/profile",
        {"social_links": {"instagram": "actor"}, "profile_visibility": "public"},
    )
    assert "actor_talent" in api(client, headers, "GET", "/me/role-covers")["covers"]
    assert api(client, headers, "GET", "/me/profile")["profile"]["social_links"] == {
        "instagram": "actor"
    }
    api(
        client,
        headers,
        "PATCH",
        "/me/role-covers/director_producer",
        {"file_id": file_id},
        403,
    )
    api(
        client,
        admin_world["support"]["headers"],
        "PATCH",
        "/me/role-covers/support_agent",
        {"file_id": file_id},
        422,
    )


def test_profile_edits_reload_and_reject_invalid_social_links(client, admin_world):
    h = admin_world["actor"]["headers"]
    assert (
        api(client, h, "GET", "/me/profile")["profile"]["profile_visibility"]
        == "private"
    )
    payload = {
        "bio": "Working actor",
        "website_url": "https://example.com",
        "profile_visibility": "public",
        "social_links": {"instagram": "https://instagram.com/qa"},
        "avatar_file_id": "",
        "cover_file_id": "",
    }
    saved = api(client, h, "PATCH", "/me/profile", payload)["profile"]
    assert (
        saved["bio"] == payload["bio"]
        and saved["social_links"] == payload["social_links"]
    )
    assert api(client, h, "GET", "/me/profile")["profile"] == saved
    for invalid in [
        {"profile_visibility": "unknown"},
        {"social_links": []},
        {"social_links": {str(i): "x" for i in range(17)}},
        {"city_id": "MISSING"},
        {"avatar_file_id": "MISSING"},
        {"cover_file_id": "MISSING"},
    ]:
        api(client, h, "PATCH", "/me/profile", invalid, 422)
    assert api(client, h, "GET", "/me/profile")["profile"] == saved
    cleared = api(
        client,
        h,
        "PATCH",
        "/me/profile",
        {"social_links": {}, "bio": "", "profile_visibility": "private"},
    )["profile"]
    assert (
        cleared["bio"] is None
        and cleared["social_links"] == {}
        and cleared["profile_visibility"] == "private"
    )


def test_credit_editor_updates_all_saved_fields_and_enforces_owner(client, admin_world):
    h = admin_world["actor"]["headers"]
    api(client, h, "PATCH", "/talent/profile", {"screen_name": "QA Actor"})
    row = api(
        client,
        h,
        "POST",
        "/credits",
        {"title": "Film credit", "production_name": "QA Film"},
        201,
    )["item"]
    path = "/credits/" + row["public_id"]
    changes = {
        "title": "Updated film",
        "production_name": "QA Studio",
        "role_label": "Lead",
        "year": 2025,
        "description": "Lead role",
        "sort_order": 2,
        "cover_file_id": "",
    }
    saved = api(client, h, "PATCH", path, changes)["item"]
    for key in [
        "title",
        "production_name",
        "role_label",
        "year",
        "description",
        "sort_order",
    ]:
        assert saved[key] == changes[key]
    assert api(client, h, "GET", "/credits")["items"][0] == saved
    title_only = api(
        client,
        h,
        "POST",
        "/credits",
        {"title": "Twisted Sapnay"},
        201,
    )["item"]
    assert title_only["production_name"] == ""
    assert (
        api(client, h, "PATCH", path, {"production_name": ""})["item"][
            "production_name"
        ]
        == ""
    )
    for invalid in [
        {"title": ""},
        {"production_name": "A"},
        {"year": "bad"},
        {"cover_file_id": "MISSING"},
    ]:
        api(client, h, "PATCH", path, invalid, 422)
    api(client, admin_world["support"]["headers"], "PATCH", path, changes, 404)
    assert api(client, h, "DELETE", path)["deleted"] is True
    assert (
        api(client, h, "DELETE", "/credits/" + title_only["public_id"])["deleted"]
        is True
    )
    assert api(client, h, "GET", "/credits")["items"] == []


def test_equipment_publication_requires_verified_profile_and_keeps_one_listing(
    client, app, admin_world
):
    h = admin_world["actor"]["headers"]
    api(
        client,
        h,
        "PATCH",
        "/equipment/provider-profile",
        {"name": "QA Equipment", "bio": "Verified equipment hire company"},
    )
    api(
        client,
        h,
        "POST",
        "/equipment/items",
        {"model_name": "QA Camera", "day_rate_minor": 123400},
        201,
    )
    payload = {
        "listing_type": "equipment",
        "title": "QA Hire",
        "summary": "Professional production equipment",
        "pricing_mode": "fixed",
    }
    api(client, h, "POST", "/marketplace/listings", payload, 403)
    with app.app_context():
        profile = db.session.scalar(select(EquipmentProviderProfile))
        profile.verification_status = "approved"
        db.session.commit()
    for bad in [{"title": "x"}, {"summary": "x"}]:
        api(client, h, "POST", "/marketplace/listings", {**payload, **bad}, 422)
    first = api(client, h, "POST", "/marketplace/listings", payload, 201)["listing"]
    second = api(
        client,
        h,
        "POST",
        "/marketplace/listings",
        {**payload, "title": "Updated hire"},
        201,
    )["listing"]
    assert (
        first["public_id"] == second["public_id"] and second["title"] == "Updated hire"
    )
    assert second["price_from_minor"] == 123400


def test_crew_publication_requires_role_and_kyc_and_preserves_edits(
    client, app, admin_world
):
    h = admin_world["actor"]["headers"]
    payload = {
        "listing_type": "crew",
        "title": "QA Crew",
        "summary": "Experienced production crew",
        "price_from_minor": 80000,
        "pricing_mode": "fixed",
    }
    api(client, h, "POST", "/marketplace/listings", payload, 403)
    with app.app_context():
        user = db.session.scalar(
            select(User).where(User.public_id == admin_world["actor"]["id"])
        )
        role = Role(code="crew_service", name="Crew", portal_route="/crew")
        db.session.add(role)
        db.session.flush()
        db.session.add(UserRole(user_id=user.id, role_id=role.id, status="active"))
        db.session.commit()
        uid, rid = user.id, role.id
        actor_role = db.session.scalar(select(Role).where(Role.code == "actor_talent"))
        db.session.add(
            KycSubmission(user_id=uid, role_id=actor_role.id, status="approved")
        )
        db.session.commit()
    api(client, h, "POST", "/marketplace/listings", payload, 403)
    with app.app_context():
        db.session.add(KycSubmission(user_id=uid, role_id=rid, status="approved"))
        db.session.commit()
    for bad in [{"title": "x"}, {"summary": "x"}, {"price_from_minor": -1}]:
        api(client, h, "POST", "/marketplace/listings", {**payload, **bad}, 422)
    first = api(client, h, "POST", "/marketplace/listings", payload, 201)["listing"]
    second = api(
        client,
        h,
        "POST",
        "/marketplace/listings",
        {**payload, "price_from_minor": 90000},
        201,
    )["listing"]
    assert (
        first["public_id"] == second["public_id"]
        and second["price_from_minor"] == 90000
    )


def test_suspended_account_cannot_login_or_refresh_even_without_session_revoke(
    client, app, admin_world
):
    with app.test_request_context():
        user = db.session.scalar(
            select(User).where(User.public_id == admin_world["actor"]["id"])
        )
        user.password_hash = hash_password("StrongPass123!")
        tokens = issue_token_pair(user)
        user.status = "suspended"
        db.session.commit()
    api(
        client,
        {},
        "POST",
        "/auth/login",
        {"email": "actor@example.com", "password": "StrongPass123!"},
        403,
    )
    api(
        client,
        {},
        "POST",
        "/auth/refresh",
        {"refresh_token": tokens.refresh_token},
        401,
    )


def test_password_recovery_provider_failure_is_redacted_and_unknown_user_is_private(
    client, app, admin_world, monkeypatch
):
    monkeypatch.setattr("app.api.auth.reset_email_available", lambda: True)
    sent = []
    monkeypatch.setattr(
        "app.api.auth.send_password_reset_email",
        lambda email, token: sent.append((email, token)),
    )
    known = api(
        client, {}, "POST", "/auth/password/forgot", {"email": "actor@example.com"}
    )
    unknown = api(
        client, {}, "POST", "/auth/password/forgot", {"email": "unknown@example.com"}
    )
    assert known == unknown and known["accepted"] is True
    assert len(sent) == 1 and sent[0][0] == "actor@example.com" and len(sent[0][1]) > 20

    def fail(email, token):
        raise RuntimeError("secret-provider-credential " + token)

    monkeypatch.setattr("app.api.auth.send_password_reset_email", fail)
    response = client.post(
        "/api/v1/auth/password/forgot", json={"email": "actor@example.com"}
    )
    assert response.status_code == 503
    assert (
        "secret-provider-credential" not in response.text
        and sent[0][1] not in response.text
    )


def test_talent_availability_categories_save_and_invalid_values_preserve_profile(
    client, admin_world
):
    h = admin_world["actor"]["headers"]
    payload = {
        "screen_name": "QA Actor",
        "availability_categories": ["actor", "model", "influencer", "model"],
    }
    saved = api(client, h, "PATCH", "/talent/profile", payload)["talent_profile"]
    assert saved["availability_categories"] == ["actor", "model", "influencer"]
    assert (
        api(client, h, "GET", "/talent/profile")["talent_profile"][
            "availability_categories"
        ]
        == saved["availability_categories"]
    )
    for value in [[], {}, "actor", ["invalid"]]:
        api(
            client,
            h,
            "PATCH",
            "/talent/profile",
            {**payload, "availability_categories": value},
            422,
        )
    assert (
        api(client, h, "GET", "/talent/profile")["talent_profile"][
            "availability_categories"
        ]
        == saved["availability_categories"]
    )


@pytest.mark.parametrize("value", [[], {}])
@pytest.mark.parametrize(
    "module, name",
    [
        ("marketplace", "_optional_int"),
        ("projects", "_optional_int"),
        ("projects", "_optional_date"),
        ("bookings", "_optional_int"),
        ("bookings", "_optional_datetime"),
    ],
)
def test_malformed_json_fields_return_validation_errors(module, name, value):
    from importlib import import_module

    parser = getattr(import_module("app.api." + module), name)
    with pytest.raises(APIError) as error:
        parser(value, "field")
    assert error.value.status == 422
