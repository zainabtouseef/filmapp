from __future__ import annotations

import json
from decimal import Decimal, InvalidOperation
from typing import Any

from app.errors import APIError


def validate_payment_schedule(value: Any) -> list[dict[str, Any]]:
    if value in (None, []):
        return []
    if not isinstance(value, list) or not 1 <= len(value) <= 12:
        raise APIError(
            "booking.invalid_terms", "Use one to twelve payment milestones.", status=422
        )
    result = []
    total = Decimal(0)
    for row in value:
        if not isinstance(row, dict):
            raise APIError(
                "booking.invalid_terms", "Each milestone must be an object.", status=422
            )
        try:
            percent = Decimal(str(row.get("percent", "")))
        except InvalidOperation as exc:
            raise APIError(
                "booking.invalid_terms",
                "Each milestone needs a percentage.",
                status=422,
            ) from exc
        if not percent.is_finite() or not 0 < percent <= 100:
            raise APIError(
                "booking.invalid_terms",
                "Milestone percentages must be positive.",
                status=422,
            )
        name = str(row.get("name", "")).strip()
        if not name or len(name) > 120:
            raise APIError(
                "booking.invalid_terms",
                "Each milestone needs a name up to 120 characters.",
                status=422,
            )
        total += percent
        result.append({"name": name, "percent": float(percent)})
    if total != Decimal(100):
        raise APIError(
            "booking.invalid_terms", "Payment percentages must total 100.", status=422
        )
    return result


def validate_booking_terms(value: Any) -> dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict) or len(json.dumps(value)) > 20000:
        raise APIError(
            "booking.invalid_terms",
            "Booking terms must be an object up to 20 KB.",
            status=422,
        )
    result: dict[str, Any] = {}
    for name in ["deliverables", "usage_rights", "conditions"]:
        text = value.get(name, "")
        if not isinstance(text, str) or len(text) > 4000:
            raise APIError(
                "booking.invalid_terms",
                f"{name} must contain at most 4000 characters.",
                status=422,
            )
        result[name] = text.strip()
    fields = value.get("category_fields", {})
    if (
        not isinstance(fields, dict)
        or len(fields) > 20
        or any(
            not isinstance(k, str)
            or len(k) > 120
            or not isinstance(v, str)
            or len(v) > 1000
            for k, v in fields.items()
        )
    ):
        raise APIError(
            "booking.invalid_terms", "Category fields are invalid.", status=422
        )
    result["category_fields"] = fields
    result["payment_schedule"] = validate_payment_schedule(
        value.get("payment_schedule")
    )
    return result
