# API/routes/metrics.py
"""
Public endpoint exposing Prometheus metrics for scraping.

This controller has NO authentication guards so that Prometheus
can scrape it without requiring a JWT token.

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


class MetricsController(Controller):
    """Prometheus metrics exposition endpoint (no auth required)."""

    path = "/metrics"

    @get()
    async def prometheus_metrics(self) -> str:
        """Return Prometheus metrics in text exposition format."""
        try:
            from prometheus_client import generate_latest, REGISTRY
            return generate_latest(REGISTRY).decode("utf-8")
        except ImportError:
            return "# Metrics not available - prometheus_client not installed"
        except Exception as exc:
            return f"# Metrics error: {exc}"
