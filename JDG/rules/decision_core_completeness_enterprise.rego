# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — DECISION CORE COMPLETENESS (P02 Warstwa Decyzyjna — Sekcje 3-5)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.decision_core_completeness
# Raport: RAPORT_P02_JDG_WARSTWA_DECYZYJNA_CORE v8.0
#         Sekcja 3 (Edge cases), Sekcja 4 (Korekty i przedawnienia),
#         Sekcja 5 (Odpowiedzialność, reprezentacja, retencja)
#
# DC-01 Edge Case Coverage Matrix — deklaracja pokrycia kombinacji faktów
#       (data.jdg.edge_case_coverage) + detektor brakujących kombinacji.
# DC-02 Limitations Calendar — kalendarz przedawnień per zobowiązanie
#       (Art. 70 §1 OP 5 lat, Art. 70 §2 10 lat, ZUS 5 lat, MDR 5 lat)
#       z alertami o zbliżającym się terminie (bufor z thresholds).
# DC-03 Liability & Representation — odpowiedzialność (Art. 70 OP), prokura,
#       pełnomocnictwa, retencja dokumentów (5 lat, faktury do przedawnienia).
# DC-04 Retention Compliance — zgodność z Art. 86 §1 OP (5 lat) + Art. 112 VAT.
#
# Zgodność: edge_cases.rego (187 bloków), corrections.rego,
#           statute_of_limitations.rego, liability.rego, representation.rego,
#           retention.rego, P02 Sekcje 3-5, ADR-005.
# package: jdg.decision_core_completeness
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.decision_core_completeness

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.decision_core_completeness.no_match","package":"jdg.decision_core_completeness","priority":999999}

# ── DC-01: Edge Case Coverage Matrix ─────────────────────────────────────────
# Deklaracja pokrycia: {fact_combination_id: {"dimensions": [...], "covered": bool}}
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

# ── DC-01b: Detektor brakujących kombinacji ─────────────────────────────────
# Kombinacje faktów obecne w input (input.edge_case_probe.dimensions) bez
# wpisu w macierzy pokrycia → luka pokrycia (gap).
uncovered_combinations := [combo |
    probe := object.get(input.edge_case_probe, "dimensions", [])
    count(probe) > 0
    some combo in probe
    not covered_combination(combo)
]

covered_combination(combo) = true {
    some ec_id in object.keys(edge_case_coverage)
    dims := object.get(edge_case_coverage[ec_id], "dimensions", [])
    object.get(edge_case_coverage[ec_id], "covered", false) == true
    count(dims) > 0
    # combo (string "a,b,c") pokryty gdy wszystkie wymiary są w dims
    combo_dims := split(combo, ",")
    all_dims_present(combo_dims, dims) == true
} else = false {
    true
}

all_dims_present(combo_dims, dims) = true {
    count([d | some d in combo_dims; not (d in dims)]) == 0
} else = false {
    true
}

# ── DC-02: LIMITATIONS CALENDAR ──────────────────────────────────────────────
# Kalendarz przedawnień per zobowiązanie z alertami.
# input.limitations_calendar = {"obligations": [{"type": "VAT|PIT|ZUS|MDR",
#   "tax_year": 2020, "due_end_of_year": 2020, "fiscal_crime": false, ...}]}
limitation_period_years(obligation_type) = 5 {
    obligation_type in {"VAT", "PIT", "ZUS", "MDR", "CIT"}
} else := 10 {
    true
}

# Art. 70 §1 OP: bieg przedawnienia LICZY SIĘ OD KOŃCA ROKU KALENDARZOWEGO,
# w którym upłynął termin płatności. Dla zobowiązań rocznych (PIT, CIT, MDR)
# termin płatności przypada w roku NASTĘPNYM po roku podatkowym (np. PIT za
# 2020 → 30.04.2021), więc okno zamyka się na koniec tax_year + 1 + okres.
# Spójnie z narzędziem limitations_calendar.py (DEADLINE_YEAR_OFFSET).
deadline_year_offset(obligation_type) = 1 {
    obligation_type in {"PIT", "CIT", "MDR"}
} else := 0 {
    true
}

limitations_calendar_entries := [entry |
    some ob in object.get(input.limitations_calendar, "obligations", [])
    ob_type := object.get(ob, "type", "VAT")
    ob_year := object.get(ob, "tax_year", 0)
    # Przedawnienie: koniec roku terminu płatności + N lat
    years := limitation_period_years(ob_type) + deadline_year_offset(ob_type)
    expire_year := ob_year + years
    today_year := to_number(substring(object.get(input, "evaluation_datetime", "2026-01-01"), 0, 4))
    remaining := expire_year - today_year
    entry := {
        "obligation_type": ob_type,
        "tax_year": ob_year,
        "expire_year": expire_year,
        "remaining_years": remaining,
        "status": status_for_remaining(remaining)
    }
]

status_for_remaining(remaining) = "EXPIRED" {
    remaining < 0
} else := "CRITICAL" {
    remaining == 0
} else := "ALERT" {
    remaining == 1
} else := "WATCH" {
    remaining <= 3
} else := "OK" {
    true
}

# ── DC-02b: DECYZJA — PRZEDAWNIENIE / ALERT ─────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.decision_core_completeness.limitations_alert",
    "package": "jdg.decision_core_completeness",
    "priority": 100,
    "limitations_calendar": [e | some e in limitations_calendar_entries; e.status in {"CRITICAL", "EXPIRED", "ALERT"}],
    "expired_count": count([e | some e in limitations_calendar_entries; e.status == "EXPIRED"]),
    "critical_count": count([e | some e in limitations_calendar_entries; e.status == "CRITICAL"]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KALENDARZ PRZEDAWNIEŃ: zobowiązanie przedawnione lub w oknie krytycznym",
    "_legal_basis": "Art. 70 § 1-2 Ordynacja podatkowa (5/10 lat)",
    "_warnings": ["Przedawnienie zobowiązania: brak podstawy do egzekucji (Art. 70 § 1 OP). Sprawdź ewentualne przerwanie biegu terminu."]
} {
    object.get(input.jdg_entrepreneur, "limitations_check", false) == true
    count([e | some e in limitations_calendar_entries; e.status in {"CRITICAL", "EXPIRED"}]) > 0
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
} {
    object.get(input.jdg_entrepreneur, "limitations_check", false) == true
    # Nie przesłaniać pozostałych bramek: kalendarz-raport tylko gdy NIE ma
    # jednocześnie włączonych compliance/edge-case/completeness checków.
    object.get(input.jdg_entrepreneur, "compliance_check", false) == false
    object.get(input.jdg_entrepreneur, "edge_case_check", false) == false
    object.get(input.jdg_entrepreneur, "completeness_check", false) == false
}

# ── DC-03: LIABILITY / REPRESENTATION / RETENTION COMPLIANCE ─────────────────
# input.compliance_probe = {"has_power_of_attorney": bool, "has_prokura": bool,
#   "retention_docs_years": int, "fiscal_crime": bool, ...}
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

# ── DC-03b: DECYZJA — RETENTION NON-COMPLIANT ────────────────────────────────
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
} {
    object.get(input.jdg_entrepreneur, "compliance_check", false) == true
    retention_compliance.compliant == false
}

# ── DC-04: DECYZJA — EDGE CASE GAP ───────────────────────────────────────────
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
} {
    object.get(input.jdg_entrepreneur, "edge_case_check", false) == true
    count(uncovered_combinations) > 0
}

# ── DECYZJA: KOMPLETNOŚĆ OK ──────────────────────────────────────────────────
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
} {
    object.get(input.jdg_entrepreneur, "completeness_check", false) == true
}

# ── EKSPORT: RAPORT KOMPLETNOŚCI ─────────────────────────────────────────────
completeness_report := {
    "edge_case_coverage": count(object.keys(edge_case_coverage)),
    "uncovered_combinations": uncovered_combinations,
    "limitations_calendar": limitations_calendar_entries,
    "retention_compliance": retention_compliance,
    "representation_compliance": representation_compliance
}
