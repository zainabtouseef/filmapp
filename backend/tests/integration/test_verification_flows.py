from __future__ import annotations

import os
import uuid
from hashlib import sha256
from urllib.parse import urlparse

import pytest
from flask.testing import FlaskClient
from sqlalchemy import select

from app.extensions import db
from app.models.base import utc_now
from app.models.identity import Role, User, UserRole
from app.services.file_processing import mark_file_scan_clean

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        os.getenv("RUN_INTEGRATION_TESTS") != "1",
        reason="Set RUN_INTEGRATION_TESTS=1 with MySQL and Redis running.",
    ),
]


def _registered_user(client: FlaskClient) -> tuple[dict[str, str], str]:
    email = f"kyc-{uuid.uuid4().hex[:12]}@example.com"
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "StrongPass123!",
            "display_name": "KYC User",
            "initial_role": "actor_talent",
            "terms_version": "2026-07",
        },
    )
    assert response.status_code == 201, response.text
    token = response.json["data"]["tokens"]["access_token"]
    return (
        {"Authorization": f"Bearer {token}"},
        response.json["data"]["user"]["public_id"],
    )


def _auth_headers(client: FlaskClient) -> dict[str, str]:
    headers, _ = _registered_user(client)
    return headers


def _reviewer_headers(client: FlaskClient) -> dict[str, str]:
    headers, user_public_id = _registered_user(client)
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        role = db.session.execute(
            select(Role).where(Role.code == "reviewer")
        ).scalar_one()
        db.session.add(
            UserRole(
                user_id=user.id,
                role_id=role.id,
                status="active",
                is_primary=False,
                approved_at=utc_now(),
            )
        )
        db.session.commit()
    return headers


def test_upload_and_kyc_submission_review_flow(client: FlaskClient) -> None:
    headers = _auth_headers(client)
    file_bytes = b"real-ish cnic image bytes" * 82

    presign = client.post(
        "/api/v1/uploads/presign",
        headers=headers,
        json={
            "purpose": "kyc_document",
            "mime_type": "image/jpeg",
            "original_name": "cnic-front.jpg",
            "size_bytes": 2048,
        },
    )
    assert presign.status_code == 201, presign.text
    upload_id = presign.json["data"]["upload_session_id"]
    assert presign.json["data"]["method"] == "PUT"
    upload_path = urlparse(presign.json["data"]["upload_url"]).path

    binary = client.put(
        upload_path,
        headers={**headers, "Content-Type": "image/jpeg"},
        data=file_bytes,
    )
    assert binary.status_code == 200, binary.text
    assert binary.json["data"]["size_bytes"] == len(file_bytes)
    assert binary.json["data"]["checksum_sha256"] == sha256(file_bytes).hexdigest()

    complete = client.post(
        f"/api/v1/uploads/{upload_id}/complete",
        headers=headers,
    )
    assert complete.status_code == 201, complete.text
    file_id = complete.json["data"]["file"]["public_id"]
    assert complete.json["data"]["file"]["scan_status"] == "pending"
    assert complete.json["data"]["file"]["size_bytes"] == len(file_bytes)

    download = client.get(
        f"/api/v1/files/{file_id}/download",
        headers=headers,
    )
    assert download.status_code == 200
    assert download.data == file_bytes

    other_headers = _auth_headers(client)
    forbidden_download = client.get(
        f"/api/v1/files/{file_id}/download",
        headers=other_headers,
    )
    assert forbidden_download.status_code == 404

    with client.application.app_context():
        scan_result = mark_file_scan_clean(file_id)
    assert scan_result["scan_status"] == "clean"
    assert scan_result["processing_status"] == "ready"

    created = client.post(
        "/api/v1/kyc/submissions",
        headers=headers,
        json={
            "role": "actor_talent",
            "documents": [
                {
                    "document_type": "national_id_front",
                    "country": "PK",
                    "file_id": file_id,
                }
            ],
        },
    )
    assert created.status_code == 201, created.text
    submission_id = created.json["data"]["submission"]["public_id"]
    assert created.json["data"]["submission"]["status"] == "draft"

    submitted = client.post(
        f"/api/v1/kyc/submissions/{submission_id}/submit",
        headers=headers,
    )
    assert submitted.status_code == 200, submitted.text
    assert submitted.json["data"]["submission"]["status"] == "pending"

    mine = client.get("/api/v1/me/kyc", headers=headers)
    assert mine.status_code == 200
    assert mine.json["data"]["submissions"][0]["public_id"] == submission_id

    forbidden_queue = client.get("/api/v1/admin/kyc/submissions", headers=headers)
    assert forbidden_queue.status_code == 403
    assert forbidden_queue.json["error"]["code"] == "auth.permission_denied"

    admin_headers = _reviewer_headers(client)
    queue = client.get("/api/v1/admin/kyc/submissions", headers=admin_headers)
    assert queue.status_code == 200
    assert any(
        item["public_id"] == submission_id for item in queue.json["data"]["submissions"]
    )
    queued = next(
        item
        for item in queue.json["data"]["submissions"]
        if item["public_id"] == submission_id
    )
    assert queued["user"]["display_name"] == "KYC User"

    detail = client.get(
        f"/api/v1/admin/kyc/submissions/{submission_id}",
        headers=admin_headers,
    )
    assert detail.status_code == 200
    assert detail.json["data"]["submission"]["public_id"] == submission_id

    decision = client.post(
        f"/api/v1/admin/kyc/submissions/{submission_id}/decision",
        headers=admin_headers,
        json={"decision": "approved", "reason": "Documents are clear."},
    )
    assert decision.status_code == 200, decision.text
    assert decision.json["data"]["submission"]["status"] == "approved"


def test_upload_presign_rejects_unsupported_type(client: FlaskClient) -> None:
    headers = _auth_headers(client)

    response = client.post(
        "/api/v1/uploads/presign",
        headers=headers,
        json={
            "purpose": "kyc_document",
            "mime_type": "application/x-msdownload",
            "original_name": "malware.exe",
            "size_bytes": 100,
        },
    )

    assert response.status_code == 422
    assert response.json["error"]["fields"]["mime_type"]
