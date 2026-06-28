from __future__ import annotations

import os
import secrets
from collections.abc import AsyncGenerator
from functools import lru_cache
from msgspec import Struct

import pendulum
from cachetools import TTLCache
from litestar.connection import ASGIConnection
from litestar.security.jwt import JWTAuth, JWTCookieAuth, Token
from sqlmodel import text
from structlog import get_logger

logger = get_logger("nexus.api.security")

# Cache for user lookups: max 1024 users, TTL 300s (5 min)
_user_cache: TTLCache[str, User | None] = TTLCache(maxsize=1024, ttl=300)


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


def _resolve_jwt_expiration_seconds() -> int:
    raw = os.getenv("NEXUS_JWT_EXPIRATION_SECONDS", "3600").strip()
    try:
        value = int(raw)
    except ValueError:
        logger.warning("Invalid NEXUS_JWT_EXPIRATION_SECONDS=%s, fallback to 3600", raw)
        return 3600
    if value <= 0:
        logger.warning("Non-positive NEXUS_JWT_EXPIRATION_SECONDS=%s, fallback to 3600", raw)
        return 3600
    return value


JWT_ISSUER = os.getenv("NEXUS_JWT_ISSUER", "nexus-ai")
JWT_AUDIENCE = os.getenv("NEXUS_JWT_AUDIENCE", "nexus-api")
JWT_EXPIRATION_SECONDS = _resolve_jwt_expiration_seconds()

# --- Konfiguracja Refresh Token (Rozwiązanie 16) ---
REFRESH_TOKEN_EXPIRATION_DAYS = int(os.getenv("NEXUS_REFRESH_TOKEN_DAYS", "30"))

# Skrócony czas życia access tokena (15 minut zamiast 3600s)
# Wymusza częstsze odświeżanie, co zwiększa bezpieczeństwo
if JWT_EXPIRATION_SECONDS > 900:
    logger.info(
        "Reducing JWT expiration from %ss to 900s for refresh-token flow (Rozwiązanie 16). "
        "Set NEXUS_JWT_EXPIRATION_SECONDS=900 to silence this message.",
        JWT_EXPIRATION_SECONDS,
    )
    JWT_EXPIRATION_SECONDS = 900


async def retrieve_user_handler(token: Token, connection: ASGIConnection) -> User | None:
    if not token.sub:
        return None

    # --- TTLCache: fast path ---
    if token.sub in _user_cache:
        return _user_cache[token.sub]

    extras = getattr(token, "extras", None) or {}
    token_jwt_version = extras.get("jwt_version")

    # Fast path: check jwt_version from token extras against database
    db_engine = getattr(connection.app.state, "db_engine", None)
    if db_engine is not None:
        async with db_engine.connect() as conn:
            row = (
                (
                    await conn.execute(
                        text(
                            "SELECT id, username, role, tenant_id, is_active, jwt_version "
                            "FROM users WHERE id = :id LIMIT 1"
                        ),
                        {"id": str(token.sub)},
                    )
                )
                .mappings()
                .first()
            )

            if not row:
                _user_cache[token.sub] = None
                return None

            # Check if user is active
            if not row.get("is_active"):
                _user_cache[token.sub] = None
                return None

            # jwt_version check: if token has a jwt_version, verify it matches the database
            if token_jwt_version is not None:
                db_jwt_version = row.get("jwt_version", 1)
                try:
                    if int(token_jwt_version) < int(db_jwt_version):
                        # Token was issued before a logout/password change
                        logger.warning(
                            "Rejected stale JWT for user %s: token_v=%s, db_v=%s",
                            row["username"],
                            token_jwt_version,
                            db_jwt_version,
                        )
                        _user_cache[token.sub] = None
                        return None
                except (ValueError, TypeError) as exc:
                    logger.warning(
                        "[AUTH] Invalid jwt_version format for user %s: %s", token.sub, exc
                    )

            user = User(
                id=str(row["id"]),
                username=str(row["username"]),
                role=str(row["role"]),
                tenant_id=str(row["tenant_id"]),
            )
            _user_cache[token.sub] = user
            return user

    # Fallback: DEV-ONLY — rely on token extras without DB verification
    # Ostrzeżenie: ten fallback omija weryfikację użytkownika w bazie danych!
    # Powinien być używany TYLKO w środowiskach deweloperskich/testowych.
    dev_mode = os.getenv("NEXUS_DEV_MODE", "").lower() in ("1", "true", "yes")
    if dev_mode and extras.get("username") and extras.get("role"):
        logger.warning(
            "[AUTH] DEV MODE: Authenticating %s from token extras without DB verification",
            extras["username"],
        )
        user = User(
            id=str(token.sub),
            username=str(extras["username"]),
            role=str(extras["role"]),
            tenant_id=str(extras.get("tenant_id")) if extras.get("tenant_id") is not None else None,
        )
        _user_cache[token.sub] = user
        return user

    _user_cache[token.sub] = None
    return None


class User(Struct):
    id: str
    username: str
    role: str
    tenant_id: str | None = None


@lru_cache(maxsize=1)
def _get_jwt_exclude() -> list[str]:
    """Pobiera listę wykluczeń JWT z configu TOML (SUPERMOC Litestar).

    Sekcja [security] w config/{env}.toml → AppConfig.effective_jwt_exclude.
    Wynik cache'owany przez lru_cache (jedno parsowanie TOML na całe życie procesu).
    Fallback: domyślna lista jeśli config nie jest dostępny.
    """
    try:
        from nexus_ai.core.config import AppConfig

        config = AppConfig.from_toml()
        exclude = config.effective_jwt_exclude
        if exclude:
            return exclude
    except (ImportError, FileNotFoundError, KeyError) as exc:
        logger.debug("[AUTH] Config not available for JWT exclude, using defaults: %s", exc)
    except Exception as exc:
        logger.warning("[AUTH] Unexpected error loading JWT exclude config: %s", exc)
    return [
        "/api/auth/login",
        "/api/auth/register",
        "/api/auth/refresh",
        "/api/auth/csrf-token",
        "/api/auth/reset-password",
        "/api/auth/reset-password/confirm",
        "/api/auth/confirm",
        "/api/v1/health",
        "/api/v2/health",
        "/schema/openapi.yml",
        "/schema/swagger",
    ]


# ── SUPERMOC Litestar: Dual Auth (JWTAuth dla API + JWTCookieAuth dla Web) ──
# JWTAuth: Bearer token w nagłówku Authorization — dla API/CLI/mobilnych
# JWTCookieAuth: Token w secure cookie — dla web (Flet UI, przeglądarki)
# Oba używają tego samego retrieve_user_handler i token_secret.

jwt_auth = JWTAuth[User](
    retrieve_user_handler=retrieve_user_handler,
    token_secret=SECRET_KEY,
    accepted_issuers=[JWT_ISSUER],
    accepted_audiences=[JWT_AUDIENCE],
    default_token_expiration=pendulum.duration(seconds=JWT_EXPIRATION_SECONDS),
    exclude=_get_jwt_exclude(),
)

# JWTCookieAuth dla klientów webowych (Flet UI, przeglądarki)
# Token jest przechowywany w secure, httponly cookie zamiast nagłówka Authorization.
# Automatycznie dodaje OAuth2 security scheme do OpenAPI/Swagger.
jwt_cookie_auth = JWTCookieAuth[User](
    retrieve_user_handler=retrieve_user_handler,
    token_secret=SECRET_KEY,
    accepted_issuers=[JWT_ISSUER],
    accepted_audiences=[JWT_AUDIENCE],
    default_token_expiration=pendulum.duration(seconds=JWT_EXPIRATION_SECONDS),
    exclude=_get_jwt_exclude(),
)
