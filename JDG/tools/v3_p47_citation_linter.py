#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I02 CITATION LINTER — walidator formatu cytowań
(kanon z raportu P47) na bramce PR: zero nowych podstaw w złym formacie.
Kanon: akt (ustawa/rozporządzenie) + jednostka redakcyjna art./ust./pkt/§ +
publikator Dz.U. RRRR poz. N, albo jawny tag [NIEZWERYFIKOWANE] /
[BŁĄD_PODSTAWY_PRAWNEJ?]. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p47_common import (P47_RULE, citation_in_canon, read_json, rule_present,
                           scan_legal_basis, write_bundle)

INNOVATION = "V3-P47-I02"
RULE = f"{P47_RULE}.citation_linter"


def main() -> int:
    checks, findings = [], []

    scan = scan_legal_basis()
    citations = scan["citations"]
    total = len(citations)
    in_canon = [c for c in citations if citation_in_canon(c)]
    violations = [c for c in citations if not citation_in_canon(c)]

    checks.append({"name": "citations_scanned", "status": "OK" if total else "FAIL",
                   "detail": f"cytowań w _legal_basis (żywy skan): {total}"})
    checks.append({"name": "canon_compliance",
                   "status": "OK" if not violations else "FAIL",
                   "detail": f"zgodnych z kanonem: {len(in_canon)}/{total}"
                             + (f"; przykłady naruszeń: {violations[:3]}" if violations else "")})

    # Reguły bez _legal_basis w ogóle (AP01 — stub udający pokrycie prawne)
    lb2 = read_json(__import__("v3_p47_common").LB_V2_REPORT) or {}
    rows = lb2.get("rows", [])
    rules_without = sum(1 for r in rows if r.get("status") == "MISSING")
    checks.append({"name": "rules_without_legal_basis",
                   "status": "TRIAGE" if rules_without else "OK",
                   "detail": f"reguły MISSING (bez żadnej podstawy): {rules_without} "
                             f"(AP01; rejestr defektów prawnych P45)"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if violations:
        findings.append({"severity": "HIGH",
                         "message": f"cytowania poza kanonem: {len(violations)} — wymagana migracja do kanonu (I12 style guide)"})

    routing = "BLOCK_AND_ALERT" if violations else ("TRIAGE_QUEUE" if rules_without else "AUTO_FILE")
    metrics = {"citations_total": total, "canon_ok": len(in_canon),
               "canon_violations": len(violations),
               "rules_without_legal_basis": rules_without, "routing": routing}
    evidence = {"sample_violations": violations[:10], "sample_ok": in_canon[:5],
                "checks": checks, "findings": findings}
    write_bundle("citation_linter", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
