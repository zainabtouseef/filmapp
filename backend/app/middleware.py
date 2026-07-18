from __future__ import annotations

import re
import secrets
import time
from typing import Any

import structlog
from flask import Flask, Response, g, request

REQUEST_ID_PATTERN = re.compile(r"^req_[A-Za-z0-9_-]{8,80}$")
logger = structlog.get_logger(__name__)


def _request_id() -> str:
    supplied = request.headers.get("X-Request-ID", "")
    if REQUEST_ID_PATTERN.fullmatch(supplied):
        return supplied
    return f"req_{secrets.token_urlsafe(16)}"


def register_middleware(app: Flask) -> None:
    @app.before_request
    def start_request() -> None:
        g.request_id = _request_id()
        g.request_started = time.perf_counter()
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(
            request_id=g.request_id,
            method=request.method,
            path=request.path,
        )

    @app.after_request
    def finish_request(response: Response) -> Response:
        response.headers["X-Request-ID"] = g.get("request_id", "req_unavailable")
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = (
            "camera=(), microphone=(), geolocation=()"
        )
        response.headers["Content-Security-Policy"] = "default-src 'none'"
        response.headers["Cache-Control"] = "no-store"
        if app.config["APP_ENV"] == "production":
            response.headers["Strict-Transport-Security"] = (
                "max-age=63072000; includeSubDomains"
            )
        started: float | None = g.get("request_started")
        duration_ms = (
            round((time.perf_counter() - started) * 1000, 2) if started else None
        )
        event: dict[str, Any] = {
            "status": response.status_code,
            "duration_ms": duration_ms,
        }
        logger.info("request.completed", **event)
        return response
