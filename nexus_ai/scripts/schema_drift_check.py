"""Schema drift checker between two SQLite snapshots (pre/post migration)."""

from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path


def load_schema(db_path: Path) -> dict[str, set[str]]:
    schema: dict[str, set[str]] = {}
    with sqlite3.connect(db_path) as conn:
        tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
        for (table_name,) in tables:
            if table_name.startswith("sqlite_"):
                continue
            cols = conn.execute(f"PRAGMA table_info({table_name})").fetchall()
            schema[table_name] = {str(c[1]) for c in cols}
    return schema


def main() -> int:
    parser = argparse.ArgumentParser(description="Detect schema drift between SQLite snapshots.")
    parser.add_argument("--expected", required=True)
    parser.add_argument("--actual", required=True)
    args = parser.parse_args()

    expected = load_schema(Path(args.expected))
    actual = load_schema(Path(args.actual))

    issues: list[str] = []
    for table, exp_cols in expected.items():
        act_cols = actual.get(table)
        if act_cols is None:
            issues.append(f"missing table: {table}")
            continue
        missing = exp_cols - act_cols
        extra = act_cols - exp_cols
        if missing:
            issues.append(f"{table}: missing columns={sorted(missing)}")
        if extra:
            issues.append(f"{table}: extra columns={sorted(extra)}")

    if issues:
        print("[schema-drift] FAILED")
        for issue in issues:
            print("-", issue)
        return 1

    print("[schema-drift] OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
