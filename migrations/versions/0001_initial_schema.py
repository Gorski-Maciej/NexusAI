"""initial_schema

Revision ID: 0001
Revises:
Create Date: 2026-05-30 18:00:00.000000

NexusAI initial database schema covering all core models.

Tables created:
- invoices
- contractors
- outbox_events
- audit_logs
- active_learning_patterns
- users
- security_alerts
- refresh_tokens
- ui_drafts
- fx_rates
- task_status
- processed_events
- company_profiles
- company_partners
- tax_policies
- ledger_transfers
- financial_periods
- manual_cashflow_items
"""

from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import sqlite

# revision identifiers, used by Alembic.
revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Core OLTP tables ──────────────────────────────────────────────────

    # invoices
    op.create_table(
        "invoices",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("number", sa.String(), nullable=True),
        sa.Column("amount_net", sa.DECIMAL(12, 2), nullable=False, server_default="0.0"),
        sa.Column("amount_gross", sa.DECIMAL(12, 2), nullable=False, server_default="0.0"),
        sa.Column("currency", sa.String(3), nullable=False, server_default="PLN"),
        sa.Column("issue_date", sa.Date(), nullable=True),
        sa.Column("contractor_nip", sa.String(10), nullable=True),
        sa.Column("contractor_id", sa.String(), nullable=True),
        sa.Column("status", sa.String(), nullable=False, server_default="NEW"),
        sa.Column("file_path", sa.String(), nullable=False),
        sa.Column("tenant_id", sa.String(), nullable=False, server_default="default"),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.Column("created_by", sa.String(), nullable=False, server_default="worker:taskiq"),
        sa.Column("updated_by", sa.String(), nullable=False, server_default="worker:taskiq"),
        sa.Column("deletion_date", sa.DateTime(), nullable=True),
        sa.Column("retention_period_years", sa.Integer(), nullable=False, server_default="5"),
        sa.Column("version_id", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default="0"),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("retry_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("processing_status", sa.String(), nullable=True),
        sa.ForeignKeyConstraint(["contractor_id"], ["contractors.id"],),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_invoices_contractor_nip", "invoices", ["contractor_nip"])
    op.create_index("idx_invoices_tenant_status", "invoices", ["tenant_id", "status"])
    op.create_index("idx_invoices_updated_at", "invoices", ["updated_at"])
    op.create_index("idx_invoices_number", "invoices", ["number"])

    # contractors
    op.create_table(
        "contractors",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("nip", sa.String(10), nullable=False),
        sa.Column("address", sa.String(), nullable=True),
        sa.Column("bank_account", sa.String(26), nullable=True),
        sa.Column("version_id", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("nip"),
    )
    op.create_index("idx_contractors_nip", "contractors", ["nip"])

    # outbox_events
    op.create_table(
        "outbox_events",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("event_type", sa.String(), nullable=False),
        sa.Column("aggregate_id", sa.String(), nullable=False),
        sa.Column("payload", sa.Text(), nullable=False),
        sa.Column("status", sa.String(), nullable=False, server_default="PENDING"),
        sa.Column("retry_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("processed", sa.Boolean(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("processed_at", sa.DateTime(), nullable=True),
        sa.Column("processing_started_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_outbox_pending", "outbox_events", ["status", "processed", "retry_count", "created_at"])

    # audit_logs
    op.create_table(
        "audit_logs",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("invoice_id", sa.String(), nullable=True),
        sa.Column("user_id", sa.String(), nullable=False, server_default="System"),
        sa.Column("action", sa.String(), nullable=False),
        sa.Column("field_changed", sa.String(), nullable=True),
        sa.Column("old_value", sa.Text(), nullable=True),
        sa.Column("new_value", sa.Text(), nullable=True),
        sa.Column("timestamp", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["invoice_id"], ["invoices.id"],),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_audit_invoice_id", "audit_logs", ["invoice_id"])

    # active_learning_patterns
    op.create_table(
        "active_learning_patterns",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("contractor_nip", sa.String(10), nullable=False),
        sa.Column("correction_payload", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_alp_contractor_nip", "active_learning_patterns", ["contractor_nip"])

    # users
    op.create_table(
        "users",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("username", sa.String(), nullable=False),
        sa.Column("password_hash", sa.String(), nullable=False),
        sa.Column("role", sa.String(), nullable=False, server_default="worker"),
        sa.Column("tenant_id", sa.String(), nullable=False, server_default="default"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("username"),
    )

    # security_alerts
    op.create_table(
        "security_alerts",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("actor", sa.String(), nullable=False),
        sa.Column("operation", sa.String(), nullable=False),
        sa.Column("details", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # refresh_tokens
    op.create_table(
        "refresh_tokens",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("token_hash", sa.String(), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("is_revoked", sa.Boolean(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token_hash"),
    )
    op.create_index("idx_refresh_tokens_user", "refresh_tokens", ["user_id"])
    op.create_index("idx_refresh_tokens_expires", "refresh_tokens", ["expires_at"])

    # ui_drafts
    op.create_table(
        "ui_drafts",
        sa.Column("tenant_id", sa.String(), nullable=False),
        sa.Column("actor_id", sa.String(), nullable=False),
        sa.Column("draft_key", sa.String(), nullable=False),
        sa.Column("payload_json", sa.Text(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.current_timestamp()),
        sa.PrimaryKeyConstraint("tenant_id", "actor_id", "draft_key"),
    )

    # fx_rates
    op.create_table(
        "fx_rates",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("currency", sa.String(), nullable=False),
        sa.Column("rate_to_pln", sa.Float(), nullable=False),
        sa.Column("effective_at", sa.DateTime(), nullable=False),
        sa.Column("source", sa.String(), nullable=False, server_default="manual"),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_fx_rates_currency_effective", "fx_rates", ["currency", "effective_at"])

    # task_status
    op.create_table(
        "task_status",
        sa.Column("task_id", sa.String(), nullable=False),
        sa.Column("task_name", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=True),
        sa.Column("status", sa.String(), nullable=False, server_default="QUEUED"),
        sa.Column("progress", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("result", sa.Text(), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("task_id"),
    )
    op.create_index("idx_task_status_user", "task_status", ["user_id"])
    op.create_index("idx_task_status_status", "task_status", ["status"])

    # processed_events (idempotency)
    op.create_table(
        "processed_events",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("event_type", sa.String(), nullable=False),
        sa.Column("aggregate_id", sa.String(), nullable=False),
        sa.Column("payload_hash", sa.String(), nullable=False),
        sa.Column("processed_at", sa.DateTime(), nullable=True),
        sa.UniqueConstraint("event_type", "aggregate_id"),
    )
    op.create_index("idx_processed_events_business_key", "processed_events", ["event_type", "aggregate_id"], unique=True)

    # ── Roboton_Reflekton tables ──────────────────────────────────────────

    # company_profiles
    op.create_table(
        "company_profiles",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("nip", sa.String(10), nullable=False),
        sa.Column("legal_form", sa.String(32), nullable=False),
        sa.Column("ksef_active", sa.Boolean(), nullable=False, server_default="1"),
        sa.Column("ksef_token", sa.String(512), nullable=True),
        sa.Column("vat_active", sa.Boolean(), nullable=False, server_default="1"),
        sa.Column("vat_proportion", sa.Numeric(5, 4), nullable=False, server_default="1.0000"),
        sa.Column("tigerbeetle_ledger_map", sa.JSON(), nullable=False),
        sa.Column("company_policy", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("nip"),
    )

    # company_partners
    op.create_table(
        "company_partners",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("company_id", sa.String(36), nullable=False),
        sa.Column("full_name", sa.String(255), nullable=False),
        sa.Column("tax_id", sa.String(10), nullable=False),
        sa.Column("share_ratio", sa.Numeric(5, 4), nullable=False),
        sa.ForeignKeyConstraint(["company_id"], ["company_profiles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    # tax_policies
    op.create_table(
        "tax_policies",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("company_id", sa.String(36), nullable=False),
        sa.Column("tax_form", sa.String(32), nullable=False),
        sa.Column("pit_costs_enabled", sa.Boolean(), nullable=False, server_default="1"),
        sa.Column("requires_full_ledger", sa.Boolean(), nullable=False, server_default="0"),
        sa.Column("vat_settlement_cycle", sa.String(32), nullable=False, server_default="monthly"),
        sa.Column("effective_from", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["company_id"], ["company_profiles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("company_id", name="uq_tax_policy_company"),
    )

    # ledger_transfers
    op.create_table(
        "ledger_transfers",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("company_id", sa.String(36), nullable=False),
        sa.Column("source_account", sa.BigInteger(), nullable=False),
        sa.Column("target_account", sa.BigInteger(), nullable=False),
        sa.Column("amount_minor", sa.BigInteger(), nullable=False),
        sa.Column("currency", sa.String(3), nullable=False, server_default="PLN"),
        sa.Column("source_document_id", sa.String(36), nullable=False),
        sa.Column("status", sa.String(32), nullable=False, server_default="pending"),
        sa.Column("meta", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["company_id"], ["company_profiles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    # financial_periods
    op.create_table(
        "financial_periods",
        sa.Column("period_id", sa.String(7), nullable=False),
        sa.Column("company_id", sa.String(36), nullable=False),
        sa.Column("status", sa.String(32), nullable=False, server_default="open"),
        sa.Column("closed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("vat_declaration_id", sa.String(128), nullable=True),
        sa.ForeignKeyConstraint(["company_id"], ["company_profiles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("period_id", "company_id"),
    )

    # manual_cashflow_items (analytics)
    op.create_table(
        "manual_cashflow_items",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("type", sa.String(), nullable=False),
        sa.Column("expected_date", sa.Date(), nullable=True),
        sa.Column("amount", sa.Numeric(18, 2), nullable=True),
        sa.Column("description", sa.String(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="1"),
        sa.PrimaryKeyConstraint("id"),
    )

    # ── Saga store table (runtime) ────────────────────────────────────────
    op.create_table(
        "saga_log",
        sa.Column("saga_id", sa.String(), nullable=False),
        sa.Column("saga_type", sa.String(), nullable=False),
        sa.Column("state", sa.String(), nullable=False, server_default="STARTED"),
        sa.Column("step_data", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("saga_id"),
    )


def downgrade() -> None:
    """Remove all tables created in the initial migration."""
    op.drop_table("saga_log")
    op.drop_table("manual_cashflow_items")
    op.drop_table("financial_periods")
    op.drop_table("ledger_transfers")
    op.drop_table("tax_policies")
    op.drop_table("company_partners")
    op.drop_table("company_profiles")
    op.drop_index("idx_processed_events_business_key", table_name="processed_events")
    op.drop_table("processed_events")
    op.drop_index("idx_task_status_status", table_name="task_status")
    op.drop_index("idx_task_status_user", table_name="task_status")
    op.drop_table("task_status")
    op.drop_index("idx_fx_rates_currency_effective", table_name="fx_rates")
    op.drop_table("fx_rates")
    op.drop_table("ui_drafts")
    op.drop_index("idx_refresh_tokens_expires", table_name="refresh_tokens")
    op.drop_index("idx_refresh_tokens_user", table_name="refresh_tokens")
    op.drop_table("refresh_tokens")
    op.drop_table("security_alerts")
    op.drop_table("users")
    op.drop_index("idx_alp_contractor_nip", table_name="active_learning_patterns")
    op.drop_table("active_learning_patterns")
    op.drop_index("idx_audit_invoice_id", table_name="audit_logs")
    op.drop_table("audit_logs")
    op.drop_index("idx_outbox_pending", table_name="outbox_events")
    op.drop_table("outbox_events")
    op.drop_index("idx_contractors_nip", table_name="contractors")
    op.drop_table("contractors")
    op.drop_index("idx_invoices_number", table_name="invoices")
    op.drop_index("idx_invoices_updated_at", table_name="invoices")
    op.drop_index("idx_invoices_tenant_status", table_name="invoices")
    op.drop_index("idx_invoices_contractor_nip", table_name="invoices")
    op.drop_table("invoices")
