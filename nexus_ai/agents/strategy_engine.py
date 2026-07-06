"""StrategyEngine — Continuous Strategy Engine (GENIALNY POMYSŁ v6.0 Silent Partner).

Odwraca paradygmat z "Agent pyta → Człowiek odpowiada" (v5.x)
na "Agent robi → Człowiek przegląda" (v6.0).

Zamiast uczenia się preferencji (taktyka), agent uczy się STRATEGII (kontekst).
5 wymiarów kontekstu strategicznego → 4 tryby strategiczne → decyzje automatyczne.

Learning by Context (LbC):
  Cash Flow Phase × Tax Period × Vendor Season × Growth Phase × Macro Context
"""

from __future__ import annotations

import uuid
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.agents.models import (
    CashFlowPhase,
    ContextDimension,
    DecisionMode,
    StrategicMode,
    StrategicRecommendation,
)

logger = get_logger("nexus.agents.strategy")


# ═════════════════════════════════════════════════════════════════════════
# Strategy Engine — Główny komponent
# ═════════════════════════════════════════════════════════════════════════


class StrategyEngine:
    """Continuous Strategy Engine — GENIALNY POMYSŁ v6.0 "Cichy Wspólnik".

    Agent pyta o STRATEGIĘ raz, działa TAKTYCZNIE zawsze.

    Cztery tryby strategiczne:
    - 💰 Cash Protect: Maksymalizuj płynność, rozkładaj koszty
    - 📈 Growth: Inwestuj, przyspieszaj amortyzację
    - ⚖️ Tax Optimal: Minimalizuj PIT/CIT, rozkładaj dochody
    - 🎯 Efficiency: Najszybsza ścieżka, zero zbędnych kroków

    Pięć wymiarów kontekstu:
    - Cash Flow Phase: surplus / deficit / neutral
    - Tax Period: start_quarter / mid_quarter / end_quarter / vat_deadline / year_end
    - Vendor Season: normal / high_season / low_season / first_time
    - Growth Phase: startup / growth / maintenance / scaling
    - Macro Context: stopy procentowe, inflacja, kursy walut
    """

    # ── Progi decyzyjne per tryb strategiczny ─────────────────────────
    STRATEGY_THRESHOLDS: dict[StrategicMode, dict[str, float]] = {
        StrategicMode.CASH_PROTECT: {
            "auto_post": 0.88,      # Wyższy próg — ostrożność
            "max_auto_amount": 10000.0,  # Niższy limit kwot
            "prefer_later_payment": True,
        },
        StrategicMode.GROWTH: {
            "auto_post": 0.85,      # Niższy próg — inwestycje
            "max_auto_amount": 50000.0,  # Wyższy limit kwot
            "prefer_accelerated_depreciation": True,
        },
        StrategicMode.TAX_OPTIMAL: {
            "auto_post": 0.82,      # Niski próg — optymalizacja
            "max_auto_amount": 30000.0,
            "prefer_tax_deferral": True,
        },
        StrategicMode.EFFICIENCY: {
            "auto_post": 0.78,      # Najniższy próg — szybkość
            "max_auto_amount": 100000.0,  # Najwyższy limit
            "skip_quality_validator": True,
        },
    }

    # ── Mapowanie fazy cash flow na tryb strategiczny ────────────────
    CASH_FLOW_TO_STRATEGY: dict[CashFlowPhase, StrategicMode] = {
        CashFlowPhase.SURPLUS: StrategicMode.GROWTH,
        CashFlowPhase.DEFICIT: StrategicMode.CASH_PROTECT,
        CashFlowPhase.NEUTRAL: StrategicMode.EFFICIENCY,
    }

    # ── Mapowanie okresu podatkowego na modyfikator trybu ───────────
    TAX_PERIOD_MODIFIERS: dict[str, dict[str, float]] = {
        "start_quarter": {"auto_post_delta": 0.0},
        "mid_quarter":   {"auto_post_delta": 0.0},
        "end_quarter":   {"auto_post_delta": -0.05},  # Ostrożniej na koniec kwartału
        "vat_deadline":  {"auto_post_delta": -0.08},  # Najostrożniej przy deadline VAT
        "year_end":      {"auto_post_delta": -0.10},  # Maksymalna ostrożność
    }

    def __init__(self, config: dict[str, Any] | None = None) -> None:
        self._config = config or {}
        self._current_mode: StrategicMode = StrategicMode.EFFICIENCY
        self._context: ContextDimension = ContextDimension()
        self._context_history: list[tuple[str, ContextDimension]] = []
        self._mode_history: list[tuple[str, StrategicMode, str]] = []  # timestamp, mode, reason
        self._strategic_recommendations: list[StrategicRecommendation] = []
        self._logger = get_logger("nexus.agents.strategy")

    # ── Properties ──────────────────────────────────────────────────

    @property
    def current_mode(self) -> StrategicMode:
        """Aktualny tryb strategiczny."""
        return self._current_mode

    @property
    def current_context(self) -> ContextDimension:
        """Aktualny kontekst strategiczny."""
        return self._context

    @property
    def mode_thresholds(self) -> dict[str, float]:
        """Progi decyzyjne dla aktualnego trybu."""
        return self.STRATEGY_THRESHOLDS.get(self._current_mode, {})

    # ── Analiza kontekstu (5 wymiarów) ──────────────────────────────

    def analyze_context(
        self,
        cash_balance: float = 0.0,
        pending_receivables: float = 0.0,
        pending_payables: float = 0.0,
        vendor_data: dict[str, Any] | None = None,
        macro_data: dict[str, Any] | None = None,
    ) -> ContextDimension:
        """Analizuj 5 wymiarów kontekstu strategicznego.

        Args:
            cash_balance: Aktualny stan gotówki.
            pending_receivables: Należności oczekujące.
            pending_payables: Zobowiązania oczekujące.
            vendor_data: Dane o kontrahencie (historia, sezonowość).
            macro_data: Dane makroekonomiczne (stopy, inflacja, kursy).

        Returns:
            ContextDimension z wypełnionymi wszystkimi 5 wymiarami.
        """
        now = pendulum.now("UTC")

        # ── Wymiar 1: Cash Flow Phase ────────────────────────────────
        net_cash = cash_balance + pending_receivables - pending_payables
        if net_cash > pending_payables * 1.5:
            cash_phase = CashFlowPhase.SURPLUS
        elif net_cash < pending_payables * 0.5:
            cash_phase = CashFlowPhase.DEFICIT
        else:
            cash_phase = CashFlowPhase.NEUTRAL

        # ── Wymiar 2: Tax Period ─────────────────────────────────────
        day = now.day
        month = now.month
        if month == 12 and day > 20:
            tax_period = "year_end"
        elif day >= 20 and day <= 25:
            tax_period = "vat_deadline"
        elif day <= 10:
            tax_period = "start_quarter" if month in (1, 4, 7, 10) else "start_quarter"
        elif day >= 25:
            tax_period = "end_quarter" if month in (3, 6, 9, 12) else "mid_quarter"
        else:
            tax_period = "mid_quarter"

        # ── Wymiar 3: Vendor Season ─────────────────────────────────
        vendor_season = self._analyze_vendor_season(vendor_data or {}, now)

        # ── Wymiar 4: Growth Phase ──────────────────────────────────
        growth_phase = self._analyze_growth_phase(
            cash_balance, pending_receivables, pending_payables,
        )

        # ── Wymiar 5: Macro Context ─────────────────────────────────
        macro = self._analyze_macro_context(macro_data or {})

        context = ContextDimension(
            cash_flow_phase=cash_phase,
            tax_period=tax_period,
            vendor_season=vendor_season,
            growth_phase=growth_phase,
            macro_context=macro,
        )

        self._context = context
        self._context_history.append((now.isoformat(), context))

        # Trim history
        if len(self._context_history) > 100:
            self._context_history = self._context_history[-100:]

        self._logger.debug(
            "[STRATEGY] Context analyzed | %s | mode=%s",
            context.summary, self._current_mode.value,
        )

        return context

    @staticmethod
    def _analyze_vendor_season(
        vendor_data: dict[str, Any],
        now: pendulum.DateTime,
    ) -> str:
        """Analizuj sezonowość kontrahenta."""
        vendor_type = vendor_data.get("type", "")
        history_months = vendor_data.get("history_months", 0)
        recent_activity = vendor_data.get("recent_activity", 0)

        if history_months < 3:
            return "first_time"

        # Sezonowość na podstawie branży
        seasonal_industries = {
            "budownictwo": (3, 10),  # marzec-październik
            "rolnictwo": (4, 9),
            "turystyka": (5, 9),
            "handel_detaliczny": (11, 12),  # święta
        }

        for industry, (start, end) in seasonal_industries.items():
            if industry in vendor_type.lower():
                if start <= now.month <= end:
                    return "high_season"
                return "low_season"

        if recent_activity > 10:
            return "high_season"

        return "normal"

    def _analyze_growth_phase(
        self,
        cash_balance: float,
        receivables: float,
        payables: float,
    ) -> str:
        """Analizuj fazę rozwoju firmy na podstawie trendów finansowych."""
        if len(self._context_history) < 5:
            return "maintenance"

        if cash_balance > 100000 and receivables > payables * 2:
            return "scaling"
        elif receivables > payables * 1.3:
            return "growth"
        elif cash_balance < 10000:
            return "startup"

        return "maintenance"

    @staticmethod
    def _analyze_macro_context(macro_data: dict[str, Any]) -> dict[str, Any]:
        """Analizuj kontekst makroekonomiczny."""
        interest_rate = macro_data.get("interest_rate", 5.75)
        inflation = macro_data.get("inflation", 4.0)
        eur_pln = macro_data.get("eur_pln", 4.30)
        usd_pln = macro_data.get("usd_pln", 3.90)

        # Wysokie stopy → preferuj oszczędzanie
        high_rates = interest_rate > 5.0

        # Wysoka inflacja → preferuj inwestycje w aktywa
        high_inflation = inflation > 5.0

        return {
            "interest_rate": interest_rate,
            "inflation": inflation,
            "eur_pln": eur_pln,
            "usd_pln": usd_pln,
            "high_rates": high_rates,
            "high_inflation": high_inflation,
            "timestamp": pendulum.now("UTC").isoformat(),
        }

    # ── Wybór trybu strategicznego ─────────────────────────────────

    def select_strategic_mode(
        self,
        context: ContextDimension | None = None,
        user_preference: StrategicMode | None = None,
    ) -> tuple[StrategicMode, str]:
        """Wybierz optymalny tryb strategiczny na podstawie kontekstu.

        Priorytety:
        1. Jawna preferencja użytkownika (nadrzędna)
        2. Cash Flow Phase (automatycznie)
        3. Macro Context (modyfikator)
        4. Tax Period (modyfikator)

        Args:
            context: Kontekst strategiczny (jeśli None, użyj self._context).
            user_preference: Jawny wybór użytkownika (nadrzędny).

        Returns:
            Tuple (wybrany tryb, przyczyna).
        """
        if user_preference:
            self._set_mode(user_preference, "user_override")
            return user_preference, "Wybór użytkownika"

        ctx = context or self._context

        # Automatyczny wybór na podstawie Cash Flow Phase
        mode = self.CASH_FLOW_TO_STRATEGY.get(ctx.cash_flow_phase, StrategicMode.EFFICIENCY)
        reason = f"Cash flow: {ctx.cash_flow_phase.value}"

        # Modyfikator makroekonomiczny
        macro = ctx.macro_context
        if macro.get("high_rates") and mode == StrategicMode.GROWTH:
            mode = StrategicMode.CASH_PROTECT
            reason += " + wysokie stopy → Cash Protect"
        elif macro.get("high_inflation") and mode == StrategicMode.CASH_PROTECT:
            mode = StrategicMode.GROWTH
            reason += " + wysoka inflacja → Growth"

        # Modyfikator okresu podatkowego
        if ctx.tax_period in ("vat_deadline", "year_end"):
            if mode != StrategicMode.CASH_PROTECT:
                mode = StrategicMode.TAX_OPTIMAL
                reason += f" + {ctx.tax_period} → Tax Optimal"

        self._set_mode(mode, reason)
        return mode, reason

    def set_user_strategic_mode(
        self,
        mode: StrategicMode,
    ) -> None:
        """Ustaw tryb strategiczny jawnie wybrany przez użytkownika.

        Agent: "Widzę, że masz wysoki stan gotówki. Czy wolisz:
        1. 💵 Zachować płynność
        2. 📈 Zainwestować nadwyżkę
        3. 🏗️ Rozłożyć koszty w czasie"
        """
        self._set_mode(mode, "user_selected")

    def _set_mode(self, mode: StrategicMode, reason: str) -> None:
        """Ustaw tryb strategiczny i zapisz w historii."""
        old_mode = self._current_mode
        self._current_mode = mode
        self._mode_history.append((
            pendulum.now("UTC").isoformat(),
            mode,
            reason,
        ))

        # Trim history
        if len(self._mode_history) > 50:
            self._mode_history = self._mode_history[-50:]

        if old_mode != mode:
            self._logger.info(
                "[STRATEGY] Mode changed | %s → %s | reason: %s",
                old_mode.value, mode.value, reason,
            )

    # ── Podejmowanie decyzji w oparciu o strategię ──────────────────

    def should_auto_post(
        self,
        trust_score: float,
        amount: float = 0.0,
        is_routine: bool = True,
        vendor_is_trusted: bool = False,
    ) -> tuple[bool, DecisionMode, str]:
        """Zdecyduj czy faktura powinna być AUTO_POST na podstawie strategii.

        GENIALNY POMYSŁ v6.0:
        W trybie Silent wszystkie decyzje przechodzą na AUTO_POST.
        Tylko wyjątki (niski trust, wysoka kwota) trafiają do SUGGEST.

        Args:
            trust_score: Trust Score decyzji (0.0-1.0).
            amount: Kwota faktury.
            is_routine: Czy to rutynowa faktura.
            vendor_is_trusted: Czy kontrahent jest zaufany.

        Returns:
            Tuple (czy auto_post, DecisionMode, przyczyna).
        """
        thresholds = self.STRATEGY_THRESHOLDS.get(self._current_mode, {})
        auto_threshold = thresholds.get("auto_post", 0.85)
        max_amount = thresholds.get("max_auto_amount", 30000.0)

        # Modyfikator okresu podatkowego
        tax_mod = self.TAX_PERIOD_MODIFIERS.get(
            self._context.tax_period, {"auto_post_delta": 0.0},
        )
        auto_threshold += tax_mod.get("auto_post_delta", 0.0)

        # Rutynowe faktury od zaufanych kontrahentów → zawsze AUTO_POST
        if is_routine and vendor_is_trusted and amount <= max_amount:
            return True, DecisionMode.AUTO_POST, "Rutynowa faktura od zaufanego kontrahenta"

        # Wysoka kwota → wymaga uwagi
        if amount > max_amount * 2:
            if trust_score >= auto_threshold:
                return True, DecisionMode.SUGGEST, f"Wysoka kwota ({amount:.0f} PLN) ale wysoki trust"
            return False, DecisionMode.ASK_USER, f"Wysoka kwota ({amount:.0f} PLN) i niski trust"

        # Niski trust → w zależności od trybu
        if trust_score < auto_threshold:
            if self._current_mode == StrategicMode.EFFICIENCY and trust_score >= 0.7:
                return True, DecisionMode.AUTO_POST, "Tryb Efficiency — obniżony próg"
            return False, DecisionMode.SUGGEST, f"Trust {trust_score:.2f} < próg {auto_threshold:.2f}"

        # Standard: AUTO_POST
        return True, DecisionMode.AUTO_POST, f"Trust {trust_score:.2f} ≥ próg {auto_threshold:.2f}"

    def should_skip_quality_validator(self, trust_score: float) -> bool:
        """Czy pominąć QualityValidator w trybie Efficiency."""
        if self._current_mode == StrategicMode.EFFICIENCY:
            thresholds = self.STRATEGY_THRESHOLDS[StrategicMode.EFFICIENCY]
            if thresholds.get("skip_quality_validator", False) and trust_score >= 0.85:
                return True
        return False

    # ── Strategiczne rekomendacje ───────────────────────────────────

    def generate_strategic_recommendations(
        self,
        cash_balance: float = 0.0,
        pending_payables: float = 0.0,
        recent_auto_post_count: int = 0,
        correction_rate: float = 0.0,
    ) -> list[StrategicRecommendation]:
        """Generuj strategiczne rekomendacje dla przedsiębiorcy.

        Agent NIE pyta o taktykę — pyta o STRATEGIĘ.

        Returns:
            Lista 0-2 rekomendacji strategicznych.
        """
        recommendations: list[StrategicRecommendation] = []
        now = pendulum.now("UTC")

        # Rekomendacja 1: Wysoki stan gotówki
        if cash_balance > pending_payables * 3 and cash_balance > 50000:
            rec = StrategicRecommendation(
                rec_id=uuid.uuid4().hex[:12],
                category="liquidity",
                title="Wysoki stan gotówki — co z nadwyżką?",
                description=(
                    f"Masz {cash_balance:,.0f} PLN wolnej gotówki "
                    f"(3× więcej niż zobowiązania {pending_payables:,.0f} PLN). "
                    f"Przy obecnych stopach {self._context.macro_context.get('interest_rate', 5.75)}% "
                    f"i inflacji {self._context.macro_context.get('inflation', 4.0)}%, "
                    f"rozważ inwestycję nadwyżki."
                ),
                impact="high",
                potential_savings=cash_balance * 0.03,  # 3% potencjalny zysk
                options=[
                    {
                        "label": "💵 Zachowaj płynność",
                        "description": "Niższe ryzyko, gotówka dostępna od ręki",
                        "mode": StrategicMode.CASH_PROTECT.value,
                    },
                    {
                        "label": "📈 Zainwestuj nadwyżkę",
                        "description": "Wyższy zysk, obligacje/lokaty",
                        "mode": StrategicMode.GROWTH.value,
                    },
                    {
                        "label": "🏗️ Rozłóż koszty w czasie",
                        "description": "Niższy PIT przez odpisy",
                        "mode": StrategicMode.TAX_OPTIMAL.value,
                    },
                ],
                context_drivers=["cash_flow_phase", "macro_context"],
                created_at=now.isoformat(),
            )
            recommendations.append(rec)

        # Rekomendacja 2: Wysoki wskaźnik korekt
        if correction_rate > 0.15 and recent_auto_post_count > 50:
            rec = StrategicRecommendation(
                rec_id=uuid.uuid4().hex[:12],
                category="efficiency",
                title=f"Wysoki wskaźnik korekt ({correction_rate:.0%}) — czy zmienić strategię?",
                description=(
                    f"W ostatnim okresie skorygowano {correction_rate:.0%} automatycznych decyzji. "
                    f"Może to oznaczać, że obecny tryb ({self._current_mode.value}) "
                    f"nie jest optymalny dla Twojej sytuacji."
                ),
                impact="medium",
                potential_savings=recent_auto_post_count * correction_rate * 50,  # 50 PLN oszczędności na unikniętej korekcie
                options=[
                    {
                        "label": "🎯 Przełącz na Efficiency",
                        "description": "Najszybsza ścieżka, mniej walidacji",
                        "mode": StrategicMode.EFFICIENCY.value,
                    },
                    {
                        "label": "⚖️ Przełącz na Tax Optimal",
                        "description": "Dokładniejsza analiza podatkowa",
                        "mode": StrategicMode.TAX_OPTIMAL.value,
                    },
                ],
                context_drivers=["correction_rate"],
                created_at=now.isoformat(),
            )
            recommendations.append(rec)

        # Rekomendacja 3: Sezonowość
        if self._context.vendor_season == "high_season" and self._current_mode != StrategicMode.CASH_PROTECT:
            rec = StrategicRecommendation(
                rec_id=uuid.uuid4().hex[:12],
                category="risk",
                title="Wysoki sezon u kontrahentów — czy zabezpieczyć płynność?",
                description=(
                    f"Twoi kontrahenci są w wysokim sezonie ({self._context.vendor_season}). "
                    f"Rozważ tryb Cash Protect, aby zabezpieczyć płynność na wypadek opóźnień."
                ),
                impact="medium",
                potential_savings=0.0,
                options=[
                    {
                        "label": "💰 Włącz Cash Protect",
                        "description": "Zabezpiecz płynność na sezon",
                        "mode": StrategicMode.CASH_PROTECT.value,
                    },
                    {
                        "label": "🤝 Kontynuuj obecny tryb",
                        "description": f"Pozostań w trybie {self._current_mode.value}",
                        "mode": self._current_mode.value,
                    },
                ],
                context_drivers=["vendor_season"],
                created_at=now.isoformat(),
            )
            if len(recommendations) < 2:
                recommendations.append(rec)

        self._strategic_recommendations = recommendations
        return recommendations

    # ── Silent Rate ─────────────────────────────────────────────────

    def calculate_silent_rate(
        self,
        total_decisions: int,
        auto_posted: int,
    ) -> float:
        """Oblicz Silent Rate — kluczowa metryka v6.0.

        Silent Rate = auto_posted / total × 100%
        Cel: ≥ 95%
        """
        if total_decisions == 0:
            return 100.0
        return (auto_posted / total_decisions) * 100.0

    def calculate_time_saved(
        self,
        auto_posted_count: int,
        avg_time_per_decision_minutes: float = 2.5,
    ) -> float:
        """Oblicz oszczędność czasu przedsiębiorcy.

        Każda automatycznie podjęta decyzja to ~2.5 min oszczędności.
        """
        return auto_posted_count * avg_time_per_decision_minutes

    # ── Podsumowanie strategii ─────────────────────────────────────

    def get_strategy_summary(self) -> dict[str, Any]:
        """Pobierz podsumowanie aktualnej strategii."""
        thresholds = self.STRATEGY_THRESHOLDS.get(self._current_mode, {})
        return {
            "current_mode": self._current_mode.value,
            "context": self._context.summary if self._context else "brak",
            "auto_post_threshold": thresholds.get("auto_post", 0.85),
            "max_auto_amount": thresholds.get("max_auto_amount", 30000.0),
            "mode_history": [
                {"timestamp": ts, "mode": m.value, "reason": r}
                for ts, m, r in self._mode_history[-5:]
            ],
            "recommendations_count": len(self._strategic_recommendations),
            "vendor_season": self._context.vendor_season if self._context else "unknown",
            "tax_period": self._context.tax_period if self._context else "unknown",
        }

    # ── Pomocnicze ──────────────────────────────────────────────────

    @staticmethod
    def get_strategic_question(mode: StrategicMode) -> dict[str, Any]:
        """Wygeneruj pytanie strategiczne do użytkownika.

        Agent pyta o STRATEGIĘ, nie o taktykę.
        """
        questions = {
            StrategicMode.CASH_PROTECT: {
                "question": "Czy chcesz zmienić strategię na bardziej ofensywną?",
                "options": [
                    {"label": "📈 Przełącz na Growth", "mode": StrategicMode.GROWTH.value},
                    {"label": "💰 Zostań przy Cash Protect", "mode": StrategicMode.CASH_PROTECT.value},
                ],
            },
            StrategicMode.GROWTH: {
                "question": "Widzę wysoką aktywność inwestycyjną. Czy to świadome?",
                "options": [
                    {"label": "✅ Tak, kontynuuj Growth", "mode": StrategicMode.GROWTH.value},
                    {"label": "⚠️ Zwolnij — Cash Protect", "mode": StrategicMode.CASH_PROTECT.value},
                ],
            },
            StrategicMode.TAX_OPTIMAL: {
                "question": "Czy priorytetem jest minimalizacja podatków, czy płynność?",
                "options": [
                    {"label": "⚖️ Minimalizuj podatki", "mode": StrategicMode.TAX_OPTIMAL.value},
                    {"label": "💵 Priorytet: płynność", "mode": StrategicMode.CASH_PROTECT.value},
                ],
            },
            StrategicMode.EFFICIENCY: {
                "question": "Czy tempo automatycznego księgowania jest odpowiednie?",
                "options": [
                    {"label": "🎯 Kontynuuj Efficiency", "mode": StrategicMode.EFFICIENCY.value},
                    {"label": "🔍 Więcej kontroli — Tax Optimal", "mode": StrategicMode.TAX_OPTIMAL.value},
                ],
            },
        }
        return questions.get(mode, questions[StrategicMode.EFFICIENCY])
