"""Exercise persistent planning edits, reports and permissions against real models."""

import pytest
from sqlalchemy import select

from app.extensions import db
from app.models.identity import Role, User
from app.scripts.seed_cineplanner_demo import DEMO_EMAIL, seed
from app.security import issue_token_pair


@pytest.fixture
def production(app):
    with app.test_request_context():
        db.session.add(
            Role(code="director_producer", name="Producer", portal_route="/director")
        )
        db.session.commit()
        info = seed()
        owner = db.session.scalar(select(User).where(User.email == DEMO_EMAIL))
        outsider = User(
            email="outsider@example.com",
            display_name="Outsider",
            password_hash="fixture",
            terms_version="2026-10",
        )
        db.session.add(outsider)
        db.session.flush()
        headers = {"Authorization": "Bearer " + issue_token_pair(owner).access_token}
        other = {"Authorization": "Bearer " + issue_token_pair(outsider).access_token}
        db.session.commit()
        return {
            "path": "/api/v1/cineplanner/productions/" + info["production_id"],
            "headers": headers,
            "other": other,
            "user_id": outsider.public_id,
        }


def request(
    client, production, method, suffix="", payload=None, expected=200, other=False
):
    response = client.open(
        production["path"] + suffix,
        method=method,
        headers=production["other" if other else "headers"],
        json=payload,
    )
    assert response.status_code == expected, response.text
    return response.json["data"] if response.is_json and expected < 400 else response


def test_planner_location_element_crew_and_character_edits_round_trip(
    client, production
):
    p = production
    snapshot = request(client, p, "GET")
    request(client, p, "POST", "/locations", {}, expected=422)
    location = request(
        client,
        p,
        "POST",
        "/locations",
        {
            "screenplay_name": "QA Studio",
            "option_name": "Option A",
            "rental_rate_minor": 50000,
            "availability": [],
        },
        expected=201,
    )["location"]
    second = request(
        client,
        p,
        "POST",
        "/locations",
        {"screenplay_name": "QA Studio", "option_name": "Option B"},
        expected=201,
    )["location"]
    request(
        client,
        p,
        "PATCH",
        "/locations/" + location["public_id"],
        {"status": "confirmed"},
    )
    request(
        client, p, "PATCH", "/locations/" + second["public_id"], {"status": "confirmed"}
    )
    request(
        client,
        p,
        "POST",
        "/elements",
        {"category": "invented", "name": "X"},
        expected=422,
    )
    element = request(
        client,
        p,
        "POST",
        "/elements",
        {
            "category": "props",
            "name": "Ledger",
            "quantity": 2,
            "cost_rate_minor": 3000,
            "scene_numbers": ["1", "2"],
        },
        expected=201,
    )["element"]
    changed = request(
        client, p, "PATCH", "/elements/" + element["public_id"], {"quantity": 3}
    )["item"]
    assert changed["quantity"] == 3
    request(client, p, "POST", "/crew", {}, expected=422)
    crew = request(
        client,
        p,
        "POST",
        "/crew",
        {
            "name": "QA Grip",
            "department": "Camera",
            "job_title": "Grip",
            "daily_rate_minor": 20000,
            "availability": [],
        },
        expected=201,
    )["crew_member"]
    assert crew["daily_rate_minor"] == 20000
    character = snapshot["characters"][0]
    changed = request(
        client,
        p,
        "PATCH",
        "/characters/" + character["public_id"],
        {"name": "Updated lead", "languages": ["Urdu"]},
    )["item"]
    assert changed["name"] == "Updated lead" and changed["languages"] == ["Urdu"]
    fresh = request(client, p, "GET")
    locations = {row["public_id"]: row for row in fresh["locations"]}
    assert locations[location["public_id"]]["status"] == "option"
    assert locations[second["public_id"]]["status"] == "confirmed"
    assert any(
        row["public_id"] == element["public_id"] and row["quantity"] == 3
        for row in fresh["elements"]
    )
    assert request(client, p, "GET", "/audit-logs")["audit_logs"]


def test_planner_team_scope_protects_edit_and_financial_data(client, production):
    p = production
    request(client, p, "GET", other=True, expected=404)
    request(
        client,
        p,
        "POST",
        "/team",
        {"user_id": p["user_id"], "role": "invalid"},
        expected=422,
    )
    for role in ["crew", "view_only"]:
        member = request(
            client,
            p,
            "POST",
            "/team",
            {"user_id": p["user_id"], "role": role},
            expected=201,
        )["team_member"]
        assert member["role"] == role
    snapshot = request(client, p, "GET", other=True)
    assert snapshot["budget"] is None
    request(client, p, "PATCH", "", {"title": "Unauthorized"}, other=True, expected=403)
    request(client, p, "GET", "/budget", other=True, expected=403)
    request(client, p, "GET", "/reports/budget", other=True, expected=403)
    assert request(client, p, "GET", "/reports/scenes", other=True)["rows"]


def test_planner_report_formats_and_filtering(client, production):
    p = production
    for report in [
        "characters",
        "props",
        "wardrobe",
        "makeup",
        "vehicles",
        "equipment",
        "extras",
        "stunts",
        "vfx",
        "sfx",
        "shooting-schedule",
        "crew",
        "script-revisions",
        "production-progress",
    ]:
        data = request(client, p, "GET", "/reports/" + report)
        assert isinstance(data["rows"], list)
    for extension, signature in [("csv", None), ("xlsx", b"PK"), ("pdf", b"%PDF-")]:
        result = request(client, p, "GET", "/reports/characters." + extension)
        assert result.data and "attachment" in result.headers["Content-Disposition"]
        if signature:
            assert result.data.startswith(signature)
    request(client, p, "GET", "/reports/not-a-report", expected=404)
    request(client, p, "PATCH", "/unknown/missing", {}, expected=404)
    request(client, p, "PATCH", "/characters/missing", {}, expected=404)


def test_planner_casting_and_actor_availability_validation(client, production):
    p = production
    headers = p["headers"]
    root = "/api/v1/cineplanner/actors"
    assert client.post(root, headers=headers, json={"name": "X"}).status_code == 422
    actor = client.post(
        root,
        headers=headers,
        json={
            "name": "QA Actor",
            "playing_age_min": 20,
            "playing_age_max": 45,
            "languages": ["Urdu"],
            "skills": ["Acting"],
        },
    ).json["data"]["actor"]
    path = root + "/" + actor["public_id"] + "/availability"
    valid = {
        "starts_on": "2026-12-01",
        "ends_on": "2026-12-02",
        "status": "available",
        "production_id": p["path"].rsplit("/", 1)[1],
    }
    for change in [
        {"starts_on": "wrong"},
        {"ends_on": "2026-11-01"},
        {"status": "wrong"},
    ]:
        assert (
            client.post(path, headers=headers, json={**valid, **change}).status_code
            == 422
        )
    assert client.post(path, headers=p["other"], json=valid).status_code == 404
    assert client.post(path, headers=headers, json=valid).status_code == 201
    character = request(client, p, "GET")["characters"][0]
    valid = {
        "actor_id": actor["public_id"],
        "character_id": character["public_id"],
        "status": "confirmed",
    }
    request(
        client,
        p,
        "POST",
        "/cast-assignments",
        {**valid, "actor_id": "missing"},
        expected=422,
    )
    request(
        client,
        p,
        "POST",
        "/cast-assignments",
        {**valid, "status": "invalid"},
        expected=422,
    )
    for status in ["confirmed", "shortlisted"]:
        assignment = request(
            client,
            p,
            "POST",
            "/cast-assignments",
            {**valid, "status": status},
            expected=201,
        )["assignment"]
        assert assignment["status"] == status
    rows = client.get(root, headers=headers).json["data"]["actors"]
    assert any(row["public_id"] == actor["public_id"] for row in rows)


@pytest.mark.parametrize(
    "payload",
    [
        {"production_start_date": "not-a-date"},
        {"maximum_shoot_days": None},
        {"working_hours_limit": "bad"},
        {"title": ""},
        {"budget_ceiling_minor": -1},
        {"settings_json": []},
    ],
)
def test_invalid_planner_edit_returns_validation_error_without_mutation(
    client, production, payload
):
    before = request(client, production, "GET")["production"]
    request(client, production, "PATCH", "", payload, expected=422)
    after = request(client, production, "GET")["production"]
    assert after == before
