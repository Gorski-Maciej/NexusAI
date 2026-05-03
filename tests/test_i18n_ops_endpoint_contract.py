from pathlib import Path


def test_i18n_ops_endpoint_registered_and_guarded() -> None:
    app_source = Path('Code/API/app.py').read_text(encoding='utf-8')
    route_source = Path('Code/API/routes/i18n_ops.py').read_text(encoding='utf-8')
    assert 'I18nOpsController' in app_source
    assert 'path = "/api/v1/system/i18n"' in route_source
    assert '@get("/status")' in route_source
    assert 'guards = [owner_only_guard]' in route_source
