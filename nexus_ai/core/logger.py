# core/logger.py
"""
Ujednolicony system logowania oparty na Loguru + structlog.

Loguru zarządza outputem (konsola, pliki, rotacja, kompresja).
structlog zapewnia ustrukturyzowane, kontekstowe logowanie z bound loggerami.

Usage (Loguru — prosty, bezpośredni):
    from core.logger import logger, setup_logger, set_log_level

    setup_logger(app_name="NexusAI", log_level="INFO")
    logger.info("Hello from Loguru")

Usage (structlog — kontekstowy, z bound contextem):
    from structlog import get_logger

    log = get_logger(__name__)
    log.info("event_occurred", invoice_id="123", amount=4500.00)
"""

from __future__ import annotations

import logging
import os
import sys
from pathlib import Path

from loguru import logger

from nexus_ai.core.msgspec_utils import msgspec_dumps

# ── Auto-init guard ───────────────────────────────────────────────────────────
_INITIALIZED = False


@logger.patch
def _patch_record(record):
    """SUPERMOC: Dynamiczne wstrzykiwanie pól do każdego rekordu logu przez logger.patch().

    Zastępuje CorrelationIdFilter — wbudowany mechanizm Loguru jest
    szybszy i czystszy niż custom filter class.
    """
    record["extra"].setdefault("correlation_id", "system")
    record["extra"].setdefault("tenant_id", "default")
    record["extra"].setdefault("service", "nexus")
    record["extra"].setdefault("request_id", "system")
    record["extra"].setdefault("user_id", "anonymous")


def _json_format(record) -> str:
    """Format a log record as a JSON string for file sink."""
    extra = record["extra"]
    exception = record["exception"]
    return msgspec_dumps(
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


# ── structlog ────────────────────────────────────────────────────────────────
# structlog zapewnia ustrukturyzowane, kontekstowe logowanie z bound loggerami.
# Jego backend to loguru — wszystkie skonfigurowane sinki (konsola, pliki, rotacja)
# działają bez zmian, a structlog dodaje: merge_contextvars, TimeStamper, JSON.
#
# Użycie w module:
#   from structlog import get_logger
#   log = get_logger(__name__)
#   log.info("user_login", user_id=u.id, role=u.role)
#   log.warning("rate_limit_exceeded", ip=request.client.host)
#   logger.exception("db_error", exc_info=True)


class _LoguruFactory:
    """LoggerFactory that routes structlog output through the existing loguru sinks.

    This means all structlog log entries pass through the same:
      - Console handler (colored, correlation_id)
      - JSON file (rotated, compressed)
      - Plain text file (rotated, compressed)
      - ERROR-only file
    without any duplication.
    """

    def __call__(self) -> logger:
        return logger  # type: ignore[return-value]


def _setup_structlog() -> None:
    """Configure structlog to use loguru as its backend logging system.

    SUPERMOCE structlog:
    - merge_contextvars: automatyczne wzbogacanie o correlation_id/tenant_id z contextvars
    - CallsiteParameterAdder: filename, lineno, func_name w każdym logu
    - format_exc_info: automatyczne formatowanie wyjątków
    - ExtraAdder: kompatybilność z stdlib logging
    - ConsoleRenderer z sort_keys i level_styles: czytelne kolory w konsoli
    - cache_logger_on_first_use: zero overhead dla powtarzających się loggerów

    Must be called after loguru sinks are set up (i.e. inside setup_logger).
    """
    import structlog as _structlog

    # SUPERMOC 1: Level styles dla ConsoleRenderer
    _level_styles = {
        "info": _structlog.dev.StructLogStyle(color="green", bold=False),
        "warning": _structlog.dev.StructLogStyle(color="yellow", bold=True),
        "error": _structlog.dev.StructLogStyle(color="red", bold=True),
        "critical": _structlog.dev.StructLogStyle(color="red", bold=True, bg="white"),
        "debug": _structlog.dev.StructLogStyle(color="cyan", bold=False),
    }

    _structlog.configure(
        processors=[
            # SUPERMOC 2: Łączy contextvars (correlation_id, tenant_id) z każdym logiem
            _structlog.contextvars.merge_contextvars,
            # SUPERMOC 3: Filtrowanie po poziomie (szybkie odrzucanie)
            _structlog.stdlib.filter_by_level,
            # SUPERMOC 4: Dodaje poziom logowania (info, warning, ...)
            _structlog.stdlib.add_log_level,
            # SUPERMOC 5: Dodaje numeryczny poziom logowania
            _structlog.stdlib.add_log_level_number,
            # SUPERMOC 6: Formatuje argumenty pozycyjne
            _structlog.stdlib.PositionalArgumentsFormatter(),
            # SUPERMOC 7: Dodaje filename:lineno:func_name do każdego logu
            _structlog.processors.CallsiteParameterAdder(
                [
                    _structlog.processors.CallsiteParameter.FILENAME,
                    _structlog.processors.CallsiteParameter.LINENO,
                    _structlog.processors.CallsiteParameter.FUNC_NAME,
                ]
            ),
            # SUPERMOC 8: Dodaje timestamp ISO
            _structlog.processors.TimeStamper(fmt="iso"),
            # SUPERMOC 9: Formatuje wyjątki (traceback)
            _structlog.processors.format_exc_info,
            # SUPERMOC 10: Dodaje extra dane z stdlib logging
            _structlog.stdlib.ExtraAdder(),
            # SUPERMOC 11: Renderowanie konsolowe z sortowaniem i kolorami
            _structlog.dev.ConsoleRenderer(
                sort_keys=True,
                pad_event=30,
                level_styles=_level_styles,
            ),
        ],
        wrapper_class=_structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=_LoguruFactory(),
        cache_logger_on_first_use=True,
    )
    logger.debug(
        "[STRUCTLOG] Configured with CallsiteParameterAdder, format_exc_info, "
        "ExtraAdder, add_log_level_number, ConsoleRenderer(sort_keys=True)"
    )


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

    # ── SUPERMOC: Custom levels dla semantycznego filtrowania ─────────────────
    logger.level("TRACE", no=5, color="<magenta>")
    logger.level("OCR", no=8, color="<blue>")
    logger.level("AUDIT", no=38, color="<yellow>")
    logger.level("TAX", no=12, color="<green>")

    # ── logger.patch() — dynamiczne wstrzykiwanie pól zamiast CorrelationIdFilter ─
    # _patch_record jest zarejestrowane przez @logger.patch na górze pliku

    # ── Konsola (kolorowa, z czytelnym formatem) ──────────────────────────────
    logger.add(
        sys.stderr,
        enqueue=True,
        colorize=True,
        level=log_level,
        diagnose=False,  # BEZPIECZEŃSTWO: brak wycieku zmiennych lokalnych (RODO)
        backtrace=True,  # DIAGNOSTYKA: pełny chain wywołań przy wyjątkach
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
    json_log_path = log_dir / f"{app_name.lower()}_json.log"
    logger.add(
        str(json_log_path),
        level=log_level,
        rotation="100 MB",
        retention="30 days",
        compression="gz",
        serialize=True,
        diagnose=False,
        backtrace=True,
    )

    # Standardowy plik logów (tekstowy, do szybkiego przeglądania)
    logger.add(
        str(log_dir / f"{app_name.lower()}.log"),
        rotation="100 MB",
        retention="14 days",
        compression="gz",
        enqueue=True,
        level=log_level,
        diagnose=False,
        backtrace=False,  # Tekstowy plik — bez backtrace dla czytelności
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {extra[correlation_id]:.12} | {message}",
    )

    # Osobny handler dla ERRORów (można przekierować do webhook)
    logger.add(
        log_dir / f"{app_name.lower()}_error.log",
        rotation="50 MB",
        retention="30 days",
        compression="gz",
        enqueue=True,
        level="ERROR",
        diagnose=False,
        backtrace=True,  # ERROR log — pełny backtrace dla debugowania
        format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {extra[correlation_id]} | {extra[request_id]} | {message}",
    )

    # ── SUPERMOC: DuckDB sink dla WARNING+ logów ─────────────────────────────
    _setup_duckdb_sink(log_dir, app_name)

    # ── Konfiguracja structlog (output przez loguru) ─────────────────────────
    _setup_structlog()

    # ── Integracje zewnętrzne ─────────────────────────────────────────────────
    # Zgodnie z aa3fvcx.txt: Sentry jest opcjonalny (sentry-sdk w [dev]).
    # Monitoring błędów odbywa się przez Loguru + structlog + OpenTelemetry.

    # Przekieruj warnings z bibliotek zewnętrznych do Loguru
    logging.captureWarnings(True)
    # Przekieruj standardowe logging do Loguru
    _redirect_standard_logging()

    # ── SUPERMOC: stamina retry + circuit breaker logging ────────────────────
    _setup_stamina_logging()

    _INITIALIZED = True


# ── SUPERMOC: DuckDB sink dla analityki logów ──────────────────────────────


def _setup_duckdb_sink(log_dir: Path, app_name: str) -> None:
    """SUPERMOC: Custom Loguru sink → DuckDB dla WARNING+ logów.

    Logi WARNING i wyższe są automatycznie zapisywane do DuckDB
    dla łatwej analizy SQL. Tabela telemetry_logs jest tworzona
    automatycznie przy pierwszym użyciu.
    """
    try:
        import duckdb
        from nexus_ai.core.msgspec_utils import msgspec_dumps as _msgspec_dumps_logger

        db_path = log_dir / f"{app_name.lower()}_logs.duckdb"
        conn = duckdb.connect(str(db_path))

        # Utwórz tabelę jeśli nie istnieje
        conn.execute("""
            CREATE TABLE IF NOT EXISTS telemetry_logs (
                timestamp TIMESTAMP,
                level VARCHAR,
                logger_name VARCHAR,
                message VARCHAR,
                extra JSON,
                correlation_id VARCHAR,
                tenant_id VARCHAR
            )
        """)

        # Custom sink jako funkcja
        def _duckdb_sink(message):
            record = message.record
            extra = record["extra"]
            try:
                conn.execute(
                    """
                    INSERT INTO telemetry_logs
                    (timestamp, level, logger_name, message, extra, correlation_id, tenant_id)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        record["time"].isoformat(),
                        record["level"].name,
                        record["name"],
                        record["message"][:2000],  # Ograniczenie długości
                        _msgspec_dumps_logger(extra, default=str),
                        extra.get("correlation_id", "system"),
                        extra.get("tenant_id", "default"),
                    ),
                )
            except Exception:
                pass  # Ignoruj błędy DuckDB — nie blokuj logowania

        logger.add(
            _duckdb_sink,
            level="WARNING",
            enqueue=True,
            diagnose=False,
        )
        logger.debug("[LOGGER] DuckDB sink initialized: %s", db_path)
    except ImportError:
        logger.debug("[LOGGER] DuckDB not available — skipping DuckDB sink")
    except Exception as exc:
        logger.debug("[LOGGER] DuckDB sink init failed: %s", exc)


def _setup_stamina_logging() -> None:
    """SUPERMOC: Konfiguruje logging dla stamina retry + circuit breaker.

    stamina używa standardowego modułu logging. Przekierowujemy jego logi
    przez Loguru/structlog, aby każda retry i każde otwarcie Circuit Breakera
    było widoczne w ustrukturyzowanych logach z kontekstem.

    Poziomy logowania stamina:
      - DEBUG: każda próba retry
      - WARNING: retry z błędem
      - ERROR: circuit breaker opened/closed
    """
    stamina_logger = logging.getLogger("stamina")
    stamina_logger.setLevel(logging.DEBUG)

    class _StaminaInterceptHandler(logging.Handler):
        def emit(self, record: logging.LogRecord) -> None:
            try:
                level = logger.level(record.levelname).name
            except ValueError:
                level = record.levelno
            logger.opt(depth=6, exception=record.exc_info).log(
                level,
                f"[STAMINA] {record.getMessage()}",
            )

    stamina_logger.handlers.clear()
    stamina_logger.addHandler(_StaminaInterceptHandler())
    stamina_logger.propagate = False
    logger.debug("[STAMINA] Retry logger configured — stamina events visible in structlog")


def _redirect_standard_logging() -> None:
    """Przekierowuje standardowy logging do Loguru, aby logi z bibliotek zewnętrznych
    (np. httpx) trafiały do ujednoliconego systemu."""

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

            logger.opt(depth=depth, exception=record.exc_info).log(level, record.getMessage())

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(_InterceptHandler())
    root_logger.setLevel(logging.WARNING)

    for lib in ("sqlalchemy", "httpx", "urllib3", "nats"):
        logging.getLogger(lib).setLevel(logging.WARNING)


def get_logger(name: str | None = None):
    """Return the pre-configured Loguru logger.

    The optional *name* argument is accepted for compatibility with
    the standard ``logging.getLogger(name)`` idiom but is not used
    — Loguru captures the caller's module automatically.
    """
    return logger


def auto_logger(cls=None, *, name: str | None = None):
    """Class decorator that auto-injects a ``logger`` class attribute.

    Eliminates the 3-line boilerplate ``from structlog import get_logger; logger = get_logger(...)``
    from 80+ files. Usage:

        @auto_logger
        class MyService:
            # ``self.logger`` and ``MyService.logger`` are auto-available

        @auto_logger(name="nexus.custom")
        class CustomService: ...

    The logger name is inferred from the module path by default.
    """
    def _decorate(klass):
        logger_name = name or f"{klass.__module__}.{klass.__qualname__}"
        from structlog import get_logger as _get_logger
        klass.logger = _get_logger(logger_name)
        return klass
    return _decorate if cls is None else _decorate(cls)


# ── Deferred initialization ───────────────────────────────────────────────────
# NOTE: Do NOT call setup_logger() at module import time.
# Main entry points (main.py, api/server.py) must call setup_logger() explicitly
# after NEXUS_LOG_LEVEL env var is available.
