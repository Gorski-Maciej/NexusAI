"""
OpenTelemetry distributed tracing for NexusAI.

Zgodnie z aa3fvcx.txt: OpenTelemetry Tracing API + SDK jako standard
dla monitorowania end-to-end przepływu żądań przez system.

Zapewnia:
  - W3C TraceContext propagation (traceparent header)
  - Automatyczne spanowanie dla HTTP requestów
  - Span decoratory dla serwisów (@traced)
  - Integracja z EventStore i JetStreamEventBus
  - Batch span exporter do OTLP z fallbackiem JSONL

Usage:
    from nexus_ai.core.otel_tracing import (
        init_tracing,
        get_tracer,
        traced,
        TracerMiddleware,
    )

    # W on_startup:
    tracer_provider = init_tracing(service_name="nexus-api")
    app.state.tracer_provider = tracer_provider

    # W handlerze:
    tracer = get_tracer("decision_engine")
    with tracer.start_as_current_span("evaluate_rules") as span:
        span.set_attribute("invoice_id", invoice_id)
        result = await evaluate(invoice)
"""

from __future__ import annotations

import os
import time
from contextlib import contextmanager
from contextvars import ContextVar
from functools import wraps
from typing import Any, Callable, Iterator, TypeVar

from structlog import get_logger

from nexus_ai.services.otel_fallback import FileSpanBuffer

logger = get_logger("nexus.core.otel_tracing")

# ── Globals ───────────────────────────────────────────────────────────────

_OTEL_AVAILABLE = False
_tracer_provider: Any = None  # TracerProvider
_span_buffer: FileSpanBuffer | None = None

# ContextVar dla propagacji parent span ID
_current_span_ctx: ContextVar[str | None] = ContextVar("current_span_id", default=None)

F = TypeVar("F", bound=Callable[..., Any])


# ── Init ──────────────────────────────────────────────────────────────────


def init_tracing(
    service_name: str = "nexus-ai",
    otlp_endpoint: str | None = None,
    environment: str = "dev",
) -> Any | None:
    """Initialize OpenTelemetry tracing.

    Args:
        service_name: Nazwa serwisu (Resource).
        otlp_endpoint: OTLP gRPC endpoint (domyślnie z env NEXUS_OTLP_ENDPOINT).
        environment: Środowisko (dev/stage/prod).

    Returns:
        TracerProvider lub None jeśli OTel nie jest dostępny.
    """
    global _OTEL_AVAILABLE, _tracer_provider, _span_buffer

    if _tracer_provider is not None:
        return _tracer_provider

    _span_buffer = FileSpanBuffer(
        file_path=os.getenv(
            "NEXUS_OTEL_SPAN_BUFFER_PATH",
            "app_data/otel_spans_buffer.jsonl",
        ),
    )

    try:
        from opentelemetry import trace
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor, SimpleSpanProcessor

        resource = Resource.create(
            {
                "service.name": service_name,
                "service.version": os.getenv("NEXUS_VERSION", "2.0.0"),
                "deployment.environment": environment,
            }
        )

        provider = TracerProvider(resource=resource)

        # OTLP exporter (gdy dostępny)
        endpoint = otlp_endpoint or os.getenv("NEXUS_OTLP_ENDPOINT", "")
        if endpoint:
            try:
                from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

                otlp_exporter = OTLPSpanExporter(
                    endpoint=endpoint,
                    insecure=True,
                    timeout=5,  # sekund — nie blokuj przy nieosiągalnym OTLP
                )
                provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
                logger.info("[OTEL-TRACING] OTLP exporter configured: %s", endpoint)
            except Exception as exc:
                logger.warning("[OTEL-TRACING] Failed to configure OTLP exporter: %s", exc)

        # Console exporter w dev
        if environment == "dev":
            try:
                from opentelemetry.sdk.trace.export import ConsoleSpanExporter

                provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))
            except Exception:
                pass

        trace.set_tracer_provider(provider)
        _tracer_provider = provider
        _OTEL_AVAILABLE = True

        logger.info(
            "[OTEL-TRACING] Tracing initialized: service=%s env=%s otlp=%s",
            service_name,
            environment,
            endpoint or "disabled",
        )

    except ImportError as exc:
        logger.warning(
            "[OTEL-TRACING] opentelemetry not available — tracing disabled: %s",
            exc,
        )
        _OTEL_AVAILABLE = False
        _tracer_provider = None

    return _tracer_provider


def get_tracer(name: str = "nexus-ai", version: str | None = None) -> Any:
    """Pobierz tracer dla danego komponentu.

    Args:
        name: Nazwa tracera (np. "decision_engine", "event_store").
        version: Opcjonalna wersja.

    Returns:
        Tracer lub no-op tracer jeśli OTel niedostępny.
    """
    if _OTEL_AVAILABLE:
        from opentelemetry import trace

        return trace.get_tracer(name, version or "2.0.0")

    # No-op tracer
    return _NoopTracer()


# ── Decorator ─────────────────────────────────────────────────────────────


def traced(
    span_name: str | None = None,
    *,
    tracer_name: str = "nexus-ai",
    attributes: dict[str, Any] | None = None,
    record_exceptions: bool = True,
) -> Callable[[F], F]:
    """Decorator: wrap async function in an OTel span.

    Args:
        span_name: Nazwa spana (domyślnie nazwa funkcji).
        tracer_name: Nazwa tracera.
        attributes: Dodatkowe atrybuty do ustawienia na span.
        record_exceptions: Czy zapisywać wyjątki jako span events.

    Returns:
        Decorator.
    """

    def decorator(func: F) -> F:
        @wraps(func)
        async def async_wrapper(*args: Any, **kwargs: Any) -> Any:
            tracer = get_tracer(tracer_name)
            name = span_name or func.__name__

            with tracer.start_as_current_span(name) as span:
                if attributes:
                    for k, v in attributes.items():
                        span.set_attribute(k, v)

                # Ustaw parent span ID w context
                token = _current_span_ctx.set(name)

                try:
                    result = await func(*args, **kwargs)
                    return result
                except Exception as exc:
                    if record_exceptions:
                        span.record_exception(exc)
                        span.set_status(status="error", description=str(exc))
                    raise
                finally:
                    _current_span_ctx.reset(token)

        @wraps(func)
        def sync_wrapper(*args: Any, **kwargs: Any) -> Any:
            tracer = get_tracer(tracer_name)
            name = span_name or func.__name__

            with tracer.start_as_current_span(name) as span:
                if attributes:
                    for k, v in attributes.items():
                        span.set_attribute(k, v)

                token = _current_span_ctx.set(name)

                try:
                    result = func(*args, **kwargs)
                    return result
                except Exception as exc:
                    if record_exceptions:
                        span.record_exception(exc)
                        span.set_status(status="error", description=str(exc))
                    raise
                finally:
                    _current_span_ctx.reset(token)

        if asyncio_coroutine(func):
            return async_wrapper  # type: ignore
        return sync_wrapper  # type: ignore

    return decorator


# ── Context manager ───────────────────────────────────────────────────────


@contextmanager
def start_span(
    name: str,
    tracer_name: str = "nexus-ai",
    attributes: dict[str, Any] | None = None,
) -> Iterator[Any]:
    """Context manager for creating a span.

    Używane w miejscach gdzie dekorator jest niewygodny (pętle, warunki).

    Args:
        name: Nazwa spana.
        tracer_name: Nazwa tracera.
        attributes: Atrybuty spana.

    Yields:
        Span object (lub no-op).
    """
    tracer = get_tracer(tracer_name)
    with tracer.start_as_current_span(name) as span:
        if attributes:
            for k, v in attributes.items():
                span.set_attribute(k, v)
        try:
            yield span
        except Exception as exc:
            span.record_exception(exc)
            span.set_status(status="error", description=str(exc))
            raise


# ── Fallback buffer ───────────────────────────────────────────────────────


def buffer_span(
    trace_id: str,
    name: str,
    duration_ms: float,
    attributes: dict[str, Any] | None = None,
) -> None:
    """Zapisz span do fallback buffer gdy OTel jest niedostępny.

    Args:
        trace_id: ID trace'a.
        name: Nazwa spana.
        duration_ms: Czas trwania w ms.
        attributes: Dodatkowe atrybuty.
    """
    if _span_buffer is None:
        return
    import pendulum

    now = pendulum.now("UTC")
    _span_buffer.append(
        trace_id=trace_id,
        name=name,
        start_ts=now,
        end_ts=now,
        attributes={"duration_ms": duration_ms, **(attributes or {})},
    )


# ── No-op tracer ──────────────────────────────────────────────────────────


class _NoopTracer:
    """No-op tracer gdy OTel nie jest dostępny."""

    def start_as_current_span(self, name: str, **kwargs: Any) -> _NoopSpan:
        return _NoopSpan(name)


class _NoopSpan:
    def __init__(self, name: str) -> None:
        self._name = name

    def __enter__(self) -> _NoopSpan:
        return self

    def __exit__(self, *args: Any) -> None:
        pass

    def set_attribute(self, key: str, value: Any) -> None:
        pass

    def set_status(self, **kwargs: Any) -> None:
        pass

    def record_exception(self, exception: Exception) -> None:
        pass

    def add_event(self, name: str, attributes: dict[str, Any] | None = None) -> None:
        pass


# ── Helper ────────────────────────────────────────────────────────────────


def asyncio_coroutine(func: Callable) -> bool:
    """Sprawdź czy funkcja jest async."""
    import inspect

    return inspect.iscoroutinefunction(func)
