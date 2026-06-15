from abc import ABC, abstractmethod
from pathlib import Path

import fsspec
from anyio import to_thread

from nexus_ai.core.config import AppConfig


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


class LocalStorageProvider(StorageProvider):
    """Provider oparty o fsspec z nieblokującym I/O w wątku roboczym.

    SUPERMOC fsspec: Używa konfigurowalnego protokołu ("file", "s3", "sftp", "memory")
    z config TOML — zmiana backendu bez zmiany kodu.
    """

    def __init__(self, config: AppConfig):
        self._protocol = config.storage_protocol
        self._base_path = config.base_dir / config.storage_root

        fs_kwargs: dict = {}
        if config.storage_auto_mkdir:
            fs_kwargs["auto_mkdir"] = True

        self.fs = fsspec.filesystem(self._protocol, **fs_kwargs)
        if self._protocol == "file":
            self.fs.makedirs(str(self._base_path), exist_ok=True)

    def _resolve_path(self, filename: str) -> str:
        safe_name = Path(filename).name
        if self._protocol == "file":
            return str(self._base_path / safe_name)
        return f"{self._protocol}://{self._base_path}/{safe_name}"

    async def save_file(self, filename: str, content: bytes) -> str:
        file_path = self._resolve_path(filename)

        def _write() -> None:
            with self.fs.open(file_path, "wb") as handle:
                handle.write(content)

        await to_thread.run_sync(_write)
        return file_path

    async def get_file(self, file_path: str) -> bytes:
        def _read() -> bytes:
            with fsspec.open(file_path, "rb") as handle:
                return handle.read()

        return await to_thread.run_sync(_read)

    async def delete_file(self, file_path: str) -> bool:
        def _delete() -> bool:
            if self.fs.exists(file_path):
                self.fs.rm(file_path)
                return True
            return False

        return await to_thread.run_sync(_delete)
