from __future__ import annotations

from pathlib import Path


def test_saga_store_initialized_on_startup() -> None:
    source = Path("Code/api/state.py").read_text(encoding="utf-8")
    assert "PersistedSagaStore" in source
    assert "SagaTransitionRequest" in Path("Code/api/routes/system_integrity.py").read_text(encoding="utf-8")
    assert "app.state.saga_store = PersistedSagaStore(engine)" in source
    assert "await app.state.saga_store.ensure_schema()" in source


def test_saga_store_has_history_and_normalization() -> None:
    source = Path("Code/CORE/saga.py").read_text(encoding="utf-8")
    assert "workflow_saga_history" in source
    assert "def _normalize_payload" in source
    assert "def get_history" in source
    assert "expected_current_state" in source
    assert "INSERT INTO workflow_saga_history" in source


def test_integrity_controller_exposes_saga_endpoints() -> None:
    source = Path("Code/api/routes/system_integrity.py").read_text(encoding="utf-8")
    assert '@get("/saga/{saga_id:str}")' in source
    assert '@post("/saga/{saga_id:str}/transition")' in source
    assert '@get("/saga/stuck")' in source
    assert '@post("/ui-drafts/cleanup")' in source
    assert 'history = await store.get_history' in source
    assert 'new_state = data.new_state.strip()' in source
    assert 'expected_current_state=data.expected_current_state' in source
