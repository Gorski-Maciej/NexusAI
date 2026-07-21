"""SilentPartnerManager — Wydzielony zarządca trybu Silent Partner v6.0.

Refaktoryzacja z AgentOrchestrator (Rekomendacja #1 z Raportu v7.0):
- Ekstrakcja ~300 LOC z monolitycznego orchestratora
- Zarządza trybami strategicznymi: CASH_PROTECT, GROWTH, TAX_OPTIMAL, EFFICIENCY
- Zarządza Executive Summary
- Zarządza Silent Mode (wszystkie workflow → AUTO_POST)
"""

from __future__ import annotations

import pendulum
from typing import Any

from structlog import get_logger

from nexus_ai.agents.models import (
    DashboardState,
    ExecutiveSummary,
    ExecutiveSummaryItem,
    StrategicMode,
    StrategicRecommendation,
)

logger = get_logger("nexus.agents.silent_partner")


class SilentPartnerManager:
    """Zarządca Silent Partner v6.0 — autonomiczny tryb CFO.

    GENIALNY POMYSŁ v6.0:
    - Agent NIE PYTA — PODEJMUJE decyzje (100%)
    - Przedsiębiorca przegląda Executive Summary
    - 1 klik → akceptuj wszystko (80% przypadków)
    - 4 tryby strategiczne zamiast DecisionMode
    """

    # ── Konfiguracja trybów strategicznych ───────────────────────────
    STRATEGY_PROFILES: dict[StrategicMode, dict[str, Any]] = {
        StrategicMode.CASH_PROTECT: {
            "description": "Maksymalizuj płynność, rozkładaj koszty",
            "auto_post_bias": 0.05,  # łatwiej AUTO_POST
            "min_cash_buffer_days": 90,
            "prefer_one_time_depreciation": True,
        },
        StrategicMode.GROWTH: {
            "description": "Inwestuj, przyspieszaj amortyzację",
            "auto_post_bias": -0.02,
            "min_cash_buffer_days": 30,
            "prefer_one_time_depreciation": False,
        },
        StrategicMode.TAX_OPTIMAL: {
            "description": "Minimalizuj PIT/CIT, rozkładaj dochody",
            "auto_post_bias": 0.0,
            "min_cash_buffer_days": 60,
            "prefer_one_time_depreciation": False,
        },
        StrategicMode.EFFICIENCY: {
            "description": "Najszybsza ścieżka, zero zbędnych kroków",
            "auto_post_bias": 0.10,  # najłatwiej AUTO_POST
            "min_cash_buffer_days": 0,
            "prefer_one_time_depreciation": True,
        },
    }

    def __init__(
        self,
        config: dict[str, Any] | None = None,
        strategy_engine: Any = None,
        executive_summary: Any = None,
    ) -> None:
        self._config = config or {}
        self._strategy_engine = strategy_engine
        self._executive_summary = executive_summary
        self._silent_mode: bool = True
        self._current_strategy: StrategicMode = StrategicMode.EFFICIENCY

        # ── Statystyki Silent Partner ──
        self._stats: dict[str, Any] = {
            "total_decisions": 0,
            "auto_posted": 0,
            "accept_all_count": 0,
            "time_saved_total_minutes": 0.0,
            "strategic_queries": 0,
            "tactical_queries_eliminated": 0,
        }

        # ── Historia strategiczna ──
        self._strategy_history: list[dict[str, Any]] = []
        self._quarterly_strategies: dict[str, StrategicMode] = {}

    # ── Properties ──────────────────────────────────────────────────

    @property
    def silent_mode(self) -> bool:
        return self._silent_mode

    @silent_mode.setter
    def silent_mode(self, value: bool) -> None:
        old = self._silent_mode
        self._silent_mode = value
        if old != value:
            logger.info("[SILENT] Mode changed: %s → %s", old, value)

    @property
    def current_strategy(self) -> StrategicMode:
        return self._current_strategy

    @property
    def stats(self) -> dict[str, Any]:
        return dict(self._stats)

    @property
    def silent_rate(self) -> float:
        total = self._stats.get("total_decisions", 0)
        if total == 0:
            return 100.0
        return (self._stats.get("auto_posted", 0) / total) * 100.0

    # ── Strategic Mode Management ───────────────────────────────────

    def set_strategy(self, mode: StrategicMode, reason: str = "") -> None:
        """Ustaw tryb strategiczny."""
        old = self._current_strategy
        self._current_strategy = mode
        entry = {
            "from": old.value,
            "to": mode.value,
            "reason": reason,
            "timestamp": pendulum.now("UTC").isoformat(),
        }
        self._strategy_history.append(entry)
        logger.info("[SILENT] Strategy: %s → %s | %s", old.value, mode.value, reason)

    def get_strategy_for_quarter(self, quarter: str | None = None) -> StrategicMode:
        """Pobierz strategię dla danego kwartału (z pamięci lub aktualną)."""
        if quarter and quarter in self._quarterly_strategies:
            return self._quarterly_strategies[quarter]
        return self._current_strategy

    def learn_quarterly_pattern(
        self, quarter: str, observed_strategy: StrategicMode
    ) -> None:
        """Zapamiętaj wzorzec strategiczny dla kwartału."""
        self._quarterly_strategies[quarter] = observed_strategy
        logger.info("[SILENT] Learned Q%s pattern: %s", quarter, observed_strategy.value)

    # ── Decision Logic ──────────────────────────────────────────────

    def should_auto_post(
        self,
        trust_score: float,
        amount: float,
        is_routine: bool = False,
        vendor_is_trusted: bool = False,
    ) -> tuple[bool, StrategicMode, str]:
        """Zdecyduj czy faktura powinna być AUTO_POST w Silent Mode.

        GENIALNY POMYSŁ v6.0:
        W Silent Mode, DOMYŚLNIE wszystkie workflow → AUTO_POST.
        Tylko wyjątki (niski trust, wysoka kwota) trafiają do SUGGEST.

        Returns:
            (should_auto, strategic_mode, reason)
        """
        if not self._silent_mode:
            return False, self._current_strategy, "Silent mode OFF"

        profile = self.STRATEGY_PROFILES.get(
            self._current_strategy, self.STRATEGY_PROFILES[StrategicMode.EFFICIENCY]
        )
        bias = profile["auto_post_bias"]
        adjusted_trust = trust_score + bias

        # Wyjątki od AUTO_POST
        if trust_score < 0.30:
            return False, self._current_strategy, "Trust score critical (< 0.30)"
        if amount > 100_000 and not vendor_is_trusted:
            return False, self._current_strategy, f"High amount ({amount:,.0f} PLN) + untrusted vendor"
        if adjusted_trust < 0.75:
            return False, self._current_strategy, f"Adjusted trust too low ({adjusted_trust:.2f})"

        # AUTO_POST
        if is_routine and vendor_is_trusted:
            return True, self._current_strategy, "Routine invoice from trusted vendor"
        if adjusted_trust >= 0.85:
            return True, self._current_strategy, f"High adjusted trust ({adjusted_trust:.2f})"

        return True, self._current_strategy, f"Silent mode AUTO_POST (trust={trust_score:.2f}, strategy={self._current_strategy.value})"

    # ── Executive Summary Integration ───────────────────────────────

    def record_auto_post(
        self, title: str, amount: float, detail: str, decision_id: str
    ) -> None:
        """Zarejestruj automatycznie zaksięgowaną fakturę."""
        self._stats["auto_posted"] += 1
        self._stats["total_decisions"] += 1
        self._stats["time_saved_total_minutes"] += 2.5
        if self._executive_summary and hasattr(self._executive_summary, 'add_auto_posted'):
            self._executive_summary.add_auto_posted(
                title=title, amount=amount, detail=detail, decision_id=decision_id
            )

    def record_verified(
        self, title: str, amount: float, detail: str, decision_id: str
    ) -> None:
        """Zarejestruj fakturę wymagającą weryfikacji."""
        self._stats["total_decisions"] += 1
        if self._executive_summary and hasattr(self._executive_summary, 'add_verified'):
            self._executive_summary.add_verified(
                title=title, amount=amount, detail=detail, decision_id=decision_id
            )

    def record_accept_all(self, count: int) -> None:
        """Zarejestruj masową akceptację (Accept All)."""
        self._stats["accept_all_count"] += 1
        self._stats["time_saved_total_minutes"] += count * 0.5
        logger.info("[SILENT] Accept-All #%d: %d decisions", self._stats["accept_all_count"], count)

    def record_strategic_query(self) -> None:
        """Zarejestruj zapytanie strategiczne (zamiast taktycznego)."""
        self._stats["strategic_queries"] += 1
        self._stats["tactical_queries_eliminated"] += 1

    # ── Dashboard State Determination ───────────────────────────────

    def determine_dashboard_state(
        self, items_to_review: int = 0, has_alerts: bool = False
    ) -> DashboardState:
        """Określ stan Executive Dashboard."""
        if has_alerts:
            return DashboardState.ALERT
        if items_to_review > 0:
            return DashboardState.ATTENTION
        if self._stats["total_decisions"] == 0:
            return DashboardState.EMPTY
        return DashboardState.NORMAL

    # ── Reporting ──────────────────────────────────────────────────

    def get_weekly_report(self) -> dict[str, Any]:
        """Generuj raport tygodniowy Silent Partner."""
        return {
            "silent_rate_pct": round(self.silent_rate, 1),
            "total_decisions": self._stats["total_decisions"],
            "auto_posted": self._stats["auto_posted"],
            "accept_all_count": self._stats["accept_all_count"],
            "time_saved_hours": round(self._stats["time_saved_total_minutes"] / 60, 1),
            "current_strategy": self._current_strategy.value,
            "strategic_queries": self._stats["strategic_queries"],
            "tactical_queries_eliminated": self._stats["tactical_queries_eliminated"],
            "strategy_history": self._strategy_history[-5:],
        }

    def get_summary(self) -> dict[str, Any]:
        """Pobierz ogólne podsumowanie."""
        return {
            "silent_mode": self._silent_mode,
            "silent_rate_pct": round(self.silent_rate, 1),
            "strategy": self._current_strategy.value,
            "total_processed": self._stats["total_decisions"],
            "auto_posted": self._stats["auto_posted"],
            "time_saved_hours": round(self._stats["time_saved_total_minutes"] / 60, 1),
            "accept_all_count": self._stats["accept_all_count"],
        }

    def reset_stats(self) -> None:
        """Resetuj statystyki (np. na początku miesiąca)."""
        self._stats = {
            "total_decisions": 0,
            "auto_posted": 0,
            "accept_all_count": 0,
            "time_saved_total_minutes": 0.0,
            "strategic_queries": 0,
            "tactical_queries_eliminated": 0,
        }
