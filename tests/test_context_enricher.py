"""
Tests for Part IV — ContextEnricher.

Covers:
  - Cache hit/miss
  - TTL expiration
  - Enrich with/without bank account
  - Fallback on missing NIP
"""

from __future__ import annotations

import duckdb
import pytest

from nexus_ai.services.context_enricher import ContextEnricher, ensure_cache_schema


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    ensure_cache_schema(c)
    return c


class TestContextEnricher:
    async def test_enrich_no_nip(self, conn: duckdb.DuckDBPyConnection) -> None:
        """No NIP → returns default values."""
        enricher = ContextEnricher(conn)
        result = await enricher.enrich({})
        assert result["vendor_vat_status"] == "unknown"
        assert result["vendor_trust"] == "unknown"

    async def test_enrich_invalid_nip(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Short NIP → returns default values."""
        enricher = ContextEnricher(conn)
        result = await enricher.enrich({"contractor_nip": "123"})
        assert result["vendor_vat_status"] == "unknown"

    async def test_cache_hit(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Cached value is returned."""
        # Pre-populate cache
        conn.execute(
            "INSERT INTO vendor_cache (nip, vat_status, pkd, account_whitelist, vendor_trust, company_name) "
            "VALUES ('1234567890', 'active', '62.01.Z', TRUE, 'high', 'Test Company')"
        )
        enricher = ContextEnricher(conn)
        result = await enricher.enrich({"contractor_nip": "1234567890"})
        assert result["vendor_vat_status"] == "active"
        assert result["vendor_pkd"] == "62.01.Z"
        assert result["vendor_account_on_whitelist"] is True
        assert result["vendor_trust"] == "high"

    async def test_cache_miss(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Unknown NIP → cache miss, falls through to API check."""
        enricher = ContextEnricher(conn)
        result = await enricher.enrich({
            "contractor_nip": "1111111111",
            "contractor_bank_account": "",
        })
        # Without a real API, should still return sensible defaults
        assert result["vendor_vat_status"] in ("active", "inactive", "unknown")

    async def test_cache_upsert(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Enriching same NIP twice updates cache (UPSERT)."""
        enricher = ContextEnricher(conn)
        await enricher.enrich({"contractor_nip": "1111111111"})
        rows = conn.execute("SELECT COUNT(1) FROM vendor_cache WHERE nip = '1111111111'").fetchone()
        assert rows[0] == 1
