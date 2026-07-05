"""msgspec Struct definitions for agent communication.

Zgodnie z blueprintem aa3fvcx.txt:
- Wszystkie struktury danych to msgspec.Struct (ultraszybka serializacja)
- Komunikacja przez NATS JetStream w formacie JSON/MessagePack
- Zero Pydantic — lżejsze i szybsze
"""

from __future__ import annotations

from typing import Any

from msgspec import Struct, field


# ── AgentContext — kontekst wykonania ─────────────────────────────────────


class AgentContext(Struct, kw_only=True):
    """Kontekst wykonania dla agenta.

    Przekazywany przez NATS w nagłówkach wiadomości.
    """

    task_id: str
    """Unikalne ID zadania (blake2b hash z broker.py)."""
    source_agent: str
    """Nazwa agenta źródłowego."""
    target_agent: str
    """Nazwa agenta docelowego."""
    correlation_id: str = ""
    """ID korelacji dla śledzenia przepływu."""
    timestamp: str = ""
    """ISO timestamp utworzenia."""
    tenant_id: str = ""
    """ID tenant (dla multi-tenancy)."""
    retry_count: int = 0
    """Liczba ponowień."""
    priority: int = 5
    """Priorytet (1-10, 1=najwyższy)."""


# ── AgentMessage — podstawowa jednostka komunikacji ──────────────────────


class AgentMessage(Struct, kw_only=True):
    """Podstawowa wiadomość między agentami przez NATS JetStream."""

    context: AgentContext
    """Kontekst wykonania."""
    payload: dict[str, Any] = field(default_factory=dict)
    """Payload zadania (zależny od typu)."""
    metadata: dict[str, Any] = field(default_factory=dict)
    """Dodatkowe metadane (np. wersja modelu, czas wykonania)."""


# ── AgentCommand — polecenie wykonania ───────────────────────────────────


class AgentCommand(Struct, kw_only=True):
    """Polecenie dla agenta do wykonania."""

    command: str
    """Nazwa komendy (np. 'extract_invoice', 'run_query')."""
    params: dict[str, Any] = field(default_factory=dict)
    """Parametry komendy."""
    context: AgentContext
    """Kontekst wykonania."""


# ── DecisionVerdict — werdykt decyzyjny ─────────────────────────────────


class DecisionVerdict(Struct, kw_only=True):
    """Werdykt decyzyjny dla faktury.

    Zgodnie z blueprintem:
    - Zielony (Trust Score >= 0.92): AUTO_POST
    - Żółty (0.75 <= Trust Score < 0.92): REVIEW
    - Czerwony (Trust Score < 0.75): BLOCK
    """

    status: str
    """Status decyzji: AUTO_POST, REVIEW, BLOCK, ESCALATED."""
    trust_score: float = 0.0
    """Trust Score (0.0 - 1.0)."""
    reason: str = ""
    """Przyczyna decyzji."""
    details: dict[str, Any] = field(default_factory=dict)
    """Szczegóły decyzji."""
    verified_by: list[str] = field(default_factory=list)
    """Lista agentów, które zweryfikowały decyzję."""


class TrustScore(Struct, kw_only=True):
    """Trust Score dla decyzji - zgodnie z blueprintem aa3fvcx.txt.

    Składa się z 4 komponentów:
    - ai_confidence: Zaufanie modelu do swojej decyzji
    - vendor_reliability: Wiarygodność kontrahenta
    - data_consistency: Spójność danych
    - context_trust: Zaufanie kontekstowe
    """

    ai_confidence: float = 0.0
    """Zaufanie modelu (0.0 - 1.0)."""
    vendor_reliability: float = 0.0
    """Wiarygodność kontrahenta (0.0 - 1.0)."""
    data_consistency: float = 0.0
    """Spójność danych (0.0 - 1.0)."""
    context_trust: float = 0.0
    """Zaufanie kontekstowe (0.0 - 1.0)."""
    overall: float = 0.0
    """Trust Score całkowity = średnia ważona."""


class AgentDecision(Struct, kw_only=True):
    """Pełna decyzja agenta z uzasadnieniem."""

    decision_id: str
    """Unikalne ID decyzji."""
    agent_name: str
    """Nazwa agenta podejmującego decyzję."""
    verdict: DecisionVerdict
    """Werdykt decyzyjny."""
    trust_score: TrustScore | None = None
    """Trust Score (jeśli dostępny)."""
    explanation: str = ""
    """Wyjaśnienie decyzji w języku naturalnym."""
    supporting_data: dict[str, Any] = field(default_factory=dict)
    """Dane wspierające decyzję."""
    created_at: str = ""
    """ISO timestamp."""


# ── AgentDataExtraction ──────────────────────────────────────────────────


class DataExtractionRequest(Struct, kw_only=True):
    """Żądanie ekstrakcji danych z dokumentu."""

    invoice_id: str
    """ID faktury."""
    file_path: str
    """Ścieżka do pliku."""
    file_type: str = ""
    """Typ pliku (pdf, jpg, png, xml)."""
    tenant_id: str = ""
    """ID tenant."""
    options: dict[str, Any] = field(default_factory=dict)
    """Opcje ekstrakcji (np. języki OCR, użyte silniki)."""


class DataExtractionResult(Struct, kw_only=True):
    """Wynik ekstrakcji danych z dokumentu."""

    invoice_id: str
    """ID faktury."""
    success: bool
    """Czy ekstrakcja się powiodła."""
    extracted_data: dict[str, Any] = field(default_factory=dict)
    """Wyekstrahowane dane (numer, data, NIP, kwoty, itd.)."""
    ocr_text: str = ""
    """Pełny tekst OCR."""
    confidence: float = 0.0
    """Ogólna pewność ekstrakcji (0.0 - 1.0)."""
    engine_results: dict[str, Any] = field(default_factory=dict)
    """Wyniki per silnik OCR."""
    document_type: str = ""
    """Typ dokumentu (INVOICE, RECEIPT, NOTE, OTHER)."""
    validation_issues: list[str] = field(default_factory=list)
    """Problemy walidacji (np. NIP nie przechodzi sumy kontrolnej)."""
    error: str = ""
    """Błąd (jeśli niepowodzenie)."""


# ── AgentAnalytics ────────────────────────────────────────────────────────


class AnalyticsQuery(Struct, kw_only=True):
    """Zapytanie analityczne do AgentAnalytics."""

    query_id: str
    """ID zapytania."""
    query_type: str
    """Typ zapytania: sql, trend, anomaly, forecast, custom."""
    natural_language: str = ""
    """Pytanie w języku naturalnym."""
    sql_query: str = ""
    """SQL do wykonania (jeśli znany)."""
    params: dict[str, Any] = field(default_factory=dict)
    """Parametry zapytania."""
    time_range: dict[str, str] = field(default_factory=dict)
    """Zakres czasowy (from, to)."""
    context: dict[str, Any] = field(default_factory=dict)
    """Dodatkowy kontekst."""


class AnalyticsResult(Struct, kw_only=True):
    """Wynik analizy."""

    query_id: str
    """ID zapytania."""
    success: bool
    """Czy analiza się powiodła."""
    summary: str = ""
    """Podsumowanie w języku naturalnym."""
    data: list[dict[str, Any]] = field(default_factory=list)
    """Dane wynikowe."""
    anomalies: list[dict[str, Any]] = field(default_factory=list)
    """Wykryte anomalie."""
    sql_executed: str = ""
    """SQL który został wykonany."""
    model_used: str = ""
    """Model użyty do analizy."""
    error: str = ""
    """Błąd (jeśli niepowodzenie)."""


# ── AgentQualityValidator ────────────────────────────────────────────────


class QualityCheckRequest(Struct, kw_only=True):
    """Żądanie walidacji jakości decyzji."""

    decision_id: str
    """ID decyzji do walidacji."""
    proposed_decision: dict[str, Any]
    """Proponowana decyzja."""
    invoice_data: dict[str, Any] = field(default_factory=dict)
    """Dane faktury."""
    context: dict[str, Any] = field(default_factory=dict)
    """Dodatkowy kontekst."""
    checks: list[str] = field(default_factory=list)
    """Lista wymaganych kontroli (tax, fraud, esg, forecast)."""


class QualityCheckResult(Struct, kw_only=True):
    """Wynik walidacji jakości."""

    decision_id: str
    """ID decyzji."""
    overall_verdict: str
    """Ogólny werdykt: OK, WARNING, ERROR."""
    overall_risk_score: float = 0.0
    """Ogólny risk score (0.0 - 1.0)."""
    tax_verdict: dict[str, Any] = field(default_factory=dict)
    """Werdykt strażnika podatkowego."""
    fraud_verdict: dict[str, Any] = field(default_factory=dict)
    """Werdykt detektora oszustw."""
    esg_verdict: dict[str, Any] = field(default_factory=dict)
    """Werdykt analityka ryzyka."""
    forecast: dict[str, Any] = field(default_factory=dict)
    """Prognoza płynności."""
    recommendations: list[str] = field(default_factory=list)
    """Rekomendacje."""
    models_used: list[str] = field(default_factory=list)
    """Modele użyte do walidacji."""
    error: str = ""
    """Błąd (jeśli niepowodzenie)."""


# ── Helpers ──────────────────────────────────────────────────────────────


def make_context(
    task_id: str,
    source: str,
    target: str,
    **kwargs: Any,
) -> AgentContext:
    """Utwórz AgentContext z domyślnymi wartościami."""
    import pendulum

    return AgentContext(
        task_id=task_id,
        source_agent=source,
        target_agent=target,
        timestamp=pendulum.now("UTC").isoformat(),
        **kwargs,
    )
