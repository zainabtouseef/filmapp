"""requirement applications (generic non-talent opportunities)

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-07-26 11:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "81aca403b670"
down_revision = "dd9621ac7f1d"
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
        "requirement_applications",
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("requirement_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("applicant_user_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("conversation_id", sa.Uuid(native_uuid=False), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("cover_note", sa.Text(), nullable=True),
        sa.Column("answers_json", sa.Text(), nullable=True),
        sa.Column("attachment_file_ids_json", sa.Text(), nullable=True),
        sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("withdrawn_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("rejection_reason", sa.Text(), nullable=True),
        *_entity_columns(),
        sa.ForeignKeyConstraint(
            ["applicant_user_id"], ["users.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["conversation_id"], ["conversations.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(
            ["requirement_id"],
            ["project_requirements.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("conversation_id"),
        sa.UniqueConstraint("public_id"),
        sa.UniqueConstraint(
            "requirement_id",
            "applicant_user_id",
            name="uq_requirement_application_applicant",
        ),
    )
    op.create_table(
        "requirement_application_status_events",
        sa.Column("application_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("actor_user_id", sa.Uuid(native_uuid=False), nullable=True),
        sa.Column("from_status", sa.String(length=32), nullable=True),
        sa.Column("to_status", sa.String(length=32), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        *_entity_columns(),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(
            ["application_id"],
            ["requirement_applications.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_requirement_applications_applicant_status",
        "requirement_applications",
        ["applicant_user_id", "status", "updated_at"],
    )
    op.create_index(
        "ix_requirement_applications_requirement_status",
        "requirement_applications",
        ["requirement_id", "status", "updated_at"],
    )
    op.create_index(
        "ix_requirement_application_events_application",
        "requirement_application_status_events",
        ["application_id", "created_at"],
    )


def downgrade():
    op.drop_table("requirement_application_status_events")
    op.drop_table("requirement_applications")
