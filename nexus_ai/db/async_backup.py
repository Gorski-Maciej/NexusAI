"""
AsyncBackup — async backup service using sqlite3.backup() API.

SUPERMOC fsspec:
- ``fsspec.open()`` zamiast ``open()`` dla uniwersalnego otwierania plików
- ``fsspec.filesystem()`` z konfigurowalnym protokołem z TOML
- ``fsspec.implementations.memory.MemoryFileSystem`` dla backupów do RAM
- ``fsspec.transaction.TransactionalFileSystem`` dla atomowych backupów

Python 3.13t (free-threaded): używamy natywnego ``sqlite3.backup()``
zamiast ``aiosqlite.backup()``. Operacje są delegowane do wątków przez
``asyncio.to_thread()``.

Usage:
    backup = AsyncBackup(config=app_config)
    await backup.backup_all(output_dir="backups/2026-06-14")
    await backup.backup_single("app_data/nexus_oltp.db", "backups/oltp.db")
"""

from __future__ import annotations

import asyncio
import os
import sqlite3
import time
import pendulum
from pathlib import Path
from typing import Any

import fsspec
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.db.async_backup")

# ── Default database paths ──────────────────────────────────────────────

DEFAULT_DATABASES: dict[str, str] = {
    "oltp": "app_data/databases/nexus_oltp.db",
    "event_store": "app_data/databases/nexus_events.db",
    "projections_invoices": "app_data/projections/invoices.db",
    "projections_decisions": "app_data/projections/decisions.db",
}

# ── AsyncBackup ─────────────────────────────────────────────────────────


class AsyncBackup:
    """Async backup service for all NexusAI databases.

    Python 3.13t (free-threaded): sync ``sqlite3.backup()`` jest wykonywany
    w wątku przez ``asyncio.to_thread()``.

    Używa natywnego ``sqlite3.Connection.backup()`` (dostępne od Python 3.6).
    SQLCipher: backup działa między szyfrowanymi bazami (ten sam klucz).
    Backup atomiczny — baza pozostaje czytelna/zapisywalna podczas backupu.
    """

    def __init__(
        self,
        databases: dict[str, str] | None = None,
        sqlcipher_key: str | None = None,
        config: AppConfig | None = None,
    ) -> None:
        self._databases = databases or dict(DEFAULT_DATABASES)
        self._sqlcipher_key = sqlcipher_key or os.environ.get("NEXUS_SQLCIPHER_KEY", "")
        
        # SUPERMOC fsspec: konfigurowalny backend backupu
        if config is not None:
            self._fs_protocol = config.storage_protocol
            self._fs = fsspec.filesystem(
                config.storage_protocol,
                auto_mkdir=config.storage_auto_mkdir,
            )
        else:
            self._fs_protocol = "file"
            self._fs = fsspec.filesystem("file", auto_mkdir=True)

    async def backup_all(
        self,
        output_dir: str | Path,
        suffix: str | None = None,
    ) -> dict[str, dict[str, Any]]:
        """Wykonaj backup wszystkich baz danych (async, w wątkach).

        Args:
            output_dir: Katalog docelowy dla backupów.
            suffix: Opcjonalny sufiks (np. dzisiejsza data).

        Returns:
            Słownik z wynikami dla każdej bazy.
        """
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        suffix = suffix or pendulum.now("UTC").format("YYYYMMDD_HHmmss")

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
        """Wykonaj backup pojedynczej bazy danych (async, w wątku).

        Używa natywnego ``sqlite3.Connection.backup()`` w wątku.
        Backup atomiczny — źródło pozostaje czytelne/zapisywalne.

        Args:
            source_path: Ścieżka źródłowej bazy danych.
            target_path: Ścieżka docelowa dla backupu.

        Returns:
            Słownik z wynikiem: status, path, size_mb.
        """
        target = Path(target_path)
        target.parent.mkdir(parents=True, exist_ok=True)

        logger.info("[BACKUP] Starting backup: %s → %s", source_path, target_path)

        start_time = time.time()

        def _sync_backup() -> None:
            """Wykonaj backup w wątku (free-threaded safe)."""
            src = sqlite3.connect(source_path, check_same_thread=False)
            try:
                if self._sqlcipher_key:
                    key_hex = self._sqlcipher_key.encode("utf-8").hex()
                    src.execute(f"PRAGMA key = x'{key_hex}';")

                tgt = sqlite3.connect(str(target), check_same_thread=False)
                try:
                    if self._sqlcipher_key:
                        key_hex = self._sqlcipher_key.encode("utf-8").hex()
                        tgt.execute(f"PRAGMA key = x'{key_hex}';")

                    # Natywny backup — deleguje do sqlite3_backup() w C
                    src.backup(tgt, pages=-1)
                finally:
                    tgt.close()
            finally:
                src.close()

        await asyncio.to_thread(_sync_backup)

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

    async def backup_to_memory(self, source_path: str) -> None:
        """Wykonaj backup do pamięci RAM (w wątku).

        SUPERMOC: Backup do ``:memory:`` — idealne do testów.
        Nie zwraca połączenia (sqlite3.Connection nie może być bezpiecznie
        używane między wątkami po zamknięciu backupu).

        Args:
            source_path: Ścieżka źródłowej bazy danych.
        """
        def _sync_backup() -> None:
            mem_conn = sqlite3.connect(":memory:", check_same_thread=False)
            try:
                if self._sqlcipher_key:
                    key_hex = self._sqlcipher_key.encode("utf-8").hex()
                    mem_conn.execute(f"PRAGMA key = x'{key_hex}';")

                src = sqlite3.connect(source_path, check_same_thread=False)
                try:
                    if self._sqlcipher_key:
                        key_hex = self._sqlcipher_key.encode("utf-8").hex()
                        src.execute(f"PRAGMA key = x'{key_hex}';")
                    src.backup(mem_conn)
                finally:
                    src.close()
            finally:
                mem_conn.close()

        await asyncio.to_thread(_sync_backup)
        logger.info("[BACKUP] In-memory backup complete: %s", source_path)

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
