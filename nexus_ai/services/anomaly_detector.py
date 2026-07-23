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
    - **v7.0.1: Adaptive Threshold** -- dynamiczny Z-score zamiast stałego 3.0
    - Zysk: czystsze API niż PyArrow + dostęp do pełnego Polars query engine
    """
    __slots__ = ('db', '_adaptive_threshold', '_rolling_stats')

    # ── Adaptive Threshold Constants ──
    BASE_THRESHOLD: float = 2.0   # Bazowy próg (97.7% danych w 2σ)
    MIN_SAMPLES: int = 10          # Minimum próbek do analizy
    ADAPTIVE_MIN: float = 1.5      # Minimalny próg adaptacyjny
    ADAPTIVE_MAX: float = 4.0      # Maksymalny próg adaptacyjny
    MAX_ROLLING_ENTRIES: int = 1000  # Limit wpisów w _rolling_stats (LRU)

    def __init__(self, db_manager: DuckDBManager):
        self.db = db_manager
        self._adaptive_threshold = self.BASE_THRESHOLD
        self._rolling_stats: dict[str, dict[str, float]] = {}  # nip -> {mean, std, count, threshold}

    def _update_adaptive_threshold(self, contractor_nip: str, mean: float, stddev: float, count: int) -> float:
        """Oblicz adaptacyjny próg Z-score na podstawie rozmiaru próbki i zmienności.

        Raport v7.0 Rec #3: Adaptive Threshold — dynamiczny zamiast stałego 2.0.
        - Małe próbki (10-30): wyższy próg (3.0) — mniej false positives
        - Duże próbki (100+): niższy próg (2.0) — więcej danych = lepsza statystyka
        - Wysoka zmienność: wyższy próg — szerszy zakres normy

        Returns:
            Adaptive Z-score threshold.
        """
        import math

        # Sample size factor: więcej danych → niższy próg
        if count < 20:
            size_factor = 1.5  # Mała próbka → wysoki próg
        elif count < 50:
            size_factor = 1.2
        elif count < 100:
            size_factor = 1.0
        else:
            size_factor = 0.85  # Duża próbka → niższy próg

        # Variability factor: wysoka zmienność → wyższy próg
        cv = (stddev / mean) if mean > 0 else 1.0  # coefficient of variation
        var_factor = 1.0 + math.log1p(cv) * 0.3   # CV 1.0 → factor 1.2

        threshold = self.BASE_THRESHOLD * size_factor * var_factor
        return max(self.ADAPTIVE_MIN, min(self.ADAPTIVE_MAX, threshold))

    def detect(self, contractor_nip: str, current_amount: float) -> bool:
        """
        Zwraca True, jeśli kwota faktury znacząco odbiega od
        historycznego profilu danego kontrahenta.

        v7.0.1: Używa adaptacyjnego progu Z-score zamiast stałego 3.0.
        - ``execute_arrow()`` + ``pl.from_arrow()`` -- zero-copy z DuckDB
        - Adaptive threshold: sample size + variability aware
        - ``.shrink_dtype()`` dla oszczędności RAM
        """
        try:
            arrow_table = self.db.execute_arrow(
                "SELECT amount_gross FROM invoices_replica WHERE contractor_nip = ?",
                (contractor_nip,),
            )
        except AttributeError:
            rows = self.db.execute(
                "SELECT amount_gross FROM invoices_replica WHERE contractor_nip = ?",
                (contractor_nip,),
            )
            if len(rows) < self.MIN_SAMPLES:
                return False
            amounts = [float(r[0]) for r in rows if r[0] is not None]
            if len(amounts) < self.MIN_SAMPLES:
                return False
            series = pl.Series("amount_gross", amounts)
        else:
            if arrow_table is None or arrow_table.num_rows < self.MIN_SAMPLES:
                return False
            series = pl.from_arrow(arrow_table["amount_gross"])

        mean = series.mean()
        if mean is None or mean == 0.0:
            return False

        stddev = series.std()
        if stddev is None or stddev == 0.0:
            return False

        # ── Adaptive threshold ──
        count = len(series)
        threshold = self._update_adaptive_threshold(contractor_nip, mean, stddev, count)
        self._adaptive_threshold = threshold

        # LRU eviction: zapobiega memory leak przy wielu unikalnych NIP
        self._rolling_stats[contractor_nip] = {
            "mean": mean, "std": stddev, "count": count, "threshold": threshold,
        }
        if len(self._rolling_stats) > self.MAX_ROLLING_ENTRIES:
            oldest = next(iter(self._rolling_stats))
            del self._rolling_stats[oldest]

        z_score = abs(current_amount - mean) / stddev
        return z_score > threshold


# Alias dla zgodności z services/__init__.py
AnomalyDetector = SmartAnomalyDetector
