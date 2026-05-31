# core/crypto.py
"""Encryption vault — optional cryptography dependency."""
from __future__ import annotations

import base64
import logging
import os

from core.config import AppConfig

logger = logging.getLogger("nexus.core.crypto")


def _load_fernet():
    """Lazy-load Fernet; return None if cryptography is unavailable."""
    try:
        from cryptography.fernet import Fernet
        from cryptography.hazmat.primitives import hashes
        from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
        return Fernet, hashes, PBKDF2HMAC
    except ImportError:
        logger.warning(
            "cryptography library not available — Vault will operate in plaintext mode"
        )
        return None, None, None


_FERNET, _HASHES, _PBKDF2 = _load_fernet()


class Vault:
    """Moduł do bezpiecznego szyfrowania danych aplikacyjnych w locie.

    Falls back to plaintext (no-op) when the ``cryptography`` package
    is not available.  This lets the rest of NexusAI start up for
    non-crypto tasks (seed data, diagnostics, etc.).
    """

    def __init__(self, config: AppConfig):
        if _FERNET is None:
            self._fernet = None
            return

        configured_key = config.encryption_key.strip()
        if configured_key:
            master_key = configured_key.encode()
        else:
            env_key = os.getenv(config.sqlcipher_key_env, "").strip()
            master_key = env_key.encode() if env_key else os.urandom(32)

        # Deriwacja klucza (KDF) dla zwiększonego bezpieczeństwa
        kdf = _PBKDF2(
            algorithm=_HASHES.SHA256(),
            length=32,
            salt=b"nexus-offline-ai-salt-v1",
            iterations=480000,
        )
        self._fernet = _FERNET(base64.urlsafe_b64encode(kdf.derive(master_key)))

    def encrypt(self, plain_text: str) -> str:
        if not plain_text or self._fernet is None:
            return plain_text
        return self._fernet.encrypt(plain_text.encode()).decode()

    def decrypt(self, encrypted_text: str) -> str:
        if not encrypted_text or self._fernet is None:
            return encrypted_text
        return self._fernet.decrypt(encrypted_text.encode()).decode()
