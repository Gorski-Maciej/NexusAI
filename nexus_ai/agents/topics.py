"""NATS JetStream topics for agent-to-agent communication.

Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt §2.1:
- nexus.agents.* — prefiks główny dla wszystkich agentów
- council.* — AgentOrchestrator (Rada Agentów)
- invoice.* — AgentDataExtraction
- analytics.* — AgentAnalytics
- quality.* — AgentQualityValidator
- tax.* — AgentTaxEngine
- cash.* — AgentCashManager
- compliance.* — AgentCompliance
- ksef.* — AgentKSeF
- vendor.* — AgentVendorIntelligence
- assets.* — AgentFixedAssets
- system.* — System (heartbeat, health, error)
"""

from __future__ import annotations

from enum import StrEnum


class AgentTopic(StrEnum):
    """NATS JetStream topics dla komunikacji między 10 agentami.

    Prefiks: nexus.agents. (opcjonalny, używany dla oficjalnych strumieni)
    """

    # ══════════════════════════════════════════════════════════════════
    # AgentOrchestrator — Rada Agentów (CFO)
    # ══════════════════════════════════════════════════════════════════
    COUNCIL_TASK_REQUEST = "council.task.request"
    """Nowe zadanie dla systemu (od UI / zewnętrznego systemu)."""
    COUNCIL_DECISION_FINAL = "council.decision.final"
    """Ostateczna decyzja Orkiestratora (do wykonania)."""
    COUNCIL_DECISION_REVIEW = "council.decision.review"
    """Decyzja wymagająca przeglądu przez użytkownika."""
    COUNCIL_DECISION_LEARN = "council.decision.learn"
    """Korekta / feedback od użytkownika."""
    COUNCIL_ESCALATION = "council.escalation"
    """Eskalacja do człowieka."""
    COUNCIL_HEARTBEAT = "council.heartbeat"
    """Heartbeat Orkiestratora (co 30s)."""

    # ══════════════════════════════════════════════════════════════════
    # AgentDataExtraction — Ekstrakcja danych
    # ══════════════════════════════════════════════════════════════════
    INVOICE_RECEIVED = "invoice.received"
    """Nowa faktura do ekstrakcji danych (od Orkiestratora)."""
    INVOICE_EXTRACTED = "invoice.extracted"
    """Dane po ekstrakcji (zwrot do Orkiestratora)."""
    INVOICE_FAILED = "invoice.failed"
    """Błąd ekstrakcji faktury."""

    # ══════════════════════════════════════════════════════════════════
    # AgentAnalytics — Analityka finansowa
    # ══════════════════════════════════════════════════════════════════
    ANALYTICS_QUERY = "analytics.query"
    """Zapytanie analityczne od Orkiestratora."""
    ANALYTICS_RESULT = "analytics.result"
    """Wynik analizy (zwrot do Orkiestratora)."""
    ANALYTICS_ALERT = "analytics.alert"
    """Proaktywne powiadomienie o anomalii (np. daily brief)."""

    # ══════════════════════════════════════════════════════════════════
    # AgentQualityValidator — Walidator jakości
    # ══════════════════════════════════════════════════════════════════
    QUALITY_CHECK_REQUEST = "quality.check.request"
    """Prośba o walidację decyzji."""
    QUALITY_CHECK_RESULT = "quality.check.result"
    """Wynik walidacji."""

    # ══════════════════════════════════════════════════════════════════
    # AgentTaxEngine — Doradca podatkowy
    # ══════════════════════════════════════════════════════════════════
    TAX_CALCULATE = "tax.calculate"
    """Kalkulacja podatku (VAT/PIT/CIT)."""
    TAX_RESULT = "tax.result"
    """Wynik kalkulacji podatku."""
    TAX_DEADLINE = "tax.deadline"
    """Alert terminu podatkowego."""
    TAX_RULE_UPDATED = "tax.rule.updated"
    """Zmiana reguł podatkowych."""

    # ══════════════════════════════════════════════════════════════════
    # AgentCashManager — Zarządca płynności
    # ══════════════════════════════════════════════════════════════════
    CASH_FORECAST = "cash.forecast"
    """Prognoza przepływów pieniężnych."""
    CASH_PAYMENT_SUGGEST = "cash.payment.suggest"
    """Sugestia płatności (optymalizacja)."""
    CASH_PAYMENT_EXECUTED = "cash.payment.executed"
    """Potwierdzenie wykonania płatności."""

    # ══════════════════════════════════════════════════════════════════
    # AgentCompliance — Strażnik regulacyjny
    # ══════════════════════════════════════════════════════════════════
    COMPLIANCE_CHECK = "compliance.check"
    """Sprawdzenie zgodności regulacyjnej."""
    COMPLIANCE_REPORT = "compliance.report"
    """Raport compliance."""
    COMPLIANCE_REGULATION_UPDATE = "compliance.regulation.update"
    """Aktualizacja przepisów."""

    # ══════════════════════════════════════════════════════════════════
    # AgentKSeF — Łącznik z Ministerstwem Finansów
    # ══════════════════════════════════════════════════════════════════
    KSEF_SEND = "ksef.send"
    """Wyślij fakturę do KSeF."""
    KSEF_STATUS = "ksef.status"
    """Status wysłanej faktury."""
    KSEF_RECEIVE = "ksef.receive"
    """Odbierz fakturę z KSeF."""

    # ══════════════════════════════════════════════════════════════════
    # AgentVendorIntelligence — Wywiad gospodarczy
    # ══════════════════════════════════════════════════════════════════
    VENDOR_CHECK = "vendor.check"
    """Sprawdź kontrahenta (Biała Lista, GUS, KRD)."""
    VENDOR_RESULT = "vendor.result"
    """Wynik weryfikacji kontrahenta."""

    # ══════════════════════════════════════════════════════════════════
    # AgentFixedAssets — Zarządca środków trwałych
    # ══════════════════════════════════════════════════════════════════
    ASSETS_CLASSIFY = "assets.classify"
    """Klasyfikacja środka trwałego."""
    ASSETS_DEPRECIATE = "assets.depreciate"
    """Wynik amortyzacji."""
    ASSETS_RESULT = "assets.result"
    """Wynik klasyfikacji."""

    # ══════════════════════════════════════════════════════════════════
    # System — System-wide topics
    # ══════════════════════════════════════════════════════════════════
    SYSTEM_HEARTBEAT = "system.heartbeat"
    """Heartbeat agenta (co 30s)."""
    SYSTEM_HEALTH = "system.health"
    """Health check systemu."""
    SYSTEM_ERROR = "system.error"
    """Błąd agenta / systemu."""
    SYSTEM_CONFIG_UPDATED = "system.config.updated"
    """Zmiana konfiguracji systemu."""


# ── Strumienie JetStream ────────────────────────────────────────────────

# Mapa: stream_name → (topics, retention, max_delivery)
JETSTREAM_STREAMS: dict[str, tuple[list[str], str, int]] = {
    "invoices": (
        [
            AgentTopic.INVOICE_RECEIVED,
            AgentTopic.INVOICE_EXTRACTED,
            AgentTopic.INVOICE_FAILED,
        ],
        "7d",
        3,
    ),
    "council": (
        [t for t in AgentTopic if t.startswith("council.")],
        "90d",
        5,
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
    "tax": (
        [t for t in AgentTopic if t.startswith("tax.")],
        "30d",
        3,
    ),
    "cash": (
        [t for t in AgentTopic if t.startswith("cash.")],
        "30d",
        3,
    ),
    "compliance": (
        [t for t in AgentTopic if t.startswith("compliance.")],
        "90d",
        5,
    ),
    "ksef": (
        [t for t in AgentTopic if t.startswith("ksef.")],
        "90d",
        5,
    ),
    "vendor": (
        [t for t in AgentTopic if t.startswith("vendor.")],
        "30d",
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
"""Konfiguracja strumieni JetStream dla agentów.

Format: {stream_name: (topics_list, retention_period, max_delivery)}
"""
