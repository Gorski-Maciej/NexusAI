# NexusAI JDG — decision core completeness (P02 sections 3-5).
# Covers edge-case matrix, limitations calendar, representation and retention.

package jdg.decision_core_completeness

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.decision_core_completeness.no_match",
    "package": "jdg.decision_core_completeness",
    "priority": 999999
}

default_edge_case_coverage := {
    "ec_vat_breach_mid_year": {"dimensions": ["vat", "limit_breach", "mid_year"], "covered": true},
    "ec_suspension_health_still_due": {"dimensions": ["sus", "suspension", "health"], "covered": true},
    "ec_car_lease_vs_own": {"dimensions": ["vat", "car", "lease"], "covered": true},
    "ec_ipbox_no_nexus": {"dimensions": ["pit", "ipbox", "nexus"], "covered": true},
    "ec_bad_debt_creditor_mirror": {"dimensions": ["vat", "bad_debt", "mirror"], "covered": true},
    "ec_ryczalt_health_tier_cross": {"dimensions": ["zus", "health", "ryczalt", "tier_cross"], "covered": true},
    "ec_whitelist_after_30d": {"dimensions": ["vat", "whitelist", "30d"], "covered": true},
    "ec_ksef_offline_7d": {"dimensions": ["ksef", "offline", "7d"], "covered": true}
}

edge_case_coverage := object.get(data.jdg, "edge_case_coverage", default_edge_case_coverage)

covered_combination(combo) = true if {
    some ec_id in object.keys(edge_case_coverage)
    entry := object.get(edge_case_coverage, ec_id, {})
    dims := object.get(entry, "dimensions", [])
    object.get(entry, "covered", false) == true
    combo_dims := split(combo, ",")
    count([dimension | some dimension in combo_dims; not array_contains(dims, dimension)]) == 0
} else = false if {
    true
}

array_contains(values, value) if {
    some index
    values[index] == value
}

all_uncovered_combinations := [combo |
    probe := object.get(input, "edge_case_probe", {})
    dimensions := object.get(probe, "dimensions", [])
    some combo in dimensions
    not covered_combination(combo)
]

uncovered_combinations := all_uncovered_combinations

limitation_period_years(obligation_type) = 5 if {
    obligation_type in {"VAT", "PIT", "ZUS", "MDR", "CIT"}
} else = 10 if {
    true
}

deadline_year_offset(obligation_type) = 1 if {
    obligation_type in {"PIT", "CIT", "MDR"}
} else = 0 if {
    true
}

status_for_remaining(remaining) = "EXPIRED" if {
    remaining < 0
} else = "CRITICAL" if {
    remaining == 0
} else = "ALERT" if {
    remaining == 1
} else = "WATCH" if {
    remaining <= 3
} else = "OK" if {
    true
}

limitations_calendar_entries := [entry |
    some obligation in object.get(input.limitations_calendar, "obligations", [])
    obligation_type := object.get(obligation, "type", "VAT")
    tax_year := object.get(obligation, "tax_year", 0)
    years := limitation_period_years(obligation_type) + deadline_year_offset(obligation_type)
    expire_year := tax_year + years
    evaluation_year := to_number(substring(object.get(input, "evaluation_datetime", "2026-01-01"), 0, 4))
    remaining := expire_year - evaluation_year
    entry := {
        "obligation_type": obligation_type,
        "tax_year": tax_year,
        "expire_year": expire_year,
        "remaining_years": remaining,
        "status": status_for_remaining(remaining)
    }
]

critical_entries := [entry |
    entry := limitations_calendar_entries[_]
    entry.status in {"CRITICAL", "EXPIRED"}
]
alert_entries := [entry |
    entry := limitations_calendar_entries[_]
    entry.status in {"CRITICAL", "EXPIRED", "ALERT"}
]

liability_compliance := {
    "statute_of_limitations": "5y (Art. 70 §1 OP), 10y dla przestępstw skarbowych (Art. 70 §2 OP)",
    "fiscal_crime_flag": object.get(input.compliance_probe, "fiscal_crime", false),
    "personal_liability": object.get(input.compliance_probe, "personal_liability", false)
}

representation_compliance := {
    "has_power_of_attorney": object.get(input.compliance_probe, "has_power_of_attorney", false),
    "has_prokura": object.get(input.compliance_probe, "has_prokura", false),
    "poa_fee": 17,
    "note": "Pełnomocnictwo: opłata skarbowa 17 PLN; prokura wymaga zgłoszenia do CEIDG/KRS"
}

retention_compliance := {
    "docs_retention_years": object.get(input.compliance_probe, "retention_docs_years", 0),
    "required_min": 5,
    "compliant": object.get(input.compliance_probe, "retention_docs_years", 0) >= 5,
    "legal_basis": "Art. 86 § 1 OP (5 lat) + Art. 112 VAT (faktury do przedawnienia)"
}

completeness_report := {
    "edge_case_coverage": count(object.keys(edge_case_coverage)),
    "uncovered_combinations": uncovered_combinations,
    "limitations_calendar": limitations_calendar_entries,
    "retention_compliance": retention_compliance,
    "representation_compliance": representation_compliance
}

# DC-02: limitations alert.
decide := {
    "matched": true,
    "rule_id": "jdg.decision_core_completeness.limitations_alert",
    "package": "jdg.decision_core_completeness",
    "priority": 100,
    "limitations_calendar": alert_entries,
    "expired_count": count([entry | entry := limitations_calendar_entries[_]; entry.status == "EXPIRED"]),
    "critical_count": count([entry | entry := limitations_calendar_entries[_]; entry.status == "CRITICAL"]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KALENDARZ PRZEDAWNIEŃ: zobowiązanie przedawnione lub w oknie krytycznym",
    "_legal_basis": "Art. 70 § 1-2 Ordynacja podatkowa (5/10 lat)",
    "_warnings": ["Przedawnienie zobowiązania: brak podstawy do egzekucji (Art. 70 § 1 OP). Sprawdź ewentualne przerwanie biegu terminu."]
} if {
    object.get(input, "jdg_entrepreneur", {}).limitations_check == true
    count(critical_entries) > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.decision_core_completeness.limitations_calendar_report",
    "package": "jdg.decision_core_completeness",
    "priority": 110,
    "limitations_calendar": limitations_calendar_entries,
    "total_obligations": count(limitations_calendar_entries),
    "_routing": "REPORT",
    "_routing_reason": "Kalendarz przedawnień per zobowiązanie (monitoring proaktywny)",
    "_legal_basis": "Art. 70 OP + P02 Sekcja 4",
    "_warnings": []
} if {
    object.get(input, "jdg_entrepreneur", {}).limitations_check == true
    object.get(input, "jdg_entrepreneur", {}).compliance_check == false
    object.get(input, "jdg_entrepreneur", {}).edge_case_check == false
    object.get(input, "jdg_entrepreneur", {}).completeness_check == false
}

else := {
    "matched": true,
    "rule_id": "jdg.decision_core_completeness.retention_non_compliant",
    "package": "jdg.decision_core_completeness",
    "priority": 120,
    "compliance": {
        "liability": liability_compliance,
        "representation": representation_compliance,
        "retention": retention_compliance
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "RETENTION NON-COMPLIANT: dokumenty przechowywane < 5 lat (Art. 86 §1 OP)",
    "_legal_basis": "Art. 86 § 1 Ordynacja podatkowa",
    "_warnings": ["Okres przechowywania dokumentów < 5 lat. Ryzyko kontroli KAS — uzupełnij archiwizację."]
} if {
    object.get(input, "jdg_entrepreneur", {}).compliance_check == true
    retention_compliance.compliant == false
}

else := {
    "matched": true,
    "rule_id": "jdg.decision_core_completeness.edge_case_gap",
    "package": "jdg.decision_core_completeness",
    "priority": 130,
    "uncovered_combinations": uncovered_combinations,
    "gap_count": count(uncovered_combinations),
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "EDGE CASE GAP: kombinacja faktów bez pokrycia regułowego — możliwa niejednoznaczna decyzja",
    "_legal_basis": "P02 Sekcja 3 — Edge Case Completeness",
    "_warnings": ["Brak reguł dla kombinacji faktów. Dodaj reguły dopełniające przed AUTO_POST."]
} if {
    object.get(input, "jdg_entrepreneur", {}).edge_case_check == true
    count(uncovered_combinations) > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.decision_core_completeness.ok",
    "package": "jdg.decision_core_completeness",
    "priority": 140,
    "completeness": {
        "edge_cases_covered": count(object.keys(edge_case_coverage)),
        "limitations_calendar": limitations_calendar_entries,
        "retention_compliant": retention_compliance.compliant,
        "uncovered_combinations": uncovered_combinations
    },
    "_routing": "REPORT",
    "_routing_reason": "Kompletność warstwy decyzyjnej OK — brak luk edge-case, retencja zgodna",
    "_legal_basis": "P02 Sekcje 3-5",
    "_warnings": []
} if {
    object.get(input, "jdg_entrepreneur", {}).completeness_check == true
}
