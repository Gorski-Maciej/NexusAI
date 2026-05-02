from pathlib import Path


def test_forecaster_projection_range_contract() -> None:
    source = Path('Code/CORE/forecaster.py').read_text(encoding='utf-8')
    assert 'projection_range' in source
    assert 'std_daily_delta' in source
    assert 'volatility_buffer' in source
