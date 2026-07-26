from __future__ import annotations

import os
import uuid

import pytest
from flask.testing import FlaskClient
from sqlalchemy import select

from app.extensions import db
from app.models.identity import Role, User
from app.models.kyc import KycSubmission

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
            "email": f"opp-{uuid.uuid4().hex[:12]}@example.com",
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


def _approve_kyc(client: FlaskClient, user_public_id: str, role_code: str) -> None:
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        role = db.session.execute(
            select(Role).where(Role.code == role_code)
        ).scalar_one()
        db.session.add(
            KycSubmission(
                user_id=user.id,
                role_id=role.id,
                status="approved",
                risk_level="low",
            )
        )
        db.session.commit()


def _create_project(client: FlaskClient, director_headers: dict[str, str]) -> str:
    project = client.post(
        "/api/v1/projects",
        headers=director_headers,
        json={
            "title": "Opportunities Test Shoot",
            "project_type": "feature",
            "status": "active",
        },
    )
    assert project.status_code == 201, project.text
    return project.json["data"]["project"]["public_id"]


def _create_requirement(
    client: FlaskClient,
    director_headers: dict[str, str],
    project_id: str,
    *,
    category: str,
    visibility: str = "all",
    required_documents: list[str] | None = None,
) -> str:
    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=director_headers,
        json={
            "category": category,
            "title": f"Need a {category} provider",
            "summary": "Test requirement.",
            "status": "open",
            "visibility": visibility,
            "quantity": 2,
            "required_documents": required_documents or [],
        },
    )
    assert requirement.status_code == 201, requirement.text
    body = requirement.json["data"]["requirement"]
    assert body["visibility"] == visibility
    assert body["quantity"] == 2
    return body["public_id"]


def test_location_provider_browses_and_applies_to_open_requirement(
    client: FlaskClient,
) -> None:
    director_headers, _ = _register(client, "director_producer", "Producer One")
    owner_headers, owner_id = _register(client, "location_owner", "Owner One")

    project_id = _create_project(client, director_headers)
    requirement_id = _create_requirement(
        client,
        director_headers,
        project_id,
        category="location",
        required_documents=["Property deed", "Insurance certificate"],
    )

    # Wrong provider role can't even see the category.
    other_headers, _ = _register(client, "equipment_provider", "Wrong Role")
    forbidden = client.get(
        "/api/v1/opportunities/roles?category=location", headers=other_headers
    )
    assert forbidden.status_code == 403, forbidden.text

    roles = client.get(
        "/api/v1/opportunities/roles?category=location", headers=owner_headers
    )
    assert roles.status_code == 200, roles.text
    assert roles.json["data"]["roles"][0]["public_id"] == requirement_id
    assert roles.json["data"]["roles"][0]["required_documents"] == [
        "Property deed",
        "Insurance certificate",
    ]

    saved = client.post(
        f"/api/v1/opportunities/roles/{requirement_id}/save", headers=owner_headers
    )
    assert saved.status_code == 201, saved.text

    application = client.post(
        f"/api/v1/opportunities/roles/{requirement_id}/applications",
        headers=owner_headers,
        json={"cover_note": "I have a great heritage property for this shoot."},
    )
    assert application.status_code == 201, application.text
    assert application.json["data"]["application"]["status"] == "submitted"
    application_id = application.json["data"]["application"]["public_id"]

    # Can't double-apply.
    duplicate = client.post(
        f"/api/v1/opportunities/roles/{requirement_id}/applications",
        headers=owner_headers,
        json={"cover_note": "Trying again."},
    )
    assert duplicate.status_code == 409, duplicate.text

    director_view = client.get(
        f"/api/v1/director/projects/{project_id}/opportunity-applications",
        headers=director_headers,
    )
    assert director_view.status_code == 200, director_view.text
    assert director_view.json["data"]["applications"][0]["status"] == "viewed"
    assert (
        director_view.json["data"]["applications"][0]["applicant"]["public_id"]
        == owner_id
    )

    shortlisted = client.patch(
        f"/api/v1/director/opportunity-applications/{application_id}",
        headers=director_headers,
        json={"status": "shortlisted"},
    )
    assert shortlisted.status_code == 200, shortlisted.text

    selected = client.patch(
        f"/api/v1/director/opportunity-applications/{application_id}",
        headers=director_headers,
        json={"status": "selected"},
    )
    assert selected.status_code == 200, selected.text
    assert selected.json["data"]["application"]["status"] == "selected"

    # Terminal state — no further transitions allowed.
    invalid_transition = client.patch(
        f"/api/v1/director/opportunity-applications/{application_id}",
        headers=director_headers,
        json={"status": "rejected"},
    )
    assert invalid_transition.status_code == 409, invalid_transition.text

    my_applications = client.get(
        "/api/v1/opportunities/applications", headers=owner_headers
    )
    assert my_applications.status_code == 200, my_applications.text
    assert my_applications.json["data"]["applications"][0]["status"] == "selected"


def test_verified_only_requirement_hides_from_unverified_providers(
    client: FlaskClient,
) -> None:
    director_headers, _ = _register(client, "director_producer", "Producer Two")
    provider_headers, provider_id = _register(
        client, "equipment_provider", "Equipment Owner"
    )

    project_id = _create_project(client, director_headers)
    requirement_id = _create_requirement(
        client,
        director_headers,
        project_id,
        category="equipment",
        visibility="verified_only",
    )

    roles = client.get(
        "/api/v1/opportunities/roles?category=equipment", headers=provider_headers
    )
    assert roles.status_code == 200, roles.text
    assert roles.json["data"]["roles"] == []

    blocked_apply = client.post(
        f"/api/v1/opportunities/roles/{requirement_id}/applications",
        headers=provider_headers,
        json={"cover_note": "I have the right camera package for this."},
    )
    assert blocked_apply.status_code == 403, blocked_apply.text

    _approve_kyc(client, provider_id, "equipment_provider")

    roles_after_kyc = client.get(
        "/api/v1/opportunities/roles?category=equipment", headers=provider_headers
    )
    assert roles_after_kyc.status_code == 200, roles_after_kyc.text
    assert roles_after_kyc.json["data"]["roles"][0]["public_id"] == requirement_id

    allowed_apply = client.post(
        f"/api/v1/opportunities/roles/{requirement_id}/applications",
        headers=provider_headers,
        json={"cover_note": "I have the right camera package for this."},
    )
    assert allowed_apply.status_code == 201, allowed_apply.text


def test_crew_provider_can_apply_and_manage_own_portfolio(
    client: FlaskClient,
) -> None:
    director_headers, _ = _register(client, "director_producer", "Producer Three")
    crew_headers, _ = _register(client, "crew_service", "Crew Member")

    project_id = _create_project(client, director_headers)
    requirement_id = _create_requirement(
        client, director_headers, project_id, category="crew"
    )

    application = client.post(
        f"/api/v1/opportunities/roles/{requirement_id}/applications",
        headers=crew_headers,
        json={"cover_note": "Ten years as a gaffer on feature productions."},
    )
    assert application.status_code == 201, application.text

    withdraw = client.post(
        f"/api/v1/opportunities/applications/"
        f"{application.json['data']['application']['public_id']}/withdraw",
        headers=crew_headers,
    )
    assert withdraw.status_code == 200, withdraw.text
    assert withdraw.json["data"]["application"]["status"] == "withdrawn"

    # profile_type='crew' portfolio is keyed off the user's own identity, no
    # dedicated crew profile row required.
    portfolio = client.get("/api/v1/portfolio?profile_type=crew", headers=crew_headers)
    assert portfolio.status_code == 200, portfolio.text
    assert portfolio.json["data"]["items"] == []


def test_model_category_uses_generic_opportunities_not_casting(
    client: FlaskClient,
) -> None:
    director_headers, _ = _register(client, "director_producer", "Producer Four")
    model_headers, model_id = _register(client, "model", "Model One")

    project_id = _create_project(client, director_headers)
    requirement_id = _create_requirement(
        client, director_headers, project_id, category="model"
    )

    # Not reachable via the talent-only casting.py roles list.
    talent_roles = client.get("/api/v1/casting/roles", headers=model_headers)
    assert talent_roles.status_code == 403, talent_roles.text

    roles = client.get(
        "/api/v1/opportunities/roles?category=model", headers=model_headers
    )
    assert roles.status_code == 200, roles.text
    assert roles.json["data"]["roles"][0]["public_id"] == requirement_id

    application = client.post(
        f"/api/v1/opportunities/roles/{requirement_id}/applications",
        headers=model_headers,
        json={"cover_note": "Strong portfolio for commercial campaigns."},
    )
    assert application.status_code == 201, application.text
    assert application.json["data"]["application"]["applicant"]["public_id"] == model_id
