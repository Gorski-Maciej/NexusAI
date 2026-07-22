"""
RiskGuard v7.0 — Dynamiczny Strażnik Ryzyka z adaptacją progów i kalibracją.

Raport v7.0, sekcja 5.2:
  - "Brak dynamicznej adaptacji progów" → AdaptiveRiskGuard
  - "Brak kalibracji per kontrahent" → vendor_trust scoring
  - "Tylko 3 poziomy akcji — mało granularne" → 5 poziomów

Enterprise v7.0:
  - Adaptive thresholds: progi dostosowują się do historycznej skuteczności
  - Vendor calibration: kalibracja per kontrahent (trust score 0-100)
  - 5 poziomów akcji: ALLOW, MONITOR, TRIAGE_QUEUE, BLOCK_AND_ALERT, FREEZE
  - Feedback loop: uczy się na podstawie wyników decyzji
"""

from __future__ import annotations

from enum import StrEnum
from typing import Any

from structlog import get_logger

from nexus_ai.services._billing_store import get_rules_connection, query_risk_threshold

logger = get_logger("nexus.services.risk_guard")


class RiskAction(StrEnum):
    """Akcja podejmowana gdy pewność AI jest poniżej progu (v7.0 rozszerzone)."""

    ALLOW = "ALLOW"
    MONITOR = "MONITOR"           # v7.0 NOWOŚĆ: pozwól, ale monitoruj
    TRIAGE_QUEUE = "TRIAGE_QUEUE"
    BLOCK_AND_ALERT = "BLOCK_AND_ALERT"
    FREEZE = "FREEZE"             # v7.0 NOWOŚĆ: zamroź transakcję do ręcznej weryfikacji


@final
class RiskThreshold:
    """Prog ryzyka z adaptacją (v7.0 rozszerzony)."""
    __slots__ = (
        'action_if_below', 'required_ml_confidence', 'rule_id',
        'vendor_trust_modifier', 'historical_accuracy',
    )

    def __init__(
        self,
        required_ml_confidence: float = 0.85,
        action_if_below: str = "TRIAGE_QUEUE",
        rule_id: str = "default",
        vendor_trust_modifier: float = 0.0,
        historical_accuracy: float = 0.85,
    ) -> None:
        self.required_ml_confidence = required_ml_confidence
        self.action_if_below = action_if_below
        self.rule_id = rule_id
        self.vendor_trust_modifier = vendor_trust_modifier
        self.historical_accuracy = historical_accuracy


@final
class RiskGuard:
    """Dynamiczny straznik ryzyka z adaptacją (v7.0 Audit).

    Nowe funkcje (v7.0):
    - Adaptive thresholds: progi dostosowują się do skuteczności
    - Vendor calibration: per-kontrahent trust score
    - 5 poziomów akcji zamiast 3
    - Feedback loop: learn_from_outcome()
    """

    __slots__ = ('_accuracy_history', '_vendor_trust_cache')

    # ── Vendor Trust Scoring (v7.0 NOWOŚĆ) ──────────────────────────

    VENDOR_TRUST_LEVELS: dict[str, float] = {
        "high": -0.05,     # Zmniejsza wymagany próg o 5%
        "medium": 0.00,    # Bez zmian
        "low": 0.05,       # Zwiększa wymagany próg o 5%
        "unknown": 0.10,   # Zwiększa wymagany próg o 10% (najostrożniej)
    }

    # ── 5-poziomowa eskalacja (v7.0 NOWOŚĆ) ─────────────────────────

    ACTION_THRESHOLDS: list[tuple[float, str]] = [
        (0.92, RiskAction.ALLOW),
        (0.82, RiskAction.MONITOR),
        (0.70, RiskAction.TRIAGE_QUEUE),
        (0.55, RiskAction.BLOCK_AND_ALERT),
        (0.00, RiskAction.FREEZE),
    ]

    def __init__(self) -> None:
        self._accuracy_history: dict[str, list[bool]] = {}  # rule_id → [True/False]
        self._vendor_trust_cache: dict[str, float] = {}  # vendor_id → trust_score

    def get_threshold(
        self,
        tax_form: str,
        expense_type: str = "inne",
        vendor_trust: str = "medium",
    ) -> RiskThreshold:
        """Get risk threshold with vendor calibration (v7.0)."""
        conn = get_rules_connection()
        try:
            rule = query_risk_threshold(conn, tax_form, expense_type)
        finally:
            conn.close()

        # Vendor trust modifier
        vendor_modifier = self.VENDOR_TRUST_LEVELS.get(vendor_trust, 0.10)

        # Adaptive threshold (v7.0 NOWOŚĆ)
        base_confidence = 0.85
        if rule:
            output = rule["output"]
            base_confidence = float(output.get("required_ml_confidence", 0.85))
            rule_id = str(rule["rule_id"])
        else:
            rule_id = "fallback"

        # Dostosowanie na podstawie historycznej skuteczności
        accuracy = self._get_rule_accuracy(rule_id)
        adapted_confidence = self._adapt_threshold(base_confidence, accuracy)

        # Finalny próg = base + vendor modifier + adaptation
        final_confidence = adapted_confidence + vendor_modifier
        final_confidence = max(0.50, min(0.98, final_confidence))  # Clamp

        return RiskThreshold(
            required_ml_confidence=final_confidence,
            action_if_below=output.get("action_if_below", "TRIAGE_QUEUE") if rule else "TRIAGE_QUEUE",
            rule_id=rule_id,
            vendor_trust_modifier=vendor_modifier,
            historical_accuracy=accuracy,
        )

    def evaluate(
        self,
        tax_form: str,
        expense_type: str,
        ai_confidence: float,
        vendor_trust: str = "medium",
    ) -> dict[str, Any]:
        """Evaluate risk with 5-level action escalation (v7.0)."""
        threshold = self.get_threshold(tax_form, expense_type, vendor_trust)

        # 5-poziomowa eskalacja zamiast binarnej decyzji
        action = RiskAction.FREEZE  # Domyślnie najbezpieczniej
        for min_conf, act in self.ACTION_THRESHOLDS:
            if ai_confidence >= min_conf:
                action = RiskAction(act)
                break

        # Jeśli AI confidence poniżej adaptacyjnego progu — eskalacja
        if ai_confidence < threshold.required_ml_confidence:
            # Eskaluj o jeden poziom wyżej
            current_idx = next(
                i for i, (_, a) in enumerate(self.ACTION_THRESHOLDS)
                if a == action
            )
            escalated_idx = max(0, current_idx - 1)  # Wyższy indeks = niższy poziom eskalacji
            if escalated_idx < current_idx:
                action = RiskAction(self.ACTION_THRESHOLDS[escalated_idx][1])

        return {
            "action": action,
            "required_confidence": threshold.required_ml_confidence,
            "ai_confidence": ai_confidence,
            "rule_id": threshold.rule_id,
            "vendor_trust": vendor_trust,
            "vendor_modifier": threshold.vendor_trust_modifier,
            "historical_accuracy": threshold.historical_accuracy,
            "reason": self._build_reason(ai_confidence, threshold, action),
        }

    # ── Adaptive Learning (v7.0 NOWOŚĆ) ────────────────────────────

    def learn_from_outcome(self, rule_id: str, was_correct: bool) -> None:
        """Ucz się na podstawie wyniku decyzji (feedback loop).

        Args:
            rule_id: ID reguły, która podjęła decyzję.
            was_correct: Czy decyzja była poprawna (np. audytor potwierdził).
        """
        if rule_id not in self._accuracy_history:
            self._accuracy_history[rule_id] = []
        self._accuracy_history[rule_id].append(was_correct)
        # Trzymaj tylko ostatnie 100 wyników
        if len(self._accuracy_history[rule_id]) > 100:
            self._accuracy_history[rule_id] = self._accuracy_history[rule_id][-100:]

        accuracy = self._get_rule_accuracy(rule_id)
        logger.debug(
            "[RISK-GUARD] Learned: rule=%s correct=%s accuracy=%.2f",
            rule_id, was_correct, accuracy,
        )

    def _get_rule_accuracy(self, rule_id: str) -> float:
        """Oblicz historyczną skuteczność reguły."""
        history = self._accuracy_history.get(rule_id, [])
        if not history:
            return 0.85  # Domyślna
        return sum(1 for h in history if h) / len(history)

    def _adapt_threshold(self, base_confidence: float, accuracy: float) -> float:
        """Adaptuj próg na podstawie historycznej skuteczności.

        Jeśli reguła jest bardzo skuteczna (>95%), możemy obniżyć próg.
        Jeśli reguła jest mało skuteczna (<80%), podnosimy próg.
        """
        if accuracy >= 0.95:
            return base_confidence - 0.03  # Bardzo skuteczna → poluzuj
        elif accuracy >= 0.85:
            return base_confidence  # Średnia → bez zmian
        elif accuracy >= 0.75:
            return base_confidence + 0.03  # Słaba → zaostrz
        else:
            return base_confidence + 0.07  # Bardzo słaba → znacznie zaostrz

    # ── Vendor Trust Calibration (v7.0 NOWOŚĆ) ─────────────────────

    def set_vendor_trust(self, vendor_id: str, trust_score: float) -> None:
        """Ustaw poziom zaufania dla kontrahenta (0-100)."""
        self._vendor_trust_cache[vendor_id] = max(0.0, min(100.0, trust_score))
        logger.info("[RISK-GUARD] Vendor trust set: %s → %.0f", vendor_id, trust_score)

    def get_vendor_trust_level(self, vendor_id: str) -> str:
        """Pobierz poziom zaufania kontrahenta jako string."""
        score = self._vendor_trust_cache.get(vendor_id, 50.0)
        if score >= 80:
            return "high"
        elif score >= 40:
            return "medium"
        elif score >= 10:
            return "low"
        else:
            return "unknown"

    @staticmethod
    def _build_reason(
        ai_confidence: float,
        threshold: RiskThreshold,
        action: RiskAction,
    ) -> str:
        """Zbuduj czytelne wyjaśnienie decyzji."""
        parts = [
            f"AI confidence {ai_confidence:.2f} vs adapted threshold {threshold.required_ml_confidence:.2f}",
            f"vendor_modifier={threshold.vendor_trust_modifier:+.2f}",
            f"historical_accuracy={threshold.historical_accuracy:.2f}",
            f"action={action.value}",
        ]
        return "; ".join(parts)
