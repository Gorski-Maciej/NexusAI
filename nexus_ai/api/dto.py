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
    AnalyticsQuery,
    DashboardSummaryResponse,
    InvoiceCreate,
    InvoiceListResponse,
    InvoiceResponse,
    SagaStateResponse,
    SagaTransitionRequest,
    TaskResponse,
    TriageItem,
    TriageResolutionRequest,
    TriageResolutionResponse,
    VatSummary,
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
from nexus_ai.api.routes.tax_math import CalculateMoneyRequest, MoneyAmount
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
TAG_FX = "FX"
TAG_I18N = "I18N"
TAG_SECURITY = "Security"
TAG_PRIVACY = "Privacy"
TAG_RISK = "Risk"
TAG_UI_STATE = "UI State"


# ── Base DTO ────────────────────────────────────────────────────────────


class NexusDTO(MsgspecDTO):
    """Bazowa klasa DTO dla wszystkich endpointów NexusAI.

    Automatycznie dodaje opisy pól do schematu OpenAPI.
    DTOConfig pozwala na precyzyjne kontrolowanie które pola są
    widoczne w request (client → server) i response (server → client).
    """

    config = DTOConfig()


# ── Auth DTOs ───────────────────────────────────────────────────────────


class RegisterDTO(NexusDTO):
    """DTO dla POST /api/auth/register — walidacja rejestracji."""

    config = DTOConfig(
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
        exclude={"password", "password_hash", "token"},
    )


# ── Invoice DTOs ────────────────────────────────────────────────────────


class InvoiceCreateDTO(NexusDTO):
    """DTO dla POST /invoices (ręczne tworzenie faktury).

    Automatyczna walidacja typów ``InvoiceCreate`` (msgspec.Struct).
    Konwersja camelCase w JSON → snake_case w Pythonie: ``amountNet → amount_net``.
    """

    config = DTOConfig(
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


# ── FX DTOs ─────────────────────────────────────────────────────────────


class FXUploadRatesDTO(NexusDTO):
    """DTO dla odpowiedzi uploadu kursów FX."""

    pass


# ── Audit DTOs ─────────────────────────────────────────────────────────-


class AuditDecisionReportDTO(NexusDTO):
    """DTO dla raportu decyzji podatkowej."""

    pass


# ── Rejestr DTO dla OpenAPI ─────────────────────────────────────────────


DTO_REGISTRY: dict[str, type[NexusDTO]] = {
    # Auth
    "RegisterRequest": RegisterDTO,
    "LoginRequest": LoginDTO,
    "RefreshRequest": RefreshDTO,
    "ResetPasswordRequest": PasswordResetDTO,
    "ResetPasswordConfirmRequest": PasswordResetConfirmDTO,
    "ChangePasswordRequest": ChangePasswordDTO,
    # Invoice
    "InvoiceUpload": InvoiceUploadDTO,
    "TaskResponse": TaskResponseDTO,
    # Admin
    "ChangeRoleRequest": ChangeRoleDTO,
    "RiskThresholdCreate": RiskThresholdDTO,
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
    # Generic
    "GenericDict": GenericDictDTO,
    # Analytics
    "AnalyticsQuery": AnalyticsQueryDTO,
    "VatSummary": AnalyticsFXResponseDTO,
    # Billing
    "BillingEstimate": BillingEstimateResponseDTO,
    # Health
    "HealthResponse": HealthResponseDTO,
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
}
