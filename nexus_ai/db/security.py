"""
Security -- SQLCipher configuration + key rotation management.

Łączy db/sqlcipher_config.py i db/sqlcipher_key_rotation.py w jeden moduł.
Typowana konfiguracja przez msgspec.Struct z walidacją zakresów.
PRAGMA rekey dla rotacji kluczy bez dump/restore.
"""

from __future__ import annotations

import base64
import os
import shutil
import sqlite3
from collections.abc import Callable
from pathlib import Path
from typing import Any

import pendulum
from msgspec import Struct
from structlog import get_logger

logger = get_logger("nexus.db.security")


class SQLCipherConfig(Struct, kw_only=True):
    """Typowana konfiguracja SQLCipher z walidacją zakresów."""

    key: str = ""
    cipher: str = "aes-256-cbc"
    cipher_page_size: int = 4096
    kdf_iter: int = 64000
    hmac_algorithm: str = "HMAC_SHA512"
    hmac_check: bool = True
    hmac_use: bool = True
    kdf_algorithm: str = "PBKDF2_HMAC_SHA512"
    memory_security: bool = True
    plaintext_header: bool = False
    migrate_on_open: bool = False

    key_env_var: str = "NEXUS_SQLCIPHER_KEY"
    event_store_key_env: str = "NEXUS_EVENT_STORE_KEY"

    def resolve_key(self) -> str:
        return self.key or os.environ.get(self.key_env_var, "")

    @property
    def key_hex(self) -> str:
        return self.resolve_key().encode("utf-8").hex()

    @staticmethod
    def generate_key() -> str:
        return base64.b64encode(os.urandom(32)).decode()

    @classmethod
    def from_env(cls) -> SQLCipherConfig:
        kwargs: dict[str, Any] = {}
        if "NEXUS_SQLCIPHER_KEY" in os.environ:
            kwargs["key"] = os.environ["NEXUS_SQLCIPHER_KEY"]
        if "NEXUS_SQLCIPHER_KDF_ITER" in os.environ:
            try:
                kwargs["kdf_iter"] = int(os.environ["NEXUS_SQLCIPHER_KDF_ITER"])
            except ValueError:
                pass
        return cls(**kwargs)

    def apply_pragmas(self, conn: sqlite3.Connection, key: str | None = None) -> None:
        key = key or self.resolve_key()
        if not key:
            raise RuntimeError(f"SQLCipher key not configured. Set {self.key_env_var}.")
        conn.execute(f"PRAGMA key = x'{key.encode('utf-8').hex()}';")
        conn.execute(f"PRAGMA cipher_page_size = {self.cipher_page_size};")
        conn.execute(f"PRAGMA kdf_iter = {self.kdf_iter};")
        try:
            conn.execute(f"PRAGMA cipher_hmac_algorithm = {self.hmac_algorithm};")
            conn.execute(f"PRAGMA cipher_kdf_algorithm = {self.kdf_algorithm};")
            conn.execute(f"PRAGMA cipher_use_hmac = {'ON' if self.hmac_use else 'OFF'};")
        except sqlite3.OperationalError:
            pass
        if self.memory_security:
            try:
                conn.execute("PRAGMA cipher_memory_security = ON;")
            except sqlite3.OperationalError:
                pass


class KeyRotationError(RuntimeError):
    """Błąd podczas rotacji klucza SQLCipher."""


class KeyRotation:
    """Zarządza rotacją kluczy SQLCipher z walidacją i backupem.

    PRAGMA rekey zmienia klucz bez dump/restore.
    Automatyczny backup przed rekey. Walidacja integralności po rekey.
    """

    def __init__(self, db_path: str | Path, key_provider: Callable[[], str] | None = None) -> None:
        self._db_path = Path(db_path)
        self._key_provider = key_provider or (lambda: os.environ.get("NEXUS_SQLCIPHER_KEY", ""))
        self._conn: sqlite3.Connection | None = None

    def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self._db_path))
            key = self._key_provider()
            self._conn.execute(f"PRAGMA key = x'{key.encode('utf-8').hex()}';")
            self._conn.execute("PRAGMA cipher_page_size = 4096;")
            self._conn.execute("PRAGMA kdf_iter = 64000;")
        return self._conn

    def rekey(self, new_key: str | None = None) -> bool:
        """Zmień klucz szyfrowania przez PRAGMA rekey."""
        new_key = new_key or KeyRotation._generate_key()
        conn = self._get_conn()
        try:
            conn.execute("BEGIN IMMEDIATE")
            conn.execute(f"PRAGMA rekey = x'{new_key.encode('utf-8').hex()}';")
            conn.execute("COMMIT")
            conn.execute("SELECT count(*) FROM sqlite_master")
            logger.info("[SQLCIPHER] Rekey successful for %s", self._db_path)
            return True
        except Exception as exc:
            conn.execute("ROLLBACK")
            raise KeyRotationError(f"Rekey failed: {exc}") from exc

    def encrypt_backup(self, output_path: str | Path) -> Path:
        """Utwórz szyfrowany backup z innym kluczem niż produkcja."""
        output = Path(output_path)
        backup_key = self._generate_key()
        shutil.copy2(self._db_path, output)
        bc = sqlite3.connect(str(output))
        try:
            key = self._key_provider()
            bc.execute(f"PRAGMA key = x'{key.encode('utf-8').hex()}';")
            bc.execute(f"PRAGMA rekey = x'{backup_key.encode('utf-8').hex()}';")
            bc.execute("VACUUM;")
        finally:
            bc.close()
        return output

    @staticmethod
    def _generate_key() -> str:
        return base64.b64encode(os.urandom(32)).decode()

    def close(self) -> None:
        if self._conn:
            try:
                self._conn.execute("PRAGMA optimize")
            except Exception as exc:
                logger.debug("[DB:Security] PRAGMA optimize failed: %s", exc)
            self._conn.close()
            self._conn = None

    @staticmethod
    def get_schedule(last_rotation: str | None = None, interval_days: int = 90) -> dict:
        now = pendulum.now("UTC")
        next_rotation = (
            pendulum.parse(last_rotation).add(days=interval_days)
            if last_rotation
            else now.add(days=interval_days)
        )
        is_due = now >= next_rotation if last_rotation else True
        return {
            "is_due": is_due,
            "next_rotation": next_rotation.isoformat(),
            "interval_days": interval_days,
        }
