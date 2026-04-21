# pipeline/deduplicator.py
import hashlib
from pathlib import Path

class PipelineDeduplicator:
    """Sprawdza, czy plik o takiej treści był już analizowany."""

    @staticmethod
    def calculate_hash(file_path: str) -> str:
        """Tworzy unikalny odcisk palca pliku (SHA-256)."""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()

    @staticmethod
    async def is_duplicate(file_hash: str, db_session) -> bool:
        """Sprawdza w bazie danych, czy hash już istnieje."""
        # Logika SQL: SELECT 1 FROM invoices WHERE file_hash = :hash
        # To wywołasz w Workerze przed startem ciężkiego AI
        return False
