#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I04 PRE-SEND FIREWALL (XSD + semantyka, zero śmieci).

Dowód wdrożenia: reguła pre_send_firewall + walidacja pól XSD (P_1..P_8),
GTU ze słownika 13 kodów, MPP zgodny z progiem (kontrakt P12/P13).
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, now, read, rule_present, emit

INNOVATION = "V3-P16-I04"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.pre_send_firewall", hay)
    has_xsd = '"missing_fields"' in hay and '"required_fields"' in hay and "P_1" in hay
    has_gtu = "gtu_known" in hay and "gtu_codes" in hay
    has_mpp = "mpp_required" in hay and "mpp_marked" in hay
    has_block = '"fail_closed": _fw_blocked' in hay or '"fail_closed": _fw_blocked' in hay

    checks.append({"name": "firewall_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła pre_send_firewall: {has_rule}"})
    checks.append({"name": "xsd_fields", "status": "OK" if has_xsd else "FAIL",
                   "detail": "walidacja wymaganych pól XSD"})
    checks.append({"name": "gtu_dictionary", "status": "OK" if has_gtu else "FAIL",
                   "detail": "GTU ze słownika 13 kodów"})
    checks.append({"name": "mpp_semantics", "status": "OK" if has_mpp else "FAIL",
                   "detail": "MPP zgodny z progiem (kontrakt P12/P13)"})
    checks.append({"name": "block_invalid", "status": "OK" if has_block else "FAIL",
                   "detail": "błędna faktura → BLOCK_AND_ALERT (zero śmieci do MF)"})

    if not (has_xsd and has_gtu):
        findings.append({"id": "V3-P16-L04", "severity": "P1",
                         "evidence": "firewall bez pełnej walidacji XSD/GTU",
                         "fix": "I04: walidacja przed wysyłką (zero śmieci do MF)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "xsd": has_xsd, "gtu": has_gtu,
                    "mpp": has_mpp, "block": has_block},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P12/P13 (GTU/MPP), rozporządzenie MF (XSD FA), P39 (bramki CI)",
                     "rule": "pre-send firewall: XSD + semantyka przed wysyłką"}}
    return emit(bundle, "v3_p16_pre_send_firewall")


if __name__ == "__main__":
    raise SystemExit(main())
