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


class Review(EntityMixin, Base):
    __tablename__ = "reviews"
    __table_args__ = (
        UniqueConstraint(
            "booking_id",
            "reviewer_user_id",
            "reviewee_user_id",
            name="uq_review_booking_parties",
        ),
    )

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("REV")
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False
    )
    reviewer_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    reviewee_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    rating: Mapped[int] = mapped_column(Integer, nullable=False)
    text: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="published")
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    booking: Mapped[Booking] = relationship(lazy="joined")
    reviewer: Mapped[User] = relationship(
        foreign_keys=[reviewer_user_id], lazy="joined"
    )
    reviewee: Mapped[User] = relationship(
        foreign_keys=[reviewee_user_id], lazy="joined"
    )
    dimensions: Mapped[list[ReviewDimension]] = relationship(
        back_populates="review", cascade="all, delete-orphan", lazy="selectin"
    )


class ReviewDimension(EntityMixin, Base):
    __tablename__ = "review_dimensions"

    review_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("reviews.id", ondelete="CASCADE"), nullable=False
    )
    dimension: Mapped[str] = mapped_column(String(64), nullable=False)
    score: Mapped[int] = mapped_column(Integer, nullable=False)

    review: Mapped[Review] = relationship(back_populates="dimensions")


class ReviewRequest(EntityMixin, Base):
    __tablename__ = "review_requests"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("RVR")
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False
    )
    requested_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    requested_from: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="sent")
    sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    completed_review_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("reviews.id", ondelete="SET NULL")
    )

    booking: Mapped[Booking] = relationship(lazy="joined")
    requester: Mapped[User] = relationship(foreign_keys=[requested_by], lazy="joined")
    requested_from_user: Mapped[User] = relationship(
        foreign_keys=[requested_from], lazy="joined"
    )
    completed_review: Mapped[Review | None] = relationship(lazy="joined")


class BlockedUser(EntityMixin, Base):
    __tablename__ = "blocked_users"
    __table_args__ = (
        UniqueConstraint(
            "blocker_user_id", "blocked_user_id", name="uq_blocked_user_pair"
        ),
    )

    blocker_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    blocked_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    reason: Mapped[str | None] = mapped_column(String(255))

    blocker: Mapped[User] = relationship(foreign_keys=[blocker_user_id], lazy="joined")
    blocked: Mapped[User] = relationship(foreign_keys=[blocked_user_id], lazy="joined")


class Report(EntityMixin, Base):
    __tablename__ = "reports"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("RPT")
    )
    reporter_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    reported_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    entity_type: Mapped[str] = mapped_column(String(64), nullable=False)
    entity_id: Mapped[str] = mapped_column(String(40), nullable=False)
    reason: Mapped[str] = mapped_column(String(64), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")
    assigned_admin_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    resolution: Mapped[str | None] = mapped_column(Text)

    reporter: Mapped[User] = relationship(
        foreign_keys=[reporter_user_id], lazy="joined"
    )
    reported_user: Mapped[User | None] = relationship(
        foreign_keys=[reported_user_id], lazy="joined"
    )
    assigned_admin: Mapped[User | None] = relationship(
        foreign_keys=[assigned_admin_id], lazy="joined"
    )


class ModerationCase(EntityMixin, Base):
    __tablename__ = "moderation_cases"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("MODC")
    )
    entity_type: Mapped[str] = mapped_column(String(64), nullable=False)
    entity_id: Mapped[str] = mapped_column(String(40), nullable=False)
    source: Mapped[str] = mapped_column(String(32), nullable=False)
    risk_level: Mapped[str] = mapped_column(
        String(32), nullable=False, default="medium"
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="queued")
    assigned_admin_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    decision: Mapped[str | None] = mapped_column(String(32))
    decision_reason: Mapped[str | None] = mapped_column(Text)

    assigned_admin: Mapped[User | None] = relationship(lazy="joined")
    events: Mapped[list[ModerationEvent]] = relationship(
        back_populates="case",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ModerationEvent.created_at",
    )


class ModerationEvent(EntityMixin, Base):
    __tablename__ = "moderation_events"

    case_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("moderation_cases.id", ondelete="CASCADE"), nullable=False
    )
    actor_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    action: Mapped[str] = mapped_column(String(64), nullable=False)
    from_status: Mapped[str | None] = mapped_column(String(32))
    to_status: Mapped[str | None] = mapped_column(String(32))
    notes: Mapped[str | None] = mapped_column(Text)

    case: Mapped[ModerationCase] = relationship(back_populates="events")
    actor: Mapped[User] = relationship(lazy="joined")


class Dispute(EntityMixin, Base):
    __tablename__ = "disputes"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("DSP")
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False
    )
    opened_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    respondent_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    type: Mapped[str] = mapped_column(String(64), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    value_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    severity: Mapped[str] = mapped_column(String(32), nullable=False, default="medium")
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")
    assigned_admin_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    booking: Mapped[Booking] = relationship(lazy="joined")
    opener: Mapped[User] = relationship(foreign_keys=[opened_by], lazy="joined")
    respondent: Mapped[User] = relationship(
        foreign_keys=[respondent_user_id], lazy="joined"
    )
    assigned_admin: Mapped[User | None] = relationship(
        foreign_keys=[assigned_admin_id], lazy="joined"
    )
    evidence: Mapped[list[DisputeEvidence]] = relationship(
        back_populates="dispute", cascade="all, delete-orphan", lazy="selectin"
    )
    events: Mapped[list[DisputeEvent]] = relationship(
        back_populates="dispute",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="DisputeEvent.created_at",
    )


class DisputeEvidence(EntityMixin, Base):
    __tablename__ = "dispute_evidence"

    dispute_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("disputes.id", ondelete="CASCADE"), nullable=False
    )
    submitted_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    evidence_type: Mapped[str] = mapped_column(String(64), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)

    dispute: Mapped[Dispute] = relationship(back_populates="evidence")
    submitter: Mapped[User] = relationship(lazy="joined")
    file: Mapped[FileAsset | None] = relationship(lazy="joined")


class DisputeEvent(EntityMixin, Base):
    __tablename__ = "dispute_events"

    dispute_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("disputes.id", ondelete="CASCADE"), nullable=False
    )
    actor_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    event_type: Mapped[str] = mapped_column(String(64), nullable=False)
    note: Mapped[str | None] = mapped_column(Text)
    metadata_json: Mapped[str | None] = mapped_column(Text)

    dispute: Mapped[Dispute] = relationship(back_populates="events")
    actor: Mapped[User] = relationship(lazy="joined")


class SupportTicket(EntityMixin, Base):
    __tablename__ = "support_tickets"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("TKT")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    booking_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("bookings.id", ondelete="SET NULL")
    )
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    priority: Mapped[str] = mapped_column(String(32), nullable=False, default="normal")
    subject: Mapped[str] = mapped_column(String(180), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")
    assigned_admin_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    last_message_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped[User] = relationship(foreign_keys=[user_id], lazy="joined")
    booking: Mapped[Booking | None] = relationship(lazy="joined")
    assigned_admin: Mapped[User | None] = relationship(
        foreign_keys=[assigned_admin_id], lazy="joined"
    )
    messages: Mapped[list[SupportMessage]] = relationship(
        back_populates="ticket",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="SupportMessage.created_at",
    )


class SupportMessage(EntityMixin, Base):
    __tablename__ = "support_messages"

    ticket_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("support_tickets.id", ondelete="CASCADE"), nullable=False
    )
    sender_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    body: Mapped[str] = mapped_column(Text, nullable=False)
    file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    internal_note: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    ticket: Mapped[SupportTicket] = relationship(back_populates="messages")
    sender: Mapped[User] = relationship(lazy="joined")
    file: Mapped[FileAsset | None] = relationship(lazy="joined")


class Announcement(EntityMixin, Base):
    __tablename__ = "announcements"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("ANN")
    )
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    audience_json: Mapped[str | None] = mapped_column(Text)
    channel_json: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    creator: Mapped[User] = relationship(lazy="joined")


class Notification(EntityMixin, Base):
    __tablename__ = "notifications"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("NTF")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    route_name: Mapped[str | None] = mapped_column(String(120))
    route_params_json: Mapped[str | None] = mapped_column(Text)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped[User] = relationship(lazy="joined")
    deliveries: Mapped[list[NotificationDelivery]] = relationship(
        back_populates="notification", cascade="all, delete-orphan", lazy="selectin"
    )


class NotificationDelivery(EntityMixin, Base):
    __tablename__ = "notification_deliveries"

    notification_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("notifications.id", ondelete="CASCADE"), nullable=False
    )
    channel: Mapped[str] = mapped_column(String(32), nullable=False)
    provider: Mapped[str | None] = mapped_column(String(64))
    provider_reference: Mapped[str | None] = mapped_column(String(255))
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    failed_reason: Mapped[str | None] = mapped_column(Text)

    notification: Mapped[Notification] = relationship(back_populates="deliveries")


class PushDevice(EntityMixin, Base):
    __tablename__ = "push_devices"
    __table_args__ = (
        UniqueConstraint("user_id", "device_id", name="uq_push_device_user_device"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    platform: Mapped[str] = mapped_column(String(32), nullable=False)
    token_reference: Mapped[str | None] = mapped_column(String(255))
    device_id: Mapped[str] = mapped_column(String(120), nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped[User] = relationship(lazy="joined")
