"""Domain error taxonomy + HTTP JSON envelope."""
from __future__ import annotations

from dataclasses import dataclass

from litestar.connection import Request
from litestar.exceptions import HTTPException
from litestar.response import Response
from structlog import get_logger

logger = get_logger("nexus.api.exceptions")


@dataclass(slots=True)
class DomainError(Exception):
    code: str
    message: str
    category: str
    status_code: int = 400


class ValidationDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(code="VALIDATION_ERROR", message=message, category="validation", status_code=422)


class IntegrationDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(code="INTEGRATION_ERROR", message=message, category="integration", status_code=502)


class TimeoutDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(code="TIMEOUT", message=message, category="timeout", status_code=504)


class BusinessRuleDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(code="BUSINESS_RULE", message=message, category="business", status_code=409)


class SecurityDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(code="SECURITY_ERROR", message=message, category="security", status_code=401)


# ── Business exception classes ───────────────────────────────────────────────

class InvoiceNotFoundError(DomainError):
    """Raised when an invoice is not found."""
    def __init__(self, invoice_id: str) -> None:
        super().__init__(
            code="INVOICE_NOT_FOUND",
            message=f"Invoice not found: {invoice_id}",
            category="business",
            status_code=404,
        )


class ContractorNotFoundError(DomainError):
    """Raised when a contractor is not found."""
    def __init__(self, contractor_id: str) -> None:
        super().__init__(
            code="CONTRACTOR_NOT_FOUND",
            message=f"Contractor not found: {contractor_id}",
            category="business",
            status_code=404,
        )


class CompanyNotFoundError(DomainError):
    """Raised when a company is not found."""
    def __init__(self, company_id: str) -> None:
        super().__init__(
            code="COMPANY_NOT_FOUND",
            message=f"Company not found: {company_id}",
            category="business",
            status_code=404,
        )


class InsufficientPermissionsError(DomainError):
    """Raised when a user lacks the required permission."""
    def __init__(self, permission: str) -> None:
        super().__init__(
            code="INSUFFICIENT_PERMISSIONS",
            message=f"Missing required permission: {permission}",
            category="security",
            status_code=403,
        )


class KSeFConnectionError(DomainError):
    """Raised when connection to KSeF fails."""
    def __init__(self, message: str = "KSeF service is unavailable") -> None:
        super().__init__(
            code="KSEF_CONNECTION_ERROR",
            message=message,
            category="integration",
            status_code=503,
        )


class RateLimitExceededError(DomainError):
    """Raised when rate limit is exceeded."""
    def __init__(self, retry_after: int = 60) -> None:
        super().__init__(
            code="RATE_LIMIT_EXCEEDED",
            message=f"Rate limit exceeded. Try again in {retry_after} seconds.",
            category="security",
            status_code=429,
        )


class DuplicateResourceError(DomainError):
    """Raised when trying to create a resource that already exists."""
    def __init__(self, resource: str, identifier: str) -> None:
        super().__init__(
            code="DUPLICATE_RESOURCE",
            message=f"{resource} already exists: {identifier}",
            category="validation",
            status_code=409,
        )


# ── Error envelope ───────────────────────────────────────────────────────────

def _error_envelope(
    request: Request,
    *,
    code: str,
    message: str,
    category: str,
    status_code: int,
) -> Response:
    correlation_id = request.headers.get("x-correlation-id", "unknown")
    return Response(
        content={
            "error": {
                "code": code,
                "category": category,
                "message": message,
                "path": request.url.path,
                "correlation_id": correlation_id,
            }
        },
        status_code=status_code,
    )


def global_exception_handler(request: Request, exc: Exception) -> Response:
    if isinstance(exc, DomainError):
        return _error_envelope(
            request,
            code=exc.code,
            message=exc.message,
            category=exc.category,
            status_code=exc.status_code,
        )

    if isinstance(exc, HTTPException):
        return _error_envelope(
            request,
            code="HTTP_ERROR",
            message=str(exc.detail),
            category="http",
            status_code=exc.status_code,
        )

    # Log unhandled exceptions internally, but don't expose details to client
    logger.error(
        "Unhandled exception: %s: %s", type(exc).__name__, str(exc), exc_info=True
    )
    return _error_envelope(
        request,
        code="INTERNAL_ERROR",
        message="Wewnętrzny błąd serwera",
        category="internal",
        status_code=500,
    )
