# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — KKS: Kodeks Karny Skarbowy (P200-P499)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: KKS Package — Penal Fiscal Code Full Decomposition (200+ rules)
# description: |
#   Rozbudowany silnik KKS — 200+ reguł w 4 grupach:
#   - P200-P229: Czynny żal i przedawnienie karalności (30 reguł, Art. 16-19, 44, 51 KKS)
#   - P240-P399: Przestępstwa skarbowe (160 reguł, Art. 54-76, 83 KKS)
#   - P365-P399: Zabezpieczenia majątkowe i pomost przestępstwo→wykroczenie (35 reguł, Art. 22-31, 77-83 KKS)
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
# ║  GRUPA 0: P130-P141_b — SPECYFICZNE PRZESTĘPSTWA SKARBOWE (Doc 42)       ║
# ║  Art. 16, 44, 56, 57, 62, 64, 68, 69, 77, 79 KKS — 12 reguł            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P130: kks_unreliable_pkpir_art56 — Nierzetelne PKPiR (kolumny 6-9)
decide := {
    "matched":true,"rule_id":"jdg.kks.unreliable_pkpir_art56",
    "package":"jdg.kks","priority":130,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_offense_type":"UNRELIABLE_BOOKS","kks_penalty_severity":"HIGH",
    "kks_max_daily_rates":240,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Nierzetelne PKPiR — Art. 56 KKS",
    "_legal_basis":"Art. 56 § 1-4 KKS",
    "_warnings":["NIERZETELNE PKPiR — celowe zaniżenie przychodów (kol. 9) lub zawyżenie KUP (kol. 6-7). Kara: do 240 stawek dziennych + pozbawienie wolności!"]
} {
    input.invoice.books_entries_falsified == true
}

# P131: kks_unreliable_vat_evidence_art57 — Nierzetelna ewidencja VAT
else := {
    "matched":true,"rule_id":"jdg.kks.unreliable_vat_evidence_art57",
    "package":"jdg.kks","priority":131,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_offense_type":"UNRELIABLE_VAT","kks_penalty_severity":"HIGH",
    "kks_omitted_sales_count":0,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Nierzetelna ewidencja VAT — Art. 57 KKS",
    "_legal_basis":"Art. 57 § 1 KKS",
    "_warnings":["NIERZETELNA EWIDENCJA VAT — pominięcie faktur sprzedaży lub fikcyjne faktury zakupowe. Niezgodność JPK_V7 z rzeczywistością!"]
} {
    input.invoice.vat_records_unreliable == true
}

# P132: kks_empty_invoice_art62 — Pusta faktura (wystawienie)
else := {
    "matched":true,"rule_id":"jdg.kks.empty_invoice_art62",
    "package":"jdg.kks","priority":132,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"none","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_offense_type":"EMPTY_INVOICE","kks_penalty_severity":"CRITICAL",
    "kks_max_imprisonment_years":25,"kks_is_empty_invoice":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Pusta faktura — Art. 62 § 2 KKS (kara do 25 lat!)",
    "_legal_basis":"Art. 62 § 2 KKS",
    "_warnings":["PUSTA FAKTURA — dokumentująca czynność która nie miała miejsca! Kara: 6 mies. do 8 lat (do 25 lat dla znacznej wartości). Natychmiast zgłoś czynny żal!"]
} {
    input.invoice.is_empty_invoice == true
    input.invoice.amount_gross > 0
}

# P133: kks_wrong_vat_rate_art64 — Niewłaściwa stawka VAT
else := {
    "matched":true,"rule_id":"jdg.kks.wrong_vat_rate_art64",
    "package":"jdg.kks","priority":133,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_offense_type":"WRONG_VAT_RATE","kks_penalty_severity":"MEDIUM",
    "kks_wrong_rate_detected":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Niewłaściwa stawka VAT — Art. 64 KKS",
    "_legal_basis":"Art. 64 KKS",
    "_warnings":["NIEWŁAŚCIWA STAWKA VAT — celowe stosowanie obniżonej stawki. Konieczna korekta JPK_V7 i dopłata różnicy. Próg odpowiedzialności: 5000 PLN uszczuplenia."]
} {
    object.get(input.invoice,"vat_rate_too_low",false) == true
}

# P134: kks_tax_return_non_filing_art77 — Niezłożenie deklaracji
else := {
    "matched":true,"rule_id":"jdg.kks.tax_return_non_filing_art77",
    "package":"jdg.kks","priority":134,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_offense_type":"DECLARATION_NOT_FILED","kks_penalty_severity":"HIGH",
    "kks_declaration_overdue":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Niezłożenie deklaracji — Art. 77 KKS",
    "_legal_basis":"Art. 77 § 1-3 KKS",
    "_warnings":["NIEZŁOŻENIE DEKLARACJI — VAT-7/JPK_V7M, PIT-36/PIT-36L/PIT-28. Grzywna do 180 stawek dziennych!"]
} {
    input.invoice.declaration_missing == true
}

# P135: kks_non_payment_of_tax_art79 — Niezapłacenie podatku
else := {
    "matched":true,"rule_id":"jdg.kks.non_payment_of_tax_art79",
    "package":"jdg.kks","priority":135,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_offense_type":"TAX_UNPAID","kks_penalty_severity":"HIGH",
    "kks_unpaid_tax":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Niezapłacenie podatku — Art. 79 KKS",
    "_legal_basis":"Art. 79 KKS",
    "_warnings":["NIEZAPŁACENIE PODATKU — zaległość podatkowa >500 PLN. Odsetki karne + odpowiedzialność karna-skarbowa!"]
} {
    arrears := object.get(input.invoice,"tax_arrears_pln",0)
    arrears > 500
}

# P136: kks_destruction_of_docs_art68 — Niszczenie/ukrywanie dokumentów
else := {
    "matched":true,"rule_id":"jdg.kks.destruction_of_docs_art68",
    "package":"jdg.kks","priority":136,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"none","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_offense_type":"DESTROYED_DOCUMENTS","kks_penalty_severity":"CRITICAL",
    "kks_documents_destroyed":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Zniszczenie dokumentów — Art. 68 KKS + Art. 86 Ordynacji",
    "_legal_basis":"Art. 68 KKS + Art. 86 Ordynacji podatkowej",
    "_warnings":["ZNISZCZENIE DOKUMENTÓW — luki w numeracji faktur, brak dokumentów za okres przechowywania (5 lat). Przestępstwo skarbowe!"]
} {
    doc_count := object.get(input.jdg_entrepreneur,"documents_destroyed_count",0)
    doc_count > 0
    not input.jdg_entrepreneur.documents_hidden_from_authorities
}

# P137: kks_voluntary_disclosure_art16 — Czynny żal (warunki skuteczności)
else := {
    "matched":true,"rule_id":"jdg.kks.voluntary_disclosure_art16",
    "package":"jdg.kks","priority":137,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_voluntary_disclosure":true,"kks_immunity_possible":true,
    "kks_disclosure_deadline":"BEFORE_AUDIT",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Czynny żal — zawiadomienie KAS przed kontrolą + wpłata w 7 dni",
    "_legal_basis":"Art. 16 § 1-3 KKS",
    "_warnings":["CZYNNY ŻAL — złóż zawiadomienie przed wykryciem przez organ. Wskaż wszystkie okoliczności. Wpłać należność w 7 dni. Nieskuteczny po wszczęciu kontroli!"]
} {
    input.jdg_entrepreneur.kks_voluntary_disclosure_filed == true
    not input.invoice.kks_flag
}

# P138: kks_statute_of_limitations_art44 — Przedawnienie karalności
else := {
    "matched":true,"rule_id":"jdg.kks.statute_of_limitations_art44",
    "package":"jdg.kks","priority":138,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_statute_barred":true,"kks_crime_statute_years":5,"kks_misd_statute_years":3,
    "kks_max_statute_years":10,
    "_routing":"","_routing_reason":"Przedawnienie karalności — Art. 44 KKS",
    "_legal_basis":"Art. 44 § 1-5 KKS",
    "_warnings":["PRZEDAWNIENIE KARALNOŚCI — przestępstwo skarbowe: 5 lat + max 10 lat. Wykroczenie skarbowe: 3 lata + max 5 lat. Bieg przerywa każda czynność organu!"]
} {
    object.get(input.jdg_entrepreneur,"kks_time_barred",false) == true
}

# P139: kks_fiscal_penalty_calculation — Kalkulacja kary grzywny
else := {
    "matched":true,"rule_id":"jdg.kks.fiscal_penalty_calculation",
    "package":"jdg.kks","priority":139,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_offense_type":"PENALTY_CALC","kks_penalty_severity":"VARIES",
    "kks_daily_rate_value_pln":"1/30_min_wage",
    "_routing":"","_routing_reason":"Kalkulacja kary grzywny — Art. 23, 48 KKS",
    "_legal_basis":"Art. 23 § 1-3 + Art. 48 KKS",
    "_warnings":["KALKULACJA KARY: stawka dzienna = 1/30 minimalnego wynagrodzenia do 400-krotności. Grzywna = liczba stawek × stawka dzienna. Max: 720 stawek × 400-krotność = do 33 552 000 PLN."]
} {
    object.get(input.jdg_entrepreneur,"kks_penalty_calculation_needed",false) == true
}

# P140_b: kks_obstruction_of_tax_audit_art69 — Utrudnianie kontroli
else := {
    "matched":true,"rule_id":"jdg.kks.obstruction_of_tax_audit_art69",
    "package":"jdg.kks","priority":140,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_offense_type":"OBSTRUCTION","kks_penalty_severity":"HIGH",
    "kks_obstruction_detected":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Utrudnianie kontroli — Art. 69 KKS",
    "_legal_basis":"Art. 69 § 1-3 KKS",
    "_warnings":["UTRUDNIANIE KONTROLI PODATKOWEJ — odmowa udostępnienia dokumentów, nieusprawiedliwiona nieobecność, uniemożliwienie oględzin. Kara: grzywna lub pozbawienie wolności!"]
} {
    input.jdg_entrepreneur.kks_obstruction_of_proceedings == true
}

# P141_b: kks_aggregate_risk_score — Agregacja ryzyka KKS
else := {
    "matched":true,"rule_id":"jdg.kks.aggregate_risk_score",
    "package":"jdg.kks","priority":141,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "kks_aggregate_risk":true,
    "kks_risk_level":"LOW",
    "_routing":"","_routing_reason":"Agregacja wszystkich flag KKS — skumulowany wskaźnik ryzyka",
    "_legal_basis":"Całość KKS — reguła pomocnicza (risk assessment)",
    "_warnings":["AGREGACJA RYZYKA KKS — sumaryczny wskaźnik ryzyka karnego-skarbowego JDG. Wagi: Art.62 puste faktury=1.0, Art.54 uchylanie=0.9, Art.56 nierzetelne księgi=0.7, Art.57 nierzetelny VAT=0.7, Art.77 niezłożenie=0.4"]
} {
    offense_count := object.get(input.jdg_entrepreneur,"kks_offenses_count",0)
    offense_count > 0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA A: P200-P229 — CZYNNY ŻAL I PRZEDAWNIENIE KARALNOŚCI              ║
# ║  Art. 16-19, 44, 51 KKS — 30 reguł                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ──── P200-P205: Czynny żal (Art. 16 KKS) — 6 reguł ───────────────────────────

# P200: voluntary_disclosure_eligible — Warunki czynnego żalu
else := {
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
# ║  GRUPA B: P240-P399 — PRZESTĘPSTWA SKARBOWE                              ║
# ║  Art. 54-76, 83 KKS — 160 reguł                                          ║
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
else := { "matched": true, "rule_id": "jdg.kks.evasion_tp_manipulation_p248", "package": "jdg.kks", "priority": 248, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "CRITICAL", "kks_tp_spread_pct": tp_spread, "_routing": "BLOCK_AND_ALERT", "_routing_reason": sprintf("Manipulacja cenami transferowymi — TP spread %.0f%% od rynkowej", [tp_spread]), "_legal_basis": "Art. 54 § 1 KKS + Art. 23o-23zf PIT", "_warnings": [sprintf("MANIPULACJA TP — spread %.0f%% od ceny rynkowej (próg bezpieczeństwa: 5%%). %.2f PLN vs %.2f PLN rynkowa. Dokumentacja TP + korekta dochodu o %.2f PLN!", [tp_spread, actual, arm_length, adjustment])] } {
    object.get(input.invoice, "transfer_pricing_manipulation", false) == true
    actual := object.get(input.invoice, "tp_actual_price", 0)
    arm_length := object.get(input.invoice, "tp_arm_length_price", 0)
    arm_length > 0
    tp_spread := abs(actual - arm_length) / arm_length * 100
    tp_spread > 5
    adjustment := abs(actual - arm_length)
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_invoice_fraud_multi_p249", "package": "jdg.kks", "priority": 249, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "CRITICAL", "kks_invoice_fraud_entities": entity_count, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Oszustwo fakturowe — wiele powiązanych podmiotów", "_legal_basis": "Art. 54 § 1-2 KKS + Art. 62 § 2 KKS (puste faktury)", "_warnings": [sprintf("OSZUSTWO FAKTUROWE — %d powiązanych podmiotów w schemacie faktur. Łańcuch transakcji A→B→C→A wykryty. Wszystkie faktury w schemacie = puste faktury (Art. 62 KKS)!", [entity_count])] } {
    entity_count := object.get(input.jdg_entrepreneur, "invoice_fraud_ring_size", 0)
    entity_count >= 3
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_fictitious_costs_temporal_p250", "package": "jdg.kks", "priority": 250, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "HIGH", "_routing": "BLOCK_AND_ALERT", "_routing_reason": sprintf("Fikcyjne koszty — %d faktur w 7 dni od nowego kontrahenta", [invoice_count]), "_legal_basis": "Art. 54 § 1 KKS + Art. 56 § 1 KKS", "_warnings": [sprintf("FIKCYJNE KOSZTY TEMPORALNE — %d faktur od nowego kontrahenta (pierwsze 7 dni). Łącznie %.2f PLN. Typowe dla fraudu fakturowego — weryfikuj natychmiast!", [invoice_count, total_amount])] } {
    invoice_count := object.get(input.jdg_entrepreneur, "rapid_invoice_chain_count", 0)
    invoice_count >= 5
    total_amount := object.get(input.jdg_entrepreneur, "rapid_invoice_chain_total", 0)
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_foreign_account_hiding_p251", "package": "jdg.kks", "priority": 251, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "CRITICAL", "kks_foreign_account_country": country, "_routing": "BLOCK_AND_ALERT", "_routing_reason": sprintf("Ukrywanie przychodów — rachunek zagraniczny w %s bez raportowania", [country]), "_legal_basis": "Art. 54 § 1 KKS + Art. 86a OrdPU (CRS/FATCA)", "_warnings": [sprintf("UKRYWANIE PRZYCHODÓW PRZEZ RACHUNKI ZAGRANICZNE — konto w %s (bank: %s). %.2f PLN niezaraportowanych przychodów. Obowiązek raportowania CRS/FATCA + zgłoszenie do KAS!", [country, bank_name, hidden_amount])] } {
    object.get(input.jdg_entrepreneur, "foreign_accounts_undeclared", false) == true
    country := object.get(input.jdg_entrepreneur, "foreign_account_country", "")
    bank_name := object.get(input.jdg_entrepreneur, "foreign_bank_name", "")
    hidden_amount := object.get(input.jdg_entrepreneur, "foreign_account_hidden_revenue", 0)
    hidden_amount > 0
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_unregistered_crossborder_p252", "package": "jdg.kks", "priority": 252, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "HIGH", "kks_unregistered_crossborder_sales": sales_count, "_routing": "BLOCK_AND_ALERT", "_routing_reason": sprintf("Niezarejestrowana działalność transgraniczna — %d transakcji do %s", [sales_count, country]), "_legal_basis": "Art. 54 § 1 KKS + Art. 17 ust. 1 pkt 3 VAT + Art. 96 VAT", "_warnings": [sprintf("NIEZAREJESTROWANA DZIAŁALNOŚĆ TRANSGRANICZNA — %d transakcji B2B do %s bez rejestracji VAT-UE/VAT w kraju przeznaczenia. Obowiązek rejestracji + korekta JPK_V7!", [sales_count, country])] } {
    sales_count := object.get(input.jdg_entrepreneur, "unregistered_crossborder_sales", 0)
    sales_count > 0
    country := object.get(input.jdg_entrepreneur, "crossborder_destination_country", "")
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_fake_residency_cert_p253", "package": "jdg.kks", "priority": 253, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "CRITICAL", "kks_fake_residency_country": country, "_routing": "BLOCK_AND_ALERT", "_routing_reason": sprintf("Fałszywy certyfikat rezydencji — %s", [country]), "_legal_basis": "Art. 54 § 1 KKS + Art. 83 KKS (fałszowanie dokumentów)", "_warnings": [sprintf("FAŁSZYWY CERTYFIKAT REZYDENCJI — %s (nr: %s). UPO z %s nie ma zastosowania. WHT 20%% zamiast 5%% + odpowiedzialność karna za fałszerstwo!", [country, cert_number, country])] } {
    object.get(input.jdg_entrepreneur, "fake_residency_certificate", false) == true
    country := object.get(input.jdg_entrepreneur, "residency_cert_country", "")
    cert_number := object.get(input.jdg_entrepreneur, "residency_cert_number", "")
}
else := { "matched": true, "rule_id": "jdg.kks.evasion_money_laundering_invoices_p254", "package": "jdg.kks", "priority": 254, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "kks_penalty_severity": "CRITICAL", "kks_ml_round_trip_detected": true, "kks_ml_cycle_count": cycle_count, "_routing": "BLOCK_AND_ALERT", "_routing_reason": sprintf("Pranie pieniędzy przez faktury — %d cykli round-trip", [cycle_count]), "_legal_basis": "Art. 54 § 1 KKS + Art. 299 KK (pranie pieniędzy) + Art. 62 § 2 KKS", "_warnings": [sprintf("PRANIE PIENIĘDZY PRZEZ FAKTURY — %d cykli round-trip A→B→A. %.2f PLN w cyrkulacji. Ten sam towar/usługa, ta sama kwota (±5%%). Obowiązek SAR do GIIF + zgłoszenie do prokuratury!", [cycle_count, total_amount])] } {
    cycle_count := object.get(input.jdg_entrepreneur, "ml_round_trip_cycles", 0)
    cycle_count >= 2
    total_amount := object.get(input.jdg_entrepreneur, "ml_round_trip_total", 0)
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

# ═══════════════════════════════════════════════════════════════════════════════
# P315-P319: ROZSZERZENIA PUSTYCH FAKTUR (Art. 62 KKS) — 5 reguł
# ═══════════════════════════════════════════════════════════════════════════════

# P315: empty_invoice_value_bands — Progi wartości pustych faktur
else := {
    "matched": true, "rule_id": "jdg.kks.empty_invoice_value_bands_p315",
    "package": "jdg.kks", "priority": 315,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "EMPTY_INVOICE", "kks_empty_invoice_value_band": value_band,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Skategoryzowana wartość pustej faktury",
    "_legal_basis": "Art. 62 § 2 KKS",
    "_warnings": [sprintf("PUSTA FAKTURA — %s (%s PLN). %s", [value_band, amount, penalty_info])]
} {
    amount := object.get(input.invoice, "amount_gross", 0)
    amount > 0
    value_band = "MALA_WARTOSC" { amount <= 200000 }
    value_band = "DUZA_WARTOSC" { amount > 200000; amount <= 1000000 }
    value_band = "WIELKA_WARTOSC" { amount > 1000000 }
    penalty_info = "grzywna do 720 stawek" { value_band == "MALA_WARTOSC" }
    penalty_info = "kara do 5 lat pozbawienia wolnosci" { value_band == "DUZA_WARTOSC" }
    penalty_info = "kara do 10 lat pozbawienia wolnosci" { value_band == "WIELKA_WARTOSC" }
}

# P316: empty_invoice_cross_border_detailed — Transgraniczne puste faktury
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_cross_border_p316", "package": "jdg.kks", "priority": 316, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "kks_cross_border_fraud": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Transgraniczny fraud fakturovy", "_legal_basis": "Art. 62 § 2 KKS w zw. z Dyrektywą VAT", "_warnings": ["Transgraniczny schemat pustych faktur — wielojurysdykcyjne ryzyko karne!"] } {
    object.get(input.invoice, "cross_border_empty_invoice_scheme", false) == true
    object.get(input.vendor, "country", "") != "PL"
}

# P317: empty_invoice_electronic_signature_forgery — Fałszowanie podpisu e-faktury
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_esignature_forgery_p317", "package": "jdg.kks", "priority": 317, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "kks_esignature_forgery": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fałszerstwo podpisu elektronicznego e-faktury", "_legal_basis": "Art. 62 § 1-2 KKS + Art. 270 KK + eIDAS", "_warnings": ["Fałszerstwo podpisu elektronicznego na e-fakturze — przestępstwo skarbowe + karne!"] } {
    object.get(input.invoice, "digital_signature_forged", false) == true
    object.get(input.invoice, "is_e_invoice", false) == true
}

# P318: empty_invoice_ksef_validation — Walidacja autentyczności przez KSeF
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_ksef_validation_p318", "package": "jdg.kks", "priority": 318, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "kks_ksef_validation_failed": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak walidacji KSeF — faktura niezweryfikowana", "_legal_basis": "Art. 106na VAT + Art. 62 KKS", "_warnings": ["Faktura bez walidacji KSeF — nie można potwierdzić jej autentyczności. Ryzyko pustej faktury!"] } {
    object.get(input.invoice, "ksef_validated", true) == false
    object.get(input.invoice, "ksef_mandatory", false) == true
}

# P319: empty_invoice_upo_verification — Weryfikacja UPO
else := { "matched": true, "rule_id": "jdg.kks.empty_invoice_upo_verification_p319", "package": "jdg.kks", "priority": 319, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EMPTY_INVOICE", "kks_upo_missing": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak UPO (Urzędowego Poświadczenia Odbioru) KSeF", "_legal_basis": "Art. 106na-106nq VAT + Art. 62 KKS", "_warnings": ["Brak UPO dla faktury KSeF — faktura może nie istnieć w systemie MF!"] } {
    object.get(input.invoice, "ksef_upo_received", true) == false
    object.get(input.invoice, "ksef_mandatory", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P320-P329: NIEWYSTAWIENIE FAKTURY (Art. 63 KKS) — 10 reguł
# ═══════════════════════════════════════════════════════════════════════════════

# P320: failure_to_invoice — Niewystawienie faktury mimo obowiązku
else := { "matched": true, "rule_id": "jdg.kks.failure_to_invoice_p320", "package": "jdg.kks", "priority": 320, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "kks_penalty_severity": "HIGH", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niewystawienie faktury — art. 63 KKS", "_legal_basis": "Art. 63 § 1 KKS", "_warnings": ["Niewystawienie faktury mimo obowiązku — wykroczenie skarbowe. Grzywna do 180 stawek dziennych!"] } {
    object.get(input.invoice, "invoice_missing_but_required", false) == true
}

# P321: failure_to_invoice_b2b — Niewystawienie faktury B2B na żądanie
else := { "matched": true, "rule_id": "jdg.kks.failure_to_invoice_b2b_p321", "package": "jdg.kks", "priority": 321, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niewystawienie faktury B2B mimo żądania nabywcy", "_legal_basis": "Art. 63 § 2 KKS w zw. z Art. 106b VAT", "_warnings": ["Niewystawienie faktury B2B w ciągu 15 dni od żądania nabywcy — sankcja KKS!"] } {
    object.get(input.invoice, "b2b_invoice_refused_to_issue", false) == true
}

# P322: failure_to_invoice_deadline — Przekroczenie terminu wystawienia faktury
else := { "matched": true, "rule_id": "jdg.kks.failure_to_invoice_deadline_p322", "package": "jdg.kks", "priority": 322, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Przekroczenie terminu na wystawienie faktury >15 dni", "_legal_basis": "Art. 63 KKS w zw. z Art. 106i VAT", "_warnings": ["Przekroczenie terminu wystawienia faktury > 15 dni od wykonania usługi"] } {
    days_since_delivery := object.get(input.invoice, "days_since_delivery_without_invoice", 0)
    days_since_delivery > 15
}

# P323: failure_to_invoice_value_threshold — Niewystawienie faktury powyżej progu
else := { "matched": true, "rule_id": "jdg.kks.failure_to_invoice_over_threshold_p323", "package": "jdg.kks", "priority": 323, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niewystawienie faktury dla transakcji >15k PLN", "_legal_basis": "Art. 63 KKS", "_warnings": ["Transakcja >15000 PLN bez faktury — wysokie ryzyko sankcji KKS + odsetki!"] } {
    amount := object.get(input.invoice, "amount_gross", 0)
    amount > 15000
    object.get(input.invoice, "invoice_missing_but_required", false) == true
}

# P324: failure_to_invoice_serial — Seryjne niewystawianie faktur
else := { "matched": true, "rule_id": "jdg.kks.failure_to_invoice_serial_p324", "package": "jdg.kks", "priority": 324, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "kks_serial_offender": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Systematyczne niewystawianie faktur — przestępstwo", "_legal_basis": "Art. 63 KKS (uporczywość)", "_warnings": ["Seryjne niewystawianie faktur — zamiast wykroczenia → przestępstwo skarbowe!"] } {
    missing_count := object.get(input.jdg_entrepreneur, "invoices_missing_count_12m", 0)
    missing_count >= 5
}

# P325: failure_to_invoice_cash — Faktura przy transakcjach gotówkowych
else := { "matched": true, "rule_id": "jdg.kks.failure_to_invoice_cash_p325", "package": "jdg.kks", "priority": 325, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niewystawienie faktury gotówkowej", "_legal_basis": "Art. 63 KKS w zw. z Art. 19a VAT", "_warnings": ["Transakcja gotówkowa bez faktury — podwójna sankcja: KKS + utrata KUP!"] } {
    object.get(input.invoice, "is_cash_payment", false) == true
    object.get(input.invoice, "invoice_missing_but_required", false) == true
}

# P326: invoice_incorrect_data — Faktura z danymi niezgodnymi z rzeczywistością
else := { "matched": true, "rule_id": "jdg.kks.invoice_incorrect_data_p326", "package": "jdg.kks", "priority": 326, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Faktura z nieprawdziwymi danymi", "_legal_basis": "Art. 63 § 2 KKS", "_warnings": ["Faktura zawiera dane niezgodne ze stanem rzeczywistym — sankcja KKS!"] } {
    object.get(input.invoice, "invoice_contains_false_data", false) == true
}

# P327: invoice_missing_mandatory_fields — Brak obowiązkowych pól faktury
else := { "matched": true, "rule_id": "jdg.kks.invoice_missing_fields_p327", "package": "jdg.kks", "priority": 327, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Faktura bez obowiązkowych pól — art. 63 KKS", "_legal_basis": "Art. 63 KKS w zw. z Art. 106e VAT", "_warnings": ["Faktura bez obowiązkowych elementów (NIP, data, kwota) — potencjalna sankcja KKS"] } {
    object.get(input.invoice, "mandatory_fields_missing", false) == true
}

# P328: invoice_false_nip — Posłużenie się cudzym NIP na fakturze
else := { "matched": true, "rule_id": "jdg.kks.invoice_false_nip_p328", "package": "jdg.kks", "priority": 328, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "kks_nip_misuse": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Posłużenie się cudzym NIP na fakturze", "_legal_basis": "Art. 63 KKS + Art. 81 KKS", "_warnings": ["Posłużenie się cudzym NIP na fakturze — przestępstwo skarbowe + kradzież tożsamości podatkowej!"] } {
    object.get(input.invoice, "uses_third_party_nip", false) == true
}

# P329: invoice_failure_aggregate — Agregacja naruszeń dot. faktur
else := { "matched": true, "rule_id": "jdg.kks.invoice_failure_aggregate_p329", "package": "jdg.kks", "priority": 329, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "NO_INVOICE", "kks_invoice_violations_total": total_v, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Liczne naruszenia dot. faktur", "_legal_basis": "Art. 62-63 KKS — agregacja", "_warnings": [sprintf("Agregacja: %d naruszeń związanych z fakturami w 12 mies. — eskalacja do US!", [total_v])] } {
    total_v := object.get(input.jdg_entrepreneur, "invoice_violations_12m", 0)
    total_v >= 3
}

# ═══════════════════════════════════════════════════════════════════════════════
# P330-P339: NIEPRAWIDŁOWA STAWKA I ZWROT VAT (Art. 64-67 KKS) — 10 reguł
# ═══════════════════════════════════════════════════════════════════════════════

# P330: wrong_vat_rate — Zastosowanie zaniżonej stawki VAT
else := { "matched": true, "rule_id": "jdg.kks.wrong_vat_rate_p330", "package": "jdg.kks", "priority": 330, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "WRONG_VAT_RATE", "kks_penalty_severity": "MEDIUM", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Zaniżona stawka VAT — art. 64 KKS", "_legal_basis": "Art. 64 KKS", "_warnings": ["Zastosowano zaniżoną stawkę VAT — konieczna korekta JPK_V7 i dopłata różnicy!"] } {
    object.get(input.invoice, "vat_rate_too_low", false) == true
}

# P331: wrong_vat_rate_significant — Znaczne zaniżenie stawki VAT
else := { "matched": true, "rule_id": "jdg.kks.wrong_vat_rate_significant_p331", "package": "jdg.kks", "priority": 331, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "WRONG_VAT_RATE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Znaczne zaniżenie stawki VAT — art. 64 KKS", "_legal_basis": "Art. 64 KKS (znaczna wartość)", "_warnings": ["Znaczne zaniżenie stawki VAT (różnica >200k PLN) — przestępstwo skarbowe!"] } {
    object.get(input.invoice, "vat_rate_mismatch_amount", 0) > 200000
}

# P332: vat_refund_overstatement — Zawyżenie zwrotu VAT
else := { "matched": true, "rule_id": "jdg.kks.vat_refund_overstatement_p332", "package": "jdg.kks", "priority": 332, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNJUSTIFIED_REFUND", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zawyżenie zwrotu VAT — art. 65 KKS", "_legal_basis": "Art. 65 KKS", "_warnings": ["Zawyżenie zwrotu VAT — nienależna kwota zwrotu. Natychmiast zwróć + czynny żal!"] } {
    object.get(input.invoice, "vat_refund_overstated", false) == true
}

# P333: vat_refund_fictitious_export — Fikcyjny eksport dla zwrotu
else := { "matched": true, "rule_id": "jdg.kks.vat_refund_fictitious_export_p333", "package": "jdg.kks", "priority": 333, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNJUSTIFIED_REFUND", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fikcyjny eksport dla zwrotu VAT — art. 65 KKS", "_legal_basis": "Art. 65 KKS w zw. z Art. 76 KKS", "_warnings": ["Fikcyjny eksport towarów — towary nigdy nie opuściły kraju. Przestępstwo + zwrot nienależnej kwoty!"] } {
    object.get(input.invoice, "export_documents_falsified", false) == true
}

# P334: vat_refund_accelerated_fraud — Nadużycie przyspieszonego zwrotu 25 dni
else := { "matched": true, "rule_id": "jdg.kks.vat_refund_accelerated_fraud_p334", "package": "jdg.kks", "priority": 334, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "UNJUSTIFIED_REFUND", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nadużycie przyspieszonego zwrotu VAT", "_legal_basis": "Art. 65 KKS w zw. z Art. 87 ust. 6 VAT", "_warnings": ["Nadużycie procedury przyspieszonego zwrotu VAT (25 dni) — fikcyjne faktury dla szybkiego zwrotu!"] } {
    object.get(input.invoice, "accelerated_refund_abuse", false) == true
}

# P335: untrue_tax_return — Nieprawda w deklaracji podatkowej
else := { "matched": true, "rule_id": "jdg.kks.untrue_tax_return_p335", "package": "jdg.kks", "priority": 335, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nieprawda w deklaracji — art. 66 KKS", "_legal_basis": "Art. 66 KKS", "_warnings": ["Podanie nieprawdy w deklaracji podatkowej — przestępstwo skarbowe!"] } {
    object.get(input.invoice, "tax_return_contains_lies", false) == true
}

# P336: withholding_tax_failure — Niepobranie podatku u źródła (WHT)
else := { "matched": true, "rule_id": "jdg.kks.withholding_tax_failure_p336", "package": "jdg.kks", "priority": 336, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_COLLECTOR_VIOLATION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niepobranie podatku u źródła — art. 67 KKS", "_legal_basis": "Art. 67 KKS", "_warnings": ["Niepobranie podatku u źródła od płatności zagranicznej — płatnik odpowiada majątkiem!"] } {
    object.get(input.jdg_entrepreneur, "wht_not_collected", false) == true
}

# P337: withholding_tax_non_remittance — Pobranie WHT ale niewpłacenie do US
else := { "matched": true, "rule_id": "jdg.kks.withholding_tax_non_remittance_p337", "package": "jdg.kks", "priority": 337, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "TAX_COLLECTOR_VIOLATION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Pobrany WHT ale nieodprowadzony", "_legal_basis": "Art. 67 KKS w zw. z Art. 59 KKS", "_warnings": ["Pobrano podatek u źródła ale nie wpłacono do US — przestępstwo płatnika!"] } {
    object.get(input.jdg_entrepreneur, "wht_collected_not_remitted", false) == true
}

# P338: withholding_tax_certificate_fraud — Fałszowanie certyfikatów rezydencji
else := { "matched": true, "rule_id": "jdg.kks.wht_certificate_fraud_p338", "package": "jdg.kks", "priority": 338, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "FALSE_DOCUMENTS", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fałszowanie certyfikatu rezydencji podatkowej", "_legal_basis": "Art. 67 KKS + Art. 60 KKS", "_warnings": ["Fałszowanie certyfikatu rezydencji podatkowej — podwójne przestępstwo: KKS + fałszerstwo dokumentu!"] } {
    object.get(input.invoice, "tax_residence_certificate_forged", false) == true
}

# P339: vat_calculation_errors_aggregate — Agregacja błędów kalkulacji VAT
else := { "matched": true, "rule_id": "jdg.kks.vat_calculation_errors_aggregate_p339", "package": "jdg.kks", "priority": 339, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "WRONG_VAT_RATE", "kks_vat_errors_total": total_err, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Liczne błędy w kalkulacji VAT — agregacja", "_legal_basis": "Art. 64-67 KKS — agregacja", "_warnings": [sprintf("%d błędów kalkulacji VAT w 12 mies. — audyt zalecany dla uniknięcia sankcji KKS", [total_err])] } {
    total_err := object.get(input.jdg_entrepreneur, "vat_calc_errors_12m", 0)
    total_err >= 3
}

# ═══════════════════════════════════════════════════════════════════════════════
# P340-P354: ZNISZCZENIE DOKUMENTÓW / UTRUDNIANIE KONTROLI (Art. 68-76 KKS)
# ═══════════════════════════════════════════════════════════════════════════════

# P340: destruction_documents_art68 — Zniszczenie dokumentów podatkowych
else := { "matched": true, "rule_id": "jdg.kks.destruction_documents_p340", "package": "jdg.kks", "priority": 340, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DESTROYED_DOCUMENTS", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zniszczenie dokumentów podatkowych — art. 68 KKS", "_legal_basis": "Art. 68 KKS", "_warnings": ["Zniszczenie/uszkodzenie/ukrycie dokumentów podatkowych — przestępstwo skarbowe!"] } {
    object.get(input.jdg_entrepreneur, "tax_documents_intentionally_destroyed", false) == true
}

# P341: destruction_before_retention — Zniszczenie przed upływem 5 lat
else := { "matched": true, "rule_id": "jdg.kks.destruction_before_retention_p341", "package": "jdg.kks", "priority": 341, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DESTROYED_DOCUMENTS", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zniszczenie przed upływem 5-letniego okresu retencji", "_legal_basis": "Art. 68 KKS w zw. z Art. 86 OrdPU", "_warnings": ["Zniszczenie dokumentów przed upływem 5 lat — naruszenie obowiązku przechowywania!"] } {
    object.get(input.jdg_entrepreneur, "documents_destroyed_before_retention", false) == true
}

# P342: destruction_during_audit — Zniszczenie dokumentów w trakcie kontroli
else := { "matched": true, "rule_id": "jdg.kks.destruction_during_audit_p342", "package": "jdg.kks", "priority": 342, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DESTROYED_DOCUMENTS", "kks_penalty_severity": "CRITICAL", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zniszczenie dokumentów w trakcie kontroli KAS", "_legal_basis": "Art. 68 KKS + Art. 83 KKS", "_warnings": ["ZNISZCZENIE DOKUMENTÓW W TRAKCIE KONTROLI — kwalifikowana postać! KARA BEZWZGLĘDNA!"] } {
    object.get(input.jdg_entrepreneur, "documents_destroyed_during_audit", false) == true
}

# P343: obstruction_audit_art69 — Utrudnianie kontroli podatkowej
else := { "matched": true, "rule_id": "jdg.kks.obstruction_audit_p343", "package": "jdg.kks", "priority": 343, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Utrudnianie kontroli podatkowej — art. 69 KKS", "_legal_basis": "Art. 69 KKS", "_warnings": ["Utrudnianie lub udaremnianie kontroli podatkowej — przestępstwo skarbowe!"] } {
    object.get(input.jdg_entrepreneur, "actively_obstructing_audit", false) == true
}

# P344: obstruction_denial_of_access — Odmowa dostępu do lokalu/dokumentów
else := { "matched": true, "rule_id": "jdg.kks.obstruction_denial_of_access_p344", "package": "jdg.kks", "priority": 344, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Odmowa dostępu do lokalu/dokumentów — art. 69 KKS", "_legal_basis": "Art. 69 KKS", "_warnings": ["Odmowa dostępu do lokalu lub dokumentów podczas kontroli — można użyć przymusu bezpośredniego!"] } {
    object.get(input.jdg_entrepreneur, "denied_access_to_auditors", false) == true
}

# P345: obstruction_false_information — Fałszywe informacje podczas kontroli
else := { "matched": true, "rule_id": "jdg.kks.obstruction_false_information_p345", "package": "jdg.kks", "priority": 345, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fałszywe informacje podczas kontroli", "_legal_basis": "Art. 69 KKS w zw. z Art. 83 KKS", "_warnings": ["Udzielanie fałszywych informacji podczas kontroli — dodatkowe sankcje + przedłużenie kontroli!"] } {
    object.get(input.jdg_entrepreneur, "gave_false_info_during_audit", false) == true
}

# P346: non_filing_declaration_art70 — Uporczywe nieskładanie deklaracji
else := { "matched": true, "rule_id": "jdg.kks.non_filing_declaration_p346", "package": "jdg.kks", "priority": 346, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Uporczywe nieskładanie deklaracji — art. 70 KKS", "_legal_basis": "Art. 70 KKS", "_warnings": ["Uporczywe nieskładanie deklaracji podatkowych — z wykroczenia → przestępstwo!"] } {
    missed_periods := object.get(input.jdg_entrepreneur, "declarations_missed_consecutive", 0)
    missed_periods >= 3
}

# P347: non_filing_multiple_periods — Nieskładanie deklaracji za wiele okresów
else := { "matched": true, "rule_id": "jdg.kks.non_filing_multiple_periods_p347", "package": "jdg.kks", "priority": 347, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "DECLARATION_NOT_FILED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak deklaracji za wiele okresów naraz", "_legal_basis": "Art. 70 KKS", "_warnings": [sprintf("Brak deklaracji za %d okresów — poważne naruszenie obowiązków!", [total_missing])] } {
    total_missing := object.get(input.jdg_entrepreneur, "declarations_missing_total", 0)
    total_missing >= 6
}

# P348: non_filing_despite_formal_request — Nieskładanie mimo wezwania
else := { "matched": true, "rule_id": "jdg.kks.non_filing_despite_request_p348", "package": "jdg.kks", "priority": 348, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "OBSTRUCTION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak reakcji na wezwanie US do złożenia deklaracji", "_legal_basis": "Art. 70 KKS w zw. z Art. 83 KKS", "_warnings": ["Niezłożenie deklaracji mimo formalnego wezwania US — kwalifikowana postać naruszenia!"] } {
    object.get(input.jdg_entrepreneur, "ignored_formal_request_to_file", false) == true
}

# P349: business_without_registration_art71 — Prowadzenie działalności bez rejestracji
else := { "matched": true, "rule_id": "jdg.kks.business_without_registration_p349", "package": "jdg.kks", "priority": 349, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": true, "kks_offense_type": "UNREGISTERED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Działalność bez wymaganej rejestracji — art. 71 KKS", "_legal_basis": "Art. 71 KKS", "_warnings": ["Prowadzenie działalności bez wymaganej rejestracji CEIDG/VAT — przestępstwo skarbowe!"] } {
    object.get(input.jdg_entrepreneur, "operating_without_registration", false) == true
}

# P350: business_despite_ban_art72 — Działalność mimo zakazu sądowego
else := { "matched": true, "rule_id": "jdg.kks.business_despite_ban_p350", "package": "jdg.kks", "priority": 350, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "BUSINESS_BAN_VIOLATION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Działalność mimo zakazu sądowego — art. 72 KKS", "_legal_basis": "Art. 72 KKS", "_warnings": ["Prowadzenie działalności mimo sądowego zakazu — przestępstwo + obligatoryjne zamknięcie firmy!"] } {
    object.get(input.jdg_entrepreneur, "operating_despite_court_ban", false) == true
}

# P351: illegal_gambling_tax_art73 — Nielegalny hazard a podatki
else := { "matched": true, "rule_id": "jdg.kks.illegal_gambling_tax_p351", "package": "jdg.kks", "priority": 351, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "ILLEGAL_GAMBLING", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nielegalny hazard — art. 73 KKS", "_legal_basis": "Art. 73 KKS", "_warnings": ["Dochody z nielegalnego hazardu — podwójne przestępstwo: KKS + ustawa hazardowa!"] } {
    object.get(input.jdg_entrepreneur, "illegal_gambling_income", false) == true
}

# P352: excise_duty_evasion_art74 — Uchylanie się od akcyzy
else := { "matched": true, "rule_id": "jdg.kks.excise_duty_evasion_p352", "package": "jdg.kks", "priority": 352, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "EXCISE_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Uchylanie się od akcyzy — art. 74 KKS", "_legal_basis": "Art. 74 KKS", "_warnings": ["Uchylanie się od podatku akcyzowego — przestępstwo skarbowe + konfiskata towarów!"] } {
    object.get(input.jdg_entrepreneur, "excise_duty_evaded", false) == true
}

# P353: customs_duty_evasion_art75 — Uchylanie się od cła
else := { "matched": true, "rule_id": "jdg.kks.customs_duty_evasion_p353", "package": "jdg.kks", "priority": 353, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "CUSTOMS_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Uchylanie się od cła — art. 75 KKS", "_legal_basis": "Art. 75 KKS", "_warnings": ["Uchylanie się od należności celnych — przestępstwo skarbowe + konfiskata towarów + kara!"] } {
    object.get(input.jdg_entrepreneur, "customs_duty_evaded", false) == true
}

# P354: import_vat_evasion_art76 — Uchylanie się od VAT od importu
else := { "matched": true, "rule_id": "jdg.kks.import_vat_evasion_p354", "package": "jdg.kks", "priority": 354, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_EVASION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Uchylanie się od VAT importowego — art. 76 KKS", "_legal_basis": "Art. 76 KKS", "_warnings": ["Uchylanie się od VAT z tytułu importu towarów — przestępstwo skarbowe!"] } {
    object.get(input.jdg_entrepreneur, "import_vat_evaded", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P355-P364: REGUŁY MIĘDZYPRZESTĘPCZE — WZORCE FRAUDU VAT (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# P355: vat_fraud_network_detection — Wykrywanie sieci fraudowych VAT
else := { "matched": true, "rule_id": "jdg.kks.vat_fraud_network_detection_p355", "package": "jdg.kks", "priority": 355, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "kks_fraud_network_detected": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Sieć fraudowa VAT wykryta", "_legal_basis": "Art. 62 KKS + Art. 76a KKS", "_warnings": ["Wykryto powiązania z siatką fraudową VAT — transakcja zablokowana. Zgłoszenie do KAS obligatoryjne!"] } {
    object.get(input.vendor, "fraud_flag", false) == true
    object.get(input.invoice, "network_links_detected", false) == true
}

# P356: vat_fraud_temporal_pattern — Analiza czasowa fraudu VAT
else := { "matched": true, "rule_id": "jdg.kks.vat_fraud_temporal_pattern_p356", "package": "jdg.kks", "priority": 356, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Sezonowy/cykliczny wzorzec fraudu VAT", "_legal_basis": "Art. 62 KKS — analiza wzorców", "_warnings": ["Wykryto cykliczny wzorzec transakcji sugerujący fraud VAT — wymagana analiza manualna"] } {
    object.get(input.invoice, "temporal_fraud_pattern_detected", false) == true
}

# P357: vat_fraud_geographic_clustering — Geograficzna koncentracja fraudu
else := { "matched": true, "rule_id": "jdg.kks.vat_fraud_geographic_clustering_p357", "package": "jdg.kks", "priority": 357, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Geograficzna koncentracja fraudu VAT", "_legal_basis": "Art. 62 KKS — geografia fraudu", "_warnings": ["Transakcje z regionem wysokiego ryzyka fraudu VAT — dodatkowa weryfikacja wymagana"] } {
    object.get(input.vendor, "high_risk_region", false) == true
}

# P358: vat_fraud_industry_specific — Fraud branżowy
else := { "matched": true, "rule_id": "jdg.kks.vat_fraud_industry_specific_p358", "package": "jdg.kks", "priority": 358, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Fraud VAT w branży wysokiego ryzyka", "_legal_basis": "Art. 62 KKS — branże wrażliwe", "_warnings": ["Transakcja w branży wysokiego ryzyka fraudu VAT (paliwa, elektronika, stal) — BLOCKOWANA do weryfikacji!"] } {
    object.get(input.invoice, "high_risk_industry", false) == true
}

# P359: vat_fraud_new_business_red_flag — Nowa firma z wysokim obrotem
else := { "matched": true, "rule_id": "jdg.kks.vat_fraud_new_business_red_flag_p359", "package": "jdg.kks", "priority": 359, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Nowy podmiot z podejrzanie wysokim obrotem", "_legal_basis": "Art. 62 KKS — red flag", "_warnings": ["Nowo zarejestrowany kontrahent (<6 mies.) z wysokim obrotem — potencjalny 'missing trader'!"] } {
    object.get(input.vendor, "is_new", false) == true
    object.get(input.invoice, "amount_gross", 0) > 50000
    object.get(input.vendor, "months_since_registration", 99) < 6
}

# P360: vat_fraud_rapid_deregistration — Szybkie wyrejestrowanie z VAT
else := { "matched": true, "rule_id": "jdg.kks.vat_fraud_rapid_dereg_p360", "package": "jdg.kks", "priority": 360, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Szybkie wyrejestrowanie z VAT po dużych transakcjach", "_legal_basis": "Art. 62 KKS — znikający podatnik", "_warnings": ["Kontrahent wyrejestrowany z VAT krótko po dużych transakcjach — typowe dla 'missing trader'!"] } {
    object.get(input.vendor, "vat_deregistered_after_transactions", false) == true
}

# P361: vat_fraud_nip_rotation — Rotacja NIP-ów
else := { "matched": true, "rule_id": "jdg.kks.vat_fraud_nip_rotation_p361", "package": "jdg.kks", "priority": 361, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Rotacja NIP-ów — częste zakładanie i zamykanie JDG", "_legal_basis": "Art. 62 KKS — rotacja podmiotów", "_warnings": ["Częste otwieranie i zamykanie JDG powiązanych z kontrahentem — potencjalny schemat fraudowy"] } {
    object.get(input.vendor, "nip_rotation_pattern", false) == true
}

# P362: vat_fraud_bank_account_hopping — Częste zmiany rachunków
else := { "matched": true, "rule_id": "jdg.kks.vat_fraud_bank_account_hopping_p362", "package": "jdg.kks", "priority": 362, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Częste zmiany rachunków bankowych kontrahenta", "_legal_basis": "Art. 62 KKS — AML red flag", "_warnings": ["Kontrahent często zmienia rachunki bankowe — red flag AML + fraud VAT"] } {
    object.get(input.vendor, "bank_account_hopping", false) == true
}

# P363: vat_fraud_insolvency_pattern — Strategiczne bankructwo
else := { "matched": true, "rule_id": "jdg.kks.vat_fraud_insolvency_pattern_p363", "package": "jdg.kks", "priority": 363, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "none", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_type": "VAT_CAROUSEL", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Strategiczne bankructwo po wyłudzeniu VAT", "_legal_basis": "Art. 62 KKS + Art. 300 KK", "_warnings": ["Strategiczne bankructwo kontrahenta po serii transakcji — typowe dla karuzeli VAT!"] } {
    object.get(input.vendor, "insolvency_after_large_transactions", false) == true
}

# P364: vat_section_aggregate_risk — Skumulowane ryzyko sekcji VAT
else := { "matched": true, "rule_id": "jdg.kks.vat_section_aggregate_risk_p364", "package": "jdg.kks", "priority": 364, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_vat_risk_score": risk_score, "kks_vat_risk_level": risk_level, "_routing": routing_action, "_routing_reason": "Skumulowane ryzyko VAT — agregacja", "_legal_basis": "Art. 62-76 KKS — agregacja sekcji VAT", "_warnings": [sprintf("Skumulowane ryzyko VAT: %s (score: %d). %s", [risk_level, risk_score, action_msg])]
} {
    risk_score := object.get(input.jdg_entrepreneur, "kks_vat_aggregate_risk_score", 0)
    risk_score > 0
    risk_level = "LOW" { risk_score <= 20 }
    risk_level = "MEDIUM" { risk_score > 20; risk_score <= 50 }
    risk_level = "HIGH" { risk_score > 50; risk_score <= 80 }
    risk_level = "CRITICAL" { risk_score > 80 }
    routing_action = "" { risk_level == "LOW" }
    routing_action = "TRIAGE_QUEUE" { risk_level in {"MEDIUM", "HIGH"} }
    routing_action = "BLOCK_AND_ALERT" { risk_level == "CRITICAL" }
    action_msg = "Monitoruj" { risk_level == "LOW" }
    action_msg = "Zalecany audyt wewnętrzny" { risk_level == "MEDIUM" }
    action_msg = "WYMAGANA weryfikacja manualna" { risk_level == "HIGH" }
    action_msg = "NATYCHMIASTOWA blokada + zgłoszenie do KAS!" { risk_level == "CRITICAL" }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗

# ═══════════════════════════════════════════════════════════════════════════════
# P365-P374: ZABEZPIECZENIA MAJĄTKOWE I ODPOWIEDZIALNOŚĆ OSÓB TRZECICH
# (Art. 22-31 KKS) — 10 reguł
# ═══════════════════════════════════════════════════════════════════════════════

# P365: asset_seizure_risk — Ryzyko zabezpieczenia majątkowego
else := {
    "matched": true, "rule_id": "jdg.kks.asset_seizure_risk_p365",
    "package": "jdg.kks", "priority": 365,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_asset_seizure_risk": true, "kks_seizure_amount": estimated_tax,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ryzyko zabezpieczenia majątkowego — art. 22-31 KKS",
    "_legal_basis": "Art. 22-31 KKS — zabezpieczenie majątkowe",
    "_warnings": [sprintf("ZABEZPIECZENIE MAJĄTKOWE — ryzyko zajęcia do %.2f PLN. Podstawa: art. 22-31 KKS. Zabezpiecz środki na podatek + karę!", [estimated_tax])]
} {
    estimated_tax := object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0)
    estimated_tax > 10000
    object.get(input.jdg_entrepreneur, "kks_proceedings_started", false) == true
}

# P366: property_security_active — Aktywne zabezpieczenie majątkowe
else := { "matched": true, "rule_id": "jdg.kks.property_security_active_p366", "package": "jdg.kks", "priority": 366, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_security_active": true, "kks_security_type": security_type, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Aktywne zabezpieczenie majątkowe KAS", "_legal_basis": "Art. 22 KKS", "_warnings": [sprintf("AKTYWNE ZABEZPIECZENIE MAJĄTKOWE — %s na kwotę %.2f PLN. Utrudniona sprzedaż majątku!", [security_type, sec_amount])] } {
    sec_amount := object.get(input.jdg_entrepreneur, "kks_security_amount", 0)
    sec_amount > 0
    security_type := object.get(input.jdg_entrepreneur, "kks_security_type", "HIPOTEKA_PRZYMUSOWA")
}

# P367: bank_account_blocked — Blokada rachunku bankowego
else := { "matched": true, "rule_id": "jdg.kks.bank_account_blocked_p367", "package": "jdg.kks", "priority": 367, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_bank_blocked": true, "kks_blocked_accounts": blocked, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Blokada rachunku bankowego — art. 23 KKS", "_legal_basis": "Art. 23 § 1 KKS", "_warnings": [sprintf("BLOKADA RACHUNKU — %d kont zablokowanych. Wpłaty od kontrahentów NIEDOSTĘPNE do czasu decyzji sądu!", [blocked])] } {
    blocked := object.get(input.jdg_entrepreneur, "kks_bank_accounts_blocked", 0)
    blocked > 0
}

# P368: mortgage_on_property — Hipoteka przymusowa na nieruchomości
else := { "matched": true, "rule_id": "jdg.kks.mortgage_on_property_p368", "package": "jdg.kks", "priority": 368, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_mortgage_active": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Hipoteka przymusowa KAS", "_legal_basis": "Art. 23 § 2 KKS w zw. z Art. 34 § 2 OrdPU", "_warnings": ["HIPOTEKA PRZYMUSOWA — nieruchomość obciążona na rzecz Skarbu Państwa. Sprzedaż wymaga zgody US!"] } {
    object.get(input.jdg_entrepreneur, "kks_mortgage_registered", false) == true
}

# P369: tax_lien_registered — Zastaw skarbowy
else := { "matched": true, "rule_id": "jdg.kks.tax_lien_registered_p369", "package": "jdg.kks", "priority": 369, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_lien_active": true, "kks_lien_amount": lien_amt, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zastaw skarbowy — art. 24 KKS", "_legal_basis": "Art. 24 KKS w zw. z Art. 41 OrdPU", "_warnings": [sprintf("ZASTAW SKARBOWY — %.2f PLN na majątku ruchomym. Rzeczy obciążone zastawem nie mogą być sprzedane!", [lien_amt])] } {
    lien_amt := object.get(input.jdg_entrepreneur, "kks_tax_lien_amount", 0)
    lien_amt > 0
}

# P370: third_party_liability_kks — Odpowiedzialność osób trzecich
else := { "matched": true, "rule_id": "jdg.kks.third_party_liability_p370", "package": "jdg.kks", "priority": 370, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_third_party_liable": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Odpowiedzialność osób trzecich — art. 24a KKS", "_legal_basis": "Art. 24a KKS", "_warnings": ["ODPOWIEDZIALNOŚĆ OSÓB TRZECICH — współmałżonek / wspólnik / członek zarządu może odpowiadać majątkiem!"] } {
    object.get(input.jdg_entrepreneur, "kks_third_party_liability_active", false) == true
}

# P371: successor_liability_kks — Odpowiedzialność następców prawnych
else := { "matched": true, "rule_id": "jdg.kks.successor_liability_p371", "package": "jdg.kks", "priority": 371, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_successor_liable": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Odpowiedzialność następców prawnych — art. 25 KKS", "_legal_basis": "Art. 25 KKS", "_warnings": ["ODPOWIEDZIALNOŚĆ NASTĘPCÓW — spadkobiercy/nabywcy przedsiębiorstwa mogą odpowiadać za zaległości KKS!"] } {
    object.get(input.jdg_entrepreneur, "in_succession", false) == true
    object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0) > 0
}

# P372: business_activity_ban — Zakaz prowadzenia działalności po KKS
else := { "matched": true, "rule_id": "jdg.kks.business_activity_ban_p372", "package": "jdg.kks", "priority": 372, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_activity_ban_possible": true, "kks_ban_duration_years": ban_yrs, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zakaz prowadzenia działalności — art. 26 KKS", "_legal_basis": "Art. 26 KKS w zw. z Art. 41 KK", "_warnings": [sprintf("ZAKAZ DZIAŁALNOŚCI — ryzyko orzeczenia zakazu na %d lat. Skazanie za KKS = utrata prawa do prowadzenia JDG!", [ban_yrs])] } {
    ban_yrs := object.get(input.jdg_entrepreneur, "kks_potential_ban_years", 0)
    ban_yrs > 0
}

# P373: public_contracts_ban — Wykluczenie z zamówień publicznych
else := { "matched": true, "rule_id": "jdg.kks.public_contracts_ban_p373", "package": "jdg.kks", "priority": 373, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_pzp_exclusion": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Wykluczenie z zamówień publicznych", "_legal_basis": "Art. 108-109 PZP + KKS", "_warnings": ["WYKLUCZENIE Z PZP — skazanie za KKS = niemożność ubiegania się o zamówienia publiczne przez 3-5 lat!"] } {
    object.get(input.jdg_entrepreneur, "kks_criminal_record_active", false) == true
    object.get(input.jdg_entrepreneur, "bids_for_public_contracts", false) == true
}

# P374: professional_license_risk — Ryzyko utraty uprawnień zawodowych
else := { "matched": true, "rule_id": "jdg.kks.professional_license_risk_p374", "package": "jdg.kks", "priority": 374, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_license_risk": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ryzyko utraty licencji zawodowej", "_legal_basis": "Art. 26 KKS + przepisy korporacyjne", "_warnings": ["RYZYKO UTRATY UPRAWNIEŃ — skazanie za KKS może skutkować odebraniem licencji (doradca podatkowy, adwokat, biegły rewident)!"] } {
    object.get(input.jdg_entrepreneur, "holds_professional_license", false) == true
    object.get(input.jdg_entrepreneur, "kks_criminal_record_active", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P375-P384: AGREGACJA RYZYKA MIĘDZYPRZESTĘPCZEGO (Art. 54-76 KKS) — 10 reguł
# ═══════════════════════════════════════════════════════════════════════════════

# P375: cross_offense_pattern — Wzorzec międzyprzestępczy
else := {
    "matched": true, "rule_id": "jdg.kks.cross_offense_pattern_p375",
    "package": "jdg.kks", "priority": 375,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_cross_offense_pattern": true, "kks_offense_types_detected": offense_types,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wzorzec międzyprzestępczy — wiele typów przestępstw",
    "_legal_basis": "Art. 54-76 KKS — analiza międzyprzestępcza",
    "_warnings": [sprintf("WZORZEC MIĘDZYPRZESTĘPCZY — %d typów przestępstw skarbowych: %s. Ryzyko eskaluje!", [type_count, offense_types])]
} {
    offense_types := object.get(input.jdg_entrepreneur, "kks_detected_offense_types", "")
    type_count := object.get(input.jdg_entrepreneur, "kks_distinct_offense_count", 0)
    type_count >= 2
}

# P376: offense_chain_detection — Łańcuch przestępstw skarbowych
else := { "matched": true, "rule_id": "jdg.kks.offense_chain_detection_p376", "package": "jdg.kks", "priority": 376, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_offense_chain": true, "kks_chain_length": chain_len, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Łańcuch przestępstw — powiązane czyny", "_legal_basis": "Art. 54-76 KKS — związek przestępstw", "_warnings": [sprintf("ŁAŃCUCH PRZESTĘPSTW — %d powiązanych czynów. Każdy kolejny zaostrza odpowiedzialność. Kara łączna możliwa!", [chain_len])] } {
    chain_len := object.get(input.jdg_entrepreneur, "kks_offense_chain_length", 0)
    chain_len >= 3
}

# P377: multi_year_fraud_pattern — Systematyczny fraud wieloletni
else := { "matched": true, "rule_id": "jdg.kks.multi_year_fraud_p377", "package": "jdg.kks", "priority": 377, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_multi_year": true, "kks_fraud_years": yrs, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Systematyczny fraud wieloletni", "_legal_basis": "Art. 54-76 KKS — ciągłość przestępstwa", "_warnings": [sprintf("FRAUD WIELOLETNI — %d lat nieprzerwanego naruszenia. Czyn ciągły = zaostrzenie kary + przedawnienie od ostatniego czynu!", [yrs])] } {
    yrs := object.get(input.jdg_entrepreneur, "kks_fraud_active_years", 0)
    yrs >= 2
}

# P378: organized_crime_indicators — Wskaźniki przestępczości zorganizowanej
else := { "matched": true, "rule_id": "jdg.kks.organized_crime_indicators_p378", "package": "jdg.kks", "priority": 378, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_organized_crime_score": org_score, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Wskaźniki przestępczości zorganizowanej", "_legal_basis": "Art. 19 § 4 KKS — grupa zorganizowana", "_warnings": [sprintf("PRZESTĘPCZOŚĆ ZORGANIZOWANA — score: %d/100. Powiązania z grupą przestępczą, podział ról, transgraniczność. Kwalifikowana odpowiedzialność!", [org_score])] } {
    org_score := object.get(input.jdg_entrepreneur, "kks_organized_crime_score", 0)
    org_score >= 50
}

# P379: money_laundering_nexus — Powiązanie z praniem pieniędzy
else := { "matched": true, "rule_id": "jdg.kks.money_laundering_nexus_p379", "package": "jdg.kks", "priority": 379, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_aml_nexus": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Powiązanie z praniem pieniędzy", "_legal_basis": "Art. 299 KK + Art. 54-76 KKS", "_warnings": ["PRANIE PIENIĘDZY — transakcje noszą znamiona prania brudnych pieniędzy. Podwójna odpowiedzialność: KKS + KK! Obowiązek zgłoszenia GIIF!"] } {
    object.get(input.jdg_entrepreneur, "kks_aml_red_flags", false) == true
}

# P380: tax_crime_evolution — Ewolucja przestępczości podatkowej
else := { "matched": true, "rule_id": "jdg.kks.tax_crime_evolution_p380", "package": "jdg.kks", "priority": 380, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_evolution_trend": trend, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Ewolucja przestępczości podatkowej", "_legal_basis": "Art. 54-76 KKS — analiza trendu", "_warnings": [sprintf("EWOLUCJA PRZESTĘPCZOŚCI — trend: %s. Eskalacja z drobnych wykroczeń do poważnych przestępstw. Wzorzec typowy dla fraudu!", [trend])] } {
    trend := object.get(input.jdg_entrepreneur, "kks_offense_evolution_trend", "STABLE")
    trend in {"ESCALATING", "RAPID_ESCALATION"}
}

# P381: cumulative_tax_loss — Skumulowana strata Skarbu Państwa
else := { "matched": true, "rule_id": "jdg.kks.cumulative_tax_loss_p381", "package": "jdg.kks", "priority": 381, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_cumulative_loss": cum_loss, "kks_cumulative_severity": severity, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Skumulowana strata fiskalna", "_legal_basis": "Art. 54-76 KKS — suma uszczupleń", "_warnings": [sprintf("SKUMULOWANA STRATA SP — %.2f PLN (%s). Przekroczono próg wielkiej wartości! Obligatoryjne zawiadomienie KAS.", [cum_loss, severity])] } {
    cum_loss := object.get(input.jdg_entrepreneur, "kks_cumulative_tax_loss", 0)
    cum_loss > 100000
    severity = "DUZA_WARTOSC" { cum_loss <= 1000000 }
    severity = "WIELKA_WARTOSC" { cum_loss > 1000000 }
}

# P382: offense_severity_escalation — Eskalacja ciężkości przestępstw
else := { "matched": true, "rule_id": "jdg.kks.offense_severity_escalation_p382", "package": "jdg.kks", "priority": 382, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_severity_escalated": true, "kks_max_severity": max_sev, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Eskalacja ciężkości przestępstw", "_legal_basis": "Art. 54-76 KKS — gradacja kar", "_warnings": [sprintf("ESKALACJA CIĘŻKOŚCI — od drobnych wykroczeń do %s. Systematyczne pogarszanie profilu. Konieczna interwencja prawna!", [max_sev])] } {
    max_sev := object.get(input.jdg_entrepreneur, "kks_max_offense_severity", "")
    max_sev in {"HIGH", "CRITICAL"}
    object.get(input.jdg_entrepreneur, "kks_offense_count_12m", 0) >= 3
}

# P383: global_kks_risk_score — Globalny scoring ryzyka KKS
else := {
    "matched": true, "rule_id": "jdg.kks.global_kks_risk_score_p383",
    "package": "jdg.kks", "priority": 383,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_global_score": glob_score, "kks_global_level": glob_level,
    "kks_at_risk_of_prosecution": at_risk,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Globalny scoring ryzyka KKS — synteza",
    "_legal_basis": "Art. 54-76 KKS — scoring globalny",
    "_warnings": [sprintf("GLOBALNY SCORING KKS: %d/100 (%s). %s", [glob_score, glob_level, action])]
} {
    glob_score := object.get(input.jdg_entrepreneur, "kks_global_risk_score", 0)
    glob_score > 0
    glob_level = "LOW" { glob_score <= 25 }
    glob_level = "MEDIUM" { glob_score > 25; glob_score <= 50 }
    glob_level = "HIGH" { glob_score > 50; glob_score <= 75 }
    glob_level = "CRITICAL" { glob_score > 75 }
    at_risk = false { glob_score <= 25 }
    at_risk = true { glob_score > 25 }
    action = "Monitoruj sytuację" { glob_level == "LOW" }
    action = "Zalecany audyt wewnętrzny" { glob_level == "MEDIUM" }
    action = "WYMAGANA interwencja prawnika" { glob_level == "HIGH" }
    action = "NATYCHMIASTOWE zgłoszenie do KAS + adwokat!" { glob_level == "CRITICAL" }
}

# P384: risk_to_business_survival — Ryzyko dla przetrwania JDG
else := { "matched": true, "rule_id": "jdg.kks.risk_to_business_survival_p384", "package": "jdg.kks", "priority": 384, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_business_survival_risk": survival_risk, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ryzyko dla kontynuacji działalności", "_legal_basis": "Art. 54-76 KKS — ocena wpływu na JDG", "_warnings": [sprintf("RYZYKO DLA JDG — %s. Potencjalna kara + zaległości = %.2f PLN vs roczny przychód %.2f PLN. %s", [survival_risk, total_exposure, annual_revenue, recommendation])] } {
    total_exposure := object.get(input.jdg_entrepreneur, "kks_total_financial_exposure", 0)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_estimate", 999999999)
    safety_revenue := max([annual_revenue, 1])
    exposure_ratio := total_exposure / safety_revenue
    survival_risk = "LOW" { exposure_ratio <= 0.1 }
    survival_risk = "MEDIUM" { exposure_ratio > 0.1; exposure_ratio <= 0.3 }
    survival_risk = "HIGH" { exposure_ratio > 0.3; exposure_ratio <= 0.5 }
    survival_risk = "CRITICAL" { exposure_ratio > 0.5 }
    recommendation = "Kontynuuj z ostrożnością" { survival_risk in {"LOW", "MEDIUM"} }
    recommendation = "ROZWAŻ ZAWIESZENIE — ryzyko egzekucji >30% przychodu" { survival_risk == "HIGH" }
    recommendation = "ZAMKNIJ JDG — egzekucja przekroczy przychody!" { survival_risk == "CRITICAL" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P385-P399: POSTĘPOWANIE MANDATOWE I POMOST PRZESTĘPSTWO→WYKROCZENIE
# (Art. 22-31, 77-83, 44-51 KKS) — 15 reguł
# ═══════════════════════════════════════════════════════════════════════════════

# P385: mandate_proceedings_eligible — Czy sprawa kwalifikuje się do mandatu
else := {
    "matched": true, "rule_id": "jdg.kks.mandate_proceedings_eligible_p385",
    "package": "jdg.kks", "priority": 385,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_mandate_eligible": true, "kks_mandate_max_amount": mand_max,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 137-149 KKW — postępowanie mandatowe",
    "_warnings": [sprintf("POSTĘPOWANIE MANDATOWE — kwalifikuje się. Max mandat: %.2f PLN. Sprawca musi wyrazić zgodę na mandat.", [mand_max])]
} {
    off_type := object.get(input.invoice, "kks_offense_type", "")
    off_type in {"DECLARATION_NOT_FILED", "INCORRECT_DATA", "TAX_UNPAID", "NO_INVOICE"}
    tax_loss := object.get(input.invoice, "tax_shortfall_pln", 0)
    tax_loss <= 26000
    mand_max = 5200 { tax_loss <= 5200 }
    mand_max = 10400 { tax_loss > 5200; tax_loss <= 13000 }
    mand_max = 26000 { tax_loss > 13000 }
}

# P386: mandate_amount_calculation — Wyliczenie mandatu karnego
else := { "matched": true, "rule_id": "jdg.kks.mandate_amount_p386", "package": "jdg.kks", "priority": 386, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_mandate_amount": mand_amt, "kks_mandate_daily_rates": daily_r, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 48 KKW — wymiar mandatu", "_warnings": [sprintf("MANDAT KARNY — %.2f PLN (%d stawek dziennych × %.2f PLN). Do zapłaty w ciągu 7 dni od uprawomocnienia.", [mand_amt, daily_r, daily_rate_pln])] } {
    daily_r := object.get(input.jdg_entrepreneur, "kks_mandate_daily_rates", 0)
    daily_r > 0
    daily_r <= 20
    daily_rate_pln := object.get(input.jdg_entrepreneur, "kks_daily_rate_pln", 100)
    mand_amt := daily_r * daily_rate_pln
}

# P387: mandate_consent_required — Zgoda na mandat (warunek konieczny)
else := { "matched": true, "rule_id": "jdg.kks.mandate_consent_required_p387", "package": "jdg.kks", "priority": 387, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_mandate_consent_pending": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Mandat wymaga zgody sprawcy", "_legal_basis": "Art. 137 § 2 KKW", "_warnings": ["ZGODA NA MANDAT — bez wyraźnej zgody mandat jest nieskuteczny. Odmowa = skierowanie sprawy do sądu!"] } {
    object.get(input.jdg_entrepreneur, "kks_mandate_offered", false) == true
    object.get(input.jdg_entrepreneur, "kks_mandate_consent_given", false) == false
}

# P388: mandate_refusal_consequences — Konsekwencje odmowy mandatu
else := { "matched": true, "rule_id": "jdg.kks.mandate_refusal_consequences_p388", "package": "jdg.kks", "priority": 388, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_mandate_refused": true, "kks_court_proceedings_risk": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Odmowa mandatu — sprawa trafia do sądu", "_legal_basis": "Art. 137 § 3 KKW", "_warnings": ["ODMOWA MANDATU — sprawa zostanie skierowana do sądu. Możliwa wyższa kara (do 720 stawek dziennych) + koszty sądowe!"] } {
    object.get(input.jdg_entrepreneur, "kks_mandate_consent_given", true) == false
    object.get(input.jdg_entrepreneur, "kks_mandate_offered", false) == true
}

# P389: mandate_payment_deadline — Termin płatności mandatu
else := { "matched": true, "rule_id": "jdg.kks.mandate_payment_deadline_p389", "package": "jdg.kks", "priority": 389, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_mandate_paid": false, "kks_mandate_overdue_days": od_days, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Niezapłacony mandat — egzekucja", "_legal_basis": "Art. 140 KKW", "_warnings": [sprintf("MANDAT NIEZAPŁACONY — %d dni po terminie. Grozi egzekucja komornicza + zamiana na pracę społecznie użyteczną!", [od_days])] } {
    od_days := object.get(input.jdg_entrepreneur, "kks_mandate_days_overdue", 0)
    od_days > 0
}

# P390: crime_to_misdemeanor_bridge — Pomost kwalifikacyjny
else := {
    "matched": true, "rule_id": "jdg.kks.crime_to_misdemeanor_bridge_p390",
    "package": "jdg.kks", "priority": 390,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_classification": classification,
    "kks_reclassified_from": original_class,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Pomost kwalifikacyjny — ocena czy przestępstwo czy wykroczenie",
    "_legal_basis": "Art. 53 § 3-4 KKS (wypadek mniejszej wagi)",
    "_warnings": [sprintf("REKLASYFIKACJA — %s → %s. Art. 53 KKS: czyn może być uznany za wypadek mniejszej wagi. Konsekwencje: %s", [original_class, classification, legal_effect])]
} {
    original_class := object.get(input.invoice, "kks_offense_classification", "PRZESTEPSTWO")
    factors := object.get(input.jdg_entrepreneur, "kks_minor_weight_factors", 0)
    factors >= 2
    classification = "WYKROCZENIE" { factors >= 3 }
    classification = "PRZESTEPSTWO_MNIEJSZEJ_WAGI" { factors == 2 }
    legal_effect = "kara jak za wykroczenie" { classification == "WYKROCZENIE" }
    legal_effect = "nadzwyczajne złagodzenie kary" { classification == "PRZESTEPSTWO_MNIEJSZEJ_WAGI" }
}

# P391: criminal_record_check — Sprawdzenie w KRK
else := { "matched": true, "rule_id": "jdg.kks.criminal_record_check_p391", "package": "jdg.kks", "priority": 391, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_criminal_record": record, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Krajowy Rejestr Karny — wpływ na recydywę", "_legal_basis": "Art. 19 § 3 KKS — recydywa skarbowa", "_warnings": [sprintf("KRK — %s. %s", [record, impact])] } {
    prev_convictions := object.get(input.jdg_entrepreneur, "kks_prior_convictions_5y", 0)
    record = "CZYSZCZY" { prev_convictions == 0 }
    record = "WCZEŚNIEJ KARANY" { prev_convictions > 0; prev_convictions < 3 }
    record = "RECYDYWISTA" { prev_convictions >= 3 }
    impact = "Pierwsze przestępstwo — szansa na warunkowe umorzenie" { record == "CZYSZCZY" }
    impact = sprintf("%d wcześniejszych skazań — utrudnione warunkowe umorzenie", [prev_convictions]) { record == "WCZEŚNIEJ KARANY" }
    impact = "Wielokrotny recydywista — obligatoryjne zaostrzenie kary!" { record == "RECYDYWISTA" }
}

# P392: prosecution_decision_factors — Czynniki decyzji o ściganiu
else := { "matched": true, "rule_id": "jdg.kks.prosecution_decision_factors_p392", "package": "jdg.kks", "priority": 392, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_prosecution_likelihood": likelihood, "kks_prosecution_factors": factors, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Ocena prawdopodobieństwa ścigania", "_legal_basis": "Art. 54-83 KKS — decyzja prokuratorska", "_warnings": [sprintf("PRAWDOPODOBIEŃSTWO ŚCIGANIA: %s. Czynniki: %s. %s", [likelihood, factors, recommendation])] } {
    factors := object.get(input.jdg_entrepreneur, "kks_prosecution_factors", "")
    score := object.get(input.jdg_entrepreneur, "kks_prosecution_score", 0)
    likelihood = "NISKIE" { score <= 20 }
    likelihood = "ŚREDNIE" { score > 20; score <= 60 }
    likelihood = "WYSOKIE" { score > 60; score <= 80 }
    likelihood = "NIEMAL PEWNE" { score > 80 }
    recommendation = "Rozważ dobrowolne ujawnienie" { likelihood in {"NISKIE", "ŚREDNIE"} }
    recommendation = "NATYCHMIAST skonsultuj z adwokatem karnym skarbowym!" { likelihood in {"WYSOKIE", "NIEMAL PEWNE"} }
}

# P393: cross_tax_type_offenses — Przestępstwa wielopodatkowe
else := { "matched": true, "rule_id": "jdg.kks.cross_tax_type_offenses_p393", "package": "jdg.kks", "priority": 393, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_cross_tax": true, "kks_tax_types_affected": tax_types, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Przestępstwa wielopodatkowe", "_legal_basis": "Art. 54-76 KKS — zbieg przepisów", "_warnings": [sprintf("WIELOPODATKOWOŚĆ — naruszenia dotyczą: %s. Zbieg przepisów = kumulatywna odpowiedzialność karna za każdy podatek!", [tax_types])] } {
    tax_types := object.get(input.jdg_entrepreneur, "kks_affected_tax_types", "")
    count_tax_types := object.get(input.jdg_entrepreneur, "kks_tax_type_count", 0)
    count_tax_types >= 2
}

# P394: offense_statute_mapping — Mapowanie na terminy przedawnienia
else := {
    "matched": true, "rule_id": "jdg.kks.offense_statute_mapping_p394",
    "package": "jdg.kks", "priority": 394,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_statute_applies": true, "kks_applicable_years": statute_years,
    "kks_statute_deadline": deadline_date,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 44, 51 KKS — terminy przedawnienia",
    "_warnings": [sprintf("PRZEDAWNIENIE — %d lat od czynu (%s). Termin upływa: %s. Status: %s", [statute_years, off_type, deadline_date, status])]
} {
    off_type := object.get(input.invoice, "kks_offense_type", "")
    off_type in {"TAX_EVASION", "EMPTY_INVOICE", "FAKE_INVOICE", "UNRELIABLE_BOOKS", "UNRELIABLE_VAT", "VAT_CAROUSEL", "DECLARATION_NOT_FILED", "INCORRECT_DATA", "TAX_UNPAID"}
    statute_years = 5 { off_type in {"TAX_EVASION", "EMPTY_INVOICE", "FAKE_INVOICE", "UNRELIABLE_BOOKS", "UNRELIABLE_VAT", "VAT_CAROUSEL"} }
    statute_years = 3 { off_type in {"DECLARATION_NOT_FILED", "INCORRECT_DATA", "TAX_UNPAID"} }
    off_date := object.get(input.invoice, "kks_offense_date", "")
    off_ns := time.parse_ns("2006-01-02", off_date)
    deadline_ns := off_ns + (statute_years * 365 * 24 * 60 * 60 * 1000000000)
    deadline_date := time.format(time.add_date(off_ns, statute_years, 0, 0))
    now_ns := time.now_ns()
    status = "PRZEDAWNIONE" { now_ns > deadline_ns }
    status = "W TOKU" { now_ns <= deadline_ns }
}

# P395: penalty_calculation_input — Dane wejściowe do kalkulacji kary
else := { "matched": true, "rule_id": "jdg.kks.penalty_calculation_input_p395", "package": "jdg.kks", "priority": 395, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_penalty_input_ready": true, "kks_fine_daily_rates": fine_rates, "kks_imprisonment_range": impr_range, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 22-31 KKS — dane wsadowe kary", "_warnings": [sprintf("KALKULACJA KARY — grzywna: %d stawek, więzienie: %s. Dochód/mies.: %.2f PLN. Stawka dzienna: %.2f PLN.", [fine_rates, impr_range, monthly_income, daily_rate_pln])] } {
    fine_rates := object.get(input.jdg_entrepreneur, "kks_recommended_daily_rates", 10)
    impr_range := object.get(input.jdg_entrepreneur, "kks_imprisonment_range", "brak")
    monthly_income := object.get(input.jdg_entrepreneur, "kks_monthly_income_estimate", 5000)
    daily_rate_pln := monthly_income / 30
    daily_rate_pln >= 50
}

# P396: pre_misdemeanor_screening — Badanie przed-wykroczeniowe
else := { "matched": true, "rule_id": "jdg.kks.pre_misdemeanor_screening_p396", "package": "jdg.kks", "priority": 396, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_pre_screening_result": result, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Badanie kwalifikacyjne przed-wykroczeniowe", "_legal_basis": "Art. 53, 77-83 KKS — granica przestępstwo/wykroczenie", "_warnings": [sprintf("BADANIE PRZED-WYKROCZENIOWE — %s. Kwota: %.2f PLN, próg: %.2f PLN. %s", [result, amount, threshold, recommendation])] } {
    amount := object.get(input.invoice, "tax_shortfall_pln", 0)
    threshold := object.get(input.jdg_entrepreneur, "kks_crime_threshold_pln", 200000)
    severity := object.get(input.invoice, "kks_offense_severity", "LOW")
    result = "WYKROCZENIE" { amount <= threshold; severity in {"LOW", "MEDIUM"} }
    result = "PRZESTĘPSTWO" { amount > threshold }
    result = "PRZESTĘPSTWO" { severity in {"HIGH", "CRITICAL"} }
    recommendation = "Mandat karny wystarczający" { result == "WYKROCZENIE" }
    recommendation = "Wymagane postępowanie sądowe" { result == "PRZESTĘPSTWO" }
}

# P397: offense_discovery_path — Ścieżka wykrycia przestępstwa
else := { "matched": true, "rule_id": "jdg.kks.offense_discovery_path_p397", "package": "jdg.kks", "priority": 397, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "kks_discovered_by": discovered_by, "kks_self_reportable": self_reportable, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Ścieżka wykrycia — wpływ na strategię obrony", "_legal_basis": "Art. 16 KKS — czynny żal", "_warnings": [sprintf("WYKRYCIE — %s. %s", [discovered_by, self_report_advice])] } {
    discovered_by := object.get(input.jdg_entrepreneur, "kks_discovery_path", "KAS_KONTROLA")
    self_reportable = true { discovered_by == "SAMOUJAWNIENIE" }
    self_reportable = true { discovered_by == "BIURO_RACHUNKOWE" }
    self_reportable = false { discovered_by in {"KAS_KONTROLA", "KAS_CZYNNOSCI", "POLICJA", "PROKURATURA"} }
    else = false { discovered_by != "" }
    self_reportable = self_reportable
    self_report_advice = "Możliwy czynny żal — złóż zawiadomienie NATYCHMIAST przed formalnym wszczęciem!" { self_reportable == true }
    self_report_advice = "Czynny żal już NIEMOŻLIWY — postępowanie w toku. Skup się na linii obrony." { self_reportable == false }
}

# P398: legal_defense_validity — Ważność obrony prawnej
else := {
    "matched": true, "rule_id": "jdg.kks.legal_defense_validity_p398",
    "package": "jdg.kks", "priority": 398,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_defense_valid": valid, "kks_defense_type": defense_type,
    "kks_defense_effect": effect,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 10-11 KKS — kontratypy i obrona",
    "_warnings": [sprintf("OBRONA PRAWNA — %s: %s. Skutek: %s. %s", [defense_type, valid, effect, recommendation])]
} {
    defense_type := object.get(input.jdg_entrepreneur, "kks_defense_strategy", "BRAK")
    defense_type != "BRAK"
    valid = "WAŻNA" { defense_type in {"BLAD_CO_DO_PRAWA_USPRAWIEDLIWIONY", "STAN_WYZSZEJ_KONIECZNOSCI", "DZIALANIE_NA_POLECENIE", "INTERPRETACJA_INDYWIDUALNA"} }
    valid = "SŁABA" { defense_type in {"BLAD_CO_DO_PRAWA_NIEUSPRAWIEDLIWIONY", "NIEWIEDZA", "DORADCA_ZAPEWNIL"} }
    valid = "NIEWAŻNA" { defense_type in {"IGNOROWANIE_PRZEPISOW"} }
    else = "NIEWAŻNA" { defense_type != "" }
    valid = valid
    effect = "Może prowadzić do uniewinnienia" { valid == "WAŻNA" }
    effect = "Może złagodzić karę" { valid == "SŁABA" }
    effect = "Brak skutecznej linii obrony" { valid == "NIEWAŻNA" }
    recommendation = "Utrzymuj linię obrony" { valid == "WAŻNA" }
    recommendation = "Rozważ negocjacje z prokuratorem" { valid == "SŁABA" }
    recommendation = "NATYCHMIAST znajdź adwokata specjalizującego się w KKS!" { valid == "NIEWAŻNA" }
}

# P399: crime_section_summary — Podsumowanie sekcji przestępczej
else := {
    "matched": true, "rule_id": "jdg.kks.crime_section_summary_p399",
    "package": "jdg.kks", "priority": 399,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_crimes_total": total_crimes, "kks_max_penalty": max_penalty,
    "kks_min_penalty": min_penalty, "kks_summary_severity": summary_sev,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PODSUMOWANIE sekcji przestępczej KKS",
    "_legal_basis": "Art. 54-76 KKS — synteza",
    "_warnings": [sprintf("PODSUMOWANIE KKS: %d przestępstw skarbowych. Kara: %s — %s. Ryzyko: %s. %s", [total_crimes, min_penalty, max_penalty, summary_sev, final_advice])]
} {
    total_crimes := object.get(input.jdg_entrepreneur, "kks_crime_count", 0)
    total_crimes > 0
    max_penalty := object.get(input.jdg_entrepreneur, "kks_max_possible_penalty", "nieznana")
    min_penalty := object.get(input.jdg_entrepreneur, "kks_min_possible_penalty", "nieznana")
    summary_sev = "NISKIE" { total_crimes <= 2 }
    summary_sev = "ŚREDNIE" { total_crimes > 2; total_crimes <= 5 }
    summary_sev = "WYSOKIE" { total_crimes > 5; total_crimes <= 10 }
    summary_sev = "KRYTYCZNE" { total_crimes > 10 }
    final_advice = "Rozważ dobrowolne ujawnienie + czynny żal" { summary_sev in {"NISKIE", "ŚREDNIE"} }
    final_advice = "KONIECZNY adwokat + rozważenie ugody z KAS" { summary_sev == "WYSOKIE" }
    final_advice = "STAN KRYTYCZNY — natychmiastowe działanie: adwokat + wniosek o dobrowolne poddanie się karze!" { summary_sev == "KRYTYCZNE" }
}
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

# P497: aggregate_penalty_multiple_offenses — Kara łączna za wiele przestępstw (Art. 24 KKS)
else := {
    "matched": true, "rule_id": "jdg.kks.aggregate_penalty_p497",
    "package": "jdg.kks", "priority": 497,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_aggregate_penalty": true, "kks_offense_count": offense_count,
    "kks_max_aggregate_daily_rates": 1080,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Kara łączna za wiele przestępstw — art. 24 KKS",
    "_legal_basis": "Art. 24 § 1-3 KKS",
    "_warnings": [sprintf("KARA ŁĄCZNA za %d przestępstw skarbowych — do 1080 stawek dziennych + możliwe pozbawienie wolności do 15 lat", [offense_count])]
} {
    offense_count := object.get(input.jdg_entrepreneur, "kks_offenses_count", 0)
    offense_count > 1
}

# P498: penalty_payment_plan — Rozłożenie grzywny na raty (Art. 27 KKS)
else := {
    "matched": true, "rule_id": "jdg.kks.penalty_payment_plan_p498",
    "package": "jdg.kks", "priority": 498,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_payment_plan_eligible": true, "kks_max_installments": 12,
    "kks_fine_total": fine_total,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Wniosek o rozłożenie grzywny na raty — art. 27 KKS",
    "_legal_basis": "Art. 27 § 1 KKS",
    "_warnings": [sprintf("Rozłożenie grzywny %.2f PLN na max 12 rat. Wniosek do sądu w ciągu 7 dni od uprawomocnienia wyroku", [fine_total])]
} {
    fine_total := object.get(input.jdg_entrepreneur, "kks_fine_total_pln", 0)
    fine_total > 5000
    input.jdg_entrepreneur.kks_voluntary_disclosure_filed == true
}

# P499: penalty_execution_timeline — Oś czasu wykonania kary (Art. 25-27 KKS)
else := {
    "matched": true, "rule_id": "jdg.kks.penalty_execution_timeline_p499",
    "package": "jdg.kks", "priority": 499,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_penalty_timeline": true, "kks_payment_deadline_days": 30,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niezapłacona grzywna KKS — ryzyko kary zastępczej",
    "_legal_basis": "Art. 25-27, Art. 46-53 KKS",
    "_warnings": [sprintf("Wykonanie kary KKS — 30 dni na zapłatę %.2f PLN. Brak = kara zastępcza pozbawienia wolności. 1 dzień = 1-2 stawki dzienne", [fine_unpaid])]
} {
    verdict_date := object.get(input.jdg_entrepreneur, "kks_verdict_date", "")
    verdict_date != ""
    fine_unpaid := object.get(input.jdg_entrepreneur, "kks_fine_unpaid_pln", 0)
    fine_unpaid > 0
}
