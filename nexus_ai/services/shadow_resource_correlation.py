from __future__ import annotations

from nexus_ai.db.analytics import DuckDBManager


def ensure_shadow_resource_schema(duckdb: DuckDBManager) -> None:
    """Creates schema required for power-vs-presence correlation analytics."""
    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS iot_power_log (
            timestamp TIMESTAMP NOT NULL,
            kwh_consumed DOUBLE NOT NULL,
            meter_id VARCHAR,
            source VARCHAR,
            created_at TIMESTAMP NOT NULL DEFAULT now()
        )
        """
    )

    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS access_control_log (
            timestamp TIMESTAMP NOT NULL,
            employee_id VARCHAR NOT NULL,
            event_type VARCHAR NOT NULL,
            source VARCHAR,
            created_at TIMESTAMP NOT NULL DEFAULT now(),
            CHECK (event_type IN ('IN', 'OUT'))
        )
        """
    )

    duckdb.execute("CREATE INDEX IF NOT EXISTS idx_iot_power_log_timestamp ON iot_power_log(timestamp)")
    duckdb.execute("CREATE INDEX IF NOT EXISTS idx_access_control_ts_emp ON access_control_log(timestamp, employee_id)")


def employee_presence_power_correlation_query(window_minutes: int = 15) -> str:
    """
    Returns DuckDB SQL that calculates Pearson correlation between employee presence and
    power spikes in fixed windows.

    The query outputs one row per employee with:
    - correlation coefficient between presence flag and kWh consumed
    - number of analyzed windows
    - spike statistics (kWh > 2.0)
    """
    return f"""
    WITH power_windows AS (
        SELECT
            time_bucket(INTERVAL '{window_minutes} minutes', timestamp) AS window_start,
            SUM(kwh_consumed) AS kwh_consumed
        FROM iot_power_log
        GROUP BY 1
    ),
    access_events AS (
        SELECT
            employee_id,
            timestamp,
            CASE WHEN event_type = 'IN' THEN 1 ELSE -1 END AS delta
        FROM access_control_log
    ),
    employee_windows AS (
        SELECT
            emps.employee_id,
            p.window_start,
            COALESCE(
                SUM(e.delta) FILTER (
                    WHERE e.timestamp <= p.window_start + INTERVAL '{window_minutes} minutes'
                ) OVER (
                    PARTITION BY emps.employee_id
                    ORDER BY e.timestamp
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ),
                0
            ) AS presence_balance,
            p.kwh_consumed
        FROM power_windows p
        CROSS JOIN (SELECT DISTINCT employee_id FROM access_control_log) emps
        LEFT JOIN access_events e ON e.employee_id = emps.employee_id
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY emps.employee_id, p.window_start
            ORDER BY e.timestamp DESC NULLS LAST
        ) = 1
    )
    SELECT
        employee_id,
        corr(CASE WHEN presence_balance > 0 THEN 1.0 ELSE 0.0 END, kwh_consumed) AS presence_power_corr,
        COUNT(*) AS windows_count,
        AVG(kwh_consumed) AS avg_window_kwh,
        SUM(CASE WHEN kwh_consumed > 2.0 THEN 1 ELSE 0 END) AS spike_windows,
        AVG(
            CASE
                WHEN kwh_consumed > 2.0 AND presence_balance > 0 THEN 1.0
                ELSE 0.0
            END
        ) AS spike_presence_ratio
    FROM employee_windows
    GROUP BY 1
    HAVING windows_count >= 4
    ORDER BY presence_power_corr DESC NULLS LAST
    """


def detect_energy_leeches(
    duckdb: DuckDBManager,
    correlation_threshold: float = 0.85,
    spike_threshold_kwh: float = 2.0,
    window_minutes: int = 15,
) -> list[tuple]:
    """Returns employees with suspiciously high correlation to energy spikes."""
    base_query = employee_presence_power_correlation_query(window_minutes)
    return duckdb.execute(
        f"""
        SELECT *
        FROM ({base_query}) q
        WHERE q.presence_power_corr > ?
          AND q.spike_windows > 0
          AND q.avg_window_kwh >= ?
        ORDER BY q.presence_power_corr DESC
        """,
        (correlation_threshold, spike_threshold_kwh),
    )
