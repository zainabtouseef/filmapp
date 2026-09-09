"""external project cinema media

Revision ID: cinema_external_media
Revises: ab12cd34ef56
Create Date: 2026-07-27 20:30:00.000000

"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "cinema_external_media"
down_revision = "ab12cd34ef56"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        "project_files",
        "file_id",
        existing_type=sa.Uuid(native_uuid=False),
        nullable=True,
    )
    op.add_column(
        "project_files",
        sa.Column("external_url", sa.String(length=1000), nullable=True),
    )
    op.add_column(
        "project_files",
        sa.Column("external_provider", sa.String(length=64), nullable=True),
    )
    op.add_column(
        "project_files",
        sa.Column("external_thumbnail_url", sa.String(length=1000), nullable=True),
    )
    op.add_column(
        "project_files",
        sa.Column("external_duration_seconds", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("project_files", "external_duration_seconds")
    op.drop_column("project_files", "external_thumbnail_url")
    op.drop_column("project_files", "external_provider")
    op.drop_column("project_files", "external_url")
    op.alter_column(
        "project_files",
        "file_id",
        existing_type=sa.Uuid(native_uuid=False),
        nullable=False,
    )
