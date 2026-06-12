"""Replay dead-letter outbox events back to FAILED status for reprocessing."""

from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Replay dead-letter outbox events.")
    parser.add_argument("--db", default="nexus_oltp.db")
    parser.add_argument("--limit", type=int, default=100)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--status-from", default="DEAD_LETTER", help="Source status to replay from")
    parser.add_argument("--status-to", default="FAILED", help="Target status after replay")
    parser.add_argument("--event-type", help="Optional event_type filter")
    parser.add_argument(
        "--ids-file", help="Optional file with outbox ids (one per line) to replay explicitly"
    )
    args = parser.parse_args()

    db_path = Path(args.db)
    if not db_path.exists():
        print(f"[outbox-replay] database not found: {db_path}")
        return 1

    with sqlite3.connect(db_path) as conn:
        if args.ids_file:
            ids = [
                line.strip()
                for line in Path(args.ids_file).read_text(encoding="utf-8").splitlines()
                if line.strip()
            ]
            ids = ids[: args.limit]
        else:
            query = """
                SELECT id FROM outbox_events
                WHERE status = ?
            """
            params: list[object] = [args.status_from]
            if args.event_type:
                query += " AND event_type = ?"
                params.append(args.event_type)
            query += " ORDER BY created_at ASC LIMIT ?"
            params.append(args.limit)
            rows = conn.execute(query, tuple(params)).fetchall()
            ids = [r[0] for r in rows]
        if not ids:
            print("[outbox-replay] no dead-letter events")
            return 0

        if args.dry_run:
            print(
                f"[outbox-replay] dry-run: would move {len(ids)} events to {args.status_to} (from status={args.status_from})"
            )
            return 0

        conn.executemany(
            "UPDATE outbox_events SET status=?, retry_count=0 WHERE id = ?",
            [(args.status_to, i) for i in ids],
        )
        conn.commit()

    print(f"[outbox-replay] moved {len(ids)} events to {args.status_to} for retry")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
