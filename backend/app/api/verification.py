from __future__ import annotations

import uuid
from datetime import timedelta
from typing import Any

from celery import Celery
from flask import Blueprint, Response, current_app, jsonify, request, send_file
from flask.typing import ResponseReturnValue
from sqlalchemy import select

from app.api.auth import _current_user, _json_body
from app.errors import APIError
from app.extensions import db, limiter
from app.models.base import utc_now
from app.models.files import FileAsset, UploadSession
from app.models.identity import Role, UserRole
from app.models.kyc import KycDocument, KycSubmission, VerificationEvent
from app.policies import require_permission
from app.responses import success
from app.security import as_utc
from app.services.local_storage import resolve_path, save_stream

verification_blueprint = Blueprint("verification", __name__)

ALLOWED_UPLOAD_MIME_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "application/pdf",
    "video/mp4",
}


def _enqueue_file_scan(file_public_id: str) -> None:
    celery_client = Celery("cineconnect-api")
    celery_client.conf.broker_url = current_app.config["CELERY_BROKER_URL"]
    try:
        celery_client.send_task(
            "app.tasks.files.scan_completed_file",
            args=[file_public_id],
        )
    except Exception:
        current_app.logger.exception(
            "file_scan_enqueue_failed",
            extra={"file_public_id": file_public_id},
        )


def _field_error(field: str, message: str) -> APIError:
    return APIError(
        "validation.invalid",
        "Request validation failed.",
        status=422,
        fields={field: [message]},
    )


def _serialize_file(file: FileAsset) -> dict[str, Any]:
    return {
        "public_id": file.public_id,
        "mime_type": file.mime_type,
        "size_bytes": file.size_bytes,
        "visibility": file.visibility,
        "scan_status": file.scan_status,
        "processing_status": file.processing_status,
        "original_name": file.original_name,
        "download_url": f"/api/v1/files/{file.public_id}/download",
    }


def _safe_original_name(original_name: str) -> str:
    clean_name = original_name.replace("\\", "/").split("/")[-1].strip()
    if not clean_name or clean_name in {".", ".."} or ".." in clean_name:
        raise _field_error("original_name", "Original file name is invalid.")
    return clean_name[:255]


def _serialize_submission(submission: KycSubmission) -> dict[str, Any]:
    return {
        "public_id": submission.public_id,
        "user": {
            "public_id": submission.user.public_id,
            "display_name": submission.user.display_name,
            "email": submission.user.email,
        },
        "role": {
            "code": submission.role.code,
            "name": submission.role.name,
        },
        "status": submission.status,
        "risk_level": submission.risk_level,
        "submitted_at": submission.submitted_at.isoformat()
        if submission.submitted_at
        else None,
        "decision_at": submission.decision_at.isoformat()
        if submission.decision_at
        else None,
        "decision_reason": submission.decision_reason,
        "documents": [
            {
                "document_type": document.document_type,
                "country": document.country,
                "status": document.status,
                "rejection_reason": document.rejection_reason,
                "file": _serialize_file(document.file) if document.file else None,
            }
            for document in submission.documents
        ],
    }


def _record_event(
    submission: KycSubmission,
    *,
    actor_id: uuid.UUID | None,
    from_status: str | None,
    to_status: str,
    reason: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> None:
    db.session.add(
        VerificationEvent(
            submission_id=submission.id,
            actor_user_id=actor_id,
            from_status=from_status,
            to_status=to_status,
            reason=reason,
            metadata_json=metadata or {},
        )
    )


@verification_blueprint.post("/uploads/presign")
@limiter.limit("60 per hour")
def presign_upload() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    purpose = str(payload.get("purpose", "")).strip()
    mime_type = str(payload.get("mime_type", "")).strip().lower()
    original_name = str(payload.get("original_name", "")).strip()
    requested_size = int(payload.get("size_bytes", 0) or 0)

    if purpose not in {
        "kyc_document",
        "profile_media",
        "payment_proof",
        "project_document",
        "location_media",
        "equipment_media",
        "inspection_evidence",
        "damage_evidence",
        "insurance_document",
        "insurance_evidence",
    }:
        raise _field_error("purpose", "Unsupported upload purpose.")
    if mime_type not in ALLOWED_UPLOAD_MIME_TYPES:
        raise _field_error("mime_type", "Unsupported file type.")
    if not original_name:
        raise _field_error("original_name", "Original file name is required.")
    original_name = _safe_original_name(original_name)
    max_bytes = 25 * 1024 * 1024 if purpose == "kyc_document" else 250 * 1024 * 1024
    if requested_size <= 0 or requested_size > max_bytes:
        raise _field_error(
            "size_bytes", f"File must be between 1 byte and {max_bytes} bytes."
        )

    storage_key = f"{purpose}/{user.public_id}/{uuid.uuid4().hex}/{original_name}"
    expires_at = utc_now() + timedelta(minutes=15)
    upload = UploadSession(
        user_id=user.id,
        purpose=purpose,
        mime_type=mime_type,
        max_bytes=max_bytes,
        storage_key=storage_key,
        bucket="private",
        original_name=original_name,
        expires_at=expires_at,
    )
    db.session.add(upload)
    db.session.commit()
    upload_url = (
        f"{current_app.config['API_PUBLIC_URL']}"
        f"/api/v1/uploads/{upload.public_id}/binary"
    )
    return jsonify(
        success(
            {
                "upload_session_id": upload.public_id,
                "method": "PUT",
                "upload_url": upload_url,
                "expires_at": expires_at.isoformat(),
                "headers": {"Content-Type": mime_type},
                "max_bytes": max_bytes,
                "storage_key": storage_key,
            }
        )
    ), 201


@verification_blueprint.put("/uploads/<public_id>/binary")
@limiter.limit("60 per hour")
def upload_binary(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    upload = db.session.execute(
        select(UploadSession).where(
            UploadSession.public_id == public_id,
            UploadSession.user_id == user.id,
        )
    ).scalar_one_or_none()
    if upload is None:
        raise APIError("uploads.not_found", "Upload session was not found.", status=404)
    if upload.completed_at is not None:
        raise APIError(
            "uploads.already_completed",
            "Upload session has already been completed.",
            status=409,
        )
    if as_utc(upload.expires_at) <= utc_now():
        raise APIError("uploads.expired", "Upload session has expired.", status=410)
    content_length = request.content_length
    if content_length is not None and content_length > upload.max_bytes:
        raise APIError(
            "uploads.file_too_large",
            "Uploaded file exceeds the allowed size.",
            status=413,
        )
    size_bytes, checksum = save_stream(upload, request.stream)
    upload.received_size_bytes = size_bytes
    upload.received_checksum_sha256 = checksum
    upload.binary_received_at = utc_now()
    db.session.commit()
    return jsonify(
        success(
            {
                "upload_session_id": upload.public_id,
                "size_bytes": size_bytes,
                "checksum_sha256": checksum,
            }
        )
    )


@verification_blueprint.post("/uploads/<public_id>/complete")
def complete_upload(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    upload = db.session.execute(
        select(UploadSession).where(
            UploadSession.public_id == public_id,
            UploadSession.user_id == user.id,
        )
    ).scalar_one_or_none()
    if upload is None:
        raise APIError("uploads.not_found", "Upload session was not found.", status=404)
    if upload.completed_at is not None and upload.file is not None:
        return jsonify(success({"file": _serialize_file(upload.file)}))
    if as_utc(upload.expires_at) <= utc_now():
        raise APIError("uploads.expired", "Upload session has expired.", status=410)
    if (
        upload.binary_received_at is None
        or upload.received_size_bytes is None
        or upload.received_checksum_sha256 is None
    ):
        raise APIError(
            "uploads.binary_not_received",
            "Upload file bytes must be sent before completing the upload.",
            status=409,
        )

    file = FileAsset(
        owner_user_id=user.id,
        storage_key=upload.storage_key,
        bucket=upload.bucket,
        mime_type=upload.mime_type,
        size_bytes=upload.received_size_bytes,
        checksum_sha256=upload.received_checksum_sha256,
        visibility="authorized",
        scan_status="pending",
        processing_status="pending",
        original_name=upload.original_name,
    )
    db.session.add(file)
    db.session.flush()
    upload.file_id = file.id
    upload.completed_at = utc_now()
    db.session.commit()
    _enqueue_file_scan(file.public_id)
    return jsonify(success({"file": _serialize_file(file)})), 201


@verification_blueprint.get("/files/<public_id>/download")
def download_file(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    file = db.session.execute(
        select(FileAsset).where(
            FileAsset.public_id == public_id,
            FileAsset.owner_user_id == user.id,
        )
    ).scalar_one_or_none()
    if file is None:
        raise APIError("files.not_found", "File was not found.", status=404)
    path = resolve_path(file)
    if not path.exists() or not path.is_file():
        raise APIError("files.missing", "File bytes are not available.", status=404)
    response = send_file(
        path,
        mimetype=file.mime_type,
        as_attachment=True,
        download_name=file.original_name,
    )
    response.headers["Cache-Control"] = "private, max-age=0"
    return response


@verification_blueprint.post("/kyc/submissions")
def create_kyc_submission() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    role_code = str(payload.get("role", "")).strip()
    role = db.session.execute(
        select(Role).where(Role.code == role_code, Role.is_active.is_(True))
    ).scalar_one_or_none()
    if role is None:
        raise _field_error("role", "Select a supported role.")
    granted = db.session.execute(
        select(UserRole).where(
            UserRole.user_id == user.id,
            UserRole.role_id == role.id,
            UserRole.status == "active",
        )
    ).scalar_one_or_none()
    if granted is None:
        raise APIError(
            "kyc.role_not_granted",
            "This role is not active on your account.",
            status=403,
        )

    submission = KycSubmission(user_id=user.id, role_id=role.id)
    db.session.add(submission)
    db.session.flush()
    for item in payload.get("documents", []):
        if not isinstance(item, dict):
            continue
        document = KycDocument(
            submission_id=submission.id,
            document_type=str(item.get("document_type", "")).strip(),
            country=str(item.get("country", "PK")).strip().upper()[:2],
        )
        file_public_id = str(item.get("file_id", "")).strip()
        if file_public_id:
            file = db.session.execute(
                select(FileAsset).where(
                    FileAsset.public_id == file_public_id,
                    FileAsset.owner_user_id == user.id,
                )
            ).scalar_one_or_none()
            if file is None:
                raise _field_error("documents", "A referenced file was not found.")
            document.file_id = file.id
        db.session.add(document)
    _record_event(
        submission,
        actor_id=user.id,
        from_status=None,
        to_status="draft",
        reason="KYC draft created",
    )
    db.session.commit()
    return jsonify(success({"submission": _serialize_submission(submission)})), 201


@verification_blueprint.post("/kyc/submissions/<public_id>/submit")
def submit_kyc(public_id: str) -> Response:
    user = _current_user()
    submission = db.session.execute(
        select(KycSubmission).where(
            KycSubmission.public_id == public_id,
            KycSubmission.user_id == user.id,
        )
    ).scalar_one_or_none()
    if submission is None:
        raise APIError("kyc.not_found", "KYC submission was not found.", status=404)
    previous = submission.status
    submission.status = "pending"
    submission.submitted_at = utc_now()
    _record_event(
        submission,
        actor_id=user.id,
        from_status=previous,
        to_status="pending",
        reason="Submitted for admin review",
    )
    db.session.commit()
    return jsonify(success({"submission": _serialize_submission(submission)}))


@verification_blueprint.get("/me/kyc")
def my_kyc() -> Response:
    user = _current_user()
    submissions = db.session.execute(
        select(KycSubmission)
        .where(KycSubmission.user_id == user.id)
        .order_by(KycSubmission.created_at.desc())
    ).scalars()
    return jsonify(
        success({"submissions": [_serialize_submission(item) for item in submissions]})
    )


@verification_blueprint.post("/kyc/submissions/<public_id>/resubmit")
def resubmit_kyc(public_id: str) -> Response:
    user = _current_user()
    submission = db.session.execute(
        select(KycSubmission).where(
            KycSubmission.public_id == public_id,
            KycSubmission.user_id == user.id,
        )
    ).scalar_one_or_none()
    if submission is None:
        raise APIError("kyc.not_found", "KYC submission was not found.", status=404)
    previous = submission.status
    submission.status = "pending"
    submission.submitted_at = utc_now()
    submission.decision_reason = None
    _record_event(
        submission,
        actor_id=user.id,
        from_status=previous,
        to_status="pending",
        reason="Resubmitted by user",
    )
    db.session.commit()
    return jsonify(success({"submission": _serialize_submission(submission)}))


@verification_blueprint.get("/admin/kyc/submissions")
def admin_kyc_queue() -> Response:
    user = _current_user()
    require_permission(user, "kyc.review")
    status = request.args.get("status", "pending")
    submissions = db.session.execute(
        select(KycSubmission)
        .where(KycSubmission.status == status)
        .order_by(KycSubmission.created_at.asc())
        .limit(100)
    ).scalars()
    return jsonify(
        success({"submissions": [_serialize_submission(item) for item in submissions]})
    )


@verification_blueprint.get("/admin/kyc/submissions/<public_id>")
def admin_kyc_detail(public_id: str) -> Response:
    user = _current_user()
    require_permission(user, "kyc.review")
    submission = db.session.execute(
        select(KycSubmission).where(KycSubmission.public_id == public_id)
    ).scalar_one_or_none()
    if submission is None:
        raise APIError("kyc.not_found", "KYC submission was not found.", status=404)
    return jsonify(success({"submission": _serialize_submission(submission)}))


@verification_blueprint.post("/admin/kyc/submissions/<public_id>/decision")
def admin_kyc_decision(public_id: str) -> Response:
    actor = _current_user()
    require_permission(actor, "kyc.review")
    payload = _json_body()
    decision = str(payload.get("decision", "")).strip()
    reason = str(payload.get("reason", "")).strip()
    if decision not in {"approved", "rejected", "needs_resubmission"}:
        raise _field_error(
            "decision", "Decision must be approved, rejected, or needs_resubmission."
        )
    submission = db.session.execute(
        select(KycSubmission).where(KycSubmission.public_id == public_id)
    ).scalar_one_or_none()
    if submission is None:
        raise APIError("kyc.not_found", "KYC submission was not found.", status=404)
    previous = submission.status
    submission.status = decision
    submission.assigned_admin_id = actor.id
    submission.decision_at = utc_now()
    submission.decision_reason = reason or None
    if decision == "approved":
        for user_role in submission.user.roles:
            if user_role.role_id == submission.role_id:
                user_role.status = "active"
                user_role.approved_at = utc_now()
    _record_event(
        submission,
        actor_id=actor.id,
        from_status=previous,
        to_status=decision,
        reason=reason or None,
    )
    db.session.commit()
    return jsonify(success({"submission": _serialize_submission(submission)}))
