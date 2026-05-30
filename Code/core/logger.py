# core/logger.py
"""
Ujednolicony system logowania oparty na Loguru.
Wszystkie moduły powinny importować logger stąd zamiast używać logging.getLogger.
"""
import sys
import json
import logging
from pathlib import Path
from loguru import logger


class CorrelationIdFilter:
    def __call__(self, record):
        # Dodaj correlation_id do każdego rekordu logu
        # Wartość domyślna, nadpisywana przez middleware lub zadania
        record["extra"].setdefault("correlation_id", "system")
        record["extra"].setdefault("tenant_id", "default")
        record["extra"].setdefault("service", "nexus")
        return True


def _serialize_record(record):
    """Serializuje rekord logu do formatu JSON dla łatwiejszego parsowania."""
    return json.dumps(
        {
            "timestamp": record["time"].isoformat(),
            "level": record["level"].name,
            "module": record["name"],
            "function": record["function"],
            "line": record["line"],
            "message": record["message"],
            "correlation_id": record["extra"].get("correlation_id", "system"),
            "tenant_id": record["extra"].get("tenant_id", "default"),
            "service": record["extra"].get("service", "nexus"),
            "exception": record["exception"].format_exception() if record.get("exception") else None,
        }
    )


def setup_logger(app_name: str = "NexusAI"):
    """Konfiguruje globalny, asynchronicznie-bezpieczny system logowania z rotacją za pomocą Loguru."""
    logger.remove()

    # Filtr dodający correlation_id
    correlation_filter = CorrelationIdFilter()

    # Konsola (kolorowa, z czytelnym formatem)
    logger.add(
        sys.stderr,
        enqueue=True,
        colorize=True,
        filter=correlation_filter,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{extra[correlation_id]:.12}</cyan> | <level>{message}</level>",
    )

    log_dir = Path("app_data/logs")
    log_dir.mkdir(parents=True, exist_ok=True)

    # Plik JSON (strukturyzowany, łatwy do parsowania przez narzędzia SIEM)
    logger.add(
        log_dir / f"{app_name.lower()}_json.log",
        rotation="100 MB",
        retention="14 days",
        compression="gz",
        enqueue=True,
        filter=correlation_filter,
        format=_serialize_record,
        level="INFO",
        serialize=True,
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
        format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {extra[correlation_id]} | {message}",
    )

    # Integracja z Sentry (jeśli DSN jest skonfigurowany)
    _try_setup_sentry(app_name)

    # Przekieruj warnings z bibliotek zewnętrznych do Loguru
    logging.captureWarnings(True)
    # Przekieruj standardowe logging do Loguru
    _redirect_standard_logging()

    return logger


def _try_setup_sentry(app_name: str) -> None:
    """Próbuje skonfigurować Sentry, jeśli DSN jest dostępny w środowisku."""
    sentry_dsn = None
    try:
        sentry_dsn = __import__("os").environ.get("NEXUS_SENTRY_DSN")
    except Exception:
        pass

    if not sentry_dsn:
        return

    try:
        import sentry_sdk
        from sentry_sdk.integrations.loguru import LoguruIntegration

        sentry_sdk.init(
            dsn=sentry_dsn,
            integrations=[LoguruIntegration(level=logging.ERROR)],
            traces_sample_rate=0.1,
            environment=__import__("os").environ.get("NEXUS_ENVIRONMENT", "development"),
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
            # Pobierz odpowiedni poziom Loguru
            try:
                level = logger.level(record.levelname).name
            except ValueError:
                level = record.levelno

            # Znajdź caller
            frame = logging.currentframe()
            depth = 0
            while frame and depth < 10:
                frame = frame.f_back
                depth += 1

            logger.opt(depth=depth, exception=record.exc_info).log(
                level, record.getMessage()
            )

    # Zastąp domyślny handler dla root loggera
    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(_InterceptHandler())
    root_logger.setLevel(logging.WARNING)  # Tylko ostrzeżenia i błędy z bibliotek zewnętrznych

    # Ustaw poziomy dla wybranych bibliotek
    for lib in ("sqlalchemy", "httpx", "urllib3", "aiosqlite", "nats"):
        logging.getLogger(lib).setLevel(logging.WARNING)


def get_logger():
    return logger


# Automatyczna konfiguracja przy imporcie
setup_logger()
