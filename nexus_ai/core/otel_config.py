"""
core/otel_config.py — Centralna konfiguracja OpenTelemetry dla NexusAI.

from __future__ import annotations

SUPERMOCE:
  1. Standardowe OTEL_* env vary (OTEL_SERVICE_NAME, OTEL_EXPORTER_OTLP_ENDPOINT, itd.)
  2. Multi-Reader: Prometheus + OTLP Metrics jednocześnie
  3. Exemplars: korelacja metryk z trace'ami (AlignedHistogramBucketExemplarReservoir)
  4. Cumulative Temporality: wymagane dla Prometheus (Delta resetuje liczniki!)
  5. Head-based Sampling: konfigurowalny przez OTEL_TRACES_SAMPLER
  6. Resource Detection: automatyczne wykrywanie zasobów (cloud, container, process)
  7. Views API: agregacja/filtrowanie metryk bez zmiany kodu
  8. BatchSpanProcessor z konfigurowalnymi parametrami (max_queue_size, scheduled_delay)
  9. Graceful shutdown przez TracerProvider.shutdown() / MeterProvider.shutdown()

Zgodnie z aa3fvcx.txt: OpenTelemetry jako standard skalowalności.
"""

from __future__ import annotations

import atexit
import os
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.otel_config")

# ── SUPERMOC: Standardowe OTEL_* env vary ─────────────────────────────────
# Zgodne z https://opentelemetry.io/docs/specs/otel/configuration/sdk-environment-variables/

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
OTEL_METRICS_EXEMPLAR_FILTER = os.getenv("OTEL_METRICS_EXEMPLAR_FILTER", "trace_based")
OTEL_METRIC_EXPORT_INTERVAL = int(os.getenv("OTEL_METRIC_EXPORT_INTERVAL", "5000"))

# SUPERMOC: Ochrona przed eksplozją kardynalności etykiet
# Ustawiamy zmienną środowiskową, którą OTel SDK odczytuje automatycznie.
# Gdy metryka ma więcej unikalnych kombinacji etykiet niż ten limit,
# SDK odrzuca nadmiarowe punkty danych (2000 = bezpieczny domyślny limit).
OTEL_METRICS_CARDINALITY_LIMIT = os.getenv("OTEL_METRICS_CARDINALITY_LIMIT", "2000")
os.environ.setdefault("OTEL_METRICS_CARDINALITY_LIMIT", OTEL_METRICS_CARDINALITY_LIMIT)


# ── SUPERMOC: Resource Detection ──────────────────────────────────────────


def create_otel_resource() -> Any:
    """SUPERMOC: Automatyczne wykrywanie zasobów.

    Łączy:
    - OTEL_RESOURCE_ATTRIBUTES env var (key=value,key2=value2)
    - Detekcja procesu (PID, executable path)
    - Service.name i service.version

    Returns:
        Resource z automatycznie wykrytymi atrybutami.
    """
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
    """SUPERMOC: Head-based sampling z OTEL_TRACES_SAMPLER env var."""
    from opentelemetry.sdk.trace import sampling

    sampler_map: dict[str, Any] = {
        "always_on": sampling.ALWAYS_ON,
        "always_off": sampling.ALWAYS_OFF,
        "parentbased_always_on": sampling.ParentBased(sampling.ALWAYS_ON),
        "parentbased_always_off": sampling.ParentBased(sampling.ALWAYS_OFF),
        "traceidratio": sampling.TraceIdRatioBased(
            float(OTEL_TRACES_SAMPLER_ARG)
        ),
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
    """SUPERMOC: Stwórz TracerProvider z samplerem i BatchSpanProcessor.

    Limity atrybutów/zdarzeń są kontrolowane przez standardowe OTEL_* env vary
    (OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT, OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT, itd.)
    — SDK automatycznie je odczytuje, nie trzeba przekazywać do TracerProvider.

    Args:
        resource: Resource (opcjonalnie, tworzy domyślny jeśli nie podany).

    Returns:
        TracerProvider lub None jeśli OTel nie jest dostępny.
    """
    try:
        from opentelemetry import trace
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor, SimpleSpanProcessor

        if resource is None:
            resource = create_otel_resource()

        sampler = _resolve_sampler()

        # SUPERMOC: TracerProvider — SDK automatycznie czyta OTEL_* env vary
        # dla limitów atrybutów, więc nie trzeba przekazywać span_limits jako dict
        provider = TracerProvider(
            resource=resource,
            sampler=sampler,
        )

        # SUPERMOC: BatchSpanProcessor z konfigurowalnymi parametrami
        if OTEL_EXPORTER_OTLP_ENDPOINT:
            try:
                from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

                otlp_exporter = OTLPSpanExporter(
                    endpoint=OTEL_EXPORTER_OTLP_ENDPOINT,
                    insecure=True,
                    timeout=5,
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
                    "[OTEL-CONFIG] OTLP exporter configured: %s (queue=%d, delay=%dms)",
                    OTEL_EXPORTER_OTLP_ENDPOINT,
                    OTEL_BSP_MAX_QUEUE_SIZE,
                    OTEL_BSP_SCHEDULE_DELAY,
                )
            except Exception as exc:
                logger.warning("[OTEL-CONFIG] Failed to configure OTLP exporter: %s", exc)

        # SUPERMOC: Console exporter w dev
        if os.getenv("NEXUS_ENV", "dev") == "dev":
            try:
                from opentelemetry.sdk.trace.export import ConsoleSpanExporter
                provider.add_span_processor(
                    SimpleSpanProcessor(ConsoleSpanExporter())
                )
            except Exception:
                pass

        trace.set_tracer_provider(provider)
        logger.info(
            "[OTEL-CONFIG] Tracing initialized: service=%s env=%s sampler=%s otlp=%s",
            OTEL_SERVICE_NAME,
            os.getenv("NEXUS_ENV", "dev"),
            OTEL_TRACES_SAMPLER,
            OTEL_EXPORTER_OTLP_ENDPOINT or "disabled",
        )
        return provider

    except ImportError as exc:
        logger.warning("[OTEL-CONFIG] opentelemetry not available — tracing disabled: %s", exc)
        return None


# ── SUPERMOC: MeterProvider z Multi-Reader + Views + Exemplars + Cumulative Temporality ──


def create_meter_provider(
    resource: Any | None = None,
    views: list[Any] | None = None,
) -> Any | None:
    """SUPERMOC: Stwórz MeterProvider z wieloma readerami, Views API, Exemplars i Cumulative temporality.

    SUPERMOC FIX: Prometheus wymaga CUMULATIVE temporality dla Counterów.
    Delta powoduje reset liczników do 0 po każdym eksporcie.

    Args:
        resource: Resource.
        views: Lista View dla agregacji/filtrowania metryk.

    Returns:
        MeterProvider lub None.
    """
    try:
        from opentelemetry import metrics
        from opentelemetry.sdk.metrics import MeterProvider
        from opentelemetry.sdk.metrics.export import (
            AggregationTemporality,
            PeriodicExportingMetricReader,
        )
        from opentelemetry.sdk.metrics import Counter as SDKCounter

        if resource is None:
            resource = create_otel_resource()

        readers: list[Any] = []

        # ── SUPERMOC: Prometheus Reader z Cumulative temporality ─────
        # 🐛 FIX: Prometheus wymaga Cumulative — Delta resetuje liczniki!
        try:
            from opentelemetry.exporter.prometheus import PrometheusMetricsExporter

            global _prometheus_exporter_ref
            prom_exporter = PrometheusMetricsExporter()
            _prometheus_exporter_ref = prom_exporter
            prom_reader = PeriodicExportingMetricReader(
                prom_exporter,
                export_interval_ms=OTEL_METRIC_EXPORT_INTERVAL,
                preferred_temporality={
                    SDKCounter: AggregationTemporality.CUMULATIVE,
                },
            )
            readers.append(prom_reader)
        except Exception as exc:
            logger.debug("[OTEL-CONFIG] Prometheus reader not available: %s", exc)

        # ── SUPERMOC: OTLP Metrics Reader ────────────────────────────
        if OTEL_EXPORTER_OTLP_ENDPOINT:
            try:
                from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter

                otlp_metric_exporter = OTLPMetricExporter(
                    endpoint=OTEL_EXPORTER_OTLP_ENDPOINT,
                    insecure=True,
                    timeout=10,
                )
                otlp_reader = PeriodicExportingMetricReader(
                    otlp_metric_exporter,
                    export_interval_ms=30000,
                )
                readers.append(otlp_reader)
            except Exception as exc:
                logger.warning("[OTEL-CONFIG] OTLP metrics reader failed: %s", exc)

        # ── SUPERMOC: Views API ──────────────────────────────────────
        configured_views: list[Any] = list(views or [])

        # Exemplars — tylko jeśli SDK wspiera
        try:
            from opentelemetry.sdk.metrics.view import (
                AlignedHistogramBucketExemplarReservoir,
                ExplicitBucketHistogramAggregation,
                View,
            )

            if OTEL_METRICS_EXEMPLAR_FILTER == "trace_based":
                exemplar_reservoir = AlignedHistogramBucketExemplarReservoir()
                configured_views.append(
                    View(
                        instrument_name="http_request_duration_seconds",
                        attribute_keys={"method", "endpoint"},
                        aggregation=ExplicitBucketHistogramAggregation(
                            boundaries=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
                            exemplar_reservoir=exemplar_reservoir,
                        ),
                    )
                )
                configured_views.append(
                    View(
                        instrument_name="ai_inference_duration_seconds",
                        attribute_keys={"model_name"},
                        aggregation=ExplicitBucketHistogramAggregation(
                            boundaries=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0],
                            exemplar_reservoir=exemplar_reservoir,
                        ),
                    )
                )
                logger.debug("[OTEL-CONFIG] Exemplars enabled (trace_based)")
        except ImportError:
            logger.debug("[OTEL-CONFIG] Exemplars not supported in this SDK version")

        # ── SUPERMOC: MeterProvider ─────────────────────────────────
        provider = MeterProvider(
            metric_readers=readers,
            resource=resource,
            views=configured_views if configured_views else None,
        )
        metrics.set_meter_provider(provider)
        logger.info(
            "[OTEL-CONFIG] Metrics initialized: readers=%d, views=%d",
            len(readers),
            len(configured_views),
        )
        return provider

    except ImportError as exc:
        logger.warning("[OTEL-CONFIG] opentelemetry metrics not available: %s", exc)
        return None


# ── SUPERMOC: Getter dla PrometheusExporter ──────────────────────────────


def get_prometheus_exporter() -> Any | None:
    """SUPERMOC: Zwraca globalny PrometheusMetricsExporter.

    Używany przez routes/metrics.py do generowania tekstu metryk
    przez publiczne API to_text().

    Returns:
        PrometheusMetricsExporter lub None jeśli nie zainicjalizowany.
    """
    return _prometheus_exporter_ref


# ── SUPERMOC: Graceful Shutdown (przez atexit) ───────────────────────────

# Globalne referencje do providerów — ustawiane po inicjalizacji
_tracer_provider_ref: Any = None
_meter_provider_ref: Any = None
_logger_provider_ref: Any = None

# SUPERMOC: Globalna referencja do PrometheusMetricsExporter
# Używana przez routes/metrics.py do generowania tekstu metryk
# bez konieczności dostępu do prywatnych atrybutów MeterProvider
_prometheus_exporter_ref: Any = None


def _otel_atexit_shutdown() -> None:
    """SUPERMOC: Graceful shutdown wszystkich OTel providerów przy atexit.

    Używa globalnych referencji (ustawionych przez register_otel_shutdown).
    """
    if _tracer_provider_ref is not None:
        try:
            _tracer_provider_ref.shutdown()
            logger.debug("[OTEL-CONFIG] TracerProvider shut down")
        except Exception as exc:
            logger.debug("[OTEL-CONFIG] TracerProvider shutdown error: %s", exc)
    if _meter_provider_ref is not None:
        try:
            _meter_provider_ref.shutdown()
            logger.debug("[OTEL-CONFIG] MeterProvider shut down")
        except Exception as exc:
            logger.debug("[OTEL-CONFIG] MeterProvider shutdown error: %s", exc)
    if _logger_provider_ref is not None:
        try:
            _logger_provider_ref.shutdown()
            logger.debug("[OTEL-CONFIG] LoggerProvider shut down")
        except Exception as exc:
            logger.debug("[OTEL-CONFIG] LoggerProvider shutdown error: %s", exc)


def register_otel_shutdown(
    tracer_provider: Any | None = None,
    meter_provider: Any | None = None,
    logger_provider: Any | None = None,
) -> None:
    """SUPERMOC: Rejestruje atexit handler dla graceful shutdown providerów.

    Zapisuje referencje do globalnych zmiennych (nie closure),
    aby atexit handler miał dostęp w momencie shutdownu.

    Args:
        tracer_provider: TracerProvider do zamknięcia.
        meter_provider: MeterProvider do zamknięcia.
        logger_provider: LoggerProvider do zamknięcia.
    """
    global _tracer_provider_ref, _meter_provider_ref, _logger_provider_ref

    if tracer_provider is not None:
        _tracer_provider_ref = tracer_provider
    if meter_provider is not None:
        _meter_provider_ref = meter_provider
    if logger_provider is not None:
        _logger_provider_ref = logger_provider

    atexit.register(_otel_atexit_shutdown)
    logger.debug("[OTEL-CONFIG] Atexit shutdown handler registered")
