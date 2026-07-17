# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise Policies — AML: Anti-Money Laundering (P1925-P1946)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: AML Enterprise — Anti-Money Laundering & Counter-Terrorist Financing for JDG
# description: |
#   Rozbudowany pakiet Enterprise dla AML/CFT w JDG.
#   Pokrycie: ocena ryzyka AML (niski/średni/wysoki), CDD (customer due diligence),
#   EDD (enhanced due diligence), PEP (politically exposed persons), monitoring
#   transakcji, raportowanie STR/SAR do GIIF, CBDD (Centralny Rejestr Beneficjentów
#   Rzeczywistych), szkolenia AML, sankcje KNF i karne.
#   Uzupełnia P1731 w jdg.compliance (podstawowe sprawdzenie PKD).
# architecture: Multi-Pass Enterprise (ADR-001), sub-package of jdg.compliance
# legal_basis: Ustawa AML z 01.03.2018 (Dz.U. 2025 poz. 567), Dyrektywa AMLD6,
#   Rozp. UE 2015/847 (WTR), Ustawa o CBDD, KKS Art. 299
# package: jdg.compliance.aml
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.compliance.aml

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.compliance.aml.no_match",
    "package": "jdg.compliance.aml",
    "priority": 1947
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1925-P1928: AML Risk Assessment — Ocena ryzyka JDG                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1925: aml_obliged_entity_pkd_check — Podmiot obowiązany wg PKD
decide := {
    "matched": true, "rule_id": "jdg.compliance.aml.obliged_entity_pkd",
    "package": "jdg.compliance.aml", "priority": 1925,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_obliged_entity": true, "aml_pkd_code": pkd,
    "aml_risk_level": risk_level,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML — podmiot obowiązany: PKD %s. Poziom ryzyka: %s", [pkd, risk_level]),
    "_legal_basis": "Art. 2 ust. 1 Ustawy AML, Art. 83-89 Ustawy o CBDD",
    "_warnings": [sprintf("[AML] PODMIOT OBOWIĄZANY — PKD %s (%s). Poziom ryzyka: %s. Obowiązki: procedura AML, CDD, raportowanie STR, szkolenia, audyt.", [pkd, sector, risk_level])]
} {
    pkd := object.get(input.jdg_entrepreneur, "pkd_main", "")
    aml_obliged_pkd := {"69.20.Z", "66.19.Z", "68.31.Z", "64.99.Z", "64.19.Z",
        "64.20.Z", "66.12.Z", "66.22.Z", "68.10.Z", "68.20.Z", "41.10.Z",
        "45.11.Z", "45.19.Z", "47.78.Z", "64.92.Z", "65.12.Z", "66.11.Z"}
    pkd in aml_obliged_pkd

    sector = "Usługi finansowe/księgowe" { pkd in {"69.20.Z", "66.19.Z"} }
    sector = "Pośrednictwo nieruchomości" { pkd in {"68.31.Z", "68.10.Z"} }
    sector = "Handel dziełami sztuki" { pkd in {"47.78.Z"} }
    sector = "Obrót kryptoaktywami" { pkd in {"64.19.Z", "64.99.Z"} }
    sector = "Inne instytucje obowiązane" { pkd in aml_obliged_pkd }

    cash_intensive := pkd in {"41.10.Z", "45.11.Z", "45.19.Z"}
    high_risk_sectors := {"64.19.Z", "64.99.Z", "47.78.Z"}
    risk_level = "HIGH" { pkd in high_risk_sectors }
    risk_level = "MEDIUM" { cash_intensive == true }
    risk_level = "STANDARD" { pkd in aml_obliged_pkd; not pkd in high_risk_sectors; not cash_intensive }
}

# P1926: aml_risk_assessment_customer — Ocena ryzyka klienta (CDD/EDD)
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.risk_assessment_customer",
    "package": "jdg.compliance.aml", "priority": 1926,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_customer_risk": customer_risk,
    "aml_due_diligence_type": dd_type,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML — ocena ryzyka klienta: %s. CDD: %s", [customer_risk, dd_type]),
    "_legal_basis": "Art. 33-43 Ustawy AML (środki bezpieczeństwa finansowego)",
    "_warnings": [sprintf("[AML] OCENA RYZYKA KLIENTA — %s. Typ CDD: %s. Transakcja %.2f PLN (%s). %s", [customer_risk, dd_type, amount, payment_method, dd_actions])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    amount := object.get(input.invoice, "amount_gross", 0)
    amount >= 15000

    is_cash := input.invoice.is_cash_payment == true
    is_cross_border := object.get(input.vendor, "country", "PL") != "PL"
    is_pep := object.get(input.vendor, "is_pep", false)
    is_high_risk_country := object.get(input.vendor, "is_high_risk_jurisdiction", false)

    # Sequential scoring — każdy kolejny krok dodaje punkty jeśli warunek spełniony
    s0 := 0
    s1 := s0 + 3 { is_cash == true }
    s1 = s0 { is_cash == false }
    s2 := s1 + 2 { is_cross_border == true }
    s2 = s1 { is_cross_border == false }
    s3 := s2 + 5 { is_pep == true }
    s3 = s2 { is_pep == false }
    s4 := s3 + 4 { is_high_risk_country == true }
    s4 = s3 { is_high_risk_country == false }
    s5 := s4 + 2 { amount >= 50000 }
    s5 = s4 { amount < 50000 }
    risk_score := s5

    customer_risk = "LOW" { risk_score <= 2 }
    customer_risk = "MEDIUM" { risk_score > 2; risk_score <= 6 }
    customer_risk = "HIGH" { risk_score > 6 }

    dd_type = "SDD (uproszczona)" { customer_risk == "LOW" }
    dd_type = "CDD (standardowa)" { customer_risk == "MEDIUM" }
    dd_type = "EDD (wzmocniona — Art. 43 AML)" { customer_risk == "HIGH" }

    payment_method = "gotówka" { is_cash == true }
    payment_method = "przelew" { is_cash == false }

    dd_actions = "Weryfikacja dokumentu tożsamości + oświadczenie" { dd_type == "SDD (uproszczona)" }
    dd_actions = "Kopia dokumentu + weryfikacja w rejestrach + oświadczenie o źródle" { dd_type == "CDD (standardowa)" }
    dd_actions = "PEŁNA WERYFIKACJA: dokument + rejestry + źródło majątku + zgoda kierownictwa + monitoring transakcji!" { dd_type == "EDD (wzmocniona — Art. 43 AML)" }
}

# P1927: aml_pep_screening — Weryfikacja PEP (osoba na eksponowanym stanowisku)
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.pep_screening",
    "package": "jdg.compliance.aml", "priority": 1927,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_pep_detected": true, "aml_pep_edd_required": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("PEP wykryty — %s. Wzmocnione środki bezpieczeństwa WYMAGANE!", [pep_name]),
    "_legal_basis": "Art. 2 ust. 2 pkt 11, Art. 43-46 Ustawy AML, Art. 20a AMLD5",
    "_warnings": [sprintf("[AML] PEP — %s (rola: %s). EDD OBOWIĄZKOWE: zgoda kierownictwa wyższego szczebla, ustalenie źródła majątku, wzmożone monitorowanie transakcji przez 12 mies. po zakończeniu funkcji.", [pep_name, pep_role])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    input.vendor.is_pep == true
    pep_name := object.get(input.vendor, "name", "Kontrahent")
    pep_role := object.get(input.vendor, "pep_role", "funkcja publiczna")
}

# P1928: aml_high_risk_country — Transakcja z krajem wysokiego ryzyka
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.high_risk_country",
    "package": "jdg.compliance.aml", "priority": 1928,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_high_risk_jurisdiction": true, "aml_edd_required": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Kraj wysokiego ryzyka AML — %s (lista FATF/GAFILAT)!", [country]),
    "_legal_basis": "Art. 43 ust. 5 Ustawy AML, Art. 9 AMLD4, Rekomendacja 19 FATF",
    "_warnings": [sprintf("[AML] KRAJ WYSOKIEGO RYZYKA — %s (kod: %s). EDD OBOWIĄZKOWE: pełna identyfikacja, źródło majątku, zgoda zarządu, monitoring transakcji + zgłoszenie do GIIF. FATF czarna/szara lista.", [country, country_code])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    input.vendor.is_high_risk_jurisdiction == true
    country := object.get(input.vendor, "country_name", "Nieznany kraj")
    country_code := object.get(input.vendor, "country", "XX")
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1929-P1933: Transaction Monitoring — Monitoring transakcji               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1929: aml_transaction_threshold_cash — Próg gotówkowy 10 000 EUR
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.transaction_cash_threshold",
    "package": "jdg.compliance.aml", "priority": 1929,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_cash_threshold_exceeded": true,
    "aml_cash_amount_eur": amount_eur,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML — gotówka %.0f EUR > 10 000 EUR. Obowiązek rejestracji!", [amount_eur]),
    "_legal_basis": "Art. 72 Ustawy AML, Rozp. UE 2018/1672 (kontrole gotówki)",
    "_warnings": [sprintf("[AML] PRÓG GOTÓWKOWY — %.0f EUR (>10k EUR). Zarejestruj transakcję + identyfikacja klienta + oświadczenie o źródle. Powyżej 15k EUR: obowiązek zgłoszenia do GIIF!", [amount_eur])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    input.invoice.is_cash_payment == true
    eur_pln := object.get(object.get(data.thresholds.jdg, "bounds", {}), "eur_pln", 4.50)
    amount_eur := floor(object.get(input.invoice, "amount_gross", 0) / eur_pln * 100) / 100
    amount_eur >= 10000
}

# P1930: aml_transaction_structuring — Strukturyzacja transakcji (smurfing)
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.transaction_structuring",
    "package": "jdg.compliance.aml", "priority": 1930,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_structuring_detected": true,
    "aml_similar_transactions": tx_count,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("AML — strukturyzacja! %d transakcji <10k EUR w ciągu 30 dni od tego samego klienta!", [tx_count]),
    "_legal_basis": "Art. 86 Ustawy AML, Rekomendacja 10 FATF (structuring/smurfing)",
    "_warnings": [sprintf("[AML] STRUKTURYZACJA TRANSAKCJI — %d przelewów od %s poniżej progu 10k EUR w 30 dni. Łącznie: %.0f EUR. ZGŁOŚ DO GIIF jako podejrzenie prania pieniędzy (STR)!", [tx_count, vendor_name, total_eur])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    tx_count := object.get(input.vendor, "similar_transactions_30d", 0)
    tx_count >= 5
    vendor_name := object.get(input.vendor, "name", "klient")
    eur_pln := object.get(object.get(data.thresholds.jdg, "bounds", {}), "eur_pln", 4.50)
    total_pln := object.get(input.vendor, "similar_transactions_total_30d", 0)
    total_eur := floor(total_pln / eur_pln * 100) / 100
}

# P1931: aml_round_trip_transaction — Transakcja round-trip (pranie przez fikcyjny obrót)
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.round_trip_transaction",
    "package": "jdg.compliance.aml", "priority": 1931,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_round_trip_detected": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("AML — round-trip: sprzedaż i zakup tej samej kwoty %.2f PLN z tym samym podmiotem %s!", [amount, vendor_name]),
    "_legal_basis": "Art. 299 KKS (pranie pieniędzy), Rekomendacja 10 FATF",
    "_warnings": [sprintf("[AML] ROUND-TRIP TRANSAKCJA — %.2f PLN sprzedaż + %.2f PLN zakup z %s. Podejrzenie fikcyjnego obrotu! NATYCHMIAST zgłoś STR do GIIF i wstrzymaj transakcję!", [amount, amount_back, vendor_name])]
} {
    input.invoice.direction == "SALE"
    input.vendor.round_trip_counterparty == true
    amount := object.get(input.invoice, "amount_gross", 0)
    amount_back := object.get(input.vendor, "round_trip_purchase_amount", 0)
    vendor_name := object.get(input.vendor, "name", "kontrahent")
    abs(amount - amount_back) < amount * 0.05
}

# P1932: aml_ubo_verification — Weryfikacja beneficjenta rzeczywistego (UBO)
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.ubo_verification",
    "package": "jdg.compliance.aml", "priority": 1932,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_ubo_verified": is_verified,
    "aml_ubo_discrepancy": discrepancy,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("UBO — weryfikacja beneficjenta rzeczywistego kontrahenta. CBDD: %s", [cbdd_status]),
    "_legal_basis": "Art. 61-79 Ustawy o CBDD, Art. 35 Ustawy AML, AMLD5",
    "_warnings": [sprintf("[AML] BENEFICJENT RZECZYWISTY — kontrahent: %s. CBDD: %s. %s. W przypadku rozbieżności >25%%: zgłoś do GIIF!", [vendor_name, cbdd_status, discrepancy_msg])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    input.invoice.amount_gross >= 15000
    vendor_name := object.get(input.vendor, "name", "kontrahent")
    cbdd_registered := object.get(input.vendor, "cbdd_registered", false)
    cbdd_status = "zarejestrowany" { cbdd_registered == true }
    cbdd_status = "BRAK W CBDD — ryzyko!" { cbdd_registered == false }

    declared_ubo := object.get(input.vendor, "declared_ubo", "")
    cbdd_ubo := object.get(input.vendor, "cbdd_ubo", "")
    is_verified = declared_ubo != "" and declared_ubo == cbdd_ubo
    discrepancy = false { declared_ubo == cbdd_ubo }
    discrepancy = true { declared_ubo != cbdd_ubo }

    discrepancy_msg = "UBO zgodny — OK" { discrepancy == false }
    discrepancy_msg = "ROZBIEŻNOŚĆ UBO — zgłoś do GIIF!" { discrepancy == true }
}

# P1933: aml_unusual_pattern — Nietypowy wzorzec transakcji
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.unusual_pattern",
    "package": "jdg.compliance.aml", "priority": 1933,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_unusual_pattern": true, "aml_pattern_type": pattern,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML — nietypowy wzorzec: %s", [pattern]),
    "_legal_basis": "Art. 83-86 Ustawy AML (obowiązek analizy ryzyka), Rekomendacja 20 FATF",
    "_warnings": [sprintf("[AML] NIETYPOWY WZORZEC — %s. Przeanalizuj i udokumentuj. Jeśli podejrzenie prania pieniędzy → STR/SAR do GIIF w ciągu 2 dni roboczych!", [pattern])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    unusual_flag := object.get(input.invoice, "aml_unusual_pattern_flag", false)
    unusual_flag == true
    pattern := object.get(input.invoice, "aml_pattern_description", "nietypowa aktywność transakcyjna")
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1934-P1938: STR/SAR Reporting — Raportowanie do GIIF                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1934: aml_str_filing_obligation — Obowiązek złożenia STR do GIIF
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.str_filing_obligation",
    "package": "jdg.compliance.aml", "priority": 1934,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_str_required": true, "aml_str_deadline_hours": 48,
    "aml_str_reason": str_reason,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("AML — STR do GIIF w ciągu 48h! Powód: %s", [str_reason]),
    "_legal_basis": "Art. 83-86 Ustawy AML, Art. 74-86 Ustawy AML",
    "_warnings": [sprintf("[AML] STR/SAR DO GIIF — %s. Złóż zawiadomienie w ciągu 48h przez system e-PUAP GIIF. Wstrzymaj transakcję do decyzji GIIF (max 96h). Nie informuj klienta o zgłoszeniu (tipping-off — Art. 86 AML)!", [str_reason])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    suspicious_transaction := object.get(input.invoice, "is_suspicious_transaction", false)
    suspicious_transaction == true
    str_reason := object.get(input.invoice, "suspicious_transaction_reason", "podejrzenie prania pieniędzy")
}

# P1935: aml_str_not_filed_penalty — Kara za brak STR
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.str_not_filed_penalty",
    "package": "jdg.compliance.aml", "priority": 1935,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_str_missing": true,
    "aml_penalty_pln": "do_5_000_000",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "AML — brak zgłoszenia STR mimo podejrzanej transakcji! Kara do 5 mln PLN!",
    "_legal_basis": "Art. 147-153 Ustawy AML (kary administracyjne KNF), Art. 299 KKS",
    "_warnings": ["[AML] BRAK STR — transakcja oznaczona jako podejrzana, a STR nie zostało złożone! NATYCHMIAST złóż STR do GIIF. Kary: administracyjna do 5 mln PLN (KNF) + karna do 25 lat pozbawienia wolności (Art. 299 KKS)!"]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    object.get(input.jdg_entrepreneur, "aml_pending_suspicious_no_str", false) == true
}

# P1936: aml_tipping_off_violation — Zakaz tipping-off (informowania klienta o STR)
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.tipping_off",
    "package": "jdg.compliance.aml", "priority": 1936,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_tipping_off_warning": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "AML — NIE informuj klienta o STR! Zakaz tipping-off (Art. 86 AML)!",
    "_legal_basis": "Art. 86 Ustawy AML (zakaz tipping-off), Art. 150 Ustawy AML (kara)",
    "_warnings": ["[AML] TIPPING-OFF — ZAKAZ informowania klienta lub osób trzecich o zgłoszeniu STR do GIIF! Naruszenie = kara do 1 mln PLN + odpowiedzialność karna!"]
} {
    object.get(input.jdg_entrepreneur, "aml_str_filed", false) == true
    object.get(input.invoice, "client_notified_of_str", false) == true
}

# P1937: aml_retention_obligation — Obowiązek przechowywania dokumentacji AML (5 lat)
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.retention_obligation",
    "package": "jdg.compliance.aml", "priority": 1937,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_retention_years": 5,
    "aml_documentation_complete": is_complete,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML — dokumentacja CDD: %s. Retencja 5 lat od zakończenia relacji.", [doc_status]),
    "_legal_basis": "Art. 48 Ustawy AML, Art. 74 UoR",
    "_warnings": [sprintf("[AML] RETENCJA AML — dokumentacja CDD/EDD przechowywana przez 5 lat od końca relacji z klientem. Status: %s. Braki: %d dokumentów.", [doc_status, missing_count])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    missing_count := object.get(input.jdg_entrepreneur, "aml_documentation_missing_count", 0)
    is_complete = missing_count == 0
    doc_status = "KOMPLETNA — OK" { is_complete == true }
    doc_status = sprintf("BRAKUJE %d dokumentów — uzupełnij!", [missing_count]) { is_complete == false }
}

# P1938: aml_employee_training — Obowiązek szkoleń AML dla pracowników
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.employee_training",
    "package": "jdg.compliance.aml", "priority": 1938,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_training_required": true,
    "aml_training_frequency": "co 12 miesięcy",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML — szkolenie pracowników. Ostatnie: %s.", [last_training_date]),
    "_legal_basis": "Art. 50 Ustawy AML, Art. 52 Ustawy AML",
    "_warnings": [sprintf("[AML] SZKOLENIA AML — %d/%d pracowników przeszkolonych. Ostatnie szkolenie: %s. Częstotliwość: co 12 mies. Dokumentuj listę obecności + test wiedzy!", [trained_count, total_employees, last_training_date])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    input.employment.has_employees == true
    total_employees := object.get(input.employment, "employee_count", 0)
    trained_count := object.get(input.employment, "aml_trained_employees", 0)
    last_training_date := object.get(input.jdg_entrepreneur, "aml_last_training_date", "nigdy")
    total_employees > 0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1939-P1942: CBDD — Centralny Rejestr Beneficjentów Rzeczywistych        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1939: cbdd_registration_obligation — Obowiązek zgłoszenia do CBDD
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.cbdd_registration",
    "package": "jdg.compliance.aml", "priority": 1939,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cbdd_registration_required": true,
    "cbdd_deadline_days": 7,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CBDD — brak zgłoszenia beneficjentów rzeczywistych! Termin: 7 dni od wpisu do CEIDG.",
    "_legal_basis": "Art. 58-79 Ustawy o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (CBDD)",
    "_warnings": ["[AML] CBDD — OBOWIĄZEK zgłoszenia beneficjentów rzeczywistych do CRBR w ciągu 7 dni od wpisu do CEIDG/KRS. JDG = Ty jako beneficjent. Kara za brak: do 1 000 000 PLN (Art. 153 AML)!"]
} {
    object.get(input.jdg_entrepreneur, "cbdd_registered", false) == false
    pkd := object.get(input.jdg_entrepreneur, "pkd_main", "")
    company_types := {"SP_ZOO", "SA", "SP_KOMANDYTOWA", "SP_JAWNA", "SP_PARTNERSKA"}
    object.get(input.jdg_entrepreneur, "company_type", "") in company_types
}

# P1940: cbdd_update_obligation — Aktualizacja CBDD w ciągu 7 dni
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.cbdd_update",
    "package": "jdg.compliance.aml", "priority": 1940,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cbdd_update_required": true,
    "cbdd_update_deadline_days": 7,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("CBDD — aktualizacja wymagana: %s", [change_reason]),
    "_legal_basis": "Art. 63 Ustawy o CBDD",
    "_warnings": [sprintf("[AML] CBDD — AKTUALIZACJA WYMAGANA w ciągu 7 dni. Powód: %s. Brak aktualizacji = kara do 50 000 PLN.", [change_reason])]
} {
    input.jdg_entrepreneur.cbdd_registered == true
    cbdd_changed := object.get(input.jdg_entrepreneur, "cbdd_data_changed", false)
    cbdd_changed == true
    change_reason := object.get(input.jdg_entrepreneur, "cbdd_change_reason", "zmiana beneficjenta rzeczywistego")
}

# P1941: cbdd_verification_vendor — Weryfikacja kontrahenta w CBDD
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.cbdd_vendor_verification",
    "package": "jdg.compliance.aml", "priority": 1941,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cbdd_vendor_checked": true,
    "cbdd_vendor_status": cbdd_status,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("CBDD — weryfikacja kontrahenta %s: %s", [vendor_name, cbdd_status]),
    "_legal_basis": "Art. 61-66 Ustawy o CBDD, Art. 35 Ustawy AML",
    "_warnings": [sprintf("[AML] CBDD KONTRAHENTA — %s (NIP: %s). Status: %s. %s", [vendor_name, vendor_nip, cbdd_status, action])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    input.invoice.amount_gross >= 15000
    vendor_name := object.get(input.vendor, "name", "kontrahent")
    vendor_nip := object.get(input.vendor, "nip", "")
    vendor_cbdd := object.get(input.vendor, "cbdd_registered", false)
    cbdd_status = "ZWERYFIKOWANY — OK" { vendor_cbdd == true }
    cbdd_status = "BRAK W CBDD — ryzyko AML!" { vendor_cbdd == false }
    action = "Transakcja może być kontynuowana" { vendor_cbdd == true }
    action = "WYMAGANA EDD + zgoda kierownictwa przed transakcją!" { vendor_cbdd == false }
}

# P1942: cbdd_discrepancy_penalty — Rozbieżność CBDD — sankcja
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.cbdd_discrepancy_penalty",
    "package": "jdg.compliance.aml", "priority": 1942,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cbdd_discrepancy_detected": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CBDD — rozbieżność między deklaracją a stanem faktycznym!",
    "_legal_basis": "Art. 68 Ustawy o CBDD, Art. 153 Ustawy AML",
    "_warnings": ["[AML] CBDD ROZBIEŻNOŚĆ — dane w CRBR niezgodne ze stanem faktycznym! Natychmiast złóż aktualizację. Sankcja KNF: do 1 000 000 PLN za nieprawdziwe dane w CBDD!"]
} {
    input.jdg_entrepreneur.cbdd_registered == true
    object.get(input.jdg_entrepreneur, "cbdd_discrepancy_detected", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1943-P1946: Crypto & Sanctions                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P1943: aml_crypto_travel_rule — Travel Rule dla kryptoaktywów
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.crypto_travel_rule",
    "package": "jdg.compliance.aml", "priority": 1943,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_travel_rule_applies": true,
    "aml_travel_rule_threshold_eur": 1000,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Travel Rule — transfer krypto %.2f EUR. Przekaż dane nadawcy/odbiorcy!", [crypto_amount_eur]),
    "_legal_basis": "Rozp. UE 2023/1113 (TFR — Transfer of Funds Regulation), FATF Rekomendacja 16",
    "_warnings": [sprintf("[AML] TRAVEL RULE — transfer %.2f EUR w kryptoaktywach. Przekaż dane: nazwa nadawcy, numer rachunku, adres, data urodzenia. Od 2025: obowiązek dla wszystkich VASP/CASP!", [crypto_amount_eur])]
} {
    object.get(input.jdg_entrepreneur, "is_crypto_exchange", false) == true
    input.invoice.crypto_transfer == true
    crypto_amount_eur := object.get(input.invoice, "crypto_amount_eur", 0)
    crypto_amount_eur >= 1000
}

# P1944: aml_sanctions_screening — Screening list sankcyjnych
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.sanctions_screening",
    "package": "jdg.compliance.aml", "priority": 1944,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_sanctions_match": match_found,
    "aml_sanctions_list": list_name,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("SANKCJE — %s na liście sankcyjnej %s!", [vendor_name, list_name]),
    "_legal_basis": "Rozp. UE 269/2014 (sankcje Rosja), Rozp. UE 765/2006 (Białoruś), Rezolucje RB ONZ",
    "_warnings": [sprintf("[AML] SANKCJE MIĘDZYNARODOWE — %s (%.0f%% match) na liście %s! NATYCHMIAST wstrzymaj transakcję + zgłoś do GIIF + KNF! Kara za naruszenie sankcji: do 20 mln PLN!", [vendor_name, match_score, list_name])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    match_found := object.get(input.vendor, "sanctions_list_match", false)
    match_found == true
    vendor_name := object.get(input.vendor, "name", "Kontrahent")
    list_name := object.get(input.vendor, "sanctions_list_name", "UE/ONZ")
    match_score := object.get(input.vendor, "sanctions_match_confidence", 0)
}

# P1945: aml_internal_procedure_gap — Luka w procedurze wewnętrznej AML
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.internal_procedure_gap",
    "package": "jdg.compliance.aml", "priority": 1945,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_procedure_gap": true, "aml_procedure_missing": missing_element,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML — brak elementu procedury wewnętrznej: %s", [missing_element]),
    "_legal_basis": "Art. 50-52 Ustawy AML, Art. 11 Ustawy AML",
    "_warnings": [sprintf("[AML] PROCEDURA WEWNĘTRZNA — brakuje: %s. Kompletna procedura AML wymaga: (1) ocena ryzyka, (2) CDD/EDD, (3) STR, (4) szkolenia, (5) audyt, (6) retencja. Uzupełnij w ciągu 30 dni!", [missing_element])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    object.get(input.jdg_entrepreneur, "aml_procedure_complete", true) == false
    missing_element := object.get(input.jdg_entrepreneur, "aml_procedure_missing_element", "nieokreślony")
}

# P1946: aml_audit_obligation — Obowiązek audytu AML (roczny)
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.audit_obligation",
    "package": "jdg.compliance.aml", "priority": 1946,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "aml_audit_required": true,
    "aml_audit_frequency": "roczny",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("AML — audyt roczny. Ostatni: %s", [last_audit_date]),
    "_legal_basis": "Art. 50 ust. 3 Ustawy AML",
    "_warnings": [sprintf("[AML] AUDYT ROCZNY — ostatni audyt AML: %s. Wymagany co 12 miesięcy. Zakres: procedura, CDD, STR, szkolenia, CBDD. Dokumentuj wnioski!", [last_audit_date])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    last_audit_date := object.get(input.jdg_entrepreneur, "aml_last_audit_date", "nigdy")
    last_audit_date == "nigdy"
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.compliance.aml.fallback",
    "package": "jdg.compliance.aml", "priority": 1998,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa AML",
    "_warnings": ["[AML] AML compliance — brak przesłanek do zgłoszenia. Procedury AML w normie."]
} { true }
