# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Rule Metadata
# ═══════════════════════════════════════════════════════════════════════════════
#
# Metadane dla wszystkich reguł — wersjonowanie, severity, remediation.
# Wzorzec: kubescape/regolibrary — rule.metadata.json per rule.
#
# package: tax.metadata
# ═══════════════════════════════════════════════════════════════════════════════

package tax.metadata

# ── Policy Version ────────────────────────────────────────────────────────────

policy_version := "2026.07.07"

# ── Rules Metadata ────────────────────────────────────────────────────────────

rules_metadata := {
    # ── Risk Rules (P0-P9) ──
    "tax.risk.fraud_graph_match": {
        "version": "1.2.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "CRITICAL",
        "category": "FRAUD",
        "framework": ["VAT_COMPLIANCE", "AML"],
        "remediation": "Zweryfikuj kontrahenta w grafie fraudowym VAT i zgłoś do KAS",
        "references": ["Art. 86 ust. 1 VAT", "Art. 55 KKS"]
    },
    "tax.risk.counterparty_trust_low": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "MEDIUM",
        "category": "RISK",
        "framework": ["VAT_COMPLIANCE"],
        "remediation": "Zweryfikuj wiarygodność kontrahenta przed księgowaniem",
        "references": ["Art. 22 UoR", "ADR-009"]
    },
    "tax.risk.anomaly_amount": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "HIGH",
        "category": "ANOMALY",
        "framework": ["AUDIT"],
        "remediation": "Sprawdź czy kwota faktury jest zgodna z umową i zakresem usług",
        "references": ["Art. 22 UoR (zasada ostrożności)"]
    },
    "tax.risk.new_counterparty_flag": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "LOW",
        "category": "RISK",
        "framework": ["VAT_COMPLIANCE"],
        "remediation": "Przeprowadź wstępną weryfikację nowego kontrahenta",
        "references": ["Art. 22 UoR", "procedury AML"]
    },
    "tax.risk.semantic_guard_disallowed": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "HIGH",
        "category": "COMPLIANCE",
        "framework": ["CIT_COMPLIANCE", "PIT_COMPLIANCE"],
        "remediation": "Wydatek niezwiązany z działalnością — nie księguj jako KUP",
        "references": ["Art. 23 ust. 1 pkt 23 PIT", "Art. 16 ust. 1 pkt 28 CIT"]
    },

    # ── Routing Rules (P10-P19) ──
    "tax.routing.fc_vat_rate_low": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "HIGH",
        "category": "OCR_CONFIDENCE",
        "framework": ["ROUTING"],
        "remediation": "Zweryfikuj ręcznie stawkę VAT na fakturze — OCR może być błędny",
        "references": ["Art. 22 UoR (rzetelność ksiąg)"]
    },
    "tax.routing.fc_vendor_nip_low": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "HIGH",
        "category": "OCR_CONFIDENCE",
        "framework": ["ROUTING", "WHITE_LIST"],
        "remediation": "Zweryfikuj ręcznie NIP kontrahenta — błędny NIP uniemożliwia weryfikację Białej Listy",
        "references": ["Art. 96b VAT", "Art. 22 UoR"]
    },

    # ── Compliance Rules (P20-P39) ──
    "tax.compliance.whitelist_missing": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "CRITICAL",
        "category": "COMPLIANCE",
        "framework": ["VAT_COMPLIANCE", "WHITE_LIST"],
        "remediation": "Sprawdź kontrahenta na Białej Liście MF przed przelewem >15 000 PLN",
        "references": ["Art. 96b VAT", "Art. 117ba Ordynacji podatkowej"]
    },
    "tax.compliance.split_payment_mandatory": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "HIGH",
        "category": "COMPLIANCE",
        "framework": ["VAT_COMPLIANCE", "MPP"],
        "remediation": "Zastosuj mechanizm podzielonej płatności (MPP) dla tej faktury",
        "references": ["Art. 108a ustawy o VAT"]
    },
    "tax.compliance.cash_over_limit": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "HIGH",
        "category": "COMPLIANCE",
        "framework": ["CIT_COMPLIANCE", "PIT_COMPLIANCE"],
        "remediation": "Płatność gotówkowa powyżej limitu — nie zaliczaj do KUP",
        "references": ["Art. 22p PIT", "Art. 15d CIT"]
    }
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# Pobiera metadane dla konkretnej reguły
get_rule_metadata(rule_id) = metadata {
    metadata := object.get(rules_metadata, rule_id, {})
}

# Pobiera severity reguły
get_rule_severity(rule_id) = severity {
    severity := object.get(object.get(rules_metadata, rule_id, {}), "severity", "UNKNOWN")
}
