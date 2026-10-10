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
