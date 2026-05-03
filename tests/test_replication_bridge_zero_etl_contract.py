from pathlib import Path


def test_replication_bridge_does_not_row_copy_into_duckdb() -> None:
    source = Path('Code/SERVICES/replication.py').read_text(encoding='utf-8')
    assert 'INSERT OR REPLACE INTO invoices_replica' not in source
    assert 'setup_zero_etl' in source
    assert 'refresh_materialized_cashflow' in source
