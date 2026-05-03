from __future__ import annotations

import uuid
import time
import json
import base64
import hashlib
import hmac
import os
from litestar.middleware import AbstractMiddleware

from core.tenant import (
    DEFAULT_TENANT_ID,
    reset_current_tenant_id,
    set_current_tenant_id,
)

from litestar.status_codes import HTTP_413_REQUEST_ENTITY_TOO_LARGE
from core.config import AppConfig


class UploadSizeGuardMiddleware(AbstractMiddleware):
    """Hard request-body guard for upload endpoints, including chunked transfer."""

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        path = scope.get("path", "")
        config = self._resolve_config(scope)
        limit = None
        if path.endswith("/invoices/upload"):
            limit = config.max_invoice_upload_bytes
        elif path.endswith("/invoices/upload-large"):
            limit = config.max_attachment_upload_bytes

        if not limit:
            await self.app(scope, receive, send)
            return

        # Fast-fail when content-length is provided.
        headers = {k.decode().lower(): v.decode() for k, v in scope.get("headers", [])}
        content_length = headers.get("content-length")
        if content_length:
            try:
                if int(content_length) > limit:
                    await self._send_413(send)
                    return
            except ValueError:
                pass

        total = 0
        blocked = False

        async def guarded_receive():
            nonlocal total, blocked
            if blocked:
                return {"type": "http.request", "body": b"", "more_body": False}
            message = await receive()
            if message.get("type") == "http.request":
                body = message.get("body", b"")
                total += len(body)
                if total > limit:
                    blocked = True
                    return {"type": "http.request", "body": b"", "more_body": False}
            return message

        if blocked:
            await self._send_413(send)
            return

        async def guarded_send(message):
            if blocked and message.get("type") == "http.response.start":
                await self._send_413(send)
                return
            if not blocked:
                await send(message)

        await self.app(scope, guarded_receive, guarded_send)

    @staticmethod
    def _resolve_config(scope) -> AppConfig:
        app = scope.get("app")
        if app is not None:
            dependencies = getattr(app, "dependencies", None) or {}
            provider = dependencies.get("config")
            if callable(provider):
                try:
                    return provider()
                except Exception:
                    pass
        return AppConfig()

    @staticmethod
    async def _send_413(send):
        await send(
            {
                "type": "http.response.start",
                "status": HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                "headers": [(b"content-type", b"application/json")],
            }
        )
        await send({"type": "http.response.body", "body": b'{"detail":"Request body too large"}'})


def _tenant_from_bearer_auth(authorization_header: str | None) -> str | None:
    """Extract tenant_id from JWT bearer token using HMAC-SHA256 verification."""
    if not authorization_header:
        return None
    if not authorization_header.lower().startswith("bearer "):
        return None

    token = authorization_header.split(" ", 1)[1].strip()
    parts = token.split(".")
    if len(parts) != 3:
        return None

    header_b64, payload_b64, signature_b64 = parts
    secret_key = os.getenv("NEXUS_JWT_SECRET", "").strip()
    if not secret_key:
        return None

    signed = f"{header_b64}.{payload_b64}".encode("utf-8")
    expected_sig = hmac.new(secret_key.encode(), signed, hashlib.sha256).digest()  # hmac.new(SECRET_KEY.encode()
    expected_b64 = base64.urlsafe_b64encode(expected_sig).rstrip(b"=").decode("utf-8")
    if not hmac.compare_digest(expected_b64, signature_b64):
        return None

    header_padded = header_b64 + "=" * (-len(header_b64) % 4)
    padded = payload_b64 + "=" * (-len(payload_b64) % 4)
    try:
        header_raw = base64.urlsafe_b64decode(header_padded.encode("utf-8"))
        header = json.loads(header_raw.decode("utf-8"))
        if str(header.get("alg", "")).upper() != "HS256":
            return None
        typ = str(header.get("typ", "JWT")).upper()
        if typ not in {"JWT", "AT+JWT"}:
            return None

        payload_raw = base64.urlsafe_b64decode(padded.encode("utf-8"))
        payload = json.loads(payload_raw.decode("utf-8"))
    except Exception:
        return None

    now = int(time.time())
    exp = payload.get("exp")
    if exp is not None:
        try:
            if int(exp) < now:
                return None
        except (TypeError, ValueError):
            return None

    nbf = payload.get("nbf")
    if nbf is not None:
        try:
            if int(nbf) > now:
                return None
        except (TypeError, ValueError):
            return None

    required_iss = os.getenv("NEXUS_JWT_ISSUER", "").strip()
    if required_iss and str(payload.get("iss", "")).strip() != required_iss:
        return None

    required_aud = os.getenv("NEXUS_JWT_AUDIENCE", "").strip()
    if required_aud:
        aud = payload.get("aud")
        if isinstance(aud, str):
            if aud != required_aud:
                return None
        elif isinstance(aud, list):
            if required_aud not in [str(x) for x in aud]:
                return None
        else:
            return None

    tenant = payload.get("tenant_id") or payload.get("tenant")
    return str(tenant) if tenant else None


class CorrelationAndDeprecationMiddleware(AbstractMiddleware):
    _tenant_from_bearer_auth = staticmethod(_tenant_from_bearer_auth)

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
        tenant_from_token = self._tenant_from_bearer_auth(request_headers.get("authorization"))
        if isinstance(scope_user, dict):
            tenant_from_user = scope_user.get("tenant_id")
        else:
            tenant_from_user = getattr(scope_user, "tenant_id", None)

        # Trust tenant only from authenticated user context injected by JWTAuth.
        tenant_id = tenant_from_user or tenant_from_token or DEFAULT_TENANT_ID  # tenant_from_user or DEFAULT_TENANT_ID
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
