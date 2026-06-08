from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_security_scan_script_contains_zap_and_semgrep() -> None:
    source = (PROJECT_ROOT / 'nexus_ai' / 'scripts' / 'security_scan.py').read_text(encoding='utf-8')
    assert 'zap-baseline.py' in source
    assert 'semgrep' in source
    assert 'run_codeql' in source
    assert '--skip-zap' in source
    assert '--target' in source
