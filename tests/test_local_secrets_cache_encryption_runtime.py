from __future__ import annotations

import importlib.util
import os
import sys
from pathlib import Path

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes
from nexus_crypto import derive_key


def _load_mod():
    path = Path('nexus_ai/CORE/secrets.py').resolve()
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
    payload = msgspec_loads((tmp_path / 'cache.json').read_text(encoding='utf-8'))
    assert payload['a']['encrypted'] is False
    assert cache.get('a') == 'secret'


def test_cache_encrypted_when_key_available(tmp_path: Path) -> None:
    # Wygeneruj 32-bajtowy klucz baz64-url za pomocą nexus-crypto
    import base64
    key_raw, _ = derive_key("test-cache-key")
    key_b64 = base64.urlsafe_b64encode(key_raw).decode('utf-8')

    os.environ['NEXUS_SECRETS_CACHE_KEY'] = key_b64
    mod = _load_mod()
    cache = mod.LocalSecretsCache(tmp_path / 'cache.json', ttl_hours=24)
    cache.save('a', 'secret')
    payload = msgspec_loads((tmp_path / 'cache.json').read_text(encoding='utf-8'))
    assert payload['a']['encrypted'] is True
    assert payload['a']['value'] != 'secret'
    assert cache.get('a') == 'secret'
