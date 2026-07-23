from __future__ import annotations

from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import func, or_, select

from app.api.auth import _current_user, _json_body
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import Booking, BookingStatusEvent
from app.models.contracts import Contract, ContractTemplate, TemplateClause
from app.models.identity import (
    Permission,
    Role,
    RolePermission,
    User,
    UserRole,
    UserSession,
    make_public_id,
)
from app.models.kyc import KycSubmission, VerificationEvent
from app.models.marketplace import MarketplaceListing
from app.models.payments import FeeRule, PaymentProof, PaymentSchedule
from app.models.trust_safety import Dispute, ModerationCase, ModerationEvent
from app.responses import success

admin_control_blueprint = Blueprint("admin_control", __name__)

ADMIN_ROLE_CODES = {
    "reviewer",
    "finance_admin",
    "support_agent",
    "super_admin",
}
SUPER_ADMIN_ROLE_CODES = {"super_admin"}


def _has_role(user: User, role_codes: set[str]) -> bool:
    return any(
        item.status == "active" and item.role.code in role_codes for item in user.roles
    )


def _require_admin(*, super_admin: bool = False) -> User:
    user = _current_user()
    allowed = SUPER_ADMIN_ROLE_CODES if super_admin else ADMIN_ROLE_CODES
    if not _has_role(user, allowed):
        raise APIError(
            "admin.permission_denied",
            "The required admin role is not active.",
            status=403,
        )
    return user


def _user_payload(item: User) -> dict[str, Any]:
    booking_count = db.session.execute(
        select(func.count()).where(
            or_(
                Booking.requester_user_id == item.id,
                Booking.provider_user_id == item.id,
            )
        )
    ).scalar_one()
    dispute_count = db.session.execute(
        select(func.count()).where(
            or_(
                Dispute.opened_by == item.id,
                Dispute.respondent_user_id == item.id,
            )
        )
    ).scalar_one()
    active_sessions = db.session.execute(
        select(func.count()).where(
            UserSession.user_id == item.id,
            UserSession.revoked_at.is_(None),
        )
    ).scalar_one()
    latest_kyc = db.session.execute(
        select(KycSubmission)
        .where(KycSubmission.user_id == item.id)
        .order_by(KycSubmission.created_at.desc())
        .limit(1)
    ).scalar_one_or_none()
    return {
        "public_id": item.public_id,
        "display_name": item.display_name,
        "email": item.email,
        "status": item.status,
        "roles": [
            {
                "code": role.role.code,
                "name": role.role.name,
                "status": role.status,
                "is_primary": role.is_primary,
            }
            for role in item.roles
        ],
        "kyc_status": latest_kyc.status if latest_kyc else "not_started",
        "kyc_risk_level": latest_kyc.risk_level if latest_kyc else "unknown",
        "bookings_count": booking_count,
        "disputes_count": dispute_count,
        "active_sessions": active_sessions,
        "last_login_at": item.last_login_at.isoformat() if item.last_login_at else None,
        "created_at": item.created_at.isoformat(),
    }


def _booking_payload(item: Booking) -> dict[str, Any]:
    contract = db.session.execute(
        select(Contract).where(Contract.booking_id == item.id).limit(1)
    ).scalar_one_or_none()
    schedule = db.session.execute(
        select(PaymentSchedule).where(PaymentSchedule.booking_id == item.id).limit(1)
    ).scalar_one_or_none()
    return {
        "public_id": item.public_id,
        "project_id": item.project.public_id,
        "project_title": item.project.title,
        "listing_id": item.listing.public_id,
        "listing_title": item.listing.title,
        "listing_type": item.listing.listing_type,
        "city": item.listing.city.name if item.listing.city else None,
        "category": item.category,
        "status": item.status,
        "requester": {
            "public_id": item.requester.public_id,
            "display_name": item.requester.display_name,
        },
        "provider": {
            "public_id": item.provider.public_id,
            "display_name": item.provider.display_name,
        },
        "agreed_amount_minor": item.agreed_amount_minor,
        "currency": item.currency,
        "start_at": item.start_at.isoformat(),
        "end_at": item.end_at.isoformat(),
        "conversation_id": item.conversation.public_id if item.conversation else None,
        "negotiation_id": (
            item.negotiation_thread.public_id if item.negotiation_thread else None
        ),
        "offers_count": len(item.offers),
        "contract_id": contract.public_id if contract else None,
        "contract_status": contract.status if contract else "not_generated",
        "payment_status": schedule.status if schedule else "not_scheduled",
        "updated_at": item.updated_at.isoformat(),
        "status_events": [
            {
                "from_status": event.from_status,
                "to_status": event.to_status,
                "reason": event.reason,
                "actor": event.actor.display_name if event.actor else "System",
                "created_at": event.created_at.isoformat(),
            }
            for event in item.status_events
        ],
    }


def _listing_payload(item: MarketplaceListing) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "title": item.title,
        "summary": item.summary,
        "listing_type": item.listing_type,
        "profile_entity_id": item.profile_entity_id,
        "owner": {
            "public_id": item.owner.public_id,
            "display_name": item.owner.display_name,
        },
        "city": item.city.name if item.city else None,
        "price_from_minor": item.price_from_minor,
        "currency": item.currency,
        "verification_status": item.verification_status,
        "moderation_status": item.moderation_status,
        "visibility": item.visibility,
        "published_at": item.published_at.isoformat() if item.published_at else None,
        "media_count": len(item.media),
        "updated_at": item.updated_at.isoformat(),
    }


def _template_payload(item: ContractTemplate) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "category": item.category,
        "jurisdiction": item.jurisdiction,
        "version_number": item.version_number,
        "status": item.status,
        "published_at": item.published_at.isoformat() if item.published_at else None,
        "updated_at": item.updated_at.isoformat(),
        "clauses": [
            {
                "clause_key": clause.clause_key,
                "title": clause.title,
                "body_text": clause.body_text,
                "sort_order": clause.sort_order,
                "required": clause.required,
                "editable": clause.editable,
            }
            for clause in item.clauses
        ],
    }


def _fee_rule_payload(item: FeeRule) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "category": item.category,
        "basis_points": item.basis_points,
        "fixed_minor": item.fixed_minor,
        "currency": item.currency,
        "active": item.active,
        "updated_at": item.updated_at.isoformat(),
    }


def _role_payload(item: Role) -> dict[str, Any]:
    admin_users = sum(
        1
        for user_role in item.users
        if user_role.status == "active" and item.code in ADMIN_ROLE_CODES
    )
    return {
        "code": item.code,
        "name": item.name,
        "portal_route": item.portal_route,
        "requires_kyc": item.requires_kyc,
        "display_order": item.display_order,
        "is_active": item.is_active,
        "admin_users": admin_users,
        "permissions": sorted(
            permission.permission.code for permission in item.permissions
        ),
    }


@admin_control_blueprint.get("/admin/control/bookings")
def admin_bookings() -> Response:
    _require_admin()
    query = select(Booking)
    status = request.args.get("status")
    if status:
        query = query.where(Booking.status == status)
    category = request.args.get("category")
    if category:
        query = query.where(Booking.category == category)
    rows = db.session.execute(
        query.order_by(Booking.updated_at.desc()).limit(200)
    ).scalars()
    return jsonify(success({"bookings": [_booking_payload(row) for row in rows]}))


@admin_control_blueprint.get("/admin/control/bookings/<public_id>")
def admin_booking_detail(public_id: str) -> Response:
    _require_admin()
    item = db.session.execute(
        select(Booking).where(Booking.public_id == public_id)
    ).scalar_one_or_none()
    if item is None:
        raise APIError("admin.booking_not_found", "Booking was not found.", status=404)
    return jsonify(success({"booking": _booking_payload(item)}))


@admin_control_blueprint.patch("/admin/control/bookings/<public_id>")
def admin_update_booking(public_id: str) -> Response:
    admin = _require_admin()
    item = db.session.execute(
        select(Booking).where(Booking.public_id == public_id)
    ).scalar_one_or_none()
    if item is None:
        raise APIError("admin.booking_not_found", "Booking was not found.", status=404)
    payload = _json_body()
    status = str(payload.get("status", item.status)).strip()
    allowed = {
        "sent",
        "viewed",
        "under_negotiation",
        "accepted",
        "secured",
        "in_progress",
        "completed",
        "cancelled",
        "rejected",
        "admin_review",
    }
    if status not in allowed:
        raise APIError(
            "validation.failed",
            "Unsupported booking status.",
            status=422,
            fields={"status": ["Choose a supported booking status."]},
        )
    previous = item.status
    reason = str(payload.get("reason", "")).strip()[:2000] or None
    item.status = status
    db.session.add(
        BookingStatusEvent(
            booking_id=item.id,
            actor_user_id=admin.id,
            from_status=previous,
            to_status=status,
            reason=reason,
            metadata_json='{"source":"admin_control"}',
        )
    )
    db.session.commit()
    return jsonify(success({"booking": _booking_payload(item)}))


@admin_control_blueprint.get("/admin/control/users")
def admin_users() -> Response:
    _require_admin()
    query = select(User)
    status = request.args.get("status")
    if status:
        query = query.where(User.status == status)
    search = request.args.get("q", "").strip()
    if search:
        pattern = f"%{search}%"
        query = query.where(
            or_(User.display_name.ilike(pattern), User.email.ilike(pattern))
        )
    rows = db.session.execute(
        query.order_by(User.created_at.desc()).limit(200)
    ).scalars()
    return jsonify(success({"users": [_user_payload(row) for row in rows]}))


@admin_control_blueprint.patch("/admin/control/users/<public_id>")
def admin_update_user(public_id: str) -> Response:
    admin = _require_admin(super_admin=True)
    item = db.session.execute(
        select(User).where(User.public_id == public_id)
    ).scalar_one_or_none()
    if item is None:
        raise APIError("admin.user_not_found", "User was not found.", status=404)
    if item.id == admin.id:
        raise APIError(
            "admin.self_protection",
            "Your own admin account cannot be changed here.",
            status=409,
        )
    payload = _json_body()
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in {"active", "suspended", "locked"}:
            raise APIError(
                "validation.failed",
                "Unsupported user status.",
                status=422,
                fields={"status": ["Use active, suspended, or locked."]},
            )
        item.status = status
        if status != "active":
            sessions = db.session.execute(
                select(UserSession).where(
                    UserSession.user_id == item.id,
                    UserSession.revoked_at.is_(None),
                )
            ).scalars()
            for session in sessions:
                session.revoked_at = utc_now()
    if "role_code" in payload:
        role_code = str(payload.get("role_code", "")).strip()
        role = db.session.execute(
            select(Role).where(Role.code == role_code)
        ).scalar_one_or_none()
        if role is None:
            raise APIError("admin.role_not_found", "Role was not found.", status=404)
        user_role = next(
            (record for record in item.roles if record.role_id == role.id),
            None,
        )
        if user_role is None:
            user_role = UserRole(
                user_id=item.id,
                role_id=role.id,
                status="active",
                is_primary=False,
            )
            db.session.add(user_role)
        else:
            role_status = str(payload.get("role_status", "active")).strip()
            if role_status not in {"active", "suspended"}:
                raise APIError(
                    "validation.failed",
                    "Unsupported role status.",
                    status=422,
                    fields={"role_status": ["Use active or suspended."]},
                )
            user_role.status = role_status
    db.session.commit()
    return jsonify(success({"user": _user_payload(item)}))


@admin_control_blueprint.get("/admin/control/listings")
def admin_listings() -> Response:
    _require_admin()
    query = select(MarketplaceListing)
    moderation_status = request.args.get("moderation_status")
    if moderation_status:
        query = query.where(MarketplaceListing.moderation_status == moderation_status)
    listing_type = request.args.get("listing_type")
    if listing_type:
        query = query.where(MarketplaceListing.listing_type == listing_type)
    rows = db.session.execute(
        query.order_by(MarketplaceListing.updated_at.desc()).limit(200)
    ).scalars()
    return jsonify(success({"listings": [_listing_payload(row) for row in rows]}))


@admin_control_blueprint.patch("/admin/control/listings/<public_id>")
def admin_update_listing(public_id: str) -> Response:
    admin = _require_admin()
    item = db.session.execute(
        select(MarketplaceListing).where(MarketplaceListing.public_id == public_id)
    ).scalar_one_or_none()
    if item is None:
        raise APIError("admin.listing_not_found", "Listing was not found.", status=404)
    payload = _json_body()
    moderation_status: str | None = None
    if "moderation_status" in payload:
        moderation_status = str(payload.get("moderation_status", "")).strip()
        if moderation_status not in {
            "pending",
            "approved",
            "rejected",
            "changes_requested",
        }:
            raise APIError(
                "validation.failed",
                "Unsupported moderation status.",
                status=422,
                fields={"moderation_status": ["Choose a supported status."]},
            )
        item.moderation_status = moderation_status
    if "visibility" in payload:
        visibility = str(payload.get("visibility", "")).strip()
        if visibility not in {"public", "private"}:
            raise APIError(
                "validation.failed",
                "Visibility must be public or private.",
                status=422,
                fields={"visibility": ["Use public or private."]},
            )
        item.visibility = visibility
    if moderation_status is not None:
        reason = str(payload.get("reason", "")).strip() or None
        moderation_case = db.session.execute(
            select(ModerationCase)
            .where(
                ModerationCase.entity_type == "marketplace_listing",
                ModerationCase.entity_id == item.public_id,
            )
            .order_by(ModerationCase.created_at.desc())
            .limit(1)
        ).scalar_one_or_none()
        if moderation_case is None:
            moderation_case = ModerationCase(
                entity_type="marketplace_listing",
                entity_id=item.public_id,
                source="admin_control",
                risk_level="medium",
                status="queued",
                assigned_admin_id=admin.id,
            )
            db.session.add(moderation_case)
            db.session.flush()
        from_status = moderation_case.status
        to_status = (
            "resolved"
            if moderation_status in {"approved", "rejected"}
            else "escalated"
            if moderation_status == "changes_requested"
            else "queued"
        )
        moderation_case.status = to_status
        moderation_case.assigned_admin_id = admin.id
        moderation_case.decision = (
            moderation_status if moderation_status != "pending" else None
        )
        moderation_case.decision_reason = reason
        db.session.add(
            ModerationEvent(
                case_id=moderation_case.id,
                actor_user_id=admin.id,
                action=f"listing_{moderation_status}",
                from_status=from_status,
                to_status=to_status,
                notes=reason,
            )
        )
    db.session.commit()
    return jsonify(success({"listing": _listing_payload(item)}))


@admin_control_blueprint.get("/admin/control/contract-templates")
def admin_contract_templates() -> Response:
    _require_admin()
    rows = db.session.execute(
        select(ContractTemplate).order_by(
            ContractTemplate.category.asc(),
            ContractTemplate.version_number.desc(),
        )
    ).scalars()
    return jsonify(success({"templates": [_template_payload(row) for row in rows]}))


@admin_control_blueprint.post("/admin/control/contract-templates")
def admin_create_contract_template() -> ResponseReturnValue:
    admin = _require_admin(super_admin=True)
    payload = _json_body()
    name = str(payload.get("name", "")).strip()
    category = str(payload.get("category", "")).strip()
    if not name or not category:
        raise APIError(
            "validation.failed",
            "Name and category are required.",
            status=422,
            fields={
                "name": [] if name else ["Name is required."],
                "category": [] if category else ["Category is required."],
            },
        )
    item = ContractTemplate(
        public_id=make_public_id("CTPL"),
        name=name[:180],
        category=category[:64],
        jurisdiction=str(payload.get("jurisdiction", "PK")).strip()[:8],
        version_number=int(payload.get("version_number") or 1),
        body_schema_json=str(payload.get("body_schema_json", "{}")),
        status="draft",
        created_by=admin.id,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"template": _template_payload(item)})), 201


@admin_control_blueprint.patch("/admin/control/contract-templates/<public_id>")
def admin_update_contract_template(public_id: str) -> Response:
    admin = _require_admin(super_admin=True)
    item = db.session.execute(
        select(ContractTemplate).where(ContractTemplate.public_id == public_id)
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "admin.template_not_found", "Contract template was not found.", status=404
        )
    payload = _json_body()
    if "name" in payload:
        name = str(payload.get("name", "")).strip()
        if not name:
            raise APIError(
                "validation.failed",
                "Template name is required.",
                status=422,
                fields={"name": ["Name is required."]},
            )
        item.name = name[:180]
    if "category" in payload:
        category = str(payload.get("category", "")).strip()
        if not category:
            raise APIError(
                "validation.failed",
                "Template category is required.",
                status=422,
                fields={"category": ["Category is required."]},
            )
        item.category = category[:64]
    if "body_schema_json" in payload:
        item.body_schema_json = str(payload.get("body_schema_json", "{}"))
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in {"draft", "published", "archived"}:
            raise APIError(
                "validation.failed",
                "Unsupported template status.",
                status=422,
                fields={"status": ["Use draft, published, or archived."]},
            )
        if status == "published":
            item.version_number += 1 if item.status == "published" else 0
            item.published_at = utc_now()
            item.approved_by = admin.id
        item.status = status
    if "clauses" in payload:
        for clause in list(item.clauses):
            db.session.delete(clause)
        for index, raw in enumerate(payload.get("clauses") or []):
            item.clauses.append(
                TemplateClause(
                    clause_key=str(raw.get("clause_key", f"clause_{index + 1}"))[:80],
                    title=str(raw.get("title", "")).strip()[:180],
                    body_text=str(raw.get("body_text", "")).strip(),
                    sort_order=int(raw.get("sort_order") or (index + 1) * 10),
                    required=bool(raw.get("required", True)),
                    editable=bool(raw.get("editable", False)),
                )
            )
    db.session.commit()
    return jsonify(success({"template": _template_payload(item)}))


@admin_control_blueprint.get("/admin/control/fee-rules")
def admin_fee_rules() -> Response:
    _require_admin()
    rows = db.session.execute(
        select(FeeRule).order_by(FeeRule.category.asc(), FeeRule.name.asc())
    ).scalars()
    return jsonify(success({"fee_rules": [_fee_rule_payload(row) for row in rows]}))


@admin_control_blueprint.post("/admin/control/fee-rules")
def admin_create_fee_rule() -> ResponseReturnValue:
    _require_admin(super_admin=True)
    payload = _json_body()
    name = str(payload.get("name", "")).strip()
    category = str(payload.get("category", "")).strip()
    try:
        basis_points = int(payload.get("basis_points") or 0)
        fixed_minor = int(payload.get("fixed_minor") or 0)
    except (TypeError, ValueError) as exc:
        raise APIError(
            "validation.failed",
            "Fee values must be whole numbers.",
            status=422,
            fields={
                "basis_points": ["Enter a whole number."],
                "fixed_minor": ["Enter a whole number."],
            },
        ) from exc
    if not name or not category or not 0 <= basis_points <= 10000 or fixed_minor < 0:
        raise APIError(
            "validation.failed",
            "Fee rule details are invalid.",
            status=422,
            fields={
                "name": [] if name else ["Name is required."],
                "category": [] if category else ["Category is required."],
                "basis_points": (
                    []
                    if 0 <= basis_points <= 10000
                    else ["Use a value from 0 to 10000."]
                ),
                "fixed_minor": (
                    [] if fixed_minor >= 0 else ["Fixed fee cannot be negative."]
                ),
            },
        )
    item = FeeRule(
        public_id=make_public_id("FEE"),
        name=name[:120],
        category=category[:64],
        basis_points=basis_points,
        fixed_minor=fixed_minor,
        currency=str(payload.get("currency", "PKR")).strip().upper()[:3],
        active=bool(payload.get("active", True)),
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"fee_rule": _fee_rule_payload(item)})), 201


@admin_control_blueprint.patch("/admin/control/fee-rules/<public_id>")
def admin_update_fee_rule(public_id: str) -> Response:
    _require_admin(super_admin=True)
    item = db.session.execute(
        select(FeeRule).where(FeeRule.public_id == public_id)
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "admin.fee_rule_not_found",
            "Fee rule was not found.",
            status=404,
        )
    payload = _json_body()
    if "name" in payload:
        name = str(payload.get("name", "")).strip()
        if not name:
            raise APIError(
                "validation.failed",
                "Fee rule name is required.",
                status=422,
                fields={"name": ["Name is required."]},
            )
        item.name = name[:120]
    if "category" in payload:
        category = str(payload.get("category", "")).strip()
        if not category:
            raise APIError(
                "validation.failed",
                "Fee rule category is required.",
                status=422,
                fields={"category": ["Category is required."]},
            )
        item.category = category[:64]
    if "basis_points" in payload:
        try:
            basis_points = int(payload.get("basis_points") or 0)
        except (TypeError, ValueError) as exc:
            raise APIError(
                "validation.failed",
                "Basis points must be a whole number.",
                status=422,
                fields={"basis_points": ["Enter a whole number."]},
            ) from exc
        if not 0 <= basis_points <= 10000:
            raise APIError(
                "validation.failed",
                "Basis points are outside the supported range.",
                status=422,
                fields={"basis_points": ["Use a value from 0 to 10000."]},
            )
        item.basis_points = basis_points
    if "fixed_minor" in payload:
        try:
            fixed_minor = int(payload.get("fixed_minor") or 0)
        except (TypeError, ValueError) as exc:
            raise APIError(
                "validation.failed",
                "Fixed fee must be a whole number.",
                status=422,
                fields={"fixed_minor": ["Enter a whole number."]},
            ) from exc
        if fixed_minor < 0:
            raise APIError(
                "validation.failed",
                "Fixed fee cannot be negative.",
                status=422,
                fields={"fixed_minor": ["Use zero or a positive value."]},
            )
        item.fixed_minor = fixed_minor
    if "active" in payload:
        item.active = bool(payload.get("active"))
    db.session.commit()
    return jsonify(success({"fee_rule": _fee_rule_payload(item)}))


@admin_control_blueprint.get("/admin/control/roles")
def admin_roles() -> Response:
    _require_admin(super_admin=True)
    rows = db.session.execute(
        select(Role).order_by(Role.display_order.asc(), Role.name.asc())
    ).scalars()
    permissions = db.session.execute(
        select(Permission).order_by(Permission.code.asc())
    ).scalars()
    return jsonify(
        success(
            {
                "roles": [_role_payload(row) for row in rows],
                "permissions": [
                    {"code": item.code, "description": item.description}
                    for item in permissions
                ],
            }
        )
    )


@admin_control_blueprint.patch("/admin/control/roles/<code>/permissions")
def admin_update_role_permissions(code: str) -> Response:
    _require_admin(super_admin=True)
    if code == "super_admin":
        raise APIError(
            "admin.protected_role",
            "Super Admin permissions cannot be changed.",
            status=409,
        )
    role = db.session.execute(
        select(Role).where(Role.code == code)
    ).scalar_one_or_none()
    if role is None:
        raise APIError("admin.role_not_found", "Role was not found.", status=404)
    payload = _json_body()
    requested = {str(item).strip() for item in payload.get("permissions") or []}
    permissions = db.session.execute(
        select(Permission).where(Permission.code.in_(requested))
    ).scalars()
    resolved = list(permissions)
    if len(resolved) != len(requested):
        raise APIError(
            "validation.failed",
            "One or more permissions were not found.",
            status=422,
        )
    for item in list(role.permissions):
        db.session.delete(item)
    for permission in resolved:
        role.permissions.append(RolePermission(permission_id=permission.id))
    db.session.commit()
    return jsonify(success({"role": _role_payload(role)}))


@admin_control_blueprint.get("/admin/control/audit-events")
def admin_audit_events() -> Response:
    _require_admin()
    events: list[dict[str, Any]] = []

    verification_events = db.session.execute(
        select(VerificationEvent)
        .order_by(VerificationEvent.created_at.desc())
        .limit(75)
    ).scalars()
    for verification_event in verification_events:
        events.append(
            {
                "event_id": (
                    f"kyc:{verification_event.submission.public_id}:"
                    f"{verification_event.id}"
                ),
                "occurred_at": verification_event.created_at.isoformat(),
                "event_type": "kyc_status_changed",
                "actor": (
                    str(verification_event.actor_user_id)
                    if verification_event.actor_user_id
                    else "System"
                ),
                "affected_user": verification_event.submission.user.display_name,
                "entity_type": "kyc_submission",
                "entity_id": verification_event.submission.public_id,
                "risk": verification_event.submission.risk_level,
                "description": (
                    "KYC status changed from "
                    f"{verification_event.from_status or 'new'} "
                    f"to {verification_event.to_status}."
                ),
                "route": "/admin/verifications/:id",
            }
        )

    booking_events = db.session.execute(
        select(BookingStatusEvent)
        .order_by(BookingStatusEvent.created_at.desc())
        .limit(75)
    ).scalars()
    for booking_event in booking_events:
        events.append(
            {
                "event_id": (
                    f"booking:{booking_event.booking.public_id}:{booking_event.id}"
                ),
                "occurred_at": booking_event.created_at.isoformat(),
                "event_type": "booking_status_changed",
                "actor": (
                    booking_event.actor.display_name
                    if booking_event.actor
                    else "System"
                ),
                "affected_user": booking_event.booking.provider.display_name,
                "entity_type": "booking",
                "entity_id": booking_event.booking.public_id,
                "risk": (
                    "high"
                    if booking_event.to_status in {"disputed", "admin_review"}
                    else "low"
                ),
                "description": (
                    "Booking status changed from "
                    f"{booking_event.from_status or 'new'} "
                    f"to {booking_event.to_status}."
                ),
                "route": "/admin/bookings-monitor/:id",
            }
        )

    payment_proofs = db.session.execute(
        select(PaymentProof).order_by(PaymentProof.updated_at.desc()).limit(50)
    ).scalars()
    for payment_proof in payment_proofs:
        events.append(
            {
                "event_id": f"payment:{payment_proof.public_id}",
                "occurred_at": payment_proof.updated_at.isoformat(),
                "event_type": "payment_proof_updated",
                "actor": (
                    payment_proof.reviewer.display_name
                    if payment_proof.reviewer
                    else "System"
                ),
                "affected_user": payment_proof.submitter.display_name,
                "entity_type": "payment_proof",
                "entity_id": payment_proof.public_id,
                "risk": "high" if payment_proof.risk_score >= 60 else "medium",
                "description": f"Payment proof is {payment_proof.status}.",
                "route": "/admin/payment-review/:id",
            }
        )

    moderation_events = db.session.execute(
        select(ModerationEvent).order_by(ModerationEvent.created_at.desc()).limit(50)
    ).scalars()
    for moderation_event in moderation_events:
        events.append(
            {
                "event_id": (
                    f"moderation:{moderation_event.case.public_id}:"
                    f"{moderation_event.id}"
                ),
                "occurred_at": moderation_event.created_at.isoformat(),
                "event_type": "moderation_action",
                "actor": moderation_event.actor.display_name,
                "affected_user": "Marketplace member",
                "entity_type": moderation_event.case.entity_type,
                "entity_id": moderation_event.case.entity_id,
                "risk": moderation_event.case.risk_level,
                "description": moderation_event.notes or moderation_event.action,
                "route": "/admin/content-moderation",
            }
        )

    events.sort(key=lambda item: item["occurred_at"], reverse=True)
    return jsonify(success({"events": events[:200]}))
