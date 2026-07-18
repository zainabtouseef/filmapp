from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.bookings import Booking
from app.models.contracts import Contract
from app.models.files import FileAsset
from app.models.identity import User, make_public_id


class PaymentSchedule(EntityMixin, Base):
    __tablename__ = "payment_schedules"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("PS"),
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"),
        nullable=False,
    )
    contract_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("contracts.id", ondelete="SET NULL")
    )
    total_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")

    booking: Mapped[Booking] = relationship(lazy="joined")
    contract: Mapped[Contract | None] = relationship(lazy="joined")
    milestones: Mapped[list[PaymentMilestone]] = relationship(
        back_populates="schedule",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="PaymentMilestone.sequence",
    )


class PaymentMilestone(EntityMixin, Base):
    __tablename__ = "payment_milestones"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("PM"),
    )
    schedule_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("payment_schedules.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    sequence: Mapped[int] = mapped_column(Integer, nullable=False)
    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    release_condition: Mapped[str] = mapped_column(String(64), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")

    schedule: Mapped[PaymentSchedule] = relationship(back_populates="milestones")
    transactions: Mapped[list[PaymentTransaction]] = relationship(
        back_populates="milestone",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="PaymentTransaction.created_at",
    )


class PaymentTransaction(EntityMixin, Base):
    __tablename__ = "payment_transactions"
    __table_args__ = (
        UniqueConstraint("idempotency_key", name="uq_payment_transactions_idem"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("TXN"),
    )
    milestone_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("payment_milestones.id", ondelete="CASCADE"),
        nullable=False,
    )
    payer_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    payee_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    provider: Mapped[str] = mapped_column(String(64), nullable=False)
    provider_reference: Mapped[str | None] = mapped_column(String(180))
    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    direction: Mapped[str] = mapped_column(
        String(32), nullable=False, default="outgoing"
    )
    status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="under_verification"
    )
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    idempotency_key: Mapped[str] = mapped_column(String(120), nullable=False)

    milestone: Mapped[PaymentMilestone] = relationship(back_populates="transactions")
    payer: Mapped[User] = relationship(foreign_keys=[payer_user_id], lazy="joined")
    payee: Mapped[User] = relationship(foreign_keys=[payee_user_id], lazy="joined")
    proof: Mapped[PaymentProof | None] = relationship(
        back_populates="transaction",
        cascade="all, delete-orphan",
        lazy="joined",
        uselist=False,
    )


class PaymentProof(EntityMixin, Base):
    __tablename__ = "payment_proofs"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("PP"),
    )
    transaction_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("payment_transactions.id", ondelete="CASCADE"),
        nullable=False,
    )
    file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    claimed_amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    method: Mapped[str] = mapped_column(String(64), nullable=False)
    transaction_reference_encrypted: Mapped[str | None] = mapped_column(String(256))
    submitted_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    risk_score: Mapped[int] = mapped_column(Integer, nullable=False, default=8)
    reviewed_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    rejection_reason: Mapped[str | None] = mapped_column(Text)

    transaction: Mapped[PaymentTransaction] = relationship(back_populates="proof")
    file: Mapped[FileAsset | None] = relationship(lazy="joined")
    submitter: Mapped[User] = relationship(foreign_keys=[submitted_by], lazy="joined")
    reviewer: Mapped[User | None] = relationship(
        foreign_keys=[reviewed_by], lazy="joined"
    )


class Receipt(EntityMixin, Base):
    __tablename__ = "receipts"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("RCT"),
    )
    transaction_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("payment_transactions.id", ondelete="CASCADE"),
        nullable=False,
    )
    receipt_number: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    issued_to_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="issued")

    transaction: Mapped[PaymentTransaction] = relationship(lazy="joined")
    issued_to: Mapped[User] = relationship(lazy="joined")


class LedgerEntry(EntityMixin, Base):
    __tablename__ = "ledger_entries"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("LED"),
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("bookings.id", ondelete="SET NULL")
    )
    transaction_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("payment_transactions.id", ondelete="SET NULL")
    )
    entry_type: Mapped[str] = mapped_column(String(64), nullable=False)
    direction: Mapped[str] = mapped_column(String(32), nullable=False)
    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    description: Mapped[str | None] = mapped_column(String(255))

    user: Mapped[User] = relationship(lazy="joined")
    booking: Mapped[Booking | None] = relationship(lazy="joined")
    transaction: Mapped[PaymentTransaction | None] = relationship(lazy="joined")


class FeeRule(EntityMixin, Base):
    __tablename__ = "fee_rules"

    public_id: Mapped[str] = mapped_column(String(40), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    basis_points: Mapped[int] = mapped_column(Integer, nullable=False)
    fixed_minor: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)


class BookingFeeSnapshot(EntityMixin, Base):
    __tablename__ = "booking_fee_snapshots"

    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    fee_rule_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("fee_rules.id", ondelete="SET NULL")
    )
    base_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    fee_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    tax_minor: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    calculation_json: Mapped[str] = mapped_column(Text, nullable=False)

    booking: Mapped[Booking] = relationship(lazy="joined")
    fee_rule: Mapped[FeeRule | None] = relationship(lazy="joined")


class PayoutAccount(EntityMixin, Base):
    __tablename__ = "payout_accounts"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("PAC"),
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    provider: Mapped[str] = mapped_column(String(64), nullable=False)
    account_token_encrypted: Mapped[str] = mapped_column(String(256), nullable=False)
    account_masked: Mapped[str] = mapped_column(String(64), nullable=False)
    account_name: Mapped[str] = mapped_column(String(120), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    is_default: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    user: Mapped[User] = relationship(lazy="joined")


class Payout(EntityMixin, Base):
    __tablename__ = "payouts"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("PO"),
    )
    payee_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    provider_reference: Mapped[str | None] = mapped_column(String(180))
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="scheduled")
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    payee: Mapped[User] = relationship(lazy="joined")
