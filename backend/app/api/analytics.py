from __future__ import annotations

import csv
import io
import json
from datetime import UTC, timedelta
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import func, or_, select

from app.api.auth import _current_user, _json_body
from app.errors import APIError
from app.extensions import db
from app.models.analytics import ExportJob
from app.models.base import utc_now
from app.models.bookings import Booking, BookingStatusEvent
from app.models.identity import User
from app.models.kyc import KycSubmission, VerificationEvent
from app.models.marketplace import UserProfile
from app.models.payments import BookingFeeSnapshot, PaymentProof
from app.models.trust_safety import (
    Dispute,
    ModerationCase,
    ModerationEvent,
    Notification,
    SupportTicket,
)
from app.responses import success

analytics_blueprint = Blueprint("analytics", __name__)

OFFER_STATUSES = {"sent", "viewed", "under_negotiation"}
OPEN_DISPUTE_STATUSES = {"open"}
OPEN_TICKET_STATUSES = {"open", "in_progress"}
OPEN_MODERATION_STATUSES = {"queued"}


def _has_role(user: User, *codes: str) -> bool:
    return any(
        user_role.status == "active" and user_role.role.code in codes
        for user_role in user.roles
    )


def _require_admin(user: User) -> None:
    if not _has_role(user, "reviewer", "finance_admin", "support_agent", "super_admin"):
        raise APIError(
            "analytics.permission_denied", "An admin role is required.", status=403
        )


@analytics_blueprint.get("/me/dashboard")
def my_dashboard() -> Response:
    user = _current_user()

    profile = db.session.execute(
        select(UserProfile).where(UserProfile.user_id == user.id)
    ).scalar_one_or_none()

    booking_party = or_(
        Booking.requester_user_id == user.id, Booking.provider_user_id == user.id
    )
    pending_offers = db.session.execute(
        select(func.count()).where(booking_party, Booking.status.in_(OFFER_STATUSES))
    ).scalar_one()
    secured_value_minor = int(
        db.session.execute(
            select(func.coalesce(func.sum(Booking.agreed_amount_minor), 0)).where(
                booking_party, Booking.status == "secured"
            )
        ).scalar_one()
        or 0
    )

    unread_notifications = db.session.execute(
        select(func.count()).where(
            Notification.user_id == user.id, Notification.read_at.is_(None)
        )
    ).scalar_one()

    open_disputes = db.session.execute(
        select(func.count()).where(
            or_(Dispute.opened_by == user.id, Dispute.respondent_user_id == user.id),
            Dispute.status.in_(OPEN_DISPUTE_STATUSES),
        )
    ).scalar_one()

    open_support_tickets = db.session.execute(
        select(func.count()).where(
            SupportTicket.user_id == user.id,
            SupportTicket.status.in_(OPEN_TICKET_STATUSES),
        )
    ).scalar_one()

    pending_kyc = db.session.execute(
        select(func.count()).where(
            KycSubmission.user_id == user.id,
            KycSubmission.status.in_(("pending", "needs_resubmission")),
        )
    ).scalar_one()

    return jsonify(
        success(
            {
                "rating_average": float(profile.rating_average) if profile else 0.0,
                "review_count": profile.review_count if profile else 0,
                "pending_offers": pending_offers,
                "secured_value_minor": secured_value_minor,
                "unread_notifications": unread_notifications,
                "open_disputes": open_disputes,
                "open_support_tickets": open_support_tickets,
                "pending_kyc": pending_kyc,
            }
        )
    )


@analytics_blueprint.get("/admin/dashboard")
def admin_dashboard() -> Response:
    user = _current_user()
    _require_admin(user)

    pending_kyc_rows = (
        db.session.execute(
            select(KycSubmission.submitted_at).where(
                KycSubmission.status.in_(("pending", "needs_resubmission")),
                KycSubmission.submitted_at.is_not(None),
            )
        )
        .scalars()
        .all()
    )
    now = utc_now()
    submitted_ats = [
        submitted if submitted.tzinfo else submitted.replace(tzinfo=UTC)
        for submitted in pending_kyc_rows
        if submitted is not None
    ]
    oldest_pending_kyc_hours = (
        max((now - submitted).total_seconds() / 3600 for submitted in submitted_ats)
        if submitted_ats
        else 0.0
    )

    pending_payment_proofs = db.session.execute(
        select(func.count()).where(PaymentProof.status == "pending")
    ).scalar_one()
    pending_moderation_cases = db.session.execute(
        select(func.count()).where(ModerationCase.status.in_(OPEN_MODERATION_STATUSES))
    ).scalar_one()
    open_disputes = db.session.execute(
        select(func.count()).where(Dispute.status.in_(OPEN_DISPUTE_STATUSES))
    ).scalar_one()
    open_support_tickets = db.session.execute(
        select(func.count()).where(SupportTicket.status.in_(OPEN_TICKET_STATUSES))
    ).scalar_one()
    total_users = db.session.execute(
        select(func.count()).select_from(User)
    ).scalar_one()

    calculated_platform_fees_minor = int(
        db.session.execute(
            select(func.coalesce(func.sum(BookingFeeSnapshot.fee_minor), 0))
        ).scalar_one()
    )

    secured_bookings = db.session.execute(
        select(func.count()).where(Booking.status == "secured")
    ).scalar_one()
    sent_bookings = db.session.execute(
        select(func.count()).where(
            Booking.status.in_(OFFER_STATUSES | {"secured", "accepted", "rejected"})
        )
    ).scalar_one()
    conversion_rate = (
        round(secured_bookings / sent_bookings, 4) if sent_bookings else 0.0
    )

    return jsonify(
        success(
            {
                "pending_kyc_count": len(pending_kyc_rows),
                "oldest_pending_kyc_hours": round(oldest_pending_kyc_hours, 1),
                "pending_payment_proofs": pending_payment_proofs,
                "pending_moderation_cases": pending_moderation_cases,
                "open_disputes": open_disputes,
                "open_support_tickets": open_support_tickets,
                "total_users": total_users,
                "calculated_platform_fees_minor": calculated_platform_fees_minor,
                "secured_bookings": secured_bookings,
                "conversion_rate": conversion_rate,
            }
        )
    )


@analytics_blueprint.get("/admin/analytics")
def admin_analytics() -> Response:
    user = _current_user()
    _require_admin(user)
    days = max(1, min(int(request.args.get("days", 30) or 30), 90))
    since = utc_now() - timedelta(days=days)

    def _daily_counts(model_column: Any, where_clause: Any) -> dict[str, int]:
        rows = db.session.execute(
            select(func.date(model_column), func.count())
            .where(where_clause)
            .group_by(func.date(model_column))
            .order_by(func.date(model_column))
        ).all()
        return {str(day): count for day, count in rows}

    new_users_by_day = _daily_counts(User.created_at, User.created_at >= since)
    new_bookings_by_day = _daily_counts(Booking.created_at, Booking.created_at >= since)
    secured_bookings_by_day = _daily_counts(
        Booking.created_at,
        (Booking.created_at >= since) & (Booking.status == "secured"),
    )

    return jsonify(
        success(
            {
                "range_days": days,
                "new_users_by_day": new_users_by_day,
                "new_bookings_by_day": new_bookings_by_day,
                "secured_bookings_by_day": secured_bookings_by_day,
            }
        )
    )


EXPORT_TYPES = {"ledger", "bookings", "admin_disputes", "admin_audit_events"}
EXPORT_ROW_LIMIT = 2000


def _export_payload(item: ExportJob) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "export_type": item.export_type,
        "status": item.status,
        "row_count": item.row_count,
        "error_message": item.error_message,
        "requested_at": item.requested_at.isoformat(),
        "completed_at": item.completed_at.isoformat() if item.completed_at else None,
        "csv_content": item.csv_content,
    }


def _write_csv(header: list[str], rows: list[list[Any]]) -> str:
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(header)
    writer.writerows(rows)
    return buffer.getvalue()


def _run_ledger_export(user: User) -> tuple[str, int]:
    from app.models.payments import LedgerEntry

    rows = (
        db.session.execute(
            select(LedgerEntry)
            .where(LedgerEntry.user_id == user.id)
            .order_by(LedgerEntry.occurred_at.desc())
            .limit(EXPORT_ROW_LIMIT)
        )
        .scalars()
        .all()
    )
    csv_text = _write_csv(
        [
            "public_id",
            "entry_type",
            "direction",
            "amount_minor",
            "currency",
            "status",
            "occurred_at",
        ],
        [
            [
                row.public_id,
                row.entry_type,
                row.direction,
                row.amount_minor,
                row.currency,
                row.status,
                row.occurred_at.isoformat(),
            ]
            for row in rows
        ],
    )
    return csv_text, len(rows)


def _run_bookings_export(user: User) -> tuple[str, int]:
    rows = (
        db.session.execute(
            select(Booking)
            .where(
                or_(
                    Booking.requester_user_id == user.id,
                    Booking.provider_user_id == user.id,
                )
            )
            .order_by(Booking.created_at.desc())
            .limit(EXPORT_ROW_LIMIT)
        )
        .scalars()
        .all()
    )
    csv_text = _write_csv(
        [
            "public_id",
            "status",
            "category",
            "agreed_amount_minor",
            "currency",
            "start_at",
            "end_at",
        ],
        [
            [
                row.public_id,
                row.status,
                row.category,
                row.agreed_amount_minor,
                row.currency,
                row.start_at.isoformat(),
                row.end_at.isoformat(),
            ]
            for row in rows
        ],
    )
    return csv_text, len(rows)


def _run_admin_disputes_export(user: User) -> tuple[str, int]:
    _require_admin(user)
    rows = (
        db.session.execute(
            select(Dispute).order_by(Dispute.created_at.desc()).limit(EXPORT_ROW_LIMIT)
        )
        .scalars()
        .all()
    )
    csv_text = _write_csv(
        [
            "public_id",
            "type",
            "status",
            "severity",
            "value_minor",
            "currency",
            "booking_id",
        ],
        [
            [
                row.public_id,
                row.type,
                row.status,
                row.severity,
                row.value_minor,
                row.currency,
                row.booking.public_id,
            ]
            for row in rows
        ],
    )
    return csv_text, len(rows)


def _run_admin_audit_events_export(user: User) -> tuple[str, int]:
    _require_admin(user)
    rows: list[tuple[Any, str, str, str, str, str]] = []

    verification_events = db.session.execute(
        select(VerificationEvent)
        .order_by(VerificationEvent.created_at.desc())
        .limit(EXPORT_ROW_LIMIT)
    ).scalars()
    for verification_event in verification_events:
        rows.append(
            (
                verification_event.created_at,
                (
                    "kyc:"
                    f"{verification_event.submission.public_id}:"
                    f"{verification_event.id}"
                ),
                "verification",
                verification_event.submission.public_id,
                str(verification_event.actor_user_id or ""),
                (
                    f"{verification_event.from_status or 'new'}"
                    f" -> {verification_event.to_status}"
                    + (
                        f": {verification_event.reason}"
                        if verification_event.reason
                        else ""
                    )
                ),
            )
        )

    booking_events = db.session.execute(
        select(BookingStatusEvent)
        .order_by(BookingStatusEvent.created_at.desc())
        .limit(EXPORT_ROW_LIMIT)
    ).scalars()
    for booking_event in booking_events:
        rows.append(
            (
                booking_event.created_at,
                f"booking:{booking_event.booking.public_id}:{booking_event.id}",
                "booking",
                booking_event.booking.public_id,
                str(booking_event.actor_user_id or ""),
                f"{booking_event.from_status or 'new'} -> {booking_event.to_status}"
                + (f": {booking_event.reason}" if booking_event.reason else ""),
            )
        )

    payment_events = db.session.execute(
        select(PaymentProof)
        .where(PaymentProof.reviewed_at.is_not(None))
        .order_by(PaymentProof.reviewed_at.desc())
        .limit(EXPORT_ROW_LIMIT)
    ).scalars()
    for proof in payment_events:
        rows.append(
            (
                proof.reviewed_at or proof.updated_at,
                f"payment:{proof.public_id}",
                "payment",
                proof.public_id,
                str(proof.reviewed_by or ""),
                f"Proof reviewed as {proof.status}"
                + (f": {proof.rejection_reason}" if proof.rejection_reason else ""),
            )
        )

    moderation_events = db.session.execute(
        select(ModerationEvent)
        .order_by(ModerationEvent.created_at.desc())
        .limit(EXPORT_ROW_LIMIT)
    ).scalars()
    for moderation_event in moderation_events:
        rows.append(
            (
                moderation_event.created_at,
                (f"moderation:{moderation_event.case.public_id}:{moderation_event.id}"),
                "moderation",
                moderation_event.case.entity_id,
                str(moderation_event.actor_user_id),
                moderation_event.action
                + (f": {moderation_event.notes}" if moderation_event.notes else ""),
            )
        )

    rows.sort(key=lambda row: row[0], reverse=True)
    rows = rows[:EXPORT_ROW_LIMIT]
    csv_text = _write_csv(
        [
            "occurred_at",
            "event_id",
            "event_type",
            "entity_id",
            "actor_user_id",
            "description",
        ],
        [
            [
                occurred_at.isoformat(),
                event_id,
                event_type,
                entity_id,
                actor_user_id,
                description,
            ]
            for (
                occurred_at,
                event_id,
                event_type,
                entity_id,
                actor_user_id,
                description,
            ) in rows
        ],
    )
    return csv_text, len(rows)


@analytics_blueprint.post("/exports")
def create_export() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    export_type = str(payload.get("export_type", "")).strip()
    if export_type not in EXPORT_TYPES:
        raise APIError(
            "export.unsupported_type",
            "Unsupported export type.",
            status=422,
            fields={"export_type": ["Unsupported export type."]},
        )
    job = ExportJob(
        requested_by=user.id,
        export_type=export_type,
        filters_json=json.dumps(payload.get("filters", {})),
        status="processing",
        requested_at=utc_now(),
    )
    db.session.add(job)
    try:
        if export_type == "ledger":
            csv_text, row_count = _run_ledger_export(user)
        elif export_type == "bookings":
            csv_text, row_count = _run_bookings_export(user)
        elif export_type == "admin_disputes":
            csv_text, row_count = _run_admin_disputes_export(user)
        else:
            csv_text, row_count = _run_admin_audit_events_export(user)
        job.csv_content = csv_text
        job.row_count = row_count
        job.status = "completed"
        job.completed_at = utc_now()
    except APIError as exc:
        job.status = "failed"
        job.error_message = exc.message
        db.session.add(job)
        db.session.commit()
        raise
    db.session.commit()
    return jsonify(success({"export": _export_payload(job)})), 201


@analytics_blueprint.get("/exports")
def list_exports() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(ExportJob)
        .where(ExportJob.requested_by == user.id)
        .order_by(ExportJob.requested_at.desc())
        .limit(50)
    ).scalars()
    return jsonify(
        success(
            {"exports": [{**_export_payload(row), "csv_content": None} for row in rows]}
        )
    )


@analytics_blueprint.get("/exports/<public_id>")
def get_export(public_id: str) -> Response:
    user = _current_user()
    job = db.session.execute(
        select(ExportJob).where(
            ExportJob.public_id == public_id, ExportJob.requested_by == user.id
        )
    ).scalar_one_or_none()
    if job is None:
        raise APIError("export.not_found", "Export job was not found.", status=404)
    return jsonify(success({"export": _export_payload(job)}))
