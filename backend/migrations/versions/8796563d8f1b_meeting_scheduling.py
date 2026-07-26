"""meeting scheduling (audition/visit/viewing/interview negotiation)

Revision ID: 8796563d8f1b
Revises: 81aca403b670
Create Date: 2026-07-26 12:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "8796563d8f1b"
down_revision = "81aca403b670"
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
    # meeting_threads first, without the current_round_id FK constraint —
    # meeting_rounds (which meeting_threads.current_round_id references)
    # doesn't exist yet. The constraint is added via ALTER after both
    # tables exist, matching the model's use_alter=True.
    op.create_table(
        "meeting_threads",
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("subject_type", sa.String(length=32), nullable=False),
        sa.Column("subject_id", sa.String(length=40), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("current_round_id", sa.Uuid(native_uuid=False), nullable=True),
        sa.Column("locked_at", sa.DateTime(timezone=True), nullable=True),
        *_entity_columns(),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id"),
        sa.UniqueConstraint(
            "subject_type", "subject_id", name="uq_meeting_thread_subject"
        ),
    )
    op.create_table(
        "meeting_rounds",
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("thread_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("round_number", sa.Integer(), nullable=False),
        sa.Column("proposed_by_user_id", sa.Uuid(native_uuid=False), nullable=False),
        sa.Column("meeting_kind", sa.String(length=32), nullable=True),
        sa.Column("meeting_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("location", sa.String(length=255), nullable=True),
        sa.Column("online_url", sa.String(length=255), nullable=True),
        sa.Column("instructions", sa.Text(), nullable=True),
        sa.Column("contact", sa.String(length=255), nullable=True),
        sa.Column("message", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("decline_reason", sa.Text(), nullable=True),
        sa.Column("responded_by_user_id", sa.Uuid(native_uuid=False), nullable=True),
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        *_entity_columns(),
        sa.ForeignKeyConstraint(
            ["thread_id"], ["meeting_threads.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["proposed_by_user_id"], ["users.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["responded_by_user_id"], ["users.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id"),
        sa.UniqueConstraint(
            "thread_id", "round_number", name="uq_meeting_round_number"
        ),
    )
    op.create_foreign_key(
        "fk_meeting_threads_current_round",
        "meeting_threads",
        "meeting_rounds",
        ["current_round_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(
        "ix_meeting_threads_subject",
        "meeting_threads",
        ["subject_type", "subject_id"],
    )

    op.add_column(
        "requirement_applications",
        sa.Column("meeting_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "requirement_applications",
        sa.Column("meeting_location", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "requirement_applications",
        sa.Column("meeting_online_url", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "requirement_applications",
        sa.Column("meeting_instructions", sa.Text(), nullable=True),
    )
    op.add_column(
        "requirement_applications",
        sa.Column("meeting_contact", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "requirement_applications",
        sa.Column("meeting_confirmed_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade():
    op.drop_column("requirement_applications", "meeting_confirmed_at")
    op.drop_column("requirement_applications", "meeting_contact")
    op.drop_column("requirement_applications", "meeting_instructions")
    op.drop_column("requirement_applications", "meeting_online_url")
    op.drop_column("requirement_applications", "meeting_location")
    op.drop_column("requirement_applications", "meeting_at")

    op.drop_constraint(
        "fk_meeting_threads_current_round", "meeting_threads", type_="foreignkey"
    )
    op.drop_table("meeting_rounds")
    op.drop_table("meeting_threads")
