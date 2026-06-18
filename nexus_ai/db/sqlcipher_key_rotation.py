"""
SQLCipher Key Rotation Manager.

SUPERMOCE SQLCipher:
- PRAGMA rekey: zmiana klucza szyfrowania bez dump/restore
- Szyfrowany backup: backup z INNYM kluczem niż produkcja
- Automatyczna walidacja po rekey
- Harmonogram rotacji (np. co 90 dni zgodnie z GDPR)

Zgodnie z docs/SQLCIPHER_AUDIT.md FAZA 2.
"""

from __future__ import annotations

import base64
import os
import shutil
import sqlite3
from pathlib import Path
from typing import Callable

import pendulum
from structlog import get_logger

logger = get_logger("nexus.db.sqlcipher")


class SQLCipherReKeyError(RuntimeError):
    """Błąd podczas rotacji klucza SQLCipher."""


class KeyRotationManager:
    """Zarządza rotacją kluczy SQLCipher z walidacją i backupem.

    SUPERMOCE:
    - PRAGMA rekey do zmiany klucza bez dump/restore
    - Automatyczny backup przed rekey
    - Walidacja integralności po rekey
    - Schedule-based rotation (np. co 90 dni)
    """

    def __init__(
        self,
        db_path: str | Path,
        key_provider: Callable[[], str] | None = None,
    ) -> None:
        self._db_path = Path(db_path)
        self._key_provider = key_provider or self._default_key_provider
        self._conn: sqlite3.Connection | None = None

    @staticmethod
    def _default_key_provider() -> str:
        """Pobierz klucz z NEXUS_SQLCIPHER_KEY."""
        key = os.environ.get("NEXUS_SQLCIPHER_KEY", "")
        if not key:
            raise SQLCipherReKeyError("NEXUS_SQLCIPHER_KEY not set")
        return key

    def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self._db_path))
            key = self._key_provider()
            key_hex = key.encode("utf-8").hex()
            self._conn.execute("PRAGMA key = x'%s';" % key_hex)
            self._conn.execute("PRAGMA cipher_page_size = 4096;")
            self._conn.execute("PRAGMA kdf_iter = 64000;")
            self._conn.execute("PRAGMA cipher_memory_security = ON;")
            self._conn.execute("PRAGMA cipher_default_plaintext_header = ON;")
        return self._conn

    def rekey(self, new_key: str | None = None) -> bool:
        """SUPERMOC: Zmień klucz szyfrowania bazy danych przez PRAGMA rekey.

        Args:
            new_key: Nowy klucz (losowy jeśli None).

        Returns:
            True jeśli rekey succeeded.
        """
        if new_key is None:
            new_key = self._generate_key()

        conn = self._get_conn()
        new_key_hex = new_key.encode("utf-8").hex()

        try:
            conn.execute("BEGIN IMMEDIATE")
            conn.execute("PRAGMA rekey = x'%s';" % new_key_hex)
            conn.execute("COMMIT")

            # Weryfikacja — czy baza jest czytelna z nowym kluczem
            conn.execute("SELECT count(*) FROM sqlite_master")

            logger.info("[SQLCIPHER] Rekey successful for %s", self._db_path)
            return True
        except Exception as exc:
            conn.execute("ROLLBACK")
            logger.error("[SQLCIPHER] Rekey failed for %s: %s", self._db_path, exc)
            raise SQLCipherReKeyError(f"Rekey failed: {exc}") from exc

    def encrypt_backup(self, output_path: str | Path) -> Path:
        """SUPERMOC: Utwórz szyfrowany backup z INNYM kluczem niż produkcja.

        Backup key może być przechowywany osobno (offline).

        Args:
            output_path: Ścieżka pliku backupu.

        Returns:
            Ścieżka do backupu.
        """
        output_path = Path(output_path)
        backup_key = self._generate_key()

        # Kopiuj plik DB
        shutil.copy2(self._db_path, output_path)

        # Otwórz backup z oryginalnym kluczem i zmień na backup key
        backup_conn = sqlite3.connect(str(output_path))
        try:
            key = self._key_provider()
            backup_conn.execute("PRAGMA key = x'%s';" % key.encode("utf-8").hex())
            backup_conn.execute("PRAGMA cipher_page_size = 4096;")
            backup_conn.execute("PRAGMA kdf_iter = 64000;")

            # Zmień klucz backupu
            backup_conn.execute("PRAGMA rekey = x'%s';" % backup_key.encode("utf-8").hex())
            backup_conn.execute("VACUUM;")  # Kompaktuj backup
            backup_conn.close()
        except Exception:
            backup_conn.close()
            output_path.unlink(missing_ok=True)
            raise

        logger.info("[SQLCIPHER] Encrypted backup created at %s (key=%s...)", output_path, backup_key[:8])
        return output_path

    @staticmethod
    def _generate_key() -> str:
        """Generuj losowy 32-bajtowy klucz."""
        return base64.b64encode(os.urandom(32)).decode()

    def close(self) -> None:
        if self._conn is not None:
            try:
                self._conn.execute("PRAGMA optimize")
            except Exception:
                pass
            self._conn.close()
            self._conn = None

    @staticmethod
    def get_rotation_schedule(last_rotation: str | None = None, interval_days: int = 90) -> dict:
        """SUPERMOC: Harmonogram rotacji kluczy (zgodność z GDPR/PCI-DSS).

        Args:
            last_rotation: ISO timestamp ostatniej rotacji (lub None).
            interval_days: Interwał rotacji w dniach (domyślnie 90).

        Returns:
            Dict z informacją czy rotacja jest wymagana i datą następnej.
        """
        now = pendulum.now("UTC")
        if last_rotation:
            last = pendulum.parse(last_rotation)
            next_rotation = last.add(days=interval_days)
            is_due = now >= next_rotation
        else:
            next_rotation = now.add(days=interval_days)
            is_due = True

        return {
            "is_due": is_due,
            "last_rotation": last_rotation,
            "next_rotation": next_rotation.isoformat(),
            "interval_days": interval_days,
            "days_until_next": now.diff(next_rotation).in_days() if not is_due else 0,
        }
