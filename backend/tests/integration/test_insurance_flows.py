from __future__ import annotations

import os
import uuid

import pytest
from flask.testing import FlaskClient

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        os.getenv("RUN_INTEGRATION_TESTS") != "1",
        reason="Set RUN_INTEGRATION_TESTS=1 with MySQL and Redis running.",
    ),
]


def _register_role(
    client: FlaskClient, role: str, *, name: str
) -> tuple[dict[str, str], str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"insurance-{uuid.uuid4().hex[:12]}@example.com",
            "password": "StrongPass123!",
            "display_name": name,
            "initial_role": role,
            "terms_version": "2026-07",
        },
    )
    assert response.status_code == 201, response.text
    token = response.json["data"]["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}, response.json["data"]["user"][
        "public_id"
    ]


def test_insurance_policy_and_claim_flow(client: FlaskClient) -> None:
    provider_headers, _provider_id = _register_role(
        client, "insurance_partner", name="Insurance Flow Provider"
    )
    producer_headers, producer_id = _register_role(
        client, "director_producer", name="Insurance Flow Producer"
    )
    outsider_headers, _outsider_id = _register_role(
        client, "director_producer", name="Insurance Flow Outsider"
    )

    profile = client.patch(
        "/api/v1/insurance/profile",
        headers=provider_headers,
        json={
            "name": "CineSecure Safety Desk",
            "coverage_regions": "Pakistan",
            "license_number": "LIC-0001",
        },
    )
    assert profile.status_code == 200, profile.text
    assert profile.json["data"]["profile"]["name"] == "CineSecure Safety Desk"

    policy = client.post(
        "/api/v1/insurance/policies",
        headers=provider_headers,
        json={
            "insured_user_id": producer_id,
            "coverage_summary": "Cast and equipment cover",
            "valid_from": "2026-07-18",
            "valid_to": "2026-07-25",
            "risk_level": "low",
        },
    )
    assert policy.status_code == 201, policy.text
    policy_id = policy.json["data"]["policy"]["public_id"]
    assert policy.json["data"]["policy"]["status"] == "active"

    provider_list = client.get("/api/v1/insurance/policies", headers=provider_headers)
    assert provider_list.status_code == 200, provider_list.text
    assert len(provider_list.json["data"]["policies"]) == 1

    insured_list = client.get("/api/v1/insurance/policies", headers=producer_headers)
    assert insured_list.status_code == 200, insured_list.text
    assert len(insured_list.json["data"]["policies"]) == 1

    outsider_detail = client.get(
        f"/api/v1/insurance/policies/{policy_id}", headers=outsider_headers
    )
    assert outsider_detail.status_code == 404, outsider_detail.text

    policy_detail = client.get(
        f"/api/v1/insurance/policies/{policy_id}", headers=producer_headers
    )
    assert policy_detail.status_code == 200, policy_detail.text
    assert policy_detail.json["data"]["policy"]["claims"] == []

    claim = client.post(
        "/api/v1/insurance/claims",
        headers=producer_headers,
        json={
            "policy_id": policy_id,
            "title": "Damaged lens",
            "item_or_room": "Sony 35mm",
            "estimate_minor": 6500000,
        },
    )
    assert claim.status_code == 201, claim.text
    claim_id = claim.json["data"]["claim"]["public_id"]
    assert claim.json["data"]["claim"]["status"] == "submitted"

    outsider_claim_attempt = client.get(
        f"/api/v1/insurance/claims/{claim_id}", headers=outsider_headers
    )
    assert outsider_claim_attempt.status_code == 403, outsider_claim_attempt.text

    evidence = client.post(
        f"/api/v1/insurance/claims/{claim_id}/evidence",
        headers=producer_headers,
        json={"evidence_type": "note", "caption": "Lens before handover"},
    )
    assert evidence.status_code == 201, evidence.text
    assert len(evidence.json["data"]["claim"]["evidence"]) == 1

    forbidden_decision = client.post(
        f"/api/v1/insurance/claims/{claim_id}/decision",
        headers=producer_headers,
        json={"status": "approved"},
    )
    assert forbidden_decision.status_code == 403, forbidden_decision.text

    decision = client.post(
        f"/api/v1/insurance/claims/{claim_id}/decision",
        headers=provider_headers,
        json={"status": "investigating", "estimate_minor": 7000000},
    )
    assert decision.status_code == 200, decision.text
    assert decision.json["data"]["claim"]["status"] == "investigating"
    assert decision.json["data"]["claim"]["estimate_minor"] == 7000000

    final_decision = client.post(
        f"/api/v1/insurance/claims/{claim_id}/decision",
        headers=provider_headers,
        json={"status": "approved"},
    )
    assert final_decision.status_code == 200, final_decision.text
    assert final_decision.json["data"]["claim"]["status"] == "approved"

    claims_list = client.get("/api/v1/insurance/claims", headers=producer_headers)
    assert claims_list.status_code == 200, claims_list.text
    assert len(claims_list.json["data"]["claims"]) == 1

    dashboard = client.get("/api/v1/insurance/dashboard", headers=provider_headers)
    assert dashboard.status_code == 200, dashboard.text
    assert dashboard.json["data"]["policy_count"] == 1
    assert dashboard.json["data"]["active_policy_count"] == 1
