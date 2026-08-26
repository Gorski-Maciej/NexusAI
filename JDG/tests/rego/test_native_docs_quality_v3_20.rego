package jdg.docs.quality_v3_20

import data.jdg.docs.quality_v3_20

# Golden evidence: pełny audyt dokumentacji kampanii V3 (Legal Twin z
# auto-trace artykul→rule_id→test i łańcuchem amendment, bramka docs↔rules,
# MANIFEST v3 z 7 pakietami, słowniki zharmonizowane, FAQ/podręcznik z
# narracją decyzyjną PL, certyfikacja 20/20 części WDROZONY_100, mapowanie
# V1/V2).
valid_ctx := {
    "source_refs": ["isap://ordpu/12", "isap://vat/109"],
    "legal_nodes": ["ordpu.art12", "vat.art109"],
    "evaluation_date": "2026-08-26",
    "facts_version": "facts-2026.08",
    "input_hash": "sha256:docs-golden-20",
    "owner_approval": true,
    "manual_recipient": "OWNER_DOCS",
    "legal_twin": {"traceability_present": true, "auto_trace_article_rule_test": true, "amendment_chain_linked": true},
    "doc_rule_gate": {"every_rule_has_legal_basis": true, "every_legal_basis_has_rule": true},
    "manifest": {"versioned": true, "auto_generated_from_packages": true, "v3_packages": ["quality_v3_14", "quality_v3_15", "quality_v3_16", "quality_v3_17", "quality_v3_18", "quality_v3_19", "quality_v3_20"]},
    "glossary": {"harmonized": true, "sources_registered": true},
    "user_documentation": {"faq_present": true, "handbook_present": true, "decision_narrative_pl": true},
    "certification": {"campaign_complete": true, "parts_wdrozone": 20, "evidence_bundle_issued": true},
    "v1v2_alignment": {"v1_principles_mapped": true, "v2_pillars_mapped": true},
}

full_input := {"docs_quality_v3_20_check": true, "docs_quality_v3_20": valid_ctx}

test_full_contract_validated if {
    result := quality_v3_20.decide with input as full_input
    result.state == "DOCS_VALIDATED"
    result._routing == "TRIAGE_QUEUE"
    result.no_auto_post == true
    result.mode == "DECOUPLED"
}

test_fail_closed_without_owner_approval if {
    ctx := object.union(valid_ctx, {"owner_approval": false})
    result := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": ctx}
    result.state == "DOCS_BLOCKED"
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_legal_twin_gaps_block if {
    no_trace := object.union(valid_ctx, {"legal_twin": {"traceability_present": false, "auto_trace_article_rule_test": true, "amendment_chain_linked": true}})
    r1 := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": no_trace}
    r1.legal_twin_ok == false
    r1.state == "DOCS_BLOCKED"

    no_amendment := object.union(valid_ctx, {"legal_twin": {"traceability_present": true, "auto_trace_article_rule_test": true, "amendment_chain_linked": false}})
    r2 := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": no_amendment}
    r2.legal_twin_ok == false
    r2.state == "DOCS_BLOCKED"
}

test_docs_gate_bidirectional_blocks if {
    missing_basis := object.union(valid_ctx, {"doc_rule_gate": {"every_rule_has_legal_basis": false, "every_legal_basis_has_rule": true}})
    r1 := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": missing_basis}
    r1.docs_gate_ok == false
    r1.state == "DOCS_BLOCKED"

    orphan_basis := object.union(valid_ctx, {"doc_rule_gate": {"every_rule_has_legal_basis": true, "every_legal_basis_has_rule": false}})
    r2 := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": orphan_basis}
    r2.docs_gate_ok == false
    r2.state == "DOCS_BLOCKED"
}

test_manifest_packages_below_min_block if {
    few_pkgs := object.union(valid_ctx, {"manifest": {"versioned": true, "auto_generated_from_packages": true, "v3_packages": ["quality_v3_14"]}})
    result := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": few_pkgs}
    result.manifest_ok == false
    result.state == "DOCS_BLOCKED"
}

test_certification_incomplete_campaign_blocks if {
    partial := object.union(valid_ctx, {"certification": {"campaign_complete": true, "parts_wdrozone": 18, "evidence_bundle_issued": true}})
    r1 := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": partial}
    r1.certification.ok == false
    r1.certification.parts_wdrozone == 18
    r1.state == "DOCS_BLOCKED"
}

test_user_docs_and_alignment_block if {
    no_narrative := object.union(valid_ctx, {"user_documentation": {"faq_present": true, "handbook_present": true, "decision_narrative_pl": false}})
    r1 := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": no_narrative}
    r1.user_docs_ok == false

    no_pillars := object.union(valid_ctx, {"v1v2_alignment": {"v1_principles_mapped": true, "v2_pillars_mapped": false}})
    r2 := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": no_pillars}
    r2.v1v2_ok == false
    r2.state == "DOCS_BLOCKED"
}

test_no_auto_post_always_true if {
    blocked := quality_v3_20.decide with input as {"docs_quality_v3_20_check": true, "docs_quality_v3_20": {}}
    blocked.no_auto_post == true
}
