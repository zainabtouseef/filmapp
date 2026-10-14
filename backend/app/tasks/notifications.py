from celery import shared_task

from app.services.web_push import deliver_web_push_batch


@shared_task(name="app.tasks.notifications.deliver_pending")  # type: ignore[untyped-decorator]
def deliver_pending() -> dict[str, int]:
    return deliver_web_push_batch()
