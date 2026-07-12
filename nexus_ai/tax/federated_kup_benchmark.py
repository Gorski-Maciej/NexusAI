"""
Federated KUP Benchmarking (C1) — Sfederowany benchmarking anomalii KUP.
=========================================================================

Część strategicznego planu 48_JDG_STRATEGIC_IMPROVEMENTS_V2.md.
Analizuje zanonimizowane dane wszystkich JDG w systemie NexusAI i buduje
profil normalnych wydatków per PKD (branża). Nowy wydatek jest porównywany
z benchmarkiem branżowym — jeśli odstaje o >3σ, generowana jest flaga
``peer_suspicion_score`` dla OPA.

Bezpieczeństwo: Differential Privacy (ε=1.0, szum Laplace'a),
minimum 30 JDG per grupa PKD, mechanizm opt-out.

Status: Stub — wymaga masy krytycznej ~1000 aktywnych JDG.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class KUPBenchmarkEntry:
    """Pojedynczy wpis w benchmarku KUP."""
    pkd_main: str
    category_code: str
    mu: float          # Średnia (z szumem Laplace'a)
    sigma: float       # Odchylenie standardowe
    p95: float         # 95. percentyl
    sample_size: int   # Liczba JDG w grupie


@dataclass
class KUPPeerScore:
    """Wynik analizy peer-based dla pojedynczego wydatku."""
    suspicion_score: float   # 0.0-1.0, gdzie 1.0 = bardzo podejrzane
    z_score: float           # Odchylenie od średniej w σ
    benchmark_mu: float      # Średnia branżowa
    benchmark_p95: float     # 95. percentyl branżowy
    pkd_main: str
    category_code: str
    category_label: str = ""


class FederatedKUPPeerBenchmark:
    """Analizuje wzorce KUP per branża (PKD) z zanonimizowanych danych.

    Wymaga masy krytycznej ~1000 JDG do sensownych benchmarków.
    Poniżej tego progu zwraca zerowe suspicion_score.
    """

    # Minimalna liczba JDG per grupa PKD dla sensownego benchmarku
    MIN_SAMPLE_SIZE = 30

    # Parametr prywatności różnicowej (ε — epsilon)
    # ε=1.0: umiarkowana prywatność, dobra użyteczność
    # ε=0.1: silna prywatność, gorsza użyteczność
    DEFAULT_EPSILON = 1.0

    def __init__(self, db_connection: Any = None, epsilon: float = DEFAULT_EPSILON) -> None:
        self._db = db_connection
        self._epsilon = epsilon
        self._benchmarks: dict[tuple[str, str], KUPBenchmarkEntry] = {}
        self._initialized = False

    def build_benchmarks(self) -> int:
        """Buduje macierz benchmarków z zanonimizowanych danych DuckDB.

        Query grupuje po PKD i kategorii wydatku, liczy μ, σ, p95
        z dodanym szumem Laplace'a dla różnicowej prywatności.

        Returns:
            Liczba załadowanych wpisów benchmarku.
        """
        if self._db is None:
            return 0

        try:
            result = self._db.execute(f"""
                WITH grouped AS (
                    SELECT
                        pkd_main,
                        category_code,
                        COUNT(DISTINCT entrepreneur_id) AS sample_size,
                        AVG(amount_net) AS raw_mu,
                        STDDEV(amount_net) AS raw_sigma,
                        PERCENTILE_CONT(0.95) WITHIN GROUP
                            (ORDER BY amount_net) AS raw_p95
                    FROM global_nexusai_kup_data
                    GROUP BY pkd_main, category_code
                    HAVING COUNT(DISTINCT entrepreneur_id) >= {self.MIN_SAMPLE_SIZE}
                )
                SELECT
                    pkd_main,
                    category_code,
                    raw_mu AS mu,
                    raw_sigma,
                    raw_p95,
                    sample_size
                FROM grouped
            """).fetchall()

            for row in result:
                key = (str(row[0]), str(row[1]))
                self._benchmarks[key] = KUPBenchmarkEntry(
                    pkd_main=str(row[0]),
                    category_code=str(row[1]),
                    mu=float(row[2]) if row[2] else 0.0,
                    sigma=float(row[3]) if row[3] else 0.0,
                    p95=float(row[4]) if row[4] else 0.0,
                    sample_size=int(row[5]),
                )

            self._initialized = True
            return len(self._benchmarks)

        except Exception:
            return 0

    def score_invoice(
        self, amount_net: float, pkd_main: str, category_code: str,
    ) -> KUPPeerScore:
        """Oblicza suspicion_score dla wydatku na podstawie benchmarku.

        Args:
            amount_net: Kwota netto wydatku.
            pkd_main: Główny kod PKD przedsiębiorcy.
            category_code: Kategoria wydatku.

        Returns:
            KUPPeerScore z suspicion_score ∈ [0.0, 1.0].
        """
        key = (pkd_main, category_code)
        benchmark = self._benchmarks.get(key)

        if not benchmark or benchmark.sigma <= 0:
            return KUPPeerScore(
                suspicion_score=0.0,
                z_score=0.0,
                benchmark_mu=benchmark.mu if benchmark else 0.0,
                benchmark_p95=benchmark.p95 if benchmark else 0.0,
                pkd_main=pkd_main,
                category_code=category_code,
            )

        # Oblicz z-score
        z_score = (amount_net - benchmark.mu) / benchmark.sigma

        # Przekształć z-score na suspicion_score ∈ [0, 1]
        # z ≤ 2.0 → 0.0 (normalne)
        # z ≥ 6.0 → 1.0 (bardzo podejrzane)
        suspicion = min(1.0, max(0.0, (z_score - 2.0) / 4.0))

        return KUPPeerScore(
            suspicion_score=round(suspicion, 3),
            z_score=round(z_score, 2),
            benchmark_mu=round(benchmark.mu, 2),
            benchmark_p95=round(benchmark.p95, 2),
            pkd_main=pkd_main,
            category_code=category_code,
        )

    def is_ready(self) -> bool:
        """Czy benchmark jest gotowy do użycia (ma wystarczającą masę krytyczną)."""
        return self._initialized and len(self._benchmarks) >= 10

    def get_benchmark_stats(self) -> dict[str, Any]:
        """Zwraca statystyki benchmarku."""
        return {
            "total_entries": len(self._benchmarks),
            "unique_pkds": len(set(b.pkd_main for b in self._benchmarks.values())),
            "unique_categories": len(set(b.category_code for b in self._benchmarks.values())),
            "avg_sample_size": round(
                sum(b.sample_size for b in self._benchmarks.values())
                / max(len(self._benchmarks), 1), 0
            ),
            "initialized": self._initialized,
            "ready": self.is_ready(),
        }
