"""
SQLCipher Auto-Rotation Scheduler (v7.0 Audit).

Raport v7.0, sekcja 3.2:
  "Brak automatycznej rotacji (trzeba ręcznie wywołać)"

Enterprise v7.0:
  - Automatyczna rotacja co 90 dni
  - Sprawdzanie is_due przy starcie aplikacji
  - Backup przed każdą rotacją
  - Walidacja integralności po rekey
  - Logowanie każdej rotacji do audytu
"""

from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.db.rotation")


class SQLCipherRotationScheduler:
    """Automatyczny scheduler rotacji kluczy SQLCipher.

    Usage:
        scheduler = SQLCipherRotationScheduler(db_path="app_data/oltp.db")
        if scheduler.is_rotation_due():
            scheduler.perform_rotation()
    """

    DEFAULT_INTERVAL_DAYS: int = 90
    LAST_ROTATION_FILE: str = "app_data/.last_sqlcipher_rotation"

    def __init__(
        self,
        db_path: str | Path,
        *,
        interval_days: int = 90,
        rotation_tracker_path: str | Path | None = None,
    ) -> None:
        self._db_path = Path(db_path)
        self._interval_days = interval_days
        self._tracker_path = Path(
            rotation_tracker_path or self.LAST_ROTATION_FILE
        )
        self._tracker_path.parent.mkdir(parents=True, exist_ok=True)

    def is_rotation_due(self) -> bool:
        """Czy rotacja klucza jest wymagana?

        Returns:
            True jeśli minęło >= interval_days od ostatniej rotacji.
        """
        if not self._tracker_path.exists():
            logger.info(
                "[SQLCIPHER-ROTATION] No previous rotation recorded — rotation is due"
            )
            return True

        try:
            last_iso = self._tracker_path.read_text().strip()
            last_rotation = datetime.fromisoformat(last_iso)
            days_since = (datetime.now(timezone.utc) - last_rotation).days
            is_due = days_since >= self._interval_days
            if is_due:
                logger.info(
                    "[SQLCIPHER-ROTATION] Rotation due: %d days since last (threshold=%d)",
                    days_since, self._interval_days,
                )
            else:
                logger.debug(
                    "[SQLCIPHER-ROTATION] Rotation not due: %d days since last",
                    days_since,
                )
            return is_due
        except (ValueError, OSError) as exc:
            logger.warning(
                "[SQLCIPHER-ROTATION] Invalid rotation tracker file: %s", exc
            )
            return True  # Assume rotation is due if file is corrupted

    def perform_rotation(self) -> bool:
        """Wykonaj rotację klucza SQLCipher.

        Returns:
            True jeśli rotacja się powiodła.
        """
        try:
            from nexus_ai.db.security import KeyRotation

            # Wygeneruj nowy klucz
            new_key = self._generate_new_key()

            # Wykonaj backup przed rotacją
            backup_path = self._create_backup()

            # Rotacja klucza
            rotator = KeyRotation(
                self._db_path,
                key_provider=lambda: os.environ.get("NEXUS_SQLCIPHER_KEY", ""),
            )

            success = rotator.rekey(new_key)
            if not success:
                logger.error("[SQLCIPHER-ROTATION] Rekey failed!")
                return False

            # Zaktualizuj env var (jeśli to bezpieczne)
            # W produkcji: zapisz nowy klucz w Vault/HSM
            os.environ["NEXUS_SQLCIPHER_KEY"] = new_key

            # Zapisz timestamp rotacji
            self._record_rotation()

            logger.info(
                "[SQLCIPHER-ROTATION] Successfully rotated SQLCipher key. "
                "Backup saved at %s. Next rotation in %d days.",
                backup_path, self._interval_days,
            )

            rotator.close()
            return True

        except ImportError as exc:
            logger.error("[SQLCIPHER-ROTATION] KeyRotation not available: %s", exc)
            return False
        except Exception as exc:
            logger.error("[SQLCIPHER-ROTATION] Rotation failed: %s", exc)
            return False

    def _create_backup(self) -> Path:
        """Utwórz backup przed rotacją."""
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        backup_dir = self._db_path.parent / "backups"
        backup_dir.mkdir(parents=True, exist_ok=True)
        backup_path = backup_dir / f"pre_rotation_backup_{timestamp}.db"
        import shutil
        shutil.copy2(self._db_path, backup_path)
        logger.info("[SQLCIPHER-ROTATION] Backup created: %s", backup_path)
        return backup_path

    def _record_rotation(self) -> None:
        """Zapisz timestamp ostatniej rotacji."""
        now = datetime.now(timezone.utc).isoformat()
        self._tracker_path.write_text(now)
        logger.debug("[SQLCIPHER-ROTATION] Rotation timestamp recorded: %s", now)

    @staticmethod
    def _generate_new_key() -> str:
        """Wygeneruj nowy klucz SQLCipher."""
        import base64
        return base64.b64encode(os.urandom(32)).decode()

    def get_rotation_status(self) -> dict[str, Any]:
        """Pobierz status rotacji."""
        if not self._tracker_path.exists():
            return {
                "last_rotation": None,
                "days_since": None,
                "is_due": True,
                "interval_days": self._interval_days,
            }
        try:
            last_iso = self._tracker_path.read_text().strip()
            last_rotation = datetime.fromisoformat(last_iso)
            days_since = (datetime.now(timezone.utc) - last_rotation).days
            return {
                "last_rotation": last_iso,
                "days_since": days_since,
                "is_due": days_since >= self._interval_days,
                "interval_days": self._interval_days,
            }
        except (ValueError, OSError):
            return {
                "last_rotation": "unknown",
                "days_since": None,
                "is_due": True,
                "interval_days": self._interval_days,
            }
