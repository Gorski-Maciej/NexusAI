from __future__ import annotations

from pathlib import Path

from nexus_ai.scripts.migration_sanity_check import TableStat, compare_stats


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_compare_stats_detects_regression() -> None:
    before = {"invoices": TableStat(name="invoices", rows=10)}
    after = {"invoices": TableStat(name="invoices", rows=8)}
    issues = compare_stats(before, after)
    assert issues
    assert 'Row count regression' in issues[0]


def test_checksum_option_contract_present() -> None:
    source = (PROJECT_ROOT / 'nexus_ai' / 'scripts' / 'migration_sanity_check.py').read_text(encoding='utf-8')
    assert '--checksum' in source
    assert 'table_checksum' in source
