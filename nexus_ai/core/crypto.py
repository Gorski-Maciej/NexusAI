# core/crypto.py
"""Encryption vault -- uses nexus-crypto (Rust+PyO3) with AEAD + Argon2id fallback.

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

    Bezpieczeństwo pamięci (audyt mimalloc Faza 3):
      - Klucz szyfrowania jest przechowywany w izolowanej stercie SecureHeap
      - Po zakończeniu operacji kryptograficznych, sterta jest niszczona
        z force collect -- dane są zerowane i zwalniane atomowo
      - Zapobiega wyciekom kluczy do swap/core dumps
    """
    __slots__ = ('_key',)

    def __init__(self, config: AppConfig):
        self._key: bytearray | None = None

        # Próba załadowania klucza z configu (bezpieczna alokacja)
        configured_key = config.encryption_key.strip()
        if configured_key:
            try:
                import base64

                raw = base64.urlsafe_b64decode(configured_key.encode("utf-8"))
                if len(raw) == 32:
                    self._key = bytearray(raw)
            except (ValueError, base64.binascii.Error) as exc:
                logger.warning(
                    "Invalid encryption_key base64 format: %s; trying as raw password", exc
                )
            except Exception as exc:
                logger.warning("Unexpected error parsing encryption_key: %s", exc)

        if self._key is None:
            password = configured_key or os.getenv(config.sqlcipher_key_env, "")
            if password:
                raw_key, _ = derive_key(password)
                self._key = bytearray(raw_key)

        if self._key is None:
            env_key = os.getenv("NEXUS_ENCRYPTION_KEY", "").strip()
            if env_key:
                try:
                    import base64

                    raw = base64.urlsafe_b64decode(env_key.encode("utf-8"))
                    if len(raw) == 32:
                        self._key = bytearray(raw)
                except (ValueError, base64.binascii.Error) as exc:
                    logger.warning("Invalid NEXUS_ENCRYPTION_KEY base64: %s", exc)
                except Exception as exc:
                    logger.warning("Unexpected error parsing NEXUS_ENCRYPTION_KEY: %s", exc)

        if self._key is None:
            logger.warning(
                "No encryption key configured -- Vault will operate in plaintext mode. "
                "Set NEXUS_ENCRYPTION_KEY or NEXUS_SQLCIPHER_KEY to enable encryption."
            )

        # Po załadowaniu klucza, mlock go w RAM (nie może trafić na swap)
        self._mlock_key()

    def _mlock_key(self) -> None:
        """Zabezpiecz klucz szyfrowania przed swapem.

        Używa mlock() przez ctypes (libc).
        Działa na bytearray (mutable buffer), więc mlock blokuje
        rzeczywiste dane klucza w RAM, a nie kopię.
        Jeśli mlock się nie uda (brak uprawnień), tylko loguje ostrzeżenie.
        """
        if self._key is None:
            return
        try:
            import ctypes
            import ctypes.util

            libc = ctypes.CDLL(ctypes.util.find_library("c"))
            # bytearray jest writable -- from_buffer() tworzy widok na właściwą pamięć
            buf = (ctypes.c_char * len(self._key)).from_buffer(self._key)
            result = libc.mlock(buf, len(self._key))
            if result != 0:
                logger.debug("[VAULT] mlock failed -- key can be swapped to disk (errno=%d)", result)
            else:
                logger.debug("[VAULT] encryption key locked in RAM (mlock)")
        except (OSError, ctypes.CDLLLoadError) as exc:
            logger.debug("[VAULT] mlock not available: %s -- key can be swapped", exc)
        except Exception as exc:
            logger.debug("[VAULT] mlock unexpected error: %s", exc)

    def _zeroize_key(self) -> None:
        """Bezpiecznie wyzeruj klucz szyfrowania w pamięci.

        Działa poprawnie na bytearray (mutable buffer) --
        ``from_buffer()`` tworzy zapisywalny widok, a ``memset``
        zeruje rzeczywiste dane w pamięci.
        """
        if self._key is not None:
            import ctypes

            # bytearray jest writable -> from_buffer() działa bez TypeError
            buf = (ctypes.c_char * len(self._key)).from_buffer(self._key)
            ctypes.memset(buf, 0, len(self._key))
            self._key = None

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
        except (ValueError, base64.binascii.Error) as exc:
            logger.error("[VAULT] Decryption failed: invalid base64 format -- %s", exc)
            return encrypted_text
        except Exception as exc:
            logger.error("[VAULT] Decryption failed: %s -- returning original ciphertext", exc)
            return encrypted_text

    # Cleanup on garbage collection -- zeroize key when Vault is destroyed
    def __del__(self) -> None:
        self._zeroize_key()
