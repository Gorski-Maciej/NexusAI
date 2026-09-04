#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I08 CBAM ARCHITECTURAL DECISION (monitoring importu).

Dowód wdrożenia: CBAM jako decyzja architektoniczna — monitoring importu
carbon-intensywnego (katalog jako dane), import w katalogu = TRIAGE do
człowieka (deklaracja CBAM NIE jest automatyzowana), przy nieaktywnym
monitoringu = BLOCK, import poza katalogiem = SUGGEST (poza zakresem).
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I08"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.cbam_architectural_decision"
TH_KEYS = ["v3_p19_cbam_monitor_active", "v3_p19_cbam_goods"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = '"imported_goods"' in hay
    has_catalogue = all(g in hay for g in ('"CEMENT"', '"STAL"', '"ALUMINIUM"'))
    has_in_scope = "_cb_in_scope" in hay
    has_manual = "MANUAL_TRACKED" in hay and "nie automatyzuj" in hay.lower()
    has_triage = "TRIAGE_QUEUE" in hay and "_cb_in_scope" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)
    wired = main_jdg_wired()

    checks.append({"name": "cbam_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "scope_catalogue", "status": "OK" if has_catalogue else "FAIL",
                   "detail": "katalog towarów carbon-intensywnych (jako dane)"})
    checks.append({"name": "in_scope_logic", "status": "OK" if has_in_scope else "FAIL",
                   "detail": "detekcja importu w katalogu CBAM"})
    checks.append({"name": "architectural_decision", "status": "OK" if has_manual else "FAIL",
                   "detail": "deklaracja CBAM = decyzja architektoniczna (NIE automatyzacja)"})
    checks.append({"name": "triage_to_human", "status": "OK" if has_triage else "FAIL",
                   "detail": "import w katalogu = TRIAGE do człowieka"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: katalog + monitoring z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_manual:
        findings.append({"id": "V3-P19-L08", "severity": "P0",
                         "evidence": "CBAM bez ścieżki decyzji architektonicznej (automatyzacja na ślepo)",
                         "fix": "I08: monitoring CBAM + TRIAGE do człowieka"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "catalogue": has_catalogue,
                    "architectural": has_manual, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "rozporządzenie UE CBAM 2023/956 (kontekst importera); Q02",
                     "rule": "monitoring CBAM — decyzja architektoniczna, TRIAGE, nie automatyzacja"}}
    return emit(bundle, "v3_p19_cbam_monitor")


if __name__ == "__main__":
    raise SystemExit(main())
