from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.bookings import Booking
from app.models.files import FileAsset
from app.models.identity import User, make_public_id
from app.models.projects import Project


class InsurancePartnerProfile(EntityMixin, Base):
    __tablename__ = "insurance_partner_profiles"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("INSP")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    license_number_token: Mapped[str | None] = mapped_column(String(255))
    coverage_regions: Mapped[str | None] = mapped_column(String(255))
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")

    user: Mapped[User] = relationship(lazy="joined")


class InsurancePolicy(EntityMixin, Base):
    __tablename__ = "insurance_policies"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("POL")
    )
    project_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("projects.id", ondelete="SET NULL")
    )
    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("bookings.id", ondelete="SET NULL")
    )
    provider_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("insurance_partner_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    insured_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    coverage_summary: Mapped[str] = mapped_column(Text, nullable=False)
    valid_from: Mapped[date] = mapped_column(Date, nullable=False)
    valid_to: Mapped[date] = mapped_column(Date, nullable=False)
    document_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    risk_level: Mapped[str] = mapped_column(String(32), nullable=False, default="low")
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")

    project: Mapped[Project | None] = relationship(lazy="joined")
    booking: Mapped[Booking | None] = relationship(lazy="joined")
    provider_profile: Mapped[InsurancePartnerProfile] = relationship(lazy="joined")
    insured_user: Mapped[User] = relationship(lazy="joined")
    document_file: Mapped[FileAsset | None] = relationship(lazy="joined")
    claims: Mapped[list[InsuranceClaim]] = relationship(
        back_populates="policy", cascade="all, delete-orphan", lazy="selectin"
    )


class InsuranceClaim(EntityMixin, Base):
    __tablename__ = "insurance_claims"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("ICL")
    )
    policy_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("insurance_policies.id", ondelete="CASCADE"), nullable=False
    )
    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("bookings.id", ondelete="SET NULL")
    )
    claimant_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    item_or_room: Mapped[str | None] = mapped_column(String(180))
    adjuster_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    estimate_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="submitted")
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    policy: Mapped[InsurancePolicy] = relationship(back_populates="claims")
    booking: Mapped[Booking | None] = relationship(lazy="joined")
    claimant: Mapped[User] = relationship(
        foreign_keys=[claimant_user_id], lazy="joined"
    )
    adjuster: Mapped[User | None] = relationship(
        foreign_keys=[adjuster_user_id], lazy="joined"
    )
    evidence: Mapped[list[InsuranceClaimEvidence]] = relationship(
        back_populates="claim", cascade="all, delete-orphan", lazy="selectin"
    )


class InsuranceClaimEvidence(EntityMixin, Base):
    __tablename__ = "insurance_claim_evidence"

    claim_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("insurance_claims.id", ondelete="CASCADE"), nullable=False
    )
    file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    evidence_type: Mapped[str] = mapped_column(String(64), nullable=False)
    mandatory: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    caption: Mapped[str | None] = mapped_column(String(255))

    claim: Mapped[InsuranceClaim] = relationship(back_populates="evidence")
    file: Mapped[FileAsset | None] = relationship(lazy="joined")
