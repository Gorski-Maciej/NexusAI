"""Data Transfer Objects (DTOs) for Litestar API endpoints — MsgspecDTO + DTOConfig."""

from __future__ import annotations

from litestar.dto import DTOConfig, MsgspecDTO


# ── OpenAPI Tag Constants ───────────────────────────────────────────────
TAG_AUTH = "Auth"; TAG_INVOICES = "Invoices"; TAG_ADMIN = "Admin"; TAG_TRIAGE = "Triage"
TAG_TAX = "Tax"; TAG_DASHBOARD = "Dashboard"; TAG_ANALYTICS = "Analytics"; TAG_SYSTEM = "System"
TAG_TASKS = "Tasks"; TAG_METRICS = "Metrics"; TAG_AUDIT = "Audit"; TAG_FILES = "Files"
TAG_HEALTH = "Health"; TAG_FINANCE = "Finance"; TAG_I18N = "I18N"; TAG_SECURITY = "Security"
TAG_PRIVACY = "Privacy"; TAG_RISK = "Risk"; TAG_EVENTS = "Events"; TAG_UI_STATE = "UI State"

# ── Base DTO ────────────────────────────────────────────────────────────
class NexusDTO(MsgspecDTO):
    """Base DTO for all NexusAI endpoints — msgspec backend, max_nested_depth=5."""
    config = DTOConfig(backend="msgspec", max_nested_depth=5)

# ── Auth DTOs ───────────────────────────────────────────────────────────
class RegisterDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"full_name": "fullName"})
class LoginDTO(NexusDTO): pass
class RefreshDTO(NexusDTO): pass
class PasswordResetDTO(NexusDTO): pass
class PasswordResetConfirmDTO(NexusDTO): pass
class ChangePasswordDTO(NexusDTO): pass
class AuthResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", exclude={"password", "password_hash", "token"})

# ── Invoice DTOs ────────────────────────────────────────────────────────
class InvoiceCreateDTO(NexusDTO):
    config = DTOConfig(backend="msgspec", rename_fields={"amount_net": "amountNet", "amount_gross": "amountGross", "file_path": "filePath", "issue_date": "issueDate", "contractor_nip": "contractorNip"})

class InvoiceResponseDTO(NexusDTO):
    config = DTOConfig(backend="msgspec", rename_fields={"amount_net": "amountNet", "amount_gross": "amountGross", "contractor_nip": "contractorNip", "issue_date": "issueDate", "file_path": "filePath", "created_at": "createdAt", "updated_at": "updatedAt", "version_id": "versionId", "processing_status": "processingStatus", "retry_count": "retryCount"})

class InvoiceListResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"next_cursor": "nextCursor", "has_more": "hasMore"})
class InvoiceUploadDTO(NexusDTO): pass
class InvoiceUploadResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"file_hash": "fileHash", "file_path": "filePath", "size_bytes": "sizeBytes", "filename": "fileName"})
class TaskResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"task_id": "taskId"})

# ── Admin, Tax, Triage, Saga, Dashboard DTOs ────────────────────────────
class ChangeRoleDTO(NexusDTO): pass
class RiskThresholdDTO(NexusDTO): pass
class TaxMathRequestDTO(NexusDTO): pass
class TaxMathResponseDTO(NexusDTO): pass
class TaxPolicySimulateDTO(NexusDTO): pass
class TriageItemDTO(NexusDTO): pass
class TriageResolutionDTO(NexusDTO): pass
class TriageResponseDTO(NexusDTO): pass
class SagaTransitionDTO(NexusDTO): pass
class SagaStateDTO(NexusDTO): pass
class DashboardSummaryDTO(NexusDTO): pass
class DashboardBriefingDTO(NexusDTO): pass
class GenericDictDTO(NexusDTO): pass
class GenericListDTO(NexusDTO): pass

# ── Admin Response DTOs ─────────────────────────────────────────────────
class StatusResponseDTO(NexusDTO): pass
class IdResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"rule_id": "ruleId"})
class ActionResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"rule_id": "ruleId"})
class RetryAllResponseDTO(NexusDTO): pass
class ChangeRoleResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"user_id": "userId", "old_role": "oldRole", "new_role": "newRole"})
class FailedTaskListDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"failed_at": "failedAt", "created_at": "createdAt"})
class RuleListResponseDTO(NexusDTO): pass
class PaginatedRuleListDTO(NexusDTO): pass
class HealthResponseDTO(NexusDTO): pass
class ReplayDecisionDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"transaction_id": "transactionId", "original_verdict": "originalVerdict", "replayed_verdict": "replayedVerdict"})
class ReplayBatchDTO(NexusDTO): pass
class IntegrityVerifyDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"total_records": "totalRecords", "verified_at": "verifiedAt", "violation_id": "violationId", "system_locked": "systemLocked"})
class FallbackListDTO(NexusDTO): pass
class HotReloadHealthDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"nats_url": "natsUrl", "events_total": "eventsTotal", "events_per_subject": "eventsPerSubject", "last_event_at": "lastEventAt", "uptime_seconds": "uptimeSeconds"})
class RuleChangelogDTO(NexusDTO): pass

# ── Auth Response DTOs ───────────────────────────────────────────────
class RegisterResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"user_id": "userId"})
class LoginResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"access_token": "accessToken", "refresh_token": "refreshToken", "token_type": "tokenType", "expires_in": "expiresIn", "refresh_token_expires_in_days": "refreshTokenExpiresInDays"})
class LogoutResponseDTO(NexusDTO): pass
class ConfirmEmailResponseDTO(NexusDTO): pass
class PasswordResetResponseDTO(NexusDTO): pass
class PasswordResetConfirmResponseDTO(NexusDTO): pass
class ChangePasswordResponseDTO(NexusDTO): pass
class CsrfTokenResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"csrf_token": "csrfToken"})
class UserProfileResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"user_id": "userId", "full_name": "fullName", "is_active": "isActive", "is_verified": "isVerified", "must_change_password": "mustChangePassword", "last_login": "lastLogin", "created_at": "createdAt"})

# ── Other Response DTOs ───────────────────────────────────────────────
class ExportStatusDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"export_id": "exportId", "file_url": "fileUrl"})
class ExportDownloadDTO(NexusDTO): pass
class FinOpsDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"hourly_cost_usd": "hourlyCostUsd", "invoice_count": "invoiceCount", "cost_per_invoice_usd": "costPerInvoiceUsd", "cpu_cores": "cpuCores", "ram_gb": "ramGb"})
class I18nStatusDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"api_languages": "apiLanguages", "prompt_languages": "promptLanguages", "api_locale_dir": "apiLocaleDir", "prompt_dir": "promptDir"})
class PiiScanDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"total_matches": "totalMatches", "dpo_notified": "dpoNotified"})
class SecurityPostureDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"summary_available": "summaryAvailable", "zap_baseline_available": "zapBaselineAvailable", "zap_full_available": "zapFullAvailable", "scan_summary": "scanSummary"})
class LocustSummaryDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"summary_available": "summaryAvailable", "p95_ms": "p95Ms", "p99_ms": "p99Ms", "check_failures": "checkFailures", "avg_response_time_ms": "avgResponseTimeMs", "current_rps": "currentRps", "total_requests": "totalRequests", "total_failures": "totalFailures"})
class StatsProcessingDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"total_processed": "totalProcessed", "avg_processing_time_ms": "avgProcessingTimeMs", "success_rate": "successRate", "error_count": "errorCount"})
class WorkerStatusDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"uptime_seconds": "uptimeSeconds", "ram_mb": "ramMb", "cpu_percent": "cpuPercent", "active_tasks": "activeTasks", "max_concurrent": "maxConcurrent", "python_version": "pythonVersion"})
class CircuitBreakerStatusDTO(NexusDTO): pass
class TelemetryFallbackStatusDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"buffer_file": "bufferFile", "buffer_exists": "bufferExists", "queued_spans": "queuedSpans", "duckdb_path": "duckdbPath"})
class AutopilotActionDTO(NexusDTO): pass
class AutopilotEvalTriggerDTO(NexusDTO): pass
class PartnerClientListDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"next_cursor": "nextCursor", "has_more": "hasMore"})
class PartnerClientInvoicesDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"invoice_id": "invoiceId", "amount_gross": "amountGross", "issue_date": "issueDate", "created_at": "createdAt"})

# ── File DTOs ───────────────────────────────────────────────────────────
class FileInfoDTO(NexusDTO): pass
class FileDeleteResponseDTO(NexusDTO): pass
class VersionInfoDTO(NexusDTO): pass

# ── Billing DTOs ────────────────────────────────────────────────────────
class BillingEstimateRequestDTO(NexusDTO): pass
class BillingEstimateResponseDTO(NexusDTO): pass

# ── Analytics DTOs ──────────────────────────────────────────────────────
class AnalyticsQueryDTO(NexusDTO): pass
class AnalyticsFXResponseDTO(NexusDTO): pass

# ── Autopilot DTOs ──────────────────────────────────────────────────────
class AutopilotDecisionsDTO(NexusDTO): pass
class AutopilotDecisionDTO(NexusDTO): pass
class AutopilotTriggerDTO(NexusDTO): pass
class AutopilotTrustScoreDTO(NexusDTO): pass
class AutopilotStatsDTO(NexusDTO): pass

# ── Tasks DTOs ──────────────────────────────────────────────────────────
class TaskStatusDTO(NexusDTO): pass
class TaskCancelResponseDTO(NexusDTO): pass

# ── UI State DTOs ───────────────────────────────────────────────────────
class UISaveDraftDTO(NexusDTO): pass
class UIGetDraftDTO(NexusDTO): pass
class UIDeleteDraftDTO(NexusDTO): pass
class UIListDraftsDTO(NexusDTO): pass
class SaveDraftResponseDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"draft_key": "draftKey"})
class RuleSetsDTO(NexusDTO): config = DTOConfig(backend="msgspec", rename_fields={"rule_sets": "ruleSets"})

# ── DLQ DTOs ────────────────────────────────────────────────────────────
class DLQStatsDTO(NexusDTO): pass
class DLQListDTO(NexusDTO): pass
class DLQItemDTO(NexusDTO): pass
class DLQRetryResponseDTO(NexusDTO): pass
class DLQBulkRetryResponseDTO(NexusDTO): pass
class DLQDeleteResponseDTO(NexusDTO): pass

# ── Outbox Ops DTOs ─────────────────────────────────────────────────────
class OutboxStatsDTO(NexusDTO): pass
class OutboxProcessResponseDTO(NexusDTO): pass
class OutboxReplayResponseDTO(NexusDTO): pass

# ── System Integrity DTOs ───────────────────────────────────────────────
class MigrationIntegrityDTO(NexusDTO): pass
class SagaStuckDTO(NexusDTO): pass
class SagaCompensateDTO(NexusDTO): pass
class UICleanupDTO(NexusDTO): pass

# ── KORE / Audit DTOs ──────────────────────────────────────────────────
class KoreAuditDTO(NexusDTO): pass
class KoreClosureDTO(NexusDTO): pass
class AuditDecisionReportDTO(NexusDTO): pass

# ── Rejestr DTO dla OpenAPI ─────────────────────────────────────────────
DTO_REGISTRY: dict[str, type[NexusDTO]] = {
    "RegisterRequest": RegisterDTO, "RegisterResponse": RegisterResponseDTO,
    "LoginRequest": LoginDTO, "LoginResponse": LoginResponseDTO,
    "RefreshRequest": RefreshDTO, "LogoutResponse": LogoutResponseDTO,
    "ConfirmEmailResponse": ConfirmEmailResponseDTO,
    "ResetPasswordRequest": PasswordResetDTO, "ResetPasswordConfirmRequest": PasswordResetConfirmDTO,
    "PasswordResetResponse": PasswordResetResponseDTO, "PasswordResetConfirmResponse": PasswordResetConfirmResponseDTO,
    "ChangePasswordRequest": ChangePasswordDTO, "ChangePasswordResponse": ChangePasswordResponseDTO,
    "CsrfTokenResponse": CsrfTokenResponseDTO, "UserProfileResponse": UserProfileResponseDTO,
    "InvoiceUpload": InvoiceUploadDTO, "TaskResponse": TaskResponseDTO,
    "InvoiceCreate": InvoiceCreateDTO, "InvoiceResponse": InvoiceResponseDTO,
    "InvoiceListResponse": InvoiceListResponseDTO,
    "ChangeRoleRequest": ChangeRoleDTO, "ChangeRoleResponse": ChangeRoleResponseDTO,
    "RiskThresholdCreate": RiskThresholdDTO, "StatusResponse": StatusResponseDTO,
    "IdResponse": IdResponseDTO, "ActionResponse": ActionResponseDTO,
    "RetryAllResponse": RetryAllResponseDTO, "FailedTaskListResponse": FailedTaskListDTO,
    "RuleListResponse": RuleListResponseDTO, "PaginatedRuleListResponse": PaginatedRuleListDTO,
    "HealthResponse": HealthResponseDTO, "ReplayDecisionResponse": ReplayDecisionDTO,
    "ReplayBatchResponse": ReplayBatchDTO, "IntegrityVerifyResponse": IntegrityVerifyDTO,
    "FallbackListResponse": FallbackListDTO, "HotReloadHealthResponse": HotReloadHealthDTO,
    "RuleChangelogResponse": RuleChangelogDTO,
    "CalculateMoneyRequest": TaxMathRequestDTO, "MoneyAmount": TaxMathResponseDTO,
    "SimulateRequest": TaxPolicySimulateDTO,
    "TriageItem": TriageItemDTO, "TriageResolutionRequest": TriageResolutionDTO,
    "TriageResolutionResponse": TriageResponseDTO,
    "SagaTransitionRequest": SagaTransitionDTO, "SagaStateResponse": SagaStateDTO,
    "DashboardSummaryResponse": DashboardSummaryDTO, "DashboardBriefingResponse": DashboardBriefingDTO,
    "GenericDict": GenericDictDTO,
    "AnalyticsQuery": AnalyticsQueryDTO, "VatSummary": AnalyticsFXResponseDTO,
    "BillingEstimate": BillingEstimateResponseDTO, "VersionInfo": VersionInfoDTO,
    "TaskStatus": TaskStatusDTO,
    "DLQStats": DLQStatsDTO, "DLQItem": DLQItemDTO,
    "OutboxStats": OutboxStatsDTO, "KoreAudit": KoreAuditDTO,
    "AuditDecisionReport": AuditDecisionReportDTO,
    "ExportStatusResponse": ExportStatusDTO, "ExportDownloadResponse": ExportDownloadDTO,
    "FinOpsResponse": FinOpsDTO, "I18nStatusResponse": I18nStatusDTO,
    "PiiScanResponse": PiiScanDTO, "SecurityPostureResponse": SecurityPostureDTO,
    "LocustSummaryResponse": LocustSummaryDTO, "StatsProcessingResponse": StatsProcessingDTO,
    "WorkerStatusResponse": WorkerStatusDTO, "CircuitBreakerStatusResponse": CircuitBreakerStatusDTO,
    "TelemetryFallbackStatusResponse": TelemetryFallbackStatusDTO,
    "AutopilotActionResponse": AutopilotActionDTO, "AutopilotEvalTriggerResponse": AutopilotEvalTriggerDTO,
    "PartnerClientListResponse": PartnerClientListDTO, "SaveDraftResponse": SaveDraftResponseDTO,
    "RuleSetsResponse": RuleSetsDTO,
}
