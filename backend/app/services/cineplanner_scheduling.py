from __future__ import annotations

from collections import defaultdict
from collections.abc import Iterable
from datetime import date, datetime, time, timedelta
from typing import Any

from sqlalchemy import delete, select

from app.extensions import db
from app.models.cineplanner import (
    CineActorAvailability,
    CineCastAssignment,
    CineCharacter,
    CineConflict,
    CineElement,
    CineLocation,
    CineProduction,
    CineScene,
    CineScheduleEvent,
    CineShootDay,
)


def _minutes(scene: CineScene) -> int:
    complexity = {"low": 0, "medium": 25, "high": 70, "extreme": 130}.get(
        scene.complexity.lower(), 25
    )
    requirements = sum(
        len(values)
        for values in (
            scene.stunts_json,
            scene.vfx_json,
            scene.sfx_json,
            scene.vehicles_json,
            scene.extras_json,
        )
    )
    return max(45, 35 + scene.page_length_eighths * 7 + complexity + requirements * 5)


def _scene_sort_key(scene: CineScene, strategy: str) -> tuple[Any, ...]:
    is_night = "night" in scene.time_of_day.lower()
    if strategy == "lowest_cost":
        return (scene.location_name.casefold(), is_night, scene.sort_order)
    if strategy == "fastest":
        return (-_minutes(scene), is_night, scene.location_name.casefold())
    return (
        is_night,
        scene.location_name.casefold(),
        scene.story_day or "",
        scene.sort_order,
    )


def build_schedule_plan(
    production: CineProduction,
    scenes: Iterable[CineScene],
    strategy: str,
) -> dict[str, Any]:
    if strategy not in {"lowest_cost", "fastest", "balanced"}:
        raise ValueError("Unsupported schedule strategy")
    start_date = production.production_start_date or date.today() + timedelta(days=7)
    max_minutes = max(6, production.working_hours_limit) * 60
    ordered = sorted(scenes, key=lambda item: _scene_sort_key(item, strategy))
    days: list[dict[str, Any]] = []
    current: list[CineScene] = []
    used = 0
    for scene in ordered:
        duration = _minutes(scene)
        location_move = bool(
            current and current[-1].location_name != scene.location_name
        )
        addition = duration + (45 if location_move else 0)
        if current and used + addition > max_minutes:
            days.append({"scenes": current, "minutes": used})
            current = []
            used = 0
            location_move = False
            addition = duration
        current.append(scene)
        used += addition
    if current:
        days.append({"scenes": current, "minutes": used})

    rendered_days: list[dict[str, Any]] = []
    location_moves = 0
    night_shoots = 0
    total_minutes = 0
    cursor_date = start_date
    for day_index, item in enumerate(days, start=1):
        while cursor_date.weekday() == 6:
            cursor_date += timedelta(days=1)
        day_scenes: list[CineScene] = item["scenes"]
        has_night = any("night" in scene.time_of_day.lower() for scene in day_scenes)
        start_minute = (
            16 * 60
            if has_night
            and all("night" in scene.time_of_day.lower() for scene in day_scenes)
            else 6 * 60
        )
        events: list[dict[str, Any]] = []
        minute_cursor = start_minute
        previous_location: str | None = None
        meal_added = False
        for scene_index, scene in enumerate(day_scenes):
            if previous_location and previous_location != scene.location_name:
                events.append(
                    {
                        "type": "travel",
                        "title": "Company move",
                        "start_minute": minute_cursor,
                        "end_minute": minute_cursor + 45,
                        "scene_id": None,
                        "travel_minutes": 45,
                    }
                )
                minute_cursor += 45
                location_moves += 1
            duration = _minutes(scene)
            events.append(
                {
                    "type": "scene",
                    "title": f"Scene {scene.scene_number} · {scene.slugline}",
                    "start_minute": minute_cursor,
                    "end_minute": minute_cursor + duration,
                    "scene_id": scene.public_id,
                    "setup_minutes": 20,
                    "rehearsal_minutes": 10,
                    "lighting_minutes": 20 if scene.int_ext == "INT" else 10,
                    "camera_minutes": 10,
                    "makeup_minutes": 10 if scene.makeup_json else 0,
                    "wardrobe_minutes": 10 if scene.wardrobe_json else 0,
                    "shooting_minutes": max(15, duration - 60),
                    "reset_minutes": 10,
                }
            )
            minute_cursor += duration
            previous_location = scene.location_name
            if (
                not meal_added
                and minute_cursor - start_minute >= 6 * 60
                and scene_index < len(day_scenes) - 1
            ):
                events.append(
                    {
                        "type": "meal",
                        "title": "Lunch",
                        "start_minute": minute_cursor,
                        "end_minute": minute_cursor + 60,
                        "scene_id": None,
                    }
                )
                minute_cursor += 60
                meal_added = True
        night_shoots += int(has_night)
        total_minutes += minute_cursor - start_minute
        rendered_days.append(
            {
                "shoot_day_number": day_index,
                "shoot_date": cursor_date.isoformat(),
                "crew_call": _minute_to_time(start_minute),
                "expected_wrap": _minute_to_time(minute_cursor),
                "location_name": day_scenes[0].location_name if day_scenes else None,
                "scene_numbers": [scene.scene_number for scene in day_scenes],
                "events": events,
            }
        )
        cursor_date += timedelta(days=1)

    estimated_cost = _estimate_plan_cost(production, len(rendered_days))
    conflicts = []
    if len(rendered_days) > production.maximum_shoot_days:
        conflicts.append(
            {
                "type": "shoot_day_limit",
                "severity": "critical",
                "message": (
                    f"Plan needs {len(rendered_days)} days; limit is "
                    f"{production.maximum_shoot_days}."
                ),
            }
        )
    return {
        "strategy": strategy,
        "shoot_days": len(rendered_days),
        "total_hours": round(total_minutes / 60, 1),
        "night_shoots": night_shoots,
        "location_moves": location_moves,
        "estimated_cost_minor": estimated_cost,
        "conflicts": conflicts,
        "days": rendered_days,
    }


def _estimate_plan_cost(production: CineProduction, shoot_days: int) -> int:
    cast_cost = 0
    assignments = db.session.execute(
        select(CineCastAssignment).where(
            CineCastAssignment.production_id == production.id,
            CineCastAssignment.status == "confirmed",
        )
    ).scalars()
    for assignment in assignments:
        from app.models.cineplanner import CineActor

        actor = db.session.get(CineActor, assignment.actor_id)
        character = db.session.get(CineCharacter, assignment.character_id)
        if actor is None:
            continue
        if actor.project_rate_minor:
            cast_cost += actor.project_rate_minor
        elif actor.daily_rate_minor:
            cast_cost += actor.daily_rate_minor * max(
                1, character.estimated_shoot_days if character else shoot_days
            )
    location_cost = sum(
        (item.rental_rate_minor or 0) * max(1, shoot_days)
        for item in db.session.execute(
            select(CineLocation).where(
                CineLocation.production_id == production.id,
                CineLocation.status == "confirmed",
            )
        ).scalars()
    )
    element_cost = sum(
        (item.cost_rate_minor or 0)
        * max(1, item.quantity)
        * (shoot_days if item.rate_basis == "daily" else 1)
        for item in db.session.execute(
            select(CineElement).where(CineElement.production_id == production.id)
        ).scalars()
    )
    return cast_cost + location_cost + element_cost


def _minute_to_time(value: int) -> str:
    value %= 24 * 60
    return f"{value // 60:02d}:{value % 60:02d}"


def _parse_clock(value: str) -> time:
    hour, minute = value.split(":", 1)
    return time(int(hour), int(minute))


def _clock_offset(value: time, crew_call: time) -> int:
    minutes = value.hour * 60 + value.minute
    crew_minutes = crew_call.hour * 60 + crew_call.minute
    return minutes + (24 * 60 if minutes < crew_minutes else 0)


def apply_schedule_plan(production: CineProduction, plan: dict[str, Any]) -> None:
    if production.schedule_locked_at is not None:
        raise ValueError("Locked schedules cannot be replaced")
    db.session.execute(
        delete(CineConflict).where(CineConflict.production_id == production.id)
    )
    db.session.execute(
        delete(CineScheduleEvent).where(
            CineScheduleEvent.production_id == production.id
        )
    )
    db.session.execute(
        delete(CineShootDay).where(CineShootDay.production_id == production.id)
    )
    scene_by_public_id = {
        scene.public_id: scene
        for scene in db.session.execute(
            select(CineScene).where(CineScene.production_id == production.id)
        ).scalars()
    }
    for raw_day in plan["days"]:
        day = CineShootDay(
            production_id=production.id,
            shoot_day_number=raw_day["shoot_day_number"],
            shoot_date=date.fromisoformat(raw_day["shoot_date"]),
            crew_call=_parse_clock(raw_day["crew_call"]),
            expected_wrap=_parse_clock(raw_day["expected_wrap"]),
            location_name=raw_day.get("location_name"),
        )
        db.session.add(day)
        db.session.flush()
        for raw_event in raw_day["events"]:
            scene = scene_by_public_id.get(raw_event.get("scene_id"))
            db.session.add(
                CineScheduleEvent(
                    production_id=production.id,
                    shoot_day_id=day.id,
                    scene_id=scene.id if scene else None,
                    event_type=raw_event["type"],
                    title=raw_event["title"],
                    starts_at=_parse_clock(_minute_to_time(raw_event["start_minute"])),
                    ends_at=_parse_clock(_minute_to_time(raw_event["end_minute"])),
                    setup_minutes=raw_event.get("setup_minutes", 0),
                    rehearsal_minutes=raw_event.get("rehearsal_minutes", 0),
                    lighting_minutes=raw_event.get("lighting_minutes", 0),
                    camera_minutes=raw_event.get("camera_minutes", 0),
                    makeup_minutes=raw_event.get("makeup_minutes", 0),
                    wardrobe_minutes=raw_event.get("wardrobe_minutes", 0),
                    shooting_minutes=raw_event.get("shooting_minutes", 0),
                    reset_minutes=raw_event.get("reset_minutes", 0),
                    travel_minutes=raw_event.get("travel_minutes", 0),
                )
            )
    detect_conflicts(production)


def detect_conflicts(production: CineProduction) -> list[CineConflict]:
    db.session.execute(
        delete(CineConflict).where(
            CineConflict.production_id == production.id,
            CineConflict.resolved_at.is_(None),
        )
    )
    conflicts: list[CineConflict] = []
    days = db.session.execute(
        select(CineShootDay).where(CineShootDay.production_id == production.id)
    ).scalars()
    characters = {
        item.normalized_name: item
        for item in db.session.execute(
            select(CineCharacter).where(CineCharacter.production_id == production.id)
        ).scalars()
    }
    confirmed = {
        assignment.character_id: assignment
        for assignment in db.session.execute(
            select(CineCastAssignment).where(
                CineCastAssignment.production_id == production.id,
                CineCastAssignment.status == "confirmed",
            )
        ).scalars()
    }
    for day in days:
        previous_end: int | None = None
        ordered_events = sorted(
            day.events, key=lambda row: _clock_offset(row.starts_at, day.crew_call)
        )
        for event in ordered_events:
            starts_at = _clock_offset(event.starts_at, day.crew_call)
            ends_at = _clock_offset(event.ends_at, day.crew_call)
            if ends_at <= starts_at:
                ends_at += 24 * 60
            if previous_end is not None and starts_at < previous_end:
                conflicts.append(
                    _conflict(
                        production,
                        day,
                        event,
                        "schedule_overlap",
                        "critical",
                        f"{event.title} overlaps another event.",
                    )
                )
            previous_end = max(previous_end, ends_at) if previous_end else ends_at
            if event.scene_id is None:
                continue
            scene = db.session.get(CineScene, event.scene_id)
            if scene is None:
                continue
            for cast_name in scene.cast_json:
                character = characters.get(cast_name.strip().casefold())
                assignment = confirmed.get(character.id) if character else None
                if assignment is None:
                    conflicts.append(
                        _conflict(
                            production,
                            day,
                            event,
                            "missing_actor",
                            "high",
                            f"No actor is confirmed for {cast_name}.",
                        )
                    )
                    continue
                unavailable = db.session.execute(
                    select(CineActorAvailability.id).where(
                        CineActorAvailability.actor_id == assignment.actor_id,
                        CineActorAvailability.status == "unavailable",
                        CineActorAvailability.starts_on <= day.shoot_date,
                        CineActorAvailability.ends_on >= day.shoot_date,
                    )
                ).scalar_one_or_none()
                if unavailable is not None:
                    conflicts.append(
                        _conflict(
                            production,
                            day,
                            event,
                            "actor_unavailable",
                            "critical",
                            f"Actor for {cast_name} is unavailable on "
                            f"{day.shoot_date.isoformat()}.",
                        )
                    )
        duration = (
            datetime.combine(day.shoot_date, day.expected_wrap)
            - datetime.combine(day.shoot_date, day.crew_call)
        ).total_seconds() / 3600
        if duration < 0:
            duration += 24
        if duration > production.working_hours_limit:
            conflicts.append(
                _conflict(
                    production,
                    day,
                    None,
                    "excessive_work_hours",
                    "high",
                    f"Shoot day {day.shoot_day_number} runs {duration:.1f} hours.",
                )
            )
    db.session.add_all(conflicts)
    return conflicts


def _conflict(
    production: CineProduction,
    day: CineShootDay,
    event: CineScheduleEvent | None,
    kind: str,
    severity: str,
    message: str,
) -> CineConflict:
    return CineConflict(
        production_id=production.id,
        shoot_day_id=day.id,
        schedule_event_id=event.id if event else None,
        conflict_type=kind,
        severity=severity,
        message=message,
    )


def optimization_preview(production: CineProduction) -> dict[str, Any]:
    days = (
        db.session.execute(
            select(CineShootDay).where(CineShootDay.production_id == production.id)
        )
        .scalars()
        .all()
    )
    location_days: dict[str, set[date]] = defaultdict(set)
    for day in days:
        for event in day.events:
            if event.scene_id:
                scene = db.session.get(CineScene, event.scene_id)
                if scene:
                    location_days[scene.location_name].add(day.shoot_date)
    split_locations = {
        name: len(values) for name, values in location_days.items() if len(values) > 1
    }
    moves = sum(
        max(
            0,
            len({event.title for event in day.events if event.event_type == "travel"}),
        )
        for day in days
    )
    scenes = (
        db.session.execute(
            select(CineScene).where(CineScene.production_id == production.id)
        )
        .scalars()
        .all()
    )
    optimized = build_schedule_plan(production, scenes, "lowest_cost")
    current_cost = _estimate_plan_cost(production, len(days))
    return {
        "opportunities": [
            {
                "type": "location_consolidation",
                "message": f"Consolidate {name} from {count} shoot days.",
            }
            for name, count in split_locations.items()
        ],
        "current_shoot_days": len(days),
        "optimized_shoot_days": optimized["shoot_days"],
        "current_location_moves": moves,
        "optimized_location_moves": optimized["location_moves"],
        "estimated_savings_minor": max(
            0, current_cost - optimized["estimated_cost_minor"]
        ),
        "plan": optimized,
    }


def day_out_of_days(production: CineProduction) -> list[dict[str, Any]]:
    appearances: dict[str, list[date]] = defaultdict(list)
    character_names: dict[str, str] = {}
    characters = {
        item.id: item
        for item in db.session.execute(
            select(CineCharacter).where(CineCharacter.production_id == production.id)
        ).scalars()
    }
    assignments = db.session.execute(
        select(CineCastAssignment).where(
            CineCastAssignment.production_id == production.id,
            CineCastAssignment.status == "confirmed",
        )
    ).scalars()
    for assignment in assignments:
        character = characters.get(assignment.character_id)
        if character:
            character_names[character.normalized_name] = character.name
    for day in db.session.execute(
        select(CineShootDay).where(CineShootDay.production_id == production.id)
    ).scalars():
        names: set[str] = set()
        for event in day.events:
            if event.scene_id:
                scene = db.session.get(CineScene, event.scene_id)
                if scene:
                    names.update(name.casefold() for name in scene.cast_json)
        for name in names:
            appearances[name].append(day.shoot_date)
    report = []
    for normalized_name, dates in appearances.items():
        ordered = sorted(set(dates))
        span = (ordered[-1] - ordered[0]).days + 1
        report.append(
            {
                "character": character_names.get(
                    normalized_name, normalized_name.title()
                ),
                "first_work": ordered[0].isoformat(),
                "last_work": ordered[-1].isoformat(),
                "work_days": len(ordered),
                "hold_days": max(0, span - len(ordered)),
                "dates": [value.isoformat() for value in ordered],
            }
        )
    return sorted(report, key=lambda item: item["character"])
