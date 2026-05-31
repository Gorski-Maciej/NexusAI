# core/logger.py
"""
Ujednolicony system logowania oparty na Loguru.
Wszystkie moduły powinny importować logger stąd zamiast używać logging.getLogger.

Usage:
    from core.logger import logger, setup_logger, set_log_level

    # W main.py, po wczytaniu konfiguracji:
    setup_logger(app_name="NexusAI", log_level=os.getenv("NEXUS_LOG_LEVEL", "INFO"))

    # Zmiana poziomu w locie:
    set_log_level("DEBUG")
"""
from __future__ import annotations

import os
import sys
import json
import logging
from pathlib import Path
from loguru import logger

# ── Auto-init guard ───────────────────────────────────────────────────────────
_INITIALIZED = False


class CorrelationIdFilter:
    def __call__(self, record):
        # Dodaj correlation_id do każdego rekordu logu
        record["extra"].setdefault("correlation_id", "system")
        record["extra"].setdefault("tenant_id", "default")
        record["extra"].setdefault("service", "nexus")
        record["extra"].setdefault("request_id", "system")
        record["extra"].setdefault("user_id", "anonymous")
        return True


def _json_format(record) -> str:
    """Format a log record as a JSON string for file sink."""
    extra = record["extra"]
    exception = record["exception"]
    return json.dumps(
        {
            "timestamp": record["time"].isoformat(),
            "level": record["level"].name,
            "logger": record["name"],
            "module": record["name"],
            "function": record["function"],
            "line": record["line"],
            "message": record["message"],
            "correlation_id": extra.get("correlation_id", "system"),
            "request_id": extra.get("request_id", "system"),
            "user_id": extra.get("user_id", "anonymous"),
            "tenant_id": extra.get("tenant_id", "default"),
            "service": extra.get("service", "nexus"),
            "exception": exception,
        },
        ensure_ascii=False,
        default=str,
    )


def set_log_level(level: str) -> None:
    """Dynamically change the log level for all handlers.

    Accepts standard level names: DEBUG, INFO, WARNING, ERROR, CRITICAL.
    Also respects NumericLevel values.
    """
    logger.configure(handlers=[{"level": level.upper()}])


def setup_logger(app_name: str = "NexusAI", log_level: str | None = None) -> None:
    """Konfiguruje globalny, asynchronicznie-bezpieczny system logowania z rotacją.

    Args:
        app_name: Nazwa aplikacji (używana w nazwach plików logów).
        log_level: Poziom logowania (DEBUG/INFO/WARNING/ERROR).
                   Domyślnie z NEXUS_LOG_LEVEL env, fallback INFO.
    """
    global _INITIALIZED
    logger.remove()

    # ── Poziom logowania ──────────────────────────────────────────────────────
    if log_level is None:
        log_level = os.getenv("NEXUS_LOG_LEVEL", "INFO").upper()
    log_level = log_level.upper()
    if log_level not in {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}:
        log_level = "INFO"

    # ── Filtr dodający correlation_id / request_id / user_id ─────────────────
    correlation_filter = CorrelationIdFilter()

    # ── Konsola (kolorowa, z czytelnym formatem) ──────────────────────────────
    logger.add(
        sys.stderr,
        enqueue=True,
        colorize=True,
        filter=correlation_filter,
        level=log_level,
        format=(
            "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
            "<level>{level: <8}</level> | "
            "<cyan>{extra[correlation_id]:.12}</cyan> | "
            "<level>{message}</level>"
        ),
    )

    # ── Pliki logów ───────────────────────────────────────────────────────────
    log_dir = Path("app_data/logs")
    log_dir.mkdir(parents=True, exist_ok=True)

    # Plik JSON (strukturyzowany, łatwy do parsowania przez narzędzia SIEM)
    # Loguru's built-in serialize=True outputs each record as a JSON line
    json_log_path = log_dir / f"{app_name.lower()}_json.log"
    logger.add(
        str(json_log_path),
        filter=correlation_filter,
        level=log_level,
        rotation="100 MB",
        retention="30 days",
        compression="gz",
        serialize=True,
    )

    # Standardowy plik logów (tekstowy, do szybkiego przeglądania)
    logger.add(
        str(log_dir / f"{app_name.lower()}.log"),
        rotation="100 MB",
        retention="14 days",
        compression="gz",
        enqueue=True,
        filter=correlation_filter,
        level=log_level,
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {extra[correlation_id]:.12} | {message}",
    )

    # Osobny handler dla ERRORów (można przekierować do Sentry/webhook)
    logger.add(
        log_dir / f"{app_name.lower()}_error.log",
        rotation="50 MB",
        retention="30 days",
        compression="gz",
        enqueue=True,
        filter=correlation_filter,
        level="ERROR",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {extra[correlation_id]} | {extra[request_id]} | {message}",
    )

    # ── Integracje zewnętrzne ─────────────────────────────────────────────────
    # Integracja z Sentry (jeśli DSN jest skonfigurowany)
    _try_setup_sentry(app_name)

    # Przekieruj warnings z bibliotek zewnętrznych do Loguru
    logging.captureWarnings(True)
    # Przekieruj standardowe logging do Loguru
    _redirect_standard_logging()

    _INITIALIZED = True


def _try_setup_sentry(app_name: str) -> None:
    """Próbuje skonfigurować Sentry, jeśli DSN jest dostępny w środowisku."""
    sentry_dsn = os.environ.get("NEXUS_SENTRY_DSN")
    if not sentry_dsn:
        return

    try:
        import sentry_sdk
        from sentry_sdk.integrations.loguru import LoguruIntegration

        sentry_sdk.init(
            dsn=sentry_dsn,
            integrations=[LoguruIntegration(level=logging.ERROR)],
            traces_sample_rate=0.1,
            environment=os.environ.get("NEXUS_ENVIRONMENT", "development"),
        )
        logger.info("Sentry SDK initialized for error tracking")
    except ImportError:
        logger.debug("sentry_sdk not available, skipping Sentry integration")
    except Exception as exc:
        logger.debug("Failed to initialize Sentry: %s", exc)


def _redirect_standard_logging() -> None:
    """Przekierowuje standardowy logging do Loguru, aby logi z bibliotek zewnętrznych
    (np. SQLAlchemy, httpx) trafiały do ujednoliconego systemu."""
    class _InterceptHandler(logging.Handler):
        def emit(self, record: logging.LogRecord) -> None:
            try:
                level = logger.level(record.levelname).name
            except ValueError:
                level = record.levelno

            frame = logging.currentframe()
            depth = 0
            while frame and depth < 10:
                frame = frame.f_back
                depth += 1

            logger.opt(depth=depth, exception=record.exc_info).log(
                level, record.getMessage()
            )

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(_InterceptHandler())
    root_logger.setLevel(logging.WARNING)

    for lib in ("sqlalchemy", "httpx", "urllib3", "aiosqlite", "nats"):
        logging.getLogger(lib).setLevel(logging.WARNING)


def get_logger(name: str | None = None):
    """Return the pre-configured Loguru logger.

    The optional *name* argument is accepted for compatibility with
    the standard ``logging.getLogger(name)`` idiom but is not used
    — Loguru captures the caller's module automatically.
    """
    return logger


# ── Deferred initialization ───────────────────────────────────────────────────
# NOTE: Do NOT call setup_logger() at module import time.
# Main entry points (main.py, api/server.py) must call setup_logger() explicitly
# after NEXUS_LOG_LEVEL env var is available.
