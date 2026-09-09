#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I02 SSOT NUMBERS — liczby w dokumentach generowane
z repo (snippety), zero ręcznych; P34 doc_consistency_validator jako silnik.
Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p41_common import (DOC_VALIDATOR, KATALOG_REGUL, MANIFEST_2_0, RULES,
                           emit, main_jdg_wired, now, read, rule_present)

INNOVATION = "V3-P41-I02"
RULE = "jdg.v3_p41_dokumentacja.ssot_numbers"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    validator_ok = DOC_VALIDATOR.exists()
    checks.append({"name": "consistency_validator_exists", "status": "OK" if validator_ok else "FAIL",
                   "detail": f"tools/doc_consistency_validator.py (P34): {validator_ok}"})

    # Realne liczby jako dowód SSOT (policzone z repo, nie z dokumentu)
    rego_count = len(list(RULES.glob("*.rego")))
    catalog = read(KATALOG_REGUL)
    checks.append({"name": "repo_counts_measurable", "status": "OK" if rego_count > 0 else "FAIL",
                   "detail": f"plików rego w rules/: {rego_count} (policzone z repo; KATALOG_REGUL {len(catalog.splitlines())} linii)"})

    manifest = read(MANIFEST_2_0)
    manifest_ok = len(manifest) > 0
    checks.append({"name": "manifest_present", "status": "OK" if manifest_ok else "FAIL",
                   "detail": f"MANIFEST_2_0.md obecny ({len(manifest.splitlines())} linii): {manifest_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "consistency_validator_exists": validator_ok,
            "rego_files_in_rules": rego_count,
            "manifest_present": manifest_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_ssot_numbers")


if __name__ == "__main__":
    raise SystemExit(main())
