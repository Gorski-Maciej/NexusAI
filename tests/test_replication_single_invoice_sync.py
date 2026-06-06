from pathlib import Path


def test_replication_bridge_uses_zero_etl_instead_of_single_invoice_row_copy() -> None:
    """The replication contract is Zero-ETL, not per-invoice DuckDB writes."""
    replication = Path("Code/services/replication.py").read_text(encoding="utf-8")
    tasks = Path("Code/api/tasks.py").read_text(encoding="utf-8")

    assert "setup_zero_etl" in replication
    assert "refresh_materialized_cashflow" in replication
    assert "INSERT OR REPLACE INTO invoices_replica" not in replication
    assert "async def sync_single_invoice_to_duckdb" not in replication
    assert "sync_single_invoice_to_duckdb(session, config, invoice_id)" not in tasks
    assert 'await broker.kick("run_data_replication")' not in tasks
