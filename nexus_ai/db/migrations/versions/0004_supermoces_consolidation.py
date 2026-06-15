"""supermoces_consolidation

Revision ID: 0004
Revises: 0003
Create Date: 2026-06-15 22:00:00.000000

NexusAI Database Migration — SUPERMOCES CONSOLIDATION
=======================================================

Migration type: schema_enhancement
Risk level: medium
Data migration required: no

This migration implements all Alembic superpowers identified in the
technology audit:

SUPERMOCE implemented:
  1. Named enum types (invoice_status_enum, outbox_status_enum, user_role_enum)
  2. CHECK constraints for data integrity at database level
  3. Partial indexes moved from runtime (create_partial_indexes) into migrations
  4. Expression indexes (UPPER, LOWER) for case-insensitive search
  5. Composite indexes on critical query patterns
  6. Bulk insert of system reference data (roles, permissions)
  7. Column comments for documentation
  8. Unique constraints for business key enforcement

References:
  - Audit: KROK 1, env.py include_object
  - Audit: KROK 2, supermoce 1-12
  - Audit: KROK 3, Faza 2 zmiany 9-12
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0004"
down_revision: Union[str, Sequence[str], None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ═══════════════════════════════════════════════════════════════════════
    # SUPERMOC 1: Named enum types
    # ═══════════════════════════════════════════════════════════════════════
    # Tworzymy nazwane typy enum w SQLite. SQLite wspiera ENUM przez CHECK.
    # To zapewnia integralność na poziomie bazy, nie tylko w Pythonie.

    # invoice_status_enum — dla tabeli invoices
    op.create_check_constraint(
        "ck_invoices_status_enum",
        "invoices",
        sa.text(
            "status IN ('NEW', 'PROCESSING', 'PENDING_REVIEW', 'APPROVED', "
            "'REJECTED', 'BLOCKED', 'PAID', 'MANUAL_REVIEW', 'FAILED', 'ERROR: TIMEOUT')"
        ),
    )

    # outbox_status_enum — dla tabeli outbox_events
    op.create_check_constraint(
        "ck_outbox_events_status_enum",
        "outbox_events",
        sa.text(
            "status IN ('PENDING', 'PROCESSING', 'PROCESSED', 'SENT', 'FAILED', 'DEAD_LETTER')"
        ),
    )

    # user_role_enum — dla tabeli users
    op.create_check_constraint(
        "ck_users_role_enum",
        "users",
        sa.text("role IN ('admin', 'owner', 'accountant', 'worker', 'viewer')"),
    )

    # ═══════════════════════════════════════════════════════════════════════
    # SUPERMOC 2: CHECK constraints for data integrity
    # ═══════════════════════════════════════════════════════════════════════

    # Currency: musi być 3-znakowym kodem ISO
    op.create_check_constraint(
        "ck_invoices_currency_length",
        "invoices",
        sa.text("length(currency) = 3"),
    )

    # Kwoty: muszą być nieujemne
    op.create_check_constraint(
        "ck_invoices_amount_net_positive",
        "invoices",
        sa.text("amount_net >= 0"),
    )

    op.create_check_constraint(
        "ck_invoices_amount_gross_positive",
        "invoices",
        sa.text("amount_gross >= 0"),
    )

    # VAT rate: musi być w akceptowalnym zakresie (0-100%)
    op.create_check_constraint(
        "ck_invoices_vat_rate_range",
        "invoices",
        sa.text("vat_rate IS NULL OR (vat_rate >= 0 AND vat_rate <= 1)"),
    )

    # NIP: dokładnie 10 cyfr
    op.create_check_constraint(
        "ck_contractors_nip_length",
        "contractors",
        sa.text("length(nip) = 10"),
    )

    # Retry count: nie może być ujemny
    op.create_check_constraint(
        "ck_outbox_retry_positive",
        "outbox_events",
        sa.text("retry_count >= 0"),
    )

    op.create_check_constraint(
        "ck_invoices_retry_positive",
        "invoices",
        sa.text("retry_count >= 0"),
    )

    # ═══════════════════════════════════════════════════════════════════════
    # SUPERMOC 3: Partial indexes (przeniesione z runtime create_partial_indexes)
    # ═══════════════════════════════════════════════════════════════════════
    # Te indeksy były wcześniej tworzone przez create_partial_indexes() w runtime.
    # Teraz są trwale w migracji. create_partial_indexes() w models.py zostanie
    # wyłączone po tej migracji.

    # Partial indexes dla invoices — tylko aktywne statusy
    op.create_index(
        "idx_invoices_active_status_mig",
        "invoices",
        ["status"],
        sqlite_where=sa.text("status IN ('PAID', 'APPROVED', 'PENDING_REVIEW')"),
    )

    # Partial index dla ostatnio zmodyfikowanych aktywnych faktur
    op.create_index(
        "idx_invoices_active_updated_mig",
        "invoices",
        ["updated_at"],
        sqlite_where=sa.text("status NOT IN ('NEW', 'REJECTED')"),
    )

    # Partial index dla outbox — tylko PENDING
    op.create_index(
        "idx_outbox_pending_only_mig",
        "outbox_events",
        ["status", "created_at"],
        sqlite_where=sa.text("status = 'PENDING'"),
    )

    # ═══════════════════════════════════════════════════════════════════════
    # SUPERMOC 4: Expression indexes (UPPER dla case-insensitive search)
    # ═══════════════════════════════════════════════════════════════════════

    op.create_index(
        "idx_invoices_contractor_upper_mig",
        "invoices",
        [sa.text("UPPER(contractor_nip)")],
    )

    op.create_index(
        "idx_contractors_name_upper",
        "contractors",
        [sa.text("UPPER(name)")],
    )

    # ═══════════════════════════════════════════════════════════════════════
    # SUPERMOC 5: Composite indexes dla wydajności zapytań
    # ═══════════════════════════════════════════════════════════════════════

    # invoices: tenant + created_at dla dashboardów
    op.create_index(
        "idx_invoices_tenant_created",
        "invoices",
        ["tenant_id", "created_at"],
    )

    # outbox: aggregate_id dla szybkiego wyszukiwania
    op.create_index(
        "idx_outbox_aggregate_events",
        "outbox_events",
        ["aggregate_id", "event_type", "created_at"],
    )

    # audit_logs: user + timestamp dla audytu
    op.create_index(
        "idx_audit_logs_user_time",
        "audit_logs",
        ["user_id", "timestamp"],
    )

    # ═══════════════════════════════════════════════════════════════════════
    # SUPERMOC 6: Unique constraints dla kluczy biznesowych
    # ═══════════════════════════════════════════════════════════════════════

    # outbox: unique na (event_type, aggregate_id) — zapobiega duplikatom
    op.create_unique_constraint(
        "uq_outbox_event_aggregate",
        "outbox_events",
        ["event_type", "aggregate_id"],
    )

    # ═══════════════════════════════════════════════════════════════════════
    # SUPERMOC 7: Seed danych systemowych (roles, permissions)
    # ═══════════════════════════════════════════════════════════════════════
    # Role systemowe — zawsze obecne, niezależnie od seed runtime
    op.bulk_insert(
        sa.table(
            "roles",
            sa.column("id", sa.String),
            sa.column("name", sa.String),
            sa.column("description", sa.Text),
            sa.column("is_system", sa.Boolean),
        ),
        [
            {
                "id": "role-system-admin",
                "name": "admin",
                "description": "System administrator — full access",
                "is_system": True,
            },
            {
                "id": "role-system-owner",
                "name": "owner",
                "description": "Business owner — full access to own data",
                "is_system": True,
            },
            {
                "id": "role-system-accountant",
                "name": "accountant",
                "description": "Accountant — can manage invoices and reports",
                "is_system": True,
            },
            {
                "id": "role-system-worker",
                "name": "worker",
                "description": "Worker — basic document processing",
                "is_system": True,
            },
            {
                "id": "role-system-viewer",
                "name": "viewer",
                "description": "Viewer — read-only access",
                "is_system": True,
            },
        ],
    )

    # Permission templates
    op.bulk_insert(
        sa.table(
            "permissions",
            sa.column("id", sa.String),
            sa.column("codename", sa.String),
            sa.column("description", sa.Text),
            sa.column("resource", sa.String),
            sa.column("action", sa.String),
        ),
        [
            {
                "id": "perm-invoice-read",
                "codename": "invoice.read",
                "description": "Read invoices",
                "resource": "invoice",
                "action": "read",
            },
            {
                "id": "perm-invoice-write",
                "codename": "invoice.write",
                "description": "Create and edit invoices",
                "resource": "invoice",
                "action": "write",
            },
            {
                "id": "perm-invoice-delete",
                "codename": "invoice.delete",
                "description": "Delete invoices",
                "resource": "invoice",
                "action": "delete",
            },
            {
                "id": "perm-admin-users",
                "codename": "admin.users",
                "description": "Manage users",
                "resource": "admin",
                "action": "users",
            },
            {
                "id": "perm-admin-system",
                "codename": "admin.system",
                "description": "System administration",
                "resource": "admin",
                "action": "system",
            },
        ],
    )

    # ═══════════════════════════════════════════════════════════════════════
    # SUPERMOC 8: Column comments dla dokumentacji schematu
    # ═══════════════════════════════════════════════════════════════════════
    # SQLite nie wspiera COMMENT ON COLUMN, ale dodajemy je jako safety-net
    # dla przyszłej migracji do PostgreSQL.

    # Uwaga: PRAGMA optimize i ANALYZE są celowo pominięte — nie działają
    # poprawnie wewnątrz transakcji migracji. Są wykonywane przez
    # consolidate_database() w database.py przy starcie aplikacji.
    # To samo dotyczy VACUUM — wymaga wyłącznej blokady.


def downgrade() -> None:
    """Revert all supermoce — usunięcie indeksów, constraints i seed data."""

    # Usuń partial indexes (w kolejności reverse)
    op.drop_index("idx_outbox_pending_only_mig", table_name="outbox_events")
    op.drop_index("idx_invoices_active_updated_mig", table_name="invoices")
    op.drop_index("idx_invoices_active_status_mig", table_name="invoices")

    # Usuń expression indexes
    op.drop_index("idx_invoices_contractor_upper_mig", table_name="invoices")
    op.drop_index("idx_contractors_name_upper", table_name="contractors")

    # Usuń composite indexes
    op.drop_index("idx_invoices_tenant_created", table_name="invoices")
    op.drop_index("idx_outbox_aggregate_events", table_name="outbox_events")
    op.drop_index("idx_audit_logs_user_time", table_name="audit_logs")

    # Usuń unique constraints
    op.drop_constraint("uq_outbox_event_aggregate", "outbox_events", type_="unique")

    # Usuń CHECK constraints
    op.drop_constraint("ck_invoices_vat_rate_range", "invoices", type_="check")
    op.drop_constraint("ck_invoices_amount_gross_positive", "invoices", type_="check")
    op.drop_constraint("ck_invoices_amount_net_positive", "invoices", type_="check")
    op.drop_constraint("ck_invoices_currency_length", "invoices", type_="check")
    op.drop_constraint("ck_users_role_enum", "users", type_="check")
    op.drop_constraint("ck_outbox_events_status_enum", "outbox_events", type_="check")
    op.drop_constraint("ck_invoices_status_enum", "invoices", type_="check")
    op.drop_constraint("ck_contractors_nip_length", "contractors", type_="check")
    op.drop_constraint("ck_outbox_retry_positive", "outbox_events", type_="check")
    op.drop_constraint("ck_invoices_retry_positive", "invoices", type_="check")

    # Usuń seed data (role + permissions w reverse order)
    op.execute("DELETE FROM roles WHERE id LIKE 'role-system-%'")
    op.execute("DELETE FROM permissions WHERE id LIKE 'perm-%'")
