"""admin verification permissions

Revision ID: 2f4a6b8c9d10
Revises: 9c1d4f8a2b67
Create Date: 2026-07-17 23:40:00.000000

"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

import sqlalchemy as sa
from alembic import op

revision = "2f4a6b8c9d10"
down_revision = "9c1d4f8a2b67"
branch_labels = None
depends_on = None


def _uuid() -> str:
    return uuid.uuid4().hex


def _now() -> datetime:
    return datetime.now(UTC)


def upgrade() -> None:
    connection = op.get_bind()
    now = _now()

    admin_roles = [
        ("support_agent", "Support Agent", "/admin/support", 901),
        ("reviewer", "Reviewer", "/admin/review-hub", 902),
        ("finance_admin", "Finance Admin", "/admin/payments", 903),
        ("super_admin", "Super Admin", "/admin/dashboard", 999),
    ]
    for code, name, route, order in admin_roles:
        connection.execute(
            sa.text(
                """
                INSERT INTO roles
                    (id, created_at, updated_at, version, code, name, portal_route,
                     requires_kyc, display_order, is_active)
                SELECT
                    :id, :now, :now, 1, :code, :name, :route,
                    false, :display_order, false
                WHERE NOT EXISTS (SELECT 1 FROM roles WHERE code = :code)
                """
            ),
            {
                "id": _uuid(),
                "now": now,
                "code": code,
                "name": name,
                "route": route,
                "display_order": order,
            },
        )

    connection.execute(
        sa.text(
            """
            INSERT INTO permissions
                (id, created_at, updated_at, version, code, description)
            SELECT
                :id, :now, :now, 1, 'kyc.review',
                'Review and decide KYC submissions'
            WHERE NOT EXISTS (SELECT 1 FROM permissions WHERE code = 'kyc.review')
            """
        ),
        {"id": _uuid(), "now": now},
    )

    for role_code in ("reviewer", "super_admin"):
        connection.execute(
            sa.text(
                """
                INSERT INTO role_permissions
                    (id, created_at, updated_at, version, role_id, permission_id)
                SELECT
                    :id, :now, :now, 1, r.id, p.id
                FROM roles r
                JOIN permissions p ON p.code = 'kyc.review'
                WHERE r.code = :role_code
                  AND NOT EXISTS (
                    SELECT 1
                    FROM role_permissions rp
                    WHERE rp.role_id = r.id AND rp.permission_id = p.id
                  )
                """
            ),
            {"id": _uuid(), "now": now, "role_code": role_code},
        )


def downgrade() -> None:
    connection = op.get_bind()
    connection.execute(
        sa.text(
            """
            DELETE rp
            FROM role_permissions rp
            JOIN permissions p ON p.id = rp.permission_id
            JOIN roles r ON r.id = rp.role_id
            WHERE p.code = 'kyc.review'
              AND r.code IN ('reviewer', 'super_admin')
            """
        )
    )
    connection.execute(sa.text("DELETE FROM permissions WHERE code = 'kyc.review'"))
    connection.execute(
        sa.text(
            """
            DELETE FROM roles
            WHERE code IN ('support_agent', 'reviewer', 'finance_admin', 'super_admin')
            """
        )
    )
