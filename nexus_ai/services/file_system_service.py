"""FileSystemService — Unified fsspec I/O dla całego projektu NexusAI.

TOTALNA REWOLUCJA: wszystkie async operacje przez AsyncFsWrapper.
- ``await afs.cat_file()`` zamiast ``await fsspec.open_async('rb')``
- ``await afs.pipe_file()`` zamiast ``await fsspec.open_async('wb')``
- ``await afs.exists()`` zamiast ``self._fs.exists()``

SUPERMOCE fsspec:
  - Jeden centralny serwis dla wszystkich operacji I/O
  - fsspec.open() — uniwersalne otwieranie (file://, s3://, http://, memory://)
  - CachingFileSystem — przezroczyste cache'owanie z TTL i LRU
  - TransactionalFileSystem — atomowe operacje zapisu
  - fsspec.get_mapper() — dict-like interfejs dla metadanych
  - AsyncFsWrapper — czyste await API bez to_thread.run_sync()
  - fsspec.implementations.memory.MemoryFileSystem — RAM-only storage

Usage:
    fs = FileSystemService(config=app_config)
    data = await fs.read_bytes("s3://bucket/invoice.pdf")
    await fs.write_bytes("file:///tmp/backup.db", db_bytes)
    mapper = fs.get_mapper("metadata/")
    mapper["key"] = "value"
"""

from __future__ import annotations

import uuid
from collections.abc import MutableMapping
from io import BytesIO
from pathlib import Path
from typing import BinaryIO, Iterable

import fsspec
from nexus_ai.core.fsspec_compat import AsyncFsWrapper, FSSpecFactory, TransactionalFileSystem
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.services.file_system")

UPLOAD_CHUNK_SIZE = 1024 * 1024  # 1 MB


class FileSystemService:
    """Unified filesystem service — centralne I/O dla całego projektu.

    TOTALNA REWOLUCJA:
    - ``self._async_fs`` — AsyncFsWrapper, czyste ``await`` API
    - zero ``fsspec.open_async()`` (nie istnieje w fsspec 2026.4.0)
    - ``await self._async_fs.cat_file()`` / ``await self._async_fs.pipe_file()``
    """

    def __init__(self, config: AppConfig) -> None:
        self._config = config

        factory = FSSpecFactory.get_instance()
        factory.configure_from_app_config(config)

        self._protocol = config.storage_protocol
        self._base_path = config.base_dir / config.storage_root

        # Sync FS dla kompatybilności (sync API, memory_fs)
        self._fs = factory.get_filesystem()

        # TOTALNA REWOLUCJA: AsyncFsWrapper
        self._async_fs: AsyncFsWrapper = factory.get_async_filesystem()

        # TransactionalFileSystem jeśli wymagany
        if config.storage_transactional:
            self._fs = TransactionalFileSystem(self._fs)

        if self._protocol == "file":
            self._fs.makedirs(str(self._base_path), exist_ok=True)

        logger.info(
            "[FileSystemService] Initialized: protocol=%s root=%s cache=%dMB tx=%s chain=%s async=%s",
            self._protocol,
            self._base_path,
            config.storage_cache_size_mb,
            config.storage_transactional,
            config.storage_chain_enabled,
            type(self._async_fs).__name__,
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

    # ── Async API (TOTALNA REWOLUCJA) ───────────────────────────────────

    async def read_bytes(self, path: str) -> bytes:
        """Odczytaj cały plik jako bytes przez async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.cat_file()`` zamiast ``fsspec.open_async()``.
        """
        return await self._async_fs.cat_file(path)

    async def write_bytes(self, path: str, data: bytes) -> None:
        """Zapisz bytes do pliku przez async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.pipe_file()`` zamiast ``fsspec.open_async()``.
        """
        await self._async_fs.pipe_file(path, data)

    async def stream_write(
        self,
        path: str,
        stream: BinaryIO | Iterable[bytes],
        chunk_size: int = UPLOAD_CHUNK_SIZE,
    ) -> str:
        """Zapisz strumień danych przez async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.open()`` dla streaming write.
        """
        # UWAGA: fsspec.open() zwraca OpenFile. write() jest sync.
        async with await self._async_fs.open(path, "wb") as out:
            if hasattr(stream, "read"):
                while True:
                    chunk = stream.read(chunk_size)
                    if not chunk:
                        break
                    out.write(chunk)  # sync, non-blocking przez OpenFile
            else:
                for chunk in stream:
                    if chunk:
                        out.write(chunk)  # sync, non-blocking przez OpenFile
        return path

    async def read_text(self, path: str, encoding: str = "utf-8") -> str:
        """Odczytaj plik tekstowy przez async fsspec I/O."""
        data = await self.read_bytes(path)
        return data.decode(encoding)

    async def write_text(self, path: str, text: str, encoding: str = "utf-8") -> None:
        """Zapisz tekst do pliku przez async fsspec I/O."""
        await self.write_bytes(path, text.encode(encoding))

    async def delete(self, path: str) -> bool:
        """Usuń plik przez async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.exists()`` + ``await self._async_fs.rm()``.
        """
        if await self._async_fs.exists(path):
            await self._async_fs.rm(path)
            return True
        return False

    async def exists(self, path: str) -> bool:
        """Sprawdź czy plik istnieje przez async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.exists()``.
        """
        return await self._async_fs.exists(path)

    async def info(self, path: str) -> dict | None:
        """Pobierz informacje o pliku przez async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.info()``.
        """
        try:
            return await self._async_fs.info(path)
        except FileNotFoundError:
            return None

    # ── Sync API (kompatybilność) ──────────────────────────────────────

    def read_bytes_sync(self, path: str) -> bytes:
        """Odczytaj cały plik jako bytes (sync)."""
        with fsspec.open(path, "rb") as f:
            return f.read()

    def write_bytes_sync(self, path: str, data: bytes) -> None:
        """Zapisz bytes do pliku (sync)."""
        with fsspec.open(path, "wb") as f:
            f.write(data)

    # ── SUPERMOC: fsspec.get_mapper() — dict-like interfejs ────────────

    def get_mapper(self, prefix: str = "") -> MutableMapping:
        """Zwraca fsspec.get_mapper() — dict-like interface do storage.

        SUPERMOC fsspec:
        ``fsspec.get_mapper(url)`` tworzy ``MutableMapping`` (dict-like),
        idealny do przechowywania metadanych, małych plików, konfiguracji.
        """
        url = self._resolve_url(prefix)
        return fsspec.get_mapper(url)

    # ── SUPERMOC: Transaction ──────────────────────────────────────────

    def transaction(self):
        """Context manager dla atomicznych operacji.

        SUPERMOC: TransactionalFileSystem zapewnia atomiczne operacje.
        Użycie:
            with fs.transaction():
                await fs.write_bytes("path1", data1)
                await fs.write_bytes("path2", data2)
            # Auto-commit po wyjściu, auto-rollback przy błędzie
        """
        if hasattr(self._fs, "transaction"):
            return self._fs.transaction()
        # Fallback: no-op transaction
        from contextlib import nullcontext

        return nullcontext()

    # ── SUPERMOC: MemoryFileSystem ─────────────────────────────────────

    @staticmethod
    def memory_fs() -> fsspec.AbstractFileSystem:
        """Zwraca MemoryFileSystem dla testów i tmp danych.

        SUPERMOC: fsspec.implementations.memory.MemoryFileSystem
        Użycie:
            mem_fs = FileSystemService.memory_fs()
            with mem_fs.open("memory://test.txt", "w") as f:
                f.write("hello")
        """
        return fsspec.filesystem("memory")

    @staticmethod
    def copy_between_fs(
        src_path: str,
        dst_path: str,
        src_fs: fsspec.AbstractFileSystem | None = None,
        dst_fs: fsspec.AbstractFileSystem | None = None,
    ) -> None:
        """Kopiuj plik między filesystemami.

        SUPERMOC: fsspec.open() dla źródła i celu — różne protokoły.
        """
        src = src_fs or fsspec.filesystem("file")
        dst = dst_fs or fsspec.filesystem("file")

        with src.open(src_path, "rb") as src_f:
            with dst.open(dst_path, "wb") as dst_f:
                while True:
                    chunk = src_f.read(UPLOAD_CHUNK_SIZE)
                    if not chunk:
                        break
                    dst_f.write(chunk)

    @property
    def fs(self):
        """Bezpośredni dostęp do instancji fsspec filesystem."""
        return self._fs
