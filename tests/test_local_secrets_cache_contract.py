from pathlib import Path


def test_local_secrets_cache_contract_present() -> None:
    source = Path('Code/core/secrets.py').read_text(encoding='utf-8')
    assert 'class LocalSecretsCache' in source
    assert 'def save(self, key: str, value: str)' in source
    assert 'def get(self, key: str) -> str | None' in source
    assert 'ttl_hours' in source
