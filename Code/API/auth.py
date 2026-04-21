from datetime import datetime, timedelta, timezone
from litestar.connection import ASGIConnection
from litestar.exceptions import NotAuthorizedException
from litestar.security.jwt import JWTAuth, Token
from pydantic import BaseModel
from core.config import AppConfig

config = AppConfig()

class User(BaseModel):
    """Reprezentacja zalogowanego użytkownika (na zapas)."""
    id: str
    username: str
    role: str

async def retrieve_user_handler(token: Token, connection: ASGIConnection) -> User | None:
    """Weryfikuje token i pobiera użytkownika z bazy (Mock dla uproszczenia)."""
    if not token.sub:
        raise NotAuthorizedException()

    # Tutaj w przyszłości dodasz zapytanie do bazy: SELECT * FROM users WHERE id = token.sub
    return User(id=token.sub, username="admin", role="ADMIN")

# Gotowy mechanizm JWT do wpięcia w app.py
jwt_auth = JWTAuth[User](
    retrieve_user_handler=retrieve_user_handler,
    token_secret=config.encryption_key,
    exclude=["/health"]
)
