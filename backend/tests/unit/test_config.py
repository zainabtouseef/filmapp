from __future__ import annotations

import pytest

from app.config import Config


def test_production_rejects_sandbox_payments() -> None:
    values = {
        "APP_ENV": "production",
        "SQLALCHEMY_DATABASE_URI": "mysql+pymysql://user:pass@db/app",
        "SECRET_KEY": "s" * 64,
        "JWT_SECRET_KEY": "j" * 64,
        "PAYMENT_MODE": "sandbox",
        "CORS_ALLOWED_ORIGINS": ["https://cine.nalexustechnologies.com"],
    }

    with pytest.raises(RuntimeError, match="sandbox is forbidden"):
        Config.validate(values)


def test_production_rejects_non_mysql_database() -> None:
    values = {
        "APP_ENV": "production",
        "SQLALCHEMY_DATABASE_URI": "postgresql://user:pass@db/app",
    }

    with pytest.raises(RuntimeError, match="mysql\\+pymysql"):
        Config.validate(values)


def test_production_rejects_short_application_secret() -> None:
    values = {
        "APP_ENV": "production",
        "SQLALCHEMY_DATABASE_URI": "mysql+pymysql://user:pass@db/app",
        "SECRET_KEY": "short",
        "JWT_SECRET_KEY": "j" * 64,
        "PAYMENT_MODE": "live",
        "CORS_ALLOWED_ORIGINS": ["https://cine.nalexustechnologies.com"],
    }

    with pytest.raises(RuntimeError, match="SECRET_KEY"):
        Config.validate(values)


def test_production_accepts_explicit_secure_configuration() -> None:
    values = {
        "APP_ENV": "production",
        "SQLALCHEMY_DATABASE_URI": "mysql+pymysql://user:pass@db/app",
        "SECRET_KEY": "s" * 64,
        "JWT_SECRET_KEY": "j" * 64,
        "PAYMENT_MODE": "live",
        "CORS_ALLOWED_ORIGINS": ["https://cine.nalexustechnologies.com"],
    }

    Config.validate(values)
