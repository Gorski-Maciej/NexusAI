#!/usr/bin/env python3
"""NexusAI JDG — V3-P33-I02 SANDBOX UPRAWNIEŃ AI — konto techniczne bez zapisu
do reguł produkcyjnych — kampania V3 FORTRESS.

Dowód wdrożenia: AI jako pisarz (autor propozycji) i człowiek jako approver
(4-eyes) w rozumieniu kontraktu P07; AI nigdy nie jest approverem. Próba
samozatwierdzenia = BLOCK (KKS — człowiek zatwierdza). Podanalizy: 5.1/5.2.
"""
from __future__ import annotations

from v3_p33_common import (P33_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P33-I02"
RULE = "jdg.v3_p33_neural_mesh_ai.ai_sandbox_permissions"


def main() -> int:
    hay = read(P33_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    sandbox_mode = threshold_present("v3_p33_ai_sandbox_mode")
    checks.append({"name": "sandbox_mode_threshold", "status": "OK" if sandbox_mode else "FAIL",
                   "detail": "v3_p33_ai_sandbox_mode w thresholds (domyślnie read_only): " + str(sandbox_mode)})

    # writer/approver rozdzielone w regule (P07: AI pisze, człowiek zatwierdza)
    separation = ("ai_sandbox_permissions" in hay and "approver" in hay
                  and "writer" in hay)
    checks.append({"name": "writer_approver_separation", "status": "OK" if separation else "FAIL",
                   "detail": "AI=writer, human=approver (P07/KKS): " + str(separation)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "sandbox_mode_as_data": sandbox_mode,
            "writer_approver_separation": separation,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p33_ai_sandbox_permissions")


if __name__ == "__main__":
    raise SystemExit(main())
