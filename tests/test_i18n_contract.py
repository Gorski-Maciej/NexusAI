from pathlib import Path


def test_i18n_catalog_and_resolver_present() -> None:
    source = Path('Code/api/i18n.py').read_text(encoding='utf-8')
    assert 'def resolve_language' in source
    assert 'def t(' in source
    assert 'upload.file_too_large' in source


def test_invoice_route_uses_i18n_translations() -> None:
    source = Path('Code/api/routes/invoices.py').read_text(encoding='utf-8')
    assert 'resolve_language(request.headers.get("accept-language"))' in source
    assert 't("upload.missing_file"' in source
    assert 't("upload.empty_file"' in source
