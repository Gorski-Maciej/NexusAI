from pathlib import Path


def test_cashflow_supports_asof_join_currency_conversion() -> None:
    source = Path('Code/api/controllers/analytics.py').read_text(encoding='utf-8')
    assert 'ASOF LEFT JOIN oltp.fx_rates' in source
    assert 'report_currency' in source
