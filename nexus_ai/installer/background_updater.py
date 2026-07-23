"""background_updater.py — Background Update Download (v7.0 Rec #2: Innowacja 3).

  Aplikacja pobiera aktualizacje W TLE, gdy użytkownik pracuje.
  Gdy gotowa → cicha podmiana plików i komunikat:
  "Aktualizacja gotowa. Uruchom ponownie by zastosować."

  Zero przestojów — aktualizacja jest gotowa zanim użytkownik ją zobaczy.

  Wspiera:
  - Phased Rollout (v7.0 Rec #1: Innowacja 2)
  - Rollback mechanism (v7.0 Rec #3: Innowacja 15)
  - SHA-256 verification (already in installer/updater.py)
"""

from __future__ import annotations

import asyncio
import hashlib
import platform
from pathlib import Path

from structlog import get_logger

from nexus_ai.installer.updater import (
    check_for_updates,
    download_update,
    install_update,
    CURRENT_VERSION,
)

logger = get_logger("nexus.installer.background")


# ── Phased Rollout (Innowacja 2) ───────────────────────────────────────────


def should_rollout_to_user(
    user_id: str,
    rollout_percentage: int = 100,
) -> bool:
    """Sprawdź czy użytkownik kwalifikuje się do stopniowego wdrożenia.

    v7.0 Innowacja 2: Phased Rollout.
    Używa deterministycznego hashu user_id do podziału na grupy.
    rollout_percentage 0-100 określa jaki procent użytkowników otrzymuje update.

    Args:
        user_id: Unikalny identyfikator użytkownika
        rollout_percentage: Procent użytkowników (0-100)

    Returns:
        True jeśli użytkownik powinien otrzymać aktualizację
    """
    if rollout_percentage >= 100:
        return True
    if rollout_percentage <= 0:
        return False

    # Deterministyczny hash do grupowania
    hash_val = int(hashlib.md5(user_id.encode()).hexdigest()[:8], 16)
    user_percentile = hash_val % 100
    return user_percentile < rollout_percentage


# ── Background Download Manager ────────────────────────────────────────────


class BackgroundUpdateManager:
    """Zarządza cichym pobieraniem aktualizacji w tle.

    Użycie:
        manager = BackgroundUpdateManager(user_id="user-123")
        await manager.start_background_check(page)

    Flow:
        1. W tle sprawdza version.json
        2. Jeśli update dostępny → cicho pobiera w tle
        3. Po pobraniu → zapisuje .ready marker
        4. Przy następnym uruchomieniu → aplikuje update
    """

    def __init__(self, user_id: str = ""):
        self.user_id = user_id
        self._download_task: asyncio.Task | None = None
        self._ready_path: Path | None = None
        self._skip_version: str | None = None

    async def start_background_check(self, page=None) -> bool:
        """Rozpocznij ciche sprawdzanie i pobieranie w tle.

        Args:
            page: Opcjonalna instancja Flet Page dla powiadomień UI

        Returns:
            True jeśli update został pobrany w tle
        """
        try:
            result = await check_for_updates(timeout=10)
            if not result.update_available or not result.info:
                logger.debug("[BG UPDATE] No update available")
                return False

            info = result.info

            # Phased Rollout check
            rollout = getattr(info, 'rollout_percentage', 100)
            if rollout < 100 and self.user_id:
                if not should_rollout_to_user(self.user_id, rollout):
                    logger.info(
                        "[BG UPDATE] User not in rollout group "
                        "(rollout=%d%%, user_id=%s)",
                        rollout, self.user_id[:8],
                    )
                    return False

            logger.info(
                "[BG UPDATE] Downloading v%s in background (%d MB)...",
                info.version, info.download_size_mb,
            )

            # Ciche pobieranie w tle
            installer_path = await download_update(info)
            if installer_path:
                # Zapisz .ready marker
                self._ready_path = installer_path
                ready_marker = installer_path.with_suffix(".ready")
                ready_marker.write_text(info.version)

                logger.info(
                    "[BG UPDATE] ✓ Downloaded v%s to %s",
                    info.version, installer_path,
                )

                # Powiadom UI jeśli dostępne
                if page:
                    self._notify_ready(page, info)
                return True

            return False

        except Exception as exc:
            logger.warning("[BG UPDATE] Background check failed: %s", exc)
            return False

    def _notify_ready(self, page, info):
        """Powiadom użytkownika że aktualizacja jest gotowa."""
        try:
            from nexus_ai.frontend.ui.notification_center import (
                add_notification,
            )
            add_notification(
                title=f"Aktualizacja v{info.version} gotowa!",
                body=f"Pobrano {info.download_size_mb} MB w tle. "
                      "Uruchom ponownie aplikację by zastosować.",
                category="update",
                action_label="Uruchom ponownie",
                priority="normal",
            )
        except Exception:
            pass

    def check_ready_update(self) -> Path | None:
        """Sprawdź czy jest gotowa aktualizacja do zastosowania.

        Returns:
            Ścieżka do pobranego instalatora lub None
        """
        if self._ready_path and self._ready_path.exists():
            return self._ready_path

        # Sprawdź temp directory
        import tempfile
        temp_dir = Path(tempfile.gettempdir()) / "NexusAI_Update"
        for ready_file in temp_dir.glob("*.ready"):
            installer = ready_file.with_suffix("")
            # Usuń .ready suffix
            if ready_file.suffix == ".ready":
                installer = Path(str(ready_file)[:-6])
            if installer.exists():
                return installer
        return None


# ── OTA Rollback Watchdog (Innowacja 15) ─────────────────────────────────


class OTARollbackWatchdog:
    """Monitoruje crashe aplikacji i automatycznie przywraca poprzednią wersję.

    v7.0 Innowacja 15: Jeśli po aktualizacji aplikacja crashuje 3 razy
    w ciągu 5 minut → automatyczny rollback do poprzedniej wersji.

    Mechanizm:
    - Zapisuje timestampy crashy w pliku .crash_log
    - Jeśli 3 crashy w 5 minut → przywraca .bak
    - Jeśli rollback się powiedzie → czyści crash log
    """

    CRASH_WINDOW_SECONDS = 300  # 5 minut
    MAX_CRASHES = 3

    def __init__(self, app_version: str = CURRENT_VERSION):
        self.app_version = app_version
        self._crash_log_path = self._get_crash_log_path()

    @staticmethod
    def _get_crash_log_path() -> Path:
        import tempfile
        return Path(tempfile.gettempdir()) / "NexusAI" / ".crash_log"

    def record_crash(self):
        """Zapisz timestamp crashu."""
        import time as _time
        self._crash_log_path.parent.mkdir(parents=True, exist_ok=True)

        timestamps = self._read_crash_log()
        timestamps.append(_time.time())
        timestamps = timestamps[-self.MAX_CRASHES:]

        self._crash_log_path.write_text(
            "\n".join(str(t) for t in timestamps)
        )
        logger.warning(
            "[ROLLBACK] Crash recorded (%d/%d in window)",
            len(timestamps), self.MAX_CRASHES,
        )

    def _read_crash_log(self) -> list[float]:
        if not self._crash_log_path.exists():
            return []
        try:
            return [
                float(line.strip())
                for line in self._crash_log_path.read_text().strip().split("\n")
                if line.strip()
            ]
        except Exception:
            return []

    def should_rollback(self) -> bool:
        """Sprawdź czy powinien nastąpić rollback.

        Returns:
            True jeśli 3+ crashy w ostatnich 5 minutach
        """
        import time as _time
        timestamps = self._read_crash_log()
        if len(timestamps) < self.MAX_CRASHES:
            return False

        now = _time.time()
        recent = [t for t in timestamps if now - t <= self.CRASH_WINDOW_SECONDS]
        return len(recent) >= self.MAX_CRASHES

    def perform_rollback(self) -> bool:
        """Wykonaj rollback do poprzedniej wersji.

        Zamienia bieżący .exe na .bak (backup sprzed aktualizacji).

        Returns:
            True jeśli rollback się powiódł
        """
        import sys
        if not getattr(sys, "frozen", False):
            logger.warning("[ROLLBACK] Not running as frozen app — cannot rollback")
            return False

        current_exe = Path(sys.executable)
        backup_path = current_exe.with_suffix(current_exe.suffix + ".bak")

        if not backup_path.exists():
            logger.error("[ROLLBACK] No backup found at %s", backup_path)
            return False

        try:
            # Rename current (broken) → .crashed
            crashed_path = current_exe.with_suffix(".crashed")
            crashed_path.unlink(missing_ok=True)
            current_exe.rename(crashed_path)

            # Restore backup → current
            backup_path.rename(current_exe)

            # Clean crash log
            self._crash_log_path.unlink(missing_ok=True)

            logger.info(
                "[ROLLBACK] ✓ Rollback successful: %s restored",
                backup_path,
            )
            return True
        except Exception as exc:
            logger.error("[ROLLBACK] Rollback failed: %s", exc)
            return False

    def clear_crash_log(self):
        """Wyczyść crash log (np. po udanym uruchomieniu)."""
        import time as _time
        self._crash_log_path.unlink(missing_ok=True)
        # Zapisz "healthy" marker z timestampem
        self._crash_log_path.parent.mkdir(parents=True, exist_ok=True)
        (self._crash_log_path.parent / ".healthy").write_text(str(_time.time()))


# ── Convenience: sprawdź crash log przy starcie ──────────────────────────


def check_crash_on_startup() -> bool:
    """Sprawdź przy starcie czy aplikacja nie crashowała.

    Jeśli wykryto pattern crashy → wykonaj rollback.
    Jeśli start udany → wyczyść crash log.

    Returns:
        True jeśli wykonano rollback
    """
    watchdog = OTARollbackWatchdog()

    if watchdog.should_rollback():
        logger.critical("[ROLLBACK] Crash pattern detected — initiating rollback")
        return watchdog.perform_rollback()

    # Normalny start — wyczyść log
    watchdog.clear_crash_log()
    return False
