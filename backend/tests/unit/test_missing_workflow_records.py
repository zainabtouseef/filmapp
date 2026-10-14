"""Missing workflow IDs must return controlled errors without creating records."""

import pytest
from sqlalchemy import select

from app.api.app import ROLES
from app.extensions import db
from app.models.identity import Permission, Role, RolePermission, User, UserRole
from app.models.operations import EquipmentProviderProfile
from tests.unit.test_admin_workflows import admin_world as admin_world


@pytest.fixture
def workflow_headers(app, admin_world):
    with app.app_context():
        user = db.session.scalar(
            select(User).where(User.public_id == admin_world["admin"]["id"])
        )
        db.session.add(EquipmentProviderProfile(user_id=user.id, name="QA provider"))
        existing = {r.code: r for r in db.session.scalars(select(Role))}
        for value in ROLES:
            code = value["code"]
            if code not in existing:
                row = Role(code=code, name=code, portal_route="/test")
                db.session.add(row)
                db.session.flush()
                existing[code] = row
            if code != "super_admin":
                db.session.add(
                    UserRole(
                        user_id=user.id, role_id=existing[code].id, status="active"
                    )
                )
        permission = Permission(code="kyc.review", description="Review")
        db.session.add(permission)
        db.session.flush()
        db.session.add(
            RolePermission(
                role_id=existing["super_admin"].id, permission_id=permission.id
            )
        )
        db.session.commit()
    return admin_world["admin"]["headers"]


CASES = [
    ("GET", "/projects/MISSING"),
    ("PATCH", "/projects/MISSING"),
    ("POST", "/projects/MISSING/duplicate"),
    ("GET", "/projects/MISSING/room"),
    ("POST", "/projects/MISSING/room/items"),
    ("GET", "/projects/MISSING/members"),
    ("POST", "/projects/MISSING/members"),
    ("GET", "/projects/MISSING/files"),
    ("POST", "/projects/MISSING/files"),
    ("GET", "/projects/MISSING/requirements"),
    ("POST", "/projects/MISSING/requirements"),
    ("PATCH", "/requirements/MISSING"),
    ("PATCH", "/availability/MISSING"),
    ("DELETE", "/availability/MISSING"),
    ("GET", "/bookings/MISSING"),
    ("PATCH", "/bookings/MISSING"),
    ("POST", "/bookings/MISSING/send"),
    ("POST", "/bookings/MISSING/offers"),
    ("POST", "/bookings/MISSING/reject"),
    ("POST", "/bookings/MISSING/cancel"),
    ("POST", "/offers/MISSING/accept"),
    ("GET", "/negotiations/MISSING"),
    ("GET", "/conversations/MISSING/messages"),
    ("POST", "/conversations/MISSING/messages"),
    ("POST", "/messages/MISSING/pin"),
    ("GET", "/casting/roles/MISSING"),
    ("PATCH", "/casting/roles/MISSING"),
    ("POST", "/casting/roles/MISSING/save"),
    ("POST", "/casting/roles/MISSING/applications"),
    ("GET", "/casting/applications/MISSING"),
    ("PATCH", "/casting/applications/MISSING"),
    ("POST", "/casting/applications/MISSING/submit"),
    ("POST", "/casting/applications/MISSING/withdraw"),
    ("POST", "/casting/applications/MISSING/confirm-audition"),
    ("GET", "/casting/applications/MISSING/meetings"),
    ("POST", "/casting/applications/MISSING/meetings/propose"),
    ("POST", "/casting/applications/MISSING/self-tape"),
    ("POST", "/casting/applications/MISSING/conversation"),
    ("GET", "/director/projects/MISSING/casting-applications"),
    ("PATCH", "/director/casting-applications/MISSING"),
    ("PATCH", "/location-properties/MISSING"),
    ("POST", "/location-properties/MISSING/spaces"),
    ("PATCH", "/location-spaces/MISSING"),
    ("POST", "/location-properties/MISSING/pricing"),
    ("PATCH", "/location-pricing/MISSING"),
    ("POST", "/location-properties/MISSING/rules"),
    ("PATCH", "/location-rules/MISSING"),
    ("POST", "/location-inspections/MISSING/items"),
    ("POST", "/location-inspections/MISSING/confirm"),
    ("POST", "/damage-claims/MISSING/evidence"),
    ("PATCH", "/equipment/items/MISSING"),
    ("PATCH", "/equipment/packages/MISSING"),
    ("POST", "/equipment/packages/MISSING/items"),
    ("PATCH", "/equipment/terms/MISSING"),
    ("POST", "/equipment-inspections/MISSING/items"),
    ("POST", "/equipment-inspections/MISSING/confirm"),
    ("GET", "/safety-checks/MISSING"),
    ("PATCH", "/safety-checks/MISSING"),
    ("POST", "/safety-checks/MISSING/items"),
    ("PATCH", "/safety-checks/MISSING/items/MISSING"),
    ("GET", "/incidents/MISSING"),
    ("PATCH", "/incidents/MISSING"),
    ("POST", "/safety-check-ins/MISSING/complete"),
    ("GET", "/opportunities/roles/MISSING"),
    ("POST", "/opportunities/roles/MISSING/save"),
    ("POST", "/opportunities/roles/MISSING/applications"),
    ("GET", "/opportunities/applications/MISSING"),
    ("POST", "/opportunities/applications/MISSING/withdraw"),
    ("GET", "/opportunities/applications/MISSING/meetings"),
    ("GET", "/director/projects/MISSING/opportunity-applications"),
    ("PATCH", "/director/opportunity-applications/MISSING"),
    ("PATCH", "/portfolio/MISSING"),
    ("DELETE", "/portfolio/MISSING"),
    ("PATCH", "/credits/MISSING"),
    ("DELETE", "/credits/MISSING"),
    ("DELETE", "/saved-searches/MISSING"),
    ("POST", "/shortlists/MISSING/items"),
    ("PATCH", "/shortlist-items/MISSING"),
    ("DELETE", "/shortlist-items/MISSING"),
    ("GET", "/marketplace/listings/MISSING"),
    ("PATCH", "/marketplace/listings/MISSING/pricing"),
    ("GET", "/files/MISSING"),
    ("POST", "/files/MISSING/download-link"),
    ("POST", "/uploads/MISSING/complete"),
    ("POST", "/kyc/submissions/MISSING/submit"),
    ("POST", "/kyc/submissions/MISSING/resubmit"),
    ("GET", "/admin/kyc/submissions/MISSING"),
    ("POST", "/admin/kyc/submissions/MISSING/decision"),
    ("GET", "/insurance/policies/MISSING"),
    ("GET", "/insurance/claims/MISSING"),
    ("POST", "/insurance/claims/MISSING/evidence"),
    ("POST", "/insurance/claims/MISSING/decision"),
    ("GET", "/bookings/MISSING/review-eligibility"),
    ("GET", "/users/MISSING/reviews"),
    ("GET", "/disputes/MISSING"),
    ("POST", "/disputes/MISSING/evidence"),
    ("GET", "/admin/disputes/MISSING"),
    ("POST", "/admin/disputes/MISSING/decision"),
    ("GET", "/support-tickets/MISSING"),
    ("POST", "/support-tickets/MISSING/messages"),
    ("PATCH", "/admin/support-tickets/MISSING"),
    ("GET", "/admin/moderation-cases/MISSING"),
    ("POST", "/admin/moderation-cases/MISSING/decision"),
    ("POST", "/admin/announcements/MISSING/publish"),
    ("PATCH", "/notifications/MISSING/read"),
]


@pytest.mark.parametrize(("method", "path"), CASES)
def test_missing_workflow_record_is_not_a_server_error(
    client, workflow_headers, method, path
):
    response = client.open(
        "/api/v1" + path,
        method=method,
        headers=workflow_headers,
        json={"decision": "approved"} if path.startswith("/admin/kyc/") else {},
    )
    assert response.status_code == 404, (method, path, response.text)
    assert response.is_json and "error" in response.json
    assert response.json["error"]["code"] != "internal.unexpected"
