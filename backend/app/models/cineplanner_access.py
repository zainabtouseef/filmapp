from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.identity import make_public_id


class CineMembership(EntityMixin, Base):
    __tablename__ = "cine_memberships"
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True
    )
    access_mode: Mapped[str] = mapped_column(String(24), default="preview")
    period_start: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    period_end: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    alterations_used: Mapped[int] = mapped_column(Integer, default=0)


class CineSubscriptionPayment(EntityMixin, Base):
    __tablename__ = "cine_subscription_payments"
    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, default=lambda: make_public_id("CSP")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE")
    )
    proof_file_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("files.id", ondelete="RESTRICT"), unique=True
    )
    reference: Mapped[str] = mapped_column(String(160))
    amount_minor: Mapped[int] = mapped_column(Integer, default=2000)
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    status: Mapped[str] = mapped_column(String(24), default="pending", index=True)
    reviewed_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    review_note: Mapped[str | None] = mapped_column(Text)


class CineAssistantMessage(EntityMixin, Base):
    __tablename__ = "cine_assistant_messages"
    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, default=lambda: make_public_id("CAM")
    )
    production_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("cine_productions.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE")
    )
    script_version_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cine_script_versions.id", ondelete="CASCADE")
    )
    role: Mapped[str] = mapped_column(String(20))
    status: Mapped[str] = mapped_column(String(24), default="complete")
    content: Mapped[str] = mapped_column(Text, default="")
    changes_json: Mapped[list[dict[str, Any]]] = mapped_column(JSON, default=list)
    context_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    applied_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
