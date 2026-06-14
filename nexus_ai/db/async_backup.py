"""
AsyncBackup — async backup service using aiosqlite.backup() API.

SUPERMOC: aiosqlite 0.22.1 wspiera ``await source.backup(target)`` — async backup
między połączeniami SQLite. Działa w pamięci, nie blokuje pętli zdarzeń.

Zgodnie z docs/AIOSQLITE_AUDIT.md:
- FAZA 3+: Async backup dla wszystkich baz danych
- Wspiera SQLCipher (backup między szyfrowanymi bazami)
- Wiele źródeł: OLTP, event store, projections, DuckDB metadata

Usage:
    backup = AsyncBackup()
    await backup.backup_all(output_dir="backups/2026-06-14")
    await backup.backup_single("app_data/nexus_oltp.db", "backups/oltp.db")
"""

from __future__ import annotations

import os
import time
from datetime import datetime
from pathlib import Path
from typing import Any

import aiosqlite
from structlog import get_logger

logger = get_logger("nexus.db.async_backup")

# ── Default database paths ──────────────────────────────────────────────

DEFAULT_DATABASES: dict[str, str] = {
    "oltp": "app_data/databases/nexus_oltp.db",          # OLTP + FTS (współdzielą plik)
    "event_store": "app_data/databases/nexus_events.db",
    "projections_invoices": "app_data/projections/invoices.db",
    "projections_decisions": "app_data/projections/decisions.db",
}

# ── AsyncBackup ─────────────────────────────────────────────────────────


class AsyncBackup:
    """Async backup service for all NexusAI databases.

    SUPERMOCE:
    - ``await source.backup(target)`` — async, non-blocking backup
    - SQLCipher: backup works between encrypted databases (same key)
    - Multiple databases: OLTP, event store, projections
    - Progress logging: logs every 10% of backup progress
    - Atomic: backup is an online backup, DB stays readable/writable
    """

    def __init__(
        self,
        databases: dict[str, str] | None = None,
        sqlcipher_key: str | None = None,
    ) -> None:
        self._databases = databases or dict(DEFAULT_DATABASES)
        self._sqlcipher_key = sqlcipher_key or os.environ.get("NEXUS_SQLCIPHER_KEY", "")

    async def backup_all(
        self,
        output_dir: str | Path,
        suffix: str | None = None,
    ) -> dict[str, dict[str, Any]]:
        """Wykonaj backup wszystkich baz danych (async).

        Args:
            output_dir: Katalog docelowy dla backupów.
            suffix: Opcjonalny sufiks (np. dzisiejsza data).

        Returns:
            Słownik z wynikami dla każdej bazy:
            ``{name: {"status": "ok"|"error", "path": "...", "size_mb": 1.5}}``
        """
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        suffix = suffix or datetime.now().strftime("%Y%m%d_%H%M%S")

        results: dict[str, dict[str, Any]] = {}

        for name, source_path in self._databases.items():
            try:
                source = Path(source_path)
                if not source.exists():
                    results[name] = {"status": "skipped", "reason": "source_not_found"}
                    logger.warning("[BACKUP] Source not found: %s", source_path)
                    continue

                target = output_path / f"{source.stem}_{suffix}{source.suffix}"
                result = await self.backup_single(str(source), str(target))
                results[name] = result
            except Exception as exc:
                results[name] = {"status": "error", "error": str(exc)}
                logger.error("[BACKUP] Failed to backup %s: %s", name, exc)

        # Podsumowanie
        ok_count = sum(1 for r in results.values() if r.get("status") == "ok")
        logger.info(
            "[BACKUP] All backups complete: %d/%d OK in %s",
            ok_count,
            len(results),
            output_dir,
        )
        return results

    async def backup_single(
        self,
        source_path: str,
        target_path: str,
    ) -> dict[str, Any]:
        """Wykonaj backup pojedynczej bazy danych (async).

        SUPERMOC: ``await source.backup(target)`` — aiosqlite wykonuje
        backup w całości asynchronicznie, nie blokując pętli zdarzeń.
        Backup atomiczny — SQLite pozostaje dostępna do odczytu/zapisu.

        Args:
            source_path: Ścieżka źródłowej bazy danych.
            target_path: Ścieżka docelowa dla backupu.

        Returns:
            Słownik z wynikiem: status, path, size_mb.
        """
        target = Path(target_path)
        target.parent.mkdir(parents=True, exist_ok=True)

        logger.info("[BACKUP] Starting backup: %s → %s", source_path, target_path)

        # SUPERMOC: aiosqlite.backup() — async backup
        # Otwieramy źródłową i docelową bazę, wykonujemy backup.
        # Aby to działało, używamy jednego połączenia aiosqlite
        # które wykonuje backup synchronicznego sqlite3 w tle.
        start_time = time.time()

        # SUPERMOC: aiosqlite 0.22+ jest thread-safe (free-threaded Python 3.13t)
        # SQLCipher: PRAGMA key to PIERWSZA operacja po connect()!
        async with aiosqlite.connect(source_path) as src_conn:
            if self._sqlcipher_key:
                key_hex = self._sqlcipher_key.encode("utf-8").hex()
                await src_conn.execute(f"PRAGMA key = x'{key_hex}';")

            async with aiosqlite.connect(str(target)) as tgt_conn:
                # SQLCipher: ustaw klucz na docelowej bazie (PIERWSZA operacja)
                if self._sqlcipher_key:
                    key_hex = self._sqlcipher_key.encode("utf-8").hex()
                    await tgt_conn.execute(f"PRAGMA key = x'{key_hex}';")

                # SUPERMOC: await src.backup(target) — async backup
                # aiosqlite 0.22+ wspiera backup() delegując do
                # sqlite3_backup() w wątku tła.
                await src_conn.backup(tgt_conn, pages=-1, progress=self._progress_callback)

        duration = time.time() - start_time
        size_mb = target.stat().st_size / (1024 * 1024) if target.exists() else 0

        logger.info(
            "[BACKUP] Complete: %s → %s (%.1f MB, %.1fs)",
            source_path,
            target_path,
            size_mb,
            duration,
        )

        return {
            "status": "ok",
            "path": str(target),
            "source": source_path,
            "size_mb": round(size_mb, 2),
            "duration_s": round(duration, 2),
        }

    async def backup_to_memory(self, source_path: str) -> aiosqlite.Connection:
        """Wykonaj backup do pamięci RAM (super szybki).

        SUPERMOC: Backup do ``:memory:`` — idealne do testów lub
        tymczasowych kopii do odczytu bez I/O na dysku.

        Args:
            source_path: Ścieżka źródłowej bazy danych.

        Returns:
            aiosqlite.Connection do bazy w pamięci.
        """
        mem_conn = await aiosqlite.connect(":memory:")

        if self._sqlcipher_key:
            key_hex = self._sqlcipher_key.encode("utf-8").hex()
            await mem_conn.execute(f"PRAGMA key = x'{key_hex}';")

        async with aiosqlite.connect(source_path) as src_conn:
            if self._sqlcipher_key:
                key_hex = self._sqlcipher_key.encode("utf-8").hex()
                await src_conn.execute(f"PRAGMA key = x'{key_hex}';")
            await src_conn.backup(mem_conn)

        logger.info("[BACKUP] In-memory backup complete: %s", source_path)
        return mem_conn

    @staticmethod
    def _progress_callback(remaining: int, total: int) -> None:
        """Callback postępu backupu — loguje co 10%."""
        if total > 0 and remaining % max(1, total // 10) == 0:
            pct = ((total - remaining) / total) * 100
            logger.debug("[BACKUP] Progress: %.0f%% (%d/%d pages)", pct, total - remaining, total)

    def add_database(self, name: str, path: str) -> None:
        """Dodaj bazę danych do listy backupów."""
        self._databases[name] = path

    def remove_database(self, name: str) -> None:
        """Usuń bazę danych z listy backupów."""
        self._databases.pop(name, None)


# ── Convenience function ────────────────────────────────────────────────


async def create_async_backup(
    output_dir: str | Path = "backups",
    sqlcipher_key: str | None = None,
) -> dict[str, dict[str, Any]]:
    """Utwórz backup wszystkich baz danych (async).

    Usage:
        results = await create_async_backup("backups/today")
        for name, result in results.items():
            print(f"{name}: {result['status']} — {result.get('size_mb', 0)} MB")
    """
    backup = AsyncBackup(sqlcipher_key=sqlcipher_key)
    return await backup.backup_all(output_dir)
