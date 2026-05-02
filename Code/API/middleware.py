from __future__ import annotations

import uuid
import time
from litestar.middleware import AbstractMiddleware

from core.tenant import (
    DEFAULT_TENANT_ID,
    reset_current_tenant_id,
    set_current_tenant_id,
)


class CorrelationAndDeprecationMiddleware(AbstractMiddleware):
    """Adds correlation-id, deprecation headers and tenant context."""

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        started = time.perf_counter()
        request_headers = {k.decode().lower(): v.decode() for k, v in scope.get("headers", [])}
        correlation_id = request_headers.get("x-correlation-id", str(uuid.uuid4()))
        scope_user = scope.get("user") or {}
        tenant_from_user = None
        if isinstance(scope_user, dict):
            tenant_from_user = scope_user.get("tenant_id")
        else:
            tenant_from_user = getattr(scope_user, "tenant_id", None)

        tenant_id = tenant_from_user or DEFAULT_TENANT_ID
        tenant_token = set_current_tenant_id(tenant_id)

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                headers = message.setdefault("headers", [])
                headers.append((b"x-correlation-id", correlation_id.encode()))
                headers.append((b"x-tenant-id", tenant_id.encode()))

                process_time_ms = (time.perf_counter() - started) * 1000.0
                headers.append((b"x-process-time", f"{process_time_ms:.2f}ms".encode()))
                headers.append((b"x-content-type-options", b"nosniff"))
                headers.append((b"x-frame-options", b"DENY"))
                headers.append((b"referrer-policy", b"no-referrer"))
                headers.append((b"permissions-policy", b"geolocation=(), microphone=(), camera=()"))
                headers.append((b"content-security-policy", b"default-src 'self'; frame-ancestors 'none'; base-uri 'self'"))

                path = scope.get("path", "")
                if path.startswith("/api/v1"):
                    headers.append((b"deprecation", b"true"))
                    headers.append((b"sunset", b"Wed, 31 Dec 2026 23:59:59 GMT"))
                    headers.append((b"link", b'</api/v2>; rel="successor-version"'))

            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            reset_current_tenant_id(tenant_token)
