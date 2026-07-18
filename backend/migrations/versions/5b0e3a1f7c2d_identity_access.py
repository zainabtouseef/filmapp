"""identity and access foundation

Revision ID: 5b0e3a1f7c2d
Revises: efc80f32cc35
Create Date: 2026-07-17 23:10:00.000000

"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

import sqlalchemy as sa
from alembic import op

revision = "5b0e3a1f7c2d"
down_revision = "efc80f32cc35"
branch_labels = None
depends_on = None


def _id() -> uuid.UUID:
    return uuid.uuid4()


def _audit_columns() -> list[sa.Column]:
    return [
        sa.Column("id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("version", sa.Integer(), nullable=False),
    ]


def upgrade() -> None:
    op.create_table(
        "users",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=32), nullable=False),
        sa.Column("email", sa.String(length=254), nullable=False),
        sa.Column("phone_e164", sa.String(length=32), nullable=True),
        sa.Column("password_hash", sa.Text(), nullable=False),
        sa.Column("display_name", sa.String(length=120), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("email_verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("phone_verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("terms_version", sa.String(length=32), nullable=False),
        sa.Column("terms_accepted_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email", name="uq_users_email"),
        sa.UniqueConstraint("phone_e164", name="uq_users_phone_e164"),
        sa.UniqueConstraint("public_id", name="uq_users_public_id"),
    )
    op.create_table(
        "roles",
        *_audit_columns(),
        sa.Column("code", sa.String(length=64), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("portal_route", sa.String(length=120), nullable=False),
        sa.Column("requires_kyc", sa.Boolean(), nullable=False),
        sa.Column("display_order", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code", name="uq_roles_code"),
    )
    op.create_table(
        "permissions",
        *_audit_columns(),
        sa.Column("code", sa.String(length=120), nullable=False),
        sa.Column("description", sa.String(length=255), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code", name="uq_permissions_code"),
    )
    op.create_table(
        "auth_security_events",
        *_audit_columns(),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("event_type", sa.String(length=64), nullable=False),
        sa.Column("success", sa.Boolean(), nullable=False),
        sa.Column("ip_address", sa.String(length=64), nullable=True),
        sa.Column("user_agent", sa.String(length=512), nullable=True),
        sa.Column("risk_score", sa.Integer(), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "notification_preferences",
        *_audit_columns(),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("email_enabled", sa.Boolean(), nullable=False),
        sa.Column("sms_enabled", sa.Boolean(), nullable=False),
        sa.Column("push_enabled", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", name="uq_notification_preferences_user_id"),
    )
    op.create_table(
        "password_reset_tokens",
        *_audit_columns(),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token_hash", name="uq_password_reset_tokens_token_hash"),
    )
    op.create_table(
        "role_permissions",
        *_audit_columns(),
        sa.Column("role_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column(
            "permission_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["permission_id"], ["permissions.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("role_id", "permission_id", name="uq_role_permission"),
    )
    op.create_table(
        "user_roles",
        *_audit_columns(),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("role_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("is_primary", sa.Boolean(), nullable=False),
        sa.Column("approved_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "role_id", name="uq_user_role"),
    )
    op.create_index(
        "ix_user_roles_user_primary",
        "user_roles",
        ["user_id", "is_primary"],
    )
    op.create_table(
        "user_sessions",
        *_audit_columns(),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("refresh_token_hash", sa.String(length=64), nullable=False),
        sa.Column("refresh_token_family", sa.String(length=64), nullable=False),
        sa.Column("previous_refresh_token_hash", sa.String(length=64), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ip_address", sa.String(length=64), nullable=True),
        sa.Column("user_agent", sa.String(length=512), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "refresh_token_hash", name="uq_user_sessions_refresh_token_hash"
        ),
    )
    op.create_index(
        "ix_user_sessions_user_expires",
        "user_sessions",
        ["user_id", "expires_at"],
    )
    op.create_table(
        "user_settings",
        *_audit_columns(),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("timezone", sa.String(length=64), nullable=False),
        sa.Column("locale", sa.String(length=16), nullable=False),
        sa.Column("active_role_code", sa.String(length=64), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", name="uq_user_settings_user_id"),
    )
    op.create_index(
        "ix_auth_security_events_user_created",
        "auth_security_events",
        ["user_id", "created_at"],
    )

    roles_table = sa.table(
        "roles",
        sa.column("id", sa.Uuid(as_uuid=True, native_uuid=False)),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
        sa.column("version", sa.Integer()),
        sa.column("code", sa.String()),
        sa.column("name", sa.String()),
        sa.column("portal_route", sa.String()),
        sa.column("requires_kyc", sa.Boolean()),
        sa.column("display_order", sa.Integer()),
        sa.column("is_active", sa.Boolean()),
    )
    now = datetime.now(UTC)
    op.bulk_insert(
        roles_table,
        [
            {
                "id": _id(),
                "created_at": now,
                "updated_at": now,
                "version": 1,
                "code": code,
                "name": name,
                "portal_route": route,
                "requires_kyc": True,
                "display_order": index,
                "is_active": True,
            }
            for index, (code, name, route) in enumerate(
                [
                    ("director_producer", "Director / Producer", "/director"),
                    ("actor_talent", "Actor / Talent", "/talent"),
                    ("model", "Model", "/model"),
                    ("location_owner", "Location Owner", "/location-owner"),
                    (
                        "equipment_provider",
                        "Media / Equipment Provider",
                        "/equipment-provider",
                    ),
                    ("crew_service", "Crew / Services", "/crew"),
                    ("casting_agency", "Casting Agency", "/agency"),
                    ("brand_sponsor", "Brand / Sponsor", "/brand"),
                    ("legal_partner", "Legal Partner", "/legal"),
                    ("insurance_partner", "Insurance / Safety Partner", "/insurance"),
                    (
                        "distribution_partner",
                        "Distribution / Release Partner",
                        "/distribution",
                    ),
                ],
                start=1,
            )
        ],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_auth_security_events_user_created", table_name="auth_security_events"
    )
    op.drop_table("user_settings")
    op.drop_index("ix_user_sessions_user_expires", table_name="user_sessions")
    op.drop_table("user_sessions")
    op.drop_index("ix_user_roles_user_primary", table_name="user_roles")
    op.drop_table("user_roles")
    op.drop_table("role_permissions")
    op.drop_table("password_reset_tokens")
    op.drop_table("notification_preferences")
    op.drop_table("auth_security_events")
    op.drop_table("permissions")
    op.drop_table("roles")
    op.drop_table("users")
