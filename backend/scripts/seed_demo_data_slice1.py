from __future__ import annotations

import json
import os
import sys
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from typing import Any

from sqlalchemy import select

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import create_app
from app.extensions import db
from app.models import (
    AgencyTalent,
    AvailabilityCalendar,
    AvailabilityEntry,
    BrandProfile,
    CastingAgency,
    City,
    Country,
    DistributorContact,
    DistributionPartnerProfile,
    DistributionProject,
    EquipmentItem,
    EquipmentPackage,
    EquipmentPackageItem,
    EquipmentProviderProfile,
    EquipmentTerm,
    FileAsset,
    KycDocument,
    KycSubmission,
    ListingMedia,
    LocationPricing,
    LocationProperty,
    LocationRule,
    LocationSpace,
    MarketplaceListing,
    ModelCampaignCategory,
    ModelProfile,
    ModelRestrictedCategory,
    ModelUsageRate,
    ModelUsageRight,
    NotificationPreference,
    PortfolioItem,
    Project,
    ProjectFile,
    ProjectMember,
    ProjectRequirement,
    ProjectRoomItem,
    RequirementSkill,
    Role,
    SavedSearch,
    Shortlist,
    ShortlistItem,
    Skill,
    TalentLanguage,
    TalentProfile,
    User,
    UserProfile,
    UserRole,
    UserSettings,
    VerificationEvent,
)
from app.security import hash_password


SEED_BATCH = "cineconnect-demo-2026-07-18"
DEFAULT_PASSWORD = os.getenv("CINECONNECT_DEMO_PASSWORD", "CineDemo@2026!")
DEMO_EMAIL_DOMAIN = os.getenv(
    "CINECONNECT_DEMO_EMAIL_DOMAIN",
    "demo.cine.nalexustechnologies.com",
)
NOW = datetime.now(UTC)
BASE_DAY = date(2026, 8, 1)


@dataclass(frozen=True)
class Backbone:
    idx: int
    project_id: str
    title: str
    project_type: str
    city: str
    status: str
    producer: str
    talent: str
    location: str
    equipment_package: str
    brand: str


BACKBONE = [
    Backbone(
        1,
        "DEMO-PROJ-001",
        "River Lights",
        "Feature film",
        "Lahore",
        "active",
        "Sara Nadeem",
        "Ayaan Malik",
        "Haveli Gulberg",
        "Alexa Mini LF Kit",
        "Nova Cola",
    ),
    Backbone(
        2,
        "DEMO-PROJ-002",
        "City of Dust",
        "TV drama",
        "Karachi",
        "casting",
        "Hamza Rafiq",
        "Meher Shah",
        "Saddar Rooftop",
        "Sony FX6 Doc Kit",
        "Zest Telecom",
    ),
    Backbone(
        3,
        "DEMO-PROJ-003",
        "Blue Van",
        "Commercial",
        "Islamabad",
        "secured",
        "Noor Khan",
        "Zain Javed",
        "Margalla Farmhouse",
        "Drone + Gimbal Pack",
        "Orion Bank",
    ),
    Backbone(
        4,
        "DEMO-PROJ-004",
        "Eid Run",
        "Music video",
        "Lahore",
        "negotiating",
        "Bilal Qureshi",
        "Hira Salman",
        "Old City Street Set",
        "Lighting Sprint Pack",
        "Naya Wear",
    ),
    Backbone(
        5,
        "DEMO-PROJ-005",
        "Salt Road",
        "Documentary",
        "Gwadar",
        "preprod",
        "Mahnoor Ali",
        "Faris Sheikh",
        "Coastal Warehouse",
        "Documentary Sound Kit",
        "TravelPK",
    ),
    Backbone(
        6,
        "DEMO-PROJ-006",
        "Campus Beat",
        "Web series",
        "Karachi",
        "active",
        "Umer Siddiqui",
        "Sana Mirza",
        "University Courtyard",
        "Multi-cam Podcast Kit",
        "ByteCafe",
    ),
    Backbone(
        7,
        "DEMO-PROJ-007",
        "Night Bazaar",
        "Short film",
        "Rawalpindi",
        "review",
        "Daniyal Hussain",
        "Omar Rehman",
        "Bazaar Backlot",
        "Low-light Cinema Kit",
        "Indie Fund",
    ),
    Backbone(
        8,
        "DEMO-PROJ-008",
        "Monsoon Menu",
        "Food campaign",
        "Lahore",
        "delivered",
        "Amina Farooq",
        "Laila Noor",
        "Studio Kitchen",
        "Tabletop Food Kit",
        "Masala House",
    ),
    Backbone(
        9,
        "DEMO-PROJ-009",
        "Safe Set PSA",
        "Safety PSA",
        "Islamabad",
        "incident_review",
        "Kamil Ahmed",
        "Mariam Tariq",
        "Hospital Training Wing",
        "Compact ENG Kit",
        "InsurePro",
    ),
    Backbone(
        10,
        "DEMO-PROJ-010",
        "Desert Echo",
        "OTT pilot",
        "Bahawalpur",
        "distribution",
        "Reema Iqbal",
        "Taha Baig",
        "Desert Fort",
        "Remote Production Kit",
        "StreamSphere",
    ),
]


USER_GROUPS: dict[str, tuple[str, str, list[str]]] = {
    "ADMIN": ("admin", "super_admin", ["CineConnect Demo Admin"]),
    "DP": ("dp", "director_producer", [b.producer for b in BACKBONE]),
    "AT": ("talent", "actor_talent", [b.talent for b in BACKBONE]),
    "MD": ("model", "model", [f"Demo Model {i:02}" for i in range(1, 11)]),
    "LO": ("location", "location_owner", [f"{b.location} Owner" for b in BACKBONE]),
    "ME": (
        "equipment",
        "equipment_provider",
        [f"{b.equipment_package} Provider" for b in BACKBONE],
    ),
    "CR": (
        "crew",
        "crew_service",
        [
            "1st AD Team",
            "Location Sound",
            "Drone Operator",
            "Choreography Crew",
            "Documentary Fixer",
            "Multi-cam Operators",
            "Night Lighting Crew",
            "Food Stylist Team",
            "Safety Marshal",
            "Remote Production Coordinator",
        ],
    ),
    "CA": (
        "agency",
        "casting_agency",
        [
            "North Star Casting",
            "Karachi Screen Faces",
            "AdCast Studio",
            "Rhythm Casting",
            "Real People Network",
            "Campus Talent Desk",
            "Character Room",
            "Lifestyle Hosts PK",
            "Public Impact Casting",
            "OTT Launch Casting",
        ],
    ),
    "BR": ("brand", "brand_sponsor", [b.brand for b in BACKBONE]),
    "LG": ("legal", "legal_partner", [f"Legal Partner {i:02}" for i in range(1, 11)]),
    "IN": (
        "insurance",
        "insurance_partner",
        [f"Insurance Partner {i:02}" for i in range(1, 11)],
    ),
    "DS": (
        "distribution",
        "distribution_partner",
        [f"Distribution Partner {i:02}" for i in range(1, 11)],
    ),
}


def one(model: type[Any], **where: Any) -> Any | None:
    return db.session.execute(select(model).filter_by(**where)).scalar_one_or_none()


def remember(stats: dict[str, int], key: str, created: bool) -> None:
    stats[f"{key}_{'created' if created else 'existing'}"] = (
        stats.get(f"{key}_{'created' if created else 'existing'}", 0) + 1
    )


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


def role(code: str) -> Role:
    row = one(Role, code=code)
    if row is None:
        raise RuntimeError(f"Required role missing: {code}")
    return row


def seed_references(stats: dict[str, int]) -> dict[str, City]:
    country = ensure(
        Country,
        stats,
        "country",
        iso2="PK",
        defaults={"name": "Pakistan", "currency_code": "PKR", "phone_prefix": "+92"},
    )
    db.session.flush()
    cities: dict[str, City] = {}
    provinces = {
        "Lahore": "Punjab",
        "Karachi": "Sindh",
        "Islamabad": "ICT",
        "Gwadar": "Balochistan",
        "Rawalpindi": "Punjab",
        "Bahawalpur": "Punjab",
    }
    for name, province in provinces.items():
        city = ensure(
            City,
            stats,
            "city",
            name=name,
            country_id=country.id,
            defaults={
                "public_id": f"DEMO-CITY-{name.upper().replace(' ', '-')}",
                "province": province,
                "timezone": "Asia/Karachi",
                "active": True,
            },
        )
        cities[name] = city
    for idx, (category, name) in enumerate(
        [
            ("acting", "Lead performance"),
            ("acting", "Drama dialogue"),
            ("model", "Commercial modeling"),
            ("crew", "Assistant direction"),
            ("crew", "Location sound"),
            ("camera", "Drone operation"),
            ("production", "Production coordination"),
            ("location", "Location management"),
            ("post", "Distribution delivery"),
            ("safety", "Set safety"),
        ],
        start=1,
    ):
        ensure(
            Skill,
            stats,
            "skill",
            public_id=f"DEMO-SKILL-{idx:03}",
            defaults={"category": category, "name": name, "active": True},
        )
    return cities


def seed_users(stats: dict[str, int]) -> dict[str, list[User]]:
    grouped: dict[str, list[User]] = {}
    for prefix, (email_prefix, role_code, names) in USER_GROUPS.items():
        grouped[prefix] = []
        for idx, name in enumerate(names, start=1):
            public_id = f"DEMO-{prefix}-{idx:03}"
            email = (
                f"demo.admin@{DEMO_EMAIL_DOMAIN}"
                if prefix == "ADMIN"
                else f"{email_prefix}{idx:02}@{DEMO_EMAIL_DOMAIN}"
            )
            user = ensure(
                User,
                stats,
                "user",
                public_id=public_id,
                defaults={
                    "email": email,
                    "password_hash": hash_password(DEFAULT_PASSWORD),
                    "display_name": name,
                    "status": "active",
                    "email_verified_at": NOW,
                    "terms_version": "2026-07",
                    "terms_accepted_at": NOW,
                },
            )
            user.email = email
            user.display_name = name
            user.status = "active"
            user.email_verified_at = user.email_verified_at or NOW
            db.session.flush()
            grouped[prefix].append(user)
            user_role = ensure(
                UserRole,
                stats,
                "user_role",
                user_id=user.id,
                role_id=role(role_code).id,
                defaults={"status": "active", "is_primary": True, "approved_at": NOW},
            )
            user_role.status = "active"
            user_role.is_primary = True
            user_role.approved_at = user_role.approved_at or NOW
            ensure(
                UserSettings,
                stats,
                "user_settings",
                user_id=user.id,
                defaults={
                    "timezone": "Asia/Karachi",
                    "locale": "en-PK",
                    "active_role_code": role_code,
                },
            )
            ensure(
                NotificationPreference,
                stats,
                "notification_pref",
                user_id=user.id,
                defaults={
                    "email_enabled": True,
                    "sms_enabled": False,
                    "push_enabled": True,
                },
            )
    return grouped


def seed_files(
    stats: dict[str, int], users: dict[str, list[User]]
) -> dict[str, FileAsset]:
    owner_cycle = users["AT"] + users["DP"] + users["LO"] + users["ME"] + users["BR"]
    files: dict[str, FileAsset] = {}
    groups = [
        ("KYC", 30, "application/pdf"),
        ("PORTFOLIO", 30, "image/jpeg"),
        ("SHOWREEL", 10, "video/mp4"),
        ("PROJECT", 20, "application/pdf"),
        ("LOCATION", 30, "image/jpeg"),
        ("EQUIPMENT", 30, "image/jpeg"),
        ("PAYMENT", 20, "application/pdf"),
        ("INSURANCE", 20, "image/jpeg"),
        ("BRAND", 20, "image/jpeg"),
        ("DISTRIBUTION", 10, "text/csv"),
    ]
    n = 0
    for group, count, mime in groups:
        for idx in range(1, count + 1):
            n += 1
            public_id = f"DEMO-FILE-{group}-{idx:03}"
            owner = owner_cycle[(n - 1) % len(owner_cycle)]
            file = ensure(
                FileAsset,
                stats,
                "file",
                public_id=public_id,
                defaults={
                    "owner_user_id": owner.id,
                    "storage_key": f"demo/{SEED_BATCH}/{group.lower()}-{idx:03}",
                    "bucket": "cineconnect-private",
                    "mime_type": mime,
                    "size_bytes": 64_000 + idx,
                    "checksum_sha256": f"{idx:064x}"[-64:],
                    "visibility": "private",
                    "scan_status": "clean",
                    "processing_status": "ready",
                    "original_name": f"{public_id.lower()}.{mime.split('/')[-1].replace('jpeg', 'jpg')}",
                },
            )
            files[public_id] = file
    return files


def seed_profiles_and_kyc(
    stats: dict[str, int],
    users: dict[str, list[User]],
    cities: dict[str, City],
    files: dict[str, FileAsset],
) -> dict[str, Any]:
    ctx: dict[str, Any] = {"talent_profiles": [], "listings": []}
    all_groups = [u for group in users.values() for u in group]
    for idx, user in enumerate(all_groups, start=1):
        city = cities[BACKBONE[(idx - 1) % 10].city]
        ensure(
            UserProfile,
            stats,
            "profile",
            user_id=user.id,
            defaults={
                "bio": f"Demo profile seeded for {SEED_BATCH}.",
                "city_id": city.id,
                "profile_visibility": "public",
            },
        )
        if idx <= 60:
            kyc_role = user.roles[0].role
            kyc = ensure(
                KycSubmission,
                stats,
                "kyc",
                public_id=f"DEMO-KYC-{idx:03}",
                defaults={
                    "user_id": user.id,
                    "role_id": kyc_role.id,
                    "status": "approved" if idx % 5 != 0 else "submitted",
                    "risk_level": "low" if idx % 7 else "medium",
                    "submitted_at": NOW - timedelta(days=20 - idx % 10),
                    "decision_at": NOW - timedelta(days=10 - idx % 5)
                    if idx % 5 != 0
                    else None,
                    "decision_reason": "Demo approval" if idx % 5 != 0 else None,
                },
            )
            ensure(
                VerificationEvent,
                stats,
                "verification_event",
                submission_id=kyc.id,
                to_status=kyc.status,
                defaults={
                    "actor_user_id": users["ADMIN"][0].id,
                    "from_status": "submitted",
                    "reason": "Demo seed status",
                    "metadata_json": {"seed_batch": SEED_BATCH, "is_demo": True},
                },
            )
            for doc_idx, doc_type in enumerate(
                ["id_front", "id_back", "selfie"], start=1
            ):
                ensure(
                    KycDocument,
                    stats,
                    "kyc_doc",
                    submission_id=kyc.id,
                    document_type=doc_type,
                    defaults={
                        "file_id": files[
                            f"DEMO-FILE-KYC-{((idx + doc_idx - 2) % 30) + 1:03}"
                        ].id,
                        "country": "PK",
                        "document_number_encrypted": f"demo-token-{idx:03}-{doc_idx}",
                        "expires_on": date(2030, 12, 31),
                        "status": "approved" if kyc.status == "approved" else "pending",
                    },
                )

    for idx, user in enumerate(users["AT"], start=1):
        b = BACKBONE[idx - 1]
        talent = ensure(
            TalentProfile,
            stats,
            "talent_profile",
            public_id=f"DEMO-TAL-{idx:03}",
            defaults={
                "user_id": user.id,
                "screen_name": b.talent,
                "age_range": "25-35",
                "gender_identity": "Not specified",
                "experience_years": 3 + idx,
                "availability_status": "available",
                "day_rate_minor": (70_000 + idx * 8_000) * 100,
                "currency": "PKR",
            },
        )
        ctx["talent_profiles"].append(talent)
        for lang in ["Urdu", "English"]:
            ensure(
                TalentLanguage,
                stats,
                "talent_language",
                talent_profile_id=talent.id,
                language=lang,
                defaults={"proficiency": "fluent"},
            )
        for item_idx in range(1, 4):
            ensure(
                PortfolioItem,
                stats,
                "portfolio",
                public_id=f"DEMO-PORT-AT-{idx:03}-{item_idx}",
                defaults={
                    "owner_user_id": user.id,
                    "profile_type": "talent",
                    "profile_id": talent.public_id,
                    "title": f"{b.talent} demo scene {item_idx}",
                    "category": "showreel" if item_idx == 3 else "portrait",
                    "file_id": files[
                        f"DEMO-FILE-PORTFOLIO-{((idx * 3 + item_idx - 4) % 30) + 1:03}"
                    ].id,
                    "duration_seconds": 90 if item_idx == 3 else None,
                    "status": "published",
                    "is_cover": item_idx == 1,
                    "sort_order": item_idx,
                    "moderation_status": "approved",
                },
            )
        listing = ensure(
            MarketplaceListing,
            stats,
            "listing",
            public_id=f"DEMO-LST-AT-{idx:03}",
            defaults={
                "owner_user_id": user.id,
                "listing_type": "talent",
                "profile_entity_id": talent.public_id,
                "title": f"{b.talent} · {b.title}",
                "summary": f"{b.talent} is available for {b.project_type.lower()} and campaign bookings.",
                "city_id": cities[b.city].id,
                "price_from_minor": talent.day_rate_minor,
                "currency": "PKR",
                "verification_status": "approved",
                "moderation_status": "approved",
                "visibility": "public",
                "published_at": NOW - timedelta(days=idx),
            },
        )
        ctx["listings"].append(listing)
        ensure(
            ListingMedia,
            stats,
            "listing_media",
            listing_id=listing.id,
            file_id=files[f"DEMO-FILE-PORTFOLIO-{((idx - 1) % 30) + 1:03}"].id,
            defaults={"sort_order": 1, "is_cover": True, "caption": "Demo cover"},
        )

    for idx, user in enumerate(users["MD"], start=1):
        b = BACKBONE[idx - 1]
        talent = ensure(
            TalentProfile,
            stats,
            "model_backing_talent",
            public_id=f"DEMO-TAL-MD-{idx:03}",
            defaults={
                "user_id": user.id,
                "screen_name": f"Model {idx:02} · {b.brand}",
                "age_range": "22-32",
                "gender_identity": "Not specified",
                "experience_years": 2 + idx,
                "availability_status": "available",
                "day_rate_minor": (95_000 + idx * 9_000) * 100,
                "currency": "PKR",
            },
        )
        model = ensure(
            ModelProfile,
            stats,
            "model_profile",
            public_id=f"DEMO-MOD-{idx:03}",
            defaults={
                "user_id": user.id,
                "talent_profile_id": talent.id,
                "brand_safety_notes": "No tobacco or political endorsements in demo seed.",
                "public_visibility": True,
            },
        )
        for cat in ["beauty", "fashion", "ecommerce"]:
            ensure(
                ModelCampaignCategory,
                stats,
                "model_category",
                model_profile_id=model.id,
                category=cat,
                defaults={"selected": True},
            )
        ensure(
            ModelUsageRight,
            stats,
            "model_usage_right",
            public_id=f"DEMO-MUR-{idx:03}",
            defaults={
                "model_profile_id": model.id,
                "platform": "social",
                "territory": "Pakistan",
                "duration_months": 6,
                "exclusive": False,
                "status": "active",
            },
        )
        ensure(
            ModelUsageRate,
            stats,
            "model_usage_rate",
            public_id=f"DEMO-MRATE-{idx:03}",
            defaults={
                "model_profile_id": model.id,
                "label": "Social campaign usage",
                "scope": f"{b.brand} demo rights",
                "amount_minor": (120_000 + idx * 10_000) * 100,
                "currency": "PKR",
                "requires_review": False,
                "negotiable": True,
            },
        )
        ensure(
            ModelRestrictedCategory,
            stats,
            "model_restriction",
            model_profile_id=model.id,
            category="tobacco",
            defaults={"blocked": True, "reason": "Demo brand-safety restriction"},
        )

    return ctx


def seed_projects(
    stats: dict[str, int],
    users: dict[str, list[User]],
    cities: dict[str, City],
    files: dict[str, FileAsset],
    listings: list[MarketplaceListing],
) -> dict[str, Any]:
    ctx: dict[str, Any] = {"projects": [], "requirements": [], "shortlists": []}
    skills = (
        db.session.execute(select(Skill).where(Skill.public_id.like("DEMO-SKILL-%")))
        .scalars()
        .all()
    )
    for idx, b in enumerate(BACKBONE, start=1):
        owner = users["DP"][idx - 1]
        project = ensure(
            Project,
            stats,
            "project",
            public_id=b.project_id,
            defaults={
                "owner_user_id": owner.id,
                "title": b.title,
                "project_type": b.project_type.lower().replace(" ", "_"),
                "description": f"{b.title} demo backbone project for {SEED_BATCH}.",
                "city_id": cities[b.city].id,
                "start_date": BASE_DAY + timedelta(days=idx * 4),
                "end_date": BASE_DAY + timedelta(days=idx * 4 + 5),
                "status": b.status,
                "estimated_budget_minor": (1_200_000 + idx * 250_000) * 100,
                "currency": "PKR",
                "visibility": "team",
                "progress_percent": min(90, idx * 8),
            },
        )
        ctx["projects"].append(project)
        for user, label in [(owner, "Producer"), (users["AT"][idx - 1], "Hero talent")]:
            ensure(
                ProjectMember,
                stats,
                "project_member",
                project_id=project.id,
                user_id=user.id,
                defaults={
                    "role_label": label,
                    "permissions_json": json.dumps(["view", "comment"]),
                    "status": "active",
                },
            )
        for req_idx, category in enumerate(
            ["actor_talent", "crew_service", "equipment_provider"], start=1
        ):
            req = ensure(
                ProjectRequirement,
                stats,
                "requirement",
                public_id=f"DEMO-REQ-{idx:03}-{req_idx}",
                defaults={
                    "project_id": project.id,
                    "category": category,
                    "title": f"{b.title} {category.replace('_', ' ')} need",
                    "summary": f"Seeded requirement for {b.title}.",
                    "budget_min_minor": (60_000 + idx * 5_000) * 100,
                    "budget_max_minor": (180_000 + idx * 10_000) * 100,
                    "currency": "PKR",
                    "start_date": project.start_date,
                    "end_date": project.end_date,
                    "status": "open" if req_idx != 3 else "shortlisting",
                    "candidate_count_cache": 2 + req_idx,
                },
            )
            ctx["requirements"].append(req)
            if skills:
                ensure(
                    RequirementSkill,
                    stats,
                    "requirement_skill",
                    requirement_id=req.id,
                    skill_id=skills[(idx + req_idx - 2) % len(skills)].id,
                    defaults={"required": True, "minimum_level": "mid"},
                )
        for room_idx, title in enumerate(
            ["Creative brief locked", "Casting note", "Schedule decision"], start=1
        ):
            ensure(
                ProjectRoomItem,
                stats,
                "room_item",
                public_id=f"DEMO-ROOM-{idx:03}-{room_idx}",
                defaults={
                    "project_id": project.id,
                    "item_type": "decision" if room_idx == 1 else "note",
                    "title": f"{b.title}: {title}",
                    "body": "Seeded project-room item for demo walkthrough.",
                    "created_by": owner.id,
                    "pinned_at": NOW if room_idx == 1 else None,
                },
            )
        for file_idx in range(1, 3):
            ensure(
                ProjectFile,
                stats,
                "project_file",
                public_id=f"DEMO-PFILE-{idx:03}-{file_idx}",
                defaults={
                    "project_id": project.id,
                    "file_id": files[
                        f"DEMO-FILE-PROJECT-{((idx * 2 + file_idx - 3) % 20) + 1:03}"
                    ].id,
                    "folder": "briefs",
                    "label": f"{b.title} file {file_idx}",
                    "uploaded_by": owner.id,
                    "visibility": "project_members",
                    "sort_order": file_idx,
                },
            )
        saved = ensure(
            SavedSearch,
            stats,
            "saved_search",
            public_id=f"DEMO-SSRCH-{idx:03}",
            defaults={
                "owner_user_id": owner.id,
                "name": f"{b.city} talent for {b.title}",
                "listing_type": "talent",
                "city_id": cities[b.city].id,
                "query_text": b.talent.split()[0],
                "filters_json": json.dumps({"seed_batch": SEED_BATCH, "is_demo": True}),
                "notify_enabled": True,
            },
        )
        shortlist = ensure(
            Shortlist,
            stats,
            "shortlist",
            public_id=f"DEMO-SHL-{idx:03}",
            defaults={
                "project_id": project.public_id,
                "requirement_id": ctx["requirements"][-3].public_id,
                "created_by": owner.id,
                "name": f"{b.title} shortlist",
            },
        )
        ctx["shortlists"].append(shortlist)
        for rank, listing in enumerate(
            [listings[idx - 1], listings[idx % len(listings)]], start=1
        ):
            ensure(
                ShortlistItem,
                stats,
                "shortlist_item",
                public_id=f"DEMO-SHLI-{idx:03}-{rank}",
                defaults={
                    "shortlist_id": shortlist.id,
                    "listing_id": listing.id,
                    "candidate_user_id": listing.owner_user_id,
                    "rank": rank,
                    "notes": f"Seeded from {saved.name}",
                    "status": "active",
                },
            )
    return ctx


def seed_provider_foundations(
    stats: dict[str, int],
    users: dict[str, list[User]],
    cities: dict[str, City],
) -> None:
    for idx, b in enumerate(BACKBONE, start=1):
        loc = ensure(
            LocationProperty,
            stats,
            "location_property",
            public_id=f"DEMO-LOC-{idx:03}",
            defaults={
                "owner_user_id": users["LO"][idx - 1].id,
                "name": b.location,
                "property_type": "studio" if "Studio" in b.location else "location",
                "city_id": cities[b.city].id,
                "area_name": b.location.split()[0],
                "public_address": f"{b.location}, {b.city}",
                "private_address_token": f"demo-location-token-{idx:03}",
                "description": f"{b.location} seeded for {b.title}.",
                "capacity": 20 + idx * 2,
                "parking_spaces": 3 + idx,
                "power_backup": idx % 2 == 0,
                "accessible": True,
                "rating_average": 4,
                "status": "published",
            },
        )
        ensure(
            LocationSpace,
            stats,
            "location_space",
            public_id=f"DEMO-LSP-{idx:03}-1",
            defaults={
                "property_id": loc.id,
                "name": "Main shoot area",
                "space_type": "interior",
                "capacity": 18 + idx,
                "area_sqft": 900 + idx * 120,
                "description": "Seeded demo shoot space",
            },
        )
        ensure(
            LocationPricing,
            stats,
            "location_pricing",
            public_id=f"DEMO-LPR-{idx:03}-1",
            defaults={
                "property_id": loc.id,
                "label": "Day shoot",
                "amount_minor": (100_000 + idx * 10_000) * 100,
                "currency": "PKR",
                "unit": "day",
                "enabled": True,
                "conditions": "Demo seeded day rate",
            },
        )
        ensure(
            LocationRule,
            stats,
            "location_rule",
            public_id=f"DEMO-LRU-{idx:03}-1",
            defaults={
                "property_id": loc.id,
                "rule_type": "noise",
                "label": "Night noise by approval only",
                "note": "Demo restriction",
                "allowed": False,
            },
        )

        epp = ensure(
            EquipmentProviderProfile,
            stats,
            "equipment_profile",
            public_id=f"DEMO-EPP-{idx:03}",
            defaults={
                "user_id": users["ME"][idx - 1].id,
                "name": f"{b.equipment_package} Rentals",
                "provider_type": "rental_house",
                "city_id": cities[b.city].id,
                "coverage": b.city,
                "service_categories": "Camera, Lens, Light, Audio",
                "bio": f"Seeded provider for {b.equipment_package}.",
                "rating_average": 4,
                "verification_status": "approved",
            },
        )
        item_ids = []
        for item_idx, (category, brand) in enumerate(
            [("Camera", "ARRI"), ("Lens", "Cooke"), ("Light", "Aputure")], start=1
        ):
            item = ensure(
                EquipmentItem,
                stats,
                "equipment_item",
                public_id=f"DEMO-EQ-{idx:03}-{item_idx}",
                defaults={
                    "provider_profile_id": epp.id,
                    "category": category,
                    "brand": brand,
                    "model_name": f"{b.equipment_package} {category} {item_idx}",
                    "serial_token": f"demo-serial-{idx:03}-{item_idx}",
                    "condition": "excellent",
                    "day_rate_minor": (35_000 + item_idx * 8_000) * 100,
                    "deposit_minor": (100_000 + item_idx * 20_000) * 100,
                    "currency": "PKR",
                    "city_id": cities[b.city].id,
                    "status": "available",
                },
            )
            item_ids.append(item)
        pkg = ensure(
            EquipmentPackage,
            stats,
            "equipment_package",
            public_id=f"DEMO-ME-PKG-{idx:03}",
            defaults={
                "provider_profile_id": epp.id,
                "name": b.equipment_package,
                "description": f"Seeded package for {b.title}.",
                "operator_included": idx % 2 == 1,
                "price_minor": (160_000 + idx * 15_000) * 100,
                "currency": "PKR",
                "terms": "Demo package terms",
                "status": "published",
            },
        )
        for item in item_ids:
            ensure(
                EquipmentPackageItem,
                stats,
                "equipment_package_item",
                package_id=pkg.id,
                equipment_item_id=item.id,
                defaults={"quantity": 1, "required": True},
            )
        ensure(
            EquipmentTerm,
            stats,
            "equipment_term",
            public_id=f"DEMO-ETM-{idx:03}-1",
            defaults={
                "provider_profile_id": epp.id,
                "label": "Damage deposit",
                "note": "Refundable after return check",
                "amount_minor": 75_000 * 100,
                "currency": "PKR",
                "enabled": True,
                "term_type": "deposit",
            },
        )

        ensure(
            CastingAgency,
            stats,
            "casting_agency_profile",
            public_id=f"DEMO-AGY-{idx:03}",
            defaults={
                "owner_user_id": users["CA"][idx - 1].id,
                "name": users["CA"][idx - 1].display_name,
                "city_id": cities[b.city].id,
                "commission_bps": 1000 + idx * 25,
                "verification_status": "approved",
            },
        )
        agency = one(CastingAgency, public_id=f"DEMO-AGY-{idx:03}")
        talent = one(TalentProfile, public_id=f"DEMO-TAL-{idx:03}")
        if agency and talent:
            ensure(
                AgencyTalent,
                stats,
                "agency_talent",
                agency_id=agency.id,
                talent_profile_id=talent.id,
                defaults={
                    "representation_type": "non_exclusive",
                    "start_date": BASE_DAY,
                    "commission_bps": 1000,
                    "status": "active",
                },
            )
        ensure(
            BrandProfile,
            stats,
            "brand_profile",
            public_id=f"DEMO-BRD-{idx:03}",
            defaults={
                "owner_user_id": users["BR"][idx - 1].id,
                "name": b.brand,
                "category": "consumer",
                "representative": users["BR"][idx - 1].display_name,
                "billing_token": f"demo-billing-{idx:03}",
                "trust_status": "approved",
                "description": f"{b.brand} seeded brand profile.",
            },
        )
        ensure(
            DistributionPartnerProfile,
            stats,
            "distribution_profile",
            public_id=f"DEMO-DSTP-{idx:03}",
            defaults={
                "user_id": users["DS"][idx - 1].id,
                "name": f"{b.brand} Distribution Desk",
                "channels": "OTT,theatrical,social",
                "territories": "Pakistan,GCC,UK",
                "status": "approved",
            },
        )
        partner = one(DistributionPartnerProfile, public_id=f"DEMO-DSTP-{idx:03}")
        project = one(Project, public_id=b.project_id)
        if partner and project:
            dproj = ensure(
                DistributionProject,
                stats,
                "distribution_project",
                public_id=f"DEMO-DPR-{idx:03}",
                defaults={
                    "project_id": project.id,
                    "partner_profile_id": partner.id,
                    "release_window_start": BASE_DAY + timedelta(days=idx * 8),
                    "release_window_end": BASE_DAY + timedelta(days=idx * 8 + 30),
                    "territories": "Pakistan,GCC",
                    "missing_items": "Final poster" if idx % 3 == 0 else None,
                    "status_note": "Seeded release coordination",
                    "status": "onboarding",
                },
            )
            for contact_idx in range(1, 3):
                ensure(
                    DistributorContact,
                    stats,
                    "distributor_contact",
                    public_id=f"DEMO-DCT-{idx:03}-{contact_idx}",
                    defaults={
                        "partner_profile_id": partner.id,
                        "name": f"{b.brand} Buyer {contact_idx}",
                        "channel": "OTT" if contact_idx == 1 else "Theatrical",
                        "territory": "Pakistan" if contact_idx == 1 else "GCC",
                        "contact_role": "Acquisitions",
                        "email_token": f"demo-contact-{idx:03}-{contact_idx}",
                        "phone_token": f"demo-phone-{idx:03}-{contact_idx}",
                        "prior_project": b.title,
                        "notes": f"Linked to {dproj.public_id}",
                        "status": "active",
                    },
                )


def seed_availability(stats: dict[str, int], users: dict[str, list[User]]) -> None:
    for group in ["AT", "CR"]:
        for idx, user in enumerate(users[group], start=1):
            calendar = ensure(
                AvailabilityCalendar,
                stats,
                "availability_calendar",
                owner_type="user",
                owner_id=user.public_id,
                defaults={
                    "public_id": f"DEMO-CAL-{group}-{idx:03}",
                    "timezone": "Asia/Karachi",
                },
            )
            for entry_idx, status in enumerate(
                ["available", "hold", "blocked"], start=1
            ):
                start = datetime(2026, 8, idx + entry_idx, 9, tzinfo=UTC)
                ensure(
                    AvailabilityEntry,
                    stats,
                    "availability_entry",
                    public_id=f"DEMO-AVL-{group}-{idx:03}-{entry_idx}",
                    defaults={
                        "calendar_id": calendar.id,
                        "resource_type": "user",
                        "resource_id": user.public_id,
                        "start_at": start,
                        "end_at": start + timedelta(hours=8),
                        "status": status,
                        "note": f"{SEED_BATCH} {status}",
                    },
                )


def write_credentials(users: dict[str, list[User]]) -> None:
    out = Path(
        os.getenv(
            "CINECONNECT_DEMO_HANDOFF_PATH", "docs/CINECONNECT_DEMO_LOGIN_HANDOFF.json"
        )
    )
    out.parent.mkdir(parents=True, exist_ok=True)
    rows = []
    for group, group_users in users.items():
        role_code = USER_GROUPS[group][1]
        for user in group_users:
            rows.append(
                {
                    "public_id": user.public_id,
                    "email": user.email,
                    "password": DEFAULT_PASSWORD,
                    "role": role_code,
                    "display_name": user.display_name,
                }
            )
    out.write_text(
        json.dumps(
            {
                "seed_batch": SEED_BATCH,
                "generated_at": NOW.isoformat(),
                "accounts": rows,
            },
            indent=2,
        )
        + "\n"
    )


def main() -> None:
    app = create_app()
    stats: dict[str, int] = {}
    with app.app_context():
        cities = seed_references(stats)
        users = seed_users(stats)
        db.session.flush()
        files = seed_files(stats, users)
        db.session.flush()
        profile_ctx = seed_profiles_and_kyc(stats, users, cities, files)
        db.session.flush()
        seed_projects(stats, users, cities, files, profile_ctx["listings"])
        db.session.flush()
        seed_provider_foundations(stats, users, cities)
        seed_availability(stats, users)
        db.session.commit()
        write_credentials(users)
    print(
        json.dumps(
            {"seed_batch": SEED_BATCH, "stats": dict(sorted(stats.items()))}, indent=2
        )
    )


if __name__ == "__main__":
    main()
