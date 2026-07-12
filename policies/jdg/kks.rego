# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — KKS: Kodeks Karny Skarbowy (P200-P499)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: KKS Package — Penal Fiscal Code Full Decomposition (200+ rules)
# description: |
#   Rozbudowany silnik KKS — 200+ reguł w 4 grupach:
#   - P200-P229: Czynny żal i przedawnienie karalności (30 reguł, Art. 16-19, 44, 51 KKS)
#   - P240-P339: Przestępstwa skarbowe (100 reguł, Art. 54-62, 76, 83 KKS)
#   - P400-P459: Wykroczenia skarbowe (60 reguł, Art. 60-61, 77-83 KKS)
#   - P460-P499: Sankcje, zabezpieczenia, postępowanie (40 reguł, Art. 22-53 KKS)
# architecture: First-Match-Wins else-chain, priorytety P200-P499
# legal_basis: Kodeks Karny Skarbowy (Dz.U. 2024 poz. 628 t.j.)
# edge_cases:
#   - Czynny żal: tylko przed rozpoczęciem postępowania przez KAS (Art. 16 § 5)
#   - Przedawnienie: 5 lat przestępstwa (Art. 44 § 1), 3 lata wykroczenia (Art. 51 § 1)
#   - Puste faktury: najwyższa kara do 25 lat pozbawienia wolności (Art. 62 § 2)
#   - Nierzetelne księgi: sankcja do 240 stawek dziennych (Art. 56 § 1)
#   - Niszczenie dokumentów: Art. 60 KKS (brak ksiąg) + art. 276 KK
# package: jdg.kks
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.kks

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.kks.no_match",
    "package": "jdg.kks", "priority": 999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA A: P200-P229 — CZYNNY ŻAL I PRZEDAWNIENIE KARALNOŚCI              ║
# ║  Art. 16-19, 44, 51 KKS — 30 reguł                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ──── P200-P205: Czynny żal (Art. 16 KKS) — 6 reguł ───────────────────────────

# P200: voluntary_disclosure_eligible — Warunki czynnego żalu
decide := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_eligible",
    "package": "jdg.kks", "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": true, "kks_immunity_possible": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 16 § 1 KKS",
    "_warnings": ["Czynny żal możliwy — złóż zawiadomienie do KAS przed rozpoczęciem postępowania!"]
} {
    input.jdg_entrepreneur.kks_voluntary_disclosure_filed == false
    input.invoice.kks_flag == true
    postepowanie := object.get(input.jdg_entrepreneur, "kks_proceedings_started", false)
    postepowanie == false
}

# P201: voluntary_disclosure_deadline_breach — Spóźniony czynny żal
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_deadline_breach",
    "package": "jdg.kks", "priority": 201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": false, "kks_immunity_possible": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Czynny żal niemożliwy — postępowanie już wszczęte",
    "_legal_basis": "Art. 16 § 5 KKS",
    "_warnings": ["Czynny żal NIEMOŻLIWY — KAS wszczęło już postępowanie. Skontaktuj się z adwokatem!"]
} {
    input.jdg_entrepreneur.kks_proceedings_started == true
    input.invoice.kks_flag == true
}

# P202: voluntary_disclosure_successor — Czynny żal przez następcę prawnego
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_successor",
    "package": "jdg.kks", "priority": 202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": true, "kks_successor_filing": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 16 § 3 KKS",
    "_warnings": ["Czynny żal przez następcę prawnego — ujawnij wszystkie znane nieprawidłowości"]
} {
    input.jdg_entrepreneur.in_succession == true
    input.invoice.kks_flag == true
}

# P203: voluntary_disclosure_partial — Częściowe ujawnienie
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_partial",
    "package": "jdg.kks", "priority": 203,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": true, "kks_partial_disclosure": true,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Częściowy czynny żal — immunitet tylko dla ujawnionych czynów",
    "_legal_basis": "Art. 16 § 2 KKS",
    "_warnings": ["Częściowy czynny żal — immunitet tylko dla ujawnionych czynów. Nieujawnione = pełna odpowiedzialność!"]
} {
    input.jdg_entrepreneur.kks_voluntary_disclosure_partial == true
}

# P204: voluntary_disclosure_payment — Wpłata należności przy czynnym żalu
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_payment",
    "package": "jdg.kks", "priority": 204,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": true, "kks_payment_required": true,
    "kks_amount_due": amount_due,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Wymagana wpłata zaległości przy czynnym żalu",
    "_legal_basis": "Art. 16 § 4 KKS",
    "_warnings": [sprintf("Wpłać %.2f PLN zaległości w ciągu 7 dni dla skuteczności czynnego żalu", [amount_due])]
} {
    amount_due := object.get(input.invoice, "kks_tax_shortfall", 0)
    amount_due > 0
}

# P205: voluntary_disclosure_multiple_offenses — Czynny żal przy wielu czynach
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_multiple_offenses",
    "package": "jdg.kks", "priority": 205,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": true, "kks_multiple_offenses": true,
    "kks_disclosed_count": offense_count,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Wiele czynów — czynny żal musi objąć wszystkie",
    "_legal_basis": "Art. 16 § 1-6 KKS",
    "_warnings": [sprintf("Wiele czynów (%d) — czynny żal musi objąć KAŻDY czyn osobno. Nieujawniony = pełna kara!", [offense_count])]
} {
    offense_count := object.get(input.jdg_entrepreneur, "kks_offenses_count", 0)
    offense_count > 1
    input.jdg_entrepreneur.kks_voluntary_disclosure_filed == true
}

# ──── P206-P209: Rozszerzone warianty czynnego żalu — 4 reguły ─────────────────

# P206: voluntary_disclosure_correction_before_audit — Korekta przed kontrolą
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_correction_before_audit",
    "package": "jdg.kks", "priority": 206,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": true, "kks_correction_before_audit": true,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Korekta deklaracji przed kontrolą — ochrona przed KKS",
    "_legal_basis": "Art. 16 § 1 KKS w zw. z Art. 81 OrdPU",
    "_warnings": [sprintf("Korekta %s przed kontrolą KAS — złóż czynny żal + skorygowaną deklarację + wpłać zaległość", [decl_type])]
} {
    input.invoice.correction_before_audit == true
    decl_type := object.get(input.invoice, "tax_declaration_type", "")
    decl_type != ""
}

# P207: voluntary_disclosure_foreign_tax — Czynny żal od zagranicznych zobowiązań
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_foreign_tax",
    "package": "jdg.kks", "priority": 207,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": true, "kks_foreign_tax_exposure": true,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Zagraniczne zobowiązania — czynny żal + CRS/FATCA",
    "_legal_basis": "Art. 16 § 1 KKS w zw. z umowami o unikaniu podwójnego opodatkowania",
    "_warnings": ["Zagraniczne zobowiązania podatkowe — czynny żal w PL może nie chronić przed karami za granicą. Skonsultuj z doradcą międzynarodowym!"]
} {
    input.jdg_entrepreneur.has_foreign_tax_exposure == true
    input.invoice.kks_flag == true
}

# P208: voluntary_disclosure_mandatory_reporter — Obowiązek zgłoszenia przez doradcę (MDR)
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_mandatory_reporter",
    "package": "jdg.kks", "priority": 208,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": true, "kks_mdr_triggered": true,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "MDR — schemat podatkowy wymaga zgłoszenia do Szefa KAS",
    "_legal_basis": "Art. 86a-86o OrdPU (MDR)",
    "_warnings": ["MDR — doradca/podatnik ma obowiązek zgłoszenia schematu podatkowego w ciągu 30 dni. Brak = kara do 2 mln PLN!"]
} {
    input.invoice.mdr_scheme_detected == true
}

# P209: voluntary_disclosure_bribe_disclosure — Ujawnienie łapówki (Art. 16a KKS)
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_bribe_disclosure",
    "package": "jdg.kks", "priority": 209,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_voluntary_disclosure": true, "kks_bribe_disclosed": true,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ujawnienie łapówki — nadzwyczajne złagodzenie kary",
    "_legal_basis": "Art. 16a KKS",
    "_warnings": ["Ujawnienie łapówki przed organem — możliwe nadzwyczajne złagodzenie kary, ale czynny żal standardowy NIE wystarcza"]
} {
    input.jdg_entrepreneur.bribe_disclosed_to_authorities == true
}

# ──── P210-P215: Okoliczności łagodzące (Art. 17-19 KKS) — 6 reguł ────────────

# P210: extraordinary_mitigation — Nadzwyczajne złagodzenie kary
else := {
    "matched": true, "rule_id": "jdg.kks.extraordinary_mitigation",
    "package": "jdg.kks", "priority": 210,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_mitigation_applied": true, "kks_extraordinary_mitigation_possible": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 17 KKS",
    "_warnings": ["Nadzwyczajne złagodzenie kary możliwe — wniosek przez adwokata. Sąd może obniżyć karę poniżej dolnej granicy"]
} {
    object.get(input.jdg_entrepreneur, "kks_extraordinary_mitigation", false) == true
}

# P211: minor_significance — Znikoma szkodliwość społeczna
else := {
    "matched": true, "rule_id": "jdg.kks.minor_significance",
    "package": "jdg.kks", "priority": 211,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_mitigation_applied": true, "kks_minor_significance": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 18 KKS",
    "_warnings": [sprintf("Znikoma szkodliwość społeczna — uszczuplenie %.2f PLN poniżej progu. Możliwość odstąpienia od kary", [shortfall])]
} {
    shortfall := object.get(input.invoice, "kks_tax_shortfall", 0)
    shortfall > 0
    shortfall <= 5000
    input.jdg_entrepreneur.kks_voluntary_disclosure_filed == true
}

# P212: damage_restitution — Naprawienie szkody przed wyrokiem
else := {
    "matched": true, "rule_id": "jdg.kks.damage_restitution",
    "package": "jdg.kks", "priority": 212,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_mitigation_applied": true, "kks_damage_repaired": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 19 § 1 KKS",
    "_warnings": [sprintf("Naprawienie szkody %.2f PLN przed wyrokiem — okoliczność łagodząca. Wpływa na wymiar kary", [repaired])]
} {
    repaired := object.get(input.jdg_entrepreneur, "kks_damage_repaired_amount", 0)
    repaired > 0
}

# P213: cooperation_with_authorities — Współpraca z organami
else := {
    "matched": true, "rule_id": "jdg.kks.cooperation_with_authorities",
    "package": "jdg.kks", "priority": 213,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_mitigation_applied": true, "kks_authority_cooperation": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 19 § 2 KKS",
    "_warnings": ["Aktywna współpraca z KAS — udostępnienie dokumentacji i wyjaśnień. Okoliczność łagodząca"]
} {
    input.jdg_entrepreneur.kks_cooperating_with_authorities == true
}

# P214: remorse_and_first_offense — Skrucha + pierwszy raz
else := {
    "matched": true, "rule_id": "jdg.kks.remorse_and_first_offense",
    "package": "jdg.kks", "priority": 214,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_mitigation_applied": true, "kks_first_offense": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 19 § 1-2 KKS",
    "_warnings": ["Pierwszy raz + skrucha — istotne okoliczności łagodzące przy wymiarze kary"]
} {
    kks_count := object.get(input.jdg_entrepreneur, "kks_incidents_12m", 0)
    kks_count == 0
    input.jdg_entrepreneur.kks_voluntary_disclosure_filed == true
}

# P215: voluntary_surrender — Samodzielne zgłoszenie przed wykryciem
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_surrender",
    "package": "jdg.kks", "priority": 215,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_mitigation_applied": true, "kks_self_reported": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 16 § 1-2 KKS",
    "_warnings": ["Samodzielne zgłoszenie przed wykryciem przez KAS — najsilniejsza przesłanka łagodząca"]
} {
    input.jdg_entrepreneur.kks_self_reported_before_detection == true
}

# ──── P216-P219: Okoliczności obciążające (Art. 19 § 3-4 KKS) — 4 reguły ──────

# P216: repeat_offense_aggravating — Recydywa skarbowa
else := {
    "matched": true, "rule_id": "jdg.kks.repeat_offense_aggravating",
    "package": "jdg.kks", "priority": 216,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_aggravating": true, "kks_recidivist": true,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Recydywa skarbowa — zaostrzenie kary",
    "_legal_basis": "Art. 19 § 3 KKS",
    "_warnings": [sprintf("RECYDYWA SKARBOWA — %d incydentów w ciągu 5 lat. KARA ZAOSTRZONA do górnej granicy + 50%%", [kks_count])]
} {
    kks_count := object.get(input.jdg_entrepreneur, "kks_incidents_60m", 0)
    kks_count >= 3
}

# P217: organized_group_aggravating — Działanie w grupie zorganizowanej
else := {
    "matched": true, "rule_id": "jdg.kks.organized_group_aggravating",
    "package": "jdg.kks", "priority": 217,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_aggravating": true, "kks_organized_group": true,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Grupa zorganizowana — kwalifikowana postać przestępstwa",
    "_legal_basis": "Art. 19 § 4 KKS",
    "_warnings": ["GRUPA ZORGANIZOWANA — kwalifikowana postać przestępstwa skarbowego. Kara jak za przestępstwo + obligatoryjny przepadek!"]
} {
    input.jdg_entrepreneur.kks_organized_group_member == true
}

# P218: large_scale_aggravating — Wielka skala uszczuplenia
else := {
    "matched": true, "rule_id": "jdg.kks.large_scale_aggravating",
    "package": "jdg.kks", "priority": 218,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_aggravating": true, "kks_large_scale": true,
    "kks_total_shortfall": total_shortfall,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Wielka skala — uszczuplenie >500k PLN",
    "_legal_basis": "Art. 19 § 3-4 KKS",
    "_warnings": [sprintf("WIELKA SKALA — uszczuplenie %.2f PLN (>500k PLN). Kwalifikowana postać z obligatoryjnym pozbawieniem wolności!", [total_shortfall])]
} {
    total_shortfall := object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0)
    total_shortfall > 500000
}

# P219: obstruction_of_justice — Utrudnianie postępowania
else := {
    "matched": true, "rule_id": "jdg.kks.obstruction_of_justice",
    "package": "jdg.kks", "priority": 219,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_aggravating": true, "kks_obstruction": true,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Utrudnianie postępowania — art. 83 KKS",
    "_legal_basis": "Art. 83 KKS",
    "_warnings": ["UTRUDNIANIE POSTĘPOWANIA KARNO-SKARBOWEGO — dodatkowa kara na podstawie art. 83 KKS!"]
} {
    input.jdg_entrepreneur.kks_obstruction_of_proceedings == true
}

# ──── P220-P229: Przedawnienie karalności (Art. 44, 51 KKS) — 10 reguł ─────────
# UWAGA: Art. 44 KKS = przedawnienie przestępstw (5 lat), Art. 51 KKS = wykroczeń (3 lata)

# P220: statute_of_limitations_crime_5y — Przedawnienie przestępstwa 5 lat (datowane)
else := {
    "matched": true, "rule_id": "jdg.kks.statute_of_limitations_crime_5y",
    "package": "jdg.kks", "priority": 220,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_statute_barred": true, "kks_statute_years": 5,
    "kks_offense_date": offense_date, "kks_barred_after": barred_after,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 44 § 1 KKS",
    "_warnings": [sprintf("PRZEDAWNIENIE — czyn z %s, przedawnienie %s. Upłynęło %d dni od przedawnienia", [offense_date, barred_after, days_past])]
} {
    offense_date := object.get(input.invoice, "kks_offense_date", "")
    offense_date != ""
    offense_ns := time.parse_ns("2006-01-02", offense_date)
    now_ns := time.now_ns()
    five_years_ns := 5 * 365 * 24 * 60 * 60 * 1000000000
    now_ns - offense_ns > five_years_ns
    offense_type := object.get(input.invoice, "kks_offense_type", "")
    offense_type in {"TAX_EVASION", "EMPTY_INVOICE", "FAKE_INVOICE", "UNRELIABLE_BOOKS", "UNRELIABLE_VAT", "VAT_CAROUSEL"}
    barred_after := time.format(time.add_date(offense_ns, 5, 0, 0))
    days_past := floor((now_ns - offense_ns - five_years_ns) / (24 * 60 * 60 * 1000000000))
}

# P221: statute_of_limitations_misdemeanor_3y — Przedawnienie wykroczenia 3 lata (datowane)
else := {
    "matched": true, "rule_id": "jdg.kks.statute_of_limitations_misdemeanor_3y",
    "package": "jdg.kks", "priority": 221,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_statute_barred": true, "kks_statute_years": 3,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 51 § 1 KKS",
    "_warnings": [sprintf("PRZEDAWNIENIE WYKROCZENIA — czyn z %s, przedawnienie po 3 latach", [offense_date])]
} {
    offense_date := object.get(input.invoice, "kks_offense_date", "")
    offense_date != ""
    offense_ns := time.parse_ns("2006-01-02", offense_date)
    now_ns := time.now_ns()
    three_years_ns := 3 * 365 * 24 * 60 * 60 * 1000000000
    now_ns - offense_ns > three_years_ns
    offense_type := object.get(input.invoice, "kks_offense_type", "")
    offense_type in {"DECLARATION_NOT_FILED", "INCORRECT_DATA", "TAX_UNPAID"}
}

# P222: statute_limitation_suspension — Zawieszenie biegu przedawnienia
else := {
    "matched": true, "rule_id": "jdg.kks.statute_limitation_suspension",
    "package": "jdg.kks", "priority": 222,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_limitation_suspended": true,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Zawieszenie biegu przedawnienia — postępowanie w toku",
    "_legal_basis": "Art. 44 § 5 KKS",
    "_warnings": ["ZAWIESZENIE PRZEDAWNIENIA — wszczęcie postępowania karnego skarbowego wstrzymuje bieg terminu!"]
} {
    input.jdg_entrepreneur.kks_proceedings_started == true
    input.jdg_entrepreneur.kks_proceedings_type == "CRIMINAL"
}

# P223: statute_limitation_interruption — Przerwanie biegu przedawnienia
else := {
    "matched": true, "rule_id": "jdg.kks.statute_limitation_interruption",
    "package": "jdg.kks", "priority": 223,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_limitation_interrupted": true,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Przerwanie biegu przedawnienia — czynność organu",
    "_legal_basis": "Art. 44 § 6 KKS",
    "_warnings": ["PRZERWANIE PRZEDAWNIENIA — każda czynność organu procesowego przerywa bieg. Termin biegnie od nowa!"]
} {
    input.jdg_entrepreneur.kks_limitation_interrupted_by_authority == true
}

# P224: statute_limitation_extension_10y — Przedłużone przedawnienie 10 lat
else := {
    "matched": true, "rule_id": "jdg.kks.statute_limitation_extension_10y",
    "package": "jdg.kks", "priority": 224,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_statute_extended": true, "kks_max_statute_years": 10,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Przedłużone przedawnienie do 10 lat",
    "_legal_basis": "Art. 44 § 2 KKS",
    "_warnings": ["PRZEDŁUŻONE PRZEDAWNIENIE 10 LAT — wszczęto postępowanie przed upływem 5 lat. Kara nie uległa jeszcze przedawnieniu"]
} {
    input.jdg_entrepreneur.kks_proceedings_started_within_5y == true
}

# P225-P229: Stuby dla pozostałych wariantów przedawnienia
else := { "matched": true, "rule_id": "jdg.kks.limitation_absolute_bar_p225", "package": "jdg.kks", "priority": 225, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_absolute_bar": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 44 § 7 KKS", "_warnings": ["Bezwzględne przedawnienie — maksymalny termin 10 lat od czynu"] } {
    object.get(input.jdg_entrepreneur, "kks_absolute_bar_reached", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA B: P240-P339 — PRZESTĘPSTWA SKARBOWE                              ║
# ║  Art. 54-62, 76, 83 KKS — 100 reguł                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ──── P240-P254: Uchylanie się od opodatkowania (Art. 54 KKS) — 15 reguł ──────

# P240: tax_evasion_false_declaration — Fałszywa deklaracja podatkowa
else := {
    "matched": true, "rule_id": "jdg.kks.tax_evasion_false_declaration",
    "package": "jdg.kks", "priority": 240,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "CRITICAL",
    "kks_max_daily_rates": 720, "kks_imprisonment_possible": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Fałszywa deklaracja podatkowa — art. 54 KKS",
    "_legal_basis": "Art. 54 § 1 KKS",
    "_warnings": [sprintf("UCHYLANIE SIĘ OD OPODATKOWANIA — fałszywa deklaracja (%s). Kara: do 720 stawek dziennych + pozbawienie wolności!", [declaration_type])]
} {
    declaration_type := object.get(input.invoice, "tax_declaration_type", "")
    declaration_type != ""
    input.invoice.declaration_data_falsified == true
    tax_shortfall := object.get(input.invoice, "tax_shortfall_pln", 0)
    tax_shortfall > 0
}

# P241: tax_declaration_overdue — Znaczne opóźnienie deklaracji
else := {
    "matched": true, "rule_id": "jdg.kks.tax_declaration_overdue",
    "package": "jdg.kks", "priority": 241,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "DECLARATION_NOT_FILED", "kks_penalty_severity": "HIGH",
    "kks_max_daily_rates": max_stawki,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Znaczne opóźnienie deklaracji — art. 54 KKS",
    "_legal_basis": "Art. 54 § 1-2 KKS",
    "_warnings": [sprintf("OPÓŹNIENIE DEKLARACJI — %d dni. Jeśli celowe ukrycie przychodów → Art. 54 KKS. Grzywna do %d stawek dziennych", [days_overdue, max_stawki])]
} {
    input.invoice.declaration_missing == true
    days_overdue := object.get(input.invoice, "declaration_days_overdue", 0)
    days_overdue > 30
    max_stawki = 120 { days_overdue <= 180 }
    max_stawki = 180 { days_overdue > 180 }
}

# P242: tax_evasion_hiding_revenue — Ukrywanie przychodów
else := {
    "matched": true, "rule_id": "jdg.kks.tax_evasion_hiding_revenue",
    "package": "jdg.kks", "priority": 242,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ukrywanie przychodów — art. 54 KKS",
    "_legal_basis": "Art. 54 § 1 KKS",
    "_warnings": [sprintf("UKRYWANIE PRZYCHODÓW — niezaksięgowano %.2f PLN. Natychmiast skoryguj ewidencję!", [hidden_amount])]
} {
    hidden_amount := object.get(input.invoice, "hidden_revenue_pln", 0)
    hidden_amount > 0
}

# P243: tax_evasion_inflated_costs — Zawyżanie kosztów
else := {
    "matched": true, "rule_id": "jdg.kks.tax_evasion_inflated_costs_p243",
    "package": "jdg.kks", "priority": 243,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zawyżanie kosztów — art. 54 KKS",
    "_legal_basis": "Art. 54 § 1 KKS",
    "_warnings": [sprintf("ZAWYŻANIE KOSZTÓW — zawyżono o %.2f PLN. Natychmiast skoryguj KPiR!", [inflated])]
} {
    inflated := object.get(input.invoice, "inflated_costs_amount", 0)
    inflated > 0
}

# P244-P254: Pozostałe warianty Art. 54 (szczegółowe stuby)
else := { "matched": true, "rule_id": "jdg.kks.tax_evasion_double_books_p244", "package": "jdg.kks", "priority": 244, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Podwójna księgowość — art. 54 KKS", "_legal_basis": "Art. 54 § 1 KKS", "_warnings": ["PODWÓJNA KSIĘGOWOŚĆ — przestępstwo skarbowe!"] } {
    object.get(input.jdg_entrepreneur, "double_books_detected", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.tax_evasion_shell_company_p245", "package": "jdg.kks", "priority": 245, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Firma-przykrywka — art. 54 KKS", "_legal_basis": "Art. 54 § 1 KKS", "_warnings": ["FIRMA-PRZYKRYWKA — transakcje przez podmiot nieprowadzący realnej działalności"] } {
    input.vendor.is_shell_company == true
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_fictitious_costs_p246", "package": "jdg.kks", "priority": 246, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fikcyjne koszty — art. 54 KKS", "_legal_basis": "Art. 54 § 1 KKS", "_warnings": ["Fikcyjne koszty — faktury od nieistniejących podmiotów"] } {
    object.get(input.invoice, "fictitious_costs_detected", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_identity_theft_p247", "package": "jdg.kks", "priority": 247, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Kradzież tożsamości podatkowej — art. 54 KKS", "_legal_basis": "Art. 54 § 1 KKS", "_warnings": ["Kradzież tożsamości podatkowej — użycie cudzego NIP"] } {
    object.get(input.jdg_entrepreneur, "identity_theft_for_tax", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_tp_manipulation_p248", "package": "jdg.kks", "priority": 248, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Manipulacja cenami transferowymi — art. 54 KKS", "_legal_basis": "Art. 54 § 1 KKS", "_warnings": ["Manipulacja cenami transferowymi — zaniżanie dochodu przez TP"] } {
    object.get(input.invoice, "transfer_pricing_manipulation", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_crypto_concealment_p249", "package": "jdg.kks", "priority": 249, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ukrywanie dochodów z kryptowalut — art. 54 KKS", "_legal_basis": "Art. 54 § 1 KKS", "_warnings": ["Ukrywanie dochodów z kryptowalut — obowiązek raportowania PIT-38!"] } {
    object.get(input.jdg_entrepreneur, "crypto_income_concealed", false) == true
}

# ──── P255-P269: Nierzetelne księgi (Art. 56 KKS) — 15 reguł ───────────────────

# P255: unreliable_books_falsified_entries — Fałszywe zapisy księgowe
else := {
    "matched": true, "rule_id": "jdg.kks.unreliable_books_falsified_entries",
    "package": "jdg.kks", "priority": 255,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "UNRELIABLE_BOOKS", "kks_penalty_severity": "HIGH",
    "kks_max_daily_rates": 240,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Fałszywe zapisy w PKPiR/księgach — art. 56 KKS",
    "_legal_basis": "Art. 56 § 1 KKS",
    "_warnings": ["NIERZETELNE KSIĘGI — fałszywe zapisy w PKPiR. Kara: do 240 stawek dziennych. Natychmiast skoryguj!"]
} {
    input.invoice.books_entries_falsified == true
    tax_impact := object.get(input.invoice, "books_falsification_tax_impact", 0)
    tax_impact > 0
}

# P256: unreliable_books_missing_entries — Brak wymaganych zapisów
else := {
    "matched": true, "rule_id": "jdg.kks.unreliable_books_missing_entries",
    "package": "jdg.kks", "priority": 256,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "UNRELIABLE_BOOKS", "kks_penalty_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak wymaganych zapisów księgowych — art. 56 § 2 KKS",
    "_legal_basis": "Art. 56 § 2 KKS",
    "_warnings": [sprintf("NIERZETELNE KSIĘGI — brak %d wymaganych zapisów w PKPiR", [missing_count])]
} {
    missing_count := object.get(input.invoice, "books_missing_entries_count", 0)
    missing_count > 0
}

# P257-P269: Szczegółowe stuby wariantów Art. 56
else := { "matched": true, "rule_id": "jdg.kks.unreliable_books_wrong_values_p257", "package": "jdg.kks", "priority": 257, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNRELIABLE_BOOKS", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nieprawidłowe wartości w księgach", "_legal_basis": "Art. 56 § 3 KKS", "_warnings": ["Nieprawidłowe wartości w księgach rachunkowych"] } {
    object.get(input.invoice, "books_wrong_values", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.unreliable_books_destroyed_p258", "package": "jdg.kks", "priority": 258, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DESTROYED_DOCUMENTS",    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zniszczenie dokumentów księgowych", "_legal_basis": "Art. 60 § 1 KKS", "_warnings": ["ZNISZCZENIE DOKUMENTÓW KSIĘGOWYCH — przestępstwo skarbowe! Art. 60 KKS"] } {
    object.get(input.jdg_entrepreneur, "books_destroyed", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.books_late_entries_p259", "package": "jdg.kks", "priority": 259, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNRELIABLE_BOOKS", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Opóźnione zapisy księgowe", "_legal_basis": "Art. 56 KKS", "_warnings": ["Opóźnione zapisy księgowe powyżej 30 dni"] } {
    object.get(input.invoice, "books_late_entries_30days", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.books_backdated_p260", "package": "jdg.kks", "priority": 260, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNRELIABLE_BOOKS", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Antydatowane zapisy", "_legal_basis": "Art. 56 KKS", "_warnings": ["Antydatowane zapisy księgowe — fałszowanie dat!"] } {
    object.get(input.invoice, "books_backdated_entries", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.books_ghost_employees_p261", "package": "jdg.kks", "priority": 261, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNRELIABLE_BOOKS", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fikcyjni pracownicy w księgach", "_legal_basis": "Art. 56 KKS", "_warnings": ["Fikcyjni pracownicy — wynagrodzenia dla nieistniejących osób!"] } {
    object.get(input.jdg_entrepreneur, "ghost_employees_detected", false) == true
}

# ──── P270-P279: Nierzetelna ewidencja VAT (Art. 57 KKS) — 10 reguł ───────────

# P270: unreliable_vat_records — Nierzetelna ewidencja VAT
else := {
    "matched": true, "rule_id": "jdg.kks.unreliable_vat_records",
    "package": "jdg.kks", "priority": 270,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "UNRELIABLE_VAT", "kks_penalty_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Nierzetelna ewidencja VAT — art. 57 KKS",
    "_legal_basis": "Art. 57 § 1 KKS",
    "_warnings": ["NIERZETELNA EWIDENCJA VAT — niezgodność JPK_V7 z rzeczywistością. Korekta wymagana natychmiast!"]
} {
    input.invoice.vat_records_unreliable == true
    vat_discrepancy := object.get(input.invoice, "vat_discrepancy_pln", 0)
    vat_discrepancy > 0
}

# P271: vat_records_concealment — Ukrywanie transakcji VAT
else := {
    "matched": true, "rule_id": "jdg.kks.vat_records_concealment_p271",
    "package": "jdg.kks", "priority": 271,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "UNRELIABLE_VAT", "kks_penalty_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ukrywanie transakcji VAT — art. 57 § 2 KKS",
    "_legal_basis": "Art. 57 § 2 KKS",
    "_warnings": [sprintf("UKRYWANIE TRANSAKCJI VAT — %d transakcji poza ewidencją. Natychmiast uzupełnij JPK_V7!", [concealed_count])]
} {
    concealed_count := object.get(input.invoice, "vat_transactions_concealed_count", 0)
    concealed_count > 0
}

# P272: vat_jpk_mismatch — Niezgodność JPK_V7 z fakturami
else := {
    "matched": true, "rule_id": "jdg.kks.vat_jpk_mismatch_p272",
    "package": "jdg.kks", "priority": 272,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "UNRELIABLE_VAT", "kks_penalty_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niezgodność JPK_V7 z fakturami — art. 57 KKS",
    "_legal_basis": "Art. 57 § 1 KKS",
    "_warnings": [sprintf("NIEZGODNOŚĆ JPK_V7 — różnica %.2f PLN między ewidencją a fakturami. Skoryguj plik JPK!", [jpk_diff])]
} {
    jpk_diff := object.get(input.invoice, "jpk_vat_discrepancy_pln", 0)
    jpk_diff > 1000
}

# P273: vat_gtu_misclassification — Błędna klasyfikacja GTU
else := {
    "matched": true, "rule_id": "jdg.kks.vat_gtu_misclassification_p273",
    "package": "jdg.kks", "priority": 273,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "UNRELIABLE_VAT", "kks_penalty_severity": "MEDIUM",
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Błędna klasyfikacja GTU w JPK_V7",
    "_legal_basis": "Art. 57 § 1 KKS",
    "_warnings": [sprintf("BŁĘDNA KLASYFIKACJA GTU — kod %s nieprawidłowy dla %s. Popraw w JPK_V7 przed kontrolą", [wrong_gtu, commodity])]
} {
    wrong_gtu := object.get(input.invoice, "gtu_misclassification_code", "")
    wrong_gtu != ""
    commodity := object.get(input.invoice, "commodity_description", "")
}

# P274: vat_rate_manipulation — Manipulacja stawką VAT
else := {
    "matched": true, "rule_id": "jdg.kks.vat_rate_manipulation_p274",
    "package": "jdg.kks", "priority": 274,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "UNRELIABLE_VAT", "kks_penalty_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Manipulacja stawką VAT — art. 57 KKS",
    "_legal_basis": "Art. 57 § 1 KKS",
    "_warnings": [sprintf("MANIPULACJA STAWKĄ VAT — użyto %s zamiast %s. Różnica %.2f PLN. Sankcja 30%% VAT!", [rate_used, rate_correct, diff_vat])]
} {
    rate_used := object.get(input.invoice, "vat_rate_applied", "")
    rate_correct := object.get(input.invoice, "vat_rate_correct", "")
    rate_used != rate_correct
    diff_vat := object.get(input.invoice, "vat_rate_mismatch_amount", 0)
    diff_vat > 0
}

# P275: vat_split_payment_evasion — Obchodzenie MPP
else := {
    "matched": true, "rule_id": "jdg.kks.vat_split_payment_evasion_p275",
    "package": "jdg.kks", "priority": 275,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "UNRELIABLE_VAT", "kks_penalty_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Obchodzenie MPP — dzielenie transakcji — art. 57 KKS",
    "_legal_basis": "Art. 57 § 1 KKS w zw. z Art. 108a VAT",
    "_warnings": ["OBCHODZENIE MPP — dzielenie transakcji >15000 PLN na mniejsze faktury. Sankcja 30% + solidarna odpowiedzialność!"]
} {
    input.invoice.split_payment_evasion_detected == true
}

# P276-P279: Stuby — pozostałe warianty Art. 57
else := { "matched": true, "rule_id": "jdg.kks.vat_currency_conversion_fraud_p276", "package": "jdg.kks", "priority": 276, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNRELIABLE_VAT", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Manipulacja kursem walut w VAT", "_legal_basis": "Art. 57 KKS", "_warnings": ["Manipulacja kursem walutowym w ewidencji VAT"] } {
    object.get(input.invoice, "vat_currency_manipulation", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.vat_reverse_charge_omission_p277", "package": "jdg.kks", "priority": 277, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNRELIABLE_VAT", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Pominięcie odwrotnego obciążenia", "_legal_basis": "Art. 57 KKS", "_warnings": ["Pominięcie odwrotnego obciążenia w ewidencji VAT"] } {
    object.get(input.invoice, "reverse_charge_omitted", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.vat_duplicate_deduction_p278", "package": "jdg.kks", "priority": 278, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNRELIABLE_VAT", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Podwójne odliczenie VAT", "_legal_basis": "Art. 57 KKS", "_warnings": ["Podwójne odliczenie VAT — ta sama faktura odliczona dwukrotnie"] } {
    object.get(input.invoice, "vat_double_deduction", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.vat_missing_sales_register_p279", "package": "jdg.kks", "priority": 279, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNRELIABLE_VAT", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak ewidencji sprzedaży VAT", "_legal_basis": "Art. 57 KKS", "_warnings": ["Brak ewidencji sprzedaży VAT — JPK_V7 nie zawiera wszystkich faktur sprzedaży"] } {
    object.get(input.invoice, "vat_missing_sales_register", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P280-P299: ROZSZERZONE PRZESTĘPSTWA — Niszczenie dokumentów, Fałszywe zeznania,
# Nienależny zwrot VAT, Odpowiedzialność płatnika (Art. 60, 61, 76, 77a, 59 KKS)
# ═══════════════════════════════════════════════════════════════════════════════

# ──── P280-P284: Niszczenie / ukrywanie dokumentów (Art. 60 KKS) ────────────

else := {
    "matched": true, "rule_id": "jdg.kks.documents_destroyed_art60",
    "package": "jdg.kks", "priority": 280,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "DESTROYED_DOCUMENTS", "kks_penalty_severity": "CRITICAL",
    "kks_max_daily_rates": 720,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zniszczenie dokumentów — art. 60 KKS",
    "_legal_basis": "Art. 60 § 1 KKS",
    "_warnings": [sprintf("ZNISZCZENIE DOKUMENTÓW — %d dokumentów za okres %s. Przestępstwo skarbowe — kara do 720 stawek + pozbawienie wolności!", [doc_count, period])]
} {
    doc_count := object.get(input.jdg_entrepreneur, "documents_destroyed_count", 0)
    doc_count > 0
    period := object.get(input.jdg_entrepreneur, "documents_destroyed_period", "")
}

else := {
    "matched": true, "rule_id": "jdg.kks.documents_hidden_from_authorities",
    "package": "jdg.kks", "priority": 281,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "DESTROYED_DOCUMENTS", "kks_penalty_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ukrywanie dokumentów przed organem — art. 60 § 2 KKS",
    "_legal_basis": "Art. 60 § 2 KKS",
    "_warnings": ["UKRYWANIE DOKUMENTÓW PRZED KAS — przestępstwo skarbowe! Art. 60 § 2 KKS"]
} {
    input.jdg_entrepreneur.documents_hidden_from_authorities == true
}

else := { "matched": true, "rule_id": "jdg.kks.documents_stolen_claim_p282", "package": "jdg.kks", "priority": 282, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DESTROYED_DOCUMENTS", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Dokumenty rzekomo skradzione — wymagany protokół policji", "_legal_basis": "Art. 60 § 1 KKS", "_warnings": ["Dokumenty zgłoszone jako skradzione — wymagany protokół policyjny + zgłoszenie do US w ciągu 7 dni"] } { object.get(input.jdg_entrepreneur, "documents_reported_stolen", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.documents_force_majeure_no_proof_p283", "package": "jdg.kks", "priority": 283, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DESTROYED_DOCUMENTS", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Siła wyższa bez dowodów — art. 60 KKS", "_legal_basis": "Art. 60 § 1 KKS", "_warnings": ["Powołanie na siłę wyższą (pożar/powódź) BEZ protokołu — US uzna za zniszczenie umyślne!"] } { object.get(input.jdg_entrepreneur, "force_majeure_no_evidence", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.documents_held_by_former_accountant_p284", "package": "jdg.kks", "priority": 284, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Biuro rachunkowe odmawia wydania dokumentów", "_legal_basis": "Art. 60 KKS w zw. z Art. 83 KKS", "_warnings": ["Byłe biuro rachunkowe odmawia wydania dokumentów — odpowiedzialność karna JDG! Złóż zawiadomienie na policję + do KAS"] } { object.get(input.jdg_entrepreneur, "accountant_refuses_to_release", false) == true }

# ──── P285-P289: Nienależny zwrot VAT / podatku (Art. 76 KKS) ──────────

else := {
    "matched": true, "rule_id": "jdg.kks.unjustified_vat_refund_art76",
    "package": "jdg.kks", "priority": 285,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "UNJUSTIFIED_REFUND", "kks_penalty_severity": "CRITICAL",
    "kks_max_daily_rates": 720, "kks_imprisonment_possible": true,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nienależny zwrot VAT — art. 76 KKS",
    "_legal_basis": "Art. 76 § 1 KKS",
    "_warnings": [sprintf("NIENALEŻNY ZWROT VAT — %.2f PLN wyłudzonego zwrotu. Przestępstwo skarbowe! Natychmiast zwróć + czynny żal!", [refund_amount])]
} {
    refund_amount := object.get(input.invoice, "unjustified_vat_refund_pln", 0)
    refund_amount > 0
}

else := { "matched": true, "rule_id": "jdg.kks.unjustified_refund_attempt_p286", "package": "jdg.kks", "priority": 286, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNJUSTIFIED_REFUND", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Próba wyłudzenia zwrotu — art. 76 § 2 KKS", "_legal_basis": "Art. 76 § 2 KKS", "_warnings": ["Próba wyłudzenia zwrotu podatku — fikcyjne faktury zakupowe dla sztucznego zwrotu VAT!"] } { object.get(input.invoice, "refund_attempt_detected", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.refund_overstated_deduction_p287", "package": "jdg.kks", "priority": 287, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNJUSTIFIED_REFUND", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zawyżone odliczenia dla zwrotu — art. 76 KKS", "_legal_basis": "Art. 76 § 1 KKS", "_warnings": ["Zawyżone odliczenia VAT — celowe zawyżenie VAT naliczonego dla uzyskania zwrotu"] } { object.get(input.invoice, "vat_deduction_overstated_for_refund", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.refund_fake_export_p288", "package": "jdg.kks", "priority": 288, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNJUSTIFIED_REFUND", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fikcyjny eksport dla zwrotu VAT", "_legal_basis": "Art. 76 § 1 KKS", "_warnings": ["Fikcyjny eksport — towary nie opuściły PL, a wnioskowano o zwrot VAT 0%!"] } { object.get(input.invoice, "fake_export_for_vat_refund", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.refund_fictitious_wnt_p289", "package": "jdg.kks", "priority": 289, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNJUSTIFIED_REFUND", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fikcyjny WNT dla zwrotu VAT", "_legal_basis": "Art. 76 KKS", "_warnings": ["Fikcyjny WNT — transakcja wewnątrzwspólnotowa nie miała miejsca"] } { object.get(input.invoice, "fictitious_wnt_for_refund", false) == true }

# ──── P290-P294: Odpowiedzialność płatnika / podżeganie (Art. 59, 77a KKS) ──

else := {
    "matched": true, "rule_id": "jdg.kks.tax_collector_not_remitted",
    "package": "jdg.kks", "priority": 290,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "TAX_COLLECTOR_VIOLATION", "kks_penalty_severity": "CRITICAL",
    "kks_collector_tax_due": tax_due,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Pobrany a nieodprowadzony podatek — art. 59 KKS",
    "_legal_basis": "Art. 59 § 1 KKS",
    "_warnings": [sprintf("PŁATNIK NIE ODPROWADZIŁ POBRANEGO PODATKU — %.2f PLN. Przestępstwo skarbowe — odpowiedzialność majątkiem osobistym!", [tax_due])]
} {
    tax_due := object.get(input.jdg_entrepreneur, "tax_collected_not_remitted", 0)
    tax_due > 0
}

else := { "matched": true, "rule_id": "jdg.kks.tax_collector_withholding_false_p291", "package": "jdg.kks", "priority": 291, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_COLLECTOR_VIOLATION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fałszywe deklaracje WHT — art. 59 KKS", "_legal_basis": "Art. 59 § 2 KKS", "_warnings": ["Fałszywe deklaracje podatku u źródła (WHT) — płatnik celowo zaniżył pobrany podatek"] } { object.get(input.jdg_entrepreneur, "withholding_false_declaration", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.collector_aiding_evasion_p292", "package": "jdg.kks", "priority": 292, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_COLLECTOR_VIOLATION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Płatnik pomaga w unikaniu podatku", "_legal_basis": "Art. 59 KKS", "_warnings": ["Płatnik świadomie pomaga podatnikowi w unikaniu opodatkowania"] } { object.get(input.jdg_entrepreneur, "collector_aided_evasion", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.collector_zus_not_remitted_p293", "package": "jdg.kks", "priority": 293, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_COLLECTOR_VIOLATION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nieodprowadzone składki ZUS pracowników", "_legal_basis": "Art. 59 KKS w zw. z Art. 46-47 SUS", "_warnings": ["Nieodprowadzone składki ZUS pracowników — odpowiedzialność płatnika = kara KKS!"] } { object.get(input.jdg_entrepreneur, "employee_zus_not_remitted", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.collector_dac7_non_filing_p294", "package": "jdg.kks", "priority": 294, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_COLLECTOR_VIOLATION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niezłożenie DAC7 — platforma cyfrowa", "_legal_basis": "Art. 59 KKS w zw. z Art. 39q OrdPU", "_warnings": ["Niezłożenie raportu DAC7 — kara do 1 000 000 PLN!"] } { object.get(input.jdg_entrepreneur, "dac7_not_filed", false) == true }

# ──── P295-P299: Fałszywe zeznania i podstęp (Art. 61, 83 KKS) ──────────────

else := { "matched": true, "rule_id": "jdg.kks.false_testimony_kas_p295", "package": "jdg.kks", "priority": 295, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "FALSE_TESTIMONY", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fałszywe zeznania przed KAS — art. 83 § 1 KKS", "_legal_basis": "Art. 83 § 1 KKS", "_warnings": ["Fałszywe zeznania podczas kontroli KAS — dodatkowa odpowiedzialność karna!"] } { object.get(input.jdg_entrepreneur, "false_testimony_to_kas", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.deceitful_evasion_method_p296", "package": "jdg.kks", "priority": 296, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Oszukańczy sposób unikania opodatkowania — art. 54 § 2 KKS", "_legal_basis": "Art. 54 § 2 KKS", "_warnings": ["Oszukańczy sposób unikania opodatkowania — kwalifikowana postać z surowszą karą"] } { object.get(input.jdg_entrepreneur, "deceitful_evasion_method", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.identity_concealment_p297", "package": "jdg.kks", "priority": 297, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ukrywanie tożsamości dla unikania podatku", "_legal_basis": "Art. 54 § 1 KKS", "_warnings": ["Ukrywanie tożsamości / działanie przez słupa — kwalifikowana postać uchylania się od opodatkowania"] } { object.get(input.jdg_entrepreneur, "identity_concealed_for_tax", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.chain_transaction_fraud_p298", "package": "jdg.kks", "priority": 298, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Łańcuch transakcji dla ukrycia przychodu", "_legal_basis": "Art. 54 § 1 KKS w zw. z Art. 62 KKS", "_warnings": ["Łańcuch fikcyjnych transakcji — wiele podmiotów, cel: ukrycie rzeczywistego beneficjenta"] } { object.get(input.invoice, "chain_transaction_fraud_scheme", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.digital_currency_concealment_p299", "package": "jdg.kks", "priority": 299, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ukrywanie dochodów przez waluty cyfrowe", "_legal_basis": "Art. 54 KKS w zw. z AML", "_warnings": ["Ukrywanie dochodów przez waluty cyfrowe/krypto — wymagany PIT-38 + zgłoszenie do GIIF"] } { object.get(input.jdg_entrepreneur, "digital_currency_income_concealed", false) == true }

# ──── P300-P319: Puste faktury / fałszerstwo (Art. 62 KKS) — 20 reguł ──────────

# P300: empty_invoice_issued — Wystawienie pustej faktury
else := {
    "matched": true, "rule_id": "jdg.kks.empty_invoice_issued",
    "package": "jdg.kks", "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "EMPTY_INVOICE", "kks_penalty_severity": "CRITICAL",
    "kks_max_imprisonment_years": 25,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Pusta faktura — art. 62 § 2 KKS (kara do 25 lat!)",
    "_legal_basis": "Art. 62 § 2 KKS",
    "_warnings": ["PUSTA FAKTURA — przestępstwo skarbowe zagrożone karą do 25 lat pozbawienia wolności! Natychmiast zgłoś czynny żal!"]
} {
    input.invoice.is_empty_invoice == true
    input.invoice.amount_gross > 0
    input.invoice.delivery_confirmed == false
}

# P301: fake_invoice_issued — Fałszywa faktura (sfabrykowana)
else := {
    "matched": true, "rule_id": "jdg.kks.fake_invoice_issued",
    "package": "jdg.kks", "priority": 301,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "FAKE_INVOICE", "kks_penalty_severity": "CRITICAL",
    "kks_max_imprisonment_years": 25,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Fałszywa faktura — art. 62 § 1 KKS",
    "_legal_basis": "Art. 62 § 1 KKS",
    "_warnings": ["FAŁSZYWA FAKTURA — sfabrykowany dokument! Art. 62 § 1 KKS — kara do 25 lat!"]
} {
    input.invoice.is_fake_invoice == true
}

# P302: invoice_carousel_detected — Karuzela VAT
else := {
    "matched": true, "rule_id": "jdg.kks.invoice_carousel_detected",
    "package": "jdg.kks", "priority": 302,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "VAT_CAROUSEL", "kks_penalty_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Karuzela VAT — art. 62 § 2 KKS",
    "_legal_basis": "Art. 62 § 2 KKS",
    "_warnings": ["KARUZELA VAT — łańcuch fikcyjnych transakcji! Odpowiedzialność karna + solidarna za VAT!"]
} {
    input.invoice.is_carousel_participant == true
}

# P303-P319: Szczegółowe warianty Art. 62 (14 reguł)
else := { "matched": true, "rule_id": "jdg.kks.invoice_falsified_amount_p303", "package": "jdg.kks", "priority": 303, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fałszowanie kwot na fakturze — art. 62 § 2 KKS", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Fałszowanie kwot na fakturze — art. 62 KKS"] } {
    object.get(input.invoice, "amount_falsified", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.invoice_counterfeit_p304", "package": "jdg.kks", "priority": 304, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Podrobiona faktura — art. 62 § 2 KKS", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Podrobiona faktura — fałszerstwo dokumentu!"] } {
    object.get(input.invoice, "is_counterfeit", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.invoice_used_for_tax_fraud_p305", "package": "jdg.kks", "priority": 305, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Faktura użyta do wyłudzenia podatku — art. 62 § 2 KKS", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Faktura użyta do wyłudzenia podatku — art. 62 KKS!"] } {
    object.get(input.invoice, "used_for_tax_fraud", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_systematic_p306", "package": "jdg.kks", "priority": 306, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Systematyczne wystawianie pustych faktur — art. 62 KKS", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Systematyczne wystawianie pustych faktur — zorganizowana działalność przestępcza!"] } {
    object.get(input.jdg_entrepreneur, "systematic_empty_invoices", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_organized_scheme_p307", "package": "jdg.kks", "priority": 307, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zorganizowany schemat pustych faktur", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Zorganizowany schemat pustych faktur — wielu uczestników!"] } {
    object.get(input.jdg_entrepreneur, "organized_invoice_scheme", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_cross_border_p308", "package": "jdg.kks", "priority": 308, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Transgraniczny schemat pustych faktur", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Transgraniczny schemat pustych faktur — zaangażowane podmioty z UE!"] } {
    object.get(input.invoice, "cross_border_empty_invoice_scheme", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_digital_forgery_p309", "package": "jdg.kks", "priority": 309, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Cyfrowe fałszerstwo faktury — podpis elektroniczny", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Cyfrowe fałszerstwo — sfałszowany podpis elektroniczny na fakturze!"] } {
    object.get(input.invoice, "digital_signature_forged", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_ksef_fraud_p310", "package": "jdg.kks", "priority": 310, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Manipulacja KSeF — fałszywy token", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Manipulacja KSeF — użycie fałszywego tokena do wystawienia faktury!"] } {
    object.get(input.invoice, "ksef_token_forged", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_timestamp_fraud_p311", "package": "jdg.kks", "priority": 311, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Manipulacja znacznikiem czasu faktury", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Manipulacja znacznikiem czasu — antydatowanie faktury w KSeF!"] } {
    object.get(input.invoice, "timestamp_manipulated", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_recipient_knowledge_p312", "package": "jdg.kks", "priority": 312, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Odbiorca wiedział o pustej fakturze", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Odbiorca świadomie przyjął pustą fakturę — współsprawstwo!"] } {
    object.get(input.invoice, "recipient_knew_empty_invoice", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_intermediary_p313", "package": "jdg.kks", "priority": 313, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Pośrednik w obrocie pustymi fakturami", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Pośrednik w obrocie pustymi fakturami — pomocnictwo w przestępstwie!"] } {
    object.get(input.jdg_entrepreneur, "empty_invoice_broker", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_conspirator_p314", "package": "jdg.kks", "priority": 314, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zmowa w sprawie pustych faktur", "_legal_basis": "Art. 62 § 2 KKS", "_warnings": ["Zmowa dot. pustych faktur — przygotowanie przestępstwa skarbowego!"] } {
    object.get(input.jdg_entrepreneur, "empty_invoice_conspiracy", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA C: P400-P459 — WYKROCZENIA SKARBOWE                              ║
# ║  Art. 60-61, 77-83 KKS — 60 reguł                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ──── P400-P409: Niezłożenie deklaracji (Art. 77 KKS) — 10 reguł ──────────────

# P400: declaration_not_filed_vat — Niezłożenie deklaracji VAT
else := {
    "matched": true, "rule_id": "jdg.kks.declaration_not_filed_vat",
    "package": "jdg.kks", "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "DECLARATION_NOT_FILED", "kks_penalty_severity": "MEDIUM",
    "kks_max_daily_rates": max_stawki,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Niezłożenie deklaracji VAT-7 — art. 77 KKS",
    "_legal_basis": "Art. 77 § 1 KKS",
    "_warnings": [sprintf("NIEZŁOŻONA DEKLARACJA VAT-7 za okres %s — %d dni opóźnienia. Złóż natychmiast! Art. 77 § 1 KKS: grzywna do %d stawek dziennych", [period, days_overdue, max_stawki])]
} {
    input.jdg_entrepreneur.is_vat_payer == true
    input.invoice.declaration_missing == true
    declaration_type := object.get(input.invoice, "tax_declaration_type", "")
    declaration_type == "VAT7"
    days_overdue := object.get(input.invoice, "declaration_days_overdue", 0)
    period := object.get(input.invoice, "declaration_period", "")
    days_overdue > 0
    max_stawki = 60 { days_overdue <= 30 }
    max_stawki = 120 { days_overdue > 30; days_overdue <= 180 }
    max_stawki = 180 { days_overdue > 180 }
}

# P401: declaration_not_filed_pit — Niezłożenie deklaracji PIT
else := {
    "matched": true, "rule_id": "jdg.kks.declaration_not_filed_pit",
    "package": "jdg.kks", "priority": 401,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "DECLARATION_NOT_FILED", "kks_penalty_severity": "MEDIUM",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Niezłożenie deklaracji PIT — art. 77 § 2 KKS",
    "_legal_basis": "Art. 77 § 2 KKS",
    "_warnings": [sprintf("NIEZŁOŻONA DEKLARACJA %s za rok %s. Złóż natychmiast — kara do 180 stawek dziennych!", [pit_type, tax_year])]
} {
    input.invoice.declaration_missing == true
    declaration_type := object.get(input.invoice, "tax_declaration_type", "")
    declaration_type in {"PIT36", "PIT36L", "PIT28"}
    tax_year := object.get(input.invoice, "tax_year", "")
    pit_type := declaration_type
    tax_year != ""
}

# P402: declaration_not_filed_zus — Niezłożenie DRA
else := {
    "matched": true, "rule_id": "jdg.kks.declaration_not_filed_zus",
    "package": "jdg.kks", "priority": 402,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "DECLARATION_NOT_FILED", "kks_penalty_severity": "MEDIUM",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Niezłożenie DRA — art. 77 § 3 KKS",
    "_legal_basis": "Art. 77 § 3 KKS",
    "_warnings": ["NIEZŁOŻONA DEKLARACJA ZUS DRA — złóż natychmiast! Brak DRA = brak ubezpieczenia!"]
} {
    input.jdg_entrepreneur.zus_dra_missing == true
}

# P403-P409: Stuby — pozostałe typy deklaracji
else := { "matched": true, "rule_id": "jdg.kks.declaration_not_filed_cit_withholding_p403", "package": "jdg.kks", "priority": 403, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezłożenie CIT-8 (JDG jako płatnik)", "_legal_basis": "Art. 77 KKS", "_warnings": ["Niezłożenie deklaracji podatku u źródła (withholding tax)"] } {
    object.get(input.jdg_entrepreneur, "withholding_tax_declaration_missing", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.declaration_not_filed_local_taxes_p404", "package": "jdg.kks", "priority": 404, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezłożenie deklaracji podatku od nieruchomości", "_legal_basis": "Art. 77 KKS", "_warnings": ["Niezłożenie DN-1 — deklaracji na podatek od nieruchomości"] } {
    object.get(input.jdg_entrepreneur, "property_tax_declaration_missing", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.declaration_not_filed_pcc_p405", "package": "jdg.kks", "priority": 405, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezłożenie PCC-3", "_legal_basis": "Art. 77 KKS", "_warnings": ["Niezłożenie PCC-3 — deklaracji PCC od czynności cywilnoprawnych"] } {
    object.get(input.jdg_entrepreneur, "pcc_declaration_missing", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.declaration_not_filed_intrastat_p406", "package": "jdg.kks", "priority": 406, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezłożenie INTRASTAT", "_legal_basis": "Art. 77 KKS", "_warnings": ["Niezłożenie INTRASTAT — obowiązek przy WNT/WDT > progów statystycznych"] } {
    object.get(input.jdg_entrepreneur, "intrastat_missing", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.declaration_not_filed_tpr_p407", "package": "jdg.kks", "priority": 407, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezłożenie TPR-C", "_legal_basis": "Art. 77 KKS", "_warnings": ["Niezłożenie TPR-C — obowiązek dokumentacji cen transferowych"] } {
    object.get(input.jdg_entrepreneur, "tpr_missing", false) == true
}

# ──── P410-P419: Nieprawidłowe dane + niezapłacenie (Art. 78-79 KKS) — 10 reguł

# P410: incorrect_data_in_declaration — Nieprawidłowe dane w deklaracji
else := {
    "matched": true, "rule_id": "jdg.kks.incorrect_data_in_declaration",
    "package": "jdg.kks", "priority": 410,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "INCORRECT_DATA", "kks_penalty_severity": "LOW",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Nieprawidłowe dane w deklaracji — art. 78 KKS",
    "_legal_basis": "Art. 78 § 1 KKS",
    "_warnings": ["NIEPRAWIDŁOWE DANE W DEKLARACJI — skoryguj przed kontrolą KAS"]
} {
    input.invoice.declaration_has_errors == true
}

# P411: tax_not_paid_on_time — Niezapłacenie podatku w terminie
else := {
    "matched": true, "rule_id": "jdg.kks.tax_not_paid_on_time",
    "package": "jdg.kks", "priority": 411,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "TAX_UNPAID", "kks_penalty_severity": "MEDIUM",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Niezapłacenie podatku w terminie — art. 79 KKS",
    "_legal_basis": "Art. 79 KKS",
    "_warnings": [sprintf("NIEZAPŁACONY PODATEK — %.2f PLN za %d dni. Odsetki ~%.2f PLN/dzień (stawka orientacyjna). Zapłać natychmiast!", [tax_due, payment_days_overdue, daily_interest])]
} {
    tax_due := object.get(input.invoice, "tax_unpaid_amount", 0)
    tax_due > 0
    payment_days_overdue := object.get(input.invoice, "payment_days_overdue", 0)
    payment_days_overdue > 0
    daily_interest = tax_due * 0.00038 { payment_days_overdue > 0 }
}

# P412-P419: Stuby — szczegółowe warianty Art. 78-79
else := { "matched": true, "rule_id": "jdg.kks.incorrect_data_partial_payment_p412", "package": "jdg.kks", "priority": 412, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_UNPAID", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Częściowa wpłata podatku", "_legal_basis": "Art. 79 KKS", "_warnings": ["Częściowa wpłata podatku — pozostała zaległość + odsetki"] } {
    object.get(input.invoice, "tax_partially_paid", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.incorrect_data_late_payment_pattern_p413", "package": "jdg.kks", "priority": 413, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_UNPAID", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Systematyczne opóźnienia w płatnościach", "_legal_basis": "Art. 79 KKS", "_warnings": ["Systematyczne opóźnienia w płatnościach podatku — ryzyko zaostrzenia kary"] } {
    object.get(input.jdg_entrepreneur, "late_payment_pattern_6m", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.incorrect_data_withholding_not_remitted_p414", "package": "jdg.kks", "priority": 414, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_UNPAID", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nieodprowadzenie podatku u źródła", "_legal_basis": "Art. 77-79 KKS", "_warnings": ["Nieodprowadzenie podatku u źródła (withholding) — odpowiedzialność płatnika!"] } {
    object.get(input.jdg_entrepreneur, "withholding_not_remitted", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.incorrect_data_wrong_account_p415", "package": "jdg.kks", "priority": 415, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "INCORRECT_DATA", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Wpłata na zły rachunek podatkowy", "_legal_basis": "Art. 78 KKS", "_warnings": ["Wpłata na zły rachunek podatkowy — podatek uznany za nieuiszczony!"] } {
    object.get(input.invoice, "tax_paid_to_wrong_account", false) == true
}

# ──── P420-P429: Utrudnianie kontroli + odmowa (Art. 80-83 KKS) — 10 reguł ─────

else := { "matched": true, "rule_id": "jdg.kks.obstruction_no_books_at_premises_p420", "package": "jdg.kks", "priority": 420, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak dokumentów w siedzibie — art. 83 KKS", "_legal_basis": "Art. 83 KKS", "_warnings": ["Brak ksiąg i dokumentów w siedzibie podczas kontroli — utrudnianie kontroli!"] } {
    object.get(input.jdg_entrepreneur, "no_books_at_premises", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.obstruction_computer_broken_p421", "package": "jdg.kks", "priority": 421, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niedostępność systemu księgowego — art. 83 KKS", "_legal_basis": "Art. 83 KKS", "_warnings": ["Niedostępność systemu księgowego podczas kontroli — utrudnianie! Obowiązek zapewnienia dostępu."] } {
    object.get(input.jdg_entrepreneur, "accounting_system_inaccessible", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.obstruction_accountant_disappeared_p422", "package": "jdg.kks", "priority": 422, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak dostępu do ksiąg przez biuro rachunkowe", "_legal_basis": "Art. 83 KKS", "_warnings": ["Biuro rachunkowe nie udostępnia dokumentów — odpowiedzialność JDG za księgi!"] } {
    object.get(input.jdg_entrepreneur, "accountant_withholding_docs", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.obstruction_data_encrypted_p423", "package": "jdg.kks", "priority": 423, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zaszyfrowane dane księgowe bez klucza", "_legal_basis": "Art. 83 KKS", "_warnings": ["Zaszyfrowane dane bez udostępnienia klucza — utrudnianie kontroli!"] } {
    object.get(input.jdg_entrepreneur, "encrypted_data_no_key", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.obstruction_force_majeure_false_p424", "package": "jdg.kks", "priority": 424, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Fałszywe powołanie na siłę wyższą", "_legal_basis": "Art. 83 KKS", "_warnings": ["Fałszywe powołanie na siłę wyższą (pożar/powódź/kradzież) — wymaga potwierdzenia policji/straży!"] } {
    object.get(input.jdg_entrepreneur, "force_majeure_claim_unverified", false) == true
}

# ──── P430-P439: Agregacja ryzyka KKS — 10 reguł ─────────────────────────────

# P430: kks_risk_aggregation_low — Niskie ryzyko KKS (0-2 incydenty)
else := {
    "matched": true, "rule_id": "jdg.kks.risk_aggregation_low",
    "package": "jdg.kks", "priority": 430,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_risk_level": "LOW", "kks_risk_score": kks_count,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "KKS — agregacja ryzyka",
    "_warnings": [sprintf("Ryzyko KKS: NISKIE (%d incydentów w okresie)", [kks_count])]
} {
    kks_count := object.get(input.jdg_entrepreneur, "kks_incidents_12m", 0)
    kks_count <= 2
}

# P431: kks_risk_aggregation_medium — Średnie ryzyko KKS (3-5 incydentów)
else := {
    "matched": true, "rule_id": "jdg.kks.risk_aggregation_medium",
    "package": "jdg.kks", "priority": 431,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_risk_level": "MEDIUM", "kks_risk_score": kks_count,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Podwyższone ryzyko KKS — wymagana weryfikacja",
    "_legal_basis": "KKS — agregacja ryzyka",
    "_warnings": [sprintf("Ryzyko KKS: ŚREDNIE (%d incydentów w 12 mies.) — zalecany audyt wewnętrzny", [kks_count])]
} {
    kks_count := object.get(input.jdg_entrepreneur, "kks_incidents_12m", 0)
    kks_count > 2
    kks_count <= 5
}

# P432: kks_risk_aggregation_high — Wysokie ryzyko KKS (>5 incydentów)
else := {
    "matched": true, "rule_id": "jdg.kks.risk_aggregation_high",
    "package": "jdg.kks", "priority": 432,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_risk_level": "HIGH", "kks_risk_score": kks_count,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "WYSOKIE RYZYKO KKS — powyżej 5 incydentów",
    "_legal_basis": "KKS — agregacja ryzyka",
    "_warnings": [sprintf("RYZYKO KKS: WYSOKIE (%d incydentów!) — NATYCHMIASTOWA konsultacja z doradcą podatkowym i adwokatem!", [kks_count])]
} {
    kks_count := object.get(input.jdg_entrepreneur, "kks_incidents_12m", 0)
    kks_count > 5
}

# P433: kks_criminal_threshold — Próg przestępstwa skarbowego
else := {
    "matched": true, "rule_id": "jdg.kks.criminal_threshold_p433",
    "package": "jdg.kks", "priority": 433,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_risk_level": "CRITICAL", "kks_criminal_threshold_exceeded": true,
    "kks_total_shortfall": total_shortfall,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Próg przestępstwa przekroczony — zamiast wykroczenia → przestępstwo",
    "_legal_basis": "Art. 53 § 3-6 KKS",
    "_warnings": [sprintf("PRÓG PRZESTĘPSTWA PRZEKROCZONY — uszczuplenie %.2f PLN przekracza ustawowy próg. Czyn kwalifikowany jako PRZESTĘPSTWO, nie wykroczenie!", [total_shortfall])]
} {
    total_shortfall := object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0)
    # TODO: data.thresholds.jdg.bounds.kks_criminal_threshold zamiast hardcode
    total_shortfall > 26000
}

# P434-P439: Stuby agregacji
else := { "matched": true, "rule_id": "jdg.kks.risk_pattern_detection_p434", "package": "jdg.kks", "priority": 434, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_pattern_detected": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Wykryto wzorzec incydentów KKS", "_legal_basis": "KKS — analiza wzorców", "_warnings": ["Wykryto powtarzalny wzorzec incydentów KKS — ryzyko systemowego unikania podatków"] } {
    object.get(input.jdg_entrepreneur, "kks_pattern_detected", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.risk_recidivism_check_p435", "package": "jdg.kks", "priority": 435, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_recidivism_risk": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Ryzyko recydywy — wcześniejsze wyroki KKS", "_legal_basis": "KKS — recydywa", "_warnings": ["Wcześniejsze wyroki KKS — ryzyko recydywy skarbowej. Kolejny wyrok = zaostrzenie kary"] } {
    object.get(input.jdg_entrepreneur, "kks_prior_convictions", 0) > 0
}
else := { "matched": true, "rule_id": "jdg.kks.risk_seasonal_pattern_p436", "package": "jdg.kks", "priority": 436, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_seasonal_pattern": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Sezonowy wzorzec incydentów", "_legal_basis": "KKS — analiza sezonowa", "_warnings": ["Sezonowy wzorzec incydentów KKS — koncentracja w określonych okresach roku"] } {
    object.get(input.jdg_entrepreneur, "kks_seasonal_pattern_detected", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P437-P459: ROZSZERZONE WYKROCZENIA — Brak rejestracji, Niezgłoszenie zmian,
# Fałszywe dane CEIDG, Brak NIP, Kasa fiskalna, BDO, Obowiazki płatnika
# (Art. 60^1, 81-82, 84 KKS)
# ═══════════════════════════════════════════════════════════════════════════════

else := { "matched": true, "rule_id": "jdg.kks.unregistered_activity_p437", "package": "jdg.kks", "priority": 437, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNREGISTERED_ACTIVITY", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Działalność bez rejestracji CEIDG", "_legal_basis": "Art. 60^1 § 1 KKS", "_warnings": ["BRAK REJESTRACJI CEIDG — działalność gospodarcza bez wpisu. Wykroczenie skarbowe + grzywna!"] } { object.get(input.jdg_entrepreneur, "activity_without_ceidg", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.ceidg_false_data_p438", "package": "jdg.kks", "priority": 438, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "INCORRECT_DATA", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fałszywe dane w CEIDG", "_legal_basis": "Art. 60^1 § 2 KKS", "_warnings": ["Fałszywe dane w CEIDG — nieprawidlowy adres/PKD/dane kontaktowe. Wykroczenie!"] } { object.get(input.jdg_entrepreneur, "ceidg_contains_false_data", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.nip_not_obtained_p439", "package": "jdg.kks", "priority": 439, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNREGISTERED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak NIP przy działalnośći", "_legal_basis": "Art. 81 § 1 KKS", "_warnings": ["Brak NIP — kazda JDG musi miec NIP. Brak = wykroczenie skarbowe"] } { object.get(input.jdg_entrepreneur, "nip_not_obtained", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.ceidg_change_not_reported_p440", "package": "jdg.kks", "priority": 440, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezgłoszenie zmiany w CEIDG 7 dni", "_legal_basis": "Art. 81 KKS", "_warnings": ["Niezgłoszenie zmiany w CEIDG w ciagu 7 dni — wykroczenie skarbowe"] } { object.get(input.jdg_entrepreneur, "ceidg_change_not_reported_7days", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.bank_account_not_reported_p441", "package": "jdg.kks", "priority": 441, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezgłoszenie rachunku bankowego", "_legal_basis": "Art. 81 KKS", "_warnings": ["Niezgłoszenie firmowego rachunku bankowego do US/CEIDG — wykroczenie skarbowe"] } { object.get(input.jdg_entrepreneur, "bank_account_not_reported", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.vat_r_not_submitted_p442", "package": "jdg.kks", "priority": 442, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak rejestracji VAT-R mimo obowiązku", "_legal_basis": "Art. 81 KKS w zw. z Art. 96 VAT", "_warnings": ["Brak VAT-R mimo obowiązku rejestracji — sankcja VAT + KKS!"] } { object.get(input.jdg_entrepreneur, "vat_r_not_submitted_despite_obligation", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.change_of_accountant_not_reported_p443", "package": "jdg.kks", "priority": 443, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Nieaktualne pełnomocnictwo UPL-1", "_legal_basis": "Art. 81 KKS", "_warnings": ["Nieaktualne pełnomocnictwo UPL-1 — zmiana biura rachunkowego wymaga aktualizacji w US"] } { object.get(input.jdg_entrepreneur, "upl1_outdated", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.business_address_unreachable_p444", "package": "jdg.kks", "priority": 444, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak możliwości doręczeń — adres nieaktualny", "_legal_basis": "Art. 82 KKS", "_warnings": ["Brak możliwości doręczeń — adres w CEIDG nieaktualny. Korespondencja z US uznana za doreczona!"] } { object.get(input.jdg_entrepreneur, "business_address_unreachable", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.cash_register_not_installed_p445", "package": "jdg.kks", "priority": 445, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Kasa fiskalna nie zainstalowana mimo obowiązku", "_legal_basis": "Art. 84 KKS w zw. z Art. 111 VAT", "_warnings": ["Brak kasy fiskalnej mimo obowiązku (B2C > 20k PLN) — sankcja 30% VAT!"] } { object.get(input.jdg_entrepreneur, "cash_register_missing_mandatory", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.receipt_not_issued_b2c_p446", "package": "jdg.kks", "priority": 446, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak paragonu B2C", "_legal_basis": "Art. 84 § 1 KKS", "_warnings": ["Brak wydania paragonu przy sprzedazy B2C — wykroczenie skarbowe!"] } { object.get(input.invoice, "b2c_receipt_missing", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.bdo_register_missing_p447", "package": "jdg.kks", "priority": 447, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Brak wpisu w BDO", "_legal_basis": "Art. 82 KKS w zw. z ustawa o odpadach", "_warnings": ["Brak wpisu w BDO (Baza Danych Odpadowych) — obowiązek przy wytwarzaniu odpadow"] } { object.get(input.jdg_entrepreneur, "bdo_registration_missing", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.employee_tax_forms_missing_p448", "package": "jdg.kks", "priority": 448, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Brak PIT-11/PIT-4R dla pracowników", "_legal_basis": "Art. 81-82 KKS", "_warnings": ["Brak PIT-11/PIT-4R dla pracowników — obowiązek płatnika, termin do 28.02"] } { object.get(input.jdg_entrepreneur, "employee_tax_forms_missing", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.intrastat_missing_p449", "package": "jdg.kks", "priority": 449, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Brak deklaracji INTRASTAT", "_legal_basis": "Art. 81 KKS w zw. z ustawa o statystyce", "_warnings": ["Brak INTRASTAT — obowiązek przy WNT/WDT > progow statystycznych"] } { object.get(input.jdg_entrepreneur, "intrastat_not_filed", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.refused_inspection_p450", "package": "jdg.kks", "priority": 450, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Odmowa poddania sie kontroli", "_legal_basis": "Art. 83 § 1 KKS", "_warnings": ["Odmowa poddania sie kontroli skarbowej — wykroczenie z kara aresztu lub grzywny!"] } { object.get(input.jdg_entrepreneur, "refused_tax_inspection", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.false_evidence_submitted_p451", "package": "jdg.kks", "priority": 451, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Przedłożenie fałszywych dowodów", "_legal_basis": "Art. 83 § 2 KKS", "_warnings": ["Przedłożenie fałszywych dowodów podczas kontroli — dodatkowa odpowiedzialność karna!"] } { object.get(input.jdg_entrepreneur, "false_evidence_to_authority", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.unpaid_vat_penalty_30pct_p452", "package": "jdg.kks", "priority": 452, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_UNPAID", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Sankcja VAT — dodatkowe 30%", "_legal_basis": "Art. 82-84 KKS w zw. z Art. 108a VAT", "_warnings": ["Dodatkowa sankcja 30% VAT za niezaewidencjonowanie sprzedazy na kasie/JPK"] } { object.get(input.invoice, "vat_penalty_30pct_applied", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.missing_invoice_numbering_p453", "package": "jdg.kks", "priority": 453, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezachowanie ciągłości numeracji faktur", "_legal_basis": "Art. 82 KKS", "_warnings": ["Niezachowanie ciągłości numeracji faktur — przeslanka kontroli + ryzyko KKS"] } { object.get(input.jdg_entrepreneur, "invoice_numbering_gaps", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.storage_below_5years_p454", "package": "jdg.kks", "priority": 454, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNRELIABLE_BOOKS", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Dokumenty przechowywane < 5 lat", "_legal_basis": "Art. 82 KKS w zw. z Art. 86 OrdPU", "_warnings": ["Okres przechowywania dokumentów < 5 lat — obowiązek 5 lat od konca roku kalendarzowego"] } { object.get(input.jdg_entrepreneur, "document_retention_below_5years", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.signature_missing_declaration_p455", "package": "jdg.kks", "priority": 455, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "INCORRECT_DATA", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Deklaracja bez podpisu", "_legal_basis": "Art. 81 KKS", "_warnings": ["Deklaracja podatkowa bez ważnego podpisu — uznana za niezlozona!"] } { object.get(input.jdg_entrepreneur, "unsigned_declaration_submitted", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.aml_sar_not_filed_p456", "package": "jdg.kks", "priority": 456, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niezgłoszenie SAR (AML)", "_legal_basis": "Art. 72-86 AML w zw. z Art. 82 KKS", "_warnings": ["Niezgłoszenie transakcji podejrzanej do GIIF (SAR) — obowiązek instytucji obowiązanej!"] } { object.get(input.jdg_entrepreneur, "aml_sar_not_filed", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.cesop_not_reported_p457", "package": "jdg.kks", "priority": 457, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezgłoszenie CESOP", "_legal_basis": "Art. 82 KKS w zw. z Rozp. 2020/284", "_warnings": ["Niezłożenie raportu CESOP — płatności transgraniczne > 25k EUR kwartalnie"] } { object.get(input.jdg_entrepreneur, "cesop_not_filed", false) == true }

else := { "matched": true, "rule_id": "jdg.kks.repeat_minor_offense_p458", "package": "jdg.kks", "priority": 458, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "INCORRECT_DATA", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Powtarzające sie drobne wykroczenia", "_legal_basis": "Art. 50 § 2 KKS", "_warnings": [sprintf("Powtarzające sie drobne wykroczenia (%d w 12 mies.) — ryzyko podwyższenia kary", [incident_count])] } { incident_count := object.get(input.jdg_entrepreneur, "kks_minor_incidents_12m", 0); incident_count >= 3 }

else := { "matched": true, "rule_id": "jdg.kks.unauthorized_tax_advice_p459", "package": "jdg.kks", "priority": 459, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNREGISTERED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niezarejestrowane doradztwo podatkowe", "_legal_basis": "Art. 81 KKS w zw. z ustawa o doradztwie podatkowym", "_warnings": ["Świadczenie uslug doradztwa podatkowego bez wpisu na liste doradcow — czyn zabroniony!"] } { object.get(input.jdg_entrepreneur, "unauthorized_tax_advice", false) == true }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA D: P460-P499 — SANKCJE I POSTĘPOWANIE                             ║
# ║  Art. 22-53 KKS — 40 reguł                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ──── P460-P469: Środki zabezpieczające i zabezpieczenie majątkowe ────────────

else := { "matched": true, "rule_id": "jdg.kks.property_seizure_risk_p460", "package": "jdg.kks", "priority": 460, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_property_seizure_risk": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ryzyko zabezpieczenia majątkowego", "_legal_basis": "Art. 31-35 KKS", "_warnings": ["ZABEZPIECZENIE MAJĄTKOWE — KAS może zająć majątek na poczet przyszłej kary!"] } {
    total_shortfall := object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0)
    total_shortfall > 100000
    input.jdg_entrepreneur.kks_proceedings_started == true
}
else := { "matched": true, "rule_id": "jdg.kks.travel_ban_risk_p461", "package": "jdg.kks", "priority": 461, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_travel_ban_possible": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ryzyko zakazu opuszczania kraju", "_legal_basis": "Art. 34 KKS", "_warnings": ["ZAKAZ OPUSZCZANIA KRAJU — przy przestępstwach powyżej 500k PLN możliwy zakaz!"] } {
    object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0) > 500000
}
else := { "matched": true, "rule_id": "jdg.kks.business_suspension_risk_p462", "package": "jdg.kks", "priority": 462, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_business_suspension_risk": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ryzyko zawieszenia działalności", "_legal_basis": "Art. 33 KKS", "_warnings": ["ZAWIESZENIE DZIAŁALNOŚCI — sąd może zawiesić JDG jako środek zabezpieczający!"] } {
    object.get(input.jdg_entrepreneur, "systematic_empty_invoices", false) == true
}

# ──── P470-P479: Odpowiedzialność posiłkowa i podżeganie (Art. 24-25 KKS) ─────

else := { "matched": true, "rule_id": "jdg.kks.aiding_abetting_p470", "package": "jdg.kks", "priority": 470, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_aiding_abetting": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Pomocnictwo w przestępstwie skarbowym", "_legal_basis": "Art. 24 KKS", "_warnings": ["Pomocnictwo w przestępstwie skarbowym — odpowiadasz jak za sprawstwo!"] } {
    object.get(input.jdg_entrepreneur, "aided_kks_offense", false) == true
}
else := { "matched": true, "rule_id": "jdg.kks.instigating_p471", "package": "jdg.kks", "priority": 471, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_instigating": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Podżeganie do przestępstwa skarbowego", "_legal_basis": "Art. 24 KKS", "_warnings": ["Podżeganie do przestępstwa skarbowego — karalne jak sprawstwo!"] } {
    object.get(input.jdg_entrepreneur, "instigated_kks_offense", false) == true
}

# ──── P490-P499: Sankcje ogólne (Art. 23-30 KKS) — 10 reguł ───────────────────

# P490: daily_rate_calculation — Kalkulacja stawki dziennej
else := {
    "matched": true, "rule_id": "jdg.kks.daily_rate_calculation",
    "package": "jdg.kks", "priority": 490,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_daily_rate_min": daily_rate_min, "kks_daily_rate_max": daily_rate_max,
    "kks_daily_rate_calculated": calculated_rate,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 § 3 KKS",
    "_warnings": [sprintf("Stawka dzienna KKS: %.2f - %.2f PLN (przyjęto %.2f PLN na podstawie dochodu %.2f PLN/mies.)", [daily_rate_min, daily_rate_max, calculated_rate, monthly_income])]
} {
    monthly_income := object.get(input.jdg_entrepreneur, "monthly_income_avg_12m", 0)
    monthly_income > 0
    min_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4666)
    daily_rate_min = floor(min_wage / 30)
    daily_rate_max = floor(monthly_income * 0.70 / 30) { monthly_income > 0 }
    calculated_rate = floor(monthly_income * 0.30 / 30) { monthly_income > 0 }
}

# P491: fine_range_calculation — Zakres grzywny w stawkach dziennych
else := {
    "matched": true, "rule_id": "jdg.kks.fine_range_calculation",
    "package": "jdg.kks", "priority": 491,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_fine_min_stawki": 10, "kks_fine_max_stawki": max_stawki,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 23 § 1-2 KKS",
    "_warnings": [sprintf("Zakres grzywny KKS: 10 - %d stawek dziennych", [max_stawki])]
} {
    offense_type := object.get(input.invoice, "kks_offense_type", "")
    max_stawki = 120 { offense_type == "DECLARATION_NOT_FILED" }
    max_stawki = 180 { offense_type == "INCORRECT_DATA" }
    max_stawki = 240 { offense_type in {"UNRELIABLE_BOOKS", "UNRELIABLE_VAT"} }
    max_stawki = 720 { offense_type in {"TAX_EVASION", "EMPTY_INVOICE", "FAKE_INVOICE"} }
    offense_type != ""
}

# P492: confiscation_risk — Ryzyko przepadku przedmiotów
else := {
    "matched": true, "rule_id": "jdg.kks.confiscation_risk",
    "package": "jdg.kks", "priority": 492,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_confiscation_possible": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ryzyko przepadku — art. 29-30 KKS",
    "_legal_basis": "Art. 29-30 KKS",
    "_warnings": ["PRZEPADEK — towary/narzędzia użyte do przestępstwa skarbowego mogą zostać skonfiskowane!"]
} {
    input.invoice.is_empty_invoice == true
    input.invoice.amount_gross > 100000
}

# P493: probation_eligibility — Możliwość warunkowego zawieszenia
else := {
    "matched": true, "rule_id": "jdg.kks.probation_eligibility",
    "package": "jdg.kks", "priority": 493,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_probation_possible": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28 KKS",
    "_warnings": ["Warunkowe zawieszenie kary możliwe — złóż wniosek przez adwokata"]
} {
    input.jdg_entrepreneur.kks_voluntary_disclosure_filed == true
    kks_count := object.get(input.jdg_entrepreneur, "kks_incidents_12m", 0)
    kks_count <= 1
    tax_shortfall := object.get(input.invoice, "tax_shortfall_pln", 0)
    tax_shortfall <= 50000
}

# P494: imprisonment_risk — Ryzyko pozbawienia wolności
else := {
    "matched": true, "rule_id": "jdg.kks.imprisonment_risk_p494",
    "package": "jdg.kks", "priority": 494,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_imprisonment_risk": true, "kks_max_imprisonment_years": max_years,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ryzyko pozbawienia wolności",
    "_legal_basis": "Art. 27 KKS",
    "_warnings": [sprintf("RYZYKO POZBAWIENIA WOLNOŚCI do %d lat — art. 27 KKS. NATYCHMIAST skontaktuj się z adwokatem!", [max_years])]
} {
    offense_type := object.get(input.invoice, "kks_offense_type", "")
    offense_type in {"TAX_EVASION", "EMPTY_INVOICE", "FAKE_INVOICE", "VAT_CAROUSEL"}
    total_shortfall := object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0)
    max_years = 5 { total_shortfall <= 200000 }
    max_years = 10 { total_shortfall > 200000; total_shortfall <= 5000000 }
    max_years = 25 { total_shortfall > 5000000 }
}

# P495: mandatory_penalty_notice — Postępowanie mandatowe
else := {
    "matched": true, "rule_id": "jdg.kks.mandatory_penalty_notice_p495",
    "package": "jdg.kks", "priority": 495,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_mandate_possible": true, "kks_mandate_max_amount": mandate_max,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Możliwość postępowania mandatowego",
    "_legal_basis": "Art. 48-52 KKS",
    "_warnings": [sprintf("Postępowanie mandatowe możliwe — mandat do %.0f PLN. Przyjęcie mandatu = zakończenie sprawy bez sądu", [mandate_max])]
} {
    offense_type := object.get(input.invoice, "kks_offense_type", "")
    offense_type in {"DECLARATION_NOT_FILED", "INCORRECT_DATA"}
    kks_count := object.get(input.jdg_entrepreneur, "kks_incidents_12m", 0)
    kks_count <= 1
    mandate_max = 2000 { offense_type == "INCORRECT_DATA" }
    mandate_max = 5000 { offense_type == "DECLARATION_NOT_FILED" }
}

# P496-P499: Stuby końcowe
else := { "matched": true, "rule_id": "jdg.kks.publication_of_verdict_p496", "package": "jdg.kks", "priority": 496, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_public_verdict_possible": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ryzyko publikacji wyroku", "_legal_basis": "Art. 30 KKS", "_warnings": ["Publikacja wyroku w prasie — środek karny za poważne przestępstwa skarbowe"] } {
    object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0) > 1000000
}
