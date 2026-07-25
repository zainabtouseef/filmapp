"""actor casting workflows and structured profile details

Revision ID: e6f7a8b9c0d1
Revises: d5e6f7a8b9c0
Create Date: 2026-07-25 14:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "e6f7a8b9c0d1"
down_revision = "d5e6f7a8b9c0"
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
    for name in (
        "skills_json",
        "accents_json",
        "special_abilities_json",
        "physical_details_json",
        "credits_json",
        "training_json",
        "representation_json",
        "social_links_json",
    ):
        op.add_column("talent_profiles", sa.Column(name, sa.Text(), nullable=True))

    op.create_table(
        "casting_role_briefs",
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("requirement_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("role_type", sa.String(length=64), nullable=True),
        sa.Column("work_location", sa.String(length=255), nullable=True),
        sa.Column("audition_mode", sa.String(length=32), nullable=True),
        sa.Column("instructions", sa.Text(), nullable=True),
        sa.Column("eligibility_json", sa.Text(), nullable=True),
        sa.Column("casting_questions_json", sa.Text(), nullable=True),
        sa.Column("application_due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sides_file_id", sa.Uuid(native_uuid=False), nullable=True),
        sa.Column("contact_name", sa.String(length=120), nullable=True),
        sa.Column("contact_email", sa.String(length=255), nullable=True),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        *_entity_columns(),
        sa.ForeignKeyConstraint(
            ["requirement_id"],
            ["project_requirements.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["sides_file_id"],
            ["files.id"],
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id"),
        sa.UniqueConstraint("requirement_id"),
    )

    op.create_table(
        "saved_casting_roles",
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("actor_user_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("requirement_id", sa.Uuid(native_uuid=False), nullable=False),
        *_entity_columns(),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["requirement_id"],
            ["project_requirements.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id"),
        sa.UniqueConstraint(
            "actor_user_id",
            "requirement_id",
            name="uq_saved_casting_role_actor",
        ),
    )

    op.create_table(
        "casting_applications",
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("requirement_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("actor_user_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("talent_profile_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("conversation_id", sa.Uuid(native_uuid=False), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("cover_note", sa.Text(), nullable=True),
        sa.Column("answers_json", sa.Text(), nullable=True),
        sa.Column("availability_note", sa.Text(), nullable=True),
        sa.Column("portfolio_item_ids_json", sa.Text(), nullable=True),
        sa.Column("self_tape_file_id", sa.Uuid(native_uuid=False), nullable=True),
        sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("viewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("withdrawn_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("audition_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("audition_due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("audition_location", sa.String(length=255), nullable=True),
        sa.Column("audition_online_url", sa.String(length=255), nullable=True),
        sa.Column("audition_instructions", sa.Text(), nullable=True),
        sa.Column("audition_contact", sa.String(length=255), nullable=True),
        sa.Column("audition_confirmed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("callback_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("callback_details", sa.Text(), nullable=True),
        sa.Column("rejection_reason", sa.Text(), nullable=True),
        *_entity_columns(),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["conversation_id"], ["conversations.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(
            ["requirement_id"],
            ["project_requirements.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["self_tape_file_id"], ["files.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(
            ["talent_profile_id"], ["talent_profiles.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("conversation_id"),
        sa.UniqueConstraint("public_id"),
        sa.UniqueConstraint(
            "requirement_id",
            "actor_user_id",
            name="uq_casting_application_actor_role",
        ),
    )

    op.create_table(
        "casting_application_status_events",
        sa.Column("application_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("actor_user_id", sa.Uuid(native_uuid=False), nullable=True),
        sa.Column("from_status", sa.String(length=32), nullable=True),
        sa.Column("to_status", sa.String(length=32), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        *_entity_columns(),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(
            ["application_id"],
            ["casting_applications.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_casting_role_briefs_due",
        "casting_role_briefs",
        ["application_due_at"],
    )
    op.create_index(
        "ix_saved_casting_roles_actor",
        "saved_casting_roles",
        ["actor_user_id", "created_at"],
    )
    op.create_index(
        "ix_casting_applications_actor_status",
        "casting_applications",
        ["actor_user_id", "status", "updated_at"],
    )
    op.create_index(
        "ix_casting_applications_requirement_status",
        "casting_applications",
        ["requirement_id", "status", "updated_at"],
    )
    op.create_index(
        "ix_casting_application_events_application",
        "casting_application_status_events",
        ["application_id", "created_at"],
    )


def downgrade():
    op.drop_table("casting_application_status_events")
    op.drop_table("casting_applications")
    op.drop_table("saved_casting_roles")
    op.drop_table("casting_role_briefs")
    for name in (
        "representation_json",
        "social_links_json",
        "training_json",
        "credits_json",
        "physical_details_json",
        "special_abilities_json",
        "accents_json",
        "skills_json",
    ):
        op.drop_column("talent_profiles", name)
