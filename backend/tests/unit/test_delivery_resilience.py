"""Exercise push retry boundaries and antivirus protocol failures without providers."""

import struct
from unittest.mock import Mock, patch

import pytest
from requests.exceptions import ConnectionError
from sqlalchemy import select

from app.extensions import db
from app.models.identity import User
from app.models.trust_safety import NotificationDelivery, PushDevice
from app.services.file_processing import scan_file
from app.services.notifications import notify_user
from app.services.web_push import deliver_web_push_batch, validate_subscription
from tests.unit.test_audit_remediation import catalogue as catalogue
from tests.unit.test_audit_remediation import register, subscription


@pytest.mark.parametrize(
    ("status", "attempts", "expected", "enabled"),
    [
        (410, 0, "failed", False),
        (404, 0, "failed", False),
        (400, 0, "failed", True),
        (413, 0, "failed", True),
        (429, 0, "retry", True),
        (503, 0, "retry", True),
        (503, 4, "failed", True),
    ],
)
def test_push_failure_retry_and_device_disable(
    client, app, tmp_path, status, attempts, expected, enabled
):
    headers, user_data = register(client)
    key = tmp_path / "vapid.pem"
    key.write_text("mock transport key")
    app.config.update(VAPID_PUBLIC_KEY="test", VAPID_PRIVATE_KEY_FILE=str(key))
    result = client.post(
        "/api/v1/push-devices",
        headers=headers,
        json={
            "device_id": "retry-qa",
            "platform": "web",
            "subscription": subscription(),
            "enabled": True,
        },
    )
    assert result.status_code == 201
    with app.app_context():
        user = db.session.scalar(
            select(User).where(User.public_id == user_data["public_id"])
        )
        notify_user(user.id, category="qa", title="Retry", body="QA")
        db.session.commit()
        row = db.session.scalar(
            select(NotificationDelivery).where(NotificationDelivery.channel == "push")
        )
        row.attempts = attempts
        db.session.commit()
        with patch(
            "app.services.web_push.webpush", return_value=Mock(status_code=status)
        ):
            assert deliver_web_push_batch() == {"sent": 0, "failed": 1}
        assert row.status == expected and row.attempts == attempts + 1
        assert row.sent_at is None
        assert db.session.scalar(select(PushDevice)).enabled is enabled
        with patch("app.services.web_push.webpush") as transport:
            deliver_web_push_batch()
            transport.assert_not_called()


def test_push_network_failure_redacts_endpoint_and_credentials(client, app, tmp_path):
    headers, user_data = register(client)
    key = tmp_path / "vapid.pem"
    key.write_text("mock transport key")
    app.config.update(VAPID_PUBLIC_KEY="test", VAPID_PRIVATE_KEY_FILE=str(key))
    client.post(
        "/api/v1/push-devices",
        headers=headers,
        json={
            "device_id": "offline",
            "platform": "web",
            "subscription": subscription(),
            "enabled": True,
        },
    )
    with app.app_context():
        user = db.session.scalar(
            select(User).where(User.public_id == user_data["public_id"])
        )
        notify_user(user.id, category="qa", title="Offline", body="QA")
        db.session.commit()
        with patch(
            "app.services.web_push.webpush",
            side_effect=ConnectionError("SENSITIVE endpoint token"),
        ):
            assert deliver_web_push_batch() == {"sent": 0, "failed": 1}
        row = db.session.scalar(
            select(NotificationDelivery).where(NotificationDelivery.channel == "push")
        )
        assert row.status == "retry" and "SENSITIVE" not in row.failed_reason
        row.provider_reference = "not-a-uuid"
        row.next_attempt_at = None
        db.session.commit()
        assert deliver_web_push_batch() == {"sent": 0, "failed": 0}
        assert row.status == "cancelled"


@pytest.mark.parametrize(
    "value",
    [
        None,
        {},
        {"endpoint": "https://fcm.googleapis.com:invalid/x"},
        {"endpoint": "http://fcm.googleapis.com/x"},
        {"endpoint": "https://fcm.googleapis.com.attacker.test/x"},
        {"endpoint": "https://user:password@fcm.googleapis.com/x"},
        {"endpoint": "https://fcm.googleapis.com/x", "keys": {}},
        {
            "endpoint": "https://fcm.googleapis.com/x",
            "keys": {"p256dh": "wrong", "auth": "wrong"},
        },
    ],
)
def test_push_subscription_rejects_malformed_or_untrusted_transport(value):
    from app.errors import APIError

    with pytest.raises(APIError) as error:
        validate_subscription(value)
    assert error.value.status == 422


@pytest.mark.parametrize(
    ("response", "verdict"),
    [
        (b"stream: OK\0", True),
        (b"stream: Eicar-Test-Signature FOUND\0", False),
        (b"stream: unknown\0", None),
        (b"", None),
    ],
)
def test_clamd_stream_transmits_actual_bytes_and_fails_closed(
    app, tmp_path, response, verdict
):
    path = tmp_path / "upload.txt"
    path.write_bytes(b"actual uploaded content")
    connection = Mock()
    connection.recv.side_effect = [response, b""]
    context = Mock()
    context.__enter__ = Mock(return_value=connection)
    context.__exit__ = Mock(return_value=False)
    with (
        app.app_context(),
        patch(
            "app.services.file_processing.socket.create_connection",
            return_value=context,
        ),
    ):
        app.config["FILE_SCAN_COMMAND"] = ""
        if verdict is None:
            with pytest.raises(RuntimeError):
                scan_file(path)
        else:
            assert scan_file(path) is verdict
    sent = b"".join(call.args[0] for call in connection.sendall.call_args_list)
    assert sent == b"zINSTREAM\0" + struct.pack(
        "!I", len(path.read_bytes())
    ) + path.read_bytes() + struct.pack("!I", 0)


@pytest.mark.parametrize(("returncode", "verdict"), [(0, True), (1, False), (2, None)])
def test_external_scanner_exit_codes_do_not_mark_errors_clean(
    app, tmp_path, returncode, verdict
):
    path = tmp_path / "upload.txt"
    path.write_text("QA")
    with (
        app.app_context(),
        patch(
            "app.services.file_processing.subprocess.run",
            return_value=Mock(returncode=returncode),
        ) as scan,
    ):
        app.config["FILE_SCAN_COMMAND"] = "clamdscan --no-summary"
        if verdict is None:
            with pytest.raises(RuntimeError):
                scan_file(path)
        else:
            assert scan_file(path) is verdict
        assert scan.call_args.args[0][-1] == str(path)
