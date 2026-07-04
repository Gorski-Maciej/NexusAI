"""Domain error taxonomy + HTTP JSON envelope."""

from __future__ import annotations

import msgspec
from litestar.connection import Request
from litestar.exceptions import HTTPException
from litestar.response import Response
from structlog import get_logger

logger = get_logger("nexus.api.exceptions")


class DomainError(Exception, msgspec.Struct):
    code: str
    message: str
    category: str
    status_code: int = 400


class ValidationDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(
            code="VALIDATION_ERROR", message=message, category="validation", status_code=422
        )


class IntegrationDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(
            code="INTEGRATION_ERROR", message=message, category="integration", status_code=502
        )


class TimeoutDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(code="TIMEOUT", message=message, category="timeout", status_code=504)


class BusinessRuleDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(
            code="BUSINESS_RULE", message=message, category="business", status_code=409
        )


class SecurityDomainError(DomainError):
    def __init__(self, message: str) -> None:
        super().__init__(
            code="SECURITY_ERROR", message=message, category="security", status_code=401
        )


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
    """RFC 9457 Problem Details response envelope.

    Zgodny ze standardem RFC 9457 (Problem Details for HTTP APIs).
    Używa ``application/problem+json`` jako media type.
    ``type`` to URL do dokumentacji błędu.

    Zarejestrowany ``ProblemDetailsPlugin`` w app.py automatycznie
    konwertuje także wszystkie ``HTTPException`` na RFC 9457.
    """
    correlation_id = request.headers.get("x-correlation-id", "unknown")
    return Response(
        media_type="application/problem+json",
        status_code=status_code,
        content={
            "type": f"https://errors.nexusai.app/{code.lower()}",
            "title": message.split(":")[0] if ":" in message else message[:80],
            "status": status_code,
            "detail": message,
            "instance": request.url.path,
            "code": code,
            "category": category,
            "correlation_id": correlation_id,
        },
    )


def domain_error_handler(request: Request, exc: DomainError) -> Response:
    """Dedykowany handler dla DomainError.

    automatycznie przechwytywany przez ProblemDetailsPlugin i formatowany
    jako RFC 9457 Problem Details (application/problem+json).

    Dzięki temu: jeden system obsługi błędów, spójny format dla wszystkich
    odpowiedzi błędów, automatyczne OpenAPI schema.
    """
    raise HTTPException(
        detail=exc.message,
        status_code=exc.status_code,
        headers={
            "X-Error-Code": exc.code,
            "X-Error-Category": exc.category,
        },
    )
    # Nie dochodzimy tu -- HTTPException jest rzucany powyżej


def http_exception_handler(request: Request, exc: HTTPException) -> Response:
    """Dedykowany handler dla Litestar HTTPException (404, 400, 401, 403, 429, 413...).

    Fazа 2: Zamiast catch-all ``{Exception: ...}``, rejestrujemy dedykowany
    handler dla ``HTTPException``. Litestar wewnętrznie używa ``HTTPException``
    dla wszystkich standardowych błędów HTTP.
    """
    return _error_envelope(
        request,
        code=f"HTTP_{exc.status_code}",
        message=str(exc.detail),
        category="http",
        status_code=exc.status_code,
    )


def msgspec_validation_handler(request: Request, exc: msgspec.ValidationError) -> Response:
    """Dedykowany handler dla msgspec.ValidationError (błędny typ w TOML/JSON).

    Fazа 2: msgspec rzuca ``ValidationError`` gdy dane nie pasują do schematu
    Structa. Przechwytujemy to i zwracamy 422 z czytelnym komunikatem.
    """
    return _error_envelope(
        request,
        code="VALIDATION_ERROR",
        message=str(exc),
        category="validation",
        status_code=422,
    )


def global_exception_handler(request: Request, exc: Exception) -> Response:
    """Catch-all handler dla wszystkich innych wyjątków (500).

    Fazа 2: Dedykowane handlery są rejestrowane dla:
    - ``DomainError`` -> 400-504 (zależnie od kodu)
    - ``HTTPException`` -> standardowe kody HTTP
    - ``msgspec.ValidationError`` -> 422

    z kontekstem requestu (method, path, correlation_id).

    Ten handler działa jako fallback -- loguje i zwraca 500.
    """
    try:
        from nexus_ai.core.sentry import capture_exception

        capture_exception(
            exc,
            method=str(request.method),
            path=request.url.path,
            correlation_id=request.headers.get("x-correlation-id", "unknown"),
        )
    except Exception as sentry_exc:
        logger.debug("Sentry capture failed: %s", sentry_exc)

    # Log unhandled exceptions internally, but don't expose details to client
    logger.error("Unhandled exception: %s: %s", type(exc).__name__, str(exc), exc_info=True)
    return _error_envelope(
        request,
        code="INTERNAL_ERROR",
        message="Wewnętrzny błąd serwera",
        category="internal",
        status_code=500,
    )


# ── Rejestr handlerów dla app.py ────────────────────────────────────────────
# Każdy handler to funkcja (request, exc) -> Response
# Rejestracja w app.py: exception_handlers={...handlers}

EXCEPTION_HANDLERS: dict[type[Exception], callable] = {
    DomainError: domain_error_handler,
    HTTPException: http_exception_handler,
    msgspec.ValidationError: msgspec_validation_handler,
    Exception: global_exception_handler,
}
