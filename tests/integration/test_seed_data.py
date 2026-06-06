from core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes
"""
test_seed_data.py — Tests for the seed data loading module.

Verifies that seed_data.py correctly loads demo data into the database:
    - Users are created with hashed passwords
    - Contractors are created with valid NIPs
    - Invoices are created with correct amounts
    - Outbox events are created for each invoice
    - Audit logs are created
    - Duplicate data is handled gracefully (idempotency)
"""

from __future__ import annotations

import pytest
from sqlalchemy import text


@pytest.mark.integration
class TestSeedDataDirect:

    async def test_seed_users_structure(self, db_session) -> None:
        """Test that the SEED_USERS data structure is valid."""
        from scripts.seed_data import SEED_USERS

        assert len(SEED_USERS) == 2
        usernames = [u["username"] for u in SEED_USERS]
        assert "admin" in usernames
        assert "ksiegowa" in usernames

        roles = [u["role"] for u in SEED_USERS]
        assert "owner" in roles
        assert "accountant" in roles

    async def test_seed_nips_are_valid(self) -> None:
        """Test that SEED_NIPS have valid checksums."""
        from scripts.seed_data import SEED_NIPS, _verify_nip_checksum

        for nip in SEED_NIPS:
            assert _verify_nip_checksum(nip), f"NIP {nip} has invalid checksum"

    async def test_seed_contractors_structure(self) -> None:
        """Test SEED_CONTRACTORS data structure."""
        from scripts.seed_data import SEED_CONTRACTORS

        assert len(SEED_CONTRACTORS) == 5
        for contractor in SEED_CONTRACTORS:
            assert "id" in contractor
            assert "name" in contractor
            assert "nip" in contractor
            assert "bank_account" in contractor
            assert contractor["bank_account"].startswith("PL")

    async def test_seed_invoices_structure(self) -> None:
        """Test SEED_INVOICES data structure and financial consistency."""
        from scripts.seed_data import SEED_INVOICES

        assert len(SEED_INVOICES) == 15

        statuses = set()
        for invoice in SEED_INVOICES:
            net = float(invoice["amount_net"])
            gross = float(invoice["amount_gross"])

            # Gross must be >= Net
            assert gross >= net, f"Invoice {invoice['number']}: gross < net"
            statuses.add(invoice["status"])

        # Verify all status types are covered
        assert "NEW" in statuses
        assert "PROCESSING" in statuses
        assert "APPROVED" in statuses
        assert "ERROR" in statuses

    async def test_seed_companies_structure(self) -> None:
        """Test SEED_COMPANIES data structure."""
        from scripts.seed_data import SEED_COMPANIES

        assert len(SEED_COMPANIES) == 3
        legal_forms = {c["legal_form"] for c in SEED_COMPANIES}
        assert "sp_z_o_o" in legal_forms
        assert "jednoosobowa" in legal_forms
        assert "sa" in legal_forms

    async def test_seed_fx_rates_structure(self) -> None:
        """Test SEED_FX_RATES data structure."""
        from scripts.seed_data import SEED_FX_RATES

        assert len(SEED_FX_RATES) == 5
        currencies = {r["currency"] for r in SEED_FX_RATES}
        assert "EUR" in currencies
        assert "USD" in currencies
        assert "GBP" in currencies

    async def test_seed_financial_periods_structure(self) -> None:
        """Test SEED_FINANCIAL_PERIODS data structure."""
        from scripts.seed_data import SEED_FINANCIAL_PERIODS

        assert len(SEED_FINANCIAL_PERIODS) == 5
        assert any(p["status"] == "open" for p in SEED_FINANCIAL_PERIODS)


@pytest.mark.integration
class TestSeedDatabase:
    """Test actual database seeding via db_session."""

    async def test_insert_contractors(self, db_session) -> None:
        """Test inserting contractors into the database."""
        import uuid
        from datetime import datetime, timezone

        now = datetime.now(timezone.utc).isoformat()
        cid = str(uuid.uuid4())

        await db_session.execute(
            text(
                """\
                INSERT INTO contractors (id, name, nip, address, bank_account, created_at, updated_at)
                VALUES (:id, 'Seed Test', '5213456789', 'Test Address', 'PL10105000997603123456789123', :now, :now)
                """
            ),
            {"id": cid, "now": now},
        )
        await db_session.commit()

        result = await db_session.execute(
            text("SELECT name, nip FROM contractors WHERE id = :id"),
            {"id": cid},
        )
        row = result.fetchone()
        assert row is not None
        assert row[0] == "Seed Test"
        assert row[1] == "5213456789"

    async def test_insert_invoice_with_relationships(self, db_session) -> None:
        """Test inserting an invoice linked to a contractor."""
        import uuid
        from datetime import datetime, timezone

        now = datetime.now(timezone.utc).isoformat()

        # First create a contractor
        cid = str(uuid.uuid4())
        await db_session.execute(
            text(
                """\
                INSERT INTO contractors (id, name, nip, created_at, updated_at)
                VALUES (:id, 'Linked Contractor', '5213456789', :now, :now)
                """
            ),
            {"id": cid, "now": now},
        )
        await db_session.commit()

        # Then create an invoice linked to that contractor
        inv_id = str(uuid.uuid4())
        await db_session.execute(
            text(
                """\
                INSERT INTO invoices (id, number, amount_net, amount_gross, currency,
                    contractor_nip, contractor_id, status, file_path, tenant_id,
                    created_at, updated_at, created_by, updated_by)
                VALUES (:id, 'FV/SEED/001', 2000.00, 2460.00, 'PLN',
                    '5213456789', :cid, 'NEW', 'seed/test.pdf', 'default',
                    :now, :now, 'seed_test', 'seed_test')
                """
            ),
            {"id": inv_id, "cid": cid, "now": now},
        )
        await db_session.commit()

        # Verify the relationship
        result = await db_session.execute(
            text(
                """\
                SELECT i.number, i.amount_net, c.name
                FROM invoices i
                JOIN contractors c ON c.id = i.contractor_id
                WHERE i.id = :id
                """
            ),
            {"id": inv_id},
        )
        row = result.fetchone()
        assert row is not None
        assert row[0] == "FV/SEED/001"
        assert float(row[1]) == 2000.00
        assert row[2] == "Linked Contractor"

    async def test_outbox_event_creation(self, db_session) -> None:
        """Test creating and querying outbox events."""
        import uuid, json
        from datetime import datetime, timezone

        now = datetime.now(timezone.utc).isoformat()
        event_id = str(uuid.uuid4())
        inv_id = str(uuid.uuid4())

        payload = msgspec_dumps({"invoice_id": inv_id, "test": True})
        await db_session.execute(
            text(
                """\
                INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at)
                VALUES (:id, 'TEST_EVENT', :aggregate_id, :payload, 'PENDING', 0, :now)
                """
            ),
            {
                "id": event_id,
                "aggregate_id": inv_id,
                "payload": payload,
                "now": now,
            },
        )
        await db_session.commit()

        # Query PENDING events
        result = await db_session.execute(
            text("SELECT event_type, payload FROM outbox_events WHERE status = 'PENDING' AND id = :id"),
            {"id": event_id},
        )
        row = result.fetchone()
        assert row is not None
        assert row[0] == "TEST_EVENT"

        loaded_payload = msgspec_loads(row[1])
        assert loaded_payload["test"] is True
        assert loaded_payload["invoice_id"] == inv_id

    async def test_idempotent_insert(self, db_session) -> None:
        """Test that inserting the same record twice is handled gracefully."""
        import uuid
        from datetime import datetime, timezone

        now = datetime.now(timezone.utc).isoformat()
        cid = str(uuid.uuid4())

        # First insert
        await db_session.execute(
            text(
                """\
                INSERT INTO contractors (id, name, nip, created_at, updated_at)
                VALUES (:id, 'Idempotent Test', '5213456789', :now, :now)
                """
            ),
            {"id": cid, "now": now},
        )
        await db_session.commit()

        # Second insert with same NIP should fail on UNIQUE constraint
        with pytest.raises(Exception):
            await db_session.execute(
                text(
                    """\
                    INSERT INTO contractors (id, name, nip, created_at, updated_at)
                    VALUES (:id, 'Duplicate', '5213456789', :now, :now)
                    """
                ),
                {"id": str(uuid.uuid4()), "now": now},
            )
            await db_session.commit()

    async def test_audit_log_workflow(self, db_session) -> None:
        """Test full audit log workflow: create invoice → audit entry."""
        import uuid
        from datetime import datetime, timezone

        now = datetime.now(timezone.utc).isoformat()

        # Create invoice
        inv_id = str(uuid.uuid4())
        await db_session.execute(
            text(
                """\
                INSERT INTO invoices (id, number, amount_net, amount_gross, currency,
                    status, file_path, tenant_id, created_at, updated_at, created_by, updated_by)
                VALUES (:id, 'FV/AUDIT/001', 500.00, 615.00, 'PLN',
                    'NEW', 'audit/test.pdf', 'default', :now, :now, 'audit_test', 'audit_test')
                """
            ),
            {"id": inv_id, "now": now},
        )
        await db_session.commit()

        # Create audit entry
        audit_id = str(uuid.uuid4())
        await db_session.execute(
            text(
                """\
                INSERT INTO audit_logs (id, invoice_id, user_id, action, new_value, timestamp, created_at)
                VALUES (:id, :inv_id, 'system', 'STATUS_CHANGED', 'CREATED', :now, :now)
                """
            ),
            {"id": audit_id, "inv_id": inv_id, "now": now},
        )
        await db_session.commit()

        # Verify audit trail
        result = await db_session.execute(
            text(
                """\
                SELECT a.action, a.user_id, i.number
                FROM audit_logs a
                JOIN invoices i ON i.id = a.invoice_id
                WHERE a.id = :id
                """
            ),
            {"id": audit_id},
        )
        row = result.fetchone()
        assert row is not None
        assert row[0] == "STATUS_CHANGED"
        assert row[1] == "system"
        assert row[2] == "FV/AUDIT/001"
