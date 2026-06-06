from pathlib import Path


def test_system_integrity_controller_registered_and_guarded() -> None:
    app_source = Path('Code/api/app.py').read_text(encoding='utf-8')
    route_source = Path('Code/api/routes/system_integrity.py').read_text(encoding='utf-8')
    assert 'SystemIntegrityController' in app_source
    assert 'path = "/api/v1/system/integrity"' in route_source
    assert 'guards = [owner_only_guard]' in route_source
    assert '@get("/migration")' in route_source
