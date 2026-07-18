from __future__ import annotations

from pathlib import Path

from flask import Blueprint, Response, current_app, jsonify
from sqlalchemy import select

from app.extensions import db
from app.models.identity import Role
from app.responses import success

app_blueprint = Blueprint("app", __name__)

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
    return jsonify(
        success(
            {
                "maintenance": {"enabled": False, "message": None},
                "force_update": {"required": False, "store_url": None},
                "supported_roles": ROLES,
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
                        "notice": "Demo payment only — no money is moved.",
                    },
                },
            }
        )
    )


@app_blueprint.get("/roles")
def roles() -> Response:
    db_roles = db.session.execute(
        select(Role).where(Role.is_active.is_(True)).order_by(Role.display_order.asc())
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
    return jsonify(success(roles_payload or ROLES))


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
