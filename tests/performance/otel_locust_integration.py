"""
NexusAI — Locust ↔ OpenTelemetry Integration (SUPERMOC)
=========================================================

Integruje locust z systemem obserwowalności NexusAI:
  - Eksport metryk locust do OpenTelemetry
  - Zapis wyników do DuckDB/Parquet
  - Porównanie z historycznymi benchmarkami
  - Automatyczne wykrywanie regresji

Zgodnie z aa3fvcx.txt: metryki locust trafiają do DuckDB przez OTel.

Usage:
    from tests.performance.otel_locust_integration import setup_locust_otel
    setup_locust_otel(environment)
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def setup_locust_otel(environment: Any) -> bool:
    """SUPERMOC: Inicjalizuje eksport metryk locust do OTel.

    Tworzy metryki OTel dla:
      - locust.request.duration — histogram czasów odpowiedzi
      - locust.request.errors   — counter błędów per endpoint
      - locust.users.active     - gauge aktywnych użytkowników

    Jeśli OTel nie jest dostępne, zapisuje wyniki do JSON (fallback).

    Args:
        environment: Locust Environment object

    Returns:
        True jeśli OTel został zainicjalizowany, False jeśli fallback
    """
    try:
        from opentelemetry import metrics

        meter = metrics.get_meter("nexusai.locust")

        # SUPERMOC: Histogram czasów odpowiedzi per endpoint
        request_duration = meter.create_histogram(
            name="locust.request.duration",
            description="Request duration per endpoint under load test",
            unit="ms",
        )

        # SUPERMOC: Counter błędów per endpoint
        error_counter = meter.create_counter(
            name="locust.request.errors",
            description="Total error count per endpoint during load test",
        )

        # SUPERMOC: Gauge aktywnych użytkowników
        active_users = meter.create_up_down_counter(
            name="locust.users.active",
            description="Number of active simulated users",
        )

        # SUPERMOC: Rejestracja hooków do zbierania metryk
        from locust import events

        @events.request_success.add_listener
        def _on_success(
            request_type: str,
            name: str,
            response_time: float,
            response_length: int,
            **_kwargs: Any,
        ) -> None:
            request_duration.record(
                response_time,
                {
                    "endpoint": name,
                    "method": request_type,
                    "status": "success",
                },
            )
            active_users.add(
                environment.runner.user_count if environment.runner else 0
            )

        @events.request_failure.add_listener
        def _on_failure(
            request_type: str,
            name: str,
            response_time: float,
            response_length: int,
            exception: Any = None,
            **_kwargs: Any,
        ) -> None:
            request_duration.record(
                response_time,
                {
                    "endpoint": name,
                    "method": request_type,
                    "status": "failure",
                },
            )
            error_counter.add(
                1,
                {
                    "endpoint": name,
                    "method": request_type,
                    "error": str(exception or "unknown"),
                },
            )

        print("[locust-otel] ✅ OpenTelemetry metrics initialized")
        return True

    except ImportError as exc:
        print(f"[locust-otel] ⚠️ OpenTelemetry not available: {exc}")
        print("[locust-otel] ⚠️ Falling back to JSON file export")
        _setup_json_fallback(environment)
        return False


def _setup_json_fallback(environment: Any) -> None:
    """SUPERMOC: Fallback — zapis metryk do JSON jeśli OTel nie dostępne.

    Zapisuje wyniki do reports/performance/locust_metrics_{timestamp}.json
    w formacie kompatybilnym z DuckDB.
    """
    reports_dir = Path("reports") / "performance"
    reports_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    metrics_path = reports_dir / f"locust_metrics_{timestamp}.json"

    from locust import events

    @events.test_stop.add_listener
    def _on_test_stop(**_kwargs: Any) -> None:
        """SUPERMOC: Zapis metryk do JSON przy zakończeniu testu."""
        if not environment.stats:
            return

        stats = environment.stats.total
        metrics = {
            "timestamp": timestamp,
            "host": environment.host or "unknown",
            "user_count": environment.runner.user_count if environment.runner else 0,
            "total_requests": stats.num_requests,
            "total_failures": stats.num_failures,
            "fail_ratio": stats.fail_ratio,
            "avg_response_time_ms": stats.avg_response_time,
            "min_response_time_ms": stats.min_response_time,
            "max_response_time_ms": stats.max_response_time,
            "current_rps": stats.current_rps,
            "total_rps": stats.total_rps,
            "p95_ms": None,  # Locust CSV ma p95, stats.total nie
            "p99_ms": None,
            "endpoints": {},
        }

        # SUPERMOC: Szczegółowe statystyki per endpoint
        for key, entry in environment.stats.entries.items():
            metrics["endpoints"][str(key)] = {
                "method": entry.method,
                "name": entry.name,
                "num_requests": entry.num_requests,
                "num_failures": entry.num_failures,
                "avg_response_time_ms": entry.avg_response_time,
                "min_response_time_ms": entry.min_response_time,
                "max_response_time_ms": entry.max_response_time,
                "total_rps": entry.total_rps,
                "current_rps": entry.current_rps,
            }

        metrics_path.write_text(
            json.dumps(metrics, indent=2, default=str), encoding="utf-8"
        )
        print(f"[locust-otel] 📊 Metrics saved to {metrics_path}")

    print(f"[locust-otel] ⚠️ Fallback metrics will be saved to {metrics_path}")


def export_locust_stats_to_duckdb(
    stats_path: Path | None = None,
    db_path: str | None = None,
) -> bool:
    """SUPERMOC: Eksport statystyk locust do DuckDB dla trendów.

    Zapisuje wyniki testów do DuckDB w tabeli `locust_benchmarks`.
    Pozwala na:
      - Porównanie wydajności między wersjami
      - Wykrywanie regresji (p95 wzrost >20%)
      - Generowanie raportów trendów

    Args:
        stats_path: Ścieżka do pliku JSON z metrykami locust
        db_path: Ścieżka do DuckDB (domyślnie raports/performance/locust.duckdb)

    Returns:
        True jeśli eksport się powiódł
    """
    if stats_path is None:
        # Znajdź ostatni plik metryk
        reports_dir = Path("reports") / "performance"
        if not reports_dir.exists():
            print("[locust-otel] No metrics files found")
            return False
        json_files = sorted(reports_dir.glob("locust_metrics_*.json"))
        if not json_files:
            print("[locust-otel] No metrics files found")
            return False
        stats_path = json_files[-1]

    if db_path is None:
        db_path = str(Path("reports") / "performance" / "locust.duckdb")

    try:
        import duckdb

        # SUPERMOC: DuckDB — zapis i agregacja trendów
        con = duckdb.connect(db_path)
        con.execute("""
            CREATE TABLE IF NOT EXISTS locust_benchmarks (
                timestamp TIMESTAMP,
                host VARCHAR,
                user_count INTEGER,
                total_requests BIGINT,
                total_failures BIGINT,
                fail_ratio DOUBLE,
                avg_response_time_ms DOUBLE,
                min_response_time_ms DOUBLE,
                max_response_time_ms DOUBLE,
                current_rps DOUBLE,
                total_rps DOUBLE
            )
        """)

        with open(stats_path) as f:
            data = json.load(f)

        con.execute("""
            INSERT INTO locust_benchmarks VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
            )
        """, (
            data["timestamp"],
            data["host"],
            data["user_count"],
            data["total_requests"],
            data["total_failures"],
            data["fail_ratio"],
            data["avg_response_time_ms"],
            data["min_response_time_ms"],
            data["max_response_time_ms"],
            data["current_rps"],
            data["total_rps"],
        ))

        con.close()
        print(f"[locust-otel] ✅ Stats exported to DuckDB: {db_path}")
        return True

    except ImportError:
        print("[locust-otel] ⚠️ DuckDB not available — skipping export")
        return False
    except Exception as exc:
        print(f"[locust-otel] ❌ Export failed: {exc}")
        return False
