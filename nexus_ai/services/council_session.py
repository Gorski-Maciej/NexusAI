"""
[DEPRECATED] Council Session — pelna sesja Rady Agentow z matryca glosowania 8 kombinacji.

UWAGA: Ten plik jest przestarzaly. Uzyj zamiast tego:
- QualityValidatorAgent (services/quality_validator_agent.py)

Zachowany dla kompatybilnosci wstecznej (DECISION_MATRIX jest importowany przez
quality_validator_agent.py).
"""

from __future__ import annotations

import warnings
warnings.warn(
    "services/council_session.py jest przestarzaly. "
    "Uzyj QualityValidatorAgent z quality_validator_agent.py.",
    DeprecationWarning,
    stacklevel=2,
)

from dataclasses import dataclass
from enum import Enum
from typing import Any

from nexus_ai.core.logger import get_logger
from nexus_ai.services.council_agents import DecisionVerdict

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Decision levels
# ---------------------------------------------------------------------------

class DecisionLevel(Enum):
    """Poziomy decyzyjne — im wyzszy, tym wiecej uwagi wymaga."""

    LEVEL_1_AUTO = "LEVEL_1_AUTO"       # Full consensus → auto
    LEVEL_2_REVIEW = "LEVEL_2_REVIEW"   # Minor disagreement → suggest
    LEVEL_3_ESCALATE = "LEVEL_3_ESCALATE"  # Major disagreement → ask user
    LEVEL_4_BLOCK = "LEVEL_4_BLOCK"     # Full reject or precision veto → block


@dataclass(slots=True)
class CouncilVerdict:
    """Wynik glosowania Rady z pelnym kontekstem."""

    pattern: str  # nazwa kombinacji (np. "FULL_APPROVE", "ALPHA_ONLY")
    level: DecisionLevel
    recommended_action: str  # AUTO_POST | SUGGEST | ASK_USER | BLOCK
    min_trust_for_auto: float  # minimalny trust score wymagany dla auto-approve
    consensus_summary: str
    deliberation: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "pattern": self.pattern,
            "level": self.level.value,
            "recommended_action": self.recommended_action,
            "min_trust_for_auto": self.min_trust_for_auto,
            "consensus_summary": self.consensus_summary,
            "deliberation": self.deliberation,
        }


# ---------------------------------------------------------------------------
# Decision Matrix — 8 kombinacji
# ---------------------------------------------------------------------------

# Indeksowane przez (alpha_decision, beta_decision, gamma_decision)
DECISION_MATRIX: dict[tuple[str, str, str], CouncilVerdict] = {
    # 1. Full consensus — all approve
    ("APPROVE", "APPROVE", "APPROVE"): CouncilVerdict(
        pattern="FULL_APPROVE",
        level=DecisionLevel.LEVEL_1_AUTO,
        recommended_action="AUTO_POST",
        min_trust_for_auto=0.85,
        consensus_summary="Pelny konsensus — wszyscy agenci zatwierdzaja fakture",
        deliberation="Alpha (kontekst), Beta (walidacja), Gamma (anomalie) — wszystkie APPROVE. "
                     "Pelna zgodnosc, niskie ryzyko.",
    ),
    # 2. Alpha + Gamma approve, Beta rejects (precision concern)
    ("APPROVE", "REJECT", "APPROVE"): CouncilVerdict(
        pattern="ALPHA_GAMMA_APPROVE",
        level=DecisionLevel.LEVEL_2_REVIEW,
        recommended_action="SUGGEST",
        min_trust_for_auto=0.92,
        consensus_summary="Alpha i Gamma zatwierdzaja, Beta ma zastrzezenia — sugeruj",
        deliberation="Alpha (kontekst) i Gamma (anomalie) approve. Beta (walidacja) reject. "
                     "Potencjalny problem z precyzja danych. Sugeruj recenzje.",
    ),
    # 3. Alpha + Beta approve, Gamma rejects (anomaly detected)
    ("APPROVE", "APPROVE", "REJECT"): CouncilVerdict(
        pattern="ALPHA_BETA_APPROVE",
        level=DecisionLevel.LEVEL_2_REVIEW,
        recommended_action="SUGGEST",
        min_trust_for_auto=0.90,
        consensus_summary="Alpha i Beta zatwierdzaja, Gamma wykrywa anomalie — sugeruj",
        deliberation="Alpha (kontekst) i Beta (walidacja) approve. Gamma (anomalie) reject. "
                     "Potencjalna anomalia kwotowa. Sugeruj recenzje.",
    ),
    # 4. Only Alpha approves (alpha alone)
    ("APPROVE", "REJECT", "REJECT"): CouncilVerdict(
        pattern="ALPHA_ONLY",
        level=DecisionLevel.LEVEL_3_ESCALATE,
        recommended_action="ASK_USER",
        min_trust_for_auto=0.0,  # never auto
        consensus_summary="Tylko Alpha zatwierdza — wymaga decyzji uzytkownika",
        deliberation="Tylko Alpha (kontekst) APPROVE. Beta (walidacja) i Gamma (anomalie) REJECT. "
                     "Znaczace rozbieznosci. Eskalacja do uzytkownika.",
    ),
    # 5. Beta + Gamma approve, Alpha rejects
    ("REJECT", "APPROVE", "APPROVE"): CouncilVerdict(
        pattern="BETA_GAMMA_APPROVE",
        level=DecisionLevel.LEVEL_3_ESCALATE,
        recommended_action="ASK_USER",
        min_trust_for_auto=0.0,
        consensus_summary="Beta i Gamma zatwierdzaja, Alpha odrzuca — wymaga decyzji uzytkownika",
        deliberation="Beta (walidacja) i Gamma (anomalie) APPROVE. Alpha (kontekst) REJECT. "
                     "Perspektywa kontekstowa jest negatywna. Eskalacja do uzytkownika.",
    ),
    # 6. Only Gamma approves
    ("REJECT", "REJECT", "APPROVE"): CouncilVerdict(
        pattern="GAMMA_ONLY",
        level=DecisionLevel.LEVEL_3_ESCALATE,
        recommended_action="ASK_USER",
        min_trust_for_auto=0.0,
        consensus_summary="Tylko Gamma zatwierdza — wymaga decyzji uzytkownika",
        deliberation="Tylko Gamma (anomalie) APPROVE. Alpha (kontekst) i Beta (walidacja) REJECT. "
                     "Znaczace rozbieznosci. Eskalacja do uzytkownika.",
    ),
    # 7. Only Beta approves (precision veto scenario)
    ("REJECT", "APPROVE", "REJECT"): CouncilVerdict(
        pattern="BETA_ONLY_PRECISION",
        level=DecisionLevel.LEVEL_4_BLOCK,
        recommended_action="BLOCK",
        min_trust_for_auto=0.0,
        consensus_summary="Tylko Beta zatwierdza — blokada (precision veto)",
        deliberation="Tylko Beta (walidacja) APPROVE. Alpha (kontekst) i Gamma (anomalie) REJECT. "
                     "Precision veto — walidacja precyzji nie jest wystarczajaca do approval. BLOKADA.",
    ),
    # 8. Full reject
    ("REJECT", "REJECT", "REJECT"): CouncilVerdict(
        pattern="FULL_REJECT",
        level=DecisionLevel.LEVEL_4_BLOCK,
        recommended_action="BLOCK",
        min_trust_for_auto=0.0,
        consensus_summary="Wszyscy agenci odrzucaja fakture — blokada",
        deliberation="Alpha (kontekst), Beta (walidacja), Gamma (anomalie) — wszystkie REJECT. "
                     "Pelna zgodnosc co do odrzucenia. BLOKADA.",
    ),
}


# ---------------------------------------------------------------------------
# Council Session
# ---------------------------------------------------------------------------

class CouncilSession:
    """Pelna sesja Rady Agentow z matryca glosowania 8 kombinacji.

    Kazda sesja przetwarza jedna fakture, agreguje glosy Alpha, Beta, Gamma
    i zwraca CouncilVerdict z rekomendowana akcja i poziomem decyzyjnym.
    """

    def __init__(
        self,
        invoice_data: dict[str, Any],
        alpha_verdict: DecisionVerdict,
        beta_verdict: DecisionVerdict,
        gamma_verdict: DecisionVerdict,
    ) -> None:
        self._invoice_data = invoice_data
        self._alpha = alpha_verdict
        self._beta = beta_verdict
        self._gamma = gamma_verdict

    def deliberate(self) -> CouncilVerdict:
        """Przeprowadz deliberacje Rady — znajdz kombinacje w macierzy 8x1."""
        key = (self._alpha.decision, self._beta.decision, self._gamma.decision)
        verdict = DECISION_MATRIX.get(key)
        if verdict is None:
            logger.warning(
                "[CouncilSession] unknown verdict pattern: %s — falling back to ASK_USER",
                key,
            )
            verdict = CouncilVerdict(
                pattern="UNKNOWN",
                level=DecisionLevel.LEVEL_3_ESCALATE,
                recommended_action="ASK_USER",
                min_trust_for_auto=0.0,
                consensus_summary=f"Nieznana kombinacja glowos: Alpha={self._alpha.decision}, "
                                  f"Beta={self._beta.decision}, Gamma={self._gamma.decision}",
                deliberation="Nieznany wzorzec glosowania. Bezpieczna eskalacja do uzytkownika.",
            )
        logger.info(
            "[CouncilSession] pattern=%s level=%s action=%s",
            verdict.pattern,
            verdict.level.value,
            verdict.recommended_action,
        )
        return verdict

    def get_consensus_type(self) -> str:
        """Zwroc typ konsensusu: full, majority, split, none."""
        key = (self._alpha.decision, self._beta.decision, self._gamma.decision)
        approves = sum(1 for d in key if d == "APPROVE")
        rejects = sum(1 for d in key if d == "REJECT")
        if approves == 3:
            return "full_approve"
        if rejects == 3:
            return "full_reject"
        if approves >= 2:
            return "majority_approve"
        if rejects >= 2:
            return "majority_reject"
        return "split"

    @staticmethod
    def get_all_patterns() -> list[dict[str, Any]]:
        """Zwroc liste wszystkich 8 kombinacji (do debugowania / dokumentacji)."""
        return [
            {
                "key": f"({a}, {b}, {c})",
                "pattern": v.pattern,
                "level": v.level.value,
                "action": v.recommended_action,
                "min_trust": v.min_trust_for_auto,
            }
            for (a, b, c), v in DECISION_MATRIX.items()
        ]
