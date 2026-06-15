from __future__ import annotations

from uuid import uuid4 as _uuid4

from nexus_crypto import verify_jwt as _verify_jwt_rust

from litestar.middleware import AbstractMiddleware

from nexus_ai.core.logger import get_logger
from nexus_ai.core.tenant import (
    DEFAULT_TENANT_ID,
    reset_current_tenant_id,
    set_current_tenant_id,
)

logger = get_logger()


def _tenant_from_bearer_auth(authorization_header: str | None) -> str | None:
    """Extract tenant_id from JWT bearer token using Rust verify_jwt.

    Delegates all JWT verification (HS256 signature, exp, nbf, iss, aud)
    to the Rust jsonwebtoken module for 10-50× faster processing.
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
    """Ustawia ``correlation_id`` i ``tenant_id`` w ContextVar dla każdego requestu.

    Zastępuje ``CorrelationAndDeprecationMiddleware`` po przeniesieniu:
    - Nagłówki bezpieczeństwa → ``_app_after_request`` w app.py
    - Nagłówki deprecation → ``_v1_after_request`` w app.py
    - correlation-id response header → ``_app_after_request`` w app.py

    Ten middleware pozostaje ponieważ:
    - ``correlation_id_ctx.set()`` wymaga ContextVar (poza scope odpowiedzi)
    - ``set_current_tenant_id()`` wymaga ContextVar
    - ``_tenant_from_bearer_auth()`` wymaga dostępu do headers requestu
    """

    _tenant_from_bearer_auth = staticmethod(_tenant_from_bearer_auth)

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request_headers = {k.decode().lower(): v.decode() for k, v in scope.get("headers", [])}
        correlation_id = request_headers.get("x-correlation-id", uuid.uuid4().hex)

        # ── Ustaw correlation_id w ContextVar dla logowania ──────────────
        from nexus_ai.core.tracing import correlation_id_ctx

        cid_token = correlation_id_ctx.set(correlation_id)

        # ── Ustaw tenant_id w ContextVar ─────────────────────────────────
        scope_user = scope.get("user") or {}
        tenant_from_user = None
        tenant_from_token = self._tenant_from_bearer_auth(request_headers.get("authorization"))
        if isinstance(scope_user, dict):
            tenant_from_user = scope_user.get("tenant_id")
        else:
            tenant_from_user = getattr(scope_user, "tenant_id", None)

        tenant_id = tenant_from_user or tenant_from_token or DEFAULT_TENANT_ID
        tenant_token = set_current_tenant_id(tenant_id)

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                headers = message.setdefault("headers", [])
                headers.append((b"x-correlation-id", correlation_id.encode()))
                headers.append((b"x-tenant-id", tenant_id.encode()))
            await send(message)

        try:
            logger.bind(correlation_id=correlation_id, tenant_id=tenant_id).debug(
                "Handling request: method=%s path=%s",
                scope.get("method", "?"),
                scope.get("path", "?"),
            )
            await self.app(scope, receive, send_wrapper)
        finally:
            reset_current_tenant_id(tenant_token)
            correlation_id_ctx.reset(cid_token)
