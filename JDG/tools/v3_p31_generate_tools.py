#!/usr/bin/env python3
"""Generator narzędzi dowodowych V3-P31-I01..I12 (jednorazowy, kampania V3).

Tworzy 12 tooli w tools/v3_p31_*.py wg wzorca v3_p30_*.py: każdy czyta
rules/v3_p31_audit_stages_enterprise.rego + thresholds_jdg.rego +
main_jdg.rego, buduje checklistę i zapisuje bundle do bundles/v3_p31_<name>.json.
"""
from pathlib import Path

TOOLS = Path(__file__).resolve().parent

# Nagłówek: formatowane tylko pola dokumentacji i stałych.
HEADER = '''#!/usr/bin/env python3
"""NexusAI JDG — {innovation} {title}.

Dowód wdrożenia: {evidence}
"""
from __future__ import annotations

from v3_p31_common import (P31_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "{innovation}"
RULE = "{rule_id}"


def main() -> int:
    hay = read(P31_RULES)
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
                   "detail": "main_jdg.rego: final_verdict_p95"})'''

CHECK_ROUTING = '''    has_routing = "__ROUTING__" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: __ROUTING__ (__NOTE__)"})'''

# (plik, innowacja, tytuł, dowód, rule_id, bundle, routing, note, klucze progów)
TOOLS_SPEC = [
    ("v3_p31_unified_schema.py", "V3-P31-I01", "UNIFIED AUDIT SCHEMA",
     "wspólny JSON-schema wyników etapów (pass/fail/partial z dowodami); automatyczna synteza (AN01-AN03)",
     "jdg.v3_p31_audit_stages.unified_audit_schema",
     "v3_p31_unified_schema", "BLOCK_AND_ALERT", "brak/FAIL etapu = BLOCK",
     []),
    ("v3_p31_conflict_detector.py", "V3-P31-I02", "CROSS-ETAP CONFLICT DETECTOR",
     "porównanie deklaracji etapów ze stanem aktualnym; sprzeczność = konflikt Cxx (AN04)",
     "jdg.v3_p31_audit_stages.cross_etap_conflict_detector",
     "v3_p31_conflict_detector", "BLOCK_AND_ALERT", "nierozstrzygnięty = BLOCK",
     []),
    ("v3_p31_red_team_pack.py", "V3-P31-I03", "RED TEAM PACK",
     "ataki regułowe (mutacje input, brakujące pola, skrajne daty) per domena (AN03)",
     "jdg.v3_p31_audit_stages.red_team_pack",
     "v3_p31_red_team_pack", "BLOCK_AND_ALERT", "atak bez fail-closed = BLOCK",
     ["v3_p31_min_red_team_attacks"]),
    ("v3_p31_risk_score.py", "V3-P31-I04", "RISK-OF-FORTRESS SCORE",
     "skalarne ryzyko z syntezy etapów+gate'ów+bramek; P37 + certyfikat P44 (AN04)",
     "jdg.v3_p31_audit_stages.risk_of_fortress_score",
     "v3_p31_risk_score", "BLOCK_AND_ALERT", "score > limitu = BLOCK",
     ["v3_p31_max_risk_of_fortress"]),
    ("v3_p31_stages_as_data.py", "V3-P31-I05", "ETAPY JAKO DANE",
     "definicje audytów etapowych w data.thresholds; zmiana audytu bez deployu (P06)",
     "jdg.v3_p31_audit_stages.stages_as_data",
     "v3_p31_stages_as_data", "BLOCK_AND_ALERT", "brak wpisu/hardcode = BLOCK",
     ["v3_p31_stage_registry"]),
    ("v3_p31_auto_rerun.py", "V3-P31-I06", "AUTO-RERUN PO NOWELIZACJI",
     "Law Radar P08 wyzwala rerun dotkniętych etapów po nowelizacji (AN04)",
     "jdg.v3_p31_audit_stages.auto_rerun_after_amendment",
     "v3_p31_auto_rerun", "TRIAGE_QUEUE", "nowelizacja bez reruna = TRIAGE",
     []),
    ("v3_p31_worm_trail.py", "V3-P31-I07", "WORM AUDIT TRAIL",
     "każdy run etapu zapisywany WORM z checksumą stanu repo (P43; AN04)",
     "jdg.v3_p31_audit_stages.worm_audit_trail",
     "v3_p31_worm_trail", "TRIAGE_QUEUE", "run bez WORM = TRIAGE",
     []),
    ("v3_p31_frontier_matrix.py", "V3-P31-I08", "FRONTIER MATRIX",
     "macierz etap×domena z datami ostatniego dowodu; wygasły >90 dni (AN01-AN03)",
     "jdg.v3_p31_audit_stages.frontier_matrix",
     "v3_p31_frontier_matrix", "TRIAGE_QUEUE", "dowód wygasły = TRIAGE",
     ["v3_p31_evidence_stale_days"]),
    ("v3_p31_conflict_resolution.py", "V3-P31-I09", "CONFLICT RESOLUTION PROCEDURE",
     "najnowszy dowód wygrywa; stara deklaracja do rejestru mediacji z reason (AN04)",
     "jdg.v3_p31_audit_stages.conflict_resolution",
     "v3_p31_conflict_resolution", "TRIAGE_QUEUE", "mediacja bez reason = TRIAGE",
     []),
    ("v3_p31_certpack.py", "V3-P31-I10", "CERTIFICATION PACK GENERATOR",
     "automatyczny pakiet dla P44: synteza + dowody + luki P0/P1 (AN04)",
     "jdg.v3_p31_audit_stages.certification_pack_generator",
     "v3_p31_certpack", "TRIAGE_QUEUE", "pakiet niekompletny = TRIAGE",
     []),
    ("v3_p31_closure_campaign.py", "V3-P31-I11", "STAGE CLOSURE CAMPAIGN",
     "plan naprawy etapów bez dowodów; priorytet ZUS core/micro, UoR, KSeF (AN01-AN03)",
     "jdg.v3_p31_audit_stages.stage_closure_campaign",
     "v3_p31_closure_campaign", "BLOCK_AND_ALERT", "etapy bez dowodów > limitu = BLOCK",
     ["v3_p31_max_stages_without_evidence"]),
    ("v3_p31_p30_feed.py", "V3-P31-I12", "P30 FEED",
     "wyniki etapów jako wejście do rejestru wdrożeń P30 (jedna historia, dwie perspektywy)",
     "jdg.v3_p31_audit_stages.p30_feed",
     "v3_p31_p30_feed", "TRIAGE_QUEUE", "feed pusty/unsync = TRIAGE",
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
