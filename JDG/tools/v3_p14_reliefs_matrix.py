#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I01 RELIEFS MATRIX COMPLETE.

Pełna macierz ulg PIT (ulga → przepis → warunki → limit → reguła → test):
art. 26e/26eb/26gb/26h/26ec, IP Box (30ca), zwolnienia art. 21 ust. 1 pkt
148/152/153/154, rehabilitacyjna (26 ust. 1 pkt 6), darowizna, e-learning.
Dowód: katalog reliefs_catalog w regułach + limit-as-data (I02) w thresholds
+ istniejące pliki domenowe rules/pit/ (rozszerzaj, nie duplikuj).
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, thresholds_missing, pit_domain_file, emit

INNOVATION = "V3-P14-I01"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.reliefs_matrix_complete", hay)
    has_catalog = "reliefs_catalog" in hay and '"legal_basis"' in hay and '"type"' in hay
    catalog_reliefs = sum(1 for rid in ["young", "return_work", "family_4plus", "senior",
                                        "thermo", "rehab_car", "rd_relief", "prototype",
                                        "robotization", "expansion", "ip_box", "donation"]
                          if f'"{rid}"' in hay)
    missing = thresholds_missing(["pit_relief_shared_limit", "pit_thermo_limit",
                                  "rehab_car_limit", "v3_p14_relief_limits"])
    domain_ok = pit_domain_file("art21_exemptions_enterprise.rego") and \
        pit_domain_file("thermo_relief_enterprise.rego") and pit_domain_file("rd_relief_enterprise.rego")

    checks.append({"name": "matrix_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła reliefs_matrix_complete: {has_rule}"})
    checks.append({"name": "catalog_present", "status": "OK" if has_catalog else "FAIL",
                   "detail": "katalog reliefs_catalog z legal_basis/type w regułach"})
    checks.append({"name": "relief_coverage", "status": "OK" if catalog_reliefs >= 12 else "FAIL",
                   "detail": f"ulgi pokryte w macierzy: {catalog_reliefs}/12 (min. 12 z P14)"})
    checks.append({"name": "limits_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak limitów w thresholds: {missing or 'BRAK'}"})
    checks.append({"name": "domain_files", "status": "OK" if domain_ok else "FAIL",
                   "detail": "pliki domenowe rules/pit (art21/thermo/rd) obecne — rozszerzenie, nie duplikat"})

    if catalog_reliefs < 12:
        findings.append({"id": "V3-P14-L01", "severity": "P2",
                         "evidence": "macierz ulg niekompletna w regułach enterprise",
                         "fix": "I01: rozszerzyć reliefs_catalog do pełnego katalogu P14 (26e/26eb/26gb/26h/26ec/30ca/21)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"matrix_rule": has_rule, "catalog": has_catalog,
                    "relief_coverage": catalog_reliefs, "domain_ok": domain_ok,
                    "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry), P10 (golden), P39 (bramki CI), P28/P44 (księgowość)",
                     "rule": "pełna macierz ulg PIT: ulga → przepis → warunki → limit → reguła → test → status"}}
    return emit(bundle, "v3_p14_reliefs_matrix")


if __name__ == "__main__":
    raise SystemExit(main())
