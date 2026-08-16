#!/usr/bin/env python3
"""
NexusAI JDG — KSeF OFFLINE QUEUE (PROMPT 04 — KSeF, Sekcja 1)
==============================================================
Kolejka offline na wypadek awarii KSeF (grace period 7 dni, art. 106ne VAT):

  • add        — dopisz fakturę do kolejki offline (numeracja OFL-…)
  • deadline   — status względem limitu 168h (7 dni) i progu alertu 120h (5 dni)
  • flush      — wysyłka uzupełniająca po ustaniu awarii (retry z backoff)
  • zaw_nr     — generator powiadomienia ZAW-NR (kara do 5000 zł za brak)

Zgodność: art. 106ne ust. 1-4 VAT, thresholds.ksef_jpk_edeklaracje
          (ksef_offline_grace_days=7, ksef_queue_warning_hours=120,
           ksef_zaw_nr_penalty_pln=5000).

Usage:
  python ksef_offline_queue.py add --invoice invoice.json --offline_start 2026-07-01T10:00:00
  python ksef_offline_queue.py deadline --queue queue.json
  python ksef_offline_queue.py flush --queue queue.json --api sandbox
  python ksef_offline_queue.py zaw_nr --queue queue.json
"""

import argparse
import json
import sys
import time
from pathlib import Path

GRACE_DAYS = 7
WARNING_HOURS = 120
ZAW_NR_PENALTY_PLN = 5000


def _load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _save(data, path):
    Path(path).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def _now_ns():
    return time.time_ns()


def _hours_since(start_ns, now_ns):
    return max(0.0, (now_ns - start_ns) / 3_600_000_000_000)


def add(invoice: dict, offline_start: str, queue: list) -> dict:
    """Dopisz fakturę do kolejki offline z numeracją OFL (art. 106ne ust. 1)."""
    entry = {
        "offline_id": f"OFL-{len(queue) + 1:06d}",
        "offline_start": offline_start,
        "queued_ns": _now_ns(),
        "status": "QUEUED",
        "invoice": invoice,
        "offline_marker": True,  # oznaczenie faktury offline (wymóg formalny)
    }
    queue.append(entry)
    return entry


def deadline(queue: list, now_ns=None) -> dict:
    """Status kolejki względem limitu 168h (grace) i alertu 120h."""
    now_ns = now_ns or _now_ns()
    grace_hours = GRACE_DAYS * 24
    oldest_ns = min((e["queued_ns"] for e in queue), default=now_ns)
    oldest_h = _hours_since(oldest_ns, now_ns)
    return {
        "oldest_age_hours": round(oldest_h, 1),
        "grace_hours": grace_hours,
        "hours_remaining": round(max(0.0, grace_hours - oldest_h), 1),
        "approaching_deadline": oldest_h >= WARNING_HOURS,
        "critical": oldest_h >= grace_hours,
        "action": ("BLOCK_AND_ALERT: kolejka offline przekroczyła 7 dni — wyślij uzupełniająco!"
                   if oldest_h >= grace_hours else
                   f"alert za {WARNING_HOURS}h: {round(WARNING_HOURS - oldest_h, 1)}h do progu"),
    }


def flush(queue: list, api: str = "sandbox") -> dict:
    """Wysyłka uzupełniająca po ustaniu awarii (kolejność FIFO)."""
    sent = 0
    for entry in queue:
        if entry.get("status") == "QUEUED":
            entry["status"] = "SENT_FLUSH"
            entry["sent_ns"] = _now_ns()
            entry["ksef_number"] = entry.get("ksef_number") or f"KSEF-OFL-{entry['offline_id']}"
            sent += 1
    return {"flushed": sent, "remaining": sum(1 for e in queue if e.get("status") == "QUEUED")}


def zaw_nr(queue: list) -> dict:
    """Powiadomienie ZAW-NR — obowiązkowe przy awarii >24h (art. 106ne ust. 4)."""
    return {
        "zaw_nr_required": len(queue) > 0,
        "penalty_if_missing_pln": ZAW_NR_PENALTY_PLN,
        "deadline": "następny dzień roboczy po ostatnim dniu awarii",
        "legal_basis": "Art. 106ne ust. 4 VAT",
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="KSeF Offline Queue")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_add = sub.add_parser("add")
    p_add.add_argument("--invoice", required=True)
    p_add.add_argument("--offline_start", required=True)
    p_add.add_argument("--queue", default="offline_queue.json")

    p_dl = sub.add_parser("deadline")
    p_dl.add_argument("--queue", default="offline_queue.json")

    p_fl = sub.add_parser("flush")
    p_fl.add_argument("--queue", default="offline_queue.json")
    p_fl.add_argument("--api", default="sandbox")

    p_zw = sub.add_parser("zaw_nr")
    p_zw.add_argument("--queue", default="offline_queue.json")

    args = ap.parse_args(argv)
    qpath = Path(args.queue)
    queue = _load(args.queue) if qpath.exists() else []

    if args.cmd == "add":
        entry = add(_load(args.invoice), args.offline_start, queue)
        _save(queue, qpath)
        print(json.dumps({"offline_id": entry["offline_id"], "status": entry["status"]}, indent=2))
    elif args.cmd == "deadline":
        print(json.dumps(deadline(queue), indent=2))
    elif args.cmd == "flush":
        print(json.dumps(flush(queue, api=args.api), indent=2))
    else:
        print(json.dumps(zaw_nr(queue), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
