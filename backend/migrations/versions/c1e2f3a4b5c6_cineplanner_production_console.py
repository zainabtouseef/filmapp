"""CinePlanner production console

Revision ID: c1e2f3a4b5c6
Revises: cinema_external_media
Create Date: 2026-08-22 10:00:00.000000

"""

from __future__ import annotations

from alembic import op

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

revision = "c1e2f3a4b5c6"
down_revision = "cinema_external_media"
branch_labels = None
depends_on = None


TABLES = (
    CineProduction.__table__,
    CineProductionRole.__table__,
    CineScriptVersion.__table__,
    CineAIJob.__table__,
    CineScene.__table__,
    CineCharacter.__table__,
    CineActor.__table__,
    CineCastAssignment.__table__,
    CineActorAvailability.__table__,
    CineLocation.__table__,
    CineElement.__table__,
    CineCrewMember.__table__,
    CineShootDay.__table__,
    CineScheduleEvent.__table__,
    CineBudgetLine.__table__,
    CineCallSheet.__table__,
    CineAuditLog.__table__,
    CineConflict.__table__,
)


def upgrade() -> None:
    bind = op.get_bind()
    for table in TABLES:
        table.create(bind=bind, checkfirst=True)


def downgrade() -> None:
    bind = op.get_bind()
    for table in reversed(TABLES):
        table.drop(bind=bind, checkfirst=True)
