"""UserDecisionProfile — Progressive Autonomy Engine (GENIALNY POMYSŁ v5.2 + v7.0).

"Agent, Który Rośnie z Przedsiębiorcą"

Agent obserwuje wzorce decyzyjne konkretnego przedsiębiorcy i stopniowo
przejmuje rutynowe decyzje. Cel: Decision Autonomy Score ≥ 90%.

TYDZIEŃ 1:  0% autonomii — wszystkie decyzje przez Action Cards
TYDZIEŃ 2: 40% — rutynowe faktury od znanych kontrahentów → AUTO_POST
TYDZIEŃ 4: 70% — większość decyzji automatyczna
MIESIĄC 3: 90%+ — przedsiębiorca widzi tylko wyjątki i podsumowania

GENIALNY POMYSŁ v7.0 — Uczenie się Strategii zamiast Nawyków:
Zamiast 4 wymiarów uczenia (vendor, category, amount, time) →
dodajemy 5. wymiar: Business Strategy (CASH_PROTECT, TAX_MINIMIZE, GROWTH, BALANCED).
Agent uczy się nie CO przedsiębiorca klika, ale DLACZEGO —
czyli jaką strategię biznesową realizuje.

Zgodnie z aa3fvcx.txt, AGENT_SYSTEM_ENTERPRISE.txt:
- Tylko technologie z RAPORT_TECHNOLOGII_NEXUSAI.txt
- SQLite + sqlite-vec dla pamięci wzorców
- DuckDB dla analityki decyzji
- msgspec dla struktur danych
- Istniejący ContinuousLearningProvider + CognitiveProofBlock
"""

from __future__ import annotations

import enum
import uuid
from dataclasses import dataclass, field
from typing import Any

import pendulum
from msgspec import Struct, field as msgspec_field
from structlog import get_logger

logger = get_logger("nexus.agents.profile")


# ═════════════════════════════════════════════════════════════════════════
# Business Strategy — GENIALNY POMYSŁ v7.0
# ═════════════════════════════════════════════════════════════════════════


class BusinessStrategy(enum.StrEnum):
    """Strategia biznesowa przedsiębiorcy — 5. wymiar uczenia.

    GENIALNY POMYSŁ v7.0 — Business Impact Decisions:
    Agent uczy się nie CO przedsiębiorca klika, ale DLACZEGO —
    czyli jaką strategię biznesową realizuje.

    - CASH_PROTECT: Chroń płynność — wybieraj opcje maksymalizujące
      gotówkę w kasie (jednorazowe koszty, odroczone płatności).
    - TAX_MINIMIZE: Minimalizuj podatek — wybieraj opcje obniżające
      PIT/CIT w bieżącym okresie (maksymalizacja kosztów).
    - GROWTH: Inwestuj w rozwój — rozkładaj koszty w czasie,
      buduj wartość firmy (amortyzacja, aktywa).
    - BALANCED: Wyważone podejście — domyślna strategia.
    """

    CASH_PROTECT = "cash_protect"
    TAX_MINIMIZE = "tax_minimize"
    GROWTH = "growth"
    BALANCED = "balanced"


class StrategyProfile(Struct, kw_only=True):
    """Profil strategiczny przedsiębiorcy — uczenie się DLACZEGO.

    GENIALNY POMYSŁ v7.0:
    Zamiast uczyć się nawyków ("zawsze klika VAT 23%"),
    agent uczy się strategii ("w Q4 zawsze maksymalizuje koszty" → TAX_MINIMIZE).

    Obserwuje wybory użytkownika i wykrywa wzorzec strategiczny:
    - Jeśli użytkownik zawsze wybiera opcję z najlepszym cash-flow → CASH_PROTECT
    - Jeśli zawsze wybiera opcję z najniższym PIT → TAX_MINIMIZE
    - Jeśli zawsze wybiera amortyzację → GROWTH
    """

    strategy: BusinessStrategy = BusinessStrategy.BALANCED
    """Wykryta strategia biznesowa."""

    confidence: float = 0.0
    """Pewność wykrycia strategii (0.0-1.0). Rośnie z każdą zgodną decyzją."""

    total_decisions: int = 0
    """Liczba decyzji zgodnych z tą strategią."""

    # ── Rozkład wyborów strategicznych ──────────────────────────
    cash_protect_count: int = 0
    """Ile razy wybrano opcję CASH_PROTECT."""

    tax_minimize_count: int = 0
    """Ile razy wybrano opcję TAX_MINIMIZE."""

    growth_count: int = 0
    """Ile razy wybrano opcję GROWTH."""

    balanced_count: int = 0
    """Ile razy wybrano opcję BALANCED."""

    # ── Sezonowość strategiczna ─────────────────────────────────
    quarterly_patterns: dict[str, str] = msgspec_field(default_factory=dict)
    """Strategia per kwartał: {"Q1": "GROWTH", "Q4": "TAX_MINIMIZE", ...}."""

    last_updated: str = ""
    """ISO timestamp ostatniej aktualizacji."""

    def observe_strategy_choice(self, chosen_strategy: str) -> None:
        """Obserwuj wybór strategiczny użytkownika.

        Args:
            chosen_strategy: Którą strategię wybrał użytkownik
                             (cash_protect, tax_minimize, growth, balanced).
        """
        now = pendulum.now("UTC")
        self.total_decisions += 1
        self.last_updated = now.isoformat()

        # Aktualizuj liczniki
        strategy_map = {
            "CASH_PROTECT": "cash_protect_count",
            "cash_protect": "cash_protect_count",
            "TAX_MINIMIZE": "tax_minimize_count",
            "tax_minimize": "tax_minimize_count",
            "GROWTH": "growth_count",
            "growth": "growth_count",
            "BALANCED": "balanced_count",
            "balanced": "balanced_count",
        }
        counter_attr = strategy_map.get(chosen_strategy, "balanced_count")
        current = getattr(self, counter_attr, 0)
        setattr(self, counter_attr, current + 1)

        # Znajdź dominującą strategię
        counts = {
            BusinessStrategy.CASH_PROTECT: self.cash_protect_count,
            BusinessStrategy.TAX_MINIMIZE: self.tax_minimize_count,
            BusinessStrategy.GROWTH: self.growth_count,
            BusinessStrategy.BALANCED: self.balanced_count,
        }
        dominant = max(counts, key=lambda k: counts[k])
        dominant_count = counts[dominant]

        if dominant_count >= 3 and self.total_decisions >= 5:
            self.strategy = dominant
            self.confidence = min(1.0, dominant_count / self.total_decisions)

        # Zapisz wzorzec kwartalny
        quarter = f"Q{(now.month - 1) // 3 + 1}"
        self.quarterly_patterns[quarter] = dominant.value

    def get_strategy_for_quarter(self, quarter: str | None = None) -> BusinessStrategy:
        """Pobierz strategię dla danego kwartału.

        Jeśli dla tego kwartału jest znany wzorzec, użyj go.
        W przeciwnym razie zwróć ogólną strategię.

        Args:
            quarter: Kwartał ("Q1", "Q2", "Q3", "Q4"). Jeśli None, bieżący.

        Returns:
            BusinessStrategy dla danego kwartału.
        """
        if quarter is None:
            quarter = f"Q{(pendulum.now('UTC').month - 1) // 3 + 1}"

        if quarter in self.quarterly_patterns:
            try:
                return BusinessStrategy(self.quarterly_patterns[quarter])
            except ValueError:
                pass

        return self.strategy

    @property
    def is_mature(self) -> bool:
        """Czy strategia jest wystarczająco dojrzała do auto-decyzji."""
        return self.confidence >= 0.7 and self.total_decisions >= 5

    @property
    def dominant_strategy_label(self) -> str:
        """Etykieta dominującej strategii dla UI."""
        labels = {
            BusinessStrategy.CASH_PROTECT: "💰 Chronisz gotówkę",
            BusinessStrategy.TAX_MINIMIZE: "⚖️ Minimalizujesz podatek",
            BusinessStrategy.GROWTH: "📈 Inwestujesz w rozwój",
            BusinessStrategy.BALANCED: "🎯 Wyważone podejście",
        }
        return labels.get(self.strategy, "🎯 Wyważone podejście")

    @property
    def agent_hint(self) -> str:
        """Podpowiedź agenta budująca zaufanie.

        GENIALNY POMYSŁ v7.0:
        Pod kartą: podpowiedź agenta budująca zaufanie.
        "W tym kwartale zwykle chronisz gotówkę"
        """
        quarter = f"Q{(pendulum.now('UTC').month - 1) // 3 + 1}"
        strategy = self.get_strategy_for_quarter(quarter)

        hints = {
            BusinessStrategy.CASH_PROTECT: f"W {quarter} zwykle chronisz gotówkę",
            BusinessStrategy.TAX_MINIMIZE: f"W {quarter} zwykle minimalizujesz podatek",
            BusinessStrategy.GROWTH: f"W {quarter} zwykle inwestujesz w rozwój",
            BusinessStrategy.BALANCED: "Uczę się Twoich preferencji strategicznych",
        }
        return hints.get(strategy, hints[BusinessStrategy.BALANCED])


# ═════════════════════════════════════════════════════════════════════════
# Struktury danych (msgspec)
# ═════════════════════════════════════════════════════════════════════════


class DecisionPattern(Struct, kw_only=True):
    """Pojedynczy wzorzec decyzyjny przedsiębiorcy."""

    pattern_id: str
    pattern_type: str  # vendor_trust | category_preference | amount_threshold | time_pattern | correction_pattern
    key: str  # np. "nip:1234567890", "category:IT", "amount:medium"
    total_decisions: int = 0
    auto_acceptable: int = 0  # ile razy user zaakceptował AUTO_POST
    corrections: int = 0  # ile razy user skorygował
    last_decision_at: str = ""
    confidence: float = 0.0  # 0.0-1.0 — jak pewny jest wzorzec

    @property
    def acceptance_rate(self) -> float:
        if self.total_decisions == 0:
            return 0.0
        return self.auto_acceptable / self.total_decisions

    @property
    def is_mature(self) -> bool:
        """Czy wzorzec jest wystarczająco dojrzały do automatyzacji."""
        return self.total_decisions >= 5 and self.acceptance_rate >= 0.8


class VendorTrustProfile(Struct, kw_only=True):
    """Profil zaufania do kontrahenta."""

    nip: str
    vendor_name: str = ""
    total_invoices: int = 0
    auto_accepted: int = 0
    rejected: int = 0
    avg_amount: float = 0.0
    first_invoice_at: str = ""
    last_invoice_at: str = ""
    trust_level: str = "new"  # new | learning | trusted | fully_trusted
    adaptive_threshold: float = 0.92  # AUTO_POST threshold dla tego vendor

    def update_trust_level(self) -> None:
        if self.total_invoices >= 20 and self.acceptance_rate >= 0.95:
            self.trust_level = "fully_trusted"
            self.adaptive_threshold = 0.75
        elif self.total_invoices >= 10 and self.acceptance_rate >= 0.9:
            self.trust_level = "trusted"
            self.adaptive_threshold = 0.82
        elif self.total_invoices >= 3:
            self.trust_level = "learning"
            self.adaptive_threshold = 0.88
        else:
            self.trust_level = "new"
            self.adaptive_threshold = 0.92

    @property
    def acceptance_rate(self) -> float:
        if self.total_invoices == 0:
            return 0.0
        return self.auto_accepted / self.total_invoices


class CategoryPreference(Struct, kw_only=True):
    """Preferencje kategorii wydatków."""

    category: str  # IT, spożywcze, usługi, materiały, etc.
    total_decisions: int = 0
    preferred_action: str = ""  # confirm | alternative | reject
    preferred_option: str = ""  # np. "amortyzacja_liniowa", "koszt_100%"
    confidence: float = 0.0


class AmountThreshold(Struct, kw_only=True):
    """Próg kwotowy przedsiębiorcy."""

    range_label: str  # micro | small | medium | large | xlarge
    min_amount: float = 0.0
    max_amount: float = 0.0
    auto_approved: int = 0
    manual_reviewed: int = 0
    preferred_auto: bool = False  # Czy user preferuje auto-posting w tym zakresie

    @property
    def should_auto_post(self) -> bool:
        return self.preferred_auto and self.total > 5 and self.approval_rate > 0.85

    @property
    def total(self) -> int:
        return self.auto_approved + self.manual_reviewed

    @property
    def approval_rate(self) -> float:
        if self.total == 0:
            return 0.0
        return self.auto_approved / self.total


class WeeklyAutonomyReport(Struct, kw_only=True):
    """Cotygodniowy raport autonomii dla przedsiębiorcy."""

    report_id: str
    week_start: str
    week_end: str
    total_decisions: int = 0
    auto_posted: int = 0
    suggested: int = 0
    asked_user: int = 0
    autonomy_score: float = 0.0  # 0-100%
    previous_score: float = 0.0
    trend: str = "stable"  # up | down | stable
    top_trusted_vendors: list[str] = msgspec_field(default_factory=list)
    patterns_discovered: int = 0
    clicks_saved: int = 0
    message: str = ""  # NL podsumowanie


# ═════════════════════════════════════════════════════════════════════════
# UserDecisionProfile — Główna klasa
# ═════════════════════════════════════════════════════════════════════════


class UserDecisionProfile:
    """Profil decyzyjny przedsiębiorcy — Progressive Autonomy Engine.

    GENIALNY POMYSŁ v5.2 + v7.0:
    Agent NIE tylko reaguje na faktury — OBSERWUJE jak przedsiębiorca
    podejmuje decyzje i ADAPTUJE się do jego stylu.

    Pięć wymiarów uczenia:
    1. Vendor Trust — "Zawsze akceptujesz faktury od XYZ" → niższy próg
    2. Category Preference — "Zawsze wybierasz amortyzację liniową dla IT"
    3. Amount Threshold — "Sprawdzasz ręcznie wszystko > 20k PLN"
    4. Time Pattern — "W piątki odrzucasz wszystko"
    5. Business Strategy (v7.0) — "W Q4 zawsze maksymalizujesz koszty" → TAX_MINIMIZE

    Metryka: Decision Autonomy Score = AUTO_POST / (AUTO_POST + ASK_USER) × 100%

    Cel: Start 0% → Tydzień 2: 40% → Tydzień 4: 70% → Miesiąc 3: 90%+

    Technologie (z RAPORT_TECHNOLOGII):
    - SQLite + sqlite-vec: pamięć wzorców decyzyjnych
    - DuckDB: analityka trendów autonomii
    - msgspec: wszystkie struktury
    - Istniejący ContinuousLearningProvider + CognitiveProofBlock
    """

    # ── Progi dojrzałości wzorców ──────────────────────────────────

    MIN_DECISIONS_FOR_PATTERN = 3  # Minimum decyzji do powstania wzorca
    MIN_DECISIONS_FOR_TRUST = 5  # Minimum do obniżenia progu AUTO_POST
    MIN_ACCEPTANCE_FOR_TRUST = 0.8  # 80% akceptacji = zaufany wzorzec
    MAX_AUTONOMY_SCORE = 95.0  # Maksymalny poziom autonomii (zawsze 5% dla człowieka)

    # ── Przedziały kwotowe ─────────────────────────────────────────

    AMOUNT_RANGES = [
        ("micro", 0, 1_000),
        ("small", 1_000, 10_000),
        ("medium", 10_000, 50_000),
        ("large", 50_000, 200_000),
        ("xlarge", 200_000, float("inf")),
    ]

    # ── Progi trust level → adaptive threshold ─────────────────────

    TRUST_THRESHOLDS = {
        "fully_trusted": 0.75,
        "trusted": 0.82,
        "learning": 0.88,
        "new": 0.92,
    }

    def __init__(self) -> None:
        self._vendor_profiles: dict[str, VendorTrustProfile] = {}
        self._category_preferences: dict[str, CategoryPreference] = {}
        self._amount_thresholds: dict[str, AmountThreshold] = {}
        self._patterns: list[DecisionPattern] = []
        self._decision_history: list[dict[str, Any]] = []
        self._autonomy_history: list[dict[str, Any]] = []  # {date, score, total}
        # ── GENIALNY POMYSŁ v7.0: 5. wymiar — Business Strategy ──
        self._strategy_profile: StrategyProfile = StrategyProfile()
        self._logger = get_logger("nexus.agents.profile")

    # ── GENIALNY POMYSŁ v7.0: Strategy Profile ───────────────────

    @property
    def strategy_profile(self) -> StrategyProfile:
        """Profil strategiczny przedsiębiorcy — 5. wymiar uczenia.

        GENIALNY POMYSŁ v7.0:
        Agent uczy się DLACZEGO przedsiębiorca podejmuje decyzje.
        """
        return self._strategy_profile

    def observe_strategy_choice(self, chosen_strategy: str) -> None:
        """Obserwuj wybór strategiczny użytkownika.

        Wywoływane gdy użytkownik wybiera opcję na karcie
        Financial Impact Card — zapisuje którą STRATEGIĘ wybrał.

        Args:
            chosen_strategy: CASH_PROTECT, TAX_MINIMIZE, GROWTH, BALANCED.
        """
        self._strategy_profile.observe_strategy_choice(chosen_strategy)

    def get_strategy_based_decision(
        self,
        trust_score: float,
        amount: float,
    ) -> tuple[bool, str]:
        """Podejmij decyzję AUTO_POST na podstawie strategii.

        GENIALNY POMYSŁ v7.0:
        Jeśli strategia jest dojrzała (confidence >= 0.7),
        agent AUTO_POST wybiera opcję zgodną ze strategią — bez pytania.

        Returns:
            (should_auto_post: bool, reason: str)
        """
        if not self._strategy_profile.is_mature:
            return False, "Strategia jeszcze niedojrzała — potrzebuję więcej danych"

        strategy = self._strategy_profile.get_strategy_for_quarter()

        # W trybie CASH_PROTECT: niższy próg dla rutynowych faktur
        if strategy == BusinessStrategy.CASH_PROTECT:
            if trust_score >= 0.85 and amount < 50000:
                return True, f"Strategia {strategy.value}: ochrona płynności — auto-księgowanie"

        # W trybie TAX_MINIMIZE: auto-księgowanie dla kosztów
        elif strategy == BusinessStrategy.TAX_MINIMIZE:
            if trust_score >= 0.80 and amount < 100000:
                return True, f"Strategia {strategy.value}: optymalizacja podatkowa — auto-księgowanie"

        # W trybie GROWTH: auto-księgowanie dla inwestycji
        elif strategy == BusinessStrategy.GROWTH:
            if trust_score >= 0.82 and amount < 75000:
                return True, f"Strategia {strategy.value}: inwestycje — auto-księgowanie"

        # BALANCED: standardowy próg
        else:
            if trust_score >= 0.88 and amount < 30000:
                return True, f"Strategia {strategy.value}: standardowe auto-księgowanie"

        return False, f"Strategia {strategy.value}: wymaga weryfikacji (trust={trust_score:.2f})"

    # ── Obserwacja decyzji ────────────────────────────────────────

    def observe_decision(
        self,
        vendor_nip: str,
        vendor_name: str = "",
        amount_gross: float = 0.0,
        category: str = "",
        status: str = "AUTO_POST",
        decision_mode: str = "auto_post",
        user_action: str = "confirm",
        user_option: str = "",
        chosen_strategy: str = "",
    ) -> None:
        """Obserwuj decyzję i aktualizuj profile.

        Każda decyzja (AUTO_POST, SUGGEST, ASK_USER) i każda akcja
        użytkownika (confirm, reject, alternative) to punkt danych.

        Args:
            vendor_nip: NIP kontrahenta.
            vendor_name: Nazwa kontrahenta (opcjonalnie).
            amount_gross: Kwota brutto.
            category: Kategoria wydatku.
            status: Status decyzji: AUTO_POST, REVIEW, BLOCK.
            decision_mode: Tryb: auto_post, suggest, ask_user.
            user_action: Akcja użytkownika: confirm, reject, alternative.
            user_option: Wybrana opcja (np. "amortyzacja_liniowa").
            chosen_strategy: Strategia wybrana przez użytkownika (v7.0).
        """
        now = pendulum.now("UTC").isoformat()

        # 1. Vendor Trust
        self._update_vendor_trust(vendor_nip, vendor_name, amount_gross, status, decision_mode, user_action, now)

        # 2. Category Preference
        if category and user_option:
            self._update_category_preference(category, user_action, user_option)

        # 3. Amount Threshold
        self._update_amount_threshold(amount_gross, status, decision_mode, user_action)

        # 4. Decision History
        self._decision_history.append({
            "vendor_nip": vendor_nip,
            "amount": amount_gross,
            "category": category,
            "status": status,
            "mode": decision_mode,
            "action": user_action,
            "option": user_option,
            "timestamp": now,
        })

        # 5. Autonomy Score
        self._update_autonomy_score(status, decision_mode, now)

        # 6. GENIALNY POMYSŁ v7.0: Strategy observation
        if chosen_strategy:
            self._strategy_profile.observe_strategy_choice(chosen_strategy)

        # 7. Derive patterns from accumulated data
        self._derive_patterns()

        # Trim history
        if len(self._decision_history) > 10_000:
            self._decision_history = self._decision_history[-5_000:]

    def _update_vendor_trust(
        self,
        nip: str,
        name: str,
        amount: float,
        status: str,
        mode: str,
        action: str,
        now: str,
    ) -> None:
        if nip not in self._vendor_profiles:
            self._vendor_profiles[nip] = VendorTrustProfile(
                nip=nip,
                vendor_name=name,
                first_invoice_at=now,
            )

        profile = self._vendor_profiles[nip]
        profile.total_invoices += 1
        profile.last_invoice_at = now
        profile.avg_amount = (
            (profile.avg_amount * (profile.total_invoices - 1) + amount)
            / profile.total_invoices
        )
        if name and not profile.vendor_name:
            profile.vendor_name = name
        if action == "confirm" and mode == "auto_post":
            profile.auto_accepted += 1
        if action == "reject":
            profile.rejected += 1

        profile.update_trust_level()

    def _update_category_preference(self, category: str, action: str, option: str) -> None:
        if category not in self._category_preferences:
            self._category_preferences[category] = CategoryPreference(category=category)

        pref = self._category_preferences[category]
        pref.total_decisions += 1
        if action == "confirm":
            pref.preferred_action = "confirm"
            pref.preferred_option = option
        elif action == "alternative" and pref.preferred_action != "confirm":
            pref.preferred_action = "alternative"
            pref.preferred_option = option
        pref.confidence = min(1.0, pref.total_decisions / self.MIN_DECISIONS_FOR_TRUST)

    def _update_amount_threshold(
        self,
        amount: float,
        status: str,
        mode: str,
        action: str,
    ) -> None:
        range_label = self._get_amount_range(amount)

        if range_label not in self._amount_thresholds:
            thresholds = dict(self.AMOUNT_RANGES)
            min_amt, max_amt = thresholds.get(range_label, (0, float("inf")))
            self._amount_thresholds[range_label] = AmountThreshold(
                range_label=range_label,
                min_amount=min_amt,
                max_amount=max_amt,
            )

        threshold = self._amount_thresholds[range_label]
        if mode == "auto_post" and action == "confirm":
            threshold.auto_approved += 1
            threshold.preferred_auto = True
        elif mode in ("suggest", "ask_user"):
            threshold.manual_reviewed += 1
            if threshold.manual_reviewed > threshold.auto_approved:
                threshold.preferred_auto = False

    def _update_autonomy_score(self, status: str, mode: str, now: str) -> None:
        today = pendulum.parse(now).to_date_string()

        # Sprawdź czy już mamy wpis na dziś
        for entry in reversed(self._autonomy_history):
            if entry["date"] == today:
                entry["total"] += 1
                if mode == "auto_post":
                    entry["auto"] += 1
                elif mode == "ask_user":
                    entry["manual"] += 1
                if entry["total"] > 0:
                    entry["score"] = round(
                        entry["auto"] / entry["total"] * 100, 1
                    )
                return

        # Nowy wpis
        self._autonomy_history.append({
            "date": today,
            "total": 1,
            "auto": 1 if mode == "auto_post" else 0,
            "manual": 1 if mode == "ask_user" else 0,
            "score": 100.0 if mode == "auto_post" else 0.0,
        })

    # ── Uczenie wzorców ──────────────────────────────────────────

    def _derive_patterns(self) -> None:
        """Wyprowadź wzorce decyzyjne z danych vendor/category/amount.

        GENIALNY POMYSŁ v5.2:
        Nie przechowujemy wzorców osobno — co observe_decision()
        derywujemy je z istniejących profili vendor, category i amount.
        """
        self._patterns = []
        now = pendulum.now("UTC").isoformat()

        # 1. Vendor Trust patterns
        for nip, vp in self._vendor_profiles.items():
            if vp.total_invoices >= self.MIN_DECISIONS_FOR_PATTERN:
                self._patterns.append(DecisionPattern(
                    pattern_id=uuid.uuid4().hex[:12],
                    pattern_type="vendor_trust",
                    key=f"nip:{nip}",
                    total_decisions=vp.total_invoices,
                    auto_acceptable=vp.auto_accepted,
                    last_decision_at=vp.last_invoice_at,
                    confidence=vp.acceptance_rate,
                ))

        # 2. Category Preference patterns
        for cat, cp in self._category_preferences.items():
            if cp.total_decisions >= self.MIN_DECISIONS_FOR_PATTERN:
                self._patterns.append(DecisionPattern(
                    pattern_id=uuid.uuid4().hex[:12],
                    pattern_type="category_preference",
                    key=f"category:{cat}",
                    total_decisions=cp.total_decisions,
                    auto_acceptable=cp.total_decisions if cp.preferred_action == "confirm" else 0,
                    last_decision_at=now,
                    confidence=cp.confidence,
                ))

        # 3. Amount Threshold patterns
        for rng, at in self._amount_thresholds.items():
            if at.total >= self.MIN_DECISIONS_FOR_PATTERN:
                self._patterns.append(DecisionPattern(
                    pattern_id=uuid.uuid4().hex[:12],
                    pattern_type="amount_threshold",
                    key=f"amount:{rng}",
                    total_decisions=at.total,
                    auto_acceptable=at.auto_approved,
                    last_decision_at=now,
                    confidence=at.approval_rate if at.total > 0 else 0.0,
                ))

    # ── Zapytania o profile ────────────────────────────────────────

    def get_vendor_trust(self, nip: str) -> VendorTrustProfile:
        """Pobierz profil zaufania do kontrahenta.

        Jeśli kontrahent jest nowy — zwróć domyślny profil.
        """
        if nip in self._vendor_profiles:
            return self._vendor_profiles[nip]
        return VendorTrustProfile(nip=nip, trust_level="new", adaptive_threshold=0.92)

    def get_adaptive_threshold(self, nip: str) -> float:
        """Pobierz adaptacyjny próg AUTO_POST dla kontrahenta.

        Uwzględnia Vendor Trust Level i Amount Thresholds.
        """
        vendor = self.get_vendor_trust(nip)
        return vendor.adaptive_threshold

    def get_category_preference(self, category: str) -> CategoryPreference | None:
        """Pobierz preferencję kategorii."""
        return self._category_preferences.get(category)

    def should_auto_post(
        self,
        vendor_nip: str,
        amount_gross: float,
        trust_score: float,
    ) -> tuple[bool, str]:
        """Sprawdź czy decyzja powinna być AUTO_POST na podstawie profilu.

        GENIALNY POMYSŁ v5.2:
        Zamiast używać sztywnego progu 0.92, użyj adaptacyjnego progu
        opartego na historii decyzji tego konkretnego przedsiębiorcy.

        Returns:
            (should_auto_post: bool, reason: str)
        """
        vendor = self.get_vendor_trust(vendor_nip)
        threshold = vendor.adaptive_threshold

        # Vendor fully trusted + wysoki trust → auto
        if vendor.trust_level == "fully_trusted" and trust_score >= threshold:
            return True, f"Zaufany kontrahent ({vendor.total_invoices} faktur, {vendor.acceptance_rate:.0%} akceptacji)"

        # Vendor trusted + przyzwoity trust → auto
        if vendor.trust_level == "trusted" and trust_score >= threshold:
            return True, f"Znany kontrahent ({vendor.total_invoices} faktur)"

        # Standardowy próg
        if trust_score >= threshold:
            return True, f"Trust score {trust_score:.2f} >= próg {threshold:.2f}"

        return False, f"Trust score {trust_score:.2f} < próg {threshold:.2f}"

    # ── Raporty ────────────────────────────────────────────────────

    def get_autonomy_score(self) -> float:
        """Pobierz aktualny Decision Autonomy Score (0-100%).

        AUTO_POST / (AUTO_POST + ASK_USER) × 100%
        """
        if not self._autonomy_history:
            return 0.0

        # Oblicz z ostatnich 7 dni
        recent = self._autonomy_history[-7:]
        total_auto = sum(e["auto"] for e in recent)
        total_manual = sum(e["manual"] for e in recent)
        total = total_auto + total_manual

        if total == 0:
            return 0.0

        return round(min(total_auto / total * 100, self.MAX_AUTONOMY_SCORE), 1)

    def get_autonomy_trend(self) -> str:
        """Określ trend autonomii: up, down, stable."""
        if len(self._autonomy_history) < 3:
            return "stable"

        current = self._autonomy_history[-1]["score"]
        previous = self._autonomy_history[-3]["score"]

        if current > previous + 2:
            return "up"
        elif current < previous - 2:
            return "down"
        return "stable"

    def generate_weekly_report(self) -> WeeklyAutonomyReport:
        """Generuj cotygodniowy raport autonomii.

        GENIALNY POMYSŁ v5.2:
        Przedsiębiorca widzi: "Przejąłem 73% decyzji, zaoszczędziłem 45 kliknięć"
        """
        now = pendulum.now("UTC")
        week_start = now.start_of("week").to_date_string()
        week_end = now.to_date_string()

        recent = self._autonomy_history[-7:]
        total = sum(e["total"] for e in recent)
        auto = sum(e["auto"] for e in recent)
        asked = sum(e["manual"] for e in recent)
        suggested = total - auto - asked
        score = self.get_autonomy_score()

        prev_score = 0.0
        if len(self._autonomy_history) > 7:
            prev_recent = self._autonomy_history[-14:-7]
            prev_total = sum(e["total"] for e in prev_recent)
            prev_auto = sum(e["auto"] for e in prev_recent)
            if prev_total > 0:
                prev_score = round(prev_auto / prev_total * 100, 1)

        trend = self.get_autonomy_trend()

        top_vendors = sorted(
            self._vendor_profiles.values(),
            key=lambda v: v.total_invoices,
            reverse=True,
        )[:3]
        top_names = [v.vendor_name or v.nip for v in top_vendors]

        patterns_count = sum(
            1 for p in self._patterns if p.is_mature
        )

        message = self._generate_report_message(score, trend, auto, asked, patterns_count)

        return WeeklyAutonomyReport(
            report_id=uuid.uuid4().hex[:12],
            week_start=week_start,
            week_end=week_end,
            total_decisions=total,
            auto_posted=auto,
            suggested=suggested,
            asked_user=asked,
            autonomy_score=score,
            previous_score=prev_score,
            trend=trend,
            top_trusted_vendors=top_names,
            patterns_discovered=patterns_count,
            clicks_saved=auto,  # Każde AUTO_POST = 1 klik zaoszczędzony
            message=message,
        )

    @staticmethod
    def _generate_report_message(
        score: float,
        trend: str,
        auto: int,
        asked: int,
        patterns: int,
    ) -> str:
        """Generuj NL podsumowanie raportu."""
        trend_emoji = {"up": "📈", "down": "📉", "stable": "📊"}.get(trend, "📊")

        if score >= 90:
            return (
                f"{trend_emoji} Autonomia: {score:.0f}% — niemal pełna automatyzacja! "
                f"Przejąłem {auto} decyzji, Ty podjąłeś tylko {asked}. "
                f"Mam {patterns} dojrzałych wzorców decyzyjnych."
            )
        elif score >= 70:
            return (
                f"{trend_emoji} Autonomia: {score:.0f}% — solidny poziom. "
                f"Przejąłem {auto} decyzji, {asked} wymagało Ciebie. "
                f"{patterns} wzorców w nauce. Cel: 90%+"
            )
        elif score >= 40:
            return (
                f"{trend_emoji} Autonomia: {score:.0f}% — uczę się Twoich preferencji. "
                f"{auto} decyzji automatycznych, {asked} z Twoim udziałem. "
                f"{patterns} wzorców rozpoznanych."
            )
        else:
            return (
                f"{trend_emoji} Autonomia: {score:.0f}% — wczesna faza nauki. "
                f"Każda Twoja decyzja to nowy punkt danych. "
                f"Cel: 90%+ w ciągu miesiąca."
            )

    # ── Pomocnicze ─────────────────────────────────────────────────

    @staticmethod
    def _get_amount_range(amount: float) -> str:
        for label, min_amt, max_amt in UserDecisionProfile.AMOUNT_RANGES:
            if min_amt <= amount < max_amt:
                return label
        return "xlarge"

    @property
    def vendor_count(self) -> int:
        return len(self._vendor_profiles)

    @property
    def decision_count(self) -> int:
        return len(self._decision_history)

    @property
    def patterns_discovered(self) -> int:
        return sum(1 for p in self._patterns if p.is_mature)

    def get_summary(self) -> dict[str, Any]:
        """Pobierz podsumowanie profilu."""
        sp = self._strategy_profile
        return {
            "autonomy_score": self.get_autonomy_score(),
            "autonomy_trend": self.get_autonomy_trend(),
            "total_decisions": self.decision_count,
            "vendor_count": self.vendor_count,
            "trusted_vendors": sum(
                1 for v in self._vendor_profiles.values()
                if v.trust_level in ("trusted", "fully_trusted")
            ),
            "category_count": len(self._category_preferences),
            "patterns_discovered": self.patterns_discovered,
            "latest_autonomy": self._autonomy_history[-7:] if self._autonomy_history else [],
            # ── GENIALNY POMYSŁ v7.0: Strategy Profile ──
            "business_strategy": sp.strategy.value,
            "strategy_confidence": sp.confidence,
            "strategy_label": sp.dominant_strategy_label,
            "strategy_agent_hint": sp.agent_hint,
            "quarterly_patterns": dict(sp.quarterly_patterns),
            "strategy_mature": sp.is_mature,
        }
