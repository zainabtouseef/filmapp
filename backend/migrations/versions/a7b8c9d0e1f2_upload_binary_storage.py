"""upload binary storage

Revision ID: a7b8c9d0e1f2
Revises: 0f25fa31c34f
Create Date: 2026-07-18 11:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "a7b8c9d0e1f2"
down_revision = "0f25fa31c34f"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "upload_sessions",
        sa.Column("binary_received_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "upload_sessions",
        sa.Column("received_size_bytes", sa.Integer(), nullable=True),
    )
    op.add_column(
        "upload_sessions",
        sa.Column("received_checksum_sha256", sa.String(length=64), nullable=True),
    )


def downgrade():
    op.drop_column("upload_sessions", "received_checksum_sha256")
    op.drop_column("upload_sessions", "received_size_bytes")
    op.drop_column("upload_sessions", "binary_received_at")
