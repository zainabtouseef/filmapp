from __future__ import annotations

from typing import Any

import structlog
from flask import Flask, jsonify
from werkzeug.exceptions import HTTPException

from app.responses import error

logger = structlog.get_logger(__name__)


class APIError(Exception):
    def __init__(
        self,
        code: str,
        message: str,
        *,
        status: int = 400,
        fields: dict[str, list[str]] | None = None,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status = status
        self.fields = fields


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(APIError)
    def handle_api_error(exc: APIError) -> tuple[Any, int]:
        return (
            jsonify(error(exc.code, exc.message, fields=exc.fields)),
            exc.status,
        )

    @app.errorhandler(HTTPException)
    def handle_http_error(exc: HTTPException) -> tuple[Any, int]:
        code = f"http.{exc.name.lower().replace(' ', '_')}"
        return jsonify(error(code, exc.description or exc.name)), exc.code or 500

    @app.errorhandler(Exception)
    def handle_unexpected_error(exc: Exception) -> tuple[Any, int]:
        logger.exception("request.failed", error_type=type(exc).__name__)
        return (
            jsonify(
                error(
                    "internal.unexpected",
                    "An unexpected server error occurred.",
                )
            ),
            500,
        )
