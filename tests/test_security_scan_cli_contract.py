from pathlib import Path


def test_security_scan_has_strict_tools_flag() -> None:
    source = Path('Code/scripts/security_scan.py').read_text(encoding='utf-8')
    assert '--strict-tools' in source
    assert 'strict_tools: bool = False' in source


def test_security_workflow_uses_strict_tools() -> None:
    source = Path('.github/workflows/security-ci.yml').read_text(encoding='utf-8')
    assert '--strict-tools' in source
