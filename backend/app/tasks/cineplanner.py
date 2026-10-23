from __future__ import annotations

from typing import Any

from celery import shared_task

from app.services.cineplanner_ai import analyze_screenplay_job


@shared_task(  # type: ignore[untyped-decorator]
    name="app.tasks.cineplanner.analyze_screenplay",
    autoretry_for=(ConnectionError, TimeoutError, RuntimeError),
    retry_backoff=True,
    retry_jitter=True,
    retry_kwargs={"max_retries": 3},
    reject_on_worker_lost=True,
)
def analyze_screenplay(job_public_id: str) -> dict[str, Any]:
    result = analyze_screenplay_job(job_public_id)
    if result.get("status") == "failed":
        raise RuntimeError("Screenplay section will resume from its saved checkpoint.")
    return result


@shared_task(name="app.tasks.cineplanner.draft_message", reject_on_worker_lost=True)  # type: ignore[untyped-decorator]
def draft_message(message_public_id: str) -> dict[str, str]:
    from app.services.cineplanner_editor import draft_message as draft

    return draft(message_public_id)
