from __future__ import annotations

import hashlib
import shlex
import socket
import struct
import subprocess
from pathlib import Path
from typing import Any

from flask import current_app
from sqlalchemy import select

from app.extensions import db
from app.models.files import FileAsset
from app.services.local_storage import resolve_path


def scan_file(path: Path) -> bool:
    """Use ClamAV's INSTREAM protocol; the daemon is private to the host."""
    command = shlex.split(str(current_app.config["FILE_SCAN_COMMAND"]))
    if command:
        result = subprocess.run(
            [*command, str(path)], capture_output=True, timeout=120, check=False
        )
        if result.returncode not in {0, 1}:
            raise RuntimeError("File scanner failed")
        return result.returncode == 0
    with socket.create_connection(
        (current_app.config["CLAMD_HOST"], current_app.config["CLAMD_PORT"]),
        timeout=120,
    ) as connection:
        connection.sendall(b"zINSTREAM\0")
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(64 * 1024), b""):
                connection.sendall(struct.pack("!I", len(chunk)) + chunk)
        connection.sendall(struct.pack("!I", 0))
        response = b""
        while b"\0" not in response and len(response) < 8192:
            chunk = connection.recv(1024)
            if not chunk:
                break
            response += chunk
    message = response.rstrip(b"\0\n")
    if message.endswith(b": OK"):
        return True
    if message.endswith(b" FOUND"):
        return False
    raise RuntimeError("File scanner did not return a valid verdict")


def mark_file_scan_clean(file_public_id: str) -> dict[str, Any]:
    """Publish a file only after storage-integrity verification and a real AV scan."""

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

    path = resolve_path(file)
    if not path.is_file():
        raise RuntimeError("Upload object is missing; scan will be retried")
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
            size += len(chunk)
    if size != file.size_bytes or (
        file.checksum_sha256 and digest.hexdigest() != file.checksum_sha256
    ):
        file.scan_status = "integrity_failed"
        file.processing_status = "failed"
        db.session.commit()
        return {
            "updated": True,
            "scan_status": file.scan_status,
            "processing_status": file.processing_status,
        }
    try:
        clean = scan_file(path)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise RuntimeError("File scanner is unavailable; scan will be retried") from exc
    file.scan_status = "clean" if clean else "infected"
    file.processing_status = "ready" if clean else "quarantined"
    db.session.commit()
    return {
        "updated": True,
        "file_id": file.public_id,
        "scan_status": file.scan_status,
        "processing_status": file.processing_status,
    }
