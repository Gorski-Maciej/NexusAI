"""
BayesianThresholdLearner — Bayesowski System Adaptacyjnych Progów Decyzyjnych.

Zamiast sztywnych DEFAULT_THRESHOLDS (auto_post=0.92, suggest=0.75, ask_user=0.50),
każda para (kontrahent, kategoria) ma własny rozkład Beta aktualizowany
po każdej decyzji użytkownika.

Matematyka:
  - Prior:  Beta(α=2, β=2) — lekki sceptycyzm
  - Likelihood: decyzja użytkownika ~ Bernoulli(p)
  - Posterior: Beta(α + sukcesy, β + porażki)
  - Threshold = odwrotność CDF (ppf) dla zadanego percentyla

Im więcej danych (α+β → ∞), tym węższy rozkład i niższy próg.
Im więcej odrzuceń (β → ∞), tym wyższy próg (ostrożniej).

W pełni samodzielny — zero zewnętrznych zależności (tylko math).
Persistance przez SQLite.
"""

from __future__ import annotations

import math
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import pendulum


# =========================================================================
# BetaPosterior — pojedynczy rozkład Beta dla pary (kontrahent, kategoria)
# =========================================================================

@dataclass
class BetaPosterior:
    """Rozkład Beta dla pary (kontrahent, kategoria).

    alpha: liczba zatwierdzeń + prior (domyślnie 2.0)
    beta:  liczba odrzuceń + prior (domyślnie 2.0)

    Prior Beta(2,2) = lekki sceptycyzm: mean=0.5, ale szeroki (uncertainty≈0.5).
    """

    alpha: float = 2.0
    beta: float = 2.0

    @property
    def n(self) -> float:
        """Łączna liczba obserwacji (z priorem)."""
        return self.alpha + self.beta

    @property
    def mean(self) -> float:
        """Średnia rozkładu — estymowane prawdopodobieństwo zatwierdzenia."""
        return self.alpha / (self.alpha + self.beta)

    @property
    def variance(self) -> float:
        """Wariancja rozkładu Beta."""
        a, b = self.alpha, self.beta
        s = a + b
        return (a * b) / (s * s * (s + 1.0))

    @property
    def uncertainty(self) -> float:
        """Niepewność — odchylenie standardowe. Maleje z √n."""
        return math.sqrt(self.variance)

    def threshold_for(self, percentile: float = 0.95) -> float:
        """Zwraca adaptacyjny próg decyzyjny dla danego percentyla.

        Oblicza: P(X > threshold) = percentile
        Czyli: threshold = quantile(1 - percentile) rozkładu Beta(alpha, beta).

        Używa logit-normal approximation z korektą dla małych próbek.
        Dla n < 6: heuristic oparta na mean + uncertainty × z-score.
        Dla n ≥ 6: logit-normal approximation przez delta method.

        Args:
            percentile: poziom ufności (0.95, 0.75, 0.50)

        Returns:
            Próg w zakresie [0.50, 0.98]
        """
        # Zbyt mało danych → bardzo ostrożny próg (safety first)
        if self.n < 6:
            # Heurystyka: mean + 2 * uncertainty, ale minimum 0.85
            heuristic = self.mean + 2.0 * self.uncertainty
            threshold = max(heuristic, 0.85)
            return round(min(threshold, 0.98), 4)

        # Dla wystarczającej liczby danych → logit-normal approximation
        # Logit-normal jest znacznie lepsza od normalnej dla rozkładów
        # blisko brzegów (mean blisko 0 lub 1).
        z = _normal_ppf(percentile)
        logit_p = math.log(self.mean / (1.0 - self.mean + 1e-15))
        var_logit = 1.0 / (self.alpha + 1e-15) + 1.0 / (self.beta + 1e-15)
        sd_logit = math.sqrt(var_logit)

        # Quantile w przestrzeni logit
        logit_q = logit_p - z * sd_logit  # minus bo szukamy górnego ogona

        # Inverse logit
        threshold = 1.0 / (1.0 + math.exp(-logit_q))
        return round(min(max(threshold, 0.50), 0.98), 4)

    def update(self, approved: bool, weight: float = 1.0) -> None:
        """Aktualizuj posterior po decyzji użytkownika.

        Args:
            approved: True jeśli zatwierdzona, False jeśli odrzucona
            weight: waga decyzji (domyślnie 1.0)
        """
        if approved:
            self.alpha += weight
        else:
            self.beta += weight

    def to_dict(self) -> dict[str, float]:
        return {"alpha": self.alpha, "beta": self.beta, "mean": self.mean, "n": self.n}

    @classmethod
    def from_dict(cls, data: dict[str, float]) -> BetaPosterior:
        return cls(alpha=data.get("alpha", 2.0), beta=data.get("beta", 2.0))


# =========================================================================
# BayesianThresholdLearner — główna klasa
# =========================================================================

class BayesianThresholdLearner:
    """Bayesowski learner adaptacyjnych progów decyzyjnych.

    Przechowuje rozkłady Beta w SQLite dla trwałości.
    Aktualizuje po każdej decyzji użytkownika.

    Hierarchia progów:
      1. (NIP, kategoria) — najbardziej specyficzny
      2. (NIP, __global__) — ogólny dla kontrahenta
      3. BetaPosterior() — domyślny prior

    Użycie:
        learner = BayesianThresholdLearner()

        # Pobierz adaptacyjne progi
        thresholds = learner.get_thresholds(
            contractor_nip="1234567890",
            category="media",
            amount_gross=1500.00,
        )
        # → {"auto_post": 0.72, "suggest": 0.58, ...}

        # Zapisz decyzję użytkownika
        learner.record_decision(
            contractor_nip="1234567890",
            category="media",
            approved=True,
            amount_gross=1500.00,
        )
    """

    def __init__(self, db_path: Path | str | None = None) -> None:
        self._db_path = Path(db_path) if db_path else Path("app_data/bayesian_priors.db")
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._cache: dict[tuple[str, str], BetaPosterior] = {}
        self._init_schema()

    # ── Schema ────────────────────────────────────────────────────────────────

    def _init_schema(self) -> None:
        """Inicjalizuj schemat SQLite dla trwałości rozkładów."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS bayesian_posteriors (
                    contractor_nip TEXT NOT NULL,
                    category TEXT NOT NULL DEFAULT '__global__',
                    alpha REAL NOT NULL DEFAULT 2.0,
                    beta REAL NOT NULL DEFAULT 2.0,
                    total_decisions INTEGER NOT NULL DEFAULT 0,
                    approved_count INTEGER NOT NULL DEFAULT 0,
                    rejected_count INTEGER NOT NULL DEFAULT 0,
                    last_updated TEXT NOT NULL,
                    PRIMARY KEY (contractor_nip, category)
                );
                CREATE INDEX IF NOT EXISTS idx_bayesian_nip
                    ON bayesian_posteriors(contractor_nip);
            """)
            conn.commit()
        finally:
            conn.close()

    # ── Public API ────────────────────────────────────────────────────────────

    def get_thresholds(
        self,
        contractor_nip: str,
        category: str = "__global__",
        amount_gross: float = 0.0,
    ) -> dict[str, float]:
        """Zwraca adaptacyjne progi decyzyjne dla danej faktury.

        Strategia hierarchiczna:
        1. Rozkład dla konkretnego (NIP, kategoria)
        2. Rozkład dla (NIP, __global__)
        3. Domyślny prior Beta(2,2)

        Kwota wpływa liniowo: im wyższa, tym wyższy próg.

        Args:
            contractor_nip: NIP kontrahenta
            category: Kategoria wydatku
            amount_gross: Kwota brutto (wpływa na ostrożność)

        Returns:
            dict z kluczami "auto_post", "suggest", "ask_user"
        """
        # Hierarchia: konkretny → globalny → prior
        posterior = self._get_posterior(contractor_nip, category)

        if posterior is None:
            posterior = self._get_posterior(contractor_nip, "__global__")

        if posterior is None:
            posterior = BetaPosterior()  # domyślny prior

        # Bazowe progi z rozkładu Beta
        base = {
            "auto_post": posterior.threshold_for(0.95),
            "suggest": posterior.threshold_for(0.75),
            "ask_user": posterior.threshold_for(0.50),
        }

        # Modyfikacja kwotowa: wyższa kwota = wyższy próg
        amount_adj = self._amount_adjustment(amount_gross)
        for key in base:
            base[key] = round(min(base[key] + amount_adj, 0.98), 4)

        return base

    def record_decision(
        self,
        contractor_nip: str,
        category: str = "__global__",
        approved: bool = True,
        amount_gross: float = 0.0,
    ) -> None:
        """Zapisz decyzję użytkownika i zaktualizuj rozkład Beta.

        Aktualizuje zarówno konkretny rozkład (NIP, kategoria),
        jak i globalny (NIP, __global__).

        Args:
            contractor_nip: NIP kontrahenta
            category: Kategoria wydatku
            approved: True jeśli zatwierdzona, False jeśli odrzucona
            amount_gross: Kwota brutto (do ważenia decyzji)
        """
        if not contractor_nip:
            return  # brak NIP → nie można uczyć

        weight = self._decision_weight(amount_gross)

        # Aktualizuj konkretny rozkład (NIP, kategoria)
        posterior = self._get_posterior(contractor_nip, category)
        if posterior is None:
            posterior = BetaPosterior()
        posterior.update(approved=approved, weight=weight)
        self._store_posterior(
            contractor_nip, category, posterior,
            approved=approved, weight=weight,
        )

        # Aktualizuj globalny rozkład (NIP, __global__) jeśli to inna kategoria
        if category != "__global__":
            global_posterior = self._get_posterior(contractor_nip, "__global__")
            if global_posterior is None:
                global_posterior = BetaPosterior()
            global_posterior.update(approved=approved, weight=weight)
            self._store_posterior(
                contractor_nip, "__global__", global_posterior,
                approved=approved, weight=weight,
            )

    def record_auto_decision(
        self,
        contractor_nip: str,
        category: str = "__global__",
        approved: bool = True,
        amount_gross: float = 0.0,
    ) -> None:
        """Zapisz decyzję automatyczną (bez interwencji użytkownika).

        Różni się od record_decision: ma mniejszą wagę, bo system
        sam potwierdza swoją decyzję (mniejsza wartość edukacyjna).

        Args:
            contractor_nip: NIP kontrahenta
            category: Kategoria wydatku
            approved: True jeśli auto-zaakceptowana
            amount_gross: Kwota brutto
        """
        if not contractor_nip:
            return

        # Auto-decyzje mają 0.3 wagi (decyzje użytkownika = 1.0)
        weight = self._decision_weight(amount_gross) * 0.3

        posterior = self._get_posterior(contractor_nip, category)
        if posterior is None:
            posterior = BetaPosterior()
        posterior.update(approved=approved, weight=weight)
        self._store_posterior(
            contractor_nip, category, posterior,
            approved=approved, weight=weight, is_auto=True,
        )

        if category != "__global__":
            global_posterior = self._get_posterior(contractor_nip, "__global__")
            if global_posterior is None:
                global_posterior = BetaPosterior()
            global_posterior.update(approved=approved, weight=weight)
            self._store_posterior(
                contractor_nip, "__global__", global_posterior,
                approved=approved, weight=weight, is_auto=True,
            )

    # ── Persistence ──────────────────────────────────────────────────────────

    def _get_posterior(self, nip: str, category: str) -> BetaPosterior | None:
        """Pobierz rozkład Beta z cache lub SQLite."""
        key = (nip, category)

        # Sprawdź cache
        if key in self._cache:
            return self._cache[key]

        # Sprawdź SQLite
        conn = sqlite3.connect(str(self._db_path))
        try:
            row = conn.execute(
                """SELECT alpha, beta FROM bayesian_posteriors
                   WHERE contractor_nip = ? AND category = ?""",
                (nip, category),
            ).fetchone()

            if row:
                posterior = BetaPosterior(alpha=float(row[0]), beta=float(row[1]))
                self._cache[key] = posterior
                return posterior
            return None
        finally:
            conn.close()

    def _store_posterior(
        self,
        nip: str,
        category: str,
        posterior: BetaPosterior,
        approved: bool = True,
        weight: float = 1.0,
        is_auto: bool = False,
    ) -> None:
        """Zapisz rozkład Beta do SQLite i cache."""
        key = (nip, category)
        self._cache[key] = posterior

        now = pendulum.now("UTC").isoformat()
        conn = sqlite3.connect(str(self._db_path))
        try:
            # UPSERT: dodaj lub zaktualizuj
            conn.execute(
                """INSERT INTO bayesian_posteriors
                   (contractor_nip, category, alpha, beta, total_decisions,
                    approved_count, rejected_count, last_updated)
                   VALUES (?, ?, ?, ?, 1, ?, ?, ?)
                   ON CONFLICT(contractor_nip, category) DO UPDATE SET
                       alpha = excluded.alpha,
                       beta = excluded.beta,
                       total_decisions = bayesian_posteriors.total_decisions + 1,
                       approved_count = bayesian_posteriors.approved_count + ?,
                       rejected_count = bayesian_posteriors.rejected_count + ?,
                       last_updated = excluded.last_updated""",
                (
                    nip, category, posterior.alpha, posterior.beta,
                    1 if approved else 0,  # approved_count w INSERT
                    0 if approved else 1,  # rejected_count w INSERT
                    now,
                    1 if approved else 0,  # approved_count increment
                    0 if approved else 1,  # rejected_count increment
                ),
            )
            conn.commit()
        finally:
            conn.close()

    # ── Heurystyki ───────────────────────────────────────────────────────────

    @staticmethod
    def _amount_adjustment(amount_gross: float) -> float:
        """Współczynnik kwotowy: wyższa kwota = wyższy próg.

        Dla 1,000 PLN:  +0.00 (neutralnie)
        Dla 10,000 PLN: +0.03
        Dla 100,000 PLN: +0.08
        Dla 1,000,000 PLN: +0.13
        """
        if amount_gross <= 1000:
            return 0.0
        return min(0.15, 0.03 * math.sqrt(amount_gross / 10000.0))

    @staticmethod
    def _decision_weight(amount_gross: float) -> float:
        """Waga decyzji: wyższa kwota = ważniejsza decyzja.

        Dla małych kwot (< 100):     0.5 (pół głosu)
        Dla średnich (100-1000):     1.0 (jeden głos)
        Dla wysokich (1000-10000):   1.5 (półtora głosu)
        Dla bardzo wysokich (>10000): 2.0 (podwójny głos)
        """
        if amount_gross <= 100:
            return 0.5
        if amount_gross <= 1000:
            return 1.0
        if amount_gross <= 10000:
            return 1.5
        return 2.0

    # ── Statystyki ────────────────────────────────────────────────────────────

    def get_vendor_summary(self, contractor_nip: str) -> dict[str, Any]:
        """Zwraca podsumowanie bayesowskie dla danego kontrahenta.

        Args:
            contractor_nip: NIP kontrahenta

        Returns:
            dict z kluczami: global_thresholds, category_breakdown,
                             total_decisions, approval_rate, trust_trend
        """
        conn = sqlite3.connect(str(self._db_path))
        try:
            rows = conn.execute(
                """SELECT category, alpha, beta, total_decisions,
                          approved_count, rejected_count
                   FROM bayesian_posteriors
                   WHERE contractor_nip = ?
                   ORDER BY total_decisions DESC""",
                (contractor_nip,),
            ).fetchall()

            if not rows:
                return {
                    "known": False,
                    "contractor_nip": contractor_nip,
                    "message": "No data yet for this contractor",
                }

            # Znajdź globalny wpis
            global_row = None
            category_rows = []
            for row in rows:
                if row[0] == "__global__":
                    global_row = row
                else:
                    category_rows.append(row)

            # Użyj globalnego lub pierwszego z brzegu
            base = global_row or rows[0]
            posterior = BetaPosterior(alpha=float(base[1]), beta=float(base[2]))

            # Oblicz trend
            approval_rate = float(base[4]) / max(float(base[3]), 1)
            trust_trend = self._compute_trend(approval_rate, posterior.n)

            return {
                "known": True,
                "contractor_nip": contractor_nip,
                "total_decisions": int(base[3]),
                "approved_count": int(base[4]),
                "rejected_count": int(base[5]),
                "approval_rate": round(approval_rate, 4),
                "posterior_mean": round(posterior.mean, 4),
                "posterior_uncertainty": round(posterior.uncertainty, 4),
                "thresholds": {
                    "auto_post": posterior.threshold_for(0.95),
                    "suggest": posterior.threshold_for(0.75),
                    "ask_user": posterior.threshold_for(0.50),
                },
                "trust_trend": trust_trend,
                "category_breakdown": [
                    {
                        "category": row[0],
                        "total_decisions": int(row[3]),
                        "approval_rate": round(
                            float(row[4]) / max(float(row[3]), 1), 4
                        ),
                        "alpha": float(row[1]),
                        "beta": float(row[2]),
                        "auto_post_threshold": round(
                            BetaPosterior(alpha=float(row[1]), beta=float(row[2]))
                            .threshold_for(0.95),
                            4,
                        ),
                    }
                    for row in category_rows
                ],
            }
        finally:
            conn.close()

    def get_all_vendors_summary(self, min_decisions: int = 1) -> list[dict[str, Any]]:
        """Zwraca podsumowanie dla wszystkich znanych kontrahentów."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            rows = conn.execute(
                """SELECT contractor_nip, category, alpha, beta, total_decisions,
                          approved_count, rejected_count
                   FROM bayesian_posteriors
                   WHERE category = '__global__' AND total_decisions >= ?
                   ORDER BY total_decisions DESC""",
                (min_decisions,),
            ).fetchall()

            result = []
            for row in rows:
                posterior = BetaPosterior(alpha=float(row[2]), beta=float(row[3]))
                result.append({
                    "contractor_nip": row[0],
                    "total_decisions": int(row[4]),
                    "approval_rate": round(float(row[5]) / max(float(row[4]), 1), 4),
                    "mean": round(posterior.mean, 4),
                    "uncertainty": round(posterior.uncertainty, 4),
                    "auto_post_threshold": posterior.threshold_for(0.95),
                })
            return result
        finally:
            conn.close()

    def get_stats(self) -> dict[str, Any]:
        """Zwraca globalne statystyki bayesowskie."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            total_vendors = conn.execute(
                "SELECT COUNT(DISTINCT contractor_nip) FROM bayesian_posteriors"
            ).fetchone()[0]
            total_entries = conn.execute(
                "SELECT COUNT(*) FROM bayesian_posteriors"
            ).fetchone()[0]
            total_decisions = conn.execute(
                "SELECT COALESCE(SUM(total_decisions), 0) FROM bayesian_posteriors"
            ).fetchone()[0]

            # Liczba kontrahentów z wysokim zaufaniem (auto_post < 0.80)
            high_trust = conn.execute(
                """SELECT COUNT(*) FROM bayesian_posteriors
                   WHERE category = '__global__'
                     AND alpha / (alpha + beta) > 0.85
                     AND total_decisions >= 10"""
            ).fetchone()[0]

            return {
                "total_vendors": int(total_vendors),
                "total_entries": int(total_entries),
                "total_decisions": int(total_decisions),
                "high_trust_vendors": int(high_trust),
                "learner_type": "Bayesian Beta Posterior",
                "prior": {"alpha": 2.0, "beta": 2.0},
            }
        finally:
            conn.close()

    def clear_all(self) -> None:
        """Wyczyść wszystkie dane bayesowskie."""
        self._cache.clear()
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.execute("DELETE FROM bayesian_posteriors")
            conn.commit()
        finally:
            conn.close()

    @staticmethod
    def _compute_trend(approval_rate: float, n: float) -> str:
        """Określ trend zaufania na podstawie approval_rate i liczby decyzji."""
        if n < 6:
            return "learning"  # jeszcze za mało danych
        if approval_rate >= 0.90:
            return "high_trust"
        if approval_rate >= 0.75:
            return "trusted"
        if approval_rate >= 0.50:
            return "neutral"
        return "caution"


# =========================================================================
# Narzędzia — normal_ppf (odwrotność CDF rozkładu normalnego)
# =========================================================================

def _normal_ppf(p: float) -> float:
    """Approksymacja odwrotności dystrybuanty rozkładu normalnego (ppf).

    Używa algorytmu Petera Acklam (rational approximation).
    Dokładność: ~1.15 × 10^-9 dla p w zakresie [0.001, 0.999].
    Zero zależności — tylko math.

    Args:
        p: Prawdopodobieństwo (0.0 < p < 1.0)

    Returns:
        z-score odpowiadający danemu percentylowi
    """
    if p <= 0.0 or p >= 1.0:
        raise ValueError(f"p must be in (0, 1), got {p}")

    # Rational approximation coefficients (Acklam)
    a1 = -3.969683028665376e+01
    a2 = 2.209460984245205e+02
    a3 = -2.759285104469687e+02
    a4 = 1.383577518672690e+02
    a5 = -3.066479806614716e+01
    a6 = 2.506628277459239e+00

    b1 = -5.447609879822406e+01
    b2 = 1.615858368580409e+02
    b3 = -1.556989798598866e+02
    b4 = 6.680131188771972e+01
    b5 = -1.328068155288572e+01

    c1 = -7.784894002430293e-03
    c2 = -3.223964580411365e-01
    c3 = -2.400758277161838e+00
    c4 = -2.549732539343734e+00
    c5 = 4.374664141464968e+00
    c6 = 2.938163982698783e+00

    d1 = 7.784695709041462e-03
    d2 = 3.224671290700398e-01
    d3 = 2.445134137142996e+00
    d4 = 3.754408661907416e+00

    # Dolny i górny próg dla approximation
    p_low = 0.02425
    p_high = 1.0 - p_low

    if p < p_low:
        # Rational approximation dla dolnego ogona
        q = math.sqrt(-2.0 * math.log(p))
        z = (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) / \
            ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0)
    elif p <= p_high:
        # Rational approximation dla środka
        q = p - 0.5
        r = q * q
        z = (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q / \
            (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1.0)
    else:
        # Rational approximation dla górnego ogona
        q = math.sqrt(-2.0 * math.log(1.0 - p))
        z = -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) / \
            ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0)

    return z
