from pathlib import Path


def test_content_length_guard_wired_for_uploads() -> None:
    source = Path('nexus_ai/api/routes/invoices.py').read_text(encoding='utf-8')
    assert 'def _validate_content_length' in source
    assert '_validate_content_length(request.headers, MAX_INVOICE_UPLOAD_BYTES)' in source
    assert '_validate_content_length(request.headers, MAX_ATTACHMENT_UPLOAD_BYTES)' in source
