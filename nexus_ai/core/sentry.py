# core/sentry.py
"""
Sentry SDK integration for production error tracking.

Zgodnie z aa3fvcx.txt (Punkt 12): Sentry SDK dostarcza maksymalnie
bogaty kontekst dla błędów produkcyjnych — stack trace, wartości
zmiennych lokalnych, breadcrumbs.

Użycie:
    from nexus_ai.core.sentry import init_sentry, capture_exception

    # Przy starcie aplikacji:
    init_sentry()

    # Ręczne przechwycenie błędu:
    try:
        ...
    except Exception as exc:
        capture_exception(exc)
"""

from __future__ import annotations

import os
from structlog import get_logger
from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.core.sentry")

_sentry_initialized = False


def init_sentry(config: AppConfig | None = None) -> bool:
    """Initialize Sentry SDK with configuration from AppConfig.

    Sentry jest opcjonalny — inicjalizowany tylko gdy skonfigurowano
    NEXUS_SENTRY_DSN lub SENTRY_DSN.

    Returns:
        True if Sentry was initialized, False otherwise.
    """
    global _sentry_initialized

    if _sentry_initialized:
        return True

    dsn = (
        os.getenv("NEXUS_SENTRY_DSN", "")
        or os.getenv("SENTRY_DSN", "")
    )

    if not dsn:
        logger.info("[Sentry] Not configured — skipping initialization")
        return False

    environment = "dev"
    if config is not None:
        environment = config.environment

    try:
        import sentry_sdk
        from sentry_sdk.integrations.loguru import LoguruIntegration
        from sentry_sdk.integrations.structlog import StructlogIntegration

        sentry_sdk.init(
            dsn=dsn,
            environment=environment,
            traces_sample_rate=0.1 if environment == "prod" else 1.0,
            profiles_sample_rate=0.1 if environment == "prod" else 0.0,
            send_default_pii=False,
            integrations=[
                LoguruIntegration(),
                StructlogIntegration(),
            ],
        )
        _sentry_initialized = True
        logger.info("[Sentry] Initialized for environment: %s", environment)
        return True

    except ImportError:
        logger.warning("[Sentry] sentry-sdk not installed. Install: pip install sentry-sdk")
        return False
    except Exception as exc:
        logger.warning("[Sentry] Initialization failed: %s", exc)
        return False


def capture_exception(exc: Exception) -> None:
    """Capture an exception with Sentry (if initialized)."""
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk
        sentry_sdk.capture_exception(exc)
    except Exception as e:
        logger.warning("[Sentry] capture_exception failed: %s", e)


def set_user_context(user_id: str | None = None, **kwargs: str) -> None:
    """Set user context for Sentry events."""
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk
        sentry_sdk.set_user({"id": user_id, **kwargs})
    except Exception as e:
        logger.warning("[Sentry] set_user_context failed: %s", e)


def add_breadcrumb(message: str, category: str = "default", level: str = "info") -> None:
    """Add a breadcrumb to Sentry."""
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk
        sentry_sdk.add_breadcrumb(
            message=message,
            category=category,
            level=level,
        )
    except Exception as e:
        logger.warning("[Sentry] add_breadcrumb failed: %s", e)
