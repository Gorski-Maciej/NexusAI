# core/storage.py
import os
import shutil
from abc import ABC, abstractmethod
from pathlib import Path
from core.config import AppConfig

class StorageProvider(ABC):
    """Interfejs dla magazynów danych (Lokalny, S3, FTP)."""

    @abstractmethod
    async def save_file(self, filename: str, content: bytes) -> str:
        pass

    @abstractmethod
    async def get_file(self, file_path: str) -> bytes:
        pass

    @abstractmethod
    async def delete_file(self, file_path: str) -> bool:
        pass

class LocalStorageProvider(StorageProvider):
    """Domyślna implementacja zapisująca pliki na dysku (Offline First)."""

    def __init__(self, config: AppConfig):
        self.base_path = config.base_dir / "app_data" / "uploads"
        self.base_path.mkdir(parents=True, exist_ok=True)

    async def save_file(self, filename: str, content: bytes) -> str:
        file_path = self.base_path / filename
        # Używamy async do operacji I/O, aby nie blokować pętli Fleta/Uvicorn
        with open(file_path, "wb") as f:
            f.write(content)
        return str(file_path)

    async def get_file(self, file_path: str) -> bytes:
        with open(file_path, "rb") as f:
            return f.read()

    async def delete_file(self, file_path: str) -> bool:
        path = Path(file_path)
        if path.exists():
            path.unlink()
            return True
        return False
