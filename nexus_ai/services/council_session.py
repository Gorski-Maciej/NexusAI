"""
[DEPRECATED] Council Session — zachowany dla kompatybilnosci wstecznej.

Zgodnie z aa3fvcx.txt: decyzje oparte na DuckDB/SQL, bez agentow AI.
DECISION_MATRIX pozostaje jako dokumentacja, ale nie jest uzywany.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Any

from nexus_ai.core.logger import get_logger

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Decision levels
# ---------------------------------------------------------------------------

class DecisionLevel(Enum):
    """Poziomy decyzyjne — im wyzszy, tym wiecej uwagi wymaga."""

    LEVEL_1_AUTO = "LEVEL_1_AUTO"
    LEVEL_2_REVIEW = "LEVEL_2_REVIEW"
    LEVEL_3_ESCALATE = "LEVEL_3_ESCALATE"
    LEVEL_4_BLOCK = "LEVEL_4_BLOCK"


@dataclass(slots=True)
class CouncilVerdict:
    """Wynik glosowania Rady."""

    pattern: str
    level: DecisionLevel
    recommended_action: str
    min_trust_for_auto: float
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
    """
    [DEPRECATED] Zachowany dla kompatybilnosci wstecznej.
    Zgodnie z aa3fvcx.txt: decyzje oparte na DecisionEngine (DuckDB/SQL).
    """

    def __init__(self) -> None:
        pass

    @staticmethod
    def get_all_patterns() -> list[dict[str, Any]]:
        """Zwroc liste wszystkich 8 kombinacji (do dokumentacji)."""
        return [
            {
                "key": f"({a}, {b}, {c})",
                "pattern": v.pattern,
                "level": v.level.value,
                "action": v.recommended_action,
            }
            for (a, b, c), v in DECISION_MATRIX.items()
        ]
