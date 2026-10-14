from __future__ import annotations

import re
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
    UserSession,
    UserSettings,
)
from app.models.marketplace import City, UserProfile
from app.responses import success
from app.security import (
    access_token_matches_credentials,
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
from app.services.auth_email import reset_email_available, send_password_reset_email

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
        "phone": user.phone_e164,
        "phone_verified": user.phone_verified_at is not None,
        "referral_code": user.referral_code,
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


def _settings_rows(user: User) -> tuple[UserSettings, NotificationPreference]:
    settings = db.session.execute(
        select(UserSettings).where(UserSettings.user_id == user.id)
    ).scalar_one_or_none()
    if settings is None:
        settings = UserSettings(user_id=user.id)
        db.session.add(settings)
    notifications = db.session.execute(
        select(NotificationPreference).where(NotificationPreference.user_id == user.id)
    ).scalar_one_or_none()
    if notifications is None:
        notifications = NotificationPreference(user_id=user.id)
        db.session.add(notifications)
    return settings, notifications


def _serialize_settings(
    settings: UserSettings, notifications: NotificationPreference
) -> dict[str, Any]:
    return {
        "timezone": settings.timezone,
        "locale": settings.locale,
        "notifications": {
            "email_enabled": notifications.email_enabled,
            "sms_enabled": notifications.sms_enabled,
            "push_enabled": notifications.push_enabled,
        },
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
    if user is None or not access_token_matches_credentials(user, payload):
        raise APIError(
            "auth.invalid_token", "Authentication token is invalid.", status=401
        )
    if user.status != "active":
        raise APIError(
            "auth.account_restricted", "Account access is restricted.", status=403
        )
    g.current_user = user
    g.current_session_family = payload.get("session_family")
    if _current_session(user) is None:
        raise APIError("auth.session_expired", "Please sign in again.", status=401)
    return user


def _current_session(user: User) -> UserSession | None:
    family = getattr(g, "current_session_family", None)
    query = select(UserSession).where(
        UserSession.user_id == user.id,
        UserSession.revoked_at.is_(None),
        UserSession.expires_at > utc_now(),
    )
    if isinstance(family, str) and family:
        return db.session.execute(
            query.where(UserSession.refresh_token_family == family)
        ).scalar_one_or_none()
    user_agent = request.headers.get("User-Agent", "")[:512]
    ip_address = request.headers.get("X-Forwarded-For", request.remote_addr)
    return (
        db.session.execute(
            query.where(
                UserSession.user_agent == user_agent,
                UserSession.ip_address == ip_address,
            ).order_by(UserSession.created_at.desc())
        )
        .scalars()
        .first()
    )


def _serialize_session(
    item: UserSession, current: UserSession | None
) -> dict[str, Any]:
    return {
        "id": str(item.id),
        "is_current": current is not None and item.id == current.id,
        "ip_address": item.ip_address,
        "user_agent": item.user_agent,
        "created_at": item.created_at.isoformat(),
        "last_used_at": item.last_used_at.isoformat() if item.last_used_at else None,
        "expires_at": item.expires_at.isoformat(),
    }


@auth_blueprint.post("/auth/register")
@limiter.limit("20 per hour")
def register() -> ResponseReturnValue:
    from app.api.app import INTERNAL_ROLE_CODES

    payload = _json_body()
    email = _normal_email(payload.get("email"))
    password = _validate_password(payload.get("password"))
    display_name = str(payload.get("display_name", "")).strip()
    initial_role_code = str(payload.get("initial_role", "")).strip()
    if initial_role_code in INTERNAL_ROLE_CODES:
        raise APIError(
            "auth.role_restricted",
            "Internal roles require administrator assignment.",
            status=403,
        )
    terms_version = str(payload.get("terms_version", "")).strip()
    phone = str(payload.get("phone") or "").strip().replace(" ", "")
    referral = str(payload.get("referral_code") or "").strip()
    city_id = str(payload.get("city_id") or "").strip()

    fields: dict[str, list[str]] = {}
    if phone and not re.fullmatch(r"\+[1-9]\d{7,14}", phone):
        fields["phone"] = [
            "Use an international phone number, for example +923001234567."
        ]
    if len(referral) > 64:
        fields["referral_code"] = ["Referral code must contain at most 64 characters."]
    city = None
    if city_id:
        city = db.session.execute(
            select(City).where(City.public_id == city_id, City.active.is_(True))
        ).scalar_one_or_none()
        if city is None:
            fields["city_id"] = ["Select an active city."]
    if (
        phone
        and db.session.execute(select(User.id).where(User.phone_e164 == phone)).first()
    ):
        fields["phone"] = ["This phone number is already registered."]
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
        phone_e164=phone or None,
        referral_code=referral or None,
    )
    db.session.add(user)
    db.session.flush()
    db.session.add(UserProfile(user_id=user.id, city_id=city.id if city else None))
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
    if user.status != "active":
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
    if not reset_email_available():
        raise APIError(
            "auth.email_delivery_unavailable",
            "Password recovery email is not configured. Please contact support.",
            status=503,
        )
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
    if user is not None:
        try:
            send_password_reset_email(user.email, token)
        except Exception as exc:
            # Never include the token, SMTP credentials or recipient in errors.
            raise APIError(
                "auth.email_delivery_failed",
                "Recovery email could not be delivered. Please try again later.",
                status=503,
            ) from exc
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
    for session in db.session.execute(
        select(UserSession).where(
            UserSession.user_id == reset.user_id, UserSession.revoked_at.is_(None)
        )
    ).scalars():
        session.revoked_at = utc_now()
    record_auth_event("password_reset_completed", success=True, user=reset.user)
    db.session.commit()
    return jsonify(success({"reset": True}))


@auth_blueprint.get("/me")
def me() -> Response:
    user = _current_user()
    return jsonify(success(_serialize_user(user)))


@auth_blueprint.patch("/me")
def update_me() -> Response:
    user = _current_user()
    payload = _json_body()
    if "display_name" in payload:
        display_name = str(payload.get("display_name", "")).strip()
        if len(display_name) < 2 or len(display_name) > 120:
            raise APIError(
                "validation.invalid",
                "Request validation failed.",
                status=422,
                fields={"display_name": ["Enter a name between 2 and 120 characters."]},
            )
        user.display_name = display_name
    record_auth_event("profile_updated", success=True, user=user)
    db.session.commit()
    return jsonify(success(_serialize_user(user)))


@auth_blueprint.get("/me/sessions")
def my_sessions() -> Response:
    user = _current_user()
    current = _current_session(user)
    rows = list(
        db.session.execute(
            select(UserSession)
            .where(
                UserSession.user_id == user.id,
                UserSession.revoked_at.is_(None),
                UserSession.expires_at > utc_now(),
            )
            .order_by(UserSession.last_used_at.desc(), UserSession.created_at.desc())
        ).scalars()
    )
    rows.sort(key=lambda item: item.id != (current.id if current else None))
    return jsonify(
        success({"sessions": [_serialize_session(row, current) for row in rows]})
    )


@auth_blueprint.delete("/me/sessions/<session_id>")
def revoke_my_session(session_id: str) -> Response:
    user = _current_user()
    current = _current_session(user)
    item = next(
        (
            row
            for row in db.session.execute(
                select(UserSession).where(UserSession.user_id == user.id)
            ).scalars()
            if str(row.id) == session_id
        ),
        None,
    )
    if item is None:
        raise APIError("auth.session_not_found", "Session was not found.", status=404)
    item.revoked_at = utc_now()
    record_auth_event(
        "session_revoked",
        success=True,
        user=user,
        metadata={"current": current is not None and current.id == item.id},
    )
    db.session.commit()
    return jsonify(
        success(
            {
                "revoked": True,
                "current": current is not None and current.id == item.id,
            }
        )
    )


@auth_blueprint.post("/me/sessions/revoke-others")
def revoke_other_sessions() -> Response:
    user = _current_user()
    current = _current_session(user)
    if current is None:
        raise APIError(
            "auth.current_session_unknown",
            "Refresh this session before revoking other devices.",
            status=409,
        )
    revoked = 0
    for item in db.session.execute(
        select(UserSession).where(
            UserSession.user_id == user.id,
            UserSession.id != current.id,
            UserSession.revoked_at.is_(None),
        )
    ).scalars():
        item.revoked_at = utc_now()
        revoked += 1
    record_auth_event(
        "other_sessions_revoked",
        success=True,
        user=user,
        metadata={"count": revoked},
    )
    db.session.commit()
    return jsonify(success({"revoked_count": revoked}))


@auth_blueprint.get("/me/roles")
def my_roles() -> Response:
    user = _current_user()
    return jsonify(success(_serialize_user(user)["roles"]))


@auth_blueprint.get("/me/settings")
def my_settings() -> Response:
    user = _current_user()
    settings, notifications = _settings_rows(user)
    db.session.commit()
    return jsonify(success(_serialize_settings(settings, notifications)))


@auth_blueprint.patch("/me/settings")
def update_my_settings() -> Response:
    user = _current_user()
    payload = _json_body()
    settings, notifications = _settings_rows(user)

    if "locale" in payload:
        locale = str(payload["locale"]).strip()
        if locale not in {"en-PK", "ur-PK", "ur-Latn-PK"}:
            raise APIError(
                "validation.invalid",
                "Request validation failed.",
                status=422,
                fields={"locale": ["Select a supported language."]},
            )
        settings.locale = locale
    if "timezone" in payload:
        timezone = str(payload["timezone"]).strip()
        if not timezone or len(timezone) > 64:
            raise APIError(
                "validation.invalid",
                "Request validation failed.",
                status=422,
                fields={"timezone": ["Enter a valid timezone."]},
            )
        settings.timezone = timezone

    notification_payload = payload.get("notifications")
    if notification_payload is not None:
        if not isinstance(notification_payload, dict):
            raise APIError(
                "validation.invalid",
                "Request validation failed.",
                status=422,
                fields={"notifications": ["Notification settings must be an object."]},
            )
        notification_fields = {
            "email_enabled": "email_enabled",
            "sms_enabled": "sms_enabled",
            "push_enabled": "push_enabled",
        }
        for api_name, attribute_name in notification_fields.items():
            if api_name not in notification_payload:
                continue
            value = notification_payload[api_name]
            if not isinstance(value, bool):
                raise APIError(
                    "validation.invalid",
                    "Request validation failed.",
                    status=422,
                    fields={f"notifications.{api_name}": ["Use true or false."]},
                )
            setattr(notifications, attribute_name, value)

    db.session.commit()
    return jsonify(success(_serialize_settings(settings, notifications)))


@auth_blueprint.post("/me/roles")
def add_role() -> ResponseReturnValue:
    from app.api.app import INTERNAL_ROLE_CODES

    user = _current_user()
    payload = _json_body()
    role_code = str(payload.get("role", "")).strip()
    if role_code in INTERNAL_ROLE_CODES:
        raise APIError(
            "auth.role_restricted",
            "Internal roles require administrator assignment.",
            status=403,
        )
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
        raise APIError(
            "auth.role_restricted",
            "An administrator must restore this role.",
            status=403,
        )
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
