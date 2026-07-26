from __future__ import annotations

import os
import uuid
from datetime import UTC, datetime, timedelta

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
            "email": f"meet-{uuid.uuid4().hex[:12]}@example.com",
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


def _iso(days: int) -> str:
    return (datetime.now(UTC) + timedelta(days=days)).isoformat()


def _create_project(client: FlaskClient, director_headers: dict[str, str]) -> str:
    project = client.post(
        "/api/v1/projects",
        headers=director_headers,
        json={
            "title": "Meeting Scheduling Test Shoot",
            "project_type": "feature",
            "status": "active",
        },
    )
    assert project.status_code == 201, project.text
    return project.json["data"]["project"]["public_id"]


def test_casting_meeting_negotiation_propose_counter_accept(
    client: FlaskClient,
) -> None:
    director_headers, _ = _register(client, "director_producer", "Meeting Director")
    actor_headers, actor_id = _register(client, "actor_talent", "Meeting Actor")

    profile = client.patch(
        "/api/v1/talent/profile",
        headers=actor_headers,
        json={"screen_name": "Meeting Actor"},
    )
    assert profile.status_code == 200, profile.text

    project_id = _create_project(client, director_headers)
    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=director_headers,
        json={
            "category": "talent",
            "title": "Supporting role",
            "status": "open",
        },
    )
    assert requirement.status_code == 201, requirement.text
    role_id = requirement.json["data"]["requirement"]["public_id"]
    published = client.patch(
        f"/api/v1/casting/roles/{role_id}",
        headers=director_headers,
        json={"publish": True},
    )
    assert published.status_code == 200, published.text

    application = client.post(
        f"/api/v1/casting/roles/{role_id}/applications",
        headers=actor_headers,
        json={"cover_note": "Strong fit for this role.", "submit": True},
    )
    assert application.status_code == 201, application.text
    application_id = application.json["data"]["application"]["public_id"]

    # Director requests an audition — this seeds round 1 of the thread.
    requested = client.patch(
        f"/api/v1/director/casting-applications/{application_id}",
        headers=director_headers,
        json={
            "status": "audition_requested",
            "audition_at": _iso(7),
            "audition_location": "Studio A, Lahore",
        },
    )
    assert requested.status_code == 200, requested.text
    thread = requested.json["data"]["application"]["meeting_thread"]
    assert thread is not None
    assert thread["status"] == "open"
    round_1_id = thread["current_round"]["public_id"]
    assert thread["current_round"]["proposed_by"]["public_id"] != actor_id

    # Actor counter-proposes a different time instead of just confirming.
    countered = client.post(
        f"/api/v1/casting/applications/{application_id}/meetings/propose",
        headers=actor_headers,
        json={
            "meeting_at": _iso(9),
            "location": "Studio B, Lahore",
            "message": "Studio A doesn't work for me, can we do this instead?",
        },
    )
    assert countered.status_code == 201, countered.text
    countered_thread = countered.json["data"]["application"]["meeting_thread"]
    round_2 = countered_thread["current_round"]
    assert round_2["public_id"] != round_1_id
    assert round_2["proposed_by"]["public_id"] == actor_id
    assert round_2["status"] == "pending"
    # The superseded first round should show up in history as such.
    superseded = next(
        r for r in countered_thread["rounds"] if r["public_id"] == round_1_id
    )
    assert superseded["status"] == "superseded"

    # The actor cannot accept their own counter-proposal.
    self_accept = client.post(
        f"/api/v1/casting/applications/{application_id}/meetings/rounds/"
        f"{round_2['public_id']}/accept",
        headers=actor_headers,
    )
    assert self_accept.status_code == 403, self_accept.text

    # The director accepts it.
    accepted = client.post(
        f"/api/v1/director/casting-applications/{application_id}/meetings/rounds/"
        f"{round_2['public_id']}/accept",
        headers=director_headers,
    )
    assert accepted.status_code == 200, accepted.text
    accepted_application = accepted.json["data"]["application"]
    assert accepted_application["meeting_thread"]["status"] == "accepted"
    # Legacy flat display columns synced from the accepted round.
    assert accepted_application["audition"]["location"] == "Studio B, Lahore"
    assert accepted_application["audition"]["confirmed_at"] is not None


def test_casting_meeting_decline_and_repropose(client: FlaskClient) -> None:
    director_headers, _ = _register(
        client, "director_producer", "Decline Test Director"
    )
    actor_headers, _ = _register(client, "actor_talent", "Decline Test Actor")
    client.patch(
        "/api/v1/talent/profile",
        headers=actor_headers,
        json={"screen_name": "Decline Test Actor"},
    )

    project_id = _create_project(client, director_headers)
    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=director_headers,
        json={"category": "talent", "title": "Extra", "status": "open"},
    )
    role_id = requirement.json["data"]["requirement"]["public_id"]
    client.patch(
        f"/api/v1/casting/roles/{role_id}",
        headers=director_headers,
        json={"publish": True},
    )
    application = client.post(
        f"/api/v1/casting/roles/{role_id}/applications",
        headers=actor_headers,
        json={"cover_note": "Interested in this role.", "submit": True},
    )
    application_id = application.json["data"]["application"]["public_id"]

    requested = client.patch(
        f"/api/v1/director/casting-applications/{application_id}",
        headers=director_headers,
        json={"status": "audition_requested", "audition_at": _iso(5)},
    )
    round_id = requested.json["data"]["application"]["meeting_thread"]["current_round"][
        "public_id"
    ]

    declined = client.post(
        f"/api/v1/casting/applications/{application_id}/meetings/rounds/"
        f"{round_id}/decline",
        headers=actor_headers,
        json={"reason": "I have a conflict that day."},
    )
    assert declined.status_code == 200, declined.text
    declined_thread = declined.json["data"]["application"]["meeting_thread"]
    assert declined_thread["status"] == "open"
    declined_round = next(
        r for r in declined_thread["rounds"] if r["public_id"] == round_id
    )
    assert declined_round["status"] == "declined"
    assert declined_round["decline_reason"] == "I have a conflict that day."

    reproposed = client.post(
        f"/api/v1/director/casting-applications/{application_id}/meetings/propose",
        headers=director_headers,
        json={"meeting_at": _iso(10), "location": "Studio C"},
    )
    assert reproposed.status_code == 201, reproposed.text
    new_round_id = reproposed.json["data"]["application"]["meeting_thread"][
        "current_round"
    ]["public_id"]

    accepted = client.post(
        f"/api/v1/casting/applications/{application_id}/meetings/rounds/"
        f"{new_round_id}/accept",
        headers=actor_headers,
    )
    assert accepted.status_code == 200, accepted.text
    assert (
        accepted.json["data"]["application"]["meeting_thread"]["status"] == "accepted"
    )


def test_requirement_application_meeting_negotiation(client: FlaskClient) -> None:
    director_headers, _ = _register(client, "director_producer", "Visit Test Director")
    owner_headers, _ = _register(client, "location_owner", "Visit Test Owner")

    project_id = _create_project(client, director_headers)
    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=director_headers,
        json={
            "category": "location",
            "title": "Need a heritage property",
            "status": "open",
        },
    )
    requirement_id = requirement.json["data"]["requirement"]["public_id"]

    application = client.post(
        f"/api/v1/opportunities/roles/{requirement_id}/applications",
        headers=owner_headers,
        json={"cover_note": "My property matches this brief perfectly."},
    )
    assert application.status_code == 201, application.text
    application_id = application.json["data"]["application"]["public_id"]

    # Director requests a site visit — same generic mechanism as casting's
    # audition, seeding round 1 on first transition into meeting_requested.
    requested = client.patch(
        f"/api/v1/director/opportunity-applications/{application_id}",
        headers=director_headers,
        json={
            "status": "meeting_requested",
            "meeting_at": _iso(4),
            "meeting_location": "123 Heritage Lane, Lahore",
            "meeting_kind": "site_visit",
        },
    )
    assert requested.status_code == 200, requested.text
    thread = requested.json["data"]["application"]["meeting_thread"]
    assert thread is not None
    round_1 = thread["current_round"]
    assert round_1["meeting_kind"] == "site_visit"

    # Owner declines with a reason, then director re-proposes, owner accepts.
    declined = client.post(
        f"/api/v1/opportunities/applications/{application_id}/meetings/rounds/"
        f"{round_1['public_id']}/decline",
        headers=owner_headers,
        json={"reason": "Property is booked that day."},
    )
    assert declined.status_code == 200, declined.text

    reproposed = client.post(
        f"/api/v1/director/opportunity-applications/{application_id}/meetings/propose",
        headers=director_headers,
        json={
            "meeting_at": _iso(6),
            "location": "123 Heritage Lane, Lahore",
            "meeting_kind": "site_visit",
        },
    )
    assert reproposed.status_code == 201, reproposed.text
    round_2_id = reproposed.json["data"]["application"]["meeting_thread"][
        "current_round"
    ]["public_id"]

    # The director cannot accept their own re-proposal.
    self_accept = client.post(
        f"/api/v1/director/opportunity-applications/{application_id}/meetings/"
        f"rounds/{round_2_id}/accept",
        headers=director_headers,
    )
    assert self_accept.status_code == 403, self_accept.text

    accepted = client.post(
        f"/api/v1/opportunities/applications/{application_id}/meetings/rounds/"
        f"{round_2_id}/accept",
        headers=owner_headers,
    )
    assert accepted.status_code == 200, accepted.text
    accepted_application = accepted.json["data"]["application"]
    assert accepted_application["meeting_thread"]["status"] == "accepted"
    assert accepted_application["meeting"]["location"] == "123 Heritage Lane, Lahore"
    assert accepted_application["meeting"]["confirmed_at"] is not None

    # Single-application fetch (used by the provider-side detail screen).
    fetched = client.get(
        f"/api/v1/opportunities/applications/{application_id}",
        headers=owner_headers,
    )
    assert fetched.status_code == 200, fetched.text
    assert fetched.json["data"]["application"]["public_id"] == application_id

    # Another provider cannot see this application or its meetings.
    other_headers, _ = _register(client, "location_owner", "Other Owner")
    forbidden = client.get(
        f"/api/v1/opportunities/applications/{application_id}",
        headers=other_headers,
    )
    assert forbidden.status_code == 404, forbidden.text
