from __future__ import annotations

import importlib.util


def _load_keyring_module():
    if importlib.util.find_spec("keyring") is None:
        return None
    import keyring
    return keyring


def _load_fernet_symbols():
    """Load Fernet cryptography symbols, gracefully falling back if unavailable.

    The cryptography package may be installed but its native Rust extension
    (_rust.abi3.so) can fail to load in some environments (e.g., Termux
    without libgcc_s.so.1). We install a meta-path blocker first to
    prevent the native extension from even being attempted, then
    catch ImportError as a safety net.
    """
    # ── Block cryptography imports at the sys.meta_path level ──────
    # This prevents Python from even trying to load the problematic
    # _rust.abi3.so native extension, which would otherwise fail with
    # "dlopen failed: library libgcc_s.so.1 not found" on Termux.
    _BLOCKED = {"cryptography", "cryptography.fernet", "cryptography.hazmat",
                 "cryptography.exceptions", "cryptography.hazmat.bindings",
                 "cryptography.hazmat.bindings._rust"}

    class _CryptographyBlocker:
        def find_spec(self, fullname, path, target=None):
            if fullname in _BLOCKED or fullname.startswith("cryptography."):
                raise ImportError(
                    f"cryptography native extension blocked (missing libgcc_s.so.1)"
                )
            return None

    import sys
    blocker = _CryptographyBlocker()
    sys.meta_path.insert(0, blocker)

    # ── Safety net: try importing anyway (should be blocked above) ──
    try:
        from cryptography.fernet import Fernet, InvalidToken
        return Fernet, InvalidToken
    except ImportError:
        return None, None
    finally:
        # Remove the blocker so it doesn't interfere with other imports
        if blocker in sys.meta_path:
            sys.meta_path.remove(blocker)


keyring = _load_keyring_module()
Fernet, InvalidToken = _load_fernet_symbols()
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
import logging
import os

logger = logging.getLogger("nexus.core.secrets")

class SecretsManager:
    """Ochrona kluczy API i haseł przy użyciu natywnego magazynu systemu operacyjnego."""
    SERVICE_NAME = "NexusAI_System"

    @staticmethod
    def save_secret(key_name: str, secret_value: str) -> None:
        if keyring is None:
            raise RuntimeError("keyring dependency is unavailable")
        try:
            keyring.set_password(SecretsManager.SERVICE_NAME, key_name, secret_value)
        except Exception as e:
            logger.error(f"Nie udało się zapisać sekretu '{key_name}' w systemie: {e}")
            raise

    @staticmethod
    def get_secret(key_name: str) -> str | None:
        if keyring is None:
            return None
        try:
            return keyring.get_password(SecretsManager.SERVICE_NAME, key_name)
        except Exception as e:
            logger.error(f"Nie udało się odczytać sekretu '{key_name}': {e}")
            return None

    @staticmethod
    def delete_secret(key_name: str) -> None:
        if keyring is None:
            return
        try:
            keyring.delete_password(SecretsManager.SERVICE_NAME, key_name)
        except Exception as e:
            logger.error(f"Nie udało się usunąć sekretu '{key_name}': {e}")


class LocalSecretsCache:
    """Offline-first cache for secrets with TTL and optional at-rest encryption."""

    def __init__(self, cache_path: Path | str = "app_data/secrets_cache.json", ttl_hours: int = 24) -> None:
        self.cache_path = Path(cache_path)
        self.ttl_hours = ttl_hours
        self.cache_path.parent.mkdir(parents=True, exist_ok=True)
        if not self.cache_path.exists():
            self.cache_path.write_text("{}", encoding="utf-8")
        try:
            self.cache_path.chmod(0o600)
        except Exception:
            pass
        self._fernet = self._build_fernet()

    @staticmethod
    def _build_fernet():
        if Fernet is None:
            return None
        key = os.getenv("NEXUS_SECRETS_CACHE_KEY", "").strip().encode("utf-8")
        if not key:
            return None
        try:
            return Fernet(key)
        except Exception:
            logger.warning("Invalid NEXUS_SECRETS_CACHE_KEY; falling back to plaintext cache")
            return None

    def _encrypt(self, value: str) -> tuple[str, bool]:
        if not self._fernet:
            return value, False
        token = self._fernet.encrypt(value.encode("utf-8")).decode("utf-8")
        return token, True

    def _decrypt(self, value: str, encrypted: bool) -> str | None:
        if not encrypted:
            return value
        if not self._fernet:
            return None
        try:
            return self._fernet.decrypt(value.encode("utf-8")).decode("utf-8")
        except (InvalidToken, Exception):
            return None

    def save(self, key: str, value: str) -> None:
        payload = self._read_all()
        stored_value, encrypted = self._encrypt(value)
        payload[key] = {
            "value": stored_value,
            "encrypted": encrypted,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        self.cache_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
        try:
            self.cache_path.chmod(0o600)
        except Exception:
            pass

    def get(self, key: str) -> str | None:
        payload = self._read_all()
        item = payload.get(key)
        if not item:
            return None
        try:
            updated = datetime.fromisoformat(item["updated_at"])
        except Exception:
            return None
        if datetime.now(timezone.utc) - updated > timedelta(hours=self.ttl_hours):
            return None
        raw = str(item.get("value", ""))
        return self._decrypt(raw, bool(item.get("encrypted", False)))

    def _read_all(self) -> dict[str, dict[str, str]]:
        if not self.cache_path.exists():
            return {}
        try:
            return json.loads(self.cache_path.read_text(encoding="utf-8"))
        except Exception:
            return {}


class OfflineFirstSecretResolver:
    """
    Prefer live secret provider, fallback to encrypted/system cache for offline-first startup.
    Provider must be a callable returning secret value or None.
    """

    def __init__(self, cache: LocalSecretsCache) -> None:
        self.cache = cache

    def resolve(self, key: str, provider) -> str | None:
        try:
            live = provider()
        except Exception:
            live = None
        if live:
            self.cache.save(key, live)
            return live
        return self.cache.get(key)
