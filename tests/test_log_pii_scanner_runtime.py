from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def _load_module():
    path = Path('Code/scripts/log_pii_scanner.py').resolve()
    spec = importlib.util.spec_from_file_location('log_pii_scanner_mod', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_scan_text_detects_pii_patterns() -> None:
    mod = _load_module()
    findings = mod.scan_text('NIP: 123-456-32-18\nSAFE')
    assert findings
    assert findings[0].pattern == 'NIP'


def test_redact_flag_contract_present() -> None:
    source = Path('Code/scripts/log_pii_scanner.py').read_text(encoding='utf-8')
    assert '--redact-output' in source
    assert '[REDACTED]' in source
