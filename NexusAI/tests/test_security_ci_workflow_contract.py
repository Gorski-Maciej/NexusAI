from pathlib import Path


def test_security_ci_uses_strict_policy_thresholds() -> None:
    source = Path('.github/workflows/security-ci.yml').read_text(encoding='utf-8')
    assert '--policy strict' in source
    assert '--max-zap-high 0' in source
    assert '--max-zap-medium 0' in source
