from pathlib import Path


def test_security_posture_endpoint_registered_and_guarded() -> None:
    app_source = Path('Code/api/app.py').read_text(encoding='utf-8')
    route_source = Path('Code/api/routes/security_posture.py').read_text(encoding='utf-8')
    assert 'SecurityPostureController' in app_source
    assert 'path = "/api/v1/system/security"' in route_source
    assert '@get("/summary")' in route_source
    assert 'guards = [owner_only_guard]' in route_source
