from __future__ import annotations

import hashlib
import secrets
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from flask import current_app, request
from sqlalchemy import select

from app.extensions import db
from app.models.base import utc_now
from app.models.identity import AuthSecurityEvent, User, UserSession

password_hasher = PasswordHasher(
    time_cost=3,
    memory_cost=65536,
    parallelism=2,
    hash_len=32,
    salt_len=16,
)


@dataclass(frozen=True)
class TokenPair:
    access_token: str
    refresh_token: str
    expires_in: int
    token_type: str = "Bearer"


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def new_opaque_token() -> str:
    return secrets.token_urlsafe(48)


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password_hash: str, password: str) -> bool:
    try:
        return password_hasher.verify(password_hash, password)
    except VerifyMismatchError:
        return False


def _jwt_payload(user: User, expires_at: datetime) -> dict[str, Any]:
    active_role = next((role.role.code for role in user.roles if role.is_primary), None)
    return {
        "iss": "cineconnect-api",
        "sub": user.public_id,
        "uid": str(user.id),
        "roles": [
            user_role.role.code
            for user_role in user.roles
            if user_role.status == "active" and user_role.role.is_active
        ],
        "active_role": active_role,
        "status": user.status,
        "iat": int(utc_now().timestamp()),
        "exp": int(expires_at.timestamp()),
        "jti": uuid.uuid4().hex,
    }


def issue_token_pair(user: User) -> TokenPair:
    access_minutes = int(current_app.config.get("ACCESS_TOKEN_MINUTES", 15))
    refresh_days = int(current_app.config.get("REFRESH_TOKEN_DAYS", 30))
    access_expires = utc_now() + timedelta(minutes=access_minutes)
    refresh_expires = utc_now() + timedelta(days=refresh_days)
    access_token = jwt.encode(
        _jwt_payload(user, access_expires),
        current_app.config["JWT_SECRET_KEY"],
        algorithm="HS256",
    )
    refresh_token = new_opaque_token()
    db.session.add(
        UserSession(
            user_id=user.id,
            refresh_token_hash=hash_token(refresh_token),
            refresh_token_family=uuid.uuid4().hex,
            expires_at=refresh_expires,
            ip_address=request.headers.get("X-Forwarded-For", request.remote_addr),
            user_agent=request.headers.get("User-Agent", "")[:512],
        )
    )
    return TokenPair(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=access_minutes * 60,
    )


def rotate_refresh_token(refresh_token: str) -> tuple[User, TokenPair]:
    now = utc_now()
    session = db.session.execute(
        select(UserSession).where(
            UserSession.refresh_token_hash == hash_token(refresh_token)
        )
    ).scalar_one_or_none()
    if (
        session is None
        or session.revoked_at is not None
        or as_utc(session.expires_at) <= now
    ):
        raise ValueError("Refresh token is invalid or expired.")

    new_refresh_token = new_opaque_token()
    new_hash = hash_token(new_refresh_token)
    session.previous_refresh_token_hash = session.refresh_token_hash
    session.refresh_token_hash = new_hash
    session.last_used_at = now
    session.user.last_login_at = now
    access_minutes = int(current_app.config.get("ACCESS_TOKEN_MINUTES", 15))
    access_expires = now + timedelta(minutes=access_minutes)
    access_token = jwt.encode(
        _jwt_payload(session.user, access_expires),
        current_app.config["JWT_SECRET_KEY"],
        algorithm="HS256",
    )
    return (
        session.user,
        TokenPair(
            access_token=access_token,
            refresh_token=new_refresh_token,
            expires_in=access_minutes * 60,
        ),
    )


def revoke_refresh_token(refresh_token: str) -> bool:
    session = db.session.execute(
        select(UserSession).where(
            UserSession.refresh_token_hash == hash_token(refresh_token)
        )
    ).scalar_one_or_none()
    if session is None:
        return False
    session.revoked_at = utc_now()
    return True


def decode_access_token(token: str) -> dict[str, Any]:
    return jwt.decode(
        token,
        current_app.config["JWT_SECRET_KEY"],
        algorithms=["HS256"],
        issuer="cineconnect-api",
    )


def record_auth_event(
    event_type: str,
    *,
    success: bool,
    user: User | None = None,
    metadata: dict[str, Any] | None = None,
) -> None:
    db.session.add(
        AuthSecurityEvent(
            user_id=user.id if user else None,
            event_type=event_type,
            success=success,
            ip_address=request.headers.get("X-Forwarded-For", request.remote_addr),
            user_agent=request.headers.get("User-Agent", "")[:512],
            metadata_json=metadata or {},
        )
    )
