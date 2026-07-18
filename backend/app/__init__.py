from __future__ import annotations

import sentry_sdk
from flask import Flask
from sentry_sdk.integrations.flask import FlaskIntegration

from app.api import api_v1
from app.config import Config
from app.errors import register_error_handlers
from app.extensions import cors, db, limiter, migrate
from app.logging import configure_logging
from app.middleware import register_middleware


def _configure_sentry(app: Flask) -> None:
    dsn = app.config.get("SENTRY_DSN", "")
    if not dsn:
        return
    sentry_sdk.init(
        dsn=dsn,
        environment=app.config["APP_ENV"],
        integrations=[FlaskIntegration()],
        traces_sample_rate=0.0,
        send_default_pii=False,
    )


def create_app(config: type[Config] = Config) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config)
    config.validate(app.config)

    _configure_sentry(app)
    configure_logging(app)
    db.init_app(app)
    migrate.init_app(app, db)
    limiter.init_app(app)
    cors.init_app(
        app,
        resources={
            r"/api/*": {
                "origins": app.config["CORS_ALLOWED_ORIGINS"],
                "supports_credentials": True,
            }
        },
    )
    register_middleware(app)
    register_error_handlers(app)
    app.register_blueprint(api_v1, url_prefix="/api/v1")

    return app
