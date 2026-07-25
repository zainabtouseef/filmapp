from __future__ import annotations

import json
from decimal import Decimal
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import func, or_, select

from app.api.auth import _current_user, _json_body
from app.api.bookings import _user_payload
from app.api.marketplace import _field_error, _file_payload, _owned_ready_file
from app.api.operations import _parse_datetime
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import Booking
from app.models.identity import User
from app.models.marketplace import UserProfile
from app.models.trust_safety import (
    Announcement,
    BlockedUser,
    Dispute,
    DisputeEvent,
    DisputeEvidence,
    ModerationCase,
    ModerationEvent,
    Notification,
    PushDevice,
    Report,
    Review,
    ReviewDimension,
    ReviewRequest,
    SupportMessage,
    SupportTicket,
)
from app.responses import success
from app.services.notifications import notify_user

trust_safety_blueprint = Blueprint("trust_safety", __name__)

REPORT_REASONS = (
    "harassment",
    "spam",
    "inappropriate_content",
    "fraud",
    "safety_concern",
    "other",
)


def _has_role(user: User, *codes: str) -> bool:
    return any(
        user_role.status == "active" and user_role.role.code in codes
        for user_role in user.roles
    )


def _require_moderation(user: User) -> None:
    if not _has_role(user, "reviewer", "super_admin"):
        raise APIError(
            "moderation.permission_denied", "A reviewer role is required.", status=403
        )


def _require_dispute_admin(user: User) -> None:
    if not _has_role(user, "reviewer", "finance_admin", "super_admin"):
        raise APIError(
            "dispute.permission_denied", "An admin role is required.", status=403
        )


def _require_support_admin(user: User) -> None:
    if not _has_role(user, "support_agent", "reviewer", "super_admin"):
        raise APIError(
            "support.permission_denied", "A support role is required.", status=403
        )


def _require_super_admin(user: User) -> None:
    if not _has_role(user, "super_admin"):
        raise APIError(
            "announcement.permission_denied",
            "A super admin role is required.",
            status=403,
        )


def _booking_for_party(public_id: str, user: User) -> Booking:
    booking = db.session.execute(
        select(Booking).where(
            Booking.public_id == public_id,
            or_(
                Booking.requester_user_id == user.id,
                Booking.provider_user_id == user.id,
            ),
        )
    ).scalar_one_or_none()
    if booking is None:
        raise APIError("booking.not_found", "Booking was not found.", status=404)
    return booking


def _counterpart(booking: Booking, user_id: Any) -> Any:
    return (
        booking.provider_user_id
        if user_id == booking.requester_user_id
        else booking.requester_user_id
    )


def _refresh_reviewee_rating(user_id: Any) -> None:
    rows = (
        db.session.execute(
            select(Review.rating).where(
                Review.reviewee_user_id == user_id, Review.status == "published"
            )
        )
        .scalars()
        .all()
    )
    profile = db.session.execute(
        select(UserProfile).where(UserProfile.user_id == user_id)
    ).scalar_one_or_none()
    if profile is None:
        profile = UserProfile(user_id=user_id, profile_visibility="private")
        db.session.add(profile)
    profile.review_count = len(rows)
    profile.rating_average = Decimal(sum(rows)) / len(rows) if rows else Decimal(0)


def _review_payload(item: Review) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "booking_id": item.booking.public_id,
        "reviewer": _user_payload(item.reviewer),
        "reviewee": _user_payload(item.reviewee),
        "rating": item.rating,
        "text": item.text,
        "status": item.status,
        "published_at": item.published_at.isoformat() if item.published_at else None,
        "dimensions": [
            {"dimension": row.dimension, "score": row.score} for row in item.dimensions
        ],
    }


def _report_payload(item: Report) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "reporter": _user_payload(item.reporter),
        "reported_user": _user_payload(item.reported_user)
        if item.reported_user
        else None,
        "entity_type": item.entity_type,
        "entity_id": item.entity_id,
        "reason": item.reason,
        "description": item.description,
        "status": item.status,
        "resolution": item.resolution,
    }


def _moderation_event_payload(item: ModerationEvent) -> dict[str, Any]:
    return {
        "actor": _user_payload(item.actor),
        "action": item.action,
        "from_status": item.from_status,
        "to_status": item.to_status,
        "notes": item.notes,
        "created_at": item.created_at.isoformat(),
    }


def _moderation_case_payload(item: ModerationCase) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "entity_type": item.entity_type,
        "entity_id": item.entity_id,
        "source": item.source,
        "risk_level": item.risk_level,
        "status": item.status,
        "assigned_admin": _user_payload(item.assigned_admin)
        if item.assigned_admin
        else None,
        "decision": item.decision,
        "decision_reason": item.decision_reason,
        "events": [_moderation_event_payload(row) for row in item.events],
    }


def _dispute_evidence_payload(item: DisputeEvidence) -> dict[str, Any]:
    return {
        "submitted_by": _user_payload(item.submitter),
        "file": _file_payload(item.file),
        "evidence_type": item.evidence_type,
        "description": item.description,
    }


def _dispute_event_payload(item: DisputeEvent) -> dict[str, Any]:
    return {
        "actor": _user_payload(item.actor),
        "event_type": item.event_type,
        "note": item.note,
        "created_at": item.created_at.isoformat(),
    }


def _dispute_payload(item: Dispute) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "booking_id": item.booking.public_id,
        "opened_by": _user_payload(item.opener),
        "respondent": _user_payload(item.respondent),
        "type": item.type,
        "description": item.description,
        "value_minor": item.value_minor,
        "currency": item.currency,
        "severity": item.severity,
        "status": item.status,
        "assigned_admin": _user_payload(item.assigned_admin)
        if item.assigned_admin
        else None,
        "resolved_at": item.resolved_at.isoformat() if item.resolved_at else None,
        "evidence": [_dispute_evidence_payload(row) for row in item.evidence],
        "events": [_dispute_event_payload(row) for row in item.events],
    }


def _support_message_payload(item: SupportMessage) -> dict[str, Any]:
    return {
        "sender": _user_payload(item.sender),
        "body": item.body,
        "file": _file_payload(item.file),
        "internal_note": item.internal_note,
        "created_at": item.created_at.isoformat(),
    }


def _support_ticket_payload(
    item: SupportTicket, *, include_internal: bool
) -> dict[str, Any]:
    messages = [
        row for row in item.messages if include_internal or not row.internal_note
    ]
    return {
        "public_id": item.public_id,
        "user": _user_payload(item.user),
        "booking_id": item.booking.public_id if item.booking else None,
        "category": item.category,
        "priority": item.priority,
        "subject": item.subject,
        "status": item.status,
        "assigned_admin": _user_payload(item.assigned_admin)
        if item.assigned_admin
        else None,
        "last_message_at": item.last_message_at.isoformat()
        if item.last_message_at
        else None,
        "messages": [_support_message_payload(row) for row in messages],
    }


def _announcement_payload(item: Announcement) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "title": item.title,
        "body": item.body,
        "audience": json.loads(item.audience_json) if item.audience_json else {},
        "channels": json.loads(item.channel_json) if item.channel_json else [],
        "status": item.status,
        "scheduled_at": item.scheduled_at.isoformat() if item.scheduled_at else None,
        "published_at": item.published_at.isoformat() if item.published_at else None,
    }


def _notification_payload(item: Notification) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "category": item.category,
        "title": item.title,
        "body": item.body,
        "route_name": item.route_name,
        "route_params": json.loads(item.route_params_json)
        if item.route_params_json
        else {},
        "read_at": item.read_at.isoformat() if item.read_at else None,
        "created_at": item.created_at.isoformat(),
    }


# ---------------------------------------------------------------------------
# Reviews
# ---------------------------------------------------------------------------


@trust_safety_blueprint.get("/bookings/<public_id>/review-eligibility")
def review_eligibility(public_id: str) -> Response:
    user = _current_user()
    booking = _booking_for_party(public_id, user)
    reviewee_id = _counterpart(booking, user.id)
    reviewee = db.session.execute(
        select(User).where(User.id == reviewee_id)
    ).scalar_one()
    already_reviewed = (
        db.session.execute(
            select(Review).where(
                Review.booking_id == booking.id,
                Review.reviewer_user_id == user.id,
                Review.reviewee_user_id == reviewee_id,
            )
        ).scalar_one_or_none()
        is not None
    )
    return jsonify(
        success(
            {
                "eligible": booking.status == "secured" and not already_reviewed,
                "already_reviewed": already_reviewed,
                "reviewee": _user_payload(reviewee),
            }
        )
    )


@trust_safety_blueprint.post("/reviews")
def create_review() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    booking = _booking_for_party(str(payload.get("booking_id", "")).strip(), user)
    if booking.status != "secured":
        raise APIError(
            "review.not_eligible", "Booking is not eligible for review yet.", status=409
        )
    rating = int(payload.get("rating") or 0)
    if rating < 1 or rating > 5:
        raise _field_error("rating", "Rating must be between 1 and 5.")
    reviewee_id = _counterpart(booking, user.id)
    existing = db.session.execute(
        select(Review).where(
            Review.booking_id == booking.id,
            Review.reviewer_user_id == user.id,
            Review.reviewee_user_id == reviewee_id,
        )
    ).scalar_one_or_none()
    if existing is not None:
        raise APIError(
            "review.already_submitted", "Review already submitted.", status=409
        )
    review = Review(
        booking_id=booking.id,
        reviewer_user_id=user.id,
        reviewee_user_id=reviewee_id,
        rating=rating,
        text=str(payload.get("text", "")).strip()[:2000] or None,
        published_at=utc_now(),
    )
    db.session.add(review)
    db.session.flush()
    for entry in payload.get("dimensions") or []:
        if not isinstance(entry, dict):
            continue
        dimension = str(entry.get("dimension", "")).strip()[:64]
        if not dimension:
            continue
        db.session.add(
            ReviewDimension(
                review_id=review.id,
                dimension=dimension,
                score=int(entry.get("score") or 0),
            )
        )
    _refresh_reviewee_rating(reviewee_id)

    pending_request = db.session.execute(
        select(ReviewRequest).where(
            ReviewRequest.booking_id == booking.id,
            ReviewRequest.requested_from == user.id,
            ReviewRequest.status == "sent",
        )
    ).scalar_one_or_none()
    if pending_request is not None:
        pending_request.status = "completed"
        pending_request.completed_review_id = review.id

    notify_user(
        reviewee_id,
        category="reviews",
        title="You received a new review",
        body=f"{user.display_name} left you a {rating}-star review.",
        route_name="/review",
        route_params={"review_id": review.public_id},
    )
    db.session.commit()
    return jsonify(success({"review": _review_payload(review)})), 201


@trust_safety_blueprint.get("/users/<public_id>/reviews")
def user_reviews(public_id: str) -> Response:
    target = db.session.execute(
        select(User).where(User.public_id == public_id)
    ).scalar_one_or_none()
    if target is None:
        raise APIError("user.not_found", "User was not found.", status=404)
    rows = db.session.execute(
        select(Review)
        .where(Review.reviewee_user_id == target.id, Review.status == "published")
        .order_by(Review.published_at.desc())
        .limit(50)
    ).scalars()
    reviews = [_review_payload(row) for row in rows]
    average = sum(row["rating"] for row in reviews) / len(reviews) if reviews else 0
    return jsonify(
        success(
            {
                "reviews": reviews,
                "rating_average": round(average, 2),
                "review_count": len(reviews),
            }
        )
    )


@trust_safety_blueprint.post("/review-requests")
def create_review_request() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    booking = _booking_for_party(str(payload.get("booking_id", "")).strip(), user)
    if booking.status != "secured":
        raise APIError(
            "review_request.not_eligible",
            "Booking is not eligible for a review request yet.",
            status=409,
        )
    requested_from_id = _counterpart(booking, user.id)
    item = ReviewRequest(
        booking_id=booking.id,
        requested_by=user.id,
        requested_from=requested_from_id,
        sent_at=utc_now(),
    )
    db.session.add(item)
    notify_user(
        requested_from_id,
        category="reviews",
        title="Review requested",
        body=f"{user.display_name} would like you to leave a review.",
        route_name="/review",
        route_params={"booking_id": booking.public_id},
    )
    db.session.commit()
    return jsonify(
        success(
            {
                "review_request": {
                    "public_id": item.public_id,
                    "booking_id": booking.public_id,
                    "status": item.status,
                }
            }
        )
    ), 201


# ---------------------------------------------------------------------------
# Reports and blocks
# ---------------------------------------------------------------------------


@trust_safety_blueprint.get("/reports/reasons")
def report_reasons() -> Response:
    return jsonify(success({"reasons": list(REPORT_REASONS)}))


@trust_safety_blueprint.post("/reports")
def create_report() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    reason = str(payload.get("reason", "")).strip()
    if reason not in REPORT_REASONS:
        raise _field_error("reason", "Unsupported report reason.")
    entity_type = str(payload.get("entity_type", "user")).strip()[:64] or "user"
    entity_id = str(payload.get("entity_id", "")).strip()[:40]
    if not entity_id:
        raise _field_error("entity_id", "Reported entity id is required.")
    reported_user = None
    reported_user_public_id = str(payload.get("reported_user_id", "")).strip()
    if reported_user_public_id:
        reported_user = db.session.execute(
            select(User).where(User.public_id == reported_user_public_id)
        ).scalar_one_or_none()
    report = Report(
        reporter_user_id=user.id,
        reported_user_id=reported_user.id if reported_user else None,
        entity_type=entity_type,
        entity_id=entity_id,
        reason=reason,
        description=str(payload.get("description", "")).strip()[:2000] or None,
    )
    db.session.add(report)
    if entity_type != "user":
        db.session.add(
            ModerationCase(
                entity_type=entity_type,
                entity_id=entity_id,
                source="user_report",
                risk_level="medium",
            )
        )
    db.session.commit()
    return jsonify(success({"report": _report_payload(report)})), 201


@trust_safety_blueprint.post("/blocked-users")
def create_blocked_user() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    target = db.session.execute(
        select(User).where(User.public_id == str(payload.get("user_id", "")).strip())
    ).scalar_one_or_none()
    if target is None:
        raise _field_error("user_id", "User was not found.")
    if target.id == user.id:
        raise _field_error("user_id", "You cannot block yourself.")
    existing = db.session.execute(
        select(BlockedUser).where(
            BlockedUser.blocker_user_id == user.id,
            BlockedUser.blocked_user_id == target.id,
        )
    ).scalar_one_or_none()
    if existing is None:
        existing = BlockedUser(
            blocker_user_id=user.id,
            blocked_user_id=target.id,
            reason=str(payload.get("reason", "")).strip()[:255] or None,
        )
        db.session.add(existing)
        db.session.commit()
    return jsonify(success({"blocked_user": _user_payload(target)})), 201


@trust_safety_blueprint.get("/blocked-users")
def list_blocked_users() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(BlockedUser).where(BlockedUser.blocker_user_id == user.id)
    ).scalars()
    return jsonify(
        success(
            {
                "blocked_users": [
                    {"user": _user_payload(row.blocked), "reason": row.reason}
                    for row in rows
                ]
            }
        )
    )


@trust_safety_blueprint.delete("/blocked-users/<public_id>")
def delete_blocked_user(public_id: str) -> Response:
    user = _current_user()
    row = db.session.execute(
        select(BlockedUser)
        .join(User, User.id == BlockedUser.blocked_user_id)
        .where(BlockedUser.blocker_user_id == user.id, User.public_id == public_id)
    ).scalar_one_or_none()
    if row is not None:
        db.session.delete(row)
        db.session.commit()
    return jsonify(success({"unblocked": True}))


# ---------------------------------------------------------------------------
# Moderation (admin)
# ---------------------------------------------------------------------------


@trust_safety_blueprint.post("/admin/moderation-cases")
def create_moderation_case() -> ResponseReturnValue:
    user = _current_user()
    _require_moderation(user)
    payload = _json_body()
    case = ModerationCase(
        entity_type=str(payload.get("entity_type", "")).strip()[:64],
        entity_id=str(payload.get("entity_id", "")).strip()[:40],
        source="admin_initiated",
        risk_level=str(payload.get("risk_level", "medium")).strip()[:32],
        assigned_admin_id=user.id,
    )
    db.session.add(case)
    db.session.flush()
    db.session.add(
        ModerationEvent(
            case_id=case.id,
            actor_user_id=user.id,
            action="opened",
            to_status=case.status,
        )
    )
    db.session.commit()
    return jsonify(success({"case": _moderation_case_payload(case)})), 201


@trust_safety_blueprint.get("/admin/moderation-cases")
def admin_moderation_cases() -> Response:
    user = _current_user()
    _require_moderation(user)
    query = select(ModerationCase)
    status_filter = request.args.get("status")
    if status_filter:
        query = query.where(ModerationCase.status == status_filter)
    rows = db.session.execute(
        query.order_by(ModerationCase.created_at.desc()).limit(100)
    ).scalars()
    return jsonify(success({"cases": [_moderation_case_payload(row) for row in rows]}))


@trust_safety_blueprint.get("/admin/moderation-cases/<public_id>")
def admin_moderation_case_detail(public_id: str) -> Response:
    user = _current_user()
    _require_moderation(user)
    case = db.session.execute(
        select(ModerationCase).where(ModerationCase.public_id == public_id)
    ).scalar_one_or_none()
    if case is None:
        raise APIError(
            "moderation_case.not_found", "Moderation case was not found.", status=404
        )
    return jsonify(success({"case": _moderation_case_payload(case)}))


@trust_safety_blueprint.post("/admin/moderation-cases/<public_id>/decision")
def admin_moderation_case_decision(public_id: str) -> Response:
    user = _current_user()
    _require_moderation(user)
    case = db.session.execute(
        select(ModerationCase).where(ModerationCase.public_id == public_id)
    ).scalar_one_or_none()
    if case is None:
        raise APIError(
            "moderation_case.not_found", "Moderation case was not found.", status=404
        )
    payload = _json_body()
    decision = str(payload.get("decision", "")).strip()
    if decision not in {"approved", "rejected", "escalated"}:
        raise _field_error("decision", "Unsupported moderation decision.")
    from_status = case.status
    case.assigned_admin_id = case.assigned_admin_id or user.id
    case.decision = decision
    case.decision_reason = str(payload.get("reason", "")).strip()[:2000] or None
    case.status = "escalated" if decision == "escalated" else "resolved"
    db.session.add(
        ModerationEvent(
            case_id=case.id,
            actor_user_id=user.id,
            action="decision",
            from_status=from_status,
            to_status=case.status,
            notes=case.decision_reason,
        )
    )
    db.session.commit()
    return jsonify(success({"case": _moderation_case_payload(case)}))


# ---------------------------------------------------------------------------
# Disputes
# ---------------------------------------------------------------------------


@trust_safety_blueprint.post("/disputes")
def create_dispute() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    booking = _booking_for_party(str(payload.get("booking_id", "")).strip(), user)
    description = str(payload.get("description", "")).strip()
    if not description:
        raise _field_error("description", "Describe the booking issue.")
    dispute = Dispute(
        booking_id=booking.id,
        opened_by=user.id,
        respondent_user_id=_counterpart(booking, user.id),
        type=str(payload.get("type", "general")).strip()[:64],
        description=description[:4000],
        value_minor=int(payload.get("value_minor") or 0) or None,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        severity=str(payload.get("severity", "medium")).strip()[:32],
    )
    db.session.add(dispute)
    db.session.flush()
    db.session.add(
        DisputeEvent(
            dispute_id=dispute.id,
            actor_user_id=user.id,
            event_type="opened",
        )
    )
    db.session.commit()
    return jsonify(success({"dispute": _dispute_payload(dispute)})), 201


def _dispute_for_party(public_id: str, user: User) -> Dispute:
    dispute = db.session.execute(
        select(Dispute).where(Dispute.public_id == public_id)
    ).scalar_one_or_none()
    if dispute is None or user.id not in {
        dispute.opened_by,
        dispute.respondent_user_id,
    }:
        raise APIError("dispute.not_found", "Dispute was not found.", status=404)
    return dispute


@trust_safety_blueprint.get("/disputes")
def list_disputes() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(Dispute)
        .where(or_(Dispute.opened_by == user.id, Dispute.respondent_user_id == user.id))
        .order_by(Dispute.created_at.desc())
    ).scalars()
    return jsonify(success({"disputes": [_dispute_payload(row) for row in rows]}))


@trust_safety_blueprint.get("/disputes/<public_id>")
def dispute_detail(public_id: str) -> Response:
    user = _current_user()
    dispute = _dispute_for_party(public_id, user)
    return jsonify(success({"dispute": _dispute_payload(dispute)}))


@trust_safety_blueprint.post("/disputes/<public_id>/evidence")
def add_dispute_evidence(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    dispute = _dispute_for_party(public_id, user)
    if dispute.status in {"resolved", "rejected"}:
        raise APIError(
            "dispute.closed",
            "Evidence cannot be added to a closed dispute.",
            status=409,
        )
    payload = _json_body()
    file = None
    if str(payload.get("file_id", "")).strip():
        file = _owned_ready_file(
            str(payload.get("file_id")).strip(), user.id, "file_id"
        )
    description = str(payload.get("description", "")).strip()
    if file is None and not description:
        raise _field_error(
            "description",
            "Add a note or attach a file as evidence.",
        )
    evidence = DisputeEvidence(
        dispute_id=dispute.id,
        submitted_by=user.id,
        file_id=file.id if file else None,
        evidence_type=str(payload.get("evidence_type", "note")).strip()[:64],
        description=description[:2000] or None,
    )
    db.session.add(evidence)
    db.session.add(
        DisputeEvent(
            dispute_id=dispute.id,
            actor_user_id=user.id,
            event_type="evidence_submitted",
        )
    )
    db.session.commit()
    return jsonify(success({"dispute": _dispute_payload(dispute)})), 201


@trust_safety_blueprint.get("/admin/disputes")
def admin_disputes() -> Response:
    user = _current_user()
    _require_dispute_admin(user)
    query = select(Dispute)
    status_filter = request.args.get("status")
    if status_filter:
        query = query.where(Dispute.status == status_filter)
    rows = db.session.execute(
        query.order_by(Dispute.created_at.desc()).limit(100)
    ).scalars()
    return jsonify(success({"disputes": [_dispute_payload(row) for row in rows]}))


@trust_safety_blueprint.get("/admin/disputes/<public_id>")
def admin_dispute_detail(public_id: str) -> Response:
    user = _current_user()
    _require_dispute_admin(user)
    dispute = db.session.execute(
        select(Dispute).where(Dispute.public_id == public_id)
    ).scalar_one_or_none()
    if dispute is None:
        raise APIError("dispute.not_found", "Dispute was not found.", status=404)
    return jsonify(success({"dispute": _dispute_payload(dispute)}))


@trust_safety_blueprint.post("/admin/disputes/<public_id>/decision")
def admin_dispute_decision(public_id: str) -> Response:
    user = _current_user()
    _require_dispute_admin(user)
    dispute = db.session.execute(
        select(Dispute).where(Dispute.public_id == public_id)
    ).scalar_one_or_none()
    if dispute is None:
        raise APIError("dispute.not_found", "Dispute was not found.", status=404)
    payload = _json_body()
    decision = str(payload.get("decision", "")).strip()
    if decision not in {"resolved", "rejected", "escalated"}:
        raise _field_error("decision", "Unsupported dispute decision.")
    note = str(payload.get("note", "")).strip()[:2000] or None
    dispute.assigned_admin_id = dispute.assigned_admin_id or user.id
    dispute.status = decision
    if decision in {"resolved", "rejected"}:
        dispute.resolved_at = utc_now()
    db.session.add(
        DisputeEvent(
            dispute_id=dispute.id,
            actor_user_id=user.id,
            event_type=f"decision_{decision}",
            note=note,
        )
    )
    for recipient_id in {dispute.opened_by, dispute.respondent_user_id}:
        notify_user(
            recipient_id,
            category="disputes",
            title="Dispute update",
            body=f"Your dispute status changed to {decision}.",
            route_name="/report",
            route_params={"dispute_id": dispute.public_id},
        )
    db.session.commit()
    return jsonify(success({"dispute": _dispute_payload(dispute)}))


# ---------------------------------------------------------------------------
# Support tickets
# ---------------------------------------------------------------------------


@trust_safety_blueprint.post("/support-tickets")
def create_support_ticket() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    subject = str(payload.get("subject", "")).strip()
    if len(subject) < 2:
        raise _field_error("subject", "Subject is required.")
    body = str(payload.get("message", "")).strip()
    if not body:
        raise _field_error("message", "An initial message is required.")
    booking = None
    booking_public_id = str(payload.get("booking_id", "")).strip()
    if booking_public_id:
        booking = _booking_for_party(booking_public_id, user)
    ticket = SupportTicket(
        user_id=user.id,
        booking_id=booking.id if booking else None,
        category=str(payload.get("category", "general")).strip()[:64],
        priority=str(payload.get("priority", "normal")).strip()[:32],
        subject=subject[:180],
        last_message_at=utc_now(),
    )
    db.session.add(ticket)
    db.session.flush()
    db.session.add(
        SupportMessage(ticket_id=ticket.id, sender_user_id=user.id, body=body[:4000])
    )
    db.session.commit()
    return jsonify(
        success({"ticket": _support_ticket_payload(ticket, include_internal=False)})
    ), 201


@trust_safety_blueprint.get("/support-tickets")
def list_support_tickets() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(SupportTicket)
        .where(SupportTicket.user_id == user.id)
        .order_by(SupportTicket.created_at.desc())
    ).scalars()
    return jsonify(
        success(
            {
                "tickets": [
                    _support_ticket_payload(row, include_internal=False) for row in rows
                ]
            }
        )
    )


def _ticket_for_viewer(public_id: str, user: User) -> tuple[SupportTicket, bool]:
    ticket = db.session.execute(
        select(SupportTicket).where(SupportTicket.public_id == public_id)
    ).scalar_one_or_none()
    if ticket is None:
        raise APIError("support_ticket.not_found", "Ticket was not found.", status=404)
    is_admin = _has_role(user, "support_agent", "reviewer", "super_admin")
    if ticket.user_id != user.id and not is_admin:
        raise APIError(
            "support_ticket.permission_denied", "Ticket is not visible.", status=403
        )
    return ticket, is_admin


@trust_safety_blueprint.get("/support-tickets/<public_id>")
def support_ticket_detail(public_id: str) -> Response:
    user = _current_user()
    ticket, is_admin = _ticket_for_viewer(public_id, user)
    return jsonify(
        success({"ticket": _support_ticket_payload(ticket, include_internal=is_admin)})
    )


@trust_safety_blueprint.post("/support-tickets/<public_id>/messages")
def create_support_message(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    ticket, is_admin = _ticket_for_viewer(public_id, user)
    payload = _json_body()
    body = str(payload.get("body", "")).strip()
    if not body:
        raise _field_error("body", "Message body is required.")
    internal_note = bool(payload.get("internal_note", False)) and is_admin
    file = None
    if str(payload.get("file_id", "")).strip():
        file = _owned_ready_file(
            str(payload.get("file_id")).strip(), user.id, "file_id"
        )
    db.session.add(
        SupportMessage(
            ticket_id=ticket.id,
            sender_user_id=user.id,
            body=body[:4000],
            file_id=file.id if file else None,
            internal_note=internal_note,
        )
    )
    ticket.last_message_at = utc_now()
    if is_admin:
        ticket.assigned_admin_id = ticket.assigned_admin_id or user.id
        if ticket.status == "open":
            ticket.status = "in_progress"
        if not internal_note:
            notify_user(
                ticket.user_id,
                category="support",
                title="Support reply received",
                body=f"New reply on your ticket: {ticket.subject}",
                route_name="/settings",
                route_params={"ticket_id": ticket.public_id},
            )
    db.session.commit()
    return jsonify(
        success({"ticket": _support_ticket_payload(ticket, include_internal=is_admin)})
    ), 201


@trust_safety_blueprint.get("/admin/support-tickets")
def admin_support_tickets() -> Response:
    user = _current_user()
    _require_support_admin(user)
    query = select(SupportTicket)
    status_filter = request.args.get("status")
    if status_filter:
        query = query.where(SupportTicket.status == status_filter)
    rows = db.session.execute(
        query.order_by(SupportTicket.created_at.desc()).limit(100)
    ).scalars()
    return jsonify(
        success(
            {
                "tickets": [
                    _support_ticket_payload(row, include_internal=True) for row in rows
                ]
            }
        )
    )


@trust_safety_blueprint.patch("/admin/support-tickets/<public_id>")
def update_support_ticket(public_id: str) -> Response:
    user = _current_user()
    _require_support_admin(user)
    ticket = db.session.execute(
        select(SupportTicket).where(SupportTicket.public_id == public_id)
    ).scalar_one_or_none()
    if ticket is None:
        raise APIError("support_ticket.not_found", "Ticket was not found.", status=404)
    payload = _json_body()
    if "status" in payload:
        ticket.status = str(payload.get("status", "")).strip()[:32]
    if "priority" in payload:
        ticket.priority = str(payload.get("priority", "")).strip()[:32]
    if payload.get("assign_to_me"):
        ticket.assigned_admin_id = user.id
    db.session.commit()
    return jsonify(
        success({"ticket": _support_ticket_payload(ticket, include_internal=True)})
    )


# ---------------------------------------------------------------------------
# Announcements
# ---------------------------------------------------------------------------


def _announcement_audience_user_ids(audience: dict[str, Any]) -> list[Any]:
    roles = audience.get("roles") if isinstance(audience, dict) else None
    query = select(User.id).where(User.status == "active")
    if roles and roles != ["all"]:
        from app.models.identity import Role, UserRole

        query = (
            select(User.id)
            .join(UserRole, UserRole.user_id == User.id)
            .join(Role, Role.id == UserRole.role_id)
            .where(
                User.status == "active",
                UserRole.status == "active",
                Role.code.in_(roles),
            )
            .distinct()
        )
    return list(db.session.execute(query).scalars())


@trust_safety_blueprint.post("/admin/announcements")
def create_announcement() -> ResponseReturnValue:
    user = _current_user()
    _require_super_admin(user)
    payload = _json_body()
    title = str(payload.get("title", "")).strip()
    if len(title) < 2:
        raise _field_error("title", "Announcement title is required.")
    scheduled_at = (
        _parse_datetime(payload["scheduled_at"], "scheduled_at")
        if payload.get("scheduled_at")
        else None
    )
    announcement = Announcement(
        title=title[:180],
        body=str(payload.get("body", "")).strip()[:4000],
        audience_json=json.dumps(payload.get("audience", {"roles": ["all"]})),
        channel_json=json.dumps(payload.get("channels", ["in_app"])),
        status="scheduled" if scheduled_at else "draft",
        scheduled_at=scheduled_at,
        created_by=user.id,
    )
    db.session.add(announcement)
    db.session.commit()
    return jsonify(success({"announcement": _announcement_payload(announcement)})), 201


@trust_safety_blueprint.get("/admin/announcements")
def admin_announcements() -> Response:
    user = _current_user()
    _require_super_admin(user)
    rows = db.session.execute(
        select(Announcement).order_by(Announcement.created_at.desc()).limit(100)
    ).scalars()
    return jsonify(
        success({"announcements": [_announcement_payload(row) for row in rows]})
    )


@trust_safety_blueprint.post("/admin/announcements/<public_id>/publish")
def publish_announcement(public_id: str) -> Response:
    user = _current_user()
    _require_super_admin(user)
    announcement = db.session.execute(
        select(Announcement).where(Announcement.public_id == public_id)
    ).scalar_one_or_none()
    if announcement is None:
        raise APIError(
            "announcement.not_found", "Announcement was not found.", status=404
        )
    audience = (
        json.loads(announcement.audience_json) if announcement.audience_json else {}
    )
    for recipient_id in _announcement_audience_user_ids(audience):
        notify_user(
            recipient_id,
            category="announcements",
            title=announcement.title,
            body=announcement.body,
            route_name="/notifications",
        )
    announcement.status = "published"
    announcement.published_at = utc_now()
    db.session.commit()
    return jsonify(success({"announcement": _announcement_payload(announcement)}))


# ---------------------------------------------------------------------------
# Notifications and push devices
# ---------------------------------------------------------------------------


@trust_safety_blueprint.get("/notifications")
def list_notifications() -> Response:
    user = _current_user()
    query = select(Notification).where(Notification.user_id == user.id)
    if request.args.get("unread") == "true":
        query = query.where(Notification.read_at.is_(None))
    rows = db.session.execute(
        query.order_by(Notification.created_at.desc()).limit(100)
    ).scalars()
    unread_count = db.session.execute(
        select(func.count()).where(
            Notification.user_id == user.id, Notification.read_at.is_(None)
        )
    ).scalar_one()
    return jsonify(
        success(
            {
                "notifications": [_notification_payload(row) for row in rows],
                "unread_count": unread_count,
            }
        )
    )


@trust_safety_blueprint.patch("/notifications/<public_id>/read")
def mark_notification_read(public_id: str) -> Response:
    user = _current_user()
    notification = db.session.execute(
        select(Notification).where(
            Notification.public_id == public_id, Notification.user_id == user.id
        )
    ).scalar_one_or_none()
    if notification is None:
        raise APIError(
            "notification.not_found", "Notification was not found.", status=404
        )
    notification.read_at = notification.read_at or utc_now()
    db.session.commit()
    return jsonify(success({"notification": _notification_payload(notification)}))


@trust_safety_blueprint.post("/notifications/read-all")
def mark_all_notifications_read() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(Notification).where(
            Notification.user_id == user.id, Notification.read_at.is_(None)
        )
    ).scalars()
    now = utc_now()
    count = 0
    for row in rows:
        row.read_at = now
        count += 1
    db.session.commit()
    return jsonify(success({"marked_read": count}))


@trust_safety_blueprint.post("/push-devices")
def register_push_device() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    device_id = str(payload.get("device_id", "")).strip()
    if not device_id:
        raise _field_error("device_id", "Device id is required.")
    device = db.session.execute(
        select(PushDevice).where(
            PushDevice.user_id == user.id, PushDevice.device_id == device_id
        )
    ).scalar_one_or_none()
    if device is None:
        device = PushDevice(user_id=user.id, device_id=device_id, platform="android")
        db.session.add(device)
    device.platform = str(payload.get("platform", device.platform)).strip()[:32]
    device.token_reference = "encrypted:pending" if payload.get("token") else None
    device.enabled = bool(payload.get("enabled", True))
    device.last_seen_at = utc_now()
    db.session.commit()
    return jsonify(
        success(
            {
                "push_device": {
                    "device_id": device.device_id,
                    "platform": device.platform,
                    "enabled": device.enabled,
                }
            }
        )
    ), 201
