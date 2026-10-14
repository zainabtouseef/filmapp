"""Persist booking terms, registration details, travel and runtime configuration.

Revision ID: f8a9b0c1d2e3
Revises: e1f2a3b4c5d6
"""

import sqlalchemy as sa
from alembic import op

revision = "f8a9b0c1d2e3"
down_revision = "e1f2a3b4c5d6"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "push_devices", sa.Column("subscription_encrypted", sa.Text(), nullable=True)
    )
    op.add_column(
        "notification_deliveries",
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "notification_deliveries",
        sa.Column("next_attempt_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column("users", sa.Column("referral_code", sa.String(64), nullable=True))
    op.add_column("bookings", sa.Column("terms_json", sa.JSON(), nullable=True))
    op.add_column(
        "payout_accounts", sa.Column("details_json", sa.JSON(), nullable=True)
    )
    op.add_column(
        "talent_profiles",
        sa.Column("travel_preferences_json", sa.Text(), nullable=True),
    )
    op.create_table(
        "app_settings",
        sa.Column("id", sa.Uuid(native_uuid=False), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("key", sa.String(64), nullable=False, unique=True),
        sa.Column("value_json", sa.JSON(), nullable=False),
    )


def downgrade() -> None:
    op.drop_column("notification_deliveries", "next_attempt_at")
    op.drop_column("notification_deliveries", "attempts")
    op.drop_column("push_devices", "subscription_encrypted")
    op.drop_table("app_settings")
    op.drop_column("talent_profiles", "travel_preferences_json")
    op.drop_column("bookings", "terms_json")
    op.drop_column("payout_accounts", "details_json")
    op.drop_column("users", "referral_code")
