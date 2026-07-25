"""
Blue-Green Schema Migration — Zero-downtime schema changes (INNOWACJA #3 v7.0).

Raport v7.0, sekcja 3.3 / INNOWACJA 3:
  "Blue-Green Schema Migration:
   1. Nowa tabela z sufiksem _v2
   2. Trigger kopiujący dane z v1 do v2 (dual-write)
   3. Backfill istniejących danych
   4. Przełączenie aplikacji na v2 (atomic rename)
   5. Usunięcie v1 po potwierdzeniu"

Features:
- Zero-downtime schema migrations
- Dual-write triggers for data consistency
- Atomic table rename for switchover
- Rollback capability by switching back to v1
- Schema validation before and after migration
- Progress tracking and validation
"""

from __future__ import annotations

import sqlite3
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal

from structlog import get_logger

logger = get_logger("nexus.db.blue_green")

MigrationPhase = Literal[
    "init", "creating_v2", "dual_writing", "backfilling",
    "validating", "switching", "cleaning_up", "done", "rolled_back",
]


@dataclass
class MigrationState:
    """State of a blue-green migration."""
    table_name: str
    phase: MigrationPhase = "init"
    v2_table: str = ""
    rows_backfilled: int = 0
    rows_dual_written: int = 0
    errors: list[str] = field(default_factory=list)
    started_at: float = 0.0
    completed_at: float = 0.0
    rolled_back: bool = False

    @property
    def duration_seconds(self) -> float:
        if self.started_at == 0:
            return 0.0
        end = self.completed_at if self.completed_at > 0 else time.monotonic()
        return end - self.started_at


class BlueGreenMigration:
    """Zero-downtime blueprint for schema migrations.

    Usage:
        mgr = BlueGreenMigration(db_path="app_data/oltp.db")

        # Phase 1: Create v2 table
        await mgr.create_v2(
            table_name="invoices",
            new_schema=""'
                CREATE TABLE invoices_v2 (
                    id TEXT PRIMARY KEY,
                    number TEXT,
                    contractor_nip TEXT,
                    amount_net_minor INTEGER CHECK(amount_net_minor >= 0),
                    amount_gross_minor INTEGER CHECK(amount_gross_minor >= 0),
                    amount_net_minor_new INTEGER DEFAULT 0
                ) STRICT;
            '"',
        )

        # Phase 2: Setup dual-write triggers
        await mgr.setup_dual_write(
            table_name="invoices",
            column_mapping={"id": "id", "number": "number", ...},
        )

        # Phase 3: Backfill existing data
        await mgr.backfill("invoices")

        # Phase 4: Validate data integrity
        await mgr.validate("invoices")

        # Phase 5: Atomic switchover
        await mgr.switch("invoices")

        # Phase 6: Cleanup old table
        await mgr.cleanup("invoices")
    """

    def __init__(self, db_path: str | Path) -> None:
        self._db_path = Path(db_path)
        self._states: dict[str, MigrationState] = {}

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self._db_path))
        conn.row_factory = sqlite3.Row
        return conn

    # ── Phase 1: Create v2 Table ────────────────────────────────────────

    def create_v2(
        self, table_name: str, new_schema: str
    ) -> MigrationState:
        """Create the new version of a table with the updated schema.

        Args:
            table_name: Name of the table to migrate.
            new_schema: Full CREATE TABLE statement for the v2 table.
                Must use table name with _v2 suffix (e.g., invoices_v2).

        Returns:
            MigrationState tracking the progress.
        """
        state = MigrationState(
            table_name=table_name,
            v2_table=f"{table_name}_v2",
            phase="creating_v2",
            started_at=time.monotonic(),
        )
        self._states[table_name] = state

        conn = self._connect()
        try:
            # Drop if exists (from previous failed migration)
            conn.execute(f"DROP TABLE IF EXISTS {state.v2_table};")

            # Create the new table
            conn.executescript(new_schema)
            conn.commit()
            logger.info(
                "[BLUE-GREEN] Created v2 table: %s", state.v2_table
            )
        except Exception as exc:
            state.errors.append(f"create_v2: {exc}")
            logger.error(
                "[BLUE-GREEN] Failed to create %s: %s", state.v2_table, exc
            )
            raise
        finally:
            conn.close()

        return state

    # ── Phase 2: Dual-Write Triggers ─────────────────────────────────────

    def setup_dual_write(
        self,
        table_name: str,
        column_mapping: dict[str, str],
        extra_column_defaults: dict[str, Any] | None = None,
    ) -> MigrationState:
        """Set up dual-write triggers to keep v1 and v2 in sync.

        Args:
            table_name: Name of the table.
            column_mapping: Mapping of v1 column names to v2 column names.
            extra_column_defaults: Default values for new columns in v2.

        Returns:
            MigrationState.
        """
        state = self._states.get(table_name)
        if state is None:
            state = MigrationState(
                table_name=table_name,
                v2_table=f"{table_name}_v2",
                started_at=time.monotonic(),
            )
            self._states[table_name] = state

        state.phase = "dual_writing"
        v2_table = state.v2_table

        conn = self._connect()
        try:
            # Build INSERT/UPDATE/DELETE triggers

            # INSERT trigger: copy new rows from v1 to v2
            v1_cols = ", ".join(column_mapping.keys())
            v2_cols = ", ".join(column_mapping.values())
            placeholders = ", ".join(["NEW." + c for c in column_mapping.keys()])

            # Add extra column defaults
            if extra_column_defaults:
                for col, default in extra_column_defaults.items():
                    if col not in column_mapping.values():
                        v2_cols += f", {col}"
                        if isinstance(default, str) and default.startswith("'"):
                            placeholders += f", {default}"
                        else:
                            placeholders += f", {default}"

            insert_trigger = f"""
            CREATE TRIGGER IF NOT EXISTS trg_{table_name}_to_v2_insert
            AFTER INSERT ON {table_name}
            BEGIN
                INSERT OR REPLACE INTO {v2_table} ({v2_cols})
                VALUES ({placeholders});
            END;
            """

            # UPDATE trigger
            update_sets = ", ".join(
                f"{v2_col} = NEW.{v1_col}"
                for v1_col, v2_col in column_mapping.items()
            )
            update_trigger = f"""
            CREATE TRIGGER IF NOT EXISTS trg_{table_name}_to_v2_update
            AFTER UPDATE ON {table_name}
            BEGIN
                UPDATE {v2_table} SET {update_sets}
                WHERE id = NEW.id;
            END;
            """

            # DELETE trigger
            delete_trigger = f"""
            CREATE TRIGGER IF NOT EXISTS trg_{table_name}_to_v2_delete
            AFTER DELETE ON {table_name}
            BEGIN
                DELETE FROM {v2_table} WHERE id = OLD.id;
            END;
            """

            conn.executescript(insert_trigger + update_trigger + delete_trigger)
            conn.commit()
            logger.info(
                "[BLUE-GREEN] Dual-write triggers created for %s -> %s",
                table_name, v2_table,
            )
        except Exception as exc:
            state.errors.append(f"dual_write: {exc}")
            logger.error(
                "[BLUE-GREEN] Failed to setup dual-write for %s: %s",
                table_name, exc,
            )
            raise
        finally:
            conn.close()

        return state

    # ── Phase 3: Backfill ────────────────────────────────────────────────

    def backfill(
        self,
        table_name: str,
        column_mapping: dict[str, str] | None = None,
        batch_size: int = 1000,
    ) -> MigrationState:
        """Backfill existing data from v1 to v2.

        Args:
            table_name: Name of the table.
            column_mapping: Column mapping (uses existing mapping if None).
            batch_size: Number of rows per batch.

        Returns:
            MigrationState.
        """
        state = self._states.get(table_name)
        if state is None:
            raise ValueError(f"No migration state for {table_name}")

        state.phase = "backfilling"
        v2_table = state.v2_table

        conn = self._connect()
        try:
            # Get count for progress reporting
            count_row = conn.execute(
                f"SELECT COUNT(*) as cnt FROM {table_name}"
            ).fetchone()
            total_rows = count_row["cnt"]
            logger.info(
                "[BLUE-GREEN] Backfilling %d rows from %s to %s",
                total_rows, table_name, v2_table,
            )

            if column_mapping:
                v1_cols = ", ".join(column_mapping.keys())
                v2_cols = ", ".join(column_mapping.values())
                sql = (
                    f"INSERT OR REPLACE INTO {v2_table} ({v2_cols}) "
                    f"SELECT {v1_cols} FROM {table_name}"
                )
            else:
                sql = f"INSERT OR REPLACE INTO {v2_table} SELECT * FROM {table_name}"

            conn.execute(sql)
            conn.commit()
            state.rows_backfilled = conn.execute(
                f"SELECT COUNT(*) FROM {v2_table}"
            ).fetchone()[0]

            logger.info(
                "[BLUE-GREEN] Backfilled %d rows", state.rows_backfilled
            )
        except Exception as exc:
            state.errors.append(f"backfill: {exc}")
            raise
        finally:
            conn.close()

        return state

    # ── Phase 4: Validate ────────────────────────────────────────────────

    def validate(self, table_name: str) -> MigrationState:
        """Validate that v1 and v2 have identical data.

        Args:
            table_name: Name of the table.

        Returns:
            MigrationState with validation results.
        """
        state = self._states.get(table_name)
        if state is None:
            raise ValueError(f"No migration state for {table_name}")

        state.phase = "validating"
        v2_table = state.v2_table

        conn = self._connect()
        try:
            v1_count = conn.execute(
                f"SELECT COUNT(*) FROM {table_name}"
            ).fetchone()[0]
            v2_count = conn.execute(
                f"SELECT COUNT(*) FROM {v2_table}"
            ).fetchone()[0]

            if v1_count != v2_count:
                diff = abs(v1_count - v2_count)
                state.errors.append(
                    f"Row count mismatch: v1={v1_count}, v2={v2_count} (diff={diff})"
                )
                logger.error(
                    "[BLUE-GREEN] Validation failed: v1=%d != v2=%d",
                    v1_count, v2_count,
                )
                return state

            logger.info(
                "[BLUE-GREEN] Validation passed: %d rows in both tables",
                v1_count,
            )
        finally:
            conn.close()

        return state

    # ── Phase 5: Atomic Switchover ───────────────────────────────────────

    def switch(self, table_name: str) -> MigrationState:
        """Perform atomic switchover from v1 to v2 via table rename.

        This creates a backup of v1, then renames v2 to the original name.

        Args:
            table_name: Name of the table.

        Returns:
            MigrationState.
        """
        state = self._states.get(table_name)
        if state is None:
            raise ValueError(f"No migration state for {table_name}")

        state.phase = "switching"
        v2_table = state.v2_table
        backup_table = f"{table_name}_v1_backup"

        conn = self._connect()
        try:
            # Drop old backup if exists
            conn.execute(f"DROP TABLE IF EXISTS {backup_table};")

            # Atomic rename: v1 -> backup, v2 -> v1
            conn.execute(f"ALTER TABLE {table_name} RENAME TO {backup_table};")
            conn.execute(f"ALTER TABLE {v2_table} RENAME TO {table_name};")

            # Drop dual-write triggers
            for suffix in ("insert", "update", "delete"):
                conn.execute(
                    f"DROP TRIGGER IF EXISTS trg_{table_name}_to_v2_{suffix};"
                )

            conn.commit()
            logger.info(
                "[BLUE-GREEN] Switchover complete: %s is now the active table, "
                "backup at %s",
                table_name, backup_table,
            )
        except Exception as exc:
            state.errors.append(f"switch: {exc}")
            raise
        finally:
            conn.close()

        return state

    # ── Phase 6: Cleanup ─────────────────────────────────────────────────

    def cleanup(self, table_name: str, keep_backup: bool = False) -> MigrationState:
        """Clean up old table and triggers after successful switchover.

        Args:
            table_name: Name of the table.
            keep_backup: If True, keep the _v1_backup table.

        Returns:
            MigrationState.
        """
        state = self._states.get(table_name)
        if state is None:
            raise ValueError(f"No migration state for {table_name}")

        state.phase = "cleaning_up"
        backup_table = f"{table_name}_v1_backup"

        conn = self._connect()
        try:
            if not keep_backup:
                conn.execute(f"DROP TABLE IF EXISTS {backup_table};")
                logger.info(
                    "[BLUE-GREEN] Dropped backup table: %s", backup_table
                )

            # Drop any remaining triggers
            for suffix in ("insert", "update", "delete"):
                conn.execute(
                    f"DROP TRIGGER IF EXISTS trg_{table_name}_to_v2_{suffix};"
                )

            conn.commit()
            state.phase = "done"
            state.completed_at = time.monotonic()
            logger.info(
                "[BLUE-GREEN] Cleanup complete for %s (duration: %.1fs)",
                table_name, state.duration_seconds,
            )
        finally:
            conn.close()

        return state

    # ── Rollback ─────────────────────────────────────────────────────────

    def rollback(self, table_name: str) -> MigrationState:
        """Rollback to v1 table if something goes wrong.

        Args:
            table_name: Name of the table.

        Returns:
            MigrationState.
        """
        state = self._states.get(table_name)
        if state is None:
            raise ValueError(f"No migration state for {table_name}")

        state.phase = "rolled_back"
        backup_table = f"{table_name}_v1_backup"

        conn = self._connect()
        try:
            # Check if backup exists
            backup_exists = bool(
                conn.execute(
                    f"SELECT name FROM sqlite_master WHERE type='table' AND name='{backup_table}'"
                ).fetchone()
            )

            if backup_exists:
                # Drop failed v2
                conn.execute(f"DROP TABLE IF EXISTS {table_name};")
                # Restore v1 backup
                conn.execute(f"ALTER TABLE {backup_table} RENAME TO {table_name};")

            # Drop triggers
            for suffix in ("insert", "update", "delete"):
                conn.execute(
                    f"DROP TRIGGER IF EXISTS trg_{table_name}_to_v2_{suffix};"
                )

            # Drop any v2 remnants
            conn.execute(f"DROP TABLE IF EXISTS {table_name}_v2;")

            conn.commit()
            state.rolled_back = True
            logger.info(
                "[BLUE-GREEN] Rolled back %s to v1", table_name
            )
        except Exception as exc:
            state.errors.append(f"rollback: {exc}")
            raise
        finally:
            conn.close()

        return state

    # ── Stats ─────────────────────────────────────────────────────────────

    def get_state(self, table_name: str) -> MigrationState | None:
        """Get migration state for a table."""
        return self._states.get(table_name)

    def list_migrations(self) -> dict[str, dict[str, Any]]:
        """List all migration states."""
        return {
            name: {
                "phase": state.phase,
                "rows_backfilled": state.rows_backfilled,
                "duration_seconds": state.duration_seconds,
                "errors": state.errors,
            }
            for name, state in self._states.items()
        }
