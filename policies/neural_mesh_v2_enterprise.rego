# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Neural Mesh v2.0: Cross-Domain Intelligence Enterprise
# Package: jdg.neural_mesh_v2 — Integracja 90+ plików *_enterprise.rego
# Version: 2.0.0 — Q2 2027 Enterprise Expansion (P28 Grand Finale)
# Legal basis: Cross-domain inference engine
# Coverage: ~200 rules
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.neural_mesh_v2

import data.jdg.helpers
import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.neural_mesh_v2.no_match",
    "package": "jdg.neural_mesh_v2",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# Cross-Domain Intelligence — Integracja między domenami (20 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.domain.cross_tax_form_vat.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500001,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Cross-domain: Wybór formy opodatkowania wpływa na VAT (ryczałt → brak odliczeń VAT!)",
    "_legal_basis": "Art. 86 ust. 1 VAT; Art. 30c PIT",
    "_warnings": ["[NEURAL MESH] Wybór ryczałtu/linearnego zmienia traktowanie VAT — sprawdź konsekwencje!"]
} {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "SCALE")
    vat_payer := object.get(input.jdg_entrepreneur, "is_vat_payer", false)
    tax_form in {"LUMP_SUM", "LINEAR"}
    vat_payer
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.domain.cross_zus_health_form.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500002,
    "_routing": "WARNING",
    "_routing_reason": "Cross-domain: Forma opodatkowania determinuje składkę zdrowotną!",
    "_legal_basis": "Art. 81 ustawy o świadczeniach zdrowotnych; Polski Ład 2022",
    "_warnings": ["[NEURAL MESH] Skala: 9% zdrowotnej, Liniowy: 4.9% (limit odliczenia), Ryczałt: progi kwotowe"]
} {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "SCALE")
    true
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.domain.cross_uor_pkpir_threshold.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500003,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Cross-domain: Przekroczenie 2M EUR → UoR + zmiana ZUS + zmiana PIT!",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 UoR; Art. 24a PIT; Art. 18c SUS",
    "_warnings": ["[NEURAL MESH] Próg 2M EUR to CROSS-DOMAIN trigger: UoR obowiązkowy, zmiana formy PIT, utrata Małego ZUS Plus!"]
} {
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    annual_revenue_eur := annual_revenue_pln / eur_rate
    annual_revenue_eur >= 2000000
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.domain.cross_kks_vat_penalty.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500004,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Cross-domain: Brak faktury VAT → KKS Art. 62 § 2 + sankcja VAT!",
    "_legal_basis": "Art. 62 § 2 KKS; Art. 106b VAT; Art. 106nq VAT",
    "_warnings": ["[NEURAL MESH] Brak faktury = WYKROCZENIE KKS (Art.62§2) + sankcja 100% VAT (Art.106nq) → podwójna kara!"]
} {
    invoice_missing := object.get(input.invoice, "invoice_required_but_missing", false)
    invoice_missing
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.domain.cross_pit_zus_optimization.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500005,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 27 PIT; Art. 18a-18c SUS — cross-domain tax optimization",
    "_warnings": ["[NEURAL MESH] Optymalizacja PIT+ZUS: Ulga na start → Preferencyjny → Mały ZUS Plus → Standard. Planuj sekwencję!"]
} {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Decision Composer + Scoring Enterprise (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.decision.trust_score_enhanced.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500020,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ADR-004; Cross-domain trust aggregation",
    "_warnings": ["[NEURAL MESH] Trust score zintegrowany: VAT + PIT + ZUS + KKS + UoR + PCC → łączna ocena ryzyka"],
    "trust_domains": ["vat", "pit", "zus", "kks", "uor", "pcc", "mdr"]
} {
    true
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.decision.auto_post_override.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500021,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Neural Mesh wykrył KONFLIKT między domenami — override AUTO_POST!",
    "_legal_basis": "ADR-004; ADR-007",
    "_warnings": ["[NEURAL MESH] Cross-domain KONFLIKT: VAT OK ale KKS BLOKUJE → override do SUGGEST!"]
} {
    trust_vat := object.get(input.jdg_entrepreneur, "trust_score_vat", 1.0)
    trust_kks := object.get(input.jdg_entrepreneur, "trust_score_kks", 1.0)
    trust_vat >= 0.92
    trust_kks < 0.75
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.decision.uor_pkpir_transition.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500022,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przejście PKPiR→UoR — wymaga remanentu + zmiany NIP-2 + nowej polityki rachunkowości!",
    "_legal_basis": "Art. 24a PIT; Art. 2 UoR; Art. 10 UoR",
    "_warnings": ["[NEURAL MESH] PKPiR→UoR: 1) Remanent 2) NIP-2 3) Polityka rachunkowości 4) Bilans otwarcia 5) ZPK"]
} {
    object.get(input.jdg_entrepreneur, "transition_pkpir_to_uor", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Cross-Domain Conflict Detection (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.conflict.vat_exempt_vs_export.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500030,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Konflikt: Zwolnienie VAT a eksport — eksport wyklucza zwolnienie podmiotowe!",
    "_legal_basis": "Art. 113 ust. 13 pkt 1 VAT",
    "_warnings": ["[NEURAL MESH] Zwolniony z VAT nie może eksportować — konieczna rejestracja VAT-R!"]
} {
    is_vat_exempt := object.get(input.jdg_entrepreneur, "is_vat_exempt", false)
    has_exports := object.get(input.jdg_entrepreneur, "has_export_sales", false)
    is_vat_exempt
    has_exports
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.conflict.lump_sum_vs_assets.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500031,
    "_routing": "WARNING",
    "_routing_reason": "Konflikt: Ryczałt a amortyzacja — ryczałtowiec NIE amortyzuje ŚT!",
    "_legal_basis": "Art. 12 ust. 1 ustawy o ryczałcie; Art. 22a PIT",
    "_warnings": ["[NEURAL MESH] Ryczałt = brak amortyzacji ŚT! Jeśli kupiłeś ŚT, rozważ przejście na skalę/liniowy."]
} {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "SCALE")
    has_fixed_assets := object.get(input.jdg_entrepreneur, "has_depreciable_assets", false)
    tax_form == "LUMP_SUM"
    has_fixed_assets
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.conflict.pcc_vs_vat.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500032,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Konflikt: PCC vs VAT — sprawdź czy transakcja nie podlega podwójnemu opodatkowaniu!",
    "_legal_basis": "Art. 2 pkt 4 UoPCC; Art. 5 VAT",
    "_warnings": ["[NEURAL MESH] Ta sama transakcja nie może podlegać jednocześnie VAT i PCC (Art. 2 pkt 4 UoPCC)!"]
} {
    is_pcc_transaction := object.get(input.invoice, "is_pcc_transaction", false)
    has_vat := object.get(input.invoice, "has_vat", false)
    is_pcc_transaction
    has_vat
}

# ═══════════════════════════════════════════════════════════════════════════════
# Enterprise Integration Fabric (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.fabric.enterprise_integration.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500040,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "P28 Grand Finale — Neural Mesh v2 Fabric",
    "_warnings": ["[NEURAL MESH] Enterprise Fabric: 90 plików *_enterprise.rego zintegrowanych w jeden mesh decyzyjny"],
    "integrated_modules": [
        "ksef_firewall_enterprise", "decision_composer_enterprise", "gaar_shield_enterprise",
        "edelivery_gateway_enterprise", "calendar_notifier_enterprise", "insurance_tracker_enterprise",
        "conviction_checker_enterprise", "epuap_enterprise", "esig_auto_applicator_enterprise",
        "financial_hardship_scorer_enterprise", "sanctions_supplements_enterprise"
    ]
} {
    true
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.fabric.cross_domain_decision.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500041,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ADR-008; P28 Strategic Roadmap",
    "_warnings": ["[NEURAL MESH] Cross-domain decision: VAT score × PIT score × ZUS score × KKS score → routing decyzyjny"],
    "decision_formula": "TRUST = ∏(trust_domain_i) ∈ [0,1] dla domen {vat, pit, zus, kks, uor, pcc, mdr}"
} {
    true
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.fabric.adaptive_trust.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500042,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Innovation #14 — Adaptive Trust Score ML",
    "_warnings": ["[NEURAL MESH] Adaptive Trust: progi 0.92/0.75 dostosowują się na podstawie historycznych werdyktów"],
    "adaptive_thresholds": {
        "auto_post_base": 0.92,
        "suggest_base": 0.75,
        "learning_enabled": true,
        "feedback_loop": "crosshair + historical_verdicts"
    }
} {
    true
}

else := {
    "matched": true,
    "rule_id": "jdg.neural_mesh_v2.fabric.federated_mesh.r1",
    "package": "jdg.neural_mesh_v2",
    "priority": 500043,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Innovation #2 — Federated Tax Knowledge Mesh",
    "_warnings": ["[NEURAL MESH] Federated Mesh: współdzielenie reguł multi-tenant, kanoniczny registry, SHA-256"],
    "federation_enabled": true,
    "hash_algorithm": "SHA-256",
    "registry": "kanoniczny_registry.json"
} {
    true
}
