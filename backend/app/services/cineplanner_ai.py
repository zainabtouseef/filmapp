from __future__ import annotations

import json
from concurrent.futures import Future, ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

from flask import current_app
from sqlalchemy import delete, select

from app.extensions import db
from app.models.base import utc_now
from app.models.cineplanner import (
    CineAIJob,
    CineCharacter,
    CineElement,
    CineLocation,
    CineProduction,
    CineScene,
    CineScriptVersion,
)
from app.models.files import FileAsset
from app.services.cineplanner_scheduling import apply_schedule_plan, build_schedule_plan
from app.services.local_storage import resolve_path


def _object(properties: dict[str, Any]) -> dict[str, Any]:
    return {
        "type": "object",
        "properties": properties,
        "required": list(properties),
        "additionalProperties": False,
    }


def _array(item: dict[str, Any]) -> dict[str, Any]:
    return {"type": "array", "items": item}


STRING = {"type": "string"}
NULLABLE_STRING = {"type": ["string", "null"]}
INTEGER = {"type": "integer"}
STRING_LIST = _array(STRING)

METADATA_SCHEMA = _object(
    {
        "title": STRING,
        "author": NULLABLE_STRING,
        "revision": NULLABLE_STRING,
        "total_pages": INTEGER,
        "logline": NULLABLE_STRING,
        "genre": NULLABLE_STRING,
    }
)

SCENE_SCHEMA = _object(
    {
        "scene_number": STRING,
        "slugline": STRING,
        "int_ext": {"type": "string", "enum": ["INT", "EXT", "INT/EXT", "UNKNOWN"]},
        "location": STRING,
        "time_of_day": STRING,
        "page_length_eighths": INTEGER,
        "estimated_screen_seconds": INTEGER,
        "summary": STRING,
        "cast": STRING_LIST,
        "extras": STRING_LIST,
        "props": STRING_LIST,
        "wardrobe": STRING_LIST,
        "makeup": STRING_LIST,
        "vehicles": STRING_LIST,
        "weapons": STRING_LIST,
        "animals": STRING_LIST,
        "stunts": STRING_LIST,
        "vfx": STRING_LIST,
        "sfx": STRING_LIST,
        "equipment": STRING_LIST,
        "sound_requirements": NULLABLE_STRING,
        "production_notes": NULLABLE_STRING,
        "safety_notes": NULLABLE_STRING,
        "ai_confidence": INTEGER,
    }
)
SCENES_SCHEMA = _object({"items": _array(SCENE_SCHEMA)})

CHARACTER_SCHEMA = _object(
    {
        "name": STRING,
        "classification": {
            "type": "string",
            "enum": ["lead", "supporting", "minor"],
        },
        "description": NULLABLE_STRING,
        "playing_age": NULLABLE_STRING,
        "languages": STRING_LIST,
        "skills": STRING_LIST,
        "scene_numbers": STRING_LIST,
        "dialogue_count": INTEGER,
        "page_count_eighths": INTEGER,
        "estimated_screen_seconds": INTEGER,
        "first_appearance": NULLABLE_STRING,
        "last_appearance": NULLABLE_STRING,
        "story_days": STRING_LIST,
        "estimated_shoot_days": INTEGER,
        "ai_confidence": INTEGER,
    }
)
CHARACTERS_SCHEMA = _object({"items": _array(CHARACTER_SCHEMA)})

LOCATION_SCHEMA = _object(
    {
        "name": STRING,
        "description": NULLABLE_STRING,
        "scene_numbers": STRING_LIST,
        "requirements": STRING_LIST,
        "ai_confidence": INTEGER,
    }
)
LOCATIONS_SCHEMA = _object({"items": _array(LOCATION_SCHEMA)})

ELEMENT_SCHEMA = _object(
    {
        "name": STRING,
        "description": NULLABLE_STRING,
        "scene_numbers": STRING_LIST,
        "quantity": INTEGER,
        "continuity_notes": NULLABLE_STRING,
        "safety_notes": NULLABLE_STRING,
        "ai_confidence": INTEGER,
    }
)
ELEMENTS_SCHEMA = _object({"items": _array(ELEMENT_SCHEMA)})

STORY_DAY_SCHEMA = _object(
    {"scene_number": STRING, "story_day": STRING, "ai_confidence": INTEGER}
)
STORY_DAYS_SCHEMA = _object({"items": _array(STORY_DAY_SCHEMA)})
CONTINUITY_SCHEMA = _object(
    {
        "scene_number": STRING,
        "continuity_notes": STRING,
        "wardrobe_continuity": STRING_LIST,
        "makeup_continuity": STRING_LIST,
        "prop_continuity": STRING_LIST,
        "ai_confidence": INTEGER,
    }
)
CONTINUITIES_SCHEMA = _object({"items": _array(CONTINUITY_SCHEMA)})
COMPLEXITY_SCHEMA = _object(
    {
        "scene_number": STRING,
        "complexity": {
            "type": "string",
            "enum": ["low", "medium", "high", "extreme"],
        },
        "reason": STRING,
        "safety_notes": NULLABLE_STRING,
        "ai_confidence": INTEGER,
    }
)
COMPLEXITIES_SCHEMA = _object({"items": _array(COMPLEXITY_SCHEMA)})


STAGES: tuple[tuple[str, str, dict[str, Any]], ...] = (
    (
        "script_structure",
        "Extract screenplay metadata and every scene in exact screenplay order. "
        "Do not omit montage, intercut, or very short scenes.",
        _object({"metadata": METADATA_SCHEMA, "scenes": SCENES_SCHEMA}),
    ),
    (
        "people_and_places",
        "Extract every speaking or narratively significant character and every "
        "distinct scripted location, including appearance statistics and practical "
        "production requirements.",
        _object(
            {
                "characters": CHARACTERS_SCHEMA,
                "locations": LOCATIONS_SCHEMA,
            }
        ),
    ),
    (
        "production_elements",
        "Extract all production elements by category. Include hero items, "
        "consumables, continuity dependencies, specialist requirements, and safety "
        "notes. Keep VFX separate from practical SFX.",
        _object(
            {
                "props": ELEMENTS_SCHEMA,
                "wardrobe": ELEMENTS_SCHEMA,
                "makeup": ELEMENTS_SCHEMA,
                "vehicles": ELEMENTS_SCHEMA,
                "extras": ELEMENTS_SCHEMA,
                "stunts": ELEMENTS_SCHEMA,
                "vfx": ELEMENTS_SCHEMA,
                "sfx": ELEMENTS_SCHEMA,
                "equipment": ELEMENTS_SCHEMA,
            }
        ),
    ),
    (
        "continuity_and_complexity",
        "Assign a story day to every scene, analyze narrative and physical "
        "continuity scene by scene, and score production complexity and safety risk.",
        _object(
            {
                "story_days": STORY_DAYS_SCHEMA,
                "continuity": CONTINUITIES_SCHEMA,
                "scene_complexity": COMPLEXITIES_SCHEMA,
            }
        ),
    ),
)

MAX_OUTPUT_TOKENS = {
    "script_structure": 60000,
    "people_and_places": 30000,
    "production_elements": 30000,
    "continuity_and_complexity": 40000,
}

ANALYSIS_INSTRUCTIONS = (
    "You are a senior film production script supervisor. Extract only facts grounded "
    "in the attached screenplay. Never invent missing data. Use empty arrays or nulls "
    "where the screenplay is silent. Confidence is an integer from 0 to 100. Preserve "
    "screenplay scene numbers exactly."
)


def _request_stage(
    client: Any,
    *,
    stage: str,
    prompt: str,
    schema: dict[str, Any],
    openai_file_id: str,
    model: str,
    safety_identifier: str,
) -> dict[str, Any]:
    response = client.responses.create(
        model=model,
        instructions=ANALYSIS_INSTRUCTIONS,
        input=[
            {
                "role": "user",
                "content": [
                    {"type": "input_file", "file_id": openai_file_id},
                    {"type": "input_text", "text": prompt},
                ],
            }
        ],
        text={
            "format": {
                "type": "json_schema",
                "name": f"cineplanner_{stage}",
                "schema": schema,
                "strict": True,
            }
        },
        reasoning={"effort": "low"},
        max_output_tokens=MAX_OUTPUT_TOKENS[stage],
        store=False,
        safety_identifier=safety_identifier,
    )
    parsed = json.loads(response.output_text)
    if not isinstance(parsed, dict):
        raise ValueError(f"CinePlanner stage {stage} returned invalid JSON")
    return parsed


def analyze_screenplay_job(job_public_id: str) -> dict[str, Any]:
    job = db.session.execute(
        select(CineAIJob).where(CineAIJob.public_id == job_public_id)
    ).scalar_one_or_none()
    if job is None:
        return {"status": "not_found"}
    if job.status == "completed":
        return {"status": "completed", "job_id": job.public_id}
    script = db.session.get(CineScriptVersion, job.script_version_id)
    production = db.session.get(CineProduction, job.production_id)
    if script is None or production is None:
        _fail(
            job,
            "cineplanner.source_missing",
            "Screenplay analysis source is unavailable.",
        )
        return {"status": "failed", "job_id": job.public_id}
    file = db.session.get(FileAsset, script.file_id)
    if file is None:
        _fail(job, "cineplanner.file_missing", "The screenplay file is unavailable.")
        return {"status": "failed", "job_id": job.public_id}

    api_key = str(current_app.config.get("OPENAI_API_KEY", ""))
    if not api_key:
        _fail(
            job, "cineplanner.openai_not_configured", "Screenplay AI is not configured."
        )
        return {"status": "failed", "job_id": job.public_id}

    from openai import OpenAI

    client = OpenAI(api_key=api_key, timeout=900.0, max_retries=2)
    model = str(current_app.config["OPENAI_SCREENPLAY_MODEL"])
    parallelism = max(
        1,
        min(
            len(STAGES),
            int(current_app.config.get("CINEPLANNER_AI_PARALLELISM", len(STAGES))),
        ),
    )
    safety_identifier = f"cineplanner_{job.requested_by_user_id.hex[:32]}"
    active_stage = job.current_stage
    job.status = "processing"
    job.started_at = job.started_at or utc_now()
    job.attempt_count += 1
    script.analysis_status = "processing"
    db.session.commit()
    openai_file_id: str | None = None
    try:
        source_path = resolve_path(file)
        _validate_pdf(source_path)
        results = dict(job.stage_results_json or {})
        completed = list(job.completed_stages_json or [])
        pending_stages = [item for item in STAGES if item[0] not in completed]
        if pending_stages:
            with source_path.open("rb") as source:
                uploaded = client.files.create(
                    file=source,
                    purpose="user_data",
                    expires_after={"anchor": "created_at", "seconds": 86400},
                )
            openai_file_id = uploaded.id
            active_stage = _public_stage(pending_stages[0][0])
            job.current_stage = active_stage
            job.progress_percent = min(94, 4 + int(len(completed) / len(STAGES) * 90))
            db.session.commit()

            failures: list[tuple[str, Exception]] = []
            worker_count = min(parallelism, len(pending_stages))
            with ThreadPoolExecutor(
                max_workers=worker_count,
                thread_name_prefix="cineplanner-ai",
            ) as executor:
                futures: dict[Future[dict[str, Any]], str] = {
                    executor.submit(
                        _request_stage,
                        client,
                        stage=stage,
                        prompt=prompt,
                        schema=schema,
                        openai_file_id=openai_file_id,
                        model=model,
                        safety_identifier=safety_identifier,
                    ): stage
                    for stage, prompt, schema in pending_stages
                }
                for future in as_completed(futures):
                    stage = futures[future]
                    try:
                        parsed = future.result()
                    except Exception as exc:
                        failures.append((stage, exc))
                        continue
                    results.update(parsed)
                    completed.append(stage)
                    active_stage = _public_stage(stage)
                    job.current_stage = active_stage
                    # Assign fresh containers so SQLAlchemy always persists each
                    # independently completed checkpoint before another result lands.
                    job.stage_results_json = dict(results)
                    job.completed_stages_json = list(completed)
                    job.progress_percent = min(
                        95, 4 + int(len(completed) / len(STAGES) * 90)
                    )
                    db.session.commit()

            if failures:
                failed_stage, error = failures[0]
                active_stage = _public_stage(failed_stage)
                raise error

        active_stage = "saving_breakdown"
        job.current_stage = active_stage
        job.progress_percent = 96
        db.session.commit()
        _materialize(production, script, results)
        scenes = (
            db.session.execute(
                select(CineScene).where(CineScene.script_version_id == script.id)
            )
            .scalars()
            .all()
        )
        if scenes:
            plan = build_schedule_plan(production, scenes, "balanced")
            apply_schedule_plan(production, plan)
        script.analysis_status = "review"
        job.status = "completed"
        job.current_stage = "cineplanner_ready"
        job.progress_percent = 100
        job.completed_at = utc_now()
        db.session.commit()
        return {"status": "completed", "job_id": job.public_id}
    except Exception:
        db.session.rollback()
        current_app.logger.exception(
            "cineplanner_analysis_failed",
            extra={"job_public_id": job_public_id, "stage": active_stage},
        )
        job = db.session.execute(
            select(CineAIJob).where(CineAIJob.public_id == job_public_id)
        ).scalar_one()
        _fail(
            job,
            "cineplanner.analysis_failed",
            "Screenplay analysis failed. Retry the job or contact support.",
        )
        return {"status": "failed", "job_id": job.public_id}
    finally:
        if openai_file_id:
            try:
                client.files.delete(openai_file_id)
            except Exception:
                current_app.logger.warning(
                    "cineplanner_openai_file_cleanup_failed",
                    extra={"job_public_id": job_public_id},
                )


def _validate_pdf(path: Path) -> None:
    with path.open("rb") as source:
        signature = source.read(5)
    if signature != b"%PDF-":
        raise ValueError("Screenplay file does not have a PDF signature")


def _public_stage(stage: str) -> str:
    if stage == "script_structure":
        return "scenes_extracted"
    if stage == "people_and_places":
        return "characters_extracted"
    if stage == "continuity_and_complexity":
        return "continuity_analyzed"
    return "production_elements_extracted"


def _fail(job: CineAIJob, code: str, message: str) -> None:
    job.status = "failed"
    job.error_code = code
    job.error_message = message
    db.session.commit()


def _materialize(
    production: CineProduction,
    script: CineScriptVersion,
    results: dict[str, Any],
) -> None:
    db.session.execute(
        delete(CineScene).where(CineScene.script_version_id == script.id)
    )
    db.session.execute(
        delete(CineCharacter).where(CineCharacter.script_version_id == script.id)
    )
    db.session.execute(
        delete(CineElement).where(CineElement.script_version_id == script.id)
    )
    db.session.execute(
        delete(CineLocation).where(CineLocation.script_version_id == script.id)
    )
    metadata = results.get("metadata", {})
    script.screenplay_title = _text(metadata.get("title"), 180) or production.title
    script.author = _text(metadata.get("author"), 180)
    script.revision = _text(metadata.get("revision"), 120)
    script.total_pages = max(0, int(metadata.get("total_pages", 0) or 0))
    script.metadata_json = metadata

    story_days = {
        str(item.get("scene_number", "")): item
        for item in results.get("story_days", {}).get("items", [])
    }
    continuities = {
        str(item.get("scene_number", "")): item
        for item in results.get("continuity", {}).get("items", [])
    }
    complexities = {
        str(item.get("scene_number", "")): item
        for item in results.get("scene_complexity", {}).get("items", [])
    }
    seen_scene_numbers: set[str] = set()
    for index, raw in enumerate(results.get("scenes", {}).get("items", []), start=1):
        scene_number = _text(raw.get("scene_number"), 24) or str(index)
        if scene_number.casefold() in seen_scene_numbers:
            continue
        seen_scene_numbers.add(scene_number.casefold())
        continuity = continuities.get(scene_number, {})
        complexity = complexities.get(scene_number, {})
        scene = CineScene(
            production_id=production.id,
            script_version_id=script.id,
            scene_number=scene_number,
            sort_order=index,
            slugline=_text(raw.get("slugline"), 300) or "UNTITLED SCENE",
            int_ext=_enum(
                raw.get("int_ext"), {"INT", "EXT", "INT/EXT", "UNKNOWN"}, "UNKNOWN"
            ),
            location_name=_text(raw.get("location"), 180) or "Unknown",
            time_of_day=_text(raw.get("time_of_day"), 40) or "Unspecified",
            story_day=_text(story_days.get(scene_number, {}).get("story_day"), 64),
            page_length_eighths=max(1, int(raw.get("page_length_eighths", 8) or 8)),
            estimated_screen_seconds=max(
                1, int(raw.get("estimated_screen_seconds", 60) or 60)
            ),
            summary=_text(raw.get("summary"), 5000) or "",
            cast_json=_strings(raw.get("cast")),
            extras_json=_strings(raw.get("extras")),
            props_json=_strings(raw.get("props")),
            wardrobe_json=_strings(raw.get("wardrobe")),
            makeup_json=_strings(raw.get("makeup")),
            vehicles_json=_strings(raw.get("vehicles")),
            weapons_json=_strings(raw.get("weapons")),
            animals_json=_strings(raw.get("animals")),
            stunts_json=_strings(raw.get("stunts")),
            vfx_json=_strings(raw.get("vfx")),
            sfx_json=_strings(raw.get("sfx")),
            equipment_json=_strings(raw.get("equipment")),
            sound_requirements=_text(raw.get("sound_requirements"), 5000),
            production_notes=_text(raw.get("production_notes"), 5000),
            safety_notes=_join_notes(
                raw.get("safety_notes"), complexity.get("safety_notes")
            ),
            continuity_notes=_text(continuity.get("continuity_notes"), 5000),
            complexity=_enum(
                complexity.get("complexity"),
                {"low", "medium", "high", "extreme"},
                "medium",
            ),
            ai_confidence=_confidence(
                complexity.get("ai_confidence", raw.get("ai_confidence"))
            ),
        )
        db.session.add(scene)

    seen_characters: set[str] = set()
    for raw in results.get("characters", {}).get("items", []):
        name = _text(raw.get("name"), 160)
        normalized_name = name.casefold() if name else ""
        if not name or normalized_name in seen_characters:
            continue
        seen_characters.add(normalized_name)
        db.session.add(
            CineCharacter(
                production_id=production.id,
                script_version_id=script.id,
                name=name,
                normalized_name=normalized_name,
                classification=_enum(
                    raw.get("classification"), {"lead", "supporting", "minor"}, "minor"
                ),
                description=_text(raw.get("description"), 5000),
                playing_age=_text(raw.get("playing_age"), 40),
                languages_json=_strings(raw.get("languages")),
                skills_json=_strings(raw.get("skills")),
                scene_numbers_json=_strings(raw.get("scene_numbers")),
                dialogue_count=max(0, int(raw.get("dialogue_count", 0) or 0)),
                page_count_eighths=max(0, int(raw.get("page_count_eighths", 0) or 0)),
                estimated_screen_seconds=max(
                    0, int(raw.get("estimated_screen_seconds", 0) or 0)
                ),
                first_appearance=_text(raw.get("first_appearance"), 24),
                last_appearance=_text(raw.get("last_appearance"), 24),
                story_days_json=_strings(raw.get("story_days")),
                estimated_shoot_days=max(
                    0, int(raw.get("estimated_shoot_days", 0) or 0)
                ),
                ai_confidence=_confidence(raw.get("ai_confidence")),
            )
        )

    seen_locations: set[str] = set()
    for raw in results.get("locations", {}).get("items", []):
        name = _text(raw.get("name"), 180)
        normalized_name = name.casefold() if name else ""
        if not name or normalized_name in seen_locations:
            continue
        seen_locations.add(normalized_name)
        db.session.add(
            CineLocation(
                production_id=production.id,
                script_version_id=script.id,
                screenplay_name=name,
                option_name="",
                notes=_text(raw.get("description"), 5000),
                ai_confidence=_confidence(raw.get("ai_confidence")),
            )
        )

    for category in (
        "props",
        "wardrobe",
        "makeup",
        "vehicles",
        "extras",
        "stunts",
        "vfx",
        "sfx",
        "equipment",
    ):
        seen_elements: set[str] = set()
        for raw in results.get(category, {}).get("items", []):
            name = _text(raw.get("name"), 180)
            normalized_name = name.casefold() if name else ""
            if not name or normalized_name in seen_elements:
                continue
            seen_elements.add(normalized_name)
            db.session.add(
                CineElement(
                    production_id=production.id,
                    script_version_id=script.id,
                    category=category,
                    name=name,
                    normalized_name=normalized_name,
                    description=_text(raw.get("description"), 5000),
                    scene_numbers_json=_strings(raw.get("scene_numbers")),
                    quantity=max(1, int(raw.get("quantity", 1) or 1)),
                    continuity_notes=_join_notes(
                        raw.get("continuity_notes"), raw.get("safety_notes")
                    ),
                    ai_confidence=_confidence(raw.get("ai_confidence")),
                )
            )
    db.session.flush()


def _text(value: Any, limit: int) -> str | None:
    if value is None:
        return None
    cleaned = str(value).strip()
    return cleaned[:limit] or None


def _strings(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [text for item in value if (text := _text(item, 180))][:500]


def _enum(value: Any, allowed: set[str], default: str) -> str:
    normalized = str(value or "").strip()
    return normalized if normalized in allowed else default


def _confidence(value: Any) -> int:
    try:
        return max(0, min(100, int(value)))
    except (TypeError, ValueError):
        return 0


def _join_notes(*values: Any) -> str | None:
    notes = [text for value in values if (text := _text(value, 2500))]
    return "\n".join(notes) or None
