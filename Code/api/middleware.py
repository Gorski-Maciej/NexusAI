from __future__ import annotations

import base64
import hashlib
import hmac
import os
import secrets
import time
import uuid

from litestar.middleware import AbstractMiddleware
from litestar.status_codes import HTTP_403_FORBIDDEN, HTTP_413_REQUEST_ENTITY_TOO_LARGE

from core.config import AppConfig
from core.logger import get_logger
from core.msgspec_utils import msgspec_dumps_bytes, msgspec_loads
from core.tenant import (
    DEFAULT_TENANT_ID,
    reset_current_tenant_id,
    set_current_tenant_id,
)

logger = get_logger()


class RequestBodyTooLargeError(RuntimeError):
    pass


_UPLOAD_SEMAPHORE = None
_CSRF_TOKENS: dict[str, float] = {}  # token -> timestamp
_CSRF_TOKEN_TTL = 3600  # 1 godzina


def _get_upload_semaphore():
    global _UPLOAD_SEMAPHORE
    if _UPLOAD_SEMAPHORE is None:
        import asyncio
        _UPLOAD_SEMAPHORE = asyncio.Semaphore(10)  # max 10 równoczesnych uploadów
    return _UPLOAD_SEMAPHORE


def _cleanup_expired_csrf_tokens():
    now = time.time()
    expired = [k for k, ts in _CSRF_TOKENS.items() if now - ts > _CSRF_TOKEN_TTL]
    for k in expired:
        _CSRF_TOKENS.pop(k, None)


def _generate_csrf_token() -> str:
    token = secrets.token_urlsafe(32)
    _CSRF_TOKENS[token] = time.time()
    _cleanup_expired_csrf_tokens()
    return token


def _validate_csrf_token(token: str | None) -> bool:
    if not token:
        return False
    ts = _CSRF_TOKENS.pop(token, None)
    if ts is None:
        return False
    if time.time() - ts > _CSRF_TOKEN_TTL:
        return False
    return True


class UploadSizeGuardMiddleware(AbstractMiddleware):
    """
    Hard request-body guard for upload endpoints, including chunked transfer.
    Rozwiązanie 15: Progressive size check, upload semaphore, timeout.
    """

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

        # Użyj semafora dla ograniczenia równoczesnych uploadów (Rozwiązanie 15)
        upload_sem = _get_upload_semaphore()
        async with upload_sem:
            try:
                import asyncio
                # Timeout na strumieniowanie danych (Rozwiązanie 15) - tylko faza odbioru
                # Użyj wyższego timeoutu, bo przetwarzanie (OCR) może trwać dłużej
                async def guarded_receive_with_timeout():
                    nonlocal total
                    try:
                        message = await asyncio.wait_for(receive(), timeout=120.0)
                    except TimeoutError:
                        raise RequestBodyTooLargeError("upload stream timeout")
                    if message.get("type") == "http.request":
                        body = message.get("body", b"")
                        total += len(body)
                        if total > limit:
                            raise RequestBodyTooLargeError("request body too large")
                    return message

                await self.app(scope, guarded_receive_with_timeout, send)
            except TimeoutError:
                logger.warning("[UPLOAD] Request timeout for path=%s", path)
                await self._send_413(send)
            except RequestBodyTooLargeError as e:
                if "timeout" in str(e):
                    logger.warning("[UPLOAD] Upload stream timeout for path=%s", path)
                await self._send_413(send)

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


class CSRFProtectionMiddleware(AbstractMiddleware):
    """
    Ochrona CSRF dla endpointów modyfikujących stan (POST, PUT, DELETE).
    Rozwiązanie 13: Double-submit cookie pattern z X-CSRF-Token.
    Używa nagłówka X-CSRF-Token do weryfikacji bezpiecznych żądań.
    """

    SAFE_METHODS = frozenset({"GET", "HEAD", "OPTIONS", "TRACE"})

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        method = scope.get("method", "GET")
        if method in self.SAFE_METHODS:
            await self.app(scope, receive, send)
            return

        path = scope.get("path", "")
        # Wyklucz endpointy auth i health z walidacji CSRF
        if path.startswith("/api/auth/"):
            await self.app(scope, receive, send)
            return
        if "/health" in path:
            await self.app(scope, receive, send)
            return

        headers = {k.decode().lower(): v.decode() for k, v in scope.get("headers", [])}

        # Dla klientów używających JWT w nagłówku Authorization (Bearer token)
        # CSRF nie jest wymagane, ponieważ przeglądarka nie dołącza tego nagłówka automatycznie
        auth_header = headers.get("authorization", "")
        if auth_header.startswith("Bearer "):
            await self.app(scope, receive, send)
            return

        # Dla klientów używających ciasteczek lub innych metod - wymagaj X-CSRF-Token
        csrf_token = headers.get("x-csrf-token")
        csrf_cookie = None
        for k, v in headers.items():
            if k == "cookie":
                for cookie in v.split(";"):
                    cookie = cookie.strip()
                    if cookie.startswith("csrf_token="):
                        csrf_cookie = cookie.split("=", 1)[1]
                        break

        # Double-submit cookie: porównaj token z ciasteczka i nagłówka
        if csrf_cookie and csrf_token and csrf_cookie == csrf_token:
            await self.app(scope, receive, send)
            return

        # Lub użyj walidacji przez pamięć podręczną
        if _validate_csrf_token(csrf_token):
            await self.app(scope, receive, send)
            return

        # Jeśli brak tokena i żądanie używa ciasteczka auth - odrzuć
        if csrf_cookie or "csrf_token" in str(headers.get("cookie", "")):
            logger.warning("[CSRF] Invalid or missing CSRF token for %s %s", method, path)
            await self._send_403(send, "CSRF validation failed")
            return

        # Dla innych klientów (np. API calls bez ciasteczek) - przepuść
        await self.app(scope, receive, send)

    @staticmethod
    async def _send_403(send, detail: str = "Forbidden"):
        body = msgspec_dumps_bytes({"detail": detail})
        await send(
            {
                "type": "http.response.start",
                "status": HTTP_403_FORBIDDEN,
                "headers": [(b"content-type", b"application/json")],
            }
        )
        await send({"type": "http.response.body", "body": body})


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

    signed = f"{header_b64}.{payload_b64}".encode()
    expected_sig = hmac.new(secret_key.encode(), signed, hashlib.sha256).digest()  # hmac.new(SECRET_KEY.encode()
    expected_b64 = base64.urlsafe_b64encode(expected_sig).rstrip(b"=").decode("utf-8")
    if not hmac.compare_digest(expected_b64, signature_b64):
        return None

    header_padded = header_b64 + "=" * (-len(header_b64) % 4)
    padded = payload_b64 + "=" * (-len(payload_b64) % 4)
    try:
        header_raw = base64.urlsafe_b64decode(header_padded.encode("utf-8"))
        header = msgspec_loads(header_raw)
        if str(header.get("alg", "")).upper() != "HS256":
            return None
        typ = str(header.get("typ", "JWT")).upper()
        if typ not in {"JWT", "AT+JWT"}:
            return None

        payload_raw = base64.urlsafe_b64decode(padded.encode("utf-8"))
        payload = msgspec_loads(payload_raw)
    except Exception:
        return None

    now = int(time.time())
    exp = payload.get("exp")
    if exp is not None:
        try:
            if int(exp) < int(time.time()):
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
                # Rozwiązanie 22: deprecation headers dla nie-wersjonowanych ścieżek
                elif path.startswith("/api/triage"):
                    headers.append((b"deprecation", b"true"))
                    headers.append((b"sunset", b"Wed, 31 Dec 2026 23:59:59 GMT"))
                    headers.append((b"link", b'</api/v2/triage>; rel="successor-version"'))
                elif path.startswith("/api/analytics"):
                    headers.append((b"deprecation", b"true"))
                    headers.append((b"sunset", b"Wed, 31 Dec 2026 23:59:59 GMT"))
                    headers.append((b"link", b'</api/v2/analytics>; rel="successor-version"'))

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
