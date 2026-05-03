from pathlib import Path


def test_upload_guard_has_content_length_fast_fail() -> None:
    source = Path('Code/API/middleware.py').read_text(encoding='utf-8')
    assert 'content_length = headers.get("content-length")' in source
    assert 'HTTP_413_REQUEST_ENTITY_TOO_LARGE' in source


def test_upload_guard_limits_target_paths() -> None:
    source = Path('Code/API/middleware.py').read_text(encoding='utf-8')
    assert 'path.endswith("/invoices/upload")' in source
    assert 'path.endswith("/invoices/upload-large")' in source
