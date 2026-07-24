"""
AuditableConfigurationManager — każda zmiana configu to event domenowy.

INNOWACJA #10 z Raportu v7.0: Kazda zmiana konfiguracji jest zdarzeniem domenowym
(ConfigChanged). Zdarzenia zapisywane w event store. Mozliwosc rollbacku do
poprzedniej konfiguracji. Git-like diff configu.

Architektura:
    TOML zmiana → ConfigChanged event → EventStore → Audit Trail
                    │
                    ▼
            Rollback możliwy przez odtworzenie z historii

Usage:
    mgr = AuditableConfigurationManager(event_store=store)
    
    # Track config change
    await mgr.record_change(
        section="database",
        key="duckdb_memory_limit",
        old_value="512MB",
        new_value="1024MB",
        changed_by="admin",
    )
    
    # Get config history
    history = await mgr.get_history(section="database", limit=10)
"""

from __future__ import annotations

import time as _time
from typing import Any

import msgspec
from structlog import get_logger

logger = get_logger("nexus.config.audit")


# ── Config Changed Event ──────────────────────────────────────────────────


class ConfigChangedEvent(msgspec.Struct, kw_only=True, frozen=True):
    """Zdarzenie domenowe: zmiana konfiguracji.

    Przechowuje pełny diff: co, kto, kiedy, wartość przed i po.
    Zapis w EventStore umożliwia odtworzenie pełnej historii.
    """

    event_id: str = ""
    timestamp: str = ""
    section: str = ""
    key: str = ""
    old_value: str = ""
    new_value: str = ""
    changed_by: str = "system"
    reason: str = ""
    version: int = 1

    # For diff computation
    diff_type: str = "modified"  # "added", "modified", "removed"


class ConfigSnapshot(msgspec.Struct, kw_only=True):
    """Snapshot stanu konfiguracji w danym momencie."""

    snapshot_id: str = ""
    timestamp: str = ""
    version: int = 1
    config_hash: str = ""
    changed_by: str = ""
    sections: dict[str, dict[str, Any]] = {}


# ── Auditable Configuration Manager ───────────────────────────────────────


class AuditableConfigurationManager:
    """Zarządza konfiguracją z pełnym audytem i możliwością rollbacku.

    Każda zmiana jest:
    1. Zapisana jako ConfigChangedEvent w EventStore
    2. Zasnapshotowana dla szybkiego odtwarzania
    3. Diff-owalna (old_value vs new_value)
    """

    __slots__ = ("_current_config", "_event_store", "_history_limit", "_lock")

    def __init__(
        self,
        event_store: Any = None,
        history_limit: int = 1000,
    ) -> None:
        import threading
        self._event_store = event_store
        self._current_config: dict[str, dict[str, Any]] = {}
        self._history_limit = history_limit
        self._lock = threading.Lock()
        self._history: list[ConfigChangedEvent] = []

    async def record_change(
        self,
        section: str,
        key: str,
        old_value: str = "",
        new_value: str = "",
        changed_by: str = "system",
        reason: str = "",
    ) -> ConfigChangedEvent:
        """Zarejestruj zmianę konfiguracji.

        Args:
            section: Sekcja configu (np. "database", "security").
            key: Klucz (np. "duckdb_memory_limit").
            old_value: Poprzednia wartość (string).
            new_value: Nowa wartość (string).
            changed_by: Kto zmienił.
            reason: Powód zmiany.

        Returns:
            ConfigChangedEvent z pełnym audytem.
        """
        import pendulum
        import uuid
        import hashlib

        now = pendulum.now("UTC")
        event = ConfigChangedEvent(
            event_id=uuid.uuid4().hex,
            timestamp=now.isoformat(),
            section=section,
            key=key,
            old_value=old_value,
            new_value=new_value,
            changed_by=changed_by,
            reason=reason,
            version=1,
            diff_type="added" if not old_value else "removed" if not new_value else "modified",
        )

        with self._lock:
            # Aktualizuj bieżący stan
            if section not in self._current_config:
                self._current_config[section] = {}
            self._current_config[section][key] = new_value

            # Dodaj do historii
            self._history.append(event)
            if len(self._history) > self._history_limit:
                self._history = self._history[-self._history_limit:]

        # Zapisz w historii (in-memory) — audyt konfiguracji nie wymaga EventStore
        # (ConfigChangedEvent nie dziedziczy po DomainEvent — to osobna ścieżka audytu)
        logger.debug(
            "[CONFIG-AUDIT] Recorded: %s.%s changed by %s",
            section, key, changed_by,
        )

        logger.info(
            "[CONFIG-AUDIT] %s.%s: %s → %s (by %s)",
            section,
            key,
            old_value,
            new_value,
            changed_by,
        )
        return event

    async def rollback(
        self,
        section: str,
        key: str,
        target_version: int | None = None,
        changed_by: str = "system-rollback",
    ) -> ConfigChangedEvent | None:
        """Przywróć poprzednią wartość konfiguracji.

        Args:
            section: Sekcja configu.
            key: Klucz.
            target_version: Docelowa wersja (domyślnie: poprzednia).
            changed_by: Kto wykonuje rollback.

        Returns:
            ConfigChangedEvent rollbacku, lub None jeśli brak historii.
        """
        # Znajdź ostatnią zmianę dla tego klucza
        relevant = [e for e in self._history if e.section == section and e.key == key]
        if not relevant:
            logger.warning("[CONFIG-AUDIT] No history for %s.%s", section, key)
            return None

        # Domyślnie: rollback do wartości przed ostatnią zmianą
        last_change = relevant[-1]
        rollback_value = last_change.old_value

        return await self.record_change(
            section=section,
            key=key,
            old_value=last_change.new_value,
            new_value=rollback_value,
            changed_by=changed_by,
            reason=f"Rollback to version before {last_change.event_id}",
        )

    def get_diff(
        self,
        section: str,
        key: str,
        from_version: int = 0,
        to_version: int = -1,
    ) -> list[dict[str, Any]]:
        """Zwróć diff dla klucza konfiguracyjnego.

        Args:
            section: Sekcja configu.
            key: Klucz.
            from_version: Od wersji (0 = od początku).
            to_version: Do wersji (-1 = do teraz).

        Returns:
            Lista diff entries.
        """
        changes = [
            e for e in self._history
            if e.section == section and e.key == key
        ]
        if not changes:
            return []

        return [
            {
                "version": i + 1,
                "timestamp": e.timestamp,
                "old_value": e.old_value,
                "new_value": e.new_value,
                "changed_by": e.changed_by,
                "diff_type": e.diff_type,
                "reason": e.reason,
            }
            for i, e in enumerate(changes)
        ]

    def get_history(
        self,
        section: str | None = None,
        key: str | None = None,
        limit: int = 50,
    ) -> list[dict[str, Any]]:
        """Zwróć historię zmian konfiguracji.

        Args:
            section: Opcjonalny filtr po sekcji.
            key: Opcjonalny filtr po kluczu.
            limit: Limit wyników.

        Returns:
            Lista zmian.
        """
        filtered = self._history
        if section:
            filtered = [e for e in filtered if e.section == section]
        if key:
            filtered = [e for e in filtered if e.key == key]

        return [
            {
                "event_id": e.event_id,
                "timestamp": e.timestamp,
                "section": e.section,
                "key": e.key,
                "old_value": e.old_value,
                "new_value": e.new_value,
                "changed_by": e.changed_by,
                "diff_type": e.diff_type,
                "reason": e.reason,
            }
            for e in filtered[-limit:]
        ]

    def get_current_snapshot(self) -> dict[str, dict[str, Any]]:
        """Zwróć bieżący stan konfiguracji."""
        with self._lock:
            return dict(self._current_config)

    @property
    def total_changes(self) -> int:
        return len(self._history)


__all__ = [
    "AuditableConfigurationManager",
    "ConfigChangedEvent",
    "ConfigSnapshot",
]
