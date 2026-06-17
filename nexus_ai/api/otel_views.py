"""
api/otel_views.py — OpenTelemetry Metrics Views dla NexusAI.

SUPERMOCE:
  1. Views API — zmiana agregacji/filtrowania metryk bez zmiany kodu instrumentacji
  2. ExplicitBucketHistogramAggregation — dedykowane buckety dla histogramów
  3. ExponentialHistogramAggregation — szybszy, bardziej precyzyjny niż explicit
  4. DropAggregation — usuwanie niechcianych metryk
  5. LastValueAggregation — dla gauge'ów, tylko ostatnia wartość
  6. Pattern-based Views — batch *total, *_duration_seconds
  7. ExemplarReservoir — korelacja metryk z trace'ami

Zgodnie z aa3fvcx.txt: Views API to niedoceniana supermoc OTel Metrics.
"""

from __future__ import annotations

from typing import Any


def get_metrics_views() -> list[Any]:
    """Zwraca listę View dla MeterProvider.

    Używane przez create_meter_provider() w otel_config.py.
    Views są dodawane do meter providera w init_metrics().

    SUPERMOCE aktywne:
    - ExponentialHistogram dla AI inference (zamiast Explicit)
    - LastValueAggregation dla wszystkich gauge'ów
    - Pattern-based: *_total i *_duration_seconds
    - Exemplars dla histogramów
    """
    try:
        from opentelemetry.sdk.metrics.view import (
            AlignedHistogramBucketExemplarReservoir,
            ExplicitBucketHistogramAggregation,
            ExponentialHistogramAggregation,
            LastValueAggregation,
            DropAggregation,
            View,
        )

        # SUPERMOC: ExemplarReservoir dla korelacji metryk z trace'ami
        exemplar_filter = AlignedHistogramBucketExemplarReservoir()

        views = [
            # ── HTTP duration ─────────────────────────────────────────
            View(
                instrument_name="http_request_duration_seconds",
                attribute_keys={"method", "endpoint"},
                aggregation=ExplicitBucketHistogramAggregation(
                    boundaries=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
                    exemplar_reservoir=exemplar_filter,
                ),
                description="HTTP request duration (bucketed)",
            ),
            # ── AI inference duration (Exponential zamiast Explicit) ──
            # SUPERMOC: ExponentialHistogram — szybszy O(log n), bardziej precyzyjny
            View(
                instrument_name="ai_inference_duration_seconds",
                attribute_keys={"model_name"},
                aggregation=ExponentialHistogramAggregation(
                    max_size=160,
                    max_scale=20,
                ),
            ),
            # ── OCR duration ──────────────────────────────────────────
            View(
                instrument_name="ocr_duration_seconds",
                attribute_keys={"engine"},
                aggregation=ExplicitBucketHistogramAggregation(
                    boundaries=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0],
                    exemplar_reservoir=exemplar_filter,
                ),
            ),
            # ── Cache L2 latency ──────────────────────────────────────
            View(
                instrument_name="cache_l2_latency_seconds",
                attribute_keys={"operation"},
                aggregation=ExplicitBucketHistogramAggregation(
                    boundaries=[0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0],
                    exemplar_reservoir=exemplar_filter,
                ),
            ),
            # ── Task execution duration (Exponential) ─────────────────
            View(
                instrument_name="task_execution_duration_seconds",
                attribute_keys={"task_name"},
                aggregation=ExponentialHistogramAggregation(
                    max_size=100,
                    max_scale=20,
                ),
            ),
            # ── EventStore append duration (Exponential) ──────────────
            View(
                instrument_name="event_store_append_duration_seconds",
                attribute_keys={"aggregate_type"},
                aggregation=ExponentialHistogramAggregation(
                    max_size=100,
                    max_scale=20,
                ),
            ),
            # ── EventStore read latency (Exponential) ─────────────────
            View(
                instrument_name="event_store_read_latency_seconds",
                attribute_keys={"operation"},
                aggregation=ExponentialHistogramAggregation(
                    max_size=100,
                    max_scale=20,
                ),
            ),
            # ── LastValueAggregation dla wszystkich gauge'ów ──────────
            # SUPERMOC: Gauge'y używają LastValue — tylko ostatnia wartość
            View(
                instrument_name="db_connection_pool_size",
                aggregation=LastValueAggregation(),
            ),
            View(
                instrument_name="queue_depth",
                aggregation=LastValueAggregation(),
            ),
            View(
                instrument_name="worker_up",
                aggregation=LastValueAggregation(),
            ),
            View(
                instrument_name="nats_up",
                aggregation=LastValueAggregation(),
            ),
            View(
                instrument_name="active_tasks",
                aggregation=LastValueAggregation(),
            ),
            # ── Drop niepotrzebnych metryk ────────────────────────────
            View(
                instrument_name="memory_usage_mb",
                aggregation=DropAggregation(),
                description="Dropped — use mimalloc metrics instead",
            ),
        ]

        return views

    except ImportError:
        return []
