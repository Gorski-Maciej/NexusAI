import duckdb
from pathlib import Path
from threading import Lock
from typing import Any
from dataclasses import dataclass
from core.config import AppConfig

@dataclass(slots=True)
class DuckDBLimits:
    """Hard limits for local analytical engine."""
    memory_limit: str = "2GB"
    threads: int = 2

class DuckDBManager:
    """Thread-safe manager for a singleton DuckDB connection."""

    def __init__(self, db_path: Path, limits: DuckDBLimits = DuckDBLimits()) -> None:
        self._db_path = db_path
        self._limits = limits
        self._lock = Lock()
        self._connection: duckdb.DuckDBPyConnection | None = None

    def connect(self) -> duckdb.DuckDBPyConnection:
        """Open (or return) connection with enforced limits."""
        with self._lock:
            if self._connection is None:
                connection = duckdb.connect(str(self._db_path))
                connection.execute(f"SET memory_limit='{self._limits.memory_limit}'")
                connection.execute(f"SET threads={self._limits.threads}")
                self._connection = connection
            return self._connection

    def execute(self, query: str, parameters: tuple[Any, ...] | None = None) -> list[tuple[Any, ...]]:
        """Execute query and return materialized rows."""
        connection = self.connect()
        if parameters:
            return connection.execute(query, parameters).fetchall()
        return connection.execute(query).fetchall()

    def close(self) -> None:
        """Close connection if currently open."""
        with self._lock:
            if self._connection is not None:
                self._connection.close()
                self._connection = None

    def upsert_invoice(self, invoice_data: dict):
        """Wstawia lub aktualizuje fakturę w DuckDB."""
        query = """
        INSERT OR REPLACE INTO invoices_replica (
            id, number, contractor_nip, amount_net,
            amount_gross, currency, status, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        params = (
            str(invoice_data['id']),
            invoice_data['number'],
            invoice_data['contractor_nip'],
            float(invoice_data['amount_net']),
            float(invoice_data['amount_gross']),
            invoice_data['currency'],
            invoice_data['status'],
            invoice_data['updated_at']
        )
        self.execute(query, params)

    def full_sync_from_sqlite(self, invoices: list[dict]):
        """Masowy import przy starcie aplikacji, aby wyrównać bazy."""
        with self._lock:
            # Czyścimy starą replikę i ładujemy świeże dane
            self.execute("DELETE FROM invoices_replica")
            for inv in invoices:
                self.upsert_invoice(inv)

class DuckDBAnalyticsEngine:
    """Silnik OLAP z limitami pamięci, odczytem Parquet i Cache KSeF."""

    def __init__(self, db_path: str = "app_data/nexus_olap.duckdb"):
        self.conn = duckdb.connect(db_path)
        # Konfiguracja limitów DuckDB (żeby nie zawiesić komputera księgowego)
        self.conn.execute("PRAGMA memory_limit='2GB'")
        self.conn.execute("PRAGMA threads=2;")

        # Tworzymy wirtualną tabelę na cache KSeF
        self.conn.execute("""
        CREATE TABLE IF NOT EXISTS ksef_cache (
            nip VARCHAR,
            invoice_number VARCHAR,
            issue_date DATE,
            ksef_reference VARCHAR
        );
        """)

    def check_ksef_cache(self, nip: str, invoice_number: str) -> str:
        """Błyskawiczne filtrowanie milionów rekordów lokalnie."""
        res = self.conn.execute("""
        SELECT ksef_reference
        FROM ksef_cache
        WHERE nip = ? AND invoice_number = ?
        """, (nip, invoice_number)).fetchone()
        return res[0] if res else None

    def archive_old_data_to_parquet(self, year: int, output_dir: Path):
        """Archiwizacja na zimno (Cold Storage)."""
        # Eksportujemy tabelę z SQLite prosto do silnie skompresowanego pliku Parquet
        parquet_path = output_dir / f"invoices_{year}.parquet"
        self.conn.execute(f"""
        COPY (SELECT * FROM sqlite_scan('app_data/dbs/{year}_nexus_oltp.db', 'invoices'))
        TO '{parquet_path}' (FORMAT PARQUET);
        """)

    def query_cross_years(self, archive_dir: Path):
        """Zapytania analityczne czytające pliki Parquet w locie."""
        # DuckDB może traktować dziesiątki plików Parquet jak jedną tabelę
        query = f"""
        SELECT contractor_nip, SUM(amount_gross) as total_spent
        FROM read_parquet('{archive_dir}/*.parquet')
        GROUP BY contractor_nip
        ORDER BY total_spent DESC
        LIMIT 10;
        """
        return self.conn.execute(query).df()

class CashflowPredictor:
    def __init__(self, conn):
        self.conn = conn

    def get_contractor_reliability(self):
        """Oblicza średnie spóźnienie dla każdego kontrahenta."""
        return self.conn.execute("""
        SELECT
            contractor_nip,
            contractor_name,
            AVG(date_diff('day', due_date, payment_date)) as avg_delay_days,
            COUNT(*) as invoice_count
        FROM invoices_replica
        WHERE status = 'PAID' AND payment_date IS NOT NULL
        GROUP BY 1, 2
        HAVING invoice_count > 2
        """).df()

    def predict_liquidity_gap(self, days_ahead=30):
        """Prognozuje saldo na podstawie faktur do zapłacenia, korygując datę o historyczne spóźnienia."""
        query = """
        WITH raw_data AS (
            SELECT
                i.amount_gross,
                -- Jeśli mamy historię, dodajemy średnie spóźnienie do daty wymagalności
                COALESCE(i.due_date + INTERVAL (rel.avg_delay_days) DAY, i.due_date) as expected_date,
                i.type -- 'PURCHASE' (minus) lub 'SALE' (plus)
            FROM invoices_replica i
            LEFT JOIN (
                SELECT contractor_nip, AVG(date_diff('day', due_date, payment_date)) as avg_delay_days
                FROM invoices_replica 
                WHERE status = 'PAID' 
                GROUP BY 1
            ) rel ON i.contractor_nip = rel.contractor_nip
            WHERE i.status != 'PAID'
        )
        SELECT
            expected_date,
            SUM(CASE WHEN type = 'SALE' THEN amount_gross ELSE -amount_gross END) as daily_delta
        FROM raw_data
        WHERE expected_date <= current_date + INTERVAL (?) DAY
        GROUP BY 1 
        ORDER BY 1
        """
        return self.conn.execute(query, [days_ahead]).df()

class FraudDetector:
    def __init__(self, conn):
        self.conn = conn

    def detect_round_number_spikes(self):
        """
        Wykrywa nienaturalne nagromadzenie faktur na równe kwoty
        pod koniec miesiąca od nowych dostawców.
        """
        return self.conn.execute("""
        SELECT
            contractor_nip,
            COUNT(*) as suspected_invoices,
            SUM(amount_gross) as total_value,
            -- Sprawdzamy czy kwoty kończą się na 00 lub 000 (np. 10 000, 5000)
            AVG(CASE WHEN amount_gross % 100 = 0 THEN 1 ELSE 0 END) as round_numbers_ratio
        FROM invoices_replica
        WHERE
            -- Ostatnie 5 dni dowolnego miesiąca
            day(issue_date) > 25
            -- Faktury kosztowe
            AND type = 'PURCHASE'
            -- Kontrahenci, z którymi nie było historii starszej niż 30 dni
            AND contractor_nip IN (
                SELECT contractor_nip FROM invoices_replica
                GROUP BY 1 
                HAVING min(issue_date) > current_date - INTERVAL 30 DAY
            )
        GROUP BY 1
        HAVING suspected_invoices >= 3 AND round_numbers_ratio > 0.8
        ORDER BY total_value DESC
        """).df()
