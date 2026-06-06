import json
from pathlib import Path


def test_i18n_catalog_and_resolver_present() -> None:
    source = Path('Code/api/i18n.py').read_text(encoding='utf-8')
    assert 'def resolve_language' in source
    assert 'def t(' in source


def test_i18n_locale_catalogs_define_upload_messages() -> None:
    for locale in ('pl', 'en'):
        catalog_path = Path(f'Code/api/locales/{locale}.json')
        catalog = json.loads(catalog_path.read_text(encoding='utf-8'))

        assert catalog['upload.missing_file']
        assert catalog['upload.empty_file']
        assert '{limit_mb}' in catalog['upload.file_too_large']


def test_invoice_route_uses_i18n_translations() -> None:
    source = Path('Code/api/routes/invoices.py').read_text(encoding='utf-8')
    assert 'resolve_language(request.headers.get("accept-language"))' in source
    assert 't("upload.missing_file"' in source
    assert 't("upload.empty_file"' in source
