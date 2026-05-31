# api/metrics_middleware.py
"""
Litestar middleware for recording HTTP request metrics (Prometheus).

Records:
  - http_requests_total (counter with method, endpoint, status labels)
  - http_request_duration_seconds (histogram)
  - http_requests_in_flight (gauge, incremented/decremented per request)

Used together with ``api.state._init_otel_metrics()`` on the API process.
"""
from __future__ import annotations

import time
from litestar.middleware import AbstractMiddleware

from core.logger import logger


class MetricsMiddleware(AbstractMiddleware):
    """Records HTTP request metrics for Prometheus exposition."""

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        # ── Import metrics lazily (no import-time side effects) ─────────
        from api.telemetry_metrics import (
            http_requests_total,
            http_request_duration_seconds,
            http_requests_in_flight,
        )

        method = scope.get("method", "UNKNOWN")
        path = scope.get("path", "/unknown")

        # Normalize endpoint to avoid label explosion (e.g., /api/v1/invoices/123 -> /api/v1/invoices/{id})
        endpoint = _normalize_path(path)

        started = time.perf_counter()

        # Increment in-flight gauge
        if http_requests_in_flight is not None:
            http_requests_in_flight.inc()

        try:
            # Intercept response to capture status code
            status_code = 200  # default

            async def send_wrapper(message):
                nonlocal status_code
                if message["type"] == "http.response.start":
                    status_code = message.get("status", 200)
                await send(message)

            await self.app(scope, receive, send_wrapper)
        finally:
            duration = time.perf_counter() - started

            # Decrement in-flight gauge
            if http_requests_in_flight is not None:
                http_requests_in_flight.dec()

            # Record metrics
            if http_requests_total is not None:
                try:
                    http_requests_total.labels(
                        method=method,
                        endpoint=endpoint,
                        status=str(status_code),
                    ).inc()
                except Exception:
                    pass

            if http_request_duration_seconds is not None:
                try:
                    http_request_duration_seconds.labels(
                        method=method,
                        endpoint=endpoint,
                    ).observe(duration)
                except Exception:
                    pass


def _normalize_path(path: str) -> str:
    """Normalize dynamic path segments to reduce Prometheus label cardinality.

    Replaces UUIDs, integers, hex IDs with ``{param}`` placeholders.
    """
    import re

    # Replace UUIDs
    path = re.sub(
        r"/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
        "/{uuid}",
        path,
    )
    # Replace long hex strings (24+ chars)
    path = re.sub(r"/[0-9a-f]{24,}", "/{id}", path)
    # Replace integers (but not after /api/v)
    path = re.sub(r"(?<=/)(\d{4,})(?=/|$)", "{id}", path)
    return path
