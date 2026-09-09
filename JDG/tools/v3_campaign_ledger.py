#!/usr/bin/env python3
"""
NexusAI JDG — V3 CAMPAIGN LEDGER (P00-I06)
===========================================
Żywy rejestr wszystkich 69 raportów serii V3 (P00–P68): kod, slug, status
(NIE_WDROŻONY / WDROŻONY_100), licznik luk P0/P1, liczba innowacji, data
wdrożenia. Podstawa certyfikacji finalnej (P68) i bramka CI.

Usage:
  python v3_campaign_ledger.py              # podsumowanie kampanii
  python v3_campaign_ledger.py --json       # JSON na stdout
  python v3_campaign_ledger.py --write      # zapis bundles/v3_campaign_ledger.json
  python v3_campaign_ledger.py --mark P00   # oznacz część jako WDROŻONY_100
  python v3_campaign_ledger.py --unmark P00 # cofnij do NIE_WDROŻONY
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
PROMPTS_DIR = BASE_DIR / "prompty_v3"
REPORTS_DIR = BASE_DIR / "raporty_glm52_v3"
OUT_JSON = BASE_DIR / "bundles" / "v3_campaign_ledger.json"

PROMPT_RE = re.compile(r"V3_PROMPT_(P\d\d)_([A-Z0-9_]+)\.txt")
REPORT_RE = re.compile(r"RAPORT_V3_(P\d\d)_([A-Z0-9_]+)\.txt")
STATUS_RE = re.compile(r"Status(?:\s+raportu)?(?:\s+wdrożenia)?:\s*(WDROŻONY_100|NIE_WDROŻONY|W_TRAKCIE)", re.IGNORECASE)


def list_parts() -> list[dict]:
    """Zbuduj listę części z prompty_v3/ (kanon = obecność pliku promptu)."""
    parts = []
    if PROMPTS_DIR.exists():
        for f in sorted(PROMPTS_DIR.glob("V3_PROMPT_P*.txt")):
            m = PROMPT_RE.match(f.name)
            if m:
                parts.append({"code": m.group(1), "slug": m.group(2), "prompt": f.name})
    # uzupełnij kody, których brakuje jako pliku promptu
    existing = {p["code"] for p in parts}
    for i in range(69):
        code = f"P{i:02d}"
        if code not in existing:
            parts.append({"code": code, "slug": "", "prompt": f"V3_PROMPT_{code}_*.txt"})
    return sorted(parts, key=lambda p: p["code"])


def report_status(report_path: Path) -> str:
    """Odczytaj status z nagłówka raportu; brak pliku = NIE_WDROŻONY."""
    if not report_path.exists():
        return "NIE_WDROŻONY"
    text = report_path.read_text(encoding="utf-8", errors="replace")
    m = STATUS_RE.search(text[:2000])
    return m.group(1).upper() if m else "NIE_WDROŻONY"


def load_ledger() -> dict:
    if OUT_JSON.exists():
        try:
            return json.loads(OUT_JSON.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass
    return {"schema_version": "1.0.0", "generated_at": None, "parts": {}}


def build(ledger: dict | None = None) -> dict:
    ledger = ledger or load_ledger()
    parts = list_parts()
    now = datetime.now(timezone.utc).isoformat()
    out: dict = {"schema_version": "1.0.0", "generated_at": now, "parts": {}}
    for p in parts:
        code = p["code"]
        entry = ledger.get("parts", {}).get(code, {})
        report_name = f"RAPORT_V3_{code}_{p['slug']}.txt" if p["slug"] else entry.get("report", "")
        report_path = REPORTS_DIR / report_name if report_name else None
        status = entry.get("status", "NIE_WDROŻONY")
        if entry.get("status") in (None, "") or entry.get("auto_recheck", True):
            status = report_status(report_path) if report_path else "NIE_WDROŻONY"
        out["parts"][code] = {
            "slug": p["slug"] or entry.get("slug", ""),
            "prompt": p["prompt"],
            "report": report_name or entry.get("report", ""),
            "status": status,
            "luki_p0": entry.get("luki_p0", 0),
            "luki_p1": entry.get("luki_p1", 0),
            "luki_p2": entry.get("luki_p2", 0),
            "luki_p3": entry.get("luki_p3", 0),
            "innovations": entry.get("innovations", 0),
            "implemented_at": entry.get("implemented_at"),
            "notes": entry.get("notes", ""),
            # P45-fix: flaga musi być zachowana w wyjściu, inaczej kolejny
            # rebuild resetuje części bez parsowalnego nagłówka raportu
            "auto_recheck": entry.get("auto_recheck", True),
        }
    done = sum(1 for v in out["parts"].values() if v["status"] == "WDROŻONY_100")
    out["summary"] = {
        "total": len(out["parts"]),
        "wdrozony_100": done,
        "nie_wdrozony": len(out["parts"]) - done,
        "progress_pct": round(100 * done / len(out["parts"]), 2),
    }
    return out


def refresh_summary(ledger: dict) -> dict:
    """Przelicz summary bez przebudowy wpisów części (używane po mark/unmark)."""
    parts = ledger.get("parts", {})
    done = sum(1 for v in parts.values() if v.get("status") == "WDROŻONY_100")
    ledger["summary"] = {
        "total": len(parts),
        "wdrozony_100": done,
        "nie_wdrozony": len(parts) - done,
        "progress_pct": round(100 * done / len(parts), 2) if parts else 0.0,
    }
    return ledger


def mark(code: str, ledger: dict, luki_p0: int = 0, luki_p1: int = 0,
         luki_p2: int = 0, luki_p3: int = 0,
         innovations: int = 0, notes: str = "") -> dict:
    if code not in ledger.get("parts", {}) and code not in {p["code"] for p in list_parts()}:
        raise ValueError(f"Nieznany kod części: {code}")
    now = datetime.now(timezone.utc).isoformat()
    parts = ledger.setdefault("parts", {})
    parts[code] = {
        **parts.get(code, {}),
        "status": "WDROŻONY_100",
        "luki_p0": luki_p0,
        "luki_p1": luki_p1,
        "luki_p2": luki_p2,
        "luki_p3": luki_p3,
        "innovations": innovations,
        "implemented_at": now,
        "auto_recheck": False,
    }
    if notes:
        parts[code]["notes"] = notes
    return ledger


def unmark(code: str, ledger: dict) -> dict:
    parts = ledger.get("parts", {})
    if code in parts:
        parts[code]["status"] = "NIE_WDROŻONY"
        parts[code].pop("implemented_at", None)
        parts[code]["auto_recheck"] = True
    return ledger


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 Campaign Ledger — rejestr 69 raportów serii V3")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--mark", metavar="P00")
    parser.add_argument("--unmark", metavar="P00")
    parser.add_argument("--luki-p0", type=int, default=0, help="liczba luk P0 przy --mark")
    parser.add_argument("--luki-p1", type=int, default=0, help="liczba luk P1 przy --mark")
    parser.add_argument("--luki-p2", type=int, default=0, help="liczba luk P2 przy --mark")
    parser.add_argument("--luki-p3", type=int, default=0, help="liczba luk P3 przy --mark")
    parser.add_argument("--innovations", type=int, default=0, help="liczba innowacji przy --mark")
    parser.add_argument("--notes", default="", help="notatka przy --mark")
    args = parser.parse_args()

    ledger = load_ledger()
    if args.mark:
        ledger = refresh_summary(mark(args.mark.upper(), ledger, args.luki_p0, args.luki_p1,
                                      args.luki_p2, args.luki_p3,
                                      args.innovations, args.notes))
        if args.write:
            OUT_JSON.write_text(json.dumps(ledger, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Oznaczono {args.mark.upper()} jako WDROŻONY_100")
        return 0
    if args.unmark:
        ledger = refresh_summary(unmark(args.unmark.upper(), ledger))
        if args.write:
            OUT_JSON.write_text(json.dumps(ledger, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Cofnięto status {args.unmark.upper()} do NIE_WDROŻONY")
        return 0

    data = build(ledger)
    if args.write:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        s = data["summary"]
        print(f"V3 CAMPAIGN LEDGER: {s['wdrozony_100']}/{s['total']} WDROŻONY_100 ({s['progress_pct']}%)")
        for code in sorted(data["parts"]):
            p = data["parts"][code]
            flag = "✅" if p["status"] == "WDROŻONY_100" else "⬜"
            print(f"  {flag} {code} {p['slug'] or '(brak promptu)'}: {p['status']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())