"""Integrity Health Check — cykliczny weryfikator integralności łańcucha hashy.

v7.0 AUDIT (Raport TigerBeetle Shadow Ledger, sekcja 3.4):
  "Brak automatycznego health check"

Ten moduł implementuje:
- Cykliczną weryfikację proof chain co 60 sekund
- Automatyczne alerty przy naruszeniu integralności
- System lock (read-only mode) przy krytycznych naruszeniach
- Dashboard-ready health status
"""

from __future__ import annotations

import asyncio
import time
from dataclasses import dataclass, field
from typing import final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.integrity.health")


# ── Konfiguracja ──────────────────────────────────────────────────────────

DEFAULT_CHECK_INTERVAL_SECONDS: float = 60.0
MAX_CONSECUTIVE_FAILURES: int = 3


@dataclass
class HealthCheckResult:
    """Wynik pojedynczego health checku."""

    timestamp: str
    status: str  # "healthy", "violation", "error"
    total_decisions: int = 0
    violations_count: int = 0
    check_duration_ms: float = 0.0
    message: str = ""


@dataclass
class HealthStatus:
    """Zagregowany status health checków."""

    is_healthy: bool = True
    last_check: HealthCheckResult | None = None
    consecutive_failures: int = 0
    system_locked: bool = False
    checks_run: int = 0
    violations_total: int = 0
    history: list[HealthCheckResult] = field(default_factory=list)
    started_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())


@final
class IntegrityHealthChecker:
    """Cykliczny weryfikator integralności księgowej.

    v7.0 AUDIT: Automatyczny health check co 60s.
    Wykrywa naruszenia proof chain i automatycznie blokuje system.

    Usage:
        checker = IntegrityHealthChecker(verifier, nats_client)
        await checker.start()  # uruchamia pętlę w tle
        status = checker.status  # bieżący status
    """

    def __init__(
        self,
        verifier,  # IntegrityVerifier
        *,
        nats_client=None,
        check_interval: float = DEFAULT_CHECK_INTERVAL_SECONDS,
        auto_lock: bool = True,
    ) -> None:
        self._verifier = verifier
        self._nats = nats_client
        self._interval = check_interval
        self._auto_lock = auto_lock
        self._running = False
        self._task: asyncio.Task | None = None
        self._status = HealthStatus()

    # ── Public API ──────────────────────────────────────────────────────

    @property
    def status(self) -> HealthStatus:
        """Bieżący status health checku."""
        return self._status

    @property
    def is_running(self) -> bool:
        return self._running

    async def start(self) -> None:
        """Uruchom cykliczny health check w tle."""
        if self._running:
            logger.warning("[INTEGRITY-HEALTH] Already running")
            return

        self._running = True
        self._task = asyncio.create_task(self._run_loop())
        logger.info(
            "[INTEGRITY-HEALTH] Started — interval=%.0fs, auto_lock=%s",
            self._interval,
            self._auto_lock,
        )

    async def stop(self) -> None:
        """Zatrzymaj cykliczny health check."""
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
            self._task = None
        logger.info("[INTEGRITY-HEALTH] Stopped — checks_run=%d", self._status.checks_run)

    async def run_once(self) -> HealthCheckResult:
        """Wykonaj pojedynczy health check (na żądanie)."""
        return await self._perform_check()

    # ── Internal ────────────────────────────────────────────────────────

    async def _run_loop(self) -> None:
        """Główna pętla health checku."""
        while self._running:
            try:
                result = await self._perform_check()
                self._process_result(result)
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.error("[INTEGRITY-HEALTH] Check failed: %s", exc)
                self._status.consecutive_failures += 1

            await asyncio.sleep(self._interval)

    async def _perform_check(self) -> HealthCheckResult:
        """Wykonaj pojedynczą weryfikację integralności."""
        t_start = time.monotonic()

        try:
            report = self._verifier.verify_all()
            t_end = time.monotonic()
            duration_ms = (t_end - t_start) * 1000

            if report.status == "violation":
                return HealthCheckResult(
                    timestamp=pendulum.now("UTC").isoformat(),
                    status="violation",
                    total_decisions=report.total_records,
                    violations_count=len(report.violations),
                    check_duration_ms=round(duration_ms, 2),
                    message=f"INTEGRITY VIOLATION: {len(report.violations)} issues detected",
                )
            else:
                return HealthCheckResult(
                    timestamp=pendulum.now("UTC").isoformat(),
                    status="healthy",
                    total_decisions=report.total_records,
                    violations_count=0,
                    check_duration_ms=round(duration_ms, 2),
                    message=f"Chain intact: {report.total_records} decisions verified",
                )

        except Exception as exc:
            t_end = time.monotonic()
            duration_ms = (t_end - t_start) * 1000
            return HealthCheckResult(
                timestamp=pendulum.now("UTC").isoformat(),
                status="error",
                check_duration_ms=round(duration_ms, 2),
                message=f"Check error: {exc}",
            )

    def _process_result(self, result: HealthCheckResult) -> None:
        """Przetwórz wynik health checku."""
        self._status.last_check = result
        self._status.checks_run += 1
        self._status.history.append(result)

        # Trim history do ostatnich 100 wpisów
        if len(self._status.history) > 100:
            self._status.history = self._status.history[-100:]

        if result.status == "healthy":
            self._status.is_healthy = True
            self._status.consecutive_failures = 0

        elif result.status == "violation":
            self._status.is_healthy = False
            self._status.consecutive_failures += 1
            self._status.violations_total += result.violations_count

            logger.critical(
                "[INTEGRITY-HEALTH] VIOLATION DETECTED — decisions=%d, violations=%d",
                result.total_decisions,
                result.violations_count,
            )

            # Auto-lock systemu po MAX_CONSECUTIVE_FAILURES
            if (
                self._auto_lock
                and self._status.consecutive_failures >= MAX_CONSECUTIVE_FAILURES
                and not self._status.system_locked
            ):
                self._lock_system()
                self._status.system_locked = True

            # Emituj alert NATS
            if self._nats and self._nats.is_connected:
                self._emit_alert(result)

        elif result.status == "error":
            self._status.consecutive_failures += 1
            logger.warning(
                "[INTEGRITY-HEALTH] Check error: %s (failures=%d)",
                result.message,
                self._status.consecutive_failures,
            )

    def _lock_system(self) -> None:
        """Zablokuj system w tryb read-only."""
        try:
            self._verifier.system_lock(lock=True)
            logger.critical(
                "[INTEGRITY-HEALTH] SYSTEM LOCKED — read-only mode after %d consecutive violations",
                MAX_CONSECUTIVE_FAILURES,
            )
        except Exception as exc:
            logger.error("[INTEGRITY-HEALTH] Failed to lock system: %s", exc)

    def _emit_alert(self, result: HealthCheckResult) -> None:
        """Emituj alert przez NATS."""
        if not self._nats:
            return
        try:
            import json

            alert_payload = {
                "type": "integrity_violation",
                "timestamp": result.timestamp,
                "total_decisions": result.total_decisions,
                "violations_count": result.violations_count,
                "message": result.message,
            }
            # Fire-and-forget — nie blokujemy health checku
            asyncio.create_task(
                self._nats.publish(
                    "nexus.integrity.violation",
                    json.dumps(alert_payload).encode(),
                )
            )
        except Exception as exc:
            logger.debug("[INTEGRITY-HEALTH] NATS alert failed (non-critical): %s", exc)

    def get_health_report(self) -> dict:
        """Wygeneruj raport health do dashboardu."""
        s = self._status
        last = s.last_check
        return {
            "is_healthy": s.is_healthy,
            "system_locked": s.system_locked,
            "checks_run": s.checks_run,
            "consecutive_failures": s.consecutive_failures,
            "violations_total": s.violations_total,
            "started_at": s.started_at,
            "last_check": {
                "timestamp": last.timestamp if last else None,
                "status": last.status if last else "unknown",
                "total_decisions": last.total_decisions if last else 0,
                "duration_ms": last.check_duration_ms if last else 0,
                "message": last.message if last else "",
            } if last else None,
        }
