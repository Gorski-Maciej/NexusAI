#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I03 ROLE-BASED DOC MAPS — mapy czytania per rola
(developer/operator/audytor/przedsiębiorca). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p41_common import DOC_REGISTRY, emit, main_jdg_wired, now, read_json, rule_present

INNOVATION = "V3-P41-I03"
RULE = "jdg.v3_p41_dokumentacja.role_doc_maps"
REQUIRED_ROLES = ["developer", "operator", "auditor", "entrepreneur"]


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(DOC_REGISTRY)
    maps = reg.get("role_reading_maps", {}) if isinstance(reg, dict) else {}
    missing = [r for r in REQUIRED_ROLES if r not in maps]
    maps_ok = not missing
    checks.append({"name": "role_maps_complete", "status": "OK" if maps_ok else "FAIL",
                   "detail": f"mapy ról w rejestrze: {sorted(maps)} brakujące={missing}"})

    # Każda mapa ma >= 3 przystanków (ścieżka czytania)
    steps_ok = all(isinstance(maps.get(r), list) and len(maps.get(r, [])) >= 3
                   for r in REQUIRED_ROLES)
    checks.append({"name": "maps_have_reading_paths", "status": "OK" if steps_ok else "FAIL",
                   "detail": f"każda mapa ma ≥3 przystanki: {steps_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "role_maps_complete": maps_ok,
            "maps_have_reading_paths": steps_ok,
            "roles": sorted(maps),
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_role_doc_maps")


if __name__ == "__main__":
    raise SystemExit(main())
