from __future__ import annotations

import base64
import hashlib
import json
import os
import re
import zlib
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any

from flask import current_app
from sqlalchemy import delete, select

from app import create_app
from app.api.cineplanner import _call_sheet_payload
from app.extensions import db
from app.models.base import utc_now
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
    CineScriptVersion,
    CineShootDay,
)
from app.models.files import FileAsset
from app.models.identity import Role, User, UserRole, UserSettings
from app.security import hash_password
from app.services.cineplanner_ai import STAGES, _materialize
from app.services.cineplanner_budget import recalculate_budget
from app.services.cineplanner_scheduling import (
    apply_schedule_plan,
    build_schedule_plan,
    detect_conflicts,
)

DEMO_EMAIL = "cineplanner.demo@demo.cine.nalexustechnologies.com"
DEMO_PASSWORD = os.getenv("CINEPLANNER_DEMO_PASSWORD", "CinePlannerDemo@2026!")
DEMO_USER_ID = "DEMO-CINEPLANNER-USER"
DEMO_PRODUCTION_ID = "DEMO-CINEPLANNER-001"
DEMO_FILE_ID = "DEMO-CINEPLANNER-FILE"
DEMO_SCRIPT_ID = "DEMO-CINEPLANNER-SCRIPT"
DEMO_JOB_ID = "DEMO-CINEPLANNER-JOB"
SEED_BATCH = "cineplanner-frontend-demo-2026-08"
DEMO_PDF_NAME = "CinePlanner_Roman_Urdu_Demo_Screenplay.pdf"
DEMO_PDF_PATH = Path(
    os.getenv(
        "CINEPLANNER_DEMO_SCREENPLAY_PATH",
        str(Path(__file__).resolve().parents[2] / "demo" / DEMO_PDF_NAME),
    )
)

CHARACTERS: dict[str, dict[str, Any]] = {
    "AYAAN": {
        "classification": "lead",
        "playing_age": "28-35",
        "description": "Accountant and whistleblower carrying the Project Raakh data.",
        "skills": ["Dramatic acting", "Screen fighting", "Stunt driving"],
    },
    "ZARA": {
        "classification": "lead",
        "playing_age": "26-33",
        "description": "Investigative journalist who takes the evidence public.",
        "skills": ["Dramatic acting", "Presenting", "Action performance"],
    },
    "FARAZ": {
        "classification": "lead",
        "playing_age": "35-43",
        "description": "Inspector who risks his career to protect the investigation.",
        "skills": ["Dramatic acting", "Screen fighting", "Police procedure"],
    },
    "BILAL": {
        "classification": "supporting",
        "playing_age": "24-30",
        "description": "Tech reporter who decrypts and preserves the evidence.",
        "skills": ["Dramatic acting", "Technical business", "Injury continuity"],
    },
    "SHAYAN": {
        "classification": "supporting",
        "playing_age": "42-50",
        "description": "Corporate antagonist behind the charity-fund operation.",
        "skills": ["Dramatic acting", "Public speaking"],
    },
    "KAMRAN": {
        "classification": "supporting",
        "playing_age": "37-45",
        "description": "Shayan's security chief and principal physical threat.",
        "skills": ["Screen fighting", "Weapons handling", "Stunt driving"],
    },
    "MEHWISH": {
        "classification": "supporting",
        "playing_age": "31-38",
        "description": "News producer coordinating the live evidence broadcast.",
        "skills": ["Dramatic acting", "Newsroom business"],
    },
    "DADI AMNA": {
        "classification": "minor",
        "playing_age": "65-72",
        "description": "Ayaan's perceptive grandmother.",
        "skills": ["Dramatic acting"],
    },
    "DR. SANA": {
        "classification": "minor",
        "playing_age": "30-37",
        "description": "Private-hospital doctor treating Bilal.",
        "skills": ["Dramatic acting", "Medical business"],
    },
    "DSP RANA": {
        "classification": "minor",
        "playing_age": "49-57",
        "description": "Senior police officer overseeing Faraz's inquiry.",
        "skills": ["Dramatic acting", "Police procedure"],
    },
    "TECHNICIAN": {
        "classification": "minor",
        "playing_age": "22-45",
        "description": "Gala AV technician who locks the evidence feed.",
        "skills": ["Technical business"],
    },
}

ELEMENT_CATALOG: dict[str, list[tuple[str, tuple[str, ...]]]] = {
    "props": [
        ("USB drive", ("USB",)),
        ("Cracked-screen mobile phone", ("MOBILE PHONE", "cracked-screen phone")),
        ("Silver watch", ("silver WATCH",)),
        ("External hard drive", ("HARD DRIVE", "hard drive")),
        ("Red evidence file", ("RED FILE", "red file")),
        ("Police ID wallet", ("police ID wallet",)),
        ("City map", ("CITY MAP", "city map")),
        ("Police radio scanner", ("RADIO scanner", "radio uthata")),
        ("Evidence bags", ("evidence bags",)),
        ("Fire extinguisher", ("fire extinguisher",)),
    ],
    "wardrobe": [
        ("Ayaan blue shirt and grey trousers", ("neeli shirt", "blue shirt")),
        ("Zara red shawl and black kurta", ("red shawl", "black kurta")),
        ("Ayaan black hoodie", ("black hoodie",)),
        ("Zara beige shawl and gala dress", ("beige shawl", "dark green formal")),
        ("Catering staff uniform", ("catering staff uniform",)),
        ("Faraz maintenance uniform", ("maintenance uniform",)),
        ("Police uniform and service kit", ("Faraz uniform", "service weapon")),
        ("Shayan gala tuxedo", ("tuxedo",)),
    ],
    "makeup": [
        ("Ayaan eyebrow wound progression", ("eyebrow",)),
        ("Bilal shoulder graze and sling", ("shoulder", "sling")),
        ("Kamran bruising and ankle injury", ("bruised face", "ankle injury")),
        ("Rain and wet-look continuity", ("Heavy rain", "rain water", "Wet road")),
    ],
    "vehicles": [
        ("Black Corolla", ("COROLLA", "Corolla")),
        ("White surveillance van", ("WHITE VAN", "White van")),
        ("Picture motorcycle", ("MOTORBIKE", "bike rider")),
        ("Unmarked blue sedan", ("BLUE SEDAN", "Blue sedan", "blue sedan")),
        ("Black SUV", ("BLACK SUV", "Black SUV", "black SUV")),
        ("Delivery trucks", ("delivery trucks",)),
        ("Police patrol cars", ("patrol cars",)),
        ("Picture ambulance", ("ambulance",)),
    ],
    "extras": [
        ("Newsroom staff", ("Busy digital newsroom", "newsroom phir busy")),
        ("Old City market crowd", ("market shoppers", "Vendors, rickshaws")),
        ("Hospital staff and patients", ("nurses", "patients/attendants")),
        ("Charity gala guests", ("gala guests", "Guests murmur")),
        (
            "Gala media, valet and security",
            ("valet staff", "media crew", "Security Zara"),
        ),
        ("Police officers and paramedics", ("police officers", "paramedics")),
    ],
    "stunts": [
        ("Newsroom stairwell fight", ("HAND-TO-HAND FIGHT",)),
        ("Textile mill gunfight", ("3 GUNSHOTS",)),
        ("Textile mill machine-floor fight", ("controlled fall",)),
        ("Industrial road car chase", ("CAR CHASE",)),
        ("Industrial bridge vehicle impact", ("bridge barrier",)),
        ("Gala server-room fight", ("wall se push", "Short fight")),
        ("Hotel exit-ramp chase", ("barrier tod", "second vehicle chase")),
        ("River warehouse fight", ("Intense fight",)),
    ],
    "vfx": [
        ("Industrial bridge impact enhancement", ("VFX may enhance impact",)),
        ("Gala transaction graphics playback", ("VFX/graphics playback",)),
        ("Newsroom investigation-map animation", ("investigation points glow",)),
        ("Optional sparks and smoke enhancement", ("VFX enhancement optional",)),
    ],
    "sfx": [
        ("Practical rain and wet-down", ("RAIN MACHINE", "rain starts", "tez baarish")),
        ("Gunshots and breakaway glass", ("GUNSHOTS", "BREAKAWAY GLASS")),
        ("Fire-suppression mist", ("suppression mist",)),
        ("Electrical sparks and smoke", ("ELECTRICAL POP", "controlled sparks")),
        ("Radio jammer and alarm effects", ("radio jammer", "SFX: alarm")),
        ("Breakaway hotel barrier", ("breakaway barrier",)),
    ],
    "equipment": [
        ("Drone and vehicle camera rig", ("Drone/vehicle rig",)),
        ("LED wall and graphics playback", ("LED screen", "LED wall")),
        ("News camera package", ("camera crew", "media cameras")),
        ("Rain covers and wet-weather sound kit", ("baarish", "rain", "wet")),
        ("Encrypted-data playback kit", ("encrypted drive", "portable adapter")),
    ],
}


def _next_monday() -> date:
    candidate = date.today() + timedelta(days=10)
    return candidate + timedelta(days=(7 - candidate.weekday()) % 7)


def _pdf_unescape(value: bytes) -> str:
    text = value.decode("latin-1", "replace")
    text = re.sub(
        r"\\([0-7]{1,3})",
        lambda match: chr(int(match.group(1), 8)),
        text,
    )
    return (
        text.replace(r"\n", "\n")
        .replace(r"\r", "\r")
        .replace(r"\t", "\t")
        .replace(r"\(", "(")
        .replace(r"\)", ")")
        .replace(r"\\", "\\")
    )


def _pdf_text_lines(content: bytes) -> list[str]:
    lines: list[str] = []
    for match in re.finditer(rb"stream\r?\n(.*?)endstream", content, re.S):
        raw = match.group(1).strip()
        try:
            decoded = zlib.decompress(base64.a85decode(b"<~" + raw, adobe=True))
        except (ValueError, zlib.error):
            continue
        for token in re.findall(rb"\(((?:\\.|[^\\)])*)\)\s*Tj", decoded):
            text = _pdf_unescape(token).strip()
            if text:
                lines.append(text)
    return lines


def _story_day(scene_number: int) -> str:
    if scene_number <= 33:
        return "Day 1"
    if scene_number <= 56:
        return "Day 2"
    return "Day 3"


def _element_names(category: str, text: str) -> list[str]:
    return [
        name
        for name, keywords in ELEMENT_CATALOG[category]
        if any(keyword.casefold() in text.casefold() for keyword in keywords)
    ]


def _continuity_notes(number: int) -> str:
    notes: list[str] = []
    if number <= 18:
        notes.append("Track Zara's red shawl and black kurta continuity.")
    if 12 <= number <= 43:
        notes.append("Track Ayaan's eyebrow cut, blood level, and bandage progression.")
    if 26 <= number <= 57:
        notes.append("Track Bilal's right-shoulder graze, torn shirt, and sling.")
    if 38 <= number <= 56:
        notes.append("Maintain charity-gala wardrobe and evidence-drive continuity.")
    if number >= 57:
        notes.append("Day 3 injuries are healing; use reduced wound makeup.")
    return " ".join(notes) or "Maintain screenplay story-day continuity."


def _screenplay_results(content: bytes) -> dict[str, Any]:
    heading = re.compile(
        r"^(\d+)\.\s+(INT\.|EXT\.|INT/EXT\.)\s+(.+)\s+-\s+"
        r"(SUBAH|DIN|SHAAM|RAAT|AGLE DIN)$"
    )
    parsed: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    for line in _pdf_text_lines(content):
        match = heading.match(line)
        if match:
            if current is not None:
                parsed.append(current)
            current = {
                "number": int(match.group(1)),
                "int_ext": match.group(2).rstrip("."),
                "location": match.group(3).strip(),
                "source_time": match.group(4),
                "heading": line,
                "lines": [],
            }
        elif (
            current is not None
            and not line.isdigit()
            and line not in {"FADE OUT.", "END"}
        ):
            current["lines"].append(line)
    if current is not None:
        parsed.append(current)
    if [item["number"] for item in parsed] != list(range(1, 61)):
        raise RuntimeError(
            "The demo screenplay must contain scene headings 1 through 60."
        )

    scenes: list[dict[str, Any]] = []
    story_days: list[dict[str, Any]] = []
    continuities: list[dict[str, Any]] = []
    complexities: list[dict[str, Any]] = []
    time_map = {
        "SUBAH": "MORNING",
        "DIN": "DAY",
        "SHAAM": "EVENING",
        "RAAT": "NIGHT",
        "AGLE DIN": "DAY",
    }
    for item in parsed:
        number = int(item["number"])
        source_text = " ".join(item["lines"])
        cast = [name for name in CHARACTERS if name in source_text.upper()]
        extras = _element_names("extras", source_text)
        stunts = _element_names("stunts", source_text)
        vfx = _element_names("vfx", source_text)
        sfx = _element_names("sfx", source_text)
        weapons = (
            ["Rubber prop pistols and safe-action weapons"]
            if any(
                word in source_text.casefold()
                for word in ("pistol", "gunshot", "weapon", "firing")
            )
            else []
        )
        page_eighths = max(1, min(8, len(source_text) // 220 + 1))
        complexity = "high" if stunts or weapons or extras or sfx else "medium"
        if stunts and (weapons or sfx):
            complexity = "extreme"
        scene_number = str(number)
        story_day = _story_day(number)
        scenes.append(
            {
                "scene_number": scene_number,
                "slugline": item["heading"].split(". ", 1)[1],
                "int_ext": item["int_ext"],
                "location": item["location"].title(),
                "time_of_day": time_map[item["source_time"]],
                "page_length_eighths": page_eighths,
                "estimated_screen_seconds": max(35, page_eighths * 42),
                "summary": source_text,
                "cast": cast,
                "extras": extras,
                "props": _element_names("props", source_text),
                "wardrobe": _element_names("wardrobe", source_text),
                "makeup": _element_names("makeup", source_text),
                "vehicles": _element_names("vehicles", source_text),
                "weapons": weapons,
                "animals": [],
                "stunts": stunts,
                "vfx": vfx,
                "sfx": sfx,
                "equipment": _element_names("equipment", source_text),
                "sound_requirements": (
                    "Plan playback, practical effects, and production-sound coverage."
                    if sfx or weapons
                    else "Standard dialogue and location ambience coverage."
                ),
                "production_notes": (
                    "Roman Urdu source text verified against the uploaded PDF."
                ),
                "safety_notes": (
                    "Stunt, weapon, vehicle, rain, and SFX department "
                    "sign-off required."
                    if stunts or weapons or sfx
                    else None
                ),
                "ai_confidence": 99,
            }
        )
        story_days.append(
            {"scene_number": scene_number, "story_day": story_day, "ai_confidence": 99}
        )
        continuities.append(
            {
                "scene_number": scene_number,
                "continuity_notes": _continuity_notes(number),
                "wardrobe_continuity": _element_names("wardrobe", source_text),
                "makeup_continuity": _element_names("makeup", source_text),
                "prop_continuity": _element_names("props", source_text),
                "ai_confidence": 98,
            }
        )
        complexities.append(
            {
                "scene_number": scene_number,
                "complexity": complexity,
                "reason": (
                    "Calculated from the scene's cast, crowd, stunt, vehicle, "
                    "weapon, rain, VFX, and SFX requirements."
                ),
                "safety_notes": (
                    "Department risk assessment and controlled-set protocol required."
                    if complexity in {"high", "extreme"}
                    else None
                ),
                "ai_confidence": 98,
            }
        )

    characters: list[dict[str, Any]] = []
    for name, profile in CHARACTERS.items():
        appearances = [
            scene["scene_number"] for scene in scenes if name in scene["cast"]
        ]
        if not appearances:
            continue
        story_day_values = sorted({_story_day(int(number)) for number in appearances})
        characters.append(
            {
                "name": name,
                "classification": profile["classification"],
                "description": profile["description"],
                "playing_age": profile["playing_age"],
                "languages": ["Urdu", "English"],
                "skills": profile["skills"],
                "scene_numbers": appearances,
                "dialogue_count": sum(
                    scene["summary"].upper().count(name) for scene in scenes
                ),
                "page_count_eighths": sum(
                    scene["page_length_eighths"]
                    for scene in scenes
                    if name in scene["cast"]
                ),
                "estimated_screen_seconds": sum(
                    scene["estimated_screen_seconds"]
                    for scene in scenes
                    if name in scene["cast"]
                ),
                "first_appearance": appearances[0],
                "last_appearance": appearances[-1],
                "story_days": story_day_values,
                "estimated_shoot_days": max(1, (len(appearances) + 3) // 4),
                "ai_confidence": 99,
            }
        )

    locations: dict[str, list[str]] = {}
    for scene in scenes:
        locations.setdefault(scene["location"], []).append(scene["scene_number"])
    result: dict[str, Any] = {
        "metadata": {
            "title": "Shehar Ke Paar",
            "author": "OpenAI — Synthetic QA Screenplay",
            "revision": "Roman Urdu System Testing Edition",
            "total_pages": 13,
            "logline": (
                "An accountant, a journalist, and a suspended inspector race to "
                "expose a charity-fund smuggling ring before its evidence disappears."
            ),
            "genre": "Roman Urdu investigative action thriller",
            "demo": True,
        },
        "scenes": {"items": scenes},
        "characters": {"items": characters},
        "locations": {
            "items": [
                {
                    "name": name,
                    "description": (
                        "Location extracted from the uploaded Roman Urdu screenplay."
                    ),
                    "scene_numbers": scene_numbers,
                    "requirements": [
                        "Power",
                        "Crew holding",
                        "Parking",
                        "Permit review",
                    ],
                    "ai_confidence": 99,
                }
                for name, scene_numbers in locations.items()
            ]
        },
        "story_days": {"items": story_days},
        "continuity": {"items": continuities},
        "scene_complexity": {"items": complexities},
    }
    for category, catalog in ELEMENT_CATALOG.items():
        result[category] = {
            "items": [
                {
                    "name": name,
                    "description": (
                        f"{category.title()} requirement extracted from Shehar Ke Paar."
                    ),
                    "scene_numbers": [
                        scene["scene_number"]
                        for scene in scenes
                        if name in scene[category]
                    ],
                    "quantity": 1,
                    "continuity_notes": "Track by scene and story day.",
                    "safety_notes": (
                        "Department sign-off required."
                        if category in {"stunts", "sfx", "vehicles"}
                        else None
                    ),
                    "ai_confidence": 99,
                }
                for name, _ in catalog
                if any(name in scene[category] for scene in scenes)
            ]
        }
    return result


def _ensure_owner() -> User:
    now = utc_now()
    owner = db.session.execute(
        select(User).where(User.email == DEMO_EMAIL)
    ).scalar_one_or_none()
    if owner is None:
        owner = User(
            public_id=DEMO_USER_ID,
            email=DEMO_EMAIL,
            password_hash=hash_password(DEMO_PASSWORD),
            display_name="CinePlanner Demo Producer",
            status="active",
            email_verified_at=now,
            terms_version="2026-08",
            terms_accepted_at=now,
        )
        db.session.add(owner)
        db.session.flush()
    else:
        owner.password_hash = hash_password(DEMO_PASSWORD)
        owner.display_name = "CinePlanner Demo Producer"
        owner.status = "active"
        owner.email_verified_at = owner.email_verified_at or now

    role = db.session.execute(
        select(Role).where(Role.code == "director_producer")
    ).scalar_one()
    user_role = db.session.execute(
        select(UserRole).where(
            UserRole.user_id == owner.id, UserRole.role_id == role.id
        )
    ).scalar_one_or_none()
    if user_role is None:
        db.session.add(
            UserRole(
                user_id=owner.id,
                role_id=role.id,
                status="active",
                is_primary=True,
                approved_at=now,
            )
        )
    else:
        user_role.status = "active"
        user_role.is_primary = True
        user_role.approved_at = user_role.approved_at or now
    settings = db.session.execute(
        select(UserSettings).where(UserSettings.user_id == owner.id)
    ).scalar_one_or_none()
    if settings is None:
        db.session.add(
            UserSettings(
                user_id=owner.id,
                timezone="Asia/Karachi",
                locale="en-PK",
                active_role_code="director_producer",
            )
        )
    else:
        settings.active_role_code = "director_producer"
    db.session.commit()
    return owner


def _screenplay_file(owner: User, content: bytes) -> FileAsset:
    storage_key = "demo/cineplanner/shehar-ke-paar.pdf"
    path = Path(str(current_app.config["LOCAL_STORAGE_PRIVATE_ROOT"])) / storage_key
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)
    asset = db.session.execute(
        select(FileAsset).where(FileAsset.public_id == DEMO_FILE_ID)
    ).scalar_one_or_none()
    values = {
        "owner_user_id": owner.id,
        "storage_key": storage_key,
        "bucket": str(current_app.config["OBJECT_STORAGE_BUCKET_PRIVATE"]),
        "mime_type": "application/pdf",
        "size_bytes": len(content),
        "checksum_sha256": hashlib.sha256(content).hexdigest(),
        "visibility": "private",
        "scan_status": "clean",
        "processing_status": "ready",
        "original_name": DEMO_PDF_NAME,
    }
    if asset is None:
        asset = FileAsset(public_id=DEMO_FILE_ID, **values)
        db.session.add(asset)
    else:
        for key, value in values.items():
            setattr(asset, key, value)
    db.session.commit()
    return asset


def _actor(owner: User, index: int, name: str) -> CineActor:
    public_id = f"DEMO-CINE-ACTOR-{index:02}"
    actor = db.session.execute(
        select(CineActor).where(CineActor.public_id == public_id)
    ).scalar_one_or_none()
    values = {
        "owner_user_id": owner.id,
        "name": name,
        "playing_age_min": 26 + index,
        "playing_age_max": 43 + index,
        "gender": "Open casting",
        "languages_json": ["English", "Urdu"],
        "skills_json": ["Dramatic acting", "Water safety"],
        "city": "Karachi",
        "agency": "Demo Screen Artists",
        "manager": "Nadia Khan",
        "phone": f"+92 300 555 {1000 + index}",
        "email": f"actor{index:02}@demo.cine.nalexustechnologies.com",
        "daily_rate_minor": 650_000 + index * 75_000,
        "project_rate_minor": None,
        "currency": "PKR",
        "notes": "Synthetic actor profile for CinePlanner frontend review.",
    }
    if actor is None:
        actor = CineActor(public_id=public_id, **values)
        db.session.add(actor)
        db.session.flush()
    else:
        for key, value in values.items():
            setattr(actor, key, value)
    return actor


def _seed_production(
    owner: User, file: FileAsset, results: dict[str, Any]
) -> CineProduction:
    previous = db.session.execute(
        select(CineProduction).where(CineProduction.public_id == DEMO_PRODUCTION_ID)
    ).scalar_one_or_none()
    if previous is not None:
        db.session.execute(
            delete(CineProduction).where(CineProduction.id == previous.id)
        )
        db.session.commit()

    now = utc_now()
    start_date = _next_monday()
    production = CineProduction(
        public_id=DEMO_PRODUCTION_ID,
        owner_user_id=owner.id,
        title="[DEMO] Shehar Ke Paar",
        status="preproduction",
        currency="PKR",
        production_start_date=start_date,
        maximum_shoot_days=20,
        # Schedule against an 11-hour scene-work envelope; the public 12-hour
        # limit leaves room for the meal event inserted by the scheduler.
        working_hours_limit=11,
        budget_ceiling_minor=180_000_000,
        settings_json={
            "is_demo": True,
            "seed_batch": SEED_BATCH,
            "timezone": "Asia/Karachi",
            "schedule_strategy": "balanced",
        },
    )
    db.session.add(production)
    db.session.flush()
    db.session.add(
        CineProductionRole(
            production_id=production.id,
            user_id=owner.id,
            role_code="producer",
            permissions_json=[
                "edit",
                "finance",
                "schedule",
                "cast",
                "approve",
                "manage_team",
                "locations",
                "elements",
            ],
        )
    )
    script = CineScriptVersion(
        public_id=DEMO_SCRIPT_ID,
        production_id=production.id,
        file_id=file.id,
        uploaded_by_user_id=owner.id,
        version_number=1,
        label="Roman Urdu System Testing Edition",
        analysis_status="approved",
        approved_at=now,
        approved_by_user_id=owner.id,
        metadata_json={"is_demo": True, "seed_batch": SEED_BATCH},
    )
    db.session.add(script)
    db.session.flush()
    _materialize(production, script, results)
    db.session.flush()
    for scene in db.session.execute(
        select(CineScene).where(CineScene.production_id == production.id)
    ).scalars():
        scene.review_status = "approved"
    for character in db.session.execute(
        select(CineCharacter).where(CineCharacter.production_id == production.id)
    ).scalars():
        character.review_status = "approved"
    elements = list(
        db.session.execute(
            select(CineElement).where(CineElement.production_id == production.id)
        ).scalars()
    )
    category_rates = {
        "props": 85_000,
        "wardrobe": 160_000,
        "makeup": 90_000,
        "vehicles": 450_000,
        "extras": 35_000,
        "stunts": 600_000,
        "vfx": 900_000,
        "sfx": 500_000,
        "equipment": 275_000,
    }
    for element in elements:
        element.review_status = "approved"
        element.status = "confirmed" if element.category != "vfx" else "quoted"
        element.owner_vendor = "CinePlanner Demo Vendor"
        element.cost_rate_minor = category_rates[element.category]
        element.rate_basis = (
            "daily"
            if element.category in {"vehicles", "extras", "equipment"}
            else "flat"
        )

    locations = list(
        db.session.execute(
            select(CineLocation).where(CineLocation.production_id == production.id)
        ).scalars()
    )
    for index, location in enumerate(locations, start=1):
        location.option_name = f"{location.screenplay_name} — Karachi Option"
        location.address = f"Unit {index}, Production District, Karachi"
        location.contact_name = "Adeel Mirza"
        location.contact_phone = "+92 300 555 0188"
        location.rental_rate_minor = 550_000 + index * 35_000
        location.currency = "PKR"
        location.availability_json = [
            {
                "starts_on": start_date.isoformat(),
                "ends_on": (start_date + timedelta(days=45)).isoformat(),
                "status": "available",
            }
        ]
        location.parking = "Parking for 8 production vehicles."
        location.electricity = "Three-phase power and silent generator tie-in."
        location.bathrooms = "Two crew washrooms."
        location.holding_area = "Covered holding for 40 cast and extras."
        location.noise_restrictions = "No exterior playback after 22:00."
        location.permit_requirements = "City permit and neighborhood notice filed."
        location.status = "confirmed" if index <= 8 else "option"

    characters = list(
        db.session.execute(
            select(CineCharacter)
            .where(CineCharacter.production_id == production.id)
            .order_by(CineCharacter.classification, CineCharacter.name)
        ).scalars()
    )
    actor_names = [
        "Ayesha Noor",
        "Hamza Rafiq",
        "Meher Shah",
        "Daniyal Khan",
        "Sana Mirza",
        "Omar Rehman",
        "Hira Salman",
        "Faris Sheikh",
        "Mariam Tariq",
        "Zain Javed",
        "Laila Noor",
        "Taha Baig",
        "Reema Iqbal",
        "Ayaan Malik",
    ]
    actors = [_actor(owner, index, name) for index, name in enumerate(actor_names, 1)]
    db.session.flush()
    for index, actor in enumerate(actors):
        db.session.add(
            CineActorAvailability(
                actor_id=actor.id,
                production_id=production.id,
                starts_on=start_date,
                ends_on=start_date + timedelta(days=60),
                status="confirmed" if index < len(characters) else "hold",
                notes="Demo production availability window.",
            )
        )
        character = characters[index % len(characters)]
        db.session.add(
            CineCastAssignment(
                production_id=production.id,
                character_id=character.id,
                actor_id=actor.id,
                status="confirmed" if index < len(characters) else "shortlisted",
                fit_score=92 - index,
                fit_breakdown_json={
                    "age": 90,
                    "suitability": 92,
                    "language": 100,
                    "skills": 90,
                    "availability": 100 if index < len(characters) else 75,
                    "budget": 86,
                    "preference": 90,
                },
                preference_notes="Seeded casting choice for interface review.",
            )
        )

    crew_rows = [
        ("Sara Nadeem", "Production", "Line Producer", 180_000),
        ("Bilal Qureshi", "Direction", "First Assistant Director", 145_000),
        ("Noor Khan", "Camera", "Director of Photography", 220_000),
        ("Rida Ahmed", "Camera", "First AC", 95_000),
        ("Usman Ali", "Lighting", "Gaffer", 110_000),
        ("Zoya Siddiqui", "Sound", "Production Sound Mixer", 120_000),
        ("Mahnoor Raza", "Art", "Production Designer", 165_000),
        ("Kamil Ahmed", "Locations", "Location Manager", 90_000),
        ("Saba Iqbal", "Wardrobe", "Costume Designer", 125_000),
        ("Taha Baig", "Safety", "Set Safety Officer", 100_000),
    ]
    for index, (name, department, title, rate) in enumerate(crew_rows, 1):
        db.session.add(
            CineCrewMember(
                public_id=f"DEMO-CINE-CREW-{index:02}",
                production_id=production.id,
                name=name,
                department=department,
                job_title=title,
                phone=f"+92 301 555 {2000 + index}",
                email=f"crew{index:02}@demo.cine.nalexustechnologies.com",
                daily_rate_minor=rate,
                availability_json=[
                    {
                        "starts_on": start_date.isoformat(),
                        "ends_on": (start_date + timedelta(days=60)).isoformat(),
                        "status": "available",
                    }
                ],
                status="confirmed",
            )
        )

    scenes = list(
        db.session.execute(
            select(CineScene)
            .where(CineScene.production_id == production.id)
            .order_by(CineScene.sort_order)
        ).scalars()
    )
    plan = build_schedule_plan(production, scenes, "balanced")
    apply_schedule_plan(production, plan)
    production.working_hours_limit = 12
    detect_conflicts(production)
    db.session.flush()

    manual_budget = [
        ("Development", "Screenplay rights and development", 4_500_000),
        ("Insurance", "Production and equipment insurance", 3_250_000),
        ("Post Production", "Editorial, grade, sound mix, and masters", 18_000_000),
        ("Contingency", "Production contingency reserve", 12_500_000),
    ]
    for category, description, amount in manual_budget:
        db.session.add(
            CineBudgetLine(
                production_id=production.id,
                category=category,
                description=description,
                estimated_minor=amount,
                quoted_minor=round(amount * 0.96),
                approved_minor=amount,
                committed_minor=round(amount * 0.72),
                paid_minor=round(amount * 0.28),
                status="approved",
                notes="Demo budget line for frontend review.",
            )
        )
    budget = recalculate_budget(production)
    for line in budget["lines"]:
        if line.source_type:
            line.quoted_minor = round(line.estimated_minor * 0.94)
            line.approved_minor = line.estimated_minor
            line.committed_minor = round(line.estimated_minor * 0.68)
            line.paid_minor = round(line.estimated_minor * 0.22)
            line.status = "approved"

    db.session.add(
        CineAIJob(
            public_id=DEMO_JOB_ID,
            production_id=production.id,
            script_version_id=script.id,
            requested_by_user_id=owner.id,
            status="completed",
            current_stage="cineplanner_ready",
            progress_percent=100,
            completed_stages_json=[stage for stage, _, _ in STAGES],
            stage_results_json=results,
            attempt_count=1,
            started_at=now - timedelta(minutes=4),
            completed_at=now,
        )
    )
    db.session.flush()
    db.session.expire_all()
    production = db.session.execute(
        select(CineProduction).where(CineProduction.public_id == DEMO_PRODUCTION_ID)
    ).scalar_one()
    days = list(
        db.session.execute(
            select(CineShootDay)
            .where(CineShootDay.production_id == production.id)
            .order_by(CineShootDay.shoot_day_number)
        ).scalars()
    )
    for day in days[:3]:
        db.session.add(
            CineCallSheet(
                production_id=production.id,
                shoot_day_id=day.id,
                generated_by_user_id=owner.id,
                revision_number=1,
                payload_json=_call_sheet_payload(production, day),
                status="published",
            )
        )
    production.schedule_locked_at = now
    for day in days:
        day.locked_at = now
        day.status = "locked"
    db.session.add(
        CineConflict(
            production_id=production.id,
            shoot_day_id=days[2].id if len(days) > 2 else days[0].id,
            conflict_type="location_permit",
            severity="warning",
            message=(
                "Demo warning: Charity Gala Hotel night-filming permit requires "
                "final confirmation."
            ),
            metadata_json={"is_demo": True, "department": "Locations"},
        )
    )
    for action, entity_type, detail in [
        ("production_created", "production", "Demo production configured"),
        ("script_analyzed", "script", "60-scene Roman Urdu breakdown completed"),
        ("breakdown_approved", "breakdown", "All extracted items approved"),
        ("schedule_generated", "schedule", "Balanced schedule generated"),
        ("schedule_locked", "schedule", "Schedule locked for call sheets"),
    ]:
        db.session.add(
            CineAuditLog(
                production_id=production.id,
                actor_user_id=owner.id,
                action=action,
                entity_type=entity_type,
                entity_public_id=production.public_id,
                old_value_json=None,
                new_value_json={"detail": detail, "is_demo": True},
            )
        )
    db.session.commit()
    return production


def seed() -> dict[str, Any]:
    if not DEMO_PDF_PATH.is_file():
        raise RuntimeError(f"Demo screenplay not found: {DEMO_PDF_PATH}")
    content = DEMO_PDF_PATH.read_bytes()
    if not content.startswith(b"%PDF-"):
        raise RuntimeError("The CinePlanner demo screenplay is not a valid PDF.")
    owner = _ensure_owner()
    results = _screenplay_results(content)
    file = _screenplay_file(owner, content)
    production = _seed_production(owner, file, results)
    snapshot = {
        "seed_batch": SEED_BATCH,
        "user": DEMO_EMAIL,
        "production_id": production.public_id,
        "production": production.title,
        "scenes": db.session.scalar(
            select(db.func.count())
            .select_from(CineScene)
            .where(CineScene.production_id == production.id)
        ),
        "characters": db.session.scalar(
            select(db.func.count())
            .select_from(CineCharacter)
            .where(CineCharacter.production_id == production.id)
        ),
        "shoot_days": db.session.scalar(
            select(db.func.count())
            .select_from(CineShootDay)
            .where(CineShootDay.production_id == production.id)
        ),
        "generated_at": datetime.now().astimezone().isoformat(),
    }
    return snapshot


def main() -> None:
    app = create_app()
    with app.app_context():
        print(json.dumps(seed(), indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
