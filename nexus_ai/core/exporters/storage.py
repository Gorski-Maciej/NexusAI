"""Storage provider for exporters using fsspec with full superpowers.

TOTALNA REWOLUCJA: wszystkie operacje I/O przez AsyncFsWrapper.
- ``await afs.cat_file()`` zamiast ``await fsspec.open_async('rb')``
- ``await afs.pipe_file()`` zamiast ``await fsspec.open_async('wb')``
- ``await afs.exists()`` + ``await afs.rm()`` zamiast ``to_thread.run_sync()``

SUPERMOC fsspec:
- ``fsspec.open()`` + ``fsspec.open_async()`` — uniwersalne I/O w każdym protokole
- ``fsspec.filesystem()`` — konfigurowalny backend przez config TOML
- ``TransactionalFileSystem`` — atomowe zapisy plików
- ``CachingFileSystem`` — przezroczyste cache'owanie dla zdalnych FS
- ``fsspec.get_mapper()`` — dict-like interface dla metadanych
- ``MemoryFileSystem`` — RAM-only dla testów

Zgodnie z aa3fvcx.txt: jeden URL, nieskończenie wiele backendów.
Zmiana storage_protocol w config TOML zmienia backend bez zmiany kodu.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from collections.abc import MutableMapping
from pathlib import Path
from typing import Any

import fsspec
from nexus_ai.core.config import AppConfig
from nexus_ai.core.fsspec_compat import (
    AsyncFsWrapper,
    FSSpecFactory,
    MemoryFileSystem,
    TransactionalFileSystem,
)
from nexus_ai.core.logger import get_logger

logger = get_logger(__name__)


class StorageProvider(ABC):
    """Interfejs dla magazynów danych (Lokalny, S3, FTP)."""

    @abstractmethod
    async def save_file(self, filename: str, content: bytes) -> str:
        raise NotImplementedError

    @abstractmethod
    async def get_file(self, file_path: str) -> bytes:
        raise NotImplementedError

    @abstractmethod
    async def delete_file(self, file_path: str) -> bool:
        raise NotImplementedError


class FSSpecStorageProvider(StorageProvider):
    """Provider oparty o fsspec z pełnią supermocy.

    TOTALNA REWOLUCJA:
    - ``self._async_fs`` — AsyncFsWrapper, czyste ``await`` API
    - Zero ``to_thread.run_sync()`` w serwisie
    - Gotowy na S3: zmiana storage_protocol → natywne async I/O
    """

    def __init__(self, config: AppConfig | None = None):
        factory = FSSpecFactory.get_instance()

        if config is None:
            self._protocol = "file"
            self._base_path = Path("./export_storage")
            self._config = None
            self._cache_size = 0
            factory.configure(protocol="file", auto_mkdir=True)
        else:
            self._config = config
            self._protocol = config.storage_protocol
            self._base_path = config.base_dir / config.storage_root
            self._cache_size = config.storage_cache_size_mb
            factory.configure_from_app_config(config)

        # Sync FS dla kompatybilności
        self.fs = factory.get_filesystem()

        # TOTALNA REWOLUCJA: AsyncFsWrapper dla async API
        self._async_fs: AsyncFsWrapper = factory.get_async_filesystem()

        # SUPERMOC: TransactionalFileSystem dla atomowych zapisów
        self._tx_fs = TransactionalFileSystem(fs=self.fs)

        if self._protocol == "file":
            self.fs.makedirs(str(self._base_path), exist_ok=True)

        logger.info(
            "[FSSpecStorageProvider] Initialized: protocol=%s root=%s cache=%dMB async=%s",
            self._protocol,
            self._base_path,
            self._cache_size,
            type(self._async_fs).__name__,
        )

    def _resolve_path(self, filename: str) -> str:
        safe_name = Path(filename).name
        if self._protocol == "file":
            return str(self._base_path / safe_name)
        return f"{self._protocol}://{self._base_path}/{safe_name}"

    # ── TOTALNA REWOLUCJA: AsyncFsWrapper zamiast fsspec.open_async ───────

    async def save_file(self, filename: str, content: bytes) -> str:
        file_path = self._resolve_path(filename)
        # TOTALNA REWOLUCJA: pipe_file zamiast open_async
        await self._async_fs.pipe_file(file_path, content)
        return file_path

    async def get_file(self, file_path: str) -> bytes:
        # TOTALNA REWOLUCJA: cat_file zamiast open_async
        return await self._async_fs.cat_file(file_path)

    async def delete_file(self, file_path: str) -> bool:
        # TOTALNA REWOLUCJA: exists + rm zamiast to_thread.run_sync
        exists = await self._async_fs.exists(file_path)
        if exists:
            await self._async_fs.rm(file_path)
            return True
        return False

    # ── SUPERMOC: TransactionalFileSystem — atomowe operacje ──────────────

    @property
    def tx_fs(self) -> TransactionalFileSystem:
        return self._tx_fs

    def transaction(self):
        """Context manager dla atomowych zapisów przez TransactionalFileSystem."""
        return self._tx_fs.transaction()

    # ── SUPERMOC: fsspec.get_mapper() — dict-like metadata ────────────────

    def get_mapper(self, prefix: str = "") -> MutableMapping:
        """Dict-like interface do metadanych przez fsspec.get_mapper()."""
        path = self._resolve_path(prefix)
        return fsspec.get_mapper(path)

    # ── SUPERMOC: MemoryFileSystem — RAM-only storage ────────────────────

    @staticmethod
    def create_memory() -> FSSpecStorageProvider:
        """Utwórz provider z MemoryFileSystem (RAM-only, idealne dla testów)."""
        provider = object.__new__(FSSpecStorageProvider)
        provider._protocol = "memory"
        provider._base_path = Path("test_export")
        provider.fs = MemoryFileSystem()
        provider._tx_fs = TransactionalFileSystem(fs=provider.fs)
        provider._use_cache = False
        provider._cache_size = 0
        provider.fs.makedirs("test_export", exist_ok=True)
        return provider

    # ── SUPERMOC: get_file_info — metadane przez fsspec.info() ────────────

    async def get_file_info(self, file_path: str) -> dict[str, Any]:
        """Pobierz metadane pliku przez async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.info()`` zamiast ``to_thread.run_sync()``.
        """
        info = await self._async_fs.info(file_path)
        return {
            "name": info.get("name", file_path),
            "size": info.get("size", 0),
            "type": info.get("type", "file"),
            "mtime": info.get("mtime", 0),
            "protocol": self._protocol,
        }

    def __repr__(self) -> str:
        return f"FSSpecStorageProvider(protocol={self._protocol}, root={self._base_path}, cache={self._cache_size}MB)"
