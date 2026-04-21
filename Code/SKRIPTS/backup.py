# scripts/backup.py
import os
import shutil
import zipfile
from datetime import datetime
from pathlib import Path
from core.config import AppConfig

def create_backup():
    config = AppConfig()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"nexus_backup_{timestamp}.zip"
    backup_path = config.base_dir / "backups"
    backup_path.mkdir(exist_ok=True)

    target_zip = backup_path / backup_name
    print(f" Tworzenie kopii zapasowej: {backup_name}...")

    with zipfile.ZipFile(target_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
        # Pakujemy bazy danych
        if config.sqlite_path.exists():
            zipf.write(config.sqlite_path, config.sqlite_path.name)
        if config.duckdb_path.exists():
            zipf.write(config.duckdb_path, config.duckdb_path.name)

        # Pakujemy skany (app_data)
        data_dir = config.base_dir / "app_data"
        for root, _, files in os.walk(data_dir):
            for file in files:
                file_path = Path(root) / file
                archive_name = file_path.relative_to(config.base_dir)
                zipf.write(file_path, archive_name)

    print(f"✅ Kopia zapasowa gotowa: {target_zip}")

if __name__ == "__main__":
    create_backup()
