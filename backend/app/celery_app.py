from __future__ import annotations

from celery import Celery, Task

from app import create_app


def create_celery() -> Celery:
    flask_app = create_app()

    class FlaskTask(Task):  # type: ignore[misc]
        def __call__(self, *args: object, **kwargs: object) -> object:
            with flask_app.app_context():
                return self.run(*args, **kwargs)

    celery_app = Celery(flask_app.import_name, task_cls=FlaskTask)
    celery_app.conf.update(
        broker_url=flask_app.config["CELERY_BROKER_URL"],
        result_backend=flask_app.config["CELERY_RESULT_BACKEND"],
        task_serializer="json",
        result_serializer="json",
        accept_content=["json"],
        timezone="UTC",
        enable_utc=True,
        task_acks_late=True,
        worker_prefetch_multiplier=1,
        imports=("app.tasks.files", "app.tasks.cineplanner"),
    )
    celery_app.set_default()
    return celery_app


celery = create_celery()
