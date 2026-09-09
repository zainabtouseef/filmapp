"""bookings negotiations chat

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-07-18 00:20:00.000000

"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "c3d4e5f6a7b8"
down_revision = "b2c3d4e5f6a7"
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


def upgrade() -> None:
    op.create_table(
        "bookings",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "project_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "requirement_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column(
            "requester_user_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=False,
        ),
        sa.Column(
            "provider_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "listing_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column("status", sa.String(length=64), nullable=False),
        sa.Column("agreed_amount_minor", sa.Integer(), nullable=True),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("start_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("secured_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("cancellation_reason", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(
            ["listing_id"], ["marketplace_listings.id"], ondelete="RESTRICT"
        ),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["provider_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["requester_user_id"], ["users.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["requirement_id"], ["project_requirements.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_bookings_public_id"),
    )
    op.create_index(
        "ix_bookings_requester_status", "bookings", ["requester_user_id", "status"]
    )
    op.create_index(
        "ix_bookings_provider_status", "bookings", ["provider_user_id", "status"]
    )
    op.create_table(
        "booking_participants",
        *_audit_columns(),
        sa.Column(
            "booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("participant_role", sa.String(length=64), nullable=False),
        sa.Column("can_chat", sa.Boolean(), nullable=False),
        sa.Column("can_view_finance", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "booking_id", "user_id", name="uq_booking_participant_user"
        ),
    )
    op.create_table(
        "booking_status_events",
        *_audit_columns(),
        sa.Column(
            "booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "actor_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("from_status", sa.String(length=64), nullable=True),
        sa.Column("to_status", sa.String(length=64), nullable=False),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("metadata_json", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "offers",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "sender_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "recipient_user_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=False,
        ),
        sa.Column("revision", sa.Integer(), nullable=False),
        sa.Column("fee_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("schedule_json", sa.Text(), nullable=True),
        sa.Column("conditions", sa.Text(), nullable=True),
        sa.Column("payment_schedule_json", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["recipient_user_id"], ["users.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(["sender_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_offers_public_id"),
        sa.UniqueConstraint("booking_id", "revision", name="uq_booking_offer_revision"),
    )
    op.create_table(
        "negotiation_threads",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column(
            "current_offer_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("locked_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["current_offer_id"], ["offers.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("booking_id", name="uq_negotiation_threads_booking_id"),
        sa.UniqueConstraint("public_id", name="uq_negotiation_threads_public_id"),
    )
    op.create_table(
        "negotiation_rounds",
        *_audit_columns(),
        sa.Column(
            "thread_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("offer_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("round_number", sa.Integer(), nullable=False),
        sa.Column(
            "sender_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("message", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["offer_id"], ["offers.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["sender_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["thread_id"], ["negotiation_threads.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("thread_id", "round_number", name="uq_negotiation_round"),
    )
    op.create_table(
        "availability_calendars",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("owner_type", sa.String(length=32), nullable=False),
        sa.Column("owner_id", sa.String(length=40), nullable=False),
        sa.Column("timezone", sa.String(length=64), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("owner_type", "owner_id", name="uq_availability_owner"),
        sa.UniqueConstraint("public_id", name="uq_availability_calendars_public_id"),
    )
    op.create_table(
        "availability_entries",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "calendar_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("resource_type", sa.String(length=64), nullable=False),
        sa.Column("resource_id", sa.String(length=40), nullable=False),
        sa.Column("start_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column(
            "source_booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("note", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(
            ["calendar_id"], ["availability_calendars.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["source_booking_id"], ["bookings.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_availability_entries_public_id"),
    )
    op.create_index(
        "ix_availability_entries_range",
        "availability_entries",
        ["calendar_id", "start_at", "end_at", "status"],
    )
    op.create_table(
        "conversations",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column(
            "project_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("type", sa.String(length=32), nullable=False),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("last_message_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("booking_id", name="uq_conversations_booking_id"),
        sa.UniqueConstraint("public_id", name="uq_conversations_public_id"),
    )
    op.create_table(
        "messages",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "conversation_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "sender_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("message_type", sa.String(length=32), nullable=False),
        sa.Column("body", sa.Text(), nullable=True),
        sa.Column(
            "reply_to_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("decision_type", sa.String(length=64), nullable=True),
        sa.Column("edited_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["conversation_id"], ["conversations.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(["reply_to_id"], ["messages.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["sender_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_messages_public_id"),
    )
    op.create_index(
        "ix_messages_conversation_created",
        "messages",
        ["conversation_id", "created_at"],
    )
    op.create_table(
        "conversation_members",
        *_audit_columns(),
        sa.Column(
            "conversation_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column(
            "last_read_message_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=True,
        ),
        sa.Column("muted_until", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["conversation_id"], ["conversations.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["last_read_message_id"], ["messages.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "conversation_id", "user_id", name="uq_conversation_member"
        ),
    )
    op.create_table(
        "message_attachments",
        *_audit_columns(),
        sa.Column(
            "message_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("attachment_type", sa.String(length=32), nullable=False),
        sa.Column("caption", sa.String(length=255), nullable=True),
        sa.ForeignKeyConstraint(["file_id"], ["files.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["message_id"], ["messages.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "pinned_decisions",
        *_audit_columns(),
        sa.Column(
            "conversation_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "message_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "pinned_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("decision_key", sa.String(length=64), nullable=False),
        sa.Column(
            "superseded_by_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.ForeignKeyConstraint(
            ["conversation_id"], ["conversations.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(["message_id"], ["messages.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["pinned_by"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["superseded_by_id"], ["pinned_decisions.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("pinned_decisions")
    op.drop_table("message_attachments")
    op.drop_table("conversation_members")
    op.drop_index("ix_messages_conversation_created", table_name="messages")
    op.drop_table("messages")
    op.drop_table("conversations")
    op.drop_index("ix_availability_entries_range", table_name="availability_entries")
    op.drop_table("availability_entries")
    op.drop_table("availability_calendars")
    op.drop_table("negotiation_rounds")
    op.drop_table("negotiation_threads")
    op.drop_table("offers")
    op.drop_table("booking_status_events")
    op.drop_table("booking_participants")
    op.drop_index("ix_bookings_provider_status", table_name="bookings")
    op.drop_index("ix_bookings_requester_status", table_name="bookings")
    op.drop_table("bookings")
