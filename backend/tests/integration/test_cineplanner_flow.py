from __future__ import annotations

import hashlib
import json
from pathlib import Path
from threading import Barrier
from types import SimpleNamespace
from typing import Any, ClassVar
from unittest.mock import patch

import pytest
from flask import Flask
from flask.testing import FlaskClient
from sqlalchemy import select
from sqlalchemy.dialects.mysql import LONGTEXT
from sqlalchemy.ext.compiler import compiles

from app import create_app
from app.config import TestConfig
from app.extensions import db
from app.models.cineplanner import CineAIJob, CineProduction
from app.models.files import FileAsset
from app.models.identity import Role, User
from app.services.cineplanner_ai import STAGES, analyze_screenplay_job
from tests.cineplanner_synthetic import screenplay_results, write_screenplay_pdf

pytestmark = pytest.mark.integration


@compiles(LONGTEXT, "sqlite")
def _compile_longtext_sqlite(_element: LONGTEXT, _compiler: Any, **_kwargs: Any) -> str:
    return "TEXT"


@pytest.fixture
def cineplanner_app(tmp_path: Path) -> Flask:
    class CinePlannerTestConfig(TestConfig):
        SQLALCHEMY_DATABASE_URI = f"sqlite:///{tmp_path / 'cineplanner.db'}"
        SQLALCHEMY_ENGINE_OPTIONS: ClassVar[dict[str, Any]] = {}
        LOCAL_STORAGE_PRIVATE_ROOT = str(tmp_path / "private")
        LOCAL_STORAGE_PUBLIC_ROOT = str(tmp_path / "public")
        OPENAI_API_KEY = "test-openai-key"
        CINEPLANNER_AI_PARALLELISM = 4

        @classmethod
        def validate(cls, _values: Any) -> None:
            return None

    app = create_app(CinePlannerTestConfig)
    with app.app_context():
        db.create_all()
        db.session.add(
            Role(
                code="director_producer",
                name="Director / Producer",
                portal_route="/director",
                requires_kyc=False,
                display_order=1,
            )
        )
        db.session.commit()
    return app


@pytest.fixture
def cineplanner_client(cineplanner_app: Flask) -> FlaskClient:
    return cineplanner_app.test_client()


def _headers(client: FlaskClient) -> dict[str, str]:
    registration = client.post(
        "/api/v1/auth/register",
        json={
            "email": "monsoon-producer@example.com",
            "password": "StrongPass123!",
            "display_name": "Monsoon Producer",
            "initial_role": "director_producer",
            "terms_version": "2026-07",
        },
    )
    assert registration.status_code == 201, registration.text
    login = client.post(
        "/api/v1/auth/login",
        json={
            "email": "monsoon-producer@example.com",
            "password": "StrongPass123!",
        },
    )
    assert login.status_code == 200, login.text
    token = login.json["data"]["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _screenplay_file(app: Flask, headers: dict[str, str]) -> str:
    client = app.test_client()
    me = client.get("/api/v1/me", headers=headers)
    assert me.status_code == 200, me.text
    with app.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == me.json["data"]["public_id"])
        ).scalar_one()
        storage_key = "screenplays/the-monsoon-ledger.pdf"
        path = Path(app.config["LOCAL_STORAGE_PRIVATE_ROOT"]) / storage_key
        write_screenplay_pdf(path)
        content = path.read_bytes()
        asset = FileAsset(
            owner_user_id=user.id,
            storage_key=storage_key,
            bucket=app.config["OBJECT_STORAGE_BUCKET_PRIVATE"],
            mime_type="application/pdf",
            size_bytes=len(content),
            checksum_sha256=hashlib.sha256(content).hexdigest(),
            visibility="private",
            scan_status="clean",
            processing_status="ready",
            original_name="the-monsoon-ledger.pdf",
        )
        db.session.add(asset)
        db.session.commit()
        return asset.public_id


class _FakeOpenAIFiles:
    deleted_ids: list[str]

    def __init__(self) -> None:
        self.deleted_ids = []

    def create(self, **kwargs: Any) -> SimpleNamespace:
        assert kwargs["purpose"] == "user_data"
        assert kwargs["expires_after"]["seconds"] == 86400
        assert kwargs["file"].read(5) == b"%PDF-"
        return SimpleNamespace(id="file_cineplanner_test")

    def delete(self, file_id: str) -> None:
        self.deleted_ids.append(file_id)


class _FakeOpenAIResponses:
    def __init__(self, results: dict[str, Any]) -> None:
        self.results = results
        self.stages: list[str] = []
        self.barrier = Barrier(len(STAGES))

    def create(self, **kwargs: Any) -> SimpleNamespace:
        assert kwargs["store"] is False
        assert kwargs["text"]["format"]["strict"] is True
        assert kwargs["reasoning"] == {"effort": "low"}
        stage = kwargs["text"]["format"]["name"].removeprefix("cineplanner_")
        self.stages.append(stage)
        self.barrier.wait(timeout=2)
        keys = kwargs["text"]["format"]["schema"]["properties"]
        return SimpleNamespace(
            output_text=json.dumps({key: self.results[key] for key in keys})
        )


class _FakeOpenAI:
    def __init__(self, results: dict[str, Any]) -> None:
        self.files = _FakeOpenAIFiles()
        self.responses = _FakeOpenAIResponses(results)


def _complete_ai_parse(app: Flask, production_id: str) -> None:
    with app.app_context():
        production = db.session.execute(
            select(CineProduction).where(CineProduction.public_id == production_id)
        ).scalar_one()
        job = db.session.execute(
            select(CineAIJob).where(CineAIJob.production_id == production.id)
        ).scalar_one()
        results = screenplay_results()
        results["locations"]["items"].append(dict(results["locations"]["items"][0]))
        fake_client = _FakeOpenAI(results)
        with patch("openai.OpenAI", return_value=fake_client):
            result = analyze_screenplay_job(job.public_id)
        assert result["status"] == "completed"
        assert sorted(fake_client.responses.stages) == sorted(
            stage for stage, _, _ in STAGES
        )
        assert fake_client.files.deleted_ids == ["file_cineplanner_test"]


def test_portal_projects_automatically_receive_one_cineplanner_workspace(
    cineplanner_client: FlaskClient,
) -> None:
    headers = _headers(cineplanner_client)
    project_response = cineplanner_client.post(
        "/api/v1/projects",
        headers=headers,
        json={
            "title": "Connected Feature",
            "project_type": "film",
            "currency": "PKR",
            "status": "active",
        },
    )
    assert project_response.status_code == 201, project_response.text
    project_id = project_response.json["data"]["project"]["public_id"]

    listed = cineplanner_client.get("/api/v1/cineplanner/productions", headers=headers)
    assert listed.status_code == 200, listed.text
    matching = [
        item
        for item in listed.json["data"]["productions"]
        if item["project_id"] == project_id
    ]
    assert len(matching) == 1

    idempotent = cineplanner_client.post(
        "/api/v1/cineplanner/productions",
        headers=headers,
        json={"title": "Connected Feature", "project_id": project_id},
    )
    assert idempotent.status_code == 200, idempotent.text
    assert (
        idempotent.json["data"]["production"]["public_id"] == matching[0]["public_id"]
    )


def test_complete_cineplanner_producer_workflow(
    cineplanner_app: Flask, cineplanner_client: FlaskClient
) -> None:
    headers = _headers(cineplanner_client)

    created = cineplanner_client.post(
        "/api/v1/cineplanner/productions",
        headers=headers,
        json={
            "title": "The Monsoon Ledger",
            "currency": "PKR",
            "production_start_date": "2026-09-07",
            "maximum_shoot_days": 45,
            "working_hours_limit": 12,
            "budget_ceiling_minor": 250_000_000,
        },
    )
    assert created.status_code == 201, created.text
    production_id = created.json["data"]["production"]["public_id"]

    file_id = _screenplay_file(cineplanner_app, headers)
    with patch("app.api.cineplanner._enqueue_analysis") as enqueue:
        uploaded = cineplanner_client.post(
            f"/api/v1/cineplanner/productions/{production_id}/scripts",
            headers=headers,
            json={"file_id": file_id, "label": "Synthetic QA Draft"},
        )
    assert uploaded.status_code == 202, uploaded.text
    enqueue.assert_called_once()
    _complete_ai_parse(cineplanner_app, production_id)

    approved = cineplanner_client.post(
        f"/api/v1/cineplanner/productions/{production_id}/approve-breakdown",
        headers=headers,
    )
    assert approved.status_code == 200, approved.text

    snapshot = cineplanner_client.get(
        f"/api/v1/cineplanner/productions/{production_id}", headers=headers
    )
    assert snapshot.status_code == 200, snapshot.text
    data = snapshot.json["data"]
    assert data["dashboard"]["total_scenes"] == 90
    assert data["dashboard"]["lead_characters"] == 4
    character_id = data["characters"][0]["public_id"]

    actor = cineplanner_client.post(
        "/api/v1/cineplanner/actors",
        headers=headers,
        json={
            "name": "Ayesha Noor",
            "playing_age_min": 28,
            "playing_age_max": 42,
            "languages": ["English", "Urdu"],
            "skills": ["Dramatic acting"],
            "daily_rate_minor": 750_000,
        },
    )
    assert actor.status_code == 201, actor.text
    actor_id = actor.json["data"]["actor"]["public_id"]

    for status in ("shortlisted", "confirmed"):
        cast = cineplanner_client.post(
            f"/api/v1/cineplanner/productions/{production_id}/cast-assignments",
            headers=headers,
            json={
                "character_id": character_id,
                "actor_id": actor_id,
                "status": status,
            },
        )
        assert cast.status_code == 201, cast.text
        assert cast.json["data"]["assignment"]["status"] == status

    availability = cineplanner_client.post(
        f"/api/v1/cineplanner/actors/{actor_id}/availability",
        headers=headers,
        json={
            "production_id": production_id,
            "starts_on": "2026-09-07",
            "ends_on": "2026-10-31",
            "status": "available",
        },
    )
    assert availability.status_code == 201, availability.text

    location = data["locations"][0]
    confirmed_location = cineplanner_client.patch(
        f"/api/v1/cineplanner/productions/{production_id}/locations/"
        f"{location['public_id']}",
        headers=headers,
        json={
            "option_name": "Harbor Unit Base",
            "address": "Pier 7, Karachi",
            "rental_rate_minor": 1_200_000,
            "status": "confirmed",
        },
    )
    assert confirmed_location.status_code == 200, confirmed_location.text

    preview = cineplanner_client.post(
        f"/api/v1/cineplanner/productions/{production_id}/schedule/generate",
        headers=headers,
        json={"apply": False},
    )
    assert preview.status_code == 200, preview.text
    assert {row["strategy"] for row in preview.json["data"]["plans"]} == {
        "lowest_cost",
        "fastest",
        "balanced",
    }
    applied = cineplanner_client.post(
        f"/api/v1/cineplanner/productions/{production_id}/schedule/generate",
        headers=headers,
        json={"apply": True, "strategy": "balanced"},
    )
    assert applied.status_code == 200, applied.text

    schedule = cineplanner_client.get(
        f"/api/v1/cineplanner/productions/{production_id}/schedule",
        headers=headers,
    )
    assert schedule.status_code == 200, schedule.text
    days = schedule.json["data"]["days"]
    scene_events = [
        event for event in days[0]["events"] if event["event_type"] == "scene"
    ]
    assert len(scene_events) >= 2
    moved = cineplanner_client.patch(
        f"/api/v1/cineplanner/productions/{production_id}/schedule/events/"
        f"{scene_events[1]['public_id']}",
        headers=headers,
        json={
            "shoot_day_id": days[0]["public_id"],
            "starts_at": scene_events[0]["starts_at"],
            "ends_at": scene_events[0]["ends_at"],
        },
    )
    assert moved.status_code == 200, moved.text
    conflicted = cineplanner_client.get(
        f"/api/v1/cineplanner/productions/{production_id}/schedule",
        headers=headers,
    )
    assert any(
        item["type"] == "schedule_overlap"
        for item in conflicted.json["data"]["conflicts"]
    )

    optimization = cineplanner_client.post(
        f"/api/v1/cineplanner/productions/{production_id}/schedule/optimize",
        headers=headers,
        json={"apply": True},
    )
    assert optimization.status_code == 200, optimization.text
    assert "estimated_savings_minor" in optimization.json["data"]

    budget = cineplanner_client.get(
        f"/api/v1/cineplanner/productions/{production_id}/budget", headers=headers
    )
    assert budget.status_code == 200, budget.text
    assert budget.json["data"]["lines"]

    locked = cineplanner_client.post(
        f"/api/v1/cineplanner/productions/{production_id}/schedule/lock",
        headers=headers,
        json={"locked": True},
    )
    assert locked.status_code == 200, locked.text
    final_schedule = cineplanner_client.get(
        f"/api/v1/cineplanner/productions/{production_id}/schedule",
        headers=headers,
    ).json["data"]
    shoot_day_id = final_schedule["days"][0]["public_id"]
    call_sheet = cineplanner_client.post(
        f"/api/v1/cineplanner/productions/{production_id}/call-sheets",
        headers=headers,
        json={"shoot_day_id": shoot_day_id},
    )
    assert call_sheet.status_code == 201, call_sheet.text
    sheet = call_sheet.json["data"]["call_sheet"]
    assert sheet["payload"]["address"] == "Pier 7, Karachi"
    downloaded = cineplanner_client.get(f"/api/v1{sheet['pdf_url']}", headers=headers)
    assert downloaded.status_code == 200, downloaded.text
    assert downloaded.data.startswith(b"%PDF-")

    for report_type in (
        "full-script-breakdown",
        "cast-breakdown",
        "day-out-of-days",
        "location-report",
        "crew-report",
        "budget-report",
        "call-sheets",
        "production-progress",
        "script-revision-report",
    ):
        report = cineplanner_client.get(
            f"/api/v1/cineplanner/productions/{production_id}/reports/{report_type}",
            headers=headers,
        )
        assert report.status_code == 200, f"{report_type}: {report.text}"
    for extension, signature in (
        ("csv", None),
        ("xlsx", b"PK"),
        ("pdf", b"%PDF-"),
    ):
        report = cineplanner_client.get(
            f"/api/v1/cineplanner/productions/{production_id}/reports/"
            f"scene-breakdown.{extension}",
            headers=headers,
        )
        assert report.status_code == 200, report.text
        if signature:
            assert report.data.startswith(signature)
