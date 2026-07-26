"""
v7.0 Pre-OPA Pipeline Wiring Factory — SINGLE SOURCE OF TRUTH.

Tworzy i konfiguruje PreOPAPipeline z wszystkimi zależnościami.
To JEDYNE miejsce gdzie wszystkie bridge'e są łączone.

Usage:
    from nexus_ai.services.pre_opa_wiring import build_pre_opa_pipeline
    pipeline = build_pre_opa_pipeline()
    evaluator = DynamicMultiPassEvaluator(pre_opa_pipeline=pipeline)
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.pre_opa_wiring")


def build_pre_opa_pipeline(
    mpp_engine: Any = None,
    fraud_scorer: Any = None,
    sanctions_api: Any = None,
    ksef_b2c_engine: Any = None,
) -> Any:
    """Build a fully wired PreOPAPipeline with all v7.0 bridges.

    Creates:
    - OPAMPPBridge (47 CN codes from Annex 15)
    - PreOPAFraudChecker (5-dimension fraud scorer)
    - PreOPACarouselChecker (VAT carousel detection)
    - GTUAutoAssigner (13 GTU codes, semantic matching)
    - KSeFB2CEngine (B2C e-invoice compliance)

    Args:
        mpp_engine: Optional pre-built MPPAnnex15Engine instance.
        fraud_scorer: Optional pre-built VATFraudRiskScorer instance.
        sanctions_api: Optional pre-built SanctionsScreeningAPI instance.
        ksef_b2c_engine: Optional pre-built KSeFB2CEngine instance.

    Returns:
        Configured PreOPAPipeline instance, or None if no bridges available.
    """
    try:
        from nexus_ai.services.pre_opa_pipeline import PreOPAPipeline
    except ImportError as exc:
        logger.warning("[PRE-OPA WIRING] PreOPAPipeline not available: %s", exc)
        return None

    # ── Lazy imports ──────────────────────────────────────────────────────
    mpp_bridge = None
    fraud_checker = None
    carousel_checker = None
    gtu_assigner = None
    b2c_engine = ksef_b2c_engine

    # 1. MPP Bridge (Annex 15, 47 CN codes)
    try:
        from nexus_ai.services.opa_mpp_bridge import OPAMPPBridge

        if mpp_engine is None:
            try:
                from nexus_ai.services.mpp_engine import MPPAnnex15Engine
                mpp_engine = MPPAnnex15Engine()
            except ImportError:
                logger.info("[PRE-OPA WIRING] MPPAnnex15Engine not available — using fallback")
                mpp_engine = None

        if mpp_engine is not None:
            mpp_bridge = OPAMPPBridge(mpp_engine)
            logger.info("[PRE-OPA WIRING] MPP Bridge: 47 CN codes active")
    except ImportError as exc:
        logger.info("[PRE-OPA WIRING] MPP Bridge not available: %s", exc)

    # 2. Fraud Checker (5-dimension scoring + carousel)
    try:
        from nexus_ai.services.pre_opa_fraud_check import PreOPAFraudChecker

        if fraud_scorer is None:
            try:
                from nexus_ai.services.vat_fraud_risk_scorer import VATFraudRiskScorer
                fraud_scorer = VATFraudRiskScorer()
            except ImportError:
                fraud_scorer = None

        # Carousel checker (always create — works standalone)
        carousel_checker = None
        try:
            from nexus_ai.services.pre_opa_carousel_check import PreOPACarouselChecker
            carousel_checker = PreOPACarouselChecker()
        except ImportError:
            pass

        fraud_checker = PreOPAFraudChecker(
            scorer=fraud_scorer,
            carousel_checker=carousel_checker,
        )
        logger.info(
            "[PRE-OPA WIRING] Fraud Checker: scorer=%s carousel=%s",
            fraud_scorer is not None,
            carousel_checker is not None,
        )
    except ImportError as exc:
        logger.info("[PRE-OPA WIRING] Fraud Checker not available: %s", exc)

    # 3. GTU Auto-Assigner (13 GTU codes, semantic matching)
    try:
        from nexus_ai.services.gtu_auto_assigner import GTUAutoAssigner
        gtu_assigner = GTUAutoAssigner()
        logger.info("[PRE-OPA WIRING] GTU Assigner: 13 codes, 4 matching methods")
    except ImportError as exc:
        logger.info("[PRE-OPA WIRING] GTU Assigner not available: %s", exc)

    # 4. KSeF B2C Engine (if not provided)
    if b2c_engine is None:
        try:
            from nexus_ai.services.ksef_b2c_engine import KSeFB2CEngine
            b2c_engine = KSeFB2CEngine()
            logger.info("[PRE-OPA WIRING] KSeF B2C Engine: 2026-07-01 mandate active")
        except ImportError as exc:
            logger.info("[PRE-OPA WIRING] KSeF B2C Engine not available: %s", exc)

    # ── Sanctions Screening (optional, for AML) ──────────────────────────
    if sanctions_api is None:
        try:
            from nexus_ai.services.sanctions_screening_api import SanctionsScreeningAPI
            sanctions_api = SanctionsScreeningAPI()
            logger.info("[PRE-OPA WIRING] Sanctions Screening API active")
        except ImportError:
            pass

    # ── Build pipeline ────────────────────────────────────────────────────
    pipeline = PreOPAPipeline(
        mpp_bridge=mpp_bridge,
        fraud_checker=fraud_checker,
        carousel_checker=carousel_checker,
        gtu_assigner=gtu_assigner,
        ksef_b2c_engine=b2c_engine,
    )

    # 5. Judgment Predictor C1 (Pass 0: SHADOW_PREDICT) — v7.0 Audit P1.1
    try:
        from JDG.tools.judgment_predictor import JudgmentPredictor
        pipeline.judgment_predictor = JudgmentPredictor()
        logger.info("[PRE-OPA WIRING] Judgment Predictor C1: Shadow Mode active (9 risk categories)")
    except ImportError as exc:
        logger.info("[PRE-OPA WIRING] Judgment Predictor C1 not available: %s", exc)
        pipeline.judgment_predictor = None

    # 6. LLM Bridge C2 (Pass 9: EXPLAIN) — v7.0 Audit P1.2
    try:
        from JDG.tools.llm_bridge import LLMBridge
        pipeline.llm_bridge = LLMBridge(model="gemini-flash")
        logger.info("[PRE-OPA WIRING] LLM Bridge C2: Gemini 2.0 Flash active (5 explanation styles)")
    except ImportError as exc:
        logger.info("[PRE-OPA WIRING] LLM Bridge C2 not available: %s", exc)
        pipeline.llm_bridge = None

    logger.info(
        "[PRE-OPA WIRING] Pipeline built: mpp=%s fraud=%s carousel=%s gtu=%s ksef_b2c=%s",
        mpp_bridge is not None,
        fraud_checker is not None,
        carousel_checker is not None,
        gtu_assigner is not None,
        b2c_engine is not None,
    )

    return pipeline


def build_dynamic_evaluator_with_pre_opa(
    opa_client: Any = None,
    mpp_engine: Any = None,
    fraud_scorer: Any = None,
) -> Any:
    """Build a DynamicMultiPassEvaluator with integrated PreOPAPipeline.

    This is the RECOMMENDED entry point for production use.
    Combines DAG pruning + telemetry fail-fast + pre-OPA intelligence.

    Args:
        opa_client: OpaClient instance (optional — can be injected later).
        mpp_engine: Pre-built MPPAnnex15Engine.
        fraud_scorer: Pre-built VATFraudRiskScorer.

    Returns:
        DynamicMultiPassEvaluator with PreOPAPipeline pre-wired.
    """
    from nexus_ai.tax.dynamic_dag import DynamicMultiPassEvaluator

    pre_opa = build_pre_opa_pipeline(
        mpp_engine=mpp_engine,
        fraud_scorer=fraud_scorer,
    )

    evaluator = DynamicMultiPassEvaluator(pre_opa_pipeline=pre_opa)
    logger.info("[PRE-OPA WIRING] DynamicMultiPassEvaluator built with PreOPAPipeline")
    return evaluator
