from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy import select

from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.identity import User
from app.models.scheduling import MeetingRound, MeetingThread

# Meeting negotiation for both CastingApplication (talent) and
# RequirementApplication (model/location/equipment/crew) — one shared
# propose/accept/decline mechanism rather than two parallel implementations.
# Kept independent of the fee-centric Booking/Offer system: a meeting has to
# be proposable before any fee is agreed (you audition someone before
# deciding to hire them).


def thread_for_subject(subject_type: str, subject_id: str) -> MeetingThread | None:
    return db.session.execute(
        select(MeetingThread).where(
            MeetingThread.subject_type == subject_type,
            MeetingThread.subject_id == subject_id,
        )
    ).scalar_one_or_none()


def get_or_create_thread(subject_type: str, subject_id: str) -> MeetingThread:
    thread = thread_for_subject(subject_type, subject_id)
    if thread is not None:
        return thread
    thread = MeetingThread(subject_type=subject_type, subject_id=subject_id)
    db.session.add(thread)
    db.session.flush()
    return thread


def propose_round(
    thread: MeetingThread,
    sender: User,
    *,
    meeting_at: datetime,
    location: str | None = None,
    online_url: str | None = None,
    instructions: str | None = None,
    contact: str | None = None,
    meeting_kind: str | None = None,
    message: str | None = None,
) -> MeetingRound:
    for round_ in thread.rounds:
        if round_.status == "pending":
            round_.status = "superseded"
    next_number = max((item.round_number for item in thread.rounds), default=0) + 1
    round_ = MeetingRound(
        thread_id=thread.id,
        round_number=next_number,
        proposed_by_user_id=sender.id,
        meeting_kind=meeting_kind,
        meeting_at=meeting_at,
        location=location,
        online_url=online_url,
        instructions=instructions,
        contact=contact,
        message=message,
    )
    db.session.add(round_)
    db.session.flush()
    thread.current_round_id = round_.id
    thread.status = "open"
    db.session.flush()
    return round_


def accept_round(round_: MeetingRound, actor: User) -> None:
    if round_.status != "pending":
        raise APIError(
            "scheduling.round_not_pending",
            "This meeting proposal is no longer awaiting a response.",
            status=409,
        )
    if round_.proposed_by_user_id == actor.id:
        raise APIError(
            "scheduling.cannot_accept_own_proposal",
            (
                "You cannot accept your own meeting proposal — "
                "wait for the other side to respond."
            ),
            status=403,
        )
    round_.status = "accepted"
    round_.responded_by_user_id = actor.id
    round_.responded_at = utc_now()
    round_.thread.status = "accepted"
    round_.thread.locked_at = utc_now()
    db.session.flush()


def decline_round(round_: MeetingRound, actor: User, reason: str | None) -> None:
    if round_.status != "pending":
        raise APIError(
            "scheduling.round_not_pending",
            "This meeting proposal is no longer awaiting a response.",
            status=409,
        )
    if round_.proposed_by_user_id == actor.id:
        raise APIError(
            "scheduling.cannot_decline_own_proposal",
            "You cannot decline your own meeting proposal.",
            status=403,
        )
    round_.status = "declined"
    round_.decline_reason = (reason or "").strip()[:2000] or None
    round_.responded_by_user_id = actor.id
    round_.responded_at = utc_now()
    db.session.flush()


def round_payload(round_: MeetingRound) -> dict[str, Any]:
    return {
        "public_id": round_.public_id,
        "round_number": round_.round_number,
        "proposed_by": {
            "public_id": round_.proposed_by.public_id,
            "display_name": round_.proposed_by.display_name,
        },
        "meeting_kind": round_.meeting_kind,
        "meeting_at": round_.meeting_at.isoformat(),
        "location": round_.location,
        "online_url": round_.online_url,
        "instructions": round_.instructions,
        "contact": round_.contact,
        "message": round_.message,
        "status": round_.status,
        "decline_reason": round_.decline_reason,
        "responded_by": (
            {
                "public_id": round_.responded_by.public_id,
                "display_name": round_.responded_by.display_name,
            }
            if round_.responded_by is not None
            else None
        ),
        "responded_at": (
            round_.responded_at.isoformat() if round_.responded_at else None
        ),
        "created_at": round_.created_at.isoformat(),
    }


def thread_payload(thread: MeetingThread | None) -> dict[str, Any] | None:
    if thread is None:
        return None
    return {
        "public_id": thread.public_id,
        "status": thread.status,
        "locked_at": thread.locked_at.isoformat() if thread.locked_at else None,
        "current_round": (
            round_payload(thread.current_round)
            if thread.current_round is not None
            else None
        ),
        "rounds": [round_payload(item) for item in thread.rounds],
    }


def round_for_public_id(
    subject_type: str, subject_id: str, round_public_id: str
) -> MeetingRound:
    round_ = db.session.execute(
        select(MeetingRound)
        .join(MeetingThread, MeetingRound.thread_id == MeetingThread.id)
        .where(
            MeetingRound.public_id == round_public_id,
            MeetingThread.subject_type == subject_type,
            MeetingThread.subject_id == subject_id,
        )
    ).scalar_one_or_none()
    if round_ is None:
        raise APIError(
            "scheduling.round_not_found",
            "Meeting proposal was not found.",
            status=404,
        )
    return round_
