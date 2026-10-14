from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from flask import Blueprint, Response, current_app, jsonify
from sqlalchemy import select

from app.errors import APIError
from app.extensions import db
from app.models.app_settings import AppSetting
from app.models.identity import Role
from app.responses import success

app_blueprint = Blueprint("app", __name__)
INTERNAL_ROLE_CODES = {"super_admin", "finance_admin", "reviewer", "support_agent"}


def active_roles() -> list[dict[str, Any]]:
    rows = db.session.execute(
        select(Role)
        .where(Role.is_active.is_(True), Role.code.not_in(INTERNAL_ROLE_CODES))
        .order_by(Role.display_order.asc())
    ).scalars()
    return [
        {
            "code": role.code,
            "name": role.name,
            "portal_route": role.portal_route,
            "requires_kyc": role.requires_kyc,
        }
        for role in rows
    ]


def runtime_settings() -> dict[str, Any]:
    config = current_app.config
    defaults = {
        "maintenance": {
            "enabled": config["MAINTENANCE_ENABLED"],
            "message": config["MAINTENANCE_MESSAGE"] or None,
            "return_at": config["MAINTENANCE_RETURN_AT"] or None,
        },
        "force_update": {
            "required": config["FORCE_UPDATE_REQUIRED"],
            "store_url": config["APP_STORE_URL"] or None,
        },
    }
    row = db.session.execute(
        select(AppSetting).where(AppSetting.key == "runtime")
    ).scalar_one_or_none()
    if row:
        defaults.update(row.value_json)
    return defaults


@app_blueprint.get("/admin/app-settings")
def get_app_settings() -> Response:
    _require_runtime_admin()
    return jsonify(success(runtime_settings()))


def _require_runtime_admin() -> None:
    from app.api.auth import _current_user

    user = _current_user()
    if not any(
        role.status == "active" and role.role.code == "super_admin"
        for role in user.roles
    ):
        raise APIError(
            "app.permission_denied", "Super Admin access is required.", status=403
        )


@app_blueprint.patch("/admin/app-settings")
def update_app_settings() -> Response:
    from app.api.auth import _json_body

    _require_runtime_admin()
    payload = _json_body()
    settings = runtime_settings()
    for key, flag in [("maintenance", "enabled"), ("force_update", "required")]:
        if key not in payload:
            continue
        value = payload[key]
        if not isinstance(value, dict) or type(value.get(flag)) is not bool:
            raise APIError(
                "app.invalid_settings",
                f"{key}.{flag} must be true or false.",
                status=422,
            )
        allowed = (
            {"enabled", "message", "return_at"}
            if key == "maintenance"
            else {"required", "store_url"}
        )
        if set(value) - allowed or any(
            v is not None and not isinstance(v, (str, bool)) for v in value.values()
        ):
            raise APIError(
                "app.invalid_settings", "Unsupported runtime setting.", status=422
            )
        if len(jsonify(value).get_data()) > 4000:
            raise APIError(
                "app.invalid_settings", "Runtime settings are too long.", status=422
            )
        settings[key] = {**settings[key], **value}
        for name in allowed - {flag}:
            if settings[key].get(name) is not None and not isinstance(
                settings[key][name], str
            ):
                raise APIError(
                    "app.invalid_settings", f"{name} must be text.", status=422
                )
    return_at = settings["maintenance"].get("return_at")
    if return_at:
        try:
            parsed_time = datetime.fromisoformat(return_at.replace("Z", "+00:00"))
            if parsed_time.tzinfo is None:
                raise ValueError()
        except ValueError as exc:
            raise APIError(
                "app.invalid_settings",
                "Return time must include a timezone.",
                status=422,
            ) from exc
    url = settings["force_update"].get("store_url")
    if (url and (urlparse(url).scheme != "https" or not urlparse(url).hostname)) or (
        settings["force_update"]["required"] and not url
    ):
        raise APIError("app.invalid_settings", "Store URL must use HTTPS.", status=422)
    row = db.session.execute(
        select(AppSetting).where(AppSetting.key == "runtime")
    ).scalar_one_or_none()
    if row is None:
        row = AppSetting(key="runtime", value_json=settings)
        db.session.add(row)
    else:
        row.value_json = settings
    db.session.commit()
    return jsonify(success(settings))


ROLES = [
    {
        "code": "director_producer",
        "name": "Director / Producer",
        "portal_route": "/director",
        "requires_kyc": True,
    },
    {
        "code": "actor_talent",
        "name": "Actor / Talent",
        "portal_route": "/talent",
        "requires_kyc": True,
    },
    {
        "code": "model",
        "name": "Model",
        "portal_route": "/model",
        "requires_kyc": True,
    },
    {
        "code": "location_owner",
        "name": "Location Owner",
        "portal_route": "/location-owner",
        "requires_kyc": True,
    },
    {
        "code": "equipment_provider",
        "name": "Media / Equipment Provider",
        "portal_route": "/equipment-provider",
        "requires_kyc": True,
    },
    {
        "code": "crew_service",
        "name": "Crew / Services",
        "portal_route": "/crew",
        "requires_kyc": True,
    },
    {
        "code": "casting_agency",
        "name": "Casting Agency",
        "portal_route": "/agency",
        "requires_kyc": True,
    },
    {
        "code": "brand_sponsor",
        "name": "Brand / Sponsor",
        "portal_route": "/brand",
        "requires_kyc": True,
    },
    {
        "code": "legal_partner",
        "name": "Legal Partner",
        "portal_route": "/legal",
        "requires_kyc": True,
    },
    {
        "code": "insurance_partner",
        "name": "Insurance / Safety Partner",
        "portal_route": "/insurance",
        "requires_kyc": True,
    },
    {
        "code": "distribution_partner",
        "name": "Distribution / Release Partner",
        "portal_route": "/distribution",
        "requires_kyc": True,
    },
]


@app_blueprint.get("/app/bootstrap")
def bootstrap() -> Response:
    from app.services.web_push import web_push_available

    return jsonify(
        success(
            {
                **runtime_settings(),
                "supported_roles": active_roles(),
                "release_version": current_app.config["RELEASE_VERSION"],
                "capabilities": {
                    "sms_otp": False,
                    "push": web_push_available(),
                    "vapid_public_key": current_app.config["VAPID_PUBLIC_KEY"],
                    "email": bool(
                        current_app.config["SMTP_HOST"]
                        and current_app.config["SMTP_FROM_EMAIL"]
                    ),
                    "liveness": "manual_review",
                    "social_metrics": "self_reported",
                },
            }
        )
    )


@app_blueprint.get("/app/public-config")
def public_config() -> Response:
    return jsonify(
        success(
            {
                "default_timezone": "Asia/Karachi",
                "default_currency": "PKR",
                "support": {
                    "business_name": "CineConnect",
                    "payments": {
                        "mode": current_app.config["PAYMENT_MODE"],
                        "notice": (
                            "Demo payment only — no money is moved."
                            if current_app.config["PAYMENT_MODE"] == "sandbox"
                            else (
                                "Bank transfers are made outside CineConnect. "
                                "Submit proof for verification; CineConnect records "
                                "and reconciles payments."
                            )
                        ),
                    },
                },
            }
        )
    )


@app_blueprint.get("/roles")
def roles() -> Response:
    db_roles = db.session.execute(
        select(Role)
        .where(Role.is_active.is_(True), Role.code.not_in(INTERNAL_ROLE_CODES))
        .order_by(Role.display_order.asc())
    ).scalars()
    roles_payload = [
        {
            "code": role.code,
            "name": role.name,
            "portal_route": role.portal_route,
            "requires_kyc": role.requires_kyc,
        }
        for role in db_roles
    ]
    return jsonify(success(roles_payload))


@app_blueprint.get("/openapi.yaml")
def openapi() -> Response:
    path = Path(current_app.config["OPENAPI_PATH"])
    if not path.is_file():
        return Response(
            "OpenAPI contract unavailable\n",
            status=404,
            mimetype="text/plain",
        )
    return Response(path.read_text(encoding="utf-8"), mimetype="application/yaml")
