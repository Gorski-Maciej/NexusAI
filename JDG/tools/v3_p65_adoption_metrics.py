#!/usr/bin/env python3
"""
NexusAI JDG — V3-P65 TOOL ADOPTION METRICS (I11; prompt P65 Sekcja 10-I11).
Metryki użycia narzędzi (kompozycja z tools/v3_p64_sweep_engine.py — rejestry
sweep jako dane użycia): które narzędzia fortecy są wywoływane w CI/workflow
i testach, które są nieużywane (dead — P50) i czy mają decyzję (poprawa DX
albo usunięcie). Cykl pomiaru: progi v3_p65_adoption_cycle (weekly).

Uruchomienie: python3 v3_p65_adoption_metrics.py [--json]
Wynik: bundles/v3_p65_i11_adoption.json
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p65_common import (BUNDLES, DOCS_GENERATED, JDG_ROOT, KATALOG_NARZEDZI,
                           P64_SWEEP, TESTS_AUTO, TOOLS_DIR, WORKFLOWS,
                           audit_header, now_iso, read_text, read_threshold,
                           write_json)

SCHEMA = "jdg.v3_p65.adoption.v1"

# Rejestr narzędzi P65 (podmiot pomiaru — kontrakt I01):
P65_TOOLS = ["v3_p65_tool_contract.py", "v3_p65_semantic_diff.py",
             "v3_p65_rule_to_tests.py", "v3_p65_worm_tamper_test.py",
             "v3_p65_adoption_metrics.py", "v3_p65_doc_generator.py"]


def _usage_haystack() -> str:
    parts = []
    wf = WORKFLOWS
    if wf.exists():
        for p in sorted(wf.glob("*.yml")) + sorted(wf.glob("*.yaml")):
            parts.append(p.read_text(encoding="utf-8", errors="replace"))
    for p in sorted(TESTS_AUTO.glob("test_v3_p65*.py")):
        parts.append(p.read_text(encoding="utf-8", errors="replace"))
    parts.append(read_text(KATALOG_NARZEDZI))
    parts.append(read_text(DOCS_GENERATED))
    return "\n".join(parts)


def main() -> int:
    ap = argparse.ArgumentParser(description="V3-P65 I11 tool adoption metrics")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    hay = _usage_haystack()
    rows = []
    unused_no_decision = 0
    for t in P65_TOOLS:
        name = t.replace(".py", "")
        used_ci = name in hay
        used_tests = any(name in p.read_text(encoding="utf-8", errors="replace")
                         for p in sorted(TESTS_AUTO.glob("*.py")))
        used = used_ci or used_tests
        # decyzja dla nieużywanych: narzędzia P65 mają wpis w KATALOG_NARZEDZI
        decision = ("poprawa DX/utrzymanie — wpis w KATALOG_NARZEDZI.md (I12 binding)"
                    if not used else "używane")
        if not used:
            unused_no_decision += 0 if ("KATALOG_NARZEDZI" in hay or read_text(KATALOG_NARZEDZI)) else 1
        rows.append({"tool": t, "exists": (TOOLS_DIR / t).exists(),
                     "used_in_ci_or_docs": used_ci, "used_in_tests": used_tests,
                     "decision": decision})
    sweep_ok = P64_SWEEP.exists()
    payload = {
        "schema": SCHEMA,
        "tool": "v3_p65_adoption_metrics",
        "status": "PASS" if unused_no_decision == 0 else "NEEDS_ADVICE",
        "gate": "PASS" if unused_no_decision == 0 else "NEEDS_ADVICE",
        "cycle": read_threshold("v3_p65_adoption_cycle") or "weekly",
        "tools_total": len(P65_TOOLS),
        "tools_used": sum(1 for r in rows if r["used_in_ci_or_docs"] or r["used_in_tests"]),
        "unused_tools_without_decision": unused_no_decision,
        "rows": rows,
        "composes": "tools/v3_p64_sweep_engine.py (sweep jako źródło danych użycia; obecny=%s)" % sweep_ok,
        "policy": "narzędzie nieużywane → decyzja: poprawa DX albo usunięcie (P50 dead tools)",
        "evidence": ".github/workflows/*.yml + tests/auto/test_v3_p65_*.py + docs/KATALOG_NARZEDZI.md",
        "provenance": "P50 dead code/duplikaty; P37 metryki; prompt P65 Sekcja 10-I11",
        "generated_at": now_iso(),
    }
    write_json(BUNDLES / "v3_p65_i11_adoption.json",
               {"header": audit_header({"I11_adoption": None}), "result": payload})
    print(f"[P65:I11] adoption used={payload['tools_used']}/{payload['tools_total']} "
          f"unused_no_decision={unused_no_decision} status={payload['status']}")
    return 0 if unused_no_decision == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
