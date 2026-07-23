"""
v7.0 INNOWACJA 9: Integration Health Dashboard — Kokpit Zdrowia Integracji.

Panel w UI pokazujący w czasie rzeczywistym:
- Status każdej integracji (online/offline/degraded)
- Circuit breaker state (closed/open/half-open)
- Średni czas odpowiedzi (p50, p95, p99)
- Liczbę udanych/nieudanych zapytań w ciągu 24h
- Przewidywany czas naprawy (na podstawie historycznych awarii)
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.ui.integration_health")


# ── Data Models ──────────────────────────────────────────────────────────────

@dataclass
class IntegrationStatus:
    """Status pojedynczej integracji."""
    name: str
    display_name: str
    status: str  # online, degraded, offline
    circuit_breaker: str  # closed, open, half-open
    avg_response_ms: float
    p50_ms: float
    p95_ms: float
    p99_ms: float
    requests_24h: int
    failures_24h: int
    success_rate_pct: float
    last_checked: float
    estimated_recovery_minutes: float = 0.0
    icon: str = "cloud"  # cloud, cloud_off, cloud_done, warning


@dataclass
class IntegrationHealthSnapshot:
    """Migawka stanu wszystkich integracji."""
    timestamp: float
    integrations: list[IntegrationStatus]
    overall_status: str  # all_healthy, some_degraded, critical_failure
    overall_uptime_pct: float


# ── Health Check Engine ──────────────────────────────────────────────────────

class IntegrationHealthChecker:
    """v7.0: Silnik monitorowania zdrowia integracji zewnętrznych.

    Cyklicznie sprawdza dostępność każdej integracji i śledzi metryki.
    """

    # v7.0: Różne timeouty per integracja (LUKA 13)
    HEALTH_CHECK_CONFIG: dict[str, dict[str, Any]] = {
        "ksef": {
            "display_name": "KSeF (MF)",
            "check_interval": 120,
            "endpoint": "https://ksef-test.mf.gov.pl/api/online/Status",
            "timeout": 5.0,
            "icon": "description",  # faktury
        },
        "gus_bir": {
            "display_name": "GUS BIR",
            "check_interval": 300,
            "endpoint": "https://wyszukiwarkaregon.stat.gov.pl/wsBIR/UslugaBIRzewnPubl.svc",
            "timeout": 15.0,
            "icon": "business",
        },
        "white_list": {
            "display_name": "Biała Lista MF",
            "check_interval": 120,
            "endpoint": "https://wl-api.mf.gov.pl/api/check/nip/5261040567",
            "timeout": 5.0,
            "icon": "verified",
        },
        "nbp": {
            "display_name": "NBP API",
            "check_interval": 300,
            "endpoint": "https://api.nbp.pl/api/exchangerates/rates/A/EUR/?format=json",
            "timeout": 5.0,
            "icon": "euro",
        },
        "ecb": {
            "display_name": "ECB Fallback",
            "check_interval": 600,
            "endpoint": "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml",
            "timeout": 10.0,
            "icon": "currency_exchange",
        },
        "vendor_intel": {
            "display_name": "Vendor Intelligence",
            "check_interval": 3600,
            "endpoint": None,  # Lokalny serwis
            "timeout": 2.0,
            "icon": "analytics",
        },
    }

    def __init__(self, http_client: Any = None) -> None:
        self._http = http_client
        self._statuses: dict[str, IntegrationStatus] = {}
        self._history: dict[str, list[dict[str, Any]]] = {}
        # Inicjalizuj domyślne statusy
        for name, config in self.HEALTH_CHECK_CONFIG.items():
            self._statuses[name] = IntegrationStatus(
                name=name,
                display_name=config["display_name"],
                status="unknown",
                circuit_breaker="unknown",
                avg_response_ms=0,
                p50_ms=0,
                p95_ms=0,
                p99_ms=0,
                requests_24h=0,
                failures_24h=0,
                success_rate_pct=100.0,
                last_checked=time.time(),
                icon=config["icon"],
            )
            self._history[name] = []

    async def check_all(self) -> IntegrationHealthSnapshot:
        """Sprawdź stan wszystkich integracji."""
        import asyncio
        tasks = [
            self._check_single(name, config)
            for name, config in self.HEALTH_CHECK_CONFIG.items()
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        statuses: list[IntegrationStatus] = []
        for name, result in zip(self.HEALTH_CHECK_CONFIG.keys(), results):
            if isinstance(result, Exception):
                logger.warning("[HEALTH] Check failed for %s: %s", name, result)
                # Zachowaj poprzedni status
                if name in self._statuses:
                    statuses.append(self._statuses[name])
            else:
                statuses.append(result)

        # Określ ogólny status
        offline_count = sum(1 for s in statuses if s.status == "offline")
        degraded_count = sum(1 for s in statuses if s.status == "degraded")

        if offline_count > 1:
            overall = "critical_failure"
        elif degraded_count > 0 or offline_count > 0:
            overall = "some_degraded"
        else:
            overall = "all_healthy"

        uptime = sum(s.success_rate_pct for s in statuses) / max(len(statuses), 1)

        return IntegrationHealthSnapshot(
            timestamp=time.time(),
            integrations=statuses,
            overall_status=overall,
            overall_uptime_pct=round(uptime, 1),
        )

    async def _check_single(
        self, name: str, config: dict[str, Any],
    ) -> IntegrationStatus:
        """Sprawdź stan pojedynczej integracji."""
        start = time.time()
        status = "online"
        response_ms = 0
        error = None

        if config["endpoint"] and self._http:
            try:
                response = await self._http.get(config["endpoint"])
                response_ms = (time.time() - start) * 1000
                if response.status_code >= 500:
                    status = "degraded"
                elif response.status_code >= 400:
                    status = "offline"
            except Exception as exc:
                response_ms = (time.time() - start) * 1000
                status = "offline"
                error = str(exc)
        else:
            # Lokalny serwis — zawsze online
            response_ms = 1.0
            status = "online"

        # Zapisz metrykę do historii
        entry = {
            "timestamp": time.time(),
            "status": status,
            "response_ms": response_ms,
            "error": error,
        }
        self._history[name].append(entry)

        # Ogranicz historię do 1000 wpisów
        if len(self._history[name]) > 1000:
            self._history[name] = self._history[name][-1000:]

        # Oblicz metryki
        recent = [e for e in self._history[name] if time.time() - e["timestamp"] < 86400]
        requests_24h = len(recent)
        failures_24h = sum(1 for e in recent if e["status"] == "offline")
        success_rate = ((requests_24h - failures_24h) / max(requests_24h, 1)) * 100

        response_times = sorted(
            [e["response_ms"] for e in recent if e["response_ms"] > 0]
        )
        p50 = response_times[len(response_times) // 2] if response_times else 0
        p95 = response_times[int(len(response_times) * 0.95)] if response_times else 0
        p99 = response_times[int(len(response_times) * 0.99)] if response_times else 0
        avg = sum(response_times) / max(len(response_times), 1) if response_times else 0

        # Szacuj czas naprawy na podstawie historycznych awarii
        recovery = self._estimate_recovery(name)

        # Circuit breaker state
        cb_state = "closed"
        if status == "offline" and failures_24h > 3:
            cb_state = "open"
        elif status == "online" and failures_24h > 0:
            cb_state = "half-open"

        result = IntegrationStatus(
            name=name,
            display_name=config["display_name"],
            status=status,
            circuit_breaker=cb_state,
            avg_response_ms=round(avg, 1),
            p50_ms=p50,
            p95_ms=p95,
            p99_ms=p99,
            requests_24h=requests_24h,
            failures_24h=failures_24h,
            success_rate_pct=round(success_rate, 1),
            last_checked=time.time(),
            estimated_recovery_minutes=round(recovery, 1),
            icon=config["icon"],
        )

        self._statuses[name] = result
        return result

    def _estimate_recovery(self, name: str) -> float:
        """Szacuj czas naprawy na podstawie historycznych awarii."""
        history = self._history.get(name, [])
        downtimes: list[float] = []
        downtime_start: float | None = None

        for entry in history:
            if entry["status"] == "offline" and downtime_start is None:
                downtime_start = entry["timestamp"]
            elif entry["status"] != "offline" and downtime_start is not None:
                duration = entry["timestamp"] - downtime_start
                downtimes.append(duration / 60)  # minuty
                downtime_start = None

        if not downtimes:
            return 5.0  # Domyślnie 5 minut

        return sum(downtimes) / len(downtimes)

    def get_status(self, name: str) -> IntegrationStatus | None:
        """Pobierz status konkretnej integracji."""
        return self._statuses.get(name)

    def get_snapshot(self) -> IntegrationHealthSnapshot:
        """Pobierz ostatnią migawkę bez wykonywania checków."""
        statuses = list(self._statuses.values())
        offline = sum(1 for s in statuses if s.status == "offline")
        if offline > 1:
            overall = "critical_failure"
        elif offline > 0 or any(s.status == "degraded" for s in statuses):
            overall = "some_degraded"
        else:
            overall = "all_healthy"
        uptime = sum(s.success_rate_pct for s in statuses) / max(len(statuses), 1)
        return IntegrationHealthSnapshot(
            timestamp=time.time(),
            integrations=statuses,
            overall_status=overall,
            overall_uptime_pct=round(uptime, 1),
        )


# ── v7.0 Health Check endpoint helper ────────────────────────────────────────

async def get_integration_health_report(
    checker: IntegrationHealthChecker,
) -> dict[str, Any]:
    """Wygeneruj raport stanu integracji dla API endpointu."""
    snapshot = checker.get_snapshot()
    return {
        "status": snapshot.overall_status,
        "uptime_pct": snapshot.overall_uptime_pct,
        "timestamp": pendulum.from_timestamp(snapshot.timestamp).isoformat(),
        "integrations": [
            {
                "name": s.name,
                "display_name": s.display_name,
                "status": s.status,
                "circuit_breaker": s.circuit_breaker,
                "avg_response_ms": s.avg_response_ms,
                "p95_ms": s.p95_ms,
                "success_rate_pct": s.success_rate_pct,
                "estimated_recovery_min": s.estimated_recovery_minutes,
            }
            for s in snapshot.integrations
        ],
    }
