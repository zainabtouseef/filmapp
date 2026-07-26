from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.bookings import Conversation
from app.models.files import FileAsset
from app.models.identity import User, make_public_id
from app.models.marketplace import TalentProfile
from app.models.projects import ProjectRequirement


class CastingRoleBrief(EntityMixin, Base):
    __tablename__ = "casting_role_briefs"
    __table_args__ = (Index("ix_casting_role_briefs_due", "application_due_at"),)

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("ROLE"),
    )
    requirement_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("project_requirements.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    role_type: Mapped[str | None] = mapped_column(String(64))
    work_location: Mapped[str | None] = mapped_column(String(255))
    audition_mode: Mapped[str | None] = mapped_column(String(32))
    instructions: Mapped[str | None] = mapped_column(Text)
    eligibility_json: Mapped[str | None] = mapped_column(Text)
    casting_questions_json: Mapped[str | None] = mapped_column(Text)
    application_due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    sides_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    contact_name: Mapped[str | None] = mapped_column(String(120))
    contact_email: Mapped[str | None] = mapped_column(String(255))
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    requirement: Mapped[ProjectRequirement] = relationship(lazy="joined")
    sides_file: Mapped[FileAsset | None] = relationship(lazy="joined")


class SavedCastingRole(EntityMixin, Base):
    __tablename__ = "saved_casting_roles"
    __table_args__ = (
        UniqueConstraint(
            "actor_user_id",
            "requirement_id",
            name="uq_saved_casting_role_actor",
        ),
        Index(
            "ix_saved_casting_roles_actor",
            "actor_user_id",
            "created_at",
        ),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("SROLE"),
    )
    actor_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    requirement_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("project_requirements.id", ondelete="CASCADE"),
        nullable=False,
    )

    actor: Mapped[User] = relationship(foreign_keys=[actor_user_id], lazy="joined")
    requirement: Mapped[ProjectRequirement] = relationship(lazy="joined")


class CastingApplication(EntityMixin, Base):
    __tablename__ = "casting_applications"
    __table_args__ = (
        UniqueConstraint(
            "requirement_id",
            "actor_user_id",
            name="uq_casting_application_actor_role",
        ),
        Index(
            "ix_casting_applications_actor_status",
            "actor_user_id",
            "status",
            "updated_at",
        ),
        Index(
            "ix_casting_applications_requirement_status",
            "requirement_id",
            "status",
            "updated_at",
        ),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("CAP"),
    )
    requirement_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("project_requirements.id", ondelete="CASCADE"),
        nullable=False,
    )
    actor_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    talent_profile_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("talent_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    conversation_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("conversations.id", ondelete="SET NULL"),
        unique=True,
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    cover_note: Mapped[str | None] = mapped_column(Text)
    answers_json: Mapped[str | None] = mapped_column(Text)
    availability_note: Mapped[str | None] = mapped_column(Text)
    portfolio_item_ids_json: Mapped[str | None] = mapped_column(Text)
    self_tape_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    viewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    withdrawn_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    audition_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    audition_due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    audition_location: Mapped[str | None] = mapped_column(String(255))
    audition_online_url: Mapped[str | None] = mapped_column(String(255))
    audition_instructions: Mapped[str | None] = mapped_column(Text)
    audition_contact: Mapped[str | None] = mapped_column(String(255))
    audition_confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    callback_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    callback_details: Mapped[str | None] = mapped_column(Text)
    rejection_reason: Mapped[str | None] = mapped_column(Text)
    review_score: Mapped[int | None] = mapped_column(Integer)
    review_comment: Mapped[str | None] = mapped_column(Text)
    reviewed_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    requirement: Mapped[ProjectRequirement] = relationship(lazy="joined")
    actor: Mapped[User] = relationship(foreign_keys=[actor_user_id], lazy="joined")
    reviewer: Mapped[User | None] = relationship(
        foreign_keys=[reviewed_by_id], lazy="joined"
    )
    talent_profile: Mapped[TalentProfile] = relationship(lazy="joined")
    conversation: Mapped[Conversation | None] = relationship(lazy="joined")
    self_tape_file: Mapped[FileAsset | None] = relationship(lazy="joined")
    status_events: Mapped[list[CastingApplicationStatusEvent]] = relationship(
        back_populates="application",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="CastingApplicationStatusEvent.created_at",
    )


class CastingApplicationStatusEvent(EntityMixin, Base):
    __tablename__ = "casting_application_status_events"
    __table_args__ = (
        Index(
            "ix_casting_application_events_application",
            "application_id",
            "created_at",
        ),
    )

    application_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("casting_applications.id", ondelete="CASCADE"),
        nullable=False,
    )
    actor_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    from_status: Mapped[str | None] = mapped_column(String(32))
    to_status: Mapped[str] = mapped_column(String(32), nullable=False)
    note: Mapped[str | None] = mapped_column(Text)

    application: Mapped[CastingApplication] = relationship(
        back_populates="status_events"
    )
    actor: Mapped[User | None] = relationship(lazy="joined")
