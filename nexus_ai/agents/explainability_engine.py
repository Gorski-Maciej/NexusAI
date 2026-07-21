"""Decision Explainability Engine — Wyjaśnialność decyzji AI.

GENIALNY POMYSŁ #13 z Raportu v7.0:
Gdy użytkownik widzi decyzję, może kliknąć "DLACZEGO?":
- Agent pokazuje PEŁEN ślad decyzyjny
- Które modele głosowały, z jaką pewnością
- Które reguły OPA zostały zastosowane
- Jakie przykłady few-shot wpłynęły na decyzję
- Link do odpowiednich przepisów (Dz.U.)
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.agents.explainability")


class DecisionExplanation:
    """Pełne wyjaśnienie decyzji AI."""

    def __init__(
        self,
        decision_id: str,
        status: str,
        trust_score: float,
        reason: str,
    ) -> None:
        self.decision_id = decision_id
        self.status = status
        self.trust_score = trust_score
        self.reason = reason
        self.model_votes: list[dict[str, Any]] = []
        self.applied_rules: list[dict[str, Any]] = []
        self.few_shot_examples: list[dict[str, Any]] = []
        self.legal_references: list[dict[str, str]] = []
        self.pipeline_steps: list[dict[str, Any]] = []
        self.key_factors: list[str] = []

    def to_dict(self) -> dict[str, Any]:
        return {
            "decision_id": self.decision_id,
            "status": self.status,
            "trust_score": round(self.trust_score, 4),
            "reason": self.reason,
            "model_votes": self.model_votes,
            "applied_rules": self.applied_rules,
            "few_shot_examples": self.few_shot_examples,
            "legal_references": self.legal_references,
            "pipeline_steps": self.pipeline_steps,
            "key_factors": self.key_factors,
        }


# ── Mapa statusów na przepisy ────────────────────────────────────────
STATUS_LEGAL_REFERENCES: dict[str, list[dict[str, str]]] = {
    "AUTO_POST": [
        {"act": "VAT", "article": "Art. 106e", "description": "Elementy faktury VAT"},
        {"act": "OrdPU", "article": "Art. 81", "description": "Korekta deklaracji"},
    ],
    "REVIEW": [
        {"act": "VAT", "article": "Art. 86 ust. 1", "description": "Prawo do odliczenia VAT"},
        {"act": "PIT", "article": "Art. 22 ust. 1", "description": "Koszty uzyskania przychodu"},
    ],
    "BLOCK": [
        {"act": "VAT", "article": "Art. 88", "description": "Wyłączenia z odliczenia VAT"},
        {"act": "KKS", "article": "Art. 54-56", "description": "Przestępstwa skarbowe"},
    ],
    "ESCALATED": [
        {"act": "OrdPU", "article": "Art. 120", "description": "Postępowanie podatkowe"},
        {"act": "KKS", "article": "Art. 16", "description": "Czynny żal"},
    ],
}


class ExplainabilityEngine:
    """Silnik wyjaśnialności decyzji AI.

    GENIALNY POMYSŁ #13:
    Buduje zaufanie i umożliwia audyt — każda decyzja ma przycisk "DLACZEGO?".
    """

    def __init__(self) -> None:
        self._explanations: dict[str, DecisionExplanation] = {}
        self._explainability_stats: dict[str, int] = {
            "total_explanations": 0,
            "explainability_requests": 0,
        }

    # ── Core Logic ──────────────────────────────────────────────────

    def build_explanation(
        self,
        decision: Any,
        trace: Any = None,
        ensemble_votes: list[Any] | None = None,
        mesh_route: Any = None,
        handbook_examples: list[Any] | None = None,
        quality_result: Any = None,
        extraction_result: Any = None,
    ) -> DecisionExplanation:
        """Zbuduj pełne wyjaśnienie decyzji.

        GENIALNY POMYSŁ #13:
        Łączy dane z wszystkich warstw systemu w jedno kompletne wyjaśnienie.
        """
        decision_id = decision.decision_id if hasattr(decision, 'decision_id') else "unknown"
        status = decision.verdict.status if hasattr(decision, 'verdict') else "unknown"
        trust = decision.verdict.trust_score if hasattr(decision, 'verdict') else 0.0
        reason = decision.verdict.reason if hasattr(decision, 'verdict') else ""

        explanation = DecisionExplanation(decision_id, status, trust, reason)

        # ── Model Votes (MultiModelEnsemble) ──
        if ensemble_votes:
            for vote in ensemble_votes:
                explanation.model_votes.append({
                    "model": getattr(vote, 'model_name', 'unknown'),
                    "vote": getattr(vote, 'vote', 'unknown'),
                    "confidence": getattr(vote, 'confidence', 0.0),
                    "weight": getattr(vote, 'model_weight', 0.0),
                    "reasoning": getattr(vote, 'reasoning', '')[:200],
                })

        # ── Applied OPA Rules ──
        if mesh_route and hasattr(mesh_route, 'applied_rules'):
            for rule_id in mesh_route.applied_rules:
                explanation.applied_rules.append({
                    "rule_id": rule_id,
                    "source": "Cross-Agent Experience Replay",
                })

        # ── Few-Shot Examples ──
        if handbook_examples:
            for i, ex in enumerate(handbook_examples[:3]):
                explanation.few_shot_examples.append({
                    "index": i + 1,
                    "ai_decision": getattr(ex, 'ai_decision', ''),
                    "user_correction": getattr(ex, 'user_correction', ''),
                    "correction_reason": getattr(ex, 'correction_reason', ''),
                })

        # ── Legal References ──
        explanation.legal_references = STATUS_LEGAL_REFERENCES.get(
            status, [{"act": "Ogólne", "article": "—", "description": "Decyzja standardowa"}]
        )

        # ── Pipeline Steps ──
        if trace and hasattr(trace, 'spans'):
            for span in trace.spans:
                explanation.pipeline_steps.append({
                    "name": getattr(span, 'name', 'unknown'),
                    "duration_ms": getattr(span, 'duration_ms', 0.0),
                    "status": getattr(span, 'status', 'OK'),
                })

        # ── Key Factors ──
        factors = explanation.key_factors
        if trust >= 0.92:
            factors.append(f"Wysoki Trust Score ({trust:.0%}) — decyzja automatyczna")
        elif trust >= 0.75:
            factors.append(f"Średni Trust Score ({trust:.0%}) — wymagana weryfikacja")
        else:
            factors.append(f"Niski Trust Score ({trust:.0%}) — decyzja zablokowana")

        if quality_result:
            factors.append(
                f"QualityValidator: {quality_result.overall_verdict if hasattr(quality_result, 'overall_verdict') else 'OK'}"
            )

        if extraction_result:
            conf = getattr(extraction_result, 'confidence', 0.0)
            factors.append(f"Pewność ekstrakcji: {conf:.0%}")

        self._explanations[decision_id] = explanation
        self._explainability_stats["total_explanations"] += 1

        return explanation

    def get_explanation(self, decision_id: str) -> DecisionExplanation | None:
        """Pobierz wyjaśnienie dla decyzji."""
        self._explainability_stats["explainability_requests"] += 1
        return self._explanations.get(decision_id)

    def generate_natural_language(self, explanation: DecisionExplanation) -> str:
        """Generuj wyjaśnienie w języku naturalnym (PL)."""
        parts = [f"# Dlaczego ta decyzja?\n"]

        parts.append(f"**Status:** {explanation.status}")
        parts.append(f"**Trust Score:** {explanation.trust_score:.0%}")
        parts.append(f"**Powód:** {explanation.reason}\n")

        if explanation.model_votes:
            parts.append("## Modele AI, które głosowały:")
            for mv in explanation.model_votes:
                parts.append(
                    f"- **{mv['model']}**: głosował **{mv['vote']}** "
                    f"(pewność: {mv['confidence']:.0%}, waga: {mv['weight']:.2f})"
                )

        if explanation.key_factors:
            parts.append("\n## Kluczowe czynniki:")
            for kf in explanation.key_factors:
                parts.append(f"- {kf}")

        if explanation.few_shot_examples:
            parts.append("\n## Podobne korekty z przeszłości:")
            for ex in explanation.few_shot_examples:
                parts.append(
                    f"- AI zdecydowało: **{ex['ai_decision']}** → "
                    f"Użytkownik poprawił: **{ex['user_correction']}**"
                )

        if explanation.legal_references:
            parts.append("\n## Podstawa prawna:")
            for ref in explanation.legal_references:
                parts.append(
                    f"- {ref['act']} {ref['article']} — {ref['description']}"
                )

        return "\n".join(parts)

    # ── Stats ───────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        return dict(self._explainability_stats)
