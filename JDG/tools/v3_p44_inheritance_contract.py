#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I05 V4 INHERITANCE CONTRACT — jawna lista kontraktów
dziedziczonych (standardy, schematy, bramki) — V4 nie zaczyna od zera.
Kontrakt bez source_of_truth = TRIAGE. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p44_common import BASE, CERT_REGISTER, emit, now, read_json, rule_present

INNOVATION = "V3-P44-I05"
RULE = "jdg.v3_p44_certyfikacja_finalna.v4_inheritance_contract"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    contracts = reg.get("v4_inheritance_contracts", []) if isinstance(reg, dict) else []
    with_sot = [c for c in contracts if isinstance(c, dict)
                and c.get("contract") and c.get("source_of_truth")]
    checks.append({"name": "contracts_with_sot", "status": "OK" if contracts and len(with_sot) == len(contracts) else "FAIL",
                   "detail": f"kontrakty ze źródłem prawdy: {len(with_sot)}/{len(contracts)}"})

    # Kontrakt wyjściowy istnieje fizycznie (sprawdzanie wskazanych plików)
    missing_sot: list[str] = []
    for c in with_sot:
        sot = str(c.get("source_of_truth", ""))
        # Ścieżki plików w source_of_truth sprawdzane; odwołania ADR/dokumenty pomijane
        cand = [tok for tok in sot.replace(";", " ").replace(",", " ").split()
                if tok.endswith((".rego", ".json", ".yml", ".yaml", ".md", ".txt"))]
        for path in cand:
            if not (BASE / path).exists():
                missing_sot.append(f"{c.get('contract')}: {path}")
    checks.append({"name": "sot_paths_exist", "status": "OK" if not missing_sot else "FAIL",
                   "detail": f"brakujące pliki source_of_truth: {missing_sot or 'brak'}"})

    if missing_sot:
        findings.append({"severity": "HIGH", "message": f"kontrakty bez fizycznego SOT: {missing_sot}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "contracts": len(contracts),
            "contracts_with_sot": len(with_sot),
            "missing_sot_paths": len(missing_sot),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_inheritance_contract")


if __name__ == "__main__":
    raise SystemExit(main())
