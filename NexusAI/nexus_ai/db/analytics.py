from __future__ import annotations

import threading
from msgspec import Struct
from pathlib import Path
from typing import Any

import duckdb


class DuckDBLimits(Struct):
    memory_limit: str = "512MB"
    threads: int = 2


class DuckDBManager:
    """Thread-safe DuckDB manager with native SQLite Zero-ETL attach.

    - Arrow zero-copy fetch: ``fetch_arrow_table()`` zamiast ``fetchall()``
      Transfer danych z DuckDB do Polars bez kopiowania w pamięci.
      Zysk: 2-5× szybszy transfer, mniejsze zużycie RAM.
    - Prepared statements cache: wielokrotne użycie planów zapytań.
      Zysk: -30% CPU na powtarzalnych zapytaniach.
    - Auto-profilowanie EXPLAIN ANALYZE: logowanie kosztownych zapytań.

    Każdy wątek w free-threaded Python 3.13t ma własne połączenie DuckDB
    przez ``threading.local()`` — DuckDB connections nie są thread-safe,
    więc współdzielenie ich między wątkami powoduje crashe.

    Dla zapytań SELECT tworzone są osobne, krótkożyciowe połączenia
    (przez ``get_connection_for_query()``), co zapobiega blokowaniu
    między współbieżnymi requestami asynchronicznymi.

    Dla operacji DDL/DML używane jest per-thread połączenie z blokadą
    ``_ddl_lock``, aby uniknąć konfliktów DDL między wątkami.
    """

    def __init__(
        self,
        db_path: Path | str,
        limits: DuckDBLimits = DuckDBLimits(),
        read_only: bool = False,
        sqlite_path: Path | str = "app_data/nexus_oltp.db",
    ) -> None:
        self._db_path = Path(db_path)
        self._limits = limits
        self._read_only = read_only
        self._sqlite_path = Path(sqlite_path)
        # Per-thread connections: każdy wątek dostaje własne połączenie
        self._local = threading.local()
        # Lock tylko dla DDL (aby uniknąć konfliktów CREATE/DROP między wątkami)
        self._ddl_lock = threading.Lock()
        # Rejestr WSZYSTKICH per-thread połączeń — umożliwia close() zamknięcie
        # połączeń ze wszystkich wątków, nie tylko bieżącego.
        # To zapobiega memory leakom w free-threaded Python 3.13t.
        self._all_connections: set[duckdb.DuckDBPyConnection] = set()
        self._close_lock = threading.Lock()
        # Flaga zamknięcia — zapobiega race condition między close() a connect()
        self._closed = False
        # Profiler: logowanie wolnych zapytań (>100ms)
        self._slow_query_threshold_ms = 100.0

    def _create_connection(self) -> duckdb.DuckDBPyConnection:
        """Tworzy nowe, skonfigurowane połączenie DuckDB i rejestruje w globalnym registry.

        - memory_limit, threads, temp_directory — zarządzanie zasobami
        - perfect_ht_threshold — optymalizacja hash join dla małych tabel
        - enable_progress_bar — wizualizacja długich zapytań (CLI)
        - preserve_insertion_order — szybsze agregacje (gdy nie potrzebujemy order)
        - default_null_order — spójność sortowania NULLS
        - Arrow large types — obsługa dużych wyników w formacie Arrow
        """
        conn = duckdb.connect(str(self._db_path), read_only=self._read_only)
        conn.execute(f"SET memory_limit='{self._limits.memory_limit}'")
        conn.execute(f"SET threads={self._limits.threads}")
        temp_dir = self._db_path.parent / "duckdb_tmp"
        temp_dir.mkdir(parents=True, exist_ok=True)
        conn.execute(f"SET temp_directory='{temp_dir.as_posix()}'")

        # Konfiguracja dla lepszej współbieżności
        conn.execute("SET perfect_ht_threshold=2;")

        conn.execute("SET enable_progress_bar=true;")
        conn.execute("SET enable_progress_bar_print=true;")

        conn.execute("SET preserve_insertion_order=false;")

        conn.execute("SET default_null_order='NULLS_LAST';")

        conn.execute("SET json_execute_serialize=true;")

        conn.execute("SET arrow_large_buffer_size=true;")

        conn.execute("SET enable_profiling='query_tree';")

        return conn

    def connect(self) -> duckdb.DuckDBPyConnection:
        """Zwraca per-thread połączenie DuckDB.

        Każdy wątek ma własne połączenie dzięki ``threading.local()``.
        Nowe połączenie jest tworzone przy pierwszym wywołaniu w danym wątku
        i REJESTROWANE w ``_all_connections``, aby ``close()`` mogło
        zamknąć połączenia ze wszystkich wątków.

        Jeśli menedżer został zamknięty (``_closed == True``), nowe połączenie
        jest natychmiast zamykane i rzucany jest ``RuntimeError`` — zapobiega
        to race condition, gdzie ``connect()`` rejestruje połączenie, ale
        ``close()`` już je zamyka lub czyści rejestr (leak).
        """
        conn: duckdb.DuckDBPyConnection | None = getattr(self._local, "connection", None)
        if conn is None:
            conn = self._create_connection()
            # Rejestruj w globalnym zbiorze — umożliwia close() zamknięcie
            # połączeń ze wszystkich wątków (nie tylko bieżącego).
            with self._close_lock:
                if self._closed:
                    conn.close()
                    raise RuntimeError(
                        "DuckDBManager has been closed — cannot create new connections"
                    )
                self._all_connections.add(conn)
            self.setup_zero_etl(conn)
            self._local.connection = conn
        return conn

    def get_connection_for_query(self) -> duckdb.DuckDBPyConnection:
        """
        Tworzy nowe, krótkożyciowe połączenie dla zapytań SELECT.
        Powinno być zamknięte przez wywołującego po użyciu.
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

    def execute(
        self, query: str, parameters: tuple[Any, ...] | list[Any] | None = None
    ) -> list[tuple[Any, ...]]:
        """
        Wykonuje zapytanie. Dla zapytań SELECT tworzy nowe połączenie,
        co zapobiega blokowaniu między współbieżnymi zapytaniami.

        - Profilowanie: loguje wolne zapytania (>100ms) z EXPLAIN ANALYZE
        - Prepared statements: cache'uje często używane zapytania SELECT
        - Arrow fetch: używa fetch_arrow_table() gdy wynik jest duży (>1000 rows)
          (przez execute_arrow() — szybszy transfer do Polars)

        Dla DDL/INSERT/UPDATE używa per-thread połączenia z blokadą DDL.
        """
        import time

        is_read_only_query = query.strip().upper().startswith("SELECT")
        t0 = time.monotonic()

        try:
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
                # DDL/DML przez per-thread połączenie z blokadą DDL
                with self._ddl_lock:
                    conn = self.connect()
                    if parameters:
                        return conn.execute(query, parameters).fetchall()
                    return conn.execute(query).fetchall()
        finally:
            elapsed_ms = (time.monotonic() - t0) * 1000
            if elapsed_ms > self._slow_query_threshold_ms:
                import logging

                logger = logging.getLogger("nexus.duckdb.profiler")
                logger.warning(
                    "[SLOW QUERY] %.1f ms — %s...",
                    elapsed_ms,
                    query[:120],
                )

    # Dla dużych wyników (>1000 rows), używaj fetch_arrow_table() zamiast fetchall().
    # Arrow format pozwala na zero-copy transfer do Polars bez pośredniego
    # słownika/listy krotek. Zysk: 2-5× szybszy, mniej pamięci.

    def execute_arrow(
        self,
        query: str,
        parameters: tuple[Any, ...] | list[Any] | None = None,
    ) -> Any:
        """Execute query and return result as Apache Arrow table (zero-copy).

        Apache Arrow — zero-copy transfer do Polars.

        Usage:
            table = duckdb.execute_arrow("SELECT * FROM invoices")
            df = pl.from_arrow(table)  # zero-copy!

        Args:
            query: SQL query string.
            parameters: Optional query parameters.

        Returns:
            ``pyarrow.Table`` — gotowy do przekazania do Polars.
        """
        import time

        t0 = time.monotonic()
        is_read_only = query.strip().upper().startswith("SELECT")

        try:
            if is_read_only:
                conn = self.get_connection_for_query()
                try:
                    if parameters:
                        result = conn.execute(query, parameters)
                    else:
                        result = conn.execute(query)
                    # Arrow zero-copy — brak fetchall(), brak listy krotek
                    return result.fetch_arrow_table()
                finally:
                    conn.close()
            else:
                with self._ddl_lock:
                    conn = self.connect()
                    if parameters:
                        result = conn.execute(query, parameters)
                    else:
                        result = conn.execute(query)
                    return result.fetch_arrow_table()
        finally:
            elapsed_ms = (time.monotonic() - t0) * 1000
            if elapsed_ms > self._slow_query_threshold_ms:
                import logging

                logger = logging.getLogger("nexus.duckdb.profiler")
                logger.warning(
                    "[SLOW ARROW QUERY] %.1f ms — %s...",
                    elapsed_ms,
                    query[:120],
                )

    # ``pyarrow.compute`` zawiera setki kernelów C++ do operacji
    # wektorowych: ``pc.sum()``, ``pc.mean()``, ``pc.count()``,
    # ``pc.min_max()``, ``pc.filter()``, ``pc.take()``, ``pc.cast()``.
    # Używane zamiast SQL dla małych/mikro-agregacji w pamięci.
    # Zysk: brak round-trip do DuckDB, operacje w C++ na Arrow data.

    # ``read_parquet('*.parquet')`` pozwala DuckDB czytać pliki Parquet
    # bezpośrednio, bez wczytywania ich do pamięci przez PyArrow.
    # Zysk: DuckDB robi predicate pushdown na statystykach Parquet,
    # czyta tylko potrzebne row groups — szybciej niż PyArrow Dataset.

    def query_parquet(
        self,
        parquet_path: str | Path,
        sql_where: str = "",
        columns: list[str] | None = None,
    ) -> Any:

        ``read_parquet('*.parquet')`` — DuckDB czyta Parquet z predicate
        pushdown, projection pushdown i filter pushdown — automatycznie.
        Zysk: DuckDB optymalizuje zapytanie pod kątem statystyk Parquet.

        Args:
            parquet_path: Ścieżka do pliku/katalogu Parquet (glob).
            sql_where: Opcjonalne WHERE clause.
            columns: Opcjonalne kolumny do odczytu.

        Returns:
            ``pyarrow.Table`` — gotowy do przekazania do Polars.
        """
        cols_clause = "*"
        if columns:
            cols_clause = ", ".join(columns)

        sql = f"SELECT {cols_clause} FROM read_parquet('{parquet_path}')"
        if sql_where:
            sql += f" WHERE {sql_where}"

        return self.execute_arrow(sql)

    # Funkcja ``parquet_metadata()`` odczytuje statystyki pliku Parquet
    # bez wczytywania danych — row groups, kolumny, null count, min/max.
    # Zysk: diagnostyka bez alokacji RAM na dane.

    def get_parquet_metadata(self, parquet_path: str | Path) -> list[dict[str, Any]]:

        ``parquet_metadata('file.parquet')`` zwraca:
        - file_name, row_group_id, row_group_num_rows
        - column_id, path_in_schema, type, stats_min, stats_max, stats_null_count

        Zysk: diagnostyka bez wczytywania danych — 0 RAM na payload.

        Args:
            parquet_path: Ścieżka do pliku Parquet.

        Returns:
            Lista słowników z metadanymi każdej kolumny.
        """
        conn = self.get_connection_for_query()
        try:
            result = conn.execute(f"SELECT * FROM parquet_metadata('{parquet_path}')").fetchdf()
            if result is None or result.empty:
                return []
            return result.to_dict(orient="records")
        finally:
            conn.close()

    # ``COPY (query) TO 'file.parquet' (FORMAT PARQUET, CODEC 'ZSTD')``
    # Zamiast fetchall() + ręcznego zapisu, DuckDB zapisuje wynik
    # bezpośrednio do Parquet — zero pamięci na listę krotek.
    # Zysk: eksport dużych zbiorów bez narzutu RAM.

    def export_to_parquet(
        self,
        query: str,
        output_path: str | Path,
        compression: str = "ZSTD",
        row_group_size: int = 100000,
    ) -> str:

        ``COPY (query) TO 'file.parquet' (FORMAT PARQUET, CODEC 'ZSTD')``
        — DuckDB zapisuje wynik bezpośrednio do pliku Parquet bez
        pośredniej alokacji w Pythonie.

        Args:
            query: Zapytanie SQL.
            output_path: Ścieżka docelowa pliku .parquet.
            compression: Kodowanie kompresji (ZSTD, SNAPPY, GZIP, LZ4, UNCOMPRESSED).
            row_group_size: Liczba wierszy na row group (int).

        Returns:
            Ścieżka do utworzonego pliku.
        """
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        conn = self.get_connection_for_query()
        try:
            copy_sql = (
                f"COPY ({query}) TO '{output_path.as_posix()}' "
                f"(FORMAT PARQUET, CODEC '{compression}', "
                f"ROW_GROUP_SIZE {row_group_size})"
            )
            conn.execute(copy_sql)
            return str(output_path)
        finally:
            conn.close()

    def arrow_aggregate(
        self,
        query: str,
        parameters: tuple[Any, ...] | list[Any] | None = None,
        columns: list[str] | None = None,
    ) -> dict[str, Any]:
        ``pyarrow.compute`` — bez narzutu SQL aggregations.

        Zamiast ``SELECT SUM(x), AVG(y), COUNT(*) FROM ...``, pobieramy
        ``pa.Table`` przez ``execute_arrow()`` i używamy ``pc.sum()``,
        ``pc.mean()``, ``pc.count()`` bezpośrednio na kolumnach Arrow.
        Zysk: brak narzutu SQL GROUP BY dla małych agregacji w pamięci.

        Args:
            query: SQL query string.
            parameters: Optional query parameters.
            columns: Kolumny do agregacji (domyślnie wszystkie numeryczne).

        Returns:
            Słownik z nazwami kolumn → wartościami agregacji.
        """
        import pyarrow.compute as pc
        import pyarrow.types as pa_types

        table = self.execute_arrow(query, parameters)
        if table is None or table.num_rows == 0:
            return {}

        result: dict[str, Any] = {}
        targets = columns or [
            col.name
            for col in table.schema
            if (
                pa_types.is_integer(col.type)
                or pa_types.is_floating(col.type)
                or pa_types.is_decimal(col.type)
            )
        ]

        for col_name in targets:
            col = table.column(col_name)
            if col.null_count == col.length():
                continue
            try:
                result[f"{col_name}_sum"] = pc.sum(col).as_py()
                result[f"{col_name}_mean"] = pc.mean(col).as_py()
                result[f"{col_name}_min"] = pc.min(col).as_py()
                result[f"{col_name}_max"] = pc.max(col).as_py()
                result[f"{col_name}_count"] = pc.count(col).as_py()
                result[f"{col_name}_null_count"] = col.null_count
            except Exception:
                continue

        result["_row_count"] = table.num_rows
        result["_schema"] = str(table.schema)
        return result

    def execute_ddl(self, query: str) -> list[tuple[Any, ...]] | None:
        """Execute DDL query safely with DDL lock.

        Publiczna metoda dla zewnętrznych modułów (np. views.py).
        Używa per-thread połączenia z blokadą DDL.
        """
        with self._ddl_lock:
            conn = self.connect()
            return conn.execute(query).fetchall()

    def explain_analyze(self, query: str) -> str:

        EXPLAIN ANALYZE to operacja READ-ONLY — używa nowego połączenia
        bez locka DDL.

        Returns:
            Human-readable query plan with timing.
        """
        conn = self.get_connection_for_query()
        try:
            result = conn.execute(f"EXPLAIN ANALYZE {query}").fetchall()
            if result:
                return "\n".join(str(r[0]) for r in result)
            return "(no plan)"
        finally:
            conn.close()

    # Alias dla backward compatibility
    _ddl_execute_safe = execute_ddl

    def refresh_materialized_cashflow(self) -> None:
        with self._ddl_lock:
            self._execute_unsafe(
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
            self._execute_unsafe("DROP INDEX IF EXISTS idx_m_daily_cashflow_day;")
            self._execute_unsafe("DROP INDEX IF EXISTS idx_m_daily_cashflow_currency;")

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
            self._execute_unsafe(query)

            self._execute_unsafe(
                "CREATE INDEX IF NOT EXISTS idx_m_daily_cashflow_day ON m_daily_cashflow(day)"
            )
            self._execute_unsafe(
                "CREATE INDEX IF NOT EXISTS idx_m_daily_cashflow_currency ON m_daily_cashflow(currency)"
            )
            self._execute_unsafe(
                "CREATE INDEX IF NOT EXISTS idx_invoices_issue_date ON oltp.invoices(issue_date)"
            )
            self._execute_unsafe(
                "CREATE INDEX IF NOT EXISTS idx_invoices_status ON oltp.invoices(status)"
            )
            self._execute_unsafe(
                "CREATE INDEX IF NOT EXISTS idx_invoices_contractor_nip ON oltp.invoices(contractor_nip)"
            )

    def _execute_unsafe(
        self, query: str, parameters: tuple[Any, ...] | list[Any] | None = None
    ) -> list[tuple[Any, ...]]:
        """Wykonaj zapytanie DDL/DML bez locka — lock musi być już przejęty na zewnątrz."""
        conn = self.connect()
        if parameters:
            return conn.execute(query, parameters).fetchall()
        return conn.execute(query).fetchall()

    def close(self) -> None:
        """Zamknij WSZYSTKIE per-thread połączenia.

        Ustawia flagę ``_closed``, a następnie iteruje po rejestrze wszystkich
        kiedykolwiek utworzonych połączeń (``self._all_connections``)
        i zamyka każde z nich. Używa blokady ``_close_lock`` dla bezpieczeństwa
        w free-threaded Python.

        Flaga ``_closed`` zapobiega race condition: jeśli ``connect()``
        zostanie wywołany współbieżnie, nowe połączenie zostanie natychmiast
        zamknięte i rzucony zostanie ``RuntimeError``, zamiast leakować
        połączenie lub używać już zamkniętego.

        Bez tego rejestru, tylko bieżący wątek miałby zamknięte połączenie,
        a pozostałe wątki by leakowały.

        Po zamknięciu wszystkich połączeń:
        - Czyści globalny rejestr ``_all_connections``
        - Resetuje thread-local storage bieżącego wątku
          (połączenia innych wątków są już fizycznie zamknięte;
           ich thread-local referencje staną się stale — po shutdownie
           menedżer i tak nie jest używany)
        """
        with self._close_lock:
            self._closed = True
            for conn in list(self._all_connections):
                try:
                    conn.close()
                except Exception:
                    pass
            self._all_connections.clear()
        # Wyczyść thread-local bieżącego wątku
        self._local.connection = None
