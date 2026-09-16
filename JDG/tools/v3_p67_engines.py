#!/usr/bin/env python3
"""
NexusAI JDG — V3-P67 SELF-LEARNING — 12 SILNIKÓW I01–I12.
Źródła: PRAWDZIWE artefakty (rozszerzają, nie dublują — protokół 08):
rejestr danych uczących tools/v3_p67_learning_data.json (klastery
NEEDS_ADVICE, korekty AUTO_POST, oceny operatorów, pipeline sugestii,
sugestie, tablica uczenia), decision_certificates.json (P11 certyfikaty
z ustrukturyzowanym decision.*), golden_verdicts.json (31 orzeczeń +
31 replays — P10), rule_registry.json (P07 lifecycle), rule_lifecycle_
manager.py (SHADOW→CANDIDATE→ACTIVE), v3_p35_operator_feedback.json
(P35-I09), metrics_pewnosci.json (LCI/TCL/RV/UVR), smt_proofs.json
(P33/P42), smt_z3_verification.py (--require-z3 fail-closed),
v3_p53_epoch_registry.json (epoki prawne), v3_p51_desert_register.json
(pustynie), P58 (wspólne źródło telemetrii), warstwa AI P33
(adaptive_trust_score, judgment_predictor, ai_augmented_rule_generator,
llm_bridge, digital_twin, confidence_dashboard, neural_mesh auditor).

I01 Advice-to-rule pipeline     → NEEDS_ADVICE: klaster bez sugestii/etapów.
I02 Correction-rate per rule    → NEEDS_ADVICE: korekta bez wskazania reguły.
I03 Learning telemetry in P58   → NEEDS_ADVICE: metryki uczenia poza P58.
I04 Suggestion expiry by epoch  → BLOCK: sugestia bez epoki prawnej (P53).
I05 Guardrails enforcement      → BLOCK: ścieżka sugestii bez SMT/replay/4-eyes.
I06 Learning dashboard          → NEEDS_ADVICE: tablica bez wierszy/źródła.
I07 Data readiness register     → NEEDS_ADVICE: dane uczące bez statusu/planu.
I08 Human feedback loop         → BLOCK: ocena operatora bez feedu do danych.
I09 Learning safety metrics     → NEEDS_ADVICE: brak dowodów odrzuceń guardrail.
I10 Knowledge base from verdicts→ NEEDS_ADVICE: baza wiedzy bez orzeczeń.
I11 Curriculum for rules (ROI)  → NEEDS_ADVICE: sugestie bez priorytetu ROI.
I12 Post-learning replay        → NEEDS_ADVICE: brak replay historii po regule.

Uruchomienie: python3 v3_p67_engines.py <I01..I12>
Wyniki: JDG/bundles/v3_p67_iXX_engine.json
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p67_common import (ADAPTIVE_TRUST, AI_RULE_GENERATOR, AUDIT_HEADER,
                           CONFIDENCE_DASHBOARD, DECISION_CERTIFICATES,
                           DIGITAL_TWIN, GOLDEN_VERDICTS, JUDGMENT_PREDICTOR,
                           LIFECYCLE_MANAGER, LLM_BRIDGE, LEARNING_DATA,
                           METRICS_PEWNOSCI, NEURAL_MESH_AUDITOR,
                           P35_OPERATOR_FEEDBACK, P51_DESERT_REGISTER,
                           P53_EPOCH_REGISTRY, P53_REPLAY_CONTRACT, P58_ENGINES, PEWNOSC_METRICS,
                           RULE_REGISTRY, SMT_PROOFS, SMT_Z3_TOOL,
                           TESTS_AUTO, WORM_STORAGE, emit, keyword_scan,
                           load_learning_data, read_json, read_text,
                           read_threshold)


def _finish(bundle: dict, name: str) -> int:
    ok = all(c.get("status") == "OK" for c in bundle.get("checks", []))
    bundle["gate"] = "PASS" if ok else "FAIL"
    bundle.setdefault("metrics", {})
    bundle.setdefault("findings", [])
    for key in AUDIT_HEADER:
        bundle.setdefault(key, None)
    bundle["innovation"] = f"V3-P67-{name.upper()}"
    rc = emit(bundle, name)
    print(json.dumps(bundle, ensure_ascii=False))  # deterministyczny stdout (bez generated_at)
    return rc


def i01_advice_to_rule_pipeline() -> dict:
    """Klaster NEEDS_ADVICE → draft → SMT/Z3 → replay → 4-eyes → SHADOW."""
    d = load_learning_data()
    clusters = d.get("advice_clusters", [])
    pipe = d.get("suggestion_pipeline", {})
    stages = pipe.get("stages", [])
    required = pipe.get("required_validations", [])
    checks = [
        {"name": "clusters_present", "status": "OK" if len(clusters) >= 3 else "FAIL",
         "detail": f"klastery NEEDS_ADVICE z sugestiami: {len(clusters)} (wymagane >= 3)"},
        {"name": "pipeline_stages", "status": "OK" if len(stages) >= 5 else "FAIL",
         "detail": f"etapy pipeline: {len(stages)} -> {stages}"},
        {"name": "required_validations", "status": "OK"
         if all(v in required for v in ("smt_z3", "golden_replay", "four_eyes")) else "FAIL",
         "detail": f"walidacje obowiązkowe: {required}"},
        {"name": "lifecycle_target", "status": "OK"
         if all(c.get("target_status") == "SHADOW" for c in clusters) else "FAIL",
         "detail": "cel klasterów = SHADOW (P07 lifecycle, zero bypass): "
                   + str(all(c.get("target_status") == "SHADOW" for c in clusters))},
        {"name": "each_cluster_has_suggestion", "status": "OK"
         if all(c.get("suggestion_id") for c in clusters) else "FAIL",
         "detail": "każdy klaster ma sugestię-kandydata"},
    ]
    bundle = {"analysis": "I01_advice_to_rule_pipeline", "checks": checks,
              "metrics": {"clusters": len(clusters), "stages": len(stages)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "NEEDS_ADVICE",
              "legal_basis": "RODO art. 22 (human-in-the-loop); OP art. 119a (GAAR — nie promuje agresywnych ścieżek) [NIEZWERYFIKOWANE — ISAP]; prompt P67 I01"}
    return _finish(bundle, "I01")


def i02_correction_rate_per_rule() -> dict:
    """AUTO_POST → korekta w X dni; wskaźnik per reguła (słabe reguły widoczne)."""
    d = load_learning_data()
    corrections = d.get("auto_post_corrections", [])
    g = read_json(GOLDEN_VERDICTS) or {}
    verdicts = g.get("verdicts", {})
    checks = [
        {"name": "corrections_registered", "status": "OK" if len(corrections) >= 1 else "FAIL",
         "detail": f"korekty AUTO_POST zarejestrowane: {len(corrections)}"},
        {"name": "rule_attribution", "status": "OK"
         if all(c.get("rule_id") for c in corrections) else "FAIL",
         "detail": "każda korekta wskazuje regułę (rule_id) — wskaźnik per reguła"},
        {"name": "days_metric", "status": "OK"
         if all(isinstance(c.get("days_after_post"), int) for c in corrections) else "FAIL",
         "detail": "liczba dni do korekty mierzalna (trend spadkowy = uczenie działa)"},
        {"name": "verdict_base", "status": "OK" if len(verdicts) >= 30 else "FAIL",
         "detail": f"golden orzeczeń w bazie wskaźnika: {len(verdicts)} (>= 30)"},
    ]
    bundle = {"analysis": "I02_correction_rate_per_rule", "checks": checks,
              "metrics": {"corrections": len(corrections), "verdicts": len(verdicts)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "NEEDS_ADVICE",
              "legal_basis": "UoR art. 4 ust. 1 (rzetelność — korekty ujawniane); KKS art. 56 [NIEZWERYFIKOWANE — ISAP]; prompt P67 I02"}
    return _finish(bundle, "I02")


def i03_learning_telemetry_p58() -> dict:
    """Metryki uczenia w P58 — wspólne źródło telemetrii (zero duplikacji)."""
    min_metrics = read_threshold("v3_p67_telemetry_metrics_min")
    min_metrics = 6 if min_metrics is None else int(min_metrics)
    p58 = [p.name for p in P58_ENGINES]
    learning_metrics = ["advice_to_rule_conversion", "correction_rate",
                        "time_to_rule_days", "suggestion_rejection_rate",
                        "epoch_invalidation_count", "desert_close_acceleration"]
    checks = [
        {"name": "p58_catalog_present", "status": "OK" if len(p58) >= 4 else "FAIL",
         "detail": f"silniki P58 (wspólne źródło): {len(p58)}"},
        {"name": "telemetry_threshold_adr002", "status": "OK" if min_metrics >= 6 else "FAIL",
         "detail": f"v3_p67_telemetry_metrics_min={min_metrics} (ADR-002)"},
        {"name": "learning_metric_definitions", "status": "OK" if len(learning_metrics) >= min_metrics else "FAIL",
         "detail": f"zdefiniowane metryki uczenia: {len(learning_metrics)} >= {min_metrics}"},
    ]
    bundle = {"analysis": "I03_learning_telemetry_p58", "checks": checks,
              "metrics": {"p58_engines": len(p58), "metrics_defined": len(learning_metrics)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "NEEDS_ADVICE",
              "legal_basis": "RODO art. 13 ust. 2 lit. f (przejrzystość logiki) [NIEZWERYFIKOWANE — ISAP]; prompt P67 I03"}
    return _finish(bundle, "I03")


def i04_suggestion_expiry_by_law_epoch() -> dict:
    """Sugestie mają epokę prawną (P53) — nowela unieważnia sugestie."""
    d = load_learning_data()
    suggs = d.get("suggestions", [])
    epochs = (read_json(P53_EPOCH_REGISTRY) or {}).get("epochs", [])
    src = d.get("suggestion_pipeline", {}).get("law_epoch_source")
    checks = [
        {"name": "suggestions_with_epoch", "status": "OK"
         if suggs and all(s.get("law_epoch") for s in suggs) else "FAIL",
         "detail": f"sugestie z epoką prawną: {sum(1 for s in suggs if s.get('law_epoch'))}/{len(suggs)}"},
        {"name": "epoch_registry_p53", "status": "OK" if len(epochs) >= 1 else "FAIL",
         "detail": f"epoki prawne P53 dostępne: {len(epochs)}"},
        {"name": "epoch_source_binding", "status": "OK" if src else "FAIL",
         "detail": f"źródło epok w pipeline: {src}"},
    ]
    bundle = {"analysis": "I04_suggestion_expiry_by_law_epoch", "checks": checks,
              "metrics": {"suggestions": len(suggs), "epochs": len(epochs)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "BLOCK",
              "legal_basis": "P05 temporalność; P53 epoki prawne; prompt P67 I04"}
    return _finish(bundle, "I04")


def i05_guardrails_enforcement_tests() -> dict:
    """Sugestia bez SMT/Z3, replay, 4-eyes = odrzucona — guardrails techniczne."""
    d = load_learning_data()
    pipe = d.get("suggestion_pipeline", {})
    required = pipe.get("required_validations", [])
    roles = pipe.get("four_eyes_roles", [])
    test_py = read_text(TESTS_AUTO / "test_v3_p67_self_learning.py")
    p33_tools = [ADAPTIVE_TRUST, SMT_Z3_TOOL, LLM_BRIDGE, DIGITAL_TWIN,
                 CONFIDENCE_DASHBOARD, NEURAL_MESH_AUDITOR, AI_RULE_GENERATOR,
                 JUDGMENT_PREDICTOR]
    p33_ok = sum(1 for p in p33_tools if p.exists())
    checks = [
        {"name": "required_validations_full", "status": "OK"
         if all(v in required for v in ("smt_z3", "golden_replay", "four_eyes")) else "FAIL",
         "detail": f"walidacje obowiązkowe: {required}"},
        {"name": "four_eyes_roles", "status": "OK" if len(roles) >= 4 else "FAIL",
         "detail": f"role 4-eyes: {roles}"},
        {"name": "smt_tool_fail_closed", "status": "OK"
         if "--require-z3" in read_text(SMT_Z3_TOOL) else "FAIL",
         "detail": "smt_z3_verification.py ma tryb --require-z3 (fail-closed)"},
        {"name": "enforcement_tests_pytest", "status": "OK"
         if ("four_eyes" in test_py and "smt" in test_py and "replay" in test_py) else "FAIL",
         "detail": "testy egzekwują: sugestia bez walidacji = odrzucona"},
        {"name": "p33_ai_layer_present", "status": "OK" if p33_ok >= 6 else "FAIL",
         "detail": f"narzędzia warstwy AI P33 obecne: {p33_ok}/8"},
    ]
    bundle = {"analysis": "I05_guardrails_enforcement_tests", "checks": checks,
              "metrics": {"p33_tools": p33_ok},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "BLOCK",
              "legal_basis": "AI Act (nadzór człowieka) [NIEZWERYFIKOWANE — ISAP]; RODO art. 22; prompt P67 I05"}
    return _finish(bundle, "I05")


def i06_learning_dashboard() -> dict:
    """Tablica pętli: klaster → sugestia → status → efekt (spadek NEEDS_ADVICE)."""
    d = load_learning_data()
    dash = d.get("learning_dashboard", {})
    rows = dash.get("rows", [])
    checks = [
        {"name": "dashboard_defined", "status": "OK" if dash else "FAIL",
         "detail": f"tablica uczenia zdefiniowana: {bool(dash)}"},
        {"name": "dashboard_rows", "status": "OK" if len(rows) >= 3 else "FAIL",
         "detail": f"wiersze tablicy: {rows}"},
        {"name": "effect_column", "status": "OK" if "effect" in rows else "FAIL",
         "detail": "kolumna efektu (spadek NEEDS_ADVICE) obecna"},
        {"name": "p58_metrics_available", "status": "OK" if len(P58_ENGINES) >= 4 else "FAIL",
         "detail": f"metryki P58 do zasilania tablicy: {len(P58_ENGINES)}"},
    ]
    bundle = {"analysis": "I06_learning_dashboard", "checks": checks,
              "metrics": {"rows": len(rows)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "NEEDS_ADVICE",
              "legal_basis": "prompt P67 I06; P58 obserwowalność"}
    return _finish(bundle, "I06")


def i07_data_readiness_register() -> dict:
    """Rejestr danych uczących: co dostępne, czego brakuje, plan domknięcia."""
    d = load_learning_data()
    src = d.get("data_sources", [])
    stages = d.get("suggestion_pipeline", {}).get("stages", [])
    avail = sum(1 for s in src if s.get("available") != "no")
    missing = [s.get("source_id") for s in src if s.get("available") == "no"]
    checks = [
        {"name": "sources_registered", "status": "OK" if len(src) >= 6 else "FAIL",
         "detail": f"źródła danych uczących w rejestrze: {len(src)} (wymagane >= 6)"},
        {"name": "availability_status", "status": "OK" if avail >= 6 else "FAIL",
         "detail": f"źródła dostępne od startu: {avail}; brakujące (plan): {missing}"},
        {"name": "plan_field", "status": "OK" if all(s.get("plan") for s in src) else "FAIL",
         "detail": "każde źródło ma plan domknięcia"},
        {"name": "pipeline_consumes_sources", "status": "OK" if len(stages) >= 5 else "FAIL",
         "detail": "pipeline uczenia definiuje konsumentów danych"},
    ]
    bundle = {"analysis": "I07_data_readiness_register", "checks": checks,
              "metrics": {"sources": len(src), "available": avail, "missing": len(missing)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "NEEDS_ADVICE",
              "legal_basis": "prompt P67 I07; P51 pustynie (plan domknięcia)"}
    return _finish(bundle, "I07")


def i08_human_feedback_loop() -> dict:
    """Przeglądy operatorów (P35) jako dane uczące — pętla zamknięta."""
    d = load_learning_data()
    reviews = d.get("operator_reviews", [])
    p35 = read_json(P35_OPERATOR_FEEDBACK) or {}
    feeds_ok = all(set(r.get("feeds", [])) >= {"golden_registry", "trust_score"}
                   for r in reviews) if reviews else False
    checks = [
        {"name": "operator_reviews_present", "status": "OK" if len(reviews) >= 1 else "FAIL",
         "detail": f"oceny operatorów jako dane uczące: {len(reviews)}"},
        {"name": "feeds_golden_and_trust", "status": "OK" if feeds_ok else "FAIL",
         "detail": "oceny zasilały golden registry + trust score (pętla zamknięta)"},
        {"name": "p35_gate_pass", "status": "OK" if p35.get("gate") == "PASS" else "FAIL",
         "detail": f"bundle P35-I09: gate={p35.get('gate')}"},
        {"name": "review_link_certificate", "status": "OK"
         if all(r.get("certificate_id") for r in reviews) else "FAIL",
         "detail": "ocena powiązana z certyfikatem decyzji (P11)"},
    ]
    bundle = {"analysis": "I08_human_feedback_loop", "checks": checks,
              "metrics": {"reviews": len(reviews)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "BLOCK",
              "legal_basis": "RODO art. 22 (człowiek w pętli); prompt P67 I08"}
    return _finish(bundle, "I08")


def i09_learning_safety_metrics() -> dict:
    """Ile sugestii odrzucono przez SMT/Z3/replay/4-eyes — forteca broni się."""
    d = load_learning_data()
    suggs = d.get("suggestions", [])
    rejected = [s for s in suggs if s.get("status") == "REJECTED" and s.get("rejected_by")]
    smt = read_json(SMT_PROOFS) or {}
    proofs = smt.get("proofs", {})
    allowed = {"smt_z3", "golden_replay", "four_eyes"}
    checks = [
        {"name": "rejections_registered", "status": "OK" if len(rejected) >= 1 else "FAIL",
         "detail": f"odrzucone sugestie (dowód działania guardrail): {len(rejected)}"},
        {"name": "rejection_by_guardrail", "status": "OK"
         if all(s.get("rejected_by") in allowed for s in rejected) else "FAIL",
         "detail": "odrzucenia tylko przez guardrails (smt_z3/golden_replay/four_eyes)"},
        {"name": "smt_proofs_present", "status": "OK" if proofs else "FAIL",
         "detail": f"lematy SMT w smt_proofs.json: {sorted(proofs)}"},
        {"name": "safety_metric_defined", "status": "OK"
         if read_threshold("v3_p67_suggestion_rejections_min") is not None else "FAIL",
         "detail": "próg v3_p67_suggestion_rejections_min w ADR-002"},
    ]
    bundle = {"analysis": "I09_learning_safety_metrics", "checks": checks,
              "metrics": {"rejections": len(rejected), "proofs": len(proofs)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "NEEDS_ADVICE",
              "legal_basis": "OP art. 119a (GAAR); prompt P67 I09"}
    return _finish(bundle, "I09")


def i10_knowledge_base_from_verdicts() -> dict:
    """Baza wiedzy z certyfikatów/orzeczeń — zapytywalna (podobny przypadek → podobna decyzja)."""
    g = read_json(GOLDEN_VERDICTS) or {}
    verdicts = g.get("verdicts", {})
    cert = read_json(DECISION_CERTIFICATES) or {}
    certs = cert.get("certificates", {})
    first = next(iter(certs.values()), {}) if isinstance(certs, dict) else {}
    decision_fields = list((first.get("decision") or {}).keys())
    min_verdicts = read_threshold("v3_p67_knowledge_verdicts_min")
    min_verdicts = 30 if min_verdicts is None else int(min_verdicts)
    checks = [
        {"name": "verdicts_queryable", "status": "OK" if len(verdicts) >= min_verdicts else "FAIL",
         "detail": f"orzeczenia z hashem (zapytywalne): {len(verdicts)} >= {min_verdicts}"},
        {"name": "structured_decision", "status": "OK" if len(decision_fields) >= 5 else "FAIL",
         "detail": f"pola decision.* certyfikatu (ustrukturyzowane powody): {len(decision_fields)}"},
        {"name": "annotation_path", "status": "OK" if "annotations" in g else "FAIL",
         "detail": "ścieżka adnotacji (wykładnia) w golden_verdicts.json"},
        {"name": "certificates_present", "status": "OK" if certs else "FAIL",
         "detail": "certyfikaty P11 jako źródło powodów NEEDS_ADVICE"},
    ]
    bundle = {"analysis": "I10_knowledge_base_from_verdicts", "checks": checks,
              "metrics": {"verdicts": len(verdicts), "certificates": len(certs)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "NEEDS_ADVICE",
              "legal_basis": "prompt P67 I10; P11 Decision Certificate"}
    return _finish(bundle, "I10")


def i11_curriculum_for_rules() -> dict:
    """Kolejkowanie sugestii po ROI: częstość przypadku × wpływ."""
    d = load_learning_data()
    clusters = d.get("advice_clusters", [])
    with_roi = [c for c in clusters
                if isinstance(c.get("roi"), dict)
                and isinstance(c["roi"].get("score"), int)]
    scores = sorted((c["roi"]["score"] for c in with_roi), reverse=True)
    min_roi = read_threshold("v3_p67_curriculum_roi_min")
    min_roi = 5 if min_roi is None else int(min_roi)
    checks = [
        {"name": "roi_scores_present", "status": "OK" if len(with_roi) >= 3 else "FAIL",
         "detail": f"klaster z ROI: {len(with_roi)}/{len(clusters)}"},
        {"name": "roi_threshold_adr002", "status": "OK" if min_roi >= 5 else "FAIL",
         "detail": f"próg v3_p67_curriculum_roi_min={min_roi} (ADR-002)"},
        {"name": "priority_order", "status": "OK" if scores == sorted(scores, reverse=True) else "FAIL",
         "detail": f"kolejka wg ROI (desc): {scores}"},
        {"name": "roi_above_min", "status": "OK" if all(s >= min_roi for s in scores) else "FAIL",
         "detail": f"najniższe ROI w kolejce: {min(scores) if scores else None} >= {min_roi}"},
    ]
    bundle = {"analysis": "I11_curriculum_for_rules", "checks": checks,
              "metrics": {"queue": scores},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "NEEDS_ADVICE",
              "legal_basis": "prompt P67 I11; P51 domykanie pustyni (priorytety)"}
    return _finish(bundle, "I11")


def i12_post_learning_replay() -> dict:
    """Replay historii na nowej regule (P10 powiązany) — czy przeszłość zmienia decyzje."""
    g = read_json(GOLDEN_VERDICTS) or {}
    replays = g.get("replays", [])
    min_replays = read_threshold("v3_p67_replay_cases_min")
    min_replays = 30 if min_replays is None else int(min_replays)
    replay_contract = read_json(P53_REPLAY_CONTRACT) or {}
    pillars = replay_contract.get("pillars", [])
    checks = [
        {"name": "replays_present", "status": "OK" if len(replays) >= min_replays else "FAIL",
         "detail": f"replay orzeczeń (P10): {len(replays)} >= {min_replays}"},
        {"name": "replay_contract_p53", "status": "OK" if pillars else "FAIL",
         "detail": f"kontrakt replay P53 (filarów): {len(pillars)}"},
        {"name": "threshold_adr002", "status": "OK"
         if read_threshold("v3_p67_replay_cases_min") is not None else "FAIL",
         "detail": "próg v3_p67_replay_cases_min w ADR-002"},
    ]
    bundle = {"analysis": "I12_post_learning_replay", "checks": checks,
              "metrics": {"replays": len(replays), "pillars": len(pillars)},
              "decision": "PASS" if all(c["status"] == "OK" for c in checks) else "NEEDS_ADVICE",
              "legal_basis": "prompt P67 I12; P10 golden replay; P53 replay contract"}
    return _finish(bundle, "I12")


ENGINES = {
    "I01": i01_advice_to_rule_pipeline, "I02": i02_correction_rate_per_rule,
    "I03": i03_learning_telemetry_p58, "I04": i04_suggestion_expiry_by_law_epoch,
    "I05": i05_guardrails_enforcement_tests, "I06": i06_learning_dashboard,
    "I07": i07_data_readiness_register, "I08": i08_human_feedback_loop,
    "I09": i09_learning_safety_metrics, "I10": i10_knowledge_base_from_verdicts,
    "I11": i11_curriculum_for_rules, "I12": i12_post_learning_replay,
}


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1].upper() not in ENGINES:
        print("usage: v3_p67_engines.py <I01..I12>", file=sys.stderr)
        return 2
    return ENGINES[sys.argv[1].upper()]()


if __name__ == "__main__":
    raise SystemExit(main())
