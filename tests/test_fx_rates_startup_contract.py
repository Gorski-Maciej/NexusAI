from pathlib import Path


def test_startup_creates_fx_rates_table_for_asof_analytics() -> None:
    source = Path('Code/API/state.py').read_text(encoding='utf-8')
    assert 'CREATE TABLE IF NOT EXISTS fx_rates' in source
    assert 'idx_fx_rates_currency_effective' in source
