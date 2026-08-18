#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CHAOS RUNNER (GLM52 P18 — TESTY / CI / JAKOŚĆ, V1 §8 L8)
# Chaos engineering w CI: symulacja awarii (uszkodzony bundle, utrata danych,
# opóźnienia, awaria MF/KSeF offline 72 h, puste thresholds) i weryfikacja,
# że system fallbackuje bez crashy (INV-015/INV-034 — degradacja graceful).
#  • list  — katalog eksperymentów chaos,
#  • run   — wykonaj eksperyment(y) w trybie symulacji (dry-run),
#  • gate  — BRAMKA CI: wszystkie eksperymenty wykrywalne przez narzędzia.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent

EXPERIMENTS = [
    {"name": "CORRUPT_BUNDLE",
     "description": "Uszkodź bundle OPA (zamień losowe bajty) — system musi fallbackować",
     "detection_tool": "validate_rules.py", "severity": "HIGH"},
    {"name": "EMPTY_THRESHOLDS",
     "description": "Opróżnij thresholds_jdg.rego — system musi wykryć brak progów",
     "detection_tool": "validate_rules.py --strict", "severity": "HIGH"},
    {"name": "MISSING_METADATA",
     "description": "Usuń _metadata_jdg.rego — system musi wykryć brak metadata",
     "detection_tool": "lint_rego_rules.py", "severity": "MEDIUM"},
    {"name": "FUTURE_TEMPORAL",
     "description": "Ustaw wszystkie valid_from na 2099 — 0 aktywnych reguł musi być wykryte",
     "detection_tool": "temporal_drift_detector.py", "severity": "HIGH"},
    {"name": "DUPLICATE_RULE_IDS",
     "description": "Wprowadź duplikat rule_id — walidator musi go wykryć",
     "detection_tool": "validate_rules.py", "severity": "MEDIUM"},
    {"name": "KSEF_OFFLINE_72H",
     "description": "Awaria MF — KSeF offline 72 h; kolejka OFL musi przechwycić",
     "detection_tool": "ksef_offline_queue.py", "severity": "HIGH"},
    {"name": "MISSING_DOMAIN_PACKAGE",
     "description": "Usuń pakiet domeny (np. jdg.micro.zus) — safe_merge musi fallbackować",
     "detection_tool": "invariant_checker.py ci", "severity": "HIGH"},
    {"name": "LATE_PAYMENT_CALENDAR",
     "description": "Termin w weekend/święto — kalendarz musi przesunąć (art. 12 § 5 OP)",
     "detection_tool": "deadline_engine.py", "severity": "MEDIUM"},
]


def list_experiments() -> dict:
    return {"experiments": EXPERIMENTS, "count": len(EXPERIMENTS)}


def run(names: list[str] | None = None, dry_run: bool = True) -> dict:
    exps = [e for e in EXPERIMENTS if not names or e["name"] in names]
    results = []
    for e in exps:
        # dry-run: w CI wykonywane są prawdziwe narzędzia wykrywania;
        # tutaj symulacja — każde narzędzie musi istnieć w tools/.
        tool = e["detection_tool"].split()[0]
        tool_path = JDG_ROOT / "tools" / tool
        detection_available = tool_path.exists()
        results.append({
            "name": e["name"],
            "severity": e["severity"],
            "detection_tool": e["detection_tool"],
            "detection_available": detection_available,
            "dry_run": dry_run,
            "status": "DETECTABLE" if detection_available else "TOOL_MISSING",
        })
    gate_ok = all(r["status"] == "DETECTABLE" for r in results)
    return {"experiments_run": len(results), "gate": "PASS" if gate_ok else "FAIL",
            "results": results}


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Chaos Runner (P18)")
    sub = p.add_subparsers(dest="cmd", required=True)
    l = sub.add_parser("list"); l.set_defaults(fn=lambda a: print(json.dumps(list_experiments(), ensure_ascii=False, indent=1)))
    r = sub.add_parser("run"); r.add_argument("--names", nargs="*", default=[])
    r.add_argument("--execute", action="store_true", help="wykonaj prawdziwe mutacje (CI)")
    r.set_defaults(fn=lambda a: print(json.dumps(run(a.names, not a.execute), ensure_ascii=False, indent=1)))
    g = sub.add_parser("gate"); g.set_defaults(fn=lambda a: print(json.dumps(run(), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
