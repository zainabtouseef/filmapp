from __future__ import annotations

from typing import Any

from sqlalchemy import select

from app.extensions import db
from app.models.files import FileAsset


def mark_file_scan_clean(file_public_id: str) -> dict[str, Any]:
    """Local/demo scan processor.

    Production will replace this state transition with object existence checks,
    checksum verification, ClamAV scanning, metadata stripping, and media
    derivative generation. Keeping the transition isolated lets the API and
    worker exercise the same state machine today without trusting user input in
    production.
    """

    file = db.session.execute(
        select(FileAsset).where(FileAsset.public_id == file_public_id)
    ).scalar_one_or_none()
    if file is None:
        return {"updated": False, "reason": "not_found"}
    if file.scan_status != "pending":
        return {
            "updated": False,
            "reason": "already_processed",
            "scan_status": file.scan_status,
            "processing_status": file.processing_status,
        }

    file.scan_status = "clean"
    file.processing_status = "ready"
    db.session.commit()
    return {
        "updated": True,
        "file_id": file.public_id,
        "scan_status": file.scan_status,
        "processing_status": file.processing_status,
    }
