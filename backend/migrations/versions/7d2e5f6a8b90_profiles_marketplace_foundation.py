"""profiles marketplace foundation

Revision ID: 7d2e5f6a8b90
Revises: 2f4a6b8c9d10
Create Date: 2026-07-18 00:05:00.000000

"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

import sqlalchemy as sa
from alembic import op

revision = "7d2e5f6a8b90"
down_revision = "2f4a6b8c9d10"
branch_labels = None
depends_on = None


def _audit_columns() -> list[sa.Column]:
    return [
        sa.Column("id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("version", sa.Integer(), nullable=False),
    ]


def _uuid() -> uuid.UUID:
    return uuid.uuid4()


def upgrade() -> None:
    op.create_table(
        "countries",
        *_audit_columns(),
        sa.Column("iso2", sa.String(length=2), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("currency_code", sa.String(length=3), nullable=False),
        sa.Column("phone_prefix", sa.String(length=8), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("iso2", name="uq_countries_iso2"),
    )
    op.create_table(
        "cities",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "country_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("province", sa.String(length=120), nullable=True),
        sa.Column("timezone", sa.String(length=64), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(["country_id"], ["countries.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_cities_public_id"),
    )
    op.create_table(
        "user_profiles",
        *_audit_columns(),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("bio", sa.Text(), nullable=True),
        sa.Column("city_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column(
            "avatar_file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column(
            "cover_file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("website_url", sa.String(length=255), nullable=True),
        sa.Column("profile_visibility", sa.String(length=32), nullable=False),
        sa.Column("rating_average", sa.Numeric(precision=3, scale=2), nullable=False),
        sa.Column("review_count", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["avatar_file_id"], ["files.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["city_id"], ["cities.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["cover_file_id"], ["files.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", name="uq_user_profiles_user_id"),
    )
    op.create_table(
        "talent_profiles",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("screen_name", sa.String(length=120), nullable=False),
        sa.Column("age_range", sa.String(length=32), nullable=True),
        sa.Column("gender_identity", sa.String(length=64), nullable=True),
        sa.Column("height_cm", sa.Integer(), nullable=True),
        sa.Column("union_note", sa.String(length=255), nullable=True),
        sa.Column("experience_years", sa.Integer(), nullable=True),
        sa.Column("availability_status", sa.String(length=32), nullable=False),
        sa.Column("day_rate_minor", sa.Integer(), nullable=True),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_talent_profiles_public_id"),
        sa.UniqueConstraint("user_id", name="uq_talent_profiles_user_id"),
    )
    op.create_table(
        "talent_languages",
        *_audit_columns(),
        sa.Column(
            "talent_profile_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=False,
        ),
        sa.Column("language", sa.String(length=64), nullable=False),
        sa.Column("proficiency", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(
            ["talent_profile_id"], ["talent_profiles.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("talent_profile_id", "language", name="uq_talent_language"),
    )
    op.create_table(
        "marketplace_listings",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "owner_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("listing_type", sa.String(length=64), nullable=False),
        sa.Column("profile_entity_id", sa.String(length=40), nullable=False),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("city_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("price_from_minor", sa.Integer(), nullable=True),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("verification_status", sa.String(length=32), nullable=False),
        sa.Column("moderation_status", sa.String(length=32), nullable=False),
        sa.Column("visibility", sa.String(length=32), nullable=False),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["city_id"], ["cities.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["owner_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_marketplace_listings_public_id"),
    )
    op.create_index(
        "ix_marketplace_listings_search",
        "marketplace_listings",
        ["listing_type", "visibility", "moderation_status", "published_at"],
    )

    countries = sa.table(
        "countries",
        sa.column("id", sa.Uuid(as_uuid=True, native_uuid=False)),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
        sa.column("version", sa.Integer()),
        sa.column("iso2", sa.String()),
        sa.column("name", sa.String()),
        sa.column("currency_code", sa.String()),
        sa.column("phone_prefix", sa.String()),
    )
    cities = sa.table(
        "cities",
        sa.column("id", sa.Uuid(as_uuid=True, native_uuid=False)),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
        sa.column("version", sa.Integer()),
        sa.column("public_id", sa.String()),
        sa.column("country_id", sa.Uuid(as_uuid=True, native_uuid=False)),
        sa.column("name", sa.String()),
        sa.column("province", sa.String()),
        sa.column("timezone", sa.String()),
        sa.column("active", sa.Boolean()),
    )
    now = datetime.now(UTC)
    pk_id = _uuid()
    op.bulk_insert(
        countries,
        [
            {
                "id": pk_id,
                "created_at": now,
                "updated_at": now,
                "version": 1,
                "iso2": "PK",
                "name": "Pakistan",
                "currency_code": "PKR",
                "phone_prefix": "+92",
            }
        ],
    )
    op.bulk_insert(
        cities,
        [
            {
                "id": _uuid(),
                "created_at": now,
                "updated_at": now,
                "version": 1,
                "public_id": public_id,
                "country_id": pk_id,
                "name": name,
                "province": province,
                "timezone": "Asia/Karachi",
                "active": True,
            }
            for public_id, name, province in [
                ("CITY-LHE", "Lahore", "Punjab"),
                ("CITY-KHI", "Karachi", "Sindh"),
                ("CITY-ISB", "Islamabad", "ICT"),
                ("CITY-RWP", "Rawalpindi", "Punjab"),
            ]
        ],
    )


def downgrade() -> None:
    op.drop_index("ix_marketplace_listings_search", table_name="marketplace_listings")
    op.drop_table("marketplace_listings")
    op.drop_table("talent_languages")
    op.drop_table("talent_profiles")
    op.drop_table("user_profiles")
    op.drop_table("cities")
    op.drop_table("countries")
