"""add_missing_schema_tables

Revision ID: 0002
Revises: 0001
Create Date: 2026-06-12 21:00:00.000000

Adds tables from api/state.py _ensure_schema_tables that were not
included in migration 0001_initial_schema:

Tables created:
- email_tokens
- failed_tasks
- roles
- permissions
- user_roles
- role_permissions

Also adds missing columns/indexes on existing tables (users, audit_logs)
that _ensure_schema_tables created but 0001 did not.

Zgodnie z aa3fvcx.txt (Punkt 25): DDL przeniesione z _ensure_schema_tables
do prawdziwych migracji Alembic.
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # ── email_tokens ──────────────────────────────────────────────────
    op.create_table(
        "email_tokens",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("token", sa.String(), nullable=False),
        sa.Column("purpose", sa.String(), nullable=False, server_default="confirm"),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("used", sa.Boolean(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token"),
    )
    op.create_index("idx_email_tokens_token", "email_tokens", ["token"])
    op.create_index("idx_email_tokens_user", "email_tokens", ["user_id"])

    # ── failed_tasks (DLQ) ────────────────────────────────────────────
    op.create_table(
        "failed_tasks",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("task_name", sa.String(), nullable=False),
        sa.Column("task_id", sa.String(), nullable=True),
        sa.Column("payload", sa.Text(), nullable=False, server_default="{}"),
        sa.Column("error_type", sa.String(), nullable=False),
        sa.Column("error_message", sa.Text(), nullable=False),
        sa.Column("stack_trace", sa.Text(), nullable=True),
        sa.Column("retry_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("max_retries", sa.Integer(), nullable=False, server_default="3"),
        sa.Column("resolved", sa.Boolean(), nullable=False, server_default="0"),
        sa.Column("resolved_at", sa.DateTime(), nullable=True),
        sa.Column("resolved_by", sa.String(), nullable=True),
        sa.Column("resolution_note", sa.Text(), nullable=True),
        sa.Column("failed_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_failed_tasks_resolved", "failed_tasks", ["resolved"])
    op.create_index("idx_failed_tasks_task_name", "failed_tasks", ["task_name"])

    # ── roles (RBAC) ──────────────────────────────────────────────────
    op.create_table(
        "roles",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("is_system", sa.Boolean(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
    )

    # ── permissions (RBAC) ────────────────────────────────────────────
    op.create_table(
        "permissions",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("codename", sa.String(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("resource", sa.String(), nullable=False),
        sa.Column("action", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("codename"),
    )
    op.create_index("idx_permissions_codename", "permissions", ["codename"])

    # ── user_roles (RBAC) ─────────────────────────────────────────────
    op.create_table(
        "user_roles",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("role_id", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_user_roles_user", "user_roles", ["user_id"])
    op.create_index("idx_user_roles_role", "user_roles", ["role_id"])

    # ── role_permissions (RBAC) ───────────────────────────────────────
    op.create_table(
        "role_permissions",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("role_id", sa.String(), nullable=False),
        sa.Column("permission_id", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["permission_id"], ["permissions.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("role_id", "permission_id"),
    )
    op.create_index("idx_role_permissions_role", "role_permissions", ["role_id"])

    # ── Missing columns on users table ────────────────────────────────
    # Migration 0001 created users with limited columns. _ensure_schema_tables
    # also creates these columns. We add them idempotently.
    with op.batch_alter_table("users") as batch_op:
        batch_op.add_column(sa.Column("email", sa.String(), nullable=True))
        batch_op.add_column(sa.Column("full_name", sa.String(), nullable=True))
        batch_op.add_column(
            sa.Column("is_verified", sa.Boolean(), nullable=False, server_default="0")
        )
        batch_op.add_column(
            sa.Column("must_change_password", sa.Boolean(), nullable=False, server_default="0")
        )
        batch_op.add_column(
            sa.Column("jwt_version", sa.Integer(), nullable=False, server_default="1")
        )
        batch_op.add_column(sa.Column("last_login", sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column("updated_at", sa.DateTime(), nullable=True))

    # ── Missing index on audit_logs ───────────────────────────────────
    op.create_index("idx_audit_logs_action", "audit_logs", ["action"])


def downgrade() -> None:
    """Remove all tables and columns created in migration 0002."""
    # Remove added columns from users (reverse order)
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_column("updated_at")
        batch_op.drop_column("last_login")
        batch_op.drop_column("jwt_version")
        batch_op.drop_column("must_change_password")
        batch_op.drop_column("is_verified")
        batch_op.drop_column("full_name")
        batch_op.drop_column("email")

    # Drop index on audit_logs
    op.drop_index("idx_audit_logs_action", table_name="audit_logs")

    # Drop RBAC tables
    op.drop_index("idx_role_permissions_role", table_name="role_permissions")
    op.drop_table("role_permissions")
    op.drop_index("idx_user_roles_role", table_name="user_roles")
    op.drop_index("idx_user_roles_user", table_name="user_roles")
    op.drop_table("user_roles")
    op.drop_index("idx_permissions_codename", table_name="permissions")
    op.drop_table("permissions")
    op.drop_table("roles")

    # Drop failed_tasks
    op.drop_index("idx_failed_tasks_task_name", table_name="failed_tasks")
    op.drop_index("idx_failed_tasks_resolved", table_name="failed_tasks")
    op.drop_table("failed_tasks")

    # Drop email_tokens
    op.drop_index("idx_email_tokens_user", table_name="email_tokens")
    op.drop_index("idx_email_tokens_token", table_name="email_tokens")
    op.drop_table("email_tokens")
