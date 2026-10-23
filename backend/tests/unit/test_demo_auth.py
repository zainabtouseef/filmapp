from __future__ import annotations

import pytest
from flask import Flask
from flask.testing import FlaskClient
from sqlalchemy import func, select

from app.config import Config
from app.extensions import db
from app.models.identity import (
    AuthSecurityEvent,
    Role,
    User,
    UserRole,
    UserSession,
    UserSettings,
)
from app.security import hash_password

KEY = "test-demo-capability-" + "a" * 64
PREFIX = "/api/v1/auth/demo"


@pytest.fixture
def demo(app: Flask) -> dict[str, str]:
    app.config.update(DEMO_ACCOUNT_PICKER_ENABLED=True, DEMO_ACCOUNT_PICKER_KEY=KEY)
    with app.app_context():
        director = Role(
            code="director_producer",
            name="Director / Producer",
            portal_route="/director/console",
            display_order=1,
        )
        actor = Role(
            code="actor_talent",
            name="Actor / Talent",
            portal_route="/actor/dashboard",
            display_order=2,
        )
        admin = Role(code="super_admin", name="Super Admin", portal_route="/admin")
        inactive = Role(
            code="inactive",
            name="Inactive",
            portal_route="/inactive",
            is_active=False,
        )
        db.session.add_all([director, actor, admin, inactive])
        users = {}
        for name, status, roles in [
            ("Director", "active", [director, actor]),
            ("Actor", "active", [actor]),
            ("Admin", "active", [admin]),
            ("Suspended", "suspended", [actor]),
            ("Unassigned", "active", []),
            ("Inactive", "active", [inactive]),
        ]:
            user = User(
                email=f"{name.lower()}@example.com",
                display_name=name,
                password_hash=hash_password("Demo-test-password-123"),
                status=status,
                terms_version="2026-07",
            )
            for index, role in enumerate(roles):
                user.roles.append(
                    UserRole(role=role, status="active", is_primary=index == 0)
                )
            db.session.add(user)
            db.session.flush()
            db.session.add(UserSettings(user_id=user.id))
            users[name] = user.public_id
        db.session.commit()
        return users


def test_disabled_by_default(client: FlaskClient) -> None:
    for endpoint in ("accounts", "login"):
        assert (
            client.post(f"{PREFIX}/{endpoint}", json={"access_key": KEY}).status_code
            == 404
        )


@pytest.mark.parametrize("key", [None, "", "wrong", "é" * 64, "x" * 257, [], {}])
def test_invalid_capability_is_rejected(
    app: Flask,
    client: FlaskClient,
    demo: dict[str, str],
    key: object,
) -> None:
    for endpoint in ("accounts", "login"):
        response = client.post(f"{PREFIX}/{endpoint}", json={"access_key": key})
        assert response.status_code == 404
        assert "categories" not in response.get_json()
    with app.app_context():
        assert db.session.scalar(select(func.count()).select_from(UserSession)) == 0


def test_directory_includes_all_accounts_and_active_role_categories(
    client: FlaskClient,
    demo: dict[str, str],
) -> None:
    response = client.post(f"{PREFIX}/accounts", json={"access_key": KEY})
    assert response.status_code == 200
    assert "no-store" in response.headers["Cache-Control"]
    assert "noindex" in response.headers["X-Robots-Tag"]
    data = response.get_json()["data"]
    assert data["total_accounts"] == 6
    groups = {group["code"]: group for group in data["categories"]}
    assert set(groups) == {
        "director_producer",
        "actor_talent",
        "super_admin",
        "unassigned",
    }
    assert len(groups["actor_talent"]["accounts"]) == 3
    accounts = [account for group in groups.values() for account in group["accounts"]]
    assert {account["public_id"] for account in accounts} == set(demo.values())
    assert all(not account["can_login"] for account in groups["unassigned"]["accounts"])
    assert not next(a for a in accounts if a["public_id"] == demo["Suspended"])[
        "can_login"
    ]
    assert KEY not in response.text
    assert "password" not in response.text


@pytest.mark.parametrize(
    "name,role",
    [
        ("Actor", "super_admin"),
        ("Suspended", "actor_talent"),
        ("Unassigned", "actor_talent"),
        ("Inactive", "inactive"),
    ],
)
def test_role_escalation_and_unavailable_accounts_are_rejected(
    client: FlaskClient,
    demo: dict[str, str],
    name: str,
    role: str,
) -> None:
    response = client.post(
        f"{PREFIX}/login",
        json={
            "access_key": KEY,
            "user_id": demo[name],
            "role_code": role,
        },
    )
    assert response.status_code == 403


def test_login_uses_selected_role_and_regular_session_lifecycle(
    app: Flask,
    client: FlaskClient,
    demo: dict[str, str],
) -> None:
    response = client.post(
        f"{PREFIX}/login",
        json={
            "access_key": KEY,
            "user_id": demo["Director"],
            "role_code": "actor_talent",
        },
    )
    assert response.status_code == 200
    data = response.get_json()["data"]
    assert data["user"]["public_id"] == demo["Director"]
    assert [r["code"] for r in data["user"]["roles"] if r["is_primary"]] == [
        "actor_talent"
    ]
    with app.app_context():
        user = db.session.scalar(select(User).where(User.public_id == demo["Director"]))
        assert user is not None
        settings = db.session.scalar(
            select(UserSettings).where(UserSettings.user_id == user.id)
        )
        assert settings is not None and settings.active_role_code == "actor_talent"
        event = db.session.scalar(
            select(AuthSecurityEvent).where(
                AuthSecurityEvent.event_type == "demo_login"
            )
        )
        assert event is not None and event.success
        assert event.metadata_json == {"role": "actor_talent"}
    headers = {"Authorization": f"Bearer {data['tokens']['access_token']}"}
    assert client.get("/api/v1/me", headers=headers).status_code == 200
    refreshed = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": data["tokens"]["refresh_token"]}
    )
    assert refreshed.status_code == 200
    refresh = refreshed.get_json()["data"]["tokens"]["refresh_token"]
    assert (
        client.post("/api/v1/auth/logout", json={"refresh_token": refresh}).status_code
        == 200
    )
    assert (
        client.post("/api/v1/auth/refresh", json={"refresh_token": refresh}).status_code
        == 401
    )
    # Demo access never changes the account's normal password.
    normal = client.post(
        "/api/v1/auth/login",
        json={
            "email": "director@example.com",
            "password": "Demo-test-password-123",
        },
    )
    assert normal.status_code == 200


def test_inactive_membership_cannot_log_in(
    app: Flask,
    client: FlaskClient,
    demo: dict[str, str],
) -> None:
    with app.app_context():
        user = db.session.scalar(select(User).where(User.public_id == demo["Actor"]))
        assert user is not None
        user.roles[0].status = "pending"
        db.session.commit()
    assert (
        client.post(
            f"{PREFIX}/login",
            json={
                "access_key": KEY,
                "user_id": demo["Actor"],
                "role_code": "actor_talent",
            },
        ).status_code
        == 403
    )


def test_enabling_demo_requires_a_strong_capability() -> None:
    with pytest.raises(RuntimeError, match="DEMO_ACCOUNT_PICKER_KEY"):
        Config.validate(
            {
                "APP_ENV": "development",
                "SQLALCHEMY_DATABASE_URI": "mysql+pymysql://user:pass@db/app",
                "DEMO_ACCOUNT_PICKER_ENABLED": True,
                "DEMO_ACCOUNT_PICKER_KEY": "short",
            }
        )
