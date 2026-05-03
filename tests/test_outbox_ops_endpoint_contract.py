from pathlib import Path


def test_outbox_ops_endpoints_registered_and_guarded() -> None:
    app_source = Path('Code/API/app.py').read_text(encoding='utf-8')
    route_source = Path('Code/API/routes/outbox_ops.py').read_text(encoding='utf-8')
    assert 'OutboxOpsController' in app_source
    assert 'path = "/api/v1/system/outbox"' in route_source
    assert '@get("/stats")' in route_source
    assert '@post("/replay-dead-letter")' in route_source
    assert 'guards = [owner_only_guard]' in route_source
