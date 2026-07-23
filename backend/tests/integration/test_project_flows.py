from __future__ import annotations

import os
import uuid

import pytest
from flask.testing import FlaskClient
from sqlalchemy import select

from app.extensions import db
from app.models.files import FileAsset
from app.models.identity import User

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        os.getenv("RUN_INTEGRATION_TESTS") != "1",
        reason="Set RUN_INTEGRATION_TESTS=1 with MySQL and Redis running.",
    ),
]


def _register_role(client: FlaskClient, role: str) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"project-{uuid.uuid4().hex[:12]}@example.com",
            "password": "StrongPass123!",
            "display_name": "Project Producer",
            "initial_role": role,
            "terms_version": "2026-07",
        },
    )
    assert response.status_code == 201, response.text
    token = response.json["data"]["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _file_for_current_user(client: FlaskClient, headers: dict[str, str]) -> str:
    me = client.get("/api/v1/me", headers=headers)
    assert me.status_code == 200, me.text
    user_public_id = me.json["data"]["public_id"]
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        file = FileAsset(
            owner_user_id=user.id,
            storage_key=f"projects/{uuid.uuid4().hex}.pdf",
            bucket="local-private",
            mime_type="application/pdf",
            size_bytes=12345,
            checksum_sha256="2" * 64,
            visibility="private",
            scan_status="clean",
            processing_status="ready",
            original_name="creative-brief.pdf",
        )
        db.session.add(file)
        db.session.commit()
        return file.public_id


def _public_image_for_current_user(client: FlaskClient, headers: dict[str, str]) -> str:
    me = client.get("/api/v1/me", headers=headers)
    assert me.status_code == 200, me.text
    user_public_id = me.json["data"]["public_id"]
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        file = FileAsset(
            owner_user_id=user.id,
            storage_key=f"project-covers/{uuid.uuid4().hex}.jpg",
            bucket="local-public",
            mime_type="image/jpeg",
            size_bytes=54321,
            checksum_sha256="3" * 64,
            visibility="public",
            scan_status="clean",
            processing_status="ready",
            original_name="project-cover.jpg",
        )
        db.session.add(file)
        db.session.commit()
        return file.public_id


def test_project_requirement_and_skills_flow(client: FlaskClient) -> None:
    headers = _register_role(client, "director_producer")
    cover_file_id = _public_image_for_current_user(client, headers)

    skills = client.get("/api/v1/skills?category=acting", headers=headers)
    assert skills.status_code == 200, skills.text
    drama_skill = next(
        item
        for item in skills.json["data"]["skills"]
        if item["public_id"] == "SKILL-ACT-DRAMA"
    )

    cities = client.get("/api/v1/cities")
    karachi = next(
        city
        for city in cities.json["data"]["cities"]
        if city["public_id"] == "CITY-KHI"
    )

    created = client.post(
        "/api/v1/projects",
        headers=headers,
        json={
            "title": "Aurora Biscuit TVC",
            "project_type": "tvc",
            "description": "Family kitchen campaign.",
            "city_id": karachi["public_id"],
            "start_date": "2026-07-18",
            "end_date": "2026-07-22",
            "status": "active",
            "estimated_budget_minor": 150000000,
            "currency": "PKR",
            "visibility": "private",
            "progress_percent": 10,
            "cover_file_id": cover_file_id,
        },
    )
    assert created.status_code == 201, created.text
    project = created.json["data"]["project"]
    assert project["title"] == "Aurora Biscuit TVC"
    assert project["cover_file"]["public_id"] == cover_file_id
    assert project["cover_file"]["public_url"].startswith("https://media.test/")
    assert project["members"][0]["permissions"]["manage_project"] is True
    project_id = project["public_id"]

    listed = client.get("/api/v1/projects", headers=headers)
    assert listed.status_code == 200
    assert any(
        row["public_id"] == project_id for row in listed.json["data"]["projects"]
    )

    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=headers,
        json={
            "category": "talent",
            "title": "Lead father",
            "summary": "Warm screen presence for family TVC.",
            "budget_min_minor": 15000000,
            "budget_max_minor": 20000000,
            "currency": "PKR",
            "start_date": "2026-07-19",
            "end_date": "2026-07-19",
            "status": "open",
            "skills": [
                {
                    "skill_id": drama_skill["public_id"],
                    "required": True,
                    "minimum_level": "intermediate",
                }
            ],
        },
    )
    assert requirement.status_code == 201, requirement.text
    requirement_payload = requirement.json["data"]["requirement"]
    requirement_id = requirement_payload["public_id"]
    assert requirement_payload["skills"][0]["skill"]["name"] == "Dramatic acting"

    updated_requirement = client.patch(
        f"/api/v1/requirements/{requirement_id}",
        headers=headers,
        json={
            "status": "filled",
            "skills": ["SKILL-ACT-DRAMA", "SKILL-LANG-URDU"],
        },
    )
    assert updated_requirement.status_code == 200, updated_requirement.text
    assert updated_requirement.json["data"]["requirement"]["status"] == "filled"
    assert len(updated_requirement.json["data"]["requirement"]["skills"]) == 2

    detail = client.get(f"/api/v1/projects/{project_id}", headers=headers)
    assert detail.status_code == 200
    assert (
        detail.json["data"]["project"]["requirements"][0]["public_id"] == requirement_id
    )

    updated_project = client.patch(
        f"/api/v1/projects/{project_id}",
        headers=headers,
        json={"progress_percent": 35, "status": "active"},
    )
    assert updated_project.status_code == 200
    assert updated_project.json["data"]["project"]["progress_percent"] == 35

    private_doc_id = _file_for_current_user(client, headers)
    rejected_cover = client.patch(
        f"/api/v1/projects/{project_id}",
        headers=headers,
        json={"cover_file_id": private_doc_id},
    )
    assert rejected_cover.status_code == 422
    assert "cover_file_id" in rejected_cover.json["error"]["fields"]


def test_project_role_and_member_scope(client: FlaskClient) -> None:
    actor_headers = _register_role(client, "actor_talent")
    producer_headers = _register_role(client, "director_producer")
    other_headers = _register_role(client, "director_producer")

    blocked = client.post(
        "/api/v1/projects",
        headers=actor_headers,
        json={"title": "Actor owned project", "project_type": "film"},
    )
    assert blocked.status_code == 403

    created = client.post(
        "/api/v1/projects",
        headers=producer_headers,
        json={"title": "Private slate", "project_type": "film"},
    )
    assert created.status_code == 201, created.text
    project_id = created.json["data"]["project"]["public_id"]

    not_found = client.get(f"/api/v1/projects/{project_id}", headers=other_headers)
    assert not_found.status_code == 404

    invalid = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=producer_headers,
        json={
            "category": "talent",
            "title": "Bad dates",
            "start_date": "2026-07-22",
            "end_date": "2026-07-18",
        },
    )
    assert invalid.status_code == 422


def test_project_room_and_file_linking(client: FlaskClient) -> None:
    headers = _register_role(client, "director_producer")
    file_id = _file_for_current_user(client, headers)

    created = client.post(
        "/api/v1/projects",
        headers=headers,
        json={"title": "Room project", "project_type": "film"},
    )
    assert created.status_code == 201, created.text
    project_id = created.json["data"]["project"]["public_id"]

    linked_file = client.post(
        f"/api/v1/projects/{project_id}/files",
        headers=headers,
        json={
            "file_id": file_id,
            "folder": "briefs",
            "label": "Approved creative brief",
            "sort_order": 1,
        },
    )
    assert linked_file.status_code == 201, linked_file.text
    assert linked_file.json["data"]["file"]["file"]["public_id"] == file_id

    relinked_file = client.post(
        f"/api/v1/projects/{project_id}/files",
        headers=headers,
        json={"file_id": file_id, "folder": "scripts", "label": "Updated brief"},
    )
    assert relinked_file.status_code == 200, relinked_file.text
    assert relinked_file.json["data"]["file"]["folder"] == "scripts"

    room_item = client.post(
        f"/api/v1/projects/{project_id}/room/items",
        headers=headers,
        json={
            "item_type": "decision",
            "title": "Final call time",
            "body": "7:30 AM call approved.",
            "linked_entity_type": "project_file",
            "linked_entity_id": linked_file.json["data"]["file"]["public_id"],
            "pinned": True,
        },
    )
    assert room_item.status_code == 201, room_item.text
    assert room_item.json["data"]["item"]["pinned_at"] is not None

    files = client.get(f"/api/v1/projects/{project_id}/files", headers=headers)
    assert files.status_code == 200
    assert files.json["data"]["files"][0]["label"] == "Updated brief"

    room = client.get(f"/api/v1/projects/{project_id}/room", headers=headers)
    assert room.status_code == 200
    assert room.json["data"]["room"]["files"][0]["file"]["public_id"] == file_id
    assert room.json["data"]["room"]["items"][0]["title"] == "Final call time"
