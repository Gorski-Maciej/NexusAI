from __future__ import annotations

import asyncio
import importlib.util
import sys
from pathlib import Path

from sqlalchemy.ext.asyncio import create_async_engine


def _load_store_class():
    root = Path(__file__).resolve().parents[1]
    module_path = root / "Code" / "CORE" / "saga.py"
    spec = importlib.util.spec_from_file_location("core_saga", module_path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module.PersistedSagaStore


def test_persisted_saga_store_runtime(tmp_path: Path) -> None:
    PersistedSagaStore = _load_store_class()

    async def scenario() -> None:
        db_path = tmp_path / "saga_runtime.db"
        engine = create_async_engine(f"sqlite+aiosqlite:///{db_path}")
        try:
            store = PersistedSagaStore(engine)
            await store.ensure_schema()

            created = await store.transition("inv-1", "uploaded", {"tenant_id": "t1"})
            assert created.saga_id == "inv-1"
            assert created.state == "uploaded"
            assert created.payload["tenant_id"] == "t1"

            updated = await store.transition("inv-1", "processing", '{"step": 2}')
            assert updated.state == "processing"
            assert updated.payload["step"] == 2

            current = await store.get("inv-1")
            assert current is not None
            assert current.state == "processing"
            assert current.payload["step"] == 2

            history = await store.get_history("inv-1")
            assert len(history) >= 2

            try:
                await store.transition("inv-1", "approved", {"ok": True}, expected_current_state="uploaded")
                assert False, "expected conflict"
            except ValueError as exc:
                assert "state_conflict" in str(exc)

            async with engine.begin() as conn:
                await conn.execute(__import__("sqlalchemy").text("UPDATE workflow_saga_state SET updated_at = datetime('now', '-180 minutes') WHERE saga_id = :id"), {"id": "inv-1"})
            stuck = await store.list_stuck(older_than_minutes=120)
            assert any(item.saga_id == "inv-1" for item in stuck)
        finally:
            await engine.dispose()

    asyncio.run(scenario())
