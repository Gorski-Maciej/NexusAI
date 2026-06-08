"""
Agent Walidator Jakości — Trójwarstwowa Tarcza Bezpieczeństwa

Zgodnie z aa3fvcx.txt:
- Pozycja w systemie: Wykonawczy. Agent odpowiedzialny za trójwarstwową
  walidację jakości danych faktury.
- Trzy warstwy:
  1. Warstwa kontekstowa (dawny Alpha Agent) — szybka ocena kontekstu
  2. Warstwa precyzji (dawny Beta Agent) — walidacja matematyczno-fiskalna
  3. Warstwa anomalii (dawny Gamma Agent) — detekcja duplikatów i anomalii
- Matryca decyzyjna 8 kombinacji (z CouncilSession)

Integruje funkcjonalność z:
- AlphaAgent (szybka decyzja pierwszego przejścia)
- BetaAgent (walidacja matematyczno-fiskalna)
- GammaAgent (detekcja anomalii)
- CouncilSession (agregacja 8 kombinacji głosów)
"""

from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass
from enum import Enum
from typing import Any

from nexus_ai.core.config import AppConfig
from nexus_ai.core.logger import get_logger
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads
from nexus_ai.services.council_agents import (
    AlphaAgent,
    BetaAgent,
    DecisionVerdict,
    GammaAgent,
    ModelManager,
)
logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Decision levels (z CouncilSession)
# ---------------------------------------------------------------------------

class ValidationLevel(Enum):
    """Poziomy walidacji — im wyższy, tym więcej uwagi wymaga."""

    LEVEL_1_AUTO = "LEVEL_1_AUTO"       # Full consensus → auto
    LEVEL_2_REVIEW = "LEVEL_2_REVIEW"   # Minor disagreement → suggest
    LEVEL_3_ESCALATE = "LEVEL_3_ESCALATE"  # Major disagreement → ask user
    LEVEL_4_BLOCK = "LEVEL_4_BLOCK"     # Full reject or precision veto → block


@dataclass(slots=True)
class ValidationVerdict:
    """Wynik walidacji z pełnym kontekstem."""

    pattern: str  # nazwa kombinacji (FULL_APPROVE, ALPHA_ONLY, itd.)
    level: ValidationLevel
    recommended_action: str  # AUTO_POST | SUGGEST | ASK_USER | BLOCK
    min_trust_for_auto: float
    consensus_summary: str
    deliberation: str
    layer1_decision: str  # warstwa kontekstowa
    layer1_confidence: float
    layer2_decision: str  # warstwa precyzji
    layer2_confidence: float
    layer3_decision: str  # warstwa anomalii
    layer3_confidence: float
    trust_score: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        return {
            "pattern": self.pattern,
            "level": self.level.value,
            "recommended_action": self.recommended_action,
            "min_trust_for_auto": self.min_trust_for_auto,
            "consensus_summary": self.consensus_summary,
            "deliberation": self.deliberation,
            "layer1_decision": self.layer1_decision,
            "layer1_confidence": self.layer1_confidence,
            "layer2_decision": self.layer2_decision,
            "layer2_confidence": self.layer2_confidence,
            "layer3_decision": self.layer3_decision,
            "layer3_confidence": self.layer3_confidence,
            "trust_score": self.trust_score,
        }


# ---------------------------------------------------------------------------
# Decision Matrix — 8 kombinacji (z CouncilSession)
# ---------------------------------------------------------------------------

DecisionMatrix = dict[tuple[str, str, str], tuple[str, ValidationLevel, str, float, str, str]]

DECISION_MATRIX: DecisionMatrix = {
    ("APPROVE", "APPROVE", "APPROVE"): (
        "FULL_APPROVE", ValidationLevel.LEVEL_1_AUTO, "AUTO_POST", 0.85,
        "Pełny konsensus — wszystkie warstwy zatwierdzają",
        "Warstwa kontekstowa, precyzji i anomalii — wszystkie APPROVE. Pełna zgodność.",
    ),
    ("APPROVE", "REJECT", "APPROVE"): (
        "CONTEXT_ANOMALY_APPROVE", ValidationLevel.LEVEL_2_REVIEW, "SUGGEST", 0.92,
        "Warstwy kontekstowa i anomalii zatwierdzają, precyzja ma zastrzeżenia",
        "Warstwa kontekstowa i anomalii approve. Warstwa precyzji reject. Sugeruj recenzję.",
    ),
    ("APPROVE", "APPROVE", "REJECT"): (
        "CONTEXT_PRECISION_APPROVE", ValidationLevel.LEVEL_2_REVIEW, "SUGGEST", 0.90,
        "Warstwy kontekstowa i precyzji zatwierdzają, anomalia wykryta",
        "Warstwa kontekstowa i precyzji approve. Warstwa anomalii reject. Sugeruj recenzję.",
    ),
    ("APPROVE", "REJECT", "REJECT"): (
        "CONTEXT_ONLY", ValidationLevel.LEVEL_3_ESCALATE, "ASK_USER", 0.0,
        "Tylko warstwa kontekstowa zatwierdza — wymaga decyzji użytkownika",
        "Tylko warstwa kontekstowa APPROVE. Precyzja i anomalie REJECT. Eskalacja.",
    ),
    ("REJECT", "APPROVE", "APPROVE"): (
        "PRECISION_ANOMALY_APPROVE", ValidationLevel.LEVEL_3_ESCALATE, "ASK_USER", 0.0,
        "Warstwy precyzji i anomalii zatwierdzają, kontekst odrzuca",
        "Warstwy precyzji i anomalii APPROVE. Kontekst REJECT. Eskalacja.",
    ),
    ("REJECT", "REJECT", "APPROVE"): (
        "ANOMALY_ONLY", ValidationLevel.LEVEL_3_ESCALATE, "ASK_USER", 0.0,
        "Tylko warstwa anomalii zatwierdza — wymaga decyzji użytkownika",
        "Tylko warstwa anomalii APPROVE. Kontekst i precyzja REJECT. Eskalacja.",
    ),
    ("REJECT", "APPROVE", "REJECT"): (
        "PRECISION_VETO", ValidationLevel.LEVEL_4_BLOCK, "BLOCK", 0.0,
        "Tylko warstwa precyzji zatwierdza — blokada (precision veto)",
        "Tylko warstwa precyzji APPROVE. Kontekst i anomalie REJECT. Precision veto. BLOKADA.",
    ),
    ("REJECT", "REJECT", "REJECT"): (
        "FULL_REJECT", ValidationLevel.LEVEL_4_BLOCK, "BLOCK", 0.0,
        "Wszystkie warstwy odrzucają — blokada",
        "Wszystkie warstwy REJECT. BLOKADA.",
    ),
}


# ---------------------------------------------------------------------------
# Agent Walidator Jakości
# ---------------------------------------------------------------------------

class QualityValidatorAgent:
    """Agent Walidator Jakości — trójwarstwowa tarcza bezpieczeństwa.

    Zgodnie z aa3fvcx.txt:
    - Trzy warstwy: kontekstowa (Alpha), precyzji (Beta), anomalii (Gamma)
    - Matryca decyzyjna 8 kombinacji
    - Rekomenduje: AUTO_POST / SUGGEST / ASK_USER / BLOCK

    Używa tych samych modeli GGUF co poprzednia Rada Agentów,
    poprzez współdzielony ModelManager.
    """

    def __init__(
        self,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
        config: AppConfig | None = None,
    ) -> None:
        self._alpha = alpha_agent    # warstwa kontekstowa
        self._beta = beta_agent      # warstwa precyzji
        self._gamma = gamma_agent    # warstwa anomalii
        self._config = config or AppConfig()
        self._timeout = self._config.autopilot_agent_timeout_seconds

    async def validate(
        self,
        invoice_id: str,
        invoice_data: dict[str, Any],
        use_fast_path: bool = True,
    ) -> ValidationVerdict:
        """Przeprowadź trójwarstwową walidację faktury.

        Args:
            invoice_id: ID faktury.
            invoice_data: Dane faktury do walidacji.
            use_fast_path: Jeśli True, używa fast-path (tylko Alpha jeśli wysoki confidence).

        Returns:
            ValidationVerdict z wynikiem walidacji.
        """
        logger.info("[QualityValidator] validating invoice_id=%s", invoice_id)

        # --- Warstwa 1: Kontekstowa (Alpha) ---
        layer1 = await self._run_with_timeout(self._alpha.evaluate(invoice_data))
        logger.debug("[QualityValidator] layer1 (context) decision=%s confidence=%.4f",
                     layer1.decision, layer1.confidence)

        # Fast-path: jeśli Alpha APPROVE z wysokim confidence
        if use_fast_path and layer1.decision == "APPROVE" and layer1.confidence >= 0.92:
            empty = DecisionVerdict(decision="APPROVE", confidence=0.0,
                                     reasoning="Skipped (fast-path)")
            verdict = self._resolve_verdict(layer1, empty, empty)
            logger.info("[QualityValidator] fast-path APPROVE for invoice_id=%s", invoice_id)
            return verdict

        # --- Warstwa 2: Precyzji (Beta) + Warstwa 3: Anomalii (Gamma) równolegle ---
        layer2_task = self._run_with_timeout(self._beta.evaluate(invoice_data))
        layer3_task = self._run_with_timeout(self._gamma.evaluate(invoice_data))
        layer2, layer3 = await asyncio.gather(layer2_task, layer3_task)

        logger.debug("[QualityValidator] layer2 (precision) decision=%s layer3 (anomaly) decision=%s",
                     layer2.decision, layer3.decision)

        # --- Matryca decyzyjna ---
        return self._resolve_verdict(layer1, layer2, layer3)

    def _resolve_verdict(
        self,
        layer1: DecisionVerdict,
        layer2: DecisionVerdict,
        layer3: DecisionVerdict,
    ) -> ValidationVerdict:
        """Znajdź kombinację w macierzy 8x1 i zwróć werdykt."""
        key = (layer1.decision, layer2.decision, layer3.decision)

        pattern_info = DECISION_MATRIX.get(key)
        if pattern_info is None:
            logger.warning("[QualityValidator] unknown pattern: %s — falling back to ASK_USER", key)
            return ValidationVerdict(
                pattern="UNKNOWN",
                level=ValidationLevel.LEVEL_3_ESCALATE,
                recommended_action="ASK_USER",
                min_trust_for_auto=0.0,
                consensus_summary=f"Nieznana kombinacja: {key}",
                deliberation="Nieznany wzorzec głosowania. Bezpieczna eskalacja.",
                layer1_decision=layer1.decision,
                layer1_confidence=layer1.confidence,
                layer2_decision=layer2.decision,
                layer2_confidence=layer2.confidence,
                layer3_decision=layer3.decision,
                layer3_confidence=layer3.confidence,
            )

        pattern, level, action, min_trust, summary, deliberation = pattern_info

        logger.info(
            "[QualityValidator] pattern=%s level=%s action=%s",
            pattern, level.value, action,
        )

        return ValidationVerdict(
            pattern=pattern,
            level=level,
            recommended_action=action,
            min_trust_for_auto=min_trust,
            consensus_summary=summary,
            deliberation=deliberation,
            layer1_decision=layer1.decision,
            layer1_confidence=layer1.confidence,
            layer2_decision=layer2.decision,
            layer2_confidence=layer2.confidence,
            layer3_decision=layer3.decision,
            layer3_confidence=layer3.confidence,
        )

    async def _run_with_timeout(self, coro) -> DecisionVerdict:
        try:
            return await asyncio.wait_for(coro, timeout=self._timeout)
        except TimeoutError:
            logger.warning("[QualityValidator] layer timed out after %ds", self._timeout)
            return DecisionVerdict.error(f"Timeout after {self._timeout}s")
