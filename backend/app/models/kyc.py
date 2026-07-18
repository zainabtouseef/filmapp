from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import JSON, Date, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.files import FileAsset
from app.models.identity import Role, User, make_public_id


class KycSubmission(EntityMixin, Base):
    __tablename__ = "kyc_submissions"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("KYC"),
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    role_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("roles.id", ondelete="RESTRICT"),
        nullable=False,
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    risk_level: Mapped[str] = mapped_column(String(32), nullable=False, default="low")
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    assigned_admin_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    decision_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    decision_reason: Mapped[str | None] = mapped_column(Text)

    user: Mapped[User] = relationship(foreign_keys=[user_id])
    role: Mapped[Role] = relationship()
    documents: Mapped[list[KycDocument]] = relationship(
        back_populates="submission",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class KycDocument(EntityMixin, Base):
    __tablename__ = "kyc_documents"

    submission_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("kyc_submissions.id", ondelete="CASCADE"),
        nullable=False,
    )
    file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    document_type: Mapped[str] = mapped_column(String(64), nullable=False)
    country: Mapped[str] = mapped_column(String(2), nullable=False, default="PK")
    document_number_encrypted: Mapped[str | None] = mapped_column(Text)
    expires_on: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    rejection_reason: Mapped[str | None] = mapped_column(Text)

    submission: Mapped[KycSubmission] = relationship(back_populates="documents")
    file: Mapped[FileAsset | None] = relationship()


class VerificationEvent(EntityMixin, Base):
    __tablename__ = "verification_events"

    submission_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("kyc_submissions.id", ondelete="CASCADE"),
        nullable=False,
    )
    actor_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    from_status: Mapped[str | None] = mapped_column(String(32))
    to_status: Mapped[str] = mapped_column(String(32), nullable=False)
    reason: Mapped[str | None] = mapped_column(Text)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(
        JSON,
        nullable=False,
        default=dict,
    )

    submission: Mapped[KycSubmission] = relationship()
