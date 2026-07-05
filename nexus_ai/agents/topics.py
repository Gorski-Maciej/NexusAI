"""NATS JetStream topics for agent-to-agent communication.

Zgodnie z aa3fvcx.txt (5 agentów):
- council.* — AgentOrchestrator (Centralny Mózg)
- invoice.* — AgentDataExtraction (Forteca Precyzji)
- analytics.* — AgentAnalytics (Sztab Analityczny)
- quality.* — AgentQualityValidator (Trójwarstwowa Tarcza)
- assets.* — AgentFixedAssets (Zarządca Majątku)
- system.* — System (heartbeat, health, error)
"""

from __future__ import annotations

from enum import StrEnum


class AgentTopic(StrEnum):
    """NATS JetStream topics dla komunikacji między 5 agentami."""

    # ══════════════════════════════════════════════════════════════════
    # AgentOrchestrator — Centralny Mózg (CFO)
    # ══════════════════════════════════════════════════════════════════
    COUNCIL_TASK_REQUEST = "council.task.request"
    COUNCIL_DECISION_FINAL = "council.decision.final"
    COUNCIL_DECISION_REVIEW = "council.decision.review"
    COUNCIL_DECISION_LEARN = "council.decision.learn"
    COUNCIL_ESCALATION = "council.escalation"
    COUNCIL_HEARTBEAT = "council.heartbeat"

    # ══════════════════════════════════════════════════════════════════
    # AgentDataExtraction — Forteca Precyzji (OCR + KSeF)
    # ══════════════════════════════════════════════════════════════════
    INVOICE_RECEIVED = "invoice.received"
    INVOICE_EXTRACTED = "invoice.extracted"
    INVOICE_FAILED = "invoice.failed"
    # KSeF (wchłonięty przez Extraction — zgodnie z aa3fvcx.txt)
    KSEF_SEND = "ksef.send"
    KSEF_STATUS = "ksef.status"
    KSEF_RECEIVE = "ksef.receive"

    # ══════════════════════════════════════════════════════════════════
    # AgentAnalytics — Sztab Analityczny (cashflow + vendor intel)
    # ══════════════════════════════════════════════════════════════════
    ANALYTICS_QUERY = "analytics.query"
    ANALYTICS_RESULT = "analytics.result"
    ANALYTICS_ALERT = "analytics.alert"
    # Cash Flow (wchłonięty przez Analytics)
    CASH_FORECAST = "analytics.cash.forecast"
    # Vendor Intelligence (wchłonięty przez Analytics)
    VENDOR_CHECK = "analytics.vendor.check"
    VENDOR_RESULT = "analytics.vendor.result"

    # ══════════════════════════════════════════════════════════════════
    # AgentQualityValidator — Trójwarstwowa Tarcza (tax + fraud + ESG)
    # ══════════════════════════════════════════════════════════════════
    QUALITY_CHECK_REQUEST = "quality.check.request"
    QUALITY_CHECK_RESULT = "quality.check.result"
    # Tax (wchłonięty przez QualityValidator)
    TAX_CALCULATE = "quality.tax.calculate"
    TAX_RESULT = "quality.tax.result"
    TAX_DEADLINE = "quality.tax.deadline"
    TAX_RULE_UPDATED = "quality.tax.rule.updated"
    # Compliance (wchłonięty przez QualityValidator)
    COMPLIANCE_CHECK = "quality.compliance.check"
    COMPLIANCE_REPORT = "quality.compliance.report"

    # ══════════════════════════════════════════════════════════════════
    # AgentFixedAssets — Zarządca Majątku
    # ══════════════════════════════════════════════════════════════════
    ASSETS_CLASSIFY = "assets.classify"
    ASSETS_DEPRECIATE = "assets.depreciate"
    ASSETS_RESULT = "assets.result"

    # ══════════════════════════════════════════════════════════════════
    # System — System-wide topics
    # ══════════════════════════════════════════════════════════════════
    SYSTEM_HEARTBEAT = "system.heartbeat"
    SYSTEM_HEALTH = "system.health"
    SYSTEM_ERROR = "system.error"
    SYSTEM_CONFIG_UPDATED = "system.config.updated"


# ── Strumienie JetStream ────────────────────────────────────────────────

JETSTREAM_STREAMS: dict[str, tuple[list[str], str, int]] = {
    "council": (
        [t for t in AgentTopic if t.startswith("council.")],
        "90d",
        5,
    ),
    "invoices": (
        [
            AgentTopic.INVOICE_RECEIVED,
            AgentTopic.INVOICE_EXTRACTED,
            AgentTopic.INVOICE_FAILED,
        ],
        "7d",
        3,
    ),
    "analytics": (
        [t for t in AgentTopic if t.startswith("analytics.")],
        "7d",
        3,
    ),
    "quality": (
        [t for t in AgentTopic if t.startswith("quality.")],
        "7d",
        3,
    ),
    "assets": (
        [t for t in AgentTopic if t.startswith("assets.")],
        "30d",
        3,
    ),
    "audit": (
        ["audit.*"],
        "365d",
        5,
    ),
    "config": (
        ["system.config.updated"],
        "30d",
        2,
    ),
}
"""Konfiguracja strumieni JetStream dla 5 agentów (zgodnie z aa3fvcx.txt)."""
