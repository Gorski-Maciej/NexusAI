#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I07 GOLDEN REPLAY ON MIRROR — złote orzeczenia
odtwarzane na mirror bundle przed deploy (podanalizy AN03). OPA niedostępny:
replay strukturalny — paryta zaso­bów bundla (manifest/pakiety) mirror vs
canonical plus kontrakt wersji; delta decyzji wymaga OPA (jawny tryb
STRUCTURAL_ONLY, brak fantazji wyników — protokół 14).
"""
from __future__ import annotations

import json

from v3_p48_common import (BASE, GOLDEN_VERDICTS, POLICIES_DIR,
                           drift_by_package, measure_drift, read_json,
                           rule_present, write_bundle)

INNOVATION = "V3-P48-I07"
RULE = "jdg.v3_p48_mirror_sync.golden_replay_mirror"


def main() -> int:
    checks, findings = [], []

    golden = read_json(GOLDEN_VERDICTS) or {}
    verdicts = golden.get("verdicts", []) or []
    verdicts_total = len(verdicts)

    # Paryta strukturalna: czy mirror zawiera wszystkie pakiety referencjonowane
    # w złotych orzeczeniach (dryf = mirror nie odtworzy decyzji).
    referenced = set()
    for v in verdicts:
        rid = str(v.get("rule_id", ""))
        pkg = rid.rsplit(".", 1)[0] if "." in rid else rid
        if pkg:
            referenced.add(pkg)
    mirror_rego = {p.relative_to(POLICIES_DIR).as_posix()
                   for p in POLICIES_DIR.rglob("*.rego")} if POLICIES_DIR.exists() else set()
    mirror_pkgs = {str(p.relative_to(POLICIES_DIR).parent.as_posix())
                   for p in POLICIES_DIR.rglob("*.rego")} if POLICIES_DIR.exists() else set()

    drift = measure_drift()
    pkgs = drift_by_package(drift)
    dirty_pkgs = [p for p, d in pkgs.items() if d["semantic"] > 0 or d["missing"] > 0]

    missing_in_mirror = sorted(p for p in dirty_pkgs if p not in mirror_pkgs)
    replay_done = False          # uczciwość: OPA brak → pełny replay niemożliwy (protokół 14)
    decision_deltas = 0          # nie policzono (brak OPA) — zero fantazji liczb

    checks.append({
        "name": "golden_verdicts_loaded",
        "status": "OK",
        "detail": f"bundles/golden_verdicts.json: {verdicts_total} orzeczeń "
                  f"(schema {golden.get('schema_version', '?')})",
    })
    checks.append({
        "name": "mirror_package_parity",
        "status": "OK" if not missing_in_mirror else "TRIAGE",
        "detail": f"pakiety z orzeczeń nieobecne w mirror: {len(missing_in_mirror)} "
                  f"({', '.join(missing_in_mirror[:5]) or 'brak'})",
    })
    checks.append({
        "name": "replay_mode",
        "status": "TRIAGE",
        "detail": "tryb STRUCTURAL_ONLY — OPA niedostępny w środowisku; delta decyzji "
                  "nie policzono (protokół 14); pełny replay na mirror PRZED deploy",
    })
    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if missing_in_mirror:
        findings.append({"severity": "HIGH",
                         "message": f"pakiety z orzeczeń złotych nieobecne w mirror: "
                                    f"{missing_in_mirror[:5]} — replay na mirror niemożliwy 1:1"})
    findings.append({"severity": "MEDIUM",
                     "message": "replay pełny wymaga OPA — uruchom w CI (P39) przed deploy"})

    routing = "BLOCK_AND_ALERT" if False else ("TRIAGE_QUEUE" if (not replay_done or missing_in_mirror) else "AUTO_FILE")
    metrics = {
        "verdicts_total": verdicts_total,
        "replay_done": replay_done,
        "decision_deltas": decision_deltas,
        "missing_mirror_packages": len(missing_in_mirror),
        "mode": "STRUCTURAL_ONLY",
        "routing": routing,
    }
    evidence = {"referenced_packages": sorted(referenced)[:40],
                "missing_in_mirror": missing_in_mirror[:20],
                "checks": checks, "findings": findings}
    write_bundle("golden_replay_mirror", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} verdicts={verdicts_total} "
          f"mode=STRUCTURAL_ONLY missing_pkgs={len(missing_in_mirror)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
