from __future__ import annotations

from decimal import Decimal

import pendulum

import msgspec

# -- msgspec Structs --


class InvoiceCreate(msgspec.Struct, kw_only=True):
    """Dane wymagane przy ręcznym tworzeniu lub uploadzie faktury."""

    number: str
    contractor_nip: str
    file_path: str = ""
    amount_net: Decimal = Decimal("0.0")
    amount_gross: Decimal = Decimal("0.0")
    currency: str = "PLN"
    issue_date: str = ""


def _validate_nip(nip: str) -> str:
    """Walidacja NIP: 10 cyfr + suma kontrolna.
    Zwraca znormalizowany NIP (tylko cyfry) lub rzuca ValueError."""
    normalized = "".join(ch for ch in str(nip) if ch.isdigit())
    if len(normalized) != 10:
        raise ValueError("NIP musi składać się z 10 cyfr.")

    weights = (6, 5, 7, 2, 3, 4, 5, 6, 7)
    checksum = sum(int(d) * w for d, w in zip(normalized[:9], weights)) % 11
    if checksum == 10 or checksum != int(normalized[9]):
        raise ValueError("Nieprawidłowy NIP (błąd sumy kontrolnej).")

    return normalized


def validate_invoice_create(payload: InvoiceCreate) -> None:
    if payload.amount_net < 0:
        raise ValueError("amount_net cannot be negative")
    if payload.amount_gross < 0:
        raise ValueError("amount_gross cannot be negative")
    if not payload.currency or len(payload.currency.strip()) != 3:
        raise ValueError("currency must be a 3-letter code")
    # Walidacja NIP przy tworzeniu faktury
    if payload.contractor_nip:
        try:
            _validate_nip(payload.contractor_nip)
        except ValueError as e:
            raise ValueError(f"contractor_nip validation failed: {e}")


class InvoiceResponse(msgspec.Struct, kw_only=True):
    """Struktura zwracana do frontendu."""

    id: str
    number: str | None
    contractor_nip: str | None = None
    file_path: str | None = None
    issue_date: str | None = None
    amount_net: Decimal
    amount_gross: Decimal
    currency: str
    status: str  # NEW, PROCESSING, APPROVED
    retry_count: int = 0
    processing_status: str | None = None
    created_at: pendulum.DateTime
    updated_at: pendulum.DateTime | None = None
    version_id: int = 1  # Optimistic locking (Rozwiązanie 23)


class AnalyticsQuery(msgspec.Struct, kw_only=True):
    start_date: str
    end_date: str
    dimension: str = "monthly"
    report_currency: str = "PLN"


class VatSummary(msgspec.Struct, kw_only=True):
    """Zagregowane dane analityczne z DuckDB."""

    month: str
    total_net: Decimal
    total_gross: Decimal
    currency: str


# -- API response/request structs --


class TaskResponse(msgspec.Struct, kw_only=True):
    task_id: str
    status: str
    message: str


class LegacyInvoiceResponse(msgspec.Struct, kw_only=True):
    id: str
    number: str | None
    contractor_nip: str | None
    amount_net: float | None
    amount_gross: float | None
    currency: str | None
    status: str
    created_at: pendulum.DateTime
    updated_at: pendulum.DateTime
    version_id: int = 1  # Optimistic locking (Rozwiązanie 23)


class DashboardSummaryResponse(msgspec.Struct, kw_only=True):
    total_net: float
    total_gross: float
    total_documents: int


class InvoiceUploadResponse(msgspec.Struct, kw_only=True):
    """Response structure for invoice file upload.

    Returned after a successful file upload with content-addressable storage.
    """

    filename: str
    status: str
    size_bytes: int
    file_hash: str
    file_path: str


class InvoiceUploadResponseLarge(InvoiceUploadResponse):
    """Response structure for large attachment upload.

    Extends ``InvoiceUploadResponse`` with a ``kind`` field.
    """

    kind: str = "large_attachment"


class InvoiceListResponse(msgspec.Struct, kw_only=True):
    """Paginated list response for invoices.

    ``items`` to lista ``InvoiceResponse``, ``next_cursor`` to token
    dla następnej strony, ``has_more`` wskazuje czy istnieją kolejne strony.
    """

    items: list[InvoiceResponse]
    next_cursor: str | None = None
    has_more: bool = False
    limit: int = 50


class TriageItem(msgspec.Struct, kw_only=True):
    invoice_id: str
    image_path: str
    extracted_data: dict[str, object]
    bounding_boxes: dict[str, object]
    confidence_score: float
    reason_for_triage: str


class TriageResolutionRequest(msgspec.Struct, kw_only=True):
    corrected_data: dict[str, object]
    action: str
    expected_version: int | None = None  # Optimistic locking (Rozwiązanie 23)


class TriageResolutionResponse(msgspec.Struct, kw_only=True):
    invoice_id: str
    status: str
    message: str


class SagaTransitionRequest(msgspec.Struct, kw_only=True):
    new_state: str
    expected_current_state: str | None = None
    payload: dict[str, object] = msgspec.field(default_factory=dict)


class SagaStateResponse(msgspec.Struct, kw_only=True):
    status: str
    saga_id: str
    current_state: str
    updated_at: str
    payload: dict[str, object]


# ═══════════════════════════════════════════════════════════════════════════
# Admin API Response Structs
# ═══════════════════════════════════════════════════════════════════════════


class StatusResponse(msgspec.Struct, kw_only=True):
    """Generic status+message response."""

    status: str
    message: str


class IdResponse(msgspec.Struct, kw_only=True):
    """Response with status + rule_id."""

    status: str
    rule_id: str


class ActionResponse(msgspec.Struct, kw_only=True):
    """Response with status + id + action."""

    status: str
    rule_id: str
    action: str


class RetryAllResponse(msgspec.Struct, kw_only=True):
    """Response for bulk retry."""

    status: str
    retried: int


class ChangeRoleResponse(msgspec.Struct, kw_only=True):
    """Response for role change."""

    status: str
    message: str
    user_id: str
    old_role: str
    new_role: str


class RuleListResponse(msgspec.Struct, kw_only=True):
    """Generic rule list response (replaces FailedTaskItem/FailedTaskListResponse/RiskThresholdRuleItem/PaginatedRuleListResponse)."""

    rules: list[dict]
    total: int
    limit: int = 50
    offset: int = 0


class HealthResponse(msgspec.Struct, kw_only=True):
    """System health check response."""

    status: str
    timestamp: str
    database: str | None = None
    failed_tasks_unresolved: int | None = None


class ReplayDecisionResponse(msgspec.Struct, kw_only=True):
    """Replay decision result."""

    transaction_id: str
    match: bool
    original_verdict: str
    replayed_verdict: str
    differences: list[str]
    error: str | None = None


class ReplayBatchItem(msgspec.Struct, kw_only=True):
    """Single replay batch result item."""

    transaction_id: str
    match: bool
    error: str | None = None
    differences: list[str]


class ReplayBatchResponse(msgspec.Struct, kw_only=True):
    """Batch replay results."""

    total: int
    matches: int
    mismatches: int
    results: list[ReplayBatchItem]


class IntegrityVerifyResponse(msgspec.Struct, kw_only=True):
    """Integrity verification result."""

    status: str
    total_records: int
    verified_at: str
    violations: list[dict]
    violation_id: str | None = None
    system_locked: bool = False
    checkpoint: dict | None = None


class FallbackListResponse(msgspec.Struct, kw_only=True):
    """Fallback events list (replaces FallbackEventItem)."""

    events: list[dict]
    total: int
    pending: int


class HotReloadHealthResponse(msgspec.Struct, kw_only=True):
    """Hot-reload listener health."""

    status: str
    nats_url: str
    subscriptions: list[dict]
    events_total: int
    events_per_subject: dict[str, int]
    last_event_at: str | None = None
    uptime_seconds: float = 0.0
    message: str = ""


class RuleChangelogResponse(msgspec.Struct, kw_only=True):
    """Rule change log."""

    changes: list[dict]
    total: int
    limit: int = 50
    offset: int = 0


# ═══════════════════════════════════════════════════════════════════════════
# Auth API Response Structs
# ═══════════════════════════════════════════════════════════════════════════


class RegisterResponse(msgspec.Struct, kw_only=True):
    """Registration response."""

    status: str
    message: str
    user_id: str


class LoginResponse(msgspec.Struct, kw_only=True):
    """Login response with tokens."""

    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int = 3600
    refresh_token_expires_in_days: int = 7


class LogoutResponse(msgspec.Struct, kw_only=True):
    """Logout response."""

    status: str
    message: str


class ConfirmEmailResponse(msgspec.Struct, kw_only=True):
    """Email confirmation response."""

    status: str
    message: str


class PasswordResetResponse(msgspec.Struct, kw_only=True):
    """Password reset email sent response."""

    status: str
    message: str


class PasswordResetConfirmResponse(msgspec.Struct, kw_only=True):
    """Password reset confirm response."""

    status: str
    message: str


class ChangePasswordResponse(msgspec.Struct, kw_only=True):
    """Password change response."""

    status: str
    message: str


class CsrfTokenResponse(msgspec.Struct, kw_only=True):
    """CSRF token response."""

    csrf_token: str


class UserProfileResponse(msgspec.Struct, kw_only=True):
    """Current user profile."""

    id: str
    username: str
    email: str | None = None
    full_name: str | None = None
    role: str = "viewer"
    is_active: bool = True
    is_verified: bool = False
    must_change_password: bool = False
    last_login: str | None = None
    created_at: str


# ═══════════════════════════════════════════════════════════════════════════
# Other API Response Structs
# ═══════════════════════════════════════════════════════════════════════════


class ExportStatusResponse(msgspec.Struct, kw_only=True):
    """Export status."""

    export_id: str
    status: str
    format: str
    file_url: str


class ExportDownloadResponse(msgspec.Struct, kw_only=True):
    """Export download response."""

    message: str
    format: str


class FinOpsResponse(msgspec.Struct, kw_only=True):
    """FinOps cost per invoice."""

    hourly_cost_usd: float
    invoice_count: int
    cost_per_invoice_usd: float
    cpu_cores: float
    ram_gb: float


class I18nStatusResponse(msgspec.Struct, kw_only=True):
    """I18n status."""

    api_languages: list[str]
    prompt_languages: list[str]
    api_locale_dir: str
    prompt_dir: str


class PiiScanResponse(msgspec.Struct, kw_only=True):
    """PII scan results."""

    status: str
    findings: dict[str, int]
    total_matches: int
    dpo_notified: bool


class SecurityPostureResponse(msgspec.Struct, kw_only=True):
    """Security posture summary."""

    summary_available: bool
    zap_baseline_available: bool
    zap_full_available: bool
    scan_summary: dict | None = None


class LocustSummaryResponse(msgspec.Struct, kw_only=True):

    Zgodnie z aa3fvcx.txt: locust zastępuje k6.
    Zawiera pełne metryki wydajnościowe z testów locust:
      - p95, p99 latencja
      - RPS (requests per second)
      - Error rate (fail_ratio)
      - Liczba żądań
      - Liczba błędów
      - Status summary_available
      - Raw payload z locust stats
    """

    status: str
    summary_available: bool = True
    p95_ms: float | None = None
    p99_ms: float | None = None
    check_failures: float | None = None
    avg_response_time_ms: float | None = None
    current_rps: float | None = None
    total_requests: int | None = None
    total_failures: int | None = None
    raw: dict | None = None


class StatsProcessingResponse(msgspec.Struct, kw_only=True):
    """Processing statistics."""

    total_processed: int
    avg_processing_time_ms: int
    success_rate: float
    error_count: int


class WorkerStatusResponse(msgspec.Struct, kw_only=True):
    """Worker status."""

    status: str
    uptime_seconds: int = 0
    ram_mb: float = 0.0
    cpu_percent: float = 0.0
    active_tasks: int = 0
    max_concurrent: int = 5
    pid: int = 0
    python_version: str = ""
    error: str | None = None


class CircuitBreakerStatusResponse(msgspec.Struct, kw_only=True):
    """Circuit breaker status."""

    provider: str = "stamina"
    status: str = "active"
    details: str = ""
    note: str = ""


class TelemetryFallbackStatusResponse(msgspec.Struct, kw_only=True):
    """Telemetry fallback status."""

    buffer_file: str
    buffer_exists: bool
    queued_spans: int
    duckdb_path: str


class AutopilotActionResponse(msgspec.Struct, kw_only=True):
    """Autopilot accept/reject response."""

    result: str
    invoice_id: str
    action: str


class AutopilotEvalTriggerResponse(msgspec.Struct, kw_only=True):
    """Autopilot trigger evaluation response."""

    result: str
    invoice_id: str
    message: str


class PartnerClientItem(msgspec.Struct, kw_only=True):
    """Partner client summary."""

    id: str
    name: str
    nip: str
    invoice_count: int
    status: str
    last_activity: str


class PartnerClientListResponse(msgspec.Struct, kw_only=True):
    """Partner client list with cursor pagination."""

    items: list[PartnerClientItem]
    next_cursor: str | None = None
    has_more: bool = False


class PartnerInvoiceItem(msgspec.Struct, kw_only=True):
    """Partner client invoice summary."""

    invoice_id: str
    number: str
    contractor: str
    amount_gross: float = 0.0
    currency: str = "PLN"
    status: str = ""
    issue_date: str = ""
    created_at: str = ""
    confidence: float = 0.0


class SaveDraftResponse(msgspec.Struct, kw_only=True):
    """Response for saving a UI draft."""

    status: str
    draft_key: str


class RuleSetsResponse(msgspec.Struct, kw_only=True):
    """Available tax simulation rule sets."""

    rule_sets: list[str]
