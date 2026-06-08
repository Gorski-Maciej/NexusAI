from __future__ import annotations

import asyncio
import base64
import os
import time
from collections import defaultdict, deque
from dataclasses import dataclass
from typing import Any

import msgspec
from litestar.middleware import AbstractMiddleware
from litestar.response import Response


@dataclass(slots=True)
class RateLimitRule:
    prefix: str
    max_requests: int
    per_seconds: int
    role_limits: dict[str, int] | None = None  # Per-role overrides: {"OWNER": 100, "WORKER": 20}


class SimpleRateLimitMiddleware(AbstractMiddleware):
    """
    Rate limiter z per-prefix rules, per-role limitami i nagłówkami X-RateLimit-*.
    Rozwiązanie 25: Rozszerzone reguły, zróżnicowanie per-rola, nagłówki standardowe.
    """

    def __init__(self, app):
        super().__init__(app)
        # --- Rozszerzone reguły rate limitingu (Rozwiązanie 25) ---
        self.rules = [
            # Auth (ograniczone, by zapobiec brute-force)
            RateLimitRule(prefix="/api/auth", max_requests=10, per_seconds=60, role_limits={"OWNER": 20}),
            # Endpointy operacji zapisu (niskie limity)
            RateLimitRule(prefix="/api/v2/invoices", max_requests=30, per_seconds=60, role_limits={"OWNER": 60, "WORKER": 15}),
            RateLimitRule(prefix="/api/v2/autopilot", max_requests=15, per_seconds=60, role_limits={"OWNER": 30, "WORKER": 5}),
            RateLimitRule(prefix="/api/v2/dashboard", max_requests=60, per_seconds=60, role_limits={"OWNER": 120, "WORKER": 30}),
            RateLimitRule(prefix="/api/v2/partner", max_requests=30, per_seconds=60, role_limits={"OWNER": 60, "WORKER": 10}),
            RateLimitRule(prefix="/api/v2/analytics", max_requests=30, per_seconds=60, role_limits={"OWNER": 60, "WORKER": 15}),
            # System ops (tylko OWNER)
            RateLimitRule(prefix="/api/v1/system/", max_requests=20, per_seconds=60, role_limits={"OWNER": 30}),
            # Endpointy triage
            RateLimitRule(prefix="/api/v2/triage", max_requests=20, per_seconds=60, role_limits={"OWNER": 40, "WORKER": 10}),
            RateLimitRule(prefix="/api/triage", max_requests=20, per_seconds=60, role_limits={"OWNER": 40, "WORKER": 10}),
            # Upload plików
            RateLimitRule(prefix="/api/v2/files", max_requests=10, per_seconds=60, role_limits={"OWNER": 20, "WORKER": 5}),
            RateLimitRule(prefix="/api/v1/files", max_requests=10, per_seconds=60, role_limits={"OWNER": 20, "WORKER": 5}),
            # Export
            RateLimitRule(prefix="/api/v2/exports", max_requests=15, per_seconds=60),
            # WebSocket
            RateLimitRule(prefix="/api/v1/ws", max_requests=5, per_seconds=60),
            # UI state
            RateLimitRule(prefix="/api/v1/ui", max_requests=60, per_seconds=60),
            # V1 endpoints (niskie limity dla deprecated API)
            RateLimitRule(prefix="/api/v1/health", max_requests=120, per_seconds=60),
            RateLimitRule(prefix="/api/v1/stats", max_requests=20, per_seconds=60),
            RateLimitRule(prefix="/api/v1/tasks", max_requests=20, per_seconds=60),
            # Fallback dla pozostałych v1 i v2
            RateLimitRule(prefix="/api/v2/", max_requests=60, per_seconds=60, role_limits={"OWNER": 120, "WORKER": 30}),
            RateLimitRule(prefix="/api/v1/", max_requests=30, per_seconds=60),
        ]
        self._hits: dict[tuple[str, str, str], deque[float]] = defaultdict(deque)  # (prefix, role, ip) -> timestamps
        self._lock = asyncio.Lock()
        self._max_keys = 20000
        self._trust_proxy = os.getenv("NEXUS_TRUST_PROXY", "0") == "1"

    def _get_role_from_scope(self, scope: dict[str, Any]) -> str:
        """
        Extract user role from JWT auth in scope.
        Rozwiązanie 25: Fallback do parsowania JWT z nagłówka Authorization,
        jeśli scope.user nie jest dostępne (bezpieczeństwo przed brakiem auth middleware).
        """
        user = scope.get("user", None)
        if user is not None:
            return getattr(user, "role", "anonymous")

        # Fallback: parsuj JWT z nagłówka Authorization
        headers = {k.decode().lower(): v.decode() for k, v in scope.get("headers", [])}
        auth = headers.get("authorization", "")
        if auth.startswith("Bearer "):
            try:
                token = auth.split(" ", 1)[1].strip()
                parts = token.split(".")
                if len(parts) == 3:
                    padded = parts[1] + "=" * (-len(parts[1]) % 4)
                    payload = msgspec.json.decode(base64.urlsafe_b64decode(padded.encode()))
                    role = payload.get("extras", {}).get("role", payload.get("role", "anonymous"))
                    return str(role)
            except Exception:
                pass

        return "anonymous"

    def _resolve_max_requests(self, rule: RateLimitRule, role: str) -> int:
        """Resolve max_requests for a given rule and role."""
        if rule.role_limits and role in rule.role_limits:
            return rule.role_limits[role]
        return rule.max_requests

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        path = scope.get("path", "")
        rule = next((r for r in self.rules if path.startswith(r.prefix)), None)
        if rule is None:
            await self.app(scope, receive, send)
            return

        headers = {k.decode().lower(): v.decode() for k, v in scope.get("headers", [])}
        client = scope.get("client")
        client_ip = client[0] if client else "unknown"
        if self._trust_proxy:
            ip = headers.get("x-forwarded-for", client_ip).split(",")[0].strip()
        else:
            ip = client_ip

        # Pobierz rolę z JWT (scope.user) i dostosuj limit
        role = self._get_role_from_scope(scope)
        effective_max = self._resolve_max_requests(rule, role)

        key = (rule.prefix, role, ip)
        now = time.time()

        async with self._lock:
            # Cleanup starych kluczy
            if len(self._hits) > self._max_keys:
                stale_keys = [
                    k for k, q in self._hits.items()
                    if not q or q[-1] < now - rule.per_seconds
                ]
                for stale in stale_keys[: len(self._hits) - self._max_keys]:
                    self._hits.pop(stale, None)

            queue = self._hits[key]
            cutoff = now - rule.per_seconds
            while queue and queue[0] < cutoff:
                queue.popleft()

            remaining = max(0, effective_max - len(queue) - 1)
            reset_at = int(now) + rule.per_seconds

            if len(queue) >= effective_max:
                response = Response(
                    content={"detail": "Rate limit exceeded", "retry_after": rule.per_seconds},
                    status_code=429,
                    headers={
                        "Retry-After": str(rule.per_seconds),
                        "X-RateLimit-Limit": str(effective_max),
                        "X-RateLimit-Remaining": "0",
                        "X-RateLimit-Reset": str(reset_at),
                    },
                )
                await response(scope, receive, send)
                return

            queue.append(now)

        # Dodaj nagłówki rate limit do odpowiedzi
        await self._send_with_ratelimit_headers(scope, receive, send, effective_max, remaining, reset_at)

    async def _send_with_ratelimit_headers(
        self, scope, receive, send, limit: int, remaining: int, reset_at: int
    ) -> None:
        """Wrap the normal response with X-RateLimit-* headers."""
        original_send = send

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                headers.append(
                    (b"X-RateLimit-Limit", str(limit).encode())
                )
                headers.append(
                    (b"X-RateLimit-Remaining", str(remaining).encode())
                )
                headers.append(
                    (b"X-RateLimit-Reset", str(reset_at).encode())
                )
                message["headers"] = headers
            await original_send(message)

        await self.app(scope, receive, send_wrapper)
