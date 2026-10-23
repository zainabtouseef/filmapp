"""CinePlanner subscriptions, reviewed assistant changes and editable scene text."""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.mysql import LONGTEXT

revision = "72e19d4ca031"
down_revision = "9f84c2e7a6b1"
branch_labels = None
depends_on = None


def _base():
    return [
        sa.Column("id", sa.Uuid(native_uuid=False), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
        sa.Column("version", sa.Integer(), nullable=False),
    ]


def upgrade():
    op.add_column(
        "cine_scenes",
        sa.Column(
            "source_text",
            sa.Text().with_variant(LONGTEXT(), "mysql"),
            nullable=False,
            server_default=sa.text("('')"),
        ),
    )
    op.create_table(
        "cine_memberships",
        *_base(),
        sa.Column(
            "user_id",
            sa.Uuid(native_uuid=False),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            unique=True,
            nullable=False,
        ),
        sa.Column("access_mode", sa.String(24), nullable=False),
        sa.Column("period_start", sa.DateTime(timezone=True)),
        sa.Column("period_end", sa.DateTime(timezone=True)),
        sa.Column("alterations_used", sa.Integer(), nullable=False),
    )
    op.create_table(
        "cine_subscription_payments",
        *_base(),
        sa.Column("public_id", sa.String(40), unique=True, nullable=False),
        sa.Column(
            "user_id",
            sa.Uuid(native_uuid=False),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "proof_file_id",
            sa.Uuid(native_uuid=False),
            sa.ForeignKey("files.id", ondelete="RESTRICT"),
            unique=True,
            nullable=False,
        ),
        sa.Column("reference", sa.String(160), nullable=False),
        sa.Column("amount_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(3), nullable=False),
        sa.Column("status", sa.String(24), nullable=False),
        sa.Column(
            "reviewed_by_user_id",
            sa.Uuid(native_uuid=False),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
        ),
        sa.Column("reviewed_at", sa.DateTime(timezone=True)),
        sa.Column("review_note", sa.Text()),
    )
    op.create_index(
        "ix_cine_subscription_payments_status", "cine_subscription_payments", ["status"]
    )
    op.create_table(
        "cine_assistant_messages",
        *_base(),
        sa.Column("public_id", sa.String(40), unique=True, nullable=False),
        sa.Column(
            "production_id",
            sa.Uuid(native_uuid=False),
            sa.ForeignKey("cine_productions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.Uuid(native_uuid=False),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "script_version_id",
            sa.Uuid(native_uuid=False),
            sa.ForeignKey("cine_script_versions.id", ondelete="CASCADE"),
        ),
        sa.Column("role", sa.String(20), nullable=False),
        sa.Column("status", sa.String(24), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("changes_json", sa.JSON(), nullable=False),
        sa.Column("context_json", sa.JSON(), nullable=False),
        sa.Column("applied_at", sa.DateTime(timezone=True)),
    )
    op.create_index(
        "ix_cine_assistant_messages_production_id",
        "cine_assistant_messages",
        ["production_id"],
    )


def downgrade():
    op.drop_table("cine_assistant_messages")
    op.drop_table("cine_subscription_payments")
    op.drop_table("cine_memberships")
    op.drop_column("cine_scenes", "source_text")
