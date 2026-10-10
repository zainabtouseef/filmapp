from __future__ import annotations

from unittest.mock import MagicMock, patch

from app.services.auth_email import send_password_reset_email


def test_missing_delivery_configuration_is_honest_and_non_enumerating(app, client):
    app.config.update(TESTING=False, SMTP_HOST="", SMTP_FROM_EMAIL="")
    response = client.post(
        "/api/v1/auth/password/forgot", json={"email": "missing@example.com"}
    )
    assert response.status_code == 503
    assert response.json["error"]["code"] == "auth.email_delivery_unavailable"


def test_reset_email_uses_tls_and_the_real_reset_route(app):
    app.config.update(
        TESTING=False,
        SMTP_HOST="smtp.example.com",
        SMTP_PORT=587,
        SMTP_FROM_EMAIL="support@example.com",
        SMTP_USERNAME="mailer",
        SMTP_PASSWORD="local-test-only",
        PUBLIC_WEB_ORIGIN="https://cine.example.com",
    )
    server = MagicMock()
    server.__enter__.return_value = server
    with (
        app.app_context(),
        patch("app.services.auth_email.smtplib.SMTP", return_value=server),
    ):
        send_password_reset_email("recipient@example.com", "one-time-test-token")
    server.starttls.assert_called_once()
    server.login.assert_called_once_with("mailer", "local-test-only")
    message = server.send_message.call_args.args[0]
    assert (
        "https://cine.example.com/#/reset-password?token=one-time-test-token"
        in message.get_content()
    )
    assert message["To"] == "recipient@example.com"
