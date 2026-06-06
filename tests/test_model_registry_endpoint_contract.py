from pathlib import Path


def test_model_registry_endpoints_registered_and_guarded() -> None:
    app_source = Path('Code/api/app.py').read_text(encoding='utf-8')
    route_source = Path('Code/api/routes/model_registry.py').read_text(encoding='utf-8')
    assert 'ModelRegistryController' in app_source
    assert 'path = "/api/v1/system/models"' in route_source
    assert '@get("/retention-status")' in route_source
    assert '@post("/retention-prune")' in route_source
    assert 'guards = [owner_only_guard]' in route_source
