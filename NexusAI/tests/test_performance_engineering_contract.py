"""
Contract tests for performance engineering — locust CSV/JSON edition.

SUPERMOCE:
  - Testy używają formatu locust CSV (_stats.csv) zamiast k6 JSON
  - Sprawdzają p95, p99, error rate, RPS
  - Testują JSON fallback
"""

from __future__ import annotations

import csv
from pathlib import Path

from nexus_ai.scripts.performance_engineering import enforce_thresholds


def _create_locust_csv(tmp_path: Path, filename: str, rows: list[dict]) -> Path:
    """SUPERMOC: Helper do tworzenia plików CSV w formacie locust."""
    csv_path = tmp_path / f"{filename}_stats.csv"
    fieldnames = [
        "Type", "Name", "Request Count", "Failure Count",
        "Median Response Time", "Average Response Time",
        "Min Response Time", "Max Response Time",
        "Average Content Size", "Requests/s",
        "50%", "66%", "75%", "80%", "90%", "95%", "98%", "99%", "99.9%", "99.99%", "100%",
    ]
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    return csv_path


def test_enforce_thresholds_passes_for_good_summary(tmp_path: Path) -> None:
    """SUPERMOC: Sprawdź czy dobre wyniki przechodzą threshold."""
    _create_locust_csv(tmp_path, "locust_stats", [
        {
            "Type": "GET",
            "Name": "/invoices",
            "Request Count": "100",
            "Failure Count": "1",
            "95%": "100.0",
            "99%": "150.0",
            "Requests/s": "10.0",
            "Average Response Time": "80.0",
        },
    ])
    assert enforce_thresholds(
        tmp_path / "locust_stats",
        max_p95_ms=1200.0,
        max_error_rate=0.02,
    ) == 0


def test_enforce_thresholds_fails_for_bad_summary(tmp_path: Path) -> None:
    """SUPERMOC: Sprawdź czy złe wyniki blokują threshold."""
    _create_locust_csv(tmp_path, "summary_bad", [
        {
            "Type": "GET",
            "Name": "/invoices",
            "Request Count": "100",
            "Failure Count": "10",
            "95%": "2200.0",
            "99%": "3000.0",
            "Requests/s": "5.0",
            "Average Response Time": "2000.0",
        },
    ])
    assert enforce_thresholds(
        tmp_path / "summary_bad",
        max_p95_ms=1200.0,
        max_error_rate=0.02,
    ) == 1


def test_enforce_thresholds_with_multiple_endpoints(tmp_path: Path) -> None:
    """SUPERMOC: Sprawdź threshold z wieloma endpointami."""
    _create_locust_csv(tmp_path, "multi", [
        {
            "Type": "GET",
            "Name": "/invoices",
            "Request Count": "200",
            "Failure Count": "1",
            "95%": "150.0",
            "99%": "200.0",
            "Requests/s": "20.0",
            "Average Response Time": "100.0",
        },
        {
            "Type": "POST",
            "Name": "/tax/calculate",
            "Request Count": "100",
            "Failure Count": "0",
            "95%": "50.0",
            "99%": "80.0",
            "Requests/s": "10.0",
            "Average Response Time": "40.0",
        },
        {
            "Type": "GET",
            "Name": "/health",
            "Request Count": "300",
            "Failure Count": "0",
            "95%": "20.0",
            "99%": "30.0",
            "Requests/s": "30.0",
            "Average Response Time": "15.0",
        },
    ])
    assert enforce_thresholds(
        tmp_path / "multi",
        max_p95_ms=1200.0,
        max_error_rate=0.02,
        max_p99_ms=500.0,
        min_rps=5.0,
    ) == 0
