from __future__ import annotations

import json
import uuid
from typing import Any

from sqlalchemy import select

from app.extensions import db
from app.models.base import utc_now
from app.models.trust_safety import Notification, NotificationDelivery, PushDevice


def notify_user(
    user_id: uuid.UUID,
    *,
    category: str,
    title: str,
    body: str,
    route_name: str | None = None,
    route_params: dict[str, Any] | None = None,
) -> Notification:
    notification = Notification(
        user_id=user_id,
        category=category,
        title=title[:180],
        body=body,
        route_name=route_name,
        route_params_json=json.dumps(route_params) if route_params else None,
    )
    db.session.add(notification)
    db.session.flush()

    sent_at = utc_now()
    db.session.add(
        NotificationDelivery(
            notification_id=notification.id,
            channel="in_app",
            provider="internal",
            status="delivered",
            sent_at=sent_at,
        )
    )

    has_push_device = db.session.execute(
        select(PushDevice).where(
            PushDevice.user_id == user_id, PushDevice.enabled.is_(True)
        )
    ).scalar_one_or_none()
    if has_push_device is not None:
        db.session.add(
            NotificationDelivery(
                notification_id=notification.id,
                channel="push",
                provider="sandbox",
                status="delivered",
                sent_at=sent_at,
            )
        )
    return notification
