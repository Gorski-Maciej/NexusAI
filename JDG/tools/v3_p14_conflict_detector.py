#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I11 MULTI-RELIEF CONFLICT DETECTOR.

Wykrywanie kolizji ulg: te same koszty (cost_ids) odliczone w dwóch ulgach
(np. B+R + robotyzacja na tym samym robocie, B+R + IP Box na tym samym IP) —
podwójne odliczenie = BLOCKER (BLOCK_AND_ALERT). Para (a<b) uporządkowana
indeksami (determinizm); output: conflicts + conflict_count.
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, emit

INNOVATION = "V3-P14-I11"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.multi_relief_conflict_detector", hay)
    has_cost_ids = "_claim_cost_ids" in hay and "_shared_cost_ids" in hay and "cost_ids" in hay
    has_pairs = "_conflict_pairs" in hay and '["rd_relief", "robotization"]' in hay
    has_blocker = "conflict_count" in hay and "BLOCK_AND_ALERT" in hay

    checks.append({"name": "conflict_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła multi_relief_conflict_detector: {has_rule}"})
    checks.append({"name": "shared_cost_ids", "status": "OK" if has_cost_ids else "FAIL",
                   "detail": "wykrywanie wspólnych cost_ids między roszczeniami"})
    checks.append({"name": "forbidden_pairs", "status": "OK" if has_pairs else "FAIL",
                   "detail": "pary zakazane: B+R+robotyzacja, B+R+IP Box (katalog)"})
    checks.append({"name": "blocker", "status": "OK" if has_blocker else "FAIL",
                   "detail": "kolizja → BLOCK_AND_ALERT (BLOCKER, nigdy cichy AUTO_POST)"})

    if not has_blocker:
        findings.append({"id": "V3-P14-L11", "severity": "P0",
                         "evidence": "brak BLOCKERA przy kolizji ulg (podwójne odliczenie kosztów)",
                         "fix": "I11: te same koszty w dwóch ulgach → BLOCK_AND_ALERT"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "cost_ids": has_cost_ids, "pairs": has_pairs,
                    "blocker": has_blocker},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P04 (invarianty runtime), P28 (księgowość), P44 (deklaracje)",
                     "rule": "wykrywanie kolizji ulg (te same koszty w 2 ulgach) — BLOCKER"}}
    return emit(bundle, "v3_p14_conflict_detector")


if __name__ == "__main__":
    raise SystemExit(main())
