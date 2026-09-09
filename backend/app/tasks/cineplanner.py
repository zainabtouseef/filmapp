from __future__ import annotations

from typing import Any

from celery import shared_task

from app.services.cineplanner_ai import analyze_screenplay_job


@shared_task(  # type: ignore[untyped-decorator]
    name="app.tasks.cineplanner.analyze_screenplay",
    autoretry_for=(ConnectionError, TimeoutError),
    retry_backoff=True,
    retry_jitter=True,
    retry_kwargs={"max_retries": 3},
)
def analyze_screenplay(job_public_id: str) -> dict[str, Any]:
    return analyze_screenplay_job(job_public_id)
