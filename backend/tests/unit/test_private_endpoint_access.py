"""Regression coverage for unauthenticated access to private workflow data."""

import pytest
from flask.testing import FlaskClient


@pytest.mark.parametrize("authorization", [None, "Bearer invalid-token"])
@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("GET", "/projects"),
        ("POST", "/projects"),
        ("GET", "/projects/PRJ-PRIVATE"),
        ("PATCH", "/projects/PRJ-PRIVATE"),
        ("GET", "/projects/PRJ-PRIVATE/room"),
        ("GET", "/projects/PRJ-PRIVATE/members"),
        ("POST", "/projects/PRJ-PRIVATE/members"),
        ("GET", "/projects/PRJ-PRIVATE/files"),
        ("GET", "/projects/PRJ-PRIVATE/requirements"),
        ("GET", "/director/dashboard"),
        ("GET", "/director/schedule"),
        ("POST", "/director/schedule"),
        ("GET", "/bookings"),
        ("POST", "/bookings"),
        ("GET", "/bookings/BKG-PRIVATE"),
        ("GET", "/conversations/CON-PRIVATE/messages"),
        ("POST", "/conversations/CON-PRIVATE/messages"),
        ("GET", "/payments/dashboard"),
        ("GET", "/payment-schedules"),
        ("POST", "/payment-proofs"),
        ("GET", "/ledger"),
        ("GET", "/payout-accounts"),
        ("GET", "/me/settings"),
        ("PATCH", "/me/settings"),
        ("GET", "/admin/payment-proofs"),
    ],
)
def test_private_workflows_require_valid_authentication(
    client: FlaskClient, method: str, path: str, authorization: str | None
) -> None:
    headers = {"Authorization": authorization} if authorization else {}
    response = client.open(f"/api/v1{path}", method=method, headers=headers, json={})
    assert response.status_code == 401, (method, path, response.get_json())
    assert response.get_json().get("data") is None
