from __future__ import annotations

import smtplib
import ssl
from email.message import EmailMessage
from urllib.parse import urlencode

from flask import current_app


def reset_email_available() -> bool:
    return bool(current_app.config.get("TESTING")) or bool(
        current_app.config.get("SMTP_HOST")
        and current_app.config.get("SMTP_FROM_EMAIL")
    )


def send_password_reset_email(recipient: str, token: str) -> None:
    if current_app.config.get("TESTING"):
        return
    config = current_app.config
    origin = str(config["PUBLIC_WEB_ORIGIN"]).rstrip("/")
    if config["APP_ENV"] == "production" and not origin.startswith("https://"):
        raise RuntimeError("Password recovery requires an HTTPS public origin")
    link = f"{origin}/#/reset-password?{urlencode({'token': token})}"
    message = EmailMessage()
    message["From"] = config["SMTP_FROM_EMAIL"]
    message["To"] = recipient
    message["Subject"] = "Reset your CineConnect password"
    message.set_content(
        "Use this one-time link to reset your CineConnect password:\n\n"
        f"{link}\n\nThis link expires in one hour. "
        "If you did not request it, ignore this email."
    )
    port = int(config["SMTP_PORT"])
    transport = (
        smtplib.SMTP_SSL(
            str(config["SMTP_HOST"]),
            port,
            timeout=8,
            context=ssl.create_default_context(),
        )
        if port == 465
        else smtplib.SMTP(str(config["SMTP_HOST"]), port, timeout=8)
    )
    with transport as server:
        if port != 465:
            server.starttls(context=ssl.create_default_context())
        if config["SMTP_USERNAME"]:
            server.login(config["SMTP_USERNAME"], config["SMTP_PASSWORD"])
        server.send_message(message)
