from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_security_scan_has_strict_tools_flag() -> None:
    source = (PROJECT_ROOT / 'nexus_ai' / 'scripts' / 'security_scan.py').read_text(encoding='utf-8')
    assert '--strict-tools' in source
    assert 'strict_tools: bool = False' in source


def test_security_workflow_uses_strict_tools() -> None:
    source = Path('.github/workflows/security-ci.yml').read_text(encoding='utf-8')
    assert '--strict-tools' in source
