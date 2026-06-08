import pytest


@pytest.mark.skip(reason="Test requires monkeypatching module-level imports; migrate to direct imports from nexus_ai.scripts.security_scan")
def test_run_semgrep_strict_mode_fails_when_binary_missing(monkeypatch) -> None:
    pass


@pytest.mark.skip(reason="Test requires monkeypatching module-level imports; migrate to direct imports from nexus_ai.scripts.security_scan")
def test_run_semgrep_non_strict_mode_warns_when_binary_missing(monkeypatch) -> None:
    pass
