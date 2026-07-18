from __future__ import annotations

import json
from datetime import timedelta

from sqlalchemy import select

from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import BookingStatusEvent
from app.models.contracts import Contract
from app.models.payments import (
    BookingFeeSnapshot,
    FeeRule,
    LedgerEntry,
    PaymentMilestone,
    PaymentSchedule,
    PaymentTransaction,
    Receipt,
)


def ensure_payment_schedule_for_contract(contract: Contract) -> PaymentSchedule:
    existing = db.session.execute(
        select(PaymentSchedule).where(PaymentSchedule.contract_id == contract.id)
    ).scalar_one_or_none()
    if existing is not None:
        return existing

    total_minor = contract.value_minor or contract.booking.agreed_amount_minor or 0
    schedule = PaymentSchedule(
        booking_id=contract.booking_id,
        contract_id=contract.id,
        total_minor=total_minor,
        currency=contract.currency,
        status="active",
    )
    db.session.add(schedule)
    db.session.flush()
    db.session.add(
        PaymentMilestone(
            schedule_id=schedule.id,
            name="Full booking payment",
            sequence=1,
            amount_minor=total_minor,
            due_at=utc_now() + timedelta(days=1),
            release_condition="proof_verified",
            status="pending",
        )
    )

    fee_rule = db.session.execute(
        select(FeeRule).where(
            FeeRule.category == contract.template.category, FeeRule.active.is_(True)
        )
    ).scalar_one_or_none()
    if fee_rule is not None:
        fee_minor = (
            total_minor * fee_rule.basis_points // 10000
        ) + fee_rule.fixed_minor
        db.session.add(
            BookingFeeSnapshot(
                booking_id=contract.booking_id,
                fee_rule_id=fee_rule.id,
                base_minor=total_minor,
                fee_minor=fee_minor,
                tax_minor=0,
                currency=contract.currency,
                calculation_json=json.dumps(
                    {
                        "basis_points": fee_rule.basis_points,
                        "fixed_minor": fee_rule.fixed_minor,
                        "sandbox": True,
                    },
                    sort_keys=True,
                ),
            )
        )
    return schedule


def post_verified_payment(transaction: PaymentTransaction) -> Receipt:
    milestone = transaction.milestone
    schedule = milestone.schedule
    booking = schedule.booking
    occurred_at = utc_now()

    payer_entry_exists = db.session.execute(
        select(LedgerEntry).where(
            LedgerEntry.transaction_id == transaction.id,
            LedgerEntry.user_id == transaction.payer_user_id,
            LedgerEntry.entry_type == "booking_payment",
            LedgerEntry.status == "posted",
        )
    ).scalar_one_or_none()
    if payer_entry_exists is None:
        db.session.add_all(
            [
                LedgerEntry(
                    user_id=transaction.payer_user_id,
                    booking_id=booking.id,
                    transaction_id=transaction.id,
                    entry_type="booking_payment",
                    direction="debit",
                    amount_minor=transaction.amount_minor,
                    currency=transaction.currency,
                    status="posted",
                    occurred_at=occurred_at,
                    description=f"{booking.project.title} booking payment",
                ),
                LedgerEntry(
                    user_id=transaction.payee_user_id,
                    booking_id=booking.id,
                    transaction_id=transaction.id,
                    entry_type="booking_earning",
                    direction="credit",
                    amount_minor=transaction.amount_minor,
                    currency=transaction.currency,
                    status="pending_release",
                    occurred_at=occurred_at,
                    description=f"{booking.project.title} booking earning",
                ),
            ]
        )

    receipt = db.session.execute(
        select(Receipt).where(Receipt.transaction_id == transaction.id)
    ).scalar_one_or_none()
    if receipt is None:
        receipt = Receipt(
            transaction_id=transaction.id,
            receipt_number=f"RCT-{transaction.public_id}",
            issued_to_user_id=transaction.payer_user_id,
            amount_minor=transaction.amount_minor,
            currency=transaction.currency,
            status="issued",
        )
        db.session.add(receipt)

    milestone.status = "verified"
    transaction.status = "verified"
    transaction.paid_at = transaction.paid_at or occurred_at
    if all(row.status == "verified" for row in schedule.milestones):
        schedule.status = "paid"
    old_status = booking.status
    if booking.status != "secured":
        booking.status = "secured"
        booking.secured_at = occurred_at
        db.session.add(
            BookingStatusEvent(
                booking_id=booking.id,
                actor_user_id=None,
                from_status=old_status,
                to_status="secured",
                reason="Payment proof verified.",
                metadata_json=json.dumps({"transaction_id": transaction.public_id}),
            )
        )
    return receipt
