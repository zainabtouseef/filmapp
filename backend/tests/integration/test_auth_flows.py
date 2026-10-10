from __future__ import annotations

import os
import uuid
from datetime import timedelta

import pytest
from flask.testing import FlaskClient
from sqlalchemy import select

from app.extensions import db
from app.models.base import utc_now
from app.models.identity import PasswordResetToken, User, UserSession
from app.security import hash_token, new_opaque_token, verify_password

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        os.getenv("RUN_INTEGRATION_TESTS") != "1",
        reason="Set RUN_INTEGRATION_TESTS=1 with MySQL and Redis running.",
    ),
]


def _email() -> str:
    return f"auth-{uuid.uuid4().hex[:12]}@example.com"


def _register(client: FlaskClient, *, email: str | None = None) -> dict:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email or _email(),
            "password": "StrongPass123!",
            "display_name": "Sara Ahmed",
            "initial_role": "actor_talent",
            "terms_version": "2026-07",
        },
    )
    assert response.status_code == 201, response.text
    return response.json["data"]


def test_register_login_refresh_roles_and_logout(client: FlaskClient) -> None:
    email = _email()
    registered = _register(client, email=email)

    assert registered["user"]["email"] == email
    assert registered["user"]["roles"][0]["code"] == "actor_talent"
    assert registered["tokens"]["token_type"] == "Bearer"

    duplicate = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "StrongPass123!",
            "display_name": "Sara Again",
            "initial_role": "actor_talent",
            "terms_version": "2026-07",
        },
    )
    assert duplicate.status_code == 409
    assert duplicate.json["error"]["code"] == "auth.email_taken"

    login = client.post(
        "/api/v1/auth/login",
        json={"email": email.upper(), "password": "StrongPass123!"},
    )
    assert login.status_code == 200, login.text
    login_data = login.json["data"]
    access_token = login_data["tokens"]["access_token"]
    refresh_token = login_data["tokens"]["refresh_token"]

    me = client.get(
        "/api/v1/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me.status_code == 200
    assert me.json["data"]["public_id"] == registered["user"]["public_id"]

    add_role = client.post(
        "/api/v1/me/roles",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"role": "director_producer"},
    )
    assert add_role.status_code == 201, add_role.text
    assert {role["code"] for role in add_role.json["data"]} == {
        "actor_talent",
        "director_producer",
    }

    switch = client.patch(
        "/api/v1/me/primary-role",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"role": "director_producer"},
    )
    assert switch.status_code == 200
    primary = [role for role in switch.json["data"]["roles"] if role["is_primary"]]
    assert primary[0]["code"] == "director_producer"

    refresh = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh.status_code == 200, refresh.text
    rotated = refresh.json["data"]["tokens"]["refresh_token"]
    assert rotated != refresh_token

    old_refresh = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert old_refresh.status_code == 401
    logout = client.post("/api/v1/auth/logout", json={"refresh_token": rotated})
    assert logout.status_code == 200
    assert logout.json["data"]["revoked"] is True

    after_logout = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": rotated},
    )
    assert after_logout.status_code == 401


def test_password_reset_updates_password_hash(client: FlaskClient) -> None:
    email = _email()
    registered = _register(client, email=email)
    with client.application.app_context():
        user = db.session.execute(select(User).where(User.email == email)).scalar_one()
        token = new_opaque_token()
        db.session.add(
            PasswordResetToken(
                user_id=user.id,
                token_hash=hash_token(token),
                expires_at=utc_now() + timedelta(hours=1),
            )
        )
        db.session.commit()

    response = client.post(
        "/api/v1/auth/password/reset",
        json={"token": token, "new_password": "NewStrongPass123!"},
    )

    assert response.status_code == 200, response.text
    old_refresh = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": registered["tokens"]["refresh_token"]},
    )
    assert old_refresh.status_code == 401
    reused = client.post(
        "/api/v1/auth/password/reset",
        json={"token": token, "new_password": "AnotherStrongPass123!"},
    )
    assert reused.status_code == 401
    old_access = client.get(
        "/api/v1/me",
        headers={"Authorization": f"Bearer {registered['tokens']['access_token']}"},
    )
    assert old_access.status_code == 401
    new_login = client.post(
        "/api/v1/auth/login", json={"email": email, "password": "NewStrongPass123!"}
    )
    assert new_login.status_code == 200
    new_token = new_login.json["data"]["tokens"]["access_token"]
    new_access = client.get(
        "/api/v1/me", headers={"Authorization": f"Bearer {new_token}"}
    )
    assert new_access.status_code == 200
    with client.application.app_context():
        user = db.session.execute(select(User).where(User.email == email)).scalar_one()
        assert verify_password(user.password_hash, "NewStrongPass123!")


def test_authenticated_user_can_read_and_update_settings(
    client: FlaskClient,
) -> None:
    registered = _register(client)
    headers = {"Authorization": f"Bearer {registered['tokens']['access_token']}"}

    initial = client.get("/api/v1/me/settings", headers=headers)
    assert initial.status_code == 200, initial.text
    assert initial.json["data"] == {
        "timezone": "Asia/Karachi",
        "locale": "en-PK",
        "notifications": {
            "email_enabled": True,
            "sms_enabled": False,
            "push_enabled": True,
        },
    }

    updated = client.patch(
        "/api/v1/me/settings",
        headers=headers,
        json={
            "locale": "ur-Latn-PK",
            "timezone": "Asia/Karachi",
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

    invalid_locale = client.patch(
        "/api/v1/me/settings", headers=headers, json={"locale": "xx-YY"}
    )
    assert invalid_locale.status_code == 422
    assert "locale" in invalid_locale.json["error"]["fields"]

    invalid_notification = client.patch(
        "/api/v1/me/settings",
        headers=headers,
        json={"notifications": {"push_enabled": "yes"}},
    )
    assert invalid_notification.status_code == 422
    assert "notifications.push_enabled" in invalid_notification.json["error"]["fields"]


def test_login_rejects_bad_password_and_records_session_only_on_success(
    client: FlaskClient,
) -> None:
    email = _email()
    _register(client, email=email)

    bad_login = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "wrong-password"},
    )
    assert bad_login.status_code == 401

    with client.application.app_context():
        user = db.session.execute(select(User).where(User.email == email)).scalar_one()
        sessions = db.session.execute(
            select(UserSession).where(UserSession.user_id == user.id)
        ).scalars()
        assert len(list(sessions)) == 1
