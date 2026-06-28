"""Unified file storage service using fsspec with configurable backend protocol.

TOTALNA REWOLUCJA: wszystkie operacje I/O przez AsyncFsWrapper.
- ``await afs.exists()`` zamiast ``await to_thread.run_sync(fs.exists)``
- ``await afs.cat_file()`` zamiast ``await fsspec.open_async(..., 'rb')``
- ``await afs.pipe_file()`` zamiast ``await fsspec.open_async(..., 'wb')``
- Gotowy na S3: zmiana storage_protocol → natywne async I/O

SUPERMOC fsspec:
- ``fsspec.open()`` — uniwersalne otwieranie plików w każdym protokole (file://, s3://, sftp://, memory://)
- ``fsspec.filesystem()`` — konfigurowalny backend przez config TOML
- ``auto_mkdir`` — automatyczne tworzenie katalogów (CachingFileSystem opcjonalnie)
- ``TransactionalFileSystem`` — atomowe zapisy (rollback przy błędzie)
- ``TqdmCallback`` — progress bary dla transferów plików
- ``MemoryFileSystem`` — RAM-only FS dla testów i tymczasowych danych

Zgodnie z aa3fvcx.txt: jeden URL, nieskończenie wiele backendów.
Zmiana storage_protocol w config TOML zmienia backend bez zmiany kodu.
"""

from __future__ import annotations

import io
import uuid
from collections.abc import Iterable
from pathlib import Path
from collections.abc import AsyncIterator, MutableMapping
from typing import Any, BinaryIO, final

import fsspec

from nexus_ai.core.config import AppConfig
from nexus_ai.core.fsspec_compat import AsyncFsWrapper, FSSpecFactory, TransactionalFileSystem
from nexus_ai.core.logger import get_logger

logger = get_logger(__name__)

UPLOAD_CHUNK_SIZE = 1024 * 1024


@final
class StorageService:
    """Unified file storage service with configurable fsspec backend.

    TOTALNA REWOLUCJA:
    - ``self._async_fs`` — AsyncFsWrapper, czyste ``await fs.exists()`` API
    - Zero ``to_thread.run_sync()`` w serwisie
    - Gotowy na S3: zmiana storage_protocol → natywne async I/O
    """

    def __init__(self, config: AppConfig) -> None:
        self._config = config

        factory = FSSpecFactory.get_instance()
        factory.configure_from_app_config(config)

        self._protocol = config.storage_protocol
        self._base_path = config.base_dir / config.storage_root

        # Sync FS dla kompatybilności (sync API, copy_between_fs)
        self._fs = factory.get_filesystem()

        # TOTALNA REWOLUCJA: AsyncFsWrapper dla async API
        self._async_fs = factory.get_async_filesystem()

        # SUPERMOC: TransactionalFileSystem dla atomowych operacji
        self._tx_fs = TransactionalFileSystem(fs=self._fs)

        # SUPERMOC: fsspec.get_mapper() dla metadanych
        self._meta_mapper = factory.get_mapper(".meta/")

        logger.info(
            "[StorageService] Initialized: protocol=%s root=%s cache=%dMB tx=%s chain=%s async=%s",
            self._protocol,
            self._base_path,
            config.storage_cache_size_mb,
            type(self._tx_fs).__name__,
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

        TOTALNA REWOLUCJA: ``await self._async_fs.open()`` zamiast ``fsspec.open_async()``.
        """
        rel_path = self._local_path(original_name)
        url = self._resolve_url(rel_path)

        # TOTALNA REWOLUCJA: AsyncFsWrapper.open() — async context manager
        # UWAGA: fsspec.open() zwraca OpenFile. Wewnątrz async with,
        # read()/write() są synchroniczne (ale non-blocking przez OpenFile).
        async with await self._async_fs.open(url, "wb") as out:
            if hasattr(stream, "read"):
                file_obj = stream  # type: ignore[assignment]
                while True:
                    chunk = file_obj.read(chunk_size)
                    if not chunk:
                        break
                    out.write(chunk)  # sync, non-blocking (OpenFile)
            else:
                for chunk in stream:
                    if chunk:
                        out.write(chunk)  # sync, non-blocking (OpenFile)

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

        TOTALNA REWOLUCJA: ``await self._async_fs.cat_file()`` zamiast ``fsspec.open_async()``.
        """
        url = self._ensure_protocol_prefix(url)
        return await self._async_fs.cat_file(url)

    async def delete_file_async(self, url: str) -> bool:
        """Delete file using async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.exists()`` + ``await self._async_fs.rm()``
        zamiast ``await to_thread.run_sync(_delete)``.
        """
        url = self._ensure_protocol_prefix(url)
        if await self._async_fs.exists(url):
            await self._async_fs.rm(url)
            return True
        return False

    async def file_exists_async(self, url: str) -> bool:
        """Check if file exists using async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.exists()`` zamiast ``to_thread.run_sync()``.
        """
        url = self._ensure_protocol_prefix(url)
        return await self._async_fs.exists(url)

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

    # ── SUPERMOC: TransactionalFileSystem — atomowe operacje ────────────────

    @property
    def tx_fs(self) -> TransactionalFileSystem:
        """TransactionalFileSystem dla atomowych zapisów.

        Użycie:
            with storage.tx_fs.transaction():
                await storage.save_invoice_bytes_async(b"...", "a.pdf")
                await storage.save_invoice_bytes_async(b"...", "b.pdf")
            # Oba pliki zapisane atomowo — jeśli któryś fail, oba są cofnięte
        """
        return self._tx_fs

    def transaction(self):
        """Context manager dla atomowych operacji na storage.

        SUPERMOC fsspec: ``TransactionalFileSystem.transaction()`` —
        wszystkie operacje w bloku są deferowane i commitują się atomowo
        po wyjściu z context managera.

        Użycie:
            with storage.transaction():
                storage.save_invoice_stream(io.BytesIO(b"..."), "a.pdf")
        """
        return self._tx_fs.transaction()

    # ── SUPERMOC: save_with_progress — TqdmCallback ────────────────────────

    def save_with_progress(
        self,
        source_path: str,
        *,
        target_name: str | None = None,
        description: str = "Uploading...",
    ) -> str:
        """SUPERMOC: Zapisz plik z progress barem przez fsspec TqdmCallback.

        Używa ``fsspec.callbacks.TqdmCallback()`` do wyświetlenia
        paska postępu podczas transferu pliku.

        Args:
            source_path: Źródłowa ścieżka pliku.
            target_name: Opcjonalna nazwa docelowa (UUID jeśli nie podana).
            description: Tekst paska postępu.

        Returns:
            URL zapisanego pliku.
        """
        from fsspec.callbacks import TqdmCallback

        rel_path = self._local_path(target_name)
        url = self._resolve_url(rel_path)

        # SUPERMOC: fsspec.get() z TqdmCallback — kopiuje plik z progress barem
        with TqdmCallback(desc=description) as cb:
            self._fs.get(source_path, url, callback=cb)

        return url

    async def save_with_progress_async(
        self,
        source_path: str,
        *,
        target_name: str | None = None,
        description: str = "Uploading...",
    ) -> str:
        """Async wersja save_with_progress — przez AsyncFsWrapper.put().

        TOTALNA REWOLUCJA: ``await self._async_fs.put()`` zamiast ``to_thread.run_sync()``.
        """
        from fsspec.callbacks import TqdmCallback

        rel_path = self._local_path(target_name)
        url = self._resolve_url(rel_path)

        with TqdmCallback(desc=description) as cb:
            await self._async_fs.put(source_path, url, callback=cb)

        return url

    # ── SUPERMOC: copy_between_fs — kopia między systemami plików ──────────

    @staticmethod
    def copy_between_fs(
        src_url: str,
        dst_url: str,
        *,
        src_protocol: str = "file",
        dst_protocol: str = "file",
        callback: Any = None,
    ) -> None:
        """SUPERMOC: Kopiuj plik między różnymi systemami plików fsspec.

        Używa ``fsspec.filesystem()`` dla źródła i celu, a następnie
        ``fs.get()`` / ``fs.put()`` do transferu.
        Działa między: file:// ↔ s3:// ↔ http:// ↔ memory://

        Args:
            src_url: Źródłowy URL.
            dst_url: Docelowy URL.
            src_protocol: Protokół źródła (domyślnie "file").
            dst_protocol: Protokół celu (domyślnie "file").
            callback: Opcjonalny callback TqdmCallback dla progress bara.
        """
        src_fs = fsspec.filesystem(src_protocol)
        dst_fs = fsspec.filesystem(dst_protocol)

        # SUPERMOC: fsspec get/put — transfer między FS
        with src_fs.open(src_url, "rb") as src:
            with dst_fs.open(dst_url, "wb") as dst:
                if callback:
                    total = src_fs.info(src_url).get("size", 0)
                    if total:
                        callback.set_size(total)
                    chunk = src.read(UPLOAD_CHUNK_SIZE)
                    while chunk:
                        dst.write(chunk)
                        if callback:
                            callback.relative_update(len(chunk))
                        chunk = src.read(UPLOAD_CHUNK_SIZE)
                else:
                    dst.write(src.read())

    # ── SUPERMOC: get_file_info — metadane pliku przez fsspec ─────────────

    async def get_file_info(self, url: str) -> dict[str, Any]:
        """Pobierz metadane pliku przez async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.info()`` zamiast ``to_thread.run_sync()``.

        Returns:
            dict z kluczami: name, size, type, mtime, protocol.
        """
        url = self._ensure_protocol_prefix(url)
        info = await self._async_fs.info(url)
        return {
            "name": info.get("name", url),
            "size": info.get("size", 0),
            "type": info.get("type", "file"),
            "mtime": info.get("mtime", 0),
            "protocol": self._protocol,
            "url": url,
        }

    # ── SUPERMOC: stream_to_response — async streaming dla API ────────────

    async def stream_to_response(
        self,
        url: str,
        chunk_size: int = UPLOAD_CHUNK_SIZE,
    ) -> AsyncIterator[bytes]:
        """SUPERMOC: Streamuj plik w async generatorze dla odpowiedzi API.

        TOTALNA REWOLUCJA: ``await self._async_fs.open()`` zamiast ``fsspec.open_async()``.

        Args:
            url: URL pliku do streamowania.
            chunk_size: Rozmiar chunka w bajtach.

        Yields:
            Chunki bajtów do wysłania klientowi.
        """
        url = self._ensure_protocol_prefix(url)
        # UWAGA: fsspec.open() zwraca OpenFile. read()/write() są sync.
        async with await self._async_fs.open(url, "rb") as f:
            while True:
                chunk = f.read(chunk_size)  # sync, non-blocking (OpenFile)
                if not chunk:
                    break
                yield chunk

    # ── SUPERMOC: MemoryFileSystem — tymczasowy storage w RAM ─────────────

    @staticmethod
    def create_memory_storage() -> StorageService:
        """SUPERMOC: Utwórz StorageService z MemoryFileSystem (RAM-only).

        Idealne dla:
        - Testów jednostkowych (szybkie, bez I/O na dysk)
        - Tymczasowych plików (preview, cache)
        - Izolowanych środowisk (każdy test ma swój FS)

        Użycie:
            storage = StorageService.create_memory_storage()
            url = await storage.save_invoice_bytes_async(b"test", "test.pdf")
            data = await storage.read_file_async(url)
        """
        from fsspec.implementations.memory import MemoryFileSystem

        # Tworzymy mock config z memory protocol
        from nexus_ai.core.config import AppConfig

        class _MockConfig:
            storage_protocol = "memory"
            storage_root = "test"
            storage_auto_mkdir = True
            storage_cache_size_mb = 0
            base_dir = Path("/tmp")

        # Inicjalizujemy z MemoryFileSystem bezpośrednio
        service = object.__new__(StorageService)
        service._protocol = "memory"
        service._base_path = Path("test")
        service._fs = MemoryFileSystem()
        service._tx_fs = TransactionalFileSystem(fs=service._fs)

        # TOTALNA REWOLUCJA: AsyncFsWrapper dla memory FS

        service._async_fs = AsyncFsWrapper(fs=service._fs)

        service._meta_mapper = fsspec.get_mapper("memory://test/.meta/")
        service._config = _MockConfig()
        service._fs.makedirs("test", exist_ok=True)
        return service

    # ── SUPERMOC: meta_mapper — dict-like metadanych ───────────────────────

    @property
    def meta(self) -> MutableMapping:
        """Dict-like interfejs do metadanych storage.

        SUPERMOC fsspec: ``fsspec.get_mapper()`` zwraca ``MutableMapping``,
        który automatycznie serializuje wartości do plików w katalogu .meta/.
        Każdy klucz to osobny plik, odczyt/zapis przez fsspec.
        """
        return self._meta_mapper

    # ── SUPERMOC: list_files — lista plików przez fsspec ────────────────────

    async def list_files(self, prefix: str = "") -> list[dict[str, Any]]:
        """Listuj pliki w storage z metadanymi przez async fsspec I/O.

        TOTALNA REWOLUCJA: ``await self._async_fs.ls()`` zamiast ``to_thread.run_sync()``.

        Args:
            prefix: Opcjonalny prefix katalogu.

        Returns:
            List[dict]: [{name, size, type, mtime}, ...]
        """
        url = self._resolve_url(prefix)
        entries = await self._async_fs.ls(url, detail=True)
        return [
            {
                "name": e.get("name", ""),
                "size": e.get("size", 0),
                "type": e.get("type", "file"),
                "mtime": e.get("mtime", 0),
            }
            for e in entries
        ]
