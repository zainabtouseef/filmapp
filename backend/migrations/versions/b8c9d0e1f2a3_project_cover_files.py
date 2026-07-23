"""project cover files

Revision ID: b8c9d0e1f2a3
Revises: a7b8c9d0e1f2
Create Date: 2026-07-22 19:15:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "b8c9d0e1f2a3"
down_revision = "a7b8c9d0e1f2"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "projects",
        sa.Column(
            "cover_file_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=True,
        ),
    )
    op.create_foreign_key(
        "fk_projects_cover_file_id_files",
        "projects",
        "files",
        ["cover_file_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade():
    op.drop_constraint(
        "fk_projects_cover_file_id_files",
        "projects",
        type_="foreignkey",
    )
    op.drop_column("projects", "cover_file_id")
