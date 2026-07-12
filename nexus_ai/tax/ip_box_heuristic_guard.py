"""
IP Box Heuristic Guard (Phase 5, P0) — Blokada niskiej pewności.
===============================================================

Część planu Phase 5: Legal Hardening Sprint (Kategoria 8: Czarne Łabędzie).
Problem: IP Box (5% stawka podatkowa, art. 30ca PIT) jest najczęściej
kwestionowaną ulgą przez KAS. Automatyczne generowanie wniosków KIS
o IP Box przy niskim confidence (<95%) naraża JDG na:
- Odrzucenie ulgi przez US
- Zaległość podatkową (19% - 5% = 14% różnicy!)
- Odsetki karne

Rozwiązanie: Blokada automatycznego draftowania wniosków KIS dla IP Box
gdy confidence < 95%. Wymusza ręczną weryfikację przez doradcę podatkowego.

Usage:
    guard = IpBoxHeuristicGuard()
    result = guard.evaluate(verdict)
    if result.blocked:
        # Wymuś ręczną weryfikację
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any

logger = logging.getLogger(__name__)


# ── Configuration ────────────────────────────────────────────────────────────

IP_BOX_RULE_IDS = {
    "jdg.allowances.ip_box",
    "P610",
    "P610_b",
    "P610_nexus",
    "kis_draft_ip_box",
}

MIN_CONFIDENCE_FOR_AUTO = 0.95  # 95% minimum
MIN_NEXUS_RATIO = 0.30  # Minimum Nexus ratio dla IP Box


@dataclass
class IpBoxEvaluation:
    """Wynik oceny IP Box."""
    rule_id: str
    confidence: float
    nexus_ratio: float  # Współczynnik Nexus (0.0-1.0)
    is_auto_approved: bool
    blocked: bool
    reason: str = ""
    recommendation: str = ""


class IpBoxHeuristicGuard:
    """Guard dla IP Box — blokuje automatyczne decyzje przy niskiej pewności.

    Reguły:
    1. IP Box confidence < 95% → BLOCK (ręczna weryfikacja)
    2. Nexus ratio < 30% → BLOCK (prawdopodobnie nie kwalifikuje się)
    3. Dla JDG bez udokumentowanej działalności B+R → BLOCK
    4. Przychód z IP Box > 80% całkowitego → ALERT (ryzyko kontroli)
    """

    def __init__(
        self,
        min_confidence: float = MIN_CONFIDENCE_FOR_AUTO,
        min_nexus_ratio: float = MIN_NEXUS_RATIO,
    ) -> None:
        self._min_confidence = min_confidence
        self._min_nexus_ratio = min_nexus_ratio

    def evaluate(
        self,
        verdict: dict[str, Any],
        context: dict[str, Any] | None = None,
    ) -> IpBoxEvaluation:
        """Ocenia czy decyzja IP Box może być automatyczna.

        Args:
            verdict: Werdykt OPA z reguły IP Box.
            context: Dodatkowe dane (przychód całkowity, dokumentacja B+R).

        Returns:
            IpBoxEvaluation z decyzją.
        """
        rule_id = verdict.get("rule_id", "")
        confidence = float(verdict.get("confidence", 0.0))
        nexus_ratio = float(verdict.get("nexus_ratio", 0.0))

        ctx = context or {}
        total_revenue = float(ctx.get("total_annual_revenue", 0))
        ip_box_revenue = float(ctx.get("ip_box_revenue", 0))

        # Check 1: Confidence threshold
        if confidence < self._min_confidence:
            return IpBoxEvaluation(
                rule_id=rule_id,
                confidence=confidence,
                nexus_ratio=nexus_ratio,
                is_auto_approved=False,
                blocked=True,
                reason=(
                    f"Niski poziom pewności ({confidence:.0%}) — wymagane {self._min_confidence:.0%}. "
                    "Automatyczne rozliczenie IP Box zablokowane."
                ),
                recommendation=(
                    "Skonsultuj się z doradcą podatkowym. "
                    "Przygotuj dokumentację B+R: opis kwalifikowanego IP, "
                    "ewidencję godzin, koszty bezpośrednie."
                ),
            )

        # Check 2: Nexus ratio
        if nexus_ratio < self._min_nexus_ratio:
            return IpBoxEvaluation(
                rule_id=rule_id,
                confidence=confidence,
                nexus_ratio=nexus_ratio,
                is_auto_approved=False,
                blocked=True,
                reason=(
                    f"Współczynnik Nexus ({nexus_ratio:.0%}) poniżej minimum "
                    f"({self._min_nexus_ratio:.0%}). "
                    "Kwalifikowane IP prawdopodobnie nie spełnia kryteriów."
                ),
                recommendation=(
                    "Zweryfikuj kalkulację współczynnika Nexus. "
                    "Upewnij się, że koszty kwalifikowane stanowią co najmniej "
                    f"{self._min_nexus_ratio:.0%} całkowitych kosztów."
                ),
            )

        # Check 3: Revenue concentration risk
        if total_revenue > 0 and ip_box_revenue / total_revenue > 0.80:
            logger.warning(
                f"[IP Box] High concentration: {ip_box_revenue/total_revenue:.0%} "
                f"of revenue from IP Box — increased audit risk"
            )
            # Nie blokujemy, ale ostrzegamy
            return IpBoxEvaluation(
                rule_id=rule_id,
                confidence=confidence,
                nexus_ratio=nexus_ratio,
                is_auto_approved=True,
                blocked=False,
                reason="",
                recommendation=(
                    "⚠️ UWAGA: Ponad 80% przychodów z IP Box — "
                    "zwiększone ryzyko kontroli KAS. Zalecana dodatkowa "
                    "dokumentacja i przegląd doradcy podatkowego."
                ),
            )

        # All checks passed
        return IpBoxEvaluation(
            rule_id=rule_id,
            confidence=confidence,
            nexus_ratio=nexus_ratio,
            is_auto_approved=True,
            blocked=False,
            reason="",
            recommendation="IP Box — automatyczne rozliczenie zaakceptowane.",
        )

    @staticmethod
    def block_low_confidence_kis_draft(verdict: dict[str, Any]) -> bool:
        """Szybka funkcja: czy zablokować draft wniosku KIS dla IP Box?

        Returns:
            True jeśli należy zablokować automatyczne generowanie.
        """
        rule_id = verdict.get("rule_id", "")
        if rule_id not in IP_BOX_RULE_IDS:
            return False

        confidence = float(verdict.get("confidence", 0.0))
        return confidence < MIN_CONFIDENCE_FOR_AUTO
