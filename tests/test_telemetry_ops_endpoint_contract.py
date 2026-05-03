from pathlib import Path


def test_telemetry_ops_endpoints_registered_and_guarded() -> None:
    app_source = Path('Code/API/app.py').read_text(encoding='utf-8')
    route_source = Path('Code/API/routes/telemetry_ops.py').read_text(encoding='utf-8')
    assert 'TelemetryOpsController' in app_source
    assert 'path = "/api/v1/system/telemetry"' in route_source
    assert '@get("/fallback-status")' in route_source
    assert '@post("/fallback-replay")' in route_source
    assert 'guards = [owner_only_guard]' in route_source
