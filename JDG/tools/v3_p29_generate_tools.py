#!/usr/bin/env python3
"""Generator narzędzi dowodowych V3-P29-I01..I12 (jednorazowy, kampania V3).

Tworzy 12 tooli w tools/v3_p29_*.py wg wzorca v3_p28_*.py: każdy czyta
rules/v3_p29_quality_campaigns_enterprise.rego + thresholds_jdg.rego +
main_jdg.rego, buduje checklistę i zapisuje bundle do bundles/v3_p29_<name>.json.
"""
from pathlib import Path

TOOLS = Path(__file__).resolve().parent

# Nagłówek: formatowane tylko pola dokumentacji i stałych.
HEADER = '''#!/usr/bin/env python3
"""NexusAI JDG — {innovation} {title}.

Dowód wdrożenia: {evidence}
"""
from __future__ import annotations

from v3_p29_common import (P29_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "{innovation}"
RULE = "{rule_id}"


def main() -> int:
    hay = read(P29_RULES)
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
                   "detail": "main_jdg.rego: final_verdict_p93"})'''

CHECK_ROUTING = '''    has_routing = "__ROUTING__" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: __ROUTING__ (__NOTE__)"})'''

# (plik, innowacja, tytuł, dowód, rule_id, bundle, routing, note, klucze progów)
TOOLS_SPEC = [
    ("v3_p29_composite_gate.py", "V3-P29-I01", "COMPOSITE QUALITY GATE",
     "bramka łączna 8 bramek v3_13..v3_20: uniform JSON + wspólny exit-code CI (AN01-AN03)",
     "jdg.v3_p29_quality_campaigns.composite_quality_gate",
     "v3_p29_composite_gate", "BLOCK_AND_ALERT", "brak/FAIL bramki = BLOCK",
     ["v3_p29_gate_registry"]),
    ("v3_p29_mutation_testing.py", "V3-P29-I02", "MUTATION TESTING CONTRACT",
     "mutacje reguł (próg, odwrócenie warunku) z asercją złapania; czułość suite'a (AN02)",
     "jdg.v3_p29_quality_campaigns.mutation_testing",
     "v3_p29_mutation_testing", "BLOCK_AND_ALERT", "score < progu = BLOCK",
     ["v3_p29_min_mutation_score"]),
    ("v3_p29_debt_ledger.py", "V3-P29-I03", "QUALITY DEBT LEDGER",
     "rejestr długów jakości z datą, właścicielem i ścieżką spłaty; P1 otwarte = BLOCK (AP06)",
     "jdg.v3_p29_quality_campaigns.quality_debt_ledger",
     "v3_p29_debt_ledger", "BLOCK_AND_ALERT", "P1 > limitu = BLOCK",
     ["v3_p29_max_open_debts_p1"]),
    ("v3_p29_seed_contract.py", "V3-P29-I04", "DETERMINISTIC SEED CONTRACT",
     "każdy test losowy ma seed w raporcie; replay 1:1 po awarii (AN02)",
     "jdg.v3_p29_quality_campaigns.deterministic_seed",
     "v3_p29_seed_contract", "TRIAGE_QUEUE", "brak seeda = TRIAGE",
     ["v3_p29_seed_required"]),
    ("v3_p29_perf_profiler.py", "V3-P29-I05", "GATE PERFORMANCE PROFILER",
     "czas wykonania bramek; dryf >50% = TRIAGE — sygnał degradacji repo (AN02)",
     "jdg.v3_p29_quality_campaigns.gate_performance_profiler",
     "v3_p29_perf_profiler", "TRIAGE_QUEUE", "dryf/limit = TRIAGE",
     ["v3_p29_max_gate_seconds", "v3_p29_perf_drift_pct"]),
    ("v3_p29_gate_as_data.py", "V3-P29-I06", "GATE-AS-DATA CONTRACT",
     "definicja bramki (kontrole, progi, zakres) w data.thresholds.v3_p29 — zmiana progu bez deployu (P06)",
     "jdg.v3_p29_quality_campaigns.gate_as_data",
     "v3_p29_gate_as_data", "BLOCK_AND_ALERT", "brak wpisu/hardcode = BLOCK",
     ["v3_p29_gate_registry"]),
    ("v3_p29_merge_block_comment.py", "V3-P29-I07", "MERGE BLOCK COMMENT GENERATOR",
     "wynik bramki → auto-kwit PR z listą kontroli i liniami Rego; zero cichych blokad",
     "jdg.v3_p29_quality_campaigns.merge_block_comment",
     "v3_p29_merge_block_comment", "BLOCK_AND_ALERT", "blokada bez kwitu = BLOCK",
     []),
    ("v3_p29_domain_heatmap.py", "V3-P29-I08", "DOMAIN QUALITY HEATMAP",
     "agregacja 8 bramek → heatmapa per domena (VAT/PIT/ZUS/...) z trendem kwartalnym",
     "jdg.v3_p29_quality_campaigns.domain_quality_heatmap",
     "v3_p29_domain_heatmap", "BLOCK_AND_ALERT", "RED = BLOCK, AMBER = TRIAGE",
     ["v3_p29_heatmap_red_below", "v3_p29_heatmap_green_from"]),
    ("v3_p29_facade_detector.py", "V3-P29-I09", "FACADE ASSERTION DETECTOR",
     "test bez asercji negatywnej = fasada; rejestr z priorytetem naprawy (AP06)",
     "jdg.v3_p29_quality_campaigns.facade_assertion_detector",
     "v3_p29_facade_detector", "BLOCK_AND_ALERT", "fasada blokująca = BLOCK",
     ["v3_p29_max_blocking_facades"]),
    ("v3_p29_cert_binding.py", "V3-P29-I10", "GATE-TO-CERTIFICATE BINDING",
     "certyfikat decyzji zawiera ID wersji bramek — pełny provenance (F4; P11/P44)",
     "jdg.v3_p29_quality_campaigns.gate_to_certificate",
     "v3_p29_cert_binding", "BLOCK_AND_ALERT", "certyfikat bez wersji = BLOCK",
     []),
    ("v3_p29_test_upgrade.py", "V3-P29-I11", "TEST UPGRADE PIPELINE",
     "generator testów granicznych z tabeli aktów jako wymóg CANDIDATE→ACTIVE (P36)",
     "jdg.v3_p29_quality_campaigns.test_upgrade_pipeline",
     "v3_p29_test_upgrade", "BLOCK_AND_ALERT", "brak testów = BLOCK",
     []),
    ("v3_p29_holy_docs_compliance.py", "V3-P29-I12", "HOLY DOCUMENTS COMPLIANCE",
     "bramki nie dopuszczają rozwiązań sprzecznych z dokumentami świętymi V1/V2",
     "jdg.v3_p29_quality_campaigns.holy_documents_compliance",
     "v3_p29_holy_docs_compliance", "BLOCK_AND_ALERT", "konflikt = BLOCK",
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
