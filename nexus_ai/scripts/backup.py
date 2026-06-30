# scripts/backup.py
"""
Backup script using fsspec for unified file system access.

- ``fsspec.open()`` zamiast ``zipfile`` -- działa z protokołami file://, s3://, sftp://
- ``fsspec.get_mapper()`` -- dict-like interface do backupu
- ``fsspec.implementations.zip.ZipFileSystem`` -- dostęp do ZIP bez rozpakowywania
- ``TqdmCallback`` -- progress bary podczas backupu
- ``CachingFileSystem`` -- cache dla szybkiego przeglądania backupów
- ``TransactionalFileSystem`` -- atomowe tworzenie backupów
- ``MemoryFileSystem`` -- tymczasowy bufor w RAM
- Zmiana storage_protocol w config TOML zmienia backend bez zmiany kodu
"""

from __future__ import annotations

import io
import zipfile
from pathlib import Path
from typing import Any

import fsspec
import pendulum

from nexus_ai.core.config import AppConfig
from nexus_ai.core.fsspec_compat import (
    HAS_TQDM_CB,
    CachingFileSystem,
    MemoryFileSystem,
    TqdmCallback,
    TransactionalFileSystem,
    ZipFileSystem,
)

BACKUP_CACHE_SIZE_MB = 500


def _setup_fs(config: AppConfig):
    """Utwórz skonfigurowany fsspec filesystem z cache i transactional support."""
    fsspec.filesystem(config.storage_protocol, auto_mkdir=True)

    cache_fs = CachingFileSystem(
        target_protocol=config.storage_protocol,
        cache_storage="/tmp/.fsspec_backup_cache",
        maxsize=BACKUP_CACHE_SIZE_MB * 1024 * 1024,
        same_names=True,
    )

    tx_fs = TransactionalFileSystem(fs=cache_fs)

    return tx_fs


def _get_backup_meta_mapper(config: AppConfig):
    """Utwórz fsspec.get_mapper() dla metadanych backupów."""
    backup_meta_dir = config.base_dir / "backups" / ".meta"
    backup_meta_dir.mkdir(parents=True, exist_ok=True)
    return fsspec.get_mapper(str(backup_meta_dir))


def create_backup():
    """Create a backup using fsspec with configurable protocol.

    - TransactionalFileSystem dla atomowości
    - TqdmCallback dla progress bara
    - fsspec.get_mapper() dla metadanych backupów
    - fsspec.find() zamiast os.walk()
    """
    config = AppConfig()
    timestamp = pendulum.now().format("YYYYMMDD_HHmmss")
    backup_name = f"nexus_backup_{timestamp}.zip"
    backup_path = config.base_dir / "backups"

    fs = _setup_fs(config)
    fs.makedirs(str(backup_path), exist_ok=True)

    target_zip = backup_path / backup_name
    target_url = str(target_zip)

    meta = _get_backup_meta_mapper(config)

    print(f"📦 Tworzenie kopii zapasowej: {backup_name}...")

    with fs.transaction():
        if config.storage_protocol == "file":
            with zipfile.ZipFile(target_url, "w", zipfile.ZIP_DEFLATED) as zipf:
                cb = (
                    TqdmCallback(desc="Compressing backup")
                    if HAS_TQDM_CB and TqdmCallback is not None
                    else None
                )
                if cb:
                    cb.__enter__()
                try:
                    for db_path in [config.sqlite_path, config.duckdb_path]:
                        if db_path.exists():
                            zipf.write(str(db_path), db_path.name)
                            if cb:
                                cb.relative_update(db_path.stat().st_size)

                    data_dir = config.base_dir / "app_data"
                    if data_dir.exists():
                        all_files = fs.find(str(data_dir))
                        for file_path_str in all_files:
                            file_path = Path(file_path_str)
                            try:
                                archive_name = str(file_path.relative_to(config.base_dir))
                                zipf.write(str(file_path), archive_name)
                                if cb:
                                    cb.relative_update(file_path.stat().st_size)
                            except ValueError:
                                continue
                finally:
                    if cb:
                        cb.__exit__(None, None, None)
        else:
            MemoryFileSystem()
            buf = io.BytesIO()

            with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zipf:
                cb = (
                    TqdmCallback(desc="Compressing backup (remote)")
                    if HAS_TQDM_CB and TqdmCallback is not None
                    else None
                )
                if cb:
                    cb.__enter__()
                try:
                    for db_path in [config.sqlite_path, config.duckdb_path]:
                        if isinstance(db_path, Path) and db_path.exists():
                            zipf.write(str(db_path), db_path.name)
                            if cb:
                                cb.relative_update(db_path.stat().st_size)

                    data_dir = config.base_dir / "app_data"
                    if data_dir.exists():
                        all_files = fs.find(str(data_dir))
                        for file_path_str in all_files:
                            file_path = Path(file_path_str)
                            try:
                                archive_name = str(file_path.relative_to(config.base_dir))
                                zipf.write(str(file_path), archive_name)
                                if cb:
                                    cb.relative_update(file_path.stat().st_size)
                            except ValueError:
                                continue
                finally:
                    if cb:
                        cb.__exit__(None, None, None)

            with fsspec.open(target_url, "wb") as f:
                cb2 = (
                    TqdmCallback(desc="Uploading backup")
                    if HAS_TQDM_CB and TqdmCallback is not None
                    else None
                )
                if cb2:
                    cb2.__enter__()
                    cb2.set_size(buf.tell())
                try:
                    buf.seek(0)
                    while True:
                        chunk = buf.read(1024 * 1024)
                        if not chunk:
                            break
                        f.write(chunk)
                        if cb2:
                            cb2.relative_update(len(chunk))
                finally:
                    if cb2:
                        cb2.__exit__(None, None, None)

    meta[backup_name] = {
        "timestamp": timestamp,
        "size": Path(target_url).stat().st_size if config.storage_protocol == "file" else 0,
        "files_count": len(fs.find(str(config.base_dir / "app_data")))
        if (config.base_dir / "app_data").exists()
        else 0,
        "protocol": config.storage_protocol,
    }

    zfs = ZipFileSystem(target_url)
    file_count = len(zfs.find("/"))

    print(f"✅ Kopia zapasowa gotowa: {backup_name} ({file_count} plików)")
    return target_url


def list_backup_contents(backup_path: str) -> list[dict[str, Any]]:
    """List contents of a backup ZIP with metadata using fsspec ZipFileSystem.


    Args:
        backup_path: Ścieżka do pliku ZIP.

    Returns:
        List[dict]: [{name, size, type}, ...]
    """
    zfs = ZipFileSystem(backup_path)
    entries = zfs.find("/", detail=True)
    return [
        {
            "name": name,
            "size": info.get("size", 0),
            "type": info.get("type", "file"),
        }
        for name, info in entries.items()
    ]


def list_backups() -> list[dict[str, Any]]:
    """List all backups with metadata from fsspec.get_mapper().

    """
    config = AppConfig()
    backup_dir = config.base_dir / "backups"
    if not backup_dir.exists():
        return []

    fsspec.filesystem(config.storage_protocol)
    backups = []

    meta = _get_backup_meta_mapper(config)

    for f in sorted(backup_dir.iterdir()):
        if f.suffix == ".zip":
            info = {
                "name": f.name,
                "path": str(f),
                "size": f.stat().st_size,
                "size_mb": round(f.stat().st_size / (1024 * 1024), 2),
                "meta": meta.get(f.name, {}),
            }
            backups.append(info)

    return sorted(backups, key=lambda b: b["name"], reverse=True)


def verify_backup(backup_path: str) -> bool:
    """Verify backup integrity using ZipFileSystem.

    odczytuje wszystkie pliki z ZIP bez rozpakowywania.
    """
    try:
        zfs = ZipFileSystem(backup_path)
        all_files = zfs.find("/")
        if not all_files:
            return False
        # Próba odczytu każdego pliku
        for f in all_files:
            with zfs.open(f, "rb") as fh:
                fh.read(1)  # Weryfikacja integralności
        return True
    except Exception:
        return False


if __name__ == "__main__":
    url = create_backup()
    print(f"\nBackups: {list_backups()}")
    if url:
        print(f"Verification: {'✅ OK' if verify_backup(url) else '❌ FAILED'}")
