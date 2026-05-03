from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def _load_module():
    path = Path('Code/SKRIPTS/log_pii_scanner.py').resolve()
    spec = importlib.util.spec_from_file_location('log_pii_scanner_mod_v2', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_nip_checksum_reduces_false_positives() -> None:
    mod = _load_module()
    bad = mod.scan_text('NIP: 123-456-78-90')
    good = mod.scan_text('NIP: 8567346215')
    assert bad == []
    assert any(item.pattern == 'NIP' for item in good)


def test_scan_path_directory_support(tmp_path: Path) -> None:
    mod = _load_module()
    (tmp_path / 'a.log').write_text('PESEL 44051401458', encoding='utf-8')
    (tmp_path / 'b.txt').write_text('SAFE', encoding='utf-8')
    out = mod.scan_path(tmp_path)
    assert str(tmp_path / 'a.log') in out
    assert len(out[str(tmp_path / 'a.log')]) == 1
