from __future__ import annotations

import os
import uuid

import pytest
from flask.testing import FlaskClient

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        os.getenv("RUN_INTEGRATION_TESTS") != "1",
        reason="Set RUN_INTEGRATION_TESTS=1 with MySQL and Redis running.",
    ),
]


def _register(client: FlaskClient, role: str, name: str) -> tuple[dict[str, str], str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"credit-{uuid.uuid4().hex[:12]}@example.com",
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


def test_credit_entry_crud_flow(client: FlaskClient) -> None:
    headers, _ = _register(client, "actor_talent", "Credit Test Actor")
    profile = client.patch(
        "/api/v1/talent/profile",
        headers=headers,
        json={"screen_name": "Credit Test Actor"},
    )
    assert profile.status_code == 200, profile.text

    empty = client.get("/api/v1/credits?profile_type=talent", headers=headers)
    assert empty.status_code == 200, empty.text
    assert empty.json["data"]["items"] == []

    created = client.post(
        "/api/v1/credits",
        headers=headers,
        json={
            "profile_type": "talent",
            "title": "Hero — Lead Role",
            "production_name": "Ishq Nama (2023)",
            "role_label": "Lead Actor",
            "year": 2023,
            "description": "Played the lead role across 18 episodes.",
        },
    )
    assert created.status_code == 201, created.text
    item = created.json["data"]["item"]
    assert item["title"] == "Hero — Lead Role"
    assert item["production_name"] == "Ishq Nama (2023)"
    assert item["year"] == 2023
    credit_id = item["public_id"]

    listed = client.get("/api/v1/credits?profile_type=talent", headers=headers)
    assert listed.status_code == 200, listed.text
    assert len(listed.json["data"]["items"]) == 1

    missing_title = client.post(
        "/api/v1/credits",
        headers=headers,
        json={"profile_type": "talent", "title": "A", "production_name": "Something"},
    )
    assert missing_title.status_code == 422, missing_title.text

    updated = client.patch(
        f"/api/v1/credits/{credit_id}",
        headers=headers,
        json={"title": "Hero — Supporting Role", "year": 2024},
    )
    assert updated.status_code == 200, updated.text
    assert updated.json["data"]["item"]["title"] == "Hero — Supporting Role"
    assert updated.json["data"]["item"]["year"] == 2024

    other_headers, _ = _register(client, "actor_talent", "Other Actor")
    forbidden = client.patch(
        f"/api/v1/credits/{credit_id}",
        headers=other_headers,
        json={"title": "Hijacked"},
    )
    assert forbidden.status_code == 404, forbidden.text

    deleted = client.delete(f"/api/v1/credits/{credit_id}", headers=headers)
    assert deleted.status_code == 200, deleted.text

    after_delete = client.get("/api/v1/credits?profile_type=talent", headers=headers)
    assert after_delete.status_code == 200, after_delete.text
    assert after_delete.json["data"]["items"] == []


def test_credit_entry_cap_enforced(client: FlaskClient) -> None:
    headers, _ = _register(client, "location_owner", "Cap Test Owner")
    for index in range(20):
        response = client.post(
            "/api/v1/credits",
            headers=headers,
            json={
                "profile_type": "location",
                "title": f"Feature {index}",
                "production_name": f"Production {index}",
            },
        )
        assert response.status_code == 201, response.text

    over_cap = client.post(
        "/api/v1/credits",
        headers=headers,
        json={
            "profile_type": "location",
            "title": "One too many",
            "production_name": "Overflow Production",
        },
    )
    assert over_cap.status_code == 422, over_cap.text


def test_credit_entry_does_not_affect_portfolio_item_cap(client: FlaskClient) -> None:
    headers, _ = _register(client, "actor_talent", "Isolation Test Actor")
    profile = client.patch(
        "/api/v1/talent/profile",
        headers=headers,
        json={"screen_name": "Isolation Test Actor"},
    )
    assert profile.status_code == 200, profile.text

    # Fill the 3-photo PortfolioItem cap for talent via direct DB rows would
    # require a real clean/ready file; instead confirm a CreditEntry write
    # doesn't touch the portfolio_items table's count at all by checking the
    # portfolio endpoint stays empty after adding several credits.
    for index in range(3):
        response = client.post(
            "/api/v1/credits",
            headers=headers,
            json={
                "profile_type": "talent",
                "title": f"Role {index}",
                "production_name": f"Show {index}",
            },
        )
        assert response.status_code == 201, response.text

    portfolio = client.get("/api/v1/portfolio?profile_type=talent", headers=headers)
    assert portfolio.status_code == 200, portfolio.text
    assert portfolio.json["data"]["items"] == []

    credits = client.get("/api/v1/credits?profile_type=talent", headers=headers)
    assert credits.status_code == 200, credits.text
    assert len(credits.json["data"]["items"]) == 3
