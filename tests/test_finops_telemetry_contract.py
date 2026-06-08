from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_finops_snapshot_contract_present() -> None:
    source = (PROJECT_ROOT / 'nexus_ai' / 'services' / 'telemetry.py').read_text(encoding='utf-8')
    assert 'CREATE TABLE IF NOT EXISTS finops_cost_snapshots' in source
    assert 'def store_finops_snapshot' in source
    assert 'cost_per_invoice' in source
