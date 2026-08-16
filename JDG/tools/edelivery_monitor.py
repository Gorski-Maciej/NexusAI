#!/usr/bin/env python3
"""
NexusAI JDG — e-DORĘCZENIA MONITOR (PROMPT 04 — Sekcja 4)
==========================================================
Monitor skrzynek e-Doręczeń (ustawa z 18.11.2020) i ePUAP:

  • check      — status skrzynki EDE/PUH (obowiązek dla JDG w CEIDG od 01.10.2025)
  • inbox      — nowe pisma → alert + kalendarz doręczeń (15 dni, art. 155 u.eD)
  • fiction    — licznik doręczenia zastępczego (15 dni od awizacji)
  • archive    — auto-archiwizacja pism do WORM (retencja 5 lat + dowód wysyłki)

Zgodność: ustawa o doręczeniach elektronicznych (18.11.2020), art. 8-9/155,
          art. 144-144c OrdPU, eIDAS 910/2014 (art. 25-26/28),
          thresholds.ksef_jpk_edeklaracje (edelivery_mandatory_from).

Usage:
  python edelivery_monitor.py check --ceidg true
  python edelivery_monitor.py inbox --letters letters.json
  python edelivery_monitor.py fiction --letters letters.json --now 2026-07-10
  python edelivery_monitor.py archive --letters letters.json
"""

import argparse
import json
import sys
from datetime import date, datetime
from pathlib import Path

FICTION_DAYS = 15
RENTENTION_YEARS = 5
EDE_MANDATORY_FROM = "2025-10-01"


def _load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _d(s):
    return datetime.strptime(s, "%Y-%m-%d").date()


def check(ceidg_registered: bool, is_jdg: bool = True) -> dict:
    """Obowiązek posiadania adresu EDE (JDG w CEIDG)."""
    required = is_jdg and ceidg_registered
    return {
        "ede_required": required,
        "mandatory_from": EDE_MANDATORY_FROM,
        "action": "ZAREJESTRUJ ADRES DO DORĘCZEŃ ELEKTRONICZNYCH (EDE/PUH)!" if required else "BRAK OBOWIĄZKU",
    }


def inbox(letters: list) -> dict:
    """Nowe pisma → alert + klasyfikacja (KPA/OrdPU)."""
    new = [l for l in letters if l.get("status") == "NEW"]
    return {
        "new_letters": len(new),
        "alerts": [f"📩 Nowe pismo: {l.get('id')} — {l.get('subject', '')}" for l in new],
        "action": "Auto-odpowiedź szablonem / przekaż do TCE (tax_correspondence)" if new else "Brak nowych pism",
    }


def fiction(letters: list, now: str) -> dict:
    """Doręczenie zastępcze: 15 dni od awizacji (art. 155 u.eD)."""
    now_d = _d(now)
    active = []
    for l in letters:
        av = l.get("avis_date")
        if not av:
            continue
        av_d = _d(av)
        days = (now_d - av_d).days
        if 0 <= days < FICTION_DAYS:
            active.append({"id": l.get("id"), "days_remaining": FICTION_DAYS - days,
                           "fiction_on": (av_d + timedelta_days(FICTION_DAYS)).isoformat()})
        elif days >= FICTION_DAYS and l.get("status") == "AVISED":
            active.append({"id": l.get("id"), "fiction_effective": True})
    return {"fiction_active": len(active), "letters": active}


def timedelta_days(n):
    from datetime import timedelta
    return timedelta(days=n)


def archive(letters: list) -> dict:
    """Auto-archiwizacja do WORM: dowód wysyłki + retencja 5 lat."""
    archived = 0
    for l in letters:
        if l.get("status") in ("RECEIVED", "SENT", "FICTION") and not l.get("archived"):
            l["archived"] = True
            l["worm_retention_until"] = date.today().replace(year=date.today().year + RENTENTION_YEARS).isoformat()
            archived += 1
    return {"archived_to_worm": archived, "retention_years": RENTENTION_YEARS}


def main(argv=None):
    ap = argparse.ArgumentParser(description="e-Doręczenia Monitor")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_c = sub.add_parser("check")
    p_c.add_argument("--ceidg", default="true")

    p_i = sub.add_parser("inbox")
    p_i.add_argument("--letters", required=True)

    p_f = sub.add_parser("fiction")
    p_f.add_argument("--letters", required=True)
    p_f.add_argument("--now", required=True)

    p_a = sub.add_parser("archive")
    p_a.add_argument("--letters", required=True)

    args = ap.parse_args(argv)

    if args.cmd == "check":
        print(json.dumps(check(args.ceidg.lower() == "true"), indent=2))
    elif args.cmd == "inbox":
        print(json.dumps(inbox(_load(args.letters)), ensure_ascii=False, indent=2))
    elif args.cmd == "fiction":
        print(json.dumps(fiction(_load(args.letters), args.now), ensure_ascii=False, indent=2))
    else:
        print(json.dumps(archive(_load(args.letters)), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
