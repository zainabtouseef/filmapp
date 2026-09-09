from __future__ import annotations

from datetime import date
from pathlib import Path
from unittest.mock import patch

from flask import Flask

from app.api.cineplanner import _export_row, _render_call_sheet_pdf, _render_report_pdf
from app.models.cineplanner import CineProduction, CineScene
from app.services.cineplanner_ai import STAGES
from app.services.cineplanner_scheduling import build_schedule_plan
from tests.cineplanner_synthetic import screenplay_results, write_screenplay_pdf


def _scene(number: int, location: str, *, night: bool = False) -> CineScene:
    return CineScene(
        scene_number=str(number),
        sort_order=number,
        slugline=f"INT. {location} - {'NIGHT' if night else 'DAY'}",
        int_ext="INT",
        location_name=location,
        time_of_day="NIGHT" if night else "DAY",
        page_length_eighths=8,
        estimated_screen_seconds=60,
        summary="Synthetic screenplay scene.",
        cast_json=[],
        extras_json=[],
        props_json=[],
        wardrobe_json=[],
        makeup_json=[],
        vehicles_json=[],
        weapons_json=[],
        animals_json=[],
        stunts_json=[],
        vfx_json=[],
        sfx_json=[],
        equipment_json=[],
        complexity="medium",
        ai_confidence=90,
        review_status="ai_draft",
    )


def test_cineplanner_routes_are_registered(app: Flask) -> None:
    routes = {rule.rule for rule in app.url_map.iter_rules()}

    assert {
        "/api/v1/cineplanner/productions",
        "/api/v1/cineplanner/actors",
        "/api/v1/cineplanner/productions/<public_id>/schedule",
        "/api/v1/cineplanner/productions/<public_id>/schedule/generate",
        "/api/v1/cineplanner/productions/<public_id>/assistant",
        "/api/v1/cineplanner/productions/<public_id>/call-sheets",
    }.issubset(routes)


def test_openai_pipeline_uses_parallel_safe_strict_passes() -> None:
    stage_names = [stage for stage, _, _ in STAGES]

    assert stage_names == [
        "script_structure",
        "people_and_places",
        "production_elements",
        "continuity_and_complexity",
    ]
    for _, _, schema in STAGES:
        assert schema["type"] == "object"
        assert schema["additionalProperties"] is False
        assert set(schema["required"]) == set(schema["properties"])


def test_scheduler_produces_all_strategies_without_exceeding_day_limit() -> None:
    production = CineProduction(
        title="Synthetic Feature",
        currency="PKR",
        production_start_date=date(2026, 9, 7),
        maximum_shoot_days=10,
        working_hours_limit=12,
        settings_json={},
    )
    scenes = [
        _scene(1, "Hospital"),
        _scene(2, "Police Station"),
        _scene(3, "Hospital", night=True),
        _scene(4, "Street"),
    ]

    with patch(
        "app.services.cineplanner_scheduling._estimate_plan_cost",
        return_value=125_000,
    ):
        plans = [
            build_schedule_plan(production, scenes, strategy)
            for strategy in ("lowest_cost", "fastest", "balanced")
        ]

    assert {plan["strategy"] for plan in plans} == {
        "lowest_cost",
        "fastest",
        "balanced",
    }
    assert all(plan["shoot_days"] <= production.maximum_shoot_days for plan in plans)
    assert all(plan["estimated_cost_minor"] == 125_000 for plan in plans)
    assert all(plan["days"] for plan in plans)


def test_original_synthetic_screenplay_exercises_production_scale(
    tmp_path: Path,
) -> None:
    results = screenplay_results()
    output = tmp_path / "the-monsoon-ledger.pdf"
    write_screenplay_pdf(output)

    scenes = results["scenes"]["items"]
    characters = results["characters"]["items"]
    assert len(scenes) == 90
    assert len([row for row in characters if row["classification"] == "lead"]) == 4
    assert len(results["locations"]["items"]) >= 15
    assert any(row["time_of_day"] == "NIGHT" for row in scenes)
    assert any(row["int_ext"] == "EXT" for row in scenes)
    assert any(row["vehicles"] for row in scenes)
    assert any(row["weapons"] for row in scenes)
    assert any(row["stunts"] for row in scenes)
    assert any(row["vfx"] for row in scenes)
    assert any(row["sfx"] for row in scenes)
    assert output.read_bytes().startswith(b"%PDF-")


def test_pdf_renderers_escape_content_and_produce_valid_documents() -> None:
    call_sheet = _render_call_sheet_pdf(
        {
            "production": "Monsoon <Ledger>",
            "shoot_day": 1,
            "shoot_date": "2026-09-07",
            "location": "City Hall & Archive",
            "crew_call": "06:30",
            "expected_wrap": "18:30",
            "meals": ["12:30"],
            "actor_calls": ["MARA VALE"],
            "scenes": [
                {
                    "scene_number": "1",
                    "slugline": "INT. CITY HALL - DAY",
                    "page_length_eighths": 8,
                    "cast": ["MARA VALE"],
                }
            ],
            "props": ["Ledger"],
            "vehicles": [],
            "equipment": ["Rain cover"],
            "extras": [],
            "safety_notes": ["Wet floor"],
        },
        1,
    )
    report = _render_report_pdf(
        "Monsoon <Ledger>",
        "scene-breakdown",
        [_export_row({"scene": "1", "cast": ["MARA VALE"]})],
    )

    assert call_sheet.read(5) == b"%PDF-"
    assert report.read(5) == b"%PDF-"
