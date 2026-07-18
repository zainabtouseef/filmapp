from __future__ import annotations

import os
from collections.abc import Mapping
from typing import Any, ClassVar


def _csv(name: str, default: str = "") -> list[str]:
    return [
        value.strip() for value in os.getenv(name, default).split(",") if value.strip()
    ]


class Config:
    APP_ENV = os.getenv("APP_ENV", "development")
    SECRET_KEY = os.getenv("SECRET_KEY", "development-secret-change-me")
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "development-jwt-change-me")
    FIELD_ENCRYPTION_KEY = os.getenv("FIELD_ENCRYPTION_KEY", "")

    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        "mysql+pymysql://cineconnect:local-only-password@127.0.0.1:3307/"
        "cineconnect?charset=utf8mb4",
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS: ClassVar[dict[str, Any]] = {
        "pool_pre_ping": True,
        "pool_recycle": 300,
        "pool_size": 10,
        "max_overflow": 20,
    }

    REDIS_URL = os.getenv("REDIS_URL", "redis://127.0.0.1:6380/0")
    CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL", "redis://127.0.0.1:6380/1")
    CELERY_RESULT_BACKEND = os.getenv(
        "CELERY_RESULT_BACKEND", "redis://127.0.0.1:6380/2"
    )
    RATELIMIT_STORAGE_URI = REDIS_URL
    RATELIMIT_HEADERS_ENABLED = True
    RATELIMIT_DEFAULT = "300 per minute"

    PUBLIC_WEB_ORIGIN = os.getenv("PUBLIC_WEB_ORIGIN", "http://localhost:3000")
    API_PUBLIC_URL = os.getenv("API_PUBLIC_URL", "http://localhost:5000")
    CORS_ALLOWED_ORIGINS = _csv("CORS_ALLOWED_ORIGINS", "http://localhost:3000")
    PAYMENT_MODE = os.getenv("PAYMENT_MODE", "sandbox")
    ACCESS_TOKEN_MINUTES = int(os.getenv("ACCESS_TOKEN_MINUTES", "15"))
    REFRESH_TOKEN_DAYS = int(os.getenv("REFRESH_TOKEN_DAYS", "30"))
    OBJECT_STORAGE_BUCKET_PRIVATE = os.getenv(
        "OBJECT_STORAGE_BUCKET_PRIVATE",
        "cineconnect-private",
    )
    OBJECT_STORAGE_BUCKET_PUBLIC = os.getenv(
        "OBJECT_STORAGE_BUCKET_PUBLIC",
        "cineconnect-public",
    )
    LOCAL_STORAGE_PRIVATE_ROOT = os.getenv(
        "LOCAL_STORAGE_PRIVATE_ROOT",
        "/data/storage/private",
    )
    LOCAL_STORAGE_PUBLIC_ROOT = os.getenv(
        "LOCAL_STORAGE_PUBLIC_ROOT",
        "/data/storage/public",
    )
    PUBLIC_MEDIA_BASE_URL = os.getenv("PUBLIC_MEDIA_BASE_URL", "")
    SENTRY_DSN = os.getenv("SENTRY_DSN", "")
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    OPENAPI_PATH = os.getenv("OPENAPI_PATH", "/app/docs/openapi.yaml")

    @classmethod
    def validate(cls, values: Mapping[str, Any]) -> None:
        environment = str(values["APP_ENV"])
        database_url = str(values["SQLALCHEMY_DATABASE_URI"])
        if not database_url.startswith("mysql+pymysql://"):
            raise RuntimeError("DATABASE_URL must use mysql+pymysql")
        if environment != "production":
            return
        if len(str(values["SECRET_KEY"])) < 64:
            raise RuntimeError("SECRET_KEY must contain at least 64 characters")
        if len(str(values["JWT_SECRET_KEY"])) < 64:
            raise RuntimeError("JWT_SECRET_KEY must contain at least 64 characters")
        if values["PAYMENT_MODE"] == "sandbox":
            raise RuntimeError("PAYMENT_MODE=sandbox is forbidden in production")
        origins = values["CORS_ALLOWED_ORIGINS"]
        if not origins or "*" in origins:
            raise RuntimeError("Production CORS origins must be explicit")


class TestConfig(Config):
    TESTING = True
    APP_ENV = "test"
    SECRET_KEY = "test-secret"
    JWT_SECRET_KEY = "test-jwt-secret-with-enough-length-for-hs256"
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "TEST_DATABASE_URL",
        "mysql+pymysql://cineconnect:local-only-password@127.0.0.1:3307/"
        "cineconnect?charset=utf8mb4",
    )
    REDIS_URL = os.getenv("TEST_REDIS_URL", "redis://127.0.0.1:6380/15")
    RATELIMIT_STORAGE_URI = "memory://"
    RATELIMIT_ENABLED = False
    SQLALCHEMY_ENGINE_OPTIONS: ClassVar[dict[str, Any]] = {"pool_pre_ping": True}
    OPENAPI_PATH = str(
        os.path.abspath(
            os.path.join(os.path.dirname(__file__), "../../docs/openapi.yaml")
        )
    )
    LOCAL_STORAGE_PRIVATE_ROOT = str(
        os.path.abspath(
            os.path.join(os.path.dirname(__file__), "../.storage/test/private")
        )
    )
    LOCAL_STORAGE_PUBLIC_ROOT = str(
        os.path.abspath(
            os.path.join(os.path.dirname(__file__), "../.storage/test/public")
        )
    )
