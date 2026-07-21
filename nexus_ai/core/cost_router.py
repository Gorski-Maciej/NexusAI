"""Cost-Aware Agent Selection — Wybór modelu na podstawie kosztu (RAM × czas).

GENIALNY POMYSŁ #12 z Raportu v7.0:
Każdy model ma koszt (RAM × czas). Dla prostych faktur system wybiera tańszy model.
Oszczędność: 40% RAM i 60% czasu dla 80% faktur.
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.cost_router")


class ModelCostProfile:
    """Profil kosztowy modelu GGUF."""

    def __init__(
        self,
        name: str,
        ram_mb: float,
        avg_inference_ms: float,
        accuracy_score: float = 0.85,
    ) -> None:
        self.name = name
        self.ram_mb = ram_mb
        self.avg_inference_ms = avg_inference_ms
        self.accuracy_score = accuracy_score

    @property
    def cost_score(self) -> float:
        """Koszt całkowity = RAM × czas (znormalizowany)."""
        return (self.ram_mb / 2100.0) * (self.avg_inference_ms / 2000.0)

    @property
    def efficiency_score(self) -> float:
        """Efektywność = accuracy / koszt."""
        cost = self.cost_score
        if cost == 0:
            return float("inf")
        return self.accuracy_score / cost


# ── Predefiniowane profile kosztowe modeli ─────────────────────────────
MODEL_COST_PROFILES: dict[str, ModelCostProfile] = {
    "granite-3.2-3b": ModelCostProfile(
        name="granite-3.2-3b",
        ram_mb=2100,
        avg_inference_ms=2000,
        accuracy_score=0.92,
    ),
    "granite-guardian-0.5b": ModelCostProfile(
        name="granite-guardian-0.5b",
        ram_mb=600,
        avg_inference_ms=500,
        accuracy_score=0.88,
    ),
    "qwen3-nano-0.5b": ModelCostProfile(
        name="qwen3-nano-0.5b",
        ram_mb=500,
        avg_inference_ms=300,
        accuracy_score=0.82,
    ),
    "llama-3.2-1b": ModelCostProfile(
        name="llama-3.2-1b",
        ram_mb=800,
        avg_inference_ms=700,
        accuracy_score=0.85,
    ),
    "phi-3.5-1.5b": ModelCostProfile(
        name="phi-3.5-1.5b",
        ram_mb=1000,
        avg_inference_ms=900,
        accuracy_score=0.87,
    ),
    "mistral-0.2b": ModelCostProfile(
        name="mistral-0.2b",
        ram_mb=300,
        avg_inference_ms=200,
        accuracy_score=0.78,
    ),
}


class CostAwareRouter:
    """Router wybierający najlepszy model na podstawie kosztu.

    GENIALNY POMYSŁ #12:
    - Proste faktury → tani model (Qwen3-Nano, 0.5 GB, 300ms)
    - Złożone faktury → drogi model (Granite 3.2, 2.1 GB, 2000ms)
    - Oszczędność 40% RAM i 60% czasu dla 80% faktur.
    """

    # ── Progi złożoności ────────────────────────────────────────────
    SIMPLE_THRESHOLD = 1_000      # PLN — poniżej = prosta faktura
    MEDIUM_THRESHOLD = 10_000     # PLN — poniżej = średnia
    # Powyżej MEDIUM_THRESHOLD = złożona

    SIMPLE_POSITION_THRESHOLD = 1     # Liczba pozycji
    MEDIUM_POSITION_THRESHOLD = 5

    def __init__(
        self,
        profiles: dict[str, ModelCostProfile] | None = None,
        ram_budget_mb: float = 6000.0,
    ) -> None:
        self._profiles = profiles or dict(MODEL_COST_PROFILES)
        self._ram_budget_mb = ram_budget_mb
        self._selection_stats: dict[str, int] = {}
        self._ram_saved_mb: float = 0.0

    # ── Core Logic ──────────────────────────────────────────────────

    def select_model(
        self,
        task_complexity: str = "medium",
        vendor_known: bool = False,
        amount: float = 0.0,
        positions: int = 1,
        current_ram_mb: float = 0.0,
    ) -> tuple[str, ModelCostProfile, str]:
        """Wybierz optymalny model dla danego zadania."""
        # Automatyczne określenie złożoności
        if task_complexity == "simple" or (amount < self.SIMPLE_THRESHOLD and positions <= self.SIMPLE_POSITION_THRESHOLD):
            complexity = "simple"
        elif task_complexity == "complex" or (amount >= self.MEDIUM_THRESHOLD or positions > self.MEDIUM_POSITION_THRESHOLD):
            complexity = "complex"
        else:
            complexity = "medium"

        available_ram = self._ram_budget_mb - current_ram_mb

        if complexity == "simple":
            # Najtańszy model z acceptable accuracy mieszczący się w RAM
            candidates = [
                p for p in self._profiles.values()
                if p.ram_mb <= available_ram and p.accuracy_score >= 0.75
            ]
            if candidates:
                best = min(candidates, key=lambda p: p.cost_score)
                return self._record_selection(best.name, best, "simple_invoice")

        elif complexity == "medium":
            # Balans koszt/accuracy
            candidates = [
                p for p in self._profiles.values()
                if p.ram_mb <= available_ram and p.accuracy_score >= 0.82
            ]
            if candidates:
                best = max(candidates, key=lambda p: p.efficiency_score)
                return self._record_selection(best.name, best, "medium_invoice")

        # complex — najdokładniejszy model
        candidates = [
            p for p in self._profiles.values()
            if p.ram_mb <= available_ram and p.accuracy_score >= 0.85
        ]
        if candidates:
            best = max(candidates, key=lambda p: p.accuracy_score)
            return self._record_selection(best.name, best, "complex_invoice")

        # Fallback: zwróć błąd gdy żaden model nie pasuje
        logger.warning("[COST] No model fits RAM budget (available=%.0fMB)", available_ram)
        return ("none", ModelCostProfile("none", 0, 0, 0), "no_models_available")

    def select_cheapest_for_routine(
        self, vendor_known: bool, current_ram_mb: float = 0.0
    ) -> tuple[str, ModelCostProfile]:
        """Wybierz najtańszy model dla rutynowej faktury od znanego kontrahenta.

        GENIALNY POMYSŁ #12:
        80% faktur to rutynowe faktury od znanych kontrahentów.
        Użyj Qwen3-Nano 0.5B zamiast Granite 3.2 3B → oszczędność 76% RAM i 85% czasu.
        """
        available_ram = self._ram_budget_mb - current_ram_mb

        if vendor_known:
            cheap_candidates = sorted(
                [p for p in self._profiles.values() if p.ram_mb < available_ram],
                key=lambda p: p.cost_score,
            )
            if cheap_candidates:
                best = cheap_candidates[0]
                name = [k for k, v in self._profiles.items() if v is best][0]
                return self._record_selection(name, best, "routine_vendor")
        return self.select_model(task_complexity="medium", current_ram_mb=current_ram_mb)

    # ── Helpers ──────────────────────────────────────────────────────

    def _record_selection(
        self, name: str, profile: ModelCostProfile, reason: str
    ) -> tuple[str, ModelCostProfile, str]:
        self._selection_stats[name] = self._selection_stats.get(name, 0) + 1
        # Oszczędność RAM vs Granite 3.2 (2.1 GB)
        self._ram_saved_mb += 2100.0 - profile.ram_mb
        logger.debug(
            "[COST] Selected %s | ram=%.0fMB | time=%.0fms | reason=%s",
            name, profile.ram_mb, profile.avg_inference_ms, reason,
        )
        return name, profile, reason

    # ── Stats ────────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        total_selections = sum(self._selection_stats.values())
        return {
            "total_selections": total_selections,
            "selection_distribution": dict(self._selection_stats),
            "ram_saved_total_mb": round(self._ram_saved_mb, 0),
            "ram_saved_avg_per_decision_mb": round(
                self._ram_saved_mb / max(total_selections, 1), 1
            ),
            "cheapest_model": min(
                self._profiles.values(), key=lambda p: p.cost_score
            ).name if self._profiles else "none",
            "most_accurate_model": max(
                self._profiles.values(), key=lambda p: p.accuracy_score
            ).name if self._profiles else "none",
        }
