from __future__ import annotations

import time
import asyncio
import os
from collections import defaultdict, deque
from dataclasses import dataclass

from litestar.middleware import AbstractMiddleware
from litestar.response import Response


@dataclass(slots=True)
class RateLimitRule:
    prefix: str
    max_requests: int
    per_seconds: int


class SimpleRateLimitMiddleware(AbstractMiddleware):
    """Process-local rate limiter with per-prefix rules."""

    def __init__(self, app):
        super().__init__(app)
        self.rules = [
            RateLimitRule(prefix="/api/auth", max_requests=5, per_seconds=60),
            RateLimitRule(prefix="/api/v2/analytics", max_requests=60, per_seconds=60),
            RateLimitRule(prefix="/api/v2/invoices", max_requests=30, per_seconds=60),
        ]
        self._hits: dict[tuple[str, str], deque[float]] = defaultdict(deque)
        self._lock = asyncio.Lock()
        self._max_keys = 10000
        self._trust_proxy = os.getenv("NEXUS_TRUST_PROXY", "0") == "1"

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
        key = (rule.prefix, ip)
        now = time.time()
        async with self._lock:
            if len(self._hits) > self._max_keys:
                stale_keys = [k for k, q in self._hits.items() if not q or q[-1] < now - rule.per_seconds]
                for stale in stale_keys[: len(self._hits) - self._max_keys]:
                    self._hits.pop(stale, None)

            queue = self._hits[key]
            cutoff = now - rule.per_seconds
            while queue and queue[0] < cutoff:
                queue.popleft()

            if len(queue) >= rule.max_requests:
                response = Response(
                    content={"detail": "Rate limit exceeded"},
                    status_code=429,
                    headers={"Retry-After": str(rule.per_seconds)},
                )
                await response(scope, receive, send)
                return

            queue.append(now)
        await self.app(scope, receive, send)
