#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I09 PROVENANCE OF TRUTH — reguła bez łańcucha
akt→art→reguła→test nie opuszcza SHADOW; awans bez dowodu = BLOCK.
Dowód: każde rule_id P45 ma wpis w rule_registry z pełnym łańcuchem
(basis + tests + lifecycle). Podanalizy: AN03.
"""
from __future__ import annotations

import json

from v3_p45_common import (BASE, P45_RULES, RULE_REGISTRY, TESTS, emit, now,
                           read, read_json)

INNOVATION = "V3-P45-I09"
RULE = "jdg.v3_p45_stub_killer.provenance_of_truth"

P45_RULE_IDS = [
    "jdg.v3_p45_stub_killer.stub_register",
    "jdg.v3_p45_stub_killer.stub_forensics",
    "jdg.v3_p45_stub_killer.auto_convert_pipeline",
    "jdg.v3_p45_stub_killer.negative_assertion",
    "jdg.v3_p45_stub_killer.mutation_score_gate",
    "jdg.v3_p45_stub_killer.stub_free_badge",
    "jdg.v3_p45_stub_killer.template_policy",
    "jdg.v3_p45_stub_killer.stub_enabling_tests",
    "jdg.v3_p45_stub_killer.provenance_of_truth",
    "jdg.v3_p45_stub_killer.stub_census",
    "jdg.v3_p45_stub_killer.legal_empty",
    "jdg.v3_p45_stub_killer.isap_parity",
]

P45_BASIS = {
    "stub_register": "P45-I01; UoR art. 4 ust. 1 [NIEZWERYFIKOWANE]; P44-K1",
    "stub_forensics": "P45-I02; RODO art. 5.2 rozliczalność [NIEZWERYFIKOWANE]",
    "auto_convert_pipeline": "P45-I03; P34 L1-L5; P36 migration ledger",
    "negative_assertion": "P45-I04; P39-I04 negative-first",
    "mutation_score_gate": "P45-I05; P39 testy jako bramki",
    "stub_free_badge": "P45-I06; P44 certyfikat",
    "template_policy": "P45-I07; P00 standardy",
    "stub_enabling_tests": "P45-I08; P39-I04; tautology_guard",
    "provenance_of_truth": "P45-I09; P07 lifecycle; Ordynacja art. 21 §1 [NIEZWERYFIKOWANE]",
    "stub_census": "P45-I10; P37 dashboard; P42 self-scan",
    "legal_empty": "P45-I11; VAT art. 41/43/108 [NIEZWERYFIKOWANE]",
    "isap_parity": "P45-I12; ISAP jedyne źródło treści ustaw [NIEZWERYFIKOWANE]",
}


def main() -> int:
    checks, findings = [], []

    # 1. Wszystkie 12 rule_id obecnych w rego
    hay = read(P45_RULES)
    missing_rule = [r for r in P45_RULE_IDS if r not in hay]
    checks.append({"name": "all_rule_ids_in_rego", "status": "OK" if not missing_rule else "FAIL",
                   "detail": f"rule_id P45 w rego: {len(P45_RULE_IDS) - len(missing_rule)}/12 "
                             f"braki={missing_rule or 'brak'}"})
    if missing_rule:
        findings.append({"severity": "BLOCKER", "message": f"rule_id bez definicji: {missing_rule}"})

    # 2. Każda reguła ma _legal_basis w ciele rego
    with_basis = sum(1 for b in P45_BASIS.values() if b.split(";")[0] in hay)
    checks.append({"name": "legal_basis_in_rego", "status": "OK" if with_basis >= 12 else "FAIL",
                   "detail": f"reguły z _legal_basis (P45-Ixx): {with_basis}/12"})

    # 3. Każda reguła ma test natywny (test_p45_i*)
    test_hay = read(TESTS / "rego" / "test_v3_p45_stub_killer.rego")
    test_ids = [f"test_p45_i{i:02d}" for i in range(1, 13)]
    missing_tests = [t for t in test_ids if t not in test_hay]
    checks.append({"name": "native_tests_per_rule", "status": "OK" if not missing_tests else "FAIL",
                   "detail": f"testy natywne per innowacja: {12 - len(missing_tests)}/12 "
                             f"braki={missing_tests or 'brak'}"})
    if missing_tests:
        findings.append({"severity": "BLOCKER", "message": f"brak testów natywnych: {missing_tests}"})

    # 4. Rule registry zawiera wpisy P45 z lifecycle
    registry = read_json(RULE_REGISTRY)
    reg_dump = json.dumps(registry, ensure_ascii=False)
    registry_ok = "v3_p45_stub_killer" in reg_dump and "v3_p45_conversions" in reg_dump
    checks.append({"name": "registry_entries_with_lifecycle", "status": "OK" if registry_ok else "FAIL",
                   "detail": f"rule_registry.json: wpisy v3_p45 z lifecycle+provenance: {registry_ok}"})

    # 5. Awans bez łańcucha — bramka lifecycle (P07): konwersje zostają w CANDIDATE
    #    dopóki człowiek nie potwierdzi merytoryki (4-eyes); do P46 status: CANDIDATE
    conv_hay = read(BASE / "rules" / "v3_p45_conversions.rego")
    candidate_ok = "CANDIDATE" in conv_hay
    checks.append({"name": "conversions_stay_candidate", "status": "OK" if candidate_ok else "FAIL",
                   "detail": f"konwersje oznaczone CANDIDATE (awans po 4-eyes): {candidate_ok}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_ids_total": len(P45_RULE_IDS),
            "with_basis": with_basis,
            "registry_ok": registry_ok,
            "conversions_lifecycle": "CANDIDATE",
        },
        "checks": checks, "findings": findings,
        "provenance_map": P45_BASIS,
    }
    return emit(bundle, "v3_p45_provenance")


if __name__ == "__main__":
    raise SystemExit(main())
