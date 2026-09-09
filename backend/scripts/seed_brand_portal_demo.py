from __future__ import annotations

# Imports from `app` intentionally follow the local backend path bootstrap.

import json
import hashlib
import os
import shutil
import sys
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal
from pathlib import Path
from typing import Any

from sqlalchemy import select

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import create_app
from app.extensions import db
from app.models import (
    Booking,
    BookingParticipant,
    BookingStatusEvent,
    City,
    Conversation,
    ConversationMember,
    FileAsset,
    ListingMedia,
    MarketplaceListing,
    Message,
    Notification,
    Project,
    ProjectMember,
    ProjectRequirement,
    KycSubmission,
    Role,
    Shortlist,
    ShortlistItem,
    TalentProfile,
    User,
    UserProfile,
)
from app.models.base import utc_now


DEMO_DOMAIN = os.getenv(
    "CINECONNECT_DEMO_EMAIL_DOMAIN",
    "demo.cine.nalexustechnologies.com",
)

DEMO_ASSET_ROOT = ROOT / "demo_assets" / "brand_portal"


def install_public_portrait(
    stats: dict[str, int],
    *,
    public_id: str,
    owner: User,
    filename: str,
) -> FileAsset:
    source = DEMO_ASSET_ROOT / filename
    if not source.is_file():
        raise RuntimeError(f"Missing Brand demo portrait: {source}")
    storage_key = f"demo/brand-portal/profile-heroes/{filename}"
    public_root = Path(
        os.getenv("LOCAL_STORAGE_PUBLIC_ROOT", "/data/storage/public")
    ).expanduser()
    destination = public_root / storage_key
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    payload = source.read_bytes()
    file = ensure(
        FileAsset,
        stats,
        "portrait_file",
        public_id=public_id,
        defaults={
            "owner_user_id": owner.id,
            "storage_key": storage_key,
            "bucket": os.getenv("OBJECT_STORAGE_BUCKET_PUBLIC", "cineconnect-public"),
            "mime_type": "image/png",
            "size_bytes": len(payload),
            "checksum_sha256": hashlib.sha256(payload).hexdigest(),
            "visibility": "public",
            "scan_status": "clean",
            "processing_status": "ready",
            "original_name": filename,
        },
    )
    file.owner_user_id = owner.id
    file.storage_key = storage_key
    file.mime_type = "image/png"
    file.size_bytes = len(payload)
    file.checksum_sha256 = hashlib.sha256(payload).hexdigest()
    file.visibility = "public"
    file.scan_status = "clean"
    file.processing_status = "ready"
    file.original_name = filename
    return file


def attach_listing_portrait(
    stats: dict[str, int],
    *,
    listing: MarketplaceListing,
    file: FileAsset,
    caption: str,
) -> None:
    for row in listing.media:
        row.is_cover = False
    media = ensure(
        ListingMedia,
        stats,
        "portrait_listing_media",
        listing_id=listing.id,
        file_id=file.id,
        defaults={"sort_order": -10, "is_cover": True, "caption": caption},
    )
    media.sort_order = -10
    media.is_cover = True
    media.caption = caption


def one(model: type[Any], **where: Any) -> Any | None:
    return db.session.execute(select(model).filter_by(**where)).scalar_one_or_none()


def required(model: type[Any], **where: Any) -> Any:
    row = one(model, **where)
    if row is None:
        raise RuntimeError(
            f"Missing {model.__name__} {where}. Run demo seed slices 1-3 first."
        )
    return row


def ensure(
    model: type[Any],
    stats: dict[str, int],
    key: str,
    *,
    defaults: dict[str, Any] | None = None,
    **where: Any,
) -> Any:
    row = one(model, **where)
    suffix = "existing"
    if row is None:
        row = model(**where, **(defaults or {}))
        db.session.add(row)
        db.session.flush()
        suffix = "created"
    stats[f"{key}_{suffix}"] = stats.get(f"{key}_{suffix}", 0) + 1
    return row


def ensure_listing(
    stats: dict[str, int],
    *,
    public_id: str,
    owner: User,
    listing_type: str,
    profile_entity_id: str,
    title: str,
    summary: str,
    city: City,
    price_minor: int,
) -> MarketplaceListing:
    return ensure(
        MarketplaceListing,
        stats,
        "listing",
        public_id=public_id,
        defaults={
            "owner_user_id": owner.id,
            "listing_type": listing_type,
            "profile_entity_id": profile_entity_id,
            "title": title,
            "summary": summary,
            "city_id": city.id,
            "price_from_minor": price_minor,
            "currency": "PKR",
            "verification_status": "approved",
            "moderation_status": "approved",
            "visibility": "public",
            "published_at": utc_now(),
        },
    )


def ensure_project(
    stats: dict[str, int],
    *,
    public_id: str,
    owner: User,
    city: City,
    title: str,
    project_type: str,
    status: str,
    start_date: date,
    progress: int,
    budget_minor: int,
) -> Project:
    project = ensure(
        Project,
        stats,
        "project",
        public_id=public_id,
        defaults={
            "owner_user_id": owner.id,
            "title": title,
            "project_type": project_type,
            "description": (
                "A production-ready brand campaign connecting cast, models, crew, "
                "location and camera resources through CineConnect."
            ),
            "city_id": city.id,
            "start_date": start_date,
            "end_date": start_date + timedelta(days=3),
            "status": status,
            "estimated_budget_minor": budget_minor,
            "currency": "PKR",
            "visibility": "project_members",
            "progress_percent": progress,
        },
    )
    ensure(
        ProjectMember,
        stats,
        "project_member",
        project_id=project.id,
        user_id=owner.id,
        defaults={
            "role_label": "Brand owner",
            "permissions_json": json.dumps(
                {
                    "manage_project": True,
                    "manage_requirements": True,
                    "manage_members": True,
                },
                sort_keys=True,
            ),
            "status": "active",
        },
    )
    return project


def ensure_conversation(
    stats: dict[str, int],
    *,
    booking: Booking,
    requester: User,
    provider: User,
    index: int,
) -> None:
    conversation = ensure(
        Conversation,
        stats,
        "conversation",
        public_id=f"DEMO-BRAND-CONV-{index:02}",
        defaults={
            "booking_id": booking.id,
            "project_id": booking.project_id,
            "type": "booking",
            "title": f"{booking.project.title} — {booking.listing.title}",
            "last_message_at": utc_now(),
        },
    )
    for member in (requester, provider):
        ensure(
            ConversationMember,
            stats,
            "conversation_member",
            conversation_id=conversation.id,
            user_id=member.id,
            defaults={},
        )
    ensure(
        Message,
        stats,
        "message",
        public_id=f"DEMO-BRAND-MSG-{index:02}",
        defaults={
            "conversation_id": conversation.id,
            "sender_user_id": requester.id,
            "message_type": "text",
            "body": (
                "We have shared the campaign brief and proposed production dates. "
                "Please confirm availability or send a counter-offer."
            ),
        },
    )


def seed() -> dict[str, int]:
    if os.getenv("CINECONNECT_ALLOW_DEMO_SEED") != "1":
        raise RuntimeError(
            "Set CINECONNECT_ALLOW_DEMO_SEED=1 to create clearly labelled demo data."
        )

    stats: dict[str, int] = {}
    now = datetime.now(UTC)
    brand = required(User, email=f"brand01@{DEMO_DOMAIN}")
    city = required(City, name="Lahore")
    brand_role = required(Role, code="brand_sponsor")
    ensure(
        KycSubmission,
        stats,
        "brand_kyc",
        public_id="DEMO-BRAND-KYC-001",
        defaults={
            "user_id": brand.id,
            "role_id": brand_role.id,
            "status": "approved",
            "risk_level": "low",
            "submitted_at": now - timedelta(days=30),
            "decision_at": now - timedelta(days=29),
            "decision_reason": "Approved demo Brand workspace.",
        },
    )

    actor_listing = required(MarketplaceListing, public_id="DEMO-LST-AT-001")
    listing_specs = [
        (
            "DEMO-LST-BRAND-MODEL-001",
            required(User, public_id="DEMO-MD-001"),
            "model",
            "DEMO-MOD-001",
            "Commercial lifestyle model",
            (
                "Experienced campaign model available for digital, fashion and "
                "product work."
            ),
            145_000 * 100,
        ),
        (
            "DEMO-LST-BRAND-CREW-001",
            required(User, public_id="DEMO-CR-001"),
            "crew",
            "DEMO-CR-001",
            "1st AD and production crew",
            "A coordinated assistant-direction team for commercials and branded films.",
            190_000 * 100,
        ),
        (
            "DEMO-LST-BRAND-LOCATION-001",
            required(User, public_id="DEMO-LO-001"),
            "location",
            "DEMO-LOC-001",
            "Haveli Gulberg campaign location",
            (
                "A camera-ready heritage interior with production access and "
                "holding space."
            ),
            220_000 * 100,
        ),
        (
            "DEMO-LST-BRAND-EQUIPMENT-001",
            required(User, public_id="DEMO-ME-001"),
            "equipment",
            "DEMO-EPP-001",
            "Alexa Mini LF commercial package",
            (
                "Cinema camera, Cooke lens and Aputure lighting package with "
                "operator support."
            ),
            260_000 * 100,
        ),
    ]
    listings = [actor_listing]
    for public_id, owner, kind, entity_id, title, summary, price in listing_specs:
        listings.append(
            ensure_listing(
                stats,
                public_id=public_id,
                owner=owner,
                listing_type=kind,
                profile_entity_id=entity_id,
                title=title,
                summary=summary,
                city=city,
                price_minor=price,
            )
        )

    actor = actor_listing.owner
    model_listing = listings[1]
    model = model_listing.owner
    actor_portrait = install_public_portrait(
        stats,
        public_id="DEMO-BRAND-ACTOR-HERO-001",
        owner=actor,
        filename="nova-cola-actor-hero.png",
    )
    model_portrait = install_public_portrait(
        stats,
        public_id="DEMO-BRAND-MODEL-HERO-001",
        owner=model,
        filename="nova-cola-model-hero.png",
    )
    actor_profile = required(UserProfile, user_id=actor.id)
    actor_profile.bio = (
        "A warm, grounded screen performer with an assured contemporary presence. "
        "Ayaan brings natural dialogue, subtle comedy and emotional credibility to "
        "commercials, branded films and modern drama."
    )
    actor_profile.avatar_file_id = actor_portrait.id
    actor_profile.cover_file_id = actor_portrait.id
    actor_profile.rating_average = Decimal("4.80")
    actor_profile.review_count = 24
    actor_talent = required(TalentProfile, user_id=actor.id)
    actor_talent.screen_name = "Ayaan Malik"
    actor_talent.age_range = "25-34"
    actor_talent.height_cm = 181
    actor_talent.experience_years = 8
    actor_talent.skills_json = json.dumps(
        ["Natural performance", "Commercial lead", "Comedy", "Improvisation"]
    )
    actor_talent.accents_json = json.dumps(["Neutral Urdu", "Lahori", "English"])
    actor_talent.credits_json = json.dumps(
        [
            {"title": "River Lights", "role": "Supporting lead"},
            {"title": "Northbound", "role": "Commercial lead"},
        ]
    )
    actor_talent.training_json = json.dumps(
        [{"title": "Camera performance intensive", "provider": "The Scene Lab"}]
    )
    actor_talent.social_links_json = json.dumps(
        {"instagram": "https://instagram.com/cineconnect.demo.actor"}
    )
    actor_listing.title = "Ayaan Malik · Commercial actor"
    actor_listing.summary = actor_profile.bio
    attach_listing_portrait(
        stats,
        listing=actor_listing,
        file=actor_portrait,
        caption="Ayaan Malik · casting portrait",
    )

    model.display_name = "Maya Raza"
    model_profile = required(UserProfile, user_id=model.id)
    model_profile.bio = (
        "Commercial and editorial model with an elegant, expressive presence for "
        "beauty, lifestyle and fashion campaigns. Maya combines camera confidence "
        "with a polished, approachable energy suited to premium brand storytelling."
    )
    model_profile.avatar_file_id = model_portrait.id
    model_profile.cover_file_id = model_portrait.id
    model_profile.rating_average = Decimal("4.90")
    model_profile.review_count = 31
    model_talent = required(TalentProfile, user_id=model.id)
    model_talent.screen_name = "Maya Raza"
    model_talent.age_range = "23-31"
    model_talent.height_cm = 173
    model_talent.experience_years = 6
    model_talent.skills_json = json.dumps(
        ["Beauty", "Lifestyle", "Fashion", "Product storytelling"]
    )
    model_talent.social_links_json = json.dumps(
        {"instagram": "https://instagram.com/cineconnect.demo.model"}
    )
    model_listing.title = "Maya Raza · Commercial model"
    model_listing.summary = model_profile.bio
    attach_listing_portrait(
        stats,
        listing=model_listing,
        file=model_portrait,
        caption="Maya Raza · campaign portrait",
    )

    shoot_day = date.today() + timedelta(days=21)
    active_project = ensure_project(
        stats,
        public_id="DEMO-BRAND-PRJ-001",
        owner=brand,
        city=city,
        title="Nova Cola Winter Stories",
        project_type="digital_advertisement",
        status="active",
        start_date=shoot_day,
        progress=58,
        budget_minor=3_800_000 * 100,
    )
    ensure_project(
        stats,
        public_id="DEMO-BRAND-PRJ-002",
        owner=brand,
        city=city,
        title="Nova Cola Campus Launch",
        project_type="social_media_campaign",
        status="draft",
        start_date=shoot_day + timedelta(days=20),
        progress=0,
        budget_minor=1_650_000 * 100,
    )
    ensure_project(
        stats,
        public_id="DEMO-BRAND-PRJ-003",
        owner=brand,
        city=city,
        title="Nova Cola Eid Table",
        project_type="product_shoot",
        status="completed",
        start_date=shoot_day - timedelta(days=45),
        progress=100,
        budget_minor=2_400_000 * 100,
    )

    requirement_specs = [
        ("talent", "Lead actor", 1, 280_000 * 100),
        ("model", "Lifestyle campaign model", 2, 320_000 * 100),
        ("crew", "Commercial production crew", 1, 450_000 * 100),
        ("location", "Heritage indoor location", 1, 300_000 * 100),
        ("equipment", "Cinema camera and lighting", 1, 500_000 * 100),
    ]
    requirements: list[ProjectRequirement] = []
    for index, (category, title, quantity, budget) in enumerate(
        requirement_specs, start=1
    ):
        requirements.append(
            ensure(
                ProjectRequirement,
                stats,
                "requirement",
                public_id=f"DEMO-BRAND-REQ-{index:02}",
                defaults={
                    "project_id": active_project.id,
                    "category": category,
                    "title": title,
                    "summary": f"Verified {category} resource for the hero campaign.",
                    "budget_max_minor": budget,
                    "currency": "PKR",
                    "start_date": active_project.start_date,
                    "end_date": active_project.end_date,
                    "status": "open",
                    "candidate_count_cache": 1,
                    "visibility": "verified_only",
                    "quantity": quantity,
                },
            )
        )

    shortlist = ensure(
        Shortlist,
        stats,
        "shortlist",
        public_id="DEMO-BRAND-SHL-001",
        defaults={
            "project_id": active_project.public_id,
            "requirement_id": requirements[0].public_id,
            "created_by": brand.id,
            "name": "Nova Cola hero production team",
        },
    )
    shortlist_statuses = ["selected", "active", "selected", "active", "selected"]
    for index, (listing, status) in enumerate(
        zip(listings, shortlist_statuses, strict=True), start=1
    ):
        ensure(
            ShortlistItem,
            stats,
            "shortlist_item",
            public_id=f"DEMO-BRAND-SHLI-{index:02}",
            defaults={
                "shortlist_id": shortlist.id,
                "listing_id": listing.id,
                "candidate_user_id": listing.owner_user_id,
                "rank": index,
                "notes": "Strong creative and budget fit for the campaign brief.",
                "status": status,
            },
        )

    booking_statuses = ["accepted", "under_negotiation", "sent", "viewed", "secured"]
    for index, (listing, requirement, status) in enumerate(
        zip(listings, requirements, booking_statuses, strict=True), start=1
    ):
        start_at = datetime.combine(
            shoot_day + timedelta(days=index - 1),
            datetime.min.time(),
            tzinfo=UTC,
        ) + timedelta(hours=9)
        booking = ensure(
            Booking,
            stats,
            "booking",
            public_id=f"DEMO-BRAND-BKG-{index:02}",
            defaults={
                "project_id": active_project.id,
                "requirement_id": requirement.id,
                "requester_user_id": brand.id,
                "provider_user_id": listing.owner_user_id,
                "listing_id": listing.id,
                "category": requirement.category,
                "status": status,
                "agreed_amount_minor": listing.price_from_minor,
                "currency": "PKR",
                "start_at": start_at,
                "end_at": start_at + timedelta(hours=10),
                "expires_at": start_at - timedelta(days=5),
                "secured_at": now if status == "secured" else None,
            },
        )
        provider = listing.owner
        for participant, role_label in ((brand, "requester"), (provider, "provider")):
            ensure(
                BookingParticipant,
                stats,
                "booking_participant",
                booking_id=booking.id,
                user_id=participant.id,
                defaults={
                    "participant_role": role_label,
                    "can_chat": True,
                    "can_view_finance": True,
                },
            )
        if not booking.status_events:
            db.session.add_all(
                [
                    BookingStatusEvent(
                        booking_id=booking.id,
                        actor_user_id=brand.id,
                        from_status=None,
                        to_status="sent",
                        reason="Brand Portal demo request sent.",
                        metadata_json=json.dumps({"is_demo": True}),
                    ),
                    BookingStatusEvent(
                        booking_id=booking.id,
                        actor_user_id=provider.id,
                        from_status="sent",
                        to_status=status,
                        reason="Brand Portal demo provider response.",
                        metadata_json=json.dumps({"is_demo": True}),
                    ),
                ]
            )
            stats["booking_status_event_created"] = (
                stats.get("booking_status_event_created", 0) + 2
            )
        ensure_conversation(
            stats,
            booking=booking,
            requester=brand,
            provider=provider,
            index=index,
        )
        ensure(
            Notification,
            stats,
            "notification",
            public_id=f"DEMO-BRAND-NTF-{index:02}",
            defaults={
                "user_id": brand.id,
                "category": "booking",
                "title": f"{listing.title}: {status.replace('_', ' ').title()}",
                "body": "The demo production request has a new persisted status.",
                "route_name": "/brand/requests",
                "route_params_json": json.dumps(
                    {"booking_id": booking.public_id, "is_demo": True}
                ),
            },
        )

    db.session.commit()
    return stats


def main() -> None:
    app = create_app()
    with app.app_context():
        stats = seed()
    print(json.dumps({"brand_portal_demo": True, "stats": stats}, indent=2))


if __name__ == "__main__":
    main()
