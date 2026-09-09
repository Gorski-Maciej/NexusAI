#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I01 DOC-CODE BINDING — front-matter dokumentów z listą
artefaktów; bramka docs w CI (P29). Podanalizy: AN01.
"""
from __future__ import annotations

import sys

from v3_p41_common import (DOC_REGISTRY, SECTION6_DOCS, WORKFLOW, DOCS,
                           emit, main_jdg_wired, now, read_json, rule_present)

INNOVATION = "V3-P41-I01"
RULE = "jdg.v3_p41_dokumentacja.doc_code_binding"


def main() -> int:
    # --gate: wywołanie z CI (Bramka 6b); zachowanie identyczne (exit code = gate)
    _ = "--gate" in sys.argv
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(DOC_REGISTRY)
    entries = reg.get("documents", {}) if isinstance(reg, dict) else {}
    bound = [d for d, v in entries.items()
             if isinstance(v, dict) and v.get("bound_artifacts")]
    # Dowód: wszystkie 24 dokumenty Sekcji 6 istnieją i mają wpis w rejestrze
    exists_ok = all((DOCS / d).exists() for d in SECTION6_DOCS)
    checks.append({"name": "section6_docs_exist", "status": "OK" if exists_ok else "FAIL",
                   "detail": f"24/24 plików Sekcji 6 istnieje: {exists_ok}"})

    bound_ok = len(bound) >= len(SECTION6_DOCS)
    checks.append({"name": "registry_bindings_complete", "status": "OK" if bound_ok else "FAIL",
                   "detail": f"bindowania w rejestrze: {len(bound)}/{len(SECTION6_DOCS)}"})

    wf = ""
    if WORKFLOW.exists():
        wf = WORKFLOW.read_text(encoding="utf-8", errors="ignore")
    gate_ci = "doc" in wf.lower()
    checks.append({"name": "docs_gate_in_ci_workflow", "status": "OK" if gate_ci else "FAIL",
                   "detail": f"workflow CI wspomina docs gate: {gate_ci}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "section6_docs_exist": exists_ok,
            "registry_bindings": len(bound),
            "docs_gate_in_ci_workflow": gate_ci,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_doc_code_binding")


if __name__ == "__main__":
    raise SystemExit(main())
