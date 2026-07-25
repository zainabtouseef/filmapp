from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.files import FileAsset
from app.models.identity import User, make_public_id


class Country(EntityMixin, Base):
    __tablename__ = "countries"

    iso2: Mapped[str] = mapped_column(String(2), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    currency_code: Mapped[str] = mapped_column(String(3), nullable=False)
    phone_prefix: Mapped[str] = mapped_column(String(8), nullable=False)


class City(EntityMixin, Base):
    __tablename__ = "cities"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("CITY"),
    )
    country_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("countries.id", ondelete="RESTRICT"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    province: Mapped[str | None] = mapped_column(String(120))
    timezone: Mapped[str] = mapped_column(String(64), nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    country: Mapped[Country] = relationship(lazy="joined")


class UserProfile(EntityMixin, Base):
    __tablename__ = "user_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    bio: Mapped[str | None] = mapped_column(Text)
    city_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cities.id", ondelete="SET NULL")
    )
    avatar_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    cover_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    website_url: Mapped[str | None] = mapped_column(String(255))
    profile_visibility: Mapped[str] = mapped_column(
        String(32), nullable=False, default="private"
    )
    rating_average: Mapped[Decimal] = mapped_column(
        Numeric(3, 2), nullable=False, default=0
    )
    review_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    user: Mapped[User] = relationship(lazy="joined")
    city: Mapped[City | None] = relationship(lazy="joined")
    avatar_file: Mapped[FileAsset | None] = relationship(
        foreign_keys=[avatar_file_id], lazy="joined"
    )
    cover_file: Mapped[FileAsset | None] = relationship(
        foreign_keys=[cover_file_id], lazy="joined"
    )


class TalentProfile(EntityMixin, Base):
    __tablename__ = "talent_profiles"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("TAL"),
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    screen_name: Mapped[str] = mapped_column(String(120), nullable=False)
    age_range: Mapped[str | None] = mapped_column(String(32))
    gender_identity: Mapped[str | None] = mapped_column(String(64))
    height_cm: Mapped[int | None] = mapped_column(Integer)
    union_note: Mapped[str | None] = mapped_column(String(255))
    experience_years: Mapped[int | None] = mapped_column(Integer)
    availability_status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="available"
    )
    day_rate_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    resume_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )

    user: Mapped[User] = relationship(lazy="joined")
    languages: Mapped[list[TalentLanguage]] = relationship(
        back_populates="talent_profile",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    resume_file: Mapped[FileAsset | None] = relationship(
        foreign_keys=[resume_file_id], lazy="joined"
    )


class TalentLanguage(EntityMixin, Base):
    __tablename__ = "talent_languages"
    __table_args__ = (
        UniqueConstraint("talent_profile_id", "language", name="uq_talent_language"),
    )

    talent_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("talent_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    language: Mapped[str] = mapped_column(String(64), nullable=False)
    proficiency: Mapped[str] = mapped_column(String(32), nullable=False)

    talent_profile: Mapped[TalentProfile] = relationship(back_populates="languages")


class MarketplaceListing(EntityMixin, Base):
    __tablename__ = "marketplace_listings"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("LST"),
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    listing_type: Mapped[str] = mapped_column(String(64), nullable=False)
    profile_entity_id: Mapped[str] = mapped_column(String(40), nullable=False)
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    city_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cities.id", ondelete="SET NULL")
    )
    price_from_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    verification_status: Mapped[str] = mapped_column(String(32), nullable=False)
    moderation_status: Mapped[str] = mapped_column(String(32), nullable=False)
    visibility: Mapped[str] = mapped_column(String(32), nullable=False)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    owner: Mapped[User] = relationship(lazy="joined")
    city: Mapped[City | None] = relationship(lazy="joined")
    media: Mapped[list[ListingMedia]] = relationship(
        back_populates="listing",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ListingMedia.sort_order",
    )


class PortfolioItem(EntityMixin, Base):
    __tablename__ = "portfolio_items"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("PORT"),
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    profile_type: Mapped[str] = mapped_column(String(64), nullable=False)
    profile_id: Mapped[str] = mapped_column(String(40), nullable=False)
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    thumbnail_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    duration_seconds: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    is_cover: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=100)
    moderation_status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="pending"
    )

    owner: Mapped[User] = relationship(lazy="joined")
    file: Mapped[FileAsset | None] = relationship(
        foreign_keys="PortfolioItem.file_id",
        lazy="joined",
    )
    thumbnail_file: Mapped[FileAsset | None] = relationship(
        foreign_keys="PortfolioItem.thumbnail_file_id",
        lazy="joined",
    )


class ListingMedia(EntityMixin, Base):
    __tablename__ = "listing_media"
    __table_args__ = (
        UniqueConstraint("listing_id", "file_id", name="uq_listing_media_file"),
    )

    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("marketplace_listings.id", ondelete="CASCADE"),
        nullable=False,
    )
    file_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("files.id", ondelete="CASCADE"),
        nullable=False,
    )
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=100)
    is_cover: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    caption: Mapped[str | None] = mapped_column(String(255))

    listing: Mapped[MarketplaceListing] = relationship(back_populates="media")
    file: Mapped[FileAsset] = relationship(lazy="joined")


class SavedSearch(EntityMixin, Base):
    __tablename__ = "saved_searches"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("SSRCH"),
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    listing_type: Mapped[str | None] = mapped_column(String(64))
    city_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cities.id", ondelete="SET NULL")
    )
    query_text: Mapped[str | None] = mapped_column(String(255))
    filters_json: Mapped[str | None] = mapped_column(Text)
    notify_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    owner: Mapped[User] = relationship(lazy="joined")
    city: Mapped[City | None] = relationship(lazy="joined")


class Shortlist(EntityMixin, Base):
    __tablename__ = "shortlists"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("SHL"),
    )
    project_id: Mapped[str | None] = mapped_column(String(40))
    requirement_id: Mapped[str | None] = mapped_column(String(40))
    created_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(160), nullable=False)

    creator: Mapped[User] = relationship(lazy="joined")
    items: Mapped[list[ShortlistItem]] = relationship(
        back_populates="shortlist",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ShortlistItem.rank",
    )


class ShortlistItem(EntityMixin, Base):
    __tablename__ = "shortlist_items"
    __table_args__ = (
        UniqueConstraint("shortlist_id", "listing_id", name="uq_shortlist_listing"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("SHLI"),
    )
    shortlist_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("shortlists.id", ondelete="CASCADE"),
        nullable=False,
    )
    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("marketplace_listings.id", ondelete="CASCADE"),
        nullable=False,
    )
    candidate_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    rank: Mapped[int] = mapped_column(Integer, nullable=False, default=100)
    notes: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")

    shortlist: Mapped[Shortlist] = relationship(back_populates="items")
    listing: Mapped[MarketplaceListing] = relationship(lazy="joined")
    candidate: Mapped[User | None] = relationship(lazy="joined")


class ModelProfile(EntityMixin, Base):
    __tablename__ = "model_profiles"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("MOD")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    talent_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("talent_profiles.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    brand_safety_notes: Mapped[str | None] = mapped_column(Text)
    public_visibility: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )

    user: Mapped[User] = relationship(lazy="joined")
    talent_profile: Mapped[TalentProfile] = relationship(lazy="joined")
    campaign_categories: Mapped[list[ModelCampaignCategory]] = relationship(
        back_populates="model_profile", cascade="all, delete-orphan", lazy="selectin"
    )
    usage_rights: Mapped[list[ModelUsageRight]] = relationship(
        back_populates="model_profile", cascade="all, delete-orphan", lazy="selectin"
    )
    usage_rates: Mapped[list[ModelUsageRate]] = relationship(
        back_populates="model_profile", cascade="all, delete-orphan", lazy="selectin"
    )
    restricted_categories: Mapped[list[ModelRestrictedCategory]] = relationship(
        back_populates="model_profile", cascade="all, delete-orphan", lazy="selectin"
    )


class ModelCampaignCategory(EntityMixin, Base):
    __tablename__ = "model_campaign_categories"
    __table_args__ = (
        UniqueConstraint(
            "model_profile_id", "category", name="uq_model_campaign_category"
        ),
    )

    model_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("model_profiles.id", ondelete="CASCADE"), nullable=False
    )
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    selected: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    public_visible: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    model_profile: Mapped[ModelProfile] = relationship(
        back_populates="campaign_categories"
    )


class ModelUsageRight(EntityMixin, Base):
    __tablename__ = "model_usage_rights"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("MUR")
    )
    model_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("model_profiles.id", ondelete="CASCADE"), nullable=False
    )
    platform: Mapped[str] = mapped_column(String(64), nullable=False)
    territory: Mapped[str] = mapped_column(String(120), nullable=False)
    duration_months: Mapped[int | None] = mapped_column(Integer)
    exclusive: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")

    model_profile: Mapped[ModelProfile] = relationship(back_populates="usage_rights")


class ModelUsageRate(EntityMixin, Base):
    __tablename__ = "model_usage_rates"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("MRT")
    )
    model_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("model_profiles.id", ondelete="CASCADE"), nullable=False
    )
    label: Mapped[str] = mapped_column(String(120), nullable=False)
    scope: Mapped[str | None] = mapped_column(String(180))
    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    requires_review: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    negotiable: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    model_profile: Mapped[ModelProfile] = relationship(back_populates="usage_rates")


class ModelRestrictedCategory(EntityMixin, Base):
    __tablename__ = "model_restricted_categories"
    __table_args__ = (
        UniqueConstraint(
            "model_profile_id", "category", name="uq_model_restricted_category"
        ),
    )

    model_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("model_profiles.id", ondelete="CASCADE"), nullable=False
    )
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    blocked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    reason: Mapped[str | None] = mapped_column(Text)

    model_profile: Mapped[ModelProfile] = relationship(
        back_populates="restricted_categories"
    )
