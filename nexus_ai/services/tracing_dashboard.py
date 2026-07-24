"""
tracing_dashboard.py — Distributed Tracing Dashboard (Flet).

Enterprise v7.0 Innowacja 3: Lokalny dashboard pokazujący:
  - Aktywne trace-y (waterfall)
  - Top 10 wolnych endpointów
  - Error rate per service
  - Span timeline
  Wszystko z Parquet przez DuckDB SQL.

Usage:
    python nexus_ai/services/tracing_dashboard.py
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.tracing.dashboard")


class TracingDashboard:
    """SQL-based tracing dashboard using DuckDB + Parquet.

    Enterprise v7.0 Innowacja 3:
      - Query spans from Parquet via DuckDB
      - Top slow endpoints
      - Error rate per service
      - Span count timeline
    """

    def __init__(self, parquet_dir: str | Path = "app_data/otel_spans_parquet") -> None:
        self.parquet_dir = Path(parquet_dir)

    def top_slow_endpoints(self, limit: int = 10) -> list[dict[str, Any]]:
        """Get top N slowest endpoints by average duration."""
        try:
            import duckdb
            conn = duckdb.connect(":memory:")
            parquet_files = list(self.parquet_dir.rglob("*.parquet"))
            if not parquet_files:
                return []

            glob_pattern = str(self.parquet_dir / "**" / "*.parquet")
            result = conn.execute(f"""
                SELECT
                    name,
                    COUNT(*) as count,
                    AVG(CAST(attributes->>'$.duration_ms' AS DOUBLE)) as avg_duration_ms,
                    MAX(CAST(attributes->>'$.duration_ms' AS DOUBLE)) as max_duration_ms,
                    MIN(CAST(attributes->>'$.duration_ms' AS DOUBLE)) as min_duration_ms
                FROM read_parquet('{glob_pattern.replace("'", "''")}', hive_partitioning=true)
                WHERE name IS NOT NULL
                GROUP BY name
                ORDER BY avg_duration_ms DESC
                LIMIT {limit}
            """).fetchall()

            return [
                {
                    "endpoint": r[0],
                    "count": r[1],
                    "avg_duration_ms": round(r[2], 1) if r[2] else 0,
                    "max_duration_ms": round(r[3], 1) if r[3] else 0,
                    "min_duration_ms": round(r[4], 1) if r[4] else 0,
                }
                for r in result
            ]
        except Exception as exc:
            logger.debug("[DASHBOARD] Query failed: %s", exc)
            return []

    def error_rate_per_service(self) -> list[dict[str, Any]]:
        """Get error rate per service/component."""
        try:
            import duckdb
            conn = duckdb.connect(":memory:")
            parquet_files = list(self.parquet_dir.rglob("*.parquet"))
            if not parquet_files:
                return []

            glob_pattern = str(self.parquet_dir / "**" / "*.parquet")
            result = conn.execute(f"""
                SELECT
                    COALESCE(attributes->>'$.component', 'unknown') as service,
                    COUNT(*) as total,
                    SUM(CASE WHEN attributes->>'$.error' = 'true' THEN 1 ELSE 0 END) as errors
                FROM read_parquet('{glob_pattern}', hive_partitioning=true)
                GROUP BY service
                ORDER BY total DESC
            """).fetchall()

            return [
                {
                    "service": r[0],
                    "total": r[1],
                    "errors": r[2],
                    "error_rate": round((r[2] / r[1] * 100), 1) if r[1] > 0 else 0,
                }
                for r in result
            ]
        except Exception as exc:
            logger.debug("[DASHBOARD] Error rate query failed: %s", exc)
            return []

    def span_timeline(self, hours: int = 24) -> list[dict[str, Any]]:
        """Get span count timeline grouped by hour."""
        try:
            import duckdb
            conn = duckdb.connect(":memory:")
            glob_pattern = str(self.parquet_dir / "**" / "*.parquet")
            result = conn.execute(f"""
                SELECT
                    year, month, day,
                    COUNT(*) as span_count
                FROM read_parquet('{glob_pattern}', hive_partitioning=true)
                GROUP BY year, month, day
                ORDER BY year, month, day
                LIMIT {hours}
            """).fetchall()

            return [
                {
                    "date": f"{r[0]}-{r[1]:02d}-{r[2]:02d}",
                    "span_count": r[3],
                }
                for r in result
            ]
        except Exception as exc:
            logger.debug("[DASHBOARD] Timeline query failed: %s", exc)
            return []

    def storage_summary(self) -> dict[str, Any]:
        """Get storage summary for the dashboard."""
        try:
            from nexus_ai.services.otel_fallback import FileSpanBuffer
            buffer = FileSpanBuffer()
            return buffer.get_storage_stats()
        except Exception:
            return {}

    def get_dashboard_data(self) -> dict[str, Any]:
        """Get complete dashboard data."""
        return {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "top_slow_endpoints": self.top_slow_endpoints(10),
            "error_rate_per_service": self.error_rate_per_service(),
            "span_timeline": self.span_timeline(),
            "storage": self.storage_summary(),
        }

    def print_dashboard(self) -> None:
        """Print text-based dashboard to stdout."""
        data = self.get_dashboard_data()
        print("=" * 70)
        print("TRACING DASHBOARD")
        print("=" * 70)
        print(f"Generated: {data['timestamp']}")
        print()

        print("── TOP 10 SLOW ENDPOINTS ──")
        for ep in data["top_slow_endpoints"]:
            print(f"  {ep['endpoint']}: avg={ep['avg_duration_ms']}ms, max={ep['max_duration_ms']}ms ({ep['count']} calls)")
        print()

        print("── ERROR RATE PER SERVICE ──")
        for svc in data["error_rate_per_service"]:
            flag = "🔴" if svc["error_rate"] > 5 else "🟡" if svc["error_rate"] > 1 else "🟢"
            print(f"  {flag} {svc['service']}: {svc['error_rate']}% ({svc['errors']}/{svc['total']})")
        print()

        print("── SPAN TIMELINE ──")
        for day in data["span_timeline"]:
            bar = "█" * min(int(day["span_count"] / 1000), 50)
            print(f"  {day['date']}: {bar} ({day['span_count']})")


if __name__ == "__main__":
    dashboard = TracingDashboard()
    dashboard.print_dashboard()
