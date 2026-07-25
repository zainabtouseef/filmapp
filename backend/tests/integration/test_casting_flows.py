from __future__ import annotations

import os
import uuid
from datetime import UTC, datetime, timedelta

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


def _register(
    client: FlaskClient,
    role: str,
    name: str,
) -> tuple[dict[str, str], str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"casting-{uuid.uuid4().hex[:12]}@example.com",
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


def _ready_video(
    client: FlaskClient,
    user_public_id: str,
) -> str:
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        file = FileAsset(
            owner_user_id=user.id,
            storage_key=f"self-tapes/{uuid.uuid4().hex}.mp4",
            bucket="local-private",
            mime_type="video/mp4",
            size_bytes=32000,
            checksum_sha256="4" * 64,
            visibility="authorized",
            scan_status="clean",
            processing_status="ready",
            original_name="lead-role-self-tape.mp4",
        )
        db.session.add(file)
        db.session.commit()
        return file.public_id


def test_actor_director_casting_application_flow(client: FlaskClient) -> None:
    application_due_at = (datetime.now(UTC) + timedelta(days=30)).isoformat()
    audition_due_at = (datetime.now(UTC) + timedelta(days=14)).isoformat()
    director_headers, _ = _register(
        client,
        "director_producer",
        "Casting Producer",
    )
    actor_headers, actor_id = _register(
        client,
        "actor_talent",
        "Casting Actor",
    )
    other_actor_headers, _ = _register(
        client,
        "actor_talent",
        "Other Actor",
    )

    profile = client.patch(
        "/api/v1/talent/profile",
        headers=actor_headers,
        json={
            "screen_name": "Casting Actor",
            "age_range": "25-34",
            "height_cm": 178,
            "skills": ["Dramatic acting", "Improvisation"],
            "accents": ["Pakistani English"],
            "credits": [{"title": "Lead - North Star"}],
            "training": [{"title": "Screen acting workshop"}],
            "representation": {"agency_name": "Independent"},
            "social_links": {"instagram": "@castingactor"},
            "languages": [
                {"language": "Urdu", "proficiency": "native"},
                {"language": "English", "proficiency": "fluent"},
            ],
        },
    )
    assert profile.status_code == 200, profile.text
    assert profile.json["data"]["talent_profile"]["skills"][0] == "Dramatic acting"

    project = client.post(
        "/api/v1/projects",
        headers=director_headers,
        json={
            "title": "Shared Casting Film",
            "project_type": "feature",
            "status": "active",
        },
    )
    assert project.status_code == 201, project.text
    project_id = project.json["data"]["project"]["public_id"]
    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=director_headers,
        json={
            "category": "talent",
            "title": "Lead investigator",
            "summary": "Quiet intensity and strong Urdu dialogue.",
            "budget_min_minor": 25000000,
            "budget_max_minor": 35000000,
            "status": "open",
        },
    )
    assert requirement.status_code == 201, requirement.text
    role_id = requirement.json["data"]["requirement"]["public_id"]

    published = client.patch(
        f"/api/v1/casting/roles/{role_id}",
        headers=director_headers,
        json={
            "role_type": "Lead",
            "work_location": "Lahore",
            "audition_mode": "self_tape",
            "instructions": "Submit a natural-light dramatic read.",
            "eligibility": ["Playable age 25-34"],
            "casting_questions": ["Can you work in Lahore?"],
            "application_due_at": application_due_at,
            "contact_name": "Casting Producer",
            "publish": True,
        },
    )
    assert published.status_code == 200, published.text
    assert published.json["data"]["role"]["casting_questions"] == [
        "Can you work in Lahore?"
    ]

    roles = client.get("/api/v1/casting/roles", headers=actor_headers)
    assert roles.status_code == 200, roles.text
    assert roles.json["data"]["roles"][0]["public_id"] == role_id
    filtered_roles = client.get(
        "/api/v1/casting/roles?audition_mode=self_tape",
        headers=actor_headers,
    )
    assert filtered_roles.status_code == 200, filtered_roles.text
    assert filtered_roles.json["data"]["roles"][0]["public_id"] == role_id

    saved = client.post(
        f"/api/v1/casting/roles/{role_id}/save",
        headers=actor_headers,
    )
    assert saved.status_code == 201, saved.text
    assert saved.json["data"]["role"]["saved"] is True

    initial_video_id = _ready_video(client, actor_id)
    application = client.post(
        f"/api/v1/casting/roles/{role_id}/applications",
        headers=actor_headers,
        json={
            "cover_note": "My recent lead work matches the tone of this role.",
            "availability_note": "Available for the listed dates.",
            "answers": {"Can you work in Lahore?": "Yes"},
            "self_tape_file_id": initial_video_id,
            "submit": True,
        },
    )
    assert application.status_code == 201, application.text
    application_id = application.json["data"]["application"]["public_id"]
    assert application.json["data"]["application"]["status"] == "submitted"
    assert (
        application.json["data"]["application"]["self_tape_file"]["public_id"]
        == initial_video_id
    )

    duplicate = client.post(
        f"/api/v1/casting/roles/{role_id}/applications",
        headers=actor_headers,
        json={"submit": True},
    )
    assert duplicate.status_code == 409

    hidden = client.get(
        f"/api/v1/casting/applications/{application_id}",
        headers=other_actor_headers,
    )
    assert hidden.status_code == 404

    director_rows = client.get(
        f"/api/v1/director/projects/{project_id}/casting-applications",
        headers=director_headers,
    )
    assert director_rows.status_code == 200, director_rows.text
    assert director_rows.json["data"]["applications"][0]["status"] == "viewed"
    self_tape_link = client.post(
        f"/api/v1/files/{initial_video_id}/download-link",
        headers=director_headers,
    )
    assert self_tape_link.status_code == 200, self_tape_link.text
    assert "?token=" in self_tape_link.json["data"]["url"]
    hidden_self_tape_link = client.post(
        f"/api/v1/files/{initial_video_id}/download-link",
        headers=other_actor_headers,
    )
    assert hidden_self_tape_link.status_code == 404

    requested = client.patch(
        f"/api/v1/director/casting-applications/{application_id}",
        headers=director_headers,
        json={
            "status": "self_tape_requested",
            "audition_due_at": audition_due_at,
            "audition_instructions": "Upload one continuous take.",
            "audition_contact": "Casting Producer",
        },
    )
    assert requested.status_code == 200, requested.text
    assert requested.json["data"]["application"]["status"] == ("self_tape_requested")

    video_id = _ready_video(client, actor_id)
    self_tape = client.post(
        f"/api/v1/casting/applications/{application_id}/self-tape",
        headers=actor_headers,
        json={"file_id": video_id},
    )
    assert self_tape.status_code == 200, self_tape.text
    assert (
        self_tape.json["data"]["application"]["self_tape_file"]["public_id"] == video_id
    )

    conversation = client.post(
        f"/api/v1/casting/applications/{application_id}/conversation",
        headers=actor_headers,
    )
    assert conversation.status_code == 200, conversation.text
    assert conversation.json["data"]["conversation_id"].startswith("CONV")
