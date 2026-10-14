from __future__ import annotations

import uuid

import pytest
from flask import Flask
from flask.testing import FlaskClient

from app.api.app import ROLES
from app.extensions import db
from app.models.identity import Role


@pytest.fixture(autouse=True)
def _seed_roles(app: Flask) -> None:
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
        db.session.commit()


def _register(client: FlaskClient) -> dict:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"settings-{uuid.uuid4().hex[:12]}@example.com",
            "password": "StrongPass123!",
            "display_name": "Settings User",
            "initial_role": "actor_talent",
            "terms_version": "2026-07",
        },
    )
    assert response.status_code == 201, response.text
    return response.json["data"]


def test_user_settings_are_persisted_and_validated(client: FlaskClient) -> None:
    registered = _register(client)
    headers = {"Authorization": f"Bearer {registered['tokens']['access_token']}"}

    initial = client.get("/api/v1/me/settings", headers=headers)
    assert initial.status_code == 200, initial.text
    assert initial.json["data"]["locale"] == "en-PK"
    assert initial.json["data"]["notifications"] == {
        "email_enabled": True,
        "sms_enabled": False,
        "push_enabled": True,
    }

    updated = client.patch(
        "/api/v1/me/settings",
        headers=headers,
        json={
            "locale": "ur-Latn-PK",
            "notifications": {
                "email_enabled": False,
                "sms_enabled": True,
                "push_enabled": False,
            },
        },
    )
    assert updated.status_code == 200, updated.text
    assert updated.json["data"]["locale"] == "ur-Latn-PK"
    assert updated.json["data"]["notifications"] == {
        "email_enabled": False,
        "sms_enabled": True,
        "push_enabled": False,
    }

    persisted = client.get("/api/v1/me/settings", headers=headers)
    assert persisted.status_code == 200
    assert persisted.json["data"] == updated.json["data"]

    invalid = client.patch(
        "/api/v1/me/settings",
        headers=headers,
        json={"notifications": {"push_enabled": "yes"}},
    )
    assert invalid.status_code == 422
    assert "notifications.push_enabled" in invalid.json["error"]["fields"]


def test_profile_and_active_session_management(client: FlaskClient) -> None:
    registered = _register(client)
    first_headers = {
        "Authorization": f"Bearer {registered['tokens']['access_token']}",
        "User-Agent": "CineConnect Test Chrome",
    }

    updated = client.patch(
        "/api/v1/me",
        headers=first_headers,
        json={"display_name": "Updated Settings User"},
    )
    assert updated.status_code == 200, updated.text
    assert updated.json["data"]["display_name"] == "Updated Settings User"
    invalid = client.patch(
        "/api/v1/me", headers=first_headers, json={"display_name": "x"}
    )
    assert invalid.status_code == 422, invalid.text

    second = client.post(
        "/api/v1/auth/login",
        headers={"User-Agent": "CineConnect Test Safari"},
        json={
            "email": registered["user"]["email"],
            "password": "StrongPass123!",
        },
    )
    assert second.status_code == 200, second.text
    sessions = client.get("/api/v1/me/sessions", headers=first_headers)
    assert sessions.status_code == 200, sessions.text
    assert len(sessions.json["data"]["sessions"]) == 2
    assert sum(row["is_current"] for row in sessions.json["data"]["sessions"]) == 1

    remote = next(
        row for row in sessions.json["data"]["sessions"] if not row["is_current"]
    )
    revoked = client.delete(
        f"/api/v1/me/sessions/{remote['id']}", headers=first_headers
    )
    assert revoked.status_code == 200, revoked.text
    assert revoked.json["data"] == {"revoked": True, "current": False}
    second_headers = {
        "Authorization": f"Bearer {second.json['data']['tokens']['access_token']}"
    }
    assert client.get("/api/v1/me", headers=second_headers).status_code == 401

    third = client.post(
        "/api/v1/auth/login",
        headers={"User-Agent": "CineConnect Test Mobile"},
        json={
            "email": registered["user"]["email"],
            "password": "StrongPass123!",
        },
    )
    assert third.status_code == 200, third.text
    revoke_others = client.post(
        "/api/v1/me/sessions/revoke-others", headers=first_headers
    )
    assert revoke_others.status_code == 200, revoke_others.text
    assert revoke_others.json["data"]["revoked_count"] == 1
    remaining = client.get("/api/v1/me/sessions", headers=first_headers)
    assert remaining.status_code == 200, remaining.text
    assert len(remaining.json["data"]["sessions"]) == 1
    assert remaining.json["data"]["sessions"][0]["is_current"] is True
    third_headers = {
        "Authorization": f"Bearer {third.json['data']['tokens']['access_token']}"
    }
    assert client.get("/api/v1/me", headers=third_headers).status_code == 401
    assert client.get("/api/v1/me", headers=first_headers).status_code == 200


def test_logout_invalidates_access_token_immediately(client: FlaskClient) -> None:
    registered = _register(client)
    headers = {"Authorization": f"Bearer {registered['tokens']['access_token']}"}
    assert (
        client.post(
            "/api/v1/auth/logout",
            json={"refresh_token": registered["tokens"]["refresh_token"]},
        ).status_code
        == 200
    )
    assert client.get("/api/v1/me", headers=headers).status_code == 401
