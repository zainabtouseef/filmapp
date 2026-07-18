from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.bookings import Booking
from app.models.files import FileAsset
from app.models.identity import User, make_public_id
from app.models.marketplace import City, TalentProfile
from app.models.projects import Project, ProjectRequirement


class CastingAgency(EntityMixin, Base):
    __tablename__ = "casting_agencies"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("AGY")
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    city_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cities.id", ondelete="SET NULL")
    )
    commission_bps: Mapped[int] = mapped_column(Integer, nullable=False, default=1000)
    verification_status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="pending"
    )

    owner: Mapped[User] = relationship(lazy="joined")
    city: Mapped[City | None] = relationship(lazy="joined")


class AgencyInvitation(EntityMixin, Base):
    __tablename__ = "agency_invitations"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("AGI")
    )
    agency_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("casting_agencies.id", ondelete="CASCADE"), nullable=False
    )
    invited_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    talent_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    contact_token: Mapped[str | None] = mapped_column(String(255))
    representation_type: Mapped[str] = mapped_column(
        String(32), nullable=False, default="non_exclusive"
    )
    commission_bps: Mapped[int] = mapped_column(Integer, nullable=False, default=1000)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    agency: Mapped[CastingAgency] = relationship(lazy="joined")
    invited_by_user: Mapped[User] = relationship(
        foreign_keys=[invited_by], lazy="joined"
    )
    talent_user: Mapped[User | None] = relationship(
        foreign_keys=[talent_user_id], lazy="joined"
    )


class AgencyTalent(EntityMixin, Base):
    __tablename__ = "agency_talent"
    __table_args__ = (
        UniqueConstraint("agency_id", "talent_profile_id", name="uq_agency_talent"),
    )

    agency_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("casting_agencies.id", ondelete="CASCADE"), nullable=False
    )
    talent_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("talent_profiles.id", ondelete="CASCADE"), nullable=False
    )
    representation_type: Mapped[str] = mapped_column(
        String(32), nullable=False, default="non_exclusive"
    )
    start_date: Mapped[date | None] = mapped_column(Date)
    end_date: Mapped[date | None] = mapped_column(Date)
    commission_bps: Mapped[int] = mapped_column(Integer, nullable=False, default=1000)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")

    agency: Mapped[CastingAgency] = relationship(lazy="joined")
    talent_profile: Mapped[TalentProfile] = relationship(lazy="joined")


class AuditionRequest(EntityMixin, Base):
    __tablename__ = "audition_requests"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("AUD")
    )
    agency_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("casting_agencies.id", ondelete="CASCADE"), nullable=False
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"), nullable=False
    )
    requirement_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("project_requirements.id", ondelete="SET NULL")
    )
    requested_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    role_title: Mapped[str] = mapped_column(String(180), nullable=False)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    budget_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="requested")

    agency: Mapped[CastingAgency] = relationship(lazy="joined")
    project: Mapped[Project] = relationship(lazy="joined")
    requirement: Mapped[ProjectRequirement | None] = relationship(lazy="joined")
    requester: Mapped[User] = relationship(lazy="joined")
    candidates: Mapped[list[AuditionCandidate]] = relationship(
        back_populates="audition_request",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="AuditionCandidate.rank",
    )


class AuditionCandidate(EntityMixin, Base):
    __tablename__ = "audition_candidates"
    __table_args__ = (
        UniqueConstraint(
            "audition_request_id", "talent_profile_id", name="uq_audition_candidate"
        ),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("AUDC")
    )
    audition_request_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("audition_requests.id", ondelete="CASCADE"), nullable=False
    )
    talent_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("talent_profiles.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="submitted")
    rank: Mapped[int] = mapped_column(Integer, nullable=False, default=100)
    agency_note: Mapped[str | None] = mapped_column(Text)
    director_note: Mapped[str | None] = mapped_column(Text)
    score: Mapped[int | None] = mapped_column(Integer)

    audition_request: Mapped[AuditionRequest] = relationship(
        back_populates="candidates"
    )
    talent_profile: Mapped[TalentProfile] = relationship(lazy="joined")
    self_tapes: Mapped[list[SelfTape]] = relationship(
        back_populates="candidate", cascade="all, delete-orphan", lazy="selectin"
    )
    selection_notes: Mapped[list[SelectionNote]] = relationship(
        back_populates="candidate", cascade="all, delete-orphan", lazy="selectin"
    )


class SelfTape(EntityMixin, Base):
    __tablename__ = "self_tapes"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("TAPE")
    )
    audition_candidate_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("audition_candidates.id", ondelete="CASCADE"), nullable=False
    )
    file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    thumbnail_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    duration_seconds: Mapped[int | None] = mapped_column(Integer)
    transcript: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="submitted")
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    candidate: Mapped[AuditionCandidate] = relationship(back_populates="self_tapes")
    file: Mapped[FileAsset | None] = relationship(
        foreign_keys="SelfTape.file_id", lazy="joined"
    )
    thumbnail_file: Mapped[FileAsset | None] = relationship(
        foreign_keys="SelfTape.thumbnail_file_id", lazy="joined"
    )


class SelectionNote(EntityMixin, Base):
    __tablename__ = "selection_notes"

    audition_candidate_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("audition_candidates.id", ondelete="CASCADE"), nullable=False
    )
    author_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    note: Mapped[str] = mapped_column(Text, nullable=False)
    score: Mapped[int | None] = mapped_column(Integer)
    visibility: Mapped[str] = mapped_column(
        String(32), nullable=False, default="agency_and_director"
    )

    candidate: Mapped[AuditionCandidate] = relationship(
        back_populates="selection_notes"
    )
    author: Mapped[User] = relationship(lazy="joined")


class AgencyCommission(EntityMixin, Base):
    __tablename__ = "agency_commissions"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("COM")
    )
    agency_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("casting_agencies.id", ondelete="CASCADE"), nullable=False
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False
    )
    talent_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("talent_profiles.id", ondelete="CASCADE"), nullable=False
    )
    gross_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    commission_bps: Mapped[int] = mapped_column(Integer, nullable=False)
    commission_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")

    agency: Mapped[CastingAgency] = relationship(lazy="joined")
    booking: Mapped[Booking] = relationship(lazy="joined")
    talent_profile: Mapped[TalentProfile] = relationship(lazy="joined")


class BrandProfile(EntityMixin, Base):
    __tablename__ = "brand_profiles"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("BRD")
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    category: Mapped[str | None] = mapped_column(String(64))
    representative: Mapped[str | None] = mapped_column(String(120))
    billing_token: Mapped[str | None] = mapped_column(String(255))
    trust_status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="pending"
    )
    description: Mapped[str | None] = mapped_column(Text)
    logo_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )

    owner: Mapped[User] = relationship(lazy="joined")
    logo_file: Mapped[FileAsset | None] = relationship(lazy="joined")


class BrandOpportunity(EntityMixin, Base):
    __tablename__ = "brand_opportunities"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("BOP")
    )
    brand_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("brand_profiles.id", ondelete="CASCADE"), nullable=False
    )
    project_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("projects.id", ondelete="SET NULL")
    )
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    budget_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    usage_summary: Mapped[str | None] = mapped_column(Text)
    eligibility: Mapped[str | None] = mapped_column(Text)
    deliverables: Mapped[str | None] = mapped_column(Text)
    application_due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    cover_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )

    brand_profile: Mapped[BrandProfile] = relationship(lazy="joined")
    project: Mapped[Project | None] = relationship(lazy="joined")
    cover_file: Mapped[FileAsset | None] = relationship(lazy="joined")
    applications: Mapped[list[BrandApplication]] = relationship(
        back_populates="opportunity", cascade="all, delete-orphan", lazy="selectin"
    )


class BrandApplication(EntityMixin, Base):
    __tablename__ = "brand_applications"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("BAP")
    )
    opportunity_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("brand_opportunities.id", ondelete="CASCADE"), nullable=False
    )
    applicant_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    talent_profile_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("talent_profiles.id", ondelete="SET NULL")
    )
    proposal: Mapped[str | None] = mapped_column(Text)
    audience_metrics_json: Mapped[str | None] = mapped_column(Text)
    budget_ask_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="submitted")

    opportunity: Mapped[BrandOpportunity] = relationship(back_populates="applications")
    applicant: Mapped[User] = relationship(lazy="joined")
    talent_profile: Mapped[TalentProfile | None] = relationship(lazy="joined")
    terms: Mapped[list[BrandTerm]] = relationship(
        back_populates="application",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="BrandTerm.version",
    )


class BrandTerm(EntityMixin, Base):
    __tablename__ = "brand_terms"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("BTM")
    )
    application_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("brand_applications.id", ondelete="CASCADE"), nullable=False
    )
    scope: Mapped[str | None] = mapped_column(Text)
    exclusivity: Mapped[str | None] = mapped_column(String(255))
    approval_rights: Mapped[str | None] = mapped_column(String(255))
    payment_schedule_json: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)

    application: Mapped[BrandApplication] = relationship(back_populates="terms")


class CampaignDeliverable(EntityMixin, Base):
    __tablename__ = "campaign_deliverables"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("DEL")
    )
    opportunity_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("brand_opportunities.id", ondelete="CASCADE"), nullable=False
    )
    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("bookings.id", ondelete="SET NULL")
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    label: Mapped[str] = mapped_column(String(180), nullable=False)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    proof_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    opportunity: Mapped[BrandOpportunity] = relationship(lazy="joined")
    booking: Mapped[Booking | None] = relationship(lazy="joined")
    owner: Mapped[User] = relationship(lazy="joined")
    proof_file: Mapped[FileAsset | None] = relationship(lazy="joined")
    metrics: Mapped[list[CampaignMetric]] = relationship(
        back_populates="deliverable", cascade="all, delete-orphan", lazy="selectin"
    )


class CampaignMetric(EntityMixin, Base):
    __tablename__ = "campaign_metrics"

    deliverable_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("campaign_deliverables.id", ondelete="CASCADE"), nullable=False
    )
    captured_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    platform: Mapped[str] = mapped_column(String(64), nullable=False)
    impressions: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    reach: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    engagements: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    clicks: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    source: Mapped[str] = mapped_column(
        String(32), nullable=False, default="manual_verified"
    )
    raw_json: Mapped[str | None] = mapped_column(Text)

    deliverable: Mapped[CampaignDeliverable] = relationship(back_populates="metrics")


class DistributionPartnerProfile(EntityMixin, Base):
    __tablename__ = "distribution_partner_profiles"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("DSTP")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    channels: Mapped[str | None] = mapped_column(String(255))
    territories: Mapped[str | None] = mapped_column(String(255))
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")

    user: Mapped[User] = relationship(lazy="joined")


class DistributionProject(EntityMixin, Base):
    __tablename__ = "distribution_projects"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("DPR")
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"), nullable=False
    )
    partner_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("distribution_partner_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    release_window_start: Mapped[date | None] = mapped_column(Date)
    release_window_end: Mapped[date | None] = mapped_column(Date)
    territories: Mapped[str | None] = mapped_column(String(255))
    missing_items: Mapped[str | None] = mapped_column(String(255))
    status_note: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="onboarding"
    )

    project: Mapped[Project] = relationship(lazy="joined")
    partner_profile: Mapped[DistributionPartnerProfile] = relationship(lazy="joined")
    handover_items: Mapped[list[ReleaseHandoverItem]] = relationship(
        back_populates="distribution_project",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    release_windows: Mapped[list[ReleaseWindow]] = relationship(
        back_populates="distribution_project",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class DistributorContact(EntityMixin, Base):
    __tablename__ = "distributor_contacts"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("DCT")
    )
    partner_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("distribution_partner_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    channel: Mapped[str] = mapped_column(String(64), nullable=False)
    territory: Mapped[str | None] = mapped_column(String(120))
    contact_role: Mapped[str | None] = mapped_column(String(120))
    email_token: Mapped[str | None] = mapped_column(String(255))
    phone_token: Mapped[str | None] = mapped_column(String(255))
    prior_project: Mapped[str | None] = mapped_column(String(180))
    notes: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")

    partner_profile: Mapped[DistributionPartnerProfile] = relationship(lazy="joined")


class ReleaseHandoverItem(EntityMixin, Base):
    __tablename__ = "release_handover_items"

    distribution_project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("distribution_projects.id", ondelete="CASCADE"), nullable=False
    )
    label: Mapped[str] = mapped_column(String(180), nullable=False)
    detail: Mapped[str | None] = mapped_column(Text)
    mandatory: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="missing")
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    distribution_project: Mapped[DistributionProject] = relationship(
        back_populates="handover_items"
    )
    file: Mapped[FileAsset | None] = relationship(lazy="joined")


class ReleaseWindow(EntityMixin, Base):
    __tablename__ = "release_windows"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("RW")
    )
    distribution_project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("distribution_projects.id", ondelete="CASCADE"), nullable=False
    )
    channel: Mapped[str] = mapped_column(String(64), nullable=False)
    territory: Mapped[str] = mapped_column(String(120), nullable=False)
    starts_on: Mapped[date | None] = mapped_column(Date)
    ends_on: Mapped[date | None] = mapped_column(Date)
    exclusivity: Mapped[str] = mapped_column(
        String(32), nullable=False, default="non_exclusive"
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="planned")

    distribution_project: Mapped[DistributionProject] = relationship(
        back_populates="release_windows"
    )


class DistributionReport(EntityMixin, Base):
    __tablename__ = "distribution_reports"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("DRP")
    )
    distribution_project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("distribution_projects.id", ondelete="CASCADE"), nullable=False
    )
    partner_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("distribution_partner_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    territory: Mapped[str] = mapped_column(String(120), nullable=False)
    channel: Mapped[str] = mapped_column(String(64), nullable=False)
    period_start: Mapped[date] = mapped_column(Date, nullable=False)
    period_end: Mapped[date] = mapped_column(Date, nullable=False)
    audience_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    revenue_minor: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    source_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="submitted")

    distribution_project: Mapped[DistributionProject] = relationship(lazy="joined")
    partner_profile: Mapped[DistributionPartnerProfile] = relationship(lazy="joined")
    source_file: Mapped[FileAsset | None] = relationship(lazy="joined")
