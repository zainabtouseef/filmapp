from __future__ import annotations

from flask import Blueprint, Response, current_app, jsonify
from redis import Redis
from sqlalchemy import text

from app.extensions import db
from app.responses import error, success

health_blueprint = Blueprint("health", __name__, url_prefix="/health")


@health_blueprint.get("/live")
def live() -> Response:
    return jsonify(success({"status": "ok", "service": "cineconnect-api"}))


@health_blueprint.get("/ready")
def ready() -> Response | tuple[Response, int]:
    dependencies: dict[str, str] = {}
    try:
        db.session.execute(text("SELECT 1"))
        dependencies["database"] = "ok"
    except Exception:
        current_app.logger.exception("Database readiness check failed")
        dependencies["database"] = "unavailable"

    redis_client = Redis.from_url(
        current_app.config["REDIS_URL"],
        socket_connect_timeout=1,
        socket_timeout=1,
    )
    try:
        redis_client.ping()
        dependencies["redis"] = "ok"
    except Exception:
        current_app.logger.exception("Redis readiness check failed")
        dependencies["redis"] = "unavailable"
    finally:
        redis_client.close()

    if any(value != "ok" for value in dependencies.values()):
        return (
            jsonify(
                error(
                    "health.dependencies_unavailable",
                    "One or more required dependencies are unavailable.",
                    fields={
                        key: [value]
                        for key, value in dependencies.items()
                        if value != "ok"
                    },
                )
            ),
            503,
        )

    return jsonify(
        success(
            {
                "status": "ok",
                "service": "cineconnect-api",
                "dependencies": dependencies,
            }
        )
    )
