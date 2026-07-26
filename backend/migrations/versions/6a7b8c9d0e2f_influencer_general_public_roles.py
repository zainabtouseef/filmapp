"""influencer and general public roles

Revision ID: 6a7b8c9d0e2f
Revises: 95078f84def1
Create Date: 2026-07-26 18:55:00.000000

"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

import sqlalchemy as sa
from alembic import op

revision = "6a7b8c9d0e2f"
down_revision = "95078f84def1"
branch_labels = None
depends_on = None


def _id() -> str:
    return uuid.uuid4().hex


def upgrade() -> None:
    connection = op.get_bind()
    inspector = sa.inspect(connection)
    talent_columns = {column["name"] for column in inspector.get_columns("talent_profiles")}
    if "availability_categories_json" not in talent_columns:
        op.add_column(
            "talent_profiles",
            sa.Column("availability_categories_json", sa.Text(), nullable=True),
        )
    now = datetime.now(UTC)
    for code, name, route, requires_kyc, display_order in [
        ("influencer", "Influencer", "/talent", True, 4),
        ("general_public", "General Public", "/public", False, 9),
    ]:
        connection.execute(
            sa.text(
                """
                INSERT INTO roles
                    (id, created_at, updated_at, deleted_at, version, code, name,
                     portal_route, requires_kyc, display_order, is_active)
                SELECT
                    :id, :now, :now, NULL, 1, :code, :name,
                    :route, :requires_kyc, :display_order, 1
                WHERE NOT EXISTS (SELECT 1 FROM roles WHERE code = :code)
                """
            ),
            {
                "id": _id(),
                "now": now,
                "code": code,
                "name": name,
                "route": route,
                "requires_kyc": requires_kyc,
                "display_order": display_order,
            },
        )

    connection.execute(
        sa.text(
            """
            UPDATE talent_profiles
            SET availability_categories_json = '["actor"]'
            WHERE availability_categories_json IS NULL
               OR availability_categories_json = ''
            """
        )
    )


def downgrade() -> None:
    connection = op.get_bind()
    connection.execute(
        sa.text("DELETE FROM roles WHERE code IN ('influencer', 'general_public')")
    )
    inspector = sa.inspect(connection)
    talent_columns = {column["name"] for column in inspector.get_columns("talent_profiles")}
    if "availability_categories_json" in talent_columns:
        op.drop_column("talent_profiles", "availability_categories_json")
