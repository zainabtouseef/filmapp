from __future__ import annotations

from pathlib import Path
from typing import Any

from reportlab.lib.pagesizes import LETTER
from reportlab.pdfgen import canvas

TITLE = "The Monsoon Ledger"
LEADS = ["MARA VALE", "IMRAN SHAH", "LEENA ROY", "DANIEL CROSS"]
SUPPORTING = [
    "CAPTAIN ASAD",
    "DR. AMAL",
    "NURSE FARAH",
    "INSPECTOR HADI",
    "MAYOR QURESHI",
    "REPORTER NINA",
    "DRIVER SAMEER",
    "OFFICER ZOYA",
    "ARCHIVIST OMAR",
    "TECH RHEA",
    "VENDOR BILAL",
    "JUDGE SANA",
]
LOCATIONS = [
    "Harbor Warehouse",
    "City Hospital",
    "Central Police Station",
    "Old Courthouse",
    "Mara's Apartment",
    "Newsroom",
    "Riverside Road",
    "Underground Car Park",
    "Municipal Archive",
    "Rooftop Garden",
    "Night Market",
    "Railway Platform",
    "Flood Control Room",
    "Hotel Ballroom",
    "Abandoned Cinema",
    "City Hall",
    "Ambulance Bay",
    "Harbor Pier",
]


def screenplay_results(scene_count: int = 90) -> dict[str, Any]:
    scenes: list[dict[str, Any]] = []
    story_days: list[dict[str, Any]] = []
    continuity: list[dict[str, Any]] = []
    complexity: list[dict[str, Any]] = []
    for number in range(1, scene_count + 1):
        location = LOCATIONS[(number - 1) % len(LOCATIONS)]
        exterior = number % 3 == 0
        night = number % 4 in {0, 1}
        cast = [LEADS[(number - 1) % len(LEADS)]]
        if number % 2 == 0:
            cast.append(LEADS[number % len(LEADS)])
        if number % 5 == 0:
            cast.append(SUPPORTING[(number // 5) % len(SUPPORTING)])
        rain = number % 11 == 0
        crowd = number % 13 == 0
        stunt = number % 17 == 0
        weapon = number % 19 == 0
        vehicle = number % 7 == 0
        scene_number = str(number)
        scenes.append(
            {
                "scene_number": scene_number,
                "slugline": (
                    f"{'EXT' if exterior else 'INT'}. {location.upper()} - "
                    f"{'NIGHT' if night else 'DAY'}"
                ),
                "int_ext": "EXT" if exterior else "INT",
                "location": location,
                "time_of_day": "NIGHT" if night else "DAY",
                "page_length_eighths": 8 + number % 8,
                "estimated_screen_seconds": 55 + number % 65,
                "summary": (
                    "The investigators follow the civic ledger trail while the rising "
                    "monsoon forces a choice between evidence and public safety."
                ),
                "cast": cast,
                "extras": ["Evacuation crowd"] if crowd else [],
                "props": ["Water-damaged ledger", "Evidence envelope"],
                "wardrobe": [f"Story day {(number - 1) // 12 + 1} rain layers"],
                "makeup": ["Rain continuity", "Forehead bruise"] if stunt else [],
                "vehicles": ["Picture ambulance"] if vehicle else [],
                "weapons": ["Rubber stunt pistol"] if weapon else [],
                "animals": [],
                "stunts": ["Controlled stair fall"] if stunt else [],
                "vfx": ["Floodwater extension"] if number % 9 == 0 else [],
                "sfx": ["Practical rain bars"] if rain else [],
                "equipment": ["Rain cover", "Wireless timecode"],
                "sound_requirements": "Rain-resistant radio microphones",
                "production_notes": "Protect the hero ledger between takes.",
                "safety_notes": "Wet-surface protocol" if rain or stunt else None,
                "ai_confidence": 96,
            }
        )
        story_day = f"Day {(number - 1) // 12 + 1}"
        story_days.append(
            {
                "scene_number": scene_number,
                "story_day": story_day,
                "ai_confidence": 97,
            }
        )
        continuity.append(
            {
                "scene_number": scene_number,
                "continuity_notes": f"Ledger damage level {min(5, number // 18 + 1)}.",
                "wardrobe_continuity": [f"{story_day} rain layers"],
                "makeup_continuity": ["Track water and bruise continuity"],
                "prop_continuity": ["Photograph ledger page before each reset"],
                "ai_confidence": 94,
            }
        )
        complexity.append(
            {
                "scene_number": scene_number,
                "complexity": "high" if rain or stunt or crowd else "medium",
                "reason": "Weather, crowd, stunt, and continuity load assessed.",
                "safety_notes": "Wet-surface protocol" if rain or stunt else None,
                "ai_confidence": 95,
            }
        )

    character_items: list[dict[str, Any]] = []
    for index, name in enumerate([*LEADS, *SUPPORTING]):
        appearances = [
            str(number)
            for number in range(1, scene_count + 1)
            if (index < 4 and (number - 1) % 4 == index)
            or (index >= 4 and number % (index + 2) == 0)
        ]
        character_items.append(
            {
                "name": name,
                "classification": "lead" if index < 4 else "supporting",
                "description": "A principal investigator."
                if index < 4
                else "A city ally.",
                "playing_age": "28-48",
                "languages": ["English", "Urdu"],
                "skills": ["Dramatic acting"],
                "scene_numbers": appearances,
                "dialogue_count": len(appearances) * 3,
                "page_count_eighths": len(appearances) * 10,
                "estimated_screen_seconds": len(appearances) * 65,
                "first_appearance": appearances[0] if appearances else None,
                "last_appearance": appearances[-1] if appearances else None,
                "story_days": sorted(
                    {f"Day {(int(value) - 1) // 12 + 1}" for value in appearances}
                ),
                "estimated_shoot_days": max(1, len(appearances) // 6),
                "ai_confidence": 96,
            }
        )

    categories = {
        "props": ["Water-damaged ledger", "Evidence envelope", "Satellite phone"],
        "wardrobe": ["Rain coat continuity set", "Police dress uniform"],
        "makeup": ["Forehead bruise progression", "Rain and mud continuity"],
        "vehicles": ["Picture ambulance", "Police SUV", "Flood rescue boat"],
        "extras": ["Evacuation crowd", "Hospital staff", "Police officers"],
        "stunts": ["Controlled stair fall", "Flood rescue transfer"],
        "vfx": ["Floodwater extension", "Storm skyline replacement"],
        "sfx": ["Practical rain bars", "Breakaway archive shelving"],
        "equipment": ["Rain cover", "Wireless timecode", "Technocrane"],
    }
    results: dict[str, Any] = {
        "metadata": {
            "title": TITLE,
            "author": "CinePlanner Test Unit",
            "revision": "Synthetic QA Draft",
            "total_pages": 112,
            "logline": (
                "Four investigators race a monsoon to expose a civic conspiracy."
            ),
            "genre": "Production thriller",
        },
        "scenes": {"items": scenes},
        "characters": {"items": character_items},
        "locations": {
            "items": [
                {
                    "name": name,
                    "description": "Scripted location requiring production review.",
                    "scene_numbers": [
                        str(number)
                        for number in range(1, scene_count + 1)
                        if LOCATIONS[(number - 1) % len(LOCATIONS)] == name
                    ],
                    "requirements": ["Power", "Crew holding", "Wet-weather cover"],
                    "ai_confidence": 96,
                }
                for name in LOCATIONS
            ]
        },
        "story_days": {"items": story_days},
        "continuity": {"items": continuity},
        "scene_complexity": {"items": complexity},
    }
    for category, names in categories.items():
        results[category] = {
            "items": [
                {
                    "name": name,
                    "description": f"Synthetic {category} requirement.",
                    "scene_numbers": [str(index * 3 + 1)],
                    "quantity": 1,
                    "continuity_notes": "Track by story day.",
                    "safety_notes": "Department sign-off required."
                    if category in {"stunts", "sfx", "vehicles"}
                    else None,
                    "ai_confidence": 95,
                }
                for index, name in enumerate(names)
            ]
        }
    return results


def write_screenplay_pdf(path: Path, scene_count: int = 90) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    document = canvas.Canvas(str(path), pagesize=LETTER, pageCompression=1)
    width, height = LETTER
    document.setTitle(TITLE)
    document.setFont("Helvetica-Bold", 20)
    document.drawCentredString(width / 2, height - 120, TITLE.upper())
    document.setFont("Helvetica", 11)
    document.drawCentredString(
        width / 2, height - 150, "An original synthetic screenplay"
    )
    document.showPage()
    scenes = screenplay_results(scene_count)["scenes"]["items"]
    for scene in scenes:
        document.setFont("Courier-Bold", 10)
        document.drawString(
            50, height - 60, f"{scene['scene_number']}. {scene['slugline']}"
        )
        document.setFont("Courier", 9)
        lines = [
            str(scene["summary"]),
            f"CAST: {', '.join(scene['cast'])}",
            f"PROPS: {', '.join(scene['props'])}",
            f"WARDROBE: {', '.join(scene['wardrobe'])}",
            f"VEHICLES: {', '.join(scene['vehicles']) or 'NONE'}",
            "WEAPONS/STUNTS: "
            f"{', '.join([*scene['weapons'], *scene['stunts']]) or 'NONE'}",
            f"VFX/SFX: {', '.join([*scene['vfx'], *scene['sfx']]) or 'NONE'}",
        ]
        y = height - 90
        for line in lines:
            document.drawString(60, y, line[:100])
            y -= 18
        document.showPage()
    document.save()
