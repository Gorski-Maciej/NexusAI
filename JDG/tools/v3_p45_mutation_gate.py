#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I05 MUTATION SCORE GATE — próg mutation score per
domena (VAT ≥90); spadek poniżej progu = BLOCKER; brak pomiaru dla domeny
krytycznej = TRIAGE. Dowód: bundles/mutation_results.json z silnika
tools/mutation_runner.py (realne mutanty, nie deklaracja). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p45_common import (BASE, MUTATION_RESULTS, emit, now, read_json,
                           rule_present, threshold_present)

INNOVATION = "V3-P45-I05"
RULE = "jdg.v3_p45_stub_killer.mutation_score_gate"
MUTATION_MIN = 90  # próg per domena (Sekcja 5.4; data-threshold w rego)


def main() -> int:
    checks, findings = [], []

    results = read_json(MUTATION_RESULTS)
    score = results.get("mutation_score")
    has_results = isinstance(results, dict) and results.get("total_mutants", 0) > 0
    checks.append({"name": "mutation_results_exist",
                   "status": "OK" if has_results else "FAIL",
                   "detail": f"bundles/mutation_results.json: "
                             f"{results.get('killed', '?')}/{results.get('total_mutants', '?')} mutantów zabitych"
                             if has_results else "brak wyników — uruchom tools/mutation_runner.py"})

    if has_results and score is not None:
        checks.append({"name": "mutation_score_above_min",
                       "status": "OK" if score >= MUTATION_MIN else "FAIL",
                       "detail": f"mutation score={score}% vs próg={MUTATION_MIN}%"})
        if score < MUTATION_MIN:
            findings.append({"severity": "BLOCKER",
                             "message": f"mutation score {score}% poniżej progu {MUTATION_MIN}% — testy nie dowodzą semantyki"})
    else:
        findings.append({"severity": "BLOCKER", "message": "brak pomiaru mutation score"})

    # Semantyczne operatory M1-M3 mają realnych mutantów
    mutators = results.get("mutators", {}) if isinstance(results, dict) else {}
    m1 = mutators.get("M1_threshold_shift", {})
    m2 = mutators.get("M2_condition_invert", {})
    m3 = mutators.get("M3_else_removal", {})
    semantic_mutants = (m1.get("applicable", 0) + m2.get("applicable", 0)
                        + m3.get("applicable", 0))
    checks.append({"name": "semantic_mutants_applied", "status": "OK" if semantic_mutants >= 5 else "FAIL",
                   "detail": f"mutanty semantyczne M1+M2+M3: {semantic_mutants} "
                             f"(M1={m1.get('applicable', 0)}, M2={m2.get('applicable', 0)}, M3={m3.get('applicable', 0)})"})

    # Próg jako dane (ADR-002)
    th_ok = threshold_present("v3_p45_mutation_score_min")
    checks.append({"name": "threshold_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": f"data.jdg.thresholds.v3_p45.v3_p45_mutation_score_min: {th_ok}"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if semantic_mutants < 5:
        findings.append({"severity": "HIGH",
                         "message": f"za mało mutantów semantycznych ({semantic_mutants} < 5) — rozszerz operatory"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "mutation_score": score,
            "mutation_score_min": MUTATION_MIN,
            "total_mutants": results.get("total_mutants", 0),
            "killed": results.get("killed", 0),
            "semantic_mutants": semantic_mutants,
            "engine": "tools/mutation_runner.py",
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p45_mutation_gate")


if __name__ == "__main__":
    raise SystemExit(main())
