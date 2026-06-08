from __future__ import annotations

from pathlib import Path

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.scripts.security_scan import _enforce_zap_severity_gate


def test_zap_severity_gate_breaches(tmp_path: Path) -> None:
    reports = tmp_path / 'reports'
    reports.mkdir()
    (reports / 'zap_full.json').write_text(msgspec_dumps({
        'site': [{'alerts': [{'riskcode': '3'}, {'riskcode': '2'}]}]
    }), encoding='utf-8')
    cwd = Path.cwd()
    try:
        import os
        os.chdir(tmp_path)
        assert _enforce_zap_severity_gate('full', max_high=0, max_medium=0) == 1
    finally:
        os.chdir(cwd)


def test_zap_severity_gate_passes(tmp_path: Path) -> None:
    reports = tmp_path / 'reports'
    reports.mkdir()
    (reports / 'zap_baseline.json').write_text(msgspec_dumps({'site': [{'alerts': [{'riskcode': '1'}]}]}), encoding='utf-8')
    cwd = Path.cwd()
    try:
        import os
        os.chdir(tmp_path)
        assert _enforce_zap_severity_gate('baseline', max_high=0, max_medium=0) == 0
    finally:
        os.chdir(cwd)
