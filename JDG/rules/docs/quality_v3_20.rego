# NexusAI JDG — V3-20 DOKUMENTACJA + LEGAL TWIN + HARMONIZACJA KONCOWA
# Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą
# progów dokumentacji. Warstwa bramkuje WYNIKI audytu Legal Twin, spójności
# dokumentacji z regułami oraz certyfikacji kampanii V3; jest deterministyczna,
# guidance-only i fail-closed (brak dowodu = FAIL).

package jdg.docs.quality_v3_20

import future.keywords.if
import future.keywords.in

_snapshot := object.get(data.jdg.thresholds, "docs_quality_v3_20", {})
threshold_version := object.get(_snapshot, "threshold_version", "")
registry_version := object.get(_snapshot, "registry_version", "")
legal_basis_version := object.get(_snapshot, "legal_basis_version", "")
valid_from := object.get(_snapshot, "valid_from", "")
valid_to := object.get(_snapshot, "valid_to", null)
campaign_total_parts := object.get(_snapshot, "campaign_total_parts", 0)
min_v3_packages_in_manifest := object.get(_snapshot, "min_v3_packages_in_manifest", 0)

ctx := object.get(input, "docs_quality_v3_20", {})
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", [])
facts_version := object.get(ctx, "facts_version", "")
evaluation_date := object.get(ctx, "evaluation_date", "")
input_hash := object.get(ctx, "input_hash", "")
owner_approval := object.get(ctx, "owner_approval", false)
manual_recipient := object.get(ctx, "manual_recipient", "")

source_complete := count(source_refs) > 0 and count(legal_nodes) > 0 and
    legal_basis_version != ""
temporal_valid := evaluation_date != "" and facts_version != "" and
    threshold_version != "" and valid_from != ""

twin := object.get(ctx, "legal_twin", {})
legal_twin_ok := object.get(twin, "traceability_present", false) and
    object.get(twin, "auto_trace_article_rule_test", false) and
    object.get(twin, "amendment_chain_linked", false)

gate := object.get(ctx, "doc_rule_gate", {})
docs_gate_ok := object.get(gate, "every_rule_has_legal_basis", false) and
    object.get(gate, "every_legal_basis_has_rule", false)

manifest := object.get(ctx, "manifest", {})
v3_packages := object.get(manifest, "v3_packages", [])
manifest_ok := object.get(manifest, "versioned", false) and
    object.get(manifest, "auto_generated_from_packages", false) and
    count(v3_packages) >= min_v3_packages_in_manifest

glossary := object.get(ctx, "glossary", {})
glossary_ok := object.get(glossary, "harmonized", false) and
    object.get(glossary, "sources_registered", false)

user_docs := object.get(ctx, "user_documentation", {})
user_docs_ok := object.get(user_docs, "faq_present", false) and
    object.get(user_docs, "handbook_present", false) and
    object.get(user_docs, "decision_narrative_pl", false)

certification := object.get(ctx, "certification", {})
parts_wdrozone := object.get(certification, "parts_wdrozone", 0)
certification_ok := object.get(certification, "campaign_complete", false) and
    parts_wdrozone >= campaign_total_parts and
    object.get(certification, "evidence_bundle_issued", false)

alignment := object.get(ctx, "v1v2_alignment", {})
v1v2_ok := object.get(alignment, "v1_principles_mapped", false) and
    object.get(alignment, "v2_pillars_mapped", false)

contract_complete := legal_twin_ok and docs_gate_ok and manifest_ok and
    glossary_ok and user_docs_ok and certification_ok and v1v2_ok and
    source_complete and temporal_valid and input_hash != ""

hard_block := not contract_complete or not owner_approval or manual_recipient == ""
docs_state := "DOCS_VALIDATED" if {
    contract_complete
    not hard_block
} else := "DOCS_BLOCKED" if {
    true
}
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE"

# Publiczny wynik: Documentation & Certification Contract — nigdy czynność
# wdrożeniowa.
decide := {
    "matched": true,
    "rule_id": "jdg.docs.quality_v3_20.documentation_certification_contract",
    "package": "jdg.docs.quality_v3_20",
    "priority": 22008,
    "stage": "V3-20",
    "state": docs_state,
    "decision_mode": "SUGGEST",
    "mode": "DECOUPLED",
    "no_auto_post": true,
    "legal_twin_ok": legal_twin_ok,
    "docs_gate_ok": docs_gate_ok,
    "manifest_ok": manifest_ok,
    "manifest_v3_packages": count(v3_packages),
    "glossary_ok": glossary_ok,
    "user_docs_ok": user_docs_ok,
    "certification": {"parts_wdrozone": parts_wdrozone, "ok": certification_ok},
    "v1v2_ok": v1v2_ok,
    "hard_block": hard_block,
    "_routing": routing,
    "_routing_reason": "Dokumentacja wymaga Legal Twin z auto-trace artykul→regula→test, bramki docs↔rules, MANIFEST v3 z pakietami kampanii, harmonizacji slownikow, dokumentacji uzytkownika z narracja decyzyjna PL, certyfikatu kampanii V3 oraz mapowania V1/V2.",
    "_legal_basis": "OrdPU art. 12 § 5, art. 193a; PIT art. 44-45; VAT art. 109; RODO art. 12-14 (przejrzystość informacji); ADR-002; MANIFEST.md",
    "_threshold_version": threshold_version,
    "_registry_version": registry_version,
    "_valid_from": valid_from,
    "_valid_to": valid_to,
    "owner_approval": owner_approval,
    "manual_recipient": manual_recipient,
    "_warnings": [
        "V3-20 bramkuje wyniki audytu dokumentacji — nie generuje dokumentów samodzielnie.",
        "Reguła bez legal_basis albo legal_basis bez reguły blokują wynik.",
        "Certyfikat kampanii bez pełnych 20 części WDROZONY_100 blokuje wynik.",
    ],
} if {
    object.get(input, "docs_quality_v3_20_check", false) == true
}

default decide := {
    "matched": false,
    "rule_id": "jdg.docs.quality_v3_20.no_match",
    "package": "jdg.docs.quality_v3_20",
    "priority": 999999,
    "mode": "DECOUPLED",
    "no_auto_post": true,
}
