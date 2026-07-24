from __future__ import annotations

import os
import uuid

import structlog
from litestar.middleware import AbstractMiddleware
from nexus_crypto import verify_jwt as _verify_jwt_rust

from nexus_ai.core.tenant import (
    DEFAULT_TENANT_ID,
    TenantIsolationError,
    reset_current_tenant_id,
    set_current_tenant_id,
)

# logger = get_logger()


def _tenant_from_bearer_auth(authorization_header: str | None) -> str | None:
    """Extract tenant_id from JWT bearer token using Rust verify_jwt.

    Delegates all JWT verification (HS256 signature, exp, nbf, iss, aud)
    to the Rust jsonwebtoken module for 10-50x faster processing.
    """
    if not authorization_header:
        return None
    if not authorization_header.lower().startswith("bearer "):
        return None

    token = authorization_header.split(" ", 1)[1].strip()
    if not token:
        return None

    secret_key = os.getenv("NEXUS_JWT_SECRET", "").strip()
    if not secret_key:
        return None

    required_issuer = os.getenv("NEXUS_JWT_ISSUER", "").strip() or None
    required_audience = os.getenv("NEXUS_JWT_AUDIENCE", "").strip() or None

    claims = _verify_jwt_rust(token, secret_key, required_issuer, required_audience)
    if claims is None:
        return None

    tenant = claims.get("tenant_id") or claims.get("tenant")
    return str(tenant) if tenant else None


class TenantContextMiddleware(AbstractMiddleware):
    """
    Zamiast własnej ContextVar (correlation_id_ctx), używa:
      - structlog.contextvars.clear_contextvars() -- czyszczenie przed nowym requestem
      - structlog.contextvars.bind_contextvars() -- wiązanie kontekstu
      - structlog.contextvars.merge_contextvars -- automatyczne wzbogacanie logów

    Dzięki temu każdy ``logger.info("msg")`` w całym projekcie automatycznie
    zawiera: correlation_id, tenant_id, request_id, path, method.
    Żaden plik nie musi robić ``logger.bind()`` -- contextvars robi to za nich.

    Zastępuje ``CorrelationAndDeprecationMiddleware`` po przeniesieniu:
    - Nagłówki bezpieczeństwa -> ``_app_after_request`` w app.py
    - Nagłówki deprecation -> ``_v1_after_request`` w app.py
    - correlation-id response header -> ``_app_after_request`` w app.py
    """

    _tenant_from_bearer_auth = staticmethod(_tenant_from_bearer_auth)

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request_headers = {k.decode().lower(): v.decode() for k, v in scope.get("headers", [])}
        correlation_id = request_headers.get("x-correlation-id", uuid.uuid4().hex)
        request_id = uuid.uuid4().hex[:12]

        # Wszystkie logi w całym projekcie automatycznie mają te pola
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(
            correlation_id=correlation_id,
            request_id=request_id,
            request_path=scope.get("path", "/"),
            request_method=scope.get("method", "?"),
        )

        # ── Ustaw tenant_id ─────────────────────────────────────────────
        scope_user = scope.get("user") or {}
        tenant_from_user = None
        tenant_from_token = self._tenant_from_bearer_auth(request_headers.get("authorization"))
        if isinstance(scope_user, dict):
            tenant_from_user = scope_user.get("tenant_id")
        else:
            tenant_from_user = getattr(scope_user, "tenant_id", None)

        tenant_id = tenant_from_user or tenant_from_token or DEFAULT_TENANT_ID
        # v7.0 SUPERMOC: Walidacja izolacji tenantów — brak explicit ID → log warning
        if tenant_id == "default" and scope.get("path", "") not in ("/api/v1/health", "/api/v2/health", "/version", "/.well-known/security.txt"):
            logger.warning(
                "[TENANT-ISOLATION] Request without explicit tenant_id on path=%s — using 'default'. "
                "This may cause data sharing between tenants. Consider adding tenant_id to JWT or x-tenant-id header.",
                scope.get("path", "?"),
            )
        tenant_token = set_current_tenant_id(tenant_id)

        structlog.contextvars.bind_contextvars(tenant_id=tenant_id)

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                headers = message.setdefault("headers", [])
                headers.append((b"x-correlation-id", correlation_id.encode()))
                headers.append((b"x-tenant-id", tenant_id.encode()))
                headers.append((b"x-request-id", request_id.encode()))
            await send(message)

        # Każdy log w tym with bloku automatycznie ma correlation_id, request_id, tenant_id
        from loguru import logger as _loguru_logger

        with _loguru_logger.contextualize(
            correlation_id=correlation_id,
            request_id=request_id,
            tenant_id=tenant_id,
            path=scope.get("path", "/"),
        ):
            try:
                logger.debug(
                    "Handling request: method=%s path=%s",
                    scope.get("method", "?"),
                    scope.get("path", "?"),
                )
                await self.app(scope, receive, send_wrapper)
            finally:
                reset_current_tenant_id(tenant_token)
                # Nie resetujemy structlog contextvars -- one są czyszczone
                # na początku next requestu przez clear_contextvars()
                # logger.contextualize() automatycznie czyści kontekst po wyjściu z with
