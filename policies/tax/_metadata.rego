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

policy_version := "2026.07.11"

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
    },

    # ── Temporal Rules (ScTemporalSandbox) ──
    "tax.temporal.period_active": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-11",
        "severity": "LOW",
        "category": "TEMPORAL",
        "framework": ["TEMPORAL_SANDBOX"],
        "remediation": "Wybrano aktywny okres thresholds na podstawie daty transakcji",
        "references": ["ScTemporalSandbox (38_STRATEGIC_IMPROVEMENTS)"]
    },

    # ── Anomaly Rules (ScAnomalyGuard) ──
    "tax.anomaly.amount_zscore": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "ANOMALY",
        "framework": ["ANOMALY_GUARD"],
        "remediation": "Kwota faktury przekracza 3σ — zweryfikuj poprawność",
        "references": ["ScAnomalyGuard (38_STRATEGIC_IMPROVEMENTS)"]
    },
    "tax.anomaly.vendor_first_large": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-11",
        "severity": "MEDIUM",
        "category": "ANOMALY",
        "framework": ["ANOMALY_GUARD", "AML"],
        "remediation": "Nowy kontrahent z wysoką pierwszą fakturą — dodatkowa weryfikacja",
        "references": ["ScAnomalyGuard (38_STRATEGIC_IMPROVEMENTS)"]
    },
    "tax.anomaly.partner_cost_ratio": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "ANOMALY",
        "framework": ["ANOMALY_GUARD", "SC_FRAUD"],
        "remediation": "Dysproporcja kosztów między udziałem wspólnika — potencjalne nadużycie",
        "references": ["ScAnomalyGuard (38_STRATEGIC_IMPROVEMENTS)"]
    },

    # ── What-If Rules (ScWhatIf Engine) ──
    "tax.what_if.simulation_active": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-11",
        "severity": "LOW",
        "category": "SIMULATION",
        "framework": ["WHAT_IF_ENGINE"],
        "remediation": "Tryb symulacyjny aktywny — werdykt NIE jest rzeczywistą decyzją podatkową",
        "references": ["ScWhatIf Engine (38_STRATEGIC_IMPROVEMENTS)"]
    },

    # ── Partner Mirror Rules (ScPartnerMirror) ──
    "tax.partner_mirror.split_active": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-11",
        "severity": "LOW",
        "category": "PRIVACY",
        "framework": ["RODO", "PARTNER_MIRROR"],
        "remediation": "Werdykt podzielony na PartnerPrivateVerdict i PartnershipRiskMirror",
        "references": ["RODO Art. 5", "Art. 864 KC", "ScPartnerMirror (38_STRATEGIC_IMPROVEMENTS)"]
    },

    # ── SC Partnership Lifecycle Rules ──
    "tax.sc_partnership.formation_verbal": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "MEDIUM",
        "category": "PARTNERSHIP",
        "framework": ["SC_LIFECYCLE"],
        "remediation": "Umowa SC ustna — zalecana forma pisemna dla celów dowodowych",
        "references": ["Art. 860 KC", "GR-330 do GR-349"]
    },
    "tax.sc_partnership.partner_addition_no_consent": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "CRITICAL",
        "category": "PARTNERSHIP",
        "framework": ["SC_LIFECYCLE"],
        "remediation": "Dodanie wspólnika wymaga zgody 100% dotychczasowych — operacja zablokowana",
        "references": ["Art. 860 § 2 KC"]
    },
    "tax.sc_partnership.dissolution_all_agree": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "PARTNERSHIP",
        "framework": ["SC_LIFECYCLE"],
        "remediation": "Rozwiązanie SC — odpowiedzialność solidarna trwa do zaspokojenia wierzycieli",
        "references": ["Art. 874-875 KC", "GR-385 do GR-414"]
    },
    "tax.sc_partnership.succession_death": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "SUCCESSION",
        "framework": ["SC_LIFECYCLE"],
        "remediation": "Sukcesja po śmierci wspólnika — spadkobiercy wchodzą w prawa i obowiązki",
        "references": ["Art. 872 KC", "Art. 97 Ordynacji podatkowej"]
    },
    "tax.sc_partnership.suspension_over_24m": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "PARTNERSHIP",
        "framework": ["SC_LIFECYCLE"],
        "remediation": "Zawieszenie >24 miesiące — obowiązek wznowienia lub rozwiązania SC",
        "references": ["Art. 22 Prawo przedsiębiorców"]
    },

    # ── SC Liability Rules ──
    "tax.sc_liability.joint_all": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "CRITICAL",
        "category": "LIABILITY",
        "framework": ["SC_SAFETY"],
        "remediation": "Wszyscy wspólnicy odpowiadają solidarnie całym majątkiem — Art. 864 KC",
        "references": ["Art. 864 KC", "Art. 366 KC"]
    },
    "tax.sc_liability.regress_right": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "MEDIUM",
        "category": "LIABILITY",
        "framework": ["SC_SAFETY"],
        "remediation": "Regres między wspólnikami — proporcjonalny do udziałów",
        "references": ["Art. 376 KC", "GR-1174 do GR-1178"]
    },
    "tax.sc_liability.spouse_limited": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "LIABILITY",
        "framework": ["SC_SAFETY", "FAMILY"],
        "remediation": "Małżonek NIE odpowiada majątkiem osobistym za długi SC",
        "references": ["Art. 41 KRO", "GR-1179 do GR-1183"]
    },

    # ── SC KSeF / JPK Rules ──
    "tax.sc_ksef_jpk.ksef_mandatory": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "MEDIUM",
        "category": "KSEF",
        "framework": ["VAT_COMPLIANCE", "KSEF"],
        "remediation": "SC jako podatnik VAT — obowiązek KSeF dla faktur B2B",
        "references": ["Art. 106ga-106gd VAT"]
    },
    "tax.sc_ksef_jpk.cash_over_limit": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "COMPLIANCE",
        "framework": ["SC_SAFETY", "KUP"],
        "remediation": "Płatność gotówkowa >15k PLN — NKUP dla wszystkich wspólników",
        "references": ["Art. 22p PIT"]
    },

    # ── SC Fallback Rules ──
    "tax.sc_fallback.domestic_sc": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "LOW",
        "category": "FALLBACK",
        "framework": ["SC_DEFAULT"],
        "remediation": "Domyślna stawka VAT 23% dla SC — żadna szczegółowa reguła nie pasuje",
        "references": ["Art. 41 ust. 1 VAT"]
    },
    "tax.sc_fallback.dissolved_sc": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "FALLBACK",
        "framework": ["SC_LIFECYCLE"],
        "remediation": "SC w likwidacji — odpowiedzialność solidarna nadal obowiązuje",
        "references": ["Art. 875 KC"]
    },
    "tax.sc_fallback.succession_sc": {
        "version": "1.0.0",
        "author": "NexusAI SC Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "FALLBACK",
        "framework": ["SC_LIFECYCLE"],
        "remediation": "Sukcesja — spadkobiercy wchodzą w prawa i obowiązki zmarłego wspólnika",
        "references": ["Art. 872 KC", "Art. 97 Ordynacji podatkowej"]
    },

    # ── Seasonal Anomaly Rules ──
    "tax.anomaly.seasonal_december_spike": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-11",
        "severity": "MEDIUM",
        "category": "ANOMALY",
        "framework": ["ANOMALY_GUARD", "ANTI_FRAUD"],
        "remediation": "Nietypowy wzrost faktur w grudniu — potencjalne sztuczne koszty",
        "references": ["ScAnomalyGuard (38_STRATEGIC_IMPROVEMENTS)"]
    },
    "tax.anomaly.ml_model_high_risk": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-11",
        "severity": "HIGH",
        "category": "ANOMALY",
        "framework": ["ANOMALY_GUARD", "ML"],
        "remediation": "Model ML wykrył anomalię — wymagana weryfikacja manualna",
        "references": ["ScAnomalyGuard (38_STRATEGIC_IMPROVEMENTS)"]
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
