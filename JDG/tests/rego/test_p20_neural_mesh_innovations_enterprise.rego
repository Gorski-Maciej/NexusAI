# NexusAI JDG — testy rego P20 (Neural Mesh + Innowacje v8)
# Package: jdg.tests.p20_neural_mesh
package jdg.tests.p20_neural_mesh

import future.keywords.in

test_p20_coverage_report {
    result := data.jdg.p20_neural_mesh_innovations.neural_mesh_coverage_report with input as {"jdg_entrepreneur": {"p20_mesh_check": true}}
    result.rule_id == "jdg.p20_neural_mesh_innovations.neural_mesh_coverage_report"
    result.matched == true
    count(result.modules) == 6
}

test_neural_mesh_audit {
    result := data.jdg.p20_neural_mesh_innovations.neural_mesh_audit with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"trust_scores": {"VAT": 0.95, "PIT": 0.2, "ZUS": 0.8}, "detected_conflicts": ["VAT vs PIT"], "max_trust_diff": 0.75}}
    result.rule_id == "jdg.p20_neural_mesh_innovations.neural_mesh_audit"
    count(result.detected_conflicts) == 1
    result._routing == "TRIAGE_QUEUE"
}

test_neural_mesh_audit_brak_konfliktu {
    result := data.jdg.p20_neural_mesh_innovations.neural_mesh_audit with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"detected_conflicts": [], "max_trust_diff": 0.1}}
    result._routing == ""
}

test_knowledge_graph {
    result := data.jdg.p20_neural_mesh_innovations.knowledge_graph with input as {"jdg_entrepreneur": {"p20_mesh_check": true}}
    result.rule_id == "jdg.p20_neural_mesh_innovations.knowledge_graph"
    result.node_count == 5
    result.edge_count == 3
}

test_confidence_propagation {
    result := data.jdg.p20_neural_mesh_innovations.confidence_propagation with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"source_confidence": 0.9, "edge_weight": 0.8}}
    result.propagated_confidence == 0.72
}

test_confidence_propagation_cutoff {
    result := data.jdg.p20_neural_mesh_innovations.confidence_propagation with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"source_confidence": 0.5, "edge_weight": 0.4}}
    result.propagated_confidence == 0
}

test_self_learning_network_positive {
    result := data.jdg.p20_neural_mesh_innovations.self_learning_network with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"rule_weight": 0.8, "feedback": "POSITIVE"}}
    result.new_weight == 0.85
}

test_self_learning_network_negative {
    result := data.jdg.p20_neural_mesh_innovations.self_learning_network with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"rule_weight": 0.8, "feedback": "NEGATIVE"}}
    result.new_weight == 0.75
}

test_innovations_v8_audit {
    result := data.jdg.p20_neural_mesh_innovations.innovations_v8_audit with input as {"jdg_entrepreneur": {"p20_mesh_check": true}}
    result.rule_id == "jdg.p20_neural_mesh_innovations.innovations_v8_audit"
    result.p01_p24.p21_p22_p23_p24 == "innowacje enterprise 49+49+21+30"
}

test_dead_innovation_detector {
    result := data.jdg.p20_neural_mesh_innovations.dead_innovation_detector with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"innovations": [{"rule_id": "A", "cycles_unused": 15}, {"rule_id": "B", "cycles_unused": 2}]}}
    count(result.dead_innovations) == 1
}

test_cross_act_coherence_audit {
    result := data.jdg.p20_neural_mesh_innovations.cross_act_coherence_audit with input as {"jdg_entrepreneur": {"p20_mesh_check": true}}
    result.rule_id == "jdg.p20_neural_mesh_innovations.cross_act_coherence_audit"
    result.p35_cross_act.cel == "rozwiązywanie konfliktów między ustawami (VAT × PIT × ZUS × KKS × Ordynacja)"
}

test_cross_act_dependency_declaration {
    result := data.jdg.p20_neural_mesh_innovations.cross_act_dependency_declaration with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"declared_dependencies": [{"act": "VAT", "verified": true}, {"act": "PIT", "verified": true}]}}
    result.verified == true
}

test_cross_act_verification_failed {
    result := data.jdg.p20_neural_mesh_innovations.cross_act_verification with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"verification_checks": [{"check": "VAT×PIT", "passed": true}, {"check": "ZUS×PIT", "passed": false}]}}
    result.consistent == false
    result._routing == "TRIAGE_QUEUE"
}

test_strategy_judicial_audit {
    result := data.jdg.p20_neural_mesh_innovations.strategy_judicial_audit with input as {"jdg_entrepreneur": {"p20_mesh_check": true}}
    result.rule_id == "jdg.p20_neural_mesh_innovations.strategy_judicial_audit"
    result.strategia.strategic_advisor == "9 reguł — doradca strategiczny"
}

test_legislative_radar_alert {
    result := data.jdg.p20_neural_mesh_innovations.legislative_radar with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"days_to_change": 15}}
    result.status == "ZMIANA PRAWA BLISKO — 15 dni"
    result._routing == "TRIAGE_QUEUE"
}

test_legislative_radar_ok {
    result := data.jdg.p20_neural_mesh_innovations.legislative_radar with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"days_to_change": 45}}
    result.status == "BEZ BLISKICH ZMIAN PRAWA"
    result._routing == ""
}

test_judicial_fast_response {
    result := data.jdg.p20_neural_mesh_innovations.judicial_fast_response with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"ruling_impact": 0.7}}
    result.auto_update == true
    result._routing == "TRIAGE_QUEUE"
}

test_weight_auto_tuning {
    result := data.jdg.p20_neural_mesh_innovations.weight_auto_tuning with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"rule_weight": 0.8, "feedback": "POSITIVE"}}
    result.tuned_weight == 0.85
}

test_hot_swap_rules {
    result := data.jdg.p20_neural_mesh_innovations.hot_swap_rules with input as {"jdg_entrepreneur": {"p20_mesh_check": true}}
    result.hot_reload == true
    result.zero_downtime == true
}

test_legal_change_simulator {
    result := data.jdg.p20_neural_mesh_innovations.legal_change_simulator with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"simulated_change": "nowelizacja VAT", "affected_rules": ["VAT-7", "JPK"], "impact_score": 8}}
    result.simulated_change == "nowelizacja VAT"
    count(result.affected_rules) == 2
}

test_rule_ranking {
    result := data.jdg.p20_neural_mesh_innovations.rule_ranking with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"ranked_rules": [{"rule_id": "VAT-7", "score": 0.95}, {"rule_id": "PIT-36", "score": 0.88}]}}
    result.top_rule == "VAT-7"
}

test_domain_trust_scoreboard {
    result := data.jdg.p20_neural_mesh_innovations.domain_trust_scoreboard with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"trust_scores": {"VAT": 0.9, "PIT": 0.85, "ZUS": 0.8}}}
    result.baseline == 0.8
}

test_mesh_adaptation_pipeline {
    result := data.jdg.p20_neural_mesh_innovations.mesh_adaptation_pipeline with input as {"jdg_entrepreneur": {"p20_mesh_check": true}}
    result.hot_reload == true
    result.pipeline.step_1_ingest == "data.jdg.thresholds.neural_mesh (ADR-002) + legislacja.gov.pl"
}

test_cross_domain_ai_assistant {
    result := data.jdg.p20_neural_mesh_innovations.cross_domain_ai_assistant with input as {"jdg_entrepreneur": {"p20_mesh_check": true}, "mesh": {"query_domains": ["VAT", "PIT", "ZUS", "KKS", "ORD"]}}
    count(result.query_domains) == 5
}

test_p20_main_decide {
    result := data.jdg.p20_neural_mesh_innovations.decide with input as {"jdg_entrepreneur": {"p20_mesh_check": true}}
    result.rule_id == "jdg.p20_neural_mesh_innovations.report"
    result.neural_mesh.rule_id == "jdg.p20_neural_mesh_innovations.neural_mesh_audit"
    result.innovations_v8.rule_id == "jdg.p20_neural_mesh_innovations.innovations_v8_audit"
}

test_p20_default_no_match {
    result := data.jdg.p20_neural_mesh_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.rule_id == "jdg.p20_neural_mesh_innovations.no_match"
}
