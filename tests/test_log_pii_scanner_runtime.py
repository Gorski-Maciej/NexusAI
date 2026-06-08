from __future__ import annotations

from pathlib import Path

from nexus_ai.scripts.log_pii_scanner import scan_text


def test_scan_text_detects_pii_patterns() -> None:
    findings = scan_text('NIP: 123-456-32-18\nSAFE')
    assert findings
    assert findings[0].pattern == 'NIP'


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_redact_flag_contract_present() -> None:
    source = (PROJECT_ROOT / 'nexus_ai' / 'scripts' / 'log_pii_scanner.py').read_text(encoding='utf-8')
    assert '--redact-output' in source
    assert '[REDACTED]' in source
