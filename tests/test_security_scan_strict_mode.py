from __future__ import annotations

import importlib.util
from pathlib import Path


def _load_security_scan_module():
    module_path = Path('Code/scripts/security_scan.py')
    spec = importlib.util.spec_from_file_location('security_scan_module', module_path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)
    return module


def test_run_semgrep_strict_mode_fails_when_binary_missing(monkeypatch) -> None:
    mod = _load_security_scan_module()
    monkeypatch.setattr(mod.shutil, 'which', lambda _: None)
    assert mod.run_semgrep(strict_tools=True) == 1


def test_run_semgrep_non_strict_mode_warns_when_binary_missing(monkeypatch) -> None:
    mod = _load_security_scan_module()
    monkeypatch.setattr(mod.shutil, 'which', lambda _: None)
    assert mod.run_semgrep(strict_tools=False) == 2
