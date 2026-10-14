"""Run demo maintenance only in the isolated test database; verify rerun integrity."""

import hashlib
from pathlib import Path
from unittest.mock import patch

import pytest
from sqlalchemy import func, select, text

from app.extensions import db
from app.models.cineplanner import CineScene
from app.models.files import FileAsset
from app.models.identity import Role, User
from app.models.projects import Project, ProjectFile
from app.scripts import seed_cinema_demo_media as media
from app.scripts import seed_cineplanner_demo as planner


def test_cineplanner_seed_rerun_keeps_scene_and_file_integrity(app):
    with app.app_context():
        db.session.execute(text("PRAGMA foreign_keys=ON"))
        db.session.add(
            Role(code="director_producer", name="Producer", portal_route="/director")
        )
        db.session.commit()
        first = planner.seed()
        second = planner.seed()
        assert first["scenes"] == second["scenes"] and first["scenes"] >= 50
        assert first["production_id"] == second["production_id"]
        assert (
            db.session.scalar(select(func.count()).select_from(CineScene))
            == first["scenes"]
        )
        row = db.session.execute(select(FileAsset)).scalar_one()
        content = (
            Path(app.config["LOCAL_STORAGE_PRIVATE_ROOT"]) / row.storage_key
        ).read_bytes()
        assert hashlib.sha256(content).hexdigest() == row.checksum_sha256
        assert len(content) == row.size_bytes


def test_cinema_seed_rerun_updates_links_without_duplicates(app):
    with app.app_context():
        with pytest.raises(RuntimeError, match="Demo owner not found"):
            media.seed()
        db.session.add(
            User(
                email=media.OWNER_EMAIL,
                display_name="QA Owner",
                password_hash="fixture",
                terms_version="2026-10",
            )
        )
        db.session.commit()
        media.seed()
        media.seed()
        assert db.session.scalar(select(func.count()).select_from(Project)) == len(
            media.DEMO_MEDIA
        )
        assert db.session.scalar(select(func.count()).select_from(ProjectFile)) == len(
            media.DEMO_MEDIA
        )
        for row in db.session.scalars(select(ProjectFile)):
            assert row.file_id is None and row.external_provider == "youtube"
            assert row.external_url.startswith("https://www.youtube.com/")


def test_demo_seed_rejects_missing_or_invalid_screenplay_before_writes(app, tmp_path):
    path = tmp_path / "screenplay.pdf"
    with app.app_context(), patch.object(planner, "DEMO_PDF_PATH", path):
        with pytest.raises(RuntimeError, match="not found"):
            planner.seed()
        path.write_text("not a pdf")
        with pytest.raises(RuntimeError, match="not a valid PDF"):
            planner.seed()
        assert db.session.scalar(select(func.count()).select_from(User)) == 0
