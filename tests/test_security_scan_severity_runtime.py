from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes
from __future__ import annotations

import importlib.util
import json
from pathlib import Path


def _load_mod():
    p = Path('Code/scripts/security_scan.py').resolve()
    spec = importlib.util.spec_from_file_location('sec_scan_mod2', p)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_zap_severity_gate_breaches(tmp_path: Path) -> None:
    mod = _load_mod()
    reports = tmp_path / 'reports'
    reports.mkdir()
    (reports / 'zap_full.json').write_text(msgspec_dumps({
        'site': [{'alerts': [{'riskcode': '3'}, {'riskcode': '2'}]}]
    }), encoding='utf-8')
    cwd = Path.cwd()
    try:
        import os
        os.chdir(tmp_path)
        assert mod._enforce_zap_severity_gate('full', max_high=0, max_medium=0) == 1
    finally:
        os.chdir(cwd)


def test_zap_severity_gate_passes(tmp_path: Path) -> None:
    mod = _load_mod()
    reports = tmp_path / 'reports'
    reports.mkdir()
    (reports / 'zap_baseline.json').write_text(msgspec_dumps({'site': [{'alerts': [{'riskcode': '1'}]}]}), encoding='utf-8')
    cwd = Path.cwd()
    try:
        import os
        os.chdir(tmp_path)
        assert mod._enforce_zap_severity_gate('baseline', max_high=0, max_medium=0) == 0
    finally:
        os.chdir(cwd)
