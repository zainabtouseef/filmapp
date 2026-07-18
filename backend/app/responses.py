from __future__ import annotations

from typing import Any

from flask import g


def success(data: Any, *, pagination: dict[str, Any] | None = None) -> dict[str, Any]:
    return {
        "data": data,
        "meta": {
            "request_id": g.request_id,
            "pagination": pagination,
        },
    }


def error(
    code: str,
    message: str,
    *,
    fields: dict[str, list[str]] | None = None,
) -> dict[str, Any]:
    return {
        "error": {
            "code": code,
            "message": message,
            "fields": fields or {},
            "request_id": g.get("request_id", "req_unavailable"),
        }
    }
