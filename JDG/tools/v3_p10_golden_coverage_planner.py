#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I09 GOLDEN COVERAGE PLANNER
==================================================
Plan domykania pokrycia golden per domena. Porównuje pakiety obecne w
golden_verdicts.json z pełną listą pakietów reguł w rules/ i priorytetyzuje
luki wg ryzyka regresji (P10-AN11).

Usage:
  python tools/v3_p10_golden_coverage_planner.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    golden = BUNDLES / "golden_verdicts.json"
    covered = set()
    if golden.exists():
        d = json.loads(golden.read_text(encoding="utf-8"))
        for rec in d.get("verdicts", {}).values():
            pkg = rec.get("verdict", {}).get("package", "")
            if pkg:
                covered.add(pkg.split(".")[1] if pkg.startswith("jdg.") and len(pkg.split(".")) > 1 else pkg)

    # pełna mapa pakietów z rules/ (katalogi + pliki *.rego)
    rules_dir = BASE / "rules"
    all_pkgs = set()
    if rules_dir.exists():
        for p in rules_dir.rglob("*.rego"):
            txt = p.read_text(encoding="utf-8", errors="replace")
            m = re.search(r"^package\s+([\w.]+)", txt, re.M)
            if m:
                parts = m.group(1).split(".")
                all_pkgs.add(parts[1] if len(parts) > 1 and parts[0] == "jdg" else m.group(1))

    high_risk = ["vat", "pit", "zus", "kks", "ord", "ryczalt", "crossborder", "ksef", "uor", "pkpir"]
    missing = sorted(all_pkgs - covered)
    missing_high = [m for m in missing if any(h in m for h in high_risk)]

    checks.append({"name": "coverage_map", "status": "OK" if all_pkgs else "FAIL",
                   "detail": f"pakiety w rules/: {len(all_pkgs)}, pokryte golden: {len(covered)}"})
    checks.append({"name": "high_risk_covered", "status": "OK" if not missing_high else "FAIL",
                   "detail": f"domeny wysokiego ryzyka BEZ pokrycia golden: {missing_high}"})

    if missing_high:
        findings.append({"id": "V3-P10-L09", "severity": "P1",
                         "evidence": f"domeny wysokiego ryzyka regresji bez werdyktu golden: "
                                     f"{missing_high} (z {len(all_pkgs)} pakietów w rules/, golden "
                                     f"pokrywa {len(covered)})",
                         "fix": "I09: plan domykania pokrycia golden per domena (priorytet wg "
                                "ryzyka P10-AN11) z seedowaniem werdyktów granicznych"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I09",
        "name": "Golden Coverage Planner — domykanie pokrycia per domena",
        "generated_at": now(),
        "gate": gate,
        "metrics": {"packages_total": len(all_pkgs), "packages_covered": len(covered),
                    "coverage_pct": round(100 * len(covered) / len(all_pkgs), 2) if all_pkgs else 0.0,
                    "missing_high_risk": missing_high},
        "plan": [{"domain": m, "priority": "HIGH", "action": "seed golden verdicts (granice + edge cases)"}
                 for m in missing_high],
        "checks": checks, "findings": findings,
        "contract": {"binding": "P10 (golden), P44 (certyfikacja), P12-P28 (domeny)",
                     "rule": "domena wysokiego ryzyka bez pokrycia golden = znany limit pokrycia "
                             "w dashboardzie (I07), plan domknięcia w CI"}}
    (BUNDLES / "v3_p10_golden_coverage_planner.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I09] gate={gate} coverage={len(covered)}/{len(all_pkgs)} "
          f"missing_high={len(missing_high)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
