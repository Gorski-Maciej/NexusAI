from pathlib import Path


def test_cashflow_uses_window_function_for_cumulative_sum() -> None:
    source = Path('nexus_ai/api/controllers/analytics.py').read_text(encoding='utf-8')
    assert 'SUM(total_gross) OVER' in source
    assert 'cumulative_gross' in source
