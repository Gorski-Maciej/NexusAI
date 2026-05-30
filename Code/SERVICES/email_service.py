"""
Email service for authentication notifications.

Current implementation logs all emails to the application logger.
When SMTP credentials are configured, it will send real emails.

Used for:
- Email confirmation after registration
- Password reset links
- Account notifications
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Protocol

logger = logging.getLogger("nexus.services.email")


class EmailProvider(Protocol):
    """Protocol for email sending providers."""
    async def send_email(
        self, *, to: str, subject: str, body_text: str, body_html: str | None = None
    ) -> bool: ...


@dataclass
class EmailConfig:
    """Email configuration from AppConfig."""
    enabled: bool = False
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    from_address: str = "noreply@nexusai.local"
    use_tls: bool = True


class LoggingEmailProvider:
    """Placeholder email provider that logs to the application logger.

    When SMTP is configured, replace with SMTPEmailProvider.
    """

    async def send_email(
        self, *, to: str, subject: str, body_text: str, body_html: str | None = None
    ) -> bool:
        logger.info(
            "[EMAIL PLACEHOLDER] To: %s | Subject: %s | Body: %s",
            to, subject, body_text[:200] if body_text else "",
        )
        # In production, this would send the email via SMTP/SendGrid/SES
        return True


_email_provider: EmailProvider = LoggingEmailProvider()


async def send_verification_email(to_email: str, confirm_token: str, username: str) -> bool:
    """Send email verification link after registration."""
    subject = "Potwierdź swoje konto w NexusAI"
    body = (
        f"Witaj {username}!\n\n"
        f"Dziękujemy za rejestrację w systemie NexusAI.\n\n"
        f"Aby aktywować swoje konto, kliknij w poniższy link:\n"
        f"{_build_confirm_url(confirm_token)}\n\n"
        f"Link jest ważny przez 24 godziny.\n\n"
        f"Pozdrawiamy,\nZespół NexusAI"
    )
    return await _email_provider.send_email(
        to=to_email, subject=subject, body_text=body
    )


async def send_password_reset_email(to_email: str, reset_token: str, username: str) -> bool:
    """Send password reset link."""
    subject = "Resetowanie hasła w NexusAI"
    body = (
        f"Witaj {username}!\n\n"
        f"Otrzymaliśmy prośbę o zresetowanie hasła do Twojego konta NexusAI.\n\n"
        f"Aby zresetować hasło, kliknij w poniższy link:\n"
        f"{_build_reset_url(reset_token)}\n\n"
        f"Link jest ważny przez 1 godzinę.\n\n"
        f"Jeśli nie prosiłeś o reset hasła, zignoruj tę wiadomość.\n\n"
        f"Pozdrawiamy,\nZespół NexusAI"
    )
    return await _email_provider.send_email(
        to=to_email, subject=subject, body_text=body
    )


def _build_confirm_url(token: str) -> str:
    """Build email confirmation URL (placeholder - uses localhost)."""
    import os
    base_url = os.getenv("NEXUS_BASE_URL", "http://localhost:8000")
    return f"{base_url}/api/auth/confirm/{token}"


def _build_reset_url(token: str) -> str:
    """Build password reset URL (placeholder - uses localhost)."""
    import os
    base_url = os.getenv("NEXUS_BASE_URL", "http://localhost:8000")
    return f"{base_url}/api/auth/reset-password/confirm?token={token}"
