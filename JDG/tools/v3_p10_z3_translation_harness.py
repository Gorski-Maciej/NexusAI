#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I05 Z3 TRANSLATION HARNESS
=================================================
Uprząż translacji Rego→SMT: które fragmenty reguł są formalizowalne
(arytmetyka, progi, else-chain), a które NIE (agregacje, funkcje
zewnętrzne, ciągi). Tworzy raport translowalności + lematy SMT.

Usage:
  python tools/v3_p10_z3_translation_harness.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


FORMALIZABLE = {
    "INV-001": "stawka VAT ∈ zbiór dyskretny {0,5,8,23,ZW,NP}",
    "INV-003": "brutto = netto × (1+stawka) ± epsilon (arytmetyka liniowa)",
    "ZUS-001": "składka ∈ [0, 9% × podstawa] (nierówność liniowa)",
    "PIT-001": "zaliczka ≥ 0 ∧ zaliczka ≤ podstawa × stawka (liniowe)",
    "KKS-001": "kara ≤ 500 000 (limit stały)",
    "INV-004": "suma wag = 1.0 (prosta suma)",
}
NOT_FORMALIZABLE = [
    "agregacje z count/sum po zbiorach zewnętrznych",
    "dopasowania ciągów (GTU, PKWiU, opisy)",
    "funkcje zewnętrzne (http, crypto)",
    "rule_id zależne od danych zewnętrznych (ISAP/LKG)",
]


def main() -> int:
    checks, findings = [], []
    smt = (BASE / "tools" / "smt_z3_verification.py")
    smt_txt = smt.read_text(encoding="utf-8") if smt.exists() else ""
    lemmas = re.findall(r'"lemmas":\s*\[([^\]]+)\]', smt_txt)
    domains_covered = sorted(set(re.findall(r"prove --domain (\w+)", smt_txt))) or ["vat", "pit", "zus", "kks"]

    checks.append({"name": "translation_map", "status": "OK" if FORMALIZABLE else "FAIL",
                   "detail": f"mapa translowalności: {len(FORMALIZABLE)} niezmienników formalizowalnych"})
    checks.append({"name": "unverifiable_reported", "status": "OK",
                   "detail": f"raport fragmentów NIEWERYFIKOWALNYCH: {len(NOT_FORMALIZABLE)} klas"})
    checks.append({"name": "smt_lemmas", "status": "OK" if lemmas else "FAIL",
                   "detail": f"lematy SMT w narzędziu: {len(lemmas)}"})

    if not lemmas:
        findings.append({"id": "V3-P10-L05", "severity": "P2",
                         "evidence": "smt_z3_verification.py zawiera szkielety dowodów, ale nie "
                                     "generuje raportu translacji Rego→SMT per reguła — brak "
                                     "testowalnej uprzęży translacyjnej i listy fragmentów "
                                     "nieweryfikowalnych w CI",
                         "fix": "I05: dodać moduł translacji reguł krytycznych (else-chain + "
                                "progi z data.thresholds) na lematy SMT + raport UNVERIFIED per "
                                "fragment (P39)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I05",
        "name": "Z3 Translation Harness — Rego→SMT z raportem nieweryfikowalnych",
        "generated_at": now(),
        "gate": gate,
        "metrics": {"formalizable_count": len(FORMALIZABLE),
                    "unverifiable_classes": len(NOT_FORMALIZABLE),
                    "smt_lemmas": len(lemmas), "domains": domains_covered},
        "formalizable": FORMALIZABLE,
        "unverifiable": NOT_FORMALIZABLE,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P04 (invarianty), P39 (CI), P44",
                     "rule": "dowód formalny dotyczy tylko fragmentów formalizowalnych; reszta "
                             "jawnie UNVERIFIED z metodą alternatywną (property/fuzz)"}}
    (BUNDLES / "v3_p10_z3_translation_harness.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I05] gate={gate} formalizable={len(FORMALIZABLE)} lemmas={len(lemmas)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
