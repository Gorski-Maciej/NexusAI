from __future__ import annotations

try:
    import keyring
except Exception:  # pragma: no cover - optional dependency
    keyring = None
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from core.logger import logger

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
    """Offline-first cache for secrets with TTL."""

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

    def save(self, key: str, value: str) -> None:
        payload = self._read_all()
        payload[key] = {
            "value": value,
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
        return str(item.get("value", ""))

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
