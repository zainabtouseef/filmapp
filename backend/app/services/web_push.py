from __future__ import annotations

import base64
import json
import uuid
from datetime import timedelta
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from cryptography.hazmat.primitives.asymmetric import ec
from flask import current_app
from itsdangerous import URLSafeTimedSerializer
from pywebpush import WebPushException, webpush
from requests.exceptions import RequestException
from sqlalchemy import or_, select

from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.identity import NotificationPreference
from app.models.trust_safety import NotificationDelivery, PushDevice
from app.services.private_fields import decrypt_private_value


def web_push_available() -> bool:
    return bool(
        current_app.config["VAPID_PUBLIC_KEY"]
        and current_app.config["VAPID_PRIVATE_KEY_FILE"]
        and Path(current_app.config["VAPID_PRIVATE_KEY_FILE"]).is_file()
    )


def validate_subscription(value: object) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise APIError(
            "push.invalid_subscription",
            "A browser subscription is required.",
            status=422,
        )
    endpoint = value.get("endpoint")
    try:
        parsed = urlparse(endpoint) if isinstance(endpoint, str) else None
        port = parsed.port if parsed else None
    except ValueError as exc:
        raise APIError(
            "push.invalid_subscription", "Invalid push endpoint.", status=422
        ) from exc
    allowed = {
        "fcm.googleapis.com",
        "updates.push.services.mozilla.com",
        "web.push.apple.com",
        "notify.windows.com",
        "wns.windows.com",
    }
    host = parsed.hostname if parsed else None
    if (
        not parsed
        or parsed.scheme != "https"
        or parsed.username
        or parsed.password
        or port not in {None, 443}
        or not host
        or not any(host == domain or host.endswith("." + domain) for domain in allowed)
    ):
        raise APIError(
            "push.invalid_subscription", "Unsupported browser push service.", status=422
        )
    keys = value.get("keys")
    if not isinstance(keys, dict):
        raise APIError(
            "push.invalid_subscription",
            "Browser subscription keys are required.",
            status=422,
        )
    for name, size in [("p256dh", 65), ("auth", 16)]:
        try:
            text = keys[name]
            if not isinstance(text, str) or len(text) > 256:
                raise ValueError()
            data = base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))
            if len(data) != size:
                raise ValueError()
            if name == "p256dh":
                ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), data)
        except (KeyError, TypeError, ValueError) as exc:
            raise APIError(
                "push.invalid_subscription",
                "Browser subscription keys are invalid.",
                status=422,
            ) from exc
    if len(str(endpoint)) > 3000:
        raise APIError(
            "push.invalid_subscription", "Browser endpoint is too long.", status=422
        )
    return {
        "endpoint": endpoint,
        "keys": {"p256dh": keys["p256dh"], "auth": keys["auth"]},
    }


def receipt_signer() -> URLSafeTimedSerializer:
    return URLSafeTimedSerializer(
        current_app.config["SECRET_KEY"], salt="push-display-receipt-v1"
    )


def deliver_web_push_batch() -> dict[str, int]:
    if not web_push_available():
        return {"sent": 0, "failed": 0}
    rows = (
        db.session.execute(
            select(NotificationDelivery)
            .where(
                NotificationDelivery.provider == "webpush",
                NotificationDelivery.status.in_({"queued", "retry"}),
                NotificationDelivery.attempts < 5,
                or_(
                    NotificationDelivery.next_attempt_at.is_(None),
                    NotificationDelivery.next_attempt_at <= utc_now(),
                ),
            )
            .limit(20)
            .with_for_update(skip_locked=True)
        )
        .scalars()
        .all()
    )
    sent = failed = 0
    for row in rows:
        try:
            device = db.session.get(PushDevice, uuid.UUID(row.provider_reference or ""))
        except ValueError:
            device = None
        notification = row.notification
        preference = db.session.execute(
            select(NotificationPreference).where(
                NotificationPreference.user_id == notification.user_id
            )
        ).scalar_one_or_none()
        if (
            device is None
            or not device.enabled
            or not device.subscription_encrypted
            or (preference and not preference.push_enabled)
        ):
            row.status = "cancelled"
            continue
        row.attempts += 1
        payload = {
            "title": notification.title,
            "body": notification.body[:500],
            "tag": notification.public_id,
            "url": "/#/notifications",
            "receipt": receipt_signer().dumps({"delivery_id": str(row.id)}),
        }
        try:
            response = webpush(
                subscription_info=json.loads(
                    decrypt_private_value(device.subscription_encrypted)
                ),
                data=json.dumps(payload),
                vapid_private_key=current_app.config["VAPID_PRIVATE_KEY_FILE"],
                vapid_claims={"sub": current_app.config["VAPID_SUBJECT"]},
                ttl=86400,
                timeout=8,
            )
            if not 200 <= response.status_code < 300:
                raise WebPushException(
                    "Push service rejected the request", response=response
                )
            row.status = "sent"
            row.sent_at = utc_now()
            row.failed_reason = None
            sent += 1
        except (WebPushException, RequestException, OSError, ValueError) as exc:
            response = getattr(exc, "response", None)
            status = getattr(response, "status_code", None)
            if status in {404, 410}:
                device.enabled = False
            row.status = (
                "failed"
                if status in {400, 404, 410, 413} or row.attempts >= 5
                else "retry"
            )
            row.next_attempt_at = utc_now() + timedelta(minutes=2**row.attempts)
            row.failed_reason = (
                f"Push service request failed (HTTP {status or 'unavailable'})."
            )
            failed += 1
    db.session.commit()
    return {"sent": sent, "failed": failed}
