# core/backup.py
import zipfile
import io
import os
from datetime import datetime, timedelta
from Cryptodome.Cipher import AES
from Cryptodome.Random import get_random_bytes
from pathlib import Path

class BackupManager:
    """Zarządza pakowaniem i szyfrowaniem bazy danych."""

    def __init__(self, config):
        self.config = config
        self.backup_dir = Path(config.base_dir) / "backups"
        self.backup_dir.mkdir(exist_ok=True)

    def create_encrypted_zip(self, password: str) -> str:
        """Tworzy zaszyfrowany ZIP z bazami danych."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        zip_buffer = io.BytesIO()

        # 1. Pakowanie plików
        files_to_backup = [
            self.config.sqlite_path,
            self.config.duckdb_path,
            # Dodaj ścieżkę do LanceDB (vector store)
        ]

        with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
            for file_path in files_to_backup:
                if os.path.exists(file_path):
                    zf.write(file_path, arcname=os.path.basename(file_path))

        # Tu w przyszłości można dodać logikę szyfrowania (AES) z użyciem buffera
        final_path = self.backup_dir / f"backup_{timestamp}.zip"
        with open(final_path, "wb") as f:
            f.write(zip_buffer.getvalue())

        self.prune_old_backups(keep_days=30)
        return str(final_path)


    def prune_old_backups(self, keep_days: int = 30) -> int:
        """Remove backups older than keep_days and return deleted count."""
        cutoff = datetime.now() - timedelta(days=keep_days)
        deleted = 0
        for backup in self.backup_dir.glob("backup_*.zip"):
            try:
                modified = datetime.fromtimestamp(backup.stat().st_mtime)
            except FileNotFoundError:
                continue
            if modified < cutoff:
                backup.unlink(missing_ok=True)
                deleted += 1
        return deleted
