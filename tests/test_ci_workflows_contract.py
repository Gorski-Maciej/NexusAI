from pathlib import Path


def test_security_workflow_uses_python_scan_script() -> None:
    source = Path('.github/workflows/security-ci.yml').read_text(encoding='utf-8')
    assert 'actions/setup-python@v5' in source
    assert 'python Code/SKRIPTS/security_scan.py' in source


def test_performance_workflow_uses_threshold_runner() -> None:
    source = Path('.github/workflows/performance-k6.yml').read_text(encoding='utf-8')
    assert 'python Code/SKRIPTS/performance_engineering.py' in source
    assert '--base-url' in source
    assert '--token' in source
