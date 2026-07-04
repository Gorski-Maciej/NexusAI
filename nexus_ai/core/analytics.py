# core/analytics.py
"""Core analytics -- Polars SQLContext + financial analytics queries.

- ``pl.sql(query, tables={...})`` -- natywny SQL w Polars 1.x
- Rejestracja DataFrame/LazyFrame jako tabel wirtualnych
- Mieszanie SQL z wyrażeniami Polars w jednym pipeline
- LazyFrame przez cały czas -- brak materializacji do końca
"""

from __future__ import annotations

import duckdb
import polars as pl

# ═══════════════════════════════════════════════════════════════════════════════
# Polars SQLContext -- natywna integracja SQL z expression API
# ═══════════════════════════════════════════════════════════════════════════════
# Polars 1.x oferuje ``pl.sql(query, tables={...})`` zamiast osobnego obiektu
# SQLContext. Ta klasa opakowuje to API w wygodny interfejs z rejestracją tabel
# i możliwością kontynuacji przez Polars expressions po zapytaniu SQL.
#
# Różnica względem DuckDB SQL:
#   DuckDB:  conn.execute(sql).pl() -> DataFrame
#   Polars:  pl.sql(sql, tables=...) -> LazyFrame -> expressions -> collect()
#
# Polars SQL jest lżejszy (bez zewnętrznego silnika), idealny dla analityki
# która już operuje na DataFrame/LazyFrame w pamięci.
# ═══════════════════════════════════════════════════════════════════════════════


@pl.api.register_lazyframe_namespace("sql")
class _SQLNamespace:
    """Rozszerza LazyFrame o metodę .sql.query() -- wygodny dostęp do SQL.

    Umożliwia::
        lazy = pl.LazyFrame(data)
        result = lazy.sql.query("SELECT * FROM self WHERE amount > 100")
        # 'self' to alias na bieżący LazyFrame
    """
    __slots__ = ('_lazy',)

    def __init__(self, lazy_frame: pl.LazyFrame):
        self._lazy = lazy_frame

    def query(self, sql: str) -> pl.LazyFrame:
        """Wykonaj zapytanie SQL na bieżącym LazyFrame.

        Używa ``pl.sql()`` z rejestracją bieżącego frame jako tabela 'self'.
        Pozwala na łączenie SQL z wyrażeniami Polars:

            lazy.sql.query("SELECT * FROM self WHERE amount > 1000")
                 .filter(pl.col("category") == "FUEL")
                 .collect()

        Args:
            sql: Zapytanie SQL, gdzie 'self' to alias bieżącego frame.

        Returns:
            LazyFrame z wynikiem zapytania.
        """
        return pl.sql(sql, tables={"self": self._lazy})


# Alias dla czytelności
PolarsSQL = _SQLNamespace


class PolarsSQLContext:
    """Polars SQLContext -- rejestruje wiele tabel i wykonuje zapytania SQL.

    Umożliwia rejestrację DataFrame/LazyFrame jako tabel wirtualnych,
    a następnie wykonywanie na nich zapytań SQL z możliwością kontynuacji
    przez Polars expressions.

    Przykład:
        ctx = PolarsSQLContext()
        ctx.register("invoices", invoices_df)
        ctx.register("payments", payments_lazy)

        # Zapytanie SQL łączące tabele
        result = ctx.sql('''
    __slots__ = ()
            SELECT i.id, i.amount_gross, p.payment_date
            FROM invoices i
            LEFT JOIN payments p ON i.id = p.invoice_id
            WHERE i.status = 'PAID'
        ''')

        # Kontynuacja przez Polars expressions
        final = (result
            .with_columns([
                (pl.col("amount_gross") * 0.23).alias("estimated_vat"),
            ])
            .collect(streaming=True)
            .shrink_dtype()
        )

    - ``pl.sql()`` -- natywny SQL Polars bez zewnętrznego silnika
    - LazyFrame -- brak materializacji do .collect()
    - Mieszanie SQL z wyrażeniami -- pełna moc Polars
    - Streaming + shrink_dtype -- wydajność dla dużych zbiorów
    """

    def __init__(self) -> None:
        self._tables: dict[str, pl.LazyFrame | pl.DataFrame] = {}

    def register(self, name: str, data: pl.LazyFrame | pl.DataFrame) -> None:
        """Zarejestruj DataFrame/LazyFrame jako tabelę wirtualną.

        Args:
            name: Nazwa tabeli (używana w FROM, JOIN itp.).
            data: Polars DataFrame lub LazyFrame.
        """
        self._tables[name] = data

    def register_many(self, **tables: pl.LazyFrame | pl.DataFrame) -> None:
        """Zarejestruj wiele tabel naraz.

        Przykład:
            ctx.register_many(
                invoices=invoices_df,
                payments=payments_lazy,
                contracts=contracts_df,
            )

        Args:
            **tables: Nazwa -> DataFrame/LazyFrame.
        """
        self._tables.update(tables)

    def sql(self, query: str) -> pl.LazyFrame:
        """Wykonaj zapytanie SQL na zarejestrowanych tabelach.

        Zwraca LazyFrame -- można kontynuować z wyrażeniami Polars.

        Args:
            query: Zapytanie SQL odnoszące się do zarejestrowanych tabel.

        Returns:
            LazyFrame z wynikiem.

        Raises:
            ValueError: Jeśli żadna tabela nie jest zarejestrowana.
        """
        if not self._tables:
            raise ValueError(
                "No tables registered in PolarsSQLContext. "
                "Call .register() or .register_many() first."
            )
        return pl.sql(query, tables=self._tables)

    def execute_sql(
        self,
        query: str,
        *,
        streaming: bool = True,
        shrink: bool = True,
    ) -> pl.DataFrame:
        """Wykonaj zapytanie SQL i od razu zbierz wynik z optymalizacjami.

        Połączenie SQL + streaming + shrink_dtype w jednym wywołaniu.

        Args:
            query: Zapytanie SQL.
            streaming: Jeśli True, używa streaming engine dla dużych danych.
            shrink: Jeśli True, stosuje shrink_dtype() po kolekcji.

        Returns:
            DataFrame zoptymalizowany pamięciowo.
        """
        lazy = self.sql(query)
        df = lazy.collect(streaming=streaming)
        if shrink:
            df = df.shrink_dtype()
        return df

    def tables(self) -> list[str]:
        """Zwraca listę zarejestrowanych tabel."""
        return list(self._tables.keys())

    def unregister(self, name: str) -> None:
        """Usuń tabelę z rejestru."""
        self._tables.pop(name, None)

    def clear(self) -> None:
        """Wyczyść wszystkie zarejestrowane tabele."""
        self._tables.clear()

    def __len__(self) -> int:
        return len(self._tables)


# ═══════════════════════════════════════════════════════════════════════════════
# Financial analytics -- Polars SQL + expressions pipeline
# ═══════════════════════════════════════════════════════════════════════════════


def financial_analysis_with_polars_sql(
    invoices: pl.DataFrame | pl.LazyFrame,
    payments: pl.DataFrame | pl.LazyFrame,
    contracts: pl.DataFrame | pl.LazyFrame | None = None,
    *,
    streaming: bool = True,
) -> pl.DataFrame:
    """Przykład integracji Polars SQL z expression API dla analityki finansowej.

    Pipeline:
    1. Rejestracja DataFrame/LazyFrame jako tabel wirtualnych
    2. Zapytanie SQL łączące faktury, płatności i kontrakty
    3. Kontynuacja przez Polars expressions (cast, with_columns, filter)
    4. Streaming collect + shrink_dtype dla wydajności

    - ``pl.sql()`` -- SQL bez zewnętrznego silnika DuckDB
    - Mieszanie SQL z wyrażeniami -- pełna swoboda
    - LazyFrame przez cały pipeline -- optymalizacja przez Polars optimizer

    Args:
        invoices: Polars DataFrame/LazyFrame z fakturami.
        payments: Polars DataFrame/LazyFrame z płatnościami.
        contracts: Opcjonalnie DataFrame/LazyFrame z kontraktami.
        streaming: Jeśli True, używa streaming (domyślnie True).

    Returns:
        DataFrame z analizą finansową (shrink_dtype).
    """
    ctx = PolarsSQLContext()
    ctx.register_many(
        invoices=invoices,
        payments=payments,
    )
    if contracts is not None:
        ctx.register("contracts", contracts)

    # ── KROK 1: SQL -- agregacje miesięczne z window function ─────
    # SQL jest naturalny dla:
    #   - Window functions (SUM OVER, ROW_NUMBER)
    #   - CTE (WITH)
    #   - Złożone JOIN między wieloma tabelami
    # Po SQL kontynuujemy z Polars expressions dla:
    #   - Transformacji (cast, with_columns)
    #   - Warunków (when/then/otherwise)
    #   - Optymalizacji (streaming, shrink_dtype)
    base_query = """
    WITH monthly_payments AS (
        SELECT
            i.id AS invoice_id,
            i.contractor_nip,
            i.amount_gross,
            i.vat_amount,
            i.kind,
            i.issue_date,
            p.payment_date,
            p.amount AS payment_amount,
            CASE
                WHEN p.status = 'COMPLETED' THEN p.amount
                ELSE 0
            END AS collected_amount
        FROM invoices i
        LEFT JOIN payments p ON i.id = p.invoice_id
        WHERE i.status IN ('APPROVED', 'PAID')
    )
    SELECT
        contractor_nip,
        kind,
        COUNT(*) AS invoice_count,
        SUM(amount_gross) AS total_gross,
        SUM(collected_amount) AS total_collected,
        SUM(amount_gross) - SUM(collected_amount) AS outstanding,
        SUM(vat_amount) AS total_vat
    FROM monthly_payments
    GROUP BY contractor_nip, kind
    """

    if contracts is not None:
        base_query += """
    HAVING contractor_nip IN (
        SELECT nip FROM contracts WHERE status = 'ACTIVE'
    )
    """

    base_query += """
    ORDER BY total_gross DESC
    """

    lazy = ctx.sql(base_query)

    # ── KROK 2: Polars expressions -- transformacje po SQL ───────
    # Po SQL używamy wyrażeń Polars dla:
    #   - Obliczeń warunkowych (pl.when)
    #   - Zaawansowanych transformacji
    #   - Czytelniejszej składni niż SQL CASE
    result = lazy.with_columns(
        [
            # Cast na Float64 dla spójności
            pl.col("total_gross").cast(pl.Float64),
            pl.col("total_collected").cast(pl.Float64).fill_null(0.0),
            pl.col("outstanding").cast(pl.Float64).fill_null(0.0),
            pl.col("total_vat").cast(pl.Float64).fill_null(0.0),
            # Kategoryzacja windykacyjna przez Polars expressions
            pl.when(pl.col("outstanding") <= 0)
            .then(pl.lit("PAID_IN_FULL"))
            .when(pl.col("outstanding") < pl.col("total_gross") * 0.3)
            .then(pl.lit("PARTIAL"))
            .otherwise(pl.lit("HIGH_RISK"))
            .alias("collection_status"),
            # Wskaźnik ściągalności
            (pl.col("total_collected") / pl.col("total_gross") * 100.0)
            .round(1)
            .fill_null(0.0)
            .alias("collection_rate_pct"),
            # Udział VAT w wartości brutto
            (pl.col("total_vat") / pl.col("total_gross") * 100.0)
            .round(1)
            .fill_null(0.0)
            .alias("vat_share_pct"),
        ]
    )

    # ── KROK 3: Streaming collect + shrink_dtype ──────────────────
    return result.collect(streaming=streaming).shrink_dtype()


def run_polars_sql_query(
    query: str,
    tables: dict[str, pl.DataFrame | pl.LazyFrame],
    *,
    streaming: bool = True,
    shrink: bool = True,
) -> pl.DataFrame:
    """Wykonaj dowolne zapytanie SQL przez Polars SQL engine.

    Najprostszy interfejs: podaj SQL + słownik tabel -> dostajesz DataFrame.
    Idealne dla ad-hoc analityki finansowej.

    Args:
        query: Zapytanie SQL (standard SQL obsługiwany przez Polars).
        tables: Słownik {nazwa_tabeli: DataFrame/LazyFrame}.
        streaming: Jeśli True, collect(streaming=True).
        shrink: Jeśli True, shrink_dtype() po kolekcji.

    Returns:
        DataFrame z wynikiem.

    Przykład:
        from nexus_ai.core.analytics import run_polars_sql_query
        import polars as pl

        df = run_polars_sql_query(
            '''
            SELECT category, SUM(amount_gross) AS total
            FROM invoices
            WHERE status = 'PAID'
            GROUP BY category
            ORDER BY total DESC
            ''',
            tables={"invoices": my_invoices_df},
            streaming=True,
            shrink=True,
        )
        print(df)
    """
    ctx = PolarsSQLContext()
    ctx.register_many(**tables)
    return ctx.execute_sql(query, streaming=streaming, shrink=shrink)


# ═══════════════════════════════════════════════════════════════════════════════
# Legacy -- DuckDB + Polars (zachowane dla kompatybilności)
# ═══════════════════════════════════════════════════════════════════════════════


def get_cashflow_forecast(db_path: str = "data/nexus_analytics.duckdb") -> pl.LazyFrame:
    """Get cashflow forecast from DuckDB, returns LazyFrame.

    LazyFrame pozwala na:
    - Optymalizację zapytań przez optimizer Polars (predicate/projection pushdown)
    - Streaming dla danych > RAM (collect(streaming=True))
    - Łączenie z innymi LazyFrame przed kolekcją
    - explain(optimized=True) dla wglądu w plan

    Zwraca pl.LazyFrame -- caller decyduje kiedy .collect()
    """
    conn = duckdb.connect(db_path)
    try:
        query = """
        WITH DailyFlows AS (
            SELECT
                due_date,
                SUM(CASE WHEN type = 'SALE' THEN amount_gross ELSE 0 END) as daily_in,
                SUM(CASE WHEN type = 'COST' THEN amount_gross ELSE 0 END) as daily_out
            FROM invoices
            WHERE due_date >= CURRENT_DATE
              AND due_date <= CURRENT_DATE + INTERVAL 30 DAY
            GROUP BY due_date
        )
        SELECT
            due_date,
            daily_in,
            daily_out,
            SUM(daily_in - daily_out) OVER (ORDER BY due_date ASC) as projected_balance
        FROM DailyFlows
        ORDER BY due_date;
        """
        df = conn.execute(query).pl()  # DuckDB natywnie zwraca Polars DataFrame

        # Konwertujemy DataFrame na LazyFrame dla optymalizacji.
        lazy = df.lazy()

        # Castujemy kolumny na oczekiwane typy przed zwróceniem.
        # Dzięki temu caller ma gwarancję typów bez własnego cast().
        schema = {
            "due_date": pl.Date,
            "daily_in": pl.Float64,
            "daily_out": pl.Float64,
            "projected_balance": pl.Float64,
        }
        lazy = lazy.cast(schema)

        return lazy
    finally:
        conn.close()


def collect_with_streaming(lazy: pl.LazyFrame, streaming: bool = True) -> pl.DataFrame:
    """Collect LazyFrame with optional streaming.

    ``collect(streaming=True)`` wykonuje zapytanie w batchach,
    nie ładując wszystkich danych do RAM. Idealne dla prognoz
    ponad 1M wierszy.

    Po kolekcji automatycznie stosuje ``shrink_dtype()`` dla
    redukcji RAM o ~50% na typach liczbowych.

    Args:
        lazy: LazyFrame do zebrania.
        streaming: Jeśli True, używa streaming engine.

    Returns:
        DataFrame z shrink_dtype() -- zminimalizowane typy.
    """
    df = lazy.collect(streaming=streaming)
    return df.shrink_dtype()
