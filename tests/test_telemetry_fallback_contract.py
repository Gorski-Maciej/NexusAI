from pathlib import Path


def test_telemetry_uses_file_span_buffer_fallback() -> None:
    source = Path('Code/services/telemetry.py').read_text(encoding='utf-8')
    assert 'FileSpanBuffer' in source
    assert 'except Exception:' in source
    assert 'FileSpanBuffer().append(' in source


def test_telemetry_optional_gputil_loader_present() -> None:
    source = Path('Code/services/telemetry.py').read_text(encoding='utf-8')
    assert 'def _load_gputil_module' in source
    assert 'importlib.util.find_spec("GPUtil")' in source
