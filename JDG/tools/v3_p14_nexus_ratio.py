#!/usr/bin/env python3
"""NexusAI JDG — V3-P14-I03 NEXUS RATIO AUDITOR (art. 30ca PIT — IP Box 5%).

Nexus ratio = (koszty kwalifikowane × 1.3) / koszty całkowite (cap 100%).
  ≥ 50% → FULL premium, ≥ 25% → partial discount, < 25% → LOW (ryzyko US).
Brak dokumentacji produktowej / ewidencji IP (art. 30cb) = NEEDS_ADVICE
(fail-closed; kontrakt V3-P03: agresywna optymalizacja → niższa klasa pewności).
"""
from __future__ import annotations

from v3_p14_common import P14_RULES, now, read, rule_present, thresholds_missing, pit_domain_file, emit

INNOVATION = "V3-P14-I03"


def main() -> int:
    hay = read(P14_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p14_pit_reliefs.nexus_ratio_auditor", hay)
    has_nexus = "nexus_raw" in hay and "_nexus_tier" in hay and "checklist" in hay
    has_doc_gate = "ip_documented" in hay and "NEEDS_ADVICE" in hay and "nexus_doc_gap" in hay
    missing = thresholds_missing(["ip_box_rate", "ip_box_nexus_full_ratio", "ip_box_nexus_partial_ratio"])
    domain_ok = pit_domain_file("ipbox_enterprise.rego")

    checks.append({"name": "nexus_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła nexus_ratio_auditor: {has_rule}"})
    checks.append({"name": "nexus_formula", "status": "OK" if has_nexus else "FAIL",
                   "detail": "wzór nexus (qc×1.3/tc, cap 100%) + tier FULL/PARTIAL/LOW + checklist"})
    checks.append({"name": "doc_gate_fail_closed", "status": "OK" if has_doc_gate else "FAIL",
                   "detail": "brak dokumentacji/ewidencji → NEEDS_ADVICE (fail-closed)"})
    checks.append({"name": "params", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów nexus: {missing or 'BRAK'}"})
    checks.append({"name": "domain_ipbox", "status": "OK" if domain_ok else "FAIL",
                   "detail": "rules/pit/ipbox_enterprise.rego obecny — rozszerzenie, nie duplikat"})

    if not has_doc_gate:
        findings.append({"id": "V3-P14-L03", "severity": "P1",
                         "evidence": "IP Box bez bramki dokumentacyjnej (fail-closed)",
                         "fix": "I03: wymusić checklist dokumentacyjną art. 30cb → NEEDS_ADVICE"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "formula": has_nexus, "doc_gate": has_doc_gate,
                    "missing_params": missing, "domain_ipbox": domain_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P03 (certainty_class), P10 (golden), P39 (CI)",
                     "rule": "IP Box 5%: nexus ratio (50/25%), checklist dokumentacyjna, NEEDS_ADVICE bez dowodów"}}
    return emit(bundle, "v3_p14_nexus_ratio")


if __name__ == "__main__":
    raise SystemExit(main())
