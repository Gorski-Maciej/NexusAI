# core/crypto.py
"""Encryption vault — uses nexus-crypto (Rust+PyO3) with AEAD + Argon2id fallback.

Zastępuje: cryptography.fernet (Fernet AES-128-CBC+HMAC, PBKDF2)
Nowy:     ChaCha20-Poly1305 AEAD + Argon2id KDF (nexus-crypto)
"""

from __future__ import annotations

import os

from nexus_crypto import decrypt as _decrypt
from nexus_crypto import derive_key
from nexus_crypto import encrypt as _encrypt
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.core.crypto")


class Vault:
    """Moduł do bezpiecznego szyfrowania danych aplikacyjnych w locie.

    Uses ChaCha20-Poly1305 AEAD with Argon2id key derivation.
    Falls back to plaintext when required keys are not configured.
    """

    def __init__(self, config: AppConfig):
        self._key: bytes | None = None

        configured_key = config.encryption_key.strip()
        if configured_key:
            # Direct 32-byte key (base64-url encoded)
            try:
                import base64

                raw = base64.urlsafe_b64decode(configured_key.encode("utf-8"))
                if len(raw) == 32:
                    self._key = raw
            except Exception:
                logger.warning("Invalid encryption_key format; trying as raw password")

        if self._key is None:
            # Fallback to password-based key derivation
            password = configured_key or os.getenv(config.sqlcipher_key_env, "")
            if password:
                self._key, _ = derive_key(password)

        if self._key is None:
            env_key = os.getenv("NEXUS_ENCRYPTION_KEY", "").strip()
            if env_key:
                try:
                    import base64

                    raw = base64.urlsafe_b64decode(env_key.encode("utf-8"))
                    if len(raw) == 32:
                        self._key = raw
                except Exception:
                    pass

        if self._key is None:
            logger.warning(
                "No encryption key configured — Vault will operate in plaintext mode. "
                "Set NEXUS_ENCRYPTION_KEY or NEXUS_SQLCIPHER_KEY to enable encryption."
            )

    def encrypt(self, plain_text: str) -> str:
        """Encrypt string with AEAD (ChaCha20-Poly1305)."""
        if not plain_text or self._key is None:
            return plain_text
        encrypted = _encrypt(self._key, plain_text.encode("utf-8"))
        import base64

        return base64.urlsafe_b64encode(encrypted).decode("utf-8")

    def decrypt(self, encrypted_text: str) -> str:
        """Decrypt string encrypted with `encrypt`."""
        if not encrypted_text or self._key is None:
            return encrypted_text
        import base64

        try:
            data = base64.urlsafe_b64decode(encrypted_text.encode("utf-8"))
            return _decrypt(self._key, data).decode("utf-8")
        except Exception as exc:
            logger.error("Decryption failed: %s", exc)
            return encrypted_text
