from pathlib import Path


def test_startup_uses_offline_first_secret_resolver() -> None:
    source = Path('Code/API/state.py').read_text(encoding='utf-8')
    assert 'LocalSecretsCache' in source
    assert 'OfflineFirstSecretResolver' in source
    assert '_resolve_startup_secret' in source
    assert 'NEXUS_ADMIN_PASSWORD' in source
