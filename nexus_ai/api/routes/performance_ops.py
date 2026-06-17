"""
SUPERMOC: Performance operations endpoint — Locust edition.

Zgodnie z aa3fvcx.txt: locust zastępuje k6.
Ten kontroler udostępnia wyniki testów wydajnościowych locust
przez REST API dla dashboardu i CI/CD.

SUPERMOCE:
  - LocustSummaryDTO — camelCase JSON API
  - Parsowanie JSON/CSV z locust
  - Wsparcie dla p95, p99, RPS, error rate
  - Integracja z health check
  - Tylko dla właściciela (owner_only_guard)
"""

from __future__ import annotations

import csv
from pathlib import Path

from litestar import Controller, get

from nexus_ai.api.dto import LocustSummaryDTO, TAG_SYSTEM
from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.core.msgspec_utils import msgspec_loads


def _parse_locust_csv_summary(summary_prefix: Path) -> dict | None:
    """SUPERMOC: Parsuj statystyki locust z pliku CSV.

    Locust generuje CSV z kolumnami:
      - Name, Request Count, Failure Count, Median Response Time,
        Average Response Time, Min Response Time, Max Response Time,
        Average Content Size, Requests/s, 50%, 66%, 75%, 80%, 90%,
        95%, 98%, 99%, 99.9%, 99.99%, 100%

    Returns:
        Dykt z zagregowanymi statystykami lub None jeśli brak pliku
    """
    csv_path = summary_prefix.with_suffix("_stats.csv")
    if not csv_path.exists():
        return None

    try:
        with open(csv_path, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            rows = []
            for row in reader:
                name = row.get("Name", "")
                if name and name != "Total":
                    rows.append(row)

            if not rows:
                return None

            # SUPERMOC: Agregacja statystyk
            p95_vals = []
            p99_vals = []
            avg_vals = []
            rps_vals = []
            total_requests = 0
            total_failures = 0

            for row in rows:
                try:
                    if row.get("95%"):
                        p95_vals.append(float(row["95%"]))
                    if row.get("99%"):
                        p99_vals.append(float(row["99%"]))
                    if row.get("Average Response Time"):
                        avg_vals.append(float(row["Average Response Time"]))
                    if row.get("Requests/s"):
                        rps_vals.append(float(row["Requests/s"]))
                    total_requests += int(row.get("Request Count", 0))
                    total_failures += int(row.get("Failure Count", 0))
                except (ValueError, KeyError):
                    continue

            if not p95_vals:
                return None

            fail_ratio = total_failures / max(total_requests, 1)

            return {
                "summary_available": True,
                "p95_ms": max(p95_vals),
                "p99_ms": max(p99_vals) if p99_vals else None,
                "check_failures": fail_ratio,
                "avg_response_time_ms": sum(avg_vals) / len(avg_vals) if avg_vals else None,
                "current_rps": sum(rps_vals) if rps_vals else None,
                "total_requests": total_requests,
                "total_failures": total_failures,
            }

    except Exception:
        return None


def _parse_locust_json_summary(json_path: Path) -> dict | None:
    """SUPERMOC: Parsuj statystyki locust z pliku JSON.

    Locust --json generuje JSON z metrykami per-endpoint.
    """
    if not json_path.exists():
        return None

    try:
        payload = msgspec_loads(json_path.read_bytes())
        if not isinstance(payload, dict):
            return None

        metrics = payload.get("metrics", {})
        if not metrics:
            return payload

        # SUPERMOC: Ekstrakcja metryk z JSON
        req_duration = (metrics.get("http_req_duration") or {}).get("values", {})
        checks = (metrics.get("checks") or {}).get("values", {})
        reqs = (metrics.get("http_reqs") or {}).get("values", {})

        return {
            "summary_available": True,
            "p95_ms": req_duration.get("p(95)"),
            "p99_ms": req_duration.get("p(99)"),
            "check_failures": 1.0 - checks.get("rate", 0) if "rate" in checks else None,
            "avg_response_time_ms": req_duration.get("avg"),
            "current_rps": reqs.get("rate"),
            "total_requests": reqs.get("count"),
        }

    except Exception:
        return None


class PerformanceOpsController(Controller):
    """SUPERMOC: Operational performance engineering visibility.

    Udostępnia wyniki testów wydajnościowych locust przez REST API.
    Obsługuje zarówno format CSV (--csv) jak i JSON (--json) z locust.
    """

    path = "/system/performance"
    guards = [owner_only_guard]
    tags = [TAG_SYSTEM]

    @get(
        "/locust-summary",
        return_dto=LocustSummaryDTO,
        summary="Get locust performance summary",
        description=(
            "Returns the latest locust load test performance summary "
            "including p95/p99 latency, RPS, error rate, and request counts. "
            "Parses both CSV and JSON outputs from locust."
        ),
        operation_id="getLocustSummary",
    )
    async def locust_summary(self) -> dict:
        """SUPERMOC: Pobierz podsumowanie ostatniego testu locust.

        Przeszukuje katalog reports/performance/ w poszukiwaniu:
          1. locust_stats.html (JSON HTML — fallback)
          2. locust_stats_stats.csv (CSV — preferowany)
          3. locust_metrics_*.json (OTel fallback)

        Returns:
            Dykt z metrykami wydajności lub status: "missing"
        """
        reports_dir = Path("reports") / "performance"

        # SUPERMOC: Próbuj różne formaty locust
        # 1. JSON (locust --json)
        json_path = reports_dir / "locust_stats.json"
        result = _parse_locust_json_summary(json_path)
        if result:
            result["status"] = "ok"
            result["raw_format"] = "json"
            return result

        # 2. CSV (locust --csv)
        csv_prefix = reports_dir / "locust_stats"
        result = _parse_locust_csv_summary(csv_prefix)
        if result:
            result["status"] = "ok"
            result["raw_format"] = "csv"
            return result

        # 3. OTel fallback JSON
        json_files = sorted(reports_dir.glob("locust_metrics_*.json"))
        if json_files:
            try:
                payload = msgspec_loads(json_files[-1].read_bytes())
                if isinstance(payload, dict):
                    return {
                        "status": "ok",
                        "summary_available": True,
                        "p95_ms": payload.get("p95_ms"),
                        "p99_ms": payload.get("p99_ms"),
                        "check_failures": payload.get("fail_ratio"),
                        "avg_response_time_ms": payload.get("avg_response_time_ms"),
                        "current_rps": payload.get("current_rps"),
                        "total_requests": payload.get("total_requests"),
                        "total_failures": payload.get("total_failures"),
                        "raw_format": "otel_fallback",
                    }
            except Exception:
                pass

        # 4. Perf gate summary (CI/CD fallback)
        gate_path = reports_dir / "perf_gate_summary.json"
        if gate_path.exists():
            try:
                payload = msgspec_loads(gate_path.read_bytes())
                if isinstance(payload, dict):
                    return {
                        "status": "ok",
                        "summary_available": True,
                        "p95_ms": payload.get("max_p95_ms"),
                        "check_failures": payload.get("max_error_rate"),
                        "raw_format": "gate_summary",
                        "exit_code": payload.get("exit_code"),
                    }
            except Exception:
                pass

        return {"status": "missing", "summary_available": False}

    @get(
        "/locust-config",
        return_dto=LocustSummaryDTO,
        summary="Get locust test configuration",
        description="Returns the default locust configuration for this environment.",
        operation_id="getLocustConfig",
        exclude_opt_key="no_rate_limit",
    )
    async def locust_config(self) -> dict:
        """SUPERMOC: Zwróć domyślną konfigurację locust dla tego środowiska."""
        import os

        return {
            "host": os.getenv("LOCUST_HOST", "http://localhost:8000"),
            "script": "tests/performance/locustfile.py",
            "default_users": 50,
            "default_spawn_rate": 10,
            "default_duration": "5m",
            "shapes_available": [
                "NexusSpikeShape",
                "NexusMonthEndShape",
                "NexusTaxPeriodShape",
                "NexusDoubleWaveShape",
                "NexusSteadyShape",
            ],
            "user_classes": ["NexusAIUser", "NexusAILightUser"],
            "superpowers": [
                "FastHttpUser (geventhttpclient) — 3-5× RPS boost",
                "SequentialTaskSet — biznesowa kolejność operacji",
                "catch_response — walidacja biznesowa odpowiedzi",
                "LoadTestShape — customowe profile obciążenia",
                "OTel integration — metryki do DuckDB/Parquet",
                "Distributed mode — master/worker skalowanie",
            ],
        }
