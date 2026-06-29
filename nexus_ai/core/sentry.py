# core/sentry.py
"""
Sentry SDK integration for production error tracking.

Zgodnie z aa3fvcx.txt: Sentry SDK jest opcjonalny (sentry-sdk w zależnościach [dev]).
Dostarcza maksymalnie bogaty kontekst dla błędów produkcyjnych.

- ``before_send`` — filtrowanie i anonymizacja eventów przed wysyłką
- ``before_breadcrumb`` — filtrowanie breadcrumbów (pomija DEBUG)
- ``set_tag()`` — tagowanie eventów (service, component, version)
- ``set_context()`` — dowolny słownik kontekstu (invoice_id, aggregate)
- ``capture_message()`` — ręczne logowanie błędów biznesowych
- ``sentry_scope()`` — context manager dla Scope (bezpieczny współbieżnie)
- ``capture_exception()`` z kontekstowymi tagami
- ``HttpxIntegration`` — śledzenie requestów HTTP
- ``AsyncioIntegration`` — śledzenie zadań asynchronicznych
- ``flush()`` — wymuszenie wysyłki przy shutdownie
- ``in_app_include`` — czystsze stack trace (tylko nexus_ai)

Użycie:
    from nexus_ai.core.sentry import init_sentry, capture_exception

    # Przy starcie aplikacji:
    init_sentry()

    # Ręczne przechwycenie błędu:
    try:
        ...
    except Exception as exc:
        capture_exception(exc, service="api", component="invoice")

    # Kontekst dla scope:
    with sentry_scope(invoice_id="123", vendor_nip="1234567890"):
        # operacje...
        pass
"""

from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Any

from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.core.sentry")

_sentry_initialized = False




def _filter_sentry_event(event: dict[str, Any], hint: dict[str, Any]) -> dict[str, Any] | None:

    - Ignoruje health checki (niepotrzebny szum)
    - Ignoruje ConnectionReset / BrokenPipe (normalne w async)
    - Anonymizuje request body (RODO)
    - Anonymizuje cookies i headers
    - Dodaje tag z wersją jeśli brak

    Zwraca:
        dict: Event do wysłania (może być zmodyfikowany)
        None: Event do odrzucenia
    """
    # ── Ignoruj znane, bezpieczne wyjątki ──────────────────────────────
    ignored_exceptions = {
        "ConnectionResetError",
        "BrokenPipeError",
        "HealthCheckError",
        "KeyboardInterrupt",
        "TaskError",
    }

    for exc in event.get("exception", {}).get("values", []):
        exc_type = exc.get("type", "")
        if exc_type in ignored_exceptions:
            return None

    # ── Anonymizacja request data (RODO) ──────────────────────────────
    if "request" in event:
        request = event["request"]
        # Anonymizuj body JSON
        if "data" in request:
            try:
                import json

                data = json.loads(request["data"])
                # Zachowaj tylko typ danych, nie treść
                if isinstance(data, dict):
                    request["data"] = json.dumps({k: type(v).__name__ for k, v in data.items()})
                else:
                    request["data"] = f"[{type(data).__name__}]"
            except (json.JSONDecodeError, TypeError):
                request["data"] = "[FILTERED]"

        # Anonymizuj cookies
        if "cookies" in request:
            request["cookies"] = "[FILTERED]"

        # Anonymizuj headers
        if "headers" in request:
            filtered_headers = {}
            sensitive_headers = {
                "authorization",
                "cookie",
                "set-cookie",
                "x-api-key",
                "x-auth-token",
            }
            for key, val in request["headers"].items():
                if key.lower() in sensitive_headers:
                    filtered_headers[key] = "[FILTERED]"
                else:
                    filtered_headers[key] = val
            request["headers"] = filtered_headers

    # ── Dodaj tag z wersją jeśli brak ─────────────────────────────────
    if not event.get("tags", {}).get("release"):
        event.setdefault("tags", {})
        event["tags"]["release"] = os.getenv("NEXUS_VERSION", "dev")

    return event




def _filter_breadcrumb(breadcrumb: dict[str, Any], hint: dict[str, Any]) -> dict[str, Any] | None:

    - Pomija DEBUG breadcrumby (redukcja szumu o ~70%)
    - Zachowuje tylko kategorie: log, http, task, user, invoice
    - Zachowuje ERROR i WARNING breadcrumby zawsze

    Zwraca:
        dict: Breadcrumb do wysłania
        None: Breadcrumb do odrzucenia
    """
    level = breadcrumb.get("level", "info")
    category = breadcrumb.get("category", "default")

    # Zawsze zachowaj ERROR i WARNING
    if level in ("error", "warning", "critical"):
        return breadcrumb

    # Pomijaj DEBUG
    if level == "debug":
        return None

    # Pomijaj nieznane kategorie
    allowed_categories = {"log", "http", "task", "user", "invoice", "auth", "query"}
    if category not in allowed_categories:
        return None

    # Ogranicz długość wiadomości
    if "message" in breadcrumb and len(str(breadcrumb["message"])) > 500:
        breadcrumb["message"] = str(breadcrumb["message"])[:500] + "..."

    return breadcrumb




def init_sentry(config: AppConfig | None = None) -> bool:
    """Initialize Sentry SDK with full configuration.

    - ``before_send`` — filtrowanie + anonymizacja
    - ``before_breadcrumb`` — pomija DEBUG i zbędne kategorie
    - ``HttpxIntegration`` — śledzenie requestów HTTP
    - ``AsyncioIntegration`` — śledzenie zadań asynchronicznych
    - ``in_app_include=['nexus_ai']`` — czystsze stack trace
    - ``ignore_errors`` — ciche ignorowanie znanych wyjątków
    - ``release`` — wersja z NEXUS_VERSION env
    - ``max_breadcrumbs=100`` — więcej kontekstu przed błędem
    - ``flush()`` — wymuszenie wysyłki przy shutdownie (atexit)

    Sentry jest opcjonalny — inicjalizowany tylko gdy skonfigurowano
    NEXUS_SENTRY_DSN lub SENTRY_DSN.

    Returns:
        True if Sentry was initialized, False otherwise.
    """
    global _sentry_initialized

    if _sentry_initialized:
        return True

    dsn = os.getenv("NEXUS_SENTRY_DSN", "") or os.getenv("SENTRY_DSN", "")

    if not dsn:
        logger.info("[Sentry] Not configured — skipping initialization")
        return False

    environment = "dev"
    if config is not None:
        environment = config.environment

    release = os.getenv("NEXUS_VERSION", os.getenv("GIT_REVISION", "dev"))

    try:
        import sentry_sdk
        from sentry_sdk.integrations.asyncio import AsyncioIntegration
        from sentry_sdk.integrations.httpx import HttpxIntegration
        from sentry_sdk.integrations.loguru import LoguruIntegration
        from sentry_sdk.integrations.structlog import StructlogIntegration

        is_prod = environment == "prod"

        sentry_sdk.init(
            dsn=dsn,
            environment=environment,
            release=release,
            traces_sample_rate=0.1 if is_prod else 1.0,
            profiles_sample_rate=0.1 if is_prod else 0.0,
            send_default_pii=False,
            max_breadcrumbs=100,
            debug=False,
            before_send=_filter_sentry_event,
            before_breadcrumb=_filter_breadcrumb,
            ignore_errors=[
                "ConnectionResetError",
                "BrokenPipeError",
                "KeyboardInterrupt",
            ],
            in_app_include=["nexus_ai"],
            integrations=[
                LoguruIntegration(level=None, event_level=None),  # Przekaż wszystkie logi
                StructlogIntegration(),
                HttpxIntegration(),
                AsyncioIntegration(),
            ],
        )

        # Wymusza wysyłkę wszystkich bufforowanych eventów przed
        # zamknięciem aplikacji — zapobiega utracie eventów.
        import atexit

        atexit.register(lambda: sentry_sdk.flush(timeout=2))

        sentry_sdk.set_tag("runtime", "python")
        sentry_sdk.set_tag("python_version", os.getenv("PYTHON_VERSION", "3.13"))

        _sentry_initialized = True
        logger.info("[Sentry] Initialized for environment: %s (release=%s)", environment, release)
        return True

    except ImportError:
        logger.warning("[Sentry] sentry-sdk not installed. Install: pip install sentry-sdk")
        return False
    except Exception as exc:
        logger.warning("[Sentry] Initialization failed: %s", exc)
        return False




def capture_exception(exc: Exception, **context_tags: str) -> None:

    Używa ``sentry_sdk.new_scope()`` do izolacji kontekstu — bezpieczne
    dla współbieżnych requestów. Dodaje tagi (service, component, invoice_id)
    do konkretnego eventu, bez wpływu na globalny kontekst.

    Args:
        exc: Wyjątek do przechwycenia.
        **context_tags: Tagi kontekstowe (np. service=\"api\", invoice_id=\"123\").
    """
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk

        with sentry_sdk.new_scope() as scope:
            for key, val in context_tags.items():
                if val is not None:
                    scope.set_tag(key, str(val))
            sentry_sdk.capture_exception(exc)
    except Exception as e:
        logger.warning("[Sentry] capture_exception failed: %s", e)




def capture_message(message: str, level: str = "warning", **context_tags: str) -> None:

    Używaj dla błędów biznesowych które nie są wyjątkami:
    - Naruszenie reguł podatkowych
    - Nieudana walidacja danych
    - Odrzucenie transakcji przez TigerBeetle

    Args:
        message: Opis zdarzenia.
        level: Poziom severity (debug, info, warning, error, critical).
        **context_tags: Tagi kontekstowe.
    """
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk

        with sentry_sdk.new_scope() as scope:
            for key, val in context_tags.items():
                if val is not None:
                    scope.set_tag(key, str(val))
            sentry_sdk.capture_message(message, level=level)
    except Exception as e:
        logger.warning("[Sentry] capture_message failed: %s", e)




def set_tag(key: str, value: str) -> None:

    Tagi są globalne (scope-less). Używaj dla stałych, długożyciowych
    wartości jak ``service``, ``component``, ``version``.

    Args:
        key: Nazwa tagu.
        value: Wartość tagu.
    """
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk

        sentry_sdk.set_tag(key, value)
    except Exception as e:
        logger.warning("[Sentry] set_tag(%s) failed: %s", key, e)




def set_context(key: str, context: dict[str, Any]) -> None:

    Używaj dla kontekstu operacji (invoice, transaction, user).
    ``set_context(\"invoice\", {\"id\": \"123\", \"amount\": 1500})``

    Args:
        key: Nazwa kontekstu (np. \"invoice\", \"transaction\").
        context: Słownik z danymi kontekstowymi.
    """
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk

        sentry_sdk.set_context(key, context)
    except Exception as e:
        logger.warning("[Sentry] set_context(%s) failed: %s", key, e)




def set_user_context(user_id: str | None = None, **kwargs: str) -> None:
    """Set user context for Sentry events (with optional extra fields).

    Args:
        user_id: ID użytkownika.
        **kwargs: Dodatkowe pola (email, role, company_id).
    """
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk

        sentry_sdk.set_user({"id": user_id, **kwargs})
    except Exception as e:
        logger.warning("[Sentry] set_user_context failed: %s", e)




def add_breadcrumb(
    message: str,
    category: str = "default",
    level: str = "info",
    data: dict[str, Any] | None = None,
) -> None:
    """Add a breadcrumb to Sentry.


    Args:
        message: Opis breadcrumba.
        category: Kategoria (log, http, task, user, invoice, auth, query).
        level: Poziom (debug, info, warning, error).
        data: Opcjonalny słownik z dodatkowymi danymi.
    """
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk

        sentry_sdk.add_breadcrumb(
            message=message,
            category=category,
            level=level,
            data=data or {},
        )
    except Exception as e:
        logger.warning("[Sentry] add_breadcrumb failed: %s", e)




@contextmanager
def sentry_scope(**context_tags: str) -> Any:

    Tworzy NOWY scope dla operacji — wszystkie tagi i konteksty są
    izolowane od globalnego scope. Bezpieczne dla współbieżnych requestów.

    Przykład:
        with sentry_scope(invoice_id=\"123\", vendor=\"ABC\"):
            result = await process_invoice(invoice)
            # Błędy w tym bloku będą miały tagi invoice_id i vendor

    Args:
        **context_tags: Tagi do ustawienia w scope.

    Yields:
        sentry_sdk.Scope: Scope do ręcznej modyfikacji (opcjonalnie).
    """
    if not _sentry_initialized:
        yield _NoopTransaction()
        return

    import sentry_sdk

    with sentry_sdk.new_scope() as scope:
        for key, val in context_tags.items():
            if val is not None:
                scope.set_tag(key, str(val))
        yield scope




class _NoopTransaction:
    """No-op transaction gdy Sentry nie jest zainicjalizowany.

    Zachowuje się jak prawdziwy Sentry transaction/span ale nic nie robi.
    Pozwala na bezpieczne używanie ``with start_transaction(...) as t:`` bez
    sprawdzania czy Sentry jest dostępne.
    """

    def __enter__(self) -> _NoopTransaction:
        return self

    def __exit__(self, *args: Any) -> None:
        pass

    def start_span(self, **kwargs: Any) -> _NoopTransaction:
        return self

    def set_attribute(self, key: str, value: Any) -> None:
        pass

    def set_tag(self, key: str, value: str) -> None:
        pass




def flush(timeout: float = 2.0) -> None:

    Używaj przed zamknięciem aplikacji lub w krytycznych momentach.

    Args:
        timeout: Maksymalny czas oczekiwania w sekundach.
    """
    if not _sentry_initialized:
        return
    try:
        import sentry_sdk

        sentry_sdk.flush(timeout=timeout)
    except Exception as e:
        logger.warning("[Sentry] flush failed: %s", e)




def start_transaction(name: str, op: str = "task") -> Any:

    Używaj dla krytycznych ścieżek biznesowych:
    - Przetwarzanie faktury (process_invoice)
    - Obliczenia podatkowe (tax_calculation)
    - OCR pipeline (ocr_pipeline)

    Args:
        name: Nazwa transakcji (np. \"process_invoice\").
        op: Operacja (task, http, function).

    Returns:
            Sentry transaction or None if not initialized.

    Przykład:
        with start_transaction(\"process_invoice\") as transaction:
            with transaction.start_span(op=\"ocr\") as span:
                ocr_result = await ocr_run(invoice)
    """
    if not _sentry_initialized:
        return _NoopTransaction()
    try:
        import sentry_sdk

        return sentry_sdk.start_transaction(name=name, op=op)
    except Exception as e:
        logger.warning("[Sentry] start_transaction failed: %s", e)
        return _NoopTransaction()
