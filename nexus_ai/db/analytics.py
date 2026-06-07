from dataclasses import dataclass
from pathlib import Path
from threading import Lock
from typing import Any

import duckdb


@dataclass(slots=True)
class DuckDBLimits:
    memory_limit: str = "512MB"
    threads: int = 2


class DuckDBManager:
    """Thread-safe DuckDB manager with native SQLite Zero-ETL attach.

    W środowisku asynchronicznym każde wywołanie execute() tworzy osobne połączenie
    (krótkożyciowe), co zapobiega blokowaniu między współbieżnymi requestami.
    Dla zadań wsadowych (refresh_materialized_cashflow) używane jest współdzielone
    połączenie z blokadą wątku, aby uniknąć konfliktów DDL.
    """

    def __init__(self, db_path: Path | str, limits: DuckDBLimits = DuckDBLimits(), read_only: bool = False, sqlite_path: Path | str = "app_data/nexus_oltp.db") -> None:
        self._db_path = Path(db_path)
        self._limits = limits
        self._read_only = read_only
        self._sqlite_path = Path(sqlite_path)
        self._lock = Lock()
        self._connection: duckdb.DuckDBPyConnection | None = None

    def _create_connection(self) -> duckdb.DuckDBPyConnection:
        """Tworzy nowe, skonfigurowane połączenie DuckDB."""
        conn = duckdb.connect(str(self._db_path), read_only=self._read_only)
        conn.execute(f"SET memory_limit='{self._limits.memory_limit}'")
        conn.execute(f"SET threads={self._limits.threads}")
        temp_dir = (self._db_path.parent / 'duckdb_tmp')
        temp_dir.mkdir(parents=True, exist_ok=True)
        conn.execute(f"SET temp_directory='{temp_dir.as_posix()}'")
        # Konfiguracja dla lepszej współbieżności
        conn.execute("SET perfect_ht_threshold=2;")
        return conn

    def connect(self) -> duckdb.DuckDBPyConnection:
        with self._lock:
            if self._connection is None:
                self._connection = self._create_connection()
                self.setup_zero_etl(self._connection)
            return self._connection

    def get_connection_for_query(self) -> duckdb.DuckDBPyConnection:
        """
        Dla prostych zapytań SELECT: tworzy nowe połączenie, które jest zamykane
        po wykonaniu. Dla operacji DDL używa współdzielonego połączenia.
        """
        conn = self._create_connection()
        self.setup_zero_etl(conn)
        return conn

    def setup_zero_etl(self, connection: duckdb.DuckDBPyConnection | None = None) -> None:
        conn = connection or self.connect()
        conn.execute("INSTALL sqlite;")
        conn.execute("LOAD sqlite;")
        conn.execute("DETACH IF EXISTS oltp;")
        conn.execute(f"ATTACH '{self._sqlite_path}' AS oltp (TYPE SQLITE);")

    def execute(self, query: str, parameters: tuple[Any, ...] | list[Any] | None = None) -> list[tuple[Any, ...]]:
        """
        Wykonuje zapytanie. Dla zapytań SELECT tworzy nowe połączenie,
        co zapobiega blokowaniu między współbieżnymi zapytaniami.
        Dla DDL/INSERT/UPDATE używa współdzielonego połączenia.
        """
        is_read_only_query = query.strip().upper().startswith("SELECT")

        if is_read_only_query:
            # Krótkożyciowe połączenie dla zapytań SELECT
            conn = self.get_connection_for_query()
            try:
                if parameters:
                    result = conn.execute(query, parameters).fetchall()
                else:
                    result = conn.execute(query).fetchall()
                return result
            finally:
                conn.close()
        else:
            # DDL/DML przez współdzielone połączenie z blokadą
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

        # Usuń stare indeksy przed odświeżeniem (jeśli istnieją)
        self.execute("DROP INDEX IF EXISTS idx_m_daily_cashflow_day;")
        self.execute("DROP INDEX IF EXISTS idx_m_daily_cashflow_currency;")

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

        # Indeksy po odświeżeniu dla szybkich zapytań analitycznych
        self.execute("CREATE INDEX IF NOT EXISTS idx_m_daily_cashflow_day ON m_daily_cashflow(day)")
        self.execute("CREATE INDEX IF NOT EXISTS idx_m_daily_cashflow_currency ON m_daily_cashflow(currency)")

        # Indeksy na źródłowej tabeli oltp.invoices (SQLite), które przyspieszają zapytania DuckDB
        self.execute("CREATE INDEX IF NOT EXISTS idx_invoices_issue_date ON oltp.invoices(issue_date)")
        self.execute("CREATE INDEX IF NOT EXISTS idx_invoices_status ON oltp.invoices(status)")
        self.execute("CREATE INDEX IF NOT EXISTS idx_invoices_contractor_nip ON oltp.invoices(contractor_nip)")

    def close(self) -> None:
        with self._lock:
            if self._connection is not None:
                self._connection.close()
                self._connection = None
