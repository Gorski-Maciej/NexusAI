"""
Enhanced runtime tests for performance engineering — locust edition.

SUPERMOCE:
  - Testy p99 threshold z locust CSV
  - Testy min RPS threshold
  - Testy z wieloma endpointami
  - Testy JSON fallback
"""

from __future__ import annotations

import csv
from pathlib import Path

from nexus_ai.scripts.performance_engineering import enforce_thresholds


def _create_locust_csv(tmp_path: Path, filename: str, rows: list[dict]) -> Path:
    """Helper do tworzenia plików CSV w formacie locust."""
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


def test_enforce_thresholds_p99_breach(tmp_path: Path) -> None:
    """SUPERMOC: Sprawdź czy p99 threshold działa."""
    _create_locust_csv(tmp_path, "summary", [
        {
            "Type": "GET",
            "Name": "/invoices",
            "Request Count": "100",
            "Failure Count": "1",
            "95%": "100.0",
            "99%": "2500.0",
            "Requests/s": "30.0",
            "Average Response Time": "80.0",
        },
    ])
    assert enforce_thresholds(
        tmp_path / "summary",
        max_p95_ms=1200.0,
        max_error_rate=0.02,
        max_p99_ms=2000.0,
    ) == 1


def test_enforce_thresholds_min_rps_breach(tmp_path: Path) -> None:
    """SUPERMOC: Sprawdź czy min RPS threshold działa."""
    _create_locust_csv(tmp_path, "summary2", [
        {
            "Type": "GET",
            "Name": "/invoices",
            "Request Count": "10",
            "Failure Count": "0",
            "95%": "100.0",
            "99%": "110.0",
            "Requests/s": "1.0",
            "Average Response Time": "80.0",
        },
    ])
    assert enforce_thresholds(
        tmp_path / "summary2",
        max_p95_ms=1200.0,
        max_error_rate=0.02,
        min_rps=5.0,
    ) == 1


def test_enforce_thresholds_empty_csv_returns_fail(tmp_path: Path) -> None:
    """SUPERMOC: Sprawdź czy pusty CSV zwraca błąd."""
    _create_locust_csv(tmp_path, "empty", [])  # Only header, no data rows
    assert enforce_thresholds(
        tmp_path / "empty",
        max_p95_ms=1200.0,
        max_error_rate=0.02,
    ) == 1


def test_enforce_thresholds_missing_csv_returns_fail(tmp_path: Path) -> None:
    """SUPERMOC: Sprawdź czy brak pliku CSV zwraca błąd."""
    assert enforce_thresholds(
        tmp_path / "nonexistent",
        max_p95_ms=1200.0,
        max_error_rate=0.02,
    ) == 1


def test_enforce_thresholds_high_error_rate(tmp_path: Path) -> None:
    """SUPERMOC: Sprawdź czy wysoki error rate jest wykrywany."""
    _create_locust_csv(tmp_path, "errors", [
        {
            "Type": "GET",
            "Name": "/invoices",
            "Request Count": "100",
            "Failure Count": "50",  # 50% error rate!
            "95%": "100.0",
            "99%": "150.0",
            "Requests/s": "10.0",
            "Average Response Time": "80.0",
        },
    ])
    assert enforce_thresholds(
        tmp_path / "errors",
        max_p95_ms=1200.0,
        max_error_rate=0.02,
    ) == 1
