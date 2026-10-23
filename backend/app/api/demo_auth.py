"""Explicitly enabled demo account access, authorized by a private link capability."""

from __future__ import annotations

import secrets
from typing import Any

from flask import Blueprint, Response, current_app, jsonify
from sqlalchemy import select

from app.api.auth import _json_body, _serialize_tokens, _serialize_user
from app.errors import APIError
from app.extensions import db, limiter
from app.models.base import utc_now
from app.models.identity import Role, User, UserSettings
from app.responses import success
from app.security import issue_token_pair, record_auth_event

demo_auth_blueprint = Blueprint("demo_auth", __name__)


def _demo_payload() -> dict[str, Any]:
    expected = str(current_app.config.get("DEMO_ACCOUNT_PICKER_KEY", ""))
    unavailable = APIError(
        "demo.unavailable",
        "This demo access link is unavailable or has expired.",
        status=404,
    )
    if not current_app.config.get("DEMO_ACCOUNT_PICKER_ENABLED") or len(expected) < 64:
        raise unavailable
    payload = _json_body()
    supplied = payload.get("access_key")
    if (
        not isinstance(supplied, str)
        or len(supplied) > 256
        or not secrets.compare_digest(expected.encode(), supplied.encode())
    ):
        raise unavailable
    return payload


@demo_auth_blueprint.post("/auth/demo/accounts")
@limiter.limit("60 per minute")
def demo_accounts() -> Response:
    # POST keeps the capability out of request URLs and access logs.
    _demo_payload()
    roles = list(
        db.session.scalars(
            select(Role)
            .where(Role.is_active.is_(True))
            .order_by(Role.display_order, Role.name)
        )
    )
    users = list(
        db.session.scalars(select(User).order_by(User.display_name, User.email))
    )
    groups: dict[str, dict[str, Any]] = {
        role.code: {"code": role.code, "name": role.name, "accounts": []}
        for role in roles
    }
    unassigned: list[dict[str, Any]] = []
    for user in users:
        account = {
            "public_id": user.public_id,
            "display_name": user.display_name,
            "email": user.email,
            "status": user.status,
            "can_login": user.status == "active",
        }
        memberships = [
            role.role.code
            for role in user.roles
            if role.status == "active" and role.role.code in groups
        ]
        for code in memberships:
            groups[code]["accounts"].append(account)
        if not memberships:
            unassigned.append({**account, "can_login": False})
    categories = [group for group in groups.values() if group["accounts"]]
    if unassigned:
        categories.append(
            {"code": "unassigned", "name": "No active role", "accounts": unassigned}
        )
    response = jsonify(
        success({"total_accounts": len(users), "categories": categories})
    )
    response.headers["X-Robots-Tag"] = "noindex, nofollow, noarchive"
    return response


@demo_auth_blueprint.post("/auth/demo/login")
@limiter.limit("60 per minute")
def demo_login() -> Response:
    payload = _demo_payload()
    user = db.session.scalar(
        select(User).where(User.public_id == str(payload.get("user_id", "")))
    )
    if user is None:
        raise APIError("demo.account_not_found", "Account was not found.", status=404)
    role_code = str(payload.get("role_code", ""))
    membership = next(
        (
            role
            for role in user.roles
            if role.role.code == role_code
            and role.status == "active"
            and role.role.is_active
        ),
        None,
    )
    if user.status != "active" or membership is None:
        raise APIError(
            "demo.account_unavailable",
            "This account or role is not available for login.",
            status=403,
        )
    for role in user.roles:
        role.is_primary = role.id == membership.id
    settings = db.session.scalar(
        select(UserSettings).where(UserSettings.user_id == user.id)
    )
    if settings is not None:
        settings.active_role_code = role_code
    user.last_login_at = utc_now()
    pair = issue_token_pair(user)
    record_auth_event(
        "demo_login", success=True, user=user, metadata={"role": role_code}
    )
    db.session.commit()
    return jsonify(
        success({"user": _serialize_user(user), "tokens": _serialize_tokens(pair)})
    )
