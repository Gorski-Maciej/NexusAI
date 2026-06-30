from pathlib import Path


def test_large_attachment_endpoint_contract() -> None:
    source = Path('Code/api/routes/invoices.py').read_text(encoding='utf-8')
    assert 'MAX_ATTACHMENT_UPLOAD_BYTES = 500 * 1024 * 1024' in source
    assert '@post("/upload-large"' in source
    assert 'ATTACHMENT_LARGE_UPLOADED' in source
