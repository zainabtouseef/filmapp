from __future__ import annotations

import json
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import func, or_, select

from app.api.auth import _current_user, _json_body
from app.api.bookings import _user_payload
from app.api.casting import _has_role, _require_director
from app.api.marketplace import _field_error, _file_payload, _has_approved_kyc_for_role
from app.api.operations import _parse_datetime
from app.api.projects import _project_for_user
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.casting import SavedCastingRole
from app.models.identity import User
from app.models.marketplace import City
from app.models.opportunities import (
    RequirementApplication,
    RequirementApplicationStatusEvent,
)
from app.models.projects import Project, ProjectRequirement
from app.models.scheduling import MeetingRound
from app.responses import success
from app.services.notifications import notify_user
from app.services.scheduling import (
    accept_round,
    decline_round,
    get_or_create_thread,
    propose_round,
    round_for_public_id,
    thread_for_subject,
    thread_payload,
)

opportunities_blueprint = Blueprint("opportunities", __name__)

# Categories browsable through this generic module — talent keeps using the
# dedicated casting.py flow (it carries a TalentProfile + acting-specific
# fields — audition mode, self-tape, etc. — that don't apply here). Model
# applicants don't need any of that, so they use this simpler flow too even
# though a Model's identity happens to be backed by a TalentProfile row.
OPEN_CATEGORIES = ("model", "location", "equipment", "crew")
CATEGORY_ROLE_CODES = {
    "model": "model",
    "location": "location_owner",
    "equipment": "equipment_provider",
    "crew": "crew_service",
}

APPLICATION_STATUSES = {
    "draft",
    "submitted",
    "viewed",
    "shortlisted",
    "meeting_requested",
    "selected",
    "rejected",
    "withdrawn",
}
DIRECTOR_STATUSES = APPLICATION_STATUSES - {"draft", "submitted", "withdrawn"}
DIRECTOR_TRANSITIONS = {
    "submitted": {"viewed", "shortlisted", "meeting_requested", "selected", "rejected"},
    "viewed": {"shortlisted", "meeting_requested", "selected", "rejected"},
    "shortlisted": {"meeting_requested", "selected", "rejected"},
    "meeting_requested": {"selected", "rejected"},
    "selected": set(),
    "rejected": set(),
    "withdrawn": set(),
}


def _require_provider(user: User, category: str) -> None:
    role_code = CATEGORY_ROLE_CODES.get(category)
    if role_code is None or not _has_role(user, role_code, "super_admin"):
        raise APIError(
            "opportunities.provider_role_required",
            "You need the matching provider role to do this.",
            status=403,
        )


def _provider_is_verified(user: User, category: str) -> bool:
    role_code = CATEGORY_ROLE_CODES.get(category, "")
    return _has_approved_kyc_for_role(user.id, role_code)


def _role_or_404(public_id: str) -> ProjectRequirement:
    role = db.session.execute(
        select(ProjectRequirement).where(
            ProjectRequirement.public_id == public_id,
            ProjectRequirement.category.in_(OPEN_CATEGORIES),
        )
    ).scalar_one_or_none()
    if role is None:
        raise APIError(
            "opportunities.role_not_found",
            "Opportunity was not found.",
            status=404,
        )
    return role


def _ensure_role_accepting(role: ProjectRequirement) -> None:
    if role.status != "open" or role.project.status != "active":
        raise APIError(
            "opportunities.role_closed",
            "This opportunity is no longer accepting applications.",
            status=409,
        )


def _role_payload(
    requirement: ProjectRequirement,
    *,
    applicant_user_id: object | None = None,
) -> dict[str, Any]:
    saved = False
    application_id = None
    application_status = None
    if applicant_user_id is not None:
        saved = (
            db.session.execute(
                select(SavedCastingRole.id).where(
                    SavedCastingRole.actor_user_id == applicant_user_id,
                    SavedCastingRole.requirement_id == requirement.id,
                )
            ).scalar_one_or_none()
            is not None
        )
        application = db.session.execute(
            select(RequirementApplication).where(
                RequirementApplication.applicant_user_id == applicant_user_id,
                RequirementApplication.requirement_id == requirement.id,
            )
        ).scalar_one_or_none()
        if application is not None:
            application_id = application.public_id
            application_status = application.status

    project = requirement.project
    return {
        "public_id": requirement.public_id,
        "category": requirement.category,
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
        "visibility": requirement.visibility,
        "quantity": requirement.quantity,
        "required_documents": (
            json.loads(requirement.required_documents_json)
            if requirement.required_documents_json
            else []
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
        "application_count": requirement.candidate_count_cache,
        "saved": saved,
        "application_id": application_id,
        "application_status": application_status,
        "created_at": requirement.created_at.isoformat(),
    }


def _status_event_payload(item: RequirementApplicationStatusEvent) -> dict[str, Any]:
    return {
        "from_status": item.from_status,
        "to_status": item.to_status,
        "note": item.note,
        "changed_by": _user_payload(item.actor) if item.actor else None,
        "created_at": item.created_at.isoformat(),
    }


def _application_payload(item: RequirementApplication) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "role": _role_payload(
            item.requirement, applicant_user_id=item.applicant_user_id
        ),
        "applicant": {
            **_user_payload(item.applicant),
        },
        "status": item.status,
        "cover_note": item.cover_note,
        "answers": json.loads(item.answers_json) if item.answers_json else {},
        "attachment_files": [
            _file_payload_for_id(file_id)
            for file_id in (
                json.loads(item.attachment_file_ids_json)
                if item.attachment_file_ids_json
                else []
            )
        ],
        "rejection_reason": item.rejection_reason,
        "submitted_at": item.submitted_at.isoformat() if item.submitted_at else None,
        "withdrawn_at": item.withdrawn_at.isoformat() if item.withdrawn_at else None,
        "meeting": {
            "at": item.meeting_at.isoformat() if item.meeting_at else None,
            "location": item.meeting_location,
            "online_url": item.meeting_online_url,
            "instructions": item.meeting_instructions,
            "contact": item.meeting_contact,
            "confirmed_at": (
                item.meeting_confirmed_at.isoformat()
                if item.meeting_confirmed_at
                else None
            ),
        },
        "meeting_thread": thread_payload(
            thread_for_subject("requirement_application", item.public_id)
        ),
        "status_events": [_status_event_payload(row) for row in item.status_events],
        "created_at": item.created_at.isoformat(),
        "updated_at": item.updated_at.isoformat(),
    }


def _file_payload_for_id(public_id: str) -> dict[str, Any] | None:
    from app.models.files import FileAsset

    file = db.session.execute(
        select(FileAsset).where(FileAsset.public_id == public_id)
    ).scalar_one_or_none()
    return _file_payload(file)


def _set_status(
    application: RequirementApplication,
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
    if status == "withdrawn":
        application.withdrawn_at = utc_now()
    db.session.add(
        RequirementApplicationStatusEvent(
            application_id=application.id,
            actor_user_id=actor.id,
            from_status=previous,
            to_status=status,
            note=note[:2000] if note else None,
        )
    )


def _apply_meeting_snapshot(
    application: RequirementApplication, round_: MeetingRound
) -> None:
    """Sync the accepted round onto the legacy flat display columns."""
    application.meeting_at = round_.meeting_at
    application.meeting_location = round_.location
    application.meeting_online_url = round_.online_url
    application.meeting_instructions = round_.instructions
    application.meeting_contact = round_.contact
    application.meeting_confirmed_at = utc_now()


def _application_or_404(public_id: str) -> RequirementApplication:
    application = db.session.execute(
        select(RequirementApplication).where(
            RequirementApplication.public_id == public_id
        )
    ).scalar_one_or_none()
    if application is None:
        raise APIError(
            "opportunities.application_not_found",
            "Application was not found.",
            status=404,
        )
    return application


@opportunities_blueprint.get("/opportunities/roles")
def list_opportunity_roles() -> Response:
    user = _current_user()
    category = request.args.get("category", "").strip()
    if category not in OPEN_CATEGORIES:
        raise _field_error("category", "Unsupported opportunity category.")
    _require_provider(user, category)
    page = max(int(request.args.get("page", "1") or 1), 1)
    per_page = min(max(int(request.args.get("per_page", "24") or 24), 1), 50)
    query = (
        select(ProjectRequirement)
        .join(Project, ProjectRequirement.project_id == Project.id)
        .where(
            ProjectRequirement.category == category,
            ProjectRequirement.status == "open",
            Project.status == "active",
        )
    )
    if not _provider_is_verified(user, category):
        query = query.where(ProjectRequirement.visibility != "verified_only")
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
                "roles": [
                    _role_payload(row, applicant_user_id=user.id) for row in rows
                ],
                "pagination": {"page": page, "per_page": per_page, "total": total},
            }
        )
    )


@opportunities_blueprint.get("/opportunities/roles/<public_id>")
def get_opportunity_role(public_id: str) -> Response:
    user = _current_user()
    role = _role_or_404(public_id)
    _require_provider(user, role.category)
    return jsonify(success({"role": _role_payload(role, applicant_user_id=user.id)}))


@opportunities_blueprint.post("/opportunities/roles/<public_id>/save")
def save_opportunity_role(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    role = _role_or_404(public_id)
    _require_provider(user, role.category)
    existing = db.session.execute(
        select(SavedCastingRole).where(
            SavedCastingRole.actor_user_id == user.id,
            SavedCastingRole.requirement_id == role.id,
        )
    ).scalar_one_or_none()
    if existing is None:
        db.session.add(SavedCastingRole(actor_user_id=user.id, requirement_id=role.id))
        db.session.commit()
    return jsonify(
        success({"role": _role_payload(role, applicant_user_id=user.id)})
    ), 201


@opportunities_blueprint.delete("/opportunities/roles/<public_id>/save")
def unsave_opportunity_role(public_id: str) -> Response:
    user = _current_user()
    role = _role_or_404(public_id)
    existing = db.session.execute(
        select(SavedCastingRole).where(
            SavedCastingRole.actor_user_id == user.id,
            SavedCastingRole.requirement_id == role.id,
        )
    ).scalar_one_or_none()
    if existing is not None:
        db.session.delete(existing)
        db.session.commit()
    return jsonify(success({"role": _role_payload(role, applicant_user_id=user.id)}))


@opportunities_blueprint.post("/opportunities/roles/<public_id>/applications")
def create_opportunity_application(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    role = _role_or_404(public_id)
    _require_provider(user, role.category)
    _ensure_role_accepting(role)
    if role.visibility == "verified_only" and not _provider_is_verified(
        user, role.category
    ):
        raise APIError(
            "opportunities.verified_only",
            "This opportunity is only open to verified profiles.",
            status=403,
        )
    existing = db.session.execute(
        select(RequirementApplication).where(
            RequirementApplication.requirement_id == role.id,
            RequirementApplication.applicant_user_id == user.id,
        )
    ).scalar_one_or_none()
    if existing is not None:
        raise APIError(
            "opportunities.application_exists",
            "You already have an application for this opportunity.",
            status=409,
        )
    payload = _json_body()
    cover_note = str(payload.get("cover_note", "")).strip()
    attachment_ids = payload.get("attachment_file_ids")
    if attachment_ids is not None and not isinstance(attachment_ids, list):
        raise _field_error("attachment_file_ids", "Attachments must be a list.")
    application = RequirementApplication(
        requirement_id=role.id,
        applicant_user_id=user.id,
        cover_note=cover_note[:4000] or None,
        answers_json=(
            json.dumps(payload.get("answers"))
            if isinstance(payload.get("answers"), dict)
            else None
        ),
        attachment_file_ids_json=(
            json.dumps([str(item).strip() for item in attachment_ids][:12])
            if attachment_ids
            else None
        ),
    )
    db.session.add(application)
    db.session.flush()
    if bool(payload.get("submit", True)):
        if len(cover_note) < 10:
            raise _field_error(
                "cover_note", "Add a short note explaining why you fit this."
            )
        _set_status(application, "submitted", actor=user)
        notify_user(
            role.project.owner_user_id,
            category="opportunities",
            title=f"New application for {role.title}",
            body=f"{user.display_name} applied to {role.title}.",
            route_name="/director/projects/:id",
            route_params={"projectId": role.project.public_id, "tab": "opportunities"},
        )
    role.candidate_count_cache += 1
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)})), 201


@opportunities_blueprint.get("/opportunities/applications")
def list_my_opportunity_applications() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(RequirementApplication)
        .where(
            RequirementApplication.applicant_user_id == user.id,
            RequirementApplication.status != "draft",
        )
        .order_by(RequirementApplication.updated_at.desc())
    ).scalars()
    return jsonify(
        success({"applications": [_application_payload(row) for row in rows]})
    )


@opportunities_blueprint.get("/opportunities/applications/<public_id>")
def get_my_opportunity_application(public_id: str) -> Response:
    user = _current_user()
    application = _application_or_404(public_id)
    if application.applicant_user_id != user.id:
        raise APIError(
            "opportunities.application_not_found",
            "Application was not found.",
            status=404,
        )
    return jsonify(success({"application": _application_payload(application)}))


@opportunities_blueprint.post("/opportunities/applications/<public_id>/withdraw")
def withdraw_opportunity_application(public_id: str) -> Response:
    user = _current_user()
    application = _application_or_404(public_id)
    if application.applicant_user_id != user.id:
        raise APIError(
            "opportunities.application_not_found",
            "Application was not found.",
            status=404,
        )
    _set_status(application, "withdrawn", actor=user)
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


def _provider_application(public_id: str, user: User) -> RequirementApplication:
    application = _application_or_404(public_id)
    if application.applicant_user_id != user.id:
        raise APIError(
            "opportunities.application_not_found",
            "Application was not found.",
            status=404,
        )
    return application


@opportunities_blueprint.get("/opportunities/applications/<public_id>/meetings")
def list_opportunity_meetings(public_id: str) -> Response:
    user = _current_user()
    application = _provider_application(public_id, user)
    thread = thread_for_subject("requirement_application", application.public_id)
    return jsonify(success({"thread": thread_payload(thread)}))


@opportunities_blueprint.post(
    "/opportunities/applications/<public_id>/meetings/propose"
)
def propose_opportunity_meeting(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    application = _provider_application(public_id, user)
    payload = _json_body()
    thread = get_or_create_thread("requirement_application", application.public_id)
    propose_round(
        thread,
        user,
        meeting_at=_parse_datetime(payload.get("meeting_at"), "meeting_at"),
        location=str(payload.get("location", "")).strip()[:255] or None,
        online_url=str(payload.get("online_url", "")).strip()[:255] or None,
        instructions=str(payload.get("instructions", "")).strip()[:4000] or None,
        contact=str(payload.get("contact", "")).strip()[:255] or None,
        meeting_kind=str(payload.get("meeting_kind", "")).strip()[:32] or None,
        message=str(payload.get("message", "")).strip()[:2000] or None,
    )
    notify_user(
        application.requirement.project.owner_user_id,
        category="opportunities",
        title=f"New meeting proposal: {application.requirement.title}",
        body=f"{user.display_name} proposed a new meeting time.",
        route_name="/director/projects/:id",
        route_params={
            "projectId": application.requirement.project.public_id,
            "tab": "opportunities",
        },
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)})), 201


@opportunities_blueprint.post(
    "/opportunities/applications/<public_id>/meetings/rounds/<round_public_id>/accept"
)
def accept_opportunity_meeting(public_id: str, round_public_id: str) -> Response:
    user = _current_user()
    application = _provider_application(public_id, user)
    round_ = round_for_public_id(
        "requirement_application", application.public_id, round_public_id
    )
    accept_round(round_, user)
    _apply_meeting_snapshot(application, round_)
    notify_user(
        application.requirement.project.owner_user_id,
        category="opportunities",
        title=f"Meeting confirmed: {application.requirement.title}",
        body=f"{user.display_name} accepted the meeting time.",
        route_name="/director/projects/:id",
        route_params={
            "projectId": application.requirement.project.public_id,
            "tab": "opportunities",
        },
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


@opportunities_blueprint.post(
    "/opportunities/applications/<public_id>/meetings/rounds/<round_public_id>/decline"
)
def decline_opportunity_meeting(public_id: str, round_public_id: str) -> Response:
    user = _current_user()
    application = _provider_application(public_id, user)
    round_ = round_for_public_id(
        "requirement_application", application.public_id, round_public_id
    )
    payload = _json_body()
    decline_round(round_, user, str(payload.get("reason", "")).strip() or None)
    notify_user(
        application.requirement.project.owner_user_id,
        category="opportunities",
        title=f"Meeting time declined: {application.requirement.title}",
        body=f"{user.display_name} declined the proposed meeting time.",
        route_name="/director/projects/:id",
        route_params={
            "projectId": application.requirement.project.public_id,
            "tab": "opportunities",
        },
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


@opportunities_blueprint.get("/director/projects/<public_id>/opportunity-applications")
def list_director_opportunity_applications(public_id: str) -> Response:
    user = _current_user()
    _require_director(user)
    project = _project_for_user(public_id, user)
    rows = list(
        db.session.execute(
            select(RequirementApplication)
            .join(ProjectRequirement)
            .where(
                ProjectRequirement.project_id == project.id,
                ProjectRequirement.category.in_(OPEN_CATEGORIES),
                RequirementApplication.status != "draft",
            )
            .order_by(RequirementApplication.updated_at.desc())
        ).scalars()
    )
    changed = False
    for row in rows:
        if row.status == "submitted":
            _set_status(row, "viewed", actor=user)
            changed = True
            notify_user(
                row.applicant_user_id,
                category="opportunities",
                title=f"Application viewed: {row.requirement.title}",
                body=f"{project.title} viewed your application.",
                route_name="/opportunities/applications/:id",
                route_params={"id": row.public_id},
            )
    if changed:
        db.session.commit()
    return jsonify(
        success({"applications": [_application_payload(row) for row in rows]})
    )


@opportunities_blueprint.patch("/director/opportunity-applications/<public_id>")
def update_director_opportunity_application(public_id: str) -> Response:
    user = _current_user()
    _require_director(user)
    application = _application_or_404(public_id)
    _project_for_user(application.requirement.project.public_id, user)
    payload = _json_body()
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in DIRECTOR_STATUSES:
            raise _field_error("status", "Application status is invalid.")
        allowed = DIRECTOR_TRANSITIONS.get(application.status, set())
        if status != application.status and status not in allowed:
            raise APIError(
                "opportunities.invalid_status_transition",
                (
                    "Application cannot move from "
                    f"{application.status.replace('_', ' ')} "
                    f"to {status.replace('_', ' ')}."
                ),
                status=409,
            )
        note = str(payload.get("note", "")).strip() or None
        if status == "rejected":
            application.rejection_reason = note
        _set_status(application, status, actor=user, note=note)
        status_label = status.replace("_", " ")
        notify_user(
            application.applicant_user_id,
            category="opportunities",
            title=f"Application {status_label}: {application.requirement.title}",
            body=f"Your application status changed to {status_label}.",
            route_name="/opportunities/applications/:id",
            route_params={"id": application.public_id},
        )
    for key, attribute in (
        ("meeting_location", "meeting_location"),
        ("meeting_online_url", "meeting_online_url"),
        ("meeting_instructions", "meeting_instructions"),
        ("meeting_contact", "meeting_contact"),
    ):
        if key in payload:
            setattr(
                application,
                attribute,
                str(payload.get(key, "")).strip()[:4000] or None,
            )
    if "meeting_at" in payload:
        application.meeting_at = (
            _parse_datetime(payload["meeting_at"], "meeting_at")
            if payload.get("meeting_at")
            else None
        )
    if (
        "status" in payload
        and status == "meeting_requested"
        and thread_for_subject("requirement_application", application.public_id) is None
        and application.meeting_at is not None
    ):
        thread = get_or_create_thread("requirement_application", application.public_id)
        propose_round(
            thread,
            user,
            meeting_at=application.meeting_at,
            location=application.meeting_location,
            online_url=application.meeting_online_url,
            instructions=application.meeting_instructions,
            contact=application.meeting_contact,
            meeting_kind=str(payload.get("meeting_kind", "")).strip()[:32] or None,
            message=note,
        )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


def _director_application(public_id: str, user: User) -> RequirementApplication:
    application = _application_or_404(public_id)
    _project_for_user(application.requirement.project.public_id, user)
    return application


@opportunities_blueprint.get("/director/opportunity-applications/<public_id>/meetings")
def list_director_opportunity_meetings(public_id: str) -> Response:
    user = _current_user()
    _require_director(user)
    application = _director_application(public_id, user)
    thread = thread_for_subject("requirement_application", application.public_id)
    return jsonify(success({"thread": thread_payload(thread)}))


@opportunities_blueprint.post(
    "/director/opportunity-applications/<public_id>/meetings/propose"
)
def propose_director_opportunity_meeting(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    _require_director(user)
    application = _director_application(public_id, user)
    payload = _json_body()
    thread = get_or_create_thread("requirement_application", application.public_id)
    propose_round(
        thread,
        user,
        meeting_at=_parse_datetime(payload.get("meeting_at"), "meeting_at"),
        location=str(payload.get("location", "")).strip()[:255] or None,
        online_url=str(payload.get("online_url", "")).strip()[:255] or None,
        instructions=str(payload.get("instructions", "")).strip()[:4000] or None,
        contact=str(payload.get("contact", "")).strip()[:255] or None,
        meeting_kind=str(payload.get("meeting_kind", "")).strip()[:32] or None,
        message=str(payload.get("message", "")).strip()[:2000] or None,
    )
    notify_user(
        application.applicant_user_id,
        category="opportunities",
        title=f"New meeting proposal: {application.requirement.title}",
        body=f"{application.requirement.project.title} proposed a new meeting time.",
        route_name="/opportunities/applications/:id",
        route_params={"id": application.public_id},
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)})), 201


@opportunities_blueprint.post(
    "/director/opportunity-applications/<public_id>/meetings/rounds/<round_public_id>/accept"
)
def accept_director_opportunity_meeting(
    public_id: str, round_public_id: str
) -> Response:
    user = _current_user()
    _require_director(user)
    application = _director_application(public_id, user)
    round_ = round_for_public_id(
        "requirement_application", application.public_id, round_public_id
    )
    accept_round(round_, user)
    _apply_meeting_snapshot(application, round_)
    notify_user(
        application.applicant_user_id,
        category="opportunities",
        title=f"Meeting confirmed: {application.requirement.title}",
        body=f"{application.requirement.project.title} accepted the meeting time.",
        route_name="/opportunities/applications/:id",
        route_params={"id": application.public_id},
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))


@opportunities_blueprint.post(
    "/director/opportunity-applications/<public_id>/meetings/rounds/<round_public_id>/decline"
)
def decline_director_opportunity_meeting(
    public_id: str, round_public_id: str
) -> Response:
    user = _current_user()
    _require_director(user)
    application = _director_application(public_id, user)
    round_ = round_for_public_id(
        "requirement_application", application.public_id, round_public_id
    )
    payload = _json_body()
    decline_round(round_, user, str(payload.get("reason", "")).strip() or None)
    notify_user(
        application.applicant_user_id,
        category="opportunities",
        title=f"Meeting time declined: {application.requirement.title}",
        body=(
            f"{application.requirement.project.title} declined "
            "the proposed meeting time."
        ),
        route_name="/opportunities/applications/:id",
        route_params={"id": application.public_id},
    )
    db.session.commit()
    return jsonify(success({"application": _application_payload(application)}))
