import sqlite3
import asyncio
from pathlib import Path
from datetime import datetime, timezone
from core.config import AppConfig
import logging

logger = logging.getLogger("nexus.db.backup")

class DatabaseHotBackup:
    """Wykonuje gorącą kopię bazy bez przerywania pracy systemu (Zero-Downtime)."""

    @staticmethod
    async def create_snapshot(config: AppConfig, backup_dir: Path) -> Path:
        """Wykorzystuje natywne API SQLite do zrzutu pamięci WAL na dysk."""
        backup_dir.mkdir(parents=True, exist_ok=True)
        timestamp = int(datetime.now(timezone.utc).timestamp())
        backup_file = backup_dir / f"nexus_oltp_snapshot_{timestamp}.sqlite"

        def _execute_backup():
            source_db = config.sqlite_path.as_posix()
            try:
                # Otwieramy połączenie synchroniczne tylko do zrobienia kopii
                with sqlite3.connect(source_db) as src, sqlite3.connect(backup_file) as dst:
                    src.backup(dst)
            except Exception as e:
                logger.error(f"Backup failed: {e}")
                raise e

        # Uruchamiamy w osobnym wątku, aby nie blokować pętli zdarzeń
        await asyncio.to_thread(_execute_backup)
        return backup_file
