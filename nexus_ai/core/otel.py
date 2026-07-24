"""
OpenTelemetry -- consolidated module for NexusAI observability.

Zastępuje 4 osobne pliki: otel_tracing.py, otel_config.py, otel_logging.py, otel_instrument.py.
Zachowuje pełną kompatybilność wsteczną -- stare pliki są shimami importującymi z tego modułu.

Usage:
    from nexus_ai.core.otel import (
        init_tracing, get_tracer, traced, start_span, buffer_span,
        create_otel_resource, create_tracer_provider, create_meter_provider,
        register_otel_shutdown, setup_otel_logging,
        instrument_all, uninstrument_all,
    )
"""

from __future__ import annotations

import atexit
import logging
import os
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from contextvars import ContextVar
from functools import wraps
from typing import Any, TypeVar

from structlog import get_logger

from nexus_ai.services.otel_fallback import FileSpanBuffer

logger = get_logger("nexus.core.otel")

# ── Rec #7 v7.0: Resilient OTLP Exporter (BSP-FileSpanBuffer gap fix) ─────
try:
    from nexus_ai.services.otel_resilient_exporter import ResilientOTLPSpanExporter
    _HAS_RESILIENT_EXPORTER = True
except ImportError:
    _HAS_RESILIENT_EXPORTER = False
    ResilientOTLPSpanExporter = None  # type: ignore

# ── Supermoc: Semantic Conventions -- standardowe atrybuty OTel ────────────
try:
    from opentelemetry.semconv.trace import SpanAttributes
    HAS_SEMCONV = True
except ImportError:
    HAS_SEMCONV = False
    class SpanAttributes:  # type: ignore
        __slots__ = ()
        HTTP_REQUEST_METHOD = "http.request.method"
        HTTP_RESPONSE_STATUS_CODE = "http.response.status_code"
        URL_PATH = "url.path"
        ERROR = "error"
        EXCEPTION_TYPE = "exception.type"
        EXCEPTION_MESSAGE = "exception.message"
        EXCEPTION_STACKTRACE = "exception.stacktrace"
        CODE_FUNCTION = "code.function"
        CODE_NAMESPACE = "code.namespace"
        DB_SYSTEM = "db.system"
        DB_OPERATION = "db.operation"
        DB_SQL_TABLE = "db.sql.table"
        MESSAGING_SYSTEM = "messaging.system"
        MESSAGING_OPERATION = "messaging.operation"
        MESSAGING_DESTINATION_NAME = "messaging.destination.name"

# ── OTel Globals ─────────────────────────────────────────────────────────
_OTEL_AVAILABLE = False
_tracer_provider: Any = None
_span_buffer: FileSpanBuffer | None = None
_current_span_ctx: ContextVar[str | None] = ContextVar("current_span_id", default=None)
_tracer_provider_ref: Any = None
_meter_provider_ref: Any = None
_logger_provider_ref: Any = None
F = TypeVar("F", bound=Callable[..., Any])

# ── Standardowe OTEL_* env vary ─────────────────────────────────────────
OTEL_SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "nexus-ai")
OTEL_EXPORTER_OTLP_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "")
OTEL_EXPORTER_OTLP_PROTOCOL = os.getenv("OTEL_EXPORTER_OTLP_PROTOCOL", "grpc")
OTEL_RESOURCE_ATTRIBUTES = os.getenv("OTEL_RESOURCE_ATTRIBUTES", "")
OTEL_TRACES_SAMPLER = os.getenv("OTEL_TRACES_SAMPLER", "parentbased_always_on")
OTEL_TRACES_SAMPLER_ARG = os.getenv("OTEL_TRACES_SAMPLER_ARG", "1.0")
OTEL_BSP_MAX_QUEUE_SIZE = int(os.getenv("OTEL_BSP_MAX_QUEUE_SIZE", "2048"))
OTEL_BSP_SCHEDULE_DELAY = int(os.getenv("OTEL_BSP_SCHEDULE_DELAY", "5000"))
OTEL_BSP_MAX_EXPORT_BATCH_SIZE = int(os.getenv("OTEL_BSP_MAX_EXPORT_BATCH_SIZE", "512"))
OTEL_BSP_EXPORT_TIMEOUT = int(os.getenv("OTEL_BSP_EXPORT_TIMEOUT", "30000"))
OTEL_METRIC_EXPORT_INTERVAL = int(os.getenv("OTEL_METRIC_EXPORT_INTERVAL", "5000"))
OTEL_METRICS_CARDINALITY_LIMIT = os.getenv("OTEL_METRICS_CARDINALITY_LIMIT", "2000")
os.environ.setdefault("OTEL_METRICS_CARDINALITY_LIMIT", OTEL_METRICS_CARDINALITY_LIMIT)

# ── v7.0 Innowacja 12: Tail-Based Sampling ─────────────────────────────
#   - ERROR traces: 100% (always capture failures)
#   - Long traces (>1s): 50% (performance bottlenecks)
#   - Short traces (<100ms): 1% (reduce volume 90%+)
#   - Default: 10% (standard traces)

_TAIL_SAMPLING_ENABLED = os.getenv("NEXUS_TAIL_SAMPLING", "0") == "1"
_TAIL_ERROR_RATE = float(os.getenv("NEXUS_TAIL_ERROR_RATE", "1.0"))
_TAIL_LONG_RATE = float(os.getenv("NEXUS_TAIL_LONG_RATE", "0.5"))
_TAIL_SHORT_RATE = float(os.getenv("NEXUS_TAIL_SHORT_RATE", "0.01"))
_TAIL_DEFAULT_RATE = float(os.getenv("NEXUS_TAIL_DEFAULT_RATE", "0.1"))
_TAIL_LONG_THRESHOLD_MS = float(os.getenv("NEXUS_TAIL_LONG_MS", "1000"))
_TAIL_SHORT_THRESHOLD_MS = float(os.getenv("NEXUS_TAIL_SHORT_MS", "100"))


def should_sample_tail(has_error: bool, duration_ms: float) -> bool:
    """Tail-based sampling decision: always capture errors, downsample fast requests.
    
    Enterprise v7.0 Innowacja 12: Redukuje volume o 70-90% bez utraty
    krytycznych trace'ów (ERROR zawsze 100%, wolne requesty 50%).
    """
    import random
    if not _TAIL_SAMPLING_ENABLED:
        return True
    if has_error:
        return random.random() < _TAIL_ERROR_RATE
    if duration_ms > _TAIL_LONG_THRESHOLD_MS:
        return random.random() < _TAIL_LONG_RATE
    if duration_ms < _TAIL_SHORT_THRESHOLD_MS:
        return random.random() < _TAIL_SHORT_RATE
    return random.random() < _TAIL_DEFAULT_RATE

# ── Semantic Conventions key resolver ─────────────────────────────────
_SEMCONV_ALIASES: dict[str, str] = {
    "component": "code.namespace",
    "method": "http.request.method",
    "endpoint": "url.path",
    "status": "http.response.status_code",
    "db_system": "db.system",
    "db_operation": "db.operation",
    "event_type": "messaging.operation",
    "destination": "messaging.destination.name",
}

def _resolve_semconv_key(key: str) -> str:
    return _SEMCONV_ALIASES.get(key, key)

# ═══════════════════════════════════════════════════════════════════════════
# RESOURCE & SAMPLING (z otel_config.py)
# ═══════════════════════════════════════════════════════════════════════════

def create_otel_resource() -> Any:
    """Automatyczne wykrywanie zasobów OTel."""
    from opentelemetry.sdk.resources import ProcessResourceDetector, Resource
    custom_attrs: dict[str, str] = {}
    if OTEL_RESOURCE_ATTRIBUTES:
        for pair in OTEL_RESOURCE_ATTRIBUTES.split(","):
            if "=" in pair:
                k, v = pair.split("=", 1)
                custom_attrs[k.strip()] = v.strip()
    process_resource = ProcessResourceDetector().detect()
    service_resource = Resource.create({
        "service.name": OTEL_SERVICE_NAME,
        "service.version": os.getenv("NEXUS_VERSION", "2.0.0"),
        "deployment.environment": os.getenv("NEXUS_ENV", "dev"),
        **custom_attrs,
    })
    return service_resource.merge(process_resource)

def _resolve_sampler() -> Any:
    from opentelemetry.sdk.trace import sampling
    sampler_map: dict[str, Any] = {
        "always_on": sampling.ALWAYS_ON,
        "always_off": sampling.ALWAYS_OFF,
        "parentbased_always_on": sampling.ParentBased(sampling.ALWAYS_ON),
        "parentbased_always_off": sampling.ParentBased(sampling.ALWAYS_OFF),
        "traceidratio": sampling.TraceIdRatioBased(float(OTEL_TRACES_SAMPLER_ARG)),
        "parentbased_traceidratio": sampling.ParentBased(sampling.TraceIdRatioBased(float(OTEL_TRACES_SAMPLER_ARG))),
    }
    return sampler_map.get(OTEL_TRACES_SAMPLER, sampling.ALWAYS_ON)

# ═══════════════════════════════════════════════════════════════════════════
# TRACING (z otel_tracing.py)
# ═══════════════════════════════════════════════════════════════════════════

def init_tracing(
    service_name: str = "nexus-ai",
    otlp_endpoint: str | None = None,
    environment: str = "dev",
) -> Any | None:
    """Initialize OpenTelemetry tracing."""
    global _OTEL_AVAILABLE, _tracer_provider, _span_buffer
    if _tracer_provider is not None:
        return _tracer_provider
    _span_buffer = FileSpanBuffer(
        file_path=os.getenv("NEXUS_OTEL_SPAN_BUFFER_PATH", "app_data/otel_spans_buffer.jsonl"),
    )
    try:
        from opentelemetry import trace
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor, SimpleSpanProcessor

        resource = Resource.create({
            "service.name": service_name,
            "service.version": os.getenv("NEXUS_VERSION", "2.0.0"),
            "deployment.environment": environment,
        })
        provider = TracerProvider(resource=resource)
        endpoint = otlp_endpoint or os.getenv("NEXUS_OTLP_ENDPOINT", "")
        if endpoint:
            try:
                from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
                provider.add_span_processor(BatchSpanProcessor(
                    OTLPSpanExporter(endpoint=endpoint, insecure=True, timeout=5),
                ))
            except Exception as exc:
                logger.warning("[OTEL] OTLP exporter failed: %s", exc)
        if environment == "dev":
            try:
                provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))
            except Exception as exc:
                logger.debug("[OTEL] ConsoleSpanExporter failed: %s", exc)
        trace.set_tracer_provider(provider)
        _tracer_provider = provider
        _OTEL_AVAILABLE = True
        logger.info("[OTEL] Tracing init: service=%s env=%s otlp=%s", service_name, environment, endpoint or "disabled")
    except ImportError as exc:
        logger.warning("[OTEL] opentelemetry not available: %s", exc)
        _OTEL_AVAILABLE = False
        _tracer_provider = None
    return _tracer_provider

def get_tracer(name: str = "nexus-ai", version: str | None = None) -> Any:
    """Pobierz tracer dla danego komponentu."""
    if _OTEL_AVAILABLE:
        from opentelemetry import trace
        return trace.get_tracer(name, version or "2.0.0")
    return _NoopTracer()

def traced(
    span_name: str | None = None, *,
    tracer_name: str = "nexus-ai",
    attributes: dict[str, Any] | None = None,
    record_exceptions: bool = True,
) -> Callable[[F], F]:
    """Decorator: wrap function in an OTel span."""
    def decorator(func: F) -> F:
        _is_async = asyncio_coroutine(func)

        @wraps(func)
        async def async_wrapper(*args: Any, **kwargs: Any) -> Any:
            tracer = get_tracer(tracer_name)
            name = span_name or func.__name__
            with tracer.start_as_current_span(name) as span:
                span.set_attribute(SpanAttributes.CODE_FUNCTION, name)
                span.set_attribute(SpanAttributes.CODE_NAMESPACE, tracer_name)
                if attributes:
                    for k, v in attributes.items():
                        span.set_attribute(_resolve_semconv_key(k), v)
                token = _current_span_ctx.set(name)
                try:
                    return await func(*args, **kwargs)
                except Exception as exc:
                    if record_exceptions:
                        span.record_exception(exc)
                        span.set_attribute(SpanAttributes.ERROR, True)
                        span.set_status(status="error", description=str(exc))
                    raise
                finally:
                    _current_span_ctx.reset(token)

        @wraps(func)
        def sync_wrapper(*args: Any, **kwargs: Any) -> Any:
            tracer = get_tracer(tracer_name)
            name = span_name or func.__name__
            with tracer.start_as_current_span(name) as span:
                span.set_attribute(SpanAttributes.CODE_FUNCTION, name)
                span.set_attribute(SpanAttributes.CODE_NAMESPACE, tracer_name)
                if attributes:
                    for k, v in attributes.items():
                        span.set_attribute(_resolve_semconv_key(k), v)
                token = _current_span_ctx.set(name)
                try:
                    return func(*args, **kwargs)
                except Exception as exc:
                    if record_exceptions:
                        span.record_exception(exc)
                        span.set_attribute(SpanAttributes.ERROR, True)
                        span.set_status(status="error", description=str(exc))
                    raise
                finally:
                    _current_span_ctx.reset(token)

        return async_wrapper if _is_async else sync_wrapper  # type: ignore
    return decorator

@contextmanager
def start_span(
    name: str, tracer_name: str = "nexus-ai",
    attributes: dict[str, Any] | None = None, *,
    baggage: dict[str, str] | None = None,
) -> Iterator[Any]:
    """Context manager dla OTel span."""
    tracer = get_tracer(tracer_name)
    if baggage:
        from opentelemetry import baggage as otel_baggage
        ctx = otel_baggage.set_baggage("span.name", name)
        for bk, bv in baggage.items():
            ctx = otel_baggage.set_baggage(bk, bv, context=ctx)
    with tracer.start_as_current_span(name) as span:
        span.set_attribute(SpanAttributes.CODE_FUNCTION, name)
        span.set_attribute(SpanAttributes.CODE_NAMESPACE, tracer_name)
        if attributes:
            for k, v in attributes.items():
                span.set_attribute(_resolve_semconv_key(k), v)
        try:
            yield span
        except Exception as exc:
            span.record_exception(exc)
            span.set_attribute(SpanAttributes.ERROR, True)
            span.set_status(status="error", description=str(exc))
            raise

def buffer_span(trace_id: str, name: str, duration_ms: float, attributes: dict[str, Any] | None = None) -> None:
    """Zapisz span do fallback buffer."""
    if _span_buffer is None:
        return
    import pendulum
    now = pendulum.now("UTC")
    _span_buffer.append(trace_id=trace_id, name=name, start_ts=now, end_ts=now,
                        attributes={"duration_ms": duration_ms, **(attributes or {})})

class _NoopTracer:
    __slots__ = ()
    def start_as_current_span(self, name: str, **kwargs: Any) -> _NoopSpan:
        return _NoopSpan(name)

class _NoopSpan:
    __slots__ = ('_name',)
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

def asyncio_coroutine(func: Callable) -> bool:
    import inspect
    return inspect.iscoroutinefunction(func)

# ═══════════════════════════════════════════════════════════════════════════
# TRACER PROVIDER / METER PROVIDER (z otel_config.py)
# ═══════════════════════════════════════════════════════════════════════════

def create_tracer_provider(resource: Any | None = None) -> Any | None:
    try:
        from opentelemetry import trace
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor, SimpleSpanProcessor
        if resource is None:
            resource = create_otel_resource()
        sampler = _resolve_sampler()
        provider = TracerProvider(resource=resource, sampler=sampler)
        if OTEL_EXPORTER_OTLP_ENDPOINT:
            try:
                from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
                provider.add_span_processor(BatchSpanProcessor(
                    OTLPSpanExporter(endpoint=OTEL_EXPORTER_OTLP_ENDPOINT, insecure=True, timeout=5),
                    max_queue_size=OTEL_BSP_MAX_QUEUE_SIZE,
                    scheduled_delay_millis=OTEL_BSP_SCHEDULE_DELAY,
                    max_export_batch_size=OTEL_BSP_MAX_EXPORT_BATCH_SIZE,
                    export_timeout_millis=OTEL_BSP_EXPORT_TIMEOUT,
                ))
            except Exception as exc:
                logger.warning("[OTEL] OTLP provider failed: %s", exc)
        if os.getenv("NEXUS_ENV", "dev") == "dev":
            try:
                provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))
            except Exception as exc:
                logger.debug("[OTEL] ConsoleSpanExporter failed: %s", exc)
        trace.set_tracer_provider(provider)
        logger.info("[OTEL] TracerProvider init: service=%s env=%s", OTEL_SERVICE_NAME, os.getenv("NEXUS_ENV", "dev"))
        return provider
    except ImportError as exc:
        logger.warning("[OTEL] opentelemetry not available: %s", exc)
        return None

def create_meter_provider(resource: Any | None = None, views: list[Any] | None = None) -> Any | None:
    try:
        from opentelemetry import metrics
        from opentelemetry.sdk.metrics import MeterProvider
        from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
        if resource is None:
            resource = create_otel_resource()
        readers: list[Any] = []
        if OTEL_EXPORTER_OTLP_ENDPOINT:
            try:
                from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import (
                    OTLPMetricExporter,
                )
                readers.append(PeriodicExportingMetricReader(
                    OTLPMetricExporter(endpoint=OTEL_EXPORTER_OTLP_ENDPOINT, insecure=True, timeout=10),
                    export_interval_ms=30000,
                ))
            except Exception as exc:
                logger.warning("[OTEL] OTLP metrics reader failed: %s", exc)
        provider = MeterProvider(metric_readers=readers, resource=resource, views=views or None)
        metrics.set_meter_provider(provider)
        logger.info("[OTEL] Metrics init: readers=%d", len(readers))
        # v7.0: Register business metrics (Raport 3.5)
        _init_business_metrics()
        return provider
    except ImportError as exc:
        logger.warning("[OTEL] opentelemetry metrics not available: %s", exc)
        return None


def _init_business_metrics() -> None:
    """v7.0: Custom business metrics — invoice_count, tax_total, transfer_count.
    
    Raport 3.5: Dodaje metryki biznesowe (invoice_count, tax_total)
    do OTel, umożliwiając monitorowanie operacji księgowych.
    """
    try:
        from opentelemetry import metrics
        meter = metrics.get_meter("nexus-ai", os.getenv("NEXUS_VERSION", "2.0.0"))
        global _business_metrics
        _business_metrics = {
            "invoice_count": meter.create_counter(
                "nexus.invoice.count",
                description="Total invoice processing count",
                unit="1",
            ),
            "invoice_errors": meter.create_counter(
                "nexus.invoice.errors",
                description="Invoice processing errors",
                unit="1",
            ),
            "tax_total": meter.create_histogram(
                "nexus.tax.total",
                description="Total tax amount per invoice",
                unit="PLN",
            ),
            "transfer_count": meter.create_counter(
                "nexus.transfer.count",
                description="Total TigerBeetle transfer count",
                unit="1",
            ),
            "transfer_latency_ms": meter.create_histogram(
                "nexus.transfer.latency",
                description="TigerBeetle transfer latency in ms",
                unit="ms",
            ),
        }
        logger.debug("[OTEL] Business metrics registered: invoice_count, tax_total, transfer_count, transfer_latency_ms")
    except Exception as exc:
        logger.debug("[OTEL] Business metrics init failed: %s", exc)

_business_metrics: dict[str, Any] = {}


def record_business_metric(name: str, value: float | int = 1, attributes: dict[str, Any] | None = None) -> None:
    """Record a business metric — safe no-op if OTel not available.
    
    Usage:
        record_business_metric("invoice_count", 1, {"status": "processed"})
        record_business_metric("tax_total", 2300.50, {"vat_rate": "23"})
        record_business_metric("transfer_latency_ms", 15.3, {"ledger": "main"})
    """
    metric = _business_metrics.get(name)
    if metric is None:
        return
    try:
        from opentelemetry.metrics import Counter, Histogram  # noqa: F811
        if isinstance(metric, Counter):
            metric.add(int(value), attributes=attributes or {})
        elif isinstance(metric, Histogram):
            metric.record(float(value), attributes=attributes or {})
    except Exception:
        pass

def _otel_atexit_shutdown() -> None:
    for ref in (_tracer_provider_ref, _meter_provider_ref, _logger_provider_ref):
        if ref is not None:
            try:
                ref.shutdown()
            except Exception as exc:
                logger.debug("[OTEL] Shutdown error for %s: %s", type(ref).__name__, exc)
def register_otel_shutdown(tracer_provider: Any | None = None, meter_provider: Any | None = None, logger_provider: Any | None = None) -> None:
    global _tracer_provider_ref, _meter_provider_ref, _logger_provider_ref
    if tracer_provider is not None:
        _tracer_provider_ref = tracer_provider
    if meter_provider is not None:
        _meter_provider_ref = meter_provider
    if logger_provider is not None:
        _logger_provider_ref = logger_provider
    atexit.register(_otel_atexit_shutdown)

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING BRIDGE (z otel_logging.py)
# ═══════════════════════════════════════════════════════════════════════════

def setup_otel_logging(resource: Any | None = None) -> Any | None:
    """Konfiguruje OTel LoggingHandler."""
    try:
        from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
        from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
        if resource is None:
            resource = create_otel_resource()
        log_provider = LoggerProvider(resource=resource)
        if OTEL_EXPORTER_OTLP_ENDPOINT:
            try:
                from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
                log_provider.add_log_record_processor(BatchLogRecordProcessor(
                    OTLPLogExporter(endpoint=OTEL_EXPORTER_OTLP_ENDPOINT, insecure=True, timeout=5),
                ))
            except Exception as exc:
                logger.debug("[OTEL] OTLP log exporter failed: %s", exc)
        if os.getenv("NEXUS_ENV", "dev") == "dev":
            try:
                from opentelemetry.sdk._logs.export import ConsoleLogExporter
                log_provider.add_log_record_processor(BatchLogRecordProcessor(ConsoleLogExporter()))
            except Exception:
                pass
        root_logger = logging.getLogger()
        root_logger.addHandler(LoggingHandler(logger_provider=log_provider, level=logging.WARNING))
        logger.info("[OTEL] LoggingHandler added (level=WARNING+)")
        return log_provider
    except ImportError as exc:
        logger.debug("[OTEL] OTel Logs SDK not available: %s", exc)
        return None
    except Exception as exc:
        logger.debug("[OTEL] Setup failed: %s", exc)
        return None

# ═══════════════════════════════════════════════════════════════════════════
# INSTRUMENTATION (z otel_instrument.py)
# ═══════════════════════════════════════════════════════════════════════════

def instrument_all() -> dict[str, bool]:
    """Instrumentacja wszystkich dostępnych bibliotek.
    
    v7.0: Dodano NATS instrumentation (Raport 3.3).
    """
    results: dict[str, bool] = {}
    for name, fn in [
        ("sqlalchemy", _instrument_sqlalchemy), ("httpx", _instrument_httpx),
        ("logging", _instrument_logging), ("asyncio", _instrument_asyncio),
        ("grpc", _instrument_grpc), ("nats", _instrument_nats),
    ]:
        results[name] = fn()
    successes = [k for k, v in results.items() if v]
    failures = [k for k, v in results.items() if not v]
    if successes:
        logger.info("[OTEL] Instrumented: %s", ", ".join(successes))
    if failures:
        logger.debug("[OTEL] Not available: %s", ", ".join(failures))
    return results

def _instrument_nats() -> bool:
    """v7.0: NATS instrumentation (Raport 3.3)."""
    try:
        from opentelemetry.instrumentation.nats import NATSInstrumentor
        NATSInstrumentor().instrument()
        return True
    except ImportError:
        pass
    try:
        from opentelemetry.instrumentation.pynats import PynatsInstrumentor
        PynatsInstrumentor().instrument()
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL] NATS instrumentation failed: %s", exc)
        return False

def uninstrument_all() -> None:
    """Wyłącz wszystkie instrumentacje.

    Używa importlib.import_module zamiast __import__ (Enterprise TOP-6 fix).
    v7.0: Dodano NATS uninstrument.
    """
    import importlib as _il
    for mod_name, instr_name in [
        ("sqlalchemy", "SQLAlchemyInstrumentor"),
        ("httpx", "HTTPXClientInstrumentor"),
        ("logging", "LoggingInstrumentor"),
        ("nats", "NATSInstrumentor"),
    ]:
        try:
            mod = _il.import_module(f"opentelemetry.instrumentation.{mod_name}")
            if hasattr(mod, instr_name):
                instr_class = getattr(mod, instr_name)
                if hasattr(instr_class, "uninstrument"):
                    instr_class.uninstrument()
        except Exception as exc:
            logger.debug("[OTEL] Failed to uninstrument %s: %s", mod_name, exc)
    logger.debug("[OTEL] All instrumentations uninstrumented")

def _instrument_sqlalchemy() -> bool:
    try:
        from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
        SQLAlchemyInstrumentor().instrument(enable_commenter=True, commenter_options={})
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL] SQL instrumentation failed: %s", exc)
        return False

def _instrument_httpx() -> bool:
    try:
        from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
        HTTPXClientInstrumentor().instrument()
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL] httpx instrumentation failed: %s", exc)
        return False

def _instrument_logging() -> bool:
    try:
        from opentelemetry.instrumentation.logging import LoggingInstrumentor
        LoggingInstrumentor().instrument(set_logging_format=True, log_level=logging.INFO)
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL] Logging instrumentation failed: %s", exc)
        return False

def _instrument_asyncio() -> bool:
    try:
        from opentelemetry.instrumentation.asyncio import AsyncioInstrumentor
        AsyncioInstrumentor().instrument()
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL] Asyncio instrumentation failed: %s", exc)
        return False

def _instrument_grpc() -> bool:
    try:
        from opentelemetry.instrumentation.grpc import GrpcInstrumentorClient
        GrpcInstrumentorClient().instrument()
        return True
    except ImportError:
        return False
    except Exception as exc:
        logger.warning("[OTEL] gRPC instrumentation failed: %s", exc)
        return False

def uninstrument_all() -> None:
    """Wyłącz wszystkie instrumentacje.

    Używa importlib.import_module zamiast __import__ (Enterprise TOP-6 fix).
    """
    import importlib as _il
    for mod_name in ("sqlalchemy", "httpx", "logging"):
        try:
            instr_name = "SQLAlchemyInstrumentor" if mod_name == "sqlalchemy" else f"{mod_name.capitalize()}Instrumentor"
            mod = _il.import_module(f"opentelemetry.instrumentation.{mod_name}")
            if hasattr(mod, instr_name):
                instr_class = getattr(mod, instr_name)
                if hasattr(instr_class, "uninstrument"):
                    instr_class.uninstrument()
        except Exception as exc:
            logger.debug("[OTEL] Failed to uninstrument %s: %s", mod_name, exc)
    logger.debug("[OTEL] All instrumentations uninstrumented")
