from __future__ import annotations

import json
from datetime import UTC, datetime
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import or_, select

from app.api.auth import _current_user, _json_body
from app.api.bookings import _user_payload
from app.api.marketplace import _field_error, _file_payload
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import Booking
from app.models.files import FileAsset
from app.models.identity import User
from app.models.marketplace import City, MarketplaceListing
from app.models.operations import (
    DamageClaim,
    DamageClaimEvidence,
    EquipmentInspection,
    EquipmentInspectionItem,
    EquipmentItem,
    EquipmentPackage,
    EquipmentPackageItem,
    EquipmentProviderProfile,
    EquipmentTerm,
    Incident,
    LocationInspection,
    LocationInspectionItem,
    LocationPricing,
    LocationProperty,
    LocationRule,
    LocationSpace,
    SafetyCheck,
    SafetyCheckIn,
    SafetyCheckItem,
)
from app.models.projects import Project, ProjectMember
from app.responses import success

operations_blueprint = Blueprint("operations", __name__)


def _parse_datetime(value: Any, field: str) -> datetime:
    if not isinstance(value, str) or not value.strip():
        raise _field_error(field, "Datetime is required.")
    try:
        parsed = datetime.fromisoformat(value.strip().replace("Z", "+00:00"))
    except ValueError as exc:
        raise _field_error(field, "Datetime must be ISO-8601.") from exc
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=UTC)
    return parsed.astimezone(UTC)


def _city_id(public_id: str | None) -> Any:
    if not public_id:
        return None
    city = db.session.execute(
        select(City).where(City.public_id == public_id)
    ).scalar_one_or_none()
    if city is None:
        raise _field_error("city_id", "City was not found.")
    return city.id


def _ready_file(public_id: str | None, user: User) -> FileAsset | None:
    if not public_id:
        return None
    file = db.session.execute(
        select(FileAsset).where(
            FileAsset.public_id == public_id,
            FileAsset.owner_user_id == user.id,
            FileAsset.scan_status == "clean",
            FileAsset.processing_status == "ready",
        )
    ).scalar_one_or_none()
    if file is None:
        raise _field_error("file_id", "Evidence file must be owned and ready.")
    return file


def _booking_for_party(public_id: str, user: User) -> Booking:
    booking = db.session.execute(
        select(Booking).where(
            Booking.public_id == public_id,
            or_(
                Booking.requester_user_id == user.id,
                Booking.provider_user_id == user.id,
            ),
        )
    ).scalar_one_or_none()
    if booking is None:
        raise APIError("booking.not_found", "Booking was not found.", status=404)
    return booking


def _project_for_member(public_id: str, user: User) -> Any:
    project = db.session.execute(
        select(Project)
        .join(ProjectMember, ProjectMember.project_id == Project.id)
        .where(Project.public_id == public_id, ProjectMember.user_id == user.id)
    ).scalar_one_or_none()
    if project is None:
        raise APIError("project.not_found", "Project was not found.", status=404)
    return project


def _location_payload(item: LocationProperty) -> dict[str, Any]:
    listing = db.session.execute(
        select(MarketplaceListing)
        .where(
            MarketplaceListing.owner_user_id == item.owner_user_id,
            MarketplaceListing.listing_type == "location",
            MarketplaceListing.profile_entity_id == item.public_id,
        )
        .limit(1)
    ).scalar_one_or_none()
    return {
        "public_id": item.public_id,
        "owner": _user_payload(item.owner),
        "name": item.name,
        "property_type": item.property_type,
        "city": {"public_id": item.city.public_id, "name": item.city.name}
        if item.city
        else None,
        "area_name": item.area_name,
        "public_address": item.public_address,
        "description": item.description,
        "capacity": item.capacity,
        "parking_spaces": item.parking_spaces,
        "power_backup": item.power_backup,
        "accessible": item.accessible,
        "rating_average": item.rating_average,
        "status": item.status,
        "spaces": [_location_space_payload(row) for row in item.spaces],
        "pricing": [_pricing_payload(row) for row in item.pricing],
        "rules": [_rule_payload(row) for row in item.rules],
        "media_files": [
            _file_payload(media.file)
            for media in listing.media
            if media.file is not None
        ]
        if listing
        else [],
    }


def _location_space_payload(item: LocationSpace) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "space_type": item.space_type,
        "capacity": item.capacity,
        "area_sqft": item.area_sqft,
        "description": item.description,
    }


def _pricing_payload(item: LocationPricing) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "label": item.label,
        "amount_minor": item.amount_minor,
        "currency": item.currency,
        "unit": item.unit,
        "enabled": item.enabled,
        "conditions": item.conditions,
    }


def _rule_payload(item: LocationRule) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "rule_type": item.rule_type,
        "label": item.label,
        "note": item.note,
        "allowed": item.allowed,
    }


def _location_inspection_payload(item: LocationInspection) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "booking_id": item.booking.public_id,
        "property_id": item.property.public_id,
        "inspection_type": item.inspection_type,
        "status": item.status,
        "confirmed_by_owner_at": item.confirmed_by_owner_at.isoformat()
        if item.confirmed_by_owner_at
        else None,
        "confirmed_by_renter_at": item.confirmed_by_renter_at.isoformat()
        if item.confirmed_by_renter_at
        else None,
        "meter_reading": item.meter_reading,
        "notes": item.notes,
        "items": [
            {
                "area_label": row.area_label,
                "before_file": _file_payload(row.before_file),
                "after_file": _file_payload(row.after_file),
                "note": row.note,
                "stage": row.stage,
                "issue_severity": row.issue_severity,
            }
            for row in item.items
        ],
    }


def _claim_payload(item: DamageClaim) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "booking_id": item.booking.public_id,
        "claimant": _user_payload(item.claimant),
        "respondent": _user_payload(item.respondent),
        "inspection_id": item.inspection.public_id if item.inspection else None,
        "description": item.description,
        "claimed_minor": item.claimed_minor,
        "currency": item.currency,
        "status": item.status,
        "submitted_at": item.submitted_at.isoformat(),
        "evidence": [
            {
                "file": _file_payload(row.file),
                "evidence_type": row.evidence_type,
                "caption": row.caption,
                "captured_at": row.captured_at.isoformat() if row.captured_at else None,
            }
            for row in item.evidence
        ],
    }


def _location_for_owner(public_id: str, user: User) -> LocationProperty:
    item = db.session.execute(
        select(LocationProperty).where(
            LocationProperty.public_id == public_id,
            LocationProperty.owner_user_id == user.id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError("location.not_found", "Location was not found.", status=404)
    return item


def _equipment_profile_payload(item: EquipmentProviderProfile) -> dict[str, Any]:
    listing = db.session.execute(
        select(MarketplaceListing)
        .where(
            MarketplaceListing.owner_user_id == item.user_id,
            MarketplaceListing.listing_type == "equipment",
            MarketplaceListing.profile_entity_id == item.public_id,
        )
        .order_by(MarketplaceListing.updated_at.desc())
        .limit(1)
    ).scalar_one_or_none()
    return {
        "public_id": item.public_id,
        "name": item.name,
        "provider_type": item.provider_type,
        "city": {"public_id": item.city.public_id, "name": item.city.name}
        if item.city
        else None,
        "coverage": item.coverage,
        "service_categories": item.service_categories,
        "bio": item.bio,
        "rating_average": item.rating_average,
        "verification_status": item.verification_status,
        "listing_id": listing.public_id if listing else None,
        "visibility": listing.visibility if listing else "private",
    }


def _equipment_item_payload(item: EquipmentItem) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "category": item.category,
        "brand": item.brand,
        "model_name": item.model_name,
        "condition": item.condition,
        "day_rate_minor": item.day_rate_minor,
        "deposit_minor": item.deposit_minor,
        "currency": item.currency,
        "status": item.status,
    }


def _equipment_package_payload(item: EquipmentPackage) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "description": item.description,
        "operator_included": item.operator_included,
        "price_minor": item.price_minor,
        "currency": item.currency,
        "terms": item.terms,
        "status": item.status,
        "items": [
            {
                "equipment_item": _equipment_item_payload(row.equipment_item),
                "quantity": row.quantity,
                "required": row.required,
            }
            for row in item.package_items
        ],
    }


def _equipment_term_payload(item: EquipmentTerm) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "equipment_item_id": item.equipment_item.public_id
        if item.equipment_item
        else None,
        "label": item.label,
        "note": item.note,
        "amount_minor": item.amount_minor,
        "currency": item.currency,
        "enabled": item.enabled,
        "term_type": item.term_type,
    }


def _equipment_inspection_payload(item: EquipmentInspection) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "booking_id": item.booking.public_id,
        "provider_profile_id": item.provider_profile.public_id,
        "inspection_type": item.inspection_type,
        "status": item.status,
        "handover_at": item.handover_at.isoformat() if item.handover_at else None,
        "return_at": item.return_at.isoformat() if item.return_at else None,
        "signed_by_provider": item.signed_by_provider,
        "signed_by_renter": item.signed_by_renter,
        "items": [
            {
                "equipment_item": _equipment_item_payload(row.equipment_item),
                "before_file": _file_payload(row.before_file),
                "after_file": _file_payload(row.after_file),
                "accessories": json.loads(row.accessories_json)
                if row.accessories_json
                else [],
                "stage": row.stage,
                "note": row.note,
            }
            for row in item.items
        ],
    }


def _equipment_profile_for_user(user: User) -> EquipmentProviderProfile:
    profile = db.session.execute(
        select(EquipmentProviderProfile).where(
            EquipmentProviderProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if profile is None:
        raise APIError(
            "equipment.profile_required", "Create provider profile first.", status=409
        )
    return profile


def _equipment_item_for_user(public_id: str, user: User) -> EquipmentItem:
    profile = _equipment_profile_for_user(user)
    item = db.session.execute(
        select(EquipmentItem).where(
            EquipmentItem.public_id == public_id,
            EquipmentItem.provider_profile_id == profile.id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "equipment_item.not_found", "Equipment item was not found.", status=404
        )
    return item


def _sync_equipment_listing(profile: EquipmentProviderProfile) -> None:
    # Resolve the rate lookup before creating/adding a new listing row: once
    # an incomplete (title-less) listing is added to the session, this
    # SELECT would trigger an autoflush of it and violate the NOT NULL
    # constraint on `title`.
    rate_item = db.session.execute(
        select(EquipmentItem)
        .where(
            EquipmentItem.provider_profile_id == profile.id,
            EquipmentItem.status.in_(["available", "published", "active"]),
            EquipmentItem.day_rate_minor.is_not(None),
        )
        .order_by(EquipmentItem.day_rate_minor.asc())
        .limit(1)
    ).scalar_one_or_none()
    listing = db.session.execute(
        select(MarketplaceListing)
        .where(
            MarketplaceListing.owner_user_id == profile.user_id,
            MarketplaceListing.listing_type == "equipment",
            MarketplaceListing.profile_entity_id == profile.public_id,
        )
        .order_by(MarketplaceListing.updated_at.desc())
        .limit(1)
    ).scalar_one_or_none()
    if listing is None:
        listing = MarketplaceListing(
            owner_user_id=profile.user_id,
            listing_type="equipment",
            profile_entity_id=profile.public_id,
            verification_status=profile.verification_status,
            moderation_status="approved",
            visibility="public",
        )
        db.session.add(listing)
    listing.title = profile.name[:180]
    listing.summary = (
        profile.bio
        or profile.service_categories
        or profile.coverage
        or f"{profile.name} provides production equipment rentals."
    )[:2000]
    listing.city_id = profile.city_id
    listing.price_from_minor = rate_item.day_rate_minor if rate_item else None
    listing.currency = rate_item.currency if rate_item else "PKR"
    listing.verification_status = profile.verification_status
    listing.moderation_status = "approved"
    listing.published_at = listing.published_at or utc_now()


def _safety_check_payload(item: SafetyCheck) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "project_id": item.project.public_id,
        "responsible_user": _user_payload(item.responsible_user),
        "due_at": item.due_at.isoformat() if item.due_at else None,
        "risk_level": item.risk_level,
        "status": item.status,
        "items": [
            {
                "id": str(row.id),
                "label": row.label,
                "detail": row.detail,
                "mandatory": row.mandatory,
                "completed_at": row.completed_at.isoformat()
                if row.completed_at
                else None,
            }
            for row in item.items
        ],
    }


def _incident_payload(item: Incident) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "project_id": item.project.public_id,
        "reported_by": _user_payload(item.reporter),
        "title": item.title,
        "severity": item.severity,
        "occurred_at": item.occurred_at.isoformat(),
        "parties": item.parties,
        "description": item.description,
        "corrective_action": item.corrective_action,
        "status": item.status,
    }


def _check_in_payload(item: SafetyCheckIn) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "user": _user_payload(item.user),
        "booking_id": item.booking.public_id,
        "scheduled_at": item.scheduled_at.isoformat(),
        "checked_in_at": item.checked_in_at.isoformat() if item.checked_in_at else None,
        "status": item.status,
        "escalated_at": item.escalated_at.isoformat() if item.escalated_at else None,
    }


@operations_blueprint.post("/location-properties")
def create_location_property() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    name = str(payload.get("name", "")).strip()
    if len(name) < 2:
        raise _field_error("name", "Location name is required.")
    status = str(payload.get("status", "draft")).strip()
    if status not in {"draft", "published", "archived"}:
        raise _field_error("status", "Unsupported location status.")
    item = LocationProperty(
        owner_user_id=user.id,
        name=name[:180],
        property_type=str(payload.get("property_type", "house")).strip()[:64],
        city_id=_city_id(str(payload.get("city_id", "")).strip() or None),
        area_name=str(payload.get("area_name", "")).strip()[:120] or None,
        public_address=str(payload.get("public_address", "")).strip()[:255] or None,
        private_address_token="encrypted:pending"
        if payload.get("private_address")
        else None,
        description=str(payload.get("description", "")).strip()[:4000] or None,
        capacity=int(payload.get("capacity") or 0) or None,
        parking_spaces=int(payload.get("parking_spaces") or 0) or None,
        power_backup=bool(payload.get("power_backup", False)),
        accessible=bool(payload.get("accessible", False)),
        status=status,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"property": _location_payload(item)})), 201


@operations_blueprint.get("/location-properties")
def list_location_properties() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(LocationProperty)
        .where(LocationProperty.owner_user_id == user.id)
        .order_by(LocationProperty.updated_at.desc())
    ).scalars()
    return jsonify(success({"properties": [_location_payload(row) for row in rows]}))


@operations_blueprint.patch("/location-properties/<public_id>")
def update_location_property(public_id: str) -> Response:
    user = _current_user()
    payload = _json_body()
    item = _location_for_owner(public_id, user)
    if "name" in payload:
        name = str(payload.get("name", "")).strip()
        if len(name) < 2:
            raise _field_error("name", "Location name is required.")
        item.name = name[:180]
    if "property_type" in payload:
        item.property_type = (
            str(payload.get("property_type", "")).strip()[:64] or item.property_type
        )
    if "city_id" in payload:
        item.city_id = _city_id(str(payload.get("city_id", "")).strip() or None)
    if "area_name" in payload:
        item.area_name = str(payload.get("area_name", "")).strip()[:120] or None
    if "public_address" in payload:
        item.public_address = (
            str(payload.get("public_address", "")).strip()[:255] or None
        )
    if "private_address" in payload:
        item.private_address_token = (
            "encrypted:pending"
            if str(payload.get("private_address", "")).strip()
            else None
        )
    if "description" in payload:
        item.description = str(payload.get("description", "")).strip()[:4000] or None
    if "capacity" in payload:
        item.capacity = int(payload.get("capacity") or 0) or None
    if "parking_spaces" in payload:
        item.parking_spaces = int(payload.get("parking_spaces") or 0) or None
    if "power_backup" in payload:
        item.power_backup = bool(payload.get("power_backup"))
    if "accessible" in payload:
        item.accessible = bool(payload.get("accessible"))
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in {"draft", "published", "archived"}:
            raise _field_error("status", "Unsupported location status.")
        item.status = status
    db.session.commit()
    return jsonify(success({"property": _location_payload(item)}))


@operations_blueprint.post("/location-properties/<public_id>/spaces")
def create_location_space(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    prop = _location_for_owner(public_id, user)
    payload = _json_body()
    name = str(payload.get("name", "")).strip()
    if len(name) < 2:
        raise _field_error("name", "Space name is required.")
    item = LocationSpace(
        property_id=prop.id,
        name=name[:120],
        space_type=str(payload.get("space_type", "interior")).strip()[:64],
        capacity=int(payload.get("capacity") or 0) or None,
        area_sqft=int(payload.get("area_sqft") or 0) or None,
        description=str(payload.get("description", "")).strip()[:2000] or None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"space": _location_space_payload(item)})), 201


@operations_blueprint.patch("/location-spaces/<public_id>")
def update_location_space(public_id: str) -> Response:
    user = _current_user()
    payload = _json_body()
    item = db.session.execute(
        select(LocationSpace)
        .join(LocationProperty)
        .where(
            LocationSpace.public_id == public_id,
            LocationProperty.owner_user_id == user.id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError("location_space.not_found", "Space was not found.", status=404)
    if "name" in payload:
        name = str(payload.get("name", "")).strip()
        if len(name) < 2:
            raise _field_error("name", "Space name is required.")
        item.name = name[:120]
    if "space_type" in payload:
        item.space_type = (
            str(payload.get("space_type", "")).strip()[:64] or item.space_type
        )
    if "capacity" in payload:
        item.capacity = int(payload.get("capacity") or 0) or None
    if "area_sqft" in payload:
        item.area_sqft = int(payload.get("area_sqft") or 0) or None
    if "description" in payload:
        item.description = str(payload.get("description", "")).strip()[:2000] or None
    db.session.commit()
    return jsonify(success({"space": _location_space_payload(item)}))


@operations_blueprint.post("/location-properties/<public_id>/pricing")
def create_location_pricing(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    prop = _location_for_owner(public_id, user)
    payload = _json_body()
    amount_minor = int(payload.get("amount_minor") or 0)
    if amount_minor < 0:
        raise _field_error("amount_minor", "Amount cannot be negative.")
    item = LocationPricing(
        property_id=prop.id,
        label=str(payload.get("label", "Day shoot")).strip()[:120],
        amount_minor=amount_minor,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        unit=str(payload.get("unit", "day")).strip()[:32],
        enabled=bool(payload.get("enabled", True)),
        conditions=str(payload.get("conditions", "")).strip()[:2000] or None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"pricing": _pricing_payload(item)})), 201


@operations_blueprint.patch("/location-pricing/<public_id>")
def update_location_pricing(public_id: str) -> Response:
    user = _current_user()
    payload = _json_body()
    item = db.session.execute(
        select(LocationPricing)
        .join(LocationProperty)
        .where(
            LocationPricing.public_id == public_id,
            LocationProperty.owner_user_id == user.id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "location_pricing.not_found", "Pricing was not found.", status=404
        )
    if "label" in payload:
        item.label = str(payload.get("label", "")).strip()[:120] or item.label
    if "amount_minor" in payload:
        amount_minor = int(payload.get("amount_minor") or 0)
        if amount_minor < 0:
            raise _field_error("amount_minor", "Amount cannot be negative.")
        item.amount_minor = amount_minor
    if "currency" in payload:
        item.currency = (
            str(payload.get("currency", "")).strip().upper()[:3] or item.currency
        )
    if "unit" in payload:
        item.unit = str(payload.get("unit", "")).strip()[:32] or item.unit
    if "enabled" in payload:
        item.enabled = bool(payload.get("enabled"))
    if "conditions" in payload:
        item.conditions = str(payload.get("conditions", "")).strip()[:2000] or None
    db.session.commit()
    return jsonify(success({"pricing": _pricing_payload(item)}))


@operations_blueprint.post("/location-properties/<public_id>/rules")
def create_location_rule(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    prop = _location_for_owner(public_id, user)
    payload = _json_body()
    label = str(payload.get("label", "")).strip()
    if len(label) < 2:
        raise _field_error("label", "Rule label is required.")
    item = LocationRule(
        property_id=prop.id,
        rule_type=str(payload.get("rule_type", "noise")).strip()[:64],
        label=label[:120],
        note=str(payload.get("note", "")).strip()[:2000] or None,
        allowed=bool(payload.get("allowed", True)),
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"rule": _rule_payload(item)})), 201


@operations_blueprint.patch("/location-rules/<public_id>")
def update_location_rule(public_id: str) -> Response:
    user = _current_user()
    payload = _json_body()
    item = db.session.execute(
        select(LocationRule)
        .join(LocationProperty)
        .where(
            LocationRule.public_id == public_id,
            LocationProperty.owner_user_id == user.id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError("location_rule.not_found", "Rule was not found.", status=404)
    if "rule_type" in payload:
        item.rule_type = (
            str(payload.get("rule_type", "")).strip()[:64] or item.rule_type
        )
    if "label" in payload:
        label = str(payload.get("label", "")).strip()
        if len(label) < 2:
            raise _field_error("label", "Rule label is required.")
        item.label = label[:120]
    if "note" in payload:
        item.note = str(payload.get("note", "")).strip()[:2000] or None
    if "allowed" in payload:
        item.allowed = bool(payload.get("allowed"))
    db.session.commit()
    return jsonify(success({"rule": _rule_payload(item)}))


@operations_blueprint.post("/location-inspections")
def create_location_inspection() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    booking = _booking_for_party(str(payload.get("booking_id", "")).strip(), user)
    prop = db.session.execute(
        select(LocationProperty).where(
            LocationProperty.public_id == str(payload.get("property_id", "")).strip()
        )
    ).scalar_one_or_none()
    if prop is None:
        raise APIError("location.not_found", "Location was not found.", status=404)
    if user.id not in {booking.requester_user_id, prop.owner_user_id}:
        raise APIError(
            "location.permission_denied", "Inspection is not visible.", status=403
        )
    item = LocationInspection(
        booking_id=booking.id,
        property_id=prop.id,
        inspection_type=str(payload.get("inspection_type", "check_in")).strip(),
        meter_reading=str(payload.get("meter_reading", "")).strip()[:80] or None,
        notes=str(payload.get("notes", "")).strip()[:4000] or None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"inspection": _location_inspection_payload(item)})), 201


@operations_blueprint.get("/location-inspections")
def location_inspections() -> Response:
    user = _current_user()
    query = (
        select(LocationInspection)
        .join(
            LocationProperty,
            LocationInspection.property_id == LocationProperty.id,
        )
        .join(Booking, LocationInspection.booking_id == Booking.id)
        .where(
            or_(
                LocationProperty.owner_user_id == user.id,
                Booking.requester_user_id == user.id,
                Booking.provider_user_id == user.id,
            )
        )
    )
    property_id = request.args.get("property_id")
    if property_id:
        query = query.where(LocationProperty.public_id == property_id)
    booking_id = request.args.get("booking_id")
    if booking_id:
        query = query.where(Booking.public_id == booking_id)
    inspection_type = request.args.get("type")
    if inspection_type:
        query = query.where(LocationInspection.inspection_type == inspection_type)
    rows = db.session.execute(
        query.order_by(LocationInspection.updated_at.desc()).limit(100)
    ).scalars()
    return jsonify(
        success({"inspections": [_location_inspection_payload(item) for item in rows]})
    )


@operations_blueprint.post("/location-inspections/<public_id>/items")
def add_location_inspection_item(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    inspection = db.session.execute(
        select(LocationInspection).where(LocationInspection.public_id == public_id)
    ).scalar_one_or_none()
    if inspection is None:
        raise APIError("inspection.not_found", "Inspection was not found.", status=404)
    if user.id not in {
        inspection.booking.requester_user_id,
        inspection.property.owner_user_id,
    }:
        raise APIError(
            "inspection.permission_denied", "Inspection is not visible.", status=403
        )
    payload = _json_body()
    before_file = _ready_file(
        str(payload.get("before_file_id", "")).strip() or None, user
    )
    after_file = _ready_file(
        str(payload.get("after_file_id", "")).strip() or None, user
    )
    item = LocationInspectionItem(
        inspection_id=inspection.id,
        area_label=str(payload.get("area_label", "")).strip()[:120],
        before_file_id=before_file.id if before_file else None,
        after_file_id=after_file.id if after_file else None,
        note=str(payload.get("note", "")).strip()[:2000] or None,
        issue_severity=str(payload.get("issue_severity", "none")).strip()[:32],
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(
        success({"inspection": _location_inspection_payload(inspection)})
    ), 201


@operations_blueprint.post("/location-inspections/<public_id>/confirm")
def confirm_location_inspection(public_id: str) -> Response:
    user = _current_user()
    inspection = db.session.execute(
        select(LocationInspection).where(LocationInspection.public_id == public_id)
    ).scalar_one_or_none()
    if inspection is None:
        raise APIError("inspection.not_found", "Inspection was not found.", status=404)
    if user.id == inspection.property.owner_user_id:
        inspection.confirmed_by_owner_at = inspection.confirmed_by_owner_at or utc_now()
    elif user.id == inspection.booking.requester_user_id:
        inspection.confirmed_by_renter_at = (
            inspection.confirmed_by_renter_at or utc_now()
        )
    else:
        raise APIError(
            "inspection.permission_denied", "Inspection is not visible.", status=403
        )
    if inspection.confirmed_by_owner_at and inspection.confirmed_by_renter_at:
        inspection.status = "confirmed"
    db.session.commit()
    return jsonify(success({"inspection": _location_inspection_payload(inspection)}))


@operations_blueprint.post("/damage-claims")
def create_damage_claim() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    booking = _booking_for_party(str(payload.get("booking_id", "")).strip(), user)
    respondent_id = (
        booking.provider_user_id
        if user.id == booking.requester_user_id
        else booking.requester_user_id
    )
    inspection = None
    raw_inspection = str(payload.get("inspection_id", "")).strip()
    if raw_inspection:
        inspection = db.session.execute(
            select(LocationInspection).where(
                LocationInspection.public_id == raw_inspection
            )
        ).scalar_one_or_none()
    item = DamageClaim(
        booking_id=booking.id,
        claimant_user_id=user.id,
        respondent_user_id=respondent_id,
        inspection_id=inspection.id if inspection else None,
        description=str(payload.get("description", "")).strip()[:4000],
        claimed_minor=int(payload.get("claimed_minor") or 0),
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        submitted_at=utc_now(),
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"claim": _claim_payload(item)})), 201


@operations_blueprint.get("/damage-claims")
def damage_claims() -> Response:
    user = _current_user()
    query = select(DamageClaim).where(
        or_(
            DamageClaim.claimant_user_id == user.id,
            DamageClaim.respondent_user_id == user.id,
        )
    )
    booking_id = request.args.get("booking_id")
    if booking_id:
        query = query.join(Booking).where(Booking.public_id == booking_id)
    rows = db.session.execute(
        query.order_by(DamageClaim.submitted_at.desc()).limit(100)
    ).scalars()
    return jsonify(success({"claims": [_claim_payload(item) for item in rows]}))


@operations_blueprint.post("/damage-claims/<public_id>/evidence")
def add_damage_claim_evidence(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    claim = db.session.execute(
        select(DamageClaim).where(DamageClaim.public_id == public_id)
    ).scalar_one_or_none()
    if claim is None or user.id not in {
        claim.claimant_user_id,
        claim.respondent_user_id,
    }:
        raise APIError(
            "damage_claim.not_found", "Damage claim was not found.", status=404
        )
    payload = _json_body()
    file = _ready_file(str(payload.get("file_id", "")).strip() or None, user)
    evidence = DamageClaimEvidence(
        claim_id=claim.id,
        file_id=file.id if file else None,
        evidence_type=str(payload.get("evidence_type", "photo")).strip()[:64],
        caption=str(payload.get("caption", "")).strip()[:255] or None,
        captured_at=_parse_datetime(payload["captured_at"], "captured_at")
        if payload.get("captured_at")
        else None,
    )
    db.session.add(evidence)
    db.session.commit()
    return jsonify(success({"claim": _claim_payload(claim)})), 201


@operations_blueprint.patch("/equipment/provider-profile")
def upsert_equipment_profile() -> Response:
    user = _current_user()
    payload = _json_body()
    item = db.session.execute(
        select(EquipmentProviderProfile).where(
            EquipmentProviderProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if item is None:
        item = EquipmentProviderProfile(user_id=user.id, name=user.display_name)
        db.session.add(item)
    item.name = str(payload.get("name", item.name)).strip()[:180]
    item.provider_type = str(payload.get("provider_type", item.provider_type)).strip()[
        :64
    ]
    if payload.get("city_id"):
        item.city_id = _city_id(str(payload.get("city_id")).strip())
    item.coverage = (
        str(payload.get("coverage", item.coverage or "")).strip()[:255] or None
    )
    item.service_categories = (
        str(payload.get("service_categories", item.service_categories or "")).strip()[
            :255
        ]
        or None
    )
    item.bio = str(payload.get("bio", item.bio or "")).strip()[:4000] or None
    db.session.flush()
    _sync_equipment_listing(item)
    if "visibility" in payload:
        visibility = str(payload.get("visibility", "public")).strip()
        if visibility not in {"public", "private"}:
            raise _field_error("visibility", "Visibility must be public or private.")
        listing = db.session.execute(
            select(MarketplaceListing)
            .where(
                MarketplaceListing.owner_user_id == item.user_id,
                MarketplaceListing.listing_type == "equipment",
                MarketplaceListing.profile_entity_id == item.public_id,
            )
            .order_by(MarketplaceListing.updated_at.desc())
            .limit(1)
        ).scalar_one()
        listing.visibility = visibility
    db.session.commit()
    return jsonify(success({"profile": _equipment_profile_payload(item)}))


@operations_blueprint.get("/equipment/provider-profile")
def equipment_profile() -> Response:
    user = _current_user()
    item = db.session.execute(
        select(EquipmentProviderProfile).where(
            EquipmentProviderProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    return jsonify(
        success({"profile": _equipment_profile_payload(item) if item else None})
    )


@operations_blueprint.post("/equipment/items")
def create_equipment_item() -> ResponseReturnValue:
    user = _current_user()
    profile = _equipment_profile_for_user(user)
    payload = _json_body()
    item = EquipmentItem(
        provider_profile_id=profile.id,
        category=str(payload.get("category", "camera")).strip()[:64],
        brand=str(payload.get("brand", "")).strip()[:120] or None,
        model_name=str(payload.get("model_name", "")).strip()[:120],
        serial_token="encrypted:pending" if payload.get("serial") else None,
        condition=str(payload.get("condition", "good")).strip()[:64],
        day_rate_minor=int(payload.get("day_rate_minor") or 0) or None,
        deposit_minor=int(payload.get("deposit_minor") or 0) or None,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        city_id=profile.city_id,
        status=str(payload.get("status", "available")).strip()[:32],
    )
    db.session.add(item)
    db.session.flush()
    _sync_equipment_listing(profile)
    db.session.commit()
    return jsonify(success({"item": _equipment_item_payload(item)})), 201


@operations_blueprint.get("/equipment/items")
def equipment_items() -> Response:
    user = _current_user()
    profile = db.session.execute(
        select(EquipmentProviderProfile).where(
            EquipmentProviderProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if profile is None:
        return jsonify(success({"items": []}))
    rows = db.session.execute(
        select(EquipmentItem).where(EquipmentItem.provider_profile_id == profile.id)
    ).scalars()
    return jsonify(success({"items": [_equipment_item_payload(row) for row in rows]}))


@operations_blueprint.patch("/equipment/items/<public_id>")
def update_equipment_item(public_id: str) -> Response:
    user = _current_user()
    item = _equipment_item_for_user(public_id, user)
    payload = _json_body()
    if "category" in payload:
        item.category = str(payload.get("category", "")).strip()[:64]
    if "brand" in payload:
        item.brand = str(payload.get("brand", "")).strip()[:120] or None
    if "model_name" in payload:
        item.model_name = str(payload.get("model_name", "")).strip()[:120]
    if "serial" in payload:
        item.serial_token = "encrypted:pending" if payload.get("serial") else None
    if "condition" in payload:
        item.condition = str(payload.get("condition", "")).strip()[:64]
    if "day_rate_minor" in payload:
        item.day_rate_minor = int(payload.get("day_rate_minor") or 0) or None
    if "deposit_minor" in payload:
        item.deposit_minor = int(payload.get("deposit_minor") or 0) or None
    if "currency" in payload:
        item.currency = str(payload.get("currency", "PKR")).strip().upper()[:3]
    if "status" in payload:
        item.status = str(payload.get("status", "available")).strip()[:32]
    _sync_equipment_listing(item.provider_profile)
    db.session.commit()
    return jsonify(success({"item": _equipment_item_payload(item)}))


@operations_blueprint.post("/equipment/packages")
def create_equipment_package() -> ResponseReturnValue:
    user = _current_user()
    profile = _equipment_profile_for_user(user)
    payload = _json_body()
    package = EquipmentPackage(
        provider_profile_id=profile.id,
        name=str(payload.get("name", "")).strip()[:180],
        description=str(payload.get("description", "")).strip()[:4000] or None,
        operator_included=bool(payload.get("operator_included", False)),
        price_minor=int(payload.get("price_minor") or 0) or None,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        terms=str(payload.get("terms", "")).strip()[:4000] or None,
        status=str(payload.get("status", "draft")).strip()[:32],
    )
    db.session.add(package)
    db.session.commit()
    return jsonify(success({"package": _equipment_package_payload(package)})), 201


@operations_blueprint.get("/equipment/packages")
def equipment_packages() -> Response:
    user = _current_user()
    profile = db.session.execute(
        select(EquipmentProviderProfile).where(
            EquipmentProviderProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if profile is None:
        return jsonify(success({"packages": []}))
    rows = db.session.execute(
        select(EquipmentPackage)
        .where(EquipmentPackage.provider_profile_id == profile.id)
        .order_by(EquipmentPackage.updated_at.desc())
    ).scalars()
    return jsonify(
        success({"packages": [_equipment_package_payload(row) for row in rows]})
    )


@operations_blueprint.patch("/equipment/packages/<public_id>")
def update_equipment_package(public_id: str) -> Response:
    user = _current_user()
    profile = _equipment_profile_for_user(user)
    package = db.session.execute(
        select(EquipmentPackage).where(
            EquipmentPackage.public_id == public_id,
            EquipmentPackage.provider_profile_id == profile.id,
        )
    ).scalar_one_or_none()
    if package is None:
        raise APIError(
            "equipment_package.not_found", "Package was not found.", status=404
        )
    payload = _json_body()
    for field, limit in (("name", 180), ("description", 4000), ("terms", 4000)):
        if field in payload:
            value = str(payload.get(field, "")).strip()[:limit]
            setattr(package, field, value or None)
    if "operator_included" in payload:
        package.operator_included = bool(payload.get("operator_included"))
    if "price_minor" in payload:
        package.price_minor = int(payload.get("price_minor") or 0) or None
    if "currency" in payload:
        package.currency = str(payload.get("currency", "PKR")).strip().upper()[:3]
    if "status" in payload:
        package.status = str(payload.get("status", "draft")).strip()[:32]
    db.session.commit()
    return jsonify(success({"package": _equipment_package_payload(package)}))


@operations_blueprint.post("/equipment/packages/<public_id>/items")
def add_equipment_package_item(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    profile = db.session.execute(
        select(EquipmentProviderProfile).where(
            EquipmentProviderProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    package = db.session.execute(
        select(EquipmentPackage).where(
            EquipmentPackage.public_id == public_id,
            EquipmentPackage.provider_profile_id == (profile.id if profile else None),
        )
    ).scalar_one_or_none()
    if package is None:
        raise APIError(
            "equipment_package.not_found", "Package was not found.", status=404
        )
    payload = _json_body()
    item = db.session.execute(
        select(EquipmentItem).where(
            EquipmentItem.public_id
            == str(payload.get("equipment_item_id", "")).strip(),
            EquipmentItem.provider_profile_id == package.provider_profile_id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise _field_error("equipment_item_id", "Equipment item was not found.")
    db.session.add(
        EquipmentPackageItem(
            package_id=package.id,
            equipment_item_id=item.id,
            quantity=int(payload.get("quantity") or 1),
            required=bool(payload.get("required", True)),
        )
    )
    db.session.commit()
    return jsonify(
        success({"package_item": {"equipment_item_id": item.public_id}})
    ), 201


@operations_blueprint.post("/equipment/terms")
def create_equipment_term() -> ResponseReturnValue:
    user = _current_user()
    profile = _equipment_profile_for_user(user)
    payload = _json_body()
    equipment_item = None
    equipment_item_id = str(payload.get("equipment_item_id", "")).strip()
    if equipment_item_id:
        equipment_item = _equipment_item_for_user(equipment_item_id, user)
    term = EquipmentTerm(
        provider_profile_id=profile.id,
        equipment_item_id=equipment_item.id if equipment_item else None,
        label=str(payload.get("label", "")).strip()[:120],
        note=str(payload.get("note", "")).strip()[:2000] or None,
        amount_minor=int(payload.get("amount_minor") or 0) or None,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        enabled=bool(payload.get("enabled", True)),
        term_type=str(payload.get("term_type", "late_fee")).strip()[:64],
    )
    db.session.add(term)
    db.session.commit()
    return jsonify(success({"term": _equipment_term_payload(term)})), 201


@operations_blueprint.get("/equipment/terms")
def equipment_terms() -> Response:
    user = _current_user()
    profile = db.session.execute(
        select(EquipmentProviderProfile).where(
            EquipmentProviderProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if profile is None:
        return jsonify(success({"terms": []}))
    rows = db.session.execute(
        select(EquipmentTerm)
        .where(EquipmentTerm.provider_profile_id == profile.id)
        .order_by(EquipmentTerm.term_type.asc(), EquipmentTerm.label.asc())
    ).scalars()
    return jsonify(success({"terms": [_equipment_term_payload(row) for row in rows]}))


@operations_blueprint.patch("/equipment/terms/<public_id>")
def update_equipment_term(public_id: str) -> Response:
    user = _current_user()
    profile = _equipment_profile_for_user(user)
    term = db.session.execute(
        select(EquipmentTerm).where(
            EquipmentTerm.public_id == public_id,
            EquipmentTerm.provider_profile_id == profile.id,
        )
    ).scalar_one_or_none()
    if term is None:
        raise APIError("equipment_term.not_found", "Term was not found.", status=404)
    payload = _json_body()
    if "label" in payload:
        term.label = str(payload.get("label", "")).strip()[:120]
    if "note" in payload:
        term.note = str(payload.get("note", "")).strip()[:2000] or None
    if "amount_minor" in payload:
        term.amount_minor = int(payload.get("amount_minor") or 0) or None
    if "currency" in payload:
        term.currency = str(payload.get("currency", "PKR")).strip().upper()[:3]
    if "enabled" in payload:
        term.enabled = bool(payload.get("enabled"))
    if "term_type" in payload:
        term.term_type = str(payload.get("term_type", "late_fee")).strip()[:64]
    db.session.commit()
    return jsonify(success({"term": _equipment_term_payload(term)}))


@operations_blueprint.get("/equipment-inspections")
def equipment_inspections() -> Response:
    user = _current_user()
    profile = db.session.execute(
        select(EquipmentProviderProfile).where(
            EquipmentProviderProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if profile is None:
        return jsonify(success({"inspections": []}))
    query = select(EquipmentInspection).where(
        EquipmentInspection.provider_profile_id == profile.id
    )
    inspection_type = request.args.get("inspection_type")
    if inspection_type:
        query = query.where(EquipmentInspection.inspection_type == inspection_type)
    rows = db.session.execute(
        query.order_by(EquipmentInspection.updated_at.desc()).limit(100)
    ).scalars()
    return jsonify(
        success({"inspections": [_equipment_inspection_payload(row) for row in rows]})
    )


@operations_blueprint.post("/equipment-inspections")
def create_equipment_inspection() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    booking = _booking_for_party(str(payload.get("booking_id", "")).strip(), user)
    profile = db.session.execute(
        select(EquipmentProviderProfile).where(
            EquipmentProviderProfile.public_id
            == str(payload.get("provider_profile_id", "")).strip()
        )
    ).scalar_one_or_none()
    if profile is None:
        raise APIError(
            "equipment.profile_not_found", "Provider profile was not found.", status=404
        )
    if user.id not in {booking.requester_user_id, profile.user_id}:
        raise APIError(
            "equipment.permission_denied", "Inspection is not visible.", status=403
        )
    item = EquipmentInspection(
        booking_id=booking.id,
        provider_profile_id=profile.id,
        inspection_type=str(payload.get("inspection_type", "handover")).strip(),
        handover_at=utc_now()
        if payload.get("inspection_type", "handover") == "handover"
        else None,
        return_at=utc_now() if payload.get("inspection_type") == "return" else None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"inspection": _equipment_inspection_payload(item)})), 201


@operations_blueprint.post("/equipment-inspections/<public_id>/items")
def add_equipment_inspection_item(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    inspection = db.session.execute(
        select(EquipmentInspection).where(EquipmentInspection.public_id == public_id)
    ).scalar_one_or_none()
    if inspection is None or user.id not in {
        inspection.booking.requester_user_id,
        inspection.provider_profile.user_id,
    }:
        raise APIError(
            "equipment_inspection.not_found", "Inspection was not found.", status=404
        )
    payload = _json_body()
    equipment_item = db.session.execute(
        select(EquipmentItem).where(
            EquipmentItem.public_id
            == str(payload.get("equipment_item_id", "")).strip(),
            EquipmentItem.provider_profile_id == inspection.provider_profile_id,
        )
    ).scalar_one_or_none()
    if equipment_item is None:
        raise _field_error("equipment_item_id", "Equipment item was not found.")
    row = db.session.execute(
        select(EquipmentInspectionItem).where(
            EquipmentInspectionItem.inspection_id == inspection.id,
            EquipmentInspectionItem.equipment_item_id == equipment_item.id,
        )
    ).scalar_one_or_none()
    if row is None:
        row = EquipmentInspectionItem(
            inspection_id=inspection.id,
            equipment_item_id=equipment_item.id,
        )
        db.session.add(row)
    if "accessories" in payload:
        row.accessories_json = json.dumps(payload.get("accessories", []))
    if "stage" in payload:
        row.stage = str(payload.get("stage", "captured")).strip()[:32]
    if "note" in payload:
        row.note = str(payload.get("note", "")).strip()[:2000] or None
    if "before_file_id" in payload:
        before_file = _ready_file(
            str(payload.get("before_file_id", "")).strip() or None, user
        )
        row.before_file_id = before_file.id if before_file else None
    if "after_file_id" in payload:
        after_file = _ready_file(
            str(payload.get("after_file_id", "")).strip() or None, user
        )
        row.after_file_id = after_file.id if after_file else None
    db.session.commit()
    return jsonify(
        success({"inspection": _equipment_inspection_payload(inspection)})
    ), 201


@operations_blueprint.post("/equipment-inspections/<public_id>/confirm")
def confirm_equipment_inspection(public_id: str) -> Response:
    user = _current_user()
    inspection = db.session.execute(
        select(EquipmentInspection).where(EquipmentInspection.public_id == public_id)
    ).scalar_one_or_none()
    if inspection is None:
        raise APIError(
            "equipment_inspection.not_found", "Inspection was not found.", status=404
        )
    if user.id == inspection.provider_profile.user_id:
        inspection.signed_by_provider = True
    elif user.id == inspection.booking.requester_user_id:
        inspection.signed_by_renter = True
    else:
        raise APIError(
            "equipment.permission_denied", "Inspection is not visible.", status=403
        )
    if inspection.signed_by_provider and inspection.signed_by_renter:
        inspection.status = "confirmed"
    db.session.commit()
    return jsonify(success({"inspection": _equipment_inspection_payload(inspection)}))


@operations_blueprint.post("/safety-checks")
def create_safety_check() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    project = _project_for_member(str(payload.get("project_id", "")).strip(), user)
    item = SafetyCheck(
        project_id=project.id,
        responsible_user_id=user.id,
        due_at=_parse_datetime(payload["due_at"], "due_at")
        if payload.get("due_at")
        else None,
        risk_level=str(payload.get("risk_level", "medium")).strip()[:32],
        status=str(payload.get("status", "in_review")).strip()[:32],
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"safety_check": _safety_check_payload(item)})), 201


@operations_blueprint.post("/safety-checks/<public_id>/items")
def create_safety_check_item(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    check = db.session.execute(
        select(SafetyCheck).where(SafetyCheck.public_id == public_id)
    ).scalar_one_or_none()
    if check is None or check.responsible_user_id != user.id:
        raise APIError(
            "safety_check.not_found", "Safety check was not found.", status=404
        )
    payload = _json_body()
    row = SafetyCheckItem(
        safety_check_id=check.id,
        label=str(payload.get("label", "")).strip()[:180],
        detail=str(payload.get("detail", "")).strip()[:2000] or None,
        mandatory=bool(payload.get("mandatory", True)),
    )
    db.session.add(row)
    db.session.commit()
    return jsonify(success({"safety_check": _safety_check_payload(check)})), 201


@operations_blueprint.post("/incidents")
def create_incident() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    project = _project_for_member(str(payload.get("project_id", "")).strip(), user)
    item = Incident(
        project_id=project.id,
        reported_by=user.id,
        title=str(payload.get("title", "")).strip()[:180],
        severity=str(payload.get("severity", "low")).strip()[:32],
        occurred_at=_parse_datetime(payload.get("occurred_at"), "occurred_at"),
        parties=str(payload.get("parties", "")).strip()[:255] or None,
        description=str(payload.get("description", "")).strip()[:4000],
        corrective_action=str(payload.get("corrective_action", "")).strip()[:4000]
        or None,
        status=str(payload.get("status", "open")).strip()[:32],
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"incident": _incident_payload(item)})), 201


@operations_blueprint.post("/safety-check-ins")
def create_safety_check_in() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    booking = _booking_for_party(str(payload.get("booking_id", "")).strip(), user)
    item = SafetyCheckIn(
        user_id=user.id,
        booking_id=booking.id,
        scheduled_at=_parse_datetime(payload.get("scheduled_at"), "scheduled_at"),
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"check_in": _check_in_payload(item)})), 201


@operations_blueprint.post("/safety-check-ins/<public_id>/complete")
def complete_safety_check_in(public_id: str) -> Response:
    user = _current_user()
    item = db.session.execute(
        select(SafetyCheckIn).where(
            SafetyCheckIn.public_id == public_id, SafetyCheckIn.user_id == user.id
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "safety_check_in.not_found", "Safety check-in was not found.", status=404
        )
    payload = _json_body()
    item.checked_in_at = utc_now()
    item.latitude_token = "encrypted:pending" if payload.get("latitude") else None
    item.longitude_token = "encrypted:pending" if payload.get("longitude") else None
    item.status = "checked_in"
    db.session.commit()
    return jsonify(success({"check_in": _check_in_payload(item)}))
