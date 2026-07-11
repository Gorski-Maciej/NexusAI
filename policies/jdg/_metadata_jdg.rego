# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Rule Metadata
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Rule Metadata Registry — Versioning, Severity, Remediation
# description: |
#   Centralny rejestr metadanych dla wszystkich reguł JDG. Zawiera:
#   - rules_metadata: mapowanie rule_id → {version, severity, remediation, references}
#   - policy_version: wersja całego pakietu JDG (YYYY.MM.DD)
#   - Helpers: get_rule_metadata(), get_rule_severity(), all_registered_rules()
#   Używany przez wszystkie pakiety poprzez `import data.jdg.metadata`.
# architecture: Single Source of Truth (SSoT) dla metadanych reguł
# legal_basis: N/A (metadata — nie zawiera reguł podatkowych)
# edge_cases:
#   - Niezarejestrowane rule_id → get_rule_metadata zwraca {}
#   - policy_version aktualizowane przy każdym release
# package: jdg.metadata
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.metadata

# ── Policy Version ────────────────────────────────────────────────────────────

policy_version := "2026.07.10"

# ── Rules Metadata Registry ───────────────────────────────────────────────────

rules_metadata := {
    # ── Risk Rules (P0-P9) ──
    "jdg.risk.fraud_graph_match": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "CRITICAL",
        "category": "FRAUD",
        "framework": ["VAT_COMPLIANCE", "JDG_SAFETY"],
        "remediation": "Zweryfikuj kontrahenta w grafie fraudowym VAT i zgłoś do KAS",
        "references": ["Art. 86 ust. 1 VAT", "Art. 55 KKS", "Doc 34 Sec 4.1"]
    },
    "jdg.risk.counterparty_trust_low": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "MEDIUM",
        "category": "RISK",
        "framework": ["VAT_COMPLIANCE", "JDG_SAFETY"],
        "remediation": "Zweryfikuj wiarygodność kontrahenta przed księgowaniem",
        "references": ["Art. 22 UoR", "Doc 34 Sec 4.1"]
    },

    # ── Allowances Rules (P600-P635) ──
    "jdg.allowances.relief_rd_centrum": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "INFO",
        "category": "TAX_ALLOWANCE",
        "framework": ["PIT_COMPLIANCE", "JDG_ALLOWANCES"],
        "remediation": "Ulga B+R 200% — wymagany status Centrum B+R",
        "references": ["Art. 26e ust. 10 PIT", "jdg.pit.a26e.r1-r15"]
    },
    "jdg.allowances.relief_rd_standard": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "INFO",
        "category": "TAX_ALLOWANCE",
        "framework": ["PIT_COMPLIANCE", "JDG_ALLOWANCES"],
        "remediation": "Ulga B+R 100% — odliczenie kosztów kwalifikowanych od dochodu",
        "references": ["Art. 26e ust. 1 PIT", "jdg.pit.a26e.r1-r15"]
    },
    "jdg.allowances.relief_ikze": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "INFO",
        "category": "TAX_ALLOWANCE",
        "framework": ["PIT_COMPLIANCE", "JDG_ALLOWANCES"],
        "remediation": "IKZE — odliczenie wpłat od dochodu (tylko w zeznaniu rocznym)",
        "references": ["Art. 26 ust. 1 pkt 2b PIT", "jdg.pit.a26b.r1-r6"]
    },
    "jdg.allowances.relief_ip_box": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "INFO",
        "category": "TAX_ALLOWANCE",
        "framework": ["PIT_COMPLIANCE", "JDG_ALLOWANCES"],
        "remediation": "IP Box — 5% od dochodów z kwalifikowanego IP (wymagana ewidencja + Nexus)",
        "references": ["Art. 30ca PIT", "jdg.pit.a30ca.r1-r10"]
    },
    "jdg.allowances.crypto_income_classification": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "HIGH",
        "category": "TAX_CLASSIFICATION",
        "framework": ["PIT_COMPLIANCE", "JDG_SAFETY"],
        "remediation": "Krypto — kapitały pieniężne 19%, NIE łączy się z JDG!",
        "references": ["Art. 30b ust. 1 pkt 1 PIT", "Doc 34 Sec 4.7"]
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

# Lista wszystkich zarejestrowanych rule_id
all_registered_rules = keys {
    keys := object.keys(rules_metadata)
}
