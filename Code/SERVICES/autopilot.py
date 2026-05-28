"""
Autopilot — the heart of the decision-making system.
Contains TrustScoreCalculator, CouncilOrchestrator (z CouncilSession),
oraz integrację z PLE (Perpetual Learning Engine).
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
from services.council_session import CouncilSession, CouncilVerdict, DecisionLevel
from services.decision_logger import DecisionLogger
from services.ple_engine import PLEEngine

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
    council_verdict: CouncilVerdict | None = None  # Nowość: wynik sesji Rady
    ple_decision_pattern: dict[str, Any] | None = None  # Nowość: wzorzec z PLE


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

    async def get_adapted_thresholds(
        self,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None = None,
        ple_engine: PLEEngine | None = None,
    ) -> dict[str, float]:
        """
        Adapt decision thresholds to context.
        Uses PLE for additional adaptation if available.
        Returns dict with auto_post, suggest, ask_user thresholds.
        """
        if not self._config.autopilot_adaptation_enabled:
            return dict(DEFAULT_THRESHOLDS)

        base = dict(DEFAULT_THRESHOLDS)
        vendor = vendor_profile or invoice_data.get("vendor_profile", {}) or {}
        adjustment = self._config.autopilot_adaptation_learning_rate

        # --- Per-category adjustment ---
        category = str(invoice_data.get("category", "")).lower()
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
        elif amount_gross >= low_amount * 20:
            base["auto_post"] += adjustment * 2.0
            base["suggest"] += adjustment * 1.0
        elif amount_gross >= low_amount * 4:
            base["auto_post"] += adjustment * 0.5
            base["suggest"] += adjustment * 0.3

        # --- PLE-based adaptation (jeśli dostępny) ---
        if ple_engine:
            try:
                contractor_nip = invoice_data.get("contractor_nip", "")
                if contractor_nip:
                    ple_adapted = await ple_engine.get_adapted_thresholds(
                        base, contractor_nip, category
                    )
                    if ple_adapted:
                        base = ple_adapted
            except Exception as exc:
                logger.debug("[TrustScore] PLE threshold adaptation failed: %s", exc)

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
        """
        lr = self._config.autopilot_adaptation_learning_rate
        for component in ("ai_confidence", "vendor_reliability", "data_consistency", "context_trust"):
            correction_rate = float(correction_stats.get(f"{component}_correction_rate", 0.0))
            if correction_rate > 0.2:
                self._weights[component] = max(self._weights[component] - lr, 0.05)
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
            return True
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
    Uses CouncilSession (matryca 8 kombinacji) do podejmowania decyzji.
    Integruje PLE do zapamiętywania wzorców decyzyjnych.
    """

    def __init__(
        self,
        model_manager: ModelManager,
        alpha: AlphaAgent,
        beta: BetaAgent,
        gamma: GammaAgent,
        trust_calculator: TrustScoreCalculator | None = None,
        decision_logger: DecisionLogger | None = None,
        ple_engine: PLEEngine | None = None,
        config: AppConfig | None = None,
    ) -> None:
        self._model_manager = model_manager
        self._alpha = alpha
        self._beta = beta
        self._gamma = gamma
        self._calculator = trust_calculator or TrustScoreCalculator(config=config)
        self._logger = decision_logger
        self._ple = ple_engine
        self._config = config or AppConfig()
        self._timeout = self._config.autopilot_agent_timeout_seconds

    async def evaluate(
        self,
        invoice_id: str,
        invoice_data: dict[str, Any],
    ) -> FinalDecision:
        """
        Full evaluation flow:
        1. Check PLE for known decision pattern (fast-path)
        2. Run Alpha (first pass)
        3. If Alpha confident + APPROVE → fast-path accept
        4. Else run Beta + Gamma in parallel
        5. CouncilSession deliberation (matryca 8 kombinacji)
        6. Calculate Trust Score
        7. Adapt thresholds (z PLE)
        8. Final decision with PLE pattern
        9. Log to PLE and DecisionLogger
        """
        logger.info("[Council] evaluating invoice_id=%s", invoice_id)

        contractor_nip = invoice_data.get("contractor_nip", "")
        category = invoice_data.get("category", "")

        # --- Step 0: Check PLE for known pattern (fastest path) ---
        ple_pattern: dict[str, Any] | None = None
        if self._ple and contractor_nip and category:
            try:
                ple_pattern = await self._ple.get_decision_pattern(contractor_nip, category)
                if ple_pattern and ple_pattern.get("source") == "fm" and ple_pattern.get("confidence", 0) >= 0.90:
                    logger.info(
                        "[Council] PLE fast-path: known pattern=%s for nip=%s cat=%s",
                        ple_pattern["typical_decision"], contractor_nip, category,
                    )
                    # Konstruuj szybki werdykt na podstawie wzorca PLE
                    alpha_v = DecisionVerdict(
                        decision="APPROVE" if ple_pattern["typical_decision"] == "AUTO_POST" else "REJECT",
                        confidence=ple_pattern["confidence"],
                        reasoning=f"PLE pattern match: {ple_pattern['typical_decision']} (freq={ple_pattern.get('frequency', 0)})",
                    )
                    beta_v = DecisionVerdict(
                        decision="APPROVE", confidence=0.9, reasoning="PLE fast-path (skipped)"
                    )
                    gamma_v = DecisionVerdict(
                        decision="APPROVE", confidence=0.9, reasoning="PLE fast-path (skipped)"
                    )
                    return await self._finalize(
                        invoice_id=invoice_id,
                        invoice_data=invoice_data,
                        alpha_verdict=alpha_v,
                        beta_verdict=beta_v,
                        gamma_verdict=gamma_v,
                        deliberation=f"PLE fast-path: pattern={ple_pattern['typical_decision']}",
                        council_verdict=None,
                        ple_pattern=ple_pattern,
                    )
            except Exception as exc:
                logger.debug("[Council] PLE pattern check failed: %s", exc)

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
                ple_pattern=ple_pattern,
            )

        # --- Step 3: Beta + Gamma in parallel ---
        beta_task = self._run_with_timeout(self._beta.evaluate(invoice_data))
        gamma_task = self._run_with_timeout(self._gamma.evaluate(invoice_data))
        beta_verdict, gamma_verdict = await asyncio.gather(beta_task, gamma_task)

        # --- Step 4: CouncilSession deliberation (matryca 8 kombinacji) ---
        session = CouncilSession(invoice_data, alpha_verdict, beta_verdict, gamma_verdict)
        council_verdict = session.deliberate()
        deliberation = f"{council_verdict.pattern}: {council_verdict.deliberation}"

        # --- Step 5-9: Finalize ---
        return await self._finalize(
            invoice_id=invoice_id,
            invoice_data=invoice_data,
            alpha_verdict=alpha_verdict,
            beta_verdict=beta_verdict,
            gamma_verdict=gamma_verdict,
            deliberation=deliberation,
            council_verdict=council_verdict,
            ple_pattern=ple_pattern,
        )

    async def _finalize(
        self,
        invoice_id: str,
        invoice_data: dict[str, Any],
        alpha_verdict: DecisionVerdict,
        beta_verdict: DecisionVerdict,
        gamma_verdict: DecisionVerdict,
        deliberation: str,
        council_verdict: CouncilVerdict | None = None,
        ple_pattern: dict[str, Any] | None = None,
    ) -> FinalDecision:
        """Calculate trust score, adapt thresholds, decide, and log to PLE."""

        # --- Step 5: Trust Score ---
        trust_result = self._calculator.calculate(
            extracted_data=invoice_data,
            alpha_verdict=alpha_verdict,
            beta_verdict=beta_verdict,
            gamma_verdict=gamma_verdict,
        )
        trust_score = trust_result["trust_score"]

        # --- Step 6: Adapted thresholds (z PLE) ---
        vendor_profile = invoice_data.get("vendor_profile", None)
        thresholds = await self._calculator.get_adapted_thresholds(
            invoice_data=invoice_data,
            vendor_profile=vendor_profile,
            ple_engine=self._ple,
        )

        # --- Step 7: Final decision ---
        final_decision = self._resolve_decision(
            trust_score=trust_score,
            thresholds=thresholds,
            deliberation=deliberation,
            council_verdict=council_verdict,
        )

        # --- Context ---
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
            council_verdict=council_verdict,
            ple_decision_pattern=ple_pattern,
        )

        # --- Log to DecisionLogger ---
        if self._logger:
            try:
                ple_stm = None
                ple_ltm = None
                if self._ple:
                    ple_data = await self._ple.get_briefing_data()
                    ple_stm = ple_data.get("stm")
                    ple_ltm = ple_data.get("ltm")
                await self._logger.log_decision(
                    invoice_id=invoice_id,
                    alpha_verdict=alpha_verdict.to_dict(),
                    beta_verdict=beta_verdict.to_dict(),
                    gamma_verdict=gamma_verdict.to_dict(),
                    final_decision=final_decision,
                    trust_score=trust_score,
                    trust_components=trust_result["components"],
                    context=context,
                    decision_level=council_verdict.level.value if council_verdict else "",
                    council_pattern=council_verdict.pattern if council_verdict else "",
                    ple_stm_snapshot=ple_stm,
                    ple_ltm_profile=ple_ltm,
                )
            except Exception as exc:
                logger.error("[Council] failed to log decision: %s", exc)

        # --- Log to PLE ---
        if self._ple:
            try:
                await self._ple.record_decision(
                    invoice_id=invoice_id,
                    decision=final_decision,
                    trust_score=trust_score,
                    trust_components=trust_result["components"],
                    contractor_nip=context.get("contractor_nip", "unknown"),
                    category=context.get("category", "unknown"),
                    amount_gross=context.get("amount_gross", 0.0),
                    metadata={
                        "council_pattern": council_verdict.pattern if council_verdict else "",
                        "decision_level": council_verdict.level.value if council_verdict else "",
                        "deliberation": deliberation,
                    },
                )
            except Exception as exc:
                logger.error("[Council] failed to record to PLE: %s", exc)

        logger.info(
            "[Council] invoice_id=%s decision=%s trust=%.4f deliberation=%s",
            invoice_id, final_decision, trust_score, deliberation,
        )
        return decision

    def _resolve_decision(
        self,
        trust_score: float,
        thresholds: dict[str, float],
        deliberation: str,
        council_verdict: CouncilVerdict | None = None,
    ) -> str:
        """Map trust score + council verdict to a final decision.

        Priorytet:
          1. CouncilVerdict.recommended_action (jeśli poziom >= LEVEL_3)
          2. Trust score thresholds
        """
        # Jeśli CouncilSession dał jednoznaczny werdykt na poziomie 3 lub 4
        if council_verdict:
            if council_verdict.level in (DecisionLevel.LEVEL_3_ESCALATE, DecisionLevel.LEVEL_4_BLOCK):
                return council_verdict.recommended_action

            # Level 2: SUGGEST — sprawdź czy trust score pozwala na auto_post
            if council_verdict.level == DecisionLevel.LEVEL_2_REVIEW:
                if trust_score >= council_verdict.min_trust_for_auto:
                    return "AUTO_POST"
                return "SUGGEST"

            # Level 1: AUTO — sprawdź minimalny trust score
            if council_verdict.level == DecisionLevel.LEVEL_1_AUTO:
                if trust_score >= council_verdict.min_trust_for_auto:
                    return "AUTO_POST"
                return "SUGGEST"

        # Fallback: trust score based (stary mechanizm)
        if trust_score >= thresholds.get("auto_post", 0.92):
            return "AUTO_POST"
        if trust_score >= thresholds.get("suggest", 0.75):
            return "SUGGEST"
        if trust_score >= thresholds.get("ask_user", 0.50):
            return "ASK_USER"

        return "BLOCK"

    async def _run_with_timeout(
        self,
        coro: asyncio.Future[DecisionVerdict] | asyncio.Task[DecisionVerdict] | DecisionVerdict,
    ) -> DecisionVerdict:
        """Run an agent evaluation with a timeout."""
        try:
            return await asyncio.wait_for(coro, timeout=self._timeout)
        except asyncio.TimeoutError:
            logger.warning("[Council] agent timed out after %ds", self._timeout)
            return DecisionVerdict.error(f"Timeout after {self._timeout}s")
