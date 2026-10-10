from __future__ import annotations

import pytest

from app.api.payments import _validate_payment_method
from app.errors import APIError


def test_production_rejects_sandbox_payment_proof(app):
    with app.app_context():
        app.config["APP_ENV"] = "production"
        with pytest.raises(APIError):
            _validate_payment_method("card_sandbox")
        _validate_payment_method("bank_transfer")


def test_unknown_payment_method_is_rejected(app):
    with app.app_context(), pytest.raises(APIError):
        _validate_payment_method("pretend_gateway")
