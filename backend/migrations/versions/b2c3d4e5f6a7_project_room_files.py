"""project room files

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-07-17 23:55:00.000000

"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "b2c3d4e5f6a7"
down_revision = "a1b2c3d4e5f6"
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
        "project_files",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("project_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("folder", sa.String(length=64), nullable=False),
        sa.Column("label", sa.String(length=180), nullable=False),
        sa.Column(
            "uploaded_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("visibility", sa.String(length=32), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["file_id"], ["files.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["uploaded_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_project_files_public_id"),
        sa.UniqueConstraint("project_id", "file_id", name="uq_project_file_asset"),
    )
    op.create_index(
        "ix_project_files_project_folder",
        "project_files",
        ["project_id", "folder"],
    )
    op.create_table(
        "project_room_items",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("project_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("item_type", sa.String(length=32), nullable=False),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("body", sa.Text(), nullable=True),
        sa.Column("linked_entity_type", sa.String(length=64), nullable=True),
        sa.Column("linked_entity_id", sa.String(length=40), nullable=True),
        sa.Column("created_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("pinned_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_project_room_items_public_id"),
    )
    op.create_index(
        "ix_project_room_items_project_created",
        "project_room_items",
        ["project_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_project_room_items_project_created", table_name="project_room_items"
    )
    op.drop_table("project_room_items")
    op.drop_index("ix_project_files_project_folder", table_name="project_files")
    op.drop_table("project_files")
