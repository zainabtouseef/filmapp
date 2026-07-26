"""requirement visibility, quantity and required documents

Revision ID: a1b2c3d4e5f6
Revises: f7a8b9c0d1e2
Create Date: 2026-07-26 10:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "dd9621ac7f1d"
down_revision = "f7a8b9c0d1e2"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "project_requirements",
        sa.Column(
            "visibility",
            sa.String(length=32),
            nullable=False,
            server_default="all",
        ),
    )
    op.add_column(
        "project_requirements",
        sa.Column(
            "quantity",
            sa.Integer(),
            nullable=False,
            server_default="1",
        ),
    )
    op.add_column(
        "project_requirements",
        sa.Column("required_documents_json", sa.Text(), nullable=True),
    )


def downgrade():
    op.drop_column("project_requirements", "required_documents_json")
    op.drop_column("project_requirements", "quantity")
    op.drop_column("project_requirements", "visibility")
