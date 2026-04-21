from __future__ import annotations

import uuid
from litestar.middleware import AbstractMiddleware


class CorrelationAndDeprecationMiddleware(AbstractMiddleware):
    """Adds correlation-id and version deprecation headers for /api/v1."""

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request_headers = {k.decode().lower(): v.decode() for k, v in scope.get("headers", [])}
        correlation_id = request_headers.get("x-correlation-id", str(uuid.uuid4()))

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                headers = message.setdefault("headers", [])
                headers.append((b"x-correlation-id", correlation_id.encode()))

                path = scope.get("path", "")
                if path.startswith("/api/v1"):
                    headers.append((b"deprecation", b"true"))
                    headers.append((b"sunset", b"Wed, 31 Dec 2026 23:59:59 GMT"))
                    headers.append((b"link", b'</api/v2>; rel="successor-version"'))

            await send(message)

        await self.app(scope, receive, send_wrapper)
