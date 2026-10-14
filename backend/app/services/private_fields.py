from __future__ import annotations

import base64
import hashlib

from cryptography.fernet import Fernet, InvalidToken
from flask import current_app


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
