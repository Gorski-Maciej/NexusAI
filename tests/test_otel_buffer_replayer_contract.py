from pathlib import Path


def test_otel_buffer_replayer_contract() -> None:
    source = Path('Code/SKRIPTS/otel_buffer_replayer.py').read_text(encoding='utf-8')
    assert 'FileSpanBuffer' in source
    assert '--endpoint' in source
    assert 'buffer.replay' in source
