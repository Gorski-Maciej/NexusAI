"""Dynamiczny Strażnik Ryzyka (RiskGuard) -- wspoldzielony SQLite store.

- First-match-wins przez reguły w SQLite
- Współdzielony store (NIE DuckDB :memory: per request)
- Fallback: domyślny próg 0.85
"""

from __future__ import annotations

from enum import StrEnum
from typing import Any

from structlog import get_logger

from nexus_ai.services._billing_store import get_rules_connection, query_risk_threshold

logger = get_logger("nexus.services.risk_guard")


class RiskAction(StrEnum):
    """Akcja podejmowana gdy pewność AI jest poniżej progu."""

    BLOCK_AND_ALERT = "BLOCK_AND_ALERT"
    TRIAGE_QUEUE = "TRIAGE_QUEUE"
    ALLOW = "ALLOW"


class RiskThreshold:
    """Próg ryzyka dla kombinacji tax_form + expense_type."""

    def __init__(
        self,
        required_ml_confidence: float = 0.85,
        action_if_below: str = "TRIAGE_QUEUE",
        rule_id: str = "default",
    ) -> None:
        self.required_ml_confidence = required_ml_confidence
        self.action_if_below = action_if_below
        self.rule_id = rule_id


class RiskGuard:
    """Dynamiczny strażnik ryzyka z regułami w SQLite."""

    def get_threshold(
        self,
        tax_form: str,
        expense_type: str = "inne",
        vendor_trust: str = "medium",
    ) -> RiskThreshold:
        """Get risk threshold for given conditions."""
        conn = get_rules_connection()
        try:
            rule = query_risk_threshold(conn, tax_form, expense_type)
        finally:
            conn.close()

        if rule:
            output = rule["output"]
            return RiskThreshold(
                required_ml_confidence=float(output.get("required_ml_confidence", 0.85)),
                action_if_below=output.get("action_if_below", "TRIAGE_QUEUE"),
                rule_id=str(rule["rule_id"]),
            )

        return RiskThreshold(
            required_ml_confidence=0.85,
            action_if_below="TRIAGE_QUEUE",
            rule_id="fallback",
        )

    def evaluate(
        self,
        tax_form: str,
        expense_type: str,
        ai_confidence: float,
        vendor_trust: str = "medium",
    ) -> dict[str, Any]:
        """Evaluate risk for given conditions."""
        threshold = self.get_threshold(tax_form, expense_type, vendor_trust)

        if ai_confidence >= threshold.required_ml_confidence:
            return {
                "action": RiskAction.ALLOW,
                "required_confidence": threshold.required_ml_confidence,
                "ai_confidence": ai_confidence,
                "rule_id": threshold.rule_id,
                "reason": f"AI confidence {ai_confidence:.2f} >= required {threshold.required_ml_confidence:.2f}",
            }

        return {
            "action": RiskAction(threshold.action_if_below),
            "required_confidence": threshold.required_ml_confidence,
            "ai_confidence": ai_confidence,
            "rule_id": threshold.rule_id,
            "reason": f"AI confidence {ai_confidence:.2f} < required {threshold.required_ml_confidence:.2f} for {tax_form}/{expense_type}",
        }
