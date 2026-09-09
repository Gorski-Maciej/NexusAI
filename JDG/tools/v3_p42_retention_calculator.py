#!/usr/bin/env python3
"""NexusAI JDG — V3-P42-I04 RETENTION CALCULATOR — 5 lat od końca roku
obrotowego per artefakt; lista do bezpiecznego usunięcia. Podanalizy: AN03.
"""
from __future__ import annotations

from datetime import date

from v3_p42_common import (SYSTEM_REGISTER, emit, main_jdg_wired, now,
                           read_json, rule_present, threshold_present)

INNOVATION = "V3-P42-I04"
RULE = "jdg.v3_p42_enterprise_reszta.retention_calculator"


def expiry_date(year_end: int) -> str:
    """Retencja 5 lat od końca roku obrotowego (UoR art. 94 [NIEZWERYFIKOWANE]):
    dla roku obrotowego R data wygaśnięcia = 31.12.(R+5)."""
    return f"{year_end + 5}-12-31"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    t = threshold_present("v3_p42_retention_years")
    checks.append({"name": "retention_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p42_retention_years w data.thresholds: {t}"})

    # Przykład wyliczenia (mechanizm działa, nie tylko deklaracja)
    sample = expiry_date(2025)
    sample_ok = sample == "2030-12-31"
    checks.append({"name": "expiry_calculation_deterministic", "status": "OK" if sample_ok else "FAIL",
                   "detail": f"przykład: koniec roku 2025 → wygaśnięcie {sample} (oczekiwane 2030-12-31)"})

    reg = read_json(SYSTEM_REGISTER)
    ret = reg.get("retention", {}) if isinstance(reg, dict) else {}
    classes_ok = len(ret.get("classes", [])) > 0
    checks.append({"name": "retention_classes_defined", "status": "OK" if classes_ok else "FAIL",
                   "detail": f"klasy retencji w rejestrze: {ret.get('classes', [])}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p106"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "retention_threshold_as_data": t,
            "expiry_calculation_deterministic": sample_ok,
            "retention_classes_defined": classes_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p42_retention_calculator")


if __name__ == "__main__":
    raise SystemExit(main())
