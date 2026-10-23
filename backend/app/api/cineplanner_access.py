from __future__ import annotations

from typing import Any

from flask import Blueprint, Response, current_app, jsonify
from sqlalchemy import select

from app.api.auth import _current_user, _json_body
from app.errors import APIError
from app.extensions import db, limiter
from app.models.base import utc_now
from app.models.cineplanner_access import CineSubscriptionPayment
from app.models.files import FileAsset
from app.models.identity import User
from app.responses import success
from app.security import record_auth_event, verify_password
from app.services.cineplanner_access import (
    account_access,
    active,
    membership,
    next_month,
)

cineplanner_access_blueprint = Blueprint(
    "cineplanner_access", __name__, url_prefix="/cineplanner"
)


def _reviewer() -> User:
    user = _current_user()
    if not any(
        r.status == "active" and r.role.code in {"super_admin", "finance_admin"}
        for r in user.roles
    ):
        raise APIError(
            "auth.forbidden", "Payment review requires finance access.", status=403
        )
    return user


def _payment_payload(row: CineSubscriptionPayment) -> dict[str, Any]:
    user = db.session.get(User, row.user_id)
    file = db.session.get(FileAsset, row.proof_file_id)
    return {
        "public_id": row.public_id,
        "user_id": user.public_id if user else None,
        "name": user.display_name if user else "Account",
        "reference": row.reference,
        "amount_minor": row.amount_minor,
        "currency": row.currency,
        "status": row.status,
        "review_note": row.review_note,
        "created_at": row.created_at.isoformat(),
        "proof_file_id": file.public_id if file else None,
        "proof_url": f"/api/v1/files/{file.public_id}/download" if file else None,
    }


@cineplanner_access_blueprint.get("/membership")
def membership_show() -> Response:
    user = _current_user()
    payments = db.session.scalars(
        select(CineSubscriptionPayment)
        .where(CineSubscriptionPayment.user_id == user.id)
        .order_by(CineSubscriptionPayment.created_at.desc())
        .limit(12)
    ).all()
    return jsonify(
        success(
            {
                "access": account_access(user),
                "payments": [_payment_payload(p) for p in payments],
            }
        )
    )


@cineplanner_access_blueprint.post("/membership/unlock")
@limiter.limit("5 per hour; 15 per day")
def owner_unlock() -> Response:
    user = _current_user()
    value = _json_body().get("key")
    expected = str(current_app.config.get("CINEPLANNER_UNLOCK_HASH", ""))
    if (
        not isinstance(value, str)
        or len(value) > 128
        or not expected
        or not verify_password(expected, value)
    ):
        raise APIError(
            "cineplanner.invalid_access_key", "Access key was not accepted.", status=403
        )
    row = membership(user.id, create=True)
    assert row is not None
    row.access_mode = "owner"
    row.period_end = None
    record_auth_event("cineplanner_private_access", success=True, user=user)
    db.session.commit()
    return jsonify(success({"access": account_access(user)}))


@cineplanner_access_blueprint.post("/membership/payments")
@limiter.limit("10 per day")
def payment_submit() -> tuple[Response, int]:
    user = _current_user()
    payload = _json_body()
    row = membership(user.id, create=True)
    if active(row):
        raise APIError(
            "cineplanner.plan_active",
            "Your plan is already active. Renew after its current period ends.",
            status=409,
        )
    if db.session.scalar(
        select(CineSubscriptionPayment)
        .where(
            CineSubscriptionPayment.user_id == user.id,
            CineSubscriptionPayment.status == "pending",
        )
        .with_for_update()
    ):
        raise APIError(
            "cineplanner.payment_pending",
            "A payment is already awaiting review.",
            status=409,
        )
    reference = str(payload.get("reference", "")).strip()
    file = db.session.scalar(
        select(FileAsset).where(
            FileAsset.public_id == str(payload.get("file_id", "")),
            FileAsset.owner_user_id == user.id,
            FileAsset.scan_status == "clean",
            FileAsset.processing_status == "ready",
        )
    )
    if (
        not file
        or file.mime_type
        not in {"application/pdf", "image/jpeg", "image/png", "image/webp"}
        or not 3 <= len(reference) <= 160
    ):
        raise APIError(
            "validation.invalid",
            "Upload a ready payment receipt and provide its bank reference.",
            status=422,
        )
    if db.session.scalar(
        select(CineSubscriptionPayment).where(
            CineSubscriptionPayment.proof_file_id == file.id
        )
    ):
        raise APIError(
            "cineplanner.receipt_used",
            "This receipt has already been submitted.",
            status=409,
        )
    payment = CineSubscriptionPayment(
        user_id=user.id,
        proof_file_id=file.id,
        reference=reference,
        amount_minor=2000,
        currency="USD",
        status="pending",
    )
    db.session.add(payment)
    db.session.commit()
    return jsonify(success({"payment": _payment_payload(payment)})), 201


@cineplanner_access_blueprint.get("/membership/review")
def payment_queue() -> Response:
    _reviewer()
    rows = db.session.scalars(
        select(CineSubscriptionPayment)
        .order_by(CineSubscriptionPayment.created_at.desc())
        .limit(100)
    ).all()
    return jsonify(success({"payments": [_payment_payload(p) for p in rows]}))


@cineplanner_access_blueprint.post("/membership/review/<public_id>")
def payment_decision(public_id: str) -> Response:
    reviewer = _reviewer()
    payload = _json_body()
    payment = db.session.scalar(
        select(CineSubscriptionPayment)
        .where(CineSubscriptionPayment.public_id == public_id)
        .with_for_update()
    )
    if payment is None:
        raise APIError(
            "cineplanner.payment_not_found", "Payment was not found.", status=404
        )
    decision = str(payload.get("decision", ""))
    if decision not in {"approved", "rejected"}:
        raise APIError("validation.invalid", "Choose approved or rejected.", status=422)
    if payment.status != "pending":
        if payment.status == decision:
            return jsonify(success({"payment": _payment_payload(payment)}))
        raise APIError(
            "cineplanner.already_reviewed",
            "This payment has already been reviewed.",
            status=409,
        )
    if payment.user_id == reviewer.id:
        raise APIError(
            "cineplanner.self_review",
            "A different finance reviewer must verify this payment.",
            status=403,
        )
    if decision == "approved":
        row = membership(payment.user_id, create=True)
        assert row is not None
        if active(row):
            raise APIError(
                "cineplanner.plan_active",
                "This account already has active access.",
                status=409,
            )
        row.access_mode = "subscription"
        row.period_start = utc_now()
        row.period_end = next_month(row.period_start)
        row.alterations_used = 0
    payment.status = decision
    payment.reviewed_at = utc_now()
    payment.reviewed_by_user_id = reviewer.id
    payment.review_note = str(payload.get("note", ""))[:2000]
    record_auth_event(
        "cineplanner_payment_review",
        success=True,
        user=reviewer,
        metadata={"payment": payment.public_id, "decision": decision},
    )
    db.session.commit()
    return jsonify(success({"payment": _payment_payload(payment)}))
