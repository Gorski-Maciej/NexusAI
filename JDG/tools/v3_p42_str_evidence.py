#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I10 STR-AS-EVIDENCE — STR (ścieżka rekonstrukcji)
włączony do certyfikatu decyzji przy awarii. Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p42_common import (STR_GENERATOR, SYSTEM_REGISTER, emit,
                           main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P42-I10"
RULE = "jdg.v3_p42_enterprise_reszta.str_evidence"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    tool_ok = STR_GENERATOR.exists()
    checks.append({"name": "str_generator_exists", "status": "OK" if tool_ok else "FAIL",
                   "detail": f"tools/str_generator.py: {tool_ok}"})

    reg = read_json(SYSTEM_REGISTER)
    str_spec = reg.get("str_evidence", {}) if isinstance(reg, dict) else {}
    in_cert = str_spec.get("included_in_certificate", False)
    checks.append({"name": "str_in_certificate_spec", "status": "OK" if in_cert else "FAIL",
                   "detail": f"STR w certyfikacie decyzji (rejestr): {in_cert}"})

    fields = str_spec.get("fields", []) if isinstance(str_spec, dict) else []
    fields_ok = {"incident_id", "timeline", "root_cause"} <= set(fields)
    checks.append({"name": "str_fields_complete", "status": "OK" if fields_ok else "FAIL",
                   "detail": f"pola STR w rejestrze: {fields} (wymagane: incident_id/timeline/root_cause)"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "str_generator_exists": tool_ok,
            "str_in_certificate_spec": in_cert,
            "str_fields_complete": fields_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_str_evidence")


if __name__ == "__main__":
    raise SystemExit(main())
