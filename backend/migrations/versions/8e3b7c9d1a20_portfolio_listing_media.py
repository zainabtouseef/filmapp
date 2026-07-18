"""portfolio and listing media

Revision ID: 8e3b7c9d1a20
Revises: 7d2e5f6a8b90
Create Date: 2026-07-17 22:05:00.000000

"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "8e3b7c9d1a20"
down_revision = "7d2e5f6a8b90"
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
        "portfolio_items",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "owner_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("profile_type", sa.String(length=64), nullable=False),
        sa.Column("profile_id", sa.String(length=40), nullable=False),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column("file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column(
            "thumbnail_file_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=True,
        ),
        sa.Column("duration_seconds", sa.Integer(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("is_cover", sa.Boolean(), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("moderation_status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(["file_id"], ["files.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(
            ["owner_user_id"], ["users.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["thumbnail_file_id"], ["files.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_portfolio_items_public_id"),
    )
    op.create_index(
        "ix_portfolio_items_owner_profile",
        "portfolio_items",
        ["owner_user_id", "profile_type", "profile_id", "sort_order"],
    )
    op.create_table(
        "listing_media",
        *_audit_columns(),
        sa.Column("listing_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("is_cover", sa.Boolean(), nullable=False),
        sa.Column("caption", sa.String(length=255), nullable=True),
        sa.ForeignKeyConstraint(["file_id"], ["files.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["listing_id"], ["marketplace_listings.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("listing_id", "file_id", name="uq_listing_media_file"),
    )
    op.create_index(
        "ix_listing_media_listing_order",
        "listing_media",
        ["listing_id", "sort_order"],
    )


def downgrade() -> None:
    op.drop_index("ix_listing_media_listing_order", table_name="listing_media")
    op.drop_table("listing_media")
    op.drop_index("ix_portfolio_items_owner_profile", table_name="portfolio_items")
    op.drop_table("portfolio_items")
