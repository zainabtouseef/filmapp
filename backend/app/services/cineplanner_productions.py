from __future__ import annotations

import uuid

from sqlalchemy import select

from app.extensions import db
from app.models.cineplanner import CineAuditLog, CineProduction, CineProductionRole
from app.models.projects import Project, ProjectMember

PRODUCER_PERMISSIONS = [
    "edit",
    "finance",
    "schedule",
    "cast",
    "approve",
    "manage_team",
    "locations",
    "elements",
]


def ensure_cineplanner_production(
    project: Project, *, actor_user_id: uuid.UUID | None = None
) -> tuple[CineProduction, bool]:
    """Return the single CinePlanner workspace linked to a portal project."""
    existing = db.session.execute(
        select(CineProduction).where(CineProduction.project_id == project.id)
    ).scalar_one_or_none()
    if existing is not None:
        return existing, False

    production = CineProduction(
        owner_user_id=project.owner_user_id,
        project_id=project.id,
        title=project.title,
        status="setup",
        currency=project.currency,
        production_start_date=project.start_date,
        budget_ceiling_minor=project.estimated_budget_minor,
        settings_json={"source": "project_portal"},
    )
    db.session.add(production)
    db.session.flush()
    db.session.add(
        CineProductionRole(
            production_id=production.id,
            user_id=project.owner_user_id,
            role_code="producer",
            permissions_json=PRODUCER_PERMISSIONS,
        )
    )
    db.session.add(
        CineAuditLog(
            production_id=production.id,
            actor_user_id=actor_user_id,
            action="project_linked_automatically",
            entity_type="project",
            entity_public_id=project.public_id,
            old_value_json=None,
            new_value_json={"title": project.title},
        )
    )
    return production, True


def sync_cineplanner_projects(user_id: uuid.UUID) -> int:
    """Create missing CinePlanner workspaces for every accessible project."""
    projects = (
        db.session.execute(
            select(Project)
            .join(ProjectMember, ProjectMember.project_id == Project.id)
            .where(
                ProjectMember.user_id == user_id,
                ProjectMember.status == "active",
            )
        )
        .unique()
        .scalars()
        .all()
    )
    created = 0
    for project in projects:
        _, was_created = ensure_cineplanner_production(project, actor_user_id=user_id)
        created += int(was_created)
    return created
