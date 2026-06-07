from __future__ import annotations

import importlib.util
import sys
import time
from pathlib import Path

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes


def _load_module():
    path = Path('Code/CORE/model_retention.py').resolve()
    spec = importlib.util.spec_from_file_location('model_retention_mod_v2', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_dry_run_does_not_delete(tmp_path: Path) -> None:
    mod = _load_module()
    root = tmp_path / 'models'
    for idx in range(4):
        p = root / 'ocr' / f'v{idx}'
        p.mkdir(parents=True, exist_ok=True)
        (p / 'w.bin').write_text('abc', encoding='utf-8')
        ts = time.time() + idx
        p.touch()
        (p / 'w.bin').touch()

    result = mod.prune_model_versions(root, keep_last=2, dry_run=True)
    assert result['removed_versions'] == 2
    assert len(list((root / 'ocr').iterdir())) == 4


def test_manifest_written_with_events(tmp_path: Path) -> None:
    mod = _load_module()
    root = tmp_path / 'models'
    arc = tmp_path / 'archive'
    man = tmp_path / 'retention.json'
    for idx in range(3):
        p = root / 'clf' / f'v{idx}'
        p.mkdir(parents=True, exist_ok=True)
        (p / 'w.bin').write_text('abc', encoding='utf-8')
        ts = time.time() + idx
        p.touch()
        (p / 'w.bin').touch()

    mod.prune_model_versions(root, keep_last=1, archive_root=arc, manifest_path=man)
    payload = msgspec_loads(man.read_bytes())
    assert payload['archived_versions'] == 2
    assert len(payload['events']) == 2
