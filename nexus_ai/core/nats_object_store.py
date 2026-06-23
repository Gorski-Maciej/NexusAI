"""
Object Store — wbudowane w NATS JetStream API do przechowywania plików.

UWAGA: To NIE jest osobna technologia. Object Store to wbudowane API serwera NATS
JetStream, dostępne przez nats-py. Nie wymaga osobnej instalacji ani konfiguracji —
jest częścią NATS Server >=2.10.

SUPERMOC NATS: Object Store wbudowany w JetStream.
Zastępuje: S3, MinIO, lokalne przechowywanie plików dla małych/średnich rozmiarów.

Użycie:
    - PDF faktur (invoices/pdf)
    - Backupów bazy danych (backups/db)
    - Obrazów do OCR (ocr/images)
    - Raportów (reports)

Usage:
    from nexus_ai.core.nats_object_store import NatsFileStore

    store = NatsFileStore()
    await store.start()

    # Zapis pliku
    meta = await store.put("invoices/FV-2026-001.pdf", pdf_bytes)
    print(f"Stored as {meta.name} ({meta.size} bytes)")

    # Odczyt pliku
    data, meta = await store.get("invoices/FV-2026-001.pdf")

    # Lista plików
    async for obj in store.list("invoices/"):
        print(obj.name)

    await store.stop()
"""

from __future__ import annotations

import io
from pathlib import Path
from typing import Any, AsyncIterator

import anyio
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.nats.object")

# Domyślne buckety Object Store
DEFAULT_BUCKETS = {
    "nexus-files": "Invoice PDFs and attachments",
    "nexus-backups": "Database backups",
    "nexus-ocr": "OCR images and results",
    "nexus-reports": "Generated reports",
}


class NatsFileStore:
    """Object Store — wbudowane w NATS JetStream API dla plików.

    UWAGA: To wbudowane API NATS, a nie osobna technologia.

    SUPERMOCE:
      - Automatyczne tworzenie bucketów przy starcie
      - Streamowanie dużych plików przez NATS
      - Metadane (content-type, timestamp) przy każdym pliku
      - Lokalny fallback cache (RAM) dla offline mode
      - Weryfikacja SHA-256 po transferze (niejawnie przez NATS)

    Args:
        nats_servers: Serwery NATS.
        buckets: Słownik {nazwa_bucketa: opis} do utworzenia.
        local_cache_dir: Katalog dla lokalnego cache plików (fallback gdy NATS offline).
    """

    def __init__(
        self,
        nats_servers: list[str] | str | None = None,
        buckets: dict[str, str] | None = None,
        local_cache_dir: str | Path | None = None,
    ) -> None:
        config = AppConfig()
        self._nats_servers = nats_servers or [config.nats_url]
        self._buckets = buckets or dict(DEFAULT_BUCKETS)
        self._nc: Any = None
        self._js: Any = None
        self._object_stores: dict[str, Any] = {}
        self._connected = False

        # Lokalny katalog cache dla offline mode
        if local_cache_dir:
            self._cache_dir = Path(local_cache_dir)
        else:
            self._cache_dir = config.base_dir / "app_data" / "nats_cache"
        self._cache_dir.mkdir(parents=True, exist_ok=True)

    async def start(self) -> None:
        """Połącz z NATS i utwórz buckety Object Store."""
        try:
            import nats as nats_module

            self._nc = await nats_module.connect(
                servers=self._nats_servers,
                name="nexus-object-store",
            )
            self._js = self._nc.jetstream()
            self._connected = True

            for bucket_name, description in self._buckets.items():
                try:
                    obj = await self._js.create_object_store(
                        bucket=bucket_name,
                        description=description,
                        max_age=365 * 24 * 3600,  # 1 rok
                        storage="file",
                    )
                    self._object_stores[bucket_name] = obj
                    logger.info("[OBJECT] Created bucket: %s — %s", bucket_name, description)
                except Exception as exc:
                    logger.warning("[OBJECT] Failed to create bucket %s: %s", bucket_name, exc)

            logger.info("[OBJECT] Store started with %d buckets", len(self._object_stores))
        except Exception as exc:
            logger.warning(
                "[OBJECT] Cannot connect to NATS at %s: %s — using local file cache",
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
            self._object_stores.clear()
            self._connected = False
            logger.info("[OBJECT] Store stopped")

    async def put(
        self,
        key: str,
        data: bytes,
        bucket: str = "nexus-files",
        content_type: str = "application/octet-stream",
        description: str = "",
    ) -> dict[str, Any] | None:
        """Zapisz plik w Object Store.

        SUPERMOC NATS: Object Store automatycznie dzieli duże pliki na chunk'i.

        Args:
            key: Klucz (ścieżka pliku, np. "invoices/FV-2026-001.pdf").
            data: Zawartość pliku (bytes).
            bucket: Nazwa bucketa.
            content_type: Typ MIME pliku.
            description: Opis pliku.

        Returns:
            Metadane zapisanego obiektu lub None.
        """
        obj = self._object_stores.get(bucket)
        if obj is not None:
            try:
                meta = await obj.put(key, io.BytesIO(data))
                logger.info("[OBJECT] Stored %s/%s (%d bytes)", bucket, key, len(data))
                return {
                    "name": meta.name if hasattr(meta, "name") else key,
                    "size": meta.size if hasattr(meta, "size") else len(data),
                    "bucket": bucket,
                }
            except Exception as exc:
                logger.warning("[OBJECT] Failed to store %s/%s: %s", bucket, key, exc)

        # Fallback: lokalny cache plików
        cache_path = self._cache_dir / bucket / key
        cache_path.parent.mkdir(parents=True, exist_ok=True)
        async with await anyio.open_file(cache_path, "wb") as f:
            await f.write(data)
        logger.debug("[OBJECT] Local cache: %s/%s (%d bytes)", bucket, key, len(data))
        return {"name": key, "size": len(data), "bucket": bucket, "cached": True}

    async def get(
        self,
        key: str,
        bucket: str = "nexus-files",
    ) -> tuple[bytes, dict[str, Any]] | tuple[None, None]:
        """Odczytaj plik z Object Store.

        Args:
            key: Klucz (ścieżka pliku).
            bucket: Nazwa bucketa.

        Returns:
            Krotka (data_bytes, metadata_dict) lub (None, None) jeśli nie znaleziono.
        """
        obj = self._object_stores.get(bucket)
        if obj is not None:
            try:
                result = await obj.get(key)
                # ObjectStoreResult ma .data (bytes) i .info (ObjectInfo)
                if result is not None:
                    data = result.data if hasattr(result, "data") else result
                    info = getattr(result, "info", {})
                    meta = {
                        "name": key,
                        "size": len(data) if isinstance(data, bytes) else 0,
                        "bucket": bucket,
                    }
                    # Pobierz metadane z info jeśli dostępne
                    if info:
                        meta["size"] = getattr(info, "size", meta["size"])
                        meta["time"] = str(getattr(info, "time", ""))
                    return data if isinstance(data, bytes) else data.read(), meta
            except Exception as exc:
                logger.warning("[OBJECT] Failed to get %s/%s: %s", bucket, key, exc)

        # Fallback: lokalny cache plików
        cache_path = self._cache_dir / bucket / key
        if cache_path.exists():
            async with await anyio.open_file(cache_path, "rb") as f:
                data = await f.read()
            logger.debug("[OBJECT] Local cache hit: %s/%s", bucket, key)
            return data, {"name": key, "size": len(data), "bucket": bucket, "cached": True}

        return None, None

    async def delete(self, key: str, bucket: str = "nexus-files") -> bool:
        """Usuń plik z Object Store.

        Args:
            key: Klucz (ścieżka pliku).
            bucket: Nazwa bucketa.

        Returns:
            ``True`` jeśli usunięto.
        """
        obj = self._object_stores.get(bucket)
        if obj is not None:
            try:
                await obj.delete(key)
                return True
            except Exception as exc:
                logger.warning("[OBJECT] Failed to delete %s/%s: %s", bucket, key, exc)

        cache_path = self._cache_dir / bucket / key
        if cache_path.exists():
            cache_path.unlink()
            return True
        return False

    async def list(
        self,
        prefix: str = "",
        bucket: str = "nexus-files",
    ) -> AsyncIterator[dict[str, Any]]:
        """Listuj pliki w bucketcie.

        Args:
            prefix: Filtr prefixu (np. "invoices/").
            bucket: Nazwa bucketa.

        Yields:
            Metadane każdego pliku.
        """
        obj = self._object_stores.get(bucket)
        if obj is not None:
            try:
                async for entry in obj.list():
                    name = getattr(entry, "name", "")
                    if prefix and not name.startswith(prefix):
                        continue
                    yield {
                        "name": name,
                        "size": getattr(entry, "size", 0),
                        "time": str(getattr(entry, "time", "")),
                        "bucket": bucket,
                    }
            except Exception:
                pass

        # Listuj lokalny cache
        cache_dir = self._cache_dir / bucket
        if cache_dir.exists():
            for path in cache_dir.rglob("*"):
                if path.is_file():
                    rel_path = str(path.relative_to(cache_dir))
                    if not prefix or rel_path.startswith(prefix):
                        yield {
                            "name": rel_path,
                            "size": path.stat().st_size,
                            "bucket": bucket,
                            "cached": True,
                        }

    def is_connected(self) -> bool:
        return self._connected

    def get_status(self) -> dict[str, Any]:
        """Zwróć status store'a."""
        return {
            "connected": self._connected,
            "buckets": list(self._object_stores.keys()),
            "cache_dir": str(self._cache_dir),
            "nats_servers": self._nats_servers,
        }


# ── Global singleton ──────────────────────────────────────────────────────

_default_store: NatsFileStore | None = None


def get_file_store(
    nats_servers: list[str] | str | None = None,
) -> NatsFileStore:
    """Zwraca globalną instancję NatsFileStore (singleton).

    Args:
        nats_servers: Serwery NATS.

    Returns:
        Globalna instancja NatsFileStore.
    """
    global _default_store
    if _default_store is None:
        _default_store = NatsFileStore(nats_servers=nats_servers)
    return _default_store
