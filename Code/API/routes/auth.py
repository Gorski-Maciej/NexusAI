from __future__ import annotations

from sqlalchemy import text
from litestar.connection import Request

from litestar import Controller, post
from litestar.response import Response
from litestar.exceptions import NotAuthorizedException
import msgspec

from api.security import jwt_auth
from api.auth_service import verify_password


class LoginRequest(msgspec.Struct):
    username: str
    password: str


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

        return jwt_auth.login(
            identifier=str(user["id"]),
            token_extras={"role": str(user["role"]), "tenant_id": str(user["tenant_id"]), "username": str(user["username"])},
            send_token_as_response_body=True,
        )
