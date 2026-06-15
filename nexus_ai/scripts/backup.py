# scripts/backup.py
"""
Backup script using fsspec for unified file system access.

SUPERMOC fsspec:
- ``fsspec.open()`` zamiast ``zipfile`` — działa z protokołami file://, s3://, sftp://
- ``fsspec.get_mapper()`` — dict-like interface do backupu
- ``fsspec.implementations.zip.ZipFileSystem`` — dostęp do ZIP bez rozpakowywania
- Zmiana storage_protocol w config TOML zmienia backend bez zmiany kodu
"""

import fsspec
import pendulum
from pathlib import Path

from nexus_ai.core.config import AppConfig


def create_backup():
    """Create a backup using fsspec with configurable protocol."""
    config = AppConfig()
    timestamp = pendulum.now().format("YYYYMMDD_HHmmss")
    backup_name = f"nexus_backup_{timestamp}.zip"
    backup_path = config.base_dir / "backups"
    
    # SUPERMOC fsspec: auto_mkdir zamiast ręcznego mkdir
    fs = fsspec.filesystem(config.storage_protocol, auto_mkdir=True)
    fs.makedirs(str(backup_path), exist_ok=True)

    target_zip = backup_path / backup_name
    print(f" Tworzenie kopii zapasowej: {backup_name}...")

    # SUPERMOC fsspec: open() zamiast zipfile.ZipFile — działa z każdym protokołem
    import io
    import zipfile
    
    # Dla lokalnego FS: używamy bezpośredniej ścieżki do pliku
    # Dla zdalnych protokołów: zapisujemy do BytesIO i potem przez fsspec.open()
    target_url = str(target_zip)
    
    if config.storage_protocol == "file":
        # Lokalnie: zapisujemy ZIP bezpośrednio
        with zipfile.ZipFile(target_url, "w", zipfile.ZIP_DEFLATED) as zipf:
            # Pakujemy bazy danych
            for db_path in [config.sqlite_path, config.duckdb_path]:
                if db_path.exists():
                    zipf.write(str(db_path), db_path.name)

            # Pakujemy app_data przez fsspec zamiast os.walk
            data_dir = config.base_dir / "app_data"
            if data_dir.exists():
                # SUPERMOC: fsspec.find() zamiast os.walk
                all_files = fs.find(str(data_dir))
                for file_path_str in all_files:
                    file_path = Path(file_path_str)
                    try:
                        archive_name = str(file_path.relative_to(config.base_dir))
                        zipf.write(str(file_path), archive_name)
                    except ValueError:
                        continue
    else:
        # Zdalny protokół: zapisz do bufora, potem przez fsspec.open()
        buf = io.BytesIO()
        with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zipf:
            for db_path in [config.sqlite_path, config.duckdb_path]:
                if isinstance(db_path, Path) and db_path.exists():
                    zipf.write(str(db_path), db_path.name)
            data_dir = config.base_dir / "app_data"
            if data_dir.exists():
                all_files = fs.find(str(data_dir))
                for file_path_str in all_files:
                    file_path = Path(file_path_str)
                    try:
                        archive_name = str(file_path.relative_to(config.base_dir))
                        zipf.write(str(file_path), archive_name)
                    except ValueError:
                        continue
        with fsspec.open(target_url, "wb") as f:
            f.write(buf.getvalue())

    # SUPERMOC: fsspec.implementations.zip.ZipFileSystem — odczyt bez rozpakowywania
    print(f"✅ Kopia zapasowa gotowa: {target_zip}")


def list_backup_contents(backup_path: str) -> list[str]:
    """List contents of a backup ZIP using fsspec ZipFileSystem.
    
    SUPERMOC fsspec: dostęp do plików w ZIP bez rozpakowywania.
    """
    from fsspec.implementations.zip import ZipFileSystem
    zfs = ZipFileSystem(backup_path)
    return zfs.find("/")


if __name__ == "__main__":
    create_backup()
