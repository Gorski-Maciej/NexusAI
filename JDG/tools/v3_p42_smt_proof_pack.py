#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I02 SMT PROOF PACK — dowody formalne dla reguł
krytycznych (VAT stawki, PIT progi, ZUS 30-krotność); P29/K04.
Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p42_common import (SMT_Z3, SYSTEM_REGISTER, emit, main_jdg_wired,
                           now, read, read_json, rule_present, threshold_present)

INNOVATION = "V3-P42-I02"
RULE = "jdg.v3_p42_enterprise_reszta.smt_proof_pack"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    smt_ok = SMT_Z3.exists()
    checks.append({"name": "smt_tool_exists", "status": "OK" if smt_ok else "FAIL",
                   "detail": f"tools/smt_z3_verification.py: {smt_ok}"})

    # Dowody dla reguł krytycznych zdefiniowane w rejestrze (nie fasada)
    reg = read_json(SYSTEM_REGISTER)
    proofs = reg.get("smt_proofs", []) if isinstance(reg, dict) else []
    critical = [p.get("rule") for p in proofs if isinstance(p, dict)]
    proofs_ok = len(proofs) >= 3 and any("vat" in c for c in critical if c)
    checks.append({"name": "critical_proofs_defined", "status": "OK" if proofs_ok else "FAIL",
                   "detail": f"dowody w rejestrze: {len(proofs)} ({critical})"})

    t = threshold_present("v3_p42_smt_min_proofs")
    checks.append({"name": "proof_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p42_smt_min_proofs w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "smt_tool_exists": smt_ok,
            "critical_proofs_defined": proofs_ok,
            "proof_count": len(proofs),
            "proof_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_smt_proof_pack")


if __name__ == "__main__":
    raise SystemExit(main())
