from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Index,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.bookings import Conversation
from app.models.identity import User, make_public_id
from app.models.projects import ProjectRequirement

# Generic counterpart to CastingApplication for non-talent/model requirement
# categories (location, equipment, crew, ...) — those applicants have no
# TalentProfile to hang an application off, and don't need the acting-specific
# audition/self-tape/callback fields CastingApplication carries.


class RequirementApplication(EntityMixin, Base):
    __tablename__ = "requirement_applications"
    __table_args__ = (
        UniqueConstraint(
            "requirement_id",
            "applicant_user_id",
            name="uq_requirement_application_applicant",
        ),
        Index(
            "ix_requirement_applications_applicant_status",
            "applicant_user_id",
            "status",
            "updated_at",
        ),
        Index(
            "ix_requirement_applications_requirement_status",
            "requirement_id",
            "status",
            "updated_at",
        ),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("RAPP"),
    )
    requirement_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("project_requirements.id", ondelete="CASCADE"),
        nullable=False,
    )
    applicant_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    conversation_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("conversations.id", ondelete="SET NULL"),
        unique=True,
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    cover_note: Mapped[str | None] = mapped_column(Text)
    answers_json: Mapped[str | None] = mapped_column(Text)
    attachment_file_ids_json: Mapped[str | None] = mapped_column(Text)
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    withdrawn_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    rejection_reason: Mapped[str | None] = mapped_column(Text)
    # Denormalized snapshot of the latest accepted meeting round (see
    # app/models/scheduling.py) — kept in sync by app/services/scheduling.py
    # so display code doesn't need to look up the negotiation thread.
    meeting_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    meeting_location: Mapped[str | None] = mapped_column(String(255))
    meeting_online_url: Mapped[str | None] = mapped_column(String(255))
    meeting_instructions: Mapped[str | None] = mapped_column(Text)
    meeting_contact: Mapped[str | None] = mapped_column(String(255))
    meeting_confirmed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )

    requirement: Mapped[ProjectRequirement] = relationship(lazy="joined")
    applicant: Mapped[User] = relationship(lazy="joined")
    conversation: Mapped[Conversation | None] = relationship(lazy="joined")
    status_events: Mapped[list[RequirementApplicationStatusEvent]] = relationship(
        back_populates="application",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="RequirementApplicationStatusEvent.created_at",
    )


class RequirementApplicationStatusEvent(EntityMixin, Base):
    __tablename__ = "requirement_application_status_events"
    __table_args__ = (
        Index(
            "ix_requirement_application_events_application",
            "application_id",
            "created_at",
        ),
    )

    application_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("requirement_applications.id", ondelete="CASCADE"),
        nullable=False,
    )
    actor_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    from_status: Mapped[str | None] = mapped_column(String(32))
    to_status: Mapped[str] = mapped_column(String(32), nullable=False)
    note: Mapped[str | None] = mapped_column(Text)

    application: Mapped[RequirementApplication] = relationship(
        back_populates="status_events"
    )
    actor: Mapped[User | None] = relationship(lazy="joined")
