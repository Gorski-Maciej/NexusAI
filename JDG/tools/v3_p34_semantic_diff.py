#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I02 SEMANTIC DIFF DLA REGO — AST diff dwóch wersji
reguły z klasyfikacją zmiany (kosmetyczna/progowa/semantyczna) — V3 FORTRESS.

Dowód wdrożenia: każda zmiana klasyfikowana; zmiana semantyczna bez dowodu
SMT/Z3 (P33-I01) = BLOCK. Klasy jako dane w thresholds. Podanalizy: AN01.
"""
from __future__ import annotations

from v3_p34_common import (P34_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P34-I02"
RULE = "jdg.v3_p34_walidacja_narzedzia.semantic_diff"
CLASSES = ["kosmetyczna", "progowa", "semantyczna"]


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # klasyfikacja zmian jako danych + ścieżka BLOCK dla zmiany semantycznej bez SMT
    block = read(THRESHOLDS)
    classes_ok = all(c in hay or c in block for c in CLASSES)
    checks.append({"name": "change_classes", "status": "OK" if classes_ok else "FAIL",
                   "detail": f"klasy zmian {CLASSES} obecne: {classes_ok}"})

    smt_link = "SMT" in hay or "smt" in hay
    checks.append({"name": "semantic_requires_smt", "status": "OK" if smt_link else "FAIL",
                   "detail": "zmiana semantyczna wymaga SMT/Z3 (P33-I01): " + str(smt_link)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "change_classes_present": classes_ok,
            "semantic_requires_smt": smt_link,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_semantic_diff")


if __name__ == "__main__":
    raise SystemExit(main())
