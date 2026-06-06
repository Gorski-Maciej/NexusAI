"""Full authentication routes for NexusAI.

Provides:
- POST /api/auth/register — register new user with password validation
- POST /api/auth/login — login with email/username, returns access+refresh tokens
- POST /api/auth/refresh — rotate refresh token (single-use)
- POST /api/auth/logout — invalidate all user tokens (increment jwt_version)
- GET  /api/auth/me — get current user profile
- POST /api/auth/confirm/{token} — confirm email address
- POST /api/auth/reset-password — request password reset email
- POST /api/auth/reset-password/confirm — set new password
- GET  /api/auth/csrf-token — get CSRF token
"""
from __future__ import annotations

import hashlib
import logging
import re
import secrets
import uuid
from datetime import UTC, datetime, timedelta

import msgspec
from litestar import Controller, get, post
from litestar.connection import Request
from litestar.exceptions import NotAuthorizedException, ValidationException
from litestar.response import Response
from sqlalchemy import text

from api.auth_service import hash_password, verify_password
from api.exceptions import DuplicateResourceError
from api.security import REFRESH_TOKEN_EXPIRATION_DAYS, jwt_auth
from core.msgspec_utils import msgspec_dumps, msgspec_loads

logger = logging.getLogger("nexus.api.auth")

# ── Password validation ──────────────────────────────────────────────────────

_PASSWORD_MIN_LENGTH = 8
_PASSWORD_REGEX = re.compile(
    r"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':\"\\|,.<>\/?]).+$"
)


def _validate_password(password: str) -> str | None:
    """Validate password strength. Returns error message or None if valid."""
    if len(password) < _PASSWORD_MIN_LENGTH:
        return f"Password must be at least {_PASSWORD_MIN_LENGTH} characters"
    if not _PASSWORD_REGEX.match(password):
        return (
            "Password must contain at least one uppercase letter, "
            "one lowercase letter, one digit, and one special character"
        )
    return None


# ── Request/Response structs ─────────────────────────────────────────────────


class RegisterRequest(msgspec.Struct):
    username: str
    email: str
    password: str
    full_name: str | None = None


class LoginRequest(msgspec.Struct):
    username: str
    password: str


class RefreshRequest(msgspec.Struct):
    refresh_token: str


class ResetPasswordRequest(msgspec.Struct):
    email: str


class ResetPasswordConfirmRequest(msgspec.Struct):
    token: str
    new_password: str


class ChangePasswordRequest(msgspec.Struct):
    current_password: str
    new_password: str


# ── Helpers ──────────────────────────────────────────────────────────────────


def _hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def _generate_refresh_token_pair() -> tuple[str, str]:
    token = secrets.token_urlsafe(48)
    hashed = _hash_refresh_token(token)
    return token, hashed


def _generate_email_token() -> str:
    return secrets.token_urlsafe(32)


async def _get_user_by_username(db_session, username: str) -> dict | None:
    """Fetch a user by username or email, returning a dict or None."""
    async with db_session.begin() as conn:
        row = (
            await conn.execute(
                text(
                    """SELECT id, username, email, full_name, password_hash, role,
                              tenant_id, is_active, is_verified, must_change_password,
                              jwt_version, last_login
                       FROM users
                       WHERE username = :username OR email = :username
                       LIMIT 1"""
                ),
                {"username": username},
            )
        ).mappings().first()
    return dict(row) if row else None


# ── Controller ───────────────────────────────────────────────────────────────


class AuthController(Controller):
    path = "/api/auth"

    @post("/register")
    async def register(self, data: RegisterRequest, request: Request) -> Response[dict[str, str]]:
        """Register a new user account."""
        # Validate password strength
        pwd_error = _validate_password(data.password)
        if pwd_error:
            raise ValidationException(detail=pwd_error)

        normalized_username = data.username.strip().lower()
        normalized_email = data.email.strip().lower()

        async with request.app.state.db_engine.connect() as conn:
            # Check uniqueness
            existing = (
                await conn.execute(
                    text("SELECT id FROM users WHERE username = :u OR email = :e LIMIT 1"),
                    {"u": normalized_username, "e": normalized_email},
                )
            ).scalar()
            if existing:
                raise DuplicateResourceError("User", normalized_username)

            user_id = str(uuid.uuid4())
            pwd_hash = hash_password(data.password)
            now = datetime.now(UTC).isoformat()
            confirm_token = _generate_email_token()

            await conn.execute(
                text(
                    """INSERT INTO users
                       (id, username, email, full_name, password_hash, role,
                        tenant_id, is_active, is_verified, must_change_password,
                        jwt_version, created_at, updated_at)
                       VALUES
                       (:id, :username, :email, :full_name, :pwd_hash, 'viewer',
                        'default', 1, 0, 0, 1, :now, :now)"""
                ),
                {
                    "id": user_id,
                    "username": normalized_username,
                    "email": normalized_email,
                    "full_name": data.full_name or normalized_username,
                    "pwd_hash": pwd_hash,
                    "now": now,
                },
            )

            # Assign default 'viewer' role
            role_row = (
                await conn.execute(
                    text("SELECT id FROM roles WHERE name = 'viewer' LIMIT 1")
                )
            ).mappings().first()
            if role_row:
                ur_id = str(uuid.uuid4())
                await conn.execute(
                    text(
                        "INSERT INTO user_roles (id, user_id, role_id) VALUES (:id, :uid, :rid)"
                    ),
                    {"id": ur_id, "uid": user_id, "rid": role_row["id"]},
                )

            # Save confirmation token (simplified: store in a simple table)
            await conn.execute(
                text(
                    """CREATE TABLE IF NOT EXISTS email_tokens (
                        id TEXT PRIMARY KEY,
                        user_id TEXT NOT NULL,
                        token TEXT UNIQUE NOT NULL,
                        purpose TEXT NOT NULL DEFAULT 'confirm',
                        expires_at TIMESTAMP NOT NULL,
                        used BOOLEAN NOT NULL DEFAULT 0,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )"""
                )
            )
            token_expires = (datetime.now(UTC) + timedelta(hours=24)).isoformat()
            await conn.execute(
                text(
                    """INSERT INTO email_tokens (id, user_id, token, purpose, expires_at)
                       VALUES (:id, :uid, :token, 'confirm', :expires)"""
                ),
                {"id": str(uuid.uuid4()), "uid": user_id, "token": confirm_token, "expires": token_expires},
            )

            await conn.commit()

        # Send verification email (fire-and-forget via notification service)
        try:
            from services.email_service import send_verification_email
            await send_verification_email(normalized_email, confirm_token, normalized_username)
        except Exception:
            logger.warning("Failed to send verification email for %s", normalized_email)

        logger.info("New user registered: %s (id=%s)", normalized_username, user_id)
        return Response(
            content={
                "status": "ok",
                "message": "User registered. Please check your email to confirm your account.",
                "user_id": user_id,
            },
            status_code=201,
        )

    @post("/login")
    async def login(self, data: LoginRequest, request: Request) -> Response[dict[str, str]]:
        """Authenticate user and return access + refresh tokens."""
        async with request.app.state.db_session_factory() as session:
            user = await _get_user_by_username(session, data.username)
        if not user or not user.get("is_active"):
            raise NotAuthorizedException("Invalid credentials")

        if not verify_password(data.password, user["password_hash"]):
            raise NotAuthorizedException("Invalid credentials")

        user_id = user["id"]
        role = user.get("role", "viewer")
        now = datetime.now(UTC)

        # Update last_login
        async with request.app.state.db_engine.connect() as conn:
            await conn.execute(
                text("UPDATE users SET last_login = :now WHERE id = :id"),
                {"now": now.isoformat(), "id": user_id},
            )
            await conn.commit()

        # Generate access token (short-lived) with jwt_version
        response = jwt_auth.login(
            identifier=user_id,
            token_extras={
                "role": role,
                "tenant_id": user.get("tenant_id", "default"),
                "username": user["username"],
                "jwt_version": user.get("jwt_version", 1),
            },
            send_token_as_response_body=True,
        )

        # Generate refresh token (long-lived, single-use rotation)
        refresh_token_str, hashed_refresh = _generate_refresh_token_pair()
        expires_at = now + timedelta(days=REFRESH_TOKEN_EXPIRATION_DAYS)

        async with request.app.state.db_engine.connect() as conn:
            # Revoke old refresh tokens for this user (rotation)
            await conn.execute(
                text(
                    "UPDATE refresh_tokens SET is_revoked = 1 WHERE user_id = :user_id AND is_revoked = 0"
                ),
                {"user_id": user_id},
            )
            await conn.execute(
                text(
                    """INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
                       VALUES (:user_id, :token_hash, :expires_at)"""
                ),
                {
                    "user_id": user_id,
                    "token_hash": hashed_refresh,
                    "expires_at": expires_at.isoformat(),
                },
            )
            await conn.commit()

        # Attach refresh token to response body
        body = msgspec_loads(response.body) if isinstance(response.body, bytes) else {}
        body["refresh_token"] = refresh_token_str
        body["refresh_token_expires_in_days"] = REFRESH_TOKEN_EXPIRATION_DAYS

        # Log audit event
        try:
            await _log_auth_event(request.app.state.db_engine, user_id, "LOGIN", {"username": user["username"]})
        except Exception:
            pass

        return Response(content=body, status_code=200)

    @post("/refresh")
    async def refresh(self, data: RefreshRequest, request: Request) -> Response[dict[str, str]]:
        """Refresh access token using a single-use refresh token (rotation)."""
        hashed_input = _hash_refresh_token(data.refresh_token)

        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        """SELECT user_id, expires_at, is_revoked
                           FROM refresh_tokens
                           WHERE token_hash = :token_hash LIMIT 1"""
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
        if datetime.now(UTC) > expires_at:
            raise NotAuthorizedException("Refresh token has expired")

        user_id = str(row["user_id"])

        # Fetch user
        async with request.app.state.db_engine.connect() as conn:
            user_row = (
                await conn.execute(
                    text(
                        """SELECT id, username, email, full_name, password_hash, role,
                                  tenant_id, is_active, is_verified, must_change_password,
                                  jwt_version, last_login
                           FROM users WHERE id = :id LIMIT 1"""
                    ),
                    {"id": user_id},
                )
            ).mappings().first()
            user = dict(user_row) if user_row else {}
            if not user.get("is_active"):
                raise NotAuthorizedException("User is inactive")

        # Revoke old + create new refresh token
        new_refresh_token_str, new_hashed_refresh = _generate_refresh_token_pair()
        new_expires_at = datetime.now(UTC) + timedelta(days=REFRESH_TOKEN_EXPIRATION_DAYS)

        async with request.app.state.db_engine.connect() as conn:
            await conn.execute(
                text("UPDATE refresh_tokens SET is_revoked = 1 WHERE token_hash = :hash"),
                {"hash": hashed_input},
            )
            await conn.execute(
                text(
                    """INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
                       VALUES (:uid, :hash, :expires)"""
                ),
                {
                    "uid": user_id,
                    "hash": new_hashed_refresh,
                    "expires": new_expires_at.isoformat(),
                },
            )
            await conn.commit()

        # Generate new access token
        response = jwt_auth.login(
            identifier=user_id,
            token_extras={
                "role": user.get("role", "viewer"),
                "tenant_id": user.get("tenant_id", "default"),
                "username": user.get("username", ""),
                "jwt_version": user.get("jwt_version", 1),
            },
            send_token_as_response_body=True,
        )

        body = msgspec_loads(response.body) if isinstance(response.body, bytes) else {}
        body["refresh_token"] = new_refresh_token_str
        body["refresh_token_expires_in_days"] = REFRESH_TOKEN_EXPIRATION_DAYS

        return Response(content=body, status_code=200)

    @post("/logout")
    async def logout(self, request: Request) -> Response[dict[str, str]]:
        """Invalidate all tokens by incrementing jwt_version."""
        user = getattr(request, "user", None)
        if not user:
            raise NotAuthorizedException("Not authenticated")

        user_id = user.id

        async with request.app.state.db_engine.connect() as conn:
            # Increment jwt_version to invalidate all existing JWTs
            await conn.execute(
                text("UPDATE users SET jwt_version = jwt_version + 1 WHERE id = :id"),
                {"id": user_id},
            )
            # Revoke all refresh tokens
            await conn.execute(
                text("UPDATE refresh_tokens SET is_revoked = 1 WHERE user_id = :uid"),
                {"uid": user_id},
            )
            await conn.commit()

        await _log_auth_event(
            request.app.state.db_engine, user_id, "LOGOUT", {"username": getattr(user, "username", "")}
        )

        return Response(content={"status": "ok", "message": "Logged out successfully"}, status_code=200)

    @get("/me")
    async def me(self, request: Request) -> dict:
        """Return current user profile."""
        user = getattr(request, "user", None)
        if not user:
            raise NotAuthorizedException("Not authenticated")

        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        """SELECT id, username, email, full_name, role,
                                  is_active, is_verified, must_change_password,
                                  last_login, created_at
                           FROM users WHERE id = :id LIMIT 1"""
                    ),
                    {"id": user.id},
                )
            ).mappings().first()

        if not row:
            raise NotAuthorizedException("User not found")

        return {
            "id": row["id"],
            "username": row["username"],
            "email": row.get("email"),
            "full_name": row.get("full_name"),
            "role": row.get("role", "viewer"),
            "is_active": row["is_active"],
            "is_verified": row.get("is_verified", False),
            "must_change_password": row.get("must_change_password", False),
            "last_login": row.get("last_login"),
            "created_at": row["created_at"],
        }

    @post("/confirm/{token:str}")
    async def confirm_email(self, token: str, request: Request) -> Response[dict[str, str]]:
        """Confirm email address using token from verification email."""
        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        """SELECT id, user_id, expires_at, used
                           FROM email_tokens
                           WHERE token = :token AND purpose = 'confirm' LIMIT 1"""
                    ),
                    {"token": token},
                )
            ).mappings().first()

            if not row:
                raise NotAuthorizedException("Invalid confirmation token")
            if row["used"]:
                raise NotAuthorizedException("Confirmation token has already been used")

            expires_at = row["expires_at"]
            if isinstance(expires_at, str):
                expires_at = datetime.fromisoformat(expires_at)
            if datetime.now(UTC) > expires_at:
                raise NotAuthorizedException("Confirmation token has expired")

            user_id = row["user_id"]
            await conn.execute(
                text("UPDATE users SET is_verified = 1 WHERE id = :id"),
                {"id": user_id},
            )
            await conn.execute(
                text("UPDATE email_tokens SET used = 1 WHERE id = :id"),
                {"id": row["id"]},
            )
            await conn.commit()

        await _log_auth_event(request.app.state.db_engine, user_id, "EMAIL_CONFIRMED", {})
        return Response(
            content={"status": "ok", "message": "Email confirmed successfully"}, status_code=200
        )

    @post("/reset-password")
    async def reset_password(self, data: ResetPasswordRequest, request: Request) -> Response[dict[str, str]]:
        """Send password reset email with a reset token."""
        email = data.email.strip().lower()

        async with request.app.state.db_engine.connect() as conn:
            user = (
                await conn.execute(
                    text("SELECT id, username FROM users WHERE email = :email LIMIT 1"),
                    {"email": email},
                )
            ).mappings().first()

            if user:
                reset_token = _generate_email_token()
                token_expires = (datetime.now(UTC) + timedelta(hours=1)).isoformat()
                await conn.execute(
                    text(
                        """INSERT INTO email_tokens (id, user_id, token, purpose, expires_at)
                           VALUES (:id, :uid, :token, 'reset', :expires)"""
                    ),
                    {
                        "id": str(uuid.uuid4()),
                        "uid": user["id"],
                        "token": reset_token,
                        "expires": token_expires,
                    },
                )
                await conn.commit()

                # Send reset email
                try:
                    from services.email_service import send_password_reset_email
                    await send_password_reset_email(email, reset_token, user["username"])
                except Exception:
                    logger.warning("Failed to send password reset email to %s", email)

        # Always return success to prevent email enumeration
        return Response(
            content={
                "status": "ok",
                "message": "If the email exists, a password reset link has been sent.",
            },
            status_code=200,
        )

    @post("/reset-password/confirm")
    async def reset_password_confirm(self, data: ResetPasswordConfirmRequest, request: Request) -> Response[dict[str, str]]:
        """Set a new password using a reset token."""
        # Validate new password
        pwd_error = _validate_password(data.new_password)
        if pwd_error:
            raise ValidationException(detail=pwd_error)

        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text(
                        """SELECT id, user_id, expires_at, used
                           FROM email_tokens
                           WHERE token = :token AND purpose = 'reset' LIMIT 1"""
                    ),
                    {"token": data.token},
                )
            ).mappings().first()

            if not row:
                raise NotAuthorizedException("Invalid reset token")
            if row["used"]:
                raise NotAuthorizedException("Reset token has already been used")

            expires_at = row["expires_at"]
            if isinstance(expires_at, str):
                expires_at = datetime.fromisoformat(expires_at)
            if datetime.now(UTC) > expires_at:
                raise NotAuthorizedException("Reset token has expired")

            user_id = row["user_id"]
            pwd_hash = hash_password(data.new_password)

            # Update password and increment jwt_version (invalidate all sessions)
            await conn.execute(
                text(
                    "UPDATE users SET password_hash = :pwd, must_change_password = 0, "
                    "jwt_version = jwt_version + 1 WHERE id = :id"
                ),
                {"pwd": pwd_hash, "id": user_id},
            )
            await conn.execute(
                text("UPDATE email_tokens SET used = 1 WHERE id = :id"),
                {"id": row["id"]},
            )
            await conn.commit()

        await _log_auth_event(request.app.state.db_engine, user_id, "PASSWORD_RESET", {})
        return Response(
            content={"status": "ok", "message": "Password has been reset successfully"}, status_code=200
        )

    @post("/change-password")
    async def change_password(self, data: ChangePasswordRequest, request: Request) -> Response[dict[str, str]]:
        """Change password for authenticated user (requires current password)."""
        user = getattr(request, "user", None)
        if not user:
            raise NotAuthorizedException("Not authenticated")

        pwd_error = _validate_password(data.new_password)
        if pwd_error:
            raise ValidationException(detail=pwd_error)

        async with request.app.state.db_engine.connect() as conn:
            row = (
                await conn.execute(
                    text("SELECT password_hash FROM users WHERE id = :id LIMIT 1"),
                    {"id": user.id},
                )
            ).mappings().first()

            if not row or not verify_password(data.current_password, row["password_hash"]):
                raise NotAuthorizedException("Current password is incorrect")

            pwd_hash = hash_password(data.new_password)
            await conn.execute(
                text(
                    "UPDATE users SET password_hash = :pwd, must_change_password = 0, "
                    "jwt_version = jwt_version + 1 WHERE id = :id"
                ),
                {"pwd": pwd_hash, "id": user.id},
            )
            await conn.commit()

        await _log_auth_event(request.app.state.db_engine, user.id, "PASSWORD_CHANGE", {})
        return Response(
            content={"status": "ok", "message": "Password changed successfully"}, status_code=200
        )

    @get("/csrf-token")
    async def get_csrf_token(self, request: Request) -> dict[str, str]:
        """Return a CSRF token for double-submit cookie protection."""
        from api.middleware import _generate_csrf_token
        token = _generate_csrf_token()
        return {"csrf_token": token}


# ── Audit helper ─────────────────────────────────────────────────────────────


async def _log_auth_event(db_engine, user_id: str, action: str, details: dict) -> None:
    """Log an authentication event to the audit_logs table."""
    try:
        async with db_engine.connect() as conn:
            log_id = str(uuid.uuid4())
            now = datetime.now(UTC).isoformat()
            await conn.execute(
                text(
                    """INSERT INTO audit_logs (id, user_id, action, new_value, timestamp, created_at)
                       VALUES (:id, :uid, :action, :details, :ts, :ts)"""
                ),
                {
                    "id": log_id,
                    "uid": user_id,
                    "action": action,
                    "details": msgspec_dumps(details),
                    "ts": now,
                },
            )
            await conn.commit()
    except Exception as exc:
        logger.warning("Failed to log auth event: %s", exc)
