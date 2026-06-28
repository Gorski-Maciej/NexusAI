from __future__ import annotations

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
        "nexus-crypto (Rust module) not available — secrets cache will use plaintext storage"
    )

# keyring is optional (system keychain)
try:
    import keyring as _kr

    HAS_KEYRING = True
except ImportError:
    HAS_KEYRING = False


class SecretsManager:
    """Ochrona kluczy API i haseł przy użyciu natywnego magazynu systemu operacyjnego."""

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

    Zastępuje: Fernet (cryptography) → ChaCha20-Poly1305 (nexus-crypto)
    """

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

    def _encrypt(self, value: str) -> tuple[str, bool]:
        if not self._key or not HAS_NEXUS_CRYPTO:
            return value, False
        encrypted = nexus_crypto.encrypt(self._key, value.encode("utf-8"))
        import base64

        return base64.urlsafe_b64encode(encrypted).decode("utf-8"), True

    def _decrypt(self, value: str, encrypted: bool) -> str | None:
        if not encrypted:
            return value
        if not self._key or not HAS_NEXUS_CRYPTO:
            return None
        try:
            import base64

            data = base64.urlsafe_b64decode(value.encode("utf-8"))
            return nexus_crypto.decrypt(self._key, data).decode("utf-8")
        except (ValueError, TypeError, base64.binascii.Error) as exc:
            logger.error("[SECRETS] Decryption format error for key: %s", exc)
            return None
        except nexus_crypto.DecryptionError as exc:
            logger.error("[SECRETS] Decryption failed - key may be corrupted: %s", exc)
            return None

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
