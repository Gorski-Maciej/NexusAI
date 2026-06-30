from pathlib import Path


def test_tenant_extraction_checks_expiry_claim() -> None:
    source = Path('Code/api/middleware.py').read_text(encoding='utf-8')
    assert 'exp = payload.get("exp")' in source
    assert 'if int(exp) < int(time.time())' in source
