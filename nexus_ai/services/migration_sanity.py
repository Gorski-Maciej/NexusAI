from __future__ import annotations

from pathlib import Path

from sqlalchemy import Engine, text

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads


def _quote_ident(identifier: str) -> str:
    return "\"" + identifier.replace("\"", "\"\"") + "\""

def run_migration_sanity_checks(engine: Engine) -> dict[str, int]:
    """
    Lightweight post-migration sanity checks.
    Returns key counters useful for alerting / observability.
    """
    with engine.connect() as conn:
        invoices_count = int(conn.execute(text("SELECT COUNT(*) FROM invoices")).scalar_one())
        outbox_count = int(conn.execute(text("SELECT COUNT(*) FROM outbox_events")).scalar_one())
        users_count = int(conn.execute(text("SELECT COUNT(*) FROM users")).scalar_one())
    return {
        "invoices_count": invoices_count,
        "outbox_count": outbox_count,
        "users_count": users_count,
    }


def capture_runtime_schema(engine: Engine) -> dict[str, list[str]]:
    schema: dict[str, list[str]] = {}
    with engine.connect() as conn:
        tables = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'")).fetchall()
        for (table_name,) in tables:
            if str(table_name).startswith("sqlite_"):
                continue
            table_quoted = _quote_ident(str(table_name))
            cols = conn.execute(text(f"PRAGMA table_info({table_quoted})")).fetchall()
            schema[str(table_name)] = sorted(str(c[1]) for c in cols)
    return schema


def verify_schema_drift(engine: Engine, baseline_path: Path) -> dict[str, object]:
    current = capture_runtime_schema(engine)
    baseline_path.parent.mkdir(parents=True, exist_ok=True)
    if not baseline_path.exists():
        baseline_path.write_text(msgspec_dumps(current, ensure_ascii=False, indent=2), encoding="utf-8")
        return {"status": "baseline_created", "tables": len(current), "issues": []}

    baseline = msgspec_loads(baseline_path.read_bytes())
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


def capture_table_row_counts(engine: Engine) -> dict[str, int]:
    counts: dict[str, int] = {}
    with engine.connect() as conn:
        tables = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'")).fetchall()
        for (table_name,) in tables:
            table = str(table_name)
            if table.startswith("sqlite_"):
                continue
            table_quoted = _quote_ident(table)
            value = conn.execute(text(f"SELECT COUNT(*) FROM {table_quoted}")).scalar_one()
            counts[table] = int(value)
    return counts


def verify_migration_integrity(engine: Engine, baseline_path: Path) -> dict[str, object]:
    """Verify post-migration row-count integrity against a persisted baseline snapshot."""
    current = capture_table_row_counts(engine)
    baseline_path.parent.mkdir(parents=True, exist_ok=True)
    if not baseline_path.exists():
        baseline_path.write_text(msgspec_dumps(current, ensure_ascii=False, indent=2), encoding="utf-8")
        return {"status": "baseline_created", "issues": [], "tables": len(current)}

    baseline = msgspec_loads(baseline_path.read_bytes())
    issues: list[str] = []
    for table, expected in baseline.items():
        actual = current.get(table)
        if actual is None:
            issues.append(f"missing table: {table}")
            continue
        if int(actual) < int(expected):
            issues.append(f"row_count_drop: {table} expected>={expected} actual={actual}")

    status = "ok" if not issues else "integrity_warning"
    return {"status": status, "issues": issues, "tables": len(current)}


def capture_table_checksums(engine: Engine, tables: list[str] | None = None) -> dict[str, str]:
    checksums: dict[str, str] = {}
    with engine.connect() as conn:
        if tables is None:
            table_rows = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'")).fetchall()
            tables = [str(t[0]) for t in table_rows if not str(t[0]).startswith("sqlite_")]
        for table in tables:
            table_quoted = _quote_ident(table)
            rows = conn.execute(text(f"SELECT * FROM {table_quoted}")).fetchall()
            digest = __import__("hashlib").sha256()
            for row in rows:
                digest.update(repr(tuple(row)).encode("utf-8"))
            checksums[table] = digest.hexdigest()
    return checksums


def verify_migration_checksums(engine: Engine, baseline_path: Path, tables: list[str] | None = None) -> dict[str, object]:
    current = capture_table_checksums(engine, tables=tables)
    baseline_path.parent.mkdir(parents=True, exist_ok=True)
    if not baseline_path.exists():
        baseline_path.write_text(msgspec_dumps(current, ensure_ascii=False, indent=2), encoding="utf-8")
        return {"status": "baseline_created", "issues": [], "tables": len(current)}

    baseline = msgspec_loads(baseline_path.read_bytes())
    issues: list[str] = []
    for table, expected in baseline.items():
        actual = current.get(table)
        if actual is None:
            issues.append(f"missing table: {table}")
            continue
        if actual != expected:
            issues.append(f"checksum_drift: {table}")

    status = "ok" if not issues else "integrity_warning"
    return {"status": status, "issues": issues, "tables": len(current)}
