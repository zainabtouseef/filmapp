from __future__ import annotations

import base64
import hashlib
from typing import Any

from cryptography.fernet import Fernet
from flask import Blueprint, Response, current_app, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import or_, select

from app.api.auth import _current_user, _json_body
from app.api.bookings import _status_event_payload, _user_payload
from app.api.marketplace import _field_error, _file_payload
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import Booking
from app.models.files import FileAsset
from app.models.identity import User
from app.models.payments import (
    LedgerEntry,
    PaymentMilestone,
    PaymentProof,
    PaymentSchedule,
    PaymentTransaction,
    PayoutAccount,
    Receipt,
)
from app.responses import success
from app.services.payments import post_verified_payment

payments_blueprint = Blueprint("payments", __name__)

PAYMENT_METHODS = {"bank_transfer", "card_sandbox"}


def _encrypt_private_value(value: str) -> str:
    configured_key = str(
        current_app.config.get("FIELD_ENCRYPTION_KEY")
        or current_app.config["SECRET_KEY"]
    )
    key = base64.urlsafe_b64encode(
        hashlib.sha256(configured_key.encode("utf-8")).digest()
    )
    return f"fernet:{Fernet(key).encrypt(value.encode('utf-8')).decode('ascii')}"


def _has_role(user: User, *codes: str) -> bool:
    return any(
        user_role.status == "active" and user_role.role.code in codes
        for user_role in user.roles
    )


def _require_finance(user: User) -> None:
    if not _has_role(user, "finance_admin", "super_admin", "reviewer"):
        raise APIError(
            "payment.permission_denied", "Finance role is required.", status=403
        )


def _schedule_visible_to(schedule: PaymentSchedule, user: User) -> bool:
    return user.id in {
        schedule.booking.requester_user_id,
        schedule.booking.provider_user_id,
    }


def _schedule_for_user(public_id: str, user: User) -> PaymentSchedule:
    schedule = db.session.execute(
        select(PaymentSchedule).where(PaymentSchedule.public_id == public_id)
    ).scalar_one_or_none()
    if schedule is None or not _schedule_visible_to(schedule, user):
        raise APIError(
            "payment_schedule.not_found",
            "Payment schedule was not found.",
            status=404,
        )
    return schedule


def _milestone_for_user(public_id: str, user: User) -> PaymentMilestone:
    milestone = db.session.execute(
        select(PaymentMilestone).where(PaymentMilestone.public_id == public_id)
    ).scalar_one_or_none()
    if milestone is None or not _schedule_visible_to(milestone.schedule, user):
        raise APIError(
            "payment_milestone.not_found",
            "Payment milestone was not found.",
            status=404,
        )
    return milestone


def _transaction_payload(item: PaymentTransaction) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "payer": _user_payload(item.payer),
        "payee": _user_payload(item.payee),
        "provider": item.provider,
        "provider_reference": item.provider_reference,
        "amount_minor": item.amount_minor,
        "currency": item.currency,
        "direction": item.direction,
        "status": item.status,
        "paid_at": item.paid_at.isoformat() if item.paid_at else None,
        "idempotency_key": item.idempotency_key,
        "proof": _proof_payload(item.proof) if item.proof else None,
    }


def _milestone_payload(item: PaymentMilestone) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "sequence": item.sequence,
        "amount_minor": item.amount_minor,
        "due_at": item.due_at.isoformat() if item.due_at else None,
        "release_condition": item.release_condition,
        "status": item.status,
        "transactions": [_transaction_payload(row) for row in item.transactions],
    }


def _schedule_payload(item: PaymentSchedule) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "booking_id": item.booking.public_id,
        "contract_id": item.contract.public_id if item.contract else None,
        "total_minor": item.total_minor,
        "currency": item.currency,
        "status": item.status,
        "milestones": [_milestone_payload(row) for row in item.milestones],
    }


def _proof_payload(item: PaymentProof) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "transaction_id": item.transaction.public_id,
        "milestone_id": item.transaction.milestone.public_id,
        "booking_id": item.transaction.milestone.schedule.booking.public_id,
        "file": _file_payload(item.file),
        "claimed_amount_minor": item.claimed_amount_minor,
        "method": item.method,
        "transaction_reference": item.transaction_reference_encrypted,
        "submitted_by": _user_payload(item.submitter),
        "status": item.status,
        "risk_score": item.risk_score,
        "reviewed_by": _user_payload(item.reviewer) if item.reviewer else None,
        "reviewed_at": item.reviewed_at.isoformat() if item.reviewed_at else None,
        "rejection_reason": item.rejection_reason,
        "transaction": {
            "public_id": item.transaction.public_id,
            "provider": item.transaction.provider,
            "status": item.transaction.status,
            "amount_minor": item.transaction.amount_minor,
            "currency": item.transaction.currency,
        },
    }


def _ledger_payload(item: LedgerEntry) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "user": _user_payload(item.user),
        "booking_id": item.booking.public_id if item.booking else None,
        "transaction_id": item.transaction.public_id if item.transaction else None,
        "entry_type": item.entry_type,
        "direction": item.direction,
        "amount_minor": item.amount_minor,
        "currency": item.currency,
        "status": item.status,
        "occurred_at": item.occurred_at.isoformat(),
        "description": item.description,
    }


def _receipt_payload(item: Receipt) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "receipt_number": item.receipt_number,
        "transaction_id": item.transaction.public_id,
        "issued_to": _user_payload(item.issued_to),
        "amount_minor": item.amount_minor,
        "currency": item.currency,
        "status": item.status,
    }


def _payout_account_payload(item: PayoutAccount) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "provider": item.provider,
        "account_masked": item.account_masked,
        "account_name": item.account_name,
        "status": item.status,
        "is_default": item.is_default,
    }


@payments_blueprint.get("/payments/dashboard")
def payments_dashboard() -> Response:
    user = _current_user()
    schedules = db.session.execute(
        select(PaymentSchedule)
        .join(Booking, Booking.id == PaymentSchedule.booking_id)
        .where(
            or_(
                Booking.requester_user_id == user.id,
                Booking.provider_user_id == user.id,
            )
        )
        .order_by(PaymentSchedule.updated_at.desc())
        .limit(20)
    ).scalars()
    ledger_rows = db.session.execute(
        select(LedgerEntry).where(LedgerEntry.user_id == user.id)
    ).scalars()
    totals = {"debit_minor": 0, "credit_minor": 0, "pending_release_minor": 0}
    for row in ledger_rows:
        if row.direction == "debit":
            totals["debit_minor"] += row.amount_minor
        if row.direction == "credit":
            totals["credit_minor"] += row.amount_minor
        if row.status == "pending_release":
            totals["pending_release_minor"] += row.amount_minor
    return jsonify(
        success(
            {
                "schedules": [_schedule_payload(row) for row in schedules],
                "totals": totals,
            }
        )
    )


@payments_blueprint.get("/payment-schedules")
def payment_schedules() -> Response:
    user = _current_user()
    booking_id = str(request.args.get("booking_id", "")).strip()
    rows_query = (
        select(PaymentSchedule)
        .join(Booking, Booking.id == PaymentSchedule.booking_id)
        .where(
            or_(
                Booking.requester_user_id == user.id,
                Booking.provider_user_id == user.id,
            )
        )
        .order_by(PaymentSchedule.updated_at.desc())
        .limit(100)
    )
    if booking_id:
        rows_query = rows_query.where(Booking.public_id == booking_id)
    rows = db.session.execute(rows_query).scalars()
    return jsonify(success({"schedules": [_schedule_payload(row) for row in rows]}))


@payments_blueprint.get("/payment-schedules/<public_id>")
def payment_schedule_detail(public_id: str) -> Response:
    user = _current_user()
    return jsonify(
        success({"schedule": _schedule_payload(_schedule_for_user(public_id, user))})
    )


@payments_blueprint.post("/payment-proofs")
def submit_payment_proof() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    milestone_id = str(payload.get("milestone_id", "")).strip()
    milestone = _milestone_for_user(milestone_id, user)
    schedule = milestone.schedule
    if user.id != schedule.booking.requester_user_id:
        raise APIError(
            "payment.permission_denied",
            "Only the booking payer can submit payment proof.",
            status=403,
        )
    if milestone.status == "verified":
        raise APIError(
            "payment.already_verified", "Milestone is already verified.", status=409
        )
    method = str(payload.get("method", "bank_transfer")).strip()
    if method not in PAYMENT_METHODS:
        raise _field_error("method", "Unsupported sandbox payment method.")
    claimed_amount = int(payload.get("claimed_amount_minor") or milestone.amount_minor)
    if claimed_amount <= 0 or claimed_amount != milestone.amount_minor:
        raise _field_error(
            "claimed_amount_minor", "Claimed amount must match the milestone."
        )
    idempotency_key = str(payload.get("idempotency_key", "")).strip()
    if not idempotency_key:
        raise _field_error("idempotency_key", "Idempotency key is required.")
    existing = db.session.execute(
        select(PaymentTransaction).where(
            PaymentTransaction.idempotency_key == idempotency_key
        )
    ).scalar_one_or_none()
    if existing is not None:
        if existing.proof is None:
            raise APIError(
                "payment.idempotency_conflict",
                "Idempotency key is already in use.",
                status=409,
            )
        return jsonify(success({"proof": _proof_payload(existing.proof)}))
    file_id = None
    raw_file_id = str(payload.get("file_id", "")).strip()
    if raw_file_id:
        file = db.session.execute(
            select(FileAsset).where(
                FileAsset.public_id == raw_file_id,
                FileAsset.owner_user_id == user.id,
                FileAsset.scan_status == "clean",
                FileAsset.processing_status == "ready",
            )
        ).scalar_one_or_none()
        if file is None:
            raise _field_error("file_id", "Proof file must be owned and ready.")
        file_id = file.id
    reference = str(payload.get("transaction_reference", "")).strip()[:180] or None
    transaction = PaymentTransaction(
        milestone_id=milestone.id,
        payer_user_id=schedule.booking.requester_user_id,
        payee_user_id=schedule.booking.provider_user_id,
        provider=method,
        provider_reference=reference,
        amount_minor=milestone.amount_minor,
        currency=schedule.currency,
        direction="outgoing",
        status="under_verification",
        paid_at=utc_now(),
        idempotency_key=idempotency_key,
    )
    db.session.add(transaction)
    db.session.flush()
    proof = PaymentProof(
        transaction_id=transaction.id,
        file_id=file_id,
        claimed_amount_minor=claimed_amount,
        method=method,
        transaction_reference_encrypted=reference,
        submitted_by=user.id,
        status="pending",
        risk_score=8 if method == "bank_transfer" else 12,
    )
    milestone.status = "proof_submitted"
    db.session.add(proof)
    db.session.add(
        LedgerEntry(
            user_id=user.id,
            booking_id=schedule.booking_id,
            transaction_id=transaction.id,
            entry_type="booking_payment",
            direction="debit",
            amount_minor=milestone.amount_minor,
            currency=schedule.currency,
            status="pending_verification",
            occurred_at=utc_now(),
            description=f"{schedule.booking.project.title} payment proof submitted",
        )
    )
    db.session.commit()
    return jsonify(success({"proof": _proof_payload(proof)})), 201


@payments_blueprint.get("/ledger")
def ledger() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(LedgerEntry)
        .where(LedgerEntry.user_id == user.id)
        .order_by(LedgerEntry.occurred_at.desc())
        .limit(100)
    ).scalars()
    return jsonify(success({"entries": [_ledger_payload(row) for row in rows]}))


@payments_blueprint.get("/receipts/<public_id>")
def receipt_detail(public_id: str) -> Response:
    user = _current_user()
    receipt = db.session.execute(
        select(Receipt).where(Receipt.public_id == public_id)
    ).scalar_one_or_none()
    if receipt is None or receipt.issued_to_user_id != user.id:
        raise APIError("receipt.not_found", "Receipt was not found.", status=404)
    return jsonify(success({"receipt": _receipt_payload(receipt)}))


@payments_blueprint.get("/payout-accounts")
def payout_accounts() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(PayoutAccount)
        .where(PayoutAccount.user_id == user.id)
        .order_by(PayoutAccount.created_at.desc())
    ).scalars()
    return jsonify(
        success({"accounts": [_payout_account_payload(row) for row in rows]})
    )


@payments_blueprint.post("/payout-accounts")
def create_payout_account() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    provider = str(payload.get("provider", "bank")).strip()
    account_name = str(payload.get("account_name", "")).strip()
    token = str(payload.get("account_token", "")).strip()
    if provider not in {"bank", "wallet", "sandbox"}:
        raise _field_error("provider", "Unsupported payout provider.")
    if len(account_name) < 2:
        raise _field_error("account_name", "Account name is required.")
    if len(token) < 4:
        raise _field_error("account_token", "Account token is required.")
    compact_token = "".join(character for character in token if character.isalnum())
    account_masked = f"****{compact_token[-4:]}"
    make_default = bool(payload.get("is_default", True))
    if make_default:
        existing = db.session.execute(
            select(PayoutAccount).where(PayoutAccount.user_id == user.id)
        ).scalars()
        for row in existing:
            row.is_default = False
    item = PayoutAccount(
        user_id=user.id,
        provider=provider,
        account_token_encrypted=_encrypt_private_value(token),
        account_masked=account_masked[:64],
        account_name=account_name[:120],
        status="verified" if provider == "sandbox" else "pending",
        is_default=make_default,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"account": _payout_account_payload(item)})), 201


@payments_blueprint.get("/admin/payment-proofs")
def admin_payment_proofs() -> Response:
    user = _current_user()
    _require_finance(user)
    rows = db.session.execute(
        select(PaymentProof).order_by(PaymentProof.created_at.desc()).limit(100)
    ).scalars()
    return jsonify(success({"proofs": [_proof_payload(row) for row in rows]}))


@payments_blueprint.get("/admin/payment-proofs/<public_id>")
def admin_payment_proof_detail(public_id: str) -> Response:
    user = _current_user()
    _require_finance(user)
    proof = db.session.execute(
        select(PaymentProof).where(PaymentProof.public_id == public_id)
    ).scalar_one_or_none()
    if proof is None:
        raise APIError(
            "payment_proof.not_found", "Payment proof was not found.", status=404
        )
    booking = proof.transaction.milestone.schedule.booking
    return jsonify(
        success(
            {
                "proof": _proof_payload(proof),
                "booking_events": [
                    _status_event_payload(row) for row in booking.status_events
                ],
            }
        )
    )


@payments_blueprint.post("/admin/payment-proofs/<public_id>/decision")
def admin_payment_proof_decision(public_id: str) -> Response:
    user = _current_user()
    _require_finance(user)
    proof = db.session.execute(
        select(PaymentProof).where(PaymentProof.public_id == public_id)
    ).scalar_one_or_none()
    if proof is None:
        raise APIError(
            "payment_proof.not_found", "Payment proof was not found.", status=404
        )
    payload = _json_body()
    decision = str(payload.get("decision", "approved")).strip()
    if decision not in {"approved", "rejected", "clarification_requested"}:
        raise _field_error("decision", "Unsupported payment proof decision.")
    if proof.status == "verified":
        receipt = db.session.execute(
            select(Receipt).where(Receipt.transaction_id == proof.transaction_id)
        ).scalar_one_or_none()
        return jsonify(
            success(
                {
                    "proof": _proof_payload(proof),
                    "receipt": _receipt_payload(receipt) if receipt else None,
                }
            )
        )
    proof.reviewed_by = user.id
    proof.reviewed_at = utc_now()
    proof.rejection_reason = str(payload.get("reason", "")).strip()[:1000] or None
    receipt = None
    if decision == "approved":
        proof.status = "verified"
        receipt = post_verified_payment(proof.transaction)
    elif decision == "rejected":
        proof.status = "rejected"
        proof.transaction.status = "rejected"
        proof.transaction.milestone.status = "rejected"
    else:
        proof.status = "clarification_requested"
        proof.transaction.status = "needs_clarification"
        proof.transaction.milestone.status = "proof_submitted"
    db.session.commit()
    return jsonify(
        success(
            {
                "proof": _proof_payload(proof),
                "receipt": _receipt_payload(receipt) if receipt else None,
            }
        )
    )
