"""Unit tests for DatabaseFirewall (INNOWACJA #5 v7.0).

Tests:
- SQL injection pattern detection
- Rate limiting
- Whitelist functionality
- Query classification
- FirewallBlockedError
- Stats collection
"""

from __future__ import annotations

import pytest

# Direct imports bypassing __init__.py chain (avoids queries.py TypeVar mock issue)
from nexus_ai.db.query_utils import classify_query

# Import firewall module directly
import importlib
_firewall_mod = importlib.import_module("nexus_ai.db.firewall")
DatabaseFirewall = _firewall_mod.DatabaseFirewall
FirewallBlockedError = _firewall_mod.FirewallBlockedError
get_firewall = _firewall_mod.get_firewall


class TestClassifyQuery:
    """Tests for shared classify_query utility."""

    def test_select(self):
        assert classify_query("SELECT * FROM invoices") == "SELECT"

    def test_insert(self):
        assert classify_query("INSERT INTO invoices VALUES (1)") == "INSERT"

    def test_update(self):
        assert classify_query("UPDATE invoices SET status = 'PAID'") == "UPDATE"

    def test_delete(self):
        assert classify_query("DELETE FROM invoices WHERE id = 1") == "DELETE"

    def test_ddl_create(self):
        assert classify_query("CREATE TABLE test (id INT)") == "DDL"

    def test_ddl_alter(self):
        assert classify_query("ALTER TABLE test ADD COLUMN x TEXT") == "DDL"

    def test_ddl_drop(self):
        assert classify_query("DROP TABLE test") == "DDL"

    def test_ddl_truncate(self):
        assert classify_query("TRUNCATE TABLE test") == "DDL"

    def test_ddl_pragma(self):
        assert classify_query("PRAGMA journal_mode=WAL") == "DDL"

    def test_other(self):
        assert classify_query("EXPLAIN QUERY PLAN SELECT 1") == "DDL"

    def test_empty(self):
        assert classify_query("") == "OTHER"


class TestSQLInjectionDetection:
    """Tests for SQL injection pattern detection."""

    @pytest.fixture
    def fw(self):
        return DatabaseFirewall()

    def test_boolean_injection(self, fw):
        with pytest.raises(FirewallBlockedError, match="Boolean-based"):
            fw.check_query("SELECT * FROM users WHERE id = 1 OR 1=1")

    def test_string_injection(self, fw):
        with pytest.raises(FirewallBlockedError, match="String-based"):
            fw.check_query("SELECT * FROM users WHERE id = 1 OR '1'='1'")

    def test_drop_table(self, fw):
        with pytest.raises(FirewallBlockedError, match="DROP TABLE"):
            fw.check_query("DROP TABLE invoices")

    def test_union_select(self, fw):
        with pytest.raises(FirewallBlockedError, match="UNION-based"):
            fw.check_query("SELECT id FROM invoices UNION SELECT * FROM users")

    def test_comment_out(self, fw):
        with pytest.raises(FirewallBlockedError, match="Comment-out"):
            fw.check_query("SELECT * FROM users WHERE id = '1'--")

    def test_safe_query(self, fw):
        # Normal parameterized query should pass
        assert fw.check_query(
            "SELECT * FROM invoices WHERE id = ?", ["123"]
        )

    def test_safe_insert(self, fw):
        assert fw.check_query(
            "INSERT INTO invoices (id, number) VALUES (?, ?)",
            ["1", "FV/2026/001"],
        )

    def test_empty_sql(self, fw):
        assert fw.check_query("") is True
        assert fw.check_query("   ") is True


class TestRateLimiting:
    """Tests for rate limiting functionality."""

    def test_rate_limit_exceeded(self):
        fw = DatabaseFirewall(
            rate_limits={"SELECT": (3, 60)}  # 3 queries per 60s
        )

        # First 3 should pass
        for _ in range(3):
            assert fw.check_query(
                "SELECT * FROM invoices WHERE id = ?", ["1"]
            )

        # 4th should be blocked
        with pytest.raises(FirewallBlockedError, match="Rate limit exceeded"):
            fw.check_query("SELECT * FROM invoices WHERE id = ?", ["1"])

    def test_different_types_separate_limits(self):
        fw = DatabaseFirewall(
            rate_limits={
                "SELECT": (2, 60),
                "INSERT": (2, 60),
            }
        )

        # Exhaust SELECT limit
        for _ in range(2):
            fw.check_query("SELECT 1", [])

        with pytest.raises(FirewallBlockedError):
            fw.check_query("SELECT 2", [])

        # INSERT should still work (separate bucket)
        assert fw.check_query("INSERT INTO t VALUES (1)", [])

    def test_rate_limit_window(self):
        # Window=0 means entries expire immediately → always room for more
        fw = DatabaseFirewall(
            rate_limits={"SELECT": (1, 0)}
        )
        # With window=0, each query is pruned instantly → all pass
        for _ in range(3):
            assert fw.check_query("SELECT 1", []) is True

    def test_custom_rate_limit(self):
        fw = DatabaseFirewall()
        fw.set_rate_limit("SELECT", 5, 30)
        assert fw._rate_limits["SELECT"] == (5, 30)


class TestWhitelist:
    """Tests for whitelist functionality."""

    def test_pragma_whitelisted(self):
        fw = DatabaseFirewall()
        # PRAGMA keys are whitelisted by default
        assert fw.check_query("PRAGMA journal_mode = WAL") is True
        assert fw.check_query("PRAGMA foreign_keys = ON") is True

    def test_analyze_whitelisted(self):
        fw = DatabaseFirewall()
        assert fw.check_query("ANALYZE") is True

    def test_vacuum_whitelisted(self):
        fw = DatabaseFirewall()
        assert fw.check_query("VACUUM") is True

    def test_explain_whitelisted(self):
        fw = DatabaseFirewall()
        assert fw.check_query("EXPLAIN QUERY PLAN SELECT 1") is True

    def test_custom_whitelist(self):
        fw = DatabaseFirewall()
        fw.add_whitelist("CUSTOM")
        assert fw.check_query("CUSTOM OPERATION") is True

    def test_whitelist_case_insensitive(self):
        fw = DatabaseFirewall()
        assert fw.check_query("pragma key = 'x'") is True
        assert fw.check_query("Explain QUERY PLAN SELECT 1") is True


class TestFirewallStats:
    """Tests for firewall statistics."""

    def test_basic_stats(self):
        fw = DatabaseFirewall()
        fw.check_query("SELECT 1", [])
        fw.check_query("SELECT 2", [])

        stats = fw.get_stats()
        assert stats["total_allowed"] == 2
        assert stats["total_blocked"] == 0
        assert stats["whitelist_size"] > 0

    def test_blocked_stats(self):
        fw = DatabaseFirewall()
        fw.check_query("SELECT 1", [])

        with pytest.raises(FirewallBlockedError):
            fw.check_query("SELECT * FROM users WHERE id = 1 OR 1=1")

        stats = fw.get_stats()
        assert stats["total_blocked"] >= 1
        assert stats["block_reasons"]["Boolean-based injection"] >= 1

    def test_reset_stats(self):
        fw = DatabaseFirewall()
        fw.check_query("SELECT 1", [])

        stats = fw.get_stats()
        assert stats["total_allowed"] == 1

        fw.reset_stats()
        stats = fw.get_stats()
        assert stats["total_allowed"] == 0
        assert stats["total_blocked"] == 0


class TestGlobalInstance:
    """Tests for the global firewall singleton."""

    def test_get_firewall_singleton(self):
        fw1 = get_firewall()
        fw2 = get_firewall()
        assert fw1 is fw2

    def test_get_firewall_works(self):
        fw = get_firewall()
        assert fw.check_query("SELECT 1", []) is True


class TestEdgeCases:
    """Edge case tests."""

    def test_none_sql(self):
        fw = DatabaseFirewall()
        # None/empty SQL is treated as non-malicious (passes through whitelist check)
        assert fw.check_query(None) is True  # type: ignore

    def test_very_long_query(self):
        fw = DatabaseFirewall()
        long_sql = "SELECT " + "a, " * 1000 + "b FROM invoices"
        assert fw.check_query(long_sql) is True

    def test_prepared_statement_warning(self):
        fw = DatabaseFirewall()
        # f-string concatenation should trigger warning (but not block)
        result = fw.check_query(
            f"SELECT * FROM invoices WHERE id = '123'", []
        )
        assert result is True
