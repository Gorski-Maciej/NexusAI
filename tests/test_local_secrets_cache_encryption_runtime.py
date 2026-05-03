from __future__ import annotations

import importlib.util
import json
import os
import sys
from pathlib import Path


def _load_mod():
    path = Path('Code/CORE/secrets.py').resolve()
    spec = importlib.util.spec_from_file_location('secrets_mod', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_cache_plaintext_when_no_key(tmp_path: Path) -> None:
    os.environ.pop('NEXUS_SECRETS_CACHE_KEY', None)
    mod = _load_mod()
    cache = mod.LocalSecretsCache(tmp_path / 'cache.json', ttl_hours=24)
    cache.save('a', 'secret')
    payload = json.loads((tmp_path / 'cache.json').read_text(encoding='utf-8'))
    assert payload['a']['encrypted'] is False
    assert cache.get('a') == 'secret'


def test_cache_encrypted_when_key_available(tmp_path: Path) -> None:
    if importlib.util.find_spec('cryptography') is None:
        return
    from cryptography.fernet import Fernet

    os.environ['NEXUS_SECRETS_CACHE_KEY'] = Fernet.generate_key().decode('utf-8')
    mod = _load_mod()
    cache = mod.LocalSecretsCache(tmp_path / 'cache.json', ttl_hours=24)
    cache.save('a', 'secret')
    payload = json.loads((tmp_path / 'cache.json').read_text(encoding='utf-8'))
    assert payload['a']['encrypted'] is True
    assert payload['a']['value'] != 'secret'
    assert cache.get('a') == 'secret'
