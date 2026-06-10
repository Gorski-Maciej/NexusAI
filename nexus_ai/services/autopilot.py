"""
[DEPRECATED] Autopilot — legacy decision-making system.

UWAGA: Ten plik jest przestarzały. Użyj zamiast tego:
- DecisionEngine (core/decision_engine.py) zamiast CouncilOrchestrator
- InferenceService (core/inference.py) zamiast konkretnych modeli LLM

Zachowany dla kompatybilności wstecznej — nowy kod nie powinien importować
z tego modułu.
"""

from __future__ import annotations

import warnings
warnings.warn(
    "services/autopilot.py jest przestarzały. Użyj DecisionEngine z core/decision_engine.py.",
    DeprecationWarning,
    stacklevel=2,
)

from dataclasses import dataclass, field
from typing import Any

from nexus_ai.core.config import AppConfig
from nexus_ai.core.decision_engine import (
    DecisionEngine,
    DecisionVerdict,
    calculate_trust_score,
    classify_invoice,
)
from nexus_ai.core.logger import get_logger
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.services.decision_logger import DecisionLogger
from nexus_ai.services.risk_guard import RiskGuard

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Decision types
# ---------------------------------------------------------------------------

@dataclass(slots=True)
class FinalDecision:
    decision: str  # AUTO_POST | SUGGEST | ASK_USER | BLOCK
    trust_score: float
    trust_components: dict[str, float]
    adapted_thresholds: dict[str, float]
    alpha_verdict: DecisionVerdict
    beta_verdict: DecisionVerdict
    gamma_verdict: DecisionVerdict
    context: dict[str, Any] = field(default_factory=dict)
    deliberation: str = ""
    risk_verdict: dict[str, Any] | None = None


# ---------------------------------------------------------------------------
# Trust Score Calculator — now uses calculate_trust_score from decision_engine
# ---------------------------------------------------------------------------

DEFAULT_WEIGHTS = {
    "ai_confidence": 0.30,
    "vendor_reliability": 0.25,
    "data_consistency": 0.20,
    "context_trust": 0.10,
    "risk_guard": 0.15,
}

DEFAULT_THRESHOLDS = {
    "auto_post": 0.92,
    "suggest": 0.75,
    "ask_user": 0.50,
}


class TrustScoreCalculator:
    """
    Calculates the Trust Score from five components.
    Delegates to calculate_trust_score() from decision_engine.
    Supports adaptive threshold tuning per context.
    """

    def __init__(
        self,
        config: AppConfig | None = None,
        duckdb: DuckDBManager | None = None,
        risk_guard: RiskGuard | None = None,
    ) -> None:
        self._config = config or AppConfig()
        self._duckdb = duckdb
        self._risk_guard = risk_guard
        self._weights = dict(DEFAULT_WEIGHTS)

    def calculate(
        self,
        extracted_data: dict[str, Any],
        alpha_verdict: DecisionVerdict,
        beta_verdict: DecisionVerdict,
        gamma_verdict: DecisionVerdict,
    ) -> dict[str, Any]:
        """Compute the composite Trust Score using calculate_trust_score."""
        vendor = extracted_data.get("vendor_profile", {}) or {}
        result = calculate_trust_score(extracted_data, vendor)

        # Add raw components for backward compatibility
        result["raw"] = {
            "ai_confidence": {
                "ocr_confidence": float(extracted_data.get("ocr_confidence", 0.5)),
                "layout_confidence": float(extracted_data.get("layout_confidence", 0.5)),
            },
            "vendor_reliability": {
                "vendor_known": 1.0 if vendor.get("known", False) else 0.0,
                "vendor_trust_score": float(vendor.get("trust_score", 0.5)),
            },
        }
        return result

    async def get_adapted_thresholds(
        self,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None = None,
    ) -> dict[str, float]:
        """Adapt decision thresholds to context (PLE removed, SQL-based now)."""
        if not self._config.autopilot_adaptation_enabled:
            return dict(DEFAULT_THRESHOLDS)

        base = dict(DEFAULT_THRESHOLDS)
        vendor = vendor_profile or invoice_data.get("vendor_profile", {}) or {}
        adjustment = self._config.autopilot_adaptation_learning_rate

        category = str(invoice_data.get("category", "")).lower()
        recurring_categories = {"paliwo", "czynsz", "media", "telekomunikacja", "leasing"}
        problematic_categories = {"usługi it", "doradztwo", "marketing", "szkolenia"}

        if category in recurring_categories:
            base["auto_post"] -= adjustment * 0.5
            base["suggest"] -= adjustment * 0.3
        elif category in problematic_categories:
            base["auto_post"] += adjustment * 1.0
            base["suggest"] += adjustment * 0.5

        vendor_known = vendor.get("known", False)
        vendor_invoice_count = int(vendor.get("invoice_count", 0))
        if vendor_known and vendor_invoice_count >= self._config.autopilot_vendor_alpha_proximity_min:
            base["auto_post"] -= adjustment * 1.0
            base["suggest"] -= adjustment * 0.5
        elif not vendor_known:
            base["auto_post"] += adjustment * 2.0
            base["suggest"] += adjustment * 1.0

        amount_gross = float(invoice_data.get("amount_gross", 0) or 0)
        low_amount = self._config.autopilot_low_amount_threshold
        if amount_gross <= low_amount:
            base["auto_post"] -= adjustment * 0.5
            base["suggest"] -= adjustment * 0.3
        elif amount_gross >= low_amount * 20:
            base["auto_post"] += adjustment * 2.0
            base["suggest"] += adjustment * 1.0
        elif amount_gross >= low_amount * 4:
            base["auto_post"] += adjustment * 0.5
            base["suggest"] += adjustment * 0.3

        for key in base:
            base[key] = round(min(max(base[key], 0.0), 1.0), 4)
        return base

    @staticmethod
    def _check_nip(nip: str) -> bool:
        """Validate NIP checksum (Polish tax ID)."""
        nip_str = "".join(ch for ch in str(nip) if ch.isdigit())
        if len(nip_str) != 10:
            return False
        weights = (6, 5, 7, 2, 3, 4, 5, 6, 7)
        checksum = sum(int(d) * w for d, w in zip(nip_str[:9], weights)) % 11
        if checksum == 10:
            return False
        return checksum == int(nip_str[9])


# ---------------------------------------------------------------------------
# Council Orchestrator — now uses DecisionEngine
# ---------------------------------------------------------------------------

class CouncilOrchestrator:
    """
    Orchestrates decision-making using DecisionEngine (SQL-based rules).
    Replaces the old Council of Agents (Alpha/Beta/Gamma).
    """

    def __init__(
        self,
        decision_engine: DecisionEngine,
        trust_calculator: TrustScoreCalculator | None = None,
        decision_logger: DecisionLogger | None = None,
        config: AppConfig | None = None,
    ) -> None:
        self._engine = decision_engine
        self._calculator = trust_calculator or TrustScoreCalculator(config=config)
        self._logger = decision_logger
        self._config = config or AppConfig()

    async def evaluate(
        self,
        invoice_id: str,
        invoice_data: dict[str, Any],
    ) -> FinalDecision:
        """Full evaluation flow using DecisionEngine."""
        logger.info("[Council] evaluating invoice_id=%s", invoice_id)

        vendor = invoice_data.get("vendor_profile", {}) or {}

        # Classify invoice (simple vs complex)
        complexity = classify_invoice(invoice_data, vendor)

        # Make decision via DecisionEngine
        verdict = self._engine.decide(invoice_data, vendor)

        # Calculate trust score
        alpha_v = verdict
        beta_v = DecisionVerdict(
            decision="APPROVE", confidence=0.0,
            reasoning="Skipped (decision engine single pass)",
        )
        gamma_v = DecisionVerdict(
            decision="APPROVE", confidence=0.0,
            reasoning="Skipped (decision engine single pass)",
        )

        trust_result = self._calculator.calculate(
            extracted_data=invoice_data,
            alpha_verdict=alpha_v,
            beta_verdict=beta_v,
            gamma_verdict=gamma_v,
        )
        trust_score = trust_result["trust_score"]
        thresholds = await self._calculator.get_adapted_thresholds(
            invoice_data=invoice_data, vendor_profile=vendor,
        )

        final_decision = verdict.decision
        risk_v = trust_result.get("risk_verdict")

        context = {
            "invoice_id": invoice_id,
            "category": invoice_data.get("category", ""),
            "contractor_nip": invoice_data.get("contractor_nip", ""),
            "amount_gross": float(invoice_data.get("amount_gross", 0)),
            "complexity": complexity,
        }

        decision = FinalDecision(
            decision=final_decision,
            trust_score=trust_score,
            trust_components=trust_result["components"],
            adapted_thresholds=thresholds,
            alpha_verdict=alpha_v,
            beta_verdict=beta_v,
            gamma_verdict=gamma_v,
            context=context,
            deliberation=f"DecisionEngine rule: {verdict.matched_rule}: {verdict.reasoning}",
            risk_verdict=risk_v,
        )

        if self._logger:
            try:
                await self._logger.log_decision(
                    invoice_id=invoice_id,
                    alpha_verdict=alpha_v.to_dict(),
                    beta_verdict=beta_v.to_dict(),
                    gamma_verdict=gamma_v.to_dict(),
                    final_decision=final_decision,
                    trust_score=trust_score,
                    trust_components=trust_result["components"],
                    context=context,
                )
            except Exception as exc:
                logger.error("[Council] failed to log decision: %s", exc)

        logger.info(
            "[Council] invoice_id=%s decision=%s trust=%.4f complexity=%s",
            invoice_id, final_decision, trust_score, complexity,
        )
        return decision
