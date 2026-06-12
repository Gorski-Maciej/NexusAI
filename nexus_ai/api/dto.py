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
    DashboardSummaryResponse,
    SagaStateResponse,
    SagaTransitionRequest,
    TaskResponse,
    TriageItem,
    TriageResolutionRequest,
    TriageResolutionResponse,
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


class InvoiceUploadDTO(NexusDTO):
    """DTO dla uploadu pliku faktury (multi-part)."""

    pass


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


# ── Rejestr DTO dla OpenAPI ─────────────────────────────────────────────


DTO_REGISTRY: dict[str, type[NexusDTO]] = {
    "RegisterRequest": RegisterDTO,
    "LoginRequest": LoginDTO,
    "RefreshRequest": RefreshDTO,
    "ResetPasswordRequest": PasswordResetDTO,
    "ResetPasswordConfirmRequest": PasswordResetConfirmDTO,
    "ChangePasswordRequest": ChangePasswordDTO,
    "InvoiceUpload": InvoiceUploadDTO,
    "TaskResponse": TaskResponseDTO,
    "ChangeRoleRequest": ChangeRoleDTO,
    "RiskThresholdCreate": RiskThresholdDTO,
    "CalculateMoneyRequest": TaxMathRequestDTO,
    "MoneyAmount": TaxMathResponseDTO,
    "SimulateRequest": TaxPolicySimulateDTO,
    "TriageItem": TriageItemDTO,
    "TriageResolutionRequest": TriageResolutionDTO,
    "TriageResolutionResponse": TriageResponseDTO,
    "SagaTransitionRequest": SagaTransitionDTO,
    "SagaStateResponse": SagaStateDTO,
    "DashboardSummaryResponse": DashboardSummaryDTO,
}
