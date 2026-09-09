"""saved searches and shortlists

Revision ID: 9a4b6c7d8e30
Revises: 8e3b7c9d1a20
Create Date: 2026-07-17 22:40:00.000000

"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "9a4b6c7d8e30"
down_revision = "8e3b7c9d1a20"
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
        "saved_searches",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "owner_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("listing_type", sa.String(length=64), nullable=True),
        sa.Column("city_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("query_text", sa.String(length=255), nullable=True),
        sa.Column("filters_json", sa.Text(), nullable=True),
        sa.Column("notify_enabled", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["city_id"], ["cities.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["owner_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_saved_searches_public_id"),
    )
    op.create_index(
        "ix_saved_searches_owner_created",
        "saved_searches",
        ["owner_user_id", "created_at"],
    )
    op.create_table(
        "shortlists",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("project_id", sa.String(length=40), nullable=True),
        sa.Column("requirement_id", sa.String(length=40), nullable=True),
        sa.Column(
            "created_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("name", sa.String(length=160), nullable=False),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_shortlists_public_id"),
    )
    op.create_index(
        "ix_shortlists_creator_created",
        "shortlists",
        ["created_by", "created_at"],
    )
    op.create_table(
        "shortlist_items",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "shortlist_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "listing_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "candidate_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("rank", sa.Integer(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(
            ["candidate_user_id"], ["users.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(
            ["listing_id"], ["marketplace_listings.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["shortlist_id"], ["shortlists.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_shortlist_items_public_id"),
        sa.UniqueConstraint("shortlist_id", "listing_id", name="uq_shortlist_listing"),
    )
    op.create_index(
        "ix_shortlist_items_board_rank",
        "shortlist_items",
        ["shortlist_id", "rank"],
    )


def downgrade() -> None:
    op.drop_index("ix_shortlist_items_board_rank", table_name="shortlist_items")
    op.drop_table("shortlist_items")
    op.drop_index("ix_shortlists_creator_created", table_name="shortlists")
    op.drop_table("shortlists")
    op.drop_index("ix_saved_searches_owner_created", table_name="saved_searches")
    op.drop_table("saved_searches")
