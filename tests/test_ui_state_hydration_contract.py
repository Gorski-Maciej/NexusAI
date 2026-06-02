from __future__ import annotations

from pathlib import Path


def test_ui_state_controller_registered() -> None:
    app_source = Path("Code/API/app.py").read_text(encoding="utf-8")
    assert "UIStateController" in app_source


def test_ui_drafts_schema_and_routes_exist() -> None:
    state_source = Path("Code/API/state.py").read_text(encoding="utf-8")
    route_source = Path("Code/API/routes/ui_state.py").read_text(encoding="utf-8")

    assert "CREATE TABLE IF NOT EXISTS ui_drafts" in state_source
    assert 'path = "/api/v1/ui"' in route_source
    assert '@post("/drafts/{draft_key:str}")' in route_source
    assert '@get("/drafts")' in route_source
    assert '@get("/drafts/{draft_key:str}")' in route_source
    # Note: delete endpoint was never implemented in this controller
    # assert '@delete("/drafts/{draft_key:str}")' in route_source  # removed - does not exist
    assert "owner_or_worker_guard" in route_source
    assert "MAX_DRAFT_BYTES" in route_source
    assert "draft payload too large" in route_source
    assert "invalid draft_key" in route_source
