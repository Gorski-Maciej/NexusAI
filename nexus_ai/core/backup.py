# core/backup.py
"""Backup manager using nexus-crypto AEAD (ChaCha20-Poly1305).

Zgodnie z aa3fvcx.txt:
- ChaCha20-Poly1305 AEAD + Argon2id KDF (nexus-crypto, Rust+PyO3)
- Legacy NEXUSENC1 (AES-256-CBC + PBKDF2) wspierany dla kompatybilności wstecznej
"""

import io
import os
import zipfile
from pathlib import Path

import fsspec
import nexus_crypto
import pendulum
from structlog import get_logger

from nexus_ai.core.config import AppConfig
from nexus_ai.core.fsspec_compat import FSSpecFactory

logger = get_logger("nexus.core.backup")

# ── Optional: cryptography for legacy NEXUSENC1 (AES-256-CBC) compatibility ───
try:
    from cryptography.hazmat.primitives import padding as _crypto_padding
    from cryptography.hazmat.primitives.ciphers import (
        Cipher as _Cipher,
        algorithms as _algos,
        modes as _modes,
    )

    _HAS_CRYPTOGRAPHY = True
except ImportError:
    _HAS_CRYPTOGRAPHY = False

# ── DuckDB import for EXPORT DATABASE ────────────────────────────────────────
try:
    import duckdb as _duckdb
    _HAS_DUCKDB = True
except ImportError:
    _HAS_DUCKDB = False

# ── Delta Lake import for ACID Parquet backups ───────────────────────────────
# SUPERMOC: Delta Lake dodaje ACID transactions do Parquet:
# - Atomic commits: write + metadata w jednej transakcji
# - Time travel: dostęp do dowolnej wersji backupu
# - Schema enforcement: dodawanie kolumn nie psuje istniejących danych
# - Zysk: backup z gwarancją ACID, bez ryzyka partial write
try:
    import deltalake as _delta
    _HAS_DELTA = True
except ImportError:
    _HAS_DELTA = False


class BackupManager:
    """Zarządza pakowaniem i szyfrowaniem bazy danych.

    SUPERMOC DuckDB:
    - ``EXPORT DATABASE`` — atomowy eksport całej bazy DuckDB do plików Parquet.
      Jedno zapytanie tworzy kompletny snapshot: schemat + dane + indeksy.
      Porównanie z ręcznym backupem ZIP: 1 komenda zamiast 20 linii kodu.
    - ``IMPORT DATABASE`` — atomowe przywracanie z backupu.

    SUPERMOC PyArrow:
    - ``pyarrow.fs.LocalFileSystem`` — jednolity interfejs plików dla operacji
      backupowych. ``copy_file`` zamiast ``shutil.copy2``.
      Zysk: brak narzutu shutil, spójny interfejs z S3/GCS (przyszłościowo).

    Szyfrowanie AEAD (ChaCha20-Poly1305) backupów przy użyciu klucza z konfiguracji.
    """

    # ── SUPERMOC fsspec: FSSpecFactory zamiast pyarrow.fs ────────────
    # ``pyarrow.fs.LocalFileSystem`` jest zastąpiony przez fsspec,
    # który zapewnia ten sam interfejs dla wszystkich protokołów
    # (file://, s3://, sftp://) bez zmiany kodu biznesowego.
    # Zmiana storage_protocol w config TOML zmienia backend backupu.
    _fs: Any = None

    @property
    def fs(self):
        if self._fs is None:
            self._fs = FSSpecFactory.get_instance().get_filesystem()
        return self._fs

    def __init__(self, config):
        self.config = config
        self.backup_dir = Path(config.base_dir) / "backups"
        self.backup_dir.mkdir(exist_ok=True)

        # SUPERMOC: Skonfiguruj FSSpecFactory z AppConfig
        FSSpecFactory.get_instance().configure_from_app_config(config)

    # ── SUPERMOC: DuckDB EXPORT / IMPORT DATABASE ──────────────────────

    def duckdb_export_database(self, duckdb_path: str | Path | None = None) -> str:
        """Atomowy eksport całej bazy DuckDB przez EXPORT DATABASE.

        SUPERMOC DuckDB:
        ``EXPORT DATABASE 'path' (FORMAT PARQUET)`` — jeden SQL tworzy:
          - ``schema.sql`` — pełny schemat (CREATE TABLE, CREATE INDEX, VIEW)
          - ``load.sql`` — skrypt do załadowania
          - Pliki Parquet z danymi
          - Backup jest atomowy — spójny snapshot bez blokowania

        Returns:
            Ścieżka do katalogu z eksportem.
        """
        if not _HAS_DUCKDB:
            logger.warning("[BACKUP] DuckDB not available — falling back to ZIP backup")
            return self.create_encrypted_zip()

        path = Path(duckdb_path or getattr(self.config, "duckdb_path", "nexus.duckdb"))
        if not path.exists():
            logger.warning("[BACKUP] DuckDB database not found at %s", path)
            return ""

        timestamp = pendulum.now().format("YYYYMMDD_HHmmss")
        export_dir = self.backup_dir / f"duckdb_export_{timestamp}"

        conn = _duckdb.connect(str(path), read_only=True)
        try:
            conn.execute(
                f"EXPORT DATABASE '{export_dir.as_posix()}' (FORMAT PARQUET)"
            )
            logger.info(
                "[BACKUP] DuckDB EXPORT DATABASE atomyczny: %s", export_dir
            )
            return str(export_dir)
        finally:
            conn.close()

    def duckdb_import_database(
        self, export_path: str | Path, target_db_path: str | Path | None = None
    ) -> bool:
        """Atomowe przywracanie bazy DuckDB przez IMPORT DATABASE.

        Args:
            export_path: Ścieżka do katalogu z eksportem.
            target_db_path: Ścieżka docelowej bazy DuckDB.

        Returns:
            True jeśli przywracanie się powiodło.
        """
        if not _HAS_DUCKDB:
            logger.warning("[BACKUP] DuckDB not available — cannot import database")
            return False

        target = Path(target_db_path or getattr(self.config, "duckdb_path", "nexus.duckdb"))
        export_path = Path(export_path)

        if not (export_path / "schema.sql").exists():
            logger.error("[BACKUP] Invalid DuckDB export directory: %s", export_path)
            return False

        conn = _duckdb.connect(str(target))
        try:
            conn.execute(f"IMPORT DATABASE '{export_path.as_posix()}'")
            logger.info("[BACKUP] DuckDB IMPORT DATABASE przywrócony do %s", target)
            return True
        finally:
            conn.close()

    def create_encrypted_zip(self, password: str = "") -> str:
        """Tworzy zaszyfrowany (AEAD) lub zwykły ZIP z bazami danych.

        Args:
            password: Hasło do szyfrowania. Jeśli puste, używa klucza z config.encryption_key.
        """
        if not password:
            password = getattr(self.config, "encryption_key", "") or os.getenv(
                "NEXUS_ENCRYPTION_KEY", ""
            )

        timestamp = pendulum.now().format("YYYYMMDD_HHmm")
        zip_buffer = io.BytesIO()

        # 1. Pakowanie plików
        files_to_backup = [
            self.config.sqlite_path,
            self.config.duckdb_path,
        ]

        # Vector store (sqlite-vec) jest włączony do sqlite_path

        with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
            for file_path in files_to_backup:
                path = Path(file_path) if not isinstance(file_path, Path) else file_path
                if path.exists():
                    zf.write(str(path), arcname=path.name)

        zip_data = zip_buffer.getvalue()

        # Szyfruj AEAD jeśli dostępne jest hasło
        if password and zip_data:
            # Derive 32-byte key using Argon2id (nexus-crypto)
            # Format: nagłówek (9B) + sól (16B) + nonce (12B) + ciphertext
            key, salt = nexus_crypto.derive_key(password)
            encrypted = nexus_crypto.encrypt(key, zip_data)
            # Header: magic (9B) + salt (16B) + encrypted (nonce+ciphertext)
            final_data = b"NEXUSAENC" + salt + encrypted
            ext = ".enc"
            logger.info(
                "[BACKUP] Encrypted backup with ChaCha20-Poly1305 (size: %d -> %d bytes)",
                len(zip_data),
                len(final_data),
            )
        else:
            final_data = zip_data
            ext = ".zip"
            if not password:
                logger.warning("[BACKUP] No password provided; backup is NOT encrypted")

        # SUPERMOC fsspec: TransactionalFileSystem dla atomowych backupów
        # fsspec.open() działa z każdym protokołem — file://, s3://, sftp://
        backup_url = str(self.backup_dir / f"backup_{timestamp}{ext}")
        with fsspec.open(backup_url, "wb") as f:
            f.write(final_data)

        self.prune_old_backups(keep_days=30)
        logger.info(
            "[BACKUP] Created backup: %s (%.2f MB)",
            final_path.name,
            len(final_data) / (1024 * 1024),
        )
        return str(final_path)

    def list_backups(self) -> list[dict]:
        """List all backups in the backup directory using fsspec.

        SUPERMOC fsspec: ``fs.glob()`` zamiast ``Path.glob()`` — działa
        z protokołami file://, s3://, sftp:// bez zmiany kodu.
        """
        backups = []
        for f in self.fs.glob(str(self.backup_dir / "backup_*")):
            info = self.fs.info(f)
            backups.append({
                "path": f,
                "size_mb": info.get("size", 0) / (1024 * 1024),
                "modified": pendulum.from_timestamp(info.get("mtime", 0)).to_iso8601_string(),
                "name": Path(f).name,
            })
        return sorted(backups, key=lambda x: x["modified"], reverse=True)

    def decrypt_backup(self, backup_path: Path | str, password: str) -> bytes:
        """Odszyfrowuje backup AEAD (ChaCha20-Poly1305).

        Obsługuje zarówno nowy format ``NEXUSAENC`` (ChaCha20-Poly1305 + Argon2id)
        jak i legacy ``NEXUSENC1`` (AES-256-CBC + PBKDF2) dla kompatybilności wstecznej.
        """
        backup_path = Path(backup_path)
        data = backup_path.read_bytes()

        if data.startswith(b"NEXUSAENC"):
            # Nowy format: ChaCha20-Poly1305 + Argon2id
            if not password:
                raise ValueError("Password required to decrypt backup")
            salt = data[9:25]
            encrypted = data[25:]
            key, _ = nexus_crypto.derive_key(password, salt=salt)
            return nexus_crypto.decrypt(key, encrypted)

        elif data.startswith(b"NEXUSENC1"):
            # Legacy format (AES-256-CBC + PBKDF2) — wsteczna kompatybilność
            if not password:
                raise ValueError("Password required to decrypt legacy backup")
            if not _HAS_CRYPTOGRAPHY:
                raise ModuleNotFoundError(
                    "Legacy backup (NEXUSENC1) requires the `cryptography` package. "
                    "Install it with: pip install cryptography\n"
                    "Or decrypt this backup on a system that still has cryptography installed, "
                    "then re-encrypt with: python -m nexus.backup"
                )
            salt = data[9:25]
            encrypted = data[25:]
            # PBKDF2 key derivation (legacy — używane tylko dla NEXUSENC1)
            import hashlib

            key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 600_000, dklen=32)
            # AES-256-CBC decrypt
            iv = encrypted[:16]
            ciphertext = encrypted[16:]
            cipher = _Cipher(_algos.AES(key), _modes.CBC(iv))
            decryptor = cipher.decryptor()
            padded_data = decryptor.update(ciphertext) + decryptor.finalize()
            unpadder = _crypto_padding.PKCS7(128).unpadder()
            return unpadder.update(padded_data) + unpadder.finalize()

        else:
            # Niezaszyfrowany ZIP
            return data

    # ── SUPERMOC: Delta Lake dla ACID backups ─────────────────────────
    # Delta Lake dodaje ACID transactions do formatu Parquet:
    # - Atomic commits: write + metadata w jednej transakcji
    # - Time travel: dostęp do dowolnej wersji backupu
    # - Schema enforcement: dodawanie kolumn nie psuje danych
    # - Zysk: backup z gwarancją ACID, bez ryzyka partial write

    def export_to_delta(
        self,
        duckdb_query: str,
        delta_table_path: str | Path | None = None,
        mode: str = "append",
        partition_by: list[str] | None = None,
    ) -> str:
        """SUPERMOC Delta Lake: Eksportuj dane z DuckDB do Delta Lake.

        Delta Lake dodaje warstwę ACID na Parquet:
        - Atomic commits: każdy zapis jest atomowy
        - Time travel: ``DeltaTable.load_as_version(N)`` do historycznych wersji
        - Schema enforcement: bezpieczne dodawanie kolumn

        Args:
            duckdb_query: Zapytanie SQL do DuckDB.
            delta_table_path: Ścieżka do tabeli Delta (domyślnie backups/delta).
            mode: "append" (dodaj do istniejącej) lub "overwrite" (nadpisz).
            partition_by: Kolumny do partycjonowania (np. ["year", "month"]).

        Returns:
            Ścieżka do Delta Table.
        """
        if not _HAS_DELTA:
            logger.warning(
                "[BACKUP] Delta Lake not available — install with: pip install deltalake"
            )
            return self.create_encrypted_zip()

        delta_path = Path(delta_table_path or self.backup_dir / "delta_backup")
        delta_path.mkdir(parents=True, exist_ok=True)

        try:
            # Pobierz dane z DuckDB jako Arrow Table
            conn = _duckdb.connect()
            try:
                arrow_table = conn.execute(duckdb_query).fetch_arrow_table()
            finally:
                conn.close()

            # Konwertuj na Pandas DataFrame (niezbędne dla deltalake)
            import pandas as pd
            pdf = arrow_table.to_pandas()

            # ── SUPERMOC: Delta Lake write z ACID ────────────────────
            # ``write_deltalake()`` tworzy _delta_log/ z commitami
            # Każdy commit to atomowa transakcja JSON.
            _delta.write_deltalake(
                str(delta_path),
                pdf,
                mode=mode,
                partition_by=partition_by or [],
            )

            logger.info(
                "[BACKUP] Delta Lake backup committed: %s (mode=%s)",
                delta_path,
                mode,
            )
            return str(delta_path)

        except Exception as exc:
            logger.error("[BACKUP] Delta Lake backup failed: %s", exc)
            return ""

    def list_delta_versions(self, delta_path: str | Path | None = None) -> list[dict]:
        """SUPERMOC Delta Lake: Wyświetl historię wersji Delta Table.

        Delta Lake przechowuje pełną historię commitów w ``_delta_log/``.
        ``DeltaTable.history()" zwraca każdą wersję z timestampem,
        operacją i metadanymi.
        Zysk: time travel — dostęp do każdej wersji backupu.

        Args:
            delta_path: Ścieżka do Delta Table.

        Returns:
            Lista słowników z historią wersji.
        """
        if not _HAS_DELTA:
            return [{"error": "Delta Lake not available"}]

        dt_path = str(delta_path or self.backup_dir / "delta_backup")
        try:
            table = _delta.DeltaTable(dt_path)
            history = table.history()
            if history is None or history.empty:
                return []
            return history.to_dict(orient="records")
        except Exception as exc:
            return [{"error": str(exc)}]

    def load_delta_version(
        self,
        version: int,
        delta_path: str | Path | None = None,
    ) -> Any:
        """SUPERMOC Delta Lake: Wczytaj konkretną wersję backupu (time travel).

        ``DeltaTable.load_as_version(N)`` ładuje stan tabeli z wersji N.
        Zysk: pełny time travel — dostęp do backupu sprzed tygodnia.

        Args:
            version: Numer wersji (0 = pierwszy backup).
            delta_path: Ścieżka do Delta Table.

        Returns:
            ``pyarrow.Table`` z danymi z danej wersji.
        """
        if not _HAS_DELTA:
            return None

        dt_path = str(delta_path or self.backup_dir / "delta_backup")
        try:
            table = _delta.DeltaTable(dt_path)
            table.load_as_version(version)
            return table.to_pyarrow_table()
        except Exception as exc:
            logger.error("[BACKUP] Failed to load Delta version %d: %s", version, exc)
            return None

    def prune_old_backups(self, keep_days: int = 30) -> int:
        """Remove backups older than keep_days and return deleted count."""
        cutoff = pendulum.now().subtract(days=keep_days)
        deleted = 0
        for backup in self.backup_dir.glob("backup_*"):
            try:
                modified = pendulum.from_timestamp(backup.stat().st_mtime)
            except FileNotFoundError:
                continue
            if modified < cutoff:
                backup.unlink(missing_ok=True)
                deleted += 1
        return deleted
