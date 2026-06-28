"""
core/otel_config.py — Centralna konfiguracja OpenTelemetry dla NexusAI.

SUPERMOCE:
  1. Standardowe OTEL_* env vary
  2. Head-based Sampling: konfigurowalny przez OTEL_TRACES_SAMPLER
  3. Resource Detection: automatyczne wykrywanie zasobów
  4. BatchSpanProcessor z konfigurowalnymi parametrami
  5. Graceful shutdown przez TracerProvider.shutdown() / MeterProvider.shutdown()
"""

from __future__ import annotations

import atexit
import os
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.otel_config")

# ── SUPERMOC: Standardowe OTEL_* env vary ─────────────────────────────────

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


# ── SUPERMOC: Resource Detection ──────────────────────────────────────────


def create_otel_resource() -> Any:
    """SUPERMOC: Automatyczne wykrywanie zasobów."""
    from opentelemetry.sdk.resources import Resource, ProcessResourceDetector

    custom_attrs: dict[str, str] = {}
    if OTEL_RESOURCE_ATTRIBUTES:
        for pair in OTEL_RESOURCE_ATTRIBUTES.split(","):
            if "=" in pair:
                key, value = pair.split("=", 1)
                custom_attrs[key.strip()] = value.strip()

    process_resource = ProcessResourceDetector().detect()
    service_resource = Resource.create(
        {
            "service.name": OTEL_SERVICE_NAME,
            "service.version": os.getenv("NEXUS_VERSION", "2.0.0"),
            "deployment.environment": os.getenv("NEXUS_ENV", "dev"),
            **custom_attrs,
        }
    )
    return service_resource.merge(process_resource)


# ── SUPERMOC: Head-based Sampling ─────────────────────────────────────────


def _resolve_sampler() -> Any:
    from opentelemetry.sdk.trace import sampling

    sampler_map: dict[str, Any] = {
        "always_on": sampling.ALWAYS_ON,
        "always_off": sampling.ALWAYS_OFF,
        "parentbased_always_on": sampling.ParentBased(sampling.ALWAYS_ON),
        "parentbased_always_off": sampling.ParentBased(sampling.ALWAYS_OFF),
        "traceidratio": sampling.TraceIdRatioBased(float(OTEL_TRACES_SAMPLER_ARG)),
        "parentbased_traceidratio": sampling.ParentBased(
            sampling.TraceIdRatioBased(float(OTEL_TRACES_SAMPLER_ARG))
        ),
    }
    sampler = sampler_map.get(OTEL_TRACES_SAMPLER, sampling.ALWAYS_ON)
    logger.debug(
        "[OTEL-CONFIG] Sampler: %s (arg=%s)",
        OTEL_TRACES_SAMPLER,
        OTEL_TRACES_SAMPLER_ARG,
    )
    return sampler


# ── SUPERMOC: TracerProvider z BatchSpanProcessor ────────────────────────


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

                otlp_exporter = OTLPSpanExporter(
                    endpoint=OTEL_EXPORTER_OTLP_ENDPOINT, insecure=True, timeout=5
                )
                provider.add_span_processor(
                    BatchSpanProcessor(
                        otlp_exporter,
                        max_queue_size=OTEL_BSP_MAX_QUEUE_SIZE,
                        scheduled_delay_millis=OTEL_BSP_SCHEDULE_DELAY,
                        max_export_batch_size=OTEL_BSP_MAX_EXPORT_BATCH_SIZE,
                        export_timeout_millis=OTEL_BSP_EXPORT_TIMEOUT,
                    )
                )
                logger.info(
                    "[OTEL-CONFIG] OTLP exporter configured: %s", OTEL_EXPORTER_OTLP_ENDPOINT
                )
            except Exception as exc:
                logger.warning("[OTEL-CONFIG] Failed to configure OTLP exporter: %s", exc)

        if os.getenv("NEXUS_ENV", "dev") == "dev":
            try:
                from opentelemetry.sdk.trace.export import ConsoleSpanExporter

                provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))
            except Exception:
                pass

        trace.set_tracer_provider(provider)
        logger.info(
            "[OTEL-CONFIG] Tracing initialized: service=%s env=%s",
            OTEL_SERVICE_NAME,
            os.getenv("NEXUS_ENV", "dev"),
        )
        return provider

    except ImportError as exc:
        logger.warning("[OTEL-CONFIG] opentelemetry not available — tracing disabled: %s", exc)
        return None


# ── MeterProvider ──


def create_meter_provider(
    resource: Any | None = None, views: list[Any] | None = None
) -> Any | None:
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

                otlp_metric_exporter = OTLPMetricExporter(
                    endpoint=OTEL_EXPORTER_OTLP_ENDPOINT, insecure=True, timeout=10
                )
                otlp_reader = PeriodicExportingMetricReader(
                    otlp_metric_exporter, export_interval_ms=30000
                )
                readers.append(otlp_reader)
            except Exception as exc:
                logger.warning("[OTEL-CONFIG] OTLP metrics reader failed: %s", exc)

        provider = MeterProvider(metric_readers=readers, resource=resource, views=views or None)
        metrics.set_meter_provider(provider)
        logger.info("[OTEL-CONFIG] Metrics initialized: readers=%d", len(readers))
        return provider

    except ImportError as exc:
        logger.warning("[OTEL-CONFIG] opentelemetry metrics not available: %s", exc)
        return None


# ── Graceful Shutdown ──

_tracer_provider_ref: Any = None
_meter_provider_ref: Any = None
_logger_provider_ref: Any = None


def _otel_atexit_shutdown() -> None:
    if _tracer_provider_ref is not None:
        try:
            _tracer_provider_ref.shutdown()
        except Exception:
            pass
    if _meter_provider_ref is not None:
        try:
            _meter_provider_ref.shutdown()
        except Exception:
            pass
    if _logger_provider_ref is not None:
        try:
            _logger_provider_ref.shutdown()
        except Exception:
            pass


def register_otel_shutdown(
    tracer_provider: Any | None = None,
    meter_provider: Any | None = None,
    logger_provider: Any | None = None,
) -> None:
    global _tracer_provider_ref, _meter_provider_ref, _logger_provider_ref
    if tracer_provider is not None:
        _tracer_provider_ref = tracer_provider
    if meter_provider is not None:
        _meter_provider_ref = meter_provider
    if logger_provider is not None:
        _logger_provider_ref = logger_provider
    atexit.register(_otel_atexit_shutdown)
