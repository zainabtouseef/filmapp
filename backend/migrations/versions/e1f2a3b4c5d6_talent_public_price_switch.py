"""Talent public price choice defaults to private.

Revision ID: e1f2a3b4c5d6
Revises: d2f3a4b5c6d7
"""

import sqlalchemy as sa
from alembic import op

revision = "e1f2a3b4c5d6"
down_revision = "d2f3a4b5c6d7"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "marketplace_listings",
        sa.Column(
            "public_price_visible",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )


def downgrade() -> None:
    op.drop_column("marketplace_listings", "public_price_visible")
