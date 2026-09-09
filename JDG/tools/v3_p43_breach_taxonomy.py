#!/usr/bin/env python3
"""NexusAI JDG — V3-P43-I10 BREACH TAXONOMY — klasyfikacja naruszeń
(dane/integralność/dostępność) ze ścieżkami prawnymi RODO/UODO.
Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p43_common import (RODO_DOC, SECURITY_REGISTER, emit, main_jdg_wired,
                           now, read_json, rule_present)

INNOVATION = "V3-P43-I10"
RULE = "jdg.v3_p43_security_dr.breach_taxonomy"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(SECURITY_REGISTER)
    bt = reg.get("breach_taxonomy", {}) if isinstance(reg, dict) else {}
    classes = bt.get("classes", []) if isinstance(bt, dict) else []
    required = ["data_confidentiality", "integrity", "availability"]
    classes_ok = all(c in classes for c in required)
    checks.append({"name": "breach_classes_complete", "status": "OK" if classes_ok else "FAIL",
                   "detail": f"klasy naruszeń: {classes} (wymagane: {required})"})

    # Ścieżki prawne per klasa (RODO/UODO)
    paths = bt.get("legal_paths", {}) if isinstance(bt, dict) else {}
    paths_ok = isinstance(paths, dict) and len(paths) >= len(required)
    checks.append({"name": "legal_paths_per_class", "status": "OK" if paths_ok else "FAIL",
                   "detail": f"ścieżki prawne: {len(paths) if isinstance(paths, dict) else 0} (min {len(required)})"})

    # Raport 72h gotowy kontraktowo (spójny z I09)
    report = isinstance(bt, dict) and bt.get("report_72h_ready", False)
    checks.append({"name": "report_72h_ready", "status": "OK" if report else "FAIL",
                   "detail": f"raport 72h gotowy (RODO art. 33 [NIEZWERYFIKOWANE]): {report}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p107"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "breach_classes_complete": classes_ok,
            "legal_paths_per_class": paths_ok,
            "report_72h_ready": report,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p43_breach_taxonomy")


if __name__ == "__main__":
    raise SystemExit(main())
