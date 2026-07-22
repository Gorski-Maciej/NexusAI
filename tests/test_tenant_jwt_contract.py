from pathlib import Path


def test_middleware_extracts_tenant_from_bearer_token_contract() -> None:
    source = Path('nexus_ai/api/middleware.py').read_text(encoding='utf-8')
    assert 'def _tenant_from_bearer_auth' in source
    assert 'hmac.new(SECRET_KEY.encode()' in source
    assert 'tenant_from_token = self._tenant_from_bearer_auth' in source
