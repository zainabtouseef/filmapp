"""projects requirements skills

Revision ID: a1b2c3d4e5f6
Revises: 9a4b6c7d8e30
Create Date: 2026-07-17 23:35:00.000000

"""

from __future__ import annotations

from datetime import UTC, datetime

import sqlalchemy as sa
from alembic import op

revision = "a1b2c3d4e5f6"
down_revision = "9a4b6c7d8e30"
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


def _id() -> object:
    import uuid

    return uuid.uuid4()


def upgrade() -> None:
    op.create_table(
        "projects",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "owner_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("organization_id", sa.String(length=40), nullable=True),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("project_type", sa.String(length=64), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("city_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("start_date", sa.Date(), nullable=True),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("estimated_budget_minor", sa.Integer(), nullable=True),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("visibility", sa.String(length=32), nullable=False),
        sa.Column("progress_percent", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["city_id"], ["cities.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["owner_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_projects_public_id"),
    )
    op.create_index("ix_projects_owner_status", "projects", ["owner_user_id", "status"])
    op.create_table(
        "project_members",
        *_audit_columns(),
        sa.Column(
            "project_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("role_label", sa.String(length=120), nullable=False),
        sa.Column("permissions_json", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("project_id", "user_id", name="uq_project_member_user"),
    )
    op.create_index(
        "ix_project_members_user_status",
        "project_members",
        ["user_id", "status"],
    )
    op.create_table(
        "skills",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_skills_public_id"),
    )
    op.create_index("ix_skills_category_active", "skills", ["category", "active"])
    op.create_table(
        "project_requirements",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "project_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("summary", sa.Text(), nullable=True),
        sa.Column("budget_min_minor", sa.Integer(), nullable=True),
        sa.Column("budget_max_minor", sa.Integer(), nullable=True),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=True),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("candidate_count_cache", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_project_requirements_public_id"),
    )
    op.create_index(
        "ix_project_requirements_project_status",
        "project_requirements",
        ["project_id", "status"],
    )
    op.create_table(
        "requirement_skills",
        *_audit_columns(),
        sa.Column(
            "requirement_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("skill_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("required", sa.Boolean(), nullable=False),
        sa.Column("minimum_level", sa.String(length=32), nullable=True),
        sa.ForeignKeyConstraint(
            ["requirement_id"], ["project_requirements.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(["skill_id"], ["skills.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("requirement_id", "skill_id", name="uq_requirement_skill"),
    )
    now = datetime.now(UTC)
    skills_table = sa.table(
        "skills",
        sa.column("id", sa.Uuid(as_uuid=True, native_uuid=False)),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
        sa.column("version", sa.Integer()),
        sa.column("public_id", sa.String()),
        sa.column("category", sa.String()),
        sa.column("name", sa.String()),
        sa.column("active", sa.Boolean()),
    )
    op.bulk_insert(
        skills_table,
        [
            {
                "id": _id(),
                "created_at": now,
                "updated_at": now,
                "version": 1,
                "public_id": public_id,
                "category": category,
                "name": name,
                "active": True,
            }
            for public_id, category, name in [
                ("SKILL-ACT-DRAMA", "acting", "Dramatic acting"),
                ("SKILL-ACT-COMEDY", "acting", "Comedy timing"),
                ("SKILL-ACT-TVC", "acting", "TVC performance"),
                ("SKILL-LANG-URDU", "language", "Urdu"),
                ("SKILL-LANG-EN", "language", "English"),
                ("SKILL-CREW-DOP", "crew", "Director of photography"),
                ("SKILL-CREW-GAFFER", "crew", "Gaffer"),
                ("SKILL-EQP-CAMERA", "equipment", "Cinema camera package"),
                ("SKILL-LOC-HOME", "location", "Residential location"),
                ("SKILL-LEGAL-CONTRACT", "legal", "Contract review"),
            ]
        ],
    )


def downgrade() -> None:
    op.drop_table("requirement_skills")
    op.drop_index(
        "ix_project_requirements_project_status", table_name="project_requirements"
    )
    op.drop_table("project_requirements")
    op.drop_index("ix_skills_category_active", table_name="skills")
    op.drop_table("skills")
    op.drop_index("ix_project_members_user_status", table_name="project_members")
    op.drop_table("project_members")
    op.drop_index("ix_projects_owner_status", table_name="projects")
    op.drop_table("projects")
