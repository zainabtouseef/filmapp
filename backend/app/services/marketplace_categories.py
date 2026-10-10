from __future__ import annotations

import re


def equipment_categories(values: list[str]) -> list[str]:
    """Map declared services/inventory labels without inventing inventory."""
    result: list[str] = []
    for value in values:
        label = value.strip()
        words = set(re.findall(r"[a-z]+", label.lower()))
        category = (
            "Cameras"
            if words & {"camera", "cameras", "lens", "lenses", "cinema"}
            else "Lighting Equipment"
            if words & {"lighting", "light", "lights", "led", "hmi", "gaffer"}
            else label
        )
        if category and category not in result:
            result.append(category)
    return result


def crew_categories(title: str, summary: str) -> list[str]:
    text = f"{title} {summary}".lower()
    labels = {
        "DOP": r"\bdop\b|director of photography|cinematograph",
        "Assistant Direction": r"assistant director|assistant direction",
        "Camera Crew": r"camera operator|camera assistant|focus puller",
        "Lighting & Grip": r"\bgaffer\b|\bgrip\b|lighting crew",
        "Sound": r"sound engineer|sound record|\bboom\b|audio",
        "Makeup & Styling": r"makeup|make-up|stylist|wardrobe",
        "Art & Production Design": r"art director|production design|set design",
        "Editing & Post": r"\beditor\b|editing|post.production|\bvfx\b",
        "Production Support": r"transport|catering|production assistant",
    }
    return [label for label, pattern in labels.items() if re.search(pattern, text)]
