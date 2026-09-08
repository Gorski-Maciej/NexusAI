#!/usr/bin/env python3
"""Generator narzędzi dowodowych V3-P30-I01..I12 (jednorazowy, kampania V3).

Tworzy 12 tooli w tools/v3_p30_*.py wg wzorca v3_p29_*.py: każdy czyta
rules/v3_p30_innovation_waves_enterprise.rego + thresholds_jdg.rego +
main_jdg.rego, buduje checklistę i zapisuje bundle do bundles/v3_p30_<name>.json.
"""
from pathlib import Path

TOOLS = Path(__file__).resolve().parent

# Nagłówek: formatowane tylko pola dokumentacji i stałych.
HEADER = '''#!/usr/bin/env python3
"""NexusAI JDG — {innovation} {title}.

Dowód wdrożenia: {evidence}
"""
from __future__ import annotations

from v3_p30_common import (P30_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "{innovation}"
RULE = "{rule_id}"


def main() -> int:
    hay = read(P30_RULES)
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
                   "detail": "main_jdg.rego: final_verdict_p94"})'''

CHECK_ROUTING = '''    has_routing = "__ROUTING__" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: __ROUTING__ (__NOTE__)"})'''

# (plik, innowacja, tytuł, dowód, rule_id, bundle, routing, note, klucze progów)
TOOLS_SPEC = [
    ("v3_p30_deployment_registry.py", "V3-P30-I01", "DEPLOYMENT REGISTRY AS DATA",
     "rejestr wdrożeń jako dane; DONE wymaga dowodu test+artefakt+commit (AN04; kanon P00)",
     "jdg.v3_p30_innovation_waves.deployment_registry",
     "v3_p30_deployment_registry", "BLOCK_AND_ALERT", "DONE bez dowodu = BLOCK",
     ["v3_p30_registry_statuses"]),
    ("v3_p30_adopt_rate.py", "V3-P30-I02", "ADOPT-RATE DASHBOARD",
     "metryka per domena: % rekomendacji wdrożonych z dowodem; trend w P37 (AN04)",
     "jdg.v3_p30_innovation_waves.adopt_rate_dashboard",
     "v3_p30_adopt_rate", "TRIAGE_QUEUE", "adopt-rate < progu = TRIAGE",
     ["v3_p30_adopt_rate_min_pct"]),
    ("v3_p30_semantic_diff.py", "V3-P30-I03", "SEMANTIC DEPLOYMENT DIFF",
     "diff semantyczny rekomendacja→implementacja; wykrywa wdrożenia fasadowe (AP06)",
     "jdg.v3_p30_innovation_waves.semantic_deployment_diff",
     "v3_p30_semantic_diff", "BLOCK_AND_ALERT", "fasada = BLOCK",
     []),
    ("v3_p30_v4_selection.py", "V3-P30-I04", "V4 SELECTION CONTRACT",
     "scoring rekomendacji: wpływ na AUTO_POST, koszt, ryzyko prawne (AN04)",
     "jdg.v3_p30_innovation_waves.v4_selection_contract",
     "v3_p30_v4_selection", "TRIAGE_QUEUE", "brak scoringu = TRIAGE",
     ["v3_p30_v4_high_roi_min"]),
    ("v3_p30_pr_traceability.py", "V3-P30-I05", "RECOMMENDATION→PR TRACEABILITY",
     "każdy PR referuje ID rekomendacji; reverse-check PR bez pochodzenia (AN04)",
     "jdg.v3_p30_innovation_waves.recommendation_pr_traceability",
     "v3_p30_pr_traceability", "TRIAGE_QUEUE", "PR bez ref = TRIAGE",
     []),
    ("v3_p30_facade_winddown.py", "V3-P30-I06", "FACADE WIND-DOWN",
     "kampania usunięcia martwych plików fasadowych z rejestrem i skanem zależności (AP06)",
     "jdg.v3_p30_innovation_waves.facade_wind_down",
     "v3_p30_facade_winddown", "TRIAGE_QUEUE", "fasada z zależnościami = TRIAGE",
     []),
    ("v3_p30_risk_triage.py", "V3-P30-I07", "RECOMMENDATION RISK TRIAGE",
     "klasyfikacja trywialna/istotna/krytyczna; krytyczna = 4-eyes (AN04)",
     "jdg.v3_p30_innovation_waves.recommendation_risk_triage",
     "v3_p30_risk_triage", "BLOCK_AND_ALERT", "krytyczna bez 4-eyes = BLOCK",
     ["v3_p30_risk_classes"]),
    ("v3_p30_golden_replay.py", "V3-P30-I08", "GOLDEN REPLAY AFTER DEPLOYMENT",
     "każde wdrożenie uruchamia replay golden verdicts (P10); regresja blokuje merge",
     "jdg.v3_p30_innovation_waves.golden_replay",
     "v3_p30_golden_replay", "BLOCK_AND_ALERT", "replay FAIL = BLOCK",
     []),
    ("v3_p30_deployment_budget.py", "V3-P30-I09", "DEPLOYMENT BUDGET",
     "limit zmian w jednym wdrożeniu (maks. N reguł); awaria lokalizowalna (AN04)",
     "jdg.v3_p30_innovation_waves.deployment_budget",
     "v3_p30_deployment_budget", "BLOCK_AND_ALERT", "przekroczenie = BLOCK",
     ["v3_p30_max_rules_per_deployment"]),
    ("v3_p30_changelog.py", "V3-P30-I10", "DATA-DRIVEN CHANGELOG",
     "automatyczny changelog z rejestru wdrożeń (domena, rekomendacja, dowód, ryzyko)",
     "jdg.v3_p30_innovation_waves.data_driven_changelog",
     "v3_p30_changelog", "TRIAGE_QUEUE", "changelog pusty = TRIAGE",
     []),
    ("v3_p30_conflict_detector.py", "V3-P30-I11", "CONFLICTING DEPLOYMENT DETECTOR",
     "sprzeczne implementacje tej samej zasady między domenami (AP04)",
     "jdg.v3_p30_innovation_waves.conflicting_deployment_detector",
     "v3_p30_conflict_detector", "BLOCK_AND_ALERT", "konflikt = BLOCK",
     []),
    ("v3_p30_law_radar_loop.py", "V3-P30-I12", "LAW RADAR LOOP CLOSURE",
     "rekomendacje prawne z P08 automatycznie tworzą wpisy w rejestrze wdrożeń",
     "jdg.v3_p30_innovation_waves.law_radar_loop_closure",
     "v3_p30_law_radar_loop", "TRIAGE_QUEUE", "rekomendacja bez wpisu = TRIAGE",
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
