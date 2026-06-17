# API/routes/metrics_debug.py
"""
SUPERMOC: Debug endpoint dla OpenTelemetry Prometheus metryk.

Zgodnie z aa3fvcx.txt: dedykowany endpoint diagnostyczny do podglądu
na żywo surowych danych telemetrycznych OTel.

Różnica od /metrics (Prometheus):
  - /metrics: sformatowany dla Prometheus scrapera (cumulative, z prefixem)
  - /debug/metrics: nieprzetworzone dane z API OTel (raw instruments, readers)
"""

from __future__ import annotations

import time

from litestar import Controller, get

from nexus_ai.api.dto import TAG_SYSTEM


class MetricsDebugController(Controller):
    """SUPERMOC: Debug endpoint dla podglądu metryk OTel na żywo.

    Umożliwia diagnostykę bez konieczności scrapowania przez Prometheus:
    - Lista zarejestrowanych instrumentów (Counter, Histogram, Gauge)
    - Status eksporterów (Prometheus, OTLP)
    - Stan MeterProvider (readers, views)
    - Timestamp ostatniej kolekcji

    Uwaga: Używa SDK internals (_sdk_meters, _sdk_metric_readers) —
    to akceptowalne dla endpointu debug, ale nie do kodu produkcyjnego.
    """

    path = "/debug/metrics"
    tags = [TAG_SYSTEM]

    @get(
        summary="Debug OTel metrics status",
        description="Returns raw OTel metrics diagnostic info (not Prometheus format)",
        operation_id="getDebugMetrics",
    )
    async def debug_metrics(self) -> dict:
        """SUPERMOC: Zwraca diagnostykę OTel Metrics na żywo.

        Returns:
            Dict z diagnostyką: providers, instruments, exporters, views.
        """
        from opentelemetry import metrics as otel_metrics
        from opentelemetry.sdk.metrics import MeterProvider

        provider = otel_metrics.get_meter_provider()
        result: dict = {
            "timestamp": time.time(),
            "provider_type": type(provider).__name__,
            "meters": [],
            "exporters": [],
            "readers": [],
            "views": [],
            "status": "active" if isinstance(provider, MeterProvider) else "noop",
        }

        if not isinstance(provider, MeterProvider):
            result["note"] = "No SDK MeterProvider configured — using no-op"
            return result

        # ── Lista metrów ────────────────────────────────────────────────
        try:
            # SUPERMOC: MeterProvider przechowuje listę SDK Meterów
            for meter in getattr(provider, "_sdk_meters", []):
                instruments = []
                for instrument in getattr(meter, "_instruments", []):
                    instruments.append(
                        {
                            "name": getattr(instrument, "name", "?"),
                            "kind": type(instrument).__name__,
                            "description": getattr(instrument, "description", ""),
                            "unit": getattr(instrument, "unit", ""),
                        }
                    )
                result["meters"].append(
                    {
                        "name": getattr(meter, "name", "?"),
                        "version": getattr(meter, "version", "?"),
                        "instruments": instruments,
                    }
                )
        except Exception:
            pass

        # ── Lista readerów ──────────────────────────────────────────────
        for reader in getattr(provider, "_sdk_metric_readers", []):
            reader_info: dict = {
                "type": type(reader).__name__,
            }
            # Sprawdź czy to PeriodicExportingMetricReader z Prometheus
            exporter = getattr(reader, "_collector", None)
            if exporter:
                inner_exporter = getattr(exporter, "_exporter", None)
                if inner_exporter:
                    reader_info["exporter"] = type(inner_exporter).__name__

            temp = getattr(reader, "_temporality", None)
            if temp:
                reader_info["default_temporality"] = str(temp)

            result["readers"].append(reader_info)

        # ── Lista widoków (Views) ────────────────────────────────────────
        for view in getattr(provider, "_sdk_views", []):
            view_info = {
                "instrument_name": getattr(view, "instrument_name", None),
                "aggregation": type(getattr(view, "aggregation", None)).__name__
                if getattr(view, "aggregation", None)
                else "default",
            }
            result["views"].append(view_info)

        return result
