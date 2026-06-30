from pathlib import Path


def test_cas_temp_file_contract_present() -> None:
    source = Path('Code/api/services.py').read_text(encoding='utf-8')
    assert 'def create_temp_upload_file' in source
    assert 'def finalize_temp_upload' in source
    assert 'Path(temp_path).replace(file_path)' in source


def test_idempotency_chunk_hash_contract_present() -> None:
    source = Path('Code/api/services.py').read_text(encoding='utf-8')
    assert 'def hash_chunks' in source
    assert 'hasher.update(chunk)' in source


def test_invoice_upload_streaming_contract_present() -> None:
    source = Path('Code/api/routes/invoices.py').read_text(encoding='utf-8')
    assert 'MAX_INVOICE_UPLOAD_BYTES = 50 * 1024 * 1024' in source
    assert 'chunk = await file_obj.read(UPLOAD_CHUNK_SIZE)' in source
    assert 'storage.finalize_temp_upload(' in source
