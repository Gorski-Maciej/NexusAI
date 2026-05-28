from abc import ABC, abstractmethod
from pathlib import Path

import fsspec
from anyio import to_thread

from core.config import AppConfig


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
    """Provider oparty o fsspec z nieblokującym I/O realizowanym w wątku roboczym."""

    def __init__(self, config: AppConfig):
        self.base_path = config.base_dir / "app_data" / "uploads"
        self.fs = fsspec.filesystem("file")
        self.fs.makedirs(str(self.base_path), exist_ok=True)

    def _resolve_path(self, filename: str) -> str:
        safe_name = Path(filename).name
        return str(self.base_path / safe_name)

    async def save_file(self, filename: str, content: bytes) -> str:
        file_path = self._resolve_path(filename)

        def _write() -> None:
            with self.fs.open(file_path, "wb") as handle:
                handle.write(content)

        await to_thread.run_sync(_write)
        return file_path

    async def get_file(self, file_path: str) -> bytes:
        def _read() -> bytes:
            with self.fs.open(file_path, "rb") as handle:
                return handle.read()

        return await to_thread.run_sync(_read)

    async def delete_file(self, file_path: str) -> bool:
        def _delete() -> bool:
            if self.fs.exists(file_path):
                self.fs.rm(file_path)
                return True
            return False

        return await to_thread.run_sync(_delete)
