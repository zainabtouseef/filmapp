from __future__ import annotations

import os

import pytest
from flask.testing import FlaskClient


@pytest.mark.integration
@pytest.mark.skipif(
    os.getenv("RUN_INTEGRATION_TESTS") != "1",
    reason="Set RUN_INTEGRATION_TESTS=1 with MySQL and Redis running.",
)
def test_readiness_checks_mysql_and_redis(client: FlaskClient) -> None:
    response = client.get("/api/v1/health/ready")

    assert response.status_code == 200
    assert response.json["data"]["dependencies"] == {
        "database": "ok",
        "redis": "ok",
    }
