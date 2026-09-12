"""marketplace pricing choice

Revision ID: d2f3a4b5c6d7
Revises: c1e2f3a4b5c6
Create Date: 2026-09-12 18:00:00.000000

"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "d2f3a4b5c6d7"
down_revision = "c1e2f3a4b5c6"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "marketplace_listings",
        sa.Column(
            "pricing_mode",
            sa.String(length=32),
            nullable=False,
            server_default="negotiable",
        ),
    )


def downgrade() -> None:
    op.drop_column("marketplace_listings", "pricing_mode")
