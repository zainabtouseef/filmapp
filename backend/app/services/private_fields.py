from __future__ import annotations

import base64
import hashlib
from typing import Any

from cryptography.fernet import Fernet, InvalidToken
from flask import current_app

from app.errors import APIError


def _fernet(value: str) -> Fernet:
    return Fernet(base64.urlsafe_b64encode(hashlib.sha256(value.encode()).digest()))


def encrypt_private_value(value: str) -> str:
    key = str(
        current_app.config.get("FIELD_ENCRYPTION_KEY")
        or current_app.config["SECRET_KEY"]
    )
    return "fernet:v2:" + _fernet(key).encrypt(value.encode()).decode("ascii")


def decrypt_private_value(value: str) -> str:
    if not value.startswith("fernet:"):
        return value
    payload = value.removeprefix("fernet:").removeprefix("v2:")
    keys = [
        current_app.config.get("FIELD_ENCRYPTION_KEY"),
        current_app.config["SECRET_KEY"],
    ]
    keys.extend(
        str(current_app.config.get("LEGACY_FIELD_ENCRYPTION_KEYS", "")).split(",")
    )
    for key in keys:
        if not key:
            continue
        try:
            return _fernet(str(key)).decrypt(payload.encode()).decode()
        except InvalidToken:
            continue
    raise ValueError("The private field encryption key is unavailable")


def encrypt_optional_private_value(value: Any, field: str) -> str | None:
    if value is None or value == "":
        return None
    if not isinstance(value, str) or len(value) > 4000:
        raise APIError(
            "validation.invalid",
            "Request validation failed.",
            status=422,
            fields={field: ["Enter text containing at most 4000 characters."]},
        )
    value = value.strip()
    return encrypt_private_value(value) if value else None


def private_field_value(value: str | None) -> str | None:
    # Old placeholder tokens contain no recoverable submitted value.
    if not value or not value.startswith("fernet:"):
        return None
    return decrypt_private_value(value)
