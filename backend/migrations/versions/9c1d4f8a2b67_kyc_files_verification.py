"""kyc files and verification

Revision ID: 9c1d4f8a2b67
Revises: 5b0e3a1f7c2d
Create Date: 2026-07-17 23:50:00.000000

"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "9c1d4f8a2b67"
down_revision = "5b0e3a1f7c2d"
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


def upgrade() -> None:
    op.create_table(
        "files",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column(
            "owner_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("storage_key", sa.String(length=512), nullable=False),
        sa.Column("bucket", sa.String(length=120), nullable=False),
        sa.Column("mime_type", sa.String(length=120), nullable=False),
        sa.Column("size_bytes", sa.Integer(), nullable=False),
        sa.Column("checksum_sha256", sa.String(length=64), nullable=True),
        sa.Column("visibility", sa.String(length=32), nullable=False),
        sa.Column("scan_status", sa.String(length=32), nullable=False),
        sa.Column("processing_status", sa.String(length=32), nullable=False),
        sa.Column("original_name", sa.String(length=255), nullable=False),
        sa.ForeignKeyConstraint(["owner_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_files_public_id"),
        sa.UniqueConstraint("storage_key", name="uq_files_storage_key"),
    )
    op.create_table(
        "file_variants",
        *_audit_columns(),
        sa.Column("file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("variant", sa.String(length=64), nullable=False),
        sa.Column("storage_key", sa.String(length=512), nullable=False),
        sa.Column("width", sa.Integer(), nullable=True),
        sa.Column("height", sa.Integer(), nullable=True),
        sa.Column("duration_seconds", sa.Integer(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.ForeignKeyConstraint(["file_id"], ["files.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "upload_sessions",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("purpose", sa.String(length=64), nullable=False),
        sa.Column("mime_type", sa.String(length=120), nullable=False),
        sa.Column("max_bytes", sa.Integer(), nullable=False),
        sa.Column("storage_key", sa.String(length=512), nullable=False),
        sa.Column("bucket", sa.String(length=120), nullable=False),
        sa.Column("original_name", sa.String(length=255), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.ForeignKeyConstraint(["file_id"], ["files.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_upload_sessions_public_id"),
        sa.UniqueConstraint("storage_key", name="uq_upload_sessions_storage_key"),
    )
    op.create_index(
        "ix_upload_sessions_user_purpose", "upload_sessions", ["user_id", "purpose"]
    )
    op.create_table(
        "kyc_submissions",
        *_audit_columns(),
        sa.Column("public_id", sa.String(length=40), nullable=False),
        sa.Column("user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("role_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("risk_level", sa.String(length=32), nullable=False),
        sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "assigned_admin_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("decision_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("decision_reason", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(
            ["assigned_admin_id"], ["users.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("public_id", name="uq_kyc_submissions_public_id"),
    )
    op.create_index(
        "ix_kyc_submissions_status_created", "kyc_submissions", ["status", "created_at"]
    )
    op.create_table(
        "kyc_documents",
        *_audit_columns(),
        sa.Column(
            "submission_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column("file_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True),
        sa.Column("document_type", sa.String(length=64), nullable=False),
        sa.Column("country", sa.String(length=2), nullable=False),
        sa.Column("document_number_encrypted", sa.Text(), nullable=True),
        sa.Column("expires_on", sa.Date(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("rejection_reason", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["file_id"], ["files.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(
            ["submission_id"], ["kyc_submissions.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "verification_events",
        *_audit_columns(),
        sa.Column(
            "submission_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=False
        ),
        sa.Column(
            "actor_user_id", sa.Uuid(as_uuid=True, native_uuid=False), nullable=True
        ),
        sa.Column("from_status", sa.String(length=32), nullable=True),
        sa.Column("to_status", sa.String(length=32), nullable=False),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(
            ["submission_id"], ["kyc_submissions.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_verification_events_submission_created",
        "verification_events",
        ["submission_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_verification_events_submission_created", table_name="verification_events"
    )
    op.drop_table("verification_events")
    op.drop_table("kyc_documents")
    op.drop_index("ix_kyc_submissions_status_created", table_name="kyc_submissions")
    op.drop_table("kyc_submissions")
    op.drop_index("ix_upload_sessions_user_purpose", table_name="upload_sessions")
    op.drop_table("upload_sessions")
    op.drop_table("file_variants")
    op.drop_table("files")
