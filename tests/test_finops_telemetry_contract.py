from pathlib import Path


def test_finops_snapshot_contract_present() -> None:
    source = Path('Code/SERVICES/telemetry.py').read_text(encoding='utf-8')
    assert 'CREATE TABLE IF NOT EXISTS finops_cost_snapshots' in source
    assert 'def store_finops_snapshot' in source
    assert 'cost_per_invoice' in source
