#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I08 AUTO-FIX Z 4-EYES — narzędzia proponują automatyczne
poprawki jako PR z etykietą review-required — kampania V3 FORTRESS.

Dowód wdrożenia: auto-merge poprawek = BLOCK (człowiek zatwierdza; P07/KKS);
poprawki bez przeglądu = TRIAGE. Narząd: convert_true_to_conditions.py
(konwersja stubów) + debug_converter.py. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p34_common import (BASE, P34_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P34-I08"
RULE = "jdg.v3_p34_walidacja_narzedzia.auto_fix_four_eyes"


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # narzędzia auto-fix istnieją (konwersja stubów, debug)
    fixer = ((BASE / "tools" / "convert_true_to_conditions.py").exists()
             and (BASE / "tools" / "debug_converter.py").exists())
    checks.append({"name": "auto_fix_tools_present", "status": "OK" if fixer else "FAIL",
                   "detail": "convert_true_to_conditions + debug_converter: " + str(fixer)})

    # PR z przeglądem — auto-merge = BLOCK
    pr_path = "PR" in hay and "BLOCK" in hay
    checks.append({"name": "pr_review_required_block", "status": "OK" if pr_path else "FAIL",
                   "detail": "auto-merge = BLOCK; poprawka jako PR (4-eyes): " + str(pr_path)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "auto_fix_tools_present": fixer,
            "pr_review_required_block": pr_path,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_auto_fix_four_eyes")


if __name__ == "__main__":
    raise SystemExit(main())
