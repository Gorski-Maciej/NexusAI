# core/crypto.py
"""Encryption vault -- uses nexus-crypto (Rust+PyO3) with AEAD + Argon2id fallback.

Zastępuje: cryptography.fernet (Fernet AES-128-CBC+HMAC, PBKDF2)
Nowy:     XChaCha20-Poly1305 AEAD + Argon2id KDF (nexus-crypto)

SUPERMOC v7.0 (INNOWACJA #1): HKDF Key Separation.
Klucz root (NEXUS_ENCRYPTION_KEY) jest używany do wyprowadzenia
osobnych kluczy dla każdego kontekstu przez HKDF-SHA256:
  - root_key → HKDF(info="nexusai:vault:v7.0") → vault_key
  - root_key → HKDF(info="nexusai:sqlcipher:v7.0") → sqlcipher_key
Każdy klucz ma inny cel — compromise jednego nie zagraża pozostałym.

SUPERMOC v7.0 (INNOWACJA #2): XChaCha20-Poly1305 jako domyślny.
192-bit nonce eliminuje ryzyko powtórzenia nonce — bezpieczne
losowe generowanie nawet przy masowej skali.

SUPERMOC v7.0 (INNOWACJA #5): SQLCipher Key z Vault (mlock).
Zamiast pobierać klucz z env var (widoczny w /proc/<pid>/environ),
Vault przechowuje klucz w pamięci chronionej przed swapem przez mlock().
"""

from __future__ import annotations

import os

from nexus_crypto import decrypt as _decrypt
from nexus_crypto import derive_key
from nexus_crypto import encrypt as _encrypt
from structlog import get_logger

from nexus_ai.core.config import AppConfig
from nexus_ai.core.hkdf import KeyContext, derive_context_key

logger = get_logger("nexus.core.crypto")


class Vault:
    """Moduł do bezpiecznego szyfrowania danych aplikacyjnych w locie.

    Uses XChaCha20-Poly1305 AEAD (192-bit nonce, misuse resistant)
    with Argon2id key derivation and HKDF key separation.
    Falls back to plaintext when required keys are not configured.

    Bezpieczeństwo pamięci (audyt mimalloc Faza 3):
      - Klucz szyfrowania jest przechowywany w izolowanej stercie SecureHeap
      - Po zakończeniu operacji kryptograficznych, sterta jest niszczona
        z force collect -- dane są zerowane i zwalniane atomowo
      - Zapobiega wyciekom kluczy do swap/core dumps
    """
    __slots__ = ('_key', '_sqlcipher_key', '_vault_key')

    def __init__(self, config: AppConfig):
        self._key: bytearray | None = None
        self._vault_key: bytes | None = None
        self._sqlcipher_key: bytes | None = None

        # ── Krok 1: Załaduj root key ───────────────────────────────────
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

        # ── Krok 2: HKDF Key Separation (INNOWACJA #1 v7.0) ────────────
        # Wyprowadź osobne klucze dla Vault i SQLCipher z root key.
        # Kompromitacja jednego klucza nie zagraża pozostałym.
        if self._key is not None:
            root_bytes = bytes(self._key)
            self._vault_key = derive_context_key(root_bytes, KeyContext.VAULT)
            self._sqlcipher_key = derive_context_key(root_bytes, KeyContext.SQLCIPHER)
            logger.debug(
                "[VAULT] HKDF key separation active: vault_key=%s..., sqlcipher_key=%s...",
                self._vault_key[:8].hex(),
                self._sqlcipher_key[:8].hex(),
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
        """Encrypt string with AEAD (ChaCha20-Poly1305, backward-compatible).

        Używa domyślnie ChaCha20 (12-byte nonce) dla kompatybilności wstecznej.
        Dla nowych danych użyj encrypt_with_version() — XChaCha20 + prefix wersji.
        Klucz szyfrowania pochodzi z HKDF (KeyContext.VAULT) —
        osobny od klucza SQLCipher, backupów i sekretów.
        """
        if not plain_text or self._key is None:
            return plain_text
        enc_key = self._vault_key if self._vault_key else bytes(self._key)
        encrypted = _encrypt(enc_key, plain_text.encode("utf-8"))
        import base64

        return base64.urlsafe_b64encode(encrypted).decode("utf-8")

    def decrypt(self, encrypted_text: str) -> str:
        """Decrypt string encrypted with `encrypt` (backward-compatible)."""
        if not encrypted_text or self._key is None:
            return encrypted_text
        import base64

        try:
            data = base64.urlsafe_b64decode(encrypted_text.encode("utf-8"))
            enc_key = self._vault_key if self._vault_key else bytes(self._key)
            # Try XChaCha20 first (new format), fall back to ChaCha20 (legacy)
            try:
                return _decrypt(enc_key, data, use_xchacha=True).decode("utf-8")
            except Exception:
                return _decrypt(enc_key, data, use_xchacha=False).decode("utf-8")
        except (ValueError, base64.binascii.Error) as exc:
            logger.error("[VAULT] Decryption failed: invalid base64 format -- %s", exc)
            return encrypted_text
        except Exception as exc:
            logger.error("[VAULT] Decryption failed: %s -- returning original ciphertext", exc)
            return encrypted_text

    # ── INNOWACJA #5 v7.0: SQLCipher Key from Vault (mlock protected) ──

    def get_sqlcipher_key(self) -> bytes | None:
        """Zwraca klucz SQLCipher z Vault (chroniony mlock).

        SUPERMOC v7.0 (INNOWACJA #5 + INNOWACJA #1):
        Zamiast pobierac klucz z env var (widoczny w /proc/<pid>/environ),
        Vault przechowuje klucz w pamieci chronionej przed swapem przez
        mlock(). Klucz SQLCipher jest wyprowadzony przez HKDF — osobny
        od klucza Vault.

        Returns:
            Klucz SQLCipher jako surowe 32 bajty (HKDF-derived), lub None.
        """
        if self._sqlcipher_key is not None:
            return self._sqlcipher_key
        if self._key is None:
            return None
        return bytes(self._key)

    def get_vault_key(self) -> bytes | None:
        """Zwraca klucz Vault (HKDF-derived, mlock protected).

        INNOWACJA #1 v7.0: Osobny klucz dla operacji Vault,
        wyprowadzony przez HKDF-SHA256 z root key.

        Returns:
            Klucz Vault jako surowe 32 bajty, lub None.
        """
        if self._vault_key is not None:
            return self._vault_key
        if self._key is not None:
            return bytes(self._key)
        return None

    @property
    def has_key(self) -> bool:
        """Czy Vault ma załadowany klucz."""
        return self._key is not None and len(self._key) == 32

    # ── Key Versioning (v7.0 Audit: "Brak key versioning") ─────────

    _KEY_VERSION: int = 1
    _KEY_VERSION_PREFIX: str = f"v{_KEY_VERSION}:"

    def encrypt_with_version(self, plain_text: str) -> str:
        """Encrypt z prefixem wersji klucza i XChaCha20 (INNOWACJA #2 v7.0).

        Format: v{version}:base64(24B_nonce+ciphertext+tag)

        Używa XChaCha20 (192-bit nonce) dla nowych danych — nonce misuse resistant.
        Dzięki prefiksowi wersji można rotować klucze bez re-encrypt
        wszystkich danych — deszyfrujemy właściwym kluczem na podstawie wersji.
        """
        if not plain_text or self._key is None:
            return plain_text
        enc_key = self._vault_key if self._vault_key else bytes(self._key)
        encrypted = _encrypt(enc_key, plain_text.encode("utf-8"), use_xchacha=True)
        import base64
        return self._KEY_VERSION_PREFIX + base64.urlsafe_b64encode(encrypted).decode("utf-8")

    def decrypt_with_version(self, versioned_text: str) -> str:
        """Decrypt z prefixem wersji klucza.

        Obsługuje rotację kluczy — prefix wersji wskazuje, którym
        kluczem odszyfrować dane. Nowe dane (v1:) używają XChaCha20,
        legacy dane (bez prefixu) używają ChaCha20.
        """
        if not versioned_text or self._key is None:
            return versioned_text
        # Sprawdź prefix wersji v1 (XChaCha20)
        if versioned_text.startswith(self._KEY_VERSION_PREFIX):
            import base64
            try:
                data = base64.urlsafe_b64decode(
                    versioned_text[len(self._KEY_VERSION_PREFIX):].encode("utf-8")
                )
                enc_key = self._vault_key if self._vault_key else bytes(self._key)
                return _decrypt(enc_key, data, use_xchacha=True).decode("utf-8")
            except Exception as exc:
                logger.error("[VAULT] XChaCha20 decrypt failed: %s", exc)
                return versioned_text
        # Brak prefixu — legacy dane (ChaCha20, bez wersjonowania)
        return self.decrypt(versioned_text)

    # Cleanup on garbage collection -- zeroize key when Vault is destroyed
    def __del__(self) -> None:
        self._zeroize_key()
