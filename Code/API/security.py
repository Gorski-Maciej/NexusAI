from __future__ import annotations

import logging
import os
import secrets
from dataclasses import dataclass
from sqlalchemy import text

from litestar.connection import ASGIConnection
from litestar.security.jwt import JWTAuth, Token

logger = logging.getLogger("nexus.api.security")

def _resolve_jwt_secret() -> str:
    """Pobiera klucz JWT z env; brak twardo zakodowanego klucza w repozytorium."""
    env_secret = os.getenv("NEXUS_JWT_SECRET", "").strip()
    if env_secret:
        return env_secret

    # Fallback wyłącznie dla środowisk lokalnych/deweloperskich.
    # Nie zapisujemy stałego sekretu w kodzie.
    generated = secrets.token_urlsafe(48)
    logger.warning("NEXUS_JWT_SECRET is missing; using ephemeral dev-only JWT secret.")
    return generated

SECRET_KEY = _resolve_jwt_secret()

async def retrieve_user_handler(token: Token, connection: ASGIConnection) -> User | None:
    if not token.sub:
        return None

    extras = getattr(token, "extras", None) or {}
    if extras.get("username") and extras.get("role"):
        return User(
            id=str(token.sub),
            username=str(extras["username"]),
            role=str(extras["role"]),
            tenant_id=str(extras.get("tenant_id")) if extras.get("tenant_id") is not None else None,
        )

    db_engine = getattr(connection.app.state, "db_engine", None)
    if db_engine is not None:
        async with db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        "SELECT id, username, role, tenant_id, is_active FROM users WHERE id = :id OR username = :id LIMIT 1"
                    ),
                    {"id": str(token.sub)},
                )
            ).mappings().first()
            if row and row.get("is_active"):
                return User(
                    id=str(row["id"]),
                    username=str(row["username"]),
                    role=str(row["role"]),
                    tenant_id=str(row["tenant_id"]),
                )

    return None


@dataclass(slots=True)
class User:
    id: str
    username: str
    role: str
    tenant_id: str | None = None

jwt_auth = JWTAuth[User](
    retrieve_user_handler=retrieve_user_handler,
    token_secret=SECRET_KEY,
    exclude=["/api/auth/login", "/api/v1/health", "/api/v2/health"],
)
