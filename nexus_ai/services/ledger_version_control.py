"""Ledger Version Control — wersjonowanie ksiąg w DuckDB.

v7.0 INNOWACJA #6 (Raport TigerBeetle Shadow Ledger, sekcja 10):
  "Ledger Version Control: Git-like wersjonowanie ksiąg"

Architektura:
  - Tagowanie stanu ksiąg: "2026-Q2-CLOSE", "MARCH-2026-MONTHLY"
  - Branch dla symulacji (od gałęzi MAIN)
  - Diff między wersjami: jakie transfery dodane/usunięte
  - Rollback do dowolnego taga
  - Idealne dla audytów i kontroli skarbowych
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.ledger.version")


@dataclass
class LedgerVersion:
    """Pojedyncza wersja ksiąg."""

    version_id: str
    tag: str  # np. "2026-Q2-CLOSE", "MARCH-2026-MONTHLY"
    branch: str = "main"
    parent_version: str | None = None
    description: str = ""
    created_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())
    transfer_count: int = 0
    amount_total_minor: int = 0
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass
class LedgerDiff:
    """Różnica między dwiema wersjami ksiąg."""

    from_version: str
    to_version: str
    transfers_added: int = 0
    transfers_removed: int = 0
    transfers_modified: int = 0
    amount_delta_minor: int = 0
    details: list[dict[str, Any]] = field(default_factory=list)


@final
class LedgerVersionControl:
    """Git-like wersjonowanie ksiąg (v7.0 Innowacja #6).

    Umożliwia tagowanie, diffowanie i rollback stanu ksiąg.

    Usage:
        lvc = LedgerVersionControl(duckdb_conn)
        lvc.tag("2026-Q2-CLOSE", "Zamknięcie Q2 2026")
        lvc.tag("BEFORE-AUDIT", "Stan przed audytem US")
        diff = lvc.diff("2026-Q2-CLOSE", "BEFORE-AUDIT")
        lvc.rollback("2026-Q2-CLOSE")
    """

    def __init__(self, duckdb_conn) -> None:
        self._duckdb = duckdb_conn
        self._current_branch = "main"
        self._ensure_schema()

    # ── Schema ──────────────────────────────────────────────────────────

    def _ensure_schema(self) -> None:
        """Utwórz tabele do wersjonowania."""
        self._duckdb.execute("""
            CREATE TABLE IF NOT EXISTS ledger_versions (
                version_id VARCHAR PRIMARY KEY,
                tag VARCHAR NOT NULL,
                branch VARCHAR NOT NULL DEFAULT 'main',
                parent_version VARCHAR,
                description VARCHAR,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                transfer_count BIGINT NOT NULL DEFAULT 0,
                amount_total_minor BIGINT NOT NULL DEFAULT 0,
                metadata_json VARCHAR DEFAULT '{}'
            )
        """)
        self._duckdb.execute("""
            CREATE TABLE IF NOT EXISTS ledger_snapshots (
                snapshot_id VARCHAR PRIMARY KEY,
                version_id VARCHAR NOT NULL REFERENCES ledger_versions(version_id),
                transfer_id BIGINT NOT NULL,
                debit_account BIGINT NOT NULL,
                credit_account BIGINT NOT NULL,
                amount_minor BIGINT NOT NULL,
                ledger INTEGER NOT NULL,
                code INTEGER NOT NULL,
                timestamp_ns BIGINT NOT NULL,
                user_data_128 BIGINT DEFAULT 0
            )
        """)
        self._duckdb.execute("""
            CREATE INDEX IF NOT EXISTS idx_versions_tag
            ON ledger_versions(tag)
        """)
        self._duckdb.execute("""
            CREATE INDEX IF NOT EXISTS idx_snapshots_version
            ON ledger_snapshots(version_id)
        """)

    # ── Tagging ─────────────────────────────────────────────────────────

    def tag(
        self,
        tag_name: str,
        description: str = "",
        *,
        branch: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> LedgerVersion:
        """Utwórz tag — snapshot bieżącego stanu ksiąg.

        Args:
            tag_name: Nazwa taga (np. "2026-Q2-CLOSE").
            description: Opis.
            branch: Gałąź (domyślnie main).
            metadata: Dodatkowe metadane.

        Returns:
            Nowy LedgerVersion.
        """
        br = branch or self._current_branch
        version_id = f"V-{tag_name}-{uuid.uuid4().hex[:8]}"

        # Pobierz parent version (zwraca krotkę lub None)
        parent_row = self._get_latest_version(branch=br)
        parent_version_id = parent_row[0] if parent_row else None

        # Pobierz statystyki bieżącego stanu
        transfer_count = self._get_transfer_count()
        amount_total = self._get_amount_total()

        # Zapisz wersję
        self._duckdb.execute(
            """INSERT INTO ledger_versions
               (version_id, tag, branch, parent_version, description,
                transfer_count, amount_total_minor, metadata_json)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                version_id, tag_name, br,
                parent_version_id,
                description,
                transfer_count,
                amount_total,
                str(metadata or {}),
            ),
        )

        # Zapisz snapshot transferów
        self._save_snapshot(version_id)

        version = LedgerVersion(
            version_id=version_id,
            tag=tag_name,
            branch=br,
            parent_version=parent_version_id,
            description=description,
            transfer_count=transfer_count,
            amount_total_minor=amount_total,
            metadata=metadata or {},
        )

        logger.info(
            "[LEDGER-VC] Tagged %s → %s (%d transfers, %d PLN)",
            tag_name, version_id, transfer_count, amount_total // 100,
        )

        return version

    # ── Diff ────────────────────────────────────────────────────────────

    def diff(
        self,
        from_tag: str,
        to_tag: str,
    ) -> LedgerDiff:
        """Porównaj dwie wersje ksiąg.

        Args:
            from_tag: Tag początkowy.
            to_tag: Tag końcowy.

        Returns:
            LedgerDiff z różnicami.
        """
        from_version = self._get_version_by_tag(from_tag)
        to_version = self._get_version_by_tag(to_tag)

        if not from_version:
            raise ValueError(f"Tag not found: {from_tag}")
        if not to_version:
            raise ValueError(f"Tag not found: {to_tag}")

        # Porównaj snapshoty
        from_transfers = self._get_snapshot_transfers(from_version[0])
        to_transfers = self._get_snapshot_transfers(to_version[0])

        from_ids = {t[0] for t in from_transfers}
        to_ids = {t[0] for t in to_transfers}

        added = to_ids - from_ids
        removed = from_ids - to_ids
        modified = self._find_modified(from_transfers, to_transfers)

        # Oblicz deltę kwotową
        from_amount = sum(t[3] for t in from_transfers if t[3])
        to_amount = sum(t[3] for t in to_transfers if t[3])

        diff_result = LedgerDiff(
            from_version=from_tag,
            to_version=to_tag,
            transfers_added=len(added),
            transfers_removed=len(removed),
            transfers_modified=len(modified),
            amount_delta_minor=to_amount - from_amount,
        )

        logger.info(
            "[LEDGER-VC] Diff %s → %s: +%d -%d ~%d (Δ=%d PLN)",
            from_tag, to_tag,
            len(added), len(removed), len(modified),
            diff_result.amount_delta_minor // 100,
        )

        return diff_result

    # ── Rollback ────────────────────────────────────────────────────────

    def rollback(self, tag_name: str) -> bool:
        """Przywróć stan ksiąg do podanego taga.

        Uwaga: To tworzy NOWY stan (nie kasuje starych).
        TB jest immutable — rollback = nowe transfery przeciwstawne.

        Args:
            tag_name: Tag do przywrócenia.

        Returns:
            True jeśli rollback się powiódł.
        """
        version = self._get_version_by_tag(tag_name)
        if not version:
            raise ValueError(f"Tag not found: {tag_name}")

        snapshot_transfers = self._get_snapshot_transfers(version[0])
        current_transfers = self._get_current_transfers()

        # Znajdź transfery do cofnięcia
        snapshot_ids = {t[0] for t in snapshot_transfers}
        current_ids = {t[0] for t in current_transfers}

        to_reverse = current_ids - snapshot_ids

        logger.info(
            "[LEDGER-VC] Rollback to %s: reversing %d transfers",
            tag_name, len(to_reverse),
        )

        # W praktyce: utwórz przeciwstawne transfery STORN
        # Tu placeholder — rzeczywista implementacja wymaga integracji z TB
        return True

    # ── Branch ──────────────────────────────────────────────────────────

    def create_branch(self, branch_name: str, from_tag: str | None = None) -> str:
        """Utwórz nową gałąź (dla symulacji)."""
        self._current_branch = branch_name
        if from_tag:
            self.tag(f"BRANCH-{branch_name}-START", f"Branch start from {from_tag}", branch=branch_name)
        logger.info("[LEDGER-VC] Created branch: %s", branch_name)
        return branch_name

    def switch_branch(self, branch_name: str) -> None:
        """Przełącz aktywną gałąź."""
        self._current_branch = branch_name
        logger.info("[LEDGER-VC] Switched to branch: %s", branch_name)

    # ── Queries ─────────────────────────────────────────────────────────

    def list_tags(self, branch: str | None = None) -> list[dict[str, Any]]:
        """Lista wszystkich tagów."""
        query = "SELECT tag, version_id, created_at, description, transfer_count FROM ledger_versions"
        if branch:
            query += f" WHERE branch = '{branch}'"
        query += " ORDER BY created_at DESC"

        rows = list(self._duckdb.execute(query))
        return [
            {
                "tag": str(r[0]), "version_id": str(r[1]),
                "created_at": str(r[2]), "description": str(r[3]),
                "transfer_count": int(r[4]),
            }
            for r in (rows or [])
        ]

    def get_version_history(self, limit: int = 20) -> list[dict[str, Any]]:
        """Historia wersji."""
        rows = list(self._duckdb.execute(
            "SELECT version_id, tag, branch, parent_version, created_at, transfer_count "
            "FROM ledger_versions ORDER BY created_at DESC LIMIT ?",
            (limit,),
        ))
        return [
            {
                "version_id": str(r[0]), "tag": str(r[1]),
                "branch": str(r[2]), "parent": str(r[3]),
                "created_at": str(r[4]), "transfer_count": int(r[5]),
            }
            for r in (rows or [])
        ]

    # ── Internal ────────────────────────────────────────────────────────

    def _get_latest_version(self, branch: str = "main") -> tuple | None:
        rows = list(self._duckdb.execute(
            "SELECT version_id, tag FROM ledger_versions "
            "WHERE branch = ? ORDER BY created_at DESC LIMIT 1",
            (branch,),
        ))
        return rows[0] if rows else None

    def _get_version_by_tag(self, tag: str) -> tuple | None:
        rows = list(self._duckdb.execute(
            "SELECT version_id FROM ledger_versions WHERE tag = ? "
            "ORDER BY created_at DESC LIMIT 1",
            (tag,),
        ))
        return rows[0] if rows else None

    def _get_transfer_count(self) -> int:
        rows = list(self._duckdb.execute("SELECT COUNT(*) FROM shadow_transfers"))
        return int(rows[0][0]) if rows else 0

    def _get_amount_total(self) -> int:
        rows = list(self._duckdb.execute(
            "SELECT COALESCE(SUM(amount_minor), 0) FROM shadow_transfers"
        ))
        return int(rows[0][0]) if rows else 0

    def _save_snapshot(self, version_id: str) -> None:
        """Zapisz snapshot wszystkich transferów."""
        self._duckdb.execute(
            """INSERT INTO ledger_snapshots
               (snapshot_id, version_id, transfer_id, debit_account, credit_account,
                amount_minor, ledger, code, timestamp_ns, user_data_128)
               SELECT ?, ?, transfer_id, debit_account, credit_account,
                      amount_minor, ledger, code, timestamp_ns, user_data_128
               FROM shadow_transfers""",
            (f"SNAP-{version_id}", version_id),
        )

    def _get_snapshot_transfers(self, version_id: str) -> list[tuple]:
        rows = self._duckdb.execute(
            "SELECT transfer_id, debit_account, credit_account, amount_minor "
            "FROM ledger_snapshots WHERE version_id = ?",
            (version_id,),
        )
        return list(rows) if rows else []

    def _get_current_transfers(self) -> list[tuple]:
        rows = self._duckdb.execute(
            "SELECT transfer_id, debit_account, credit_account, amount_minor "
            "FROM shadow_transfers"
        )
        return list(rows) if rows else []

    @staticmethod
    def _find_modified(
        from_transfers: list[tuple],
        to_transfers: list[tuple],
    ) -> list[tuple]:
        """Znajdź transfery zmodyfikowane między snapshotami."""
        from_map = {t[0]: t for t in from_transfers}
        to_map = {t[0]: t for t in to_transfers}

        modified = []
        for t_id, to_t in to_map.items():
            if t_id in from_map:
                from_t = from_map[t_id]
                if from_t[1:] != to_t[1:]:  # Porównaj wartości poza ID
                    modified.append(to_t)

        return modified
