"""casting application self-tape reviews

Revision ID: ab12cd34ef56
Revises: 6a7b8c9d0e2f
Create Date: 2026-07-27 03:10:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "ab12cd34ef56"
down_revision = "6a7b8c9d0e2f"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "casting_applications",
        sa.Column("review_score", sa.Integer(), nullable=True),
    )
    op.add_column(
        "casting_applications",
        sa.Column("review_comment", sa.Text(), nullable=True),
    )
    op.add_column(
        "casting_applications",
        sa.Column("reviewed_by_id", sa.Uuid(native_uuid=False), nullable=True),
    )
    op.add_column(
        "casting_applications",
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_casting_applications_reviewed_by",
        "casting_applications",
        "users",
        ["reviewed_by_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade():
    op.drop_constraint(
        "fk_casting_applications_reviewed_by",
        "casting_applications",
        type_="foreignkey",
    )
    op.drop_column("casting_applications", "reviewed_at")
    op.drop_column("casting_applications", "reviewed_by_id")
    op.drop_column("casting_applications", "review_comment")
    op.drop_column("casting_applications", "review_score")
