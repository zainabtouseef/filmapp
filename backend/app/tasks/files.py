from __future__ import annotations

from typing import Any

from celery import shared_task

from app.services.file_processing import mark_file_scan_clean


@shared_task(  # type: ignore[untyped-decorator]
    name="app.tasks.files.scan_completed_file",
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_kwargs={"max_retries": 3},
)
def scan_completed_file(file_public_id: str) -> dict[str, Any]:
    return mark_file_scan_clean(file_public_id)
