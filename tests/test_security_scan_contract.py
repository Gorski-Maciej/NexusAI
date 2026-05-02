from pathlib import Path


def test_security_scan_script_contains_zap_and_semgrep() -> None:
    source = Path('Code/SKRIPTS/security_scan.py').read_text(encoding='utf-8')
    assert 'zap-baseline.py' in source
    assert 'semgrep' in source
    assert 'run_codeql' in source
    assert '--skip-zap' in source
    assert '--target' in source
