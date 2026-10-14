from __future__ import annotations

from typing import Any

from sqlalchemy import JSON, String
from sqlalchemy.orm import Mapped, mapped_column

from app.extensions import Base
from app.models.base import EntityMixin


class AppSetting(EntityMixin, Base):
    __tablename__ = "app_settings"

    key: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    value_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
