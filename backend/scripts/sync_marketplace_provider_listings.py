from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

from sqlalchemy import select

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import create_app
from app.extensions import db
from app.models import (
    CastingAgency,
    DistributionPartnerProfile,
    EquipmentItem,
    EquipmentProviderProfile,
    LocationPricing,
    LocationProperty,
    MarketplaceListing,
    ModelProfile,
    ModelUsageRate,
    TalentProfile,
    UserProfile,
    UserRole,
)
from app.models.base import utc_now


def _money_label_rate(amount: int | None) -> int | None:
    return amount if amount is not None and amount >= 0 else None


def _profile_city_id(user_id: Any) -> Any | None:
    profile = db.session.execute(
        select(UserProfile).where(UserProfile.user_id == user_id)
    ).scalar_one_or_none()
    return profile.city_id if profile else None


def _listing(
    *,
    owner_user_id: Any,
    listing_type: str,
    profile_entity_id: str,
) -> MarketplaceListing:
    row = db.session.execute(
        select(MarketplaceListing).where(
            MarketplaceListing.owner_user_id == owner_user_id,
            MarketplaceListing.listing_type == listing_type,
            MarketplaceListing.profile_entity_id == profile_entity_id,
        )
    ).scalar_one_or_none()
    if row is None:
        row = MarketplaceListing(
            owner_user_id=owner_user_id,
            listing_type=listing_type,
            profile_entity_id=profile_entity_id,
            verification_status="approved",
            moderation_status="approved",
            visibility="public",
            published_at=utc_now(),
        )
        db.session.add(row)
    return row


def _publish(
    *,
    owner_user_id: Any,
    listing_type: str,
    profile_entity_id: str,
    title: str,
    summary: str,
    city_id: Any | None,
    price_from_minor: int | None,
    currency: str = "PKR",
    verification_status: str = "approved",
) -> str:
    row = _listing(
        owner_user_id=owner_user_id,
        listing_type=listing_type,
        profile_entity_id=profile_entity_id,
    )
    row.title = title[:180]
    row.summary = summary[:2000] if len(summary) >= 10 else f"{title} profile."
    row.city_id = city_id
    row.price_from_minor = _money_label_rate(price_from_minor)
    row.currency = (currency or "PKR")[:3].upper()
    row.verification_status = verification_status or "approved"
    row.moderation_status = "approved"
    row.visibility = "public"
    row.published_at = row.published_at or utc_now()
    return row.public_id


def _location_rate(item: LocationProperty) -> tuple[int | None, str]:
    rate = (
        db.session.execute(
            select(LocationPricing)
            .where(LocationPricing.property_id == item.id, LocationPricing.enabled)
            .order_by(LocationPricing.amount_minor.asc())
        )
        .scalars()
        .first()
    )
    return (rate.amount_minor, rate.currency) if rate else (None, "PKR")


def _equipment_rate(item: EquipmentProviderProfile) -> tuple[int | None, str]:
    rate = (
        db.session.execute(
            select(EquipmentItem)
            .where(
                EquipmentItem.provider_profile_id == item.id,
                EquipmentItem.day_rate_minor.is_not(None),
            )
            .order_by(EquipmentItem.day_rate_minor.asc())
        )
        .scalars()
        .first()
    )
    return (rate.day_rate_minor, rate.currency) if rate else (None, "PKR")


def _model_rate(item: ModelProfile) -> tuple[int | None, str]:
    rate = (
        db.session.execute(
            select(ModelUsageRate)
            .where(ModelUsageRate.model_profile_id == item.id)
            .order_by(ModelUsageRate.amount_minor.asc())
        )
        .scalars()
        .first()
    )
    if rate:
        return rate.amount_minor, rate.currency
    return item.talent_profile.day_rate_minor, item.talent_profile.currency


def sync() -> dict[str, int]:
    counts = {
        "actor": 0,
        "model": 0,
        "location": 0,
        "equipment": 0,
        "agency": 0,
        "distribution": 0,
    }
    model_talent_ids = {
        row.talent_profile_id
        for row in db.session.execute(select(ModelProfile)).scalars()
    }
    actors = db.session.execute(
        select(TalentProfile)
        .join(UserRole, UserRole.user_id == TalentProfile.user_id)
        .where(
            UserRole.status == "active",
            UserRole.role.has(code="actor_talent"),
        )
        .order_by(TalentProfile.updated_at.desc())
    ).scalars()
    for actor in actors:
        if actor.id in model_talent_ids:
            continue
        _publish(
            owner_user_id=actor.user_id,
            listing_type="actor",
            profile_entity_id=actor.public_id,
            title=actor.screen_name,
            summary=(
                f"{actor.screen_name} actor profile for casting and production "
                "bookings."
            ),
            city_id=_profile_city_id(actor.user_id),
            price_from_minor=actor.day_rate_minor,
            currency=actor.currency,
        )
        counts["actor"] += 1

    for model in db.session.execute(select(ModelProfile)).scalars():
        if not model.public_visibility:
            continue
        price, currency = _model_rate(model)
        _publish(
            owner_user_id=model.user_id,
            listing_type="model",
            profile_entity_id=model.public_id,
            title=model.talent_profile.screen_name,
            summary=model.brand_safety_notes
            or (
                f"{model.talent_profile.screen_name} model profile for brand "
                "and production campaigns."
            ),
            city_id=_profile_city_id(model.user_id),
            price_from_minor=price,
            currency=currency,
        )
        counts["model"] += 1

    for location in db.session.execute(select(LocationProperty)).scalars():
        if location.status not in {"published", "active", "available"}:
            continue
        price, currency = _location_rate(location)
        _publish(
            owner_user_id=location.owner_user_id,
            listing_type="location",
            profile_entity_id=location.public_id,
            title=location.name,
            summary=location.description
            or location.public_address
            or f"{location.name} location profile.",
            city_id=location.city_id,
            price_from_minor=price,
            currency=currency,
            verification_status=location.status,
        )
        counts["location"] += 1

    for equipment in db.session.execute(select(EquipmentProviderProfile)).scalars():
        price, currency = _equipment_rate(equipment)
        _publish(
            owner_user_id=equipment.user_id,
            listing_type="equipment",
            profile_entity_id=equipment.public_id,
            title=equipment.name,
            summary=equipment.bio
            or equipment.service_categories
            or f"{equipment.name} equipment provider profile.",
            city_id=equipment.city_id,
            price_from_minor=price,
            currency=currency,
            verification_status=equipment.verification_status,
        )
        counts["equipment"] += 1

    for agency in db.session.execute(select(CastingAgency)).scalars():
        _publish(
            owner_user_id=agency.owner_user_id,
            listing_type="agency",
            profile_entity_id=agency.public_id,
            title=agency.name,
            summary=f"{agency.name} casting agency profile and audition roster.",
            city_id=agency.city_id,
            price_from_minor=None,
            verification_status=agency.verification_status,
        )
        counts["agency"] += 1

    for partner in db.session.execute(select(DistributionPartnerProfile)).scalars():
        _publish(
            owner_user_id=partner.user_id,
            listing_type="distribution",
            profile_entity_id=partner.public_id,
            title=partner.name,
            summary=partner.territories
            or partner.channels
            or f"{partner.name} distribution partner profile.",
            city_id=None,
            price_from_minor=None,
            verification_status=partner.status,
        )
        counts["distribution"] += 1

    db.session.commit()
    return counts


def main() -> None:
    app = create_app()
    with app.app_context():
        counts = sync()
    print(counts)


if __name__ == "__main__":
    main()
