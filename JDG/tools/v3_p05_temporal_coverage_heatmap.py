#!/usr/bin/env python3
"""
NexusAI JDG — TEMPORAL COVERAGE HEATMAP (V3-P05-I12)
====================================================
Mapa pokrycia testami granicznymi per nowelizacja (P05-AN05/AN12):
dla każdej kotwicy (data wejścia w życie) — które warstwy pokryte:

  • REGISTRY — wpis w temporal_validity (rule_id → valid_from);
  • DOC38c  — wiersz w Plan OPA/38c_JDG_CANONICAL_MAP.md;
  • PYTEST  — reguła obecna w testach pytest (assert aktywności);
  • BOUNDARY— para day-1 (nieaktywna) + day0 (aktywna) w testach;
  • GOLDEN  — reguła obecna w złotym zestawie (golden_verdicts.json).

Rollup per domena (zus, edge_cases, validation, business, ksef_jpk, ...).
Plan domknięcia luk: każda kotwica bez PYTEST/BOUNDARY = P2 do dodania
(test day-1/0/+1 — Time Gate I05); bez GOLDEN = P3 (reper replay I06).

Usage: python tools/v3_p05_temporal_coverage_heatmap.py
Exit:  0 = PASS, 1 = FAIL (kotwica bez żadnego pokrycia testowego).
"""
from __future__ import annotations

import json
import re
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules"
TESTS = ROOT / "tests"
BUNDLES = ROOT / "bundles"
OUT = BUNDLES / "v3_p05_temporal_coverage_heatmap.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def registry_entries() -> list[dict]:
    md = (RULES / "_metadata_jdg.rego").read_text(encoding="utf-8")
    m = re.search(r"temporal_validity\s*:=\s*\{", md)
    if not m:
        return []
    start, depth, i = m.end(), 1, m.end()
    while i < len(md) and depth > 0:
        if md[i] == "{":
            depth += 1
        elif md[i] == "}":
            depth -= 1
        i += 1
    block = md[start : i - 1]
    out = []
    for em in re.finditer(r'"((?:jdg|tax)\.[a-z0-9_.]+)"\s*:\s*\{([^}]*)\}', block):
        vf = re.search(r'"valid_from"\s*:\s*"(\d{4}-\d{2}-\d{2})"', em.group(2))
        out.append({"rule_id": em.group(1),
                    "valid_from": vf.group(1) if vf else None})
    return out


def main() -> int:
    entries = [e for e in registry_entries() if e.get("valid_from")]
    test_txt = "".join(p.read_text(encoding="utf-8", errors="replace")
                       for p in sorted(TESTS.rglob("*.py")))
    doc38 = (ROOT / "Plan OPA" / "38c_JDG_CANONICAL_MAP.md")
    doc_txt = doc38.read_text(encoding="utf-8", errors="replace") if doc38.exists() else ""
    gv = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
    golden_rules = {v.get("verdict", {}).get("rule_id")
                    for v in gv.get("verdicts", {}).values()}

    rows = []
    for e in entries:
        rid, d = e["rule_id"], e["valid_from"]
        d1 = (date.fromisoformat(d) - timedelta(days=1)).isoformat()
        c = {
            "rule_id": rid, "anchor": d,
            "registry": True,
            "doc38c": rid in doc_txt,
            "pytest": rid in test_txt,
            "boundary": (rid in test_txt and d in test_txt and d1 in test_txt),
            "golden": rid in golden_rules,
        }
        rows.append(c)

    by_domain: dict[str, dict] = {}
    for r in rows:
        dom = r["rule_id"].split(".")[1] if len(r["rule_id"].split(".")) > 1 else "?"
        agg = by_domain.setdefault(dom, {"total": 0, "pytest": 0, "boundary": 0, "golden": 0})
        agg["total"] += 1
        agg["pytest"] += 1 if r["pytest"] else 0
        agg["boundary"] += 1 if r["boundary"] else 0
        agg["golden"] += 1 if r["golden"] else 0

    heat = ["mapa pokrycia per domena (procent reguł temporalnych z pokryciem):"]
    for dom in sorted(by_domain):
        a = by_domain[dom]
        heat.append(f"  {dom:<10} pytest={round(100*a['pytest']/a['total']):>3}%  "
                    f"boundary={round(100*a['boundary']/a['total']):>3}%  "
                    f"golden={round(100*a['golden']/a['total']):>3}%  "
                    f"(n={a['total']})")

    no_test = [r for r in rows if not r["pytest"] and not r["boundary"]]
    checks = [
        {"name": "no_test_anchors", "status": "FAIL" if no_test else "OK",
         "detail": f"kotwic bez pokrycia testowego (pytest/boundary): {len(no_test)}"},
        {"name": "heatmap_built", "status": "OK",
         "detail": f"wierszy macierzy: {len(rows)}, domen: {len(by_domain)}"},
    ]
    findings = [{
        "id": "V3-P05-L14", "severity": "P2",
        "evidence": f"kotwice bez testów: {[r['rule_id'] + '@' + r['anchor'] for r in no_test[:10]]}",
        "fix": "testy day-1/0/+1 per kotwica (I05 Time Gate) + reper golden (I06)",
    }] if no_test else []

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I12",
        "generated_at": now(),
        "gate": gate,
        "heatmap": heat,
        "rows": rows,
        "rollup": by_domain,
        "metrics": {
            "anchors_total": len(rows),
            "anchors_pytest": sum(1 for r in rows if r["pytest"]),
            "anchors_boundary": sum(1 for r in rows if r["boundary"]),
            "anchors_golden": sum(1 for r in rows if r["golden"]),
            "domains": len(by_domain),
        },
        "checks": checks,
        "findings": findings,
        "contract": {
            "binding": "P37 heatmapa pokrycia / P39 CI / P12 cele kwartalne",
            "plan": "domknięcie luk: każda nowelizacja bez testów granicznych = P2; "
                    "cel: 100% kotwic z parą day-1/day0 (bramka I05)",
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I12] gate={gate} anchors={len(rows)} "
          f"pytest={bundle['metrics']['anchors_pytest']} "
          f"boundary={bundle['metrics']['anchors_boundary']} "
          f"golden={bundle['metrics']['anchors_golden']} no_test={len(no_test)}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
