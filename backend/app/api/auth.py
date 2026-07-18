from __future__ import annotations

from datetime import timedelta
from typing import Any

import jwt
from email_validator import EmailNotValidError, validate_email
from flask import Blueprint, Response, g, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import select

from app.errors import APIError
from app.extensions import db, limiter
from app.models.base import utc_now
from app.models.identity import (
    NotificationPreference,
    PasswordResetToken,
    Role,
    User,
    UserRole,
    UserSettings,
)
from app.responses import success
from app.security import (
    as_utc,
    decode_access_token,
    hash_password,
    hash_token,
    issue_token_pair,
    new_opaque_token,
    record_auth_event,
    revoke_refresh_token,
    rotate_refresh_token,
    verify_password,
)

auth_blueprint = Blueprint("auth", __name__)


def _json_body() -> dict[str, Any]:
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        raise APIError("validation.invalid_json", "Request body must be a JSON object.")
    return payload


def _normal_email(value: Any) -> str:
    if not isinstance(value, str):
        raise APIError(
            "validation.invalid",
            "Email is required.",
            status=422,
            fields={"email": ["Email is required."]},
        )
    try:
        result = validate_email(value, check_deliverability=False)
    except EmailNotValidError as exc:
        raise APIError(
            "validation.invalid",
            "Request validation failed.",
            status=422,
            fields={"email": [str(exc)]},
        ) from exc
    return result.normalized.lower()


def _validate_password(value: Any) -> str:
    if not isinstance(value, str) or len(value) < 10:
        raise APIError(
            "validation.invalid",
            "Request validation failed.",
            status=422,
            fields={"password": ["Password must contain at least 10 characters."]},
        )
    return value


def _serialize_role(role: Role) -> dict[str, Any]:
    return {
        "code": role.code,
        "name": role.name,
        "portal_route": role.portal_route,
        "requires_kyc": role.requires_kyc,
    }


def _serialize_user(user: User) -> dict[str, Any]:
    active_roles = [
        user_role for user_role in user.roles if user_role.status == "active"
    ]
    return {
        "public_id": user.public_id,
        "email": user.email,
        "display_name": user.display_name,
        "status": user.status,
        "roles": [
            {
                **_serialize_role(user_role.role),
                "is_primary": user_role.is_primary,
                "status": user_role.status,
            }
            for user_role in sorted(
                active_roles, key=lambda item: item.role.display_order
            )
        ],
    }


def _serialize_tokens(token_pair: Any) -> dict[str, Any]:
    return {
        "access_token": token_pair.access_token,
        "refresh_token": token_pair.refresh_token,
        "expires_in": token_pair.expires_in,
        "token_type": token_pair.token_type,
    }


def _current_user() -> User:
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise APIError("auth.missing_token", "Authentication is required.", status=401)
    token = auth_header.removeprefix("Bearer ").strip()
    try:
        payload = decode_access_token(token)
    except jwt.PyJWTError as exc:
        raise APIError(
            "auth.invalid_token", "Authentication token is invalid.", status=401
        ) from exc
    user = db.session.execute(
        select(User).where(User.public_id == payload["sub"])
    ).scalar_one_or_none()
    if user is None:
        raise APIError(
            "auth.invalid_token", "Authentication token is invalid.", status=401
        )
    if user.status not in {"active", "suspended"}:
        raise APIError(
            "auth.account_restricted", "Account access is restricted.", status=403
        )
    g.current_user = user
    return user


@auth_blueprint.post("/auth/register")
@limiter.limit("20 per hour")
def register() -> ResponseReturnValue:
    payload = _json_body()
    email = _normal_email(payload.get("email"))
    password = _validate_password(payload.get("password"))
    display_name = str(payload.get("display_name", "")).strip()
    initial_role_code = str(payload.get("initial_role", "")).strip()
    terms_version = str(payload.get("terms_version", "")).strip()

    fields: dict[str, list[str]] = {}
    if len(display_name) < 2:
        fields["display_name"] = ["Display name must contain at least 2 characters."]
    if not terms_version:
        fields["terms_version"] = ["Terms version is required."]
    role = db.session.execute(
        select(Role).where(Role.code == initial_role_code, Role.is_active.is_(True))
    ).scalar_one_or_none()
    if role is None:
        fields["initial_role"] = ["Select a supported CineConnect role."]
    if fields:
        raise APIError(
            "validation.invalid",
            "Request validation failed.",
            status=422,
            fields=fields,
        )
    assert role is not None

    existing = db.session.execute(
        select(User).where(User.email == email)
    ).scalar_one_or_none()
    if existing is not None:
        raise APIError(
            "auth.email_taken",
            "An account already exists for this email.",
            status=409,
            fields={"email": ["Email is already registered."]},
        )

    user = User(
        email=email,
        password_hash=hash_password(password),
        display_name=display_name,
        terms_version=terms_version,
    )
    db.session.add(user)
    db.session.flush()
    db.session.add(
        UserRole(
            user_id=user.id,
            role_id=role.id,
            status="active",
            is_primary=True,
            approved_at=utc_now(),
        )
    )
    db.session.add(UserSettings(user_id=user.id, active_role_code=role.code))
    db.session.add(NotificationPreference(user_id=user.id))
    db.session.flush()
    token_pair = issue_token_pair(user)
    record_auth_event("register", success=True, user=user, metadata={"role": role.code})
    db.session.commit()
    return jsonify(
        success(
            {"user": _serialize_user(user), "tokens": _serialize_tokens(token_pair)}
        )
    ), 201


@auth_blueprint.post("/auth/login")
@limiter.limit("10 per minute")
def login() -> Response:
    payload = _json_body()
    email = _normal_email(payload.get("email"))
    password = str(payload.get("password", ""))
    user = db.session.execute(
        select(User).where(User.email == email)
    ).scalar_one_or_none()
    if user is None or not verify_password(user.password_hash, password):
        record_auth_event("login", success=False, metadata={"email": email})
        db.session.commit()
        raise APIError(
            "auth.invalid_credentials", "Email or password is incorrect.", status=401
        )
    if user.status not in {"active", "suspended"}:
        record_auth_event(
            "login", success=False, user=user, metadata={"status": user.status}
        )
        db.session.commit()
        raise APIError(
            "auth.account_restricted", "Account access is restricted.", status=403
        )

    user.last_login_at = utc_now()
    token_pair = issue_token_pair(user)
    record_auth_event("login", success=True, user=user)
    db.session.commit()
    return jsonify(
        success(
            {"user": _serialize_user(user), "tokens": _serialize_tokens(token_pair)}
        )
    )


@auth_blueprint.post("/auth/refresh")
@limiter.limit("30 per minute")
def refresh() -> Response:
    payload = _json_body()
    refresh_token = str(payload.get("refresh_token", ""))
    try:
        user, token_pair = rotate_refresh_token(refresh_token)
    except ValueError as exc:
        raise APIError("auth.invalid_refresh_token", str(exc), status=401) from exc
    record_auth_event("refresh", success=True, user=user)
    db.session.commit()
    return jsonify(
        success(
            {"user": _serialize_user(user), "tokens": _serialize_tokens(token_pair)}
        )
    )


@auth_blueprint.post("/auth/logout")
def logout() -> Response:
    payload = _json_body()
    refresh_token = str(payload.get("refresh_token", ""))
    revoked = revoke_refresh_token(refresh_token)
    db.session.commit()
    return jsonify(success({"revoked": revoked}))


@auth_blueprint.post("/auth/password/forgot")
@limiter.limit("10 per hour")
def forgot_password() -> Response:
    payload = _json_body()
    email = _normal_email(payload.get("email"))
    user = db.session.execute(
        select(User).where(User.email == email)
    ).scalar_one_or_none()
    if user is not None:
        token = new_opaque_token()
        db.session.add(
            PasswordResetToken(
                user_id=user.id,
                token_hash=hash_token(token),
                expires_at=utc_now() + timedelta(hours=1),
            )
        )
        record_auth_event("password_reset_requested", success=True, user=user)
    db.session.commit()
    return jsonify(
        success(
            {
                "accepted": True,
                "message": (
                    "If the email exists, password reset instructions will be sent."
                ),
            }
        )
    )


@auth_blueprint.post("/auth/password/reset")
@limiter.limit("10 per hour")
def reset_password() -> Response:
    payload = _json_body()
    token = str(payload.get("token", ""))
    new_password = _validate_password(payload.get("new_password"))
    reset = db.session.execute(
        select(PasswordResetToken).where(
            PasswordResetToken.token_hash == hash_token(token)
        )
    ).scalar_one_or_none()
    if (
        reset is None
        or reset.used_at is not None
        or as_utc(reset.expires_at) <= utc_now()
    ):
        raise APIError(
            "auth.invalid_reset_token", "Password reset token is invalid.", status=401
        )
    reset.user.password_hash = hash_password(new_password)
    reset.used_at = utc_now()
    record_auth_event("password_reset_completed", success=True, user=reset.user)
    db.session.commit()
    return jsonify(success({"reset": True}))


@auth_blueprint.get("/me")
def me() -> Response:
    user = _current_user()
    return jsonify(success(_serialize_user(user)))


@auth_blueprint.get("/me/roles")
def my_roles() -> Response:
    user = _current_user()
    return jsonify(success(_serialize_user(user)["roles"]))


@auth_blueprint.post("/me/roles")
def add_role() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    role_code = str(payload.get("role", "")).strip()
    role = db.session.execute(
        select(Role).where(Role.code == role_code, Role.is_active.is_(True))
    ).scalar_one_or_none()
    if role is None:
        raise APIError(
            "validation.invalid",
            "Request validation failed.",
            status=422,
            fields={"role": ["Select a supported CineConnect role."]},
        )
    existing = next(
        (user_role for user_role in user.roles if user_role.role_id == role.id), None
    )
    if existing is None:
        db.session.add(
            UserRole(
                user_id=user.id,
                role_id=role.id,
                status="active",
                is_primary=False,
                approved_at=utc_now(),
            )
        )
    elif existing.status != "active":
        existing.status = "active"
        existing.approved_at = utc_now()
    db.session.commit()
    return jsonify(success(_serialize_user(user)["roles"])), 201


@auth_blueprint.patch("/me/primary-role")
def set_primary_role() -> Response:
    user = _current_user()
    payload = _json_body()
    role_code = str(payload.get("role", "")).strip()
    matched = None
    for user_role in user.roles:
        if user_role.role.code == role_code and user_role.status == "active":
            matched = user_role
            break
    if matched is None:
        raise APIError(
            "auth.role_not_granted",
            "This role is not active on your account.",
            status=403,
        )
    for user_role in user.roles:
        user_role.is_primary = user_role.id == matched.id
    settings = db.session.execute(
        select(UserSettings).where(UserSettings.user_id == user.id)
    ).scalar_one_or_none()
    if settings is not None:
        settings.active_role_code = role_code
    db.session.commit()
    return jsonify(success(_serialize_user(user)))
