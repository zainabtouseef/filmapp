from __future__ import annotations

from collections.abc import Iterable
from typing import Any

from sqlalchemy import select

from app.extensions import db
from app.models.cineplanner import (
    CineActor,
    CineBudgetLine,
    CineCastAssignment,
    CineCharacter,
    CineCrewMember,
    CineElement,
    CineLocation,
    CineProduction,
    CineShootDay,
)

ELEMENT_BUDGET_CATEGORY = {
    "props": "Props",
    "wardrobe": "Wardrobe",
    "makeup": "Makeup",
    "vehicles": "Vehicles",
    "extras": "Cast",
    "stunts": "Stunts",
    "vfx": "VFX",
    "sfx": "SFX",
    "equipment": "Equipment",
}


def recalculate_budget(production: CineProduction) -> dict[str, Any]:
    generated: list[dict[str, Any]] = []
    shoot_days = (
        db.session.execute(
            select(CineShootDay).where(CineShootDay.production_id == production.id)
        )
        .scalars()
        .all()
    )
    shoot_day_count = len(shoot_days)

    for assignment in db.session.execute(
        select(CineCastAssignment).where(
            CineCastAssignment.production_id == production.id,
            CineCastAssignment.status == "confirmed",
        )
    ).scalars():
        actor = db.session.get(CineActor, assignment.actor_id)
        character = db.session.get(CineCharacter, assignment.character_id)
        if actor is None:
            continue
        days = max(1, character.estimated_shoot_days if character else shoot_day_count)
        amount = actor.project_rate_minor or (actor.daily_rate_minor or 0) * days
        generated.append(
            {
                "category": "Cast",
                "description": (
                    f"{actor.name} · {character.name if character else 'Cast'}"
                ),
                "source_type": "cast_assignment",
                "source_public_id": assignment.public_id,
                "estimated_minor": amount,
            }
        )

    location_day_counts: dict[str, int] = {}
    for day in shoot_days:
        if day.location_name:
            location_day_counts[day.location_name.casefold()] = (
                location_day_counts.get(day.location_name.casefold(), 0) + 1
            )
    for location in db.session.execute(
        select(CineLocation).where(
            CineLocation.production_id == production.id,
            CineLocation.status == "confirmed",
        )
    ).scalars():
        days = max(1, location_day_counts.get(location.screenplay_name.casefold(), 1))
        generated.append(
            {
                "category": "Locations",
                "description": location.option_name or location.screenplay_name,
                "source_type": "location",
                "source_public_id": location.public_id,
                "estimated_minor": (location.rental_rate_minor or 0) * days,
            }
        )

    for element in db.session.execute(
        select(CineElement).where(CineElement.production_id == production.id)
    ).scalars():
        days = max(1, len(set(element.scene_numbers_json)))
        multiplier = days if element.rate_basis == "daily" else 1
        generated.append(
            {
                "category": ELEMENT_BUDGET_CATEGORY.get(element.category, "Other"),
                "description": element.name,
                "source_type": "element",
                "source_public_id": element.public_id,
                "estimated_minor": (element.cost_rate_minor or 0)
                * max(1, element.quantity)
                * multiplier,
            }
        )

    for crew in db.session.execute(
        select(CineCrewMember).where(
            CineCrewMember.production_id == production.id,
            CineCrewMember.status.in_({"confirmed", "active"}),
        )
    ).scalars():
        generated.append(
            {
                "category": "Crew",
                "description": f"{crew.name} · {crew.job_title}",
                "source_type": "crew",
                "source_public_id": crew.public_id,
                "estimated_minor": (crew.daily_rate_minor or 0)
                * max(1, shoot_day_count),
            }
        )

    _sync_generated(production, generated)
    db.session.flush()
    lines = (
        db.session.execute(
            select(CineBudgetLine).where(CineBudgetLine.production_id == production.id)
        )
        .scalars()
        .all()
    )
    totals = {
        "estimated_minor": sum(item.estimated_minor for item in lines),
        "quoted_minor": sum(item.quoted_minor for item in lines),
        "approved_minor": sum(item.approved_minor for item in lines),
        "committed_minor": sum(item.committed_minor for item in lines),
        "paid_minor": sum(item.paid_minor for item in lines),
    }
    basis = (
        production.budget_ceiling_minor
        or totals["approved_minor"]
        or totals["estimated_minor"]
    )
    totals["remaining_minor"] = basis - totals["committed_minor"]
    totals["variance_minor"] = totals["estimated_minor"] - totals["approved_minor"]
    return {"totals": totals, "lines": lines}


def _sync_generated(
    production: CineProduction,
    generated: Iterable[dict[str, Any]],
) -> None:
    generated_rows = list(generated)
    keys = {
        (str(item["source_type"]), str(item["source_public_id"]))
        for item in generated_rows
    }
    existing = (
        db.session.execute(
            select(CineBudgetLine).where(
                CineBudgetLine.production_id == production.id,
                CineBudgetLine.source_type.is_not(None),
            )
        )
        .scalars()
        .all()
    )
    by_key = {
        (item.source_type or "", item.source_public_id or ""): item for item in existing
    }
    for key, item in by_key.items():
        if key not in keys:
            db.session.delete(item)
    for raw in generated_rows:
        key = (raw["source_type"], raw["source_public_id"])
        line = by_key.get(key)
        if line is None:
            line = CineBudgetLine(production_id=production.id, **raw)
            db.session.add(line)
        else:
            line.category = raw["category"]
            line.description = raw["description"]
            line.estimated_minor = raw["estimated_minor"]
