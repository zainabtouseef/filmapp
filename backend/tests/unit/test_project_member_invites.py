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


def _register(client: FlaskClient, *, display_name: str) -> tuple[dict[str, str], str]:
    email = f"member-{uuid.uuid4().hex[:12]}@example.com"
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "StrongPass123!",
            "display_name": display_name,
            "initial_role": "director_producer",
            "terms_version": "2026-07",
        },
    )
    assert response.status_code == 201, response.text
    token = response.json["data"]["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}, email


def test_project_owner_can_add_existing_user_but_member_cannot_invite(
    client: FlaskClient,
) -> None:
    owner, _ = _register(client, display_name="Project Owner")
    member_headers, member_email = _register(client, display_name="Co Producer")
    _, third_email = _register(client, display_name="Third Producer")
    created = client.post(
        "/api/v1/projects",
        headers=owner,
        json={
            "title": "Member invite unit project",
            "project_type": "film",
            "status": "draft",
            "visibility": "project_members",
        },
    )
    assert created.status_code == 201, created.text
    project_id = created.json["data"]["project"]["public_id"]

    invited = client.post(
        f"/api/v1/projects/{project_id}/members",
        headers=owner,
        json={
            "email": member_email,
            "role_label": "Co-producer",
            "can_edit_project": True,
        },
    )
    assert invited.status_code == 201, invited.text
    assert invited.json["data"]["member"]["user"]["display_name"] == "Co Producer"
    assert invited.json["data"]["member"]["permissions"]["manage_project"] is True
    assert invited.json["data"]["member"]["permissions"]["manage_members"] is False

    visible = client.get(f"/api/v1/projects/{project_id}", headers=member_headers)
    assert visible.status_code == 200
    forbidden = client.post(
        f"/api/v1/projects/{project_id}/members",
        headers=member_headers,
        json={"email": third_email, "role_label": "Co-producer"},
    )
    assert forbidden.status_code == 403
