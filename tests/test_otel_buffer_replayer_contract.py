from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_otel_buffer_replayer_contract() -> None:
    source = (PROJECT_ROOT / 'nexus_ai' / 'scripts' / 'otel_buffer_replayer.py').read_text(encoding='utf-8')
    assert 'FileSpanBuffer' in source
    assert '--endpoint' in source
    assert 'buffer.replay' in source
