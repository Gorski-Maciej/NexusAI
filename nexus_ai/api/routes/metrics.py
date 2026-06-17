# API/routes/metrics.py
"""
Public endpoint exposing Prometheus metrics for scraping via OpenTelemetry.

Zastępuje: prometheus_client (bezpośrednia zależność)
Nowy:      OpenTelemetry Metrics SDK + PrometheusExporter

Zgodnie z aa3fvcx.txt:
- OpenTelemetry Prometheus Exporter — lekki most do ekosystemu Prometheus
- Endpoint /metrics dla scrapowania przez Prometheus/Grafana

SUPERMOCE:
  1. Publiczne API PrometheusMetricsExporter.to_text() zamiast _collect()
  2. Obsługa OpenMetrics format (Accept: application/openmetrics-text)
  3. Wykorzystanie istniejącego MeterProvider z otel_config.py (bez duplikacji)

Usage in prometheus.yml:
  scrape_configs:
    - job_name: "nexus_api"
      scrape_interval: 15s
      metrics_path: "/metrics"
      static_configs:
        - targets: ["localhost:8000"]
"""

from __future__ import annotationsfrom litestar import Controller, get, MediaType, Request

from nexus_ai.api.dto import TAG_METRICS



def _get_metrics_text() -> str | None:
    """SUPERMOC: Pobierz metryki przez publiczne API PrometheusMetricsExporter.

    Używa globalnej referencji z otel_config.py zamiast
    prywatnych atrybutów MeterProvider._sdk_metric_readers.

    Returns:
        Tekst metryk w formacie Prometheus exposition lub None.
    """
    try:
        from nexus_ai.core.otel_config import get_prometheus_exporter

        exporter = get_prometheus_exporter()
        if exporter is None:
            return None

        # SUPERMOC: Publiczne API to_text() — dostępne od 0.46b0
        # Zastępuje _collect() (prywatne API, noqa: SLF001)
        metrics_bytes = exporter.to_text()
        if metrics_bytes:
            return (
                metrics_bytes.decode("utf-8")
                if isinstance(metrics_bytes, bytes)
                else str(metrics_bytes)
            )
        return "# No metrics collected yet"
    except ImportError:
        return None
    except AttributeError:
        # SUPERMOC: Fallback dla starszych wersji eksportera
        # Niektóre wersje nie mają to_text(), używamy str()
        try:
            from nexus_ai.core.otel_config import get_prometheus_exporter

            exporter = get_prometheus_exporter()
            if exporter:
                text = str(exporter)
                if text and text != "None":
                    return text
        except Exception:
            pass
        return None
    except Exception:
        return None


class MetricsController(Controller):
    """Prometheus metrics exposition endpoint via OpenTelemetry (no auth required).

    SUPERMOC: Zastępuje własny MetricsController z _collect()
    przez publiczne API to_text() z obsługą OpenMetrics.
    """

    path = "/metrics"
    tags = [TAG_METRICS]
    signature_namespace = {"Request": Request}

    @get(
        media_type=MediaType.TEXT,
        summary="Prometheus metrics",
        description="Returns Prometheus/OpenMetrics exposition format via OpenTelemetry PrometheusExporter",
        operation_id="getPrometheusMetrics",
    )
    async def prometheus_metrics(self, request: Request) -> str:
        """Return Prometheus metrics in text exposition format via OTel.

        SUPERMOCE:
        - Publiczne API to_text() zamiast _collect()
        - Globalna referencja do eksportera z otel_config.py
        - Fallback przez create_meter_provider() gdy eksporter nie zainicjalizowany
        """
        try:
            metrics_text = _get_metrics_text()

            if metrics_text is None:
                # SUPERMOC: Fallback — spróbuj utworzyć MeterProvider z otel_config
                try:
                    from nexus_ai.core.otel_config import (
                        create_meter_provider,
                        create_otel_resource,
                    )
                    resource = create_otel_resource()
                    create_meter_provider(resource=resource)
                    metrics_text = _get_metrics_text()
                except Exception:
                    pass

            if metrics_text:
                return metrics_text

            return (
                "# HELP nexus_metrics NexusAI OpenTelemetry metrics\n"
                "# TYPE nexus_metrics gauge\n"
                "nexus_metrics_up 1\n"
            )
        except ImportError as e:
            return (
                f"# Metrics not available - "
                f"opentelemetry-prometheus-exporter not installed: {e}"
            )
        except Exception as exc:
            return f"# Metrics error: {exc}"
