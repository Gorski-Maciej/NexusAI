from pathlib import Path


def test_security_workflow_uses_python_scan_script() -> None:
    source = Path('.github/workflows/security-ci.yml').read_text(encoding='utf-8')
    assert 'actions/setup-python@v5' in source
    assert 'python -m nexus_ai.scripts.security_scan' in source


def test_performance_workflow_uses_locust_runner() -> None:
    """SUPERMOC: Sprawdź czy CI używa locust zamiast k6."""
    source = Path('.github/workflows/performance-locust.yml').read_text(encoding='utf-8')
    assert 'python -m nexus_ai.scripts.performance_engineering' in source
    assert '--base-url' in source
    assert '--vus' in source
    assert '--duration' in source
    assert 'locust' in source


def test_performance_workflow_no_k6_references() -> None:
    """SUPERMOC: Upewnij się że nie ma już k6 w CI."""
    # Sprawdź czy stary plik k6 został usunięty
    old_k6 = Path('.github/workflows/performance-k6.yml')
    assert not old_k6.exists(), "Old k6 workflow still exists! Remove it."
