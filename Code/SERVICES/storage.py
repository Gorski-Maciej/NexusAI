import shutil
import uuid
from pathlib import Path

from core.config import AppConfig


class StorageService:
    def __init__(self, config: AppConfig):
        self.storage_root = config.base_dir / "app_data" / "scans"
        self._ensure_storage_exists()

    def _ensure_storage_exists(self):
        self.storage_root.mkdir(parents=True, exist_ok=True)

    def save_invoice_file(self, source_path: str) -> str:
        """Kopiuje plik do wewnętrznego folderu, nadając mu unikalną nazwę. Zwraca nową ścieżkę."""
        source_file = Path(source_path)
        if not source_file.exists():
            raise FileNotFoundError(f"Nie znaleziono pliku: {source_path}")

        file_extension = source_file.suffix
        # Generujemy bezpieczną nazwę: {uuid}_{oryginalna_nazwa} lub tylko z rozszerzeniem
        new_filename = f"{uuid.uuid4().hex}{file_extension}"
        destination_path = self.storage_root / new_filename

        # Bezpieczne kopiowanie z zachowaniem metadanych
        shutil.copy2(source_file, destination_path)
        return str(destination_path)
