"""
SQLCipher Key Rotation Manager — rotacja kluczy szyfrowania SQLCipher.

SUPERMOC: ``PRAGMA rekey`` pozwala zmienić klucz szyfrowania SQLCipher
bez dumpowania i przywracania bazy. SQLCipher deszyfruje każdą stronę
starym kluczem i szyfruje nowym — w miejscu, bez downtime.

Zgodnie z aa3fvcx.txt:
- Rotacja kluczy zgodna z GDPR/PCI-DSS (okresowa zmiana kluczy)
- Szyfrowane backup z innym kluczem niż produkcyjny
- Automatyczny backup przed każdą rotacją

Usage:
    from nexus_ai.db.sqlcipher_key_rotation import rotate_sqlcipher_key

    # Ręczna rotacja
    success = rotate_sqlcipher_key("app_data/databases/nexus_oltp.db")

    # Z harmonogramem
    from schedule import every, repeat
    @repeat(every().day.at("03:00"))
    def rotate_keys():
        rotate_sqlcipher_key("app_data/databases/nexus_oltp.db")
"""

from __future__ import annotations

import base64
import hashlib
import os
import sqlite3
import time
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.db.rekey")


class SQLCipherReKeyError(RuntimeError):
    """Błąd podczas rotacji klucza SQLCipher."""


class ReKeyResult:
    """Wynik operacji rekey."""

    def __init__(
        self,
        success: bool,
        old_key_hash: str = "",
        new_key_hash: str = "",
        backup_path: str = "",
        duration_ms: float = 0.0,
        error: str = "",
    ) -> None:
        self.success = success
        self.old_key_hash = old_key_hash
        self.new_key_hash = new_key_hash
        self.backup_path = backup_path
        self.duration_ms = duration_ms
        self.error = error


def _get_default_key() -> str:
    """Pobierz klucz z env var."""
    key = os.environ.get("NEXUS_SQLCIPHER_KEY", "")
    if not key:
        raise SQLCipherReKeyError("NEXUS_SQLCIPHER_KEY not set")
    return key


def _hash_key(key: str) -> str:
    """Hash klucza dla logów (nigdy nie loguj raw klucza!)."""
    return hashlib.sha256(key.encode()).hexdigest()[:16]


def _open_connection(
    db_path: str | Path,
    key: str,
) -> sqlite3.Connection:
    """Otwórz połączenie z bazą SQLCipher z danym kluczem.

    SUPERMOC: Używa ``SQLCipherConfig.from_env().apply_pragmas()`` zamiast
    ręcznego ustawiania PRAGM — jedna źródło prawdy dla konfiguracji SQLCipher.

    Args:
        db_path: Ścieżka do pliku DB.
        key: Klucz AES-256.

    Returns:
        sqlite3.Connection z ustawionym PRAGMA key.
    """
    from nexus_ai.db.sqlcipher_config import SQLCipherConfig

    conn = sqlite3.connect(str(db_path))
    config = SQLCipherConfig(key=key)
    config.apply_pragmas(conn, key=key)
    return conn


def _verify_connection(conn: sqlite3.Connection) -> bool:
    """Sprawdź czy klucz jest poprawny (baza czytelna)."""
    try:
        conn.execute("SELECT count(*) FROM sqlite_master").fetchone()
        return True
    except sqlite3.DatabaseError:
        return False


def create_encrypted_backup(
    db_path: str | Path,
    output_path: str | Path,
    source_key: str | None = None,
    backup_key: str | None = None,
) -> Path:
    """Utwórz szyfrowany backup bazy z INNYM kluczem niż produkcyjny.

    SUPERMOC: Backup może mieć inny klucz niż produkcyjna baza.
    Backup key jest przechowywany offline (np. w Vault lub na papierze).
    Nawet jeśli ktoś ukradnie backup, nie może go odczytać bez backup key.

    Args:
        db_path: Ścieżka do oryginalnej bazy.
        output_path: Ścieżka pliku backupu.
        source_key: Klucz źródłowej bazy (domyślnie z env).
        backup_key: Klucz dla backupu (domyślnie losowy).

    Returns:
        Ścieżka do backupu.

    Raises:
        SQLCipherReKeyError: Gdy backup się nie powiedzie.
    """
    import shutil

    source_key = source_key or _get_default_key()
    backup_key = backup_key or base64.b64encode(os.urandom(32)).decode()
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Krok 1: Kopiuj plik DB
    shutil.copy2(db_path, output_path)

    # Krok 2: Otwórz backup z oryginalnym kluczem
    try:
        backup_conn = _open_connection(output_path, source_key)

        # Krok 3: Zweryfikuj integralność
        if not _verify_connection(backup_conn):
            raise SQLCipherReKeyError("Backup verification failed: cannot decrypt copy")

        # Krok 4: Zmień klucz backupu przez PRAGMA rekey
        backup_key_hex = backup_key.encode("utf-8").hex()
        backup_conn.execute("PRAGMA rekey = x'%s';" % backup_key_hex)
        backup_conn.execute("VACUUM;")  # Kompaktuj i odśwież statystyki
        backup_conn.close()
    except Exception as exc:
        # Cleanup przy błędzie
        try:
            backup_conn.close()
        except Exception:
            pass
        output_path.unlink(missing_ok=True)
        raise SQLCipherReKeyError(f"Backup failed: {exc}") from exc

    logger.info(
        "[Rekey] Encrypted backup created at %s (hash=%s)",
        output_path,
        _hash_key(backup_key),
    )
    return output_path


def rekey_database(
    db_path: str | Path,
    new_key: str | None = None,
    old_key: str | None = None,
    backup_dir: str | Path | None = None,
) -> ReKeyResult:
    """Zmień klucz szyfrowania bazy SQLCipher przez PRAGMA rekey.

    SUPERMOC: PRAGMA rekey zmienia klucz w miejscu:
    1. Deszyfruje każdą stronę starym kluczem
    2. Szyfruje każdą stronę nowym kluczem
    3. Zero downtime — baza dostępna przez cały czas

    Args:
        db_path: Ścieżka do pliku DB.
        new_key: Nowy klucz (domyślnie losowy).
        old_key: Stary klucz (domyślnie z NEXUS_SQLCIPHER_KEY).
        backup_dir: Katalog na backup przed rekey (opcjonalnie).

    Returns:
        ReKeyResult z informacją o wyniku.
    """
    t0 = time.time()
    db_path = Path(db_path)
    old_key = old_key or _get_default_key()
    new_key = new_key or base64.b64encode(os.urandom(32)).decode()

    try:
        # Krok 1: Backup przed rekey (jeśli skonfigurowany)
        backup_path = ""
        if backup_dir:
            backup_dir_path = Path(backup_dir)
            backup_dir_path.mkdir(parents=True, exist_ok=True)
            backup_file = backup_dir_path / f"{db_path.stem}_pre_rekey_{int(t0)}.db"
            backup_path = str(create_encrypted_backup(
                db_path=db_path,
                output_path=backup_file,
                source_key=old_key,
            ))

        # Krok 2: Otwórz połączenie z starym kluczem
        with _open_connection(db_path, old_key) as conn:
            # Weryfikacja starego klucza
            if not _verify_connection(conn):
                return ReKeyResult(
                    success=False,
                    error="Old key verification failed: cannot decrypt database",
                    duration_ms=(time.time() - t0) * 1000,
                )

            # Krok 3: Wykonaj PRAGMA rekey
            new_key_hex = new_key.encode("utf-8").hex()
            conn.execute("BEGIN IMMEDIATE")
            try:
                conn.execute("PRAGMA rekey = x'%s';" % new_key_hex)
                conn.execute("COMMIT")
            except Exception:
                conn.execute("ROLLBACK")
                raise

            # Krok 4: Weryfikacja nowego klucza
            # Zamknij i otwórz ponownie z nowym kluczem
            conn.close()

        # Otwarte z nowym kluczem
        with _open_connection(db_path, new_key) as verify_conn:
            if not _verify_connection(verify_conn):
                return ReKeyResult(
                    success=False,
                    old_key_hash=_hash_key(old_key),
                    new_key_hash=_hash_key(new_key),
                    error="New key verification failed after rekey",
                    backup_path=backup_path,
                    duration_ms=(time.time() - t0) * 1000,
                )

        duration = (time.time() - t0) * 1000
        logger.info(
            "[Rekey] Success: %s old=%s → new=%s backup=%s duration=%.0fms",
            db_path,
            _hash_key(old_key),
            _hash_key(new_key),
            backup_path or "none",
            duration,
        )

        return ReKeyResult(
            success=True,
            old_key_hash=_hash_key(old_key),
            new_key_hash=_hash_key(new_key),
            backup_path=backup_path,
            duration_ms=duration,
        )

    except Exception as exc:
        logger.error("[Rekey] Failed: %s — %s", db_path, exc)
        return ReKeyResult(
            success=False,
            error=str(exc),
            duration_ms=(time.time() - t0) * 1000,
        )


def verify_sqlcipher_key(
    db_path: str | Path,
    key: str | None = None,
) -> bool:
    """Sprawdź czy dany klucz otwiera bazę SQLCipher.

    Args:
        db_path: Ścieżka do pliku DB.
        key: Klucz do weryfikacji (domyślnie z env).

    Returns:
        True jeśli klucz jest poprawny.
    """
    key = key or _get_default_key()
    try:
        conn = _open_connection(db_path, key)
        result = _verify_connection(conn)
        conn.close()
        return result
    except Exception:
        return False


def get_key_hash(key: str | None = None) -> str:
    """Zwraca hash bieżącego klucza (bezpieczny do logowania)."""
    key = key or os.environ.get("NEXUS_SQLCIPHER_KEY", "")
    return _hash_key(key) if key else "no_key_configured"
