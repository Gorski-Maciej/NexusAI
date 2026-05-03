from __future__ import annotations

import json
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine


async def run_migration_sanity_checks(engine: AsyncEngine) -> dict[str, int]:
    """
    Lightweight post-migration sanity checks.
    Returns key counters useful for alerting / observability.
    """
    async with engine.connect() as conn:
        invoices_count = int((await conn.execute(text("SELECT COUNT(*) FROM invoices"))).scalar_one())
        outbox_count = int((await conn.execute(text("SELECT COUNT(*) FROM outbox_events"))).scalar_one())
        users_count = int((await conn.execute(text("SELECT COUNT(*) FROM users"))).scalar_one())
    return {
        "invoices_count": invoices_count,
        "outbox_count": outbox_count,
        "users_count": users_count,
    }


async def capture_runtime_schema(engine: AsyncEngine) -> dict[str, list[str]]:
    schema: dict[str, list[str]] = {}
    async with engine.connect() as conn:
        tables = (await conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))).fetchall()
        for (table_name,) in tables:
            if str(table_name).startswith("sqlite_"):
                continue
            cols = (await conn.execute(text(f"PRAGMA table_info({table_name})"))).fetchall()
            schema[str(table_name)] = sorted(str(c[1]) for c in cols)
    return schema


async def verify_schema_drift(engine: AsyncEngine, baseline_path: Path) -> dict[str, object]:
    current = await capture_runtime_schema(engine)
    baseline_path.parent.mkdir(parents=True, exist_ok=True)
    if not baseline_path.exists():
        baseline_path.write_text(json.dumps(current, ensure_ascii=False, indent=2), encoding="utf-8")
        return {"status": "baseline_created", "tables": len(current), "issues": []}

    baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
    issues: list[str] = []
    for table, expected_cols in baseline.items():
        actual_cols = current.get(table)
        if actual_cols is None:
            issues.append(f"missing table: {table}")
            continue
        missing = sorted(set(expected_cols) - set(actual_cols))
        extra = sorted(set(actual_cols) - set(expected_cols))
        if missing:
            issues.append(f"{table}: missing columns={missing}")
        if extra:
            issues.append(f"{table}: extra columns={extra}")

    status = "ok" if not issues else "drift_detected"
    return {"status": status, "tables": len(current), "issues": issues}
