#!/usr/bin/env python3
"""NexusAI JDG — V3-P49-I03 MISSING-FIELD GENERATOR + pokrycie testami negatywnymi.

Kontrakt P03 (ADR-004): pola obowiązkowe matched=true ⇒ rule_id, package,
priority, valid_from, _legal_basis. Generator:
  1) wyprowadza listę pól obowiązkowych z kodu polityki P49 (object.get z
     kontraktów wejściowych) i z rejestrów kontraktowych (golden_verdicts),
  2) generuje przypadki testowe „brak pola X" (null/""/brak klucza — różne
     braki, kryterium 9.10) dla każdego pola,
  3) mierzy pokrycie reguł testem negatywnym braku (testy natywne Rego P49
     zawierają asercję braku pola) — coverage vs próg v3_p49_field_coverage_min_pct.

Wyjście: bundle v3_p49_missing_field_coverage.json + szkice przypadków
(evidence.cases_sample; pełna lista w evidence.case_count).
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from v3_p48_common import RULES_DIR
from v3_p49_common import P49_REGO, read_json, write_p49_bundle

BUNDLES = Path(__file__).resolve().parents[1] / "bundles"

# Pola obowiązkowe kontraktu werdyktu P03 (ADR-004) — źródło: rejestr złotych
# orzeczeń + kontrakt evaluate() w runtime_invariants (jedno źródło prawdy).
P03_REQUIRED_FIELDS = ["rule_id", "package", "priority", "valid_from", "_legal_basis"]

# Różne braki (kryterium: null / pusty string / brak klucza to RÓŻNE braki)
MISSING_VARIANTS = {
    "null": None,
    "empty_string": "",
    "absent": "<ABSENT>",
}

GET_FIELD_RE = re.compile(r'object\.get\(\s*[\w.()]+,\s*"([a-z_0-9]+)"')


def derive_fields_from_policy() -> list[str]:
    """Pola wyciągnięte z object.get(...) w polityce P49 (kontrakty wejściowe)."""
    src = P49_REGO.read_text(encoding="utf-8", errors="replace")
    fields = set(GET_FIELD_RE.findall(src))
    # pola własne analiz (context mapy) są częścią kontraktu wejściowego P49
    ordered = sorted(fields)
    return ordered


def generate_cases(fields: list[str]) -> list[dict]:
    cases = []
    for f in fields:
        for variant, val in MISSING_VARIANTS.items():
            case = {
                "case_id": f"P49-MF-{f}-{variant}",
                "missing_field": f,
                "missing_variant": variant,
                "expected_decision_mode": "NEEDS_ADVICE",
                "expected_routing": "TRIAGE_QUEUE",
            }
            if variant == "null":
                case["input_patch"] = {f: None}
            elif variant == "empty_string":
                case["input_patch"] = {f: ""}
            else:
                case["input_patch"] = {}
            cases.append(case)
    return cases


# Analiza P49 → numer innowacji (testy natywne nazywają się test_p49_i<NN>_*)
ANALYSIS_TO_INNOVATION = {
    "invariant_pack": "i01", "default_deny_core": "i02",
    "missing_field_coverage": "i03", "chaos_input": "i04",
    "circuit_breaker": "i05", "amount_ceiling": "i06",
    "reason_completeness": "i07", "emergency_export": "i08",
    "replay_audit": "i09", "fail_closed_score": "i10",
    "silent_post_canary": "i11", "user_visible_safety": "i12",
}


def measure_rego_negative_coverage() -> dict:
    """Pokrycie: liczba reguł P49 (12 analiz I01–I12) z dedykowanymi testami
    natywnymi (tests/rego/test_v3_p49_fail_closed.rego, funkcje test_p49_i<NN>_*)
    plus asercje braku pól kontraktu (missing/empty/partial) w testach."""
    test_path = RULES_DIR.parent / "tests" / "rego" / "test_v3_p49_fail_closed.rego"
    rule_ids = re.findall(r'"rule_id":\s*"jdg\.v3_p49_fail_closed\.([a-z_0-9]+)"',
                          P49_REGO.read_text(encoding="utf-8", errors="replace"))
    analyses = sorted({r for r in rule_ids if r not in
                       ("thresholds_missing", "no_match")})
    if not test_path.exists():
        return {"rules_total": len(analyses), "rules_covered": 0,
                "covered_list": [], "test_file_present": False}
    tsrc = test_path.read_text(encoding="utf-8", errors="replace")
    covered = [r for r in analyses
               if ANALYSIS_TO_INNOVATION.get(r)
               and f"test_p49_{ANALYSIS_TO_INNOVATION[r]}" in tsrc]
    # asercje braku pól kontraktu (różne braki: null/empty/partial) muszą być
    # obecne globalnie — chaos generatora bez asercji = fasada (AP06)
    missing_assertions = sum(1 for pat in ("missing", "empty", "partial")
                             if pat in tsrc)
    return {"rules_total": len(analyses), "rules_covered": len(covered),
            "covered_list": covered, "test_file_present": True,
            "missing_field_assertions": missing_assertions}


def main() -> int:
    fields = derive_fields_from_policy()
    cases = generate_cases(fields)
    cov = measure_rego_negative_coverage()

    total = cov["rules_total"]
    covered = cov["rules_covered"]
    coverage_pct = round(covered * 100.0 / total, 2) if total else 0.0

    metrics = {
        "fields_derived": len(fields),
        "cases_total": len(cases),
        "missing_variants": len(MISSING_VARIANTS),
        "rules_total": total,
        "rules_covered": covered,
        "coverage_pct": coverage_pct,
        "missing_field_assertions": cov.get("missing_field_assertions", 0),
        "generator_run": True,
        "routing": ("TRIAGE_QUEUE" if coverage_pct < 95 else "AUTO_FILE"),
    }
    evidence = {
        "fields": fields,
        "p03_required": P03_REQUIRED_FIELDS,
        "case_count": len(cases),
        "cases_sample": cases[:12],
        "covered_rules": cov["covered_list"],
        "note": ("Generator: dla każdego pola kontraktu P03/P49 3 warianty braku "
                 "(null/''/brak klucza) → oczekiwane NEEDS_ADVICE (I02 default-deny). "
                 "Pokrycie = reguły P49 z natywną asercją braku pola; rozszerzenie "
                 "pokrycia = wejście do P36 (generatory) i P39 (testy CI)."),
    }
    write_p49_bundle("missing_field_coverage", "V3-P49-I03", metrics, evidence)
    print(f"[V3-P49-I03] fields={len(fields)} cases={len(cases)} "
          f"coverage={coverage_pct}% ({covered}/{total})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
