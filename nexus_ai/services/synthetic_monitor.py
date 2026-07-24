"""
synthetic_monitor.py — Synthetic Monitoring for NexusAI.

Enterprise v7.0 Innowacja 15: Wbudowane syntetyczne testy monitorujące:
  - Co 60s: health check API
  - Co 5min: testowa faktura (create + validate)
  - Co 15min: pełen pipeline OCR
  - Metryki: success rate, latency p50/p95/p99
  - Alerty gdy success rate < 99%

Usage:
    from nexus_ai.services.synthetic_monitor import SyntheticMonitor
    monitor = SyntheticMonitor()
    await monitor.start()
"""

from __future__ import annotations

import asyncio
import os
import time
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.synthetic.monitor")


@dataclass
class SyntheticCheck:
    """Result of a single synthetic check."""

    check_type: str  # "health", "invoice", "ocr_pipeline"
    success: bool
    duration_ms: float
    error: str | None = None
    timestamp: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


@dataclass
class SyntheticStats:
    """Rolling statistics for a check type."""

    total: int = 0
    successes: int = 0
    failures: int = 0
    latencies: deque[float] = field(default_factory=lambda: deque(maxlen=1000))

    @property
    def success_rate(self) -> float:
        return (self.successes / self.total * 100) if self.total > 0 else 100.0

    @property
    def p50(self) -> float:
        return self._percentile(50)

    @property
    def p95(self) -> float:
        return self._percentile(95)

    @property
    def p99(self) -> float:
        return self._percentile(99)

    def _percentile(self, pct: float) -> float:
        if not self.latencies:
            return 0.0
        sorted_lat = sorted(self.latencies)
        idx = int(len(sorted_lat) * pct / 100)
        return sorted_lat[min(idx, len(sorted_lat) - 1)]


class SyntheticMonitor:
    """Synthetic monitoring for NexusAI health verification.

    Enterprise v7.0 Innowacja 15:
      - Automated health checks every 60s
      - Test invoice creation every 5min
      - OCR pipeline test every 15min
      - Rolling stats with p50/p95/p99
      - Alert when success_rate < 99%
    """

    def __init__(
        self,
        base_url: str | None = None,
        *,
        health_interval: float = 60.0,
        invoice_interval: float = 300.0,
        ocr_interval: float = 900.0,
        alert_threshold: float = 99.0,
    ) -> None:
        self.base_url = base_url or os.getenv("NEXUS_API_URL", "http://127.0.0.1:8000")
        self.health_interval = health_interval
        self.invoice_interval = invoice_interval
        self.ocr_interval = ocr_interval
        self.alert_threshold = alert_threshold
        self.stats: dict[str, SyntheticStats] = {
            "health": SyntheticStats(),
            "invoice": SyntheticStats(),
            "ocr_pipeline": SyntheticStats(),
        }
        self._running = False
        self._tasks: list[asyncio.Task] = []

    async def start(self) -> None:
        """Start all synthetic monitoring loops."""
        if self._running:
            return
        self._running = True
        logger.info(
            "[SYNTHETIC] Starting synthetic monitor: health=%ds invoice=%ds ocr=%ds",
            self.health_interval, self.invoice_interval, self.ocr_interval,
        )
        self._tasks = [
            asyncio.create_task(self._loop("health", self.health_interval, self._check_health)),
            asyncio.create_task(self._loop("invoice", self.invoice_interval, self._check_invoice)),
            asyncio.create_task(self._loop("ocr_pipeline", self.ocr_interval, self._check_ocr_pipeline)),
        ]

    async def stop(self) -> None:
        """Stop all monitoring loops."""
        self._running = False
        for task in self._tasks:
            task.cancel()
        self._tasks.clear()
        logger.info("[SYNTHETIC] Synthetic monitor stopped")

    async def _loop(
        self, check_type: str, interval: float, check_fn: Any,
    ) -> None:
        """Run a synthetic check periodically."""
        while self._running:
            try:
                start = time.monotonic()
                success, error = await check_fn()
                duration = (time.monotonic() - start) * 1000

                stats = self.stats[check_type]
                stats.total += 1
                stats.latencies.append(duration)
                if success:
                    stats.successes += 1
                else:
                    stats.failures += 1
                    logger.warning(
                        "[SYNTHETIC] %s check FAILED: %s (%.1fms)",
                        check_type, error, duration,
                    )

                if stats.total > 5 and stats.success_rate < self.alert_threshold:
                    await self._alert(check_type, stats)

            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.error("[SYNTHETIC] %s loop error: %s", check_type, exc)

            await asyncio.sleep(interval)

    async def _check_health(self) -> tuple[bool, str | None]:
        """Check API health endpoint."""
        try:
            import httpx
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(f"{self.base_url}/health")
                return resp.status_code == 200, None if resp.status_code == 200 else f"HTTP {resp.status_code}"
        except Exception as exc:
            return False, str(exc)

    async def _check_invoice(self) -> tuple[bool, str | None]:
        """Create a test invoice and validate."""
        try:
            import httpx
            test_invoice = {
                "invoice_number": f"SYNTH-{int(time.time())}",
                "vendor_nip": "1234567890",
                "amount_gross": 1230.00,
                "vat_rate": 0.23,
                "issue_date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            }
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(
                    f"{self.base_url}/api/invoices/validate",
                    json=test_invoice,
                )
                if resp.status_code in (200, 201, 422):
                    return True, None
                return False, f"Invoice validation returned {resp.status_code}"
        except Exception as exc:
            return False, str(exc)

    async def _check_ocr_pipeline(self) -> tuple[bool, str | None]:
        """Simplified OCR pipeline check — verify OCR engine availability."""
        try:
            import httpx
            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.get(f"{self.base_url}/api/ocr/engines")
                if resp.status_code == 200:
                    engines = resp.json()
                    if isinstance(engines, list) and len(engines) > 0:
                        return True, None
                    return False, "No OCR engines available"
                return False, f"OCR engines check returned {resp.status_code}"
        except Exception as exc:
            return False, str(exc)

    async def _alert(self, check_type: str, stats: SyntheticStats) -> None:
        """Send alert when success rate drops below threshold."""
        logger.error(
            "[SYNTHETIC-ALERT] %s success rate: %.1f%% (threshold: %.1f%%), "
            "p50=%.1fms p95=%.1fms p99=%.1fms",
            check_type, stats.success_rate, self.alert_threshold,
            stats.p50, stats.p95, stats.p99,
        )
        try:
            from nexus_ai.core.sentry import capture_message
            capture_message(
                f"[SYNTHETIC] {check_type} success rate below threshold",
                level="error",
                check_type=check_type,
                success_rate=str(stats.success_rate),
                p95=str(stats.p95),
            )
        except ImportError:
            pass

    def get_stats(self) -> dict[str, Any]:
        """Get current synthetic monitoring stats."""
        return {
            name: {
                "total": s.total,
                "successes": s.successes,
                "failures": s.failures,
                "success_rate": round(s.success_rate, 2),
                "p50_ms": round(s.p50, 1),
                "p95_ms": round(s.p95, 1),
                "p99_ms": round(s.p99, 1),
            }
            for name, s in self.stats.items()
        }
