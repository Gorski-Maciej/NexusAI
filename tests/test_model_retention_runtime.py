from __future__ import annotations

import importlib.util
import sys
import time
from pathlib import Path


def _load_module():
    path = Path('Code/CORE/model_retention.py').resolve()
    spec = importlib.util.spec_from_file_location('model_retention_mod', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_prune_model_versions_keeps_latest_three(tmp_path: Path) -> None:
    mod = _load_module()
    model_root = tmp_path / 'models'
    for idx in range(5):
        p = model_root / 'ocr-model' / f'v{idx}'
        p.mkdir(parents=True, exist_ok=True)
        (p / 'weights.bin').write_text('x', encoding='utf-8')
        ts = time.time() + idx
        p.touch()
        (p / 'weights.bin').touch()

    result = mod.prune_model_versions(model_root, keep_last=3)
    remaining = sorted([p.name for p in (model_root / 'ocr-model').iterdir() if p.is_dir()])

    assert result['removed_versions'] == 2
    assert len(remaining) == 3
