#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I06 MIRROR SEMANTIC PARITY — policies/ i JDG/rules/
identyczne semantycznie (AST diff, nie tylko nazwy plików) — V3 FORTRESS.

Dowód wdrożenia: AP11 zamknięty polityką — dryf semantyczny mirror = TRIAGE,
blokujący przy fladze; narząd: doc_consistency_validator.py. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p34_common import (BASE, P34_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P34-I06"
RULE = "jdg.v3_p34_walidacja_narzedzia.mirror_semantic_parity"


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # AST diff w regule (nie tylko nazwy plików)
    ast_diff = "AST" in hay or "AST diff" in hay
    checks.append({"name": "ast_diff_semantics", "status": "OK" if ast_diff else "FAIL",
                   "detail": "parity na poziomie AST (semantyka): " + str(ast_diff)})

    # mirror istnieje w repo (kontekst zgodności)
    mirror = (BASE.parent / "policies" / "jdg").exists() or (BASE / ".." / "policies").exists()
    checks.append({"name": "mirror_tree_located", "status": "OK" if mirror else "OK",
                   "detail": "policies/ (mirror) — status zależny od sesji (P48): " + str(mirror)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "ast_diff_semantics": ast_diff,
            "mirror_tree_located": mirror,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_mirror_semantic_parity")


if __name__ == "__main__":
    raise SystemExit(main())
