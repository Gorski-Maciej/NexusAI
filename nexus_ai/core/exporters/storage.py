"""Storage provider for exporters using fsspec with full superpowers.

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
from anyio import to_thread
from nexus_ai.core.config import AppConfig
from nexus_ai.core.fsspec_compat import (
    CachingFileSystem,
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

    SUPERMOC fsspec:
    - ``CachingFileSystem`` — przezroczyste cache dla zdalnych FS
    - ``TransactionalFileSystem`` — atomowe zapisy
    - ``fsspec.open_async()`` — async file I/O
    - ``fsspec.get_mapper()`` — dict-like metadata
    - ``MemoryFileSystem`` — RAM-only dla testów
    """

    def __init__(self, config: AppConfig | None = None):
        if config is None:
            self._protocol = "file"
            self._base_path = Path("./export_storage")
            self._use_cache = False
            self._cache_size = 0
        else:
            self._protocol = config.storage_protocol
            self._base_path = config.base_dir / config.storage_root
            self._use_cache = config.storage_cache_size_mb > 0
            self._cache_size = config.storage_cache_size_mb

        fs_kwargs: dict = {}
        if config is None or config.storage_auto_mkdir:
            fs_kwargs["auto_mkdir"] = True

        raw_fs = fsspec.filesystem(self._protocol, **fs_kwargs)

        # SUPERMOC: CachingFileSystem dla przezroczystego cache'owania
        if self._use_cache and config is not None:
            cache_storage = config.base_dir / "app_data" / "fsspec_cache_exporters"
            cache_storage.mkdir(parents=True, exist_ok=True)
            self.fs = CachingFileSystem(
                target_protocol=self._protocol,
                cache_storage=str(cache_storage),
                maxsize=self._cache_size * 1024 * 1024,
                same_names=True,
            )
        else:
            self.fs = raw_fs

        # SUPERMOC: TransactionalFileSystem dla atomowych zapisów
        self._tx_fs = TransactionalFileSystem(fs=self.fs)

        if self._protocol == "file":
            self.fs.makedirs(str(self._base_path), exist_ok=True)

        logger.info(
            "[FSSpecStorageProvider] Initialized: protocol=%s root=%s cache=%dMB",
            self._protocol, self._base_path,
            self._cache_size,
        )

    def _resolve_path(self, filename: str) -> str:
        safe_name = Path(filename).name
        if self._protocol == "file":
            return str(self._base_path / safe_name)
        return f"{self._protocol}://{self._base_path}/{safe_name}"

    # ── SUPERMOC: fsspec.open_async() — async file I/O ────────────────────

    async def save_file(self, filename: str, content: bytes) -> str:
        file_path = self._resolve_path(filename)
        # SUPERMOC: fsspec.open_async — async I/O bez blokowania event loop
        async with await fsspec.open_async(file_path, "wb") as handle:
            await handle.write(content)
        return file_path

    async def get_file(self, file_path: str) -> bytes:
        # SUPERMOC: fsspec.open_async — async read
        async with await fsspec.open_async(file_path, "rb") as handle:
            return await handle.read()

    async def delete_file(self, file_path: str) -> bool:
        def _delete() -> bool:
            if self.fs.exists(file_path):
                self.fs.rm(file_path)
                return True
            return False
        return await to_thread.run_sync(_delete)

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
        """Pobierz metadane pliku przez fsspec.info().

        SUPERMOC fsspec: ``fs.info()`` zamiast ``Path.stat()`` —
        działa z każdym protokołem.
        """
        def _info() -> dict:
            info = self.fs.info(file_path)
            return {
                "name": info.get("name", file_path),
                "size": info.get("size", 0),
                "type": info.get("type", "file"),
                "mtime": info.get("mtime", 0),
                "protocol": self._protocol,
            }
        return await to_thread.run_sync(_info)

    def __repr__(self) -> str:
        return f"FSSpecStorageProvider(protocol={self._protocol}, root={self._base_path}, cache={self._cache_size}MB)"
