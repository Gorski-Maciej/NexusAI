# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise AML/CFT — P1925-P1946
# Legal basis: Ustawa AML z 01.03.2018; AMLD6; Rozp. UE 2015/847; KKS Art. 299.
# Public contract: jdg.compliance.aml.no_match, P1925-P1946 and fallback.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.compliance.aml

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.compliance.aml.no_match",
    "package": "jdg.compliance.aml",
    "priority": 1947
}

profile(payload) = object.get(payload, "jdg_entrepreneur", {})
invoice(payload) = object.get(payload, "invoice", {})
vendor(payload) = object.get(payload, "vendor", {})

decision(rule_id, priority, routing, reason, legal_basis, warning) = {
    "matched": true,
    "rule_id": rule_id,
    "package": "jdg.compliance.aml",
    "priority": priority,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": reason,
    "_legal_basis": legal_basis,
    "_warnings": [warning]
}

obliged_pkds := {"69.20.Z", "66.19.Z", "68.31.Z", "64.99.Z", "64.19.Z", "64.20.Z", "66.12.Z", "66.22.Z", "68.10.Z", "68.20.Z", "41.10.Z", "45.11.Z", "45.19.Z", "47.78.Z", "64.92.Z", "65.12.Z", "66.11.Z"}
high_risk_pkds := {"64.19.Z", "64.99.Z", "47.78.Z"}
cash_intensive_pkds := {"41.10.Z", "45.11.Z", "45.19.Z"}
company_types := {"SP_ZOO", "SA", "SP_KOMANDYTOWA", "SP_JAWNA", "SP_PARTNERSKA"}

pkd_sector(pkd) = "Usługi finansowe/księgowe" {
    pkd in {"69.20.Z", "66.19.Z"}
} else = "Pośrednictwo nieruchomości" {
    pkd in {"68.31.Z", "68.10.Z"}
} else = "Handel dziełami sztuki" {
    pkd == "47.78.Z"
} else = "Obrót kryptoaktywami" {
    pkd in {"64.19.Z", "64.99.Z"}
} else = "Inne instytucje obowiązane"

pkd_risk(pkd) = "HIGH" {
    pkd in high_risk_pkds
} else = "MEDIUM" {
    pkd in cash_intensive_pkds
} else = "STANDARD"

boolean_points(value, points) = points {
    value
} else = 0

amount_points(amount) = 2 {
    amount >= 50000
} else = 0

customer_score(payload) = boolean_points(object.get(invoice(payload), "is_cash_payment", false), 3) +
    boolean_points(object.get(vendor(payload), "country", "PL") != "PL", 2) +
    boolean_points(object.get(vendor(payload), "is_pep", false), 5) +
    boolean_points(object.get(vendor(payload), "is_high_risk_jurisdiction", false), 4) +
    amount_points(object.get(invoice(payload), "amount_gross", 0))

customer_risk(score) = "LOW" {
    score <= 2
} else = "MEDIUM" {
    score <= 6
} else = "HIGH"

dd_type(risk) = "SDD (uproszczona)" {
    risk == "LOW"
} else = "CDD (standardowa)" {
    risk == "MEDIUM"
} else = "EDD (wzmocniona — Art. 43 AML)"

aml_1925 := decision(
    "jdg.compliance.aml.obliged_entity_pkd", 1925, "TRIAGE_QUEUE",
    sprintf("AML — podmiot obowiązany: PKD %s. Poziom ryzyka: %s", [object.get(profile(input), "pkd_main", ""), pkd_risk(object.get(profile(input), "pkd_main", ""))]),
    "Art. 2 ust. 1 Ustawy AML, Art. 83-89 Ustawy o CBDD",
    sprintf("[AML] PODMIOT OBOWIĄZANY — PKD %s (%s).", [object.get(profile(input), "pkd_main", ""), pkd_sector(object.get(profile(input), "pkd_main", ""))])
) {
    object.get(profile(input), "pkd_main", "") in obliged_pkds
}

aml_1926 := decision(
    "jdg.compliance.aml.risk_assessment_customer", 1926, "TRIAGE_QUEUE",
    sprintf("AML — ocena ryzyka klienta: %s. CDD: %s", [customer_risk(customer_score(input)), dd_type(customer_risk(customer_score(input)))]),
    "Art. 33-43 Ustawy AML",
    sprintf("[AML] OCENA RYZYKA KLIENTA — %s.", [customer_risk(customer_score(input))])
) {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(invoice(input), "amount_gross", 0) >= 15000
}

aml_1927 := decision("jdg.compliance.aml.pep_screening", 1927, "BLOCK_AND_ALERT", "PEP wykryty — EDD wymagane!", "Art. 43-46 Ustawy AML", "[AML] PEP — EDD obowiązkowe.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(vendor(input), "is_pep", false)
}

aml_1928 := decision("jdg.compliance.aml.high_risk_country", 1928, "BLOCK_AND_ALERT", sprintf("Kraj wysokiego ryzyka AML — %s", [object.get(vendor(input), "country", "XX")]), "Art. 43 ust. 5 Ustawy AML", "[AML] KRAJ WYSOKIEGO RYZYKA — EDD obowiązkowe.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(vendor(input), "is_high_risk_jurisdiction", false)
}

aml_1929 := decision("jdg.compliance.aml.transaction_cash_threshold", 1929, "TRIAGE_QUEUE", "AML — gotówka powyżej 10 000 EUR.", "Art. 72 Ustawy AML", "[AML] PRÓG GOTÓWKOWY — zarejestruj transakcję.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(invoice(input), "is_cash_payment", false)
    object.get(invoice(input), "amount_gross", 0) >= 45000
}

aml_1930 := decision("jdg.compliance.aml.transaction_structuring", 1930, "BLOCK_AND_ALERT", "AML — wykryto strukturyzację transakcji.", "Art. 86 Ustawy AML", "[AML] STRUKTURYZACJA TRANSAKCJI — zgłoś STR do GIIF.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(vendor(input), "similar_transactions_30d", 0) >= 5
}

aml_1931 := decision("jdg.compliance.aml.round_trip_transaction", 1931, "BLOCK_AND_ALERT", "AML — wykryto round-trip.", "Art. 299 KKS", "[AML] ROUND-TRIP TRANSAKCJA — wstrzymaj i przeanalizuj.") {
    object.get(invoice(input), "direction", "") == "SALE"
    object.get(vendor(input), "round_trip_counterparty", false)
}

aml_1932 := decision("jdg.compliance.aml.ubo_verification", 1932, "TRIAGE_QUEUE", "UBO — wymagana weryfikacja beneficjenta rzeczywistego.", "Art. 61-79 Ustawy o CBDD", "[AML] BENEFICJENT RZECZYWISTY — zweryfikuj CBDD.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(invoice(input), "amount_gross", 0) >= 15000
}

aml_1933 := decision("jdg.compliance.aml.unusual_pattern", 1933, "TRIAGE_QUEUE", "AML — wykryto nietypowy wzorzec.", "Art. 83-86 Ustawy AML", "[AML] NIETYPOWY WZORZEC — udokumentuj analizę.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(invoice(input), "aml_unusual_pattern_flag", false)
}

aml_1934 := decision("jdg.compliance.aml.str_filing_obligation", 1934, "BLOCK_AND_ALERT", "AML — STR do GIIF w ciągu 48h.", "Art. 83-86 Ustawy AML", "[AML] STR/SAR DO GIIF — nie informuj klienta.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(invoice(input), "is_suspicious_transaction", false)
}

aml_1935 := decision("jdg.compliance.aml.str_not_filed_penalty", 1935, "BLOCK_AND_ALERT", "AML — brak zgłoszenia STR.", "Art. 147-153 Ustawy AML", "[AML] BRAK STR — kara do 5 mln PLN.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(profile(input), "aml_pending_suspicious_no_str", false)
}

aml_1936 := decision("jdg.compliance.aml.tipping_off", 1936, "BLOCK_AND_ALERT", "AML — naruszenie zakazu tipping-off.", "Art. 86 Ustawy AML", "[AML] TIPPING-OFF — zakaz informowania klienta o STR.") {
    object.get(profile(input), "aml_str_filed", false)
    object.get(invoice(input), "client_notified_of_str", false)
}

aml_1937 := decision("jdg.compliance.aml.retention_obligation", 1937, "TRIAGE_QUEUE", "AML — retencja dokumentacji przez 5 lat.", "Art. 48 Ustawy AML", "[AML] RETENCJA AML — przechowuj CDD/EDD przez 5 lat.") {
    object.get(profile(input), "is_aml_obliged", false)
}

aml_1938 := decision("jdg.compliance.aml.employee_training", 1938, "TRIAGE_QUEUE", "AML — szkolenie pracowników wymagane.", "Art. 50 Ustawy AML", "[AML] SZKOLENIA AML — częstotliwość co 12 miesięcy.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(object.get(input, "employment", {}), "has_employees", false)
}

aml_1939 := decision("jdg.compliance.aml.cbdd_registration", 1939, "BLOCK_AND_ALERT", "CBDD — brak zgłoszenia beneficjentów.", "Art. 58-79 Ustawy AML", "[AML] CBDD — zgłoszenie w ciągu 7 dni.") {
    not object.get(profile(input), "cbdd_registered", false)
    object.get(profile(input), "company_type", "") in company_types
}

aml_1940 := decision("jdg.compliance.aml.cbdd_update", 1940, "TRIAGE_QUEUE", "CBDD — aktualizacja wymagana.", "Art. 63 Ustawy o CBDD", "[AML] CBDD — aktualizacja w ciągu 7 dni.") {
    object.get(profile(input), "cbdd_registered", false)
    object.get(profile(input), "cbdd_data_changed", false)
}

aml_1941 := decision("jdg.compliance.aml.cbdd_vendor_verification", 1941, "TRIAGE_QUEUE", "CBDD — weryfikacja kontrahenta.", "Art. 61-66 Ustawy o CBDD", "[AML] CBDD KONTRAHENTA — sprawdź status.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(invoice(input), "amount_gross", 0) >= 15000
}

aml_1942 := decision("jdg.compliance.aml.cbdd_discrepancy_penalty", 1942, "BLOCK_AND_ALERT", "CBDD — rozbieżność danych.", "Art. 68 Ustawy o CBDD", "[AML] CBDD ROZBIEŻNOŚĆ — złóż aktualizację.") {
    object.get(profile(input), "cbdd_registered", false)
    object.get(profile(input), "cbdd_discrepancy_detected", false)
}

aml_1943 := decision("jdg.compliance.aml.crypto_travel_rule", 1943, "TRIAGE_QUEUE", "Travel Rule — przekaż dane nadawcy i odbiorcy.", "Rozp. UE 2023/1113", "[AML] TRAVEL RULE — transfer krypto przekracza próg.") {
    object.get(profile(input), "is_crypto_exchange", false)
    object.get(invoice(input), "crypto_transfer", false)
    object.get(invoice(input), "crypto_amount_eur", 0) >= 1000
}

aml_1944 := decision("jdg.compliance.aml.sanctions_screening", 1944, "BLOCK_AND_ALERT", "SANKCJE — wstrzymaj transakcję.", "Rozp. UE 269/2014; Rozp. UE 765/2006", "[AML] SANKCJE MIĘDZYNARODOWE — wstrzymaj transakcję.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(vendor(input), "sanctions_list_match", false)
}

aml_1945 := decision("jdg.compliance.aml.internal_procedure_gap", 1945, "TRIAGE_QUEUE", "AML — luka w procedurze wewnętrznej.", "Art. 50-52 Ustawy AML", "[AML] PROCEDURA WEWNĘTRZNA — uzupełnij brakujący element.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(profile(input), "aml_procedure_complete", true) == false
}

aml_1946 := decision("jdg.compliance.aml.audit_obligation", 1946, "TRIAGE_QUEUE", "AML — wymagany audyt roczny.", "Art. 50 ust. 3 Ustawy AML", "[AML] AUDYT ROCZNY — wykonaj audyt AML.") {
    object.get(profile(input), "is_aml_obliged", false)
    object.get(profile(input), "aml_last_audit_date", "nigdy") == "nigdy"
}

fallback := decision("jdg.compliance.aml.fallback", 1998, "", "", "Ustawa AML", "[AML] AML compliance — brak przesłanek do zgłoszenia.")

decide := aml_1925 { object.get(profile(input), "pkd_main", "") in obliged_pkds }
else := aml_1926 { object.get(profile(input), "is_aml_obliged", false); object.get(invoice(input), "amount_gross", 0) >= 15000 }
else := aml_1927 { object.get(profile(input), "is_aml_obliged", false); object.get(vendor(input), "is_pep", false) }
else := aml_1928 { object.get(profile(input), "is_aml_obliged", false); object.get(vendor(input), "is_high_risk_jurisdiction", false) }
else := aml_1929 { object.get(profile(input), "is_aml_obliged", false); object.get(invoice(input), "is_cash_payment", false); object.get(invoice(input), "amount_gross", 0) >= 45000 }
else := aml_1930 { object.get(profile(input), "is_aml_obliged", false); object.get(vendor(input), "similar_transactions_30d", 0) >= 5 }
else := aml_1931 { object.get(invoice(input), "direction", "") == "SALE"; object.get(vendor(input), "round_trip_counterparty", false) }
else := aml_1932 { object.get(profile(input), "is_aml_obliged", false); object.get(invoice(input), "amount_gross", 0) >= 15000 }
else := aml_1933 { object.get(profile(input), "is_aml_obliged", false); object.get(invoice(input), "aml_unusual_pattern_flag", false) }
else := aml_1934 { object.get(profile(input), "is_aml_obliged", false); object.get(invoice(input), "is_suspicious_transaction", false) }
else := aml_1935 { object.get(profile(input), "is_aml_obliged", false); object.get(profile(input), "aml_pending_suspicious_no_str", false) }
else := aml_1936 { object.get(profile(input), "aml_str_filed", false); object.get(invoice(input), "client_notified_of_str", false) }
else := aml_1937 { object.get(profile(input), "is_aml_obliged", false) }
else := aml_1938 { object.get(profile(input), "is_aml_obliged", false); object.get(object.get(input, "employment", {}), "has_employees", false) }
else := aml_1939 { not object.get(profile(input), "cbdd_registered", false); object.get(profile(input), "company_type", "") in company_types }
else := aml_1940 { object.get(profile(input), "cbdd_registered", false); object.get(profile(input), "cbdd_data_changed", false) }
else := aml_1941 { object.get(profile(input), "is_aml_obliged", false); object.get(invoice(input), "amount_gross", 0) >= 15000 }
else := aml_1942 { object.get(profile(input), "cbdd_registered", false); object.get(profile(input), "cbdd_discrepancy_detected", false) }
else := aml_1943 { object.get(profile(input), "is_crypto_exchange", false); object.get(invoice(input), "crypto_transfer", false); object.get(invoice(input), "crypto_amount_eur", 0) >= 1000 }
else := aml_1944 { object.get(profile(input), "is_aml_obliged", false); object.get(vendor(input), "sanctions_list_match", false) }
else := aml_1945 { object.get(profile(input), "is_aml_obliged", false); object.get(profile(input), "aml_procedure_complete", true) == false }
else := aml_1946 { object.get(profile(input), "is_aml_obliged", false); object.get(profile(input), "aml_last_audit_date", "nigdy") == "nigdy" }
else := fallback
