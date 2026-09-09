"""contracts legal

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a7b8
Create Date: 2026-07-18 01:20:00.000000

"""

from __future__ import annotations

from datetime import UTC, datetime

import sqlalchemy as sa
from alembic import op

revision = "d4e5f6a7b8c9"
down_revision = "c3d4e5f6a7b8"
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
        "contract_templates",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("name", sa.String(length=180), nullable=False),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column("jurisdiction", sa.String(length=8), nullable=False),
        sa.Column("version_number", sa.Integer(), nullable=False),
        sa.Column("body_schema_json", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column(
            "created_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column(
            "approved_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["approved_by"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_contract_templates_public_id"),
    )
    op.create_index(
        "ix_contract_templates_category_status",
        "contract_templates",
        ["category", "status"],
    )
    op.create_table(
        "template_clauses",
        *_audit_columns(),
        sa.Column(
            "template_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("clause_key", sa.String(length=80), nullable=False),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("body_text", sa.Text(), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("required", sa.Boolean(), nullable=False),
        sa.Column("editable", sa.Boolean(), nullable=False),
        sa.ForeignKeyConstraint(
            ["template_id"], ["contract_templates.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("template_id", "clause_key", name="uq_template_clause_key"),
    )
    op.create_table(
        "contracts",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "booking_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "project_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "template_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("version_number", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("effective_date", sa.Date(), nullable=True),
        sa.Column("value_minor", sa.Integer(), nullable=True),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column(
            "rendered_file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("content_snapshot_json", sa.Text(), nullable=False),
        sa.Column(
            "signature_progress", sa.Numeric(precision=4, scale=3), nullable=False
        ),
        sa.ForeignKeyConstraint(["booking_id"], ["bookings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["rendered_file_id"], ["files.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(
            ["template_id"], ["contract_templates.id"], ondelete="RESTRICT"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("booking_id", name="uq_contracts_booking_id"),
        sa.UniqueConstraint("public_id", name="uq_contracts_public_id"),
    )
    op.create_index(
        "ix_contracts_project_status", "contracts", ["project_id", "status"]
    )
    op.create_table(
        "contract_parties",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "contract_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("organization_id", sa.String(length=40), nullable=True),
        sa.Column("party_role", sa.String(length=64), nullable=False),
        sa.Column("signing_order", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(["contract_id"], ["contracts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_contract_parties_public_id"),
        sa.UniqueConstraint("contract_id", "user_id", name="uq_contract_party_user"),
    )
    op.create_index(
        "ix_contract_parties_user_status", "contract_parties", ["user_id", "status"]
    )
    op.create_table(
        "contract_clauses",
        *_audit_columns(),
        sa.Column(
            "contract_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("clause_key", sa.String(length=80), nullable=False),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("body_text", sa.Text(), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("highlighted", sa.Boolean(), nullable=False),
        sa.Column(
            "source_template_clause_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["contract_id"], ["contracts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["source_template_clause_id"], ["template_clauses.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("contract_id", "clause_key", name="uq_contract_clause_key"),
    )
    op.create_table(
        "contract_signatures",
        *_audit_columns(),
        sa.Column(
            "contract_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("party_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column(
            "signer_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "signature_file_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=True,
        ),
        sa.Column("signature_hash", sa.String(length=128), nullable=False),
        sa.Column("signed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ip_address", sa.String(length=64), nullable=True),
        sa.Column("user_agent", sa.String(length=512), nullable=True),
        sa.ForeignKeyConstraint(["contract_id"], ["contracts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["party_id"], ["contract_parties.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["signature_file_id"], ["files.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["signer_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("party_id", name="uq_contract_signature_party"),
    )
    op.create_table(
        "contract_addendums",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "contract_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "requested_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column(
            "reviewer_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column(
            "rendered_file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.ForeignKeyConstraint(["contract_id"], ["contracts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["rendered_file_id"], ["files.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["requested_by"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["reviewer_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_contract_addendums_public_id"),
    )
    op.create_table(
        "legal_review_requests",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "contract_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column(
            "template_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column(
            "addendum_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column(
            "requested_by", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "assigned_legal_user_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=True,
        ),
        sa.Column("contract_type", sa.String(length=64), nullable=False),
        sa.Column("risk", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("sla_due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("decision_notes", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(
            ["addendum_id"], ["contract_addendums.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(
            ["assigned_legal_user_id"], ["users.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["contract_id"], ["contracts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["requested_by"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["template_id"], ["contract_templates.id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_legal_review_requests_public_id"),
    )
    op.create_index(
        "ix_legal_review_status_created",
        "legal_review_requests",
        ["status", "created_at"],
    )
    op.create_table(
        "legal_clause_risks",
        *_audit_columns(),
        sa.Column(
            "review_request_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=False,
        ),
        sa.Column(
            "contract_clause_id",
            sa.Uuid(as_uuid=True, native_uuid=False),
            nullable=True,
        ),
        sa.Column("risk_level", sa.String(length=32), nullable=False),
        sa.Column("issue", sa.Text(), nullable=False),
        sa.Column("recommendation", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(
            ["contract_clause_id"], ["contract_clauses.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(
            ["review_request_id"], ["legal_review_requests.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "legal_billing_records",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "legal_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("matter_type", sa.String(length=64), nullable=False),
        sa.Column("matter_id", sa.String(length=40), nullable=False),
        sa.Column(
            "client_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("minutes", sa.Integer(), nullable=False),
        sa.Column("amount_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("invoice_number", sa.String(length=64), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["client_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["legal_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_legal_billing_records_public_id"),
    )

    now = datetime.now(UTC)
    template_id = _id()
    contract_templates = sa.table(
        "contract_templates",
        sa.column("id", sa.Uuid(as_uuid=True, native_uuid=False)),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
        sa.column("deleted_at", sa.DateTime(timezone=True)),
        sa.column("version", sa.Integer()),
        sa.column("public_id", sa.String(length=40)),
        sa.column("name", sa.String(length=180)),
        sa.column("category", sa.String(length=64)),
        sa.column("jurisdiction", sa.String(length=8)),
        sa.column("version_number", sa.Integer()),
        sa.column("body_schema_json", sa.Text()),
        sa.column("status", sa.String(length=32)),
        sa.column("published_at", sa.DateTime(timezone=True)),
    )
    template_clauses = sa.table(
        "template_clauses",
        sa.column("id", sa.Uuid(as_uuid=True, native_uuid=False)),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
        sa.column("deleted_at", sa.DateTime(timezone=True)),
        sa.column("version", sa.Integer()),
        sa.column("template_id", sa.Uuid(as_uuid=True, native_uuid=False)),
        sa.column("clause_key", sa.String(length=80)),
        sa.column("title", sa.String(length=180)),
        sa.column("body_text", sa.Text()),
        sa.column("sort_order", sa.Integer()),
        sa.column("required", sa.Boolean()),
        sa.column("editable", sa.Boolean()),
    )
    op.bulk_insert(
        contract_templates,
        [
            {
                "id": template_id,
                "created_at": now,
                "updated_at": now,
                "deleted_at": None,
                "version": 1,
                "public_id": "TPL-TALENT-001",
                "name": "Talent Engagement Agreement",
                "category": "talent",
                "jurisdiction": "PK",
                "version_number": 1,
                "body_schema_json": (
                    '{"sections":["scope","payment_schedule","usage_rights",'
                    '"cancellation","safety"]}'
                ),
                "status": "published",
                "published_at": now,
            }
        ],
    )
    op.bulk_insert(
        template_clauses,
        [
            {
                "id": _id(),
                "created_at": now,
                "updated_at": now,
                "deleted_at": None,
                "version": 1,
                "template_id": template_id,
                "clause_key": "scope",
                "title": "Scope of Work",
                "body_text": (
                    "The talent will provide the agreed performance services for the "
                    "project dates, locations, call times, and deliverables recorded in "
                    "the accepted booking."
                ),
                "sort_order": 10,
                "required": True,
                "editable": False,
            },
            {
                "id": _id(),
                "created_at": now,
                "updated_at": now,
                "deleted_at": None,
                "version": 1,
                "template_id": template_id,
                "clause_key": "payment_schedule",
                "title": "Payment Schedule",
                "body_text": (
                    "Payment will follow the accepted offer amount and schedule. Any "
                    "manual bank transfer or card payment rail remains dummy until "
                    "production payment details are configured."
                ),
                "sort_order": 20,
                "required": True,
                "editable": True,
            },
            {
                "id": _id(),
                "created_at": now,
                "updated_at": now,
                "deleted_at": None,
                "version": 1,
                "template_id": template_id,
                "clause_key": "usage_rights",
                "title": "Usage Rights",
                "body_text": (
                    "The producer may use approved footage and publicity materials for "
                    "the project scope described in the booking unless an addendum "
                    "grants broader rights."
                ),
                "sort_order": 30,
                "required": True,
                "editable": True,
            },
            {
                "id": _id(),
                "created_at": now,
                "updated_at": now,
                "deleted_at": None,
                "version": 1,
                "template_id": template_id,
                "clause_key": "cancellation",
                "title": "Cancellation",
                "body_text": (
                    "Cancellation, postponement, and no-show handling will follow the "
                    "accepted booking terms and any mutually approved platform policy."
                ),
                "sort_order": 40,
                "required": True,
                "editable": True,
            },
            {
                "id": _id(),
                "created_at": now,
                "updated_at": now,
                "deleted_at": None,
                "version": 1,
                "template_id": template_id,
                "clause_key": "safety",
                "title": "Safety and Conduct",
                "body_text": (
                    "Both parties agree to maintain a safe working environment, report "
                    "safety concerns through CineConnect, and avoid conduct that would "
                    "place cast, crew, or production assets at risk."
                ),
                "sort_order": 50,
                "required": True,
                "editable": False,
            },
        ],
    )


def downgrade() -> None:
    op.drop_table("legal_billing_records")
    op.drop_table("legal_clause_risks")
    op.drop_index("ix_legal_review_status_created", table_name="legal_review_requests")
    op.drop_table("legal_review_requests")
    op.drop_table("contract_addendums")
    op.drop_table("contract_signatures")
    op.drop_table("contract_clauses")
    op.drop_index("ix_contract_parties_user_status", table_name="contract_parties")
    op.drop_table("contract_parties")
    op.drop_index("ix_contracts_project_status", table_name="contracts")
    op.drop_table("contracts")
    op.drop_table("template_clauses")
    op.drop_index(
        "ix_contract_templates_category_status",
        table_name="contract_templates",
    )
    op.drop_table("contract_templates")
