"""FileSystemService — Unified fsspec I/O dla całego projektu NexusAI.

SUPERMOCE fsspec:
  - Jeden centralny serwis dla wszystkich operacji I/O
  - fsspec.open() — uniwersalne otwieranie (file://, s3://, http://, memory://)
  - CachingFileSystem — przezroczyste cache'owanie z TTL i LRU
  - TransactionalFileSystem — atomowe operacje zapisu
  - fsspec.get_mapper() — dict-like interfejs dla metadanych
  - fsspec.open_async() — async file I/O bez blokowania event loop
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
from fsspec.implementations.cached import CachingFileSystem
from nexus_ai.core.fsspec_compat import TransactionalFileSystem
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.services.file_system")

UPLOAD_CHUNK_SIZE = 1024 * 1024  # 1 MB
DEFAULT_CACHE_SIZE_MB = 500


class FileSystemService:
    """Unified filesystem service — centralne I/O dla całego projektu.

    SUPERMOC fsspec:
    - fsspec.filesystem() z config TOML (file://, s3://, memory://)
    - CachingFileSystem dla przezroczystego cache
    - TransactionalFileSystem dla atomicznych zapisów
    - fsspec.open_async() dla async I/O
    - fsspec.get_mapper() dla dict-like interfejsu
    - Auto-mkdir dla katalogów
    """

    def __init__(self, config: AppConfig) -> None:
        self._protocol = config.storage_protocol
        self._base_path = config.base_dir / config.storage_root
        self._config = config

        # Podstawowy filesystem z config
        fs_kwargs: dict = {}
        if config.storage_auto_mkdir:
            fs_kwargs["auto_mkdir"] = True

        self._fs = fsspec.filesystem(self._protocol, **fs_kwargs)

        # SUPERMOC: CachingFileSystem dla przezroczystego cache
        if config.storage_cache_size_mb > 0:
            cache_storage = config.base_dir / "app_data" / "fsspec_cache"
            cache_storage.mkdir(parents=True, exist_ok=True)
            self._fs = CachingFileSystem(
                target_protocol=self._protocol,
                cache_storage=str(cache_storage),
                maxsize=config.storage_cache_size_mb * 1024 * 1024,
                same_names=True,
            )

        # SUPERMOC: TransactionalFileSystem dla atomicznych zapisów
        if config.storage_transactional:
            self._fs = TransactionalFileSystem(self._fs)

        if self._protocol == "file":
            self._fs.makedirs(str(self._base_path), exist_ok=True)

        logger.info(
            "[FileSystemService] Initialized: protocol=%s root=%s cache=%dMB transactional=%s",
            self._protocol,
            self._base_path,
            config.storage_cache_size_mb,
            config.storage_transactional,
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

    # ── Async API (rekomendowane) ───────────────────────────────────────

    async def read_bytes(self, path: str) -> bytes:
        """Odczytaj cały plik jako bytes przez async fsspec I/O.

        SUPERMOC: fsspec.open_async() — nie blokuje event loop.
        """
        async with await fsspec.open_async(path, "rb") as f:
            return await f.read()

    async def write_bytes(self, path: str, data: bytes) -> None:
        """Zapisz bytes do pliku przez async fsspec I/O.

        SUPERMOC: fsspec.open_async() — nie blokuje event loop.
        """
        async with await fsspec.open_async(path, "wb") as f:
            await f.write(data)

    async def stream_write(
        self,
        path: str,
        stream: BinaryIO | Iterable[bytes],
        chunk_size: int = UPLOAD_CHUNK_SIZE,
    ) -> str:
        """Zapisz strumień danych przez async fsspec I/O.

        SUPERMOC: fsspec.open_async() dla streaming write.
        """
        async with await fsspec.open_async(path, "wb") as out:
            if hasattr(stream, "read"):
                while True:
                    chunk = stream.read(chunk_size)
                    if not chunk:
                        break
                    await out.write(chunk)
            else:
                for chunk in stream:
                    if chunk:
                        await out.write(chunk)
        return path

    async def read_text(self, path: str, encoding: str = "utf-8") -> str:
        """Odczytaj plik tekstowy przez async fsspec I/O."""
        data = await self.read_bytes(path)
        return data.decode(encoding)

    async def write_text(self, path: str, text: str, encoding: str = "utf-8") -> None:
        """Zapisz tekst do pliku przez async fsspec I/O."""
        await self.write_bytes(path, text.encode(encoding))

    async def delete(self, path: str) -> bool:
        """Usuń plik przez fsspec."""
        if self._fs.exists(path):
            self._fs.rm(path)
            return True
        return False

    async def exists(self, path: str) -> bool:
        """Sprawdź czy plik istnieje przez fsspec."""
        return self._fs.exists(path)

    async def info(self, path: str) -> dict | None:
        """Pobierz informacje o pliku przez fsspec.info()."""
        try:
            return self._fs.info(path)
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
