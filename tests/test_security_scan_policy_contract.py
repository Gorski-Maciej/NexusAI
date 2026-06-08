from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_security_scan_policy_flags_present() -> None:
    source = (PROJECT_ROOT / 'nexus_ai' / 'scripts' / 'security_scan.py').read_text(encoding='utf-8')
    assert '--policy' in source
    assert 'moderate' in source
    assert 'lenient' in source
