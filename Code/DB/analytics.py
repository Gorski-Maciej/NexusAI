import duckdb
from pathlib import Path
from threading import Lock
from typing import Any
from dataclasses import dataclass


@dataclass(slots=True)
class DuckDBLimits:
    memory_limit: str = "512MB"
    threads: int = 2


class DuckDBManager:
    """Thread-safe DuckDB manager with native SQLite Zero-ETL attach."""

    def __init__(self, db_path: Path | str, limits: DuckDBLimits = DuckDBLimits(), read_only: bool = False, sqlite_path: Path | str = "app_data/nexus_oltp.db") -> None:
        self._db_path = Path(db_path)
        self._limits = limits
        self._read_only = read_only
        self._sqlite_path = Path(sqlite_path)
        self._lock = Lock()
        self._connection: duckdb.DuckDBPyConnection | None = None

    def connect(self) -> duckdb.DuckDBPyConnection:
        with self._lock:
            if self._connection is None:
                self._connection = duckdb.connect(str(self._db_path), read_only=self._read_only)
                self._connection.execute(f"SET memory_limit='{self._limits.memory_limit}'")
                self._connection.execute(f"SET threads={self._limits.threads}")
                temp_dir = (self._db_path.parent / 'duckdb_tmp')
                temp_dir.mkdir(parents=True, exist_ok=True)
                self._connection.execute(f"SET temp_directory='{temp_dir.as_posix()}'")
                self.setup_zero_etl(self._connection)
            return self._connection

    def setup_zero_etl(self, connection: duckdb.DuckDBPyConnection | None = None) -> None:
        conn = connection or self.connect()
        conn.execute("INSTALL sqlite;")
        conn.execute("LOAD sqlite;")
        conn.execute("DETACH IF EXISTS oltp;")
        conn.execute(f"ATTACH '{self._sqlite_path}' AS oltp (TYPE SQLITE);")

    def execute(self, query: str, parameters: tuple[Any, ...] | list[Any] | None = None) -> list[tuple[Any, ...]]:
        connection = self.connect()
        if parameters:
            return connection.execute(query, parameters).fetchall()
        return connection.execute(query).fetchall()

    def refresh_materialized_cashflow(self) -> None:
        # Data-quality gate: reject malformed/unsafe rows from OLAP aggregates.
        self.execute(
            """
            CREATE OR REPLACE TABLE dq_invalid_invoices AS
            SELECT id, issue_date, currency, amount_gross, status
            FROM oltp.invoices
            WHERE amount_gross < 0
               OR currency IS NULL
               OR length(trim(currency)) <> 3
               OR issue_date IS NULL
            """
        )
        query = """
        CREATE OR REPLACE TABLE m_daily_cashflow AS
        SELECT
            date_trunc('day', issue_date) as day,
            upper(trim(currency)) as currency,
            SUM(amount_gross) AS daily_income,
            COUNT(id) AS invoice_count
        FROM oltp.invoices
        WHERE status IN ('PAID', 'APPROVED')
          AND amount_gross >= 0
          AND currency IS NOT NULL
          AND length(trim(currency)) = 3
          AND issue_date IS NOT NULL
        GROUP BY 1, 2
        """
        self.execute(query)
        self.execute("CREATE INDEX IF NOT EXISTS idx_m_daily_cashflow_day ON m_daily_cashflow(day)")

    def close(self) -> None:
        with self._lock:
            if self._connection is not None:
                self._connection.close()
                self._connection = None
