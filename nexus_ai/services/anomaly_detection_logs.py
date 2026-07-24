"""
anomaly_detection_logs.py — Anomaly Detection on Logs via DuckDB SQL.

Enterprise v7.0 Innowacja 2: SQL queries na telemetry_logs do automatycznego
wykrywania anomalii — ERROR rate > threshold, nagłe spadki throughput, wzorce.
Alerty przez Sentry + structlog gdy wykryto anomalię.

Usage:
    from nexus_ai.services.anomaly_detection_logs import LogAnomalyDetector
    detector = LogAnomalyDetector(db_path="app_data/logs/nexusai_logs.duckdb")
    anomalies = detector.scan()
    for a in anomalies:
        detector.alert(a)
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.anomaly.logs")


@dataclass
class LogAnomaly:
    """Single detected anomaly in logs."""

    anomaly_type: str  # "error_spike", "throughput_drop", "pattern_anomaly"
    severity: str  # "critical", "warning", "info"
    description: str
    detected_at: str
    metric_value: float
    threshold: float
    window_minutes: int
    details: dict[str, Any] = field(default_factory=dict)


class LogAnomalyDetector:
    """DuckDB-based anomaly detection on telemetry_logs.

    Enterprise v7.0 Innowacja 2:
      - ERROR rate monitoring: COUNT(*) GROUP BY level
      - Throughput change detection: COUNT(*) per time window
      - Pattern anomalies: nietypowe poziomy logowania
      - Alert thresholds configurable via env vars
    """

    def __init__(
        self,
        db_path: str | Path = "app_data/logs/nexusai_logs.duckdb",
        *,
        error_rate_threshold: float | None = None,
        throughput_drop_threshold: float | None = None,
        window_minutes: int | None = None,
    ) -> None:
        self.db_path = Path(db_path)
        self.error_rate_threshold = error_rate_threshold or float(
            os.getenv("NEXUS_ANOMALY_ERROR_RATE", "10")
        )
        self.throughput_drop_threshold = throughput_drop_threshold or float(
            os.getenv("NEXUS_ANOMALY_THROUGHPUT_DROP", "50")
        )
        self.window_minutes = window_minutes or int(
            os.getenv("NEXUS_ANOMALY_WINDOW_MINUTES", "5")
        )
        self._conn: Any = None
        self._last_scan: datetime | None = None

    def _ensure_connection(self) -> Any:
        if self._conn is None and self.db_path.exists():
            import duckdb
            self._conn = duckdb.connect(str(self.db_path), read_only=True)
        return self._conn

    def close(self) -> None:
        """Close the DuckDB connection."""
        if self._conn is not None:
            try:
                self._conn.close()
            except Exception:
                pass
            self._conn = None

    def scan(self) -> list[LogAnomaly]:
        """Scan logs for all anomaly types. Returns detected anomalies."""
        anomalies: list[LogAnomaly] = []
        now = datetime.now(timezone.utc)

        conn = self._ensure_connection()
        if conn is None:
            logger.debug("[ANOMALY] DuckDB not available — skipping scan")
            return anomalies

        anomalies.extend(self._check_error_rate(conn, now))
        anomalies.extend(self._check_throughput_drop(conn, now))
        anomalies.extend(self._check_pattern_anomalies(conn, now))

        self._last_scan = now
        if anomalies:
            logger.warning(
                "[ANOMALY] Detected %d anomalies in logs", len(anomalies)
            )
        return anomalies

    def _check_error_rate(self, conn: Any, now: datetime) -> list[LogAnomaly]:
        """Check if ERROR rate exceeds threshold."""
        window_start = (now - timedelta(minutes=self.window_minutes)).isoformat()
        try:
            result = conn.execute("""
                SELECT
                    level,
                    COUNT(*) as cnt
                FROM telemetry_logs
                WHERE timestamp > ?
                GROUP BY level
            """, [window_start]).fetchall()

            total = sum(r[1] for r in result)
            errors = sum(r[1] for r in result if r[0] in ("ERROR", "CRITICAL"))

            if total > 0:
                error_pct = (errors / total) * 100
                if error_pct > self.error_rate_threshold:
                    return [LogAnomaly(
                        anomaly_type="error_spike",
                        severity="critical" if error_pct > self.error_rate_threshold * 2 else "warning",
                        description=f"ERROR rate at {error_pct:.1f}% (threshold: {self.error_rate_threshold}%)",
                        detected_at=now.isoformat(),
                        metric_value=error_pct,
                        threshold=self.error_rate_threshold,
                        window_minutes=self.window_minutes,
                        details={"total_logs": total, "error_count": errors},
                    )]
        except Exception as exc:
            logger.debug("[ANOMALY] Error rate check failed: %s", exc)
        return []

    def _check_throughput_drop(self, conn: Any, now: datetime) -> list[LogAnomaly]:
        """Check for sudden drops in log throughput."""
        current_window = (now - timedelta(minutes=self.window_minutes)).isoformat()
        previous_window = (now - timedelta(minutes=self.window_minutes * 2)).isoformat()
        try:
            current = conn.execute(
                "SELECT COUNT(*) FROM telemetry_logs WHERE timestamp > ?",
                [current_window]
            ).fetchone()
            previous = conn.execute(
                "SELECT COUNT(*) FROM telemetry_logs WHERE timestamp > ? AND timestamp <= ?",
                [previous_window, current_window]
            ).fetchone()

            curr_cnt = current[0] if current else 0
            prev_cnt = previous[0] if previous else 0

            if prev_cnt > 0:
                drop_pct = ((prev_cnt - curr_cnt) / prev_cnt) * 100
                if drop_pct > self.throughput_drop_threshold and curr_cnt > 0:
                    return [LogAnomaly(
                        anomaly_type="throughput_drop",
                        severity="warning",
                        description=f"Log throughput dropped by {drop_pct:.1f}% "
                                    f"({prev_cnt} → {curr_cnt} in {self.window_minutes}min)",
                        detected_at=now.isoformat(),
                        metric_value=drop_pct,
                        threshold=self.throughput_drop_threshold,
                        window_minutes=self.window_minutes,
                        details={"previous_count": prev_cnt, "current_count": curr_cnt},
                    )]
        except Exception as exc:
            logger.debug("[ANOMALY] Throughput check failed: %s", exc)
        return []

    def _check_pattern_anomalies(self, conn: Any, now: datetime) -> list[LogAnomaly]:
        """Check for unusual log patterns — e.g. sudden AUDIT/TAX spikes."""
        window_start = (now - timedelta(minutes=self.window_minutes)).isoformat()
        try:
            result = conn.execute("""
                SELECT level, COUNT(*) as cnt
                FROM telemetry_logs
                WHERE timestamp > ? AND level IN ('AUDIT', 'TAX', 'OCR')
                GROUP BY level
                HAVING COUNT(*) > 50
            """, [window_start]).fetchall()

            anomalies: list[LogAnomaly] = []
            for level, cnt in result:
                anomalies.append(LogAnomaly(
                    anomaly_type="pattern_anomaly",
                    severity="info",
                    description=f"Unusual {level} log volume: {cnt} in {self.window_minutes}min",
                    detected_at=now.isoformat(),
                    metric_value=cnt,
                    threshold=50.0,
                    window_minutes=self.window_minutes,
                    details={"level": level, "count": cnt},
                ))
            return anomalies
        except Exception as exc:
            logger.debug("[ANOMALY] Pattern check failed: %s", exc)
        return []

    def alert(self, anomaly: LogAnomaly) -> None:
        """Send alert for detected anomaly via structlog + Sentry."""
        logger.warning(
            "[ANOMALY-ALERT] %s: %s",
            anomaly.anomaly_type,
            anomaly.description,
            severity=anomaly.severity,
            metric_value=anomaly.metric_value,
            threshold=anomaly.threshold,
        )
        try:
            from nexus_ai.core.sentry import capture_message
            capture_message(
                f"[ANOMALY] {anomaly.anomaly_type}: {anomaly.description}",
                level=anomaly.severity,
                anomaly_type=anomaly.anomaly_type,
                metric_value=str(anomaly.metric_value),
            )
        except ImportError:
            pass

    def get_stats(self) -> dict[str, Any]:
        """Get overall log statistics for dashboard."""
        conn = self._ensure_connection()
        if conn is None:
            return {}
        try:
            total = conn.execute("SELECT COUNT(*) FROM telemetry_logs").fetchone()
            by_level = conn.execute(
                "SELECT level, COUNT(*) FROM telemetry_logs GROUP BY level"
            ).fetchall()
            return {
                "total_logs": total[0] if total else 0,
                "by_level": {r[0]: r[1] for r in by_level},
            }
        except Exception:
            return {}


# ── Periodic scan task ────────────────────────────────────────────────────────


async def anomaly_scan_loop(
    detector: LogAnomalyDetector | None = None,
    interval_sec: float = 300.0,
) -> None:
    """Periodic anomaly detection loop (runs every 5 minutes by default)."""
    import asyncio

    if detector is None:
        detector = LogAnomalyDetector()

    logger.info("[ANOMALY] Starting scan loop (interval=%ds)", interval_sec)
    while True:
        try:
            anomalies = detector.scan()
            for a in anomalies:
                detector.alert(a)
        except Exception as exc:
            logger.error("[ANOMALY] Scan loop error: %s", exc)
        await asyncio.sleep(interval_sec)
