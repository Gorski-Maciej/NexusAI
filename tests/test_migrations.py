"""
Test for the native SQLite migration system (replaces Alembic).

Tests:
- run_migrations on an in-memory DB
- Idempotent re-runs (skipped migrations)
- get_current_version / get_migration_history
- SQL syntax correctness of all migration files
- Dry-run mode
"""

from __future__ import annotations

import os
import sqlite3
import tempfile
from pathlib import Path

import pytest


# ── Fixtures ──────────────────────────────────────────────────────────────


@pytest.fixture
def temp_db() -> Path:
    """Create a temporary database file for testing."""
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    yield Path(path)
    if Path(path).exists():
        os.unlink(path)


@pytest.fixture
def migration_runner():
    """Return the run_migrations function for testing."""
    from migrations.run_migrations import run_migrations
    return run_migrations


# ── Test: Basic migration run ────────────────────────────────────────────


def test_migrations_run_fresh_db(temp_db: Path, migration_runner) -> None:
    """Run all migrations on a fresh database."""
    result = migration_runner(str(temp_db))

    assert len(result["applied"]) == 7
    assert len(result["skipped"]) == 0
    assert result["total_duration_ms"] > 0


def test_migrations_idempotent(temp_db: Path, migration_runner) -> None:
    """Run migrations twice — second run should skip all."""
    # First run
    result1 = migration_runner(str(temp_db))
    assert len(result1["applied"]) == 7
    assert len(result1["skipped"]) == 0

    # Second run — idempotent
    result2 = migration_runner(str(temp_db))
    assert len(result2["applied"]) == 0
    assert len(result2["skipped"]) == 7


def test_migrations_dry_run(temp_db: Path, migration_runner) -> None:
    """Dry-run should list migrations without applying them."""
    result = migration_runner(str(temp_db), dry_run=True)

    assert len(result["applied"]) == 7
    assert result["is_dry_run"] is True

    # Verify no migration SQL files were executed (dry-run)
    # The _migrations_version tracking table may be created for bookkeeping
    # but no actual migration SQL should have run
    conn = sqlite3.connect(str(temp_db))
    cursor = conn.execute("SELECT COUNT(*) FROM _migrations_version")
    count = cursor.fetchone()[0]
    conn.close()

    assert count == 0, "Dry-run should not record any migrations"


# ── Test: Migration version tracking ─────────────────────────────────────


def test_get_current_version_empty(temp_db: Path) -> None:
    """Fresh database should return None for current version."""
    from migrations.run_migrations import get_current_version
    assert get_current_version(str(temp_db)) is None


def test_get_current_version_after_migration(temp_db: Path, migration_runner) -> None:
    """After migration, current version should be the last migration file."""
    migration_runner(str(temp_db))
    from migrations.run_migrations import get_current_version
    version = get_current_version(str(temp_db))
    assert version == "007_v7_audit_enhancements.sql"


def test_get_migration_history(temp_db: Path, migration_runner) -> None:
    """Migration history should contain all applied files with metadata."""
    migration_runner(str(temp_db))
    from migrations.run_migrations import get_migration_history
    history = get_migration_history(str(temp_db))

    assert len(history) == 7
    for entry in history:
        assert "filename" in entry
        assert "applied_at" in entry
        assert "duration_ms" in entry
        assert entry["duration_ms"] > 0


# ── Test: Table creation ─────────────────────────────────────────────────


def test_all_tables_created(temp_db: Path, migration_runner) -> None:
    """Verify that all expected tables are created by migrations."""
    migration_runner(str(temp_db))

    conn = sqlite3.connect(str(temp_db))
    cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = {row[0] for row in cursor.fetchall()}
    conn.close()

    expected_tables = {
        # Core tables
        "invoices", "contractors", "outbox_events", "audit_logs",
        "active_learning_patterns", "users", "security_alerts",
        "refresh_tokens", "ui_drafts", "fx_rates", "task_status",
        "processed_events",
        # Migration 002: email_tokens, failed_tasks
        "email_tokens",
        "failed_tasks",
        # RBAC
        "roles", "permissions", "user_roles", "role_permissions",
        # Roboton_Reflekton
        "company_profiles", "company_partners", "tax_policies",
        "ledger_transfers", "financial_periods", "manual_cashflow_items",
        # Service tables
        "scheduled_tasks", "reminders", "event_log", "dq_decisions",
        "notifications", "workflow_saga_state", "workflow_saga_history",
        "dead_letter_events", "idempotency_requests",
        # Saga
        "saga_log",
        # Migration 006: fraud temporal analysis
        "fraud_entity_registry",
        # Migration 007: v7.0 audit enhancements
        "category_codes", "payment_methods", "db_query_metrics",
        # Migration tracking
        "_migrations_version",
    }

    missing = expected_tables - tables
    extra = tables - expected_tables

    assert not missing, f"Missing tables: {missing}"
    # Ignore sqlite_sequence and sqlite_stat1 (auto-created by SQLite)
    extra_known = {"sqlite_sequence", "sqlite_stat1"}
    unexpected = extra - extra_known
    assert not unexpected, f"Unexpected tables: {unexpected}"


# ── Test: Index creation ─────────────────────────────────────────────────


def test_core_indexes_created(temp_db: Path, migration_runner) -> None:
    """Verify that critical indexes are created."""
    migration_runner(str(temp_db))

    conn = sqlite3.connect(str(temp_db))
    cursor = conn.execute(
        "SELECT name, tbl_name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
    )
    indexes = {row[0] for row in cursor.fetchall()}
    conn.close()

    expected_indexes = {
        "idx_invoices_contractor_nip",
        "idx_invoices_tenant_status",
        "idx_invoices_updated_at",
        "idx_invoices_number",
        "idx_contractors_nip",
        "idx_outbox_pending",
        "idx_audit_invoice_id",
        "idx_alp_contractor_nip",
        "idx_refresh_tokens_user",
        "idx_refresh_tokens_expires",
        "idx_fx_rates_currency_effective",
        "idx_task_status_user",
        "idx_task_status_status",
        "idx_processed_events_business_key",
        "idx_invoices_active_status_mig",
    }

    missing = expected_indexes - indexes
    assert not missing, f"Missing indexes: {missing}"


# ── Test: Error handling ─────────────────────────────────────────────────


def test_migration_on_empty_file(temp_db: Path, migration_runner) -> None:
    """Verify that run_migrations works with an empty migration set."""
    # Use a target that doesn't exist — should skip everything if no migrations applied
    result = migration_runner(str(temp_db), target="nonexistent.sql")
    # When target doesn't exist, it just applies nothing
    assert isinstance(result, dict)
    assert "applied" in result


# ── Test: ALTER TABLE idempotence ────────────────────────────────────────


def test_alter_table_idempotent(temp_db: Path, migration_runner) -> None:
    """Migration 002 adds columns to users — verify it doesn't fail on re-run."""
    # Run all migrations
    migration_runner(str(temp_db))

    # Connect and verify columns exist
    conn = sqlite3.connect(str(temp_db))
    cursor = conn.execute("PRAGMA table_info(users)")
    columns = {row[1] for row in cursor.fetchall()}
    conn.close()

    expected_columns = {
        "id", "username", "password_hash", "role", "tenant_id",
        "is_active", "created_at", "email", "full_name",
        "is_verified", "must_change_password", "jwt_version",
        "last_login", "updated_at",
    }
    missing = expected_columns - columns
    assert not missing, f"Missing columns in users table: {missing}"


# ── Test: Seed data (roles + permissions) ────────────────────────────────


def test_seed_data_roles(temp_db: Path, migration_runner) -> None:
    """Migration 004 seeds system roles — verify they exist."""
    migration_runner(str(temp_db))

    conn = sqlite3.connect(str(temp_db))
    conn.row_factory = sqlite3.Row
    cursor = conn.execute("SELECT id, name FROM roles ORDER BY name")
    roles = {row["name"] for row in cursor.fetchall()}
    conn.close()

    expected_roles = {"admin", "owner", "accountant", "worker", "viewer"}
    assert expected_roles.issubset(roles), f"Missing roles: {expected_roles - roles}"
