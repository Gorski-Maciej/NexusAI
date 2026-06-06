from pathlib import Path


def test_invoice_upload_no_model_dump_on_msgspec_struct() -> None:
    invoices = Path('Code/api/routes/invoices.py').read_text(encoding='utf-8')

    assert 'response = TaskResponse(' in invoices
    assert '.model_dump()' not in invoices
    assert 'return response' in invoices
