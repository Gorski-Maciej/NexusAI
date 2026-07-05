"""NATS JetStream topics for agent-to-agent communication.

Zgodnie z blueprintem aa3fvcx.txt:
- council.* — komunikacja z AgentOrchestrator
- invoice.* — AgentDataExtraction
- analytics.* — AgentAnalytics
- quality.* — AgentQualityValidator
- assets.* — Fixed Assets (przyszłościowy)
"""

from __future__ import annotations

from enum import StrEnum


class AgentTopic(StrEnum):
    """NATS JetStream topics dla komunikacji między agentami."""

    # ── AgentOrchestrator (Rada Agentów) ─────────────────────────────
    COUNCIL_TASK_REQUEST = "council.task.request"
    """Nowe zadanie dla systemu (od UI / zewnętrznego systemu)."""
    COUNCIL_DECISION_FINAL = "council.decision.final"
    """Ostateczna decyzja Orkiestratora (do wykonania)."""

    # ── AgentDataExtraction ──────────────────────────────────────────
    INVOICE_RECEIVED = "invoice.received"
    """Nowa faktura do ekstrakcji danych."""
    INVOICE_EXTRACTED = "invoice.extracted"
    """Dane po ekstrakcji (zwrot do Orkiestratora)."""

    # ── AgentAnalytics ───────────────────────────────────────────────
    ANALYTICS_QUERY = "analytics.query"
    """Zapytanie analityczne od Orkiestratora."""
    ANALYTICS_RESULT = "analytics.result"
    """Wynik analizy (zwrot do Orkiestratora)."""
    ANALYTICS_ALERT = "analytics.alert"
    """Proaktywne powiadomienie o anomalii."""

    # ── AgentQualityValidator ────────────────────────────────────────
    QUALITY_CHECK_REQUEST = "quality.check.request"
    """Prośba o walidację decyzji."""
    QUALITY_CHECK_RESULT = "quality.check.result"
    """Wynik walidacji."""

    # ── Fixed Assets (przyszłościowy) ────────────────────────────────
    ASSETS_CLASSIFY = "assets.classify"
    """Klasyfikacja środka trwałego."""
    ASSETS_RESULT = "assets.result"
    """Wynik klasyfikacji."""

    # ── System ───────────────────────────────────────────────────────
    SYSTEM_HEARTBEAT = "system.heartbeat"
    """Heartbeat agenta."""
    SYSTEM_ERROR = "system.error"
    """Błąd agenta."""
