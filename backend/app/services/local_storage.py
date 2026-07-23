from __future__ import annotations

import hashlib
import os
from pathlib import Path
from typing import IO

from flask import current_app

from app.errors import APIError
from app.models.files import FileAsset, UploadSession

CHUNK_SIZE = 1024 * 1024


def _root_for_bucket(bucket: str) -> Path:
    private_bucket = current_app.config.get("OBJECT_STORAGE_BUCKET_PRIVATE")
    public_bucket = current_app.config.get("OBJECT_STORAGE_BUCKET_PUBLIC")
    if bucket in {"private", private_bucket}:
        return Path(current_app.config["LOCAL_STORAGE_PRIVATE_ROOT"])
    if bucket in {"public", public_bucket}:
        return Path(current_app.config["LOCAL_STORAGE_PUBLIC_ROOT"])
    raise APIError("uploads.storage_bucket_invalid", "Upload storage is invalid.")


def _safe_storage_path(root: Path, storage_key: str) -> Path:
    if not storage_key or storage_key.startswith(("/", "\\")):
        raise APIError("uploads.storage_key_invalid", "Upload storage path is invalid.")
    candidate = (root / storage_key).resolve()
    root_resolved = root.resolve()
    try:
        candidate.relative_to(root_resolved)
    except ValueError as exc:
        raise APIError(
            "uploads.storage_key_invalid",
            "Upload storage path is invalid.",
        ) from exc
    return candidate


def save_stream(upload_session: UploadSession, stream: IO[bytes]) -> tuple[int, str]:
    root = _root_for_bucket(upload_session.bucket)
    path = _safe_storage_path(root, upload_session.storage_key)
    tmp_path = path.with_name(f".{path.name}.tmp")
    path.parent.mkdir(parents=True, exist_ok=True)

    digest = hashlib.sha256()
    size = 0
    try:
        with tmp_path.open("wb") as handle:
            while True:
                chunk = stream.read(CHUNK_SIZE)
                if not chunk:
                    break
                size += len(chunk)
                if size > upload_session.max_bytes:
                    raise APIError(
                        "uploads.file_too_large",
                        "Uploaded file exceeds the allowed size.",
                        status=413,
                    )
                digest.update(chunk)
                handle.write(chunk)
        if size <= 0:
            raise APIError("uploads.empty_file", "Uploaded file is empty.", status=422)
        os.replace(tmp_path, path)
    except Exception:
        tmp_path.unlink(missing_ok=True)
        path.unlink(missing_ok=True)
        raise

    return size, digest.hexdigest()


def resolve_path(file_asset: FileAsset) -> Path:
    root = _root_for_bucket(file_asset.bucket)
    return _safe_storage_path(root, file_asset.storage_key)


def public_url_for(file_asset: FileAsset) -> str | None:
    if file_asset.visibility != "public":
        return None
    if file_asset.scan_status != "clean" or file_asset.processing_status != "ready":
        return None
    base_url = str(current_app.config.get("PUBLIC_MEDIA_BASE_URL") or "").rstrip("/")
    if not base_url:
        return None
    return f"{base_url}/{file_asset.storage_key.lstrip('/')}"
