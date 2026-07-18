from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.mysql import LONGTEXT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.identity import User, make_public_id


class ExportJob(EntityMixin, Base):
    __tablename__ = "export_jobs"

    public_id: Mapped[str] = mapped_column(
        String(40), unique=True, nullable=False, default=lambda: make_public_id("EXP")
    )
    requested_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    export_type: Mapped[str] = mapped_column(String(64), nullable=False)
    filters_json: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="queued")
    row_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    csv_content: Mapped[str | None] = mapped_column(LONGTEXT)
    error_message: Mapped[str | None] = mapped_column(Text)
    requested_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    requester: Mapped[User] = relationship(lazy="joined")
