from pathlib import Path


def test_security_scan_policy_flags_present() -> None:
    source = Path('Code/SKRIPTS/security_scan.py').read_text(encoding='utf-8')
    assert '--policy' in source
    assert 'moderate' in source
    assert 'lenient' in source
