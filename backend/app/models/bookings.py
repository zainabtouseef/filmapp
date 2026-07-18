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
from app.models.files import FileAsset
from app.models.identity import User, make_public_id
from app.models.marketplace import MarketplaceListing
from app.models.projects import Project, ProjectRequirement


class Booking(EntityMixin, Base):
    __tablename__ = "bookings"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("BK"),
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
    )
    requirement_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("project_requirements.id", ondelete="SET NULL")
    )
    requester_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    provider_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("marketplace_listings.id", ondelete="RESTRICT"),
        nullable=False,
    )
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    status: Mapped[str] = mapped_column(String(64), nullable=False, default="draft")
    agreed_amount_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    start_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    secured_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    cancellation_reason: Mapped[str | None] = mapped_column(Text)

    project: Mapped[Project] = relationship(lazy="joined")
    requirement: Mapped[ProjectRequirement | None] = relationship(lazy="joined")
    requester: Mapped[User] = relationship(
        foreign_keys=[requester_user_id],
        lazy="joined",
    )
    provider: Mapped[User] = relationship(
        foreign_keys=[provider_user_id],
        lazy="joined",
    )
    listing: Mapped[MarketplaceListing] = relationship(lazy="joined")
    participants: Mapped[list[BookingParticipant]] = relationship(
        back_populates="booking",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    status_events: Mapped[list[BookingStatusEvent]] = relationship(
        back_populates="booking",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="BookingStatusEvent.created_at",
    )
    offers: Mapped[list[Offer]] = relationship(
        back_populates="booking",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="Offer.revision",
    )
    negotiation_thread: Mapped[NegotiationThread | None] = relationship(
        back_populates="booking",
        cascade="all, delete-orphan",
        lazy="selectin",
        uselist=False,
    )
    conversation: Mapped[Conversation | None] = relationship(
        back_populates="booking",
        cascade="all, delete-orphan",
        lazy="selectin",
        uselist=False,
    )


class BookingParticipant(EntityMixin, Base):
    __tablename__ = "booking_participants"
    __table_args__ = (
        UniqueConstraint("booking_id", "user_id", name="uq_booking_participant_user"),
    )

    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    participant_role: Mapped[str] = mapped_column(String(64), nullable=False)
    can_chat: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    can_view_finance: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )

    booking: Mapped[Booking] = relationship(back_populates="participants")
    user: Mapped[User] = relationship(lazy="joined")


class BookingStatusEvent(EntityMixin, Base):
    __tablename__ = "booking_status_events"

    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"),
        nullable=False,
    )
    actor_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    from_status: Mapped[str | None] = mapped_column(String(64))
    to_status: Mapped[str] = mapped_column(String(64), nullable=False)
    reason: Mapped[str | None] = mapped_column(Text)
    metadata_json: Mapped[str | None] = mapped_column(Text)

    booking: Mapped[Booking] = relationship(back_populates="status_events")
    actor: Mapped[User | None] = relationship(lazy="joined")


class Offer(EntityMixin, Base):
    __tablename__ = "offers"
    __table_args__ = (
        UniqueConstraint("booking_id", "revision", name="uq_booking_offer_revision"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("OFF"),
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"),
        nullable=False,
    )
    sender_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    recipient_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    revision: Mapped[int] = mapped_column(Integer, nullable=False)
    fee_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False)
    schedule_json: Mapped[str | None] = mapped_column(Text)
    conditions: Mapped[str | None] = mapped_column(Text)
    payment_schedule_json: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    booking: Mapped[Booking] = relationship(back_populates="offers")
    sender: Mapped[User] = relationship(foreign_keys=[sender_user_id], lazy="joined")
    recipient: Mapped[User] = relationship(
        foreign_keys=[recipient_user_id],
        lazy="joined",
    )


class NegotiationThread(EntityMixin, Base):
    __tablename__ = "negotiation_threads"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("NEG"),
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")
    current_offer_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("offers.id", ondelete="SET NULL")
    )
    locked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    booking: Mapped[Booking] = relationship(back_populates="negotiation_thread")
    current_offer: Mapped[Offer | None] = relationship(lazy="joined")
    rounds: Mapped[list[NegotiationRound]] = relationship(
        back_populates="thread",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="NegotiationRound.round_number",
    )


class NegotiationRound(EntityMixin, Base):
    __tablename__ = "negotiation_rounds"
    __table_args__ = (
        UniqueConstraint("thread_id", "round_number", name="uq_negotiation_round"),
    )

    thread_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("negotiation_threads.id", ondelete="CASCADE"),
        nullable=False,
    )
    offer_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("offers.id", ondelete="CASCADE"),
        nullable=False,
    )
    round_number: Mapped[int] = mapped_column(Integer, nullable=False)
    sender_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    message: Mapped[str | None] = mapped_column(Text)

    thread: Mapped[NegotiationThread] = relationship(back_populates="rounds")
    offer: Mapped[Offer] = relationship(lazy="joined")
    sender: Mapped[User] = relationship(lazy="joined")


class AvailabilityCalendar(EntityMixin, Base):
    __tablename__ = "availability_calendars"
    __table_args__ = (
        UniqueConstraint("owner_type", "owner_id", name="uq_availability_owner"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("CAL"),
    )
    owner_type: Mapped[str] = mapped_column(String(32), nullable=False)
    owner_id: Mapped[str] = mapped_column(String(40), nullable=False)
    timezone: Mapped[str] = mapped_column(
        String(64), nullable=False, default="Asia/Karachi"
    )

    entries: Mapped[list[AvailabilityEntry]] = relationship(
        back_populates="calendar",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class AvailabilityEntry(EntityMixin, Base):
    __tablename__ = "availability_entries"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("AVL"),
    )
    calendar_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("availability_calendars.id", ondelete="CASCADE"),
        nullable=False,
    )
    resource_type: Mapped[str] = mapped_column(String(64), nullable=False)
    resource_id: Mapped[str] = mapped_column(String(40), nullable=False)
    start_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    source_booking_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("bookings.id", ondelete="SET NULL")
    )
    note: Mapped[str | None] = mapped_column(Text)

    calendar: Mapped[AvailabilityCalendar] = relationship(back_populates="entries")
    source_booking: Mapped[Booking | None] = relationship(lazy="joined")


class Conversation(EntityMixin, Base):
    __tablename__ = "conversations"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("CONV"),
    )
    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"),
        unique=True,
    )
    project_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE")
    )
    type: Mapped[str] = mapped_column(String(32), nullable=False)
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    last_message_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    booking: Mapped[Booking | None] = relationship(back_populates="conversation")
    project: Mapped[Project | None] = relationship(lazy="joined")
    members: Mapped[list[ConversationMember]] = relationship(
        back_populates="conversation",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    messages: Mapped[list[Message]] = relationship(
        back_populates="conversation",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="Message.created_at",
    )


class ConversationMember(EntityMixin, Base):
    __tablename__ = "conversation_members"
    __table_args__ = (
        UniqueConstraint("conversation_id", "user_id", name="uq_conversation_member"),
    )

    conversation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    last_read_message_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("messages.id", ondelete="SET NULL")
    )
    muted_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    conversation: Mapped[Conversation] = relationship(back_populates="members")
    user: Mapped[User] = relationship(lazy="joined")


class Message(EntityMixin, Base):
    __tablename__ = "messages"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("MSG"),
    )
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"),
        nullable=False,
    )
    sender_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    message_type: Mapped[str] = mapped_column(
        String(32), nullable=False, default="text"
    )
    body: Mapped[str | None] = mapped_column(Text)
    reply_to_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("messages.id", ondelete="SET NULL")
    )
    decision_type: Mapped[str | None] = mapped_column(String(64))
    edited_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    conversation: Mapped[Conversation] = relationship(back_populates="messages")
    sender: Mapped[User] = relationship(lazy="joined")
    attachments: Mapped[list[MessageAttachment]] = relationship(
        back_populates="message",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class MessageAttachment(EntityMixin, Base):
    __tablename__ = "message_attachments"

    message_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("messages.id", ondelete="CASCADE"),
        nullable=False,
    )
    file_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("files.id", ondelete="CASCADE"),
        nullable=False,
    )
    attachment_type: Mapped[str] = mapped_column(String(32), nullable=False)
    caption: Mapped[str | None] = mapped_column(String(255))

    message: Mapped[Message] = relationship(back_populates="attachments")
    file: Mapped[FileAsset] = relationship(lazy="joined")


class PinnedDecision(EntityMixin, Base):
    __tablename__ = "pinned_decisions"

    conversation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"),
        nullable=False,
    )
    message_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("messages.id", ondelete="CASCADE"),
        nullable=False,
    )
    pinned_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    decision_key: Mapped[str] = mapped_column(String(64), nullable=False)
    superseded_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("pinned_decisions.id", ondelete="SET NULL")
    )

    conversation: Mapped[Conversation] = relationship(lazy="joined")
    message: Mapped[Message] = relationship(foreign_keys=[message_id], lazy="joined")
    pinner: Mapped[User] = relationship(foreign_keys=[pinned_by], lazy="joined")
