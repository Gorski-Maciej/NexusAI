"""consolidate_service_tables

Revision ID: 0003
Revises: 0002
Create Date: 2026-06-12 22:00:00.000000

Consolidates all SQLite tables from service-level files into the main
application database. Tables that were previously created in separate
.db files (app_data/scheduler.db, app_data/event_log.db, etc.) via raw
``sqlite3`` are now part of the Alembic-managed schema.

Tables created:
- scheduled_tasks          (from services/scheduler.py)
- reminders                (from services/scheduler.py)
- event_log                (from services/event_log.py SQLite fallback)
- decisions                (from services/decision_queue.py)
- notifications            (from services/notification_manager.py)
- workflow_saga_state      (from core/saga.py — already uses main engine)
- workflow_saga_history    (from core/saga.py — already uses main engine)
- dead_letter_events       (from services/outbox_relay.py — already uses main engine)
- idempotency_requests     (from api/services.py — separate sqlite3 file)

DuckDB-only tables are NOT included here (telemetry, analytics_schema,
zpk_schema, fallback_handler, context_enricher, decision_logger, etc.
stay in their respective service files).

Zgodnie z aa3fvcx.txt (Punkt 25): wszystkie DDL przeniesione z serwisów
do prawdziwych migracji Alembic.
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # ── scheduled_tasks (from scheduler.py) ──────────────────────────────
    op.create_table(
        "scheduled_tasks",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("task_type", sa.Text(), nullable=False, server_default="custom"),
        sa.Column("trigger_at", sa.Text(), nullable=False),
        sa.Column("interval_minutes", sa.Integer(), nullable=True),
        sa.Column("callback", sa.Text(), nullable=False, server_default=""),
        sa.Column("params", sa.Text(), nullable=False, server_default="{}"),
        sa.Column("is_active", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("last_run_at", sa.Text(), nullable=True),
        sa.Column("next_run_at", sa.Text(), nullable=True),
        sa.Column("created_at", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_scheduler_next",
        "scheduled_tasks",
        ["next_run_at"],
        postgresql_where=sa.text("is_active = 1"),
        sqlite_where=sa.text("is_active = 1"),
    )

    # ── reminders (from scheduler.py) ────────────────────────────────────
    op.create_table(
        "reminders",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Text(), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("reminder_type", sa.Text(), nullable=False, server_default="custom"),
        sa.Column("remind_at", sa.Text(), nullable=False),
        sa.Column("status", sa.Text(), nullable=False, server_default="active"),
        sa.Column("reference_type", sa.Text(), nullable=True),
        sa.Column("reference_id", sa.Text(), nullable=True),
        sa.Column("notification_id", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_reminders_pending", "reminders", ["status", "remind_at"])

    # ── event_log (from event_log.py SQLite fallback) ────────────────────
    op.create_table(
        "event_log",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("event_type", sa.Text(), nullable=False),
        sa.Column("source", sa.Text(), nullable=False, server_default=""),
        sa.Column("description", sa.Text(), nullable=False, server_default=""),
        sa.Column("user_id", sa.Text(), nullable=True),
        sa.Column("agent_name", sa.Text(), nullable=True),
        sa.Column("metadata", sa.Text(), nullable=False, server_default="{}"),
        sa.Column("severity", sa.Text(), nullable=False, server_default="info"),
        sa.Column("created_at", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_event_log_type", "event_log", ["event_type", "created_at"])
    op.create_index("idx_event_log_source", "event_log", ["source", "created_at"])
    op.create_index("idx_event_log_user", "event_log", ["user_id", "created_at"])
    op.create_index("idx_event_log_severity", "event_log", ["severity", "created_at"])
    op.create_index("idx_event_log_created", "event_log", ["created_at"])

    # ── decisions (from decision_queue.py) ───────────────────────────────
    op.create_table(
        "dq_decisions",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Text(), nullable=False),
        sa.Column("notification_id", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("source_agent", sa.Text(), nullable=False, server_default=""),
        sa.Column("reference_type", sa.Text(), nullable=False, server_default=""),
        sa.Column("reference_id", sa.Text(), nullable=False, server_default=""),
        sa.Column("status", sa.Text(), nullable=False, server_default="pending"),
        sa.Column("priority", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("expires_at", sa.Text(), nullable=True),
        sa.Column("resolved_at", sa.Text(), nullable=True),
        sa.Column("resolution", sa.Text(), nullable=True),
        sa.Column("created_at", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_dq_decisions_user_pending",
        "dq_decisions",
        ["user_id", "status", "priority", "created_at"],
    )
    op.create_index(
        "idx_dq_decisions_expires",
        "dq_decisions",
        ["expires_at"],
        postgresql_where=sa.text("status = 'pending' AND expires_at IS NOT NULL"),
        sqlite_where=sa.text("status = 'pending' AND expires_at IS NOT NULL"),
    )
    op.create_index(
        "idx_dq_decisions_reference", "dq_decisions", ["reference_type", "reference_id"]
    )

    # ── notifications (from notification_manager.py) ─────────────────────
    op.create_table(
        "notifications",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Text(), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("category", sa.Text(), nullable=False, server_default="info"),
        sa.Column("priority", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("source_agent", sa.Text(), nullable=False, server_default=""),
        sa.Column("reference_type", sa.Text(), nullable=True),
        sa.Column("reference_id", sa.Text(), nullable=True),
        sa.Column("is_read", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("requires_action", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("expires_at", sa.Text(), nullable=True),
        sa.Column("created_at", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_notif_user_read", "notifications", ["user_id", "is_read", "created_at"])
    op.create_index("idx_notif_category", "notifications", ["category", "created_at"])
    op.create_index(
        "idx_notif_expires",
        "notifications",
        ["expires_at"],
        postgresql_where=sa.text("expires_at IS NOT NULL"),
        sqlite_where=sa.text("expires_at IS NOT NULL"),
    )

    # ── workflow_saga_state (from core/saga.py) ───────────────────────────
    op.create_table(
        "workflow_saga_state",
        sa.Column("saga_id", sa.Text(), nullable=False),
        sa.Column("current_state", sa.Text(), nullable=False),
        sa.Column("payload_json", sa.Text(), nullable=False, server_default="{}"),
        sa.Column(
            "updated_at", sa.DateTime(), nullable=False, server_default=sa.func.current_timestamp()
        ),
        sa.PrimaryKeyConstraint("saga_id"),
    )

    # ── workflow_saga_history (from core/saga.py) ────────────────────────
    op.create_table(
        "workflow_saga_history",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("saga_id", sa.Text(), nullable=False),
        sa.Column("previous_state", sa.Text(), nullable=True),
        sa.Column("new_state", sa.Text(), nullable=False),
        sa.Column("payload_json", sa.Text(), nullable=False, server_default="{}"),
        sa.Column(
            "transitioned_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.func.current_timestamp(),
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_workflow_saga_history_saga_id",
        "workflow_saga_history",
        ["saga_id", "transitioned_at"],
    )

    # ── dead_letter_events (from services/outbox_relay.py) ────────────────
    op.create_table(
        "dead_letter_events",
        sa.Column("id", sa.Text(), nullable=False),
        sa.Column("event_type", sa.Text(), nullable=False),
        sa.Column("aggregate_id", sa.Text(), nullable=True),
        sa.Column("payload", sa.Text(), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("stack_trace", sa.Text(), nullable=True),
        sa.Column("retry_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "created_at", sa.DateTime(), nullable=True, server_default=sa.func.current_timestamp()
        ),
        sa.Column(
            "dead_at", sa.DateTime(), nullable=True, server_default=sa.func.current_timestamp()
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # ── idempotency_requests (from api/services.py) ──────────────────────
    op.create_table(
        "idempotency_requests",
        sa.Column("idempotency_key", sa.Text(), nullable=False),
        sa.Column("payload_hash", sa.Text(), nullable=False),
        sa.Column("response_json", sa.Text(), nullable=False),
        sa.Column("created_at", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("idempotency_key"),
    )


def downgrade() -> None:
    """Remove all tables created in migration 0003."""
    op.drop_table("idempotency_requests")
    op.drop_table("dead_letter_events")
    op.drop_index("idx_workflow_saga_history_saga_id", table_name="workflow_saga_history")
    op.drop_table("workflow_saga_history")
    op.drop_table("workflow_saga_state")
    op.drop_index("idx_notif_expires", table_name="notifications")
    op.drop_index("idx_notif_category", table_name="notifications")
    op.drop_index("idx_notif_user_read", table_name="notifications")
    op.drop_table("notifications")
    op.drop_index("idx_dq_decisions_reference", table_name="dq_decisions")
    op.drop_index("idx_dq_decisions_expires", table_name="dq_decisions")
    op.drop_index("idx_dq_decisions_user_pending", table_name="dq_decisions")
    op.drop_table("dq_decisions")
    op.drop_index("idx_event_log_created", table_name="event_log")
    op.drop_index("idx_event_log_severity", table_name="event_log")
    op.drop_index("idx_event_log_user", table_name="event_log")
    op.drop_index("idx_event_log_source", table_name="event_log")
    op.drop_index("idx_event_log_type", table_name="event_log")
    op.drop_table("event_log")
    op.drop_index("idx_reminders_pending", table_name="reminders")
    op.drop_table("reminders")
    op.drop_index("idx_scheduler_next", table_name="scheduled_tasks")
    op.drop_table("scheduled_tasks")
