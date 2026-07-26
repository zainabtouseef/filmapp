from __future__ import annotations

import hashlib
import json
import os
import struct
import sys
import zlib
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from typing import Any

from sqlalchemy import select

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import create_app  # noqa: E402
from app.extensions import db  # noqa: E402
from app.models import (  # noqa: E402
    Booking,
    BookingParticipant,
    BookingStatusEvent,
    City,
    Conversation,
    ConversationMember,
    FileAsset,
    KycDocument,
    KycSubmission,
    ListingMedia,
    MarketplaceListing,
    Message,
    NegotiationRound,
    NegotiationThread,
    Offer,
    Project,
    Role,
    TalentLanguage,
    TalentProfile,
    User,
    UserProfile,
    UserRole,
    VerificationEvent,
)
from app.security import hash_password  # noqa: E402

SEED_BATCH = "cineconnect-influencer-public-demo-2026-07-26"
DEFAULT_PASSWORD = os.getenv("CINECONNECT_DEMO_PASSWORD", "CineDemo@2026!")
DEMO_EMAIL_DOMAIN = os.getenv(
    "CINECONNECT_DEMO_EMAIL_DOMAIN",
    "demo.cine.nalexustechnologies.com",
)
NOW = datetime.now(UTC)
BASE_DAY = date(2026, 10, 1)


@dataclass(frozen=True)
class InfluencerSeed:
    idx: int
    name: str
    city: str
    niche: str
    platform: str
    followers: str
    rate_pkr: int
    palette: tuple[int, int, int]

    @property
    def user_public_id(self) -> str:
        return f"DEMO-INF-{self.idx:03}"

    @property
    def email(self) -> str:
        return f"influencer{self.idx:02}@{DEMO_EMAIL_DOMAIN}"

    @property
    def talent_public_id(self) -> str:
        return f"DEMO-TAL-INF-{self.idx:03}"

    @property
    def listing_public_id(self) -> str:
        return f"DEMO-LST-INF-{self.idx:03}"

    @property
    def file_public_id(self) -> str:
        return f"DEMO-FILE-INF-{self.idx:03}"


INFLUENCERS = [
    InfluencerSeed(
        1,
        "Ayesha Khan Studio",
        "Lahore",
        "fashion lifestyle",
        "Instagram",
        "420k",
        180_000,
        (185, 135, 45),
    ),
    InfluencerSeed(
        2,
        "Bilal Vlogs PK",
        "Karachi",
        "food and city culture",
        "YouTube",
        "610k",
        220_000,
        (30, 120, 170),
    ),
    InfluencerSeed(
        3,
        "Mina Beauty Desk",
        "Islamabad",
        "beauty skincare",
        "Instagram",
        "380k",
        160_000,
        (184, 76, 118),
    ),
    InfluencerSeed(
        4,
        "Hamza Tech Finds",
        "Lahore",
        "tech reviews",
        "TikTok",
        "290k",
        145_000,
        (70, 95, 170),
    ),
    InfluencerSeed(
        5,
        "Noor Travel Stories",
        "Gwadar",
        "travel tourism",
        "Instagram",
        "510k",
        210_000,
        (35, 145, 130),
    ),
    InfluencerSeed(
        6,
        "Sana Campus Style",
        "Karachi",
        "student lifestyle",
        "TikTok",
        "260k",
        125_000,
        (150, 95, 45),
    ),
    InfluencerSeed(
        7,
        "Omar Fitness Lab",
        "Rawalpindi",
        "fitness wellness",
        "Instagram",
        "340k",
        155_000,
        (60, 150, 80),
    ),
    InfluencerSeed(
        8,
        "Laila Home Kitchen",
        "Lahore",
        "food recipes",
        "YouTube",
        "470k",
        190_000,
        (205, 92, 48),
    ),
    InfluencerSeed(
        9,
        "Mariam Impact PK",
        "Islamabad",
        "public awareness",
        "Instagram",
        "315k",
        150_000,
        (95, 120, 70),
    ),
    InfluencerSeed(
        10,
        "Taha Street Frames",
        "Bahawalpur",
        "street photography",
        "TikTok",
        "230k",
        115_000,
        (105, 80, 150),
    ),
]

PUBLIC_BUYER = {
    "public_id": "DEMO-GP-001",
    "email": f"public01@{DEMO_EMAIL_DOMAIN}",
    "display_name": "Zain Marketing Customer",
    "phone_e164": "+923001990001",
}


def one(model: type[Any], **where: Any) -> Any | None:
    return db.session.execute(select(model).filter_by(**where)).scalar_one_or_none()


def remember(stats: dict[str, int], key: str, created: bool) -> None:
    suffix = "created" if created else "existing"
    stats[f"{key}_{suffix}"] = stats.get(f"{key}_{suffix}", 0) + 1


def ensure(
    model: type[Any],
    stats: dict[str, int],
    key: str,
    defaults: dict[str, Any] | None = None,
    **where: Any,
) -> Any:
    row = one(model, **where)
    if row is not None:
        remember(stats, key, False)
        return row
    row = model(**where, **(defaults or {}))
    db.session.add(row)
    db.session.flush()
    remember(stats, key, True)
    return row


def required(model: type[Any], **where: Any) -> Any:
    row = one(model, **where)
    if row is None:
        raise RuntimeError(f"Missing required {model.__name__}: {where}")
    return row


def role(code: str) -> Role:
    return required(Role, code=code)


def city(name: str) -> City:
    return required(City, name=name)


def public_root() -> Path:
    return Path(
        os.getenv("LOCAL_STORAGE_PUBLIC_ROOT")
        or os.getenv("CINECONNECT_PUBLIC_STORAGE_ROOT")
        or "/data/storage/public"
    )


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + kind
        + payload
        + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )


def demo_png(width: int, height: int, base: tuple[int, int, int], idx: int) -> bytes:
    rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            vignette = int(34 * (x / width) + 28 * (y / height))
            stripe = 42 if ((x + y + idx * 17) // 34) % 2 == 0 else 0
            gold_dot = (x - width + 70) ** 2 + (y - 70) ** 2 < 44**2
            r = min(255, max(0, base[0] + stripe - vignette))
            g = min(255, max(0, base[1] + stripe - vignette))
            b = min(255, max(0, base[2] + stripe - vignette))
            if gold_dot:
                r, g, b = 196, 145, 48
            row.extend((r, g, b))
        rows.append(bytes(row))
    raw = b"".join(rows)
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(raw, 9))
        + png_chunk(b"IEND", b"")
    )


def write_public_png(seed: InfluencerSeed) -> dict[str, Any]:
    filename = f"influencer-{seed.idx:02}-{seed.name.lower().replace(' ', '-')}.png"
    storage_key = f"demo/{SEED_BATCH}/influencer-covers/{filename}"
    target = public_root() / storage_key
    target.parent.mkdir(parents=True, exist_ok=True)
    data = demo_png(960, 640, seed.palette, seed.idx)
    target.write_bytes(data)
    return {
        "storage_key": storage_key,
        "mime_type": "image/png",
        "size_bytes": len(data),
        "checksum_sha256": hashlib.sha256(data).hexdigest(),
        "original_name": filename,
    }


def ensure_file(
    public_id: str,
    owner_user_id: Any,
    media: dict[str, Any],
    stats: dict[str, int],
) -> FileAsset:
    file = one(FileAsset, public_id=public_id)
    created = False
    if file is None:
        file = FileAsset(public_id=public_id, owner_user_id=owner_user_id)
        db.session.add(file)
        created = True
    file.owner_user_id = owner_user_id
    file.storage_key = media["storage_key"]
    file.bucket = os.getenv("OBJECT_STORAGE_BUCKET_PUBLIC", "cineconnect-public")
    file.mime_type = media["mime_type"]
    file.size_bytes = media["size_bytes"]
    file.checksum_sha256 = media["checksum_sha256"]
    file.visibility = "public"
    file.scan_status = "clean"
    file.processing_status = "ready"
    file.original_name = media["original_name"]
    db.session.flush()
    remember(stats, "public_file", created)
    return file


def ensure_user(
    *,
    stats: dict[str, int],
    public_id: str,
    email: str,
    display_name: str,
    role_code: str,
    primary: bool = True,
    phone_e164: str | None = None,
) -> User:
    user = ensure(
        User,
        stats,
        "user",
        public_id=public_id,
        defaults={
            "email": email,
            "phone_e164": phone_e164,
            "password_hash": hash_password(DEFAULT_PASSWORD),
            "display_name": display_name,
            "status": "active",
            "email_verified_at": NOW,
            "phone_verified_at": NOW if phone_e164 else None,
            "terms_version": "2026-07",
            "terms_accepted_at": NOW,
        },
    )
    user.email = email
    user.display_name = display_name
    user.status = "active"
    user.email_verified_at = user.email_verified_at or NOW
    if phone_e164 and not user.phone_e164:
        user.phone_e164 = phone_e164
    user_role = ensure(
        UserRole,
        stats,
        "user_role",
        user_id=user.id,
        role_id=role(role_code).id,
        defaults={
            "status": "active",
            "is_primary": primary,
            "approved_at": NOW,
        },
    )
    user_role.status = "active"
    user_role.is_primary = primary
    user_role.approved_at = user_role.approved_at or NOW
    return user


def ensure_approved_kyc(user: User, stats: dict[str, int]) -> None:
    influencer_role = role("influencer")
    submission = ensure(
        KycSubmission,
        stats,
        "kyc_submission",
        public_id=f"DEMO-KYC-INF-{user.public_id[-3:]}",
        defaults={
            "user_id": user.id,
            "role_id": influencer_role.id,
            "status": "approved",
            "risk_level": "low",
            "submitted_at": NOW - timedelta(days=3),
            "decision_at": NOW - timedelta(days=2),
            "decision_reason": "Demo influencer identity approved.",
        },
    )
    submission.user_id = user.id
    submission.role_id = influencer_role.id
    submission.status = "approved"
    submission.decision_at = submission.decision_at or NOW
    ensure(
        VerificationEvent,
        stats,
        "verification_event",
        submission_id=submission.id,
        to_status="approved",
        defaults={
            "actor_user_id": user.id,
            "from_status": "pending",
            "reason": "Demo approval for influencer walkthrough.",
            "metadata_json": {"seed_batch": SEED_BATCH},
        },
    )
    ensure(
        KycDocument,
        stats,
        "kyc_document",
        submission_id=submission.id,
        document_type="cnic_front",
        defaults={
            "country": "PK",
            "document_number_encrypted": f"demo-inf-{user.public_id[-3:]}",
            "expires_on": date(2031, 12, 31),
            "status": "approved",
        },
    )


def seed_influencers(stats: dict[str, int]) -> list[MarketplaceListing]:
    listings: list[MarketplaceListing] = []
    for seed in INFLUENCERS:
        user = ensure_user(
            stats=stats,
            public_id=seed.user_public_id,
            email=seed.email,
            display_name=seed.name,
            role_code="influencer",
        )
        media = write_public_png(seed)
        image_file = ensure_file(seed.file_public_id, user.id, media, stats)
        user_profile = ensure(
            UserProfile,
            stats,
            "user_profile",
            user_id=user.id,
            defaults={
                "bio": (
                    f"{seed.name} creates Pakistan-relevant {seed.niche} "
                    f"campaigns with {seed.followers} followers on {seed.platform}."
                ),
                "city_id": city(seed.city).id,
                "avatar_file_id": image_file.id,
                "cover_file_id": image_file.id,
                "website_url": f"https://cine.nalexustechnologies.com/demo/influencer/{seed.idx:02}",
                "social_links_json": json.dumps(
                    {
                        seed.platform.lower(): f"@cine_demo_influencer_{seed.idx:02}",
                        "followers": seed.followers,
                    }
                ),
                "profile_visibility": "public",
                "rating_average": 4,
                "review_count": 12 + seed.idx,
            },
        )
        user_profile.city_id = city(seed.city).id
        user_profile.avatar_file_id = image_file.id
        user_profile.cover_file_id = image_file.id
        talent = ensure(
            TalentProfile,
            stats,
            "talent_profile",
            public_id=seed.talent_public_id,
            defaults={
                "user_id": user.id,
                "screen_name": seed.name,
                "age_range": "24-34",
                "gender_identity": "Not specified",
                "experience_years": 4 + seed.idx,
                "availability_status": "available",
                "day_rate_minor": seed.rate_pkr * 100,
                "currency": "PKR",
                "skills_json": json.dumps(
                    [seed.niche, "brand integrations", "short-form video"]
                ),
                "social_links_json": json.dumps(
                    {
                        "primary_platform": seed.platform,
                        "followers": seed.followers,
                    }
                ),
                "availability_categories_json": json.dumps(["influencer"]),
            },
        )
        talent.user_id = user.id
        talent.screen_name = seed.name
        talent.availability_status = "available"
        talent.day_rate_minor = seed.rate_pkr * 100
        talent.availability_categories_json = json.dumps(["influencer"])
        for language in ["Urdu", "English"]:
            ensure(
                TalentLanguage,
                stats,
                "talent_language",
                talent_profile_id=talent.id,
                language=language,
                defaults={"proficiency": "fluent"},
            )
        listing = ensure(
            MarketplaceListing,
            stats,
            "listing",
            public_id=seed.listing_public_id,
            defaults={
                "owner_user_id": user.id,
                "listing_type": "influencer",
                "profile_entity_id": talent.public_id,
                "title": seed.name,
                "summary": (
                    f"{seed.platform} creator for {seed.niche} campaigns in "
                    f"{seed.city}. Demo audience: {seed.followers} followers."
                ),
                "city_id": city(seed.city).id,
                "price_from_minor": seed.rate_pkr * 100,
                "currency": "PKR",
                "verification_status": "approved",
                "moderation_status": "approved",
                "visibility": "public",
                "published_at": NOW - timedelta(days=seed.idx),
            },
        )
        listing.owner_user_id = user.id
        listing.listing_type = "influencer"
        listing.profile_entity_id = talent.public_id
        listing.title = seed.name
        listing.summary = (
            f"{seed.platform} creator for {seed.niche} campaigns in {seed.city}. "
            f"Demo audience: {seed.followers} followers."
        )
        listing.city_id = city(seed.city).id
        listing.price_from_minor = seed.rate_pkr * 100
        listing.currency = "PKR"
        listing.verification_status = "approved"
        listing.moderation_status = "approved"
        listing.visibility = "public"
        listing.published_at = listing.published_at or NOW - timedelta(days=seed.idx)
        media_row = ensure(
            ListingMedia,
            stats,
            "listing_media",
            listing_id=listing.id,
            file_id=image_file.id,
            defaults={
                "sort_order": 0,
                "is_cover": True,
                "caption": f"{seed.name} demo campaign cover",
            },
        )
        media_row.sort_order = 0
        media_row.is_cover = True
        media_row.caption = f"{seed.name} demo campaign cover"
        ensure_approved_kyc(user, stats)
        listings.append(listing)
    return listings


def seed_public_buyer(stats: dict[str, int]) -> User:
    user = ensure_user(
        stats=stats,
        public_id=PUBLIC_BUYER["public_id"],
        email=PUBLIC_BUYER["email"],
        display_name=PUBLIC_BUYER["display_name"],
        role_code="general_public",
        phone_e164=PUBLIC_BUYER["phone_e164"],
    )
    ensure(
        UserProfile,
        stats,
        "user_profile",
        user_id=user.id,
        defaults={
            "bio": "Demo customer account for booking actors, models and influencers.",
            "city_id": city("Lahore").id,
            "profile_visibility": "private",
        },
    )
    return user


def seed_public_bookings(
    stats: dict[str, int],
    buyer: User,
    influencer_listings: list[MarketplaceListing],
) -> None:
    campaign_titles = [
        "Nova Cola Creator Launch",
        "Naya Wear Eid Reel Campaign",
        "TravelPK Gwadar Weekend Push",
        "ByteCafe Student Offer",
        "Masala House Recipe Series",
    ]
    for idx, listing in enumerate(influencer_listings[:5], start=1):
        project = ensure(
            Project,
            stats,
            "public_campaign_project",
            public_id=f"DEMO-GP-PRJ-{idx:03}",
            defaults={
                "owner_user_id": buyer.id,
                "title": campaign_titles[idx - 1],
                "project_type": "marketing_campaign",
                "description": (
                    "General Public demo campaign automatically managed as a "
                    "private booking project."
                ),
                "city_id": listing.city_id,
                "start_date": BASE_DAY + timedelta(days=idx * 5),
                "end_date": BASE_DAY + timedelta(days=idx * 5 + 3),
                "status": "active",
                "estimated_budget_minor": (300_000 + idx * 50_000) * 100,
                "currency": "PKR",
                "visibility": "private",
                "progress_percent": 20 + idx * 10,
            },
        )
        start = datetime(2026, 10, 5 + idx * 5, 10, tzinfo=UTC)
        fee_minor = listing.price_from_minor or 150_000 * 100
        booking = ensure(
            Booking,
            stats,
            "public_booking",
            public_id=f"DEMO-GP-BKG-{idx:03}",
            defaults={
                "project_id": project.id,
                "requirement_id": None,
                "requester_user_id": buyer.id,
                "provider_user_id": listing.owner_user_id,
                "listing_id": listing.id,
                "category": "influencer",
                "status": "sent" if idx in {1, 4} else "under_negotiation",
                "agreed_amount_minor": None if idx in {1, 4} else fee_minor,
                "currency": "PKR",
                "start_at": start,
                "end_at": start + timedelta(days=2),
                "expires_at": start - timedelta(days=3),
            },
        )
        booking.project_id = project.id
        booking.requester_user_id = buyer.id
        booking.provider_user_id = listing.owner_user_id
        booking.listing_id = listing.id
        booking.category = "influencer"
        for participant, participant_role in [
            (buyer, "requester"),
            (listing.owner, "provider"),
        ]:
            ensure(
                BookingParticipant,
                stats,
                "public_booking_participant",
                booking_id=booking.id,
                user_id=participant.id,
                defaults={
                    "participant_role": participant_role,
                    "can_chat": True,
                    "can_view_finance": True,
                },
            )
        ensure(
            BookingStatusEvent,
            stats,
            "public_booking_status",
            booking_id=booking.id,
            to_status=booking.status,
            defaults={
                "actor_user_id": buyer.id,
                "from_status": "draft",
                "reason": "Demo public customer campaign request.",
                "metadata_json": json.dumps({"seed_batch": SEED_BATCH}),
            },
        )
        offer = ensure(
            Offer,
            stats,
            "public_offer",
            public_id=f"DEMO-GP-OFF-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "sender_user_id": buyer.id,
                "recipient_user_id": listing.owner_user_id,
                "revision": 1,
                "fee_minor": fee_minor,
                "currency": "PKR",
                "conditions": (
                    "Demo public campaign request: one hero reel, two stories, "
                    "brand tag and 30-day usage."
                ),
                "payment_schedule_json": json.dumps(
                    {"advance_percent": 50, "completion_percent": 50}
                ),
                "status": "active",
                "expires_at": booking.expires_at,
            },
        )
        thread = ensure(
            NegotiationThread,
            stats,
            "public_negotiation_thread",
            public_id=f"DEMO-GP-NEG-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "status": "open",
                "current_offer_id": offer.id,
            },
        )
        thread.current_offer_id = offer.id
        ensure(
            NegotiationRound,
            stats,
            "public_negotiation_round",
            thread_id=thread.id,
            round_number=1,
            defaults={
                "offer_id": offer.id,
                "sender_user_id": buyer.id,
                "message": (
                    "Please share deliverables, availability and content "
                    "approval timing."
                ),
            },
        )
        conv = ensure(
            Conversation,
            stats,
            "public_conversation",
            public_id=f"DEMO-GP-CONV-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "project_id": project.id,
                "type": "booking",
                "title": f"{project.title} chat",
                "last_message_at": NOW - timedelta(hours=idx),
            },
        )
        for member in [buyer, listing.owner]:
            ensure(
                ConversationMember,
                stats,
                "public_conversation_member",
                conversation_id=conv.id,
                user_id=member.id,
                defaults={},
            )
        for msg_idx, sender in enumerate([buyer, listing.owner], start=1):
            ensure(
                Message,
                stats,
                "public_message",
                public_id=f"DEMO-GP-MSG-{idx:03}-{msg_idx:02}",
                defaults={
                    "conversation_id": conv.id,
                    "sender_user_id": sender.id,
                    "message_type": "text",
                    "body": (
                        "Demo campaign brief received."
                        if msg_idx == 2
                        else "We need a Pakistan-relevant social campaign next month."
                    ),
                },
            )


def main() -> None:
    app = create_app()
    stats: dict[str, int] = {}
    with app.app_context():
        # Ensure the two newer roles exist even if someone runs this before migration.
        role("influencer")
        role("general_public")
        influencer_listings = seed_influencers(stats)
        buyer = seed_public_buyer(stats)
        seed_public_bookings(stats, buyer, influencer_listings)
        db.session.commit()
        output = {
            "seed_batch": SEED_BATCH,
            "stats": dict(sorted(stats.items())),
            "logins": {
                "general_public": {
                    "email": PUBLIC_BUYER["email"],
                    "password": DEFAULT_PASSWORD,
                    "route": "/public",
                },
                "influencer_primary": {
                    "email": INFLUENCERS[0].email,
                    "password": DEFAULT_PASSWORD,
                    "route": "/talent",
                },
            },
            "influencer_count": len(influencer_listings),
        }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
