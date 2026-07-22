"""
JWT Key ID (kid) Support — rotacja klucza JWT bez unieważniania (v7.0 Audit).

Raport v7.0, sekcja 2.1:
  "Brak JWT kid (Key ID) dla rotacji klucza bez unieważniania"

Enterprise v7.0:
  - Wsparcie dla wielu kluczy JWT (kid → key mapping)
  - Automatyczna rotacja z zachowaniem starego klucza
  - Tokeny podpisane starym kluczem są nadal akceptowane
  - Nowe tokeny są podpisywane najnowszym kluczem
  - Delikatna rotacja: stary klucz wygasa po 2x TTL
"""

from __future__ import annotations

import os
import secrets
import time as _time
from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.jwt.kid")


@dataclass
class JWTKey:
    """Klucz JWT z metadanymi."""

    kid: str
    secret: str
    created_at: float
    expires_at: float | None = None  # None = nie wygasa


class JWTKeyManager:
    """Zarządca kluczy JWT z wsparciem kid.

    Usage:
        manager = JWTKeyManager()

        # Pobierz aktualny klucz do podpisywania
        active_key = manager.active_key

        # Weryfikuj token — automatycznie znajduje klucz po kid
        claims = manager.verify_with_kid(token, kid)

        # Rotuj klucz (stary klucz wciąż działa przez 2x TTL)
        manager.rotate_key()
    """

    # Nowy klucz jest ważny 2x TTL starego (dla delikatnej rotacji)
    KEY_GRACE_PERIOD_MULTIPLIER: float = 2.0

    def __init__(self) -> None:
        self._keys: dict[str, JWTKey] = {}
        self._active_kid: str | None = None

        # Załaduj istniejący klucz z env
        env_secret = os.getenv("NEXUS_JWT_SECRET", "").strip()
        if env_secret:
            kid = self._generate_kid(env_secret)
            self._keys[kid] = JWTKey(
                kid=kid,
                secret=env_secret,
                created_at=_time.monotonic(),
            )
            self._active_kid = kid
            logger.info("[JWT-KID] Loaded existing JWT key: kid=%s", kid[:8])

    @staticmethod
    def _generate_kid(secret: str) -> str:
        """Wygeneruj Key ID na podstawie hashu sekretu."""
        import hashlib
        return hashlib.sha256(secret.encode()).hexdigest()[:16]

    def rotate_key(self, new_secret: str | None = None) -> JWTKey:
        """Rotuj klucz JWT — nowy klucz staje się aktywny.

        Stary klucz NIE jest usuwany — tokeny nim podpisane
        są nadal akceptowane przez okres grace.

        Args:
            new_secret: Nowy sekret (auto-generowany jeśli None).

        Returns:
            Nowy aktywny klucz.
        """
        if new_secret is None:
            new_secret = secrets.token_urlsafe(48)

        kid = self._generate_kid(new_secret)

        # Ustaw expiry dla starego klucza (grace period)
        if self._active_kid and self._active_kid in self._keys:
            old_key = self._keys[self._active_kid]
            ttl = _time.monotonic() - old_key.created_at
            old_key.expires_at = (
                _time.monotonic() + ttl * self.KEY_GRACE_PERIOD_MULTIPLIER
            )
            logger.info(
                "[JWT-KID] Old key %s expires in %.0fs (grace period)",
                old_key.kid[:8], ttl * self.KEY_GRACE_PERIOD_MULTIPLIER,
            )

        # Dodaj nowy klucz
        new_key = JWTKey(
            kid=kid,
            secret=new_secret,
            created_at=_time.monotonic(),
        )
        self._keys[kid] = new_key
        self._active_kid = kid

        # Wyczyść przeterminowane klucze
        self._cleanup_expired()

        logger.info(
            "[JWT-KID] Key rotated: new active kid=%s, total keys=%d",
            kid[:8], len(self._keys),
        )

        return new_key

    def get_key(self, kid: str) -> JWTKey | None:
        """Pobierz klucz po kid (dla weryfikacji tokena).

        Returns:
            JWTKey lub None jeśli klucz nie istnieje lub wygasł.
        """
        key = self._keys.get(kid)
        if key is None:
            return None

        if key.expires_at is not None and _time.monotonic() > key.expires_at:
            logger.warning("[JWT-KID] Key %s has expired", kid[:8])
            return None

        return key

    def verify_with_kid(self, token: str, kid: str) -> dict[str, Any] | None:
        """Zweryfikuj token JWT używając klucza wskazanego przez kid.

        Args:
            token: Token JWT.
            kid: Key ID z nagłówka JWT.

        Returns:
            Claims lub None jeśli weryfikacja nieudana.
        """
        key = self.get_key(kid)
        if key is None:
            logger.warning("[JWT-KID] Unknown or expired kid: %s", kid[:8])
            return None

        try:
            from nexus_crypto import verify_jwt
            return verify_jwt(token, key.secret)
        except ImportError:
            import jwt
            try:
                return jwt.decode(token, key.secret, algorithms=["HS256"])
            except Exception:
                return None

    def _cleanup_expired(self) -> None:
        """Usuń przeterminowane klucze."""
        now = _time.monotonic()
        expired = [
            kid for kid, k in self._keys.items()
            if k.expires_at is not None and now > k.expires_at
        ]
        for kid in expired:
            logger.info("[JWT-KID] Removing expired key: kid=%s", kid[:8])
            del self._keys[kid]

    @property
    def active_key(self) -> JWTKey | None:
        """Aktualnie aktywny klucz do podpisywania."""
        if self._active_kid:
            return self._keys.get(self._active_kid)
        return None

    @property
    def all_kids(self) -> list[str]:
        """Lista wszystkich aktywnych Key IDs."""
        return list(self._keys.keys())

    @property
    def stats(self) -> dict[str, Any]:
        """Statystyki zarządcy kluczy."""
        return {
            "active_kid": self._active_kid[:8] if self._active_kid else None,
            "total_keys": len(self._keys),
            "grace_period_multiplier": self.KEY_GRACE_PERIOD_MULTIPLIER,
        }
