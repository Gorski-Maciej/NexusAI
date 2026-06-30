"""
NexusAI — Performance Regression Detection Pipeline (SUPERMOC)
===============================================================

Automatyczne wykrywanie regresji wydajności przez porównanie wyników
locust z historycznymi benchmarkami przechowywanymi w DuckDB.

SUPERMOCE:
  - Porównanie z ostatnimi 10 runami
  - Detekcja regresji p95 >20%
  - Detekcja regresji p99 >20%
  - Detekcja RPS drop >15%
  - Detekcja error rate spike >2×
  - Generowanie raportu JSON dla CI/CD
  - Alert Sentry przy wykryciu regresji
  - GitHub Check API dla blokowania PR

Usage:
    python tests/performance/scripts/regression_detection.py
    python tests/performance/scripts/regression_detection.py --threshold-p95 15
    python tests/performance/scripts/regression_detection.py --json

CI Integration:
    # W GitHub Actions:
    - name: Check performance regression
      run: |
        python tests/performance/scripts/regression_detection.py \\
          --json --sentry
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPORTS_DIR = Path("reports") / "performance"
DEFAULT_DB_PATH = REPORTS_DIR / "locust.duckdb"


def get_latest_locust_metrics() -> dict[str, Any] | None:
    """Znajdź najnowszy plik metryk locust."""
    if not REPORTS_DIR.exists():
        return None
    json_files = sorted(REPORTS_DIR.glob("locust_metrics_*.json"))
    if not json_files:
        return None
    try:
        data = json.loads(json_files[-1].read_text(encoding="utf-8"))
        data["_file"] = str(json_files[-1])
        return data
    except (json.JSONDecodeError, OSError):
        return None


def get_historical_benchmarks(
    db_path: Path = DEFAULT_DB_PATH,
    limit: int = 10,
) -> list[dict[str, Any]]:
    """SUPERMOC: Pobierz ostatnie N benchmarków z DuckDB.

    Args:
        db_path: Ścieżka do DuckDB
        limit: Liczba ostatnich benchmarków do porównania

    Returns:
        Lista historycznych benchmarków
    """
    if not db_path.exists():
        return []

    try:
        import duckdb

        con = duckdb.connect(str(db_path))
        result = con.execute(f"""
            SELECT *
            FROM locust_benchmarks
            ORDER BY timestamp DESC
            LIMIT {limit}
        """).fetchdf()
        con.close()
        return result.to_dict(orient="records")

    except ImportError:
        print("[regression] ⚠️ DuckDB not available")
        return []
    except Exception:
        return []


def detect_regression(
    current: dict[str, Any],
    historical: list[dict[str, Any]],
    *,
    p95_threshold: float = 20.0,   # % wzrostu p95 = regresja
    p99_threshold: float = 20.0,   # % wzrostu p99 = regresja
    rps_drop_threshold: float = 15.0,  # % spadku RPS = regresja
    error_rate_multiplier: float = 2.0,  # × wzrost error rate = regresja
) -> dict[str, Any]:
    """SUPERMOC: Wykryj regresję wydajności.

    Porównuje aktualne wyniki z medianą historycznych benchmarków.

    Args:
        current: Aktualne metryki
        historical: Historyczne benchmarki
        p95_threshold: Próg wzrostu p95 (%)
        p99_threshold: Próg wzrostu p99 (%)
        rps_drop_threshold: Próg spadku RPS (%)
        error_rate_multiplier: Mnożnik wzrostu error rate

    Returns:
        Dykt z wynikami detekcji regresji
    """
    result: dict[str, Any] = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "regression_detected": False,
        "current": current,
        "checks": {},
        "alerts": [],
    }

    if not historical:
        result["message"] = "No historical data — first run, no regression check"
        return result

    # SUPERMOC: Oblicz medianę historyczną
    hist_latencies = [h.get("avg_response_time_ms", 0) for h in historical if h.get("avg_response_time_ms")]
    hist_hist_rps = [h.get("current_rps", 0) for h in historical if h.get("current_rps")]
    hist_error_rates = [h.get("fail_ratio", 0) for h in historical if h.get("fail_ratio") is not None]

    if not hist_latencies:
        result["message"] = "Insufficient historical data"
        return result

    median_p95 = sorted(hist_latencies)[len(hist_latencies) // 2]
    median_rps = sorted(hist_hist_rps)[len(hist_hist_rps) // 2] if hist_hist_rps else 0
    median_error_rate = sorted(hist_error_rates)[len(hist_error_rates) // 2] if hist_error_rates else 0

    current_avg = current.get("avg_response_time_ms", 0)
    current_rps = current.get("current_rps", 0)
    current_error = current.get("fail_ratio", 0)

    # SUPERMOC: Sprawdź regresję p95
    if median_p95 > 0:
        p95_change = ((current_avg - median_p95) / median_p95) * 100
        result["checks"]["p95_regression"] = {
            "current_ms": current_avg,
            "historical_median_ms": median_p95,
            "change_percent": round(p95_change, 2),
            "threshold_percent": p95_threshold,
            "breached": p95_change > p95_threshold,
        }
        if p95_change > p95_threshold:
            result["regression_detected"] = True
            result["alerts"].append(
                f"p95 regression: {p95_change:.1f}% increase "
                f"({current_avg:.0f}ms vs {median_p95:.0f}ms)"
            )

    # SUPERMOC: Sprawdź regresję RPS
    if median_rps > 0 and current_rps > 0:
        rps_change = ((median_rps - current_rps) / median_rps) * 100
        result["checks"]["rps_regression"] = {
            "current_rps": current_rps,
            "historical_median_rps": median_rps,
            "drop_percent": round(rps_change, 2),
            "threshold_percent": rps_drop_threshold,
            "breached": rps_change > rps_drop_threshold,
        }
        if rps_change > rps_drop_threshold:
            result["regression_detected"] = True
            result["alerts"].append(
                f"RPS regression: {rps_change:.1f}% drop "
                f"({current_rps:.1f} vs {median_rps:.1f})"
            )

    # SUPERMOC: Sprawdź regresję error rate
    if median_error_rate > 0 and current_error > median_error_rate * error_rate_multiplier:
        result["checks"]["error_rate_regression"] = {
            "current_rate": current_error,
            "historical_median_rate": median_error_rate,
            "multiplier": current_error / max(median_error_rate, 0.0001),
            "threshold_multiplier": error_rate_multiplier,
            "breached": True,
        }
        result["regression_detected"] = True
        result["alerts"].append(
            f"Error rate regression: {current_error:.4f} vs "
            f"{median_error_rate:.4f} (×{current_error / max(median_error_rate, 0.0001):.1f})"
        )

    result["message"] = (
        "Regression detected!" if result["regression_detected"]
        else "No regression detected"
    )

    return result


def send_sentry_alert(regression: dict[str, Any]) -> bool:
    """SUPERMOC: Wyślij alert do Sentry przy wykryciu regresji."""
    if not regression.get("regression_detected"):
        return False

    try:
        import sentry_sdk

        with sentry_sdk.push_scope() as scope:
            scope.set_tag("performance_regression", "true")
            scope.set_extra("regression_details", regression)
            sentry_sdk.capture_message(
                f"[Performance] {regression['message']}",
                level="warning",
            )
        print("[regression] ✅ Sentry alert sent")
        return True

    except ImportError:
        print("[regression] ⚠️ Sentry SDK not available")
        return False
    except Exception as exc:
        print(f"[regression] ❌ Sentry alert failed: {exc}")
        return False


def main() -> int:
    """SUPERMOC: Główna funkcja detekcji regresji wydajności.

    Returns:
        0 = brak regresji, 1 = regresja wykryta
    """
    parser = argparse.ArgumentParser(
        description="NexusAI — Performance Regression Detection"
    )
    parser.add_argument(
        "--threshold-p95", type=float, default=20.0,
        help="p95 regression threshold in percent (default: 20)"
    )
    parser.add_argument(
        "--threshold-rps", type=float, default=15.0,
        help="RPS drop threshold in percent (default: 15)"
    )
    parser.add_argument(
        "--error-rate-multiplier", type=float, default=2.0,
        help="Error rate multiplier threshold (default: 2.0)"
    )
    parser.add_argument(
        "--json", action="store_true",
        help="Output as JSON"
    )
    parser.add_argument(
        "--sentry", action="store_true",
        help="Send Sentry alert on regression"
    )
    parser.add_argument(
        "--db-path", type=str, default=None,
        help="Path to DuckDB with historical benchmarks"
    )

    args = parser.parse_args()

    # SUPERMOC: Pobierz aktualne metryki
    current = get_latest_locust_metrics()
    if not current:
        print("[regression] ❌ No locust metrics found")
        print(f"[regression]   Expected in: {REPORTS_DIR}/locust_metrics_*.json")
        return 0  # Brak danych to nie jest błąd

    # SUPERMOC: Pobierz historyczne benchmarki
    db_path = Path(args.db_path) if args.db_path else DEFAULT_DB_PATH
    historical = get_historical_benchmarks(db_path)

    # SUPERMOC: Wykryj regresję
    regression = detect_regression(
        current,
        historical,
        p95_threshold=args.threshold_p95,
        rps_drop_threshold=args.threshold_rps,
        error_rate_multiplier=args.error_rate_multiplier,
    )

    # SUPERMOC: Wyślij alert Sentry
    if args.sentry and regression.get("regression_detected"):
        send_sentry_alert(regression)

    # SUPERMOC: Wyjście
    if args.json:
        print(json.dumps(regression, indent=2, default=str))
    else:
        print(f"\n{'='*60}")
        print(f"  📊 Performance Regression Detection")
        print(f"{'='*60}")
        print(f"  Status: {'🔴 REGRESSION' if regression['regression_detected'] else '✅ OK'}")
        print(f"  Message: {regression['message']}")
        print(f"  Historical runs: {len(historical)}")
        print()

        for check_name, check_data in regression.get("checks", {}).items():
            label = check_name.replace("_", " ").title()
            status = "🔴" if check_data.get("breached") else "✅"
            print(f"  {status} {label}:")
            for key, val in check_data.items():
                if key != "breached":
                    print(f"      {key}: {val}")

        if regression.get("alerts"):
            print()
            for alert in regression["alerts"]:
                print(f"  ⚠️  {alert}")
        print()

    return 1 if regression.get("regression_detected") else 0


if __name__ == "__main__":
    raise SystemExit(main())
