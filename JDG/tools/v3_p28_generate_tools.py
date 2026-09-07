#!/usr/bin/env python3
"""Generator narzędzi dowodowych V3-P28-I01..I12 (jednorazowy, kampania V3).

Tworzy 12 tooli w tools/v3_p28_*.py wg wzorca v3_p27_*.py: każdy czyta
rules/v3_p28_hyper_plan45_enterprise.rego + thresholds_jdg.rego + main_jdg.rego,
buduje checklistę i zapisuje bundle do bundles/v3_p28_<name>.json.
"""
from pathlib import Path

TOOLS = Path(__file__).resolve().parent

# Nagłówek: formatowane tylko pola dokumentacji i stałych.
HEADER = '''#!/usr/bin/env python3
"""NexusAI JDG — {innovation} {title}.

Dowód wdrożenia: {evidence}
"""
from __future__ import annotations

from v3_p28_common import (P28_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "{innovation}"
RULE = "{rule_id}"


def main() -> int:
    hay = read(P28_RULES)
    checks, findings = [], []

'''

TAIL = '''
    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": rule_present(RULE, hay),
            "wiring_main_jdg": main_jdg_wired(),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "__BUNDLE__")


if __name__ == "__main__":
    raise SystemExit(main())
'''

CHECK_RULE = '''    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})'''

CHECK_THRESH = '''    keys_missing = [k for k in __KEYS__ if not threshold_present(k)]
    checks.append({"name": "thresholds", "status": "OK" if not keys_missing else "FAIL",
                   "detail": f"brakujące klucze: {keys_missing or 'brak'}"})'''

CHECK_WIRING = '''    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p92"})'''

CHECK_ROUTING = '''    has_routing = "__ROUTING__" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: __ROUTING__ (__NOTE__)"})'''

# (plik, innowacja, tytuł, dowód, rule_id, bundle, routing, note, klucze progów)
TOOLS_SPEC = [
    ("v3_p28_hyper_context_map.py", "V3-P28-I01", "HYPER CONTEXT MAP",
     "mapa hiperkontekst→domeny→kontrakty→testy (AN01); 14 katalogów hyper/*; wejście do P44",
     "jdg.v3_p28_hyper_plan45.hyper_context_map",
     "v3_p28_hyper_context_map", "SUGGEST", "mapa dokumentowana",
     ["v3_p28_context_map_version"]),
    ("v3_p28_duplicate_detector.py", "V3-P28-I02", "DUPLICATE DETECTOR PACK",
     "detekcja duplikatów fx/limits → decyzja konsolidacji (AP04; fx=P15, limits=P06)",
     "jdg.v3_p28_hyper_plan45.duplicate_detector",
     "v3_p28_duplicate_detector", "TRIAGE_QUEUE", "niewykazany duplikat = TRIAGE",
     []),
    ("v3_p28_force_majeure.py", "V3-P28-I03", "FORCE MAJEURE FRAMEWORK",
     "kwalifikacja zdarzenia + zawieszenie terminów wg kalendarza P25 + degradacja NEEDS_ADVICE (AN03)",
     "jdg.v3_p28_hyper_plan45.force_majeure_framework",
     "v3_p28_force_majeure", "NEEDS_ADVICE", "okno siły wyższej = doradca",
     ["v3_p28_force_majeure_max_days", "v3_p28_force_majeure_calendar_p25_linked",
      "v3_p28_force_majeure_degradation"]),
    ("v3_p28_sanctions_gate.py", "V3-P28-I04", "SANCTIONS GATE",
     "lista sankcyjna → BLOCK + HUMAN REVIEW + AML P22; nigdy auto-transakcja (AN04)",
     "jdg.v3_p28_hyper_plan45.sanctions_gate",
     "v3_p28_sanctions_gate", "BLOCK_AND_ALERT", "brak human review = BLOCK",
     ["v3_p28_sanctions_list_version", "v3_p28_sanctions_human_review_required",
      "v3_p28_sanctions_aml_p22_linked"]),
    ("v3_p28_marginal_register.py", "V3-P28-I05", "MARGINAL DOMAIN DECISIONS",
     "rejestr decyzji taxfree/seasonal/insurance/advertising/regulated/procurement/esig (AN05; P44)",
     "jdg.v3_p28_hyper_plan45.marginal_domain_register",
     "v3_p28_marginal_register", "SUGGEST", "rejestr dokumentowany",
     ["v3_p28_marginal_register_version"]),
    ("v3_p28_esig_contract.py", "V3-P28-I06", "ESIG CONTRACT LAYER",
     "e-podpisy: klucz z kontraktu P11/P16; próg kwalifikowany z danych (eIDAS art. 25-26)",
     "jdg.v3_p28_hyper_plan45.esig_contract_layer",
     "v3_p28_esig_contract", "BLOCK_AND_ALERT", "brak klucza = BLOCK",
     ["v3_p28_esig_qualified_threshold_pln", "v3_p28_esig_contract_p11_p16"]),
    ("v3_p28_crisis_drill.py", "V3-P28-I07", "CRISIS DRILL RIG",
     "chaos: siła wyższa + KSeF down + termin → zero ciszy (P04 K10; AN09)",
     "jdg.v3_p28_hyper_plan45.crisis_drill",
     "v3_p28_crisis_drill", "BLOCK_AND_ALERT", "scenariusz FAIL = BLOCK",
     ["v3_p28_crisis_required_scenarios", "v3_p28_crisis_zero_silence"]),
    ("v3_p28_network_gate.py", "V3-P28-I08", "NETWORK CONSISTENCY GATE",
     "CI: hiperkontekst↔domena rozjazd = BLOCKER (mapa I01 egzekwowana; AN11)",
     "jdg.v3_p28_hyper_plan45.network_consistency_gate",
     "v3_p28_network_gate", "BLOCK_AND_ALERT", "rozjazd = BLOCK",
     ["v3_p28_network_expected_contexts", "v3_p28_network_gap_blocker"]),
    ("v3_p28_invariants.py", "V3-P28-I09", "HYPER INVARIANTS PACK",
     "INV-H01 sanctions human-only / INV-H02 FM kalendarz-only / INV-H03 fx jednolity / INV-H04 zero AUTO_POST (P04)",
     "jdg.v3_p28_hyper_plan45.hyper_invariants_pack",
     "v3_p28_invariants", "BLOCK_AND_ALERT", "naruszenie = BLOCK",
     ["v3_p28_invariants_active", "v3_p28_sanctions_human_only",
      "v3_p28_fm_calendar_only", "v3_p28_fx_single_engine",
      "v3_p28_hyper_no_silent_auto_post"]),
    ("v3_p28_golden_set.py", "V3-P28-I10", "HYPER GOLDEN SET",
     "granice: FM max dni, próg podpisu, komplet scenariuszy; niezgodność = BLOCK (P10)",
     "jdg.v3_p28_hyper_plan45.hyper_golden_set",
     "v3_p28_golden_set", "BLOCK_AND_ALERT", "niezgodność = BLOCK",
     ["v3_p28_golden_version", "v3_p28_golden_tolerance"]),
    ("v3_p28_cleanup_plan.py", "V3-P28-I11", "MARGINAL CLEANUP PLAN",
     "plan domknięcia domen marginalnych; pustynie = katalogi bez testów natywnych (AN07)",
     "jdg.v3_p28_hyper_plan45.marginal_cleanup_plan",
     "v3_p28_cleanup_plan", "TRIAGE_QUEUE", "pustynia = TRIAGE",
     ["v3_p28_cleanup_max_untested"]),
    ("v3_p28_explanation_engine.py", "V3-P28-I12", "HYPER EXPLANATION ENGINE",
     "wyjaśnienia prostym językiem: siła wyższa/sankcje/degradacja/esig/drill (V2 F4)",
     "jdg.v3_p28_hyper_plan45.hyper_explanation_engine",
     "v3_p28_explanation_engine", "TRIAGE_QUEUE", "nieznany temat = TRIAGE",
     []),
]


def build_tool(spec) -> str:
    (name, innovation, title, evidence, rule_id, bundle_name,
     routing, routing_note, keys) = spec
    body = [CHECK_RULE]
    if keys:
        pylist = "[" + ", ".join(f'"{k}"' for k in keys) + "]"
        body.append(CHECK_THRESH.replace("__KEYS__", pylist))
    if routing:
        body.append(CHECK_ROUTING.replace("__ROUTING__", routing)
                    .replace("__NOTE__", routing_note))
    body.append(CHECK_WIRING)
    tail = TAIL.replace("__BUNDLE__", bundle_name)
    return HEADER.format(innovation=innovation, title=title, evidence=evidence,
                         rule_id=rule_id) + "\n".join(body) + tail


def main() -> None:
    for spec in TOOLS_SPEC:
        (TOOLS / spec[0]).write_text(build_tool(spec), encoding="utf-8")
        print(f"wrote tools/{spec[0]}")


if __name__ == "__main__":
    main()
