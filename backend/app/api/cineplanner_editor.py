from __future__ import annotations

import html
import io
from typing import Any

from celery import Celery
from flask import Blueprint, Response, current_app, jsonify, send_file
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.api.auth import _current_user, _json_body
from app.api.cineplanner import _production_for_user, _require_permission
from app.errors import APIError
from app.extensions import db, limiter
from app.models.cineplanner import CineProduction, CineScene
from app.models.cineplanner_access import CineAssistantMessage
from app.responses import success
from app.services.cineplanner_editor import (
    apply_message,
    editor_context,
    latest_script,
    serialize_message,
)

cineplanner_editor_blueprint = Blueprint(
    "cineplanner_editor", __name__, url_prefix="/cineplanner"
)


@cineplanner_editor_blueprint.get("/productions/<public_id>/assistant/messages")
def messages_index(public_id: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    rows = db.session.scalars(
        select(CineAssistantMessage)
        .where(CineAssistantMessage.production_id == production.id)
        .order_by(CineAssistantMessage.created_at.desc())
        .limit(60)
    ).all()
    return jsonify(
        success({"messages": [serialize_message(row) for row in reversed(rows)]})
    )


@cineplanner_editor_blueprint.post("/productions/<public_id>/assistant/messages")
@limiter.limit("30 per hour")
def messages_create(public_id: str) -> tuple[Response, int]:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "edit")
    db.session.execute(
        select(CineProduction.id)
        .where(CineProduction.id == production.id)
        .with_for_update()
    ).scalar_one()
    payload = _json_body()
    question = str(payload.get("question", "")).strip()
    if not 3 <= len(question) <= 8000:
        raise APIError(
            "validation.invalid",
            "Write a request between 3 and 8,000 characters.",
            status=422,
        )
    pending = db.session.scalar(
        select(CineAssistantMessage)
        .where(
            CineAssistantMessage.production_id == production.id,
            CineAssistantMessage.status.in_(["queued", "processing"]),
        )
        .with_for_update()
    )
    if pending:
        raise APIError(
            "cineplanner.assistant_busy",
            "The current request is still processing.",
            status=409,
        )
    context = editor_context(production, question, payload.get("scene_id"))
    history = db.session.scalars(
        select(CineAssistantMessage)
        .where(CineAssistantMessage.production_id == production.id)
        .order_by(CineAssistantMessage.created_at.desc())
        .limit(10)
    ).all()
    script = latest_script(production)
    assert script is not None
    db.session.add(
        CineAssistantMessage(
            production_id=production.id,
            user_id=user.id,
            script_version_id=script.id,
            role="user",
            content=question,
            status="complete",
        )
    )
    message = CineAssistantMessage(
        production_id=production.id,
        user_id=user.id,
        script_version_id=script.id,
        role="assistant",
        content="Preparing your response…",
        status="queued",
        context_json={
            "question": question,
            "history": [
                {"role": m.role, "content": m.content, "status": m.status}
                for m in reversed(history)
            ],
            "production_context": context,
        },
    )
    db.session.add(message)
    db.session.commit()
    queue = Celery("cineconnect-api")
    queue.conf.broker_url = current_app.config["CELERY_BROKER_URL"]
    try:
        queue.send_task(
            "app.tasks.cineplanner.draft_message",
            args=[message.public_id],
            queue=current_app.config["CINEPLANNER_TASK_QUEUE"],
        )
    except Exception:
        message.status = "failed"
        message.content = "The assistant queue is unavailable. Please try again."
        db.session.commit()
        raise APIError(
            "cineplanner.queue_unavailable", message.content, status=503
        ) from None
    return jsonify(success({"message": serialize_message(message)})), 202


@cineplanner_editor_blueprint.post(
    "/productions/<public_id>/assistant/messages/<message_id>/<action>"
)
def message_decision(public_id: str, message_id: str, action: str) -> Response:
    user = _current_user()
    production = _production_for_user(public_id, user)
    _require_permission(production, user, "edit")
    db.session.execute(
        select(CineProduction.id)
        .where(CineProduction.id == production.id)
        .with_for_update()
    ).scalar_one()
    message = db.session.scalar(
        select(CineAssistantMessage)
        .where(
            CineAssistantMessage.production_id == production.id,
            CineAssistantMessage.public_id == message_id,
        )
        .with_for_update()
    )
    if not message or message.role != "assistant":
        raise APIError(
            "cineplanner.message_not_found", "Proposal was not found.", status=404
        )
    if action == "discard":
        if message.status == "proposed":
            message.status = "discarded"
    elif action in {"apply", "undo"}:
        try:
            apply_message(production, user, message, undo=action == "undo")
            db.session.flush()
        except IntegrityError:
            db.session.rollback()
            raise APIError(
                "cineplanner.edit_conflict",
                "This change conflicts with an existing or assigned item. "
                "Request a revised proposal.",
                status=409,
            ) from None
    else:
        raise APIError(
            "validation.invalid", "Choose apply, discard, or undo.", status=422
        )
    db.session.commit()
    return jsonify(success({"message": serialize_message(message)}))


@cineplanner_editor_blueprint.get("/productions/<public_id>/screenplay.pdf")
def screenplay_export(public_id: str) -> Any:
    user = _current_user()
    production = _production_for_user(public_id, user)
    script = latest_script(production)
    scenes = list(
        db.session.scalars(
            select(CineScene)
            .where(CineScene.script_version_id == (script.id if script else None))
            .order_by(CineScene.sort_order)
        )
    )
    if not scenes or any(not scene.source_text for scene in scenes):
        raise APIError(
            "cineplanner.source_text_unavailable",
            "Analyze the screenplay with the updated reader before "
            "exporting an editable draft.",
            status=409,
        )
    output = io.BytesIO()
    styles = getSampleStyleSheet()
    story: list[Any] = [
        Paragraph(html.escape(production.title) + " — working draft", styles["Title"]),
        Spacer(1, 18),
    ]
    for scene in scenes:
        story.append(
            Paragraph(f"Scene {html.escape(scene.scene_number)}", styles["Heading2"])
        )
        for paragraph in scene.source_text.split("\n"):
            if paragraph.strip():
                story.append(Paragraph(html.escape(paragraph), styles["BodyText"]))
            else:
                story.append(Spacer(1, 6))
    SimpleDocTemplate(output, pagesize=A4).build(story)
    output.seek(0)
    return send_file(
        output,
        mimetype="application/pdf",
        as_attachment=True,
        download_name="cineplanner-working-draft.pdf",
    )
