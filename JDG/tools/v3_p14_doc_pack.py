#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I08 RELIEF DOCUMENTATION PACK (dowody dla KAS).

Generator checklist dokumentacyjnych per ulga (katalog dokumentów jako dane
w regułach): termo (faktura VAT + dokumentacja techniczna), B+R (ewidencja
czasu), IP Box (ewidencja art. 30cb), rehabilitacyjna, darowizna itd.
Brak dokumentów przy roszczeniu = NEEDS_ADVICE (fail-closed, AP07 — nigdy
cichy AUTO_POST).
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, emit

INNOVATION = "V3-P14-I08"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.relief_documentation_pack", hay)
    has_catalog = "_docs_catalog" in hay and '"thermo"' in hay and '"rd_relief"' in hay and '"ip_box"' in hay
    has_gap = "missing_docs" in hay and "complete" in hay and "NEEDS_ADVICE" in hay and "doc_pack_gap" in hay

    doc_reliefs = sum(1 for rid in ["thermo", "rd_relief", "ip_box", "rehab_car", "young",
                                    "return_work", "family_4plus", "senior", "donation",
                                    "internet", "prototype", "robotization", "expansion"]
                      if f'"{rid}": [' in hay)

    checks.append({"name": "doc_pack_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła relief_documentation_pack: {has_rule}"})
    checks.append({"name": "docs_catalog", "status": "OK" if has_catalog else "FAIL",
                   "detail": "katalog checklist per ulga (termo/rd/ip_box minimum)"})
    checks.append({"name": "coverage", "status": "OK" if doc_reliefs >= 10 else "FAIL",
                   "detail": f"ulg z checklistą: {doc_reliefs}/13"})
    checks.append({"name": "fail_closed", "status": "OK" if has_gap else "FAIL",
                   "detail": "brak dokumentów → NEEDS_ADVICE (AP07 — nigdy cichy AUTO_POST)"})

    if not has_gap:
        findings.append({"id": "V3-P14-L08", "severity": "P1",
                         "evidence": "brak fail-closed przy braku dokumentacji roszczenia",
                         "fix": "I08: brak dokumentów + kwota roszczenia > 0 → NEEDS_ADVICE"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "catalog": has_catalog, "coverage": doc_reliefs,
                    "fail_closed": has_gap},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P03 (certainty), P11 (certyfikat), KAS (dowody), P28 (księgowość)",
                     "rule": "checklist dokumentacyjne per ulga — dowody dla KAS; brak = NEEDS_ADVICE"}}
    return emit(bundle, "v3_p14_doc_pack")


if __name__ == "__main__":
    raise SystemExit(main())
