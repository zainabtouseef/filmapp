from __future__ import annotations

import uuid
from datetime import date, datetime, time
from typing import Any

from sqlalchemy import (
    JSON,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    Time,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.identity import make_public_id


class CineProduction(EntityMixin, Base):
    __tablename__ = "cine_productions"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CPR")
    )
    project_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("projects.id", ondelete="SET NULL"), unique=True
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="setup")
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    production_start_date: Mapped[date | None] = mapped_column(Date)
    maximum_shoot_days: Mapped[int] = mapped_column(Integer, nullable=False, default=30)
    working_hours_limit: Mapped[int] = mapped_column(
        Integer, nullable=False, default=12
    )
    budget_ceiling_minor: Mapped[int | None] = mapped_column(Integer)
    schedule_locked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    settings_json: Mapped[dict[str, Any]] = mapped_column(
        JSON, nullable=False, default=dict
    )

    scripts: Mapped[list[CineScriptVersion]] = relationship(
        back_populates="production", cascade="all, delete-orphan", lazy="selectin"
    )
    scenes: Mapped[list[CineScene]] = relationship(
        back_populates="production", cascade="all, delete-orphan", lazy="selectin"
    )
    characters: Mapped[list[CineCharacter]] = relationship(
        back_populates="production", cascade="all, delete-orphan", lazy="selectin"
    )
    elements: Mapped[list[CineElement]] = relationship(
        back_populates="production", cascade="all, delete-orphan", lazy="selectin"
    )
    locations: Mapped[list[CineLocation]] = relationship(
        back_populates="production", cascade="all, delete-orphan", lazy="selectin"
    )
    shoot_days: Mapped[list[CineShootDay]] = relationship(
        back_populates="production", cascade="all, delete-orphan", lazy="selectin"
    )


class CineProductionRole(EntityMixin, Base):
    __tablename__ = "cine_production_roles"
    __table_args__ = (
        UniqueConstraint("production_id", "user_id", name="uq_cine_role_user"),
    )

    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    role_code: Mapped[str] = mapped_column(String(32), nullable=False)
    permissions_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="active")


class CineScriptVersion(EntityMixin, Base):
    __tablename__ = "cine_script_versions"
    __table_args__ = (
        UniqueConstraint(
            "production_id", "version_number", name="uq_cine_script_version"
        ),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CSV")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    file_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("files.id", ondelete="RESTRICT"), nullable=False
    )
    uploaded_by_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )
    version_number: Mapped[int] = mapped_column(Integer, nullable=False)
    label: Mapped[str] = mapped_column(String(120), nullable=False)
    screenplay_title: Mapped[str | None] = mapped_column(String(180))
    author: Mapped[str | None] = mapped_column(String(180))
    revision: Mapped[str | None] = mapped_column(String(120))
    total_pages: Mapped[int | None] = mapped_column(Integer)
    analysis_status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="uploaded"
    )
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    approved_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    metadata_json: Mapped[dict[str, Any]] = mapped_column(
        JSON, nullable=False, default=dict
    )

    production: Mapped[CineProduction] = relationship(back_populates="scripts")


class CineAIJob(EntityMixin, Base):
    __tablename__ = "cine_ai_jobs"
    __table_args__ = (Index("ix_cine_ai_job_status", "status", "updated_at"),)

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CAI")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    script_version_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_script_versions.id", ondelete="CASCADE"), nullable=False
    )
    requested_by_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="queued")
    current_stage: Mapped[str] = mapped_column(
        String(64), nullable=False, default="file_uploaded"
    )
    progress_percent: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    completed_stages_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    stage_results_json: Mapped[dict[str, Any]] = mapped_column(
        JSON, nullable=False, default=dict
    )
    attempt_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    error_code: Mapped[str | None] = mapped_column(String(80))
    error_message: Mapped[str | None] = mapped_column(String(500))
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class CineScene(EntityMixin, Base):
    __tablename__ = "cine_scenes"
    __table_args__ = (
        UniqueConstraint(
            "script_version_id", "scene_number", name="uq_cine_scene_number"
        ),
        Index("ix_cine_scene_production_order", "production_id", "sort_order"),
        Index("ix_cine_scene_location", "production_id", "location_name"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CSC")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    script_version_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_script_versions.id", ondelete="CASCADE"), nullable=False
    )
    scene_number: Mapped[str] = mapped_column(String(24), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False)
    slugline: Mapped[str] = mapped_column(String(300), nullable=False)
    int_ext: Mapped[str] = mapped_column(String(16), nullable=False, default="UNKNOWN")
    location_name: Mapped[str] = mapped_column(
        String(180), nullable=False, default="Unknown"
    )
    time_of_day: Mapped[str] = mapped_column(
        String(40), nullable=False, default="Unspecified"
    )
    story_day: Mapped[str | None] = mapped_column(String(64))
    page_length_eighths: Mapped[int] = mapped_column(Integer, nullable=False, default=8)
    estimated_screen_seconds: Mapped[int] = mapped_column(
        Integer, nullable=False, default=60
    )
    summary: Mapped[str] = mapped_column(Text, nullable=False, default="")
    cast_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    extras_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    props_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    wardrobe_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    makeup_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    vehicles_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    weapons_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    animals_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    stunts_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    vfx_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    sfx_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    equipment_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    sound_requirements: Mapped[str | None] = mapped_column(Text)
    production_notes: Mapped[str | None] = mapped_column(Text)
    safety_notes: Mapped[str | None] = mapped_column(Text)
    continuity_notes: Mapped[str | None] = mapped_column(Text)
    complexity: Mapped[str] = mapped_column(
        String(16), nullable=False, default="medium"
    )
    ai_confidence: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    review_status: Mapped[str] = mapped_column(
        String(24), nullable=False, default="ai_draft"
    )

    production: Mapped[CineProduction] = relationship(back_populates="scenes")


class CineCharacter(EntityMixin, Base):
    __tablename__ = "cine_characters"
    __table_args__ = (
        UniqueConstraint(
            "script_version_id", "normalized_name", name="uq_cine_character_name"
        ),
        Index("ix_cine_character_production", "production_id", "classification"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CCH")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    script_version_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_script_versions.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    normalized_name: Mapped[str] = mapped_column(String(160), nullable=False)
    classification: Mapped[str] = mapped_column(
        String(24), nullable=False, default="minor"
    )
    description: Mapped[str | None] = mapped_column(Text)
    playing_age: Mapped[str | None] = mapped_column(String(40))
    languages_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    skills_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    scene_numbers_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    dialogue_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    page_count_eighths: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    estimated_screen_seconds: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0
    )
    first_appearance: Mapped[str | None] = mapped_column(String(24))
    last_appearance: Mapped[str | None] = mapped_column(String(24))
    story_days_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    estimated_shoot_days: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0
    )
    ai_confidence: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    review_status: Mapped[str] = mapped_column(
        String(24), nullable=False, default="ai_draft"
    )

    production: Mapped[CineProduction] = relationship(back_populates="characters")


class CineActor(EntityMixin, Base):
    __tablename__ = "cine_actors"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CAC")
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    photo_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    playing_age_min: Mapped[int | None] = mapped_column(Integer)
    playing_age_max: Mapped[int | None] = mapped_column(Integer)
    gender: Mapped[str | None] = mapped_column(String(64))
    languages_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    skills_json: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    city: Mapped[str | None] = mapped_column(String(120))
    agency: Mapped[str | None] = mapped_column(String(180))
    manager: Mapped[str | None] = mapped_column(String(180))
    phone: Mapped[str | None] = mapped_column(String(64))
    email: Mapped[str | None] = mapped_column(String(320))
    daily_rate_minor: Mapped[int | None] = mapped_column(Integer)
    project_rate_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    notes: Mapped[str | None] = mapped_column(Text)


class CineCastAssignment(EntityMixin, Base):
    __tablename__ = "cine_cast_assignments"
    __table_args__ = (
        UniqueConstraint(
            "production_id", "character_id", "actor_id", name="uq_cine_cast_option"
        ),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CAS")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    character_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_characters.id", ondelete="CASCADE"), nullable=False
    )
    actor_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_actors.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="suggested")
    fit_score: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    fit_breakdown_json: Mapped[dict[str, int]] = mapped_column(
        JSON, nullable=False, default=dict
    )
    preference_notes: Mapped[str | None] = mapped_column(Text)


class CineActorAvailability(EntityMixin, Base):
    __tablename__ = "cine_actor_availability"
    __table_args__ = (
        Index("ix_cine_actor_availability_dates", "actor_id", "starts_on", "ends_on"),
    )

    actor_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_actors.id", ondelete="CASCADE"), nullable=False
    )
    production_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE")
    )
    starts_on: Mapped[date] = mapped_column(Date, nullable=False)
    ends_on: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(String(24), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)


class CineLocation(EntityMixin, Base):
    __tablename__ = "cine_locations"
    __table_args__ = (
        UniqueConstraint(
            "script_version_id",
            "screenplay_name",
            "option_name",
            name="uq_cine_location_option",
        ),
        Index("ix_cine_location_production_status", "production_id", "status"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CLO")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    script_version_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_script_versions.id", ondelete="CASCADE"), nullable=False
    )
    screenplay_name: Mapped[str] = mapped_column(String(180), nullable=False)
    option_name: Mapped[str | None] = mapped_column(String(180))
    address: Mapped[str | None] = mapped_column(String(500))
    photo_file_ids_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    contact_name: Mapped[str | None] = mapped_column(String(180))
    contact_phone: Mapped[str | None] = mapped_column(String(64))
    rental_rate_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    availability_json: Mapped[list[dict[str, Any]]] = mapped_column(
        JSON, nullable=False, default=list
    )
    parking: Mapped[str | None] = mapped_column(Text)
    electricity: Mapped[str | None] = mapped_column(Text)
    bathrooms: Mapped[str | None] = mapped_column(Text)
    holding_area: Mapped[str | None] = mapped_column(Text)
    noise_restrictions: Mapped[str | None] = mapped_column(Text)
    permit_requirements: Mapped[str | None] = mapped_column(Text)
    notes: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="extracted")
    ai_confidence: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    production: Mapped[CineProduction] = relationship(back_populates="locations")


class CineElement(EntityMixin, Base):
    __tablename__ = "cine_elements"
    __table_args__ = (
        UniqueConstraint(
            "script_version_id", "category", "normalized_name", name="uq_cine_element"
        ),
        Index("ix_cine_element_production_category", "production_id", "category"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CEL")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    script_version_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_script_versions.id", ondelete="CASCADE"), nullable=False
    )
    category: Mapped[str] = mapped_column(String(32), nullable=False)
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    normalized_name: Mapped[str] = mapped_column(String(180), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    scene_numbers_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    cost_rate_minor: Mapped[int | None] = mapped_column(Integer)
    rate_basis: Mapped[str] = mapped_column(String(24), nullable=False, default="flat")
    availability_json: Mapped[list[dict[str, Any]]] = mapped_column(
        JSON, nullable=False, default=list
    )
    owner_vendor: Mapped[str | None] = mapped_column(String(180))
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="required")
    continuity_notes: Mapped[str | None] = mapped_column(Text)
    photo_file_ids_json: Mapped[list[str]] = mapped_column(
        JSON, nullable=False, default=list
    )
    notes: Mapped[str | None] = mapped_column(Text)
    ai_confidence: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    review_status: Mapped[str] = mapped_column(
        String(24), nullable=False, default="ai_draft"
    )

    production: Mapped[CineProduction] = relationship(back_populates="elements")


class CineCrewMember(EntityMixin, Base):
    __tablename__ = "cine_crew_members"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CCR")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    department: Mapped[str] = mapped_column(String(120), nullable=False)
    job_title: Mapped[str] = mapped_column(String(120), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(64))
    email: Mapped[str | None] = mapped_column(String(320))
    daily_rate_minor: Mapped[int | None] = mapped_column(Integer)
    availability_json: Mapped[list[dict[str, Any]]] = mapped_column(
        JSON, nullable=False, default=list
    )
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="proposed")


class CineShootDay(EntityMixin, Base):
    __tablename__ = "cine_shoot_days"
    __table_args__ = (
        UniqueConstraint(
            "production_id", "shoot_day_number", name="uq_cine_shoot_day_number"
        ),
        UniqueConstraint("production_id", "shoot_date", name="uq_cine_shoot_date"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CSD")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    shoot_day_number: Mapped[int] = mapped_column(Integer, nullable=False)
    shoot_date: Mapped[date] = mapped_column(Date, nullable=False)
    crew_call: Mapped[time] = mapped_column(
        Time, nullable=False, default=lambda: time(6, 0)
    )
    expected_wrap: Mapped[time] = mapped_column(
        Time, nullable=False, default=lambda: time(18, 0)
    )
    location_name: Mapped[str | None] = mapped_column(String(180))
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="draft")
    locked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    notes: Mapped[str | None] = mapped_column(Text)

    production: Mapped[CineProduction] = relationship(back_populates="shoot_days")
    events: Mapped[list[CineScheduleEvent]] = relationship(
        back_populates="shoot_day", cascade="all, delete-orphan", lazy="selectin"
    )


class CineScheduleEvent(EntityMixin, Base):
    __tablename__ = "cine_schedule_events"
    __table_args__ = (
        Index("ix_cine_schedule_time", "shoot_day_id", "starts_at", "ends_at"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CSE")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    shoot_day_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_shoot_days.id", ondelete="CASCADE"), nullable=False
    )
    scene_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cine_scenes.id", ondelete="SET NULL")
    )
    event_type: Mapped[str] = mapped_column(String(32), nullable=False, default="scene")
    title: Mapped[str] = mapped_column(String(240), nullable=False)
    starts_at: Mapped[time] = mapped_column(Time, nullable=False)
    ends_at: Mapped[time] = mapped_column(Time, nullable=False)
    setup_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    rehearsal_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    lighting_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    camera_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    makeup_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    wardrobe_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    shooting_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    reset_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    travel_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    notes: Mapped[str | None] = mapped_column(Text)

    shoot_day: Mapped[CineShootDay] = relationship(back_populates="events")


class CineBudgetLine(EntityMixin, Base):
    __tablename__ = "cine_budget_lines"
    __table_args__ = (Index("ix_cine_budget_category", "production_id", "category"),)

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CBL")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    description: Mapped[str] = mapped_column(String(240), nullable=False)
    source_type: Mapped[str | None] = mapped_column(String(40))
    source_public_id: Mapped[str | None] = mapped_column(String(40))
    estimated_minor: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    quoted_minor: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    approved_minor: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    committed_minor: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    paid_minor: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="estimated")
    notes: Mapped[str | None] = mapped_column(Text)


class CineCallSheet(EntityMixin, Base):
    __tablename__ = "cine_call_sheets"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CCS")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    shoot_day_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_shoot_days.id", ondelete="CASCADE"), nullable=False
    )
    generated_by_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )
    revision_number: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    payload_json: Mapped[dict[str, Any]] = mapped_column(
        JSON, nullable=False, default=dict
    )
    pdf_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="draft")


class CineAuditLog(EntityMixin, Base):
    __tablename__ = "cine_audit_logs"
    __table_args__ = (
        Index("ix_cine_audit_production_time", "production_id", "created_at"),
    )

    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    actor_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    action: Mapped[str] = mapped_column(String(80), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(64), nullable=False)
    entity_public_id: Mapped[str | None] = mapped_column(String(40))
    old_value_json: Mapped[dict[str, Any] | list[Any] | None] = mapped_column(JSON)
    new_value_json: Mapped[dict[str, Any] | list[Any] | None] = mapped_column(JSON)


class CineConflict(EntityMixin, Base):
    __tablename__ = "cine_conflicts"
    __table_args__ = (
        Index("ix_cine_conflict_open", "production_id", "resolved_at", "severity"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("CCF")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), nullable=False
    )
    shoot_day_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cine_shoot_days.id", ondelete="CASCADE")
    )
    schedule_event_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cine_schedule_events.id", ondelete="CASCADE")
    )
    conflict_type: Mapped[str] = mapped_column(String(64), nullable=False)
    severity: Mapped[str] = mapped_column(String(16), nullable=False)
    message: Mapped[str] = mapped_column(String(500), nullable=False)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(
        JSON, nullable=False, default=dict
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    resolved_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
