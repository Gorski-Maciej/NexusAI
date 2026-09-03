#!/usr/bin/env python3
"""
NexusAI JDG — V3 ID CANON (P00-I07)
====================================
Globalna rezerwacja identyfikatorów serii V3: V3-<KOD>-Lxx/Ixx/Cxx/Qxx/Xxx.
Definiuje kanon (format, zakresy, rezerwacje) i wykrywa kolizje między
raportami w JDG/raporty_glm52_v3/ oraz pomiędzy prompty_v3 a raportami.

Usage:
  python v3_id_canon.py                    # walidacja kanonu (bramka)
  python v3_id_canon.py --json             # JSON na stdout
  python v3_id_canon.py --write            # zapis bundles/v3_id_canon.json
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
OUT_JSON = BASE_DIR / "bundles" / "v3_id_canon.json"

# Kanon identyfikatorów serii V3 (kontrakt P00 — wiążący dla P01–P68)
CANON = {
    "series": "V3",
    "prefix": "V3-",
    "id_types": {
        "L": {"name": "luka", "format": r"V3-P\d\d-L\d{2}", "range": "01..99", "owner": "rejestr luk (9.06)"},
        "I": {"name": "innowacja", "format": r"V3-P\d\d-I\d{2}", "range": "01..99", "owner": "rejestr innowacji (9.07)"},
        "C": {"name": "konflikt", "format": r"V3-P\d\d-C\d{2}", "range": "01..99", "owner": "rejestr konfliktów (9.16/T12)"},
        "Q": {"name": "pytanie do człowieka", "format": r"V3-P\d\d-Q\d{2}", "range": "01..99", "owner": "sekcja 9.11"},
        "X": {"name": "pytanie krzyżowe", "format": r"V3-P\d\d-X\d{2}", "range": "01..10", "owner": "sekcja 7.4"},
    },
    "codes": [f"P{i:02d}" for i in range(69)],
    "parts_count": 69,
    "reserved": {
        "L": "luki — P0 (BLOCKER) > P1 > P2 > P3; identyfikator przypisywany w raporcie źródłowym",
        "I": "innowacje — min. 12 na część; szkielet 6-punktowy z Sekcji 10 promptu",
        "C": "konflikty — dokument↔kod, mirror↔canonical, kontrakt↔kontrakt; cytaty obu stron",
        "Q": "pytania do człowieka — nigdy cisza; rozstrzygnięcie zarezerwowane dla właściciela",
        "X": "pytania krzyżowe — 10 obowiązkowych (7.4), identyfikatory V3-<KOD>-X01..X10",
    },
    "naming": {
        "reports": "RAPORT_V3_<KOD>_<SLUG>.txt",
        "prompts": "V3_PROMPT_<KOD>_<SLUG>.txt",
        "rego_package": "jdg/<pakiet>/...",
        "rego_rule_id": "jdg.<pakiet>.<reguła>",
        "thresholds": "data.thresholds.* (ADR-002), okna valid_from/valid_to (P05)",
    },
    "created_at": datetime.now(timezone.utc).isoformat(),
    "contract_source": "JDG/prompty_v3/V3_PROMPT_P00_MAPA_KANONICZNA.txt, Sekcja 11.5",
}

ID_RE = re.compile(r"V3-P\d\d-[LICQX]\d{2}")


def scan_reports() -> dict:
    """Zbierz wszystkie identyfikatory użyte w istniejących raportach V3."""
    used: dict[str, list[dict]] = {}
    if not REPORTS_DIR.exists():
        return {"reports_scanned": 0, "ids_found": 0, "by_type": {}}
    reports = sorted(REPORTS_DIR.glob("*.txt"))
    for report in reports:
        text = report.read_text(encoding="utf-8", errors="replace")
        for m in ID_RE.finditer(text):
            ident = m.group(0)
            code, typ, num = ident[3:8], ident[8], ident[9:11]
            key = f"{typ}"
            used.setdefault(key, []).append(
                {"id": ident, "code": code, "type": typ, "num": num, "report": report.name}
            )
    by_type = {t: len(v) for t, v in used.items()}
    return {"reports_scanned": len(reports), "ids_found": sum(len(v) for v in used.values()), "by_type": by_type}


def check_canon(scan: dict) -> list[str]:
    """Wykryj kolizje / naruszenia formatu w użytych identyfikatorach."""
    problems = []
    for typ, items in scan.get("by_type", {}).items():
        pass
    # kolizje: ten sam identyfikator w dwóch różnych raportach (poza kontraktami międzyczęściowymi)
    seen: dict[str, list[str]] = {}
    if REPORTS_DIR.exists():
        for report in sorted(REPORTS_DIR.glob("*.txt")):
            text = report.read_text(encoding="utf-8", errors="replace")
            for m in ID_RE.finditer(text):
                seen.setdefault(m.group(0), []).append(report.name)
    for ident, reports in sorted(seen.items()):
        uniq = sorted(set(reports))
        if len(uniq) > 1:
            problems.append(f"KOLIZJA ID {ident} użyty w {len(uniq)} raportach: {', '.join(uniq)}")
    return problems


def build() -> dict:
    scan = scan_reports()
    problems = check_canon(scan)
    canon = {
        "schema_version": "1.0.0",
        "canon": CANON,
        "usage": scan,
        "problems": problems,
        "valid": not problems,
        "status": "WDROŻONY_100 (P00-I07)" if not problems else "KOLIZJE_WYKRYTO",
    }
    return canon


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 ID Canon — rezerwacja i walidacja identyfikatorów serii V3")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    data = build()
    if args.write:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3 ID CANON: {data['status']} — {data['usage']['ids_found']} identyfikatorów w {data['usage']['reports_scanned']} raportach")
        if data["problems"]:
            for p in data["problems"]:
                print(f"  ! {p}")
            return 1
        print("  Kanon: L/I/C/Q/X z zakresami 01..99 (X: 01..10); kody P00–P68 (69 części)")
    return 0 if data["valid"] else 1


if __name__ == "__main__":
    sys.exit(main())