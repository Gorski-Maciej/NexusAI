# API/routes/metrics.py
"""
Public endpoint exposing Prometheus metrics for scraping via OpenTelemetry.

Zastępuje: prometheus_client (bezpośrednia zależność)
Nowy:      OpenTelemetry Metrics SDK + PrometheusExporter

Zgodnie z aa3fvcx.txt:
- OpenTelemetry Prometheus Exporter — lekki most do ekosystemu Prometheus
- Endpoint /metrics dla scrapowania przez Prometheus/Grafana

Usage in prometheus.yml:
  scrape_configs:
    - job_name: "nexus_api"
      scrape_interval: 15s
      metrics_path: "/metrics"
      static_configs:
        - targets: ["localhost:8000"]
"""

from __future__ import annotations

from litestar import Controller, get
from opentelemetry import metrics
from opentelemetry.exporter.prometheus import PrometheusMetricsExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader


# Globalny eksporter Prometheus — inicjalizowany raz
_exporter: PrometheusMetricsExporter | None = None
_initialized = False


def _ensure_otel_prometheus() -> None:
    """Lazy-init the OTel Prometheus exporter once using proper OTel SDK API.

    PrometheusMetricsExporter collects metrics from the MeterProvider
    and makes them available via its internal registry in text format.
    """
    global _exporter, _initialized
    if _initialized:
        return
    try:
        exporter = PrometheusMetricsExporter()
        reader = PeriodicExportingMetricReader(exporter, export_interval_ms=5000)
        provider = MeterProvider(metric_readers=[reader])
        metrics.set_meter_provider(provider)
        _exporter = exporter
        _initialized = True
    except Exception as exc:
        _initialized = True
        raise exc


class MetricsController(Controller):
    """Prometheus metrics exposition endpoint via OpenTelemetry (no auth required)."""

    path = "/metrics"

    @get()
    async def prometheus_metrics(self) -> str:
        """Return Prometheus metrics in text exposition format via OTel."""
        global _exporter, _initialized
        try:
            if not _initialized:
                _ensure_otel_prometheus()
            if _exporter is None:
                return "# Metrics not available - OpenTelemetry Prometheus exporter not configured"
            # Export current metrics to Prometheus text format.
            # The OTel PrometheusExporter stores metrics in an internal registry
            # that can be scraped. We trigger a collection and return the text.
            metrics_text = _exporter._collect()  # noqa: SLF001  # internal API for sync collection
            if metrics_text:
                return metrics_text.decode("utf-8") if isinstance(metrics_text, bytes) else str(metrics_text)
            return "# No metrics collected yet"
        except ImportError as e:
            return f"# Metrics not available - opentelemetry-prometheus-exporter not installed: {e}"
        except AttributeError:
            # Fallback: use the exporter's string representation
            try:
                from io import StringIO
                buf = StringIO()
                _exporter._registry.write_to_file(buf) if _exporter and hasattr(_exporter, '_registry') else None  # noqa: SLF001
                return buf.getvalue() if buf else "# Cannot generate metrics"
            except Exception:
                return "# Metrics endpoint: OpenTelemetry Prometheus exporter initialized but cannot generate output in this runtime"
        except Exception as exc:
            return f"# Metrics error: {exc}"
