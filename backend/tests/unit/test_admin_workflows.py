"""Admin operations preserve records, validate inputs and enforce staff boundaries."""

from datetime import timedelta

import pytest

from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import Booking
from app.models.identity import Permission, Role, User, UserRole
from app.models.marketplace import MarketplaceListing
from app.models.projects import Project
from app.security import issue_token_pair


@pytest.fixture
def admin_world(app):
    with app.test_request_context():
        roles = {
            code: Role(code=code, name=code, portal_route="/test")
            for code in (
                "super_admin",
                "support_agent",
                "actor_talent",
                "director_producer",
            )
        }
        db.session.add_all(roles.values())
        db.session.flush()
        users = {}
        for name, role in [
            ("admin", "super_admin"),
            ("support", "support_agent"),
            ("actor", "actor_talent"),
        ]:
            user = User(
                email=f"{name}@example.com",
                display_name=name,
                password_hash="fixture-hash",
                terms_version="2026-10",
                status="active",
            )
            db.session.add(user)
            db.session.flush()
            db.session.add(
                UserRole(
                    user_id=user.id,
                    role_id=roles[role].id,
                    is_primary=True,
                    status="active",
                )
            )
            db.session.flush()
            users[name] = user
        project = Project(
            owner_user_id=users["admin"].id,
            title="Moderated production",
            project_type="film",
        )
        listing = MarketplaceListing(
            owner_user_id=users["actor"].id,
            listing_type="talent",
            profile_entity_id="QA-TALENT",
            verification_status="approved",
            moderation_status="pending",
            visibility="public",
            title="QA actor",
            summary="Auditable listing",
        )
        db.session.add_all([project, listing])
        db.session.flush()
        booking = Booking(
            project_id=project.id,
            requester_user_id=users["admin"].id,
            provider_user_id=users["actor"].id,
            listing_id=listing.id,
            category="talent",
            start_at=utc_now(),
            end_at=utc_now() + timedelta(hours=2),
            status="sent",
        )
        db.session.add_all(
            [booking, Permission(code="review", description="Review records")]
        )
        db.session.flush()
        result = {
            name: {
                "headers": {
                    "Authorization": "Bearer " + issue_token_pair(user).access_token
                },
                "id": user.public_id,
            }
            for name, user in users.items()
        }
        result.update(booking=booking.public_id, listing=listing.public_id)
        db.session.commit()
        return result


def call(client, world, method, path, payload=None, role="admin", expected=200):
    response = client.open(
        "/api/v1/admin/control/" + path,
        method=method,
        headers=world[role]["headers"],
        json=payload,
    )
    assert response.status_code == expected, response.text
    return response.json.get("data")


def test_booking_moderation_persists_history_and_filters(client, admin_world):
    w = admin_world
    data = call(client, w, "GET", "bookings?status=sent&category=talent")
    assert [row["public_id"] for row in data["bookings"]] == [w["booking"]]
    path = "bookings/" + w["booking"]
    assert call(client, w, "GET", path)["booking"]["contract_status"] == "not_generated"
    call(client, w, "PATCH", path, {"status": "invented"}, expected=422)
    updated = call(
        client,
        w,
        "PATCH",
        path,
        {"status": "admin_review", "reason": "Investigate disputed date"},
    )["booking"]
    assert updated["status"] == "admin_review"
    assert updated["status_events"][-1]["reason"] == "Investigate disputed date"
    assert call(client, w, "GET", "bookings?status=sent")["bookings"] == []
    events = call(client, w, "GET", "audit-events")["events"]
    assert any(e["entity_id"] == w["booking"] and e["risk"] == "high" for e in events)


def test_user_suspension_revokes_sessions_and_role_changes_persist(client, admin_world):
    w = admin_world
    path = "users/" + w["actor"]["id"]
    call(
        client, w, "PATCH", path, {"status": "suspended"}, role="support", expected=403
    )
    call(
        client,
        w,
        "PATCH",
        "users/" + w["admin"]["id"],
        {"status": "suspended"},
        expected=409,
    )
    call(client, w, "PATCH", path, {"status": "unknown"}, expected=422)
    user = call(client, w, "PATCH", path, {"status": "suspended"})["user"]
    assert user["active_sessions"] == 0
    assert client.get("/api/v1/me", headers=w["actor"]["headers"]).status_code == 403
    rows = call(client, w, "GET", "users?status=suspended&q=actor")["users"]
    assert [u["public_id"] for u in rows] == [w["actor"]["id"]]
    call(
        client, w, "PATCH", path, {"status": "active", "role_code": "director_producer"}
    )
    user = call(
        client,
        w,
        "PATCH",
        path,
        {"role_code": "director_producer", "role_status": "suspended"},
    )["user"]
    assert (
        next(r for r in user["roles"] if r["code"] == "director_producer")["status"]
        == "suspended"
    )
    call(
        client,
        w,
        "PATCH",
        path,
        {"role_code": "director_producer", "role_status": "bad"},
        expected=422,
    )
    call(client, w, "PATCH", path, {"role_code": "missing"}, expected=404)


def test_listing_moderation_retains_auditable_decisions(client, admin_world):
    w = admin_world
    path = "listings/" + w["listing"]
    call(client, w, "PATCH", path, {"visibility": "unknown"}, expected=422)
    call(client, w, "PATCH", path, {"moderation_status": "unknown"}, expected=422)
    for status in ["approved", "changes_requested", "pending", "rejected"]:
        row = call(
            client,
            w,
            "PATCH",
            path,
            {
                "moderation_status": status,
                "visibility": "private",
                "reason": "QA decision",
            },
        )["listing"]
        assert row["moderation_status"] == status and row["visibility"] == "private"
    rows = call(
        client, w, "GET", "listings?moderation_status=rejected&listing_type=talent"
    )["listings"]
    assert [r["public_id"] for r in rows] == [w["listing"]]
    events = call(client, w, "GET", "audit-events")["events"]
    assert len([e for e in events if e["event_type"] == "moderation_action"]) == 4


def test_contract_template_publication_and_clause_replacement(client, admin_world):
    w = admin_world
    call(client, w, "POST", "contract-templates", {}, expected=422)
    template = call(
        client,
        w,
        "POST",
        "contract-templates",
        {"name": "Talent agreement", "category": "talent"},
        expected=201,
    )["template"]
    path = "contract-templates/" + template["public_id"]
    for payload in [{"name": ""}, {"category": ""}, {"status": "bad"}]:
        call(client, w, "PATCH", path, payload, expected=422)
    for revision in [1, 2]:
        template = call(
            client,
            w,
            "PATCH",
            path,
            {
                "name": "Updated agreement",
                "category": "talent",
                "body_schema_json": "{}",
                "status": "published",
                "clauses": [
                    {
                        "clause_key": "usage",
                        "title": "Usage rights",
                        "body_text": f"Revision {revision}",
                        "required": True,
                        "editable": False,
                    }
                ],
            },
        )["template"]
        assert template["version_number"] == revision
        assert len(template["clauses"]) == 1
        assert template["clauses"][0]["body_text"] == f"Revision {revision}"
    saved = call(client, w, "GET", "contract-templates")["templates"]
    assert saved[0]["clauses"] == template["clauses"]


def test_fee_rule_validation_and_persistence(client, admin_world):
    w = admin_world
    valid = {
        "name": "Platform fee",
        "category": "talent",
        "basis_points": 250,
        "fixed_minor": 100,
    }
    for patch in [
        {"basis_points": "oops"},
        {"basis_points": 10001},
        {"fixed_minor": -1},
        {"name": ""},
        {"category": ""},
    ]:
        call(client, w, "POST", "fee-rules", {**valid, **patch}, expected=422)
    row = call(client, w, "POST", "fee-rules", valid, expected=201)["fee_rule"]
    path = "fee-rules/" + row["public_id"]
    for patch in [
        {"basis_points": "oops"},
        {"basis_points": -1},
        {"fixed_minor": "oops"},
        {"fixed_minor": -1},
        {"name": ""},
        {"category": ""},
    ]:
        call(client, w, "PATCH", path, patch, expected=422)
    row = call(
        client,
        w,
        "PATCH",
        path,
        {
            "name": "Updated",
            "category": "crew",
            "basis_points": 300,
            "fixed_minor": 0,
            "active": False,
        },
    )["fee_rule"]
    assert (
        row["active"] is False
        and row["basis_points"] == 300
        and row["fixed_minor"] == 0
    )
    assert call(client, w, "GET", "fee-rules")["fee_rules"] == [row]


def test_role_permissions_replace_without_duplicates_and_protect_super_admin(
    client, admin_world
):
    w = admin_world
    call(client, w, "GET", "roles", role="support", expected=403)
    call(
        client,
        w,
        "PATCH",
        "roles/super_admin/permissions",
        {"permissions": []},
        expected=409,
    )
    call(client, w, "PATCH", "roles/missing/permissions", {}, expected=404)
    call(
        client,
        w,
        "PATCH",
        "roles/actor_talent/permissions",
        {"permissions": ["missing"]},
        expected=422,
    )
    for permissions in [["review"], ["review"], []]:
        row = call(
            client,
            w,
            "PATCH",
            "roles/actor_talent/permissions",
            {"permissions": permissions},
        )["role"]
        assert row["permissions"] == permissions
    assert call(client, w, "GET", "roles")["permissions"][0]["code"] == "review"


@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("GET", "bookings/missing"),
        ("PATCH", "bookings/missing"),
        ("PATCH", "users/missing"),
        ("PATCH", "listings/missing"),
        ("PATCH", "fee-rules/missing"),
        ("PATCH", "contract-templates/missing"),
    ],
)
def test_admin_missing_resources_return_404(client, admin_world, method, path):
    call(client, admin_world, method, path, {}, expected=404)


@pytest.mark.parametrize(
    "path",
    [
        "bookings",
        "users",
        "listings",
        "contract-templates",
        "fee-rules",
        "roles",
        "audit-events",
    ],
)
def test_regular_members_cannot_read_admin_data(client, admin_world, path):
    call(client, admin_world, "GET", path, role="actor", expected=403)
