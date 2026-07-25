from __future__ import annotations

import json
from datetime import UTC, datetime, timedelta
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import or_, select

from app.api.auth import _current_user, _json_body
from app.api.marketplace import _field_error, _file_payload
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import (
    AvailabilityCalendar,
    AvailabilityEntry,
    Booking,
    BookingParticipant,
    BookingStatusEvent,
    Conversation,
    ConversationMember,
    Message,
    MessageAttachment,
    NegotiationRound,
    NegotiationThread,
    Offer,
    PinnedDecision,
)
from app.models.casting import (
    CastingApplication,
    CastingApplicationStatusEvent,
)
from app.models.files import FileAsset
from app.models.identity import User
from app.models.marketplace import MarketplaceListing
from app.models.projects import Project, ProjectMember, ProjectRequirement
from app.responses import success
from app.services.notifications import notify_user

bookings_blueprint = Blueprint("bookings", __name__)

BOOKING_MUTABLE_STATUSES = {"draft", "sent", "viewed", "under_negotiation"}
BOOKING_VISIBLE_STATUSES = BOOKING_MUTABLE_STATUSES | {
    "accepted",
    "rejected",
    "cancelled",
    "secured",
}
MANUAL_AVAILABILITY_STATUSES = {"available", "hold", "blocked"}
CONFLICTING_AVAILABILITY_STATUSES = {"hold", "blocked", "booked"}


def _parse_datetime(value: Any, field: str) -> datetime:
    if not isinstance(value, str) or not value.strip():
        raise _field_error(field, "Datetime is required.")
    normalized = value.strip().replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError as exc:
        raise _field_error(field, "Datetime must be ISO-8601.") from exc
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=UTC)
    return parsed.astimezone(UTC)


def _optional_datetime(value: Any, field: str) -> datetime | None:
    if value in {None, ""}:
        return None
    return _parse_datetime(value, field)


def _optional_int(value: Any, field: str) -> int | None:
    if value in {None, ""}:
        return None
    try:
        return int(str(value))
    except ValueError as exc:
        raise _field_error(field, "Value must be an integer.") from exc


def _user_payload(user: User) -> dict[str, Any]:
    return {"public_id": user.public_id, "display_name": user.display_name}


def _participant_payload(item: BookingParticipant) -> dict[str, Any]:
    return {
        "user": _user_payload(item.user),
        "participant_role": item.participant_role,
        "can_chat": item.can_chat,
        "can_view_finance": item.can_view_finance,
    }


def _status_event_payload(item: BookingStatusEvent) -> dict[str, Any]:
    return {
        "from_status": item.from_status,
        "to_status": item.to_status,
        "reason": item.reason,
        "actor": _user_payload(item.actor) if item.actor else None,
        "metadata": json.loads(item.metadata_json) if item.metadata_json else {},
        "created_at": item.created_at.isoformat(),
    }


def _offer_payload(item: Offer) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "revision": item.revision,
        "sender": _user_payload(item.sender),
        "recipient": _user_payload(item.recipient),
        "fee_minor": item.fee_minor,
        "currency": item.currency,
        "schedule": json.loads(item.schedule_json) if item.schedule_json else {},
        "conditions": item.conditions,
        "payment_schedule": json.loads(item.payment_schedule_json)
        if item.payment_schedule_json
        else [],
        "status": item.status,
        "expires_at": item.expires_at.isoformat() if item.expires_at else None,
        "created_at": item.created_at.isoformat(),
    }


def _booking_payload(item: Booking) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "project_id": item.project.public_id,
        "project_title": item.project.title,
        "project_type": item.project.project_type,
        "project_city": item.project.city.name if item.project.city else None,
        "requirement_id": item.requirement.public_id if item.requirement else None,
        "requirement_title": item.requirement.title if item.requirement else None,
        "listing_id": item.listing.public_id,
        "listing_title": item.listing.title,
        "category": item.category,
        "status": item.status,
        "requester": _user_payload(item.requester),
        "provider": _user_payload(item.provider),
        "agreed_amount_minor": item.agreed_amount_minor,
        "currency": item.currency,
        "start_at": item.start_at.isoformat(),
        "end_at": item.end_at.isoformat(),
        "expires_at": item.expires_at.isoformat() if item.expires_at else None,
        "secured_at": item.secured_at.isoformat() if item.secured_at else None,
        "cancellation_reason": item.cancellation_reason,
        "conversation_id": item.conversation.public_id if item.conversation else None,
        "negotiation_id": item.negotiation_thread.public_id
        if item.negotiation_thread
        else None,
        "participants": [_participant_payload(row) for row in item.participants],
        "offers": [_offer_payload(row) for row in item.offers],
        "status_events": [_status_event_payload(row) for row in item.status_events],
    }


def _round_payload(item: NegotiationRound) -> dict[str, Any]:
    return {
        "round_number": item.round_number,
        "sender": _user_payload(item.sender),
        "message": item.message,
        "offer": _offer_payload(item.offer),
        "created_at": item.created_at.isoformat(),
    }


def _negotiation_payload(thread: NegotiationThread) -> dict[str, Any]:
    return {
        "public_id": thread.public_id,
        "status": thread.status,
        "booking": _booking_payload(thread.booking),
        "current_offer": _offer_payload(thread.current_offer)
        if thread.current_offer
        else None,
        "locked_at": thread.locked_at.isoformat() if thread.locked_at else None,
        "rounds": [_round_payload(row) for row in thread.rounds],
    }


def _attachment_payload(item: MessageAttachment) -> dict[str, Any]:
    return {
        "file": _file_payload(item.file),
        "attachment_type": item.attachment_type,
        "caption": item.caption,
    }


def _message_payload(item: Message) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "sender": _user_payload(item.sender),
        "message_type": item.message_type,
        "body": item.body,
        "reply_to_id": item.reply_to_id.hex if item.reply_to_id else None,
        "decision_type": item.decision_type,
        "edited_at": item.edited_at.isoformat() if item.edited_at else None,
        "attachments": [_attachment_payload(row) for row in item.attachments],
        "created_at": item.created_at.isoformat(),
    }


def _conversation_payload(item: Conversation) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "booking_id": item.booking.public_id if item.booking else None,
        "project_id": item.project.public_id if item.project else None,
        "type": item.type,
        "title": item.title,
        "last_message_at": item.last_message_at.isoformat()
        if item.last_message_at
        else None,
        "members": [_user_payload(row.user) for row in item.members],
        "messages": [_message_payload(row) for row in item.messages],
    }


def _booking_for_user(public_id: str, user: User) -> Booking:
    booking = db.session.execute(
        select(Booking)
        .join(BookingParticipant, BookingParticipant.booking_id == Booking.id)
        .where(
            Booking.public_id == public_id,
            BookingParticipant.user_id == user.id,
            Booking.status.in_(BOOKING_VISIBLE_STATUSES),
        )
    ).scalar_one_or_none()
    if booking is None:
        raise APIError("booking.not_found", "Booking was not found.", status=404)
    return booking


def _conversation_for_user(public_id: str, user: User) -> Conversation:
    conversation = db.session.execute(
        select(Conversation)
        .join(ConversationMember, ConversationMember.conversation_id == Conversation.id)
        .where(
            Conversation.public_id == public_id,
            ConversationMember.user_id == user.id,
        )
    ).scalar_one_or_none()
    if conversation is None:
        raise APIError(
            "conversation.not_found", "Conversation was not found.", status=404
        )
    return conversation


def _availability_entry_for_user(public_id: str, user: User) -> AvailabilityEntry:
    entry = db.session.execute(
        select(AvailabilityEntry)
        .join(AvailabilityCalendar)
        .where(
            AvailabilityEntry.public_id == public_id,
            AvailabilityCalendar.owner_type == "user",
            AvailabilityCalendar.owner_id == user.public_id,
        )
    ).scalar_one_or_none()
    if entry is None:
        raise APIError(
            "availability.not_found",
            "Availability entry was not found.",
            status=404,
        )
    return entry


def _offer_for_user(public_id: str, user: User) -> Offer:
    offer = db.session.execute(
        select(Offer)
        .join(Booking, Offer.booking_id == Booking.id)
        .join(BookingParticipant, BookingParticipant.booking_id == Booking.id)
        .where(
            Offer.public_id == public_id,
            BookingParticipant.user_id == user.id,
        )
    ).scalar_one_or_none()
    if offer is None:
        raise APIError("offer.not_found", "Offer was not found.", status=404)
    return offer


def _project_for_booking(public_id: str, user: User) -> Project:
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
        raise _field_error("project_id", "Select a project you can access.")
    return project


def _listing_for_booking(public_id: str) -> MarketplaceListing:
    listing = db.session.execute(
        select(MarketplaceListing).where(
            MarketplaceListing.public_id == public_id,
            MarketplaceListing.visibility == "public",
            MarketplaceListing.moderation_status == "approved",
        )
    ).scalar_one_or_none()
    if listing is None:
        raise _field_error("listing_id", "Select an approved public listing.")
    return listing


def _set_status(
    booking: Booking,
    to_status: str,
    actor: User,
    *,
    reason: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> None:
    if booking.status == to_status:
        return
    db.session.add(
        BookingStatusEvent(
            booking_id=booking.id,
            actor_user_id=actor.id,
            from_status=booking.status,
            to_status=to_status,
            reason=reason,
            metadata_json=json.dumps(metadata or {}, sort_keys=True),
        )
    )
    booking.status = to_status


def _sync_casting_application_status(
    booking: Booking,
    actor: User,
    to_status: str,
    *,
    note: str,
) -> None:
    if booking.requirement_id is None:
        return
    application = db.session.execute(
        select(CastingApplication).where(
            CastingApplication.requirement_id == booking.requirement_id,
            CastingApplication.actor_user_id == booking.provider_user_id,
        )
    ).scalar_one_or_none()
    if application is None or application.status == to_status:
        return
    if application.status in {"selected", "rejected", "withdrawn"}:
        return
    previous = application.status
    application.status = to_status
    if to_status == "withdrawn":
        application.withdrawn_at = utc_now()
    db.session.add(
        CastingApplicationStatusEvent(
            application_id=application.id,
            actor_user_id=actor.id,
            from_status=previous,
            to_status=to_status,
            note=note,
        )
    )


def _ensure_calendar(owner_id: str) -> AvailabilityCalendar:
    calendar = db.session.execute(
        select(AvailabilityCalendar).where(
            AvailabilityCalendar.owner_type == "user",
            AvailabilityCalendar.owner_id == owner_id,
        )
    ).scalar_one_or_none()
    if calendar is None:
        calendar = AvailabilityCalendar(owner_type="user", owner_id=owner_id)
        db.session.add(calendar)
        db.session.flush()
    return calendar


def _availability_conflicts(
    owner_id: str,
    start_at: datetime,
    end_at: datetime,
    *,
    exclude_booking_id: object | None = None,
) -> list[AvailabilityEntry]:
    query = (
        select(AvailabilityEntry)
        .join(AvailabilityCalendar)
        .where(
            AvailabilityCalendar.owner_type == "user",
            AvailabilityCalendar.owner_id == owner_id,
            AvailabilityEntry.status.in_(CONFLICTING_AVAILABILITY_STATUSES),
            AvailabilityEntry.start_at < end_at,
            AvailabilityEntry.end_at > start_at,
        )
    )
    if exclude_booking_id is not None:
        query = query.where(
            or_(
                AvailabilityEntry.source_booking_id.is_(None),
                AvailabilityEntry.source_booking_id != exclude_booking_id,
            )
        )
    rows = db.session.execute(query).scalars().all()
    return list(rows)


def _entry_payload(item: AvailabilityEntry) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "resource_type": item.resource_type,
        "resource_id": item.resource_id,
        "start_at": item.start_at.isoformat(),
        "end_at": item.end_at.isoformat(),
        "status": item.status,
        "source_booking_id": item.source_booking.public_id
        if item.source_booking
        else None,
        "note": item.note,
    }


def _create_conversation(booking: Booking) -> Conversation:
    conversation = Conversation(
        booking_id=booking.id,
        project_id=booking.project_id,
        type="booking",
        title=f"{booking.project.title} — {booking.listing.title}",
    )
    db.session.add(conversation)
    db.session.flush()
    db.session.add_all(
        [
            ConversationMember(
                conversation_id=conversation.id, user_id=booking.requester_user_id
            ),
            ConversationMember(
                conversation_id=conversation.id, user_id=booking.provider_user_id
            ),
        ]
    )
    return conversation


def _next_offer_revision(booking: Booking) -> int:
    return max((offer.revision for offer in booking.offers), default=0) + 1


def _create_offer(
    booking: Booking,
    sender: User,
    recipient_id: object,
    payload: dict[str, Any],
    *,
    message: str | None = None,
) -> Offer:
    fee = _optional_int(payload.get("fee_minor"), "fee_minor")
    if fee is None or fee <= 0:
        raise _field_error("fee_minor", "Offer fee must be positive.")
    currency = str(payload.get("currency") or booking.currency).strip().upper()
    if len(currency) != 3:
        raise _field_error("currency", "Currency must be a 3-letter ISO code.")
    for existing in booking.offers:
        if existing.status == "active":
            existing.status = "superseded"
    offer = Offer(
        booking_id=booking.id,
        sender_user_id=sender.id,
        recipient_user_id=recipient_id,
        revision=_next_offer_revision(booking),
        fee_minor=fee,
        currency=currency,
        schedule_json=json.dumps(payload.get("schedule") or {}, sort_keys=True),
        conditions=str(payload.get("conditions", "")).strip()[:4000] or None,
        payment_schedule_json=json.dumps(payload.get("payment_schedule") or []),
        status="active",
        expires_at=_optional_datetime(payload.get("expires_at"), "expires_at"),
    )
    db.session.add(offer)
    db.session.flush()
    thread = booking.negotiation_thread
    if thread is None:
        thread = NegotiationThread(booking_id=booking.id, status="open")
        db.session.add(thread)
        db.session.flush()
    thread.current_offer_id = offer.id
    db.session.add(
        NegotiationRound(
            thread_id=thread.id,
            offer_id=offer.id,
            round_number=offer.revision,
            sender_user_id=sender.id,
            message=message,
        )
    )
    return offer


@bookings_blueprint.get("/availability")
def availability_entries() -> Response:
    user = _current_user()
    query = (
        select(AvailabilityEntry)
        .join(AvailabilityCalendar)
        .where(
            AvailabilityCalendar.owner_type == "user",
            AvailabilityCalendar.owner_id == user.public_id,
        )
        .order_by(AvailabilityEntry.start_at.asc())
    )
    resource_type = request.args.get("resource_type")
    if resource_type:
        query = query.where(AvailabilityEntry.resource_type == resource_type)
    status = request.args.get("status")
    if status:
        query = query.where(AvailabilityEntry.status == status)
    rows = db.session.execute(query.limit(200)).scalars()
    return jsonify(success({"availability": [_entry_payload(row) for row in rows]}))


@bookings_blueprint.post("/availability")
def create_availability_entry() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    start_at = _parse_datetime(payload.get("start_at"), "start_at")
    end_at = _parse_datetime(payload.get("end_at"), "end_at")
    if end_at <= start_at:
        raise _field_error("end_at", "End time must be after start time.")
    status = str(payload.get("status", "hold")).strip()
    if status not in MANUAL_AVAILABILITY_STATUSES:
        raise _field_error("status", "Unsupported availability status.")
    if status in CONFLICTING_AVAILABILITY_STATUSES and _availability_conflicts(
        user.public_id, start_at, end_at
    ):
        raise APIError(
            "availability.conflict",
            "This availability block overlaps a hold or booking.",
            status=409,
        )
    calendar = _ensure_calendar(user.public_id)
    entry = AvailabilityEntry(
        calendar_id=calendar.id,
        resource_type=str(payload.get("resource_type", "user")).strip()[:64] or "user",
        resource_id=str(payload.get("resource_id") or user.public_id).strip()[:40],
        start_at=start_at,
        end_at=end_at,
        status=status,
        note=str(payload.get("note", "")).strip()[:2000] or None,
    )
    db.session.add(entry)
    db.session.commit()
    return jsonify(success({"entry": _entry_payload(entry)})), 201


@bookings_blueprint.patch("/availability/<public_id>")
def update_availability_entry(public_id: str) -> Response:
    user = _current_user()
    entry = _availability_entry_for_user(public_id, user)
    if entry.source_booking_id is not None:
        raise APIError(
            "availability.locked",
            "Booking-generated availability entries cannot be edited here.",
            status=409,
        )
    payload = _json_body()
    if "start_at" in payload:
        entry.start_at = _parse_datetime(payload.get("start_at"), "start_at")
    if "end_at" in payload:
        entry.end_at = _parse_datetime(payload.get("end_at"), "end_at")
    if entry.end_at <= entry.start_at:
        raise _field_error("end_at", "End time must be after start time.")
    if "status" in payload:
        status = str(payload.get("status", "hold")).strip()
        if status not in MANUAL_AVAILABILITY_STATUSES:
            raise _field_error("status", "Unsupported availability status.")
        entry.status = status
    if entry.status in CONFLICTING_AVAILABILITY_STATUSES and _availability_conflicts(
        user.public_id, entry.start_at, entry.end_at, exclude_booking_id=None
    ):
        conflicts = [
            row
            for row in _availability_conflicts(
                user.public_id, entry.start_at, entry.end_at
            )
            if row.id != entry.id
        ]
        if conflicts:
            raise APIError(
                "availability.conflict",
                "This availability block overlaps a hold or booking.",
                status=409,
            )
    if "resource_type" in payload:
        entry.resource_type = (
            str(payload.get("resource_type", "user")).strip()[:64] or "user"
        )
    if "resource_id" in payload:
        entry.resource_id = (
            str(payload.get("resource_id") or user.public_id).strip()[:40]
            or user.public_id
        )
    if "note" in payload:
        entry.note = str(payload.get("note", "")).strip()[:2000] or None
    db.session.commit()
    return jsonify(success({"entry": _entry_payload(entry)}))


@bookings_blueprint.delete("/availability/<public_id>")
def delete_availability_entry(public_id: str) -> Response:
    user = _current_user()
    entry = _availability_entry_for_user(public_id, user)
    if entry.source_booking_id is not None:
        raise APIError(
            "availability.locked",
            "Booking-generated availability entries cannot be deleted here.",
            status=409,
        )
    db.session.delete(entry)
    db.session.commit()
    return jsonify(success({"deleted": True}))


@bookings_blueprint.post("/availability/check")
def availability_check() -> Response:
    payload = _json_body()
    owner_id = str(payload.get("owner_user_id", "")).strip()
    start_at = _parse_datetime(payload.get("start_at"), "start_at")
    end_at = _parse_datetime(payload.get("end_at"), "end_at")
    if end_at <= start_at:
        raise _field_error("end_at", "End time must be after start time.")
    conflicts = _availability_conflicts(owner_id, start_at, end_at) if owner_id else []
    return jsonify(
        success(
            {
                "available": not conflicts,
                "conflicts": [_entry_payload(row) for row in conflicts],
            }
        )
    )


@bookings_blueprint.get("/bookings")
def bookings() -> Response:
    user = _current_user()
    query = (
        select(Booking)
        .join(BookingParticipant, BookingParticipant.booking_id == Booking.id)
        .where(
            BookingParticipant.user_id == user.id,
            Booking.status.in_(BOOKING_VISIBLE_STATUSES),
        )
    )
    role = request.args.get("role")
    if role == "requester":
        query = query.where(Booking.requester_user_id == user.id)
    elif role == "provider":
        query = query.where(Booking.provider_user_id == user.id)
    status = request.args.get("status")
    if status:
        query = query.where(Booking.status == status)
    rows = db.session.execute(
        query.order_by(Booking.updated_at.desc()).limit(100)
    ).scalars()
    return jsonify(success({"bookings": [_booking_payload(row) for row in rows]}))


@bookings_blueprint.get("/talent/opportunities")
def talent_opportunities() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(Booking)
        .join(BookingParticipant, BookingParticipant.booking_id == Booking.id)
        .where(
            Booking.provider_user_id == user.id,
            BookingParticipant.user_id == user.id,
            Booking.status.in_(BOOKING_VISIBLE_STATUSES),
        )
        .order_by(Booking.updated_at.desc())
        .limit(100)
    ).scalars()
    return jsonify(success({"bookings": [_booking_payload(row) for row in rows]}))


@bookings_blueprint.get("/bookings/<public_id>")
def booking_detail(public_id: str) -> Response:
    user = _current_user()
    return jsonify(
        success({"booking": _booking_payload(_booking_for_user(public_id, user))})
    )


@bookings_blueprint.post("/bookings")
def create_booking() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    project = _project_for_booking(str(payload.get("project_id", "")).strip(), user)
    listing = _listing_for_booking(str(payload.get("listing_id", "")).strip())
    if listing.owner_user_id == user.id:
        raise _field_error("listing_id", "You cannot book your own listing.")
    requirement = None
    requirement_id = str(payload.get("requirement_id", "")).strip()
    if requirement_id:
        requirement = db.session.execute(
            select(ProjectRequirement).where(
                ProjectRequirement.public_id == requirement_id,
                ProjectRequirement.project_id == project.id,
            )
        ).scalar_one_or_none()
        if requirement is None:
            raise _field_error(
                "requirement_id", "Select a requirement in this project."
            )
    start_at = _parse_datetime(payload.get("start_at"), "start_at")
    end_at = _parse_datetime(payload.get("end_at"), "end_at")
    if end_at <= start_at:
        raise _field_error("end_at", "End time must be after start time.")
    if _availability_conflicts(listing.owner.public_id, start_at, end_at):
        raise APIError(
            "availability.conflict",
            "Provider has a conflicting hold or booking.",
            status=409,
        )
    amount = _optional_int(payload.get("fee_minor"), "fee_minor")
    booking = Booking(
        project_id=project.id,
        requirement_id=requirement.id if requirement else None,
        requester_user_id=user.id,
        provider_user_id=listing.owner_user_id,
        listing_id=listing.id,
        category=str(payload.get("category") or listing.listing_type).strip(),
        status="draft",
        agreed_amount_minor=amount,
        currency=str(payload.get("currency") or listing.currency).strip().upper(),
        start_at=start_at,
        end_at=end_at,
        expires_at=_optional_datetime(payload.get("expires_at"), "expires_at")
        or utc_now() + timedelta(days=2),
    )
    db.session.add(booking)
    db.session.flush()
    db.session.add_all(
        [
            BookingParticipant(
                booking_id=booking.id,
                user_id=user.id,
                participant_role="requester",
                can_chat=True,
                can_view_finance=True,
            ),
            BookingParticipant(
                booking_id=booking.id,
                user_id=listing.owner_user_id,
                participant_role=listing.listing_type,
                can_chat=True,
                can_view_finance=True,
            ),
            BookingStatusEvent(
                booking_id=booking.id,
                actor_user_id=user.id,
                from_status=None,
                to_status="draft",
                reason="Booking drafted.",
                metadata_json="{}",
            ),
        ]
    )
    _create_conversation(booking)
    db.session.commit()
    return jsonify(success({"booking": _booking_payload(booking)})), 201


@bookings_blueprint.post("/bookings/<public_id>/send")
def send_booking(public_id: str) -> Response:
    user = _current_user()
    booking = _booking_for_user(public_id, user)
    if booking.requester_user_id != user.id:
        raise APIError(
            "booking.permission_denied", "Only requester can send.", status=403
        )
    if booking.status != "draft":
        raise APIError(
            "booking.invalid_state", "Only draft bookings can be sent.", status=409
        )
    payload = _json_body()
    offer_payload = {
        "fee_minor": payload.get("fee_minor", booking.agreed_amount_minor),
        "currency": payload.get("currency", booking.currency),
        "schedule": payload.get("schedule")
        or {
            "start_at": booking.start_at.isoformat(),
            "end_at": booking.end_at.isoformat(),
        },
        "conditions": payload.get("conditions"),
        "payment_schedule": payload.get("payment_schedule") or [],
        "expires_at": payload.get("expires_at") or booking.expires_at.isoformat()
        if booking.expires_at
        else None,
    }
    offer = _create_offer(
        booking,
        user,
        booking.provider_user_id,
        offer_payload,
        message=str(payload.get("message", "")).strip()[:4000] or None,
    )
    booking.agreed_amount_minor = offer.fee_minor
    booking.currency = offer.currency
    _set_status(booking, "sent", user, reason="Initial offer sent.")
    _sync_casting_application_status(
        booking,
        user,
        "offer_received",
        note="A booking offer was sent.",
    )
    notify_user(
        booking.provider_user_id,
        category="booking",
        title=(
            "New offer for "
            f"{booking.requirement.title if booking.requirement else booking.category}"
        ),
        body=f"{booking.requester.display_name} sent a booking offer.",
        route_name="/talent/offers/:id",
        route_params={"id": booking.public_id},
    )
    db.session.commit()
    return jsonify(success({"booking": _booking_payload(booking)}))


@bookings_blueprint.get("/negotiations")
def negotiations() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(NegotiationThread)
        .join(Booking)
        .join(BookingParticipant, BookingParticipant.booking_id == Booking.id)
        .where(BookingParticipant.user_id == user.id)
        .order_by(NegotiationThread.updated_at.desc())
    ).scalars()
    return jsonify(
        success({"negotiations": [_negotiation_payload(row) for row in rows]})
    )


@bookings_blueprint.get("/negotiations/<public_id>")
def negotiation_detail(public_id: str) -> Response:
    user = _current_user()
    thread = db.session.execute(
        select(NegotiationThread)
        .join(Booking)
        .join(BookingParticipant, BookingParticipant.booking_id == Booking.id)
        .where(
            NegotiationThread.public_id == public_id,
            BookingParticipant.user_id == user.id,
        )
    ).scalar_one_or_none()
    if thread is None:
        raise APIError(
            "negotiation.not_found", "Negotiation was not found.", status=404
        )
    return jsonify(success({"negotiation": _negotiation_payload(thread)}))


@bookings_blueprint.post("/bookings/<public_id>/offers")
def create_counter_offer(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    booking = _booking_for_user(public_id, user)
    if booking.status not in {"sent", "viewed", "under_negotiation"}:
        raise APIError(
            "booking.invalid_state",
            "Booking is not open for negotiation.",
            status=409,
        )
    if user.id not in {booking.requester_user_id, booking.provider_user_id}:
        raise APIError("booking.permission_denied", "Not a participant.", status=403)
    recipient_id = (
        booking.provider_user_id
        if user.id == booking.requester_user_id
        else booking.requester_user_id
    )
    payload = _json_body()
    offer = _create_offer(
        booking,
        user,
        recipient_id,
        payload,
        message=str(payload.get("message", "")).strip()[:4000] or None,
    )
    _set_status(booking, "under_negotiation", user, reason="Counter offer sent.")
    db.session.commit()
    return jsonify(success({"offer": _offer_payload(offer)})), 201


@bookings_blueprint.post("/offers/<public_id>/accept")
def accept_offer(public_id: str) -> Response:
    user = _current_user()
    offer = _offer_for_user(public_id, user)
    booking = offer.booking
    if offer.status != "active":
        raise APIError(
            "offer.invalid_state", "Only active offers can be accepted.", status=409
        )
    if offer.recipient_user_id != user.id:
        raise APIError(
            "offer.permission_denied", "Only recipient can accept.", status=403
        )
    if _availability_conflicts(
        booking.provider.public_id,
        booking.start_at,
        booking.end_at,
        exclude_booking_id=booking.id,
    ):
        raise APIError(
            "availability.conflict",
            "Provider has a conflicting hold or booking.",
            status=409,
        )
    offer.status = "accepted"
    booking.agreed_amount_minor = offer.fee_minor
    booking.currency = offer.currency
    booking.secured_at = utc_now()
    if booking.negotiation_thread:
        booking.negotiation_thread.status = "accepted"
        booking.negotiation_thread.locked_at = utc_now()
    calendar = _ensure_calendar(booking.provider.public_id)
    db.session.add(
        AvailabilityEntry(
            calendar_id=calendar.id,
            resource_type=booking.category,
            resource_id=booking.listing.profile_entity_id,
            start_at=booking.start_at,
            end_at=booking.end_at,
            status="booked",
            source_booking_id=booking.id,
            note=f"{booking.project.title} booking",
        )
    )
    _set_status(booking, "accepted", user, reason="Offer accepted.")
    _sync_casting_application_status(
        booking,
        user,
        "selected",
        note="The booking offer was accepted.",
    )
    db.session.commit()
    return jsonify(success({"booking": _booking_payload(booking)}))


@bookings_blueprint.post("/bookings/<public_id>/reject")
def reject_booking(public_id: str) -> Response:
    user = _current_user()
    booking = _booking_for_user(public_id, user)
    if booking.status not in BOOKING_MUTABLE_STATUSES:
        raise APIError(
            "booking.invalid_state", "Booking cannot be rejected.", status=409
        )
    reason = str(_json_body().get("reason", "")).strip()[:2000] or "Rejected."
    _set_status(booking, "rejected", user, reason=reason)
    _sync_casting_application_status(
        booking,
        user,
        "withdrawn" if user.id == booking.provider_user_id else "rejected",
        note=reason,
    )
    if booking.negotiation_thread:
        booking.negotiation_thread.status = "rejected"
        booking.negotiation_thread.locked_at = utc_now()
    db.session.commit()
    return jsonify(success({"booking": _booking_payload(booking)}))


@bookings_blueprint.get("/conversations/<public_id>/messages")
def conversation_messages(public_id: str) -> Response:
    user = _current_user()
    conversation = _conversation_for_user(public_id, user)
    return jsonify(success({"conversation": _conversation_payload(conversation)}))


@bookings_blueprint.post("/conversations/<public_id>/messages")
def create_message(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    conversation = _conversation_for_user(public_id, user)
    payload = _json_body()
    body = str(payload.get("body", "")).strip()
    attachments = payload.get("attachments") or []
    if not body and not attachments:
        raise _field_error("body", "Message body or attachment is required.")
    message = Message(
        conversation_id=conversation.id,
        sender_user_id=user.id,
        message_type=str(payload.get("message_type", "text")).strip()[:32] or "text",
        body=body[:5000] or None,
        decision_type=str(payload.get("decision_type", "")).strip()[:64] or None,
    )
    db.session.add(message)
    db.session.flush()
    if not isinstance(attachments, list):
        raise _field_error("attachments", "Attachments must be a list.")
    for raw_item in attachments[:8]:
        if not isinstance(raw_item, dict):
            continue
        file_id = str(raw_item.get("file_id", "")).strip()
        file = db.session.execute(
            select(FileAsset).where(
                FileAsset.public_id == file_id,
                FileAsset.owner_user_id == user.id,
                FileAsset.scan_status == "clean",
                FileAsset.processing_status == "ready",
            )
        ).scalar_one_or_none()
        if file is None:
            raise _field_error(
                "attachments", "Attachment file must be owned and ready."
            )
        db.session.add(
            MessageAttachment(
                message_id=message.id,
                file_id=file.id,
                attachment_type=str(raw_item.get("attachment_type", "file")).strip()[
                    :32
                ],
                caption=str(raw_item.get("caption", "")).strip()[:255] or None,
            )
        )
    conversation.last_message_at = utc_now()
    db.session.commit()
    return jsonify(success({"message": _message_payload(message)})), 201


@bookings_blueprint.post("/messages/<public_id>/pin")
def pin_message(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    message = db.session.execute(
        select(Message)
        .join(Conversation)
        .join(ConversationMember, ConversationMember.conversation_id == Conversation.id)
        .where(Message.public_id == public_id, ConversationMember.user_id == user.id)
    ).scalar_one_or_none()
    if message is None:
        raise APIError("message.not_found", "Message was not found.", status=404)
    decision_key = (
        str(payload.get("decision_key", "decision")).strip()[:64] or "decision"
    )
    pin = PinnedDecision(
        conversation_id=message.conversation_id,
        message_id=message.id,
        pinned_by=user.id,
        decision_key=decision_key,
    )
    db.session.add(pin)
    db.session.commit()
    return jsonify(success({"pinned": True, "decision_key": decision_key})), 201
