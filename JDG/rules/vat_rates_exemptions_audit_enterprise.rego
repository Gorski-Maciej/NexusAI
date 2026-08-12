# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT RATES & EXEMPTIONS AUDIT (P03 VAT Macro — Sekcja 1)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.vat_rates_audit
# Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_VAT_MACRO (P03) v8.0 — Sekcja 1
#
# AUDYT STAWEK I ZWOLNIEŃ (poziom ENTERPRISE):
#   RA-01 Mapa stawek per kategoria/PKWiU/CN — automatyczna walidacja stawek
#        wg PKWiU/CN (data.jdg.vat.rate_map) z fallbackiem kategorii.
#   RA-02 Zwolnienie podmiotowe (art. 113) — limit 200 000 PLN + walidacja
#        przekroczenia MID-YEAR (proporcja do pozostałych miesięcy).
#   RA-03 Proporcja startowa — nowa JDG (art. 113 ust. 9): limit proporcjonalny
#        do liczby dni/miesięcy prowadzenia działalności w roku.
#   RA-04 Zwolnienia przedmiotowe (art. 43) — matryca pokrycia per pozycja.
#   RA-05 Kontrakt stawki: 23/8/5/0/NP — każda kategoria musi mieć stawkę,
#        a stawka musi być zgodna z ustawą (wykrywanie stawki NIEZGODNEJ).
#   RA-06 Rate Drift Monitor — stawki zmienione rozporządzeniem (2024-12-04)
#        vs stawki w input — sygnał do aktualizacji reguł.
#
# Zgodność: art. 41-43, 113 VAT, Rozp. MF z 4.12.2024 r., P03 Sekcja 1.
# package: jdg.vat_rates_audit
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat_rates_audit

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.vat_rates_audit.no_match","package":"jdg.vat_rates_audit","priority":999999}

# ── RA-01: MAPA STAWEK per kategoria/PKWiU/CN ────────────────────────────────
# Priorytet dopasowania: CN code → PKWiU → category_code → stawka standardowa.
# Źródło mapy: data.jdg.vat.rate_map (externalizowane — auto-aktualizacja wg
# rozporządzeń MF przez pipeline z P03 Sekcja 7). Fallback: wbudowana mapa.
default_rate_map := {
    "FOOD": "5.00", "GROCERIES": "5.00", "FOOD_BASIC": "5.00",
    "BOOKS": "5.00", "EBOOKS": "5.00", "AUDIOBOOKS": "5.00",
    "CONSTRUCTION_RESIDENTIAL": "8.00", "HOTEL": "8.00",
    "TRANSPORT_PASSENGER": "8.00", "PHARMACEUTICALS": "8.00",
    "MEDICAL_EQUIPMENT": "8.00", "RESTAURANT_CATERING": "8.00",
    "WATER_SUPPLY": "8.00", "WASTE_COLLECTION": "8.00",
    "FUEL": "23.00", "ELECTRONICS": "23.00", "VEHICLES": "23.00",
    "CLOTHING": "23.00", "FURNITURE": "23.00", "TOYS": "23.00",
    "TOBACCO": "23.00", "ALCOHOL": "23.00", "BEVERAGES_ALCOHOLIC": "23.00",
    "SERVICES": "23.00", "CONSULTING": "23.00", "IT_SERVICES": "23.00",
    "SOFTWARE_LICENSE": "23.00", "ADVERTISING": "23.00",
    "REAL_ESTATE_COMMERCIAL": "23.00"
}

rate_map := object.get(object.get(data.jdg, "vat", {}), "rate_map", default_rate_map)

# ── RA-01a: wyznacz stawkę wg mapy (CN → PKWiU → kategoria) ──────────────────
mapped_vat_rate := rate {
    cn := object.get(input.invoice, "cn_code", "")
    cn != ""
    rate_map_cn := object.get(object.get(data.jdg.vat, "rate_map_cn", {}), cn, "")
    rate_map_cn != ""
    rate := rate_map_cn
} else := rate {
    pkwiu := object.get(input.invoice, "pkwiu_code", "")
    pkwiu != ""
    rate_map_pk := object.get(object.get(data.jdg.vat, "rate_map_pkwiu", {}), pkwiu, "")
    rate_map_pk != ""
    rate := rate_map_pk
} else := rate {
    cat := object.get(input.invoice, "category_code", "")
    rate_map_cat := object.get(rate_map, cat, "")
    rate_map_cat != ""
    rate := rate_map_cat
} else := rate {
    rate := "UNKNOWN"
}

# ── RA-05: KONTRAKT STAWKI — wykrywanie stawki niezgodnej ───────────────────
# Gdy input podaje stawkę i mapa zna właściwą — rozbieżność = sygnał błędu.
# Dozwolone: zgodność z mapą; "NP" (nie podlega); "ZW" (zwolnione); "OO" (odwr.
# obciążenie); "MPP" nie jest stawką. Wszystko inne ≠ mapa → niezgodne.
rate_mismatch := {
    "matched": true,
    "rule_id": "jdg.vat_rates_audit.rate_mismatch",
    "package": "jdg.vat_rates_audit",
    "priority": 100,
    "invoice_rate": object.get(input.invoice, "vat_rate", ""),
    "expected_rate": mapped_vat_rate,
    "category": object.get(input.invoice, "category_code", ""),
    "cn_code": object.get(input.invoice, "cn_code", ""),
    "pkwiu_code": object.get(input.invoice, "pkwiu_code", ""),
    "mismatch": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Stawka VAT w fakturze niezgodna z mapą stawek (PKWiU/CN) — ryzyko błędnej stawki",
    "_legal_basis": "Art. 41 ust. 1-2a VAT + rozporządzenia MF z 4.12.2024 r.",
    "_warnings": [sprintf("Rozbieżność stawki: faktura %s, oczekiwana %s wg mapy (kategoria %s). Zweryfikuj PKWiU/CN.", [object.get(input.invoice, "vat_rate", ""), mapped_vat_rate, object.get(input.invoice, "category_code", "")])]
} {
    input.invoice.vat_rate
    mapped_vat_rate != "UNKNOWN"
    input.invoice.vat_rate != mapped_vat_rate
    input.invoice.vat_rate not in {"NP", "ZW", "OO", "0.00"}
}

# ── RA-06: RATE DRIFT MONITOR ────────────────────────────────────────────────
# Stawki z input mogą pochodzić ze starych reguł (przed Rozp. MF 4.12.2024).
# Porównanie stawki z input ze stawką wg mapy per kategoria (jeśli różne → drift).
rate_drift_warnings := [w |
    some cat in object.keys(rate_map)
    expected := rate_map[cat]
    declared := object.get(object.get(data.jdg.vat, "declared_rates", {}), cat, "")
    declared != ""
    declared != expected
    w := {"category": cat, "declared": declared, "expected": expected, "drift": true}
] else := [] {
    true
}

# ── RA-02: ZWOLNIENIE PODMIOTOWE + PRZEKROCZENIE MID-YEAR ───────────────────
# Limit 200 000 PLN (art. 113 ust. 1). Przekroczenie MID-YEAR: gdy obrót
# przekracza limit przed końcem roku, zwolnienie wygasa od miesiąca przekroczenia
# (art. 113 ust. 5). Proporcja startowa (art. 113 ust. 9): limit = 200k × (liczba
# miesięcy prowadzenia / 12).
annual_exemption_limit := 200000

midyear_breach := {
    "matched": true,
    "rule_id": "jdg.vat_rates_audit.midyear_breach",
    "package": "jdg.vat_rates_audit",
    "priority": 200,
    "limit": annual_exemption_limit,
    "turnover_to_date": object.get(input.jdg_entrepreneur, "annual_turnover_net", 0),
    "breach_month": object.get(input.jdg_entrepreneur, "breach_month", ""),
    "exemption_ended": true,
    "vat_registration_due": true,
    "registration_deadline": sprintf("%s-25", [object.get(input.jdg_entrepreneur, "breach_month", "____")]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczenie limitu zwolnienia 200 000 PLN mid-year — obowiązek rejestracji VAT od miesiąca przekroczenia",
    "_legal_basis": "Art. 113 ust. 1, 5 i 9 VAT",
    "_warnings": [sprintf("LIMIT PRZEKROCZONY: obrót %v PLN ≥ 200 000 PLN. Zwolnienie wygasa od %s. Rejestracja VAT do 25. dnia następnego miesiąca po miesiącu przekroczenia.", [object.get(input.jdg_entrepreneur, "annual_turnover_net", 0), object.get(input.jdg_entrepreneur, "breach_month", "")])]
} {
    object.get(input.jdg_entrepreneur, "vat_exemption_check", false) == true
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == false
    object.get(input.jdg_entrepreneur, "annual_turnover_net", 0) >= annual_exemption_limit
    object.get(input.jdg_entrepreneur, "breach_month", "") != ""
}

# ── RA-03: PROPORCJA STARTOWA (art. 113 ust. 9) ──────────────────────────────
# Nowa JDG: limit proporcjonalny = 200k × (miesiące prowadzenia / 12).
# Miesiące liczone od CEIDG entry do końca roku (lub miesiąc przekroczenia).
startup_proportional_limit := limit {
    entry_month := to_number(object.get(input.jdg_entrepreneur, "ceidg_entry_month", "1"))
    months_remaining := 13 - entry_month
    limit := round(annual_exemption_limit * (months_remaining / 12.0) * 100) / 100
} else := annual_exemption_limit {
    true
}

startup_limit_report := {
    "matched": true,
    "rule_id": "jdg.vat_rates_audit.startup_proportional_limit",
    "package": "jdg.vat_rates_audit",
    "priority": 210,
    "startup": true,
    "full_limit": annual_exemption_limit,
    "proportional_limit": startup_proportional_limit,
    "ceidg_entry_month": object.get(input.jdg_entrepreneur, "ceidg_entry_month", "1"),
    "turnover_net": object.get(input.jdg_entrepreneur, "annual_turnover_net", 0),
    "within_limit": object.get(input.jdg_entrepreneur, "annual_turnover_net", 0) < startup_proportional_limit,
    "_routing": "REPORT",
    "_routing_reason": "Proporcja startowa limitu zwolnienia podmiotowego (nowa JDG)",
    "_legal_basis": "Art. 113 ust. 9 VAT",
    "_warnings": [sprintf("Nowa JDG: limit zwolnienia proporcjonalny = %v PLN (200 000 × miesiące/12). Obrót: %v PLN.", [startup_proportional_limit, object.get(input.jdg_entrepreneur, "annual_turnover_net", 0)])]
} {
    object.get(input.jdg_entrepreneur, "vat_exemption_check", false) == true
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == false
    object.get(input.jdg_entrepreneur, "ceidg_entry_month", "") != ""
    object.get(input.jdg_entrepreneur, "annual_turnover_net", 0) < annual_exemption_limit
}

# ── RA-04: MATRYCA ZWOLNIEŃ PRZEDMIOTOWYCH (art. 43) ─────────────────────────
# Pokrycie per kategoria → status zwolnienia przedmiotowego (OBJECT).
object_exemption_matrix := {
    "EDUCATION": "art. 43 ust. 1 pkt 26-29",
    "TRAINING": "art. 43 ust. 1 pkt 26-29",
    "TUTORING": "art. 43 ust. 1 pkt 26-29",
    "HEALTHCARE": "art. 43 ust. 1 pkt 18-20",
    "MEDICAL": "art. 43 ust. 1 pkt 18-20",
    "DENTAL": "art. 43 ust. 1 pkt 18-20",
    "FINANCIAL": "art. 43 ust. 1 pkt 7, 37-38",
    "INSURANCE": "art. 43 ust. 1 pkt 7, 37-38",
    "BANKING": "art. 43 ust. 1 pkt 7, 37-38",
    "CULTURE": "art. 43 ust. 1 pkt 32-33",
    "SPORT": "art. 43 ust. 1 pkt 32-33",
    "MUSEUM": "art. 43 ust. 1 pkt 32-33",
    "POSTAL": "art. 43 ust. 1 pkt 17",
    "REAL_ESTATE": "art. 43 ust. 1 pkt 10"
}

exemption_gap_warnings := [cat |
    some cat in ["EDUCATION", "HEALTHCARE", "FINANCIAL", "CULTURE", "POSTAL"]
    declared_exempt := object.get(input.invoice, "vat_exemption", "") == "OBJECT"
    category_known := object.get(object_exemption_matrix, cat, "") != ""
    category_known
    input.invoice.category_code == cat
    not declared_exempt
    cat
] else := [] {
    true
}

# ── DECYZJA: RAPORT AUDYTU STAWEK I ZWOLNIEŃ ─────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.vat_rates_audit.report",
    "package": "jdg.vat_rates_audit",
    "priority": 300,
    "rates_audit": {
        "mapped_rate": mapped_vat_rate,
        "rate_map_entries": count(object.keys(rate_map)),
        "rate_mismatch_detected": object.get(input.invoice, "vat_rate", "") != "" and mapped_vat_rate != "UNKNOWN" and object.get(input.invoice, "vat_rate", "") != mapped_vat_rate,
        "object_exemptions_matrix": count(object.keys(object_exemption_matrix)),
        "exemption_gaps": exemption_gap_warnings,
        "rate_drift": rate_drift_warnings,
        "annual_exemption_limit": annual_exemption_limit,
        "startup_proportional_limit": startup_proportional_limit
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport audytu stawek i zwolnień VAT (Sekcja 1 P03) — mapa PKWiU/CN + kontrakt stawki",
    "_legal_basis": "Art. 41-43, 113 VAT + P03 Sekcja 1",
    "_warnings": [sprintf("Rate mismatches: %v | Exemption gaps: %d | Rate drift: %d", [object.get(input.invoice, "vat_rate", "") != "" and mapped_vat_rate != "UNKNOWN" and object.get(input.invoice, "vat_rate", "") != mapped_vat_rate, count(exemption_gap_warnings), count(rate_drift_warnings)])]
} {
    object.get(input.jdg_entrepreneur, "vat_rates_check", false) == true
}
