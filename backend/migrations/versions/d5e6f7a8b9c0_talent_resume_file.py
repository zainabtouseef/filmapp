"""talent profile resume file

Revision ID: d5e6f7a8b9c0
Revises: c4d5e6f7a8b9
Create Date: 2026-07-25 09:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "d5e6f7a8b9c0"
down_revision = "c4d5e6f7a8b9"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "talent_profiles",
        sa.Column(
            "resume_file_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=True,
        ),
    )
    op.create_foreign_key(
        "fk_talent_profiles_resume_file_id_files",
        "talent_profiles",
        "files",
        ["resume_file_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade():
    op.drop_constraint(
        "fk_talent_profiles_resume_file_id_files",
        "talent_profiles",
        type_="foreignkey",
    )
    op.drop_column("talent_profiles", "resume_file_id")
