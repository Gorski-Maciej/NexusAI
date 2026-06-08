from __future__ import annotations

import importlib.util
import sys
import types
from pathlib import Path

from sqlalchemy import text
from sqlalchemy import create_engine


def _load_cleanup_helper():
    root = Path(__file__).resolve().parents[1]
    module_path = root / "Code" / "API" / "routes" / "system_integrity.py"
    spec = importlib.util.spec_from_file_location("api_system_integrity", module_path)
    assert spec and spec.loader

    if "api" not in sys.modules:
        sys.modules["api"] = types.ModuleType("api")
    for name in ["api.rbac", "api.schemas", "core.config", "db.database", "services.migration_sanity"]:
        if name not in sys.modules:
            mod = types.ModuleType(name)
            if name == "api.rbac":
                mod.owner_only_guard = lambda *args, **kwargs: None
            if name == "api.schemas":
                class _Req: ...
                mod.SagaTransitionRequest = _Req
            if name == "core.config":
                class _Cfg: ...
                mod.AppConfig = _Cfg
            if name == "db.database":
                mod.create_oltp_engine = lambda *_args, **_kwargs: None
            if name == "services.migration_sanity":
                async def _noop(*_args, **_kwargs): return {}
                mod.run_migration_sanity_checks = _noop
                mod.verify_migration_integrity = _noop
                mod.verify_migration_checksums = _noop
            sys.modules[name] = mod

    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module.cleanup_stale_ui_drafts


def test_cleanup_stale_ui_drafts_runtime(tmp_path: Path) -> None:
    cleanup_stale_ui_drafts = _load_cleanup_helper()

    def scenario() -> None:
        db_path = tmp_path / "cleanup.db"
        engine = create_engine(f"sqlite:///{db_path}")
        try:
            with engine.begin() as conn:
                conn.execute(text("CREATE TABLE ui_drafts (tenant_id TEXT, actor_id TEXT, draft_key TEXT, payload_json TEXT, updated_at TIMESTAMP)"))
                conn.execute(text("INSERT INTO ui_drafts VALUES ('t','u','old','{}', datetime('now', '-10 days'))"))
                conn.execute(text("INSERT INTO ui_drafts VALUES ('t','u','new','{}', datetime('now'))"))

            result = cleanup_stale_ui_drafts(engine, older_than_hours=24)
            assert result["status"] == "ok"
            assert result["deleted"] >= 1
            assert result["remaining"] >= 1
        finally:
            engine.dispose()

    scenario()
