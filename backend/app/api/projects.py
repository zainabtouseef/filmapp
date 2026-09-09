from __future__ import annotations

import json
from datetime import date
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import desc, select

from app.api.auth import _current_user, _json_body
from app.api.marketplace import (
    _city_by_public_id,
    _city_payload,
    _field_error,
    _file_payload,
)
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.files import FileAsset
from app.models.identity import User
from app.models.marketplace import City
from app.models.projects import (
    Project,
    ProjectFile,
    ProjectMember,
    ProjectRequirement,
    ProjectRoomItem,
    RequirementSkill,
    Skill,
)
from app.responses import success
from app.services.cineplanner_productions import ensure_cineplanner_production

projects_blueprint = Blueprint("projects", __name__)

PROJECT_STATUSES = {
    "draft",
    "active",
    "paused",
    "completed",
    "cancelled",
    "archived",
}
PROJECT_VISIBILITIES = {"private", "project_members"}
REQUIREMENT_CATEGORIES = {
    "talent",
    "model",
    "crew",
    "location",
    "equipment",
    "service",
    "legal",
    "distribution",
}
REQUIREMENT_STATUSES = {"draft", "open", "paused", "filled", "closed", "archived"}
REQUIREMENT_VISIBILITIES = {"all", "verified_only"}
PROJECT_FILE_FOLDERS = {
    "briefs",
    "scripts",
    "contracts",
    "references",
    "deliverables",
    "trailer",
    "ost",
}
PUBLIC_CINEMA_FOLDERS = {"trailer", "ost"}
PROJECT_ROOM_ITEM_TYPES = {"note", "decision", "activity", "milestone"}


def _optional_int(value: Any, field: str) -> int | None:
    if value in {None, ""}:
        return None
    try:
        return int(str(value))
    except ValueError as exc:
        raise _field_error(field, "Value must be an integer.") from exc


def _optional_date(value: Any, field: str) -> date | None:
    if value in {None, ""}:
        return None
    if not isinstance(value, str):
        raise _field_error(field, "Date must be formatted as YYYY-MM-DD.")
    value = value.split("T", 1)[0]
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise _field_error(field, "Date must be formatted as YYYY-MM-DD.") from exc


def _has_role(user: User, *role_codes: str) -> bool:
    return any(
        user_role.status == "active" and user_role.role.code in role_codes
        for user_role in user.roles
    )


def _require_project_creator(user: User) -> None:
    if not _has_role(
        user,
        "director_producer",
        "casting_agency",
        "brand_sponsor",
        "super_admin",
    ):
        raise APIError(
            "projects.role_required",
            "A director/producer, casting agency, or brand role is required for "
            "projects.",
            status=403,
        )


def _member_permissions_payload(member: ProjectMember) -> dict[str, Any]:
    if not member.permissions_json:
        return {}
    try:
        payload = json.loads(member.permissions_json)
    except json.JSONDecodeError:
        return {}
    return payload if isinstance(payload, dict) else {}


def _member_payload(member: ProjectMember) -> dict[str, Any]:
    return {
        "user": {
            "public_id": member.user.public_id,
            "display_name": member.user.display_name,
        },
        "role_label": member.role_label,
        "permissions": _member_permissions_payload(member),
        "status": member.status,
    }


def _project_file_payload(item: ProjectFile) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "file": _file_payload(item.file),
        "folder": item.folder,
        "label": item.label,
        "external_url": item.external_url,
        "external_provider": item.external_provider,
        "external_thumbnail_url": item.external_thumbnail_url,
        "external_duration_seconds": item.external_duration_seconds,
        "uploaded_by": {
            "public_id": item.uploader.public_id,
            "display_name": item.uploader.display_name,
        }
        if item.uploader
        else None,
        "visibility": item.visibility,
        "sort_order": item.sort_order,
        "created_at": item.created_at.isoformat(),
    }


def _public_cinema_payload(item: ProjectFile) -> dict[str, Any]:
    project = item.project
    file_payload = _file_payload(item.file)
    file_name = item.file.original_name if item.file else None
    return {
        "public_id": item.public_id,
        "kind": item.folder,
        "title": item.label or file_name or project.title,
        "project": {
            "public_id": project.public_id,
            "title": project.title,
            "project_type": project.project_type,
            "description": project.description,
            "city": _city_payload(project.city),
            "cover_file": _file_payload(project.cover_file),
            "start_date": project.start_date.isoformat()
            if project.start_date
            else None,
            "end_date": project.end_date.isoformat() if project.end_date else None,
            "status": project.status,
            "estimated_budget_minor": project.estimated_budget_minor,
            "currency": project.currency,
            "visibility": project.visibility,
            "progress_percent": project.progress_percent,
            "requirement_count": len(project.requirements),
            "member_count": len(
                [row for row in project.members if row.status == "active"]
            ),
        },
        "file": file_payload,
        "external_url": item.external_url,
        "external_provider": item.external_provider,
        "external_thumbnail_url": item.external_thumbnail_url,
        "external_duration_seconds": item.external_duration_seconds,
        "uploaded_by": {
            "public_id": item.uploader.public_id,
            "display_name": item.uploader.display_name,
        }
        if item.uploader
        else None,
        "created_at": item.created_at.isoformat(),
    }


def _room_item_payload(item: ProjectRoomItem) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "item_type": item.item_type,
        "title": item.title,
        "body": item.body,
        "linked_entity_type": item.linked_entity_type,
        "linked_entity_id": item.linked_entity_id,
        "created_by": {
            "public_id": item.creator.public_id,
            "display_name": item.creator.display_name,
        }
        if item.creator
        else None,
        "pinned_at": item.pinned_at.isoformat() if item.pinned_at else None,
        "created_at": item.created_at.isoformat(),
    }


def _skill_payload(skill: Skill) -> dict[str, Any]:
    return {
        "public_id": skill.public_id,
        "category": skill.category,
        "name": skill.name,
        "active": skill.active,
    }


def _requirement_skill_payload(item: RequirementSkill) -> dict[str, Any]:
    return {
        "skill": _skill_payload(item.skill),
        "required": item.required,
        "minimum_level": item.minimum_level,
    }


def _requirement_payload(item: ProjectRequirement) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "project_id": item.project.public_id,
        "category": item.category,
        "title": item.title,
        "summary": item.summary,
        "budget_min_minor": item.budget_min_minor,
        "budget_max_minor": item.budget_max_minor,
        "currency": item.currency,
        "start_date": item.start_date.isoformat() if item.start_date else None,
        "end_date": item.end_date.isoformat() if item.end_date else None,
        "status": item.status,
        "candidate_count_cache": item.candidate_count_cache,
        "visibility": item.visibility,
        "quantity": item.quantity,
        "required_documents": (
            json.loads(item.required_documents_json)
            if item.required_documents_json
            else []
        ),
        "skills": [_requirement_skill_payload(row) for row in item.skills],
        "created_at": item.created_at.isoformat(),
    }


def _project_payload(
    project: Project, *, include_nested: bool = False
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "public_id": project.public_id,
        "owner": {
            "public_id": project.owner.public_id,
            "display_name": project.owner.display_name,
        },
        "organization_id": project.organization_id,
        "title": project.title,
        "project_type": project.project_type,
        "description": project.description,
        "city": _city_payload(project.city),
        "cover_file": _file_payload(project.cover_file),
        "start_date": project.start_date.isoformat() if project.start_date else None,
        "end_date": project.end_date.isoformat() if project.end_date else None,
        "status": project.status,
        "estimated_budget_minor": project.estimated_budget_minor,
        "currency": project.currency,
        "visibility": project.visibility,
        "progress_percent": project.progress_percent,
        "requirement_count": len(project.requirements),
        "member_count": len([row for row in project.members if row.status == "active"]),
        "created_at": project.created_at.isoformat(),
        "updated_at": project.updated_at.isoformat(),
    }
    if include_nested:
        payload["members"] = [_member_payload(row) for row in project.members]
        payload["requirements"] = [
            _requirement_payload(row) for row in project.requirements
        ]
    return payload


def _project_for_user(public_id: str, user: User) -> Project:
    project = db.session.execute(
        select(Project)
        .join(ProjectMember, ProjectMember.project_id == Project.id)
        .where(
            Project.public_id == public_id,
            ProjectMember.user_id == user.id,
            ProjectMember.status == "active",
        )
    ).scalar_one_or_none()
    if project is None:
        raise APIError("project.not_found", "Project was not found.", status=404)
    return project


def _requirement_for_user(public_id: str, user: User) -> ProjectRequirement:
    requirement = db.session.execute(
        select(ProjectRequirement)
        .join(Project, ProjectRequirement.project_id == Project.id)
        .join(ProjectMember, ProjectMember.project_id == Project.id)
        .where(
            ProjectRequirement.public_id == public_id,
            ProjectMember.user_id == user.id,
            ProjectMember.status == "active",
        )
    ).scalar_one_or_none()
    if requirement is None:
        raise APIError(
            "requirement.not_found", "Project requirement was not found.", status=404
        )
    return requirement


def _sync_requirement_skills(requirement: ProjectRequirement, skill_items: Any) -> None:
    if skill_items is None:
        return
    if not isinstance(skill_items, list):
        raise _field_error("skills", "Skills must be a list.")
    requirement.skills.clear()
    for raw_item in skill_items[:24]:
        if isinstance(raw_item, str):
            public_id = raw_item
            required = True
            minimum_level = None
        elif isinstance(raw_item, dict):
            public_id = str(raw_item.get("skill_id", "")).strip()
            required = bool(raw_item.get("required", True))
            minimum_level = str(raw_item.get("minimum_level", "")).strip()[:32] or None
        else:
            continue
        if not public_id:
            continue
        skill = db.session.execute(
            select(Skill).where(Skill.public_id == public_id, Skill.active.is_(True))
        ).scalar_one_or_none()
        if skill is None:
            raise _field_error("skills", f"Unsupported skill id: {public_id}.")
        requirement.skills.append(
            RequirementSkill(
                skill_id=skill.id,
                required=required,
                minimum_level=minimum_level,
            )
        )


def _owned_ready_project_file(public_id: str | None, user: User) -> FileAsset:
    if not public_id:
        raise _field_error("file_id", "File id is required.")
    file = db.session.execute(
        select(FileAsset).where(
            FileAsset.public_id == public_id,
            FileAsset.owner_user_id == user.id,
        )
    ).scalar_one_or_none()
    if file is None:
        raise _field_error("file_id", "Select a file owned by the current user.")
    if file.scan_status != "clean" or file.processing_status != "ready":
        raise _field_error("file_id", "File must be clean and ready before linking.")
    return file


def _owned_public_project_cover(public_id: str | None, user: User) -> FileAsset | None:
    if public_id in {None, ""}:
        return None
    file = _owned_ready_project_file(public_id, user)
    if file.visibility != "public":
        raise _field_error("cover_file_id", "Project cover image must be public.")
    if not file.mime_type.startswith("image/"):
        raise _field_error("cover_file_id", "Project cover must be an image file.")
    return file


def _apply_project_payload(
    project: Project, payload: dict[str, Any], *, actor: User
) -> None:
    if "title" in payload:
        title = str(payload.get("title", "")).strip()
        if len(title) < 2:
            raise _field_error("title", "Project title is required.")
        project.title = title[:180]
    if "project_type" in payload:
        project_type = str(payload.get("project_type", "")).strip()
        if len(project_type) < 2:
            raise _field_error("project_type", "Project type is required.")
        project.project_type = project_type[:64]
    if "description" in payload:
        project.description = str(payload.get("description", "")).strip()[:5000] or None
    if "city_id" in payload:
        city = _city_by_public_id(str(payload.get("city_id", "")).strip() or None)
        project.city_id = city.id if city else None
    if "cover_file_id" in payload:
        cover_file = _owned_public_project_cover(
            str(payload.get("cover_file_id", "")).strip() or None,
            actor,
        )
        project.cover_file_id = cover_file.id if cover_file else None
    if "start_date" in payload:
        project.start_date = _optional_date(payload.get("start_date"), "start_date")
    if "end_date" in payload:
        project.end_date = _optional_date(payload.get("end_date"), "end_date")
    if (
        project.start_date
        and project.end_date
        and project.end_date < project.start_date
    ):
        raise _field_error("end_date", "End date cannot be before start date.")
    if "estimated_budget_minor" in payload:
        budget = _optional_int(
            payload.get("estimated_budget_minor"), "estimated_budget_minor"
        )
        if budget is not None and budget < 0:
            raise _field_error("estimated_budget_minor", "Budget cannot be negative.")
        project.estimated_budget_minor = budget
    if "currency" in payload:
        currency = str(payload.get("currency", "PKR")).strip().upper()
        if len(currency) != 3:
            raise _field_error("currency", "Currency must be a 3-letter ISO code.")
        project.currency = currency
    if "visibility" in payload:
        visibility = str(payload.get("visibility", "private")).strip()
        if visibility not in PROJECT_VISIBILITIES:
            raise _field_error("visibility", "Unsupported project visibility.")
        project.visibility = visibility
    if "status" in payload:
        status = str(payload.get("status", "draft")).strip()
        if status not in PROJECT_STATUSES:
            raise _field_error("status", "Unsupported project status.")
        project.status = status
    if "progress_percent" in payload:
        progress = (
            _optional_int(payload.get("progress_percent"), "progress_percent") or 0
        )
        if progress < 0 or progress > 100:
            raise _field_error(
                "progress_percent", "Progress must be between 0 and 100."
            )
        project.progress_percent = progress


def _apply_requirement_payload(
    requirement: ProjectRequirement, payload: dict[str, Any]
) -> None:
    if "category" in payload:
        category = str(payload.get("category", "")).strip()
        if category not in REQUIREMENT_CATEGORIES:
            raise _field_error("category", "Unsupported requirement category.")
        requirement.category = category
    if "title" in payload:
        title = str(payload.get("title", "")).strip()
        if len(title) < 2:
            raise _field_error("title", "Requirement title is required.")
        requirement.title = title[:180]
    if "summary" in payload:
        requirement.summary = str(payload.get("summary", "")).strip()[:4000] or None
    if "budget_min_minor" in payload:
        minimum = _optional_int(payload.get("budget_min_minor"), "budget_min_minor")
        if minimum is not None and minimum < 0:
            raise _field_error("budget_min_minor", "Budget cannot be negative.")
        requirement.budget_min_minor = minimum
    if "budget_max_minor" in payload:
        maximum = _optional_int(payload.get("budget_max_minor"), "budget_max_minor")
        if maximum is not None and maximum < 0:
            raise _field_error("budget_max_minor", "Budget cannot be negative.")
        requirement.budget_max_minor = maximum
    if (
        requirement.budget_min_minor is not None
        and requirement.budget_max_minor is not None
        and requirement.budget_max_minor < requirement.budget_min_minor
    ):
        raise _field_error("budget_max_minor", "Max budget cannot be below min budget.")
    if "currency" in payload:
        currency = str(payload.get("currency", "PKR")).strip().upper()
        if len(currency) != 3:
            raise _field_error("currency", "Currency must be a 3-letter ISO code.")
        requirement.currency = currency
    if "start_date" in payload:
        requirement.start_date = _optional_date(payload.get("start_date"), "start_date")
    if "end_date" in payload:
        requirement.end_date = _optional_date(payload.get("end_date"), "end_date")
    if (
        requirement.start_date
        and requirement.end_date
        and requirement.end_date < requirement.start_date
    ):
        raise _field_error("end_date", "End date cannot be before start date.")
    if "status" in payload:
        status = str(payload.get("status", "open")).strip()
        if status not in REQUIREMENT_STATUSES:
            raise _field_error("status", "Unsupported requirement status.")
        requirement.status = status
    if "visibility" in payload:
        visibility = str(payload.get("visibility", "all")).strip()
        if visibility not in REQUIREMENT_VISIBILITIES:
            raise _field_error("visibility", "Unsupported requirement visibility.")
        requirement.visibility = visibility
    if "quantity" in payload:
        quantity = _optional_int(payload.get("quantity"), "quantity") or 1
        if quantity < 1:
            raise _field_error("quantity", "Quantity must be at least 1.")
        requirement.quantity = quantity
    if "required_documents" in payload:
        documents = payload.get("required_documents")
        if not isinstance(documents, list):
            raise _field_error(
                "required_documents", "Required documents must be a list."
            )
        cleaned = [str(item).strip()[:120] for item in documents if str(item).strip()]
        if len(cleaned) > 10:
            raise _field_error(
                "required_documents", "Supports up to 10 required documents."
            )
        requirement.required_documents_json = json.dumps(cleaned) if cleaned else None


@projects_blueprint.get("/skills")
def skills() -> Response:
    category = request.args.get("category")
    query = select(Skill).where(Skill.active.is_(True))
    if category:
        query = query.where(Skill.category == category)
    rows = db.session.execute(
        query.order_by(Skill.category.asc(), Skill.name.asc())
    ).scalars()
    return jsonify(success({"skills": [_skill_payload(row) for row in rows]}))


@projects_blueprint.get("/projects")
def projects() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(Project)
        .join(ProjectMember, ProjectMember.project_id == Project.id)
        .where(ProjectMember.user_id == user.id, ProjectMember.status == "active")
        .order_by(Project.updated_at.desc())
    ).scalars()
    return jsonify(success({"projects": [_project_payload(row) for row in rows]}))


@projects_blueprint.post("/projects")
def create_project() -> ResponseReturnValue:
    user = _current_user()
    _require_project_creator(user)
    payload = _json_body()
    project = Project(
        owner_user_id=user.id,
        title="Untitled project",
        project_type="film",
        organization_id=str(payload.get("organization_id", "")).strip()[:40] or None,
    )
    _apply_project_payload(project, payload, actor=user)
    db.session.add(project)
    db.session.flush()
    db.session.add(
        ProjectMember(
            project_id=project.id,
            user_id=user.id,
            role_label="Owner",
            permissions_json=json.dumps(
                {
                    "manage_project": True,
                    "manage_requirements": True,
                    "manage_members": True,
                },
                sort_keys=True,
            ),
            status="active",
        )
    )
    if _has_role(user, "director_producer", "super_admin"):
        ensure_cineplanner_production(project, actor_user_id=user.id)
    db.session.commit()
    return jsonify(
        success({"project": _project_payload(project, include_nested=True)})
    ), 201


@projects_blueprint.get("/public/cinema")
def public_cinema() -> Response:
    kind = str(request.args.get("kind", "")).strip().lower()
    project_type = str(request.args.get("project_type", "")).strip().lower()
    city = str(request.args.get("city", "")).strip().lower()
    search = str(request.args.get("q", "")).strip().lower()
    try:
        limit = min(max(int(request.args.get("limit", 60) or 60), 1), 100)
    except ValueError:
        raise _field_error("limit", "Limit must be an integer.") from None

    statement = (
        select(ProjectFile)
        .join(Project, ProjectFile.project_id == Project.id)
        .outerjoin(FileAsset, ProjectFile.file_id == FileAsset.id)
        .where(
            ProjectFile.folder.in_(PUBLIC_CINEMA_FOLDERS),
            (
                (
                    (FileAsset.id.is_not(None))
                    & (FileAsset.visibility == "public")
                    & (FileAsset.scan_status == "clean")
                    & (FileAsset.processing_status == "ready")
                )
                | (ProjectFile.external_url.is_not(None))
            ),
            Project.status.in_({"active", "paused", "completed"}),
        )
        .order_by(desc(ProjectFile.created_at))
        .limit(limit)
    )
    if kind in PUBLIC_CINEMA_FOLDERS:
        statement = statement.where(ProjectFile.folder == kind)
    if project_type:
        statement = statement.where(Project.project_type.ilike(f"%{project_type}%"))
    if city:
        statement = statement.where(Project.city.has(City.name.ilike(f"%{city}%")))
    if search:
        pattern = f"%{search}%"
        statement = statement.where(
            Project.title.ilike(pattern) | ProjectFile.label.ilike(pattern)
        )
    items = db.session.execute(statement).scalars().unique().all()
    return jsonify(success({"items": [_public_cinema_payload(item) for item in items]}))


@projects_blueprint.get("/projects/<public_id>")
def project_detail(public_id: str) -> Response:
    user = _current_user()
    project = _project_for_user(public_id, user)
    return jsonify(success({"project": _project_payload(project, include_nested=True)}))


@projects_blueprint.patch("/projects/<public_id>")
def update_project(public_id: str) -> Response:
    user = _current_user()
    project = _project_for_user(public_id, user)
    if project.owner_user_id != user.id:
        raise APIError(
            "project.permission_denied",
            "Only the project owner can update project settings.",
            status=403,
        )
    _apply_project_payload(project, _json_body(), actor=user)
    db.session.commit()
    return jsonify(success({"project": _project_payload(project, include_nested=True)}))


@projects_blueprint.post("/projects/<public_id>/duplicate")
def duplicate_project(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    source = _project_for_user(public_id, user)
    if source.owner_user_id != user.id:
        raise APIError(
            "project.permission_denied",
            "Only the project owner can duplicate this project.",
            status=403,
        )
    payload = _json_body()
    requested_title = str(payload.get("title", "")).strip()
    if requested_title and len(requested_title) < 2:
        raise _field_error("title", "Project title must contain at least 2 characters.")
    title = requested_title or f"{source.title} copy"
    duplicate = Project(
        owner_user_id=user.id,
        organization_id=source.organization_id,
        title=title[:180],
        project_type=source.project_type,
        description=source.description,
        city_id=source.city_id,
        cover_file_id=source.cover_file_id,
        start_date=source.start_date,
        end_date=source.end_date,
        status="draft",
        estimated_budget_minor=source.estimated_budget_minor,
        currency=source.currency,
        visibility=source.visibility,
        progress_percent=0,
    )
    db.session.add(duplicate)
    db.session.flush()
    db.session.add(
        ProjectMember(
            project_id=duplicate.id,
            user_id=user.id,
            role_label="Owner",
            permissions_json=json.dumps(
                {
                    "manage_project": True,
                    "manage_requirements": True,
                    "manage_members": True,
                },
                sort_keys=True,
            ),
            status="active",
        )
    )
    for source_requirement in source.requirements:
        requirement = ProjectRequirement(
            project_id=duplicate.id,
            category=source_requirement.category,
            title=source_requirement.title,
            summary=source_requirement.summary,
            budget_min_minor=source_requirement.budget_min_minor,
            budget_max_minor=source_requirement.budget_max_minor,
            currency=source_requirement.currency,
            start_date=source_requirement.start_date,
            end_date=source_requirement.end_date,
            status="draft",
            visibility=source_requirement.visibility,
            quantity=source_requirement.quantity,
            required_documents_json=source_requirement.required_documents_json,
        )
        requirement.skills = [
            RequirementSkill(
                skill_id=row.skill_id,
                required=row.required,
                minimum_level=row.minimum_level,
            )
            for row in source_requirement.skills
        ]
        db.session.add(requirement)
    if _has_role(user, "director_producer", "super_admin"):
        ensure_cineplanner_production(duplicate, actor_user_id=user.id)
    db.session.commit()
    return jsonify(
        success({"project": _project_payload(duplicate, include_nested=True)})
    ), 201


@projects_blueprint.get("/projects/<public_id>/room")
def project_room(public_id: str) -> Response:
    user = _current_user()
    project = _project_for_user(public_id, user)
    return jsonify(
        success(
            {
                "room": {
                    "project": _project_payload(project),
                    "members": [_member_payload(row) for row in project.members],
                    "files": [_project_file_payload(row) for row in project.files],
                    "items": [_room_item_payload(row) for row in project.room_items],
                }
            }
        )
    )


@projects_blueprint.post("/projects/<public_id>/room/items")
def create_project_room_item(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    project = _project_for_user(public_id, user)
    payload = _json_body()
    item_type = str(payload.get("item_type", "note")).strip()
    if item_type not in PROJECT_ROOM_ITEM_TYPES:
        raise _field_error("item_type", "Unsupported project room item type.")
    title = str(payload.get("title", "")).strip()
    if len(title) < 2:
        raise _field_error("title", "Room item title is required.")
    item = ProjectRoomItem(
        project_id=project.id,
        item_type=item_type,
        title=title[:180],
        body=str(payload.get("body", "")).strip()[:5000] or None,
        linked_entity_type=str(payload.get("linked_entity_type", "")).strip()[:64]
        or None,
        linked_entity_id=str(payload.get("linked_entity_id", "")).strip()[:40] or None,
        created_by=user.id,
        pinned_at=utc_now() if bool(payload.get("pinned", False)) else None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"item": _room_item_payload(item)})), 201


@projects_blueprint.get("/projects/<public_id>/members")
def project_members(public_id: str) -> Response:
    user = _current_user()
    project = _project_for_user(public_id, user)
    return jsonify(
        success({"members": [_member_payload(row) for row in project.members]})
    )


@projects_blueprint.get("/projects/<public_id>/files")
def project_files(public_id: str) -> Response:
    user = _current_user()
    project = _project_for_user(public_id, user)
    return jsonify(
        success({"files": [_project_file_payload(row) for row in project.files]})
    )


@projects_blueprint.post("/projects/<public_id>/files")
def link_project_file(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    project = _project_for_user(public_id, user)
    payload = _json_body()
    file = _owned_ready_project_file(str(payload.get("file_id", "")).strip(), user)
    folder = str(payload.get("folder", "briefs")).strip()
    if folder not in PROJECT_FILE_FOLDERS:
        raise _field_error("folder", "Unsupported project file folder.")
    label = str(payload.get("label") or file.original_name or "Project file").strip()
    existing = db.session.execute(
        select(ProjectFile).where(
            ProjectFile.project_id == project.id,
            ProjectFile.file_id == file.id,
        )
    ).scalar_one_or_none()
    if existing is None:
        existing = ProjectFile(
            project_id=project.id,
            file_id=file.id,
            uploaded_by=user.id,
            folder=folder,
            label=label[:180],
            visibility="project_members",
            sort_order=_optional_int(payload.get("sort_order"), "sort_order") or 100,
        )
        db.session.add(existing)
        status_code = 201
    else:
        existing.folder = folder
        existing.label = label[:180]
        existing.sort_order = (
            _optional_int(payload.get("sort_order"), "sort_order")
            or existing.sort_order
        )
        status_code = 200
    db.session.commit()
    return jsonify(success({"file": _project_file_payload(existing)})), status_code


@projects_blueprint.get("/projects/<public_id>/requirements")
def project_requirements(public_id: str) -> Response:
    user = _current_user()
    project = _project_for_user(public_id, user)
    return jsonify(
        success(
            {
                "requirements": [
                    _requirement_payload(row) for row in project.requirements
                ]
            }
        )
    )


@projects_blueprint.post("/projects/<public_id>/requirements")
def create_project_requirement(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    project = _project_for_user(public_id, user)
    payload = _json_body()
    requirement = ProjectRequirement(
        project_id=project.id,
        category="talent",
        title="Untitled requirement",
        currency=project.currency,
        start_date=project.start_date,
        end_date=project.end_date,
    )
    _apply_requirement_payload(requirement, payload)
    db.session.add(requirement)
    db.session.flush()
    _sync_requirement_skills(requirement, payload.get("skills"))
    db.session.commit()
    return jsonify(success({"requirement": _requirement_payload(requirement)})), 201


@projects_blueprint.patch("/requirements/<public_id>")
def update_requirement(public_id: str) -> Response:
    user = _current_user()
    requirement = _requirement_for_user(public_id, user)
    payload = _json_body()
    _apply_requirement_payload(requirement, payload)
    _sync_requirement_skills(requirement, payload.get("skills"))
    db.session.commit()
    return jsonify(success({"requirement": _requirement_payload(requirement)}))
