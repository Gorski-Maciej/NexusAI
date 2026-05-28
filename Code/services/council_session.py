"""
Council Session — pełna sesja Rady Agentów z matrycą głosowania 8 kombinacji.

Matryca decyzyjna (8 kombinacji):
  1. APP + APP + APP → AUTO_POST (full consensus, trust ≥ 0.85)
  2. APP + REJ + APP → SUGGEST  (Alpha + Gamma approve, Beta ma wątpliwości)
  3. APP + APP + REJ → SUGGEST  (Alpha + Beta approve, Gamma anomaly)
  4. APP + REJ + REJ → ASK_USER (tylko Alpha approve)
  5. REJ + APP + APP → ASK_USER (tylko Beta + Gamma approve)
  6. REJ + REJ + APP → ASK_USER (tylko Gamma approve)
  7. REJ + APP + REJ → BLOCK    (tylko Beta approve — precision veto)
  8. REJ + REJ + REJ → BLOCK    (full reject)

Każda kombinacja ma przypisany:
  - Poziom decyzyjny (Level 1-4)
  - Rekomendowaną akcję
  - Minimalny trust score dla auto-approve
  - Strategię eskalacji
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any

from core.logger import get_logger
from services.council_agents import DecisionVerdict

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Decision levels
# ---------------------------------------------------------------------------

class DecisionLevel(Enum):
    """Poziomy decyzyjne — im wyższy, tym więcej uwagi wymaga."""

    LEVEL_1_AUTO = "LEVEL_1_AUTO"       # Full consensus → auto
    LEVEL_2_REVIEW = "LEVEL_2_REVIEW"   # Minor disagreement → suggest
    LEVEL_3_ESCALATE = "LEVEL_3_ESCALATE"  # Major disagreement → ask user
    LEVEL_4_BLOCK = "LEVEL_4_BLOCK"     # Full reject or precision veto → block


@dataclass(slots=True)
class CouncilVerdict:
    """Wynik głosowania Rady z pełnym kontekstem."""

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
        consensus_summary="Pełny konsensus — wszyscy agenci zatwierdzają fakturę",
        deliberation="Alpha (kontekst), Beta (walidacja), Gamma (anomalie) — wszystkie APPROVE. "
                     "Pełna zgodność, niskie ryzyko.",
    ),
    # 2. Alpha + Gamma approve, Beta rejects (precision concern)
    ("APPROVE", "REJECT", "APPROVE"): CouncilVerdict(
        pattern="ALPHA_GAMMA_APPROVE",
        level=DecisionLevel.LEVEL_2_REVIEW,
        recommended_action="SUGGEST",
        min_trust_for_auto=0.92,
        consensus_summary="Alpha i Gamma zatwierdzają, Beta ma zastrzeżenia — sugeruj",
        deliberation="Alpha (kontekst) i Gamma (anomalie) approve. Beta (walidacja) reject. "
                     "Potencjalny problem z precyzją danych. Sugeruj recenzję.",
    ),
    # 3. Alpha + Beta approve, Gamma rejects (anomaly detected)
    ("APPROVE", "APPROVE", "REJECT"): CouncilVerdict(
        pattern="ALPHA_BETA_APPROVE",
        level=DecisionLevel.LEVEL_2_REVIEW,
        recommended_action="SUGGEST",
        min_trust_for_auto=0.90,
        consensus_summary="Alpha i Beta zatwierdzają, Gamma wykrywa anomalię — sugeruj",
        deliberation="Alpha (kontekst) i Beta (walidacja) approve. Gamma (anomalie) reject. "
                     "Potencjalna anomalia kwotowa. Sugeruj recenzję.",
    ),
    # 4. Only Alpha approves (alpha alone)
    ("APPROVE", "REJECT", "REJECT"): CouncilVerdict(
        pattern="ALPHA_ONLY",
        level=DecisionLevel.LEVEL_3_ESCALATE,
        recommended_action="ASK_USER",
        min_trust_for_auto=0.0,  # never auto
        consensus_summary="Tylko Alpha zatwierdza — wymaga decyzji użytkownika",
        deliberation="Tylko Alpha (kontekst) APPROVE. Beta (walidacja) i Gamma (anomalie) REJECT. "
                     "Znaczące rozbieżności. Eskalacja do użytkownika.",
    ),
    # 5. Beta + Gamma approve, Alpha rejects
    ("REJECT", "APPROVE", "APPROVE"): CouncilVerdict(
        pattern="BETA_GAMMA_APPROVE",
        level=DecisionLevel.LEVEL_3_ESCALATE,
        recommended_action="ASK_USER",
        min_trust_for_auto=0.0,
        consensus_summary="Beta i Gamma zatwierdzają, Alpha odrzuca — wymaga decyzji użytkownika",
        deliberation="Beta (walidacja) i Gamma (anomalie) APPROVE. Alpha (kontekst) REJECT. "
                     "Perspektywa kontekstowa jest negatywna. Eskalacja do użytkownika.",
    ),
    # 6. Only Gamma approves
    ("REJECT", "REJECT", "APPROVE"): CouncilVerdict(
        pattern="GAMMA_ONLY",
        level=DecisionLevel.LEVEL_3_ESCALATE,
        recommended_action="ASK_USER",
        min_trust_for_auto=0.0,
        consensus_summary="Tylko Gamma zatwierdza — wymaga decyzji użytkownika",
        deliberation="Tylko Gamma (anomalie) APPROVE. Alpha (kontekst) i Beta (walidacja) REJECT. "
                     "Znaczące rozbieżności. Eskalacja do użytkownika.",
    ),
    # 7. Only Beta approves (precision veto scenario)
    ("REJECT", "APPROVE", "REJECT"): CouncilVerdict(
        pattern="BETA_ONLY_PRECISION",
        level=DecisionLevel.LEVEL_4_BLOCK,
        recommended_action="BLOCK",
        min_trust_for_auto=0.0,
        consensus_summary="Tylko Beta zatwierdza — blokada (precision veto)",
        deliberation="Tylko Beta (walidacja) APPROVE. Alpha (kontekst) i Gamma (anomalie) REJECT. "
                     "Precision veto — walidacja precyzji nie jest wystarczająca do approval. BLOKADA.",
    ),
    # 8. Full reject
    ("REJECT", "REJECT", "REJECT"): CouncilVerdict(
        pattern="FULL_REJECT",
        level=DecisionLevel.LEVEL_4_BLOCK,
        recommended_action="BLOCK",
        min_trust_for_auto=0.0,
        consensus_summary="Wszyscy agenci odrzucają fakturę — blokada",
        deliberation="Alpha (kontekst), Beta (walidacja), Gamma (anomalie) — wszystkie REJECT. "
                     "Pełna zgodność co do odrzucenia. BLOKADA.",
    ),
}


# ---------------------------------------------------------------------------
# Council Session
# ---------------------------------------------------------------------------

class CouncilSession:
    """Pełna sesja Rady Agentów z matrycą głosowania 8 kombinacji.

    Każda sesja przetwarza jedną fakturę, agreguje głosy Alpha, Beta, Gamma
    i zwraca CouncilVerdict z rekomendowaną akcją i poziomem decyzyjnym.
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
        """Przeprowadź deliberację Rady — znajdź kombinację w macierzy 8x1.

        Zwraca CouncilVerdict z:
          - pattern (nazwa kombinacji)
          - level (LEVEL_1_AUTO ... LEVEL_4_BLOCK)
          - recommended_action (AUTO_POST | SUGGEST | ASK_USER | BLOCK)
          - min_trust_for_auto (minimalny trust score dla auto-approve)
          - consensus_summary (podsumowanie)
          - deliberation (szczegółowe uzasadnienie)
        """
        key = (self._alpha.decision, self._beta.decision, self._gamma.decision)

        verdict = DECISION_MATRIX.get(key)
        if verdict is None:
            # Fallback dla nieznanych kombinacji (np. z ERROR)
            logger.warning(
                "[CouncilSession] unknown verdict pattern: %s — falling back to ASK_USER",
                key,
            )
            verdict = CouncilVerdict(
                pattern="UNKNOWN",
                level=DecisionLevel.LEVEL_3_ESCALATE,
                recommended_action="ASK_USER",
                min_trust_for_auto=0.0,
                consensus_summary=f"Nieznana kombinacja głosów: Alpha={self._alpha.decision}, "
                                  f"Beta={self._beta.decision}, Gamma={self._gamma.decision}",
                deliberation="Nieznany wzorzec głosowania. Bezpieczna eskalacja do użytkownika.",
            )

        logger.info(
            "[CouncilSession] pattern=%s level=%s action=%s",
            verdict.pattern,
            verdict.level.value,
            verdict.recommended_action,
        )
        return verdict

    def get_consensus_type(self) -> str:
        """Zwróć typ konsensusu: full, majority, split, none."""
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
        """Zwróć listę wszystkich 8 kombinacji (do debugowania / dokumentacji)."""
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
