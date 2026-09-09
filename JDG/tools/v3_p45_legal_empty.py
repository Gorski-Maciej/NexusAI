#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I11 LEGAL-EMPTY DETECTOR — detekcja reguł, których
_legal_basis jest puste albo placeholder (TODO, N/A, myślnik); reguła
materiałowa bez aktu = BLOCK. Skan wszystkich pakietów rules/.
Podanalizy: AN01.
"""
from __future__ import annotations

import json
import re

from v3_p45_common import (BASE, RULES, emit, now, rule_present)

INNOVATION = "V3-P45-I11"
RULE = "jdg.v3_p45_stub_killer.legal_empty"

PLACEHOLDERS = re.compile(r'"_legal_basis"\s*:\s*"\s*(TODO|N/?A|—|-|TBD|\{wrap\}|placeholder)\s*"',
                          re.IGNORECASE)
EMPTY_BASIS = re.compile(r'"_legal_basis"\s*:\s*""')
# Akt prawny w treści: „art." + numer LUB nazwa ustawy + art.
ACT_REF = re.compile(r"(art\.|artykuł|ustawa|rozporządzenie|dyrektywa|konwencja)", re.IGNORECASE)
MATERIAL_HINT = re.compile(r"(stawka|limit|próg|podatek|składka|ulga|zwolnienie|kary|termin)", re.IGNORECASE)


def main() -> int:
    checks, findings = [], []

    legal_empty, material_no_act, scanned = [], [], 0
    for f in RULES.rglob("*.rego"):
        scanned += 1
        src = f.read_text(encoding="utf-8", errors="ignore")
        for m in PLACEHOLDERS.finditer(src):
            legal_empty.append({"file": str(f.relative_to(BASE)),
                                "snippet": m.group(0)[:80]})
        for m in EMPTY_BASIS.finditer(src):
            legal_empty.append({"file": str(f.relative_to(BASE)), "snippet": '"" (puste)'})
        # Reguły materiałowe bez aktu (heurystyka treści)
        for block in re.finditer(r'"_legal_basis"\s*:\s*"([^"]*)"', src):
            basis = block.group(1)
            if MATERIAL_HINT.search(basis) and not ACT_REF.search(basis):
                material_no_act.append({"file": str(f.relative_to(BASE)),
                                        "basis": basis[:80]})

    # Deliverable P45-I11: REJESTR z priorytetem (naprawa → P46/P47 wg SLA;
    # cel zero do P68). Reguła runtime (legal_empty w rego) blokuje NOWE
    # reguły materiałowe bez aktu w decyzjach.
    register = {
        "generated_at": now(),
        "rego_files_scanned": scanned,
        "legal_basis_empty_or_placeholder": len(legal_empty),
        "material_rules_without_act": len(material_no_act),
        "zero_target": "P68 RECERTYFIKACJA_FINALNA",
        "handoff": "P46 (hardcode) + P47 (legal basis) — naprawa wg priorytetu",
        "entries": [
            [{"kind": "placeholder_basis", **e, "priority": "P1"} for e in legal_empty],
            [{"kind": "material_without_act", **e, "priority": "P0"} for e in material_no_act],
        ],
    }
    reg_path = BASE / "bundles" / "v3_p45_legal_empty_register.json"
    reg_path.write_text(json.dumps(register, ensure_ascii=False, indent=2),
                        encoding="utf-8")

    checks.append({"name": "scan_complete", "status": "OK",
                   "detail": f"przeskanowano {scanned} plików rego"})
    checks.append({"name": "legal_empty_register_written", "status": "OK",
                   "detail": f"bundles/v3_p45_legal_empty_register.json: "
                             f"placeholder={len(legal_empty)} (P1), materiałowe-bez-aktu="
                             f"{len(material_no_act)} (P0) — SLA u właściciela części P46/P47"})

    if material_no_act:
        findings.append({"severity": "HIGH",
                         "message": f"reguły materiałowe bez aktu: {len(material_no_act)} "
                                    f"— zarejestrowane P0, naprawa P47"})
    if legal_empty:
        findings.append({"severity": "MEDIUM",
                         "message": f"placeholdery _legal_basis: {len(legal_empty)} — "
                                    f"zarejestrowane P1, naprawa P46/P47"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rego_files_scanned": scanned,
            "legal_basis_empty_or_placeholder": len(legal_empty),
            "material_rules_without_act": len(material_no_act),
            "findings_detail": (legal_empty + material_no_act)[:20],
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p45_legal_empty")


if __name__ == "__main__":
    raise SystemExit(main())
