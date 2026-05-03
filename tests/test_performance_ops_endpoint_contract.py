from pathlib import Path


def test_performance_ops_endpoint_registered_and_guarded() -> None:
    app_source = Path('Code/API/app.py').read_text(encoding='utf-8')
    route_source = Path('Code/API/routes/performance_ops.py').read_text(encoding='utf-8')
    assert 'PerformanceOpsController' in app_source
    assert 'path = "/api/v1/system/performance"' in route_source
    assert '@get("/k6-summary")' in route_source
    assert 'guards = [owner_only_guard]' in route_source
