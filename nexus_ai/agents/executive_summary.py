"""ExecutiveSummaryGenerator — GENIALNY POMYSŁ v6.0 "Cichy Wspólnik".

Generuje Executive Summary — podsumowanie pracy agenta dla przedsiębiorcy.
Zamiast kart decyzyjnych (v5.x), przedsiębiorca widzi Executive Dashboard
z przyciskiem "Akceptuj wszystkie".

Architektura (zgodnie z dokumentem):
  1. Executive Summary Generator
     ├── Czy to rutynowa faktura? → AUTO_POST + dodaj do summary
     ├── Czy to wyjątek? → Zastosuj tryb strategiczny
     └── Czy wymaga strategii? → Zapisz do \"rekomendacje strategiczne\"
  2. Strategic Engine
     ├── Jaki tryb? (Cash Protect / Growth / Tax Optimal / Efficiency)
     ├── Jaki kontekst? (5 wymiarów)
     └── Optymalna decyzja na podstawie strategii + kontekstu
  3. Queue for Executive Summary
  4. User opens app → widzi Executive Summary z 1 kliknięciem
"""

from __future__ import annotations

import uuid
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.agents.models import (
    DashboardState,
    ExecutiveSummary,
    ExecutiveSummaryItem,
    StrategicRecommendation,
)

logger = get_logger("nexus.agents.summary")


class ExecutiveSummaryGenerator:
    """Generator Executive Summary — GENIALNY POMYSŁ v6.0.

    Buduje podsumowanie pracy agenta w formie Executive Summary.
    Przedsiębiorca widzi:
    - Ile faktur zaksięgowano
    - Ile automatycznie vs z weryfikacją
    - Trend vs poprzedni okres
    - Oszczędność czasu
    - Opcjonalnie: strategiczne rekomendacje
    """

    def __init__(self, orchestrator: Any = None) -> None:
        self._orchestrator = orchestrator
        self._logger = get_logger("nexus.agents.summary")
        self._collected_items: list[ExecutiveSummaryItem] = []
        self._auto_posted_count: int = 0
        self._auto_posted_amount: float = 0.0
        self._verified_count: int = 0
        self._previous_auto_posted: int = 0  # Do obliczania trendu

    # ── Kolekcjonowanie pozycji ─────────────────────────────────────

    def add_auto_posted(
        self,
        title: str,
        amount: float = 0.0,
        detail: str = "",
        decision_id: str = "",
        currency: str = "PLN",
    ) -> None:
        """Dodaj automatycznie zaksięgowaną fakturę do podsumowania."""
        item = ExecutiveSummaryItem(
            item_type="invoice_posted",
            title=title,
            detail=detail,
            amount=amount,
            currency=currency,
            status="auto",
            decision_id=decision_id,
        )
        self._collected_items.append(item)
        self._auto_posted_count += 1
        self._auto_posted_amount += amount

    def add_verified(
        self,
        title: str,
        amount: float = 0.0,
        detail: str = "",
        decision_id: str = "",
        currency: str = "PLN",
    ) -> None:
        """Dodaj fakturę z weryfikacją (SUGGEST/ASK_USER) do podsumowania."""
        item = ExecutiveSummaryItem(
            item_type="invoice_posted",
            title=title,
            detail=detail,
            amount=amount,
            currency=currency,
            status="verified",
            decision_id=decision_id,
        )
        self._collected_items.append(item)
        self._verified_count += 1

    def add_item_to_review(
        self,
        title: str,
        detail: str = "",
        decision_id: str = "",
        amount: float = 0.0,
        currency: str = "PLN",
        status: str = "pending",
    ) -> ExecutiveSummaryItem:
        """Dodaj pozycję do opcjonalnego wglądu.

        To są pozycje, które zostały automatycznie zaksięgowane,
        ale oznaczone jako warte przejrzenia (np. wysoka kwota > 50k).
        """
        item = ExecutiveSummaryItem(
            item_type="invoice_posted",
            title=title,
            detail=detail,
            amount=amount,
            currency=currency,
            status=status,
            decision_id=decision_id,
        )
        self._collected_items.append(item)
        # Nie inkrementujemy auto_posted_count — pozycja dla wglądu
        return item

    # ── Budowanie Executive Summary ─────────────────────────────────

    def build_summary(
        self,
        strategic_recommendations: list[StrategicRecommendation] | None = None,
        previous_auto_posted: int = 0,
        greeting_name: str = "",
    ) -> ExecutiveSummary:
        """Zbuduj Executive Summary gotowe do prezentacji w UI.

        Args:
            strategic_recommendations: Lista rekomendacji strategicznych.
            previous_auto_posted: Liczba AUTO_POST w poprzednim okresie (do trendu).
            greeting_name: Imię przedsiębiorcy do powitania.

        Returns:
            ExecutiveSummary gotowe do konsumpcji przez ExecutiveDashboard.
        """
        now = pendulum.now("UTC")
        summary_id = uuid.uuid4().hex[:12]

        # ── Powitanie ────────────────────────────────────────────────
        greeting = self._generate_greeting(greeting_name)

        # ── Trend ────────────────────────────────────────────────────
        trend_pct = self._calculate_trend(previous_auto_posted)

        # ── Oszczędność czasu ───────────────────────────────────────
        time_saved = self._auto_posted_count * 2.5  # 2.5 min na decyzję

        # ── Pozycje do wglądu ───────────────────────────────────────
        items_to_review = sum(
            1 for item in self._collected_items
            if item.status in ("pending", "verified")
        )

        # ── Stan dashboardu ─────────────────────────────────────────
        dashboard_state = self._determine_dashboard_state(items_to_review)

        # ── Silent Rate ─────────────────────────────────────────────
        total = self._auto_posted_count + self._verified_count
        silent_rate = (self._auto_posted_count / total * 100.0) if total > 0 else 100.0

        summary = ExecutiveSummary(
            summary_id=summary_id,
            generated_at=now.isoformat(),
            greeting=greeting,
            items=self._collected_items,
            auto_posted_count=self._auto_posted_count,
            auto_posted_amount=self._auto_posted_amount,
            verified_count=self._verified_count,
            time_saved_minutes=round(time_saved, 1),
            trend_pct=round(trend_pct, 1),
            items_to_review=items_to_review,
            strategic_recommendations=strategic_recommendations or [],
            dashboard_state=dashboard_state,
            silent_rate=round(silent_rate, 1),
        )

        self._logger.info(
            "[SUMMARY] Built | %d auto (%s PLN) + %d verified | %d to review | "
            "%.1f min saved | trend %+.1f%% | state=%s",
            self._auto_posted_count,
            f"{self._auto_posted_amount:,.0f}",
            self._verified_count,
            items_to_review,
            time_saved,
            trend_pct,
            dashboard_state.value,
        )

        return summary

    # ── Reset ───────────────────────────────────────────────────────

    def reset(self) -> None:
        """Zresetuj kolektor do nowego dnia."""
        self._previous_auto_posted = self._auto_posted_count
        self._collected_items = []
        self._auto_posted_count = 0
        self._auto_posted_amount = 0.0
        self._verified_count = 0

    # ── Pomocnicze ──────────────────────────────────────────────────

    @staticmethod
    def _generate_greeting(name: str = "") -> str:
        """Wygeneruj powitanie w zależności od pory dnia."""
        now = pendulum.now("UTC")
        hour = now.hour

        if hour < 12:
            time_part = "Dzień dobry"
        elif hour < 18:
            time_part = "Dzień dobry" if hour < 16 else "Dobry wieczór"
        else:
            time_part = "Dobry wieczór"

        name_part = f", {name}!" if name else "!"
        return f"🌅 {time_part}{name_part} Agent przepracował noc. Oto podsumowanie:"

    def _calculate_trend(self, previous_count: int) -> float:
        """Oblicz trend vs poprzedni okres."""
        prev = previous_count or self._previous_auto_posted
        if prev == 0:
            return 0.0
        return ((self._auto_posted_count - prev) / prev) * 100.0

    @staticmethod
    def _determine_dashboard_state(items_to_review: int) -> DashboardState:
        """Określ stan Executive Dashboard."""
        if items_to_review == 0:
            return DashboardState.EMPTY
        elif items_to_review <= 2:
            return DashboardState.NORMAL
        elif items_to_review <= 5:
            return DashboardState.ATTENTION
        else:
            return DashboardState.ALERT

    # ── Pomocnicze dla trendu ───────────────────────────────────────

    def set_previous_count(self, count: int) -> None:
        """Ustaw liczbę AUTO_POST z poprzedniego okresu."""
        self._previous_auto_posted = count
