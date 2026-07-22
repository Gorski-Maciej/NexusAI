from pathlib import Path


def test_finops_cost_endpoint_registered_and_guarded() -> None:
    app_source = Path('nexus_ai/api/app.py').read_text(encoding='utf-8')
    route_source = Path('nexus_ai/api/routes/finops.py').read_text(encoding='utf-8')
    assert 'FinOpsController' in app_source
    assert 'path = "/api/v1/system/finops"' in route_source
    assert '@get("/cost-per-invoice")' in route_source
    assert 'guards = [owner_only_guard]' in route_source
