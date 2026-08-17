# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise Policies — BDO: Baza Danych Odpadowych (P1900-P1921)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: BDO Enterprise — Advanced Waste Management Compliance for JDG
# description: |
#   Rozbudowany pakiet Enterprise dla BDO i gospodarki odpadami w JDG.
#   Pokrycie: rejestracja BDO, kody EWC, ewidencja kwartalna, KPO,
#   transport, transgraniczne przemieszczanie, zezwolenia, sankcje i EPR.
# architecture: Multi-Pass Enterprise (ADR-001)
# legal_basis: ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321), Rozporządzenie ws. BDO, Dyrektywa 2008/98/WE
# package: jdg.environmental.bdo
# deprecated: false
#

package jdg.environmental.bdo


bdo_validation_msg(is_valid) = "OK — format poprawny" {
    is_valid == true
}

bdo_validation_msg(is_valid) = "BŁĘDNY FORMAT — użyj formatu XX XX XX (z gwiazdką dla niebezpiecznych!)" {
    is_valid == false
}

bdo_packaging_status(achieved_pct) = "CEL OSIĄGNIĘTY" {
    achieved_pct >= 60
}

bdo_packaging_status(achieved_pct) = "CEL NIEOSIĄGNIĘTY — opłata produktowa!" {
    achieved_pct < 60
}

bdo_quarter(month) = 1 {
    month <= 3
}

bdo_quarter(month) = 2 {
    month > 3
    month <= 6
}

bdo_quarter(month) = 3 {
    month > 6
    month <= 9
}

bdo_quarter(month) = 4 {
    month > 9
}

bdo_quarter_deadline(quarter) = "30 kwietnia" {
    quarter == 1
}

bdo_quarter_deadline(quarter) = "31 lipca" {
    quarter == 2
}

bdo_quarter_deadline(quarter) = "31 października" {
    quarter == 3
}

bdo_quarter_deadline(quarter) = "31 stycznia następnego roku" {
    quarter == 4
}

bdo_registration_status(is_registered) = "ZAREJESTROWANY — OK" {
    is_registered == true
}

bdo_registration_status(is_registered) = "NIEZAREJESTROWANY — zarejestruj w BDO!" {
    is_registered == false
}

bdo_transport_type(is_hazardous) = "Odpady inne niż niebezpieczne — wpis w BDO" {
    is_hazardous == false
}

bdo_transport_type(is_hazardous) = "Odpady NIEBEZPIECZNE — zezwolenie + ADR + ubezpieczenie OC!" {
    is_hazardous == true
}

bdo_cross_border_procedure(is_hazardous, _) = "NOTYFIKACJA (zgoda przed transportem)" {
    is_hazardous == true
}

bdo_cross_border_procedure(is_hazardous, is_green_list) = "ZIELONA LISTA (uproszczona, zał. VII)" {
    is_green_list == true
    is_hazardous == false
}

bdo_cross_border_procedure(is_hazardous, is_green_list) = "AMBERSKA LISTA (notyfikacja uproszczona)" {
    is_green_list == false
    is_hazardous == false
}

bdo_sanction_amounts := {
    "NO_REGISTRATION": 5000,
    "NO_LEDGER": 10000,
    "NO_KPO": 20000,
    "NO_DGO": 50000,
    "ILLEGAL_STORAGE": 100000,
    "ILLEGAL_TRANSPORT": 1000000,
}

bdo_sanction_types := {
    "NO_REGISTRATION": "Brak rejestracji w BDO",
    "NO_LEDGER": "Brak ewidencji odpadów",
    "NO_KPO": "Brak KPO",
    "NO_DGO": "Brak DGO",
    "ILLEGAL_STORAGE": "Nielegalne magazynowanie",
    "ILLEGAL_TRANSPORT": "Nielegalny transport",
}

bdo_sanction_details := {
    "NO_REGISTRATION": "Zarejestruj się w BDO i ureguluj opłatę",
    "NO_LEDGER": "Uzupełnij ewidencję kwartalną",
    "NO_KPO": "Wystaw elektroniczną KPO w BDO",
    "NO_DGO": "Wystąp o DGO do właściwego organu",
    "ILLEGAL_STORAGE": "Przekaż odpady w ciągu 14 dni",
    "ILLEGAL_TRANSPORT": "Wystąp o zezwolenie na transport",
}

default decide := {
    "matched": false,
    "rule_id": "jdg.environmental.bdo.no_match",
    "package": "jdg.environmental.bdo",
    "priority": 1922
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1900-P1903: BDO Registration — Rejestracja, progi, opłaty              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1900: bdo_registration_micro — Mikroprzedsiębiorca: opłata 100 PLN
decide := {
    "matched": true, "rule_id": "jdg.environmental.bdo.registration_micro",
    "package": "jdg.environmental.bdo", "priority": 1900,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_registration_required": true, "bdo_fee_pln": 100,
    "bdo_entity_category": "MIKROPRZEDSIEBIORCA",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "BDO — mikroprzedsiębiorca bez rejestracji. Opłata 100 PLN.",
    "_legal_basis": "Art. 49-54 Ustawy o odpadach, Art. 7a Ustawy o utrzymaniu czystości i porządku w gminach",
    "_warnings": ["[BDO] REJESTRACJA WYMAGANA — mikroprzedsiębiorca (opłata 100 PLN). Zarejestruj się w BDO przed rozpoczęciem działalności. Brak = kara do 5000 PLN (Art. 194 UoO)."]
} {
    input.business.produces_waste == true
    input.business.bdo_registered == false
    object.get(input.jdg_entrepreneur, "is_micro_entrepreneur", false) == true
}

# P1901: bdo_registration_small — Mały przedsiębiorca: opłata 300 PLN
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.registration_small",
    "package": "jdg.environmental.bdo", "priority": 1901,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_registration_required": true, "bdo_fee_pln": 300,
    "bdo_entity_category": "MALY_PRZEDSIEBIORCA",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "BDO — mały przedsiębiorca bez rejestracji. Opłata 300 PLN.",
    "_legal_basis": "Art. 49-54 Ustawy o odpadach",
    "_warnings": ["[BDO] REJESTRACJA WYMAGANA — mały przedsiębiorca (opłata 300 PLN). Termin: przed rozpoczęciem działalności. Kara do 10 000 PLN."]
} {
    input.business.produces_waste == true
    input.business.bdo_registered == false
    employee_count := object.get(input.employment, "employee_count", 0)
    revenue_eur := object.get(input.jdg_entrepreneur, "annual_revenue_eur_m", 0)
    employee_count < 50
    revenue_eur < 10
}

# P1902: bdo_registration_update — Aktualizacja wpisu BDO w ciągu 30 dni
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.registration_update",
    "package": "jdg.environmental.bdo", "priority": 1902,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_update_deadline_days": 30,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "BDO — aktualizacja wpisu w ciągu 30 dni od zmiany",
    "_legal_basis": "Art. 53 Ustawy o odpadach",
    "_warnings": [sprintf("[BDO] AKTUALIZACJA WPISU — zmiana danych: %s. Masz 30 dni od zmiany na aktualizację w BDO. Opłata za zmianę: 50 PLN.", [change_type])]
} {
    input.business.bdo_registered == true
    bdo_data_changed := object.get(input.business, "bdo_data_changed", false)
    bdo_data_changed == true
    change_type := object.get(input.business, "bdo_change_type", "dane podstawowe")
}

# P1903: bdo_de_registration — Wyrejestrowanie z BDO
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.de_registration",
    "package": "jdg.environmental.bdo", "priority": 1903,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_deregistration_required": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "BDO — wyrejestruj po zaprzestaniu wytwarzania odpadów",
    "_legal_basis": "Art. 55 Ustawy o odpadach",
    "_warnings": ["[BDO] WYREJESTROWANIE — zaprzestano wytwarzania odpadów. Złóż wniosek o wykreślenie z BDO w ciągu 30 dni. Zachowaj kopię potwierdzenia na 5 lat."]
} {
    input.business.produces_waste == false
    input.business.bdo_registered == true
    object.get(input.business, "bdo_deregistration_filed", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1904-P1908: EWC Codes — Europejski Katalog Odpadów                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1904: ewc_code_validation — Walidacja kodów EWC
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.ewc_code_validation",
    "package": "jdg.environmental.bdo", "priority": 1904,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_ewc_code_required": true, "bdo_ewc_valid": is_valid,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Kod EWC %s — walidacja formatu (XX XX XX)", [ewc_code]),
    "_legal_basis": "Rozporządzenie ws. katalogu odpadów (Dz.U. 2020 poz. 10)",
    "_warnings": [sprintf("[BDO] KOD EWC %s — %s. Katalog odpadów: grupy 01-20. Kod niebezpieczny = * przy kodzie.", [ewc_code, validation_msg])]
} {
    input.business.waste_generated_this_quarter > 0
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    ewc_code != ""
    is_valid = regex.match("\\d{2} \\d{2} \\d{2}\\*?", ewc_code)
    validation_msg := bdo_validation_msg(is_valid)
}

# P1905: ewc_hazardous_waste — Odpady niebezpieczne (*) — zaostrzone wymogi
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.ewc_hazardous",
    "package": "jdg.environmental.bdo", "priority": 1905,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_hazardous_waste": true, "bdo_hazardous_extra_requirements": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Odpady niebezpieczne EWC %s — zezwolenie na przetwarzanie WYMAGANE!", [ewc_code]),
    "_legal_basis": "Art. 41-42 Ustawy o odpadach, Rozp. REACH (WE 1907/2006)",
    "_warnings": [sprintf("[BDO] ODPADY NIEBEZPIECZNE — EWC %s: %s ton. Wymagane: zezwolenie na przetwarzanie, karta charakterystyki, ADR dla transportu, magazynowanie ≤3 lat.", [ewc_code, tonnage])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    contains(ewc_code, "*") == true
    tonnage := object.get(input.invoice, "bdo_waste_tonnes", 0)
}

# P1906: ewc_medical_waste — Odpady medyczne — wymogi szczególne
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.ewc_medical",
    "package": "jdg.environmental.bdo", "priority": 1906,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_medical_waste": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Odpady medyczne grupy 18 — unieszkodliwianie przez specjalistyczną firmę!",
    "_legal_basis": "Art. 22-26 Ustawy o odpadach, Rozp. MZ ws. postępowania z odpadami medycznymi",
    "_warnings": [sprintf("[BDO] ODPADY MEDYCZNE — EWC %s. Zakaz magazynowania >30 dni. Obowiązek unieszkodliwiania przez uprawnionego odbiorcę. Dokumentacja: karta przekazania + faktura!", [ewc_code])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    startswith(ewc_code, "18 ") == true
}

# P1907: ewc_construction_waste — Grupa 17 — odpady budowlane
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.ewc_construction",
    "package": "jdg.environmental.bdo", "priority": 1907,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_construction_waste": true, "bdo_segregation_required": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 101a Ustawy o odpadach (segregacja odpadów budowlanych od 2025)",
    "_warnings": [sprintf("[BDO] ODPADY BUDOWLANE — EWC %s. OBOWIĄZKOWA segregacja na frakcje: drewno, metale, szkło, tworzywa, gips, odpady mineralne (od 2025).", [ewc_code])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    startswith(ewc_code, "17 ") == true
}

# P1908: ewc_packaging_waste — Grupa 15 — odpady opakowaniowe
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.ewc_packaging",
    "package": "jdg.environmental.bdo", "priority": 1908,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_packaging_recycling_level": achieved_pct,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Odpady opakowaniowe — recykling %.0f%% (cel: 60%%)", [achieved_pct]),
    "_legal_basis": "Ustawa o gospodarce opakowaniami i odpadami opakowaniowymi, Dyrektywa PPWR 2025/40",
    "_warnings": [sprintf("[BDO] ODPADY OPAKOWANIOWE — poziom recyklingu %.0f%% (wymagane 60%%). %s. Sprawozdanie roczne do 15 marca.", [achieved_pct, status])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    startswith(ewc_code, "15 01") == true
    achieved_pct := object.get(input.business, "packaging_recycling_achieved_pct", 0)
    status := bdo_packaging_status(achieved_pct)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1909-P1913: Waste Ledger, KPO, Transport                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1909: bdo_waste_ledger_quarterly_deadline — Ewidencja kwartalna — terminy
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.ledger_quarterly_deadline",
    "package": "jdg.environmental.bdo", "priority": 1909,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_ledger_deadline": deadline,
    "bdo_quarter": quarter,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("BDO — kwartalna ewidencja Q%d. Termin: %s", [quarter, deadline]),
    "_legal_basis": "Art. 66-67 Ustawy o odpadach",
    "_warnings": [sprintf("[BDO] EWIDENCJA KWARTALNA Q%d — termin: %s. Ilość odpadów: %.2f ton (%d kart przekazania). Złóż elektronicznie w BDO!", [quarter, deadline, tonnage, kpo_count])]
} {
    input.business.bdo_registered == true
    tonnage := object.get(input.business, "waste_generated_this_quarter", 0)
    tonnage > 0
    kpo_count := object.get(input.business, "kpo_count_this_quarter", 0)
    month := object.get(input, "evaluation_month", 4)
    quarter := bdo_quarter(month)
    deadline := bdo_quarter_deadline(quarter)
}

# P1910: bdo_annual_report — Roczne sprawozdanie BDO
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.annual_report",
    "package": "jdg.environmental.bdo", "priority": 1910,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_annual_report_deadline": "15 marca",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("BDO — roczne sprawozdanie za %d. Termin: 15 marca %d.", [report_year, report_year + 1]),
    "_legal_basis": "Art. 75 Ustawy o odpadach",
    "_warnings": [sprintf("[BDO] SPRAWOZDANIE ROCZNE za %d — złóż do 15 marca %d. Zawiera: masę odpadów wg EWC, sposób zagospodarowania, poziom recyklingu.", [report_year, report_year + 1])]
} {
    input.business.bdo_registered == true
    input.calendar.month == 2
    input.calendar.day_of_month >= 15
    report_year := object.get(input.calendar, "year", 2026) - 1
    object.get(input.business, "bdo_annual_report_filed", false) == false
}

# P1911: bdo_kpo_electronic — Karta Przekazania Odpadów — obowiązek elektroniczny
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.kpo_electronic",
    "package": "jdg.environmental.bdo", "priority": 1911,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_kpo_electronic_required": true,
    "bdo_kpo_signature_required": "PODPIS_ELEKTRONICZNY_LUB_PROFIL_ZAUFANY",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KPO — brak elektronicznego potwierdzenia odbiorcy odpadów!",
    "_legal_basis": "Art. 67 Ustawy o odpadach, Rozp. ws. BDO",
    "_warnings": [sprintf("[BDO] KPO ELEKTRONICZNA — %d kart przekazania bez potwierdzenia odbiorcy. KPO MUSI być potwierdzona elektronicznie przez odbiorcę w ciągu 7 dni!", [unconfirmed_count])]
} {
    input.business.waste_transported == true
    unconfirmed_count := object.get(input.business, "bdo_kpo_unconfirmed_count", 0)
    unconfirmed_count > 0
}

# P1912: bdo_transport_permit — Zezwolenie na transport odpadów
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.transport_permit",
    "package": "jdg.environmental.bdo", "priority": 1912,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_transport_permit_required": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Transport odpadów bez zezwolenia — wymagane zezwolenie/zapis w BDO!",
    "_legal_basis": "Art. 232-234 Ustawy o odpadach",
    "_warnings": [sprintf("[BDO] TRANSPORT ODPADÓW — %s. Wpis do BDO jako transportujący + zezwolenie starosty. ADR dla odpadów niebezpiecznych. Numer rejestracyjny pojazdu w KPO.", [transport_type])]
} {
    input.business.transports_waste == true
    object.get(input.business, "bdo_transport_permit_valid", false) == false
    is_hazardous := object.get(input.business, "transports_hazardous_waste", false)
    transport_type := bdo_transport_type(is_hazardous)
}

# P1913: bdo_storage_limit — Limit magazynowania odpadów (3 lata)
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.storage_limit",
    "package": "jdg.environmental.bdo", "priority": 1913,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_storage_exceeded": true,
    "bdo_storage_max_years": 3,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Odpady magazynowane %d lat — przekroczony limit 3 lat! Przekaż natychmiast!", [storage_years]),
    "_legal_basis": "Art. 25 Ustawy o odpadach",
    "_warnings": [sprintf("[BDO] LIMIT MAGAZYNOWANIA — odpady EWC %s magazynowane %d lat (max 3). Przekaż do unieszkodliwienia/odzysku natychmiast! Kara: 5 000 – 100 000 PLN.", [ewc_code, storage_years])]
} {
    storage_years := object.get(input.business, "waste_storage_years", 0)
    storage_years >= 3
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1914-P1917: Cross-border waste, DGO, BAT, Sanctions                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1914: bdo_cross_border_shipment — Transgraniczne przemieszczanie odpadów
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.cross_border_shipment",
    "package": "jdg.environmental.bdo", "priority": 1914,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_cross_border_notification": procedure,
    "bdo_gios_consent_required": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Transgraniczne przemieszczanie odpadów do/z %s — procedura %s!", [country, procedure]),
    "_legal_basis": "Rozp. WE 1013/2006, Ustawa o międzynarodowym przemieszczaniu odpadów",
    "_warnings": [sprintf("[BDO] TRANSGRANICZNE — EWC %s → %s. Procedura: %s. Zgoda GIOŚ + krajowe punkty kontaktowe + gwarancja finansowa + zgoda kraju odbioru!", [ewc_code, country, procedure])]
} {
    destination_country := object.get(input.invoice, "waste_destination_country", "")
    destination_country != ""
    destination_country != "PL"
    country := destination_country
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    is_green_list := object.get(input.invoice, "waste_green_list", false)
    is_hazardous := contains(ewc_code, "*")
    procedure := bdo_cross_border_procedure(is_hazardous, is_green_list)
}

# P1915: bdo_dgo_permit — Decyzja o gospodarowaniu odpadami (DGO)
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.dgo_permit",
    "package": "jdg.environmental.bdo", "priority": 1915,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_dgo_required": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak DGO — zezwolenie na zbieranie/przetwarzanie odpadów!",
    "_legal_basis": "Art. 41-42 Ustawy o odpadach",
    "_warnings": [sprintf("[BDO] DGO WYMAGANE — %s. Działalność: %s. Bez DGO: kara do 100 000 PLN i wstrzymanie działalności!", [ewc_code, activity_type])]
} {
    input.business.processes_waste == true
    object.get(input.business, "dgo_permit_valid", false) == false
    ewc_code := object.get(input.business, "primary_ewc_code", "brak")
    activity_type := object.get(input.business, "waste_activity_type", "zbieranie/przetwarzanie")
}

# P1916: bdo_bat_conclusions — Konkluzje BAT (najlepsze dostępne techniki)
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.bat_conclusions",
    "package": "jdg.environmental.bdo", "priority": 1916,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_bat_required": true,
    "bdo_bat_deadline_years": 4,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Konkluzje BAT — dostosowanie w ciągu 4 lat od publikacji. Termin: %d.", [bat_deadline_year]),
    "_legal_basis": "Dyrektywa IED 2010/75/UE, Rozp. ws. pozwolenia zintegrowanego",
    "_warnings": [sprintf("[BDO] KONKLUZJE BAT — %s. Dostosuj instalację do konkluzji BAT do %d. Przegląd pozwolenia zintegrowanego co 4 lata.", [bat_sector, bat_deadline_year])]
} {
    input.business.ippc_installation == true
    bat_sector := object.get(input.business, "bat_sector", "odpady")
    bat_pub_year := object.get(input.business, "bat_published_year", 2022)
    bat_deadline_year := bat_pub_year + 4
    bat_deadline_year > object.get(input.calendar, "year", 2026)
}

# P1917: bdo_sanction_administrative — Sankcje administracyjne BDO
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.sanction_administrative",
    "package": "jdg.environmental.bdo", "priority": 1917,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_sanction_applied": true,
    "bdo_sanction_amount_pln": sanction_amount,
    "bdo_sanction_type": sanction_type,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Sankcja BDO: %s — %.0f PLN!", [sanction_type, sanction_amount]),
    "_legal_basis": "Art. 194-204 Ustawy o odpadach",
    "_warnings": [sprintf("[BDO] SANKCJA BDO — %s: %.0f PLN. %s. Odwołanie do SKO w ciągu 14 dni.", [sanction_type, sanction_amount, sanction_detail])]
} {
    violation_code := object.get(input.business, "bdo_violation_code", "")
    violation_code != ""

    sanction_amount := object.get(bdo_sanction_amounts, violation_code, 0)
    sanction_amount > 0
    sanction_type := object.get(bdo_sanction_types, violation_code, "")
    sanction_detail := object.get(bdo_sanction_details, violation_code, "")
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1918-P1921: WEEE, Batteries, Plastic, Extended Producer Responsibility  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1918: bdo_weee_compliance — ZSEiE (zużyty sprzęt elektryczny i elektroniczny)
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.weee_compliance",
    "package": "jdg.environmental.bdo", "priority": 1918,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_weee_sold_kg": weight_kg,
    "bdo_weee_registered_in_bdo": is_registered,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("WEEE — sprzedaż sprzętu elektrycznego %.1f kg. Rejestracja BDO: %s", [weight_kg, registered_status]),
    "_legal_basis": "Ustawa o ZSEiE (Dz.U. 2023 poz. 1322), Dyrektywa WEEE 2012/19/UE",
    "_warnings": [sprintf("[BDO] WEEE/ZSEiE — sprzedano %.1f kg sprzętu. %s. Poziom zbiórki: %.0f%%. Rejestracja w oddzielnym rejestrze ZSEiE w BDO.", [weight_kg, registered_status, collection_pct])]
} {
    input.business.sells_electronics == true
    weight_kg := object.get(input.business, "weee_sold_kg", 0)
    weight_kg > 0
    is_registered := object.get(input.business, "weee_registered_in_bdo", false)
    registered_status := bdo_registration_status(is_registered)
    collection_pct := object.get(input.business, "weee_collection_pct", 0)
}

# P1919: bdo_battery_compliance — Baterie i akumulatory
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.battery_compliance",
    "package": "jdg.environmental.bdo", "priority": 1919,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_battery_mass_kg": mass_kg,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Baterie — wprowadzono %.1f kg. Obowiązek zbiórki: %.0f%%.", [mass_kg, target_pct]),
    "_legal_basis": "Ustawa o bateriach i akumulatorach, Rozp. UE 2023/1542",
    "_warnings": [sprintf("[BDO] BATERIE — %.1f kg wprowadzonych. Cel zbiórki: %.0f%% (wzrasta do 73%% w 2030). Opłata produktowa przy nieosiągnięciu celu. Sprawozdanie roczne.", [mass_kg, target_pct])]
} {
    input.business.introduces_batteries == true
    mass_kg := object.get(input.business, "battery_mass_introduced_kg", 0)
    mass_kg > 0
    target_pct := object.get(object.get(data.thresholds, "jdg", {}), "battery_collection_target_pct", 45)
}

# P1920: bdo_sup_plastic — Single-Use Plastics (SUP) — rozszerzona odpowiedzialność
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.sup_extended",
    "package": "jdg.environmental.bdo", "priority": 1920,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_sup_extended_producer": true,
    "bdo_sup_epr_fee_pln": epr_fee,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("SUP EPR — opłata rozszerzonej odpowiedzialności producenta: %.2f PLN", [epr_fee]),
    "_legal_basis": "Ustawa SUP (Dz.U. 2023 poz. 877) + Dyrektywa SUP 2019/904 + Rozp. PPWR 2025/40",
    "_warnings": [sprintf("[BDO] SUP ROZSZERZONA ODPOWIEDZIALNOŚĆ — %.0f kg plastiku jednorazowego. Opłata EPR: %.2f PLN. Od 2025: zakaz niektórych produktów SUP (patyczki, słomki, sztućce).", [plastic_kg, epr_fee])]
} {
    input.business.introduces_sup_products == true
    plastic_kg := object.get(input.business, "sup_plastic_kg", 0)
    plastic_kg > 0
    epr_rate := object.get(object.get(data.thresholds, "jdg", {}), "sup_epr_rate_per_kg", 0.80)
    epr_fee := floor(plastic_kg * epr_rate * 100) / 100
}

# P1921: bdo_remediation_obligation — Obowiązek remediacji szkód w środowisku
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.remediation",
    "package": "jdg.environmental.bdo", "priority": 1921,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bdo_remediation_required": true,
    "bdo_remediation_deadline_days": 30,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Szkoda w środowisku — obowiązek remediacji w ciągu 30 dni!",
    "_legal_basis": "Ustawa o zapobieganiu szkodom w środowisku i ich naprawie (Dz.U. 2020 poz. 2187)",
    "_warnings": [sprintf("[BDO] SZKODA W ŚRODOWISKU — %s. Natychmiastowe działania zapobiegawcze + zgłoszenie do RDOŚ w ciągu 30 dni. Koszty remediacji: szacunkowo %.0f PLN. Odpowiedzialność niezależnie od winy!", [damage_type, estimated_cost])]
} {
    input.business.environmental_damage_detected == true
    damage_type := object.get(input.business, "environmental_damage_type", "zanieczyszczenie gleby")
    estimated_cost := object.get(input.business, "remediation_estimated_cost_pln", 0)
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.environmental.bdo.fallback",
    "package": "jdg.environmental.bdo", "priority": 1999,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)",
    "_warnings": ["[BDO] Gospodarka odpadami — brak naruszeń. Ewidencja BDO prowadzona prawidłowo."]
} { true }
