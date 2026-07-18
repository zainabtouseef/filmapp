from __future__ import annotations

import pytest
from flask import Flask
from flask.testing import FlaskClient

from app import create_app
from app.config import TestConfig


@pytest.fixture
def app() -> Flask:
    return create_app(TestConfig)


@pytest.fixture
def client(app: Flask) -> FlaskClient:
    return app.test_client()
