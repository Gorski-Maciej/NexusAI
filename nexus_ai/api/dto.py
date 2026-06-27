"""
Data Transfer Objects (DTOs) for Litestar API endpoints — Phase 2.

Używa Litestar ``MsgspecDTO`` + ``DTOConfig`` do automatycznej:
  - Walidacji danych wejściowych
  - Serializacji odpowiedzi
  - Generowania schematu OpenAPI z metadanymi i ``operation_id``

Zgodnie z Fazą 2 audytu: każdy endpoint ma przypisane DTO wejściowe
(``dto=...``) i wyjściowe (``return_dto=...``) oraz tagi OpenAPI
(``tags=[...]``) i ``operation_id`` dla jednoznacznej identyfikacji.

OpenAPI Tags używane w projekcie:
  - ``Auth`` — rejestracja, logowanie, refresh, reset hasła
  - ``Invoices`` — upload faktur, tworzenie
  - ``Admin`` — zarządzanie użytkownikami, regułami, DLQ
  - ``Triage`` — przegląd i korekta faktur
  - ``Tax`` — kalkulacje podatkowe, symulacje
  - ``Dashboard`` — dashboard, briefing
  - ``Analytics`` — analityka, raporty
  - ``System`` — health, integrity, saga, export
  - ``Tasks`` — status zadań, anulowanie
  - ``Metrics`` — Prometheus metrics
  - ``Audit`` — audyt decyzji podatkowych
  - ``Files`` — zarządzanie plikami

Usage:
    @post("/path", dto=RegisterDTO, return_dto=AuthResponseDTO,
          tags=["Auth"], operation_id="registerUser")
    async def register(self, data: RegisterRequest, ...) -> ...:
        ...
"""

from __future__ import annotations

from litestar.dto import DTOConfig, MsgspecDTO

from nexus_ai.api.schemas import (
    ActionResponse,
    AnalyticsQuery,
    AutopilotActionResponse,
    AutopilotEvalTriggerResponse,
    ChangePasswordResponse,
    ChangeRoleResponse,
    CircuitBreakerStatusResponse,
    ConfirmEmailResponse,
    CsrfTokenResponse,
    DashboardSummaryResponse,
    ExportDownloadResponse,
    ExportStatusResponse,
    FailedTaskListResponse,
    FallbackListResponse,
    FinOpsResponse,
    HealthResponse,
    HotReloadHealthResponse,
    I18nStatusResponse,
    IdResponse,
    IntegrityVerifyResponse,
    InvoiceCreate,
    InvoiceListResponse,
    InvoiceResponse,
    LocustSummaryResponse,
    LoginResponse,
    LogoutResponse,
    PaginatedRuleListResponse,
    PartnerClientListResponse,
    PartnerInvoiceItem,
    PasswordResetConfirmResponse,
    PasswordResetResponse,
    PiiScanResponse,
    ReplayBatchResponse,
    ReplayDecisionResponse,
    RegisterResponse,
    RetryAllResponse,
    RuleChangelogResponse,
    RuleSetsResponse,
    RuleListResponse,
    SagaStateResponse,
    SagaTransitionRequest,
    SaveDraftResponse,
    SecurityPostureResponse,
    StatsProcessingResponse,
    StatusResponse,
    TaskResponse,
    TelemetryFallbackStatusResponse,
    TriageItem,
    TriageResolutionRequest,
    TriageResolutionResponse,
    UserProfileResponse,
    VatSummary,
    WorkerStatusResponse,
)
from nexus_ai.api.routes.admin import ChangeRoleRequest, RiskThresholdCreate
from nexus_ai.api.routes.auth import (
    ChangePasswordRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordConfirmRequest,
    ResetPasswordRequest,
)
from nexus_ai.api.routes.tax_policy import SimulateRequest


# ── OpenAPI Tag Constants ───────────────────────────────────────────────

TAG_AUTH = "Auth"
TAG_INVOICES = "Invoices"
TAG_ADMIN = "Admin"
TAG_TRIAGE = "Triage"
TAG_TAX = "Tax"
TAG_DASHBOARD = "Dashboard"
TAG_ANALYTICS = "Analytics"
TAG_SYSTEM = "System"
TAG_TASKS = "Tasks"
TAG_METRICS = "Metrics"
TAG_AUDIT = "Audit"
TAG_FILES = "Files"
TAG_HEALTH = "Health"
TAG_FINANCE = "Finance"
TAG_I18N = "I18N"
TAG_SECURITY = "Security"
TAG_PRIVACY = "Privacy"
TAG_RISK = "Risk"
TAG_EVENTS = "Events"
TAG_UI_STATE = "UI State"


# ── Base DTO ────────────────────────────────────────────────────────────


class NexusDTO(MsgspecDTO):
    """Bazowa klasa DTO dla wszystkich endpointów NexusAI.

    Fazа 2: Dynamiczne DTO z msgspec.
    - ``backend="msgspec"`` — jawny backend msgspec dla optymalnej wydajności
    - ``max_nested_depth=5`` — ograniczenie zagnieżdżenia dla bezpieczeństwa
    - ``rename_fields`` — konwersja snake_case↔camelCase dla JSON API

    Automatycznie dodaje opisy pól do schematu OpenAPI.
    DTOConfig pozwala na precyzyjne kontrolowanie które pola są
    widoczne w request (client → server) i response (server → client).
    """

    config = DTOConfig(
        backend="msgspec",
        max_nested_depth=5,
    )


# ── Auth DTOs ───────────────────────────────────────────────────────────


class RegisterDTO(NexusDTO):
    """DTO dla POST /api/auth/register — walidacja rejestracji."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "full_name": "fullName",
        },
    )


class LoginDTO(NexusDTO):
    """DTO dla POST /api/auth/login."""

    pass


class RefreshDTO(NexusDTO):
    """DTO dla POST /api/auth/refresh (single-use rotation)."""

    pass


class PasswordResetDTO(NexusDTO):
    """DTO dla POST /api/auth/reset-password (email)."""

    pass


class PasswordResetConfirmDTO(NexusDTO):
    """DTO dla POST /api/auth/reset-password/confirm (nowe hasło)."""

    pass


class ChangePasswordDTO(NexusDTO):
    """DTO dla POST /api/auth/change-password."""

    pass


class AuthResponseDTO(NexusDTO):
    """DTO dla odpowiedzi auth — ukrywa wrażliwe pola."""

    config = DTOConfig(
        backend="msgspec",
        exclude={"password", "password_hash", "token"},
    )


# ── Invoice DTOs ────────────────────────────────────────────────────────


class InvoiceCreateDTO(NexusDTO):
    """DTO dla POST /invoices (ręczne tworzenie faktury).

    Automatyczna walidacja typów ``InvoiceCreate`` (msgspec.Struct).
    Konwersja camelCase w JSON → snake_case w Pythonie: ``amountNet → amount_net``.
    """

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "amount_net": "amountNet",
            "amount_gross": "amountGross",
            "file_path": "filePath",
            "issue_date": "issueDate",
            "contractor_nip": "contractorNip",
        },
    )


class InvoiceResponseDTO(NexusDTO):
    """DTO dla odpowiedzi z danymi faktury.

    Konwersja snake_case → camelCase w JSON:
      - ``amount_net`` → ``amountNet``
      - ``contractor_nip`` → ``contractorNip``
      - ``created_at`` → ``createdAt``
      - ``updated_at`` → ``updatedAt``
      - ``version_id`` → ``versionId``
      - ``processing_status`` → ``processingStatus``
      - ``retry_count`` → ``retryCount``

    ``amount_net`` i ``amount_gross`` to ``Money`` — serializowane przez
    ``AppConfig.type_encoders`` (z ``litestar.types``).
    """

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "amount_net": "amountNet",
            "amount_gross": "amountGross",
            "contractor_nip": "contractorNip",
            "issue_date": "issueDate",
            "file_path": "filePath",
            "created_at": "createdAt",
            "updated_at": "updatedAt",
            "version_id": "versionId",
            "processing_status": "processingStatus",
            "retry_count": "retryCount",
        },
    )


class InvoiceListResponseDTO(NexusDTO):
    """DTO dla paginowanej listy faktur.

    ``next_cursor`` → ``nextCursor`` (camelCase).
    ``has_more`` → ``hasMore``.
    ``items`` to lista ``InvoiceResponse``.
    """

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "next_cursor": "nextCursor",
            "has_more": "hasMore",
        },
    )


class InvoiceUploadDTO(NexusDTO):
    """DTO dla uploadu pliku faktury (multi-part).

    Automatyczna walidacja typu ``UploadFile``.
    Obsługuje ``RequestEncodingType.MULTI_PART``.
    """

    pass


class InvoiceUploadResponseDTO(NexusDTO):
    """DTO dla odpowiedzi z uploadu faktury.

    ``file_hash`` → ``fileHash``, ``size_bytes`` → ``sizeBytes``,
    ``file_path`` → ``filePath``, ``task_id`` → ``taskId.
    """

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "file_hash": "fileHash",
            "file_path": "filePath",
            "size_bytes": "sizeBytes",
            "filename": "fileName",
        },
    )


class TaskResponseDTO(NexusDTO):
    """DTO dla odpowiedzi z task_id (kolejkowanie zadań)."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"task_id": "taskId"},
    )


# ── Admin DTOs ──────────────────────────────────────────────────────────


class ChangeRoleDTO(NexusDTO):
    """DTO dla PUT /api/admin/users/{id}/role."""

    pass


class RiskThresholdDTO(NexusDTO):
    """DTO dla POST /api/admin/risk-thresholds."""

    pass


# ── Tax DTOs ────────────────────────────────────────────────────────────


class TaxMathRequestDTO(NexusDTO):
    """DTO dla POST /api/v2/tax/calculate-money."""

    pass


class TaxMathResponseDTO(NexusDTO):
    """DTO dla odpowiedzi kalkulacji podatkowej."""

    pass


class TaxPolicySimulateDTO(NexusDTO):
    """DTO dla POST /api/v2/tax-policy/simulate."""

    pass


# ── Triage DTOs ─────────────────────────────────────────────────────────


class TriageItemDTO(NexusDTO):
    """DTO dla listy faktur oczekujących na decyzję."""

    pass


class TriageResolutionDTO(NexusDTO):
    """DTO dla POST /api/triage/resolve/{id}."""

    pass


class TriageResponseDTO(NexusDTO):
    """DTO dla odpowiedzi po rozwiązaniu triage."""

    pass


# ── Saga DTOs ───────────────────────────────────────────────────────────


class SagaTransitionDTO(NexusDTO):
    """DTO dla POST /api/system/saga/{id}/transition."""

    pass


class SagaStateDTO(NexusDTO):
    """DTO dla odpowiedzi stanu sagi."""

    pass


# ── Dashboard DTOs ──────────────────────────────────────────────────────


class DashboardSummaryDTO(NexusDTO):
    """DTO dla odpowiedzi dashboardu — kwoty, liczba dokumentów."""

    pass


# ── Generic passthrough DTO ──────────────────────────────────────────


class GenericDictDTO(NexusDTO):
    """Generic passthrough DTO dla endpointów zwracających ``dict[str, Any]``.

    Używany jako ``return_dto=GenericDictDTO`` na endpointach które nie mają
    dedykowanego schematu wyjściowego. Generuje ``{"type": "object"}`` w OpenAPI.
    """

    pass


class GenericListDTO(NexusDTO):
    """Generic passthrough DTO dla endpointów zwracających ``list[dict]``."""

    pass


# ── Admin Response DTOs ─────────────────────────────────────────────────


class StatusResponseDTO(NexusDTO):
    """DTO dla prostych odpowiedzi status+message."""

    pass


class IdResponseDTO(NexusDTO):
    """DTO dla odpowiedzi z status+rule_id."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"rule_id": "ruleId"},
    )


class ActionResponseDTO(NexusDTO):
    """DTO dla odpowiedzi z status+rule_id+action."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"rule_id": "ruleId"},
    )


class RetryAllResponseDTO(NexusDTO):
    """DTO dla odpowiedzi bulk retry."""

    pass


class ChangeRoleResponseDTO(NexusDTO):
    """DTO dla odpowiedzi zmiany roli."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"user_id": "userId", "old_role": "oldRole", "new_role": "newRole"},
    )


class FailedTaskListDTO(NexusDTO):
    """DTO dla paginowanej listy failed tasks."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"failed_at": "failedAt", "created_at": "createdAt"},
    )


class RuleListResponseDTO(NexusDTO):
    """DTO dla listy reguł."""

    pass


class PaginatedRuleListDTO(NexusDTO):
    """DTO dla paginowanej listy reguł."""

    pass


class HealthResponseDTO(NexusDTO):
    """DTO dla odpowiedzi health check."""

    pass


class ReplayDecisionDTO(NexusDTO):
    """DTO dla odpowiedzi replay decyzji."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "transaction_id": "transactionId",
            "original_verdict": "originalVerdict",
            "replayed_verdict": "replayedVerdict",
        },
    )


class ReplayBatchDTO(NexusDTO):
    """DTO dla odpowiedzi batch replay."""

    pass


class IntegrityVerifyDTO(NexusDTO):
    """DTO dla odpowiedzi weryfikacji integralności."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "total_records": "totalRecords",
            "verified_at": "verifiedAt",
            "violation_id": "violationId",
            "system_locked": "systemLocked",
        },
    )


class FallbackListDTO(NexusDTO):
    """DTO dla listy fallback events."""

    pass


class HotReloadHealthDTO(NexusDTO):
    """DTO dla health hot-reload listenera."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "nats_url": "natsUrl",
            "events_total": "eventsTotal",
            "events_per_subject": "eventsPerSubject",
            "last_event_at": "lastEventAt",
            "uptime_seconds": "uptimeSeconds",
        },
    )


class RuleChangelogDTO(NexusDTO):
    """DTO dla logu zmian reguł."""

    pass


# ── Auth Response DTOs ───────────────────────────────────────────────


class RegisterResponseDTO(NexusDTO):
    """DTO dla odpowiedzi rejestracji."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"user_id": "userId"},
    )


class LoginResponseDTO(NexusDTO):
    """DTO dla odpowiedzi logowania z tokenami."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "access_token": "accessToken",
            "refresh_token": "refreshToken",
            "token_type": "tokenType",
            "expires_in": "expiresIn",
            "refresh_token_expires_in_days": "refreshTokenExpiresInDays",
        },
    )


class LogoutResponseDTO(NexusDTO):
    """DTO dla odpowiedzi wylogowania."""

    pass


class ConfirmEmailResponseDTO(NexusDTO):
    """DTO dla odpowiedzi potwierdzenia email."""

    pass


class PasswordResetResponseDTO(NexusDTO):
    """DTO dla odpowiedzi resetu hasła (email wysłany)."""

    pass


class PasswordResetConfirmResponseDTO(NexusDTO):
    """DTO dla odpowiedzi potwierdzenia resetu hasła."""

    pass


class ChangePasswordResponseDTO(NexusDTO):
    """DTO dla odpowiedzi zmiany hasła."""

    pass


class CsrfTokenResponseDTO(NexusDTO):
    """DTO dla odpowiedzi CSRF tokena."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"csrf_token": "csrfToken"},
    )


class UserProfileResponseDTO(NexusDTO):
    """DTO dla profilu użytkownika."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "user_id": "userId",
            "full_name": "fullName",
            "is_active": "isActive",
            "is_verified": "isVerified",
            "must_change_password": "mustChangePassword",
            "last_login": "lastLogin",
            "created_at": "createdAt",
        },
    )


# ── Other Response DTOs ───────────────────────────────────────────────


class ExportStatusDTO(NexusDTO):
    """DTO dla statusu eksportu."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"export_id": "exportId", "file_url": "fileUrl"},
    )


class ExportDownloadDTO(NexusDTO):
    """DTO dla odpowiedzi pobrania eksportu."""

    pass


class FinOpsDTO(NexusDTO):
    """DTO dla FinOps metryk."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "hourly_cost_usd": "hourlyCostUsd",
            "invoice_count": "invoiceCount",
            "cost_per_invoice_usd": "costPerInvoiceUsd",
            "cpu_cores": "cpuCores",
            "ram_gb": "ramGb",
        },
    )


class I18nStatusDTO(NexusDTO):
    """DTO dla statusu i18n."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "api_languages": "apiLanguages",
            "prompt_languages": "promptLanguages",
            "api_locale_dir": "apiLocaleDir",
            "prompt_dir": "promptDir",
        },
    )


class PiiScanDTO(NexusDTO):
    """DTO dla wyników skanowania PII."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "total_matches": "totalMatches",
            "dpo_notified": "dpoNotified",
        },
    )


class SecurityPostureDTO(NexusDTO):
    """DTO dla podsumowania security posture."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "summary_available": "summaryAvailable",
            "zap_baseline_available": "zapBaselineAvailable",
            "zap_full_available": "zapFullAvailable",
            "scan_summary": "scanSummary",
        },
    )


class LocustSummaryDTO(NexusDTO):
    """SUPERMOC: DTO dla podsumowania locust.

    Zgodnie z aa3fvcx.txt: locust zastępuje k6.
    Zawiera pełne metryki wydajnościowe z testów locust.
    Używa camelCase dla JSON API (summaryAvailable, p95Ms, itp.).
    """

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "summary_available": "summaryAvailable",
            "p95_ms": "p95Ms",
            "p99_ms": "p99Ms",
            "check_failures": "checkFailures",
            "avg_response_time_ms": "avgResponseTimeMs",
            "current_rps": "currentRps",
            "total_requests": "totalRequests",
            "total_failures": "totalFailures",
        },
    )


class StatsProcessingDTO(NexusDTO):
    """DTO dla statystyk przetwarzania."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "total_processed": "totalProcessed",
            "avg_processing_time_ms": "avgProcessingTimeMs",
            "success_rate": "successRate",
            "error_count": "errorCount",
        },
    )


class WorkerStatusDTO(NexusDTO):
    """DTO dla statusu workera."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "uptime_seconds": "uptimeSeconds",
            "ram_mb": "ramMb",
            "cpu_percent": "cpuPercent",
            "active_tasks": "activeTasks",
            "max_concurrent": "maxConcurrent",
            "python_version": "pythonVersion",
        },
    )


class CircuitBreakerStatusDTO(NexusDTO):
    """DTO dla statusu circuit breaker."""

    pass


class TelemetryFallbackStatusDTO(NexusDTO):
    """DTO dla statusu fallback telemetry."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "buffer_file": "bufferFile",
            "buffer_exists": "bufferExists",
            "queued_spans": "queuedSpans",
            "duckdb_path": "duckdbPath",
        },
    )


class AutopilotActionDTO(NexusDTO):
    """DTO dla odpowiedzi accept/reject autopilota."""

    pass


class AutopilotEvalTriggerDTO(NexusDTO):
    """DTO dla odpowiedzi triggera ewaluacji autopilota."""

    pass


class PartnerClientListDTO(NexusDTO):
    """DTO dla listy klientów partnera z cursor pagination."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "next_cursor": "nextCursor",
            "has_more": "hasMore",
        },
    )


class PartnerClientInvoicesDTO(NexusDTO):
    """DTO dla listy faktur klienta partnera."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={
            "invoice_id": "invoiceId",
            "amount_gross": "amountGross",
            "issue_date": "issueDate",
            "created_at": "createdAt",
        },
    )


# ── Health DTOs ─────────────────────────────────────────────────────────


class HealthResponseDTO(NexusDTO):
    """DTO dla odpowiedzi health check."""

    pass


# ── Version DTOs ────────────────────────────────────────────────────────


class VersionInfoDTO(NexusDTO):
    """DTO dla odpowiedzi wersji API."""

    pass


# ── File DTOs ───────────────────────────────────────────────────────────


class FileInfoDTO(NexusDTO):
    """DTO dla informacji o pliku."""

    pass


class FileDeleteResponseDTO(NexusDTO):
    """DTO dla odpowiedzi usunięcia pliku."""

    pass


# ── Billing DTOs ────────────────────────────────────────────────────────


class BillingEstimateRequestDTO(NexusDTO):
    """DTO dla GET /api/v2/billing/estimate."""

    pass


class BillingEstimateResponseDTO(NexusDTO):
    """DTO dla odpowiedzi estymacji kosztów."""

    pass


# ── Analytics DTOs ──────────────────────────────────────────────────────


class AnalyticsQueryDTO(NexusDTO):
    """DTO dla zapytań analitycznych."""

    pass


class AnalyticsFXResponseDTO(NexusDTO):
    """DTO dla odpowiedzi FX AS OF JOIN."""

    pass


# ── Dashboard DTOs ──────────────────────────────────────────────────────


class DashboardBriefingDTO(NexusDTO):
    """DTO dla odpowiedzi daily briefing."""

    pass


class DashboardSummaryDTO(NexusDTO):
    """DTO dla odpowiedzi dashboardu — kwoty, liczba dokumentów."""

    pass


# ── Autopilot DTOs ──────────────────────────────────────────────────────


class AutopilotDecisionsDTO(NexusDTO):
    """DTO dla listy decyzji Autopilota."""

    pass


class AutopilotDecisionDTO(NexusDTO):
    """DTO dla szczegółów decyzji Autopilota."""

    pass


class AutopilotTriggerDTO(NexusDTO):
    """DTO dla triggera ewaluacji Autopilota."""

    pass


class AutopilotTrustScoreDTO(NexusDTO):
    """DTO dla trendu trust score."""

    pass


class AutopilotStatsDTO(NexusDTO):
    """DTO dla statystyk Autopilota."""

    pass


# ── Tasks DTOs ──────────────────────────────────────────────────────────


class TaskStatusDTO(NexusDTO):
    """DTO dla statusu zadania."""

    pass


class TaskCancelResponseDTO(NexusDTO):
    """DTO dla odpowiedzi anulowania zadania."""

    pass


# ── UI State DTOs ───────────────────────────────────────────────────────


class UISaveDraftDTO(NexusDTO):
    """DTO dla zapisu draftu UI."""

    pass


class UIGetDraftDTO(NexusDTO):
    """DTO dla odczytu draftu UI."""

    pass


class UIDeleteDraftDTO(NexusDTO):
    """DTO dla usunięcia draftu UI."""

    pass


class UIListDraftsDTO(NexusDTO):
    """DTO dla listy draftów UI."""

    pass


class SaveDraftResponseDTO(NexusDTO):
    """DTO dla odpowiedzi zapisu draftu UI."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"draft_key": "draftKey"},
    )


class RuleSetsDTO(NexusDTO):
    """DTO dla listy zestawów reguł symulacyjnych."""

    config = DTOConfig(
        backend="msgspec",
        rename_fields={"rule_sets": "ruleSets"},
    )


# ── DLQ DTOs ───────────────────────────────────────────────────────────-


class DLQStatsDTO(NexusDTO):
    """DTO dla statystyk DLQ."""

    pass


class DLQListDTO(NexusDTO):
    """DTO dla listy pozycji DLQ."""

    pass


class DLQItemDTO(NexusDTO):
    """DTO dla szczegółów pozycji DLQ."""

    pass


class DLQRetryResponseDTO(NexusDTO):
    """DTO dla odpowiedzi retry DLQ."""

    pass


class DLQBulkRetryResponseDTO(NexusDTO):
    """DTO dla odpowiedzi bulk retry DLQ."""

    pass


class DLQDeleteResponseDTO(NexusDTO):
    """DTO dla odpowiedzi usunięcia DLQ."""

    pass


# ── Outbox Ops DTOs ─────────────────────────────────────────────────────


class OutboxStatsDTO(NexusDTO):
    """DTO dla statystyk outbox."""

    pass


class OutboxProcessResponseDTO(NexusDTO):
    """DTO dla odpowiedzi procesowania outbox."""

    pass


class OutboxReplayResponseDTO(NexusDTO):
    """DTO dla odpowiedzi replay dead-letter outbox."""

    pass


# ── System Integrity DTOs ───────────────────────────────────────────────


class MigrationIntegrityDTO(NexusDTO):
    """DTO dla odpowiedzi integrity migracji."""

    pass


class SagaStateDTO(NexusDTO):
    """DTO dla odpowiedzi stanu sagi."""

    pass


class SagaTransitionDTO(NexusDTO):
    """DTO dla POST /api/system/saga/{id}/transition."""

    pass


class SagaStuckDTO(NexusDTO):
    """DTO dla listy stuck sag."""

    pass


class SagaCompensateDTO(NexusDTO):
    """DTO dla odpowiedzi kompensacji sagi."""

    pass


class UICleanupDTO(NexusDTO):
    """DTO dla odpowiedzi czyszczenia UI drafts."""

    pass


# ── KORE DTOs ───────────────────────────────────────────────────────────


class KoreAuditDTO(NexusDTO):
    """DTO dla odpowiedzi KORE audit."""

    pass


class KoreClosureDTO(NexusDTO):
    """DTO dla odpowiedzi KORE closure."""

    pass



# ── Audit DTOs ─────────────────────────────────────────────────────────-


class AuditDecisionReportDTO(NexusDTO):
    """DTO dla raportu decyzji podatkowej."""

    pass


# ── Rejestr DTO dla OpenAPI ─────────────────────────────────────────────


DTO_REGISTRY: dict[str, type[NexusDTO]] = {
    # Auth
    "RegisterRequest": RegisterDTO,
    "RegisterResponse": RegisterResponseDTO,
    "LoginRequest": LoginDTO,
    "LoginResponse": LoginResponseDTO,
    "RefreshRequest": RefreshDTO,
    "LogoutResponse": LogoutResponseDTO,
    "ConfirmEmailResponse": ConfirmEmailResponseDTO,
    "ResetPasswordRequest": PasswordResetDTO,
    "ResetPasswordConfirmRequest": PasswordResetConfirmDTO,
    "PasswordResetResponse": PasswordResetResponseDTO,
    "PasswordResetConfirmResponse": PasswordResetConfirmResponseDTO,
    "ChangePasswordRequest": ChangePasswordDTO,
    "ChangePasswordResponse": ChangePasswordResponseDTO,
    "CsrfTokenResponse": CsrfTokenResponseDTO,
    "UserProfileResponse": UserProfileResponseDTO,
    # Invoice
    "InvoiceUpload": InvoiceUploadDTO,
    "TaskResponse": TaskResponseDTO,
    "InvoiceCreate": InvoiceCreateDTO,
    "InvoiceResponse": InvoiceResponseDTO,
    "InvoiceListResponse": InvoiceListResponseDTO,
    # Admin
    "ChangeRoleRequest": ChangeRoleDTO,
    "ChangeRoleResponse": ChangeRoleResponseDTO,
    "RiskThresholdCreate": RiskThresholdDTO,
    "StatusResponse": StatusResponseDTO,
    "IdResponse": IdResponseDTO,
    "ActionResponse": ActionResponseDTO,
    "RetryAllResponse": RetryAllResponseDTO,
    "FailedTaskListResponse": FailedTaskListDTO,
    "RuleListResponse": RuleListResponseDTO,
    "PaginatedRuleListResponse": PaginatedRuleListDTO,
    "HealthResponse": HealthResponseDTO,
    "ReplayDecisionResponse": ReplayDecisionDTO,
    "ReplayBatchResponse": ReplayBatchDTO,
    "IntegrityVerifyResponse": IntegrityVerifyDTO,
    "FallbackListResponse": FallbackListDTO,
    "HotReloadHealthResponse": HotReloadHealthDTO,
    "RuleChangelogResponse": RuleChangelogDTO,
    # Tax
    "CalculateMoneyRequest": TaxMathRequestDTO,
    "MoneyAmount": TaxMathResponseDTO,
    "SimulateRequest": TaxPolicySimulateDTO,
    # Triage
    "TriageItem": TriageItemDTO,
    "TriageResolutionRequest": TriageResolutionDTO,
    "TriageResolutionResponse": TriageResponseDTO,
    # Saga
    "SagaTransitionRequest": SagaTransitionDTO,
    "SagaStateResponse": SagaStateDTO,
    # Dashboard
    "DashboardSummaryResponse": DashboardSummaryDTO,
    "DashboardBriefingResponse": DashboardBriefingDTO,
    # Generic (keeping for backward compat)
    "GenericDict": GenericDictDTO,
    # Analytics
    "AnalyticsQuery": AnalyticsQueryDTO,
    "VatSummary": AnalyticsFXResponseDTO,
    # Billing
    "BillingEstimate": BillingEstimateResponseDTO,
    # Version
    "VersionInfo": VersionInfoDTO,
    # Tasks
    "TaskStatus": TaskStatusDTO,
    # DLQ
    "DLQStats": DLQStatsDTO,
    "DLQItem": DLQItemDTO,
    # Outbox
    "OutboxStats": OutboxStatsDTO,
    # KORE
    "KoreAudit": KoreAuditDTO,
    # Audit
    "AuditDecisionReport": AuditDecisionReportDTO,
    # Other
    "ExportStatusResponse": ExportStatusDTO,
    "ExportDownloadResponse": ExportDownloadDTO,
    "FinOpsResponse": FinOpsDTO,
    "I18nStatusResponse": I18nStatusDTO,
    "PiiScanResponse": PiiScanDTO,
    "SecurityPostureResponse": SecurityPostureDTO,
    "LocustSummaryResponse": LocustSummaryDTO,
    "StatsProcessingResponse": StatsProcessingDTO,
    "WorkerStatusResponse": WorkerStatusDTO,
    "CircuitBreakerStatusResponse": CircuitBreakerStatusDTO,
    "TelemetryFallbackStatusResponse": TelemetryFallbackStatusDTO,
    "AutopilotActionResponse": AutopilotActionDTO,
    "AutopilotEvalTriggerResponse": AutopilotEvalTriggerDTO,
    "PartnerClientListResponse": PartnerClientListDTO,
    "SaveDraftResponse": SaveDraftResponseDTO,
    "RuleSetsResponse": RuleSetsDTO,
}
