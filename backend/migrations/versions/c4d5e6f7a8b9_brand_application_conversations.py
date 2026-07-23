"""brand sponsor workflow records

Revision ID: c4d5e6f7a8b9
Revises: b8c9d0e1f2a3
Create Date: 2026-07-23 18:45:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "c4d5e6f7a8b9"
down_revision = "b8c9d0e1f2a3"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "brand_applications",
        sa.Column(
            "conversation_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=True,
        ),
    )
    op.add_column(
        "brand_applications",
        sa.Column("rejection_reason", sa.Text(), nullable=True),
    )
    op.create_unique_constraint(
        "uq_brand_applications_conversation_id",
        "brand_applications",
        ["conversation_id"],
    )
    op.create_foreign_key(
        "fk_brand_applications_conversation_id_conversations",
        "brand_applications",
        "conversations",
        ["conversation_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.add_column(
        "campaign_deliverables",
        sa.Column("revision_note", sa.Text(), nullable=True),
    )


def downgrade():
    op.drop_column("campaign_deliverables", "revision_note")
    op.drop_constraint(
        "fk_brand_applications_conversation_id_conversations",
        "brand_applications",
        type_="foreignkey",
    )
    op.drop_constraint(
        "uq_brand_applications_conversation_id",
        "brand_applications",
        type_="unique",
    )
    op.drop_column("brand_applications", "rejection_reason")
    op.drop_column("brand_applications", "conversation_id")
