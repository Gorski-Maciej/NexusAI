#!/usr/bin/env python3
"""NexusAI JDG — V3-P33-I05 RED-TEAM PROMPT SUITE — ataki injection/jailbreak/
exfiltration na bridge — kampania V3 FORTRESS.

Dowód wdrożenia: kategorie ataków jako dane w thresholds (ADR-002), wynik
red-teamu blokuje merge przy słabości; słabość = BLOCK. Podanalizy: 5.4.
"""
from __future__ import annotations

from v3_p33_common import (P33_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P33-I05"
RULE = "jdg.v3_p33_neural_mesh_ai.red_team_prompt_suite"
ATTACKS = ["injection", "jailbreak", "exfiltration", "role_escape", "key_phishing"]


def main() -> int:
    hay = read(P33_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    block = read(THRESHOLDS)
    i = block.find("v3_p33 := {")
    depth, block_text = 0, ""
    if i >= 0:
        for j in range(i, len(block)):
            if block[j] == "{":
                depth += 1
            elif block[j] == "}":
                depth -= 1
                if depth == 0:
                    block_text = block[i:j]
                    break
    attacks_ok = all(f'"{a}"' in block_text for a in ATTACKS)
    checks.append({"name": "attack_categories_as_data", "status": "OK" if attacks_ok else "FAIL",
                   "detail": f"kategorie ataków {ATTACKS} jako dane: {attacks_ok}"})

    # słabość red-teamu blokuje merge
    block_path = "red_team" in hay and "BLOCK" in hay
    checks.append({"name": "weakness_blocks_merge", "status": "OK" if block_path else "FAIL",
                   "detail": "słabość red-team = BLOCK (merge blocker): " + str(block_path)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "attack_categories": ATTACKS,
            "attack_categories_as_data": attacks_ok,
            "weakness_blocks_merge": block_path,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p33_red_team_prompt_suite")


if __name__ == "__main__":
    raise SystemExit(main())
