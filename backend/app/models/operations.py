from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
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
from app.models.marketplace import City
from app.models.projects import Project


class LocationProperty(EntityMixin, Base):
    __tablename__ = "location_properties"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("LOC")
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    property_type: Mapped[str] = mapped_column(String(64), nullable=False)
    city_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cities.id", ondelete="SET NULL")
    )
    area_name: Mapped[str | None] = mapped_column(String(120))
    public_address: Mapped[str | None] = mapped_column(String(255))
    private_address_token: Mapped[str | None] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text)
    capacity: Mapped[int | None] = mapped_column(Integer)
    parking_spaces: Mapped[int | None] = mapped_column(Integer)
    power_backup: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    accessible: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    rating_average: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")

    owner: Mapped[User] = relationship(lazy="joined")
    city: Mapped[City | None] = relationship(lazy="joined")
    spaces: Mapped[list[LocationSpace]] = relationship(
        back_populates="property",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    pricing: Mapped[list[LocationPricing]] = relationship(
        back_populates="property",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    rules: Mapped[list[LocationRule]] = relationship(
        back_populates="property",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class LocationSpace(EntityMixin, Base):
    __tablename__ = "location_spaces"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("LSP")
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("location_properties.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    space_type: Mapped[str] = mapped_column(String(64), nullable=False)
    capacity: Mapped[int | None] = mapped_column(Integer)
    area_sqft: Mapped[int | None] = mapped_column(Integer)
    description: Mapped[str | None] = mapped_column(Text)

    property: Mapped[LocationProperty] = relationship(back_populates="spaces")


class LocationPricing(EntityMixin, Base):
    __tablename__ = "location_pricing"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("LPR")
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("location_properties.id", ondelete="CASCADE"), nullable=False
    )
    label: Mapped[str] = mapped_column(String(120), nullable=False)
    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    unit: Mapped[str] = mapped_column(String(32), nullable=False, default="day")
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    conditions: Mapped[str | None] = mapped_column(Text)

    property: Mapped[LocationProperty] = relationship(back_populates="pricing")


class LocationRule(EntityMixin, Base):
    __tablename__ = "location_rules"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("LRU")
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("location_properties.id", ondelete="CASCADE"), nullable=False
    )
    rule_type: Mapped[str] = mapped_column(String(64), nullable=False)
    label: Mapped[str] = mapped_column(String(120), nullable=False)
    note: Mapped[str | None] = mapped_column(Text)
    allowed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    property: Mapped[LocationProperty] = relationship(back_populates="rules")


class LocationInspection(EntityMixin, Base):
    __tablename__ = "location_inspections"
    __table_args__ = (
        UniqueConstraint(
            "booking_id", "inspection_type", name="uq_location_booking_inspection"
        ),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("LIN")
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("location_properties.id", ondelete="CASCADE"), nullable=False
    )
    inspection_type: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="in_progress"
    )
    confirmed_by_owner_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    confirmed_by_renter_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    meter_reading: Mapped[str | None] = mapped_column(String(80))
    notes: Mapped[str | None] = mapped_column(Text)

    booking: Mapped[Booking] = relationship(lazy="joined")
    property: Mapped[LocationProperty] = relationship(lazy="joined")
    items: Mapped[list[LocationInspectionItem]] = relationship(
        back_populates="inspection",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class LocationInspectionItem(EntityMixin, Base):
    __tablename__ = "location_inspection_items"

    inspection_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("location_inspections.id", ondelete="CASCADE"), nullable=False
    )
    space_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("location_spaces.id", ondelete="SET NULL")
    )
    area_label: Mapped[str] = mapped_column(String(120), nullable=False)
    before_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    after_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    note: Mapped[str | None] = mapped_column(Text)
    stage: Mapped[str] = mapped_column(String(32), nullable=False, default="captured")
    issue_severity: Mapped[str] = mapped_column(
        String(32), nullable=False, default="none"
    )

    inspection: Mapped[LocationInspection] = relationship(back_populates="items")
    before_file: Mapped[FileAsset | None] = relationship(
        foreign_keys=[before_file_id], lazy="joined"
    )
    after_file: Mapped[FileAsset | None] = relationship(
        foreign_keys=[after_file_id], lazy="joined"
    )


class DamageClaim(EntityMixin, Base):
    __tablename__ = "damage_claims"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("DCL")
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False
    )
    claimant_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    respondent_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    inspection_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("location_inspections.id", ondelete="SET NULL")
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)
    claimed_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="submitted")
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    booking: Mapped[Booking] = relationship(lazy="joined")
    claimant: Mapped[User] = relationship(
        foreign_keys=[claimant_user_id], lazy="joined"
    )
    respondent: Mapped[User] = relationship(
        foreign_keys=[respondent_user_id], lazy="joined"
    )
    inspection: Mapped[LocationInspection | None] = relationship(lazy="joined")
    evidence: Mapped[list[DamageClaimEvidence]] = relationship(
        back_populates="claim", cascade="all, delete-orphan", lazy="selectin"
    )


class DamageClaimEvidence(EntityMixin, Base):
    __tablename__ = "damage_claim_evidence"

    claim_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("damage_claims.id", ondelete="CASCADE"), nullable=False
    )
    file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    evidence_type: Mapped[str] = mapped_column(String(64), nullable=False)
    caption: Mapped[str | None] = mapped_column(String(255))
    captured_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    claim: Mapped[DamageClaim] = relationship(back_populates="evidence")
    file: Mapped[FileAsset | None] = relationship(lazy="joined")


class EquipmentProviderProfile(EntityMixin, Base):
    __tablename__ = "equipment_provider_profiles"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("EPP")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    provider_type: Mapped[str] = mapped_column(
        String(64), nullable=False, default="rental_house"
    )
    city_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cities.id", ondelete="SET NULL")
    )
    coverage: Mapped[str | None] = mapped_column(String(255))
    service_categories: Mapped[str | None] = mapped_column(String(255))
    bio: Mapped[str | None] = mapped_column(Text)
    rating_average: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    verification_status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="pending"
    )

    user: Mapped[User] = relationship(lazy="joined")
    city: Mapped[City | None] = relationship(lazy="joined")


class EquipmentItem(EntityMixin, Base):
    __tablename__ = "equipment_items"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("EQ")
    )
    provider_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment_provider_profiles.id", ondelete="CASCADE"), nullable=False
    )
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    brand: Mapped[str | None] = mapped_column(String(120))
    model_name: Mapped[str] = mapped_column(String(120), nullable=False)
    serial_token: Mapped[str | None] = mapped_column(String(255))
    condition: Mapped[str] = mapped_column(String(64), nullable=False, default="good")
    day_rate_minor: Mapped[int | None] = mapped_column(Integer)
    deposit_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    city_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cities.id", ondelete="SET NULL")
    )
    cover_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="available")

    provider_profile: Mapped[EquipmentProviderProfile] = relationship(lazy="joined")


class EquipmentPackage(EntityMixin, Base):
    __tablename__ = "equipment_packages"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("EPK")
    )
    provider_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment_provider_profiles.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    operator_included: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    price_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    terms: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")

    package_items: Mapped[list[EquipmentPackageItem]] = relationship(
        back_populates="package",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class EquipmentPackageItem(EntityMixin, Base):
    __tablename__ = "equipment_package_items"
    __table_args__ = (
        UniqueConstraint(
            "package_id", "equipment_item_id", name="uq_equipment_package_item"
        ),
    )

    package_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment_packages.id", ondelete="CASCADE"), nullable=False
    )
    equipment_item_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment_items.id", ondelete="CASCADE"), nullable=False
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    required: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    package: Mapped[EquipmentPackage] = relationship(back_populates="package_items")
    equipment_item: Mapped[EquipmentItem] = relationship(lazy="joined")


class EquipmentTerm(EntityMixin, Base):
    __tablename__ = "equipment_terms"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("ETM")
    )
    provider_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment_provider_profiles.id", ondelete="CASCADE"), nullable=False
    )
    equipment_item_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("equipment_items.id", ondelete="CASCADE")
    )
    label: Mapped[str] = mapped_column(String(120), nullable=False)
    note: Mapped[str | None] = mapped_column(Text)
    amount_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    term_type: Mapped[str] = mapped_column(String(64), nullable=False)

    equipment_item: Mapped[EquipmentItem | None] = relationship(lazy="joined")


class EquipmentInspection(EntityMixin, Base):
    __tablename__ = "equipment_inspections"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("EIN")
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False
    )
    provider_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment_provider_profiles.id", ondelete="CASCADE"), nullable=False
    )
    inspection_type: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="in_progress"
    )
    handover_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    return_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    signed_by_provider: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    signed_by_renter: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )

    booking: Mapped[Booking] = relationship(lazy="joined")
    provider_profile: Mapped[EquipmentProviderProfile] = relationship(lazy="joined")
    items: Mapped[list[EquipmentInspectionItem]] = relationship(
        back_populates="inspection",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class EquipmentInspectionItem(EntityMixin, Base):
    __tablename__ = "equipment_inspection_items"

    inspection_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment_inspections.id", ondelete="CASCADE"), nullable=False
    )
    equipment_item_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment_items.id", ondelete="CASCADE"), nullable=False
    )
    before_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    after_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    accessories_json: Mapped[str | None] = mapped_column(Text)
    stage: Mapped[str] = mapped_column(String(32), nullable=False, default="captured")
    note: Mapped[str | None] = mapped_column(Text)

    inspection: Mapped[EquipmentInspection] = relationship(back_populates="items")
    equipment_item: Mapped[EquipmentItem] = relationship(lazy="joined")
    before_file: Mapped[FileAsset | None] = relationship(
        foreign_keys=[before_file_id], lazy="joined"
    )
    after_file: Mapped[FileAsset | None] = relationship(
        foreign_keys=[after_file_id], lazy="joined"
    )


class SafetyCheck(EntityMixin, Base):
    __tablename__ = "safety_checks"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("SFC")
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"), nullable=False
    )
    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE")
    )
    location_property_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("location_properties.id", ondelete="SET NULL")
    )
    responsible_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    risk_level: Mapped[str] = mapped_column(
        String(32), nullable=False, default="medium"
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="in_review")

    project: Mapped[Project] = relationship(lazy="joined")
    responsible_user: Mapped[User] = relationship(lazy="joined")
    items: Mapped[list[SafetyCheckItem]] = relationship(
        back_populates="safety_check", cascade="all, delete-orphan", lazy="selectin"
    )


class SafetyCheckItem(EntityMixin, Base):
    __tablename__ = "safety_check_items"

    safety_check_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("safety_checks.id", ondelete="CASCADE"), nullable=False
    )
    label: Mapped[str] = mapped_column(String(180), nullable=False)
    detail: Mapped[str | None] = mapped_column(Text)
    mandatory: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )

    safety_check: Mapped[SafetyCheck] = relationship(back_populates="items")
    completed_user: Mapped[User | None] = relationship(lazy="joined")


class Incident(EntityMixin, Base):
    __tablename__ = "incidents"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("INC")
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"), nullable=False
    )
    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("bookings.id", ondelete="SET NULL")
    )
    reported_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    severity: Mapped[str] = mapped_column(String(32), nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    parties: Mapped[str | None] = mapped_column(String(255))
    description: Mapped[str] = mapped_column(Text, nullable=False)
    corrective_action: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")

    project: Mapped[Project] = relationship(lazy="joined")
    reporter: Mapped[User] = relationship(lazy="joined")


class SafetyCheckIn(EntityMixin, Base):
    __tablename__ = "safety_check_ins"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("SCI")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False
    )
    scheduled_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    checked_in_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    latitude_token: Mapped[str | None] = mapped_column(String(255))
    longitude_token: Mapped[str | None] = mapped_column(String(255))
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="scheduled")
    escalated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped[User] = relationship(lazy="joined")
    booking: Mapped[Booking] = relationship(lazy="joined")
