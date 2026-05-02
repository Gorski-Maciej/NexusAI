from __future__ import annotations

import importlib.util
from pathlib import Path
import sys


def _load_services_module():
    module_path = Path('Code/API/services.py').resolve()
    spec = importlib.util.spec_from_file_location('nexus_api_services_runtime', module_path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def test_stream_hash_matches_payload_hash() -> None:
    services = _load_services_module()
    chunks = [b'a', b'bc', b'def']
    assert services.IdempotencyStore.hash_chunks(chunks) == services.IdempotencyStore.hash_payload(b''.join(chunks))


def test_temp_file_finalize_moves_or_dedupes(tmp_path: Path) -> None:
    services = _load_services_module()
    storage = services.ContentAddressableStorage(tmp_path)
    payload = b'invoice-data'
    digest = services.IdempotencyStore.hash_payload(payload)

    temp_1 = storage.create_temp_upload_file()
    Path(temp_1).write_bytes(payload)
    saved_1 = storage.finalize_temp_upload(temp_1, digest=digest, size_bytes=len(payload), suffix='.pdf')
    assert Path(saved_1.file_path).exists()

    temp_2 = storage.create_temp_upload_file()
    Path(temp_2).write_bytes(payload)
    saved_2 = storage.finalize_temp_upload(temp_2, digest=digest, size_bytes=len(payload), suffix='.pdf')

    assert saved_1.file_path == saved_2.file_path
    assert not Path(temp_2).exists()
