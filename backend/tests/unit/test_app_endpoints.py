from __future__ import annotations

from unittest.mock import Mock, patch

from flask import Flask
from flask.testing import FlaskClient

from app.errors import APIError


def test_liveness_envelope_and_security_headers(client: FlaskClient) -> None:
    response = client.get(
        "/api/v1/health/live",
        headers={"X-Request-ID": "req_client_request_123"},
    )

    assert response.status_code == 200
    assert response.json == {
        "data": {"service": "cineconnect-api", "status": "ok"},
        "meta": {
            "pagination": None,
            "request_id": "req_client_request_123",
        },
    }
    assert response.headers["X-Request-ID"] == "req_client_request_123"
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["Cache-Control"] == "no-store"


def test_invalid_request_id_is_replaced(client: FlaskClient) -> None:
    response = client.get(
        "/api/v1/health/live",
        headers={"X-Request-ID": "contains spaces"},
    )

    assert response.status_code == 200
    assert response.headers["X-Request-ID"].startswith("req_")
    assert response.headers["X-Request-ID"] != "contains spaces"


def test_bootstrap_has_no_real_payment_claim(client: FlaskClient) -> None:
    response = client.get("/api/v1/app/public-config")

    assert response.status_code == 200
    payments = response.json["data"]["support"]["payments"]
    assert payments["mode"] == "sandbox"
    assert payments["notice"] == "Demo payment only — no money is moved."


def test_roles_are_stable_and_kyc_gated(client: FlaskClient) -> None:
    response = client.get("/api/v1/roles")

    assert response.status_code == 200
    roles = response.json["data"]
    assert roles[0]["code"] == "director_producer"
    assert len(roles) == 11
    assert all(role["requires_kyc"] for role in roles)


def test_openapi_contract_is_served(client: FlaskClient) -> None:
    response = client.get("/api/v1/openapi.yaml")

    assert response.status_code == 200
    assert response.mimetype == "application/yaml"
    assert response.text.startswith("openapi: 3.1.0")


def test_unknown_route_uses_error_envelope(client: FlaskClient) -> None:
    response = client.get("/api/v1/does-not-exist")

    assert response.status_code == 404
    assert response.json["error"]["code"] == "http.not_found"
    assert response.json["error"]["request_id"].startswith("req_")


def test_readiness_reports_available_dependencies(client: FlaskClient) -> None:
    redis_client = Mock()
    redis_client.ping.return_value = True

    with (
        patch("app.api.health.db.session.execute", return_value=1),
        patch("app.api.health.Redis.from_url", return_value=redis_client),
    ):
        response = client.get("/api/v1/health/ready")

    assert response.status_code == 200
    assert response.json["data"]["dependencies"] == {
        "database": "ok",
        "redis": "ok",
    }
    redis_client.close.assert_called_once()


def test_readiness_uses_safe_error_envelope(client: FlaskClient) -> None:
    redis_client = Mock()
    redis_client.ping.side_effect = ConnectionError("secret internal address")

    with (
        patch(
            "app.api.health.db.session.execute",
            side_effect=ConnectionError("secret database address"),
        ),
        patch("app.api.health.Redis.from_url", return_value=redis_client),
    ):
        response = client.get("/api/v1/health/ready")

    assert response.status_code == 503
    assert response.json["error"]["code"] == "health.dependencies_unavailable"
    assert "secret" not in response.text
    assert set(response.json["error"]["fields"]) == {"database", "redis"}


def test_api_error_handler_serializes_fields(app: Flask) -> None:
    @app.get("/test-error")
    def test_error() -> None:
        raise APIError(
            "validation.invalid",
            "Invalid request.",
            status=422,
            fields={"email": ["Invalid email."]},
        )

    response = app.test_client().get("/test-error")

    assert response.status_code == 422
    assert response.json["error"]["fields"] == {"email": ["Invalid email."]}
