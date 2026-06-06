from pathlib import Path


def test_single_invoice_sync_exists_and_task_uses_it() -> None:
    replication = Path('Code/db/replication.py').read_text(encoding='utf-8')
    tasks = Path('Code/api/tasks.py').read_text(encoding='utf-8')

    assert 'async def sync_single_invoice_to_duckdb' in replication
    assert 'select(Invoice).where(Invoice.id == invoice_id)' in replication
    assert 'sync_single_invoice_to_duckdb(session, config, invoice_id)' in tasks
    assert 'await broker.kick("run_data_replication")' not in tasks
