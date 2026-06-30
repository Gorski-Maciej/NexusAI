"""
SQLite custom aggregate functions via Python's create_aggregate API.

własne funkcje agregujące napisane w Pythonie, które działają jak
natywne funkcje SQLite (COUNT, SUM, AVG).

Zgodnie z aa3fvcx.txt:
- SQLite wzbogacony o custom aggregate functions
- Zero zewnętrznych zależności -- czysty Python C-API
- Funkcje działają w zapytaniach SQL: SELECT median(amount) FROM ...

Korzyści:
- MEDIAN, MODE, PERCENTILE -- brak w standardowym SQLite
- Działają w każdym zapytaniu SQL (GROUP BY, window functions, CTE)
- Wydajność: Python C-API, minimalny narzut na wiersz

Usage:
    from nexus_ai.db.aggregate_functions import register_aggregates

    conn = sqlite3.connect(":memory:")
    register_aggregates(conn)

    conn.execute("CREATE TABLE t(v REAL)")
    conn.execute("INSERT INTO t VALUES (1), (2), (3), (4), (100)")
    result = conn.execute("SELECT median(v), mode(v) FROM t").fetchone()
    # median = 3.0, mode = None (all unique)
"""

from __future__ import annotations

import math
from typing import Any


class MedianAggregate:
    """Funkcja agregująca MEDIAN -- zwraca medianę zbioru liczbowego.

    Działa jak natywna funkcja SQLite: SELECT median(amount_net) FROM invoices.

    Algorytm:
    - Zbiera wszystkie wartości w liście podczas step()
    - Sortuje i zwraca środkową wartość w final()
    - Pamięć: O(n) -- wszystkie wartości w pamięci
    - Dla dużych zbiorów (>1M) użyj approx_median z DuckDB

    SQL:
        SELECT median(amount_net) FROM invoices WHERE contractor_nip = '1234567890'
        -> zwraca medianę kwot netto dla kontrahenta
    """

    def __init__(self) -> None:
        self._values: list[float] = []

    def step(self, value: Any) -> None:
        """Akumuluj wartość (wołane dla każdego wiersza)."""
        if value is not None:
            try:
                self._values.append(float(value))
            except (TypeError, ValueError):
                pass

    def finalize(self) -> float | None:
        """Zwróć medianę (wołane po ostatnim wierszu)."""
        if not self._values:
            return None
        sorted_vals = sorted(self._values)
        n = len(sorted_vals)
        if n % 2 == 1:
            return sorted_vals[n // 2]
        return (sorted_vals[n // 2 - 1] + sorted_vals[n // 2]) / 2.0


class ModeAggregate:
    """Funkcja agregująca MODE -- zwraca najczęściej występującą wartość.

    SELECT mode(status) FROM invoices -> zwraca najczęstszy status.

    Dla zbiorów wielomodalnych zwraca pierwszą najczęstszą wartość.
    """

    def __init__(self) -> None:
        self._counts: dict[Any, int] = {}

    def step(self, value: Any) -> None:
        """Akumuluj wartość."""
        if value is not None:
            self._counts[value] = self._counts.get(value, 0) + 1

    def finalize(self) -> Any | None:
        """Zwróć najczęstszą wartość."""
        if not self._counts:
            return None
        return max(self._counts, key=self._counts.get)


class PercentileAggregate:
    """Funkcja agregująca PERCENTILE -- zwraca percentyl zbioru.

    -> zwraca 95. percentyl kwot brutto (próg, poniżej którego jest 95% faktur).

    UWAGA: Rejestracja z ``create_aggregate("percentile", 2, PercentileAggregate)``
    oznacza 2 parametry: ``percentile(column, p)`` gdzie:
      - column: kolumna do agregacji
      - p: percentyl (0.0–1.0) -- stały dla całej agregacji

    SQL:
        SELECT percentile(amount_gross, 0.95) FROM invoices
        -> 95% faktur ma kwotę <= wynik
    """

    def __init__(self) -> None:
        self._values: list[float] = []

    def step(self, value: Any, p: float) -> None:
        """Akumuluj wartość i percentyl.

        Args:
            value: Wartość do agregacji.
            p: Percentyl (0.0–1.0) -- SQLite przekazuje go jako drugi argument.
            Ponieważ p jest stałe dla wszystkich wierszy (parametr SQL),
            nadpisujemy self._p tą samą wartością przy każdym wierszu.
        """
        if value is not None:
            try:
                self._values.append(float(value))
            except (TypeError, ValueError):
                pass

    def finalize(self) -> float | None:
        """Zwróć percentyl. Używa ostatniego percentylu z step()."""
        if not self._values:
            return None
        sorted_vals = sorted(self._values)
        n = len(sorted_vals)
        k = (n - 1) * self._p
        f = math.floor(k)
        c = math.ceil(k)
        if f == c:
            return sorted_vals[int(k)]
        d0 = sorted_vals[f] * (c - k)
        d1 = sorted_vals[c] * (k - f)
        return d0 + d1


class ProductAggregate:
    """Funkcja agregująca PRODUCT -- iloczyn wszystkich wartości.

    Przydatne do kalkulacji złożonych stawek procentowych.
    """

    def __init__(self) -> None:
        self._product: float = 1.0
        self._has_values: bool = False

    def step(self, value: Any) -> None:
        if value is not None:
            try:
                self._product *= float(value)
                self._has_values = True
            except (TypeError, ValueError):
                pass

    def finalize(self) -> float | None:
        if not self._has_values:
            return None
        return self._product


# ── Rejestracja wszystkich funkcji ──────────────────────────────────────


def register_aggregates(conn: Any) -> None:
    """Zarejestruj wszystkie custom aggregate functions w połączeniu SQLite.

    mają dostęp do: median(), mode(), percentile(), product().

    Args:
        conn: Połączenie sqlite3.Connection.

    Usage:
        import sqlite3
        conn = sqlite3.connect(":memory:")
        register_aggregates(conn)
        conn.execute("SELECT median(amount) FROM invoices")
    """
    conn.create_aggregate("median", 1, MedianAggregate)
    conn.create_aggregate("mode", 1, ModeAggregate)
    conn.create_aggregate("percentile", 2, PercentileAggregate)
    conn.create_aggregate("product", 1, ProductAggregate)
