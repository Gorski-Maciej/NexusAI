from __future__ import annotations

import secrets
import hashlib
import json
from datetime import datetime, timedelta, timezone

from sqlalchemy import text
from litestar.connection import Request

from litestar import Controller, get, post
from litestar.response import Response
from litestar.exceptions import NotAuthorizedException
import msgspec

from api.security import jwt_auth, REFRESH_TOKEN_EXPIRATION_DAYS
from api.auth_service import verify_password


class LoginRequest(msgspec.Struct):
    username: str
    password: str


class RefreshRequest(msgspec.Struct):
    refresh_token: str


class AuthController(Controller):
    path = "/api/auth"

    @post("/login")
    async def login(self, data: LoginRequest, request: Request) -> Response[dict[str, str]]:
        async with request.app.state.db_engine.connect() as conn:
            user = (
                await conn.execute(
                    text(
                        """
                        SELECT id, username, password_hash, role, tenant_id, is_active
                        FROM users
                        WHERE username = :username
                        LIMIT 1
                        """
                    ),
                    {"username": data.username},
                )
            ).mappings().first()

        if not user or not user.get("is_active") or not verify_password(data.password, str(user["password_hash"])):
            raise NotAuthorizedException("Invalid credentials")

        user_id = str(user["id"])

        # Generuj access token (krótkotrwały)
        response = jwt_auth.login(
            identifier=user_id,
            token_extras={"role": str(user["role"]), "tenant_id": str(user["tenant_id"]), "username": str(user["username"])},
            send_token_as_response_body=True,
        )

        # Generuj refresh token (długotrwały, Rozwiązanie 16)
        refresh_token_str, hashed_refresh = _generate_refresh_token_pair()
        expires_at = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRATION_DAYS)

        # Zapisz hash refresh tokena w bazie
        async with request.app.state.db_engine.connect() as conn:
            # Unieważnij stare refresh tokeny dla tego użytkownika (rotacja)
            await conn.execute(
                text(
                    "UPDATE refresh_tokens SET is_revoked = 1 WHERE user_id = :user_id AND is_revoked = 0"
                ),
                {"user_id": user_id},
            )
            await conn.execute(
                text(
                    """
                    INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
                    VALUES (:user_id, :token_hash, :expires_at)
                    """
                ),
                {
                    "user_id": user_id,
                    "token_hash": hashed_refresh,
                    "expires_at": expires_at.isoformat(),
                },
            )
            await conn.commit()

        # Dołącz refresh token do odpowiedzi
        body = json.loads(response.body.decode()) if isinstance(response.body, bytes) else {}
        body["refresh_token"] = refresh_token_str
        body["refresh_token_expires_in_days"] = REFRESH_TOKEN_EXPIRATION_DAYS
        response.body = json.dumps(body).encode()

        # Ustaw ciasteczko CSRF (SameSite=Strict dla ochrony przed CSRF - Rozwiązanie 13)
        from api.middleware import _generate_csrf_token
        csrf_token = _generate_csrf_token()
        response.set_cookie(
            key="csrf_token",
            value=csrf_token,
            max_age=3600,
            httponly=False,  # Must be accessible by JS for double-submit
            samesite="strict",
            secure=True if request.url.scheme == "https" else False,
        )

        return response

    @post("/refresh")
    async def refresh(self, data: RefreshRequest, request: Request) -> Response[dict[str, str]]:
        """
        Odświeża parę tokenów (access + refresh).
        Stary refresh token jest unieważniany (rotacja).
        """
        hashed_input = _hash_refresh_token(data.refresh_token)

        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        """
                        SELECT user_id, expires_at, is_revoked
                        FROM refresh_tokens
                        WHERE token_hash = :token_hash
                        LIMIT 1
                        """
                    ),
                    {"token_hash": hashed_input},
                )
            ).mappings().first()

        if not row:
            raise NotAuthorizedException("Invalid refresh token")

        if row["is_revoked"]:
            raise NotAuthorizedException("Refresh token has been revoked")

        expires_at = row["expires_at"]
        if isinstance(expires_at, str):
            expires_at = datetime.fromisoformat(expires_at)
        if datetime.now(timezone.utc) > expires_at:
            raise NotAuthorizedException("Refresh token has expired")

        user_id = str(row["user_id"])

        # Pobierz dane użytkownika
        async with request.app.state.db_engine.connect() as conn2:
            user = (
                await conn2.execute(
                    text(
                        """
                        SELECT id, username, role, tenant_id, is_active
                        FROM users
                        WHERE id = :id AND is_active = 1
                        LIMIT 1
                        """
                    ),
                    {"id": user_id},
                )
            ).mappings().first()

        if not user:
            raise NotAuthorizedException("User not found or inactive")

        # Generuj nową parę tokenów
        response = jwt_auth.login(
            identifier=user_id,
            token_extras={"role": str(user["role"]), "tenant_id": str(user["tenant_id"]), "username": str(user["username"])},
            send_token_as_response_body=True,
        )

        # Unieważnij stary refresh token i dodaj nowy
        new_refresh_token_str, new_hashed_refresh = _generate_refresh_token_pair()
        new_expires_at = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRATION_DAYS)

        async with request.app.state.db_engine.connect() as conn3:
            await conn3.execute(
                text(
                    "UPDATE refresh_tokens SET is_revoked = 1 WHERE token_hash = :token_hash"
                ),
                {"token_hash": hashed_input},
            )
            await conn3.execute(
                text(
                    """
                    INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
                    VALUES (:user_id, :token_hash, :expires_at)
                    """
                ),
                {
                    "user_id": user_id,
                    "token_hash": new_hashed_refresh,
                    "expires_at": new_expires_at.isoformat(),
                },
            )
            await conn3.commit()

        # Dołącz nowy refresh token do odpowiedzi
        body = json.loads(response.body.decode()) if isinstance(response.body, bytes) else {}
        body["refresh_token"] = new_refresh_token_str
        body["refresh_token_expires_in_days"] = REFRESH_TOKEN_EXPIRATION_DAYS
        response.body = json.dumps(body).encode()

        return response

    @get("/csrf-token")
    async def get_csrf_token(self, request: Request) -> dict[str, str]:
        """Endpoint do pobrania tokena CSRF (Rozwiązanie 13)."""
        from api.middleware import _generate_csrf_token
        token = _generate_csrf_token()
        return {"csrf_token": token}


def _generate_refresh_token_pair() -> tuple[str, str]:
    """Generuje parę (plain_token, hashed_token)."""
    token = secrets.token_urlsafe(48)
    hashed = _hash_refresh_token(token)
    return token, hashed


def _hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()
