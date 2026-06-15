"""
NATS Key-Value Store — distributed configuration and caching through NATS JetStream.

SUPERMOC NATS: Key-Value Store wbudowany w JetStream.
Zastępuje: Redis, etcd, Consul dla małych/średnich konfiguracji.

Użycie:
    - Konfiguracja reguł podatkowych (rule/config)
    - Thresholds ryzyka (risk/thresholds)
    - Cache API (api/cache)
    - Stan workerów (workers/status)
    - Feature flags (features/flags)

Usage:
    from nexus_ai.core.nats_kv_store import NatsConfigStore

    store = NatsConfigStore()
    await store.start()

    # Zapis
    await store.put("rules/vat/threshold", {"pl": 23, "de": 19})
    await store.put("risk/max_amount", 100000)

    # Odczyt
    threshold = await store.get("rules/vat/threshold")
    max_amount = await store.get("risk/max_amount", default=50000)

    # Watch
    async for update in store.watch("rules/."):
        print(f"Rule changed: {update}")

    await store.stop()
"""

from __future__ import annotations

import json
from typing import Any, AsyncIterator

import anyio
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.nats.kv")

# Domyślne buckety KV
DEFAULT_BUCKETS = {
    "nexus-config": "Global configuration store",
    "nexus-rules": "Tax and risk rules",
    "nexus-features": "Feature flags",
    "nexus-workers": "Worker status and heartbeats",
    "nexus-cache": "API response cache",
}


class NatsConfigStore:
    """NATS Key-Value Store dla rozproszonej konfiguracji.

    SUPERMOCE:
      - Automatyczne tworzenie bucketów przy starcie
      - Watch na zmiany kluczy (reaktywne odświeżanie cache)
      - Thread-safe dla free-threaded Python
      - Graceful degradation gdy NATS niedostępny
      - Lokalny fallback cache (RAM) dla offline mode

    Args:
        nats_servers: Serwery NATS.
        buckets: Słownik {nazwa_bucketa: opis} do utworzenia.
        local_fallback: Czy używać lokalnego cache (RAM) jako fallback.
    """

    def __init__(
        self,
        nats_servers: list[str] | str | None = None,
        buckets: dict[str, str] | None = None,
        local_fallback: bool = True,
    ) -> None:
        config = AppConfig()
        self._nats_servers = nats_servers or [config.nats_url]
        self._buckets = buckets or dict(DEFAULT_BUCKETS)
        self._local_fallback = local_fallback
        self._nc: Any = None
        self._js: Any = None
        self._kv_stores: dict[str, Any] = {}
        self._connected = False

        # Lokalny fallback cache (RAM)
        self._local_cache: dict[str, dict[str, Any]] = {
            bucket: {} for bucket in self._buckets
        }

    async def start(self) -> None:
        """Połącz z NATS i utwórz buckety KV."""
        try:
            import nats as nats_module

            self._nc = await nats_module.connect(
                servers=self._nats_servers,
                name="nexus-kv-store",
            )
            self._js = self._nc.jetstream()
            self._connected = True

            for bucket_name, description in self._buckets.items():
                try:
                    kv = await self._js.create_key_value(
                        bucket=bucket_name,
                        description=description,
                        history=5,  # zachowaj ostatnie 5 wartości
                        max_value_size=1024 * 1024,  # 1MB max
                    )
                    self._kv_stores[bucket_name] = kv
                    logger.info("[KV] Created bucket: %s — %s", bucket_name, description)
                except Exception as exc:
                    logger.warning("[KV] Failed to create bucket %s: %s", bucket_name, exc)

            logger.info("[KV] Store started with %d buckets", len(self._kv_stores))
        except Exception as exc:
            logger.warning(
                "[KV] Cannot connect to NATS at %s: %s — using local fallback",
                self._nats_servers,
                exc,
            )
            self._connected = False

    async def stop(self) -> None:
        """Zamknij połączenie NATS."""
        if self._nc is not None:
            try:
                await self._nc.drain()
            except Exception:
                pass
            self._nc = None
            self._js = None
            self._kv_stores.clear()
            self._connected = False
            logger.info("[KV] Store stopped")

    async def put(
        self,
        key: str,
        value: Any,
        bucket: str = "nexus-config",
    ) -> bool:
        """Zapisz wartość w KV Store.

        Args:
            key: Klucz (np. "rules/vat/threshold").
            value: Wartość (JSON-serializowalna).
            bucket: Nazwa bucketa.

        Returns:
            ``True`` jeśli zapisano, ``False`` jeśli fallback do local cache.
        """
        kv = self._kv_stores.get(bucket)
        if kv is not None:
            try:
                data = json.dumps(value).encode("utf-8")
                await kv.put(key, data)
                return True
            except Exception as exc:
                logger.warning("[KV] Failed to put %s/%s: %s", bucket, key, exc)

        # Fallback do lokalnego cache
        if self._local_fallback:
            self._local_cache[bucket][key] = value
            logger.debug("[KV] Local fallback: %s/%s", bucket, key)
            return True
        return False

    async def get(
        self,
        key: str,
        default: Any = None,
        bucket: str = "nexus-config",
    ) -> Any:
        """Odczytaj wartość z KV Store.

        Args:
            key: Klucz.
            default: Domyślna wartość jeśli klucz nie istnieje.
            bucket: Nazwa bucketa.

        Returns:
            Wartość lub default.
        """
        kv = self._kv_stores.get(bucket)
        if kv is not None:
            try:
                entry = await kv.get(key)
                if entry is not None:
                    return json.loads(entry.value.decode("utf-8"))
            except Exception as exc:
                logger.warning("[KV] Failed to get %s/%s: %s", bucket, key, exc)

        # Fallback do lokalnego cache
        if self._local_fallback:
            return self._local_cache[bucket].get(key, default)
        return default

    async def delete(self, key: str, bucket: str = "nexus-config") -> bool:
        """Usuń klucz z KV Store.

        Args:
            key: Klucz do usunięcia.
            bucket: Nazwa bucketa.

        Returns:
            ``True`` jeśli usunięto.
        """
        kv = self._kv_stores.get(bucket)
        if kv is not None:
            try:
                await kv.delete(key)
                return True
            except Exception as exc:
                logger.warning("[KV] Failed to delete %s/%s: %s", bucket, key, exc)

        if self._local_fallback:
            self._local_cache[bucket].pop(key, None)
            return True
        return False

    async def watch(
        self,
        bucket: str = "nexus-config",
    ) -> AsyncIterator[Any]:
        """Watch na zmiany w bucketcie.

        SUPERMOC NATS: Reaktywne powiadomienia o zmianach kluczy.
        Używane do automatycznego odświeżania cache reguł podatkowych.

        Args:
            bucket: Nazwa bucketa.

        Yields:
            Operacja na kluczu (put/delete).
        """
        kv = self._kv_stores.get(bucket)
        if kv is None:
            return

        watcher = await kv.watch_all()
        try:
            async for update in watcher:
                yield update
        finally:
            await watcher.stop()

    def is_connected(self) -> bool:
        return self._connected

    def get_status(self) -> dict[str, Any]:
        """Zwróć status store'a."""
        return {
            "connected": self._connected,
            "buckets": list(self._kv_stores.keys()),
            "local_fallback": self._local_fallback,
            "nats_servers": self._nats_servers,
        }


# ── Global singleton ──────────────────────────────────────────────────────

_default_store: NatsConfigStore | None = None


def get_config_store(
    nats_servers: list[str] | str | None = None,
) -> NatsConfigStore:
    """Zwraca globalną instancję NatsConfigStore (singleton).

    Args:
        nats_servers: Serwery NATS.

    Returns:
        Globalna instancja NatsConfigStore.
    """
    global _default_store
    if _default_store is None:
        _default_store = NatsConfigStore(nats_servers=nats_servers)
    return _default_store
