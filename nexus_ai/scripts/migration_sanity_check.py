"""Verify row-count integrity before/after migrations on key tables."""

from __future__ import annotations

import argparse
import sqlite3

from nexus_crypto import Sha256Hasher
from msgspec import Struct
from pathlib import Path


class TableStat(Struct):
    name: str
    rows: int
    checksum: str | None = None


def collect_table_stats(
    db_path: Path, tables: list[str], *, with_checksum: bool = False
) -> dict[str, TableStat]:
    with sqlite3.connect(db_path) as conn:
        result: dict[str, TableStat] = {}
        for table in tables:
            rows = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            checksum = None
            if with_checksum:
                checksum = table_checksum(conn, table)
            result[table] = TableStat(name=table, rows=int(rows), checksum=checksum)
        return result


def table_checksum(conn: sqlite3.Connection, table: str) -> str:
    hasher = Sha256Hasher()
    cursor = conn.execute(f"SELECT * FROM {table}")
    for row in cursor:
        hasher.update(repr(row).encode("utf-8"))
    return hasher.hexdigest()


def compare_stats(
    before: dict[str, TableStat], after: dict[str, TableStat], *, compare_checksum: bool = False
) -> list[str]:
    issues: list[str] = []
    for table, b in before.items():
        a = after.get(table)
        if a is None:
            issues.append(f"Missing table after migration: {table}")
            continue
        if a.rows < b.rows:
            issues.append(f"Row count regression in {table}: {b.rows} -> {a.rows}")
        if (
            compare_checksum
            and b.checksum
            and a.checksum
            and b.rows == a.rows
            and b.checksum != a.checksum
        ):
            issues.append(f"Checksum drift in {table}: {b.checksum[:12]} -> {a.checksum[:12]}")
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description="Run migration row-count sanity check.")
    parser.add_argument("--before", required=True, help="Path to DB snapshot before migration")
    parser.add_argument("--after", required=True, help="Path to DB snapshot after migration")
    parser.add_argument(
        "--tables", default="users,invoices,outbox_events", help="Comma-separated table list"
    )
    parser.add_argument(
        "--checksum",
        action="store_true",
        help="Also compare row-content checksum when row counts match",
    )
    args = parser.parse_args()

    tables = [t.strip() for t in args.tables.split(",") if t.strip()]
    before = collect_table_stats(Path(args.before), tables, with_checksum=args.checksum)
    after = collect_table_stats(Path(args.after), tables, with_checksum=args.checksum)
    issues = compare_stats(before, after, compare_checksum=args.checksum)

    if issues:
        print("[migration-sanity] FAILED")
        for issue in issues:
            print(" -", issue)
        return 1

    print("[migration-sanity] OK")
    for name in tables:
        print(f" - {name}: {before[name].rows} -> {after[name].rows}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
