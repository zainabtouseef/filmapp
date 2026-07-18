"""payments finance

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-07-18 02:10:00.000000

"""

from __future__ import annotations

from datetime import UTC, datetime

import sqlalchemy as sa
from alembic import op

revision = "e5f6a7b8c9d0"
down_revision = "d4e5f6a7b8c9"
branch_labels = None
depends_on = None


def _audit_columns() -> list[sa.Column]:
    return [
        sa.Column("id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("version", sa.Integer(), nullable=False),
    ]


def _id() -> object:
    import uuid

    return uuid.uuid4()


def upgrade() -> None:
    op.create_table(
        "payment_schedules",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("contract_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("total_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["contract_id"], ["contracts.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("contract_id", name="uq_payment_schedules_contract_id"),
        sa.UniqueConstraint("public_id", name="uq_payment_schedules_public_id"),
    )
    op.create_index(
        "ix_payment_schedules_booking_status",
        "payment_schedules",
        ["booking_id", "status"],
    )
    op.create_table(
        "payment_milestones",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("schedule_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("sequence", sa.Integer(), nullable=False),
        sa.Column("amount_minor", sa.Integer(), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("release_condition", sa.String(length=64), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(
            ["schedule_id"], ["payment_schedules.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_payment_milestones_public_id"),
        sa.UniqueConstraint("schedule_id", "sequence", name="uq_payment_milestone_sequence"),
    )
    op.create_table(
        "payment_transactions",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("milestone_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("payer_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("payee_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("provider", sa.String(length=64), nullable=False),
        sa.Column("provider_reference", sa.String(length=180), nullable=True),
        sa.Column("amount_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("direction", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("idempotency_key", sa.String(length=120), nullable=False),
        sa.ForeignKeyConstraint(
            ["milestone_id"], ["payment_milestones.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(["payee_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["payer_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("idempotency_key", name="uq_payment_transactions_idem"),
        sa.UniqueConstraint("public_id", name="uq_payment_transactions_public_id"),
    )
    op.create_index(
        "ix_payment_transactions_status",
        "payment_transactions",
        ["status", "created_at"],
    )
    op.create_table(
        "payment_proofs",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("transaction_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("claimed_amount_minor", sa.Integer(), nullable=False),
        sa.Column("method", sa.String(length=64), nullable=False),
        sa.Column("transaction_reference_encrypted", sa.String(length=256), nullable=True),
        sa.Column("submitted_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("risk_score", sa.Integer(), nullable=False),
        sa.Column("reviewed_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("rejection_reason", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["file_id"], ["files.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["reviewed_by"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["submitted_by"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["transaction_id"], ["payment_transactions.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_payment_proofs_public_id"),
        sa.UniqueConstraint("transaction_id", name="uq_payment_proofs_transaction_id"),
    )
    op.create_index(
        "ix_payment_proofs_status_created",
        "payment_proofs",
        ["status", "created_at"],
    )
    op.create_table(
        "receipts",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("transaction_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("receipt_number", sa.String(length=64), nullable=False),
        sa.Column(
            "issued_to_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("amount_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(["issued_to_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["transaction_id"], ["payment_transactions.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_receipts_public_id"),
        sa.UniqueConstraint("receipt_number", name="uq_receipts_receipt_number"),
        sa.UniqueConstraint("transaction_id", name="uq_receipts_transaction_id"),
    )
    op.create_table(
        "ledger_entries",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column(
            "transaction_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("entry_type", sa.String(length=64), nullable=False),
        sa.Column("direction", sa.String(length=32), nullable=False),
        sa.Column("amount_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("description", sa.String(length=255), nullable=True),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(
            ["transaction_id"], ["payment_transactions.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_ledger_entries_public_id"),
    )
    op.create_index("ix_ledger_user_occurred", "ledger_entries", ["user_id", "occurred_at"])
    op.create_table(
        "fee_rules",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column("basis_points", sa.Integer(), nullable=False),
        sa.Column("fixed_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_fee_rules_public_id"),
    )
    op.create_index("ix_fee_rules_category_active", "fee_rules", ["category", "active"])
    op.create_table(
        "booking_fee_snapshots",
        *_audit_columns(),
        sa.Column("booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("fee_rule_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("base_minor", sa.Integer(), nullable=False),
        sa.Column("fee_minor", sa.Integer(), nullable=False),
        sa.Column("tax_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("calculation_json", sa.Text(), nullable=False),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["fee_rule_id"], ["fee_rules.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("booking_id", name="uq_booking_fee_snapshots_booking_id"),
    )
    op.create_table(
        "payout_accounts",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("provider", sa.String(length=64), nullable=False),
        sa.Column("account_token_encrypted", sa.String(length=256), nullable=False),
        sa.Column("account_masked", sa.String(length=64), nullable=False),
        sa.Column("account_name", sa.String(length=120), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("is_default", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_payout_accounts_public_id"),
    )
    op.create_index(
        "ix_payout_accounts_user_default",
        "payout_accounts",
        ["user_id", "is_default"],
    )
    op.create_table(
        "payouts",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("payee_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("amount_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("provider_reference", sa.String(length=180), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["payee_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_payouts_public_id"),
    )

    now = datetime.now(UTC)
    fee_rules = sa.table(
        "fee_rules",
        sa.column("id", sa.Uuid(as_uuid=True, native_uuid=False)),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
        sa.column("deleted_at", sa.DateTime(timezone=True)),
        sa.column("version", sa.Integer()),
        sa.column("public_id", sa.String(length=40)),
        sa.column("name", sa.String(length=120)),
        sa.column("category", sa.String(length=64)),
        sa.column("basis_points", sa.Integer()),
        sa.column("fixed_minor", sa.Integer()),
        sa.column("currency", sa.String(length=3)),
        sa.column("active", sa.Boolean()),
    )
    op.bulk_insert(
        fee_rules,
        [
            {
                "id": _id(),
                "created_at": now,
                "updated_at": now,
                "deleted_at": None,
                "version": 1,
                "public_id": "FEE-TALENT-SANDBOX-001",
                "name": "Sandbox Talent Platform Fee",
                "category": "talent",
                "basis_points": 500,
                "fixed_minor": 0,
                "currency": "PKR",
                "active": True,
            }
        ],
    )


def downgrade() -> None:
    op.drop_table("payouts")
    op.drop_index("ix_payout_accounts_user_default", table_name="payout_accounts")
    op.drop_table("payout_accounts")
    op.drop_table("booking_fee_snapshots")
    op.drop_index("ix_fee_rules_category_active", table_name="fee_rules")
    op.drop_table("fee_rules")
    op.drop_index("ix_ledger_user_occurred", table_name="ledger_entries")
    op.drop_table("ledger_entries")
    op.drop_table("receipts")
    op.drop_index("ix_payment_proofs_status_created", table_name="payment_proofs")
    op.drop_table("payment_proofs")
    op.drop_index("ix_payment_transactions_status", table_name="payment_transactions")
    op.drop_table("payment_transactions")
    op.drop_table("payment_milestones")
    op.drop_index("ix_payment_schedules_booking_status", table_name="payment_schedules")
    op.drop_table("payment_schedules")
