from __future__ import annotations

import json
import uuid
from typing import Any

from sqlalchemy import select

from app.extensions import db
from app.models.base import utc_now
from app.models.identity import NotificationPreference
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

    from app.services.web_push import web_push_available

    preferences = db.session.execute(
        select(NotificationPreference).where(NotificationPreference.user_id == user_id)
    ).scalar_one_or_none()
    if preferences is not None and not preferences.push_enabled:
        return notification
    devices = db.session.execute(
        select(PushDevice)
        .where(PushDevice.user_id == user_id, PushDevice.enabled.is_(True))
        .limit(20)
    ).scalars()
    available = web_push_available()
    for device in devices:
        supported = (
            available
            and device.platform == "web"
            and bool(device.subscription_encrypted)
        )
        db.session.add(
            NotificationDelivery(
                notification_id=notification.id,
                channel="push",
                provider="webpush" if supported else "unconfigured",
                provider_reference=str(device.id),
                status="queued" if supported else "unavailable",
            )
        )
    return notification
