#!/usr/bin/env python3
"""Generator narzędzi dowodowych V3-P27-I01..I13 (jednorazowy, kampania V3).

Tworzy 13 tooli w tools/v3_p27_*.py wg wzorca v3_p26_*.py: każdy czyta
rules/v3_p27_cfc_exit_mdr_enterprise.rego + thresholds_jdg.rego + main_jdg.rego,
buduje checklistę i zapisuje bundle do bundles/v3_p27_<name>.json.
"""
from pathlib import Path

TOOLS = Path(__file__).resolve().parent

# Nagłówek: formatowane tylko pola dokumentacji i stałych.
HEADER = '''#!/usr/bin/env python3
"""NexusAI JDG — {innovation} {title}.

Dowód wdrożenia: {evidence}
"""
from __future__ import annotations

from v3_p27_common import (P27_RULES, THRESHOLDS, MAIN_JDG, emit, legacy_stub_hits,
                           main_jdg_wired, now, read, rule_present,
                           stub_scan, threshold_present)

INNOVATION = "{innovation}"
RULE = "{rule_id}"


def main() -> int:
    hay = read(P27_RULES)
    checks, findings = [], []

'''

# Treść: nieformatowany sufix — dowolne nawiasy bez escapowania.
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
                   "detail": "main_jdg.rego: final_verdict_p91"})'''

CHECK_ROUTING = '''    has_routing = "__ROUTING__" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: __ROUTING__ (__NOTE__)"})'''

LEGACY_SCAN_CODE = '''    legacy = legacy_stub_hits()
    ap_hits = {k: len(v) for k, v in legacy.items() if v}
    checks.append({"name": "legacy_ap_scan", "status": "OK" if not ap_hits else "FAIL",
                   "detail": f"anty-wzorce w plikach legacy: {ap_hits or 'brak'}"})'''

# (plik, innowacja, tytuł, dowód, rule_id, bundle, routing, note, klucze progów)
TOOLS_SPEC = [
    ("v3_p27_architecture_register.py", "V3-P27-I01", "ARCHITECTURE DECISION REGISTER",
     "rejestr decyzji CFC/PAiN/rulingi/MDR/exit — wejście do P44 (jawne decyzje z uzasadnieniem)",
     "jdg.v3_p27_cfc_exit_mdr.architecture_decision_register",
     "v3_p27_architecture_register", "SUGGEST", "rejestr dokumentowany",
     ["v3_p27_threshold_version"]),
    ("v3_p27_exit_tax_signal_monitor.py", "V3-P27-I02", "EXIT TAX SIGNAL MONITOR",
     "sygnały rezydencja/majątek/funkcja → zawsze NEEDS_ADVICE; nigdy automatyczna deklaracja (AP03/AP07)",
     "jdg.v3_p27_cfc_exit_mdr.exit_tax_signal_monitor",
     "v3_p27_exit_tax_signal_monitor", "NEEDS_ADVICE", "zawsze doradca",
     ["v3_p27_exit_tax_property_threshold_pln", "v3_p27_exit_tax_reinvestment_lock_years",
      "v3_p27_exit_tax_installments_eea"]),
    ("v3_p27_exit_tax_threshold_verifier.py", "V3-P27-I03", "EXIT TAX THRESHOLD VERIFIER",
     "progi 2M/4M PLN [ZWERYFIKOWANO-WEB]; rozbieżność bazy wiedzy = BLOCK_AND_ALERT (ISAP gate)",
     "jdg.v3_p27_cfc_exit_mdr.exit_tax_threshold_verifier",
     "v3_p27_exit_tax_threshold_verifier", "BLOCK_AND_ALERT", "drift blokuje",
     ["v3_p27_verifier_version", "v3_p27_verifier_drift_pln"]),
    ("v3_p27_mdr_hallmark_scorer.py", "V3-P27-I04", "MDR HALLMARK SCORER V2",
     "scoring + HUMAN REVIEW — nigdy automatyczny raport (kontrakt P22)",
     "jdg.v3_p27_cfc_exit_mdr.mdr_hallmark_scorer_v2",
     "v3_p27_mdr_hallmark_scorer", "BLOCK_AND_ALERT", "brak human approval = BLOCK",
     ["v3_p27_mdr_human_review_score"]),
    ("v3_p27_mdr_30day_gate.py", "V3-P27-I05", "MDR 30-DAY GATE",
     "termin 30 dni w kalendarzu P25; T-7 alarm; weekend shift; zero-ciszy",
     "jdg.v3_p27_cfc_exit_mdr.mdr_30day_gate",
     "v3_p27_mdr_30day_gate", "BLOCK_AND_ALERT", "przegapienie = BLOCK",
     ["v3_p27_mdr_warn_days", "v3_p27_mdr_weekend_shift", "v3_p27_mdr_zero_silence"]),
    ("v3_p27_mdr_auxiliary_function.py", "V3-P27-I06", "MDR AUXILIARY FUNCTION CHECK",
     "kryterium kwalifikowanego korzystającego 10M/2.5M EUR [ZWERYFIKOWANO-WEB]; 50M PLN z promptu [NIEZWERYFIKOWANE]",
     "jdg.v3_p27_cfc_exit_mdr.mdr_auxiliary_function",
     "v3_p27_mdr_auxiliary_function", "NEEDS_ADVICE", "powyżej kryterium = doradca",
     ["v3_p27_mdr_qualified_beneficiary_eur", "v3_p27_mdr_arrangement_value_eur",
      "v3_p27_mdr_auxiliary_excludes"]),
    ("v3_p27_cfc_signal_detector.py", "V3-P27-I07", "CFC SIGNAL DETECTOR",
     "sygnały CFC → WYŁĄCZNIE NEEDS_ADVICE; nigdy automatyczna kalkulacja podatku",
     "jdg.v3_p27_cfc_exit_mdr.cfc_signal_detector",
     "v3_p27_cfc_signal_detector", "NEEDS_ADVICE", "sygnał = doradca",
     ["v3_p27_cfc_ownership_min_pct", "v3_p27_cfc_passive_signal_pct",
      "v3_p27_cfc_de_minimis_eur"]),
    ("v3_p27_invariants.py", "V3-P27-I08", "INTERNATIONAL INVARIANTS PACK",
     "INV-X01 MDR human-only / INV-X02 exit tax advisor-only / INV-X03 CFC need-advice / INV-X04 zero AUTO_POST (kontrakt P04)",
     "jdg.v3_p27_cfc_exit_mdr.international_invariants_pack",
     "v3_p27_invariants", "BLOCK_AND_ALERT", "naruszenie = BLOCK",
     ["v3_p27_invariants_active", "v3_p27_mdr_human_only",
      "v3_p27_exit_tax_advisor_only", "v3_p27_cfc_needs_advice_only"]),
    ("v3_p27_exit_tax_documentation.py", "V3-P27-I09", "EXIT TAX DOCUMENTATION PACK",
     "checklista wyceny: metoda z katalogu + dokumenty + opinia; brak = NEEDS_ADVICE",
     "jdg.v3_p27_cfc_exit_mdr.exit_tax_documentation",
     "v3_p27_exit_tax_documentation", "NEEDS_ADVICE", "niekompletna checklista = doradca",
     ["v3_p27_valuation_methods"]),
    ("v3_p27_ruling_path_advisor.py", "V3-P27-I10", "RULING PATH ADVISOR",
     "ścieżka wniosków o wiążące informacje; złożenie zawsze human-only (decyzja rejestru I01)",
     "jdg.v3_p27_cfc_exit_mdr.ruling_path_advisor",
     "v3_p27_ruling_path_advisor", "NEEDS_ADVICE", "wniosek = ścieżka doradcza", []),
    ("v3_p27_golden_set.py", "V3-P27-I11", "GOLDEN INTERNATIONAL SET",
     "granice 2M/4M exit tax, 30 dni MDR, 183 dni rezydencji, de minimis CFC; niezgodność = BLOCK (P10)",
     "jdg.v3_p27_cfc_exit_mdr.international_golden_set",
     "v3_p27_golden_set", "BLOCK_AND_ALERT", "niezgodność = BLOCK",
     ["v3_p27_golden_version", "v3_p27_golden_tolerance"]),
    ("v3_p27_stress_lab.py", "V3-P27-I12", "INTERNATIONAL STRESS LAB",
     "RESIDENCE_MIDYEAR / MDR_DEADLINE_WEEKEND / THRESHOLD_BOUNDARY; brak kompletu = TRIAGE (P04 K10)",
     "jdg.v3_p27_cfc_exit_mdr.international_stress_lab",
     "v3_p27_stress_lab", "BLOCK_AND_ALERT", "scenariusz FAIL = BLOCK",
     ["v3_p27_stress_required_scenarios"]),
    ("v3_p27_cross_domain_flow_gate.py", "V3-P27-I13", "CROSS-DOMAIN FLOW GATE",
     "harmonizacja kursów P15 (D-1), kalendarza P25, odsetek rat P17, AML P22; brak = TRIAGE",
     "jdg.v3_p27_cfc_exit_mdr.cross_domain_flow_gate",
     "v3_p27_cross_domain_flow_gate", "TRIAGE_QUEUE", "brak harmonizacji = TRIAGE", []),
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
    if innovation == "V3-P27-I08":
        body.append(LEGACY_SCAN_CODE)
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
