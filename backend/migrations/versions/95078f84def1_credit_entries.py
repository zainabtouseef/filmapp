"""credit entries (past roles / production credits)

Revision ID: 95078f84def1
Revises: 8796563d8f1b
Create Date: 2026-07-26 12:30:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "95078f84def1"
down_revision = "8796563d8f1b"
branch_labels = None
depends_on = None


def _entity_columns() -> list[sa.Column]:
    return [
        sa.Column("id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("version", sa.Integer(), nullable=False),
    ]


def upgrade():
    op.create_table(
        "credit_entries",
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("owner_user_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("profile_type", sa.String(length=64), nullable=False),
        sa.Column("profile_id", sa.String(length=40), nullable=False),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("production_name", sa.String(length=180), nullable=False),
        sa.Column("role_label", sa.String(length=180), nullable=True),
        sa.Column("year", sa.Integer(), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("cover_file_id", sa.Uuid(native_uuid=False), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        *_entity_columns(),
        sa.ForeignKeyConstraint(
            ["owner_user_id"], ["users.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["cover_file_id"], ["files.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id"),
    )
    op.create_index(
        "ix_credit_entries_owner_profile",
        "credit_entries",
        ["owner_user_id", "profile_type", "profile_id", "sort_order"],
    )


def downgrade():
    op.drop_table("credit_entries")
