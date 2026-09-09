from __future__ import annotations

import os
from pathlib import Path
from typing import Any, ClassVar

import pytest
from flask import Flask
from flask.testing import FlaskClient
from sqlalchemy.dialects.mysql import LONGTEXT
from sqlalchemy.ext.compiler import compiles

from app import create_app
from app.config import TestConfig
from app.extensions import db


@compiles(LONGTEXT, "sqlite")
def _compile_longtext_sqlite(_element: LONGTEXT, _compiler: Any, **_kwargs: Any) -> str:
    return "TEXT"


@pytest.fixture
def app(tmp_path: Path) -> Flask:
    if os.getenv("RUN_INTEGRATION_TESTS") == "1":
        return create_app(TestConfig)

    class SQLiteTestConfig(TestConfig):
        SQLALCHEMY_DATABASE_URI = f"sqlite:///{tmp_path / 'unit-tests.db'}"
        SQLALCHEMY_ENGINE_OPTIONS: ClassVar[dict[str, Any]] = {}
        LOCAL_STORAGE_PRIVATE_ROOT = str(tmp_path / "private")
        LOCAL_STORAGE_PUBLIC_ROOT = str(tmp_path / "public")

        @classmethod
        def validate(cls, _values: Any) -> None:
            return None

    application = create_app(SQLiteTestConfig)
    with application.app_context():
        db.create_all()
    return application


@pytest.fixture
def client(app: Flask) -> FlaskClient:
    return app.test_client()
