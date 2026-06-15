"""Unified file storage service using fsspec with configurable backend protocol.

SUPERMOC fsspec:
- ``fsspec.open()`` — uniwersalne otwieranie plików w każdym protokole (file://, s3://, sftp://, memory://)
- ``fsspec.filesystem()`` — konfigurowalny backend przez config TOML
- ``auto_mkdir`` — automatyczne tworzenie katalogów (CachingFileSystem opcjonalnie)
- ``fsspec.open_async`` — async file I/O bez blokowania event loop

Zgodnie z aa3fvcx.txt: jeden URL, nieskończenie wiele backendów.
Zmiana storage_protocol w config TOML zmienia backend bez zmiany kodu.
"""

from __future__ import annotations

import io
import uuid
from collections.abc import Iterable
from pathlib import Path
from collections.abc import MutableMapping
from typing import BinaryIO, final

import anyio
import fsspec
from anyio import to_thread

from nexus_ai.core.config import AppConfig
from nexus_ai.core.logger import get_logger

logger = get_logger(__name__)

UPLOAD_CHUNK_SIZE = 1024 * 1024


@final
class StorageService:
    """Unified file storage service with configurable fsspec backend.

    SUPERMOC fsspec:
    - Domyślnie ``file://`` (lokalny FS), ale config ``storage_protocol = "s3"`` zmienia
      backend na S3 bez zmiany kodu biznesowego.
    - ``storage_auto_mkdir = true`` automatycznie tworzy katalogi.
    - ``storage_cache_size_mb > 0`` włącza przezroczyste CachingFileSystem.

    Usage:
        config = AppConfig()
        storage = StorageService(config)
        path = await storage.save_invoice_bytes_async(b"PDF data...", "invoice.pdf")
    """

    def __init__(self, config: AppConfig) -> None:
        self._protocol = config.storage_protocol
        self._config = config
        self._base_path = config.base_dir / config.storage_root

        # SUPERMOC fsspec: konfigurowalny backend przez config TOML
        fs_kwargs: dict = {}
        if config.storage_auto_mkdir:
            fs_kwargs["auto_mkdir"] = True

        self._fs = fsspec.filesystem(self._protocol, **fs_kwargs)

        # SUPERMOC: CachingFileSystem dla przezroczystego cache'owania
        if config.storage_cache_size_mb > 0:
            from fsspec.implementations.cached import CachingFileSystem

            cache_storage = config.base_dir / "app_data" / "fsspec_cache"
            cache_storage.mkdir(parents=True, exist_ok=True)
            self._fs = CachingFileSystem(
                target_protocol=self._protocol,
                cache_storage=str(cache_storage),
                maxsize=config.storage_cache_size_mb * 1024 * 1024,
                same_names=True,
            )

        if self._protocol == "file":
            self._fs.makedirs(str(self._base_path), exist_ok=True)
        logger.info(
            "[StorageService] Initialized: protocol=%s root=%s cache=%dMB",
            self._protocol,
            self._base_path,
            config.storage_cache_size_mb,
        )

    def _resolve_url(self, relative_path: str) -> str:
        """Zwraca pełny URL fsspec dla ścieżki względnej."""
        if self._protocol == "file":
            return str(self._base_path / relative_path)
        return f"{self._protocol}://{self._base_path}/{relative_path}"

    def _local_path(self, original_name: str | None = None) -> str:
        """Zwraca względną ścieżkę pliku z UUID."""
        suffix = Path(original_name or "").suffix if original_name else ""
        return f"{uuid.uuid4().hex}{suffix}"

    def _ensure_protocol_prefix(self, path: str) -> str:
        """Dodaje prefix protokołu jeśli brak."""
        if "://" not in path and not path.startswith("/"):
            return self._resolve_url(path)
        return path

    # ── Sync API (kompatybilność wsteczna) ──────────────────────────────────

    def save_invoice_stream(
        self,
        stream: BinaryIO | Iterable[bytes],
        original_name: str | None = None,
        chunk_size: int = UPLOAD_CHUNK_SIZE,
    ) -> str:
        """Save file content using chunked streaming (sync, wątek roboczy).

        SUPERMOC fsspec: ``fsspec.open()`` działa z każdym protokołem.
        """
        rel_path = self._local_path(original_name)
        url = self._resolve_url(rel_path)

        with fsspec.open(url, "wb") as out:
            if hasattr(stream, "read"):
                file_obj = stream  # type: ignore[assignment]
                while True:
                    chunk = file_obj.read(chunk_size)
                    if not chunk:
                        break
                    out.write(chunk)
            else:
                for chunk in stream:
                    if chunk:
                        out.write(chunk)

        return url

    def save_invoice_file(self, source_path: str) -> str:
        """Copy file to internal storage using fsspec (sync)."""
        rel_path = self._local_path(Path(source_path).name)
        url = self._resolve_url(rel_path)

        # SUPERMOC: fsspec.open() dla źródła i celu
        with fsspec.open(source_path, "rb") as src:
            with fsspec.open(url, "wb") as dst:
                while True:
                    chunk = src.read(UPLOAD_CHUNK_SIZE)
                    if not chunk:
                        break
                    dst.write(chunk)

        return url

    def save_invoice_bytes(self, payload: bytes, original_name: str | None = None) -> str:
        """Compatibility helper for in-memory payloads (sync)."""
        return self.save_invoice_stream(io.BytesIO(payload), original_name=original_name)

    # ── Async API (SUPERMOC: non-blocking file I/O) ─────────────────────────

    async def save_invoice_stream_async(
        self,
        stream: BinaryIO | Iterable[bytes],
        original_name: str | None = None,
        chunk_size: int = UPLOAD_CHUNK_SIZE,
    ) -> str:
        """Save file content using async fsspec I/O — nie blokuje event loop.

        SUPERMOC fsspec: ``await fsspec.open_async()`` dla async file I/O.
        """
        rel_path = self._local_path(original_name)
        url = self._resolve_url(rel_path)

        # SUPERMOC: fsspec.open_async — async file I/O bez wątków
        async with await fsspec.open_async(url, "wb") as out:
            if hasattr(stream, "read"):
                file_obj = stream  # type: ignore[assignment]
                while True:
                    chunk = await to_thread.run_sync(file_obj.read, chunk_size)
                    if not chunk:
                        break
                    await out.write(chunk)
            else:
                for chunk in stream:
                    if chunk:
                        await out.write(chunk)

        return url

    async def save_invoice_bytes_async(
        self, payload: bytes, original_name: str | None = None
    ) -> str:
        """Save in-memory bytes using async fsspec I/O."""
        return await self.save_invoice_stream_async(
            io.BytesIO(payload), original_name=original_name
        )

    async def read_file_async(self, url: str) -> bytes:
        """Read entire file as bytes using async fsspec I/O.

        SUPERMOC fsspec: ``await fsspec.open_async(url, "rb")`` dla async read.
        """
        url = self._ensure_protocol_prefix(url)
        async with await fsspec.open_async(url, "rb") as f:
            return await f.read()

    async def delete_file_async(self, url: str) -> bool:
        """Delete file using fsspec (async wrapper)."""
        url = self._ensure_protocol_prefix(url)

        def _delete() -> bool:
            if self._fs.exists(url):
                self._fs.rm(url)
                return True
            return False

        return await to_thread.run_sync(_delete)

    async def file_exists_async(self, url: str) -> bool:
        """Check if file exists using fsspec."""
        url = self._ensure_protocol_prefix(url)

        def _exists() -> bool:
            return self._fs.exists(url)

        return await to_thread.run_sync(_exists)

    # ── SUPERMOC: fsspec.get_mapper() — dict-like interface ─────────────────

    def get_mapper(self, prefix: str = "") -> MutableMapping:
        """Zwraca fsspec.get_mapper() — dict-like interface do storage.

        SUPERMOC fsspec:
        ``fsspec.get_mapper(url)`` tworzy ``MutableMapping`` (dict-like),
        idealny do przechowywania metadanych, małych plików, konfiguracji.
        Zwraca ``fsspec.mapping.FSMap`` implementujący ``MutableMapping``.
        """
        url = self._resolve_url(prefix)
        return fsspec.get_mapper(url)

    @property
    def fs(self):
        """Bezpośredni dostęp do instancji fsspec filesystem."""
        return self._fs
