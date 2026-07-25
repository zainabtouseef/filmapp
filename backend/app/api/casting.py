from __future__ import annotations

import json
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import func, or_, select

from app.api.auth import _current_user, _json_body
from app.api.bookings import _user_payload
from app.api.marketplace import _field_error, _file_payload, _owned_ready_file
from app.api.operations import _parse_datetime
from app.api.projects import _project_for_user
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import Conversation, ConversationMember
from app.models.casting import (
    CastingApplication,
    CastingApplicationStatusEvent,
    CastingRoleBrief,
    SavedCastingRole,
)
from app.models.identity import User
from app.models.marketplace import (
    City,
    MarketplaceListing,
    PortfolioItem,
    TalentProfile,
    UserProfile,
)
from app.models.projects import Project, ProjectRequirement
from app.responses import success
from app.security import as_utc
from app.services.notifications import notify_user

casting_blueprint = Blueprint("casting", __name__)

APPLICATION_STATUSES = {
    "draft",
    "submitted",
    "viewed",
    "shortlisted",
    "audition_requested",
    "self_tape_requested",
    "callback",
    "offer_received",
    "selected",
    "rejected",
    "withdrawn",
}
DIRECTOR_STATUSES = APPLICATION_STATUSES - {"draft", "submitted", "withdrawn"}
AUDITION_MODES = {"in_person", "online", "self_tape", "hybrid"}
DIRECTOR_TRANSITIONS = {
    "submitted": {
        "viewed",
        "shortlisted",
        "audition_requested",
        "self_tape_requested",
        "rejected",
    },
    "viewed": {
        "shortlisted",
        "audition_requested",
        "self_tape_requested",
        "rejected",
    },
    "shortlisted": {
        "audition_requested",
        "self_tape_requested",
        "callback",
        "selected",
        "rejected",
    },
    "audition_requested": {
        "self_tape_requested",
        "callback",
        "selected",
        "rejected",
    },
    "self_tape_requested": {
        "audition_requested",
        "callback",
        "selected",
        "rejected",
    },
    "callback": {"selected", "rejected"},
    "offer_received": {"selected", "rejected"},
    "selected": set(),
    "rejected": set(),
    "withdrawn": set(),
}


def _has_role(user: User, *codes: str) -> bool:
    return any(row.status == "active" and row.role.code in codes for row in user.roles)


def _require_actor(user: User) -> None:
    if not _has_role(user, "actor_talent", "super_admin"):
        raise APIError(
            "casting.actor_role_required",
            "An actor/talent role is required.",
            status=403,
        )


def _require_director(user: User) -> None:
    if not _has_role(
        user,
        "director_producer",
        "casting_agency",
        "super_admin",
    ):
        raise APIError(
            "casting.director_role_required",
            "A director/producer or casting agency role is required.",
            status=403,
        )


def _json_value(raw: str | None, fallback: Any) -> Any:
    if not raw:
        return fallback
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return fallback
    return value


def _profile_avatar_url(user_id: object) -> str | None:
    profile = db.session.execute(
        select(UserProfile).where(UserProfile.user_id == user_id)
    ).scalar_one_or_none()
    if profile is None:
        return None
    payload = _file_payload(profile.avatar_file)
    return payload["public_url"] if payload else None


def _talent_listing_id(user_id: object) -> str | None:
    return db.session.execute(
        select(MarketplaceListing.public_id)
        .where(
            MarketplaceListing.owner_user_id == user_id,
            MarketplaceListing.listing_type == "talent",
            MarketplaceListing.visibility == "public",
            MarketplaceListing.moderation_status == "approved",
        )
        .order_by(MarketplaceListing.published_at.desc())
        .limit(1)
    ).scalar_one_or_none()


def _brief_for_requirement(
    requirement_id: object,
) -> CastingRoleBrief | None:
    return db.session.execute(
        select(CastingRoleBrief).where(
            CastingRoleBrief.requirement_id == requirement_id
        )
    ).scalar_one_or_none()


def _role_payload(
    requirement: ProjectRequirement,
    *,
    actor_user_id: object | None = None,
) -> dict[str, Any]:
    brief = _brief_for_requirement(requirement.id)
    saved = False
    application_id = None
    application_status = None
    if actor_user_id is not None:
        saved = (
            db.session.execute(
                select(SavedCastingRole.id).where(
                    SavedCastingRole.actor_user_id == actor_user_id,
                    SavedCastingRole.requirement_id == requirement.id,
                )
            ).scalar_one_or_none()
            is not None
        )
        application = db.session.execute(
            select(CastingApplication).where(
                CastingApplication.actor_user_id == actor_user_id,
                CastingApplication.requirement_id == requirement.id,
            )
        ).scalar_one_or_none()
        if application is not None:
            application_id = application.public_id
            application_status = application.status

    project = requirement.project
    return {
        "public_id": requirement.public_id,
        "project": {
            "public_id": project.public_id,
            "title": project.title,
            "project_type": project.project_type,
            "description": project.description,
            "city": {
                "public_id": project.city.public_id,
                "name": project.city.name,
                "province": project.city.province,
                "timezone": project.city.timezone,
            }
            if project.city
            else None,
            "cover_file": _file_payload(project.cover_file),
            "owner": _user_payload(project.owner),
        },
        "title": requirement.title,
        "summary": requirement.summary,
        "role_type": brief.role_type if brief else None,
        "work_location": brief.work_location if brief else None,
        "audition_mode": brief.audition_mode if brief else None,
        "instructions": brief.instructions if brief else None,
        "eligibility": _json_value(brief.eligibility_json, []) if brief else [],
        "casting_questions": (
            _json_value(brief.casting_questions_json, []) if brief else []
        ),
        "application_due_at": (
            brief.application_due_at.isoformat()
            if brief and brief.application_due_at
            else None
        ),
        "sides_file": _file_payload(brief.sides_file) if brief else None,
        "contact_name": brief.contact_name if brief else None,
        "contact_email": brief.contact_email if brief else None,
        "published_at": (
            brief.published_at.isoformat()
            if brief and brief.published_at
            else requirement.created_at.isoformat()
        ),
        "budget_min_minor": requirement.budget_min_minor,
        "budget_max_minor": requirement.budget_max_minor,
        "currency": requirement.currency,
        "start_date": (
            requirement.start_date.isoformat() if requirement.start_date else None
        ),
        "end_date": (
            requirement.end_date.isoformat() if requirement.end_date else None
        ),
        "status": requirement.status,
        "skills": [
            {
                "public_id": row.skill.public_id,
                "name": row.skill.name,
                "category": row.skill.category,
                "required": row.required,
                "minimum_level": row.minimum_level,
            }
            for row in requirement.skills
        ],
        "application_count": requirement.candidate_count_cache,
        "saved": saved,
        "application_id": application_id,
        "application_status": application_status,
    }


def _status_event_payload(item: CastingApplicationStatusEvent) -> dict[str, Any]:
    return {
        "from_status": item.from_status,
        "to_status": item.to_status,
        "note": item.note,
        "changed_by": _user_payload(item.actor) if item.actor else None,
        "created_at": item.created_at.isoformat(),
    }


def _application_payload(item: CastingApplication) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "role": _role_payload(item.requirement, actor_user_id=item.actor_user_id),
        "actor": {
            **_user_payload(item.actor),
            "avatar_url": _profile_avatar_url(item.actor_user_id),
        },
        "talent_profile": {
            "public_id": item.talent_profile.public_id,
            "marketplace_listing_id": _talent_listing_id(item.actor_user_id),
            "screen_name": item.talent_profile.screen_name,
            "age_range": item.talent_profile.age_range,
            "height_cm": item.talent_profile.height_cm,
            "experience_years": item.talent_profile.experience_years,
            "languages": [
                {
                    "language": row.language,
                    "proficiency": row.proficiency,
                }
                for row in item.talent_profile.languages
            ],
        },
        "conversation_id": item.conversation.public_id if item.conversation else None,
        "status": item.status,
        "cover_note": item.cover_note,
        "answers": _json_value(item.answers_json, {}),
        "availability_note": item.availability_note,
        "portfolio_item_ids": _json_value(item.portfolio_item_ids_json, []),
        "self_tape_file": _file_payload(item.self_tape_file),
        "submitted_at": item.submitted_at.isoformat() if item.submitted_at else None,
        "viewed_at": item.viewed_at.isoformat() if item.viewed_at else None,
        "withdrawn_at": item.withdrawn_at.isoformat() if item.withdrawn_at else None,
        "audition": {
            "at": item.audition_at.isoformat() if item.audition_at else None,
            "due_at": item.audition_due_at.isoformat()
            if item.audition_due_at
            else None,
            "location": item.audition_location,
            "online_url": item.audition_online_url,
            "instructions": item.audition_instructions,
            "contact": item.audition_contact,
            "confirmed_at": item.audition_confirmed_at.isoformat()
            if item.audition_confirmed_at
            else None,
        },
        "callback": {
            "at": item.callback_at.isoformat() if item.callback_at else None,
            "details": item.callback_details,
        },
        "rejection_reason": item.rejection_reason,
        "status_events": [_status_event_payload(row) for row in item.status_events],
        "created_at": item.created_at.isoformat(),
        "updated_at": item.updated_at.isoformat(),
    }


def _role_or_404(public_id: str) -> ProjectRequirement:
    role = db.session.execute(
        select(ProjectRequirement).where(
            ProjectRequirement.public_id == public_id,
            ProjectRequirement.category == "talent",
        )
    ).scalar_one_or_none()
    if role is None:
        raise APIError(
            "casting.role_not_found",
            "Casting role was not found.",
            status=404,
        )
    return role


def _actor_profile(user: User) -> TalentProfile:
    profile = db.session.execute(
        select(TalentProfile).where(TalentProfile.user_id == user.id)
    ).scalar_one_or_none()
    if profile is None:
        raise APIError(
            "casting.profile_required",
            "Complete your casting profile before applying.",
            status=409,
        )
    return profile


def _ensure_role_accepting(role: ProjectRequirement) -> None:
    if role.status != "open" or role.project.status != "active":
        raise APIError(
            "casting.role_closed",
            "This casting role is no longer accepting applications.",
            status=410,
        )
    brief = _brief_for_requirement(role.id)
    if (
        brief
        and brief.application_due_at
        and as_utc(brief.application_due_at) < utc_now()
    ):
        raise APIError(
            "casting.role_expired",
            "The application deadline has passed.",
            status=410,
        )


def _actor_application(public_id: str, user: User) -> CastingApplication:
    application = db.session.execute(
        select(CastingApplication).where(
            CastingApplication.public_id == public_id,
            CastingApplication.actor_user_id == user.id,
        )
    ).scalar_one_or_none()
    if application is None:
        raise APIError(
            "casting.application_not_found",
            "Application was not found.",
            status=404,
        )
    return application


def _director_application(public_id: str, user: User) -> CastingApplication:
    application = db.session.execute(
        select(CastingApplication).where(CastingApplication.public_id == public_id)
    ).scalar_one_or_none()
    if application is None:
        raise APIError(
            "casting.application_not_found",
            "Application was not found.",
            status=404,
        )
    _project_for_user(application.requirement.project.public_id, user)
    return application


def _set_status(
    application: CastingApplication,
    status: str,
    *,
    actor: User,
    note: str | None = None,
) -> None:
    if status not in APPLICATION_STATUSES:
        raise _field_error("status", "Application status is invalid.")
    previous = application.status
    if previous == status:
        return
    application.status = status
    if status == "submitted" and application.submitted_at is None:
        application.submitted_at = utc_now()
    if status == "viewed" and application.viewed_at is None:
        application.viewed_at = utc_now()
    if status == "withdrawn":
        application.withdrawn_at = utc_now()
    db.session.add(
        CastingApplicationStatusEvent(
            application_id=application.id,
            actor_user_id=actor.id,
            from_status=previous,
            to_status=status,
            note=note[:2000] if note else None,
        )
    )


def _validate_portfolio_ids(user: User, raw_ids: Any) -> list[str]:
    if raw_ids is None or raw_ids == "":
        return []
    if not isinstance(raw_ids, list):
        raise _field_error("portfolio_item_ids", "Portfolio items must be a list.")
    ids = [str(value).strip() for value in raw_ids[:12] if str(value).strip()]
    if not ids:
        return []
    rows = list(
        db.session.execute(
            select(PortfolioItem).where(
                PortfolioItem.owner_user_id == user.id,
                PortfolioItem.public_id.in_(ids),
                PortfolioItem.status == "published",
            )
        ).scalars()
    )
    if len({row.public_id for row in rows}) != len(set(ids)):
        raise _field_error(
            "portfolio_item_ids",
            "Select only published portfolio items you own.",
        )
    return ids


def _apply_actor_content(
    application: CastingApplication,
    payload: dict[str, Any],
    *,
    user: User,
) -> None:
    if "cover_note" in payload:
        application.cover_note = (
            str(payload.get("cover_note", "")).strip()[:4000] or None
        )
    if "availability_note" in payload:
        application.availability_note = (
            str(payload.get("availability_note", "")).strip()[:2000] or None
        )
    if "answers" in payload:
        if not isinstance(payload.get("answers"), dict):
            raise _field_error("answers", "Casting answers must be an object.")
        application.answers_json = json.dumps(payload.get("answers", {}))
    if "portfolio_item_ids" in payload:
        application.portfolio_item_ids_json = json.dumps(
            _validate_portfolio_ids(user, payload.get("portfolio_item_ids"))
        )
    if "self_tape_file_id" in payload:
        raw_file_id = str(payload.get("self_tape_file_id") or "").strip()
        if not raw_file_id:
            application.self_tape_file_id = None
        else:
            file = _owned_ready_file(raw_file_id, user.id, "self_tape_file_id")
            if not file.mime_type.startswith("video/"):
                raise _field_error(
                    "self_tape_file_id",
                    "Self-tape must be a video file.",
                )
            application.self_tape_file_id = file.id


def _validate_application_submission(application: CastingApplication) -> None:
    if len((application.cover_note or "").strip()) < 20:
        raise _field_error(
            "cover_note",
            "Add a short note explaining why you fit this role.",
        )
    brief = _brief_for_requirement(application.requirement_id)
    questions = (
        _json_value(brief.casting_questions_json, []) if brief is not None else []
    )
    answers = _json_value(application.answers_json, {})
    missing = [
        str(question)
        for question in questions
        if not str(answers.get(str(question), "")).strip()
    ]
    if missing:
        raise _field_error(
            "answers",
            "Answer every casting question before submitting.",
        )


@casting_blueprint.get("/casting/roles")
def list_casting_roles() -> Response:
    user = _current_user()
    _require_actor(user)
    page = max(int(request.args.get("page", "1") or 1), 1)
    per_page = min(max(int(request.args.get("per_page", "24") or 24), 1), 50)
    query = (
        select(ProjectRequirement)
        .join(Project, ProjectRequirement.project_id == Project.id)
        .outerjoin(
            CastingRoleBrief,
            CastingRoleBrief.requirement_id == ProjectRequirement.id,
        )
        .where(
            ProjectRequirement.category == "talent",
            ProjectRequirement.status == "open",
            Project.status == "active",
            or_(
                CastingRoleBrief.application_due_at.is_(None),
                CastingRoleBrief.application_due_at >= utc_now(),
            ),
        )
    )
    search = request.args.get("q", "").strip()
    if search:
        pattern = f"%{search}%"
        query = query.where(
            or_(
                ProjectRequirement.title.ilike(pattern),
                ProjectRequirement.summary.ilike(pattern),
                Project.title.ilike(pattern),
                Project.city.has(City.name.ilike(pattern)),
            )
        )
    audition_mode = request.args.get("audition_mode", "").strip()
    if audition_mode:
        if audition_mode not in AUDITION_MODES:
            raise _field_error("audition_mode", "Audition mode is invalid.")
        query = query.where(CastingRoleBrief.audition_mode == audition_mode)
    city = request.args.get("city", "").strip()
    if city:
        query = query.where(Project.city.has(name=city))
    if request.args.get("saved") == "1":
        query = query.join(
            SavedCastingRole,
            SavedCastingRole.requirement_id == ProjectRequirement.id,
        ).where(SavedCastingRole.actor_user_id == user.id)
    total = db.session.execute(
        select(func.count()).select_from(query.order_by(None).subquery())
    ).scalar_one()
    rows = db.session.execute(
        query.order_by(ProjectRequirement.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    ).scalars()
    return jsonify(
        success(
            {
                "roles": [_role_payload(row, actor_user_id=user.id) for row in rows],
                "pagination": {
                    "page": page,
                    "per_page": per_page,
                    "total": total,
                },
            }
        )
    )


@casting_blueprint.get("/casting/roles/<public_id>")
def casting_role_detail(public_id: str) -> Response:
    user = _current_user()
    _require_actor(user)
    role = _role_or_404(public_id)
    brief = _brief_for_requirement(role.id)
    expired = bool(
        brief
        and brief.application_due_at
        and as_utc(brief.application_due_at) < utc_now()
    )
    if role.status != "open" or role.project.status != "active" or expired:
        existing = db.session.execute(
            select(CastingApplication.id).where(
                CastingApplication.requirement_id == role.id,
                CastingApplication.actor_user_id == user.id,
            )
        ).scalar_one_or_none()
        if existing is None:
            raise APIError(
                "casting.role_closed",
                "This casting role is no longer accepting applications.",
                status=410,
            )
    return jsonify(success({"role": _role_payload(role, actor_user_id=user.id)}))


@casting_blueprint.patch("/casting/roles/<public_id>")
def publish_casting_role(public_id: str) -> Response:
    user = _current_user()
    _require_director(user)
    role = _role_or_404(public_id)
    _project_for_user(role.project.public_id, user)
    payload = _json_body()
    brief = _brief_for_requirement(role.id)
    if brief is None:
        brief = CastingRoleBrief(requirement_id=role.id)
        db.session.add(brief)
    if "role_type" in payload:
        brief.role_type = str(payload.get("role_type", "")).strip()[:64] or None
    if "work_location" in payload:
        brief.work_location = (
            str(payload.get("work_location", "")).strip()[:255] or None
        )
    if "audition_mode" in payload:
        mode = str(payload.get("audition_mode", "")).strip()
        if mode and mode not in AUDITION_MODES:
            raise _field_error("audition_mode", "Audition mode is invalid.")
        brief.audition_mode = mode or None
    if "instructions" in payload:
        brief.instructions = str(payload.get("instructions", "")).strip()[:4000] or None
    if "eligibility" in payload:
        if not isinstance(payload.get("eligibility"), list):
            raise _field_error("eligibility", "Eligibility must be a list.")
        brief.eligibility_json = json.dumps(payload.get("eligibility", [])[:24])
    if "casting_questions" in payload:
        if not isinstance(payload.get("casting_questions"), list):
            raise _field_error(
                "casting_questions",
                "Casting questions must be a list.",
            )
        brief.casting_questions_json = json.dumps(
            payload.get("casting_questions", [])[:12]
        )
    if "application_due_at" in payload:
        brief.application_due_at = (
            _parse_datetime(payload["application_due_at"], "application_due_at")
            if payload.get("application_due_at")
            else None
        )
    if "sides_file_id" in payload:
        raw_file_id = str(payload.get("sides_file_id") or "").strip()
        brief.sides_file_id = (
            _owned_ready_file(raw_file_id, user.id, "sides_file_id").id
            if raw_file_id
            else None
        )
    if "contact_name" in payload:
        brief.contact_name = str(payload.get("contact_name", "")).strip()[:120] or None
    if "contact_email" in payload:
        brief.contact_email = (
            str(payload.get("contact_email", "")).strip()[:255] or None
        )
    if bool(payload.get("publish", True)):
        brief.published_at = brief.published_at or utc_now()
        role.status = "open"
    db.session.commit()
    return jsonify(success({"role": _role_payload(role)}))


@casting_blueprint.post("/casting/roles/<public_id>/save")
def save_casting_role(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    _require_actor(user)
    role = _role_or_404(public_id)
    saved = db.session.execute(
        select(SavedCastingRole).where(
            SavedCastingRole.actor_user_id == user.id,
            SavedCastingRole.requirement_id == role.id,
        )
    ).scalar_one_or_none()
    if saved is None:
        saved = SavedCastingRole(actor_user_id=user.id, requirement_id=role.id)
        db.session.add(saved)
        db.session.commit()
    return jsonify(success({"role": _role_payload(role, actor_user_id=user.id)})), 201


@casting_blueprint.delete("/casting/roles/<public_id>/save")
def unsave_casting_role(public_id: str) -> Response:
    user = _current_user()
    _require_actor(user)
    role = _role_or_404(public_id)
    saved = db.session.execute(
        select(SavedCastingRole).where(
            SavedCastingRole.actor_user_id == user.id,
            SavedCastingRole.requirement_id == role.id,
        )
    ).scalar_one_or_none()
    if saved is not None:
        db.session.delete(saved)
        db.session.commit()
    return jsonify(success({"deleted": True}))


@casting_blueprint.post("/casting/roles/<public_id>/applications")
def create_casting_application(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    _require_actor(user)
    role = _role_or_404(public_id)
    _ensure_role_accepting(role)
    existing = db.session.execute(
        select(CastingApplication).where(
            CastingApplication.requirement_id == role.id,
            CastingApplication.actor_user_id == user.id,
        )
    ).scalar_one_or_none()
    if existing is not None:
        raise APIError(
            "casting.application_exists",
            "You already have an application for this role.",
            status=409,
        )
    payload = _json_body()
    application = CastingApplication(
        requirement_id=role.id,
        actor_user_id=user.id,
        talent_profile_id=_actor_profile(user).id,
    )
    db.session.add(application)
    db.session.flush()
    _apply_actor_content(application, payload, user=user)
    if bool(payload.get("submit", False)):
        _validate_application_submission(application)
        _set_status(application, "submitted", actor=user)
        notify_user(
            role.project.owner_user_id,
            category="casting",
            title=f"New application for {role.title}",
            body=f"{application.talent_profile.screen_name} submitted an application.",
            route_name="/director/projects/:id",
            route_params={"projectId": role.project.public_id, "tab": "casting"},
        )
    role.candidate_count_cache += 1
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)})), 201


@casting_blueprint.get("/casting/applications")
def list_actor_applications() -> Response:
    user = _current_user()
    _require_actor(user)
    query = select(CastingApplication).where(
        CastingApplication.actor_user_id == user.id
    )
    status = request.args.get("status", "").strip()
    if status:
        query = query.where(CastingApplication.status == status)
    rows = db.session.execute(
        query.order_by(CastingApplication.updated_at.desc())
    ).scalars()
    return jsonify(
        success({"applications": [_application_payload(row) for row in rows]})
    )


@casting_blueprint.get("/casting/applications/<public_id>")
def actor_application_detail(public_id: str) -> Response:
    user = _current_user()
    _require_actor(user)
    return jsonify(
        success(
            {"application": _application_payload(_actor_application(public_id, user))}
        )
    )


@casting_blueprint.patch("/casting/applications/<public_id>")
def update_actor_application(public_id: str) -> Response:
    user = _current_user()
    _require_actor(user)
    application = _actor_application(public_id, user)
    if application.status != "draft":
        raise APIError(
            "casting.application_locked",
            "Only draft applications can be edited.",
            status=409,
        )
    _apply_actor_content(application, _json_body(), user=user)
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


@casting_blueprint.post("/casting/applications/<public_id>/submit")
def submit_casting_application(public_id: str) -> Response:
    user = _current_user()
    _require_actor(user)
    application = _actor_application(public_id, user)
    if application.status != "draft":
        raise APIError(
            "casting.application_already_submitted",
            "This application has already been submitted.",
            status=409,
        )
    _ensure_role_accepting(application.requirement)
    _validate_application_submission(application)
    _set_status(application, "submitted", actor=user)
    notify_user(
        application.requirement.project.owner_user_id,
        category="casting",
        title=f"New application for {application.requirement.title}",
        body=f"{application.talent_profile.screen_name} submitted an application.",
        route_name="/director/projects/:id",
        route_params={
            "projectId": application.requirement.project.public_id,
            "tab": "casting",
        },
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


@casting_blueprint.post("/casting/applications/<public_id>/withdraw")
def withdraw_casting_application(public_id: str) -> Response:
    user = _current_user()
    _require_actor(user)
    application = _actor_application(public_id, user)
    if application.status in {"selected", "rejected", "withdrawn"}:
        raise APIError(
            "casting.application_locked",
            "This application can no longer be withdrawn.",
            status=409,
        )
    _set_status(application, "withdrawn", actor=user)
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


@casting_blueprint.post("/casting/applications/<public_id>/confirm-audition")
def confirm_casting_audition(public_id: str) -> Response:
    user = _current_user()
    _require_actor(user)
    application = _actor_application(public_id, user)
    if application.status not in {
        "audition_requested",
        "self_tape_requested",
        "callback",
    }:
        raise APIError(
            "casting.audition_unavailable",
            "This application does not have an audition to confirm.",
            status=409,
        )
    application.audition_confirmed_at = utc_now()
    notify_user(
        application.requirement.project.owner_user_id,
        category="casting",
        title=f"Audition confirmed: {application.requirement.title}",
        body=f"{application.talent_profile.screen_name} confirmed attendance.",
        route_name="/director/projects/:id",
        route_params={
            "projectId": application.requirement.project.public_id,
            "tab": "casting",
        },
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


@casting_blueprint.post("/casting/applications/<public_id>/self-tape")
def submit_casting_self_tape(public_id: str) -> Response:
    user = _current_user()
    _require_actor(user)
    application = _actor_application(public_id, user)
    if application.status not in {
        "audition_requested",
        "self_tape_requested",
        "callback",
    }:
        raise APIError(
            "casting.self_tape_unavailable",
            "A self-tape has not been requested for this application.",
            status=409,
        )
    if application.audition_due_at and as_utc(application.audition_due_at) < utc_now():
        raise APIError(
            "casting.self_tape_expired",
            "The self-tape deadline has passed.",
            status=410,
        )
    payload = _json_body()
    file_id = str(payload.get("file_id", "")).strip()
    file = _owned_ready_file(file_id, user.id, "file_id")
    if not file.mime_type.startswith("video/"):
        raise _field_error("file_id", "Self-tape must be a video file.")
    application.self_tape_file_id = file.id
    if application.audition_confirmed_at is None:
        application.audition_confirmed_at = utc_now()
    notify_user(
        application.requirement.project.owner_user_id,
        category="casting",
        title=f"Self-tape received: {application.requirement.title}",
        body=f"{application.talent_profile.screen_name} submitted a self-tape.",
        route_name="/director/projects/:id",
        route_params={
            "projectId": application.requirement.project.public_id,
            "tab": "casting",
        },
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


@casting_blueprint.post("/casting/applications/<public_id>/conversation")
def ensure_casting_conversation(public_id: str) -> Response:
    user = _current_user()
    application = db.session.execute(
        select(CastingApplication).where(CastingApplication.public_id == public_id)
    ).scalar_one_or_none()
    if application is None:
        raise APIError(
            "casting.application_not_found",
            "Application was not found.",
            status=404,
        )
    if user.id != application.actor_user_id:
        _project_for_user(application.requirement.project.public_id, user)
    if application.conversation is None:
        conversation = Conversation(
            project_id=application.requirement.project_id,
            type="casting_application",
            title=(
                f"{application.requirement.title} - "
                f"{application.talent_profile.screen_name}"
            )[:180],
        )
        db.session.add(conversation)
        db.session.flush()
        db.session.add_all(
            [
                ConversationMember(
                    conversation_id=conversation.id,
                    user_id=application.actor_user_id,
                ),
                ConversationMember(
                    conversation_id=conversation.id,
                    user_id=application.requirement.project.owner_user_id,
                ),
            ]
        )
        application.conversation = conversation
        db.session.commit()
    return jsonify(
        success(
            {
                "conversation_id": application.conversation.public_id,
                "application": _application_payload(application),
            }
        )
    )


@casting_blueprint.get("/director/projects/<public_id>/casting-applications")
def list_director_casting_applications(public_id: str) -> Response:
    user = _current_user()
    _require_director(user)
    project = _project_for_user(public_id, user)
    rows = list(
        db.session.execute(
            select(CastingApplication)
            .join(ProjectRequirement)
            .where(
                ProjectRequirement.project_id == project.id,
                CastingApplication.status != "draft",
            )
            .order_by(CastingApplication.updated_at.desc())
        ).scalars()
    )
    changed = False
    for row in rows:
        if row.status == "submitted":
            _set_status(row, "viewed", actor=user)
            changed = True
            notify_user(
                row.actor_user_id,
                category="casting",
                title=f"Application viewed: {row.requirement.title}",
                body=f"{project.title} viewed your application.",
                route_name="/talent/applications/:id",
                route_params={"id": row.public_id},
            )
    if changed:
        db.session.commit()
    return jsonify(
        success({"applications": [_application_payload(row) for row in rows]})
    )


@casting_blueprint.patch("/director/casting-applications/<public_id>")
def update_director_casting_application(public_id: str) -> Response:
    user = _current_user()
    _require_director(user)
    application = _director_application(public_id, user)
    payload = _json_body()
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in DIRECTOR_STATUSES:
            raise _field_error("status", "Director application status is invalid.")
        allowed = DIRECTOR_TRANSITIONS.get(application.status, set())
        if status != application.status and status not in allowed:
            raise APIError(
                "casting.invalid_status_transition",
                (
                    "Application cannot move from "
                    f"{application.status.replace('_', ' ')} "
                    f"to {status.replace('_', ' ')}."
                ),
                status=409,
            )
        _set_status(
            application,
            status,
            actor=user,
            note=str(payload.get("note", "")).strip() or None,
        )
        if status != "rejected":
            application.rejection_reason = None
    if "rejection_reason" in payload:
        if application.status != "rejected":
            raise _field_error(
                "rejection_reason",
                "A rejection reason requires rejected status.",
            )
        application.rejection_reason = (
            str(payload.get("rejection_reason", "")).strip()[:2000] or None
        )
    for key, attribute in (
        ("audition_location", "audition_location"),
        ("audition_online_url", "audition_online_url"),
        ("audition_instructions", "audition_instructions"),
        ("audition_contact", "audition_contact"),
        ("callback_details", "callback_details"),
    ):
        if key in payload:
            setattr(
                application,
                attribute,
                str(payload.get(key, "")).strip()[:4000] or None,
            )
    for key, attribute in (
        ("audition_at", "audition_at"),
        ("audition_due_at", "audition_due_at"),
        ("callback_at", "callback_at"),
    ):
        if key in payload:
            setattr(
                application,
                attribute,
                _parse_datetime(payload[key], key) if payload.get(key) else None,
            )
    db.session.flush()
    notify_user(
        application.actor_user_id,
        category="casting",
        title=f"Application update: {application.requirement.title}",
        body=f"Your status is now {application.status.replace('_', ' ')}.",
        route_name="/talent/applications/:id",
        route_params={"id": application.public_id},
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))
