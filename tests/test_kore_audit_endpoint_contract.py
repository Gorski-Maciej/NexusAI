from pathlib import Path


def test_kore_audit_controller_is_registered() -> None:
    source = Path('Code/API/app.py').read_text(encoding='utf-8')
    assert 'KoreAuditController' in source
    assert '/api/v1/system/kore' in Path('Code/API/routes/kore_audit.py').read_text(encoding='utf-8')


def test_kore_audit_is_owner_guarded() -> None:
    source = Path('Code/API/routes/kore_audit.py').read_text(encoding='utf-8')
    assert 'guards = [owner_only_guard]' in source
    assert '@get("/audit")' in source
