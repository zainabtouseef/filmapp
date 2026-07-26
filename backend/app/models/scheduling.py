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
from app.models.identity import User, make_public_id


class MeetingThread(EntityMixin, Base):
    __tablename__ = "meeting_threads"
    __table_args__ = (
        UniqueConstraint(
            "subject_type", "subject_id", name="uq_meeting_thread_subject"
        ),
        Index("ix_meeting_threads_subject", "subject_type", "subject_id"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("MEET"),
    )
    subject_type: Mapped[str] = mapped_column(String(32), nullable=False)
    subject_id: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")
    current_round_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("meeting_rounds.id", ondelete="SET NULL", use_alter=True)
    )
    locked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    current_round: Mapped[MeetingRound | None] = relationship(
        foreign_keys=[current_round_id],
        lazy="joined",
        post_update=True,
    )
    rounds: Mapped[list[MeetingRound]] = relationship(
        back_populates="thread",
        foreign_keys="MeetingRound.thread_id",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="MeetingRound.round_number",
    )


class MeetingRound(EntityMixin, Base):
    __tablename__ = "meeting_rounds"
    __table_args__ = (
        UniqueConstraint("thread_id", "round_number", name="uq_meeting_round_number"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("MTR"),
    )
    thread_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("meeting_threads.id", ondelete="CASCADE"),
        nullable=False,
    )
    round_number: Mapped[int] = mapped_column(Integer, nullable=False)
    proposed_by_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    meeting_kind: Mapped[str | None] = mapped_column(String(32))
    meeting_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    location: Mapped[str | None] = mapped_column(String(255))
    online_url: Mapped[str | None] = mapped_column(String(255))
    instructions: Mapped[str | None] = mapped_column(Text)
    contact: Mapped[str | None] = mapped_column(String(255))
    message: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    decline_reason: Mapped[str | None] = mapped_column(Text)
    responded_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    responded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    thread: Mapped[MeetingThread] = relationship(
        back_populates="rounds",
        foreign_keys=[thread_id],
    )
    proposed_by: Mapped[User] = relationship(
        foreign_keys=[proposed_by_user_id],
        lazy="joined",
    )
    responded_by: Mapped[User | None] = relationship(
        foreign_keys=[responded_by_user_id],
        lazy="joined",
    )
