"""Domain error taxonomy + HTTP JSON envelope."""
from __future__ import annotations

from dataclasses import dataclass
from litestar.connection import Request
from litestar.response import Response
from litestar.exceptions import HTTPException


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

    return _error_envelope(
        request,
        code="INTERNAL_ERROR",
        message="Wewnętrzny błąd serwera",
        category="internal",
        status_code=500,
    )
