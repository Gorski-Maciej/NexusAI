import os
import secrets
import logging
from datetime import timedelta
from litestar.security.jwt import JWTAuth, Token
from litestar.connection import ASGIConnection
from litestar.handlers.base import BaseRouteHandler
from litestar.exceptions import NotAuthorizedException
from litestar.config.rate_limit import RateLimitConfig
from models.user import User # Założenie, że model użytkownika istnieje

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
    # Tutaj weryfikujemy użytkownika w SQLite
    # Na potrzeby offline-first, możemy używać domyślnego profilu "admin"
    return User(id="admin", role="admin")

jwt_auth = JWTAuth[User](
    retrieve_user_handler=retrieve_user_handler,
    token_secret=SECRET_KEY,
    exclude=["/auth/login", "/health"], # Endpointy publiczne
)

# Odczytujemy token, który wygenerował main.py (Launcher)
EXPECTED_TOKEN = os.getenv("NEXUS_TOKEN")

def token_guard(connection: ASGIConnection, route_handler: BaseRouteHandler) -> None:
    """Strażnik Litestar.
    Odrzuca wszystkie zapytania, które nie posiadają ważnego tokena w nagłówku.
    Chroni lokalne API przed atakami z innych aplikacji."""

    # 1. Wyjątek dla Healthcheck (żeby Launcher wiedział, czy serwer żyje)
    if connection.url.path == "/health":
        return

    # 2. Tryb deweloperski
    if not EXPECTED_TOKEN:
        raise NotAuthorizedException("Błąd krytyczny: Serwer nie został uruchomiony z Launchera.")

    # 3. Sprawdzanie nagłówka
    auth_header = connection.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise NotAuthorizedException("Odmowa dostępu. Brak poprawnego nagłówka Authorization.")

    # Wyciągamy sam ciąg znaków po słowie "Bearer"
    token = auth_header.split(" ")[1]

    # 4. Weryfikacja
    if token != EXPECTED_TOKEN:
        raise NotAuthorizedException("Nieprawidłowy token dostępu. Połączenie odrzucone.")

# Limit: 100 żądań na minutę dla danego IP
rate_limit_config = RateLimitConfig(
    rate_limit=("minute", 100),
    exclude=["/api/v1/health"], # Zdrowie sprawdzamy bez limitu
)
