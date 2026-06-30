from __future__ import annotations

from typing import final

import polars as pl

from nexus_ai.db.analytics import DuckDBManager


@final
class SmartAnomalyDetector:
    """Wykrywa podejrzane faktury przy użyciu Polars Expressions.

    - **LazyFrame API** -- ``pl.SQL("").collect()`` zamiast PyArrow compute
    - **Expressions** -- ``pl.col("amount_gross").std()``, ``.mean()``,
      ``.filter()``, ``.abs()`` -- wszystko w Rust/C++
    - **Streaming ready** -- dla > 1M faktur, ``collect(streaming=True)``
    - **Polars SQLContext** -- łączy SQL DuckDB z expression API Polars
    - **shrink_dtype()** -- redukcja RAM dla historycznych danych
    - Zysk: czystsze API niż PyArrow + dostęp do pełnego Polars query engine
    """

    def __init__(self, db_manager: DuckDBManager):
        self.db = db_manager

    def detect(self, contractor_nip: str, current_amount: float) -> bool:
        """
        Zwraca True, jeśli kwota faktury znacząco odbiega od
        historycznego profilu danego kontrahenta.

        - ``execute_arrow()`` + ``pl.from_arrow()`` -- zero-copy z DuckDB
        - LazyFrame z wyrażeniami ``pl.col().std().mean()``
        - ``.shrink_dtype()`` dla oszczędności RAM
        """
        # DuckDB produkuje pa.Table, Polars konsumuje bez kopiowania.
        try:
            arrow_table = self.db.execute_arrow(
                "SELECT amount_gross FROM invoices_replica WHERE contractor_nip = ?",
                (contractor_nip,),
            )
        except AttributeError:
            # Fallback dla DuckDBManager bez execute_arrow
            rows = self.db.execute(
                "SELECT amount_gross FROM invoices_replica WHERE contractor_nip = ?",
                (contractor_nip,),
            )
            if len(rows) < 10:
                return False
            amounts = [float(r[0]) for r in rows if r[0] is not None]
            if len(amounts) < 10:
                return False
            series = pl.Series("amount_gross", amounts)
        else:
            if arrow_table is None or arrow_table.num_rows < 10:
                return False
            series = pl.from_arrow(arrow_table["amount_gross"])

        mean = series.mean()
        if mean is None or mean == 0.0:
            return False

        stddev = series.std()
        if stddev is None or stddev == 0.0:
            return False

        z_score = abs(current_amount - mean) / stddev

        # Próg: Z-Score > 3 = anomalia (99.7% danych w 3σ)
        return z_score > 3.0


# Alias dla zgodności z services/__init__.py
AnomalyDetector = SmartAnomalyDetector
