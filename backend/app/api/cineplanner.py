from __future__ import annotations

import csv
import html
import io
import json
from collections.abc import Callable
from datetime import date, time
from typing import Any

from celery import Celery
from flask import Blueprint, Response, current_app, jsonify, send_file
from flask.typing import ResponseReturnValue
from openpyxl import Workbook
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from sqlalchemy import func, or_, select

from app.api.auth import _current_user, _json_body
from app.errors import APIError
from app.extensions import db, limiter
from app.models.base import utc_now
from app.models.cineplanner import (
    CineActor,
    CineActorAvailability,
    CineAIJob,
    CineAuditLog,
    CineBudgetLine,
    CineCallSheet,
    CineCastAssignment,
    CineCharacter,
    CineConflict,
    CineCrewMember,
    CineElement,
    CineLocation,
    CineProduction,
    CineProductionRole,
    CineScene,
    CineScheduleEvent,
    CineScriptVersion,
    CineShootDay,
)
from app.models.files import FileAsset
from app.models.identity import User
from app.models.projects import Project, ProjectFile, ProjectMember
from app.responses import success
from app.services.cineplanner_budget import recalculate_budget
from app.services.cineplanner_productions import sync_cineplanner_projects
from app.services.cineplanner_scheduling import (
    apply_schedule_plan,
    build_schedule_plan,
    day_out_of_days,
    detect_conflicts,
    optimization_preview,
)

cineplanner_blueprint = Blueprint("cineplanner", __name__, url_prefix="/cineplanner")

PRODUCTION_ROLE_PERMISSIONS: dict[str, set[str]] = {
    "admin": {"*"},
    "producer": {
        "edit",
        "finance",
        "schedule",
        "cast",
        "approve",
        "manage_team",
        "locations",
        "elements",
    },
    "director": {"edit", "schedule", "cast", "approve", "locations", "elements"},
    "first_ad": {"edit", "schedule", "approve"},
    "line_producer": {
        "edit",
        "finance",
        "schedule",
        "approve",
        "locations",
        "elements",
    },
    "casting_director": {"cast", "edit"},
    "location_manager": {"locations", "edit"},
    "department_head": {"elements", "edit"},
    "crew": {"view"},
    "view_only": {"view"},
}
EDITABLE_RESOURCES: dict[str, tuple[type[Any], set[str]]] = {
    "scenes": (
        CineScene,
        {
            "slugline",
            "int_ext",
            "location_name",
            "time_of_day",
            "story_day",
            "page_length_eighths",
            "estimated_screen_seconds",
            "summary",
            "cast_json",
            "extras_json",
            "props_json",
            "wardrobe_json",
            "makeup_json",
            "vehicles_json",
            "weapons_json",
            "animals_json",
            "stunts_json",
            "vfx_json",
            "sfx_json",
            "equipment_json",
            "sound_requirements",
            "production_notes",
            "safety_notes",
            "continuity_notes",
            "complexity",
            "review_status",
        },
    ),
    "characters": (
        CineCharacter,
        {
            "name",
            "classification",
            "description",
            "playing_age",
            "languages_json",
            "skills_json",
            "scene_numbers_json",
            "story_days_json",
            "estimated_shoot_days",
            "review_status",
        },
    ),
    "locations": (
        CineLocation,
        {
            "option_name",
            "address",
            "contact_name",
            "contact_phone",
            "rental_rate_minor",
            "availability_json",
            "parking",
            "electricity",
            "bathrooms",
            "holding_area",
            "noise_restrictions",
            "permit_requirements",
            "notes",
            "status",
        },
    ),
    "elements": (
        CineElement,
        {
            "name",
            "description",
            "scene_numbers_json",
            "quantity",
            "cost_rate_minor",
            "rate_basis",
            "availability_json",
            "owner_vendor",
            "status",
            "continuity_notes",
            "notes",
            "review_status",
        },
    ),
}


def _field_error(field: str, message: str) -> APIError:
    return APIError(
        "validation.invalid",
        "Request validation failed.",
        status=422,
        fields={field: [message]},
    )


def _has_platform_role(user: User, *codes: str) -> bool:
    return any(
        role.status == "active" and role.role.code in codes for role in user.roles
    )


def _production_for_user(public_id: str, user: User) -> CineProduction:
    production = (
        db.session.execute(
            select(CineProduction)
            .outerjoin(
                CineProductionRole,
                CineProductionRole.production_id == CineProduction.id,
            )
            .outerjoin(Project, Project.id == CineProduction.project_id)
            .outerjoin(ProjectMember, ProjectMember.project_id == Project.id)
            .where(
                CineProduction.public_id == public_id,
                or_(
                    CineProduction.owner_user_id == user.id,
                    (CineProductionRole.user_id == user.id)
                    & (CineProductionRole.status == "active"),
                    (ProjectMember.user_id == user.id)
                    & (ProjectMember.status == "active"),
                ),
            )
        )
        .unique()
        .scalar_one_or_none()
    )
    if production is None:
        raise APIError(
            "cineplanner.production_not_found",
            "CinePlanner production was not found.",
            status=404,
        )
    return production


def _permission_set(production: CineProduction, user: User) -> set[str]:
    if production.owner_user_id == user.id or _has_platform_role(user, "super_admin"):
        return {"*"}
    role = db.session.execute(
        select(CineProductionRole).where(
            CineProductionRole.production_id == production.id,
            CineProductionRole.user_id == user.id,
            CineProductionRole.status == "active",
        )
    ).scalar_one_or_none()
    if role is None:
        return {"view"}
    return PRODUCTION_ROLE_PERMISSIONS.get(role.role_code, {"view"}) | set(
        role.permissions_json
    )


def _require_permission(
    production: CineProduction, user: User, permission: str
) -> None:
    permissions = _permission_set(production, user)
    if "*" not in permissions and permission not in permissions:
        raise APIError(
            "cineplanner.permission_denied",
            "You do not have permission for this CinePlanner action.",
            status=403,
        )


def _latest_script(production: CineProduction) -> CineScriptVersion | None:
    return db.session.execute(
        select(CineScriptVersion)
        .where(CineScriptVersion.production_id == production.id)
        .order_by(CineScriptVersion.version_number.desc())
        .limit(1)
    ).scalar_one_or_none()


def _audit(
    production: CineProduction,
    user: User | None,
    action: str,
    entity_type: str,
    entity_public_id: str | None,
    old_value: Any,
    new_value: Any,
) -> None:
    db.session.add(
        CineAuditLog(
            production_id=production.id,
            actor_user_id=user.id if user else None,
            action=action,
            entity_type=entity_type,
            entity_public_id=entity_public_id,
            old_value_json=_json_safe(old_value),
            new_value_json=_json_safe(new_value),
        )
    )


def _json_safe(value: Any) -> Any:
    if value is None or isinstance(value, (str, int, float, bool, list, dict)):
        return value
    if isinstance(value, (date, time)):
        return value.isoformat()
    return str(value)


def _production_payload(item: CineProduction) -> dict[str, Any]:
    latest = _latest_script(item)
    project = db.session.get(Project, item.project_id) if item.project_id else None
    return {
        "public_id": item.public_id,
        "project_id": project.public_id if project else None,
        "title": item.title,
        "status": item.status,
        "currency": item.currency,
        "production_start_date": item.production_start_date.isoformat()
        if item.production_start_date
        else None,
        "maximum_shoot_days": item.maximum_shoot_days,
        "working_hours_limit": item.working_hours_limit,
        "budget_ceiling_minor": item.budget_ceiling_minor,
        "schedule_locked": item.schedule_locked_at is not None,
        "settings": item.settings_json,
        "latest_script": _script_payload(latest) if latest else None,
        "created_at": item.created_at.isoformat(),
        "updated_at": item.updated_at.isoformat(),
    }


def _script_payload(item: CineScriptVersion) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "version_number": item.version_number,
        "label": item.label,
        "screenplay_title": item.screenplay_title,
        "author": item.author,
        "revision": item.revision,
        "total_pages": item.total_pages,
        "analysis_status": item.analysis_status,
        "approved_at": item.approved_at.isoformat() if item.approved_at else None,
        "created_at": item.created_at.isoformat(),
    }


def _job_payload(item: CineAIJob) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "status": item.status,
        "current_stage": item.current_stage,
        "progress_percent": item.progress_percent,
        "completed_stages": item.completed_stages_json,
        "attempt_count": item.attempt_count,
        "error": {"code": item.error_code, "message": item.error_message}
        if item.error_code
        else None,
        "created_at": item.created_at.isoformat(),
        "completed_at": item.completed_at.isoformat() if item.completed_at else None,
    }


def _scene_payload(item: CineScene) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "scene_number": item.scene_number,
        "sort_order": item.sort_order,
        "slugline": item.slugline,
        "int_ext": item.int_ext,
        "location": item.location_name,
        "time_of_day": item.time_of_day,
        "story_day": item.story_day,
        "page_length_eighths": item.page_length_eighths,
        "estimated_screen_seconds": item.estimated_screen_seconds,
        "summary": item.summary,
        "cast": item.cast_json,
        "extras": item.extras_json,
        "props": item.props_json,
        "wardrobe": item.wardrobe_json,
        "makeup": item.makeup_json,
        "vehicles": item.vehicles_json,
        "weapons": item.weapons_json,
        "animals": item.animals_json,
        "stunts": item.stunts_json,
        "vfx": item.vfx_json,
        "sfx": item.sfx_json,
        "equipment": item.equipment_json,
        "sound_requirements": item.sound_requirements,
        "production_notes": item.production_notes,
        "safety_notes": item.safety_notes,
        "continuity_notes": item.continuity_notes,
        "complexity": item.complexity,
        "ai_confidence": item.ai_confidence,
        "review_status": item.review_status,
    }


def _character_payload(item: CineCharacter) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "classification": item.classification,
        "description": item.description,
        "playing_age": item.playing_age,
        "languages": item.languages_json,
        "skills": item.skills_json,
        "scenes": item.scene_numbers_json,
        "dialogue_count": item.dialogue_count,
        "page_count_eighths": item.page_count_eighths,
        "estimated_screen_seconds": item.estimated_screen_seconds,
        "first_appearance": item.first_appearance,
        "last_appearance": item.last_appearance,
        "story_days": item.story_days_json,
        "estimated_shoot_days": item.estimated_shoot_days,
        "ai_confidence": item.ai_confidence,
        "review_status": item.review_status,
    }


def _element_payload(item: CineElement) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "category": item.category,
        "name": item.name,
        "description": item.description,
        "scene_numbers": item.scene_numbers_json,
        "quantity": item.quantity,
        "cost_rate_minor": item.cost_rate_minor,
        "rate_basis": item.rate_basis,
        "availability": item.availability_json,
        "owner_vendor": item.owner_vendor,
        "status": item.status,
        "continuity_notes": item.continuity_notes,
        "photos": item.photo_file_ids_json,
        "notes": item.notes,
        "ai_confidence": item.ai_confidence,
        "review_status": item.review_status,
    }


def _location_payload(item: CineLocation) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "screenplay_name": item.screenplay_name,
        "option_name": item.option_name,
        "address": item.address,
        "photos": item.photo_file_ids_json,
        "contact_name": item.contact_name,
        "contact_phone": item.contact_phone,
        "rental_rate_minor": item.rental_rate_minor,
        "currency": item.currency,
        "availability": item.availability_json,
        "parking": item.parking,
        "electricity": item.electricity,
        "bathrooms": item.bathrooms,
        "holding_area": item.holding_area,
        "noise_restrictions": item.noise_restrictions,
        "permit_requirements": item.permit_requirements,
        "notes": item.notes,
        "status": item.status,
        "ai_confidence": item.ai_confidence,
    }


def _actor_payload(item: CineActor) -> dict[str, Any]:
    availability = db.session.execute(
        select(CineActorAvailability)
        .where(CineActorAvailability.actor_id == item.id)
        .order_by(CineActorAvailability.starts_on)
    ).scalars()
    photo = (
        db.session.get(FileAsset, item.photo_file_id) if item.photo_file_id else None
    )
    return {
        "public_id": item.public_id,
        "name": item.name,
        "photo_file_id": photo.public_id if photo else None,
        "playing_age_min": item.playing_age_min,
        "playing_age_max": item.playing_age_max,
        "gender": item.gender,
        "languages": item.languages_json,
        "skills": item.skills_json,
        "city": item.city,
        "agency": item.agency,
        "manager": item.manager,
        "phone": item.phone,
        "email": item.email,
        "daily_rate_minor": item.daily_rate_minor,
        "project_rate_minor": item.project_rate_minor,
        "currency": item.currency,
        "notes": item.notes,
        "availability": [
            {
                "starts_on": row.starts_on.isoformat(),
                "ends_on": row.ends_on.isoformat(),
                "status": row.status,
                "notes": row.notes,
            }
            for row in availability
        ],
    }


def _assignment_payload(item: CineCastAssignment) -> dict[str, Any]:
    character = db.session.get(CineCharacter, item.character_id)
    actor = db.session.get(CineActor, item.actor_id)
    return {
        "public_id": item.public_id,
        "character": _character_payload(character) if character else None,
        "actor": _actor_payload(actor) if actor else None,
        "status": item.status,
        "fit_score": item.fit_score,
        "fit_breakdown": item.fit_breakdown_json,
        "preference_notes": item.preference_notes,
    }


def _crew_payload(item: CineCrewMember) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "department": item.department,
        "job_title": item.job_title,
        "phone": item.phone,
        "email": item.email,
        "daily_rate_minor": item.daily_rate_minor,
        "availability": item.availability_json,
        "status": item.status,
    }


def _event_payload(item: CineScheduleEvent) -> dict[str, Any]:
    scene = db.session.get(CineScene, item.scene_id) if item.scene_id else None
    return {
        "public_id": item.public_id,
        "event_type": item.event_type,
        "title": item.title,
        "starts_at": item.starts_at.strftime("%H:%M"),
        "ends_at": item.ends_at.strftime("%H:%M"),
        "scene": _scene_payload(scene) if scene else None,
        "setup_minutes": item.setup_minutes,
        "rehearsal_minutes": item.rehearsal_minutes,
        "lighting_minutes": item.lighting_minutes,
        "camera_minutes": item.camera_minutes,
        "makeup_minutes": item.makeup_minutes,
        "wardrobe_minutes": item.wardrobe_minutes,
        "shooting_minutes": item.shooting_minutes,
        "reset_minutes": item.reset_minutes,
        "travel_minutes": item.travel_minutes,
        "notes": item.notes,
    }


def _event_clock_offset(value: time, crew_call: time) -> int:
    minutes = value.hour * 60 + value.minute
    crew_minutes = crew_call.hour * 60 + crew_call.minute
    return minutes + (24 * 60 if minutes < crew_minutes else 0)


def _shoot_day_payload(item: CineShootDay) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "shoot_day_number": item.shoot_day_number,
        "shoot_date": item.shoot_date.isoformat(),
        "crew_call": item.crew_call.strftime("%H:%M"),
        "expected_wrap": item.expected_wrap.strftime("%H:%M"),
        "location_name": item.location_name,
        "status": item.status,
        "locked": item.locked_at is not None,
        "events": [
            _event_payload(event)
            for event in sorted(
                item.events,
                key=lambda row: _event_clock_offset(row.starts_at, item.crew_call),
            )
        ],
    }


def _conflict_payload(item: CineConflict) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "type": item.conflict_type,
        "severity": item.severity,
        "message": item.message,
        "metadata": item.metadata_json,
        "resolved_at": item.resolved_at.isoformat() if item.resolved_at else None,
    }


def _budget_line_payload(item: CineBudgetLine) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "category": item.category,
        "description": item.description,
        "estimated_minor": item.estimated_minor,
        "quoted_minor": item.quoted_minor,
        "approved_minor": item.approved_minor,
        "committed_minor": item.committed_minor,
        "paid_minor": item.paid_minor,
        "status": item.status,
        "notes": item.notes,
        "automatic": item.source_type is not None,
    }


@cineplanner_blueprint.get("/productions")
def productions_index() -> Response:
    user = _current_user()
    if _has_platform_role(
        user, "director_producer", "super_admin"
    ) and sync_cineplanner_projects(user.id):
        db.session.commit()
    rows = (
        db.session.execute(
            select(CineProduction)
            .outerjoin(
                CineProductionRole,
                CineProductionRole.production_id == CineProduction.id,
            )
            .outerjoin(Project, Project.id == CineProduction.project_id)
            .outerjoin(ProjectMember, ProjectMember.project_id == Project.id)
            .where(
                CineProduction.deleted_at.is_(None),
                or_(
                    CineProduction.owner_user_id == user.id,
                    (CineProductionRole.user_id == user.id)
                    & (CineProductionRole.status == "active"),
                    (ProjectMember.user_id == user.id)
                    & (ProjectMember.status == "active"),
                ),
            )
            .order_by(CineProduction.updated_at.desc())
        )
        .unique()
        .scalars()
    )
    return jsonify(success({"productions": [_production_payload(row) for row in rows]}))


@cineplanner_blueprint.post("/productions")
@limiter.limit("30 per hour")
def productions_create() -> ResponseReturnValue:
    user = _current_user()
    if not _has_platform_role(user, "director_producer", "super_admin"):
        raise APIError(
            "cineplanner.role_required",
            "A Director or Producer account is required for CinePlanner.",
            status=403,
        )
    payload = _json_body()
    title = str(payload.get("title", "")).strip()
    if len(title) < 2:
        raise _field_error(
            "title", "Production title must contain at least 2 characters."
        )
    project: Project | None = None
    project_public_id = str(payload.get("project_id", "")).strip()
    if project_public_id:
        project = db.session.execute(
            select(Project)
            .join(ProjectMember, ProjectMember.project_id == Project.id)
            .where(
                Project.public_id == project_public_id,
                ProjectMember.user_id == user.id,
                ProjectMember.status == "active",
            )
        ).scalar_one_or_none()
        if project is None:
            raise _field_error("project_id", "Select a project you can access.")
        existing = db.session.execute(
            select(CineProduction).where(CineProduction.project_id == project.id)
        ).scalar_one_or_none()
        if existing is not None:
            return jsonify(success({"production": _production_payload(existing)}))
    start_raw = str(payload.get("production_start_date", "")).strip()
    try:
        start_date = date.fromisoformat(start_raw) if start_raw else None
    except ValueError as exc:
        raise _field_error("production_start_date", "Use YYYY-MM-DD.") from exc
    production = CineProduction(
        owner_user_id=user.id,
        project_id=project.id if project else None,
        title=title[:180],
        status="setup",
        currency=str(payload.get("currency", "PKR"))[:3].upper(),
        production_start_date=start_date,
        maximum_shoot_days=max(
            1, min(365, int(payload.get("maximum_shoot_days", 30) or 30))
        ),
        working_hours_limit=max(
            6, min(18, int(payload.get("working_hours_limit", 12) or 12))
        ),
        budget_ceiling_minor=_optional_int(payload.get("budget_ceiling_minor")),
        settings_json=payload.get("settings")
        if isinstance(payload.get("settings"), dict)
        else {},
    )
    db.session.add(production)
    db.session.flush()
    db.session.add(
        CineProductionRole(
            production_id=production.id,
            user_id=user.id,
            role_code="producer",
            permissions_json=[
                "edit",
                "finance",
                "schedule",
                "cast",
                "approve",
                "manage_team",
            ],
        )
    )
    _audit(
        production,
        user,
        "production_created",
        "production",
        production.public_id,
        None,
        {"title": production.title},
    )
    db.session.commit()
    return jsonify(success({"production": _production_payload(production)})), 201


@cineplanner_blueprint.get("/productions/<public_id>")
def production_show(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    snapshot = _production_snapshot(production, user)
    db.session.commit()
    return jsonify(success(snapshot))


@cineplanner_blueprint.patch("/productions/<public_id>")
def production_update(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "edit")
    payload = _json_body()
    allowed = {
        "title",
        "status",
        "currency",
        "production_start_date",
        "maximum_shoot_days",
        "working_hours_limit",
        "budget_ceiling_minor",
        "settings_json",
    }
    old = {key: _json_safe(getattr(production, key)) for key in allowed}
    for key, value in payload.items():
        if key not in allowed:
            continue
        if key == "production_start_date":
            value = date.fromisoformat(str(value)) if value else None
        elif key in {
            "maximum_shoot_days",
            "working_hours_limit",
            "budget_ceiling_minor",
        }:
            value = _optional_int(value)
        setattr(production, key, value)
    new = {key: _json_safe(getattr(production, key)) for key in allowed}
    _audit(
        production,
        user,
        "production_updated",
        "production",
        production.public_id,
        old,
        new,
    )
    db.session.commit()
    return jsonify(success({"production": _production_payload(production)}))


@cineplanner_blueprint.post("/productions/<public_id>/scripts")
@limiter.limit("12 per hour")
def script_create(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "edit")
    payload = _json_body()
    file_public_id = str(payload.get("file_id", "")).strip()
    file = db.session.execute(
        select(FileAsset).where(
            FileAsset.public_id == file_public_id,
            FileAsset.owner_user_id == user.id,
            FileAsset.mime_type == "application/pdf",
            FileAsset.scan_status == "clean",
            FileAsset.processing_status == "ready",
        )
    ).scalar_one_or_none()
    if file is None:
        raise _field_error("file_id", "Select a ready, privately uploaded PDF.")
    latest_number = (
        db.session.execute(
            select(func.max(CineScriptVersion.version_number)).where(
                CineScriptVersion.production_id == production.id
            )
        ).scalar_one()
        or 0
    )
    script = CineScriptVersion(
        production_id=production.id,
        file_id=file.id,
        uploaded_by_user_id=user.id,
        version_number=latest_number + 1,
        label=str(payload.get("label", f"Draft {latest_number + 1}"))[:120],
        analysis_status="queued",
    )
    db.session.add(script)
    db.session.flush()
    job = CineAIJob(
        production_id=production.id,
        script_version_id=script.id,
        requested_by_user_id=user.id,
        status="queued",
        current_stage="file_uploaded",
        progress_percent=2,
    )
    db.session.add(job)
    if production.project_id is not None:
        linked_file = db.session.execute(
            select(ProjectFile).where(
                ProjectFile.project_id == production.project_id,
                ProjectFile.file_id == file.id,
            )
        ).scalar_one_or_none()
        if linked_file is None:
            db.session.add(
                ProjectFile(
                    project_id=production.project_id,
                    file_id=file.id,
                    uploaded_by=user.id,
                    folder="scripts",
                    label=script.label,
                    visibility="project_members",
                    sort_order=script.version_number * 10,
                )
            )
        else:
            linked_file.folder = "scripts"
            linked_file.label = script.label
    production.status = "processing"
    _audit(
        production,
        user,
        "screenplay_revision_uploaded",
        "script_version",
        script.public_id,
        None,
        {"version": script.version_number, "file_id": file.public_id},
    )
    db.session.commit()
    _enqueue_analysis(job.public_id)
    return jsonify(
        success({"script": _script_payload(script), "job": _job_payload(job)})
    ), 202


def _enqueue_analysis(job_public_id: str) -> None:
    celery_client = Celery("cineconnect-api")
    celery_client.conf.broker_url = current_app.config["CELERY_BROKER_URL"]
    try:
        celery_client.send_task(
            "app.tasks.cineplanner.analyze_screenplay", args=[job_public_id]
        )
    except Exception:
        current_app.logger.exception(
            "cineplanner_enqueue_failed", extra={"job_public_id": job_public_id}
        )


@cineplanner_blueprint.get("/productions/<public_id>/jobs/<job_public_id>")
def job_show(public_id: str, job_public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    job = db.session.execute(
        select(CineAIJob).where(
            CineAIJob.public_id == job_public_id,
            CineAIJob.production_id == production.id,
        )
    ).scalar_one_or_none()
    if job is None:
        raise APIError("cineplanner.job_not_found", "AI job was not found.", status=404)
    return jsonify(success({"job": _job_payload(job)}))


@cineplanner_blueprint.post("/productions/<public_id>/jobs/<job_public_id>/retry")
def job_retry(public_id: str, job_public_id: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "edit")
    job = db.session.execute(
        select(CineAIJob).where(
            CineAIJob.public_id == job_public_id,
            CineAIJob.production_id == production.id,
        )
    ).scalar_one_or_none()
    if job is None:
        raise APIError("cineplanner.job_not_found", "AI job was not found.", status=404)
    if job.status not in {"failed", "queued"}:
        raise APIError(
            "cineplanner.job_not_retryable",
            "Only failed or queued jobs can be retried.",
            status=409,
        )
    job.status = "queued"
    job.error_code = None
    job.error_message = None
    db.session.commit()
    _enqueue_analysis(job.public_id)
    return jsonify(success({"job": _job_payload(job)})), 202


@cineplanner_blueprint.post("/productions/<public_id>/approve-breakdown")
def approve_breakdown(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "approve")
    script = _latest_script(production)
    if script is None or script.analysis_status not in {"review", "approved"}:
        raise APIError(
            "cineplanner.breakdown_not_ready",
            "The breakdown is not ready for approval.",
            status=409,
        )
    for model in (CineScene, CineCharacter, CineElement):
        rows = db.session.execute(
            select(model).where(model.script_version_id == script.id)
        ).scalars()
        for row in rows:
            editable_row: Any = row
            editable_row.review_status = "approved"
    script.analysis_status = "approved"
    script.approved_at = utc_now()
    script.approved_by_user_id = user.id
    production.status = "active"
    _audit(
        production,
        user,
        "breakdown_approved",
        "script_version",
        script.public_id,
        {"status": "review"},
        {"status": "approved"},
    )
    db.session.commit()
    return jsonify(success({"script": _script_payload(script)}))


@cineplanner_blueprint.patch("/productions/<public_id>/<resource>/<entity_public_id>")
def resource_update(public_id: str, resource: str, entity_public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "edit")
    config = EDITABLE_RESOURCES.get(resource)
    if config is None:
        raise APIError(
            "cineplanner.resource_not_found", "Resource was not found.", status=404
        )
    model, allowed = config
    entity = db.session.execute(
        select(model).where(
            model.public_id == entity_public_id, model.production_id == production.id
        )
    ).scalar_one_or_none()
    if entity is None:
        raise APIError(
            "cineplanner.item_not_found", "Production item was not found.", status=404
        )
    payload = _json_body()
    old: dict[str, Any] = {}
    new: dict[str, Any] = {}
    for key, value in payload.items():
        internal_key = _resource_key(resource, key)
        if internal_key not in allowed:
            continue
        old[internal_key] = _json_safe(getattr(entity, internal_key))
        setattr(entity, internal_key, value)
        new[internal_key] = _json_safe(value)
    if resource == "characters" and "name" in new:
        entity.normalized_name = str(entity.name).casefold()
    if resource == "locations" and new.get("status") == "confirmed":
        confirmed_location: CineLocation = entity
        other_options = db.session.execute(
            select(CineLocation).where(
                CineLocation.production_id == production.id,
                CineLocation.script_version_id == confirmed_location.script_version_id,
                CineLocation.screenplay_name == confirmed_location.screenplay_name,
                CineLocation.id != confirmed_location.id,
                CineLocation.status == "confirmed",
            )
        ).scalars()
        for other in other_options:
            other.status = "option"
    action = {
        "scenes": "scene_changed",
        "characters": "character_changed",
        "locations": "location_changed",
        "elements": "production_element_changed",
    }[resource]
    _audit(production, user, action, resource[:-1], entity.public_id, old, new)
    if resource in {"locations", "elements"}:
        recalculate_budget(production)
    db.session.commit()
    serializers: dict[str, Callable[[Any], dict[str, Any]]] = {
        "scenes": lambda item: _scene_payload(item),
        "characters": lambda item: _character_payload(item),
        "locations": lambda item: _location_payload(item),
        "elements": lambda item: _element_payload(item),
    }
    serializer = serializers[resource]
    return jsonify(success({"item": serializer(entity)}))


@cineplanner_blueprint.post("/productions/<public_id>/locations")
def location_create(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "locations")
    script = _latest_script(production)
    if script is None:
        raise APIError(
            "cineplanner.script_required",
            "Upload a screenplay before adding location options.",
            status=409,
        )
    payload = _json_body()
    screenplay_name = str(payload.get("screenplay_name", "")).strip()
    option_name = str(payload.get("option_name", "")).strip()
    if not screenplay_name or not option_name:
        raise _field_error(
            "option_name", "Screenplay location and option name are required."
        )
    location = CineLocation(
        production_id=production.id,
        script_version_id=script.id,
        screenplay_name=screenplay_name[:180],
        option_name=option_name[:180],
        address=_optional_text(payload.get("address"), 500),
        contact_name=_optional_text(payload.get("contact_name"), 180),
        contact_phone=_optional_text(payload.get("contact_phone"), 64),
        rental_rate_minor=_optional_int(payload.get("rental_rate_minor")),
        currency=production.currency,
        availability_json=(
            payload["availability"]
            if isinstance(payload.get("availability"), list)
            else []
        ),
        parking=_optional_text(payload.get("parking"), 5000),
        electricity=_optional_text(payload.get("electricity"), 5000),
        bathrooms=_optional_text(payload.get("bathrooms"), 5000),
        holding_area=_optional_text(payload.get("holding_area"), 5000),
        noise_restrictions=_optional_text(payload.get("noise_restrictions"), 5000),
        permit_requirements=_optional_text(payload.get("permit_requirements"), 5000),
        notes=_optional_text(payload.get("notes"), 5000),
        status=str(payload.get("status", "option"))[:24],
        ai_confidence=100,
    )
    db.session.add(location)
    db.session.flush()
    _audit(
        production,
        user,
        "location_option_created",
        "location",
        location.public_id,
        None,
        {"option_name": option_name},
    )
    recalculate_budget(production)
    db.session.commit()
    return jsonify(success({"location": _location_payload(location)})), 201


@cineplanner_blueprint.post("/productions/<public_id>/elements")
def element_create(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "elements")
    script = _latest_script(production)
    if script is None:
        raise APIError(
            "cineplanner.script_required",
            "Upload a screenplay before adding production elements.",
            status=409,
        )
    payload = _json_body()
    category = str(payload.get("category", "")).strip().lower()
    name = str(payload.get("name", "")).strip()
    supported = {
        "props",
        "wardrobe",
        "makeup",
        "vehicles",
        "extras",
        "stunts",
        "vfx",
        "sfx",
        "equipment",
    }
    if category not in supported or not name:
        raise _field_error("category", "Select a supported category and enter a name.")
    element = CineElement(
        production_id=production.id,
        script_version_id=script.id,
        category=category,
        name=name[:180],
        normalized_name=name.casefold()[:180],
        description=_optional_text(payload.get("description"), 5000),
        scene_numbers_json=_string_list(payload.get("scene_numbers")),
        quantity=max(1, _optional_int(payload.get("quantity")) or 1),
        cost_rate_minor=_optional_int(payload.get("cost_rate_minor")),
        rate_basis=str(payload.get("rate_basis", "flat"))[:24],
        owner_vendor=_optional_text(payload.get("owner_vendor"), 180),
        status=str(payload.get("status", "required"))[:24],
        continuity_notes=_optional_text(payload.get("continuity_notes"), 5000),
        notes=_optional_text(payload.get("notes"), 5000),
        ai_confidence=100,
        review_status="manual",
    )
    db.session.add(element)
    db.session.flush()
    _audit(
        production,
        user,
        "production_element_created",
        "element",
        element.public_id,
        None,
        {"category": category, "name": name},
    )
    recalculate_budget(production)
    db.session.commit()
    return jsonify(success({"element": _element_payload(element)})), 201


@cineplanner_blueprint.post("/productions/<public_id>/crew")
def crew_create(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "edit")
    payload = _json_body()
    name = str(payload.get("name", "")).strip()
    department = str(payload.get("department", "")).strip()
    job_title = str(payload.get("job_title", "")).strip()
    if not name or not department or not job_title:
        raise _field_error("name", "Name, department, and job title are required.")
    member = CineCrewMember(
        production_id=production.id,
        name=name[:180],
        department=department[:120],
        job_title=job_title[:120],
        phone=_optional_text(payload.get("phone"), 64),
        email=_optional_text(payload.get("email"), 320),
        daily_rate_minor=_optional_int(payload.get("daily_rate_minor")),
        availability_json=(
            payload["availability"]
            if isinstance(payload.get("availability"), list)
            else []
        ),
        status=str(payload.get("status", "proposed"))[:24],
    )
    db.session.add(member)
    db.session.flush()
    _audit(
        production,
        user,
        "crew_member_created",
        "crew_member",
        member.public_id,
        None,
        {"name": name, "job_title": job_title},
    )
    recalculate_budget(production)
    db.session.commit()
    return jsonify(success({"crew_member": _crew_payload(member)})), 201


@cineplanner_blueprint.post("/productions/<public_id>/team")
def production_team_upsert(public_id: str) -> ResponseReturnValue:
    actor = _current_user()
    production = _production_for_user(public_id, actor)
    _require_permission(production, actor, "manage_team")
    payload = _json_body()
    user = db.session.execute(
        select(User).where(User.public_id == str(payload.get("user_id", "")))
    ).scalar_one_or_none()
    role_code = str(payload.get("role", "")).strip().lower()
    if user is None or role_code not in PRODUCTION_ROLE_PERMISSIONS:
        raise _field_error("role", "Select a valid user and production role.")
    role = db.session.execute(
        select(CineProductionRole).where(
            CineProductionRole.production_id == production.id,
            CineProductionRole.user_id == user.id,
        )
    ).scalar_one_or_none()
    if role is None:
        role = CineProductionRole(
            production_id=production.id,
            user_id=user.id,
            role_code=role_code,
        )
        db.session.add(role)
    role.role_code = role_code
    role.permissions_json = _string_list(payload.get("permissions"))
    role.status = "active"
    _audit(
        production,
        actor,
        "team_role_changed",
        "production_role",
        user.public_id,
        None,
        {"role": role_code},
    )
    db.session.commit()
    return jsonify(
        success(
            {
                "team_member": {
                    "user_id": user.public_id,
                    "name": user.display_name,
                    "role": role.role_code,
                    "permissions": role.permissions_json,
                }
            }
        )
    ), 201


def _resource_key(resource: str, key: str) -> str:
    aliases = {
        "location": "location_name",
        "cast": "cast_json",
        "extras": "extras_json",
        "props": "props_json",
        "wardrobe": "wardrobe_json",
        "makeup": "makeup_json",
        "vehicles": "vehicles_json",
        "weapons": "weapons_json",
        "animals": "animals_json",
        "stunts": "stunts_json",
        "vfx": "vfx_json",
        "sfx": "sfx_json",
        "equipment": "equipment_json",
        "languages": "languages_json",
        "skills": "skills_json",
        "scenes": "scene_numbers_json",
        "story_days": "story_days_json",
        "scene_numbers": "scene_numbers_json",
        "availability": "availability_json",
    }
    return aliases.get(key, key)


@cineplanner_blueprint.get("/actors")
def actors_index() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(CineActor)
        .where(CineActor.owner_user_id == user.id)
        .order_by(CineActor.name)
    ).scalars()
    return jsonify(success({"actors": [_actor_payload(row) for row in rows]}))


@cineplanner_blueprint.post("/actors")
def actors_create() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    name = str(payload.get("name", "")).strip()
    if len(name) < 2:
        raise _field_error("name", "Actor name must contain at least 2 characters.")
    actor = CineActor(
        owner_user_id=user.id,
        name=name[:180],
        playing_age_min=_optional_int(payload.get("playing_age_min")),
        playing_age_max=_optional_int(payload.get("playing_age_max")),
        gender=_optional_text(payload.get("gender"), 64),
        languages_json=_string_list(payload.get("languages")),
        skills_json=_string_list(payload.get("skills")),
        city=_optional_text(payload.get("city"), 120),
        agency=_optional_text(payload.get("agency"), 180),
        manager=_optional_text(payload.get("manager"), 180),
        phone=_optional_text(payload.get("phone"), 64),
        email=_optional_text(payload.get("email"), 320),
        daily_rate_minor=_optional_int(payload.get("daily_rate_minor")),
        project_rate_minor=_optional_int(payload.get("project_rate_minor")),
        currency=str(payload.get("currency", "PKR"))[:3].upper(),
        notes=_optional_text(payload.get("notes"), 5000),
    )
    db.session.add(actor)
    db.session.commit()
    return jsonify(success({"actor": _actor_payload(actor)})), 201


@cineplanner_blueprint.post("/actors/<actor_public_id>/availability")
def actor_availability_create(actor_public_id: str) -> ResponseReturnValue:
    user = _current_user()
    actor = db.session.execute(
        select(CineActor).where(
            CineActor.public_id == actor_public_id, CineActor.owner_user_id == user.id
        )
    ).scalar_one_or_none()
    if actor is None:
        raise APIError(
            "cineplanner.actor_not_found", "Actor profile was not found.", status=404
        )
    payload = _json_body()
    try:
        starts_on = date.fromisoformat(str(payload.get("starts_on", "")))
        ends_on = date.fromisoformat(str(payload.get("ends_on", "")))
    except ValueError as exc:
        raise _field_error(
            "starts_on", "Availability dates must use YYYY-MM-DD."
        ) from exc
    if ends_on < starts_on:
        raise _field_error("ends_on", "End date cannot precede start date.")
    status = str(payload.get("status", "")).lower()
    if status not in {"available", "unavailable", "hold", "option", "confirmed"}:
        raise _field_error("status", "Select a supported availability status.")
    production_id = None
    production_public_id = str(payload.get("production_id", "")).strip()
    if production_public_id:
        production_id = _production_for_user(production_public_id, user).id
    db.session.add(
        CineActorAvailability(
            actor_id=actor.id,
            production_id=production_id,
            starts_on=starts_on,
            ends_on=ends_on,
            status=status,
            notes=_optional_text(payload.get("notes"), 5000),
        )
    )
    db.session.commit()
    return jsonify(success({"actor": _actor_payload(actor)})), 201


@cineplanner_blueprint.post("/productions/<public_id>/cast-assignments")
def cast_assignment_upsert(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "cast")
    payload = _json_body()
    character = db.session.execute(
        select(CineCharacter).where(
            CineCharacter.public_id == str(payload.get("character_id", "")),
            CineCharacter.production_id == production.id,
        )
    ).scalar_one_or_none()
    actor = db.session.execute(
        select(CineActor).where(
            CineActor.public_id == str(payload.get("actor_id", "")),
            CineActor.owner_user_id == user.id,
        )
    ).scalar_one_or_none()
    if character is None or actor is None:
        raise _field_error("actor_id", "Select a valid character and actor.")
    status = str(payload.get("status", "suggested")).lower()
    if status not in {"suggested", "shortlisted", "rejected", "confirmed"}:
        raise _field_error("status", "Select a supported casting status.")
    assignment = db.session.execute(
        select(CineCastAssignment).where(
            CineCastAssignment.production_id == production.id,
            CineCastAssignment.character_id == character.id,
            CineCastAssignment.actor_id == actor.id,
        )
    ).scalar_one_or_none()
    if status == "confirmed":
        previous = db.session.execute(
            select(CineCastAssignment).where(
                CineCastAssignment.production_id == production.id,
                CineCastAssignment.character_id == character.id,
                CineCastAssignment.status == "confirmed",
            )
        ).scalars()
        for item in previous:
            item.status = "shortlisted"
    fit = _fit_score(character, actor, production)
    if assignment is None:
        assignment = CineCastAssignment(
            production_id=production.id,
            character_id=character.id,
            actor_id=actor.id,
            status=status,
            fit_score=fit["score"],
            fit_breakdown_json=fit["breakdown"],
        )
        db.session.add(assignment)
        db.session.flush()
        old_status = None
    else:
        old_status = assignment.status
        assignment.status = status
        assignment.fit_score = fit["score"]
        assignment.fit_breakdown_json = fit["breakdown"]
    _audit(
        production,
        user,
        "actor_changed",
        "cast_assignment",
        assignment.public_id,
        {"status": old_status},
        {"status": status, "actor": actor.public_id},
    )
    recalculate_budget(production)
    detect_conflicts(production)
    db.session.commit()
    return jsonify(success({"assignment": _assignment_payload(assignment)})), 201


def _fit_score(
    character: CineCharacter, actor: CineActor, production: CineProduction
) -> dict[str, Any]:
    language_matches = len(
        set(value.casefold() for value in character.languages_json)
        & set(value.casefold() for value in actor.languages_json)
    )
    skill_matches = len(
        set(value.casefold() for value in character.skills_json)
        & set(value.casefold() for value in actor.skills_json)
    )
    language_score = (
        100
        if not character.languages_json
        else min(100, int(language_matches / len(character.languages_json) * 100))
    )
    skill_score = (
        100
        if not character.skills_json
        else min(100, int(skill_matches / len(character.skills_json) * 100))
    )
    availability_score = 100
    if production.production_start_date:
        blocked = db.session.execute(
            select(CineActorAvailability.id).where(
                CineActorAvailability.actor_id == actor.id,
                CineActorAvailability.status == "unavailable",
                CineActorAvailability.starts_on <= production.production_start_date,
                CineActorAvailability.ends_on >= production.production_start_date,
            )
        ).scalar_one_or_none()
        availability_score = 0 if blocked else 100
    expected_cost = actor.project_rate_minor or (actor.daily_rate_minor or 0) * max(
        1, character.estimated_shoot_days
    )
    budget_score = 100
    if production.budget_ceiling_minor and expected_cost:
        budget_score = max(
            0,
            min(
                100,
                int(
                    (production.budget_ceiling_minor - expected_cost)
                    / production.budget_ceiling_minor
                    * 100
                ),
            ),
        )
    breakdown = {
        "age": 75
        if character.playing_age
        and (actor.playing_age_min is None or actor.playing_age_max is None)
        else 90,
        "suitability": 75,
        "language": language_score,
        "skills": skill_score,
        "availability": availability_score,
        "budget": budget_score,
        "preference": 75,
    }
    return {
        "score": round(sum(breakdown.values()) / len(breakdown)),
        "breakdown": breakdown,
    }


@cineplanner_blueprint.get("/productions/<public_id>/schedule")
def schedule_show(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    days = db.session.execute(
        select(CineShootDay)
        .where(CineShootDay.production_id == production.id)
        .order_by(CineShootDay.shoot_day_number)
    ).scalars()
    conflicts = db.session.execute(
        select(CineConflict).where(
            CineConflict.production_id == production.id,
            CineConflict.resolved_at.is_(None),
        )
    ).scalars()
    return jsonify(
        success(
            {
                "locked": production.schedule_locked_at is not None,
                "days": [_shoot_day_payload(day) for day in days],
                "conflicts": [_conflict_payload(row) for row in conflicts],
            }
        )
    )


@cineplanner_blueprint.post("/productions/<public_id>/schedule/generate")
def schedule_generate(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "schedule")
    if production.schedule_locked_at:
        raise APIError(
            "cineplanner.schedule_locked",
            "Unlock the schedule before regenerating it.",
            status=409,
        )
    payload = _json_body()
    latest = _latest_script(production)
    if latest is None:
        raise APIError(
            "cineplanner.script_required",
            "Upload and process a screenplay first.",
            status=409,
        )
    scenes = (
        db.session.execute(
            select(CineScene)
            .where(CineScene.script_version_id == latest.id)
            .order_by(CineScene.sort_order)
        )
        .scalars()
        .all()
    )
    plans = [
        build_schedule_plan(production, scenes, strategy)
        for strategy in ("lowest_cost", "fastest", "balanced")
    ]
    strategy = str(payload.get("strategy", "")).strip()
    if bool(payload.get("apply")):
        selected = next((plan for plan in plans if plan["strategy"] == strategy), None)
        if selected is None:
            raise _field_error("strategy", "Choose lowest_cost, fastest, or balanced.")
        apply_schedule_plan(production, selected)
        _audit(
            production,
            user,
            "schedule_generated",
            "schedule",
            None,
            None,
            {"strategy": strategy, "shoot_days": selected["shoot_days"]},
        )
        recalculate_budget(production)
        db.session.commit()
    return jsonify(success({"plans": plans}))


@cineplanner_blueprint.patch(
    "/productions/<public_id>/schedule/events/<event_public_id>"
)
def schedule_event_move(public_id: str, event_public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "schedule")
    if production.schedule_locked_at:
        raise APIError(
            "cineplanner.schedule_locked",
            "Unlock the schedule before moving scenes.",
            status=409,
        )
    event = db.session.execute(
        select(CineScheduleEvent).where(
            CineScheduleEvent.public_id == event_public_id,
            CineScheduleEvent.production_id == production.id,
        )
    ).scalar_one_or_none()
    if event is None:
        raise APIError(
            "cineplanner.event_not_found", "Schedule event was not found.", status=404
        )
    payload = _json_body()
    target_day = db.session.execute(
        select(CineShootDay).where(
            CineShootDay.public_id == str(payload.get("shoot_day_id", "")),
            CineShootDay.production_id == production.id,
        )
    ).scalar_one_or_none()
    if target_day is None:
        raise _field_error("shoot_day_id", "Select a valid shoot day.")
    old = {
        "shoot_day_id": event.shoot_day.public_id,
        "starts_at": event.starts_at.strftime("%H:%M"),
        "ends_at": event.ends_at.strftime("%H:%M"),
    }
    event.shoot_day_id = target_day.id
    event.starts_at = _parse_time(payload.get("starts_at"), "starts_at")
    event.ends_at = _parse_time(payload.get("ends_at"), "ends_at")
    if event.ends_at <= event.starts_at:
        raise _field_error("ends_at", "End time must be later than start time.")
    _audit(
        production,
        user,
        "scene_moved",
        "schedule_event",
        event.public_id,
        old,
        {
            "shoot_day_id": target_day.public_id,
            "starts_at": event.starts_at.strftime("%H:%M"),
            "ends_at": event.ends_at.strftime("%H:%M"),
        },
    )
    detect_conflicts(production)
    recalculate_budget(production)
    db.session.commit()
    return jsonify(success({"event": _event_payload(event)}))


@cineplanner_blueprint.post("/productions/<public_id>/schedule/optimize")
def schedule_optimize(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "schedule")
    payload = _json_body()
    preview = optimization_preview(production)
    if bool(payload.get("apply")):
        if production.schedule_locked_at:
            raise APIError(
                "cineplanner.schedule_locked",
                "Unlock the schedule before optimization.",
                status=409,
            )
        apply_schedule_plan(production, preview["plan"])
        _audit(
            production,
            user,
            "schedule_optimized",
            "schedule",
            None,
            None,
            {"estimated_savings_minor": preview["estimated_savings_minor"]},
        )
        recalculate_budget(production)
        db.session.commit()
    return jsonify(success(preview))


@cineplanner_blueprint.post("/productions/<public_id>/schedule/lock")
def schedule_lock(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "approve")
    payload = _json_body()
    locked = bool(payload.get("locked", True))
    old = production.schedule_locked_at is not None
    production.schedule_locked_at = utc_now() if locked else None
    days = db.session.execute(
        select(CineShootDay).where(CineShootDay.production_id == production.id)
    ).scalars()
    for day in days:
        day.locked_at = production.schedule_locked_at
        day.status = "locked" if locked else "draft"
    _audit(
        production,
        user,
        "schedule_locked" if locked else "schedule_unlocked",
        "schedule",
        None,
        {"locked": old},
        {"locked": locked},
    )
    db.session.commit()
    return jsonify(success({"locked": locked}))


@cineplanner_blueprint.get("/productions/<public_id>/budget")
def budget_show(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "finance")
    result = recalculate_budget(production)
    db.session.commit()
    return jsonify(
        success(
            {
                "currency": production.currency,
                "totals": result["totals"],
                "lines": [_budget_line_payload(row) for row in result["lines"]],
            }
        )
    )


@cineplanner_blueprint.patch("/productions/<public_id>/budget/<line_public_id>")
def budget_line_update(public_id: str, line_public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "finance")
    line = db.session.execute(
        select(CineBudgetLine).where(
            CineBudgetLine.public_id == line_public_id,
            CineBudgetLine.production_id == production.id,
        )
    ).scalar_one_or_none()
    if line is None:
        raise APIError(
            "cineplanner.budget_line_not_found",
            "Budget line was not found.",
            status=404,
        )
    payload = _json_body()
    fields = {
        "description",
        "estimated_minor",
        "quoted_minor",
        "approved_minor",
        "committed_minor",
        "paid_minor",
        "status",
        "notes",
    }
    old = {key: _json_safe(getattr(line, key)) for key in fields}
    for key, value in payload.items():
        if key in fields:
            setattr(
                line,
                key,
                _optional_int(value) or 0 if key.endswith("_minor") else value,
            )
    new = {key: _json_safe(getattr(line, key)) for key in fields}
    _audit(production, user, "budget_changed", "budget_line", line.public_id, old, new)
    db.session.commit()
    return jsonify(success({"line": _budget_line_payload(line)}))


@cineplanner_blueprint.post("/productions/<public_id>/call-sheets")
def call_sheet_create(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "schedule")
    if production.schedule_locked_at is None:
        raise APIError(
            "cineplanner.schedule_not_locked",
            "Lock the schedule before generating call sheets.",
            status=409,
        )
    payload = _json_body()
    day = db.session.execute(
        select(CineShootDay).where(
            CineShootDay.public_id == str(payload.get("shoot_day_id", "")),
            CineShootDay.production_id == production.id,
        )
    ).scalar_one_or_none()
    if day is None:
        raise _field_error("shoot_day_id", "Select a valid shoot day.")
    call_payload = _call_sheet_payload(production, day)
    latest_revision = (
        db.session.execute(
            select(func.max(CineCallSheet.revision_number)).where(
                CineCallSheet.shoot_day_id == day.id
            )
        ).scalar_one()
        or 0
    )
    sheet = CineCallSheet(
        production_id=production.id,
        shoot_day_id=day.id,
        generated_by_user_id=user.id,
        revision_number=latest_revision + 1,
        payload_json=call_payload,
        status="published",
    )
    db.session.add(sheet)
    db.session.commit()
    return jsonify(
        success(
            {
                "call_sheet": {
                    "public_id": sheet.public_id,
                    "revision_number": sheet.revision_number,
                    "status": sheet.status,
                    "payload": call_payload,
                    "pdf_url": (
                        f"/cineplanner/productions/{production.public_id}"
                        f"/call-sheets/{sheet.public_id}.pdf"
                    ),
                }
            }
        )
    ), 201


@cineplanner_blueprint.get("/productions/<public_id>/call-sheets/<sheet_public_id>.pdf")
def call_sheet_pdf(public_id: str, sheet_public_id: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    sheet = db.session.execute(
        select(CineCallSheet).where(
            CineCallSheet.public_id == sheet_public_id,
            CineCallSheet.production_id == production.id,
        )
    ).scalar_one_or_none()
    if sheet is None:
        raise APIError(
            "cineplanner.call_sheet_not_found",
            "Call sheet was not found.",
            status=404,
        )
    buffer = _render_call_sheet_pdf(sheet.payload_json, sheet.revision_number)
    return send_file(
        buffer,
        mimetype="application/pdf",
        as_attachment=True,
        download_name=(
            f"{production.title}-shoot-day-"
            f"{sheet.payload_json.get('shoot_day', 'call-sheet')}-r"
            f"{sheet.revision_number}.pdf"
        ),
    )


def _call_sheet_payload(
    production: CineProduction, day: CineShootDay
) -> dict[str, Any]:
    ordered_events = sorted(
        day.events,
        key=lambda row: _event_clock_offset(row.starts_at, day.crew_call),
    )
    loaded_scenes = [
        db.session.get(CineScene, event.scene_id)
        for event in ordered_events
        if event.scene_id
    ]
    scenes: list[CineScene] = [scene for scene in loaded_scenes if scene is not None]
    location = (
        db.session.execute(
            select(CineLocation).where(
                CineLocation.production_id == production.id,
                CineLocation.screenplay_name == day.location_name,
                CineLocation.status == "confirmed",
            )
        )
        .scalars()
        .first()
    )
    actor_first_calls: dict[str, time] = {}
    for event in ordered_events:
        if event.scene_id is None:
            continue
        scene = db.session.get(CineScene, event.scene_id)
        if scene is None:
            continue
        for actor_name in scene.cast_json:
            actor_first_calls.setdefault(actor_name, event.starts_at)
    actor_call_details = [
        {
            "name": name,
            "call": _time_minus(first_scene, 60),
            "makeup_call": _time_minus(first_scene, 90)
            if any(name in scene.cast_json and scene.makeup_json for scene in scenes)
            else None,
            "wardrobe_call": _time_minus(first_scene, 75)
            if any(name in scene.cast_json and scene.wardrobe_json for scene in scenes)
            else None,
        }
        for name, first_scene in sorted(actor_first_calls.items())
    ]
    page_count_eighths = sum(scene.page_length_eighths for scene in scenes)
    return {
        "production": production.title,
        "shoot_date": day.shoot_date.isoformat(),
        "shoot_day": day.shoot_day_number,
        "location": day.location_name,
        "address": location.address if location else None,
        "crew_call": day.crew_call.strftime("%H:%M"),
        "expected_wrap": day.expected_wrap.strftime("%H:%M"),
        "actor_calls": sorted(actor_first_calls),
        "actor_call_details": actor_call_details,
        "scenes": [_scene_payload(scene) for scene in scenes],
        "page_count_eighths": page_count_eighths,
        "page_count": round(page_count_eighths / 8, 2),
        "props": sorted({name for scene in scenes for name in scene.props_json}),
        "vehicles": sorted({name for scene in scenes for name in scene.vehicles_json}),
        "equipment": sorted(
            {name for scene in scenes for name in scene.equipment_json}
        ),
        "extras": sorted({name for scene in scenes for name in scene.extras_json}),
        "safety_notes": [scene.safety_notes for scene in scenes if scene.safety_notes],
        "meals": [
            event.starts_at.strftime("%H:%M")
            for event in ordered_events
            if event.event_type == "meal"
        ],
    }


def _time_minus(value: time, minutes: int) -> str:
    total = (value.hour * 60 + value.minute - minutes) % (24 * 60)
    return f"{total // 60:02d}:{total % 60:02d}"


def _render_call_sheet_pdf(payload: dict[str, Any], revision: int) -> io.BytesIO:
    buffer = io.BytesIO()
    styles = getSampleStyleSheet()
    body = styles["BodyText"]
    body.fontSize = 8
    body.leading = 10
    story: list[Any] = [
        Paragraph(
            _pdf_text(str(payload.get("production", "Production"))), styles["Title"]
        ),
        Paragraph(
            _pdf_text(
                f"CALL SHEET · Shoot Day {payload.get('shoot_day', '')} · "
                f"Revision {revision}"
            ),
            styles["Heading2"],
        ),
        Spacer(1, 4 * mm),
    ]
    summary = [
        ["Shoot date", payload.get("shoot_date", "")],
        ["Location", payload.get("location", "")],
        ["Address", payload.get("address", "")],
        ["Crew call", payload.get("crew_call", "")],
        ["Expected wrap", payload.get("expected_wrap", "")],
        ["Pages", payload.get("page_count", "")],
        ["Meal times", ", ".join(payload.get("meals", []))],
    ]
    story.append(_pdf_table(summary, [34 * mm, 140 * mm], body))
    actor_details = payload.get("actor_call_details", [])
    if actor_details:
        story.extend([Spacer(1, 5 * mm), Paragraph("Actor calls", styles["Heading2"])])
        actor_rows: list[list[Any]] = [["Actor", "Call", "Makeup", "Wardrobe"]]
        actor_rows.extend(
            [
                item.get("name", ""),
                item.get("call", ""),
                item.get("makeup_call", ""),
                item.get("wardrobe_call", ""),
            ]
            for item in actor_details
        )
        story.append(
            _pdf_table(
                actor_rows,
                [72 * mm, 34 * mm, 34 * mm, 34 * mm],
                body,
                header=True,
            )
        )
    story.extend([Spacer(1, 5 * mm), Paragraph("Scenes", styles["Heading2"])])
    scene_rows: list[list[Any]] = [["Scene", "Slugline", "Pages", "Cast"]]
    for scene in payload.get("scenes", []):
        scene_rows.append(
            [
                scene.get("scene_number", ""),
                scene.get("slugline", ""),
                f"{int(scene.get('page_length_eighths', 0)) / 8:g}",
                ", ".join(scene.get("cast", [])),
            ]
        )
    story.append(
        _pdf_table(
            scene_rows,
            [18 * mm, 78 * mm, 18 * mm, 60 * mm],
            body,
            header=True,
        )
    )
    for heading, key in (
        ("Actor calls", "actor_calls"),
        ("Props", "props"),
        ("Vehicles", "vehicles"),
        ("Equipment", "equipment"),
        ("Extras", "extras"),
        ("Safety notes", "safety_notes"),
    ):
        values = payload.get(key, [])
        if values:
            story.extend(
                [
                    Spacer(1, 4 * mm),
                    Paragraph(heading, styles["Heading3"]),
                    Paragraph(_pdf_text(" · ".join(map(str, values))), body),
                ]
            )
    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=14 * mm,
        leftMargin=14 * mm,
        topMargin=12 * mm,
        bottomMargin=12 * mm,
        title=f"{payload.get('production', 'Production')} call sheet",
    )
    document.build(story)
    buffer.seek(0)
    return buffer


def _pdf_text(value: str) -> str:
    return html.escape(value, quote=True).replace("\n", "<br/>")


def _pdf_table(
    rows: list[list[Any]],
    widths: list[float],
    body_style: Any,
    *,
    header: bool = False,
) -> Table:
    rendered = [
        [Paragraph(_pdf_text(str(cell or "")), body_style) for cell in row]
        for row in rows
    ]
    table = Table(rendered, colWidths=widths, repeatRows=1 if header else 0)
    commands: list[tuple[Any, ...]] = [
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#CBD5E1")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    if header:
        commands.extend(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0F172A")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ]
        )
    else:
        commands.append(("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#F1F5F9")))
    table.setStyle(TableStyle(commands))
    return table


@cineplanner_blueprint.get("/productions/<public_id>/reports/<report_type>.csv")
def report_csv(public_id: str, report_type: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    rows = _report_rows(production, report_type, user)
    export_rows = [_export_row(row) for row in rows]
    output = io.StringIO()
    if export_rows:
        writer = csv.DictWriter(output, fieldnames=list(export_rows[0]))
        writer.writeheader()
        writer.writerows(export_rows)
    buffer = io.BytesIO(output.getvalue().encode("utf-8-sig"))
    return send_file(
        buffer,
        mimetype="text/csv",
        as_attachment=True,
        download_name=f"{production.title}-{report_type}.csv",
    )


@cineplanner_blueprint.get("/productions/<public_id>/reports/<report_type>.xlsx")
def report_excel(public_id: str, report_type: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    rows = [_export_row(row) for row in _report_rows(production, report_type, user)]
    workbook = Workbook(write_only=True)
    worksheet = workbook.create_sheet(title="CinePlanner Report")
    if rows:
        headings = list(rows[0])
        worksheet.append(headings)
        for row in rows:
            worksheet.append([row.get(heading, "") for heading in headings])
    buffer = io.BytesIO()
    workbook.save(buffer)
    buffer.seek(0)
    return send_file(
        buffer,
        mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        as_attachment=True,
        download_name=f"{production.title}-{report_type}.xlsx",
    )


@cineplanner_blueprint.get("/productions/<public_id>/reports/<report_type>.pdf")
def report_pdf(public_id: str, report_type: str) -> ResponseReturnValue:
    user = _current_user()
    production = _production_for_user(public_id, user)
    rows = [_export_row(row) for row in _report_rows(production, report_type, user)]
    buffer = _render_report_pdf(production.title, report_type, rows)
    return send_file(
        buffer,
        mimetype="application/pdf",
        as_attachment=True,
        download_name=f"{production.title}-{report_type}.pdf",
    )


@cineplanner_blueprint.get("/productions/<public_id>/reports/<report_type>")
def report_json(public_id: str, report_type: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    return jsonify(
        success(
            {
                "report_type": report_type,
                "rows": _report_rows(production, report_type, user),
            }
        )
    )


def _export_row(row: dict[str, Any]) -> dict[str, Any]:
    return {
        key: json.dumps(value, ensure_ascii=False, separators=(",", ":"))
        if isinstance(value, (list, dict))
        else value
        for key, value in row.items()
    }


def _render_report_pdf(
    production_title: str, report_type: str, rows: list[dict[str, Any]]
) -> io.BytesIO:
    buffer = io.BytesIO()
    styles = getSampleStyleSheet()
    cell_style = styles["BodyText"]
    cell_style.fontSize = 5
    cell_style.leading = 6
    story: list[Any] = [
        Paragraph(_pdf_text(production_title), styles["Title"]),
        Paragraph(_pdf_text(report_type.replace("-", " ").title()), styles["Heading2"]),
        Spacer(1, 4 * mm),
    ]
    if rows:
        headings = list(rows[0])
        table_rows: list[list[Any]] = [headings]
        for row in rows:
            table_rows.append([str(row.get(heading, ""))[:500] for heading in headings])
        usable_width = landscape(A4)[0] - 20 * mm
        story.append(
            _pdf_table(
                table_rows,
                [usable_width / len(headings)] * len(headings),
                cell_style,
                header=True,
            )
        )
    else:
        story.append(Paragraph("No records found.", styles["BodyText"]))
    document = SimpleDocTemplate(
        buffer,
        pagesize=landscape(A4),
        rightMargin=10 * mm,
        leftMargin=10 * mm,
        topMargin=10 * mm,
        bottomMargin=10 * mm,
        title=f"{production_title} {report_type}",
    )
    document.build(story)
    buffer.seek(0)
    return buffer


def _report_rows(
    production: CineProduction, report_type: str, user: User
) -> list[dict[str, Any]]:
    if report_type in {"budget", "budget-report"}:
        _require_permission(production, user, "finance")
        budget = recalculate_budget(production)
        return [_budget_line_payload(row) for row in budget["lines"]]
    if report_type in {"day-out-of-days", "actor-schedule"}:
        return day_out_of_days(production)
    if report_type in {"scenes", "scene-breakdown", "full-script-breakdown"}:
        latest = _latest_script(production)
        if latest is None:
            return []
        return [
            _scene_payload(row)
            for row in db.session.execute(
                select(CineScene)
                .where(CineScene.script_version_id == latest.id)
                .order_by(CineScene.sort_order)
            ).scalars()
        ]
    if report_type in {"characters", "character-breakdown"}:
        return [
            _character_payload(row)
            for row in db.session.execute(
                select(CineCharacter)
                .where(CineCharacter.production_id == production.id)
                .order_by(CineCharacter.name)
            ).scalars()
        ]
    if report_type == "cast-breakdown":
        return [
            _assignment_payload(row)
            for row in db.session.execute(
                select(CineCastAssignment).where(
                    CineCastAssignment.production_id == production.id
                )
            ).scalars()
        ]
    if report_type in {"locations", "location-report"}:
        return [
            _location_payload(row)
            for row in db.session.execute(
                select(CineLocation).where(CineLocation.production_id == production.id)
            ).scalars()
        ]
    if report_type in {
        "schedule",
        "shooting-schedule",
        "daily-timetable",
        "weekly-timetable",
    }:
        return [
            _shoot_day_payload(row)
            for row in db.session.execute(
                select(CineShootDay)
                .where(CineShootDay.production_id == production.id)
                .order_by(CineShootDay.shoot_day_number)
            ).scalars()
        ]
    if report_type in {"crew", "crew-report"}:
        return [
            _crew_payload(row)
            for row in db.session.execute(
                select(CineCrewMember)
                .where(CineCrewMember.production_id == production.id)
                .order_by(CineCrewMember.department, CineCrewMember.name)
            ).scalars()
        ]
    if report_type in {"call-sheets", "call-sheet-report"}:
        return [
            {
                "public_id": row.public_id,
                "revision_number": row.revision_number,
                "status": row.status,
                **row.payload_json,
            }
            for row in db.session.execute(
                select(CineCallSheet)
                .where(CineCallSheet.production_id == production.id)
                .order_by(CineCallSheet.created_at)
            ).scalars()
        ]
    if report_type in {"script-revisions", "script-revision-report"}:
        return [
            _script_payload(row)
            for row in db.session.execute(
                select(CineScriptVersion)
                .where(CineScriptVersion.production_id == production.id)
                .order_by(CineScriptVersion.version_number)
            ).scalars()
        ]
    if report_type in {"production-progress", "progress-report"}:
        latest = _latest_script(production)
        scenes = (
            db.session.execute(
                select(CineScene).where(CineScene.script_version_id == latest.id)
            )
            .scalars()
            .all()
            if latest
            else []
        )
        characters = (
            db.session.execute(
                select(CineCharacter).where(
                    CineCharacter.script_version_id == latest.id
                )
            )
            .scalars()
            .all()
            if latest
            else []
        )
        return [
            {
                "production": production.title,
                "status": production.status,
                "script_version": latest.version_number if latest else None,
                "scenes_total": len(scenes),
                "scenes_approved": sum(
                    row.review_status == "approved" for row in scenes
                ),
                "characters_total": len(characters),
                "characters_approved": sum(
                    row.review_status == "approved" for row in characters
                ),
                "schedule_locked": production.schedule_locked_at is not None,
            }
        ]
    category = report_type.removesuffix("-report")
    if category in {
        "props",
        "wardrobe",
        "makeup",
        "vehicles",
        "equipment",
        "extras",
        "stunts",
        "vfx",
        "sfx",
    }:
        return [
            _element_payload(row)
            for row in db.session.execute(
                select(CineElement).where(
                    CineElement.production_id == production.id,
                    CineElement.category == category,
                )
            ).scalars()
        ]
    raise APIError(
        "cineplanner.report_not_found", "Report type is not supported.", status=404
    )


@cineplanner_blueprint.post("/productions/<public_id>/assistant")
@limiter.limit("60 per hour")
def assistant_query(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    payload = _json_body()
    question = str(payload.get("question", "")).strip()
    if len(question) < 3:
        raise _field_error("question", "Ask a production question.")
    context = _assistant_context(production, question)
    answer = _assistant_answer(question, context, user)
    return jsonify(success({"answer": answer, "sources": context["sources"]}))


def _assistant_context(production: CineProduction, question: str) -> dict[str, Any]:
    words = {
        word.strip(".,?!").casefold() for word in question.split() if len(word) > 2
    }
    scenes = list(
        db.session.execute(
            select(CineScene)
            .where(CineScene.production_id == production.id)
            .order_by(CineScene.sort_order)
        )
        .scalars()
        .all()
    )
    matched = [
        scene
        for scene in scenes
        if words
        & {
            token.strip(".,-/").casefold()
            for token in " ".join(
                (
                    scene.slugline,
                    scene.summary,
                    *scene.cast_json,
                    *scene.props_json,
                    *scene.vfx_json,
                    *scene.sfx_json,
                )
            ).split()
        }
    ]
    if not matched:
        matched = scenes[:40]
    conflicts = (
        db.session.execute(
            select(CineConflict).where(
                CineConflict.production_id == production.id,
                CineConflict.resolved_at.is_(None),
            )
        )
        .scalars()
        .all()
    )
    return {
        "production": production.title,
        "scenes": [_scene_payload(scene) for scene in matched[:80]],
        "conflicts": [_conflict_payload(item) for item in conflicts[:30]],
        "sources": [
            {
                "type": "scene",
                "public_id": scene.public_id,
                "label": f"Scene {scene.scene_number}",
            }
            for scene in matched[:20]
        ],
    }


def _assistant_answer(question: str, context: dict[str, Any], user: User) -> str:
    if not current_app.config.get(
        "CINEPLANNER_AI_ENABLED"
    ) or not current_app.config.get("OPENAI_API_KEY"):
        scene_count = len(context["scenes"])
        conflict_count = len(context["conflicts"])
        return (
            f"I found {scene_count} relevant scenes and "
            f"{conflict_count} open conflicts."
        )
    from openai import OpenAI

    try:
        response = OpenAI(
            api_key=current_app.config["OPENAI_API_KEY"], timeout=60.0, max_retries=1
        ).responses.create(
            model=current_app.config["OPENAI_SCREENPLAY_MODEL"],
            instructions=(
                "Answer as CinePlanner. Use only the provided production snapshot. "
                "Cite scene numbers in prose. Do not claim to change data."
            ),
            input=(
                f"Question: {question}\nProduction snapshot: "
                f"{json.dumps(context, separators=(',', ':'))}"
            ),
            reasoning={"effort": "low"},
            store=False,
            max_output_tokens=1200,
            safety_identifier=f"cineplanner_{user.id.hex[:32]}",
        )
        return response.output_text.strip()
    except Exception:
        current_app.logger.exception("cineplanner_assistant_failed")
        raise APIError(
            "cineplanner.assistant_unavailable",
            "CinePlanner Assistant is temporarily unavailable.",
            status=503,
        ) from None


@cineplanner_blueprint.get("/productions/<public_id>/audit-logs")
def audit_logs(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    rows = db.session.execute(
        select(CineAuditLog)
        .where(CineAuditLog.production_id == production.id)
        .order_by(CineAuditLog.created_at.desc())
        .limit(200)
    ).scalars()
    return jsonify(
        success(
            {
                "audit_logs": [
                    {
                        "action": row.action,
                        "entity_type": row.entity_type,
                        "entity_public_id": row.entity_public_id,
                        "old_value": row.old_value_json,
                        "new_value": row.new_value_json,
                        "created_at": row.created_at.isoformat(),
                    }
                    for row in rows
                ]
            }
        )
    )


def _production_snapshot(production: CineProduction, user: User) -> dict[str, Any]:
    latest = _latest_script(production)
    script_id = latest.id if latest else None
    scenes = (
        db.session.execute(
            select(CineScene)
            .where(CineScene.script_version_id == script_id)
            .order_by(CineScene.sort_order)
        )
        .scalars()
        .all()
        if script_id
        else []
    )
    characters = (
        db.session.execute(
            select(CineCharacter)
            .where(CineCharacter.script_version_id == script_id)
            .order_by(CineCharacter.classification, CineCharacter.name)
        )
        .scalars()
        .all()
        if script_id
        else []
    )
    elements = (
        db.session.execute(
            select(CineElement)
            .where(CineElement.script_version_id == script_id)
            .order_by(CineElement.category, CineElement.name)
        )
        .scalars()
        .all()
        if script_id
        else []
    )
    locations = (
        db.session.execute(
            select(CineLocation)
            .where(CineLocation.script_version_id == script_id)
            .order_by(CineLocation.screenplay_name)
        )
        .scalars()
        .all()
        if script_id
        else []
    )
    jobs = (
        db.session.execute(
            select(CineAIJob)
            .where(CineAIJob.production_id == production.id)
            .order_by(CineAIJob.created_at.desc())
            .limit(5)
        )
        .scalars()
        .all()
    )
    assignments = (
        db.session.execute(
            select(CineCastAssignment).where(
                CineCastAssignment.production_id == production.id
            )
        )
        .scalars()
        .all()
    )
    crew = (
        db.session.execute(
            select(CineCrewMember)
            .where(CineCrewMember.production_id == production.id)
            .order_by(CineCrewMember.department, CineCrewMember.name)
        )
        .scalars()
        .all()
    )
    call_sheets = (
        db.session.execute(
            select(CineCallSheet)
            .where(CineCallSheet.production_id == production.id)
            .order_by(CineCallSheet.created_at.desc())
        )
        .scalars()
        .all()
    )
    team_roles = (
        db.session.execute(
            select(CineProductionRole).where(
                CineProductionRole.production_id == production.id,
                CineProductionRole.status == "active",
            )
        )
        .scalars()
        .all()
    )
    days = (
        db.session.execute(
            select(CineShootDay)
            .where(CineShootDay.production_id == production.id)
            .order_by(CineShootDay.shoot_day_number)
        )
        .scalars()
        .all()
    )
    conflicts = (
        db.session.execute(
            select(CineConflict).where(
                CineConflict.production_id == production.id,
                CineConflict.resolved_at.is_(None),
            )
        )
        .scalars()
        .all()
    )
    permissions = _permission_set(production, user)
    budget_payload = None
    if "*" in permissions or "finance" in permissions:
        budget = recalculate_budget(production)
        budget_payload = {
            "currency": production.currency,
            "totals": budget["totals"],
            "lines": [_budget_line_payload(row) for row in budget["lines"]],
        }
    approved_count = (
        sum(item.review_status == "approved" for item in scenes)
        + sum(item.review_status == "approved" for item in characters)
        + sum(item.review_status == "approved" for item in elements)
    )
    review_total = len(scenes) + len(characters) + len(elements)
    return {
        "production": _production_payload(production),
        "permissions": sorted(permissions),
        "scripts": [
            _script_payload(item)
            for item in sorted(
                production.scripts, key=lambda row: row.version_number, reverse=True
            )
        ],
        "jobs": [_job_payload(item) for item in jobs],
        "dashboard": {
            "screenplay_title": latest.screenplay_title if latest else None,
            "total_pages": latest.total_pages if latest else 0,
            "total_scenes": len(scenes),
            "characters": len(characters),
            "lead_characters": sum(
                item.classification == "lead" for item in characters
            ),
            "locations": len(locations),
            "props": sum(item.category == "props" for item in elements),
            "scheduled_shoot_days": len(days),
            "production_progress": round(approved_count / review_total * 100)
            if review_total
            else 0,
            "estimated_budget_minor": budget_payload["totals"]["estimated_minor"]
            if budget_payload
            else None,
            "upcoming_shoot": next(
                (
                    day.shoot_date.isoformat()
                    for day in days
                    if day.shoot_date >= date.today()
                ),
                None,
            ),
            "schedule_conflicts": len(conflicts),
            "actor_availability_issues": sum(
                item.conflict_type == "actor_unavailable" for item in conflicts
            ),
            "unapproved_ai_items": review_total - approved_count,
            "high_complexity_scenes": sum(
                item.complexity in {"high", "extreme"} for item in scenes
            ),
        },
        "scenes": [_scene_payload(item) for item in scenes],
        "characters": [_character_payload(item) for item in characters],
        "locations": [_location_payload(item) for item in locations],
        "elements": [_element_payload(item) for item in elements],
        "actors": [
            _actor_payload(item)
            for item in db.session.execute(
                select(CineActor)
                .where(CineActor.owner_user_id == user.id)
                .order_by(CineActor.name)
            ).scalars()
        ],
        "cast_assignments": [_assignment_payload(item) for item in assignments],
        "crew": [_crew_payload(item) for item in crew],
        "call_sheets": [
            {
                "public_id": item.public_id,
                "revision_number": item.revision_number,
                "status": item.status,
                "payload": item.payload_json,
                "created_at": item.created_at.isoformat(),
            }
            for item in call_sheets
        ],
        "team": [
            {
                "user_id": member.public_id,
                "name": member.display_name,
                "role": item.role_code,
                "permissions": item.permissions_json,
            }
            for item in team_roles
            if (member := db.session.get(User, item.user_id)) is not None
        ],
        "schedule": {
            "locked": production.schedule_locked_at is not None,
            "days": [_shoot_day_payload(item) for item in days],
            "conflicts": [_conflict_payload(item) for item in conflicts],
        },
        "budget": budget_payload,
    }


def _optional_int(value: Any) -> int | None:
    if value in {None, ""}:
        return None
    try:
        return int(str(value))
    except ValueError as exc:
        raise _field_error("value", "Value must be an integer.") from exc


def _optional_text(value: Any, limit: int) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text[:limit] or None


def _string_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item).strip()[:180] for item in value if str(item).strip()][:200]


def _parse_time(value: Any, field: str) -> time:
    try:
        return time.fromisoformat(str(value))
    except ValueError as exc:
        raise _field_error(field, "Use HH:MM time format.") from exc
