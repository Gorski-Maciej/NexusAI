"""
core/otel_instrument.py — Autoinstrumentacja bibliotek zewnętrznych przez OpenTelemetry.

SUPERMOCE:
  1. Instrumentor zapytań SQL przez SQLModel
  2. HTTPXClientInstrumentor — automatyczne trace'owanie requestów HTTP
  3. LoggingInstrumentor — automatyczna korelacja logów z trace'ami
  4. GrpcInstrumentorClient — automatyczne trace'owanie gRPC
  5. Wszystkie instrumentory są opcjonalne — ładują się tylko gdy biblioteka dostępna

Zgodnie z aa3fvcx.txt: OpenTelemetry jako standard skalowalności.
Jedno wywołanie → wszystkie biblioteki instrumentowane.
"""

from __future__ import annotations

import logging
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.otel_instrument")


def instrument_all() -> dict[str, bool]:
    """SUPERMOC: Jedno wywołanie → instrumentacja wszystkich dostępnych bibliotek.

    Każdy instrumentor jest opcjonalny — jeśli biblioteka nie jest zainstalowana,
    instrumentor jest pomijany. Zwraca słownik {biblioteka: czy_się_udało}.

    Returns:
        dict[str, bool]: status każdej instrumentacji.
    """
    results: dict[str, bool] = {}

    # ── SUPERMOC: Instrumentacja zapytań SQL przez SQLModel ──────────
    # Automatyczne trace'owanie każdego zapytania SQL wykonywanego przez SQLModel
    results["sqlalchemy"] = _instrument_sqlalchemy()

    # ── SUPERMOC: HTTPXClientInstrumentor ─────────────────────────────
    # Automatyczne trace'owanie requestów HTTP z nagłówkami W3C TraceContext
    results["httpx"] = _instrument_httpx()

    # ── SUPERMOC: LoggingInstrumentor ─────────────────────────────────
    # Automatyczna korelacja logów z OTel trace'ami
    results["logging"] = _instrument_logging()

    # ── SUPERMOC: AsyncioInstrumentor ─────────────────────────────────
    # Trace'owanie operacji asyncio (taski, future)
    results["asyncio"] = _instrument_asyncio()

    # ── SUPERMOC: GrpcClientInstrumentor ──────────────────────────────
    # Trace'owanie gRPC (dla OTLP exportera)
    results["grpc"] = _instrument_grpc()

    # Loguj podsumowanie
    successes = [k for k, v in results.items() if v]
    failures = [k for k, v in results.items() if not v]
    if successes:
        logger.info("[OTEL-INSTRUMENT] Instrumented: %s", ", ".join(successes))
    if failures:
        logger.debug("[OTEL-INSTRUMENT] Not available: %s", ", ".join(failures))

    return results


def _instrument_sqlalchemy() -> bool:
    """Instrument SQL ORM/core calls (used by SQLModel internally)."""
    try:
        from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

        SQLAlchemyInstrumentor().instrument(
            enable_commenter=True,
            commenter_options={},
        )
        logger.debug("[OTEL-INSTRUMENT] SQL instrumented via SQLModel")
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL-INSTRUMENT] SQL instrumentation failed: %s", exc)
        return False


def _instrument_httpx() -> bool:
    """Instrument httpx client for distributed tracing."""
    try:
        from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor

        HTTPXClientInstrumentor().instrument()
        logger.debug("[OTEL-INSTRUMENT] httpx instrumented")
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL-INSTRUMENT] httpx instrumentation failed: %s", exc)
        return False


def _instrument_logging() -> bool:
    """Instrument stdlib logging — auto-inject trace_id/span_id into log records."""
    try:
        from opentelemetry.instrumentation.logging import LoggingInstrumentor

        LoggingInstrumentor().instrument(
            set_logging_format=True,
            log_level=logging.INFO,
        )
        logger.debug("[OTEL-INSTRUMENT] Logging instrumented")
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL-INSTRUMENT] Logging instrumentation failed: %s", exc)
        return False


def _instrument_asyncio() -> bool:
    """Instrument asyncio — trace task creation and execution."""
    try:
        from opentelemetry.instrumentation.asyncio import AsyncioInstrumentor

        AsyncioInstrumentor().instrument()
        logger.debug("[OTEL-INSTRUMENT] Asyncio instrumented")
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL-INSTRUMENT] Asyncio instrumentation failed: %s", exc)
        return False


def _instrument_grpc() -> bool:
    """Instrument gRPC client (used by OTLP exporter)."""
    try:
        from opentelemetry.instrumentation.grpc import GrpcInstrumentorClient

        GrpcInstrumentorClient().instrument()
        logger.debug("[OTEL-INSTRUMENT] gRPC instrumented")
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL-INSTRUMENT] gRPC instrumentation failed: %s", exc)
        return False


def uninstrument_all() -> None:
    """Wyłącz wszystkie instrumentacje (dla cleanup)."""
    try:
        from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
        SQLAlchemyInstrumentor().uninstrument()
    except Exception:
        pass
    try:
        from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
        HTTPXClientInstrumentor().uninstrument()
    except Exception:
        pass
    try:
        from opentelemetry.instrumentation.logging import LoggingInstrumentor
        LoggingInstrumentor().uninstrument()
    except Exception:
        pass
    logger.debug("[OTEL-INSTRUMENT] All instrumentations uninstrumented")
