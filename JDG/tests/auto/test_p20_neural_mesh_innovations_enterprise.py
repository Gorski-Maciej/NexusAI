# -*- coding: utf-8 -*-
"""Testy P20 — Neural Mesh + Innowacje v8 (NexusAI JDG)."""
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))

from neural_mesh_innovations_auditor import (  # noqa: E402
    audit_rego_files,
    confidence_propagation,
    cross_act_dependency_declaration,
    cross_act_verification,
    cross_domain_ai_assistant,
    dead_innovation_detector,
    domain_trust_scoreboard,
    full_graph_confidence_propagation,
    hot_swap_rules,
    judicial_fast_response,
    judicial_trend_rulings_engine,
    knowledge_graph,
    legal_change_simulator,
    legislacja_gov_pl_integration,
    legislative_radar,
    mesh_adaptation_pipeline,
    neural_mesh_audit,
    novelization_impact_report,
    nsa_wsa_rulings_database,
    rule_ranking,
    self_learning_network,
    sro_panel_ui,
    strategic_roadmap_engine,
    weight_auto_tuning,
)


# ── Sekcja 1: Neural Mesh ─────────────────────────────────────────────────────
def test_neural_mesh_audit_conflict():
    res = neural_mesh_audit(trust_scores={"VAT": 0.95, "PIT": 0.2, "ZUS": 0.8}, detected_conflicts=["VAT vs PIT"])
    assert res["max_trust_diff"] == 0.75
    assert res["_routing"] == "TRIAGE_QUEUE"
    assert "KONFLIKT KRYTYCZNY" in res["conflict_alert"]


def test_neural_mesh_audit_brak_konfliktu():
    res = neural_mesh_audit(trust_scores={"VAT": 0.9, "PIT": 0.9}, detected_conflicts=[])
    assert res["_routing"] == ""
    assert "BRAK KONFLIKTU" in res["conflict_alert"]


def test_knowledge_graph():
    res = knowledge_graph()
    assert res["node_count"] == 5
    assert res["edge_count"] == 3
    assert res["nodes"][0] == "VAT"


def test_confidence_propagation():
    res = confidence_propagation(source_confidence=0.9, edge_weight=0.8)
    assert res["propagated_confidence"] == 0.72


def test_confidence_propagation_cutoff():
    res = confidence_propagation(source_confidence=0.5, edge_weight=0.4)
    assert res["propagated_confidence"] == 0


def test_self_learning_network_positive():
    res = self_learning_network(rule_weight=0.8, feedback="POSITIVE")
    assert res["new_weight"] == 0.85


def test_self_learning_network_negative():
    res = self_learning_network(rule_weight=0.8, feedback="NEGATIVE")
    assert res["new_weight"] == 0.75


# ── Sekcja 2: Innowacje v8 ────────────────────────────────────────────────────
def test_dead_innovation_detector():
    res = dead_innovation_detector(innovations=[
        {"rule_id": "A", "cycles_unused": 15},
        {"rule_id": "B", "cycles_unused": 2},
    ])
    assert res["dead_count"] == 1
    assert res["dead_innovations"][0]["rule_id"] == "A"


# ── Sekcja 3: Spójność międzyaktowa ───────────────────────────────────────────
def test_cross_act_dependency_declaration():
    res = cross_act_dependency_declaration(declared_dependencies=[
        {"act": "VAT", "verified": True},
        {"act": "PIT", "verified": True},
    ])
    assert res["verified"] is True
    assert res["verified_count"] == 2


def test_cross_act_verification_failed():
    res = cross_act_verification(verification_checks=[
        {"check": "VAT×PIT", "passed": True},
        {"check": "ZUS×PIT", "passed": False},
    ])
    assert res["consistent"] is False
    assert res["_routing"] == "TRIAGE_QUEUE"


def test_cross_act_verification_ok():
    res = cross_act_verification(verification_checks=[
        {"check": "VAT×PIT", "passed": True},
        {"check": "ZUS×PIT", "passed": True},
    ])
    assert res["consistent"] is True
    assert res["_routing"] == ""


# ── Sekcja 4: Strategia i orzecznictwo ────────────────────────────────────────
def test_legislative_radar_alert():
    res = legislative_radar(days_to_change=15)
    assert "ZMIANA PRAWA BLISKO" in res["status"]
    assert res["_routing"] == "TRIAGE_QUEUE"


def test_legislative_radar_ok():
    res = legislative_radar(days_to_change=45)
    assert "BEZ BLISKICH ZMIAN PRAWA" in res["status"]
    assert res["_routing"] == ""


def test_judicial_fast_response_istotne():
    res = judicial_fast_response(ruling_impact=0.7)
    assert res["auto_update"] is True
    assert res["_routing"] == "TRIAGE_QUEUE"


def test_judicial_fast_response_male_znaczenie():
    res = judicial_fast_response(ruling_impact=0.3)
    assert res["auto_update"] is False
    assert res["_routing"] == ""


# ── Sekcja 5: OPA jako system ─────────────────────────────────────────────────
def test_weight_auto_tuning():
    res = weight_auto_tuning(rule_weight=0.8, feedback="POSITIVE")
    assert res["tuned_weight"] == 0.85


def test_hot_swap_rules():
    res = hot_swap_rules()
    assert res["hot_reload"] is True
    assert res["zero_downtime"] is True


def test_legal_change_simulator():
    res = legal_change_simulator(simulated_change="nowelizacja VAT", affected_rules=["VAT-7", "JPK"], impact_score=8)
    assert res["simulated_change"] == "nowelizacja VAT"
    assert len(res["affected_rules"]) == 2


# ── INN-12..15 ────────────────────────────────────────────────────────────────
def test_rule_ranking():
    res = rule_ranking(ranked_rules=[{"rule_id": "VAT-7", "score": 0.95}, {"rule_id": "PIT-36", "score": 0.88}])
    assert res["top_rule"] == "VAT-7"


def test_domain_trust_scoreboard():
    res = domain_trust_scoreboard(trust_scores={"VAT": 0.9, "PIT": 0.85, "ZUS": 0.8})
    assert res["baseline"] == 0.8
    assert res["trust_scores"]["VAT"] == 0.9


def test_mesh_adaptation_pipeline():
    res = mesh_adaptation_pipeline()
    assert res["hot_reload"] is True
    assert res["pipeline"]["step_1_ingest"].startswith("data.jdg.thresholds")


def test_cross_domain_ai_assistant():
    res = cross_domain_ai_assistant(query_domains=["VAT", "PIT", "ZUS", "KKS", "ORD"])
    assert len(res["query_domains"]) == 5
    assert "synteza" in res["synthesis"]


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    audit = audit_rego_files()
    assert audit["total_rule_ids"] > 300, "Za mało rule_id w modułach P20"
    assert audit["summary"]["total_modules"] == 6
    assert audit["gap_pct"] == 0, "Wszystkie 6 modułów powinny być COMPLETE"


def test_audit_neural_mesh_complete():
    audit = audit_rego_files()
    assert audit["modules"]["neural_mesh"]["status"] == "COMPLETE"
    assert audit["modules"]["neural_mesh"]["rules"] >= 35  # 20+16


def test_audit_innovations_complete():
    audit = audit_rego_files()
    assert audit["modules"]["innovations_v8"]["status"] == "COMPLETE"
    assert audit["modules"]["innovations_v8"]["rules"] >= 180  # 8+49+49+21+30+30


def test_audit_cross_act_complete():
    audit = audit_rego_files()
    assert audit["modules"]["cross_act"]["status"] == "COMPLETE"
    assert audit["modules"]["cross_act"]["rules"] >= 85  # 8+8+17+15+11+17+12+4


def test_audit_strategy_judicial_complete():
    audit = audit_rego_files()
    assert audit["modules"]["strategy"]["status"] == "COMPLETE"
    assert audit["modules"]["judicial"]["status"] == "COMPLETE"


# ── Kontrola pakietu P20 ──────────────────────────────────────────────────────
# ── Mapa drogowa R20 (P0/P1/P2) — 7 nowych reguł ──────────────────────────────
def test_r20_strategic_roadmap_engine():
    """R20 P0-1: strategic_roadmap — ready → KOMPLETNY; nie-ready → TRIAGE_QUEUE."""
    ok = strategic_roadmap_engine(roadmap_ready=True)
    assert ok["horizon_years"] == 5
    assert ok["transformation_threshold_pln"] == 300000
    assert ok["_routing"] == ""
    assert "KOMPLETNY" in ok["engine_status"]
    bad = strategic_roadmap_engine(roadmap_ready=False)
    assert bad["_routing"] == "TRIAGE_QUEUE"


def test_r20_judicial_trend_rulings_engine():
    """R20 P0-2: orzecznictwo — trendy+db OK → ZINTEGROWANE; brak → TRIAGE_QUEUE."""
    ok = judicial_trend_rulings_engine(trends_detected=True, db_ready=True)
    assert ok["_routing"] == ""
    assert "ZINTEGROWANE" in ok["engine_status"]
    assert ok["unfavorable_trend_threshold_pct"] == 60
    bad = judicial_trend_rulings_engine(trends_detected=False, db_ready=True)
    assert bad["_routing"] == "TRIAGE_QUEUE"
    assert "WYMAGA INDEKSACJI" in bad["engine_status"]


def test_r20_legislacja_gov_pl_integration():
    """R20 P1-1: legislacja.gov.pl — api_ok → radar live; brak → TRIAGE_QUEUE."""
    ok = legislacja_gov_pl_integration(api_ok=True)
    assert ok["_routing"] == ""
    assert "radar live" in ok["integration_status"]
    bad = legislacja_gov_pl_integration(api_ok=False)
    assert bad["_routing"] == "TRIAGE_QUEUE"
    assert "WYMAGA KONFIGURACJI" in bad["integration_status"]


def test_r20_nsa_wsa_rulings_database():
    """R20 P1-2: baza orzeczeń — 12 ≥ 5 → OK; 3 < 5 → TRIAGE_QUEUE."""
    ok = nsa_wsa_rulings_database(rulings_indexed=12)
    assert ok["_routing"] == ""
    assert "12 orzeczeń" in ok["db_status"]
    bad = nsa_wsa_rulings_database(rulings_indexed=3)
    assert bad["_routing"] == "TRIAGE_QUEUE"
    assert "3 orzeczeń" in bad["db_status"]


def test_r20_full_graph_confidence_propagation():
    """R20 P1-3: pełny graf — 10/10 → KOMPLETNA; 6/10 → TRIAGE_QUEUE."""
    ok = full_graph_confidence_propagation(total_nodes=10, propagated_nodes=10)
    assert ok["_routing"] == ""
    assert "KOMPLETNA" in ok["graph_status"]
    assert len(ok["domains"]) >= 8
    bad = full_graph_confidence_propagation(total_nodes=10, propagated_nodes=6)
    assert bad["_routing"] == "TRIAGE_QUEUE"
    assert "6/10" in bad["graph_status"]


def test_r20_sro_panel_ui():
    """R20 P2-1: panel SRO — 0 zmian → sync; 2 zmiany → TRIAGE_QUEUE."""
    ok = sro_panel_ui(pending_updates=0)
    assert ok["_routing"] == ""
    assert "zsynchronizowane" in ok["panel_status"]
    bad = sro_panel_ui(pending_updates=2)
    assert bad["_routing"] == "TRIAGE_QUEUE"
    assert "2 zmian" in bad["panel_status"]


def test_r20_novelization_impact_report():
    """R20 P2-2: nowelizacja — WYSOKI/KRYTYCZNY → TRIAGE_QUEUE; NISKI → OK."""
    high = novelization_impact_report(simulated_change="nowelizacja VAT", impact_level="WYSOKI", affected_rules_count=4)
    assert high["_routing"] == "TRIAGE_QUEUE"
    assert "WPŁYW WYSOKI" in high["report_status"]
    crit = novelization_impact_report(impact_level="KRYTYCZNY")
    assert crit["_routing"] == "TRIAGE_QUEUE"
    low = novelization_impact_report(impact_level="NISKI")
    assert low["_routing"] == ""


def test_r20_roadmap_rules_present_in_rego():
    """Wszystkie 7 reguł mapy drogowej R20 obecnych w pakiecie rego z podstawą prawną."""
    text = (BASE_DIR / "rules" / "p20_neural_mesh_innovations_v9.rego").read_text(encoding="utf-8")
    for rid in ["strategic_roadmap_engine", "judicial_trend_rulings_engine", "legislacja_gov_pl_integration",
                "nsa_wsa_rulings_database", "full_graph_confidence_propagation", "sro_panel_ui",
                "novelization_impact_report"]:
        assert f"jdg.p20_neural_mesh_innovations.{rid}" in text, f"Brak reguły {rid}"
    assert '"roadmap": {' in text
    assert "p20_mesh_check" in text


def test_r20_thresholds_block_exists():
    """ADR-002: blok data.jdg.thresholds.neural_mesh istnieje w thresholds_jdg.rego."""
    text = (BASE_DIR / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert "neural_mesh := {" in text
    for key in ["strategic_roadmap", "judicial_trend_rulings", "legislacja_gov_pl", "nsa_wsa_rulings_db",
                "full_graph_confidence", "sro_panel", "novelization_impact"]:
        assert f'"{key}":' in text, f"Brak konfiguracji {key} w thresholds"


def test_p20_package_exists():
    p = BASE_DIR / "rules" / "p20_neural_mesh_innovations_v9.rego"
    assert p.exists(), "Brak pliku p20_neural_mesh_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p20_neural_mesh_innovations" in text


def test_p20_braces_balanced():
    text = (BASE_DIR / "rules" / "p20_neural_mesh_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("{") == text.count("}"), "Niezbalansowane nawiasy w pakiecie P20"


def test_p20_innovations_count():
    text = (BASE_DIR / "rules" / "p20_neural_mesh_innovations_v9.rego").read_text(encoding="utf-8")
    for i in range(1, 16):
        marker = f"INN-{i:02d}"
        assert marker in text, f"Brak markera {marker} w pakiecie P20"


def test_p20_legal_basis_present():
    text = (BASE_DIR / "rules" / "p20_neural_mesh_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 15, "Za mało podstaw prawnych w pakiecie P20"


def test_p20_wiring_in_main():
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p20_neural_mesh_innovations" in main
    assert '"jdg.p20_neural_mesh_innovations": p20_neural_mesh_innovations.decide' in main
    assert "final_verdict_p20 = safe_merge(final_verdict_p19," in main


def test_p20_no_collision():
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "jdg.p20_neural_mesh_innovations" in main
    text = (BASE_DIR / "rules" / "p20_neural_mesh_innovations_v9.rego").read_text(encoding="utf-8")
    assert "jdg.p20_neural_mesh_innovations" in text


def test_p20_tool_smoke():
    audit = audit_rego_files()
    assert audit["total_rule_ids"] > 0
    res = legislative_radar(days_to_change=15)
    assert res["_routing"] == "TRIAGE_QUEUE"


def test_p20_tool_smoke_table():
    res = neural_mesh_audit(trust_scores={"VAT": 0.9, "PIT": 0.85})
    assert res["max_trust_diff"] == 0.05
    assert "KONFLIKT OBSERWOWANY" in res["conflict_alert"]
    res2 = confidence_propagation(source_confidence=0.9, edge_weight=0.8)
    assert res2["propagated_confidence"] == 0.72


def test_p20_constants_match():
    """Progi w narzędziu (Python) zgodne z rego (0.7 konflikt, 0.5 cutoff, 0.6 SRO, 30 dni radar)."""
    assert neural_mesh_audit(trust_scores={"VAT": 0.9, "PIT": 0.15})["_routing"] == "TRIAGE_QUEUE"  # diff 0.75 ≥ 0.7
    assert confidence_propagation(source_confidence=0.5, edge_weight=0.4)["propagated_confidence"] == 0
    assert judicial_fast_response(ruling_impact=0.59)["auto_update"] is False
    assert judicial_fast_response(ruling_impact=0.6)["auto_update"] is True
    assert legislative_radar(days_to_change=30)["_routing"] == "TRIAGE_QUEUE"
    assert legislative_radar(days_to_change=31)["_routing"] == ""
