from pathlib import Path


def test_privacy_pii_scan_endpoint_registered_and_guarded() -> None:
    app_source = Path('nexus_ai/api/app.py').read_text(encoding='utf-8')
    route_source = Path('nexus_ai/api/routes/privacy.py').read_text(encoding='utf-8')
    assert 'PrivacyController' in app_source
    assert 'path = "/api/v1/system/privacy"' in route_source
    assert '@get("/pii-scan")' in route_source
    assert 'guards = [owner_only_guard]' in route_source
