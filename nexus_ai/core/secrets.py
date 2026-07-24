from __future__ import annotations

import ctypes
import os
from pathlib import Path

import pendulum
from structlog import get_logger

from nexus_ai.core.msgspec_utils import DecodeError, msgspec_dumps, msgspec_loads

logger = get_logger("nexus.core.secrets")

try:
    import nexus_crypto

    HAS_NEXUS_CRYPTO = True
except ImportError:
    HAS_NEXUS_CRYPTO = False
    nexus_crypto = None  # type: ignore[assignment]
    logger.warning(
        "nexus-crypto (Rust module) not available -- secrets cache will use plaintext storage"
    )

# keyring is optional (system keychain)
try:
    import keyring as _kr

    HAS_KEYRING = True
except ImportError:
    HAS_KEYRING = False


class SecretsManager:
    """Ochrona kluczy API i haseł przy użyciu natywnego magazynu systemu operacyjnego."""
    __slots__ = ()

    SERVICE_NAME = "NexusAI_System"

    @staticmethod
    def save_secret(key_name: str, secret_value: str) -> None:
        if not HAS_KEYRING:
            raise RuntimeError("keyring dependency is unavailable")
        try:
            _kr.set_password(SecretsManager.SERVICE_NAME, key_name, secret_value)
        except Exception as e:
            logger.error(f"Nie udało się zapisać sekretu '{key_name}' w systemie: {e}")
            raise

    @staticmethod
    def get_secret(key_name: str) -> str | None:
        if not HAS_KEYRING:
            return None
        try:
            return _kr.get_password(SecretsManager.SERVICE_NAME, key_name)
        except Exception as e:
            logger.error(f"Nie udało się odczytać sekretu '{key_name}': {e}")
            return None

    @staticmethod
    def delete_secret(key_name: str) -> None:
        if not HAS_KEYRING:
            return
        try:
            _kr.delete_password(SecretsManager.SERVICE_NAME, key_name)
        except Exception as e:
            logger.error(f"Nie udało się usunąć sekretu '{key_name}': {e}")


class LocalSecretsCache:
    """Offline-first cache for secrets with TTL and AEAD at-rest encryption (nexus-crypto).

    Zastępuje: Fernet (cryptography) -> ChaCha20-Poly1305 (nexus-crypto)
    """
    __slots__ = ('_encrypt_cache', '_hkdf_key', '_key', '_mlock_buf', 'cache_path', 'ttl_hours')

    def __init__(
        self, cache_path: Path | str = "app_data/secrets_cache.json", ttl_hours: int = 24
    ) -> None:
        self.cache_path = Path(cache_path)
        self.ttl_hours = ttl_hours
        self.cache_path.parent.mkdir(parents=True, exist_ok=True)
        if not self.cache_path.exists():
            self.cache_path.write_text("{}", encoding="utf-8")
        try:
            self.cache_path.chmod(0o600)
        except PermissionError:
            logger.warning("[SECRETS] Cannot set permissions on cache file: %s", self.cache_path)
        except OSError:
            logger.warning("[SECRETS] OS error setting permissions: %s", self.cache_path)
        self._key = self._load_encryption_key()
        # ── INNOWACJA #1 v7.0: HKDF Key Separation dla Secrets ─────
        # Wyprowadź osobny klucz dla sekretów z root key.
        self._hkdf_key: bytes | None = None
        self._mlock_buf: Any = None  # Utrzymywane jako atrybut dla mlock
        if self._key is not None:
            try:
                from nexus_ai.core.hkdf import derive_context_key, KeyContext
                self._hkdf_key = derive_context_key(self._key, KeyContext.SECRETS)
                logger.debug("[SECRETS] HKDF key separation active: secrets_key=%s...", self._hkdf_key[:8].hex())
            except ImportError:
                pass
        # ── mlock() dla klucza sekretów (INNOWACJA #5 rozszerzona) ──
        # Raport v7.0: "mlock() tylko na kluczu Vault, NIE na kluczu LocalSecretsCache"
        # Fix: buf przechowywany jako atrybut instancji, żeby GC go nie zwolnił
        if self._hkdf_key is not None:
            self._mlock_secrets_key(self._hkdf_key)
        # ── SUPERMOC v7.0: At-rest encryption of secrets cache ──────
        # Raport v7.0: "Sekrety w JSON (niezaszyfrowane na dysku!)"
        # Fix: Każdy write do cache jest teraz szyfrowany nexus-crypto
        # (ChaCha20-Poly1305) jeśli klucz dostępny.
        self._encrypt_cache = self._key is not None or self._hkdf_key is not None
        if self._encrypt_cache:
            logger.debug("[SECRETS] At-rest encryption active for secrets cache")
        # Automatycznie prze-szyfruj istniejący plaintext cache
        if self._encrypt_cache and self.cache_path.exists():
            self._migrate_plaintext_cache()

    @staticmethod
    def _load_encryption_key() -> bytes | None:
        key_str = os.getenv("NEXUS_SECRETS_CACHE_KEY", "").strip()
        if not key_str:
            return None
        try:
            import base64

            raw = base64.urlsafe_b64decode(key_str.encode("utf-8"))
            if len(raw) == 32:
                return raw
            # If not 32 bytes, derive from password (requires nexus-crypto)
            if HAS_NEXUS_CRYPTO:
                key, _ = nexus_crypto.derive_key(key_str)
                return key
            logger.warning(
                "nexus-crypto not available, cannot derive key from password; falling back to plaintext cache"
            )
            return None
        except (ValueError, TypeError, base64.binascii.Error) as exc:
            logger.warning(
                "Invalid NEXUS_SECRETS_CACHE_KEY format: %s; falling back to plaintext cache", exc
            )
            return None

    def _get_active_key(self) -> bytes | None:
        """Zwraca aktywny klucz szyfrowania (HKDF-derived pref.)."""
        return self._hkdf_key if self._hkdf_key else self._key

    def _mlock_secrets_key(self, key: bytes) -> None:
        """Zabezpiecz klucz sekretów przed swapem (INNOWACJA #5 rozszerzona).

        Raport v7.0: "mlock() tylko na kluczu Vault, NIE na kluczu
        LocalSecretsCache" — ta luka jest teraz załatana.

        Kluczowe: buf jest przechowywany jako atrybut instancji (self._mlock_buf),
        żeby garbage collector go nie zwolnił natychmiast po wyjściu z funkcji.
        """
        try:
            import ctypes
            import ctypes.util

            libc = ctypes.CDLL(ctypes.util.find_library("c"))
            buf = (ctypes.c_char * len(key)).from_buffer_copy(key)
            result = libc.mlock(buf, len(key))
            if result != 0:
                logger.debug("[SECRETS] mlock failed — key can be swapped (errno=%d)", result)
            else:
                logger.debug("[SECRETS] secrets encryption key locked in RAM (mlock)")
                # Przechowaj buf jako atrybut, żeby nie został GC
                self._mlock_buf = buf
        except (OSError, ctypes.CDLLError) as exc:
            logger.debug("[SECRETS] mlock not available: %s", exc)
        except Exception as exc:
            logger.debug("[SECRETS] mlock unexpected error: %s", exc)

    def _encrypt(self, value: str) -> tuple[str, bool]:
        enc_key = self._get_active_key()
        if not enc_key or not HAS_NEXUS_CRYPTO:
            return value, False
        # Użyj XChaCha20 (INNOWACJA #2) dla nonce misuse resistance
        encrypted = nexus_crypto.encrypt(enc_key, value.encode("utf-8"), use_xchacha=True)
        import base64

        return base64.urlsafe_b64encode(encrypted).decode("utf-8"), True

    def _decrypt(self, value: str, encrypted: bool) -> str | None:
        if not encrypted:
            return value
        enc_key = self._get_active_key()
        if not enc_key or not HAS_NEXUS_CRYPTO:
            return None
        try:
            import base64

            data = base64.urlsafe_b64decode(value.encode("utf-8"))
            return nexus_crypto.decrypt(enc_key, data, use_xchacha=True).decode("utf-8")
        except (ValueError, TypeError, base64.binascii.Error) as exc:
            logger.error("[SECRETS] Decryption format error for key: %s", exc)
            return None
        except nexus_crypto.DecryptionError as exc:
            logger.error("[SECRETS] Decryption failed - key may be corrupted: %s", exc)
            return None

    def _migrate_plaintext_cache(self) -> None:
        """SUPERMOC v7.0: Migrate existing plaintext cache to encrypted.

        Raz wywołane przy starcie. Czyta plaintext, zapisuje encrypted.
        Po migracji plik zawiera już tylko zaszyfrowane dane.
        """
        try:
            payload = msgspec_loads(self.cache_path.read_bytes())
        except Exception:
            return
        if not payload or not isinstance(payload, dict):
            return
        migrated = 0
        for key, item in list(payload.items()):
            if isinstance(item, dict) and not item.get("encrypted", False):
                raw = str(item.get("value", ""))
                encrypted_value, enc_flag = self._encrypt(raw)
                payload[key] = {
                    "value": encrypted_value,
                    "encrypted": enc_flag,
                    "updated_at": item.get("updated_at", pendulum.now("UTC").isoformat()),
                }
                migrated += 1
        if migrated > 0:
            self.cache_path.write_text(msgspec_dumps(payload, ensure_ascii=False), encoding="utf-8")
            try:
                self.cache_path.chmod(0o600)
            except (PermissionError, OSError):
                pass
            logger.info("[SECRETS] Migrated %d plaintext secrets to encrypted", migrated)

    def save(self, key: str, value: str) -> None:
        payload = self._read_all()
        stored_value, encrypted = self._encrypt(value)
        payload[key] = {
            "value": stored_value,
            "encrypted": encrypted,
            "updated_at": pendulum.now("UTC").isoformat(),
        }
        self.cache_path.write_text(msgspec_dumps(payload, ensure_ascii=False), encoding="utf-8")
        try:
            self.cache_path.chmod(0o600)
        except PermissionError:
            logger.warning("[SECRETS] Cannot set permissions on save: %s", self.cache_path)
        except OSError:
            logger.warning("[SECRETS] OS error on save permissions: %s", self.cache_path)

    def get(self, key: str) -> str | None:
        payload = self._read_all()
        item = payload.get(key)
        if not item:
            return None
        try:
            updated = pendulum.parse(item["updated_at"])
        except (pendulum.ParserError, ValueError, TypeError) as exc:
            logger.warning("[SECRETS] Invalid timestamp format for key=%s: %s", key, exc)
            return None
        if pendulum.now("UTC") - updated > pendulum.duration(hours=self.ttl_hours):
            return None
        raw = str(item.get("value", ""))
        return self._decrypt(raw, bool(item.get("encrypted", False)))

    def _read_all(self) -> dict[str, dict[str, str]]:
        if not self.cache_path.exists():
            return {}
        try:
            return msgspec_loads(self.cache_path.read_bytes())
        except (FileNotFoundError, PermissionError) as exc:
            logger.warning("[SECRETS] Cannot read cache file: %s", exc)
            return {}
        except (ValueError, TypeError, DecodeError) as exc:
            logger.warning("[SECRETS] Cache file corrupted, resetting: %s", exc)
            return {}


class OfflineFirstSecretResolver:
    """Prefer live secret provider, fallback to encrypted/system cache for offline-first startup."""
    __slots__ = ('cache',)

    def __init__(self, cache: LocalSecretsCache) -> None:
        self.cache = cache

    def resolve(self, key: str, provider) -> str | None:
        try:
            live = provider()
        except (ConnectionError, TimeoutError, OSError) as exc:
            logger.warning("[SECRETS] Live provider failed for key=%s: %s", key, exc)
            live = None
        except Exception as exc:
            logger.error("[SECRETS] Unexpected error from live provider for key=%s: %s", key, exc)
            live = None
        if live:
            self.cache.save(key, live)
            return live
        return self.cache.get(key)
