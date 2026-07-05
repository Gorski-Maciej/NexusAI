"""Taskiq task definitions for NexusAI Agent System.

Rejestruje zadania Taskiq dla 5 agentów AI (zgodnie z aa3fvcx.txt).
Każde zadanie jest uruchamiane przez PullBasedJetStreamBroker (NATS).

5 Agentów:
- agent_orchestrator.* — Orkiestrator (Centralny Mózg)
- agent_data_extraction.* — Ekstrakcja Danych (OCR + KSeF)
- agent_analytics.* — Analityka (cashflow + vendor intel)
- agent_quality_validator.* — Walidacja Jakości (tax + fraud + ESG)
- agent_fixed_assets.* — Środki Trwałe (amortyzacja)
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger
from taskiq import TaskiqDepends

from nexus_ai.agents.models import AnalyticsQuery, DataExtractionRequest, QualityCheckRequest
from nexus_ai.agents.orchestrator import AgentOrchestrator
from nexus_ai.agents.extraction import AgentDataExtraction
from nexus_ai.agents.analytics import AgentAnalytics
from nexus_ai.agents.quality_validator import AgentQualityValidator
from nexus_ai.core.broker import broker
from nexus_ai.core.di import get_config

logger = get_logger("nexus.agents.tasks")


# ═════════════════════════════════════════════════════════════════════════
# Inicjalizacja 5 agentów — singleton na stan workera
# ═════════════════════════════════════════════════════════════════════════

_agents_initialized = False


async def ensure_agents(state: Any, config: Any | None = None) -> dict[str, Any]:
    """Inicjalizuj 5 agentów (zgodnie z aa3fvcx.txt)."""
    global _agents_initialized
    if _agents_initialized and hasattr(state, "agents"):
        return state.agents

    from nexus_ai.core.config import AppConfig
    cfg = config or AppConfig()

    agent_config = {
        "ocr_model": cfg.ocr_model,
        "analytics_sql_model": cfg.analytics_model,
        "analytics_analyst_model": cfg.analytics_model,
        "quality_tax_model": cfg.rules_model,
        "quality_fraud_model": cfg.ocr_model,
        "quality_esg_model": cfg.ocr_model,
        "orchestrator_actor_model": cfg.orchestrator_model or cfg.decision_granite_model,
        "orchestrator_guardian_model": cfg.rules_model,
        "orchestrator_communicator_model": cfg.ocr_model,
        "decision_mode": "auto_post",
    }

    orchestrator = AgentOrchestrator(config=agent_config)
    extraction = AgentDataExtraction(config={
        **agent_config,
        "ocr": {"use_tesseract": True, "use_paddleocr": True, "use_doctr": True},
    })
    analytics = AgentAnalytics(config=agent_config)
    quality = AgentQualityValidator(config=agent_config)

    # Zarejestruj 4 pod-agentów w Orkiestratorze
    orchestrator.register_agent("extraction", extraction)
    orchestrator.register_agent("analytics", analytics)
    orchestrator.register_agent("quality-validator", quality)
    # Agent nr 5 (FixedAssets) — osobny komponent, wywoływany przez services/fixed_assets.py

    await orchestrator.start()
    await extraction.start()
    await analytics.start()
    await quality.start()

    agents = {
        "orchestrator": orchestrator,
        "extraction": extraction,
        "analytics": analytics,
        "quality": quality,
    }
    state.agents = agents
    _agents_initialized = True
    logger.info("[AGENTS] 5 agents initialized (aa3fvcx.txt architecture)")
    return agents


# ═════════════════════════════════════════════════════════════════════════
# AgentOrchestrator — zadania
# ═════════════════════════════════════════════════════════════════════════

@broker.task(task_name="agent_orchestrator.process_invoice", labels={"agent": "orchestrator"})
async def orchestrator_process_invoice(
    invoice_data: dict[str, Any],
    config: Any = TaskiqDepends(get_config),
) -> dict[str, Any]:
    agents = await ensure_agents(broker, config)
    orchestrator: AgentOrchestrator = agents["orchestrator"]
    decision = await orchestrator.process_invoice(invoice_data)
    return {
        "decision_id": decision.decision_id,
        "status": decision.verdict.status,
        "trust_score": decision.verdict.trust_score,
        "explanation": decision.explanation,
        "decision_mode": decision.decision_mode.value,
    }


# ═════════════════════════════════════════════════════════════════════════
# AgentDataExtraction — zadania
# ═════════════════════════════════════════════════════════════════════════

@broker.task(task_name="agent_data_extraction.extract", labels={"agent": "extraction"})
async def extraction_extract(
    invoice_id: str,
    file_path: str,
    file_type: str = "",
    config: Any = TaskiqDepends(get_config),
) -> dict[str, Any]:
    agents = await ensure_agents(broker, config)
    extraction: AgentDataExtraction = agents["extraction"]
    request = DataExtractionRequest(
        invoice_id=invoice_id,
        file_path=file_path,
        file_type=file_type,
    )
    result = await extraction.extract(request)
    return {
        "invoice_id": result.invoice_id,
        "success": result.success,
        "extracted_data": result.extracted_data,
        "confidence": result.confidence,
        "document_type": result.document_type,
        "validation_issues": result.validation_issues,
        "error": result.error,
    }


# ═════════════════════════════════════════════════════════════════════════
# AgentAnalytics — zadania
# ═════════════════════════════════════════════════════════════════════════

@broker.task(task_name="agent_analytics.query", labels={"agent": "analytics"})
async def analytics_query(
    query_id: str,
    query_type: str = "sql",
    natural_language: str = "",
    sql_query: str = "",
    params: dict[str, Any] | None = None,
    config: Any = TaskiqDepends(get_config),
) -> dict[str, Any]:
    agents = await ensure_agents(broker, config)
    analytics: AgentAnalytics = agents["analytics"]
    query = AnalyticsQuery(
        query_id=query_id,
        query_type=query_type,
        natural_language=natural_language,
        sql_query=sql_query,
        params=params or {},
    )
    result = await analytics.analyze(query)
    return {
        "query_id": result.query_id,
        "success": result.success,
        "summary": result.summary,
        "data": result.data,
        "anomalies": result.anomalies,
        "error": result.error,
    }


# ═════════════════════════════════════════════════════════════════════════
# AgentQualityValidator — zadania
# ═════════════════════════════════════════════════════════════════════════

@broker.task(task_name="agent_quality_validator.validate", labels={"agent": "quality"})
async def quality_validate(
    decision_id: str,
    proposed_decision: dict[str, Any],
    invoice_data: dict[str, Any] | None = None,
    checks: list[str] | None = None,
    config: Any = TaskiqDepends(get_config),
) -> dict[str, Any]:
    agents = await ensure_agents(broker, config)
    quality: AgentQualityValidator = agents["quality"]
    request = QualityCheckRequest(
        decision_id=decision_id,
        proposed_decision=proposed_decision,
        invoice_data=invoice_data or {},
        checks=checks or ["tax", "fraud", "esg"],
    )
    result = await quality.validate(request)
    return {
        "decision_id": result.decision_id,
        "overall_verdict": result.overall_verdict,
        "overall_risk_score": result.overall_risk_score,
        "recommendations": result.recommendations,
    }


# ═════════════════════════════════════════════════════════════════════════
# Workflow — zadania złożone
# ═════════════════════════════════════════════════════════════════════════

@broker.task(task_name="agent_workflow.process_and_validate", labels={"agent": "workflow"})
async def workflow_process_and_validate(
    invoice_data: dict[str, Any],
    config: Any = TaskiqDepends(get_config),
) -> dict[str, Any]:
    """Pełny workflow: ekstrakcja → decyzja → walidacja (5 agentów)."""
    agents = await ensure_agents(broker, config)
    orchestrator: AgentOrchestrator = agents["orchestrator"]
    decision = await orchestrator.process_invoice(invoice_data)
    return {
        "decision_id": decision.decision_id,
        "status": decision.verdict.status,
        "trust_score": decision.verdict.trust_score,
        "explanation": decision.explanation,
        "verified_by": decision.verdict.verified_by,
        "timestamp": decision.created_at,
        "decision_mode": decision.decision_mode.value,
    }


__all__ = [
    "ensure_agents",
    "orchestrator_process_invoice",
    "extraction_extract",
    "analytics_query",
    "quality_validate",
    "workflow_process_and_validate",
]
