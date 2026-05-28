"""
Autopilot — the heart of the decision-making system.
Contains TrustScoreCalculator and CouncilOrchestrator.
"""

from __future__ import annotations

import asyncio
import json
import time
from dataclasses import dataclass, field
from decimal import Decimal
from typing import Any

from core.config import AppConfig
from core.logger import get_logger
from db.analytics import DuckDBManager
from services.council_agents import (
    AlphaAgent,
    BaseCouncilAgent,
    BetaAgent,
    DecisionVerdict,
    GammaAgent,
    ModelManager,
)
from services.decision_logger import DecisionLogger

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


# ---------------------------------------------------------------------------
# Trust Score Calculator
# ---------------------------------------------------------------------------

DEFAULT_WEIGHTS = {
    "ai_confidence": 0.35,
    "vendor_reliability": 0.30,
    "data_consistency": 0.25,
    "context_trust": 0.10,
}

DEFAULT_THRESHOLDS = {
    "auto_post": 0.92,
    "suggest": 0.75,
    "ask_user": 0.50,
}


class TrustScoreCalculator:
    """
    Calculates the Trust Score from four components:
    AI Confidence, Vendor Reliability, Data Consistency, Context Trust.
    Supports adaptive threshold tuning per context.
    """

    def __init__(
        self,
        config: AppConfig | None = None,
        duckdb: DuckDBManager | None = None,
    ) -> None:
        self._config = config or AppConfig()
        self._duckdb = duckdb
        self._weights = dict(DEFAULT_WEIGHTS)

    def calculate(
        self,
        extracted_data: dict[str, Any],
        alpha_verdict: DecisionVerdict,
        beta_verdict: DecisionVerdict,
        gamma_verdict: DecisionVerdict,
    ) -> dict[str, Any]:
        """Compute the composite Trust Score and return breakdown."""

        # --- 1. AI Confidence (weight 0.35) ---
        ocr_confidence = float(extracted_data.get("ocr_confidence", 0.5))
        layout_confidence = float(extracted_data.get("layout_confidence", 0.5))
        amount_consensus = 1.0 if extracted_data.get("amount_consensus", True) else 0.3
        llm_validation = float(extracted_data.get("llm_validation", 0.5))

        ai_score = (
            ocr_confidence * 0.30
            + layout_confidence * 0.25
            + amount_consensus * 0.25
            + llm_validation * 0.20
        )

        # --- 2. Vendor Reliability (weight 0.30) ---
        vendor = extracted_data.get("vendor_profile", {}) or {}
        vendor_known = 1.0 if vendor.get("known", False) else 0.0
        vendor_invoice_count = min(float(vendor.get("invoice_count", 0)) / 10.0, 1.0)
        vendor_trust_score = float(vendor.get("trust_score", 0.5))
        category_consistent = 1.0 if vendor.get("category_consistent", True) else 0.3

        vendor_score = (
            vendor_known * 0.30
            + vendor_invoice_count * 0.25
            + vendor_trust_score * 0.30
            + category_consistent * 0.15
        )

        # --- 3. Data Consistency (weight 0.25) ---
        math_ok = 1.0 if self._check_math(extracted_data) else 0.0
        nip_valid = 1.0 if self._check_nip(extracted_data.get("contractor_nip", "")) else 0.0
        bank_ok = 1.0 if extracted_data.get("bank_account_consistent", True) else 0.3
        amount_typical = 1.0 if extracted_data.get("amount_typical", True) else 0.0

        data_score = (
            math_ok * 0.30
            + nip_valid * 0.30
            + bank_ok * 0.20
            + amount_typical * 0.20
        )

        # --- 4. Context Trust (weight 0.10) ---
        auto_approve = 1.0 if vendor.get("auto_approve", False) else 0.0
        category_pref = 1.0 if vendor.get("category_preference_match", True) else 0.3

        context_score = (
            auto_approve * 0.60
            + category_pref * 0.40
        )

        # --- Composite ---
        trust_score = (
            ai_score * self._weights["ai_confidence"]
            + vendor_score * self._weights["vendor_reliability"]
            + data_score * self._weights["data_consistency"]
            + context_score * self._weights["context_trust"]
        )

        return {
            "trust_score": round(min(max(trust_score, 0.0), 1.0), 4),
            "components": {
                "ai_confidence": round(ai_score, 4),
                "vendor_reliability": round(vendor_score, 4),
                "data_consistency": round(data_score, 4),
                "context_trust": round(context_score, 4),
            },
            "raw": {
                "ai_confidence": {
                    "ocr_confidence": ocr_confidence,
                    "layout_confidence": layout_confidence,
                    "amount_consensus": amount_consensus,
                    "llm_validation": llm_validation,
                },
                "vendor_reliability": {
                    "vendor_known": vendor_known,
                    "vendor_invoice_count": vendor_invoice_count,
                    "vendor_trust_score": vendor_trust_score,
                    "category_consistent": category_consistent,
                },
                "data_consistency": {
                    "math_ok": math_ok,
                    "nip_valid": nip_valid,
                    "bank_ok": bank_ok,
                    "amount_typical": amount_typical,
                },
                "context_trust": {
                    "auto_approve": auto_approve,
                    "category_preference": category_pref,
                },
            },
        }

    def get_adapted_thresholds(
        self,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None = None,
    ) -> dict[str, float]:
        """
        Adapt decision thresholds to context.
        Returns dict with auto_post, suggest, ask_user thresholds.
        """
        if not self._config.autopilot_adaptation_enabled:
            return dict(DEFAULT_THRESHOLDS)

        base = dict(DEFAULT_THRESHOLDS)
        vendor = vendor_profile or invoice_data.get("vendor_profile", {}) or {}
        adjustment = self._config.autopilot_adaptation_learning_rate

        # --- Per-category adjustment ---
        category = str(invoice_data.get("category", "")).lower()
        # Recurring categories → lower threshold (more aggressive)
        recurring_categories = {"paliwo", "czynsz", "media", "telekomunikacja", "leasing"}
        problematic_categories = {"usługi it", "doradztwo", "marketing", "szkolenia"}

        if category in recurring_categories:
            base["auto_post"] -= adjustment * 0.5
            base["suggest"] -= adjustment * 0.3
        elif category in problematic_categories:
            base["auto_post"] += adjustment * 1.0
            base["suggest"] += adjustment * 0.5

        # --- Per-vendor adjustment ---
        vendor_known = vendor.get("known", False)
        vendor_invoice_count = int(vendor.get("invoice_count", 0))

        if vendor_known and vendor_invoice_count >= self._config.autopilot_vendor_alpha_proximity_min:
            base["auto_post"] -= adjustment * 1.0
            base["suggest"] -= adjustment * 0.5
        elif not vendor_known:
            base["auto_post"] += adjustment * 2.0
            base["suggest"] += adjustment * 1.0

        # --- Per-amount adjustment ---
        amount_gross = float(invoice_data.get("amount_gross", 0) or 0)
        low_amount = self._config.autopilot_low_amount_threshold

        if amount_gross <= low_amount:
            base["auto_post"] -= adjustment * 0.5
            base["suggest"] -= adjustment * 0.3
        elif amount_gross >= low_amount * 20:  # 10k+ PLN
            base["auto_post"] += adjustment * 2.0
            base["suggest"] += adjustment * 1.0
        elif amount_gross >= low_amount * 4:  # 2k+ PLN
            base["auto_post"] += adjustment * 0.5
            base["suggest"] += adjustment * 0.3

        # Clamp values to [0.0, 1.0]
        for key in base:
            base[key] = round(min(max(base[key], 0.0), 1.0), 4)

        return base

    def update_weights_from_user_corrections(
        self,
        correction_stats: dict[str, Any],
    ) -> None:
        """
        Dynamically adjust component weights based on user correction history.
        If users frequently correct decisions in a specific category,
        the weight of that component is adjusted.
        """
        lr = self._config.autopilot_adaptation_learning_rate
        for component in ("ai_confidence", "vendor_reliability", "data_consistency", "context_trust"):
            correction_rate = float(correction_stats.get(f"{component}_correction_rate", 0.0))
            # High correction rate → reduce weight (the component is unreliable)
            if correction_rate > 0.2:
                self._weights[component] = max(self._weights[component] - lr, 0.05)
            # Low correction rate → increase weight
            elif correction_rate < 0.05:
                self._weights[component] = min(self._weights[component] + lr * 0.5, 0.95)

        # Normalize weights to sum to 1.0
        total = sum(self._weights.values())
        if total > 0:
            for k in self._weights:
                self._weights[k] = round(self._weights[k] / total, 4)

    @staticmethod
    def _check_math(data: dict[str, Any]) -> bool:
        """Check netto + VAT ≈ brutto with ±0.01 tolerance."""
        net = float(data.get("amount_net", 0) or 0)
        vat = float(data.get("vat", 0) or 0)
        gross = float(data.get("amount_gross", 0) or 0)
        if gross == 0:
            return True  # no data to check
        return abs((net + vat) - gross) <= 0.01

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
# Council Orchestrator
# ---------------------------------------------------------------------------

class CouncilOrchestrator:
    """
    Orchestrates the Council of Agents deliberation.
    Follows the decision matrix:
      - Full consensus → AUTO_POST or SUGGEST
      - Majority consensus → SUGGEST / ASK_USER
      - No consensus / Beta veto → BLOCK
    """

    def __init__(
        self,
        model_manager: ModelManager,
        alpha: AlphaAgent,
        beta: BetaAgent,
        gamma: GammaAgent,
        trust_calculator: TrustScoreCalculator | None = None,
        decision_logger: DecisionLogger | None = None,
        config: AppConfig | None = None,
    ) -> None:
        self._model_manager = model_manager
        self._alpha = alpha
        self._beta = beta
        self._gamma = gamma
        self._calculator = trust_calculator or TrustScoreCalculator(config=config)
        self._logger = decision_logger
        self._config = config or AppConfig()
        self._timeout = self._config.autopilot_agent_timeout_seconds

    async def evaluate(
        self,
        invoice_id: str,
        invoice_data: dict[str, Any],
    ) -> FinalDecision:
        """
        Full evaluation flow:
        1. Run Alpha (first pass)
        2. If Alpha confident + APPROVE → fast-path accept
        3. Else run Beta + Gamma in parallel
        4. Deliberate (decision matrix)
        5. Calculate Trust Score
        6. Adapt thresholds to context
        7. Final decision
        8. Log
        """
        logger.info("[Council] evaluating invoice_id=%s", invoice_id)

        # --- Step 1: Alpha (fast leader) ---
        alpha_verdict = await self._run_with_timeout(self._alpha.evaluate(invoice_data))

        # --- Step 2: Fast path (green zone) ---
        if alpha_verdict.decision == "APPROVE" and alpha_verdict.confidence >= 0.92:
            beta_verdict = DecisionVerdict(
                decision="APPROVE", confidence=0.0, reasoning="Skipped (alpha fast-path)"
            )
            gamma_verdict = DecisionVerdict(
                decision="APPROVE", confidence=0.0, reasoning="Skipped (alpha fast-path)"
            )
            logger.info("[Council] fast-path APPROVE for invoice_id=%s", invoice_id)
            return await self._finalize(
                invoice_id=invoice_id,
                invoice_data=invoice_data,
                alpha_verdict=alpha_verdict,
                beta_verdict=beta_verdict,
                gamma_verdict=gamma_verdict,
                deliberation="Alpha fast-path (green zone)",
            )

        # --- Step 3: Beta + Gamma in parallel ---
        beta_task = self._run_with_timeout(self._beta.evaluate(invoice_data))
        gamma_task = self._run_with_timeout(self._gamma.evaluate(invoice_data))
        beta_verdict, gamma_verdict = await asyncio.gather(beta_task, gamma_task)

        # --- Step 4: Deliberate ---
        deliberation = self._deliberate(alpha_verdict, beta_verdict, gamma_verdict)

        # --- Step 5-8: Finalize ---
        return await self._finalize(
            invoice_id=invoice_id,
            invoice_data=invoice_data,
            alpha_verdict=alpha_verdict,
            beta_verdict=beta_verdict,
            gamma_verdict=gamma_verdict,
            deliberation=deliberation,
        )

    def _deliberate(
        self,
        alpha: DecisionVerdict,
        beta: DecisionVerdict,
        gamma: DecisionVerdict,
    ) -> str:
        """
        Decision matrix logic.
        Returns a deliberation explanation string.
        """
        decisions = {"ALPHA": alpha.decision, "BETA": beta.decision, "GAMMA": gamma.decision}
        approves = sum(1 for d in decisions.values() if d == "APPROVE")
        rejects = sum(1 for d in decisions.values() if d == "REJECT")

        # --- Beta veto ---
        if beta.decision == "REJECT" and "error" in beta.reasoning.lower():
            return f"BETA_VETO: {beta.reasoning}"

        # --- Full consensus ---
        if approves == 3:
            return "FULL_CONSENSUS: all agents approve"
        if rejects == 3:
            return "FULL_CONSENSUS: all agents reject"

        # --- Majority ---
        if approves >= 2:
            return "MAJORITY_APPROVE"
        if rejects >= 2:
            if beta.decision == "REJECT":
                return "MAJORITY_REJECT_WITH_BETA"
            return "MAJORITY_REJECT"

        # --- No consensus ---
        if approves == 1 and rejects == 1:
            return "SPLIT: one approve, one reject, one unknown"

        return f"NO_CONSENSUS: alpha={alpha.decision}, beta={beta.decision}, gamma={gamma.decision}"

    async def _finalize(
        self,
        invoice_id: str,
        invoice_data: dict[str, Any],
        alpha_verdict: DecisionVerdict,
        beta_verdict: DecisionVerdict,
        gamma_verdict: DecisionVerdict,
        deliberation: str,
    ) -> FinalDecision:
        """Calculate trust score, adapt thresholds, decide, and log."""

        # --- Step 5: Trust Score ---
        trust_result = self._calculator.calculate(
            extracted_data=invoice_data,
            alpha_verdict=alpha_verdict,
            beta_verdict=beta_verdict,
            gamma_verdict=gamma_verdict,
        )
        trust_score = trust_result["trust_score"]

        # --- Step 6: Adapted thresholds ---
        vendor_profile = invoice_data.get("vendor_profile", None)
        thresholds = self._calculator.get_adapted_thresholds(
            invoice_data=invoice_data,
            vendor_profile=vendor_profile,
        )

        # --- Step 7: Final decision ---
        final_decision = self._resolve_decision(
            trust_score=trust_score,
            thresholds=thresholds,
            deliberation=deliberation,
        )

        # --- Step 8: Context for logging ---
        context = {
            "invoice_id": invoice_id,
            "category": invoice_data.get("category", ""),
            "contractor_nip": invoice_data.get("contractor_nip", ""),
            "amount_gross": float(invoice_data.get("amount_gross", 0)),
            "vendor_invoice_count": (invoice_data.get("vendor_profile") or {}).get("invoice_count", 0),
        }

        decision = FinalDecision(
            decision=final_decision,
            trust_score=trust_score,
            trust_components=trust_result["components"],
            adapted_thresholds=thresholds,
            alpha_verdict=alpha_verdict,
            beta_verdict=beta_verdict,
            gamma_verdict=gamma_verdict,
            context=context,
            deliberation=deliberation,
        )

        # --- Log decision ---
        if self._logger:
            try:
                await self._logger.log_decision(
                    invoice_id=invoice_id,
                    alpha_verdict=alpha_verdict.to_dict(),
                    beta_verdict=beta_verdict.to_dict(),
                    gamma_verdict=gamma_verdict.to_dict(),
                    final_decision=final_decision,
                    trust_score=trust_score,
                    trust_components=trust_result["components"],
                    context=context,
                )
            except Exception as exc:
                logger.error("[Council] failed to log decision: %s", exc)

        logger.info(
            "[Council] invoice_id=%s decision=%s trust=%.4f deliberation=%s",
            invoice_id,
            final_decision,
            trust_score,
            deliberation,
        )
        return decision

    def _resolve_decision(
        self,
        trust_score: float,
        thresholds: dict[str, float],
        deliberation: str,
    ) -> str:
        """Map trust score + deliberation to a final decision."""

        # Beta veto always triggers at least ASK_USER
        if deliberation.startswith("BETA_VETO"):
            return "ASK_USER"

        # Full reject consensus → BLOCK
        if deliberation == "FULL_CONSENSUS: all agents reject":
            return "BLOCK"

        # Trust score based decision
        if trust_score >= thresholds["auto_post"]:
            return "AUTO_POST"
        if trust_score >= thresholds["suggest"]:
            return "SUGGEST"
        if trust_score >= thresholds["ask_user"]:
            return "ASK_USER"

        return "BLOCK"

    async def _run_with_timeout(
        self,
        coro: 'asyncio.Future[DecisionVerdict] | asyncio.Task[DecisionVerdict] | DecisionVerdict',
    ) -> DecisionVerdict:
        """Run an agent evaluation with a timeout."""
        try:
            return await asyncio.wait_for(coro, timeout=self._timeout)
        except asyncio.TimeoutError:
            logger.warning("[Council] agent timed out after %ds", self._timeout)
            return DecisionVerdict.error(f"Timeout after {self._timeout}s")
