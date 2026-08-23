#!/usr/bin/env python3
"""P13 CEIDG deadline tracker."""
from __future__ import annotations

import argparse
import json
from datetime import date, timedelta

DEADLINES = {"DATA_CHANGE": 7, "REGISTRATION": 7, "SUSPENSION": 30, "RESUMPTION": 7}


def track_deadline(
    change_date: date,
    as_of: date | None = None,
    obligation_type: str = "DATA_CHANGE",
    deadline_days: int | None = None,
) -> dict:
    """Track a CEIDG notice deadline using calendar days."""
    kind = obligation_type.upper()
    days = deadline_days if deadline_days is not None else DEADLINES.get(kind)
    if days is None or days < 0:
        raise ValueError(f"unsupported obligation_type: {obligation_type}")
    today = as_of or date.today()
    due = change_date + timedelta(days=days)
    remaining = (due - today).days
    status = "OVERDUE" if remaining < 0 else "WARNING" if remaining <= 3 else "OK"
    return {
        "obligation_type": kind,
        "change_date": change_date.isoformat(),
        "deadline_days": days,
        "due_date": due.isoformat(),
        "as_of": today.isoformat(),
        "days_remaining": remaining,
        "status": status,
        "sanction_note": "brak aktualizacji może skutkować grzywną do 5 000 PLN",
        "legal_basis": "ustawa o CEIDG art. 12 i art. 56",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("change_date", nargs="?", default=date.today().isoformat())
    parser.add_argument("--type", default="DATA_CHANGE", choices=sorted(DEADLINES))
    args = parser.parse_args()
    print(json.dumps(track_deadline(date.fromisoformat(args.change_date), obligation_type=args.type), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
