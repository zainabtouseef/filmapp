from __future__ import annotations

import calendar
from datetime import datetime
from typing import Any

from flask import current_app
from sqlalchemy import select

from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.cineplanner import CineProduction
from app.models.cineplanner_access import CineMembership
from app.models.identity import User
from app.security import as_utc

PRICE_MINOR = 2000
ALTERATIONS = 10


def membership(user_id: Any, *, create: bool = False) -> CineMembership | None:
    if create:
        db.session.execute(
            select(User).where(User.id == user_id).with_for_update()
        ).scalar_one()
    statement = select(CineMembership).where(CineMembership.user_id == user_id)
    if create:
        statement = statement.with_for_update().execution_options(
            populate_existing=True
        )
    row = db.session.scalar(statement)
    if row is None and create:
        row = CineMembership(user_id=user_id, access_mode="preview", alterations_used=0)
        db.session.add(row)
        db.session.flush()
    return row


def active(row: CineMembership | None) -> bool:
    return bool(
        row
        and (
            row.access_mode == "owner"
            or (
                row.access_mode == "subscription"
                and row.period_end
                and as_utc(row.period_end) > utc_now()
            )
        )
    )


def account_access(
    user: User, production: CineProduction | None = None
) -> dict[str, Any]:
    row = membership(user.id)
    if (
        not active(row)
        and production is not None
        and production.owner_user_id != user.id
    ):
        row = membership(production.owner_user_id)
    enabled = current_app.config.get("CINEPLANNER_BILLING_ENABLED", True)
    full = not enabled or active(row)
    unlimited = bool(not enabled or (row and row.access_mode == "owner"))
    used = row.alterations_used if row and active(row) else 0
    return {
        "full_access": full,
        "mode": "owner" if unlimited else "subscription" if full else "preview",
        "price_minor": PRICE_MINOR,
        "currency": "USD",
        "interval": "month",
        "alterations_included": ALTERATIONS,
        "alterations_used": used,
        "alterations_remaining": None
        if unlimited
        else max(0, ALTERATIONS - used)
        if full
        else 0,
        "unlimited_alterations": unlimited,
        "expires_at": row.period_end.isoformat() if row and row.period_end else None,
        "payment_method": "bank_transfer",
        "auto_renew": False,
        "payment_instructions": current_app.config.get(
            "CINEPLANNER_PAYMENT_INSTRUCTIONS",
            "Contact support for bank-transfer details.",
        ),
    }


def require_full(user: User, production: CineProduction | None = None) -> None:
    if not account_access(user, production)["full_access"]:
        raise APIError(
            "cineplanner.subscription_required",
            (
                "Unlock the complete workspace with CinePlanner Complete: USD"
                " 20/month, including 10 alterations."
            ),
            status=402,
        )


def consume_alteration(user: User, production: CineProduction) -> None:
    if not current_app.config.get("CINEPLANNER_BILLING_ENABLED", True):
        return
    own = membership(user.id)
    payer_id = user.id if active(own) else production.owner_user_id
    row = membership(payer_id, create=True)
    assert row is not None
    if not active(row):
        require_full(user, production)
    if row.access_mode == "owner":
        return
    if row.alterations_used >= ALTERATIONS:
        raise APIError(
            "cineplanner.alterations_exhausted",
            (
                "All 10 alterations for this month have been used. Your "
                "complete breakdown remains available until the plan expires."
            ),
            status=402,
        )
    row.alterations_used += 1


def next_month(value: datetime) -> datetime:
    year, month = (
        (value.year + 1, 1) if value.month == 12 else (value.year, value.month + 1)
    )
    return value.replace(
        year=year, month=month, day=min(value.day, calendar.monthrange(year, month)[1])
    )


def preview_snapshot(
    snapshot: dict[str, Any], user: User, production: CineProduction
) -> dict[str, Any]:
    access = account_access(user, production)
    snapshot["access"] = access
    if access["full_access"]:
        return snapshot
    snapshot["preview"] = {
        "scene_limit": 3,
        "character_limit": 3,
        "location_limit": 3,
        "element_limit_per_category": 2,
    }
    for key in ("scenes", "characters", "locations"):
        snapshot[key] = snapshot[key][:3]
    elements = []
    for category in ("props", "wardrobe"):
        elements.extend(
            [row for row in snapshot["elements"] if row["category"] == category][:2]
        )
    snapshot["elements"] = elements
    for key in ("actors", "cast_assignments", "crew", "call_sheets", "team"):
        snapshot[key] = []
    snapshot["schedule"] = {"locked": True, "days": [], "conflicts": []}
    snapshot["budget"] = None
    return snapshot
