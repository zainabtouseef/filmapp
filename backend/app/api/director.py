from __future__ import annotations

import json
from datetime import datetime, time
from typing import Any

from flask import Blueprint, Response, jsonify, request
from sqlalchemy import select

from app.api.auth import _current_user
from app.api.marketplace import (
    _city_payload,
    _file_payload,
    _owner_avatar_url,
    _talent_availability_categories,
)
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import Booking
from app.models.contracts import Contract
from app.models.identity import User, UserRole
from app.models.marketplace import (
    MarketplaceListing,
    ModelProfile,
    PortfolioItem,
    TalentProfile,
    UserProfile,
)
from app.models.operations import (
    EquipmentItem,
    EquipmentPackage,
    EquipmentProviderProfile,
    EquipmentTerm,
    LocationPricing,
    LocationProperty,
    LocationRule,
)
from app.models.payments import PaymentMilestone, PaymentSchedule
from app.models.projects import Project, ProjectMember, ProjectRoomItem
from app.models.specialist import (
    AgencyTalent,
    CastingAgency,
    DistributionPartnerProfile,
)
from app.responses import success
from app.security import as_utc

director_blueprint = Blueprint("director", __name__)


def _has_role(user: User, *role_codes: str) -> bool:
    return any(
        user_role.status == "active" and user_role.role.code in role_codes
        for user_role in user.roles
    )


def _require_director_dashboard(user: User) -> None:
    if not _has_role(user, "director_producer", "casting_agency", "super_admin"):
        raise APIError(
            "director.role_required",
            "A director/producer, casting agency, or admin role is required.",
            status=403,
        )


def _visible_projects(user: User) -> list[Project]:
    query = select(Project)
    if not _has_role(user, "super_admin"):
        query = query.join(ProjectMember, ProjectMember.project_id == Project.id).where(
            ProjectMember.user_id == user.id,
            ProjectMember.status == "active",
        )
    return list(
        db.session.execute(
            query.order_by(Project.updated_at.desc()).limit(20)
        ).scalars()
    )


def _requester_bookings(user: User) -> list[Booking]:
    query = select(Booking)
    if not _has_role(user, "super_admin"):
        query = query.where(Booking.requester_user_id == user.id)
    return list(
        db.session.execute(
            query.order_by(Booking.updated_at.desc()).limit(50)
        ).scalars()
    )


def _project_payload(project: Project) -> dict[str, Any]:
    return {
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
        "status": project.status,
        "start_date": project.start_date.isoformat() if project.start_date else None,
        "end_date": project.end_date.isoformat() if project.end_date else None,
        "estimated_budget_minor": project.estimated_budget_minor,
        "currency": project.currency,
        "visibility": project.visibility,
        "progress_percent": project.progress_percent,
        "requirement_count": len(project.requirements),
        "member_count": len([row for row in project.members if row.status == "active"]),
        "cover_file": _file_payload(project.cover_file),
        "created_at": project.created_at.isoformat(),
        "updated_at": project.updated_at.isoformat(),
    }


def _booking_counterparty(booking: Booking, user: User) -> User:
    return (
        booking.provider if booking.requester_user_id == user.id else booking.requester
    )


def _booking_timeline_payload(booking: Booking, user: User) -> dict[str, Any]:
    counterparty = _booking_counterparty(booking, user)
    return {
        "kind": "booking",
        "public_id": booking.public_id,
        "project_id": booking.project.public_id,
        "project_title": booking.project.title,
        "title": booking.requirement.title if booking.requirement else booking.category,
        "subtitle": counterparty.display_name,
        "starts_at": booking.start_at.isoformat(),
        "ends_at": booking.end_at.isoformat(),
        "status": booking.status,
        "route": "/booking",
        "argument": booking.public_id,
    }


def _payment_rows(user: User) -> list[PaymentMilestone]:
    query = (
        select(PaymentMilestone)
        .join(PaymentSchedule, PaymentSchedule.id == PaymentMilestone.schedule_id)
        .join(Booking, Booking.id == PaymentSchedule.booking_id)
    )
    if not _has_role(user, "super_admin"):
        query = query.where(Booking.requester_user_id == user.id)
    return list(
        db.session.execute(
            query.order_by(PaymentMilestone.due_at.asc()).limit(100)
        ).scalars()
    )


def _payment_payload(milestone: PaymentMilestone) -> dict[str, Any]:
    schedule = milestone.schedule
    booking = schedule.booking
    return {
        "public_id": milestone.public_id,
        "schedule_id": schedule.public_id,
        "booking_id": booking.public_id,
        "project_id": booking.project.public_id,
        "project_title": booking.project.title,
        "stakeholder": booking.provider.display_name,
        "name": milestone.name,
        "amount_minor": milestone.amount_minor,
        "currency": schedule.currency,
        "status": milestone.status,
        "due_at": milestone.due_at.isoformat() if milestone.due_at else None,
        "route": "/payments/proof",
        "argument": milestone.public_id,
    }


def _minor_money_label(amount_minor: int | None, currency: str = "PKR") -> str:
    if amount_minor is None:
        return "Rate on request"
    whole = round(amount_minor / 100)
    if whole >= 1_000_000:
        return f"{currency} {whole / 1_000_000:.1f}M"
    if whole >= 1_000:
        return f"{currency} {round(whole / 1_000)}k"
    return f"{currency} {whole}"


def _split_tags(value: str | None) -> list[str]:
    if not value:
        return []
    return [part.strip() for part in value.replace("|", ",").split(",") if part.strip()]


def _owner_payload(user: User | None) -> dict[str, Any] | None:
    if user is None:
        return None
    return {
        "public_id": user.public_id,
        "display_name": user.display_name,
        "avatar_url": _owner_avatar_url(user.id),
    }


def _detail_row(label: str, value: Any) -> dict[str, str]:
    if value is None:
        text = "Not provided"
    elif isinstance(value, bool):
        text = "Yes" if value else "No"
    else:
        text = str(value)
    return {"label": label, "value": text}


def _detail_section(
    title: str,
    *rows: tuple[str, Any],
) -> dict[str, Any]:
    return {
        "title": title,
        "rows": [_detail_row(label, value) for label, value in rows],
    }


def _matches_discovery_query(item: dict[str, Any], query: str | None) -> bool:
    if not query:
        return True
    haystack = " ".join(
        str(value)
        for value in [
            item.get("title"),
            item.get("subtitle"),
            item.get("summary"),
            item.get("city", {}).get("name") if item.get("city") else None,
            *item.get("tags", []),
        ]
        if value
    ).lower()
    return query.lower() in haystack


def _listing_for_profile(
    listing_type: str,
    profile_entity_id: str,
) -> MarketplaceListing | None:
    return db.session.execute(
        select(MarketplaceListing).where(
            MarketplaceListing.listing_type == listing_type,
            MarketplaceListing.profile_entity_id == profile_entity_id,
            MarketplaceListing.visibility == "public",
            MarketplaceListing.moderation_status == "approved",
        )
    ).scalar_one_or_none()


def _portfolio_media_payload(
    profile_type: str,
    profile_id: str,
) -> list[dict[str, Any]]:
    rows = db.session.execute(
        select(PortfolioItem)
        .where(
            PortfolioItem.profile_type == profile_type,
            PortfolioItem.profile_id == profile_id,
            PortfolioItem.status == "published",
            PortfolioItem.moderation_status == "approved",
        )
        .order_by(PortfolioItem.is_cover.desc(), PortfolioItem.sort_order.asc())
    ).scalars()
    return [
        {
            "file": _file_payload(row.file),
            "sort_order": row.sort_order,
            "is_cover": row.is_cover,
            "caption": row.title,
        }
        for row in rows
        if row.file is not None
    ]


def _with_listing(
    item: dict[str, Any],
    listing_type: str,
    profile_id: str,
) -> dict[str, Any]:
    listing = _listing_for_profile(listing_type, profile_id)
    item["listing_id"] = listing.public_id if listing else None
    if listing:
        if listing.media:
            item["media"] = [
                {
                    "file": _file_payload(row.file),
                    "sort_order": row.sort_order,
                    "is_cover": row.is_cover,
                    "caption": row.caption,
                }
                for row in listing.media
            ]
        item["rate_from_minor"] = listing.price_from_minor
        item["currency"] = listing.currency
        item["rate_label"] = _minor_money_label(
            listing.price_from_minor,
            listing.currency,
        )
        item["verification_status"] = listing.verification_status
    return item


def _profile_for_user(user_id: Any) -> UserProfile | None:
    return db.session.execute(
        select(UserProfile).where(UserProfile.user_id == user_id)
    ).scalar_one_or_none()


def _talent_tags(profile: TalentProfile) -> list[str]:
    tags = [
        *(row.language for row in profile.languages),
        *([f"{profile.experience_years}+ years"] if profile.experience_years else []),
        *(["Available"] if profile.availability_status == "available" else []),
    ]
    return [tag for tag in tags if tag]


def _actor_discovery_item(item: TalentProfile) -> dict[str, Any]:
    profile = _profile_for_user(item.user_id)
    card = {
        "public_id": item.public_id,
        "kind": "actor",
        "category": "Actors",
        "title": item.screen_name,
        "subtitle": item.user.display_name,
        "summary": profile.bio if profile else "Actor / talent profile.",
        "city": _city_payload(profile.city) if profile else None,
        "owner": _owner_payload(item.user),
        "rate_from_minor": item.day_rate_minor,
        "currency": item.currency,
        "rate_label": _minor_money_label(item.day_rate_minor, item.currency),
        "verification_status": "approved",
        "rating_average": int(profile.rating_average) if profile else 0,
        "available": item.availability_status == "available",
        "tags": _talent_tags(item),
        "media": _portfolio_media_payload("talent", item.public_id),
        "resume_file": _file_payload(item.resume_file),
        "route": "/director/discovery/actor",
        "source": {"table": "talent_profiles"},
    }
    return _with_listing(card, "actor", item.public_id)


def _influencer_discovery_item(item: TalentProfile) -> dict[str, Any]:
    profile = _profile_for_user(item.user_id)
    social_tags: list[str] = []
    if item.social_links_json:
        try:
            social_links = json.loads(item.social_links_json)
        except json.JSONDecodeError:
            social_links = {}
        if isinstance(social_links, dict):
            social_tags = [
                key.title()
                for key, value in social_links.items()
                if str(value).strip()
            ][:4]
    card = {
        "public_id": item.public_id,
        "kind": "influencer",
        "category": "Influencers",
        "title": item.screen_name,
        "subtitle": "Influencer / creator profile",
        "summary": profile.bio if profile else "Influencer campaign profile.",
        "city": _city_payload(profile.city) if profile else None,
        "owner": _owner_payload(item.user),
        "rate_from_minor": item.day_rate_minor,
        "currency": item.currency,
        "rate_label": _minor_money_label(item.day_rate_minor, item.currency),
        "verification_status": "approved",
        "rating_average": int(profile.rating_average) if profile else 0,
        "available": item.availability_status == "available",
        "tags": social_tags or _talent_tags(item),
        "media": _portfolio_media_payload("talent", item.public_id),
        "resume_file": _file_payload(item.resume_file),
        "route": "/director/discovery/influencer",
        "source": {"table": "talent_profiles"},
    }
    return _with_listing(card, "influencer", item.public_id)


def _talent_model_discovery_item(item: TalentProfile) -> dict[str, Any]:
    profile = _profile_for_user(item.user_id)
    card = {
        "public_id": item.public_id,
        "kind": "model",
        "category": "Models",
        "title": item.screen_name,
        "subtitle": "Model / talent profile",
        "summary": profile.bio if profile else "Model campaign profile.",
        "city": _city_payload(profile.city) if profile else None,
        "owner": _owner_payload(item.user),
        "rate_from_minor": item.day_rate_minor,
        "currency": item.currency,
        "rate_label": _minor_money_label(item.day_rate_minor, item.currency),
        "verification_status": "approved",
        "rating_average": int(profile.rating_average) if profile else 0,
        "available": item.availability_status == "available",
        "tags": _talent_tags(item),
        "media": _portfolio_media_payload("talent", item.public_id),
        "resume_file": _file_payload(item.resume_file),
        "route": "/director/discovery/model",
        "source": {"table": "talent_profiles"},
    }
    return _with_listing(card, "model", item.public_id)


def _talent_model_discovery_detail(item: TalentProfile) -> dict[str, Any]:
    card = _talent_model_discovery_item(item)
    card["sections"] = [
        _detail_section(
            "Model availability",
            ("Screen name", item.screen_name),
            ("Display name", item.user.display_name),
            ("Availability", item.availability_status),
            (
                "Available as",
                ", ".join(_talent_availability_categories(item)),
            ),
        )
    ]
    return card


def _influencer_discovery_detail(item: TalentProfile) -> dict[str, Any]:
    profile = _profile_for_user(item.user_id)
    card = _influencer_discovery_item(item)
    card["sections"] = [
        _detail_section(
            "Influencer profile",
            ("Creator name", item.screen_name),
            ("Display name", item.user.display_name),
            ("Availability", item.availability_status),
            (
                "Available as",
                ", ".join(_talent_availability_categories(item)),
            ),
        ),
        _detail_section(
            "Campaign profile",
            ("Bio", profile.bio if profile else None),
            ("Website", profile.website_url if profile else None),
            ("Reviews", profile.review_count if profile else 0),
        ),
    ]
    return card


def _actor_discovery_detail(item: TalentProfile) -> dict[str, Any]:
    profile = _profile_for_user(item.user_id)
    card = _actor_discovery_item(item)
    card["sections"] = [
        _detail_section(
            "Actor profile",
            ("Screen name", item.screen_name),
            ("Display name", item.user.display_name),
            ("Age range", item.age_range),
            ("Gender identity", item.gender_identity),
            ("Height", f"{item.height_cm} cm" if item.height_cm else None),
            (
                "Experience",
                f"{item.experience_years} years" if item.experience_years else None,
            ),
            ("Availability", item.availability_status),
            ("Union note", item.union_note),
        ),
        {
            "title": "Languages",
            "rows": [
                _detail_row(row.language, row.proficiency) for row in item.languages
            ],
        },
        _detail_section(
            "Public profile",
            ("Bio", profile.bio if profile else None),
            ("Website", profile.website_url if profile else None),
            ("Reviews", profile.review_count if profile else 0),
        ),
    ]
    return card


def _model_rate(item: ModelProfile) -> tuple[int | None, str]:
    rates = [row for row in item.usage_rates if row.amount_minor is not None]
    if rates:
        rate = sorted(rates, key=lambda row: row.amount_minor)[0]
        return rate.amount_minor, rate.currency
    return item.talent_profile.day_rate_minor, item.talent_profile.currency


def _model_discovery_item(item: ModelProfile) -> dict[str, Any]:
    profile = _profile_for_user(item.user_id)
    rate_minor, currency = _model_rate(item)
    categories = [
        row.category
        for row in item.campaign_categories
        if row.selected and row.public_visible
    ]
    card = {
        "public_id": item.public_id,
        "kind": "model",
        "category": "Models",
        "title": item.talent_profile.screen_name,
        "subtitle": "Model profile",
        "summary": item.brand_safety_notes
        or (profile.bio if profile else None)
        or "Model / brand campaign profile.",
        "city": _city_payload(profile.city) if profile else None,
        "owner": _owner_payload(item.user),
        "rate_from_minor": rate_minor,
        "currency": currency,
        "rate_label": _minor_money_label(rate_minor, currency),
        "verification_status": "approved" if item.public_visibility else "private",
        "rating_average": int(profile.rating_average) if profile else 0,
        "available": item.public_visibility,
        "tags": categories or _talent_tags(item.talent_profile),
        "media": _portfolio_media_payload("model", item.public_id),
        "resume_file": _file_payload(item.talent_profile.resume_file),
        "route": "/director/discovery/model",
        "source": {"table": "model_profiles"},
    }
    return _with_listing(card, "model", item.public_id)


def _model_discovery_detail(item: ModelProfile) -> dict[str, Any]:
    card = _model_discovery_item(item)
    card["sections"] = [
        _detail_section(
            "Model profile",
            ("Screen name", item.talent_profile.screen_name),
            ("Public visibility", item.public_visibility),
            ("Brand safety notes", item.brand_safety_notes),
        ),
        {
            "title": "Campaign categories",
            "rows": [
                _detail_row(
                    row.category,
                    "Visible" if row.public_visible and row.selected else "Hidden",
                )
                for row in item.campaign_categories
            ],
        },
        {
            "title": "Usage rates",
            "rows": [
                _detail_row(
                    row.label,
                    " · ".join(
                        [
                            _minor_money_label(row.amount_minor, row.currency),
                            row.scope or "",
                            "Negotiable" if row.negotiable else "Fixed",
                            "Review required" if row.requires_review else "",
                        ]
                    ).strip(" ·"),
                )
                for row in item.usage_rates
            ],
        },
        {
            "title": "Usage rights",
            "rows": [
                _detail_row(
                    row.platform,
                    " · ".join(
                        [
                            row.territory,
                            f"{row.duration_months} months"
                            if row.duration_months
                            else "",
                            "Exclusive" if row.exclusive else "Non-exclusive",
                            row.status,
                        ]
                    ).strip(" ·"),
                )
                for row in item.usage_rights
            ],
        },
        {
            "title": "Restricted categories",
            "rows": [
                _detail_row(
                    row.category,
                    ("Blocked" if row.blocked else "Allowed")
                    + (f" · {row.reason}" if row.reason else ""),
                )
                for row in item.restricted_categories
            ],
        },
    ]
    return card


def _location_rate(property_id: Any) -> tuple[int | None, str]:
    rows = list(
        db.session.execute(
            select(LocationPricing)
            .where(LocationPricing.property_id == property_id, LocationPricing.enabled)
            .order_by(LocationPricing.amount_minor.asc())
            .limit(20)
        ).scalars()
    )
    if not rows:
        return None, "PKR"
    return rows[0].amount_minor, rows[0].currency


def _location_discovery_item(item: LocationProperty) -> dict[str, Any]:
    rate_minor, currency = _location_rate(item.id)
    tags = [
        item.property_type,
        *(["Power backup"] if item.power_backup else []),
        *(["Accessible"] if item.accessible else []),
        *([f"{item.capacity} capacity"] if item.capacity else []),
    ]
    card = {
        "public_id": item.public_id,
        "kind": "location",
        "category": "Locations",
        "title": item.name,
        "subtitle": item.area_name or item.property_type,
        "summary": item.description or item.public_address or "Published location.",
        "city": _city_payload(item.city),
        "owner": _owner_payload(item.owner),
        "rate_from_minor": rate_minor,
        "currency": currency,
        "rate_label": _minor_money_label(rate_minor, currency),
        "verification_status": item.status,
        "rating_average": item.rating_average,
        "available": item.status in {"published", "active", "available"},
        "tags": [tag for tag in tags if tag],
        # Falls back to the owner's general portfolio gallery; _with_listing
        # below overrides with this specific property's published photos
        # when that property has its own listing media.
        "media": _portfolio_media_payload("location", item.owner.public_id),
        "route": "/director/discovery/location",
        "source": {"table": "location_properties"},
    }
    return _with_listing(card, "location", item.public_id)


def _location_discovery_detail(item: LocationProperty) -> dict[str, Any]:
    pricing = list(
        db.session.execute(
            select(LocationPricing)
            .where(LocationPricing.property_id == item.id)
            .order_by(LocationPricing.amount_minor.asc())
        ).scalars()
    )
    rules = list(
        db.session.execute(
            select(LocationRule)
            .where(LocationRule.property_id == item.id)
            .order_by(LocationRule.rule_type.asc(), LocationRule.label.asc())
        ).scalars()
    )
    card = _location_discovery_item(item)
    card["sections"] = [
        _detail_section(
            "Location profile",
            ("Property type", item.property_type),
            ("Public area", item.area_name),
            ("Public address", item.public_address),
            ("Capacity", item.capacity),
            ("Parking spaces", item.parking_spaces),
            ("Power backup", item.power_backup),
            ("Accessible", item.accessible),
        ),
        {
            "title": "Spaces",
            "rows": [
                _detail_row(
                    row.name,
                    " · ".join(
                        [
                            row.space_type,
                            f"{row.capacity} capacity" if row.capacity else "",
                            f"{row.area_sqft} sqft" if row.area_sqft else "",
                            row.description or "",
                        ]
                    ).strip(" ·"),
                )
                for row in item.spaces
            ],
        },
        {
            "title": "Pricing",
            "rows": [
                _detail_row(
                    row.label,
                    f"{_minor_money_label(row.amount_minor, row.currency)} / {row.unit}"
                    + (f" · {row.conditions}" if row.conditions else ""),
                )
                for row in pricing
            ],
        },
        {
            "title": "Rules",
            "rows": [
                _detail_row(
                    row.label,
                    ("Allowed" if row.allowed else "Not allowed")
                    + (f" · {row.note}" if row.note else ""),
                )
                for row in rules
            ],
        },
    ]
    return card


def _equipment_rate(provider_id: Any) -> tuple[int | None, str]:
    rows = list(
        db.session.execute(
            select(EquipmentItem)
            .where(
                EquipmentItem.provider_profile_id == provider_id,
                EquipmentItem.status.in_(["available", "published", "active"]),
            )
            .order_by(EquipmentItem.day_rate_minor.asc())
            .limit(40)
        ).scalars()
    )
    for row in rows:
        if row.day_rate_minor is not None:
            return row.day_rate_minor, row.currency
    return None, "PKR"


def _equipment_discovery_item(item: EquipmentProviderProfile) -> dict[str, Any]:
    rate_minor, currency = _equipment_rate(item.id)
    card = {
        "public_id": item.public_id,
        "kind": "equipment",
        "category": "Media & Equipment",
        "title": item.name,
        "subtitle": item.provider_type.replace("_", " ").title(),
        "summary": item.bio or item.coverage or "Equipment provider.",
        "city": _city_payload(item.city),
        "owner": _owner_payload(item.user),
        "rate_from_minor": rate_minor,
        "currency": currency,
        "rate_label": _minor_money_label(rate_minor, currency),
        "verification_status": item.verification_status,
        "rating_average": item.rating_average,
        "available": item.verification_status in {"approved", "verified", "active"},
        "tags": _split_tags(item.service_categories) or _split_tags(item.coverage),
        "media": _portfolio_media_payload("equipment", item.public_id),
        "route": "/director/discovery/equipment",
        "source": {"table": "equipment_provider_profiles"},
    }
    return _with_listing(card, "equipment", item.public_id)


def _equipment_discovery_detail(item: EquipmentProviderProfile) -> dict[str, Any]:
    inventory = list(
        db.session.execute(
            select(EquipmentItem)
            .where(EquipmentItem.provider_profile_id == item.id)
            .order_by(EquipmentItem.category.asc(), EquipmentItem.model_name.asc())
            .limit(50)
        ).scalars()
    )
    packages = list(
        db.session.execute(
            select(EquipmentPackage)
            .where(EquipmentPackage.provider_profile_id == item.id)
            .order_by(EquipmentPackage.updated_at.desc())
            .limit(20)
        ).scalars()
    )
    terms = list(
        db.session.execute(
            select(EquipmentTerm)
            .where(EquipmentTerm.provider_profile_id == item.id, EquipmentTerm.enabled)
            .order_by(EquipmentTerm.term_type.asc(), EquipmentTerm.label.asc())
            .limit(30)
        ).scalars()
    )
    card = _equipment_discovery_item(item)
    card["sections"] = [
        _detail_section(
            "Provider profile",
            ("Provider type", item.provider_type.replace("_", " ").title()),
            ("Coverage", item.coverage),
            ("Service categories", item.service_categories),
            ("Verification", item.verification_status),
        ),
        {
            "title": "Inventory",
            "rows": [
                _detail_row(
                    row.model_name,
                    " · ".join(
                        [
                            row.category,
                            row.brand or "",
                            row.condition,
                            _minor_money_label(row.day_rate_minor, row.currency),
                            row.status,
                        ]
                    ).strip(" ·"),
                )
                for row in inventory
            ],
        },
        {
            "title": "Packages",
            "rows": [
                _detail_row(
                    row.name,
                    " · ".join(
                        [
                            _minor_money_label(row.price_minor, row.currency),
                            "Operator included" if row.operator_included else "",
                            row.status,
                            row.description or "",
                        ]
                    ).strip(" ·"),
                )
                for row in packages
            ],
        },
        {
            "title": "Terms",
            "rows": [
                _detail_row(
                    row.label,
                    " · ".join(
                        [
                            row.term_type,
                            _minor_money_label(row.amount_minor, row.currency)
                            if row.amount_minor is not None
                            else "",
                            row.note or "",
                        ]
                    ).strip(" ·"),
                )
                for row in terms
            ],
        },
    ]
    return card


def _agency_discovery_item(item: CastingAgency) -> dict[str, Any]:
    roster_count = (
        db.session.execute(
            select(AgencyTalent).where(
                AgencyTalent.agency_id == item.id,
                AgencyTalent.status == "active",
            )
        )
        .scalars()
        .all()
    )
    card = {
        "public_id": item.public_id,
        "kind": "agency",
        "category": "Agencies",
        "title": item.name,
        "subtitle": f"{len(roster_count)} represented talent",
        "summary": "Casting agency roster and audition desk.",
        "city": _city_payload(item.city),
        "owner": _owner_payload(item.owner),
        "rate_from_minor": None,
        "currency": "PKR",
        "rate_label": f"{item.commission_bps / 100:.0f}% commission",
        "verification_status": item.verification_status,
        "rating_average": 0,
        "available": item.verification_status in {"approved", "verified", "active"},
        "tags": ["Casting", "Auditions", "Roster"],
        "media": [],
        "route": "/director/discovery/agency",
        "source": {"table": "casting_agencies"},
    }
    return _with_listing(card, "agency", item.public_id)


def _agency_discovery_detail(item: CastingAgency) -> dict[str, Any]:
    roster = list(
        db.session.execute(
            select(AgencyTalent)
            .where(AgencyTalent.agency_id == item.id)
            .order_by(AgencyTalent.status.asc(), AgencyTalent.created_at.desc())
            .limit(60)
        ).scalars()
    )
    card = _agency_discovery_item(item)
    card["sections"] = [
        _detail_section(
            "Agency profile",
            ("Commission", f"{item.commission_bps / 100:.0f}%"),
            ("Verification", item.verification_status),
            ("Owner", item.owner.display_name if item.owner else None),
        ),
        {
            "title": "Represented talent",
            "rows": [
                _detail_row(
                    row.talent_profile.screen_name,
                    " · ".join(
                        [
                            row.representation_type.replace("_", " ").title(),
                            row.status,
                            f"{row.commission_bps / 100:.0f}% commission",
                        ]
                    ),
                )
                for row in roster
            ],
        },
    ]
    return card


def _distribution_discovery_item(item: DistributionPartnerProfile) -> dict[str, Any]:
    card = {
        "public_id": item.public_id,
        "kind": "distribution",
        "category": "Distribution",
        "title": item.name,
        "subtitle": item.channels or "Distribution partner",
        "summary": item.territories or "Release and distribution partner.",
        "city": None,
        "owner": _owner_payload(item.user),
        "rate_from_minor": None,
        "currency": "PKR",
        "rate_label": "Terms on request",
        "verification_status": item.status,
        "rating_average": 0,
        "available": item.status in {"approved", "active", "verified"},
        "tags": [*_split_tags(item.channels), *_split_tags(item.territories)],
        "media": [],
        "route": "/director/discovery/distribution",
        "source": {"table": "distribution_partner_profiles"},
    }
    return _with_listing(card, "distribution", item.public_id)


def _distribution_discovery_detail(item: DistributionPartnerProfile) -> dict[str, Any]:
    card = _distribution_discovery_item(item)
    card["sections"] = [
        _detail_section(
            "Distribution profile",
            ("Channels", item.channels),
            ("Territories", item.territories),
            ("Status", item.status),
            ("Owner", item.user.display_name if item.user else None),
        )
    ]
    return card


_DIRECTOR_DISCOVERY_KIND_ALIASES = {
    "all": {
        "actor",
        "model",
        "influencer",
        "location",
        "equipment",
        "agency",
        "distribution",
    },
    "actors": {"actor"},
    "actor": {"actor"},
    "talent": {"actor"},
    "models": {"model"},
    "model": {"model"},
    "influencers": {"influencer"},
    "influencer": {"influencer"},
    "creators": {"influencer"},
    "creator": {"influencer"},
    "locations": {"location"},
    "location": {"location"},
    "media": {"equipment"},
    "media_equipment": {"equipment"},
    "media & equipment": {"equipment"},
    "equipment": {"equipment"},
    "agencies": {"agency"},
    "agency": {"agency"},
    "distribution": {"distribution"},
    "crew": set(),
}


def _director_discovery_items(
    *,
    category: str | None,
    query: str | None,
) -> list[dict[str, Any]]:
    category_key = (category or "all").strip().lower().replace("-", "_")
    kinds = _DIRECTOR_DISCOVERY_KIND_ALIASES.get(
        category_key,
        {
            "actor",
            "model",
            "influencer",
            "location",
            "equipment",
            "agency",
            "distribution",
        },
    )
    items: list[dict[str, Any]] = []

    if "actor" in kinds:
        actor_query = (
            select(TalentProfile)
            .join(UserRole, UserRole.user_id == TalentProfile.user_id)
            .where(
                UserRole.status == "active",
                UserRole.role.has(code="actor_talent"),
            )
            .order_by(TalentProfile.updated_at.desc())
            .limit(120)
        )
        actors = db.session.execute(actor_query).scalars()
        items.extend(
            _actor_discovery_item(row)
            for row in actors
            if "actor" in _talent_availability_categories(row)
        )
    if "model" in kinds:
        models = db.session.execute(
            select(ModelProfile)
            .where(ModelProfile.public_visibility.is_(True))
            .order_by(ModelProfile.updated_at.desc())
            .limit(120)
        ).scalars()
        model_rows = list(models)
        items.extend(_model_discovery_item(row) for row in model_rows)
        model_talent_ids = {row.talent_profile_id for row in model_rows}
        talent_models = db.session.execute(
            select(TalentProfile).order_by(TalentProfile.updated_at.desc()).limit(120)
        ).scalars()
        items.extend(
            _talent_model_discovery_item(row)
            for row in talent_models
            if row.id not in model_talent_ids
            and "model" in _talent_availability_categories(row)
        )
    if "influencer" in kinds:
        influencer_query = (
            select(TalentProfile)
            .order_by(TalentProfile.updated_at.desc())
            .limit(120)
        )
        influencers = db.session.execute(influencer_query).scalars()
        items.extend(
            _influencer_discovery_item(row)
            for row in influencers
            if "influencer" in _talent_availability_categories(row)
        )
    if "location" in kinds:
        locations = db.session.execute(
            select(LocationProperty)
            .where(LocationProperty.status.in_(["published", "active", "available"]))
            .order_by(LocationProperty.updated_at.desc())
            .limit(80)
        ).scalars()
        items.extend(_location_discovery_item(row) for row in locations)
    if "equipment" in kinds:
        equipment = db.session.execute(
            select(EquipmentProviderProfile)
            .order_by(EquipmentProviderProfile.updated_at.desc())
            .limit(80)
        ).scalars()
        items.extend(_equipment_discovery_item(row) for row in equipment)
    if "agency" in kinds:
        agencies = db.session.execute(
            select(CastingAgency).order_by(CastingAgency.updated_at.desc()).limit(80)
        ).scalars()
        items.extend(_agency_discovery_item(row) for row in agencies)
    if "distribution" in kinds:
        partners = db.session.execute(
            select(DistributionPartnerProfile)
            .order_by(DistributionPartnerProfile.updated_at.desc())
            .limit(80)
        ).scalars()
        items.extend(_distribution_discovery_item(row) for row in partners)

    return [row for row in items if _matches_discovery_query(row, query)][:120]


def _director_discovery_facets(items: list[dict[str, Any]]) -> dict[str, Any]:
    by_kind: dict[str, int] = {}
    by_city: dict[str, int] = {}
    for item in items:
        by_kind[item["kind"]] = by_kind.get(item["kind"], 0) + 1
        city = item.get("city") or {}
        city_name = city.get("name")
        if city_name:
            by_city[city_name] = by_city.get(city_name, 0) + 1
    return {
        "kind_counts": by_kind,
        "city_counts": by_city,
        "unsupported_categories": {
            "Crew": (
                "Crew currently uses talent/project requirement records until "
                "a dedicated crew-provider schema is added."
            ),
        },
    }


def _director_discovery_detail(kind: str, public_id: str) -> dict[str, Any]:
    kind_key = kind.strip().lower().replace("-", "_")
    if kind_key == "location":
        row = db.session.execute(
            select(LocationProperty).where(LocationProperty.public_id == public_id)
        ).scalar_one_or_none()
        if row:
            return _location_discovery_detail(row)
    elif kind_key == "actor":
        row = db.session.execute(
            select(TalentProfile).where(TalentProfile.public_id == public_id)
        ).scalar_one_or_none()
        if row:
            return _actor_discovery_detail(row)
    elif kind_key == "model":
        row = db.session.execute(
            select(ModelProfile).where(ModelProfile.public_id == public_id)
        ).scalar_one_or_none()
        if row:
            return _model_discovery_detail(row)
        talent_row = db.session.execute(
            select(TalentProfile).where(TalentProfile.public_id == public_id)
        ).scalar_one_or_none()
        if talent_row and "model" in _talent_availability_categories(talent_row):
            return _talent_model_discovery_detail(talent_row)
    elif kind_key == "influencer":
        row = db.session.execute(
            select(TalentProfile).where(TalentProfile.public_id == public_id)
        ).scalar_one_or_none()
        if row:
            return _influencer_discovery_detail(row)
    elif kind_key == "equipment":
        row = db.session.execute(
            select(EquipmentProviderProfile).where(
                EquipmentProviderProfile.public_id == public_id
            )
        ).scalar_one_or_none()
        if row:
            return _equipment_discovery_detail(row)
    elif kind_key == "agency":
        row = db.session.execute(
            select(CastingAgency).where(CastingAgency.public_id == public_id)
        ).scalar_one_or_none()
        if row:
            return _agency_discovery_detail(row)
    elif kind_key == "distribution":
        row = db.session.execute(
            select(DistributionPartnerProfile).where(
                DistributionPartnerProfile.public_id == public_id
            )
        ).scalar_one_or_none()
        if row:
            return _distribution_discovery_detail(row)
    raise APIError(
        "director.discovery_not_found",
        "Director discovery item was not found.",
        status=404,
    )


def _project_lookup(projects: list[Project]) -> dict[str, Project]:
    return {project.public_id: project for project in projects}


def _schedule_event(
    *,
    kind: str,
    public_id: str,
    project: Project,
    title: str,
    starts_at: datetime | None,
    ends_at: datetime | None = None,
    status: str = "scheduled",
    subtitle: str | None = None,
    location: str | None = None,
    stakeholders: list[str] | None = None,
    route: str | None = None,
    argument: str | None = None,
    risk_level: str = "low",
) -> dict[str, Any]:
    return {
        "kind": kind,
        "public_id": public_id,
        "project_id": project.public_id,
        "project_title": project.title,
        "title": title,
        "subtitle": subtitle,
        "location": location or (project.city.name if project.city else "Pakistan"),
        "stakeholders": stakeholders or [],
        "starts_at": starts_at.isoformat() if starts_at else None,
        "ends_at": ends_at.isoformat() if ends_at else None,
        "status": status,
        "risk_level": risk_level,
        "route": route,
        "argument": argument,
    }


def _date_start(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    return datetime.combine(value, time(hour=9))


def _date_end(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    return datetime.combine(value, time(hour=18))


def _director_schedule_payload(
    user: User,
    *,
    project_id: str | None = None,
) -> dict[str, Any]:
    all_projects = _visible_projects(user)
    project_by_public_id = _project_lookup(all_projects)
    projects = (
        [project_by_public_id[project_id]]
        if project_id and project_id in project_by_public_id
        else all_projects
    )
    visible_ids = {project.id for project in projects}
    events: list[dict[str, Any]] = []
    risks: list[dict[str, Any]] = []

    for project in projects:
        if project.start_date:
            events.append(
                _schedule_event(
                    kind="project_start",
                    public_id=f"{project.public_id}-START",
                    project=project,
                    title="Project start",
                    starts_at=_date_start(project.start_date),
                    status=project.status,
                    subtitle=project.project_type,
                    route="/director/projects/:id",
                    argument=project.public_id,
                )
            )
        if project.end_date:
            events.append(
                _schedule_event(
                    kind="project_wrap",
                    public_id=f"{project.public_id}-WRAP",
                    project=project,
                    title="Project wrap",
                    starts_at=_date_end(project.end_date),
                    status=project.status,
                    subtitle=project.project_type,
                    route="/director/projects/:id",
                    argument=project.public_id,
                )
            )
        if not project.start_date or not project.end_date:
            risks.append(
                {
                    "kind": "project_dates",
                    "project_id": project.public_id,
                    "project_title": project.title,
                    "title": "Project dates incomplete",
                    "message": "Add start and wrap dates before issuing call sheets.",
                    "risk_level": "medium",
                    "route": "/director/projects/:id",
                    "argument": project.public_id,
                }
            )

    booking_query = select(Booking)
    if visible_ids:
        booking_query = booking_query.where(Booking.project_id.in_(visible_ids))
    if not _has_role(user, "super_admin"):
        booking_query = booking_query.where(Booking.requester_user_id == user.id)
    bookings = list(
        db.session.execute(
            booking_query.order_by(Booking.start_at.asc()).limit(100)
        ).scalars()
    )
    for booking in bookings:
        if booking.status in {"cancelled", "rejected"}:
            continue
        events.append(
            _schedule_event(
                kind="booking",
                public_id=booking.public_id,
                project=booking.project,
                title=(
                    booking.requirement.title
                    if booking.requirement
                    else booking.category
                ),
                subtitle=booking.provider.display_name,
                location=(
                    booking.project.city.name if booking.project.city else "Pakistan"
                ),
                stakeholders=[booking.provider.display_name],
                starts_at=booking.start_at,
                ends_at=booking.end_at,
                status=booking.status,
                risk_level=(
                    "medium"
                    if booking.status in {"sent", "under_negotiation"}
                    else "low"
                ),
                route="/booking",
                argument=booking.public_id,
            )
        )

    contracts = _contract_rows(user)
    for contract in contracts:
        if contract.project_id not in visible_ids:
            continue
        if contract.status != "signed":
            risks.append(
                {
                    "kind": "contract_signature",
                    "project_id": contract.project.public_id,
                    "project_title": contract.project.title,
                    "title": "Contract signature pending",
                    "message": (
                        f"{contract.title} is {contract.status.replace('_', ' ')}."
                    ),
                    "risk_level": "medium",
                    "route": "/contract",
                    "argument": contract.public_id,
                }
            )
        events.append(
            _schedule_event(
                kind="contract",
                public_id=contract.public_id,
                project=contract.project,
                title=contract.title,
                subtitle=contract.status.replace("_", " "),
                starts_at=contract.updated_at,
                status=contract.status,
                stakeholders=[party.user.display_name for party in contract.parties],
                route="/contract",
                argument=contract.public_id,
                risk_level="low" if contract.status == "signed" else "medium",
            )
        )

    payments = _payment_rows(user)
    now = utc_now()
    for milestone in payments:
        project = milestone.schedule.booking.project
        if project.id not in visible_ids:
            continue
        due_at = milestone.due_at
        is_overdue = (
            due_at is not None
            and as_utc(due_at) < now
            and milestone.status not in {"paid", "verified"}
        )
        if is_overdue:
            risks.append(
                {
                    "kind": "payment_overdue",
                    "project_id": project.public_id,
                    "project_title": project.title,
                    "title": "Payment milestone overdue",
                    "message": f"{milestone.name} is still {milestone.status}.",
                    "risk_level": "high",
                    "route": "/director/payments",
                    "argument": milestone.public_id,
                }
            )
        events.append(
            _schedule_event(
                kind="payment",
                public_id=milestone.public_id,
                project=project,
                title=milestone.name,
                subtitle=(
                    f"{milestone.schedule.currency} {milestone.amount_minor // 100}"
                ),
                starts_at=due_at,
                status=milestone.status,
                stakeholders=[milestone.schedule.booking.provider.display_name],
                route="/payments/proof",
                argument=milestone.public_id,
                risk_level="high" if is_overdue else "low",
            )
        )

    room_items = _room_items(projects)
    for item in room_items:
        events.append(
            _schedule_event(
                kind="room_item",
                public_id=item["public_id"],
                project=project_by_public_id[item["project_id"]],
                title=item["title"],
                subtitle=item["item_type"],
                starts_at=datetime.fromisoformat(item["created_at"]),
                status="pinned" if item["item_type"] == "decision" else "logged",
                route=item["route"],
                argument=item["argument"],
            )
        )

    events.sort(key=lambda row: row["starts_at"] or "9999-12-31T00:00:00")
    future_events = [
        row
        for row in events
        if row["starts_at"] and as_utc(datetime.fromisoformat(row["starts_at"])) >= now
    ]
    call_sheet_event = (
        future_events[0] if future_events else (events[0] if events else None)
    )
    call_sheet = {
        "status": "ready" if call_sheet_event else "empty",
        "label": "Next live call sheet" if call_sheet_event else "No live events",
        "event": call_sheet_event,
        "crew": call_sheet_event["stakeholders"] if call_sheet_event else [],
        "weather": {
            "status": "provider_not_configured",
            "summary": "Weather provider not connected yet.",
        },
    }
    return {
        "events": events[:120],
        "risks": risks[:30],
        "call_sheet": call_sheet,
    }


def _contract_rows(user: User) -> list[Contract]:
    query = select(Contract).join(Booking, Booking.id == Contract.booking_id)
    if not _has_role(user, "super_admin"):
        query = query.where(Booking.requester_user_id == user.id)
    return list(
        db.session.execute(
            query.order_by(Contract.updated_at.desc()).limit(50)
        ).scalars()
    )


def _pipeline_rows(user: User, bookings: list[Booking]) -> list[dict[str, Any]]:
    contracts = _contract_rows(user)
    contract_items = [
        {
            "kind": "contract",
            "public_id": contract.public_id,
            "booking_id": contract.booking.public_id,
            "project_id": contract.project.public_id,
            "project_title": contract.project.title,
            "counterparty": contract.booking.provider.display_name,
            "title": contract.title,
            "status": contract.status,
            "value_minor": contract.value_minor,
            "currency": contract.currency,
            "route": "/contract",
            "argument": contract.public_id,
        }
        for contract in contracts
    ]
    booking_items = [
        {
            "kind": "booking",
            "public_id": booking.public_id,
            "booking_id": booking.public_id,
            "project_id": booking.project.public_id,
            "project_title": booking.project.title,
            "counterparty": booking.provider.display_name,
            "title": (
                booking.requirement.title if booking.requirement else booking.category
            ),
            "status": booking.status,
            "value_minor": booking.agreed_amount_minor,
            "currency": booking.currency,
            "route": "/booking",
            "argument": booking.public_id,
        }
        for booking in bookings
        if booking.status in {"sent", "under_negotiation", "accepted", "secured"}
    ]
    return [*contract_items, *booking_items][:8]


def _room_items(projects: list[Project]) -> list[dict[str, Any]]:
    project_ids = [project.id for project in projects]
    if not project_ids:
        return []
    rows = db.session.execute(
        select(ProjectRoomItem)
        .where(ProjectRoomItem.project_id.in_(project_ids))
        .order_by(ProjectRoomItem.created_at.desc())
        .limit(6)
    ).scalars()
    return [
        {
            "public_id": item.public_id,
            "project_id": item.project.public_id,
            "project_title": item.project.title,
            "item_type": item.item_type,
            "title": item.title,
            "body": item.body,
            "created_at": item.created_at.isoformat(),
            "route": "/director/room",
            "argument": item.project.public_id,
        }
        for item in rows
    ]


def _priority_actions(
    projects: list[Project],
    bookings: list[Booking],
    payments: list[PaymentMilestone],
    contracts: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    due_payments = [row for row in payments if row.status not in {"verified", "paid"}]
    if due_payments:
        first = due_payments[0]
        actions.append(
            {
                "tone": "warning",
                "urgency": "payment",
                "title": f"{first.name} needs payment action",
                "subtitle": first.schedule.booking.project.title,
                "route": "/director/payments",
                "argument": first.public_id,
            }
        )
    pending_contracts = [
        item
        for item in contracts
        if item["kind"] == "contract" and "pending" in item["status"]
    ]
    if pending_contracts:
        first_contract = pending_contracts[0]
        actions.append(
            {
                "tone": "info",
                "urgency": "contract",
                "title": f"{first_contract['title']} is awaiting signatures",
                "subtitle": first_contract["project_title"],
                "route": "/director/contracts",
                "argument": first_contract["public_id"],
            }
        )
    active_bookings = [
        row for row in bookings if row.status in {"sent", "under_negotiation"}
    ]
    if active_bookings:
        first_booking = active_bookings[0]
        actions.append(
            {
                "tone": "success",
                "urgency": "booking",
                "title": f"Follow up with {first_booking.provider.display_name}",
                "subtitle": first_booking.project.title,
                "route": "/director/bargaining",
                "argument": first_booking.public_id,
            }
        )
    draft_projects = [row for row in projects if row.status in {"draft", "preprod"}]
    if draft_projects:
        first_project = draft_projects[0]
        actions.append(
            {
                "tone": "neutral",
                "urgency": "project",
                "title": f"Complete setup for {first_project.title}",
                "subtitle": "Add requirements, files, and shortlist picks",
                "route": "/director/projects/:id",
                "argument": first_project.public_id,
            }
        )
    return actions[:5]


@director_blueprint.get("/director/dashboard")
def director_dashboard() -> Response:
    user = _current_user()
    _require_director_dashboard(user)
    projects = _visible_projects(user)
    bookings = _requester_bookings(user)
    payments = _payment_rows(user)
    pipeline = _pipeline_rows(user, bookings)
    active_project_count = sum(
        1 for project in projects if project.status not in {"completed", "archived"}
    )
    committed_minor = sum(
        booking.agreed_amount_minor or 0
        for booking in bookings
        if booking.status in {"accepted", "secured"}
    )
    paid_minor = sum(
        milestone.amount_minor
        for milestone in payments
        if milestone.status in {"paid", "verified"}
    )
    pending_minor = sum(
        milestone.amount_minor
        for milestone in payments
        if milestone.status not in {"paid", "verified"}
    )
    upcoming = [
        booking
        for booking in bookings
        if as_utc(booking.end_at) >= utc_now()
        and booking.status not in {"cancelled", "rejected"}
    ][:5]
    priority = _priority_actions(projects, bookings, payments, pipeline)
    payload = {
        "summary": {
            "active_projects": active_project_count,
            "project_count": len(projects),
            "committed_budget_minor": committed_minor,
            "paid_minor": paid_minor,
            "pending_payment_minor": pending_minor,
            "secured_bookings": sum(1 for row in bookings if row.status == "secured"),
            "attention_count": len(priority),
            "currency": "PKR",
        },
        "projects": [_project_payload(project) for project in projects[:6]],
        "timeline": [_booking_timeline_payload(row, user) for row in upcoming],
        "payments_attention": [
            _payment_payload(row)
            for row in payments
            if row.status not in {"paid", "verified"}
        ][:5],
        "pipeline": pipeline,
        "activity": _room_items(projects),
        "priority_actions": priority,
    }
    return jsonify(success({"dashboard": payload}))


@director_blueprint.get("/director/schedule")
def director_schedule() -> Response:
    user = _current_user()
    _require_director_dashboard(user)
    project_id = request.args.get("project_id")
    payload = _director_schedule_payload(user, project_id=project_id)
    return jsonify(success({"schedule": payload}))


@director_blueprint.get("/director/discovery")
def director_discovery() -> Response:
    user = _current_user()
    _require_director_dashboard(user)
    items = _director_discovery_items(
        category=request.args.get("category"),
        query=request.args.get("q"),
    )
    return jsonify(
        success(
            {
                "discovery": {
                    "items": items,
                    "facets": _director_discovery_facets(items),
                }
            }
        )
    )


@director_blueprint.get("/director/discovery/<kind>/<public_id>")
def director_discovery_item(kind: str, public_id: str) -> Response:
    user = _current_user()
    _require_director_dashboard(user)
    item = _director_discovery_detail(kind, public_id)
    return jsonify(success({"item": item}))
