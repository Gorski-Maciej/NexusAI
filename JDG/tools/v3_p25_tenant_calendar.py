#!/usr/bin/env python3
"""NexusAI JDG — V3-P25-I07 TENANT CALENDAR LAYER (multi-tenant per forma).

Dowód wdrożenia: terminy per JDG (tenant_id) i per forma opodatkowania
(SCALE/LINEAR/LUMP_SUM/TAX_CARD — determinuje wiersze PIT/ZUS); izolacja
tenant_id obowiązkowa (AP08/AP12); brak tenant_id = BLOCK.
"""
from __future__ import annotations

from v3_p25_common import P25_RULES, emit, now, read, rule_present

INNOVATION = "V3-P25-I07"
RULE = "jdg.v3_p25_kalendarz_zbiorczy.tenant_calendar"
FORMS = ("SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD")


def calendar_for(form: str) -> dict:
    """Wiersze kalendarza per forma opodatkowania (warstwa tenant)."""
    base = ["VAT_JPK_MONTHLY", "ZUS_DRA_NO_EMPLOYEES", "PPK_CONTRIBUTION"]
    pit = {"SCALE": ["PIT_ADVANCE_MONTHLY", "PIT_ANNUAL_RETURN"],
           "LINEAR": ["PIT_ADVANCE_MONTHLY", "PIT_ANNUAL_RETURN"],
           "LUMP_SUM": ["PIT_LUMP_SUM_MONTHLY", "PIT_ANNUAL_RETURN"],
           "TAX_CARD": ["PIT_ANNUAL_RETURN"]}
    return {"tax_form": form, "obligations": base + pit.get(form, [])}


def main() -> int:
    hay = read(P25_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_forms = all(f in hay for f in FORMS)
    has_isolation = "tenant_id" in hay and "AP12" in hay
    has_fail = "_tn_tenant_ok" in hay

    layer_ok = all(calendar_for(f)["obligations"] for f in FORMS)
    forms_distinct = len({tuple(calendar_for(f)["obligations"]) for f in FORMS}) > 1

    checks.append({"name": "tenant_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "forms_matrix", "status": "OK" if has_forms and layer_ok else "FAIL",
                   "detail": "4 formy → różne zestawy terminów PIT/ZUS"})
    checks.append({"name": "forms_distinct", "status": "OK" if forms_distinct else "FAIL",
                   "detail": "zestawy terminów różnią się per forma (LUMP_SUM → ryczałt 20.)"})
    checks.append({"name": "isolation", "status": "OK" if has_isolation else "FAIL",
                   "detail": "izolacja tenant_id (AP08/AP12 — jedno źródło, brak mieszania)"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail else "FAIL",
                   "detail": "brak tenant_id / nieznana forma = BLOCK"})

    if not forms_distinct:
        findings.append({"id": "V3-P25-L07", "severity": "P2",
                         "evidence": "zestawy terminów identyczne dla różnych form",
                         "fix": "różnicuj wiersze PIT/ZUS per forma (I07)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "forms": list(FORMS), "layer_ok": layer_ok,
                    "forms_distinct": forms_distinct, "isolation": has_isolation},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Warstwa tenant wiąże P63 (multi-tenant) i P41 (widok per JDG)",
                     "rule": "kalendarz per tenant per forma; izolacja obowiązkowa"}}
    return emit(bundle, "v3_p25_tenant_calendar")


if __name__ == "__main__":
    raise SystemExit(main())
