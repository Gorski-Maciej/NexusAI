# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ETAP 17 Cross-border / MDR / DAC6 / DAC8 / CFC / CBAM / ViDA / FX
# ═══════════════════════════════════════════════════════════════════════════════
# Pakiet jest warstwą kontrolną nad istniejącymi regułami cross-border. Nie udaje
# porady prawnej, nie wykonuje operacji i nie pozwala na AUTO_POST.

package jdg.crossborder_etap17

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.crossborder_etap17.no_match",
    "package": "jdg.crossborder_etap17",
    "priority": 999999,
    "decision_mode": "SUGGEST",
}

decision_mode := "SUGGEST"

# ADR-002: progi i wersje pochodzą z warstwy danych, a nie z decyzji.
_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_cb := object.get(_thresholds, "crossborder", {})
mdr_risk_high_threshold := object.get(_cb, "mdr_risk_high_threshold", 70)
residency_days_threshold := object.get(_cb, "residency_days", 183)

ctx := object.get(input, "crossborder_etap17", {})
source_refs := object.get(ctx, "source_refs", [])
evidence := object.get(ctx, "evidence", {})
legal_nodes := object.get(ctx, "legal_nodes", {})
evaluation_date := object.get(ctx, "evaluation_date", "")
threshold_version := object.get(ctx, "threshold_version", "")
legal_basis_version := object.get(ctx, "legal_basis_version", "")
facts_version := object.get(ctx, "facts_version", "")

# Każda domena ma ten sam dowód: fakt → dokument → obliczenie → test.
domains := ["residency", "direction", "place_of_supply", "wdt_wnt", "tp_cfc", "mdr_dac", "cbam_vida_dac8", "fx"]

domain_evidence(domain) := {
    "domain": domain,
    "fact": object.get(object.get(evidence, domain, {}), "fact", null),
    "document": object.get(object.get(evidence, domain, {}), "document", null),
    "calculation": object.get(object.get(evidence, domain, {}), "calculation", null),
    "test": object.get(object.get(evidence, domain, {}), "test", null),
    "confidence": object.get(object.get(evidence, domain, {}), "confidence", "LOW"),
    "manual_review": object.get(object.get(evidence, domain, {}), "manual_review", true),
}

evidence_pack := {domain: domain_evidence(domain) | domain := domains[_]}

evidence_complete := count([domain |
    domain := domains[_]
    item := object.get(evidence, domain, {})
    object.get(item, "fact", null) != null
    object.get(item, "document", null) != null
    object.get(item, "calculation", null) != null
    object.get(item, "test", null) != null
]) == count(domains)

context_complete := evaluation_date != "" and threshold_version != "" and legal_basis_version != "" and facts_version != ""
source_complete := count(source_refs) > 0
legal_source_complete := count(legal_nodes) > 0

# Kontrole kierunku i kolizji są celowo konserwatywne.
transaction_direction := object.get(ctx, "transaction_direction", "")
destination_country := object.get(ctx, "destination_country", "")
origin_country := object.get(ctx, "origin_country", "")
vat_chargeable := object.get(ctx, "vat_chargeable", false)
pcc_claimed := object.get(ctx, "pcc_claimed", false)
days_in_poland := object.get(ctx, "days_in_poland", -1)
tax_resident_declared := object.get(ctx, "tax_resident_declared", false)
fx_rate_present := object.get(ctx, "fx_rate_present", false)
mdr_risk_score := object.get(ctx, "mdr_risk_score", 0)
cfc_triggered := object.get(ctx, "cfc_triggered", false)
cbam_triggered := object.get(ctx, "cbam_triggered", false)

conflicts := [
    {"type": "DIRECTION_DESTINATION_CONFLICT", "active": true, "reason": "WDT/WNT ma kierunek sprzeczny z krajem transakcji"} |
    transaction_direction == "WDT"
    destination_country == "PL"
] ++ [
    {"type": "DIRECTION_ORIGIN_CONFLICT", "active": true, "reason": "WNT nie może mieć źródła w Polsce"} |
    transaction_direction == "WNT"
    origin_country == "PL"
] ++ [
    {"type": "VAT_PCC_CONFLICT", "active": true, "reason": "Jednoczesne twierdzenie o opodatkowaniu VAT i PCC wymaga kwalifikacji"} |
    vat_chargeable == true
    pcc_claimed == true
] ++ [
    {"type": "RESIDENCY_DECLARATION_CONFLICT", "active": true, "reason": "Deklaracja rezydencji nie zgadza się z liczbą dni"} |
    days_in_poland >= residency_days_threshold
    tax_resident_declared == false
] ++ [
    {"type": "FX_EVIDENCE_MISSING", "active": true, "reason": "Brak potwierdzonego kursu NBP dla transakcji walutowej"} |
    transaction_direction != ""
    fx_rate_present == false
]

conflict_count := count(conflicts)
high_risk := mdr_risk_score >= mdr_risk_high_threshold or cfc_triggered == true or cbam_triggered == true

confidence := "HIGH" if {
    context_complete
    source_complete
    legal_source_complete
    evidence_complete
    conflict_count == 0
    not high_risk
} else := "MEDIUM" if {
    context_complete
    source_complete
} else := "LOW" if {
    true
}

routing := "BLOCK_AND_ALERT" if {
    not context_complete
} else := "BLOCK_AND_ALERT" if {
    not source_complete
} else := "BLOCK_AND_ALERT" if {
    not legal_source_complete
} else := "BLOCK_AND_ALERT" if {
    conflict_count > 0
} else := "TRIAGE_QUEUE" if {
    high_risk
} else := "TRIAGE_QUEUE" if {
    not evidence_complete
} else := "TRIAGE_QUEUE" if {
    confidence != "HIGH"
} else := "" if {
    true
}

manual_review_required := routing != ""

phase_status := {
    "ingest": "PASS" if {source_complete} else "BLOCK",
    "normalize": "PASS" if {context_complete} else "BLOCK",
    "legal_traceability": "PASS" if {legal_source_complete} else "BLOCK",
    "evidence_pack": "PASS" if {evidence_complete} else "BLOCK",
    "conflict_scan": "PASS" if {conflict_count == 0} else "BLOCK",
    "manual_gate": "REQUIRED" if {manual_review_required} else "AVAILABLE",
    "emit": "SUGGEST_ONLY",
}

# Wszystkie domeny są monitorowane; ViDA/DAC8/CBAM mają status monitoringu,
# a nie fałszywe twierdzenie o wysłaniu raportu lub spełnieniu obowiązku.
domain_scope := {
    "residency": "rezydencja 183 dni / centrum interesów — PIT art. 3",
    "direction": "kierunek WNT/WDT/import/export — VAT art. 9-13",
    "place_of_supply": "miejsce świadczenia — VAT art. 28a-28o",
    "wdt_wnt": "dokumenty, VIES i termin dowodu wywozu — VAT art. 41-42",
    "tp_cfc": "ceny transferowe i CFC — PIT art. 23m-23zf, 30f",
    "mdr_dac": "hallmarks i raportowanie — OrdPU art. 86a-86r / DAC6",
    "cbam_vida_dac8": "monitoring CBAM, ViDA/DRR i DAC8/CARF; bez deklaracji wysyłki",
    "fx": "kurs NBP i różnice kursowe — PIT art. 24c, UoR art. 30",
}

# ETAP 17: evidence-first, temporal, manual-gated verdict.
decide := {
    "matched": true,
    "rule_id": "jdg.crossborder_etap17.evidence_first_verdict",
    "package": "jdg.crossborder_etap17",
    "priority": 17001,
    "decision_mode": "SUGGEST",
    "valid_from": object.get(_cb, "valid_from", "2025-01-01"),
    "valid_to": object.get(_cb, "valid_to", null),
    "stage": "ETAP_17",
    "scope": domain_scope,
    "phase_status": phase_status,
    "evidence_pack": evidence_pack,
    "legal_traceability": legal_nodes,
    "source_refs": source_refs,
    "versions": {
        "evaluation_date": evaluation_date,
        "threshold_version": threshold_version,
        "legal_basis_version": legal_basis_version,
        "facts_version": facts_version,
    },
    "conflicts": conflicts,
    "conflict_count": conflict_count,
    "confidence": confidence,
    "manual_review_required": manual_review_required,
    "high_risk": high_risk,
    "_routing": routing,
    "_routing_reason": "Cross-border ETAP 17: brak dowodu/źródła/wersji lub konflikt blokuje; ryzyko i niepełność trafiają do manual review.",
    "_legal_basis": "VAT art. 9-13, 28a-28o, 41-42; PIT art. 3, 23m-23zf, 24c, 30da-30f; OrdPU art. 86a-86r; DAC6/DAC8; CBAM; ViDA",
    "_warnings": ["Nie stanowi porady prawnej.", "Pakiet nie wysyła deklaracji, raportu ani dokumentu do organu.", "Brak źródła lub confidence nie daje podstawy do rekomendacji transgranicznej."],
    "no_auto_post": true,
} {
    object.get(object.get(input, "jdg_entrepreneur", {}), "crossborder_etap17_check", false) == true
}
