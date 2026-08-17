# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P14 GENIALNE POMYSŁY ENTERPRISE (PCC + Podatki Lokalne + Akcyza)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p14_pcc_lokalne_akcyza_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG PCC + LOKALNE + AKCYZĄ (P14) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: AUDYT PCC (PRIORYTET) — czynności (art. 1), obowiązek (art. 4),
#            stawki 1-2% (art. 6-7), PCC-3 w 14 dni (art. 10), zwolnienia
#            + AUTO-GENERATOR PCC-3 (INN-01), DETEKTOR czynności (INN-02)
#   Sekcja 2: AUDYT PODATKÓW LOKALNYCH (PRIORYTET) — nieruchomości (DN-1,
#            stawki ~33 zł/m² firmowe), środki transportowe >3,5t, opłata
#            targowa + REJESTR STAWEK GMINNYCH (INN-03)
#   Sekcja 3: AUDYT AKCYZY — paliwa, alkohol, tytoń, energia, obowiązki
#            ewidencyjne, skład podatkowy
#   Sekcja 4: AUDYT LUK I DUPLIKATÓW — porównanie rule_id z MANIFEST,
#            stuby i brakujące obszary (LEGAL_COVERAGE: 225 punktów)
#   Sekcja 5: OPA jako rozbudowany system — pipeline auto-aktualizacji
#            thresholdów lokalnych (ADR-002, hot-reload)
#   Sekcja 6: 12+ genialnych pomysłów Enterprise (INN-01..INN-12)
#   Sekcja 7: Mapa drogowa P0/P1/P2 (w raporcie R14)
#
# Zgodność: ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789), podatki i opłaty lokalne
#           (Dz.U. 2025 poz. 1234), ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220),
#           ADR-002 (progi z data.jdg.thresholds).
# package: jdg.p14_pcc_lokalne_akcyza_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p14_pcc_lokalne_akcyza_innovations

import future.keywords.in
import future.keywords.if

default decide := {"matched": false, "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.no_match", "package": "jdg.p14_pcc_lokalne_akcyza_innovations", "priority": 999999}

# RAPORT_11 rekomendacja P2 (TOP 10 pkt 10): warstwa P14 jest doradcza —
# nigdy nie podejmuje automatycznej decyzji podatkowej (tryb SUGGEST).
decision_mode := "SUGGEST"

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
pcc_local_limits := object.get(thresholds, "pcc_local_excise", {
    "pcc_rates": {                 # Sekcja 1: stawki PCC (art. 6-7)
        "SALE_MOVABLE": 2.0, "SALE_REAL_ESTATE": 2.0, "SALE_VEHICLE_PRIVATE": 2.0,
        "LOAN": 0.5, "SHARE_PURCHASE": 1.0, "COMPANY_FORMATION": 0.5,
        "EXCHANGE_REAL_ESTATE": 2.0, "EXCHANGE_OTHER": 1.0, "MORTGAGE": 0.1,
        "SURETY": 0.5, "INSTALLMENT_SALE": 2.0, "INHERITANCE_DIVISION": 1.0,
    },
    "pcc_threshold_small": 1000,   # art. 9 pkt 1 — kwoty ≤ 1000 PLN zwolnione
    "pcc_family_loan_limit": 36120, # pożyczka rodzinna zwolniona do tego limitu
    "pcc3_deadline_days": 14,      # art. 10 — PCC-3 w 14 dni
    "real_estate_rates": {         # Sekcja 2: podatek od nieruchomości 2026
        "land_business": 1.43, "land_other": 0.71,
        "building_business": 33.10, "building_residential": 1.15,
        "construction_pct_value": 2.0,
    },
    "dn1_deadline_days": 14,       # DN-1 — 14 dni od nabycia/zmiany
    "dn1_payment_schedule": ["MARCH_15", "MAY_15", "SEPTEMBER_15", "NOVEMBER_15"],
    "transport_heavy_threshold_t": 3.5,  # środki transportowe >3,5t
    "excise_fuel": {               # Sekcja 3: akcyza na paliwa 2026 (PLN/1000l)
        "benzyna": 1566.0, "on": 1206.0, "lpg": 695.0,
    },
    "excise_alcohol": {            # akcyza na alkohol 2026
        "alkohol_etylowy_pln_hl": 6900.0, "piwo_pln_hl_plato": 8.57,
        "wino_pln_hl": 185.0,
    },
})

pcc_rates := object.get(pcc_local_limits, "pcc_rates", {})
pcc_threshold_small := to_number(object.get(pcc_local_limits, "pcc_threshold_small", 1000))
pcc_family_loan_limit := to_number(object.get(pcc_local_limits, "pcc_family_loan_limit", 36120))
pcc3_deadline_days := to_number(object.get(pcc_local_limits, "pcc3_deadline_days", 14))
real_estate_rates := object.get(pcc_local_limits, "real_estate_rates", {})
dn1_deadline_days := to_number(object.get(pcc_local_limits, "dn1_deadline_days", 14))
transport_heavy_threshold := to_number(object.get(pcc_local_limits, "transport_heavy_threshold_t", 3.5))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── SEKCJA 1: MAPA POKRYCIA ARTYKUŁÓW (PCC + lokalne + akcyza) ────────────────
# Status COMPLETE/PARTIAL/MISSING z data.jdg.p14_audit (pcc_local_excise_auditor.py).
p14_priority_articles := ["a1", "a2", "a3", "a4", "a6", "a7", "a8", "a12", "a16", "a26", "a30", "a99"]

p14_audit_data := object.get(data.jdg, "p14_audit", {})
p14_coverage_articles := object.get(p14_audit_data, "articles", {})

pcc_local_excise_coverage_report := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.pcc_local_excise_coverage_report",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1010,
    "matched": true,
    "articles": {art: {
        "status": object.get(object.get(p14_coverage_articles, art, {}), "status", "MISSING"),
        "rules": object.get(object.get(p14_coverage_articles, art, {}), "rules", 0),
    } | art := p14_priority_articles[_]},
    "summary": {
        "total": count(p14_priority_articles),
        "complete": count([a | a := p14_priority_articles[_]; object.get(object.get(p14_coverage_articles, a, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([a | a := p14_priority_articles[_]; object.get(object.get(p14_coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([a | a := p14_priority_articles[_]; object.get(object.get(p14_coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]) / count(p14_priority_articles) * 100),
    "micro_total_rule_ids": object.get(p14_audit_data, "total_rule_ids", 328),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia artykułów PCC + lokalnych + akcyzy (art. 1-99) — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789); podatki lokalne; ustawa o podatku akcyzowym",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# ── SEKCJA 1: AUDYT PCC (POZIOM ENTERPRISE — PRIORYTET) ───────────────────────
# art. 1 (przedmiot), art. 4 (obowiązek), art. 6-7 (stawki), art. 10 (PCC-3 14 dni).
pcc_audit := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.pcc_audit",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1120,
    "matched": true,
    "rates": pcc_rates,
    "subject_art1": ["umowy sprzedaży rzeczy i praw majątkowych", "umowy pożyczki", "umowy spółki", "umowy zamiany", "umowy darowizny", "ustanowienie hipoteki"],
    "obligation_art4": "obowiązek podatkowy ciąży na kupującym/pożyczkobiorcy (strona nabywająca)",
    "exclusions_vat": "transakcje objęte VAT są wyłączone z PCC (art. 2 pkt 4)",
    "small_value_exemption": sprintf("kwoty ≤ %v PLN zwolnione (art. 9 pkt 1)", [pcc_threshold_small]),
    "family_loan_limit": sprintf("pożyczka rodzinna zwolniona do %v PLN", [pcc_family_loan_limit]),
    "pcc3_deadline_days": pcc3_deadline_days,
    "_routing": "",
    "_routing_reason": "Audyt PCC — czynności, stawki 1-2%, PCC-3 w 14 dni, zwolnienia (priorytet)",
    "_legal_basis": "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789) art. 1-10",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-01: AUTO-GENERATOR deklaracji PCC-3.
pcc3_generator := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.pcc3_generator",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1121,
    "matched": true,
    "transaction_type": object.get(input.transaction, "type", "SALE_MOVABLE"),
    "amount": to_number(object.get(input.transaction, "amount", 0)),
    "rate_pct": object.get(pcc_rates, object.get(input.transaction, "type", "SALE_MOVABLE"), 2.0),
    "tax_due": round2(to_number(object.get(input.transaction, "amount", 0)) * object.get(pcc_rates, object.get(input.transaction, "type", "SALE_MOVABLE"), 2.0) / 100),
    "deadline_days": pcc3_deadline_days,
    "form": "PCC-3 (deklaracja) + PCC-3/A (załącznik) do US w 14 dni od powstania obowiązku",
    "small_value_exempt": to_number(object.get(input.transaction, "amount", 0)) <= pcc_threshold_small,
    "note": "auto-generator PCC-3 — kwota podatku, termin 14 dni, formularz PCC-3/PCC-3/A",
    "_routing": "",
    "_routing_reason": "Auto-generator PCC-3 (INN-01) — kwota, termin 14 dni, formularz",
    "_legal_basis": "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789) art. 10",
    "_warnings": [],
    "valid_from": "2001-01-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-02: DETEKTOR czynności opodatkowanych PCC z dokumentów.
pcc_detector := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.pcc_detector",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1122,
    "matched": true,
    "document_type": object.get(input.document, "type", ""),
    "taxable": object.get(input.document, "type", "") == "umowa_sprzedazy" or object.get(input.document, "type", "") == "umowa_pozyczki" or object.get(input.document, "type", "") == "umowa_spolki" or object.get(input.document, "type", "") == "umowa_zamiany",
    "pcc_rate": object.get(pcc_rates, "SALE_MOVABLE", 2.0) if object.get(input.document, "type", "") == "umowa_sprzedazy" else object.get(pcc_rates, "LOAN", 0.5) if object.get(input.document, "type", "") == "umowa_pozyczki" else object.get(pcc_rates, "COMPANY_FORMATION", 0.5) if object.get(input.document, "type", "") == "umowa_spolki" else object.get(pcc_rates, "EXCHANGE_OTHER", 1.0) if object.get(input.document, "type", "") == "umowa_zamiany" else 0,
    "note": "detektor czynności opodatkowanych PCC z dokumentów (umowy sprzedaży/pożyczki/spółki/zamiany)",
    "_routing": "",
    "_routing_reason": "Detektor czynności opodatkowanych PCC z dokumentów (INN-02)",
    "_legal_basis": "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789) art. 1",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# ── SEKCJA 2: AUDYT PODATKÓW LOKALNYCH (POZIOM ENTERPRISE — PRIORYTET) ───────
# Nieruchomości (DN-1, stawki gminne), środki transportowe >3,5t, opłata targowa.
local_taxes_audit := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.local_taxes_audit",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1130,
    "matched": true,
    "real_estate": {
        "rates_2026": real_estate_rates,
        "dn1_deadline_days": dn1_deadline_days,
        "payment_schedule": object.get(pcc_local_limits, "dn1_payment_schedule", ["MARCH_15", "MAY_15", "SEPTEMBER_15", "NOVEMBER_15"]),
        "note": "podatek od nieruchomości — stawki gminne (DN-1 w 14 dni od nabycia)",
    },
    "transport": {
        "heavy_threshold_t": transport_heavy_threshold,
        "note": "podatek od środków transportowych — pojazdy >3,5t (art. 8-13 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234))",
    },
    "market_fee": "opłata targowa — stawka gminna za sprzedaż na targowisku (art. 15 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234))",
    "health_resort_fee": "opłata uzdrowiskowa — stawka gminna (art. 17 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234))",
    "integrated_packages": ["jdg.local_taxes.real_estate", "jdg.local_taxes.transport", "jdg.local_taxes", "jdg.micro.plan33_prop", "jdg.micro.transport"],
    "_routing": "",
    "_routing_reason": "Audyt podatków lokalnych — nieruchomości DN-1, transport >3,5t, opłata targowa (priorytet)",
    "_legal_basis": "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-03: REJESTR STAWEK GMINNYCH — system thresholdów lokalnych.
gmina_rates_registry := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.gmina_rates_registry",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1131,
    "matched": true,
    "gmina": object.get(input.jdg_entrepreneur, "gmina", "domyślna"),
    "rates_source": "data.jdg.thresholds.pcc_local_excise.real_estate_rates (ADR-002) — stawki gminne coroczne",
    "auto_update": "zmiana stawek gminnych (uchwała rady gminy) → pipeline auto-aktualizacji thresholdów",
    "registry": {
        "land_business_pln_m2": object.get(real_estate_rates, "land_business", 1.43),
        "building_business_pln_m2": object.get(real_estate_rates, "building_business", 33.10),
        "construction_pct": object.get(real_estate_rates, "construction_pct_value", 2.0),
    },
    "note": "rejestr stawek gminnych — podatek od nieruchomości per gmina (2026)",
    "_routing": "",
    "_routing_reason": "Rejestr stawek gminnych — system thresholdów lokalnych (INN-03)",
    "_legal_basis": "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234); obwieszczenia MF",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-04: SYMULATOR podatku od nieruchomości.
real_estate_tax_calculator := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.real_estate_tax_calculator",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1132,
    "matched": true,
    "land_business_m2": to_number(object.get(input.property, "land_business_m2", 0)),
    "building_business_m2": to_number(object.get(input.property, "building_business_m2", 0)),
    "land_tax": round2(to_number(object.get(input.property, "land_business_m2", 0)) * object.get(real_estate_rates, "land_business", 1.43)),
    "building_tax": round2(to_number(object.get(input.property, "building_business_m2", 0)) * object.get(real_estate_rates, "building_business", 33.10)),
    "total_annual": round2(to_number(object.get(input.property, "land_business_m2", 0)) * object.get(real_estate_rates, "land_business", 1.43) + to_number(object.get(input.property, "building_business_m2", 0)) * object.get(real_estate_rates, "building_business", 33.10)),
    "note": "symulator podatku od nieruchomości — grunty i budynki firmowe (stawki gminne 2026)",
    "_routing": "",
    "_routing_reason": "Symulator podatku od nieruchomości — stawki gminne (INN-04)",
    "_legal_basis": "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-05: KALKULATOR podatku od środków transportowych.
transport_tax_calculator := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.transport_tax_calculator",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1133,
    "matched": true,
    "vehicle_gvw_t": to_number(object.get(input.vehicle, "gvw_t", 0)),
    "taxable": to_number(object.get(input.vehicle, "gvw_t", 0)) > transport_heavy_threshold,
    "note": "podatek od środków transportowych — pojazdy >3,5t, stawki gminne (art. 8-13 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234))",
    "_routing": "",
    "_routing_reason": "Kalkulator podatku od środków transportowych >3,5t (INN-05)",
    "_legal_basis": "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234) art. 8-13",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-06: TRACKER terminów DN-1.
dn1_tracker := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.dn1_tracker",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1134,
    "matched": true,
    "dn1_deadline_days": dn1_deadline_days,
    "payment_schedule": object.get(pcc_local_limits, "dn1_payment_schedule", ["MARCH_15", "MAY_15", "SEPTEMBER_15", "NOVEMBER_15"]),
    "note": "tracker terminów DN-1 — 14 dni od nabycia, raty 15.03/15.05/15.09/15.11",
    "_routing": "",
    "_routing_reason": "Tracker terminów DN-1 (INN-06) — deklaracja i raty",
    "_legal_basis": "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# ── SEKCJA 3: AUDYT AKCYZY (POZIOM ENTERPRISE) ────────────────────────────────
# Paliwa, alkohol, tytoń, energia — stawki, zwolnienia, ewidencja, skład podatkowy.
excise_audit := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.excise_audit",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1140,
    "matched": true,
    "fuel_2026": object.get(pcc_local_limits, "excise_fuel", {}),
    "alcohol_2026": object.get(pcc_local_limits, "excise_alcohol", {}),
    "tobacco": "wyroby tytoniowe — akcyza wg stawek na 1000 szt./kg (art. 99 ustawy)",
    "energy": "energia elektryczna i węglowa — akcyza wg stawek (art. 89 ustawy)",
    "excise_warehouse": "skład podatkowy — obowiązkowy dla produkcji alkoholu/paliw",
    "banderoles": "banderole — obowiązkowe na wyrobach alkoholowych >100ml (znaki akcyzy)",
    "_routing": "",
    "_routing_reason": "Audyt akcyzy — paliwa, alkohol, tytoń, energia, ewidencja, skład podatkowy",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) art. 89-99",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-07: KALKULATOR akcyzy na paliwa.
excise_fuel_calculator := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.excise_fuel_calculator",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1141,
    "matched": true,
    "fuel_type": object.get(input.fuel, "type", "benzyna"),
    "volume_l": to_number(object.get(input.fuel, "volume_l", 0)),
    "rate_per_1000l": object.get(object.get(pcc_local_limits, "excise_fuel", {}), object.get(input.fuel, "type", "benzyna"), 1566.0),
    "excise_due": round2(to_number(object.get(input.fuel, "volume_l", 0)) / 1000 * object.get(object.get(pcc_local_limits, "excise_fuel", {}), object.get(input.fuel, "type", "benzyna"), 1566.0)),
    "note": "kalkulator akcyzy na paliwa — stawki 2026 (PLN/1000l): benzyna 1566, ON 1206, LPG 695",
    "_routing": "",
    "_routing_reason": "Kalkulator akcyzy na paliwa (INN-07) — stawki 2026",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) art. 89",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# Pomocnicze: stawka akcyzy na alkohol per produkt (2026).
excise_alcohol_rate(product) = rate {
    product == "alkohol_etylowy"
    rate := object.get(object.get(pcc_local_limits, "excise_alcohol", {}), "alkohol_etylowy_pln_hl", 6900.0)
} else := object.get(object.get(pcc_local_limits, "excise_alcohol", {}), "wino_pln_hl", 185.0) {
    product == "wino"
} else := object.get(object.get(pcc_local_limits, "excise_alcohol", {}), "piwo_pln_hl_plato", 8.57) {
    true
}

# INN-08: KALKULATOR akcyzy na alkohol.
excise_alcohol_calculator := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.excise_alcohol_calculator",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1142,
    "matched": true,
    "product": object.get(input.alcohol, "product", "alkohol_etylowy"),
    "volume_hl": to_number(object.get(input.alcohol, "volume_hl", 0)),
    "rate_pln_hl": excise_alcohol_rate(object.get(input.alcohol, "product", "alkohol_etylowy")),
    "excise_due": round2(to_number(object.get(input.alcohol, "volume_hl", 0)) * excise_alcohol_rate(object.get(input.alcohol, "product", "alkohol_etylowy"))),
    "warehouse_required": object.get(input.alcohol, "product", "alkohol_etylowy") == "alkohol_etylowy",
    "note": "kalkulator akcyzy na alkohol — stawki 2026 (PLN/hl): alkohol 6900, piwo 8,57/°Plato, wino 185",
    "_routing": "",
    "_routing_reason": "Kalkulator akcyzy na alkohol (INN-08) — stawki 2026, skład podatkowy",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) art. 92-96",
    "_warnings": [],
    "valid_from": "2009-03-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-09: WYKRYWACZ akcyzy w kosztach.
excise_cost_detector := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.excise_cost_detector",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1143,
    "matched": true,
    "costs": object.get(input.jdg_entrepreneur, "costs_with_excise", []),
    "flagged": [c | c := object.get(input.jdg_entrepreneur, "costs_with_excise", [])[_]; object.get(c, "excise_risk", false) == true],
    "note": "wykrywacz akcyzy w kosztach — paliwo, alkohol, wyroby akcyzowe w kosztach firmy",
    "_routing": "",
    "_routing_reason": "Wykrywacz akcyzy w kosztach (INN-09) — ryzyko akcyzowe w kosztach",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# ── SEKCJA 4: AUDYT LUK I DUPLIKATÓW (POZIOM ENTERPRISE) ──────────────────────
# Porównanie rule_id z MANIFEST.md, stuby i brakujące obszary (LEGAL_COVERAGE: 225 punktów).
gaps_duplicates_audit := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.gaps_duplicates_audit",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1150,
    "matched": true,
    "legal_coverage_gap": "LEGAL_COVERAGE.md: 225 punktów PCC+lokalne+akcyza — największa luka pokrycia (~1%)",
    "micro_total_rule_ids": object.get(p14_audit_data, "total_rule_ids", 328),
    "duplicates": object.get(p14_audit_data, "duplicate_count", 0),
    "stubs": object.get(p14_audit_data, "stub_count", 0),
    "missing_areas": ["opłata targowa — stawki per gmina", "opłata uzdrowiskowa", "tytoń — pełne stawki", "energia — stawki akcyzy"],
    "_routing": "",
    "_routing_reason": "Audyt luk i duplikatów — porównanie rule_id, stuby, brakujące obszary",
    "_legal_basis": "LEGAL_COVERAGE.md; MANIFEST.md",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# ── SEKCJA 5: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE TEMPORALNY ───────────────
local_taxes_pipeline_snapshot := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.local_taxes_pipeline_snapshot",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1160,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.pcc_local_excise (ADR-002) — stawki PCC, nieruchomości, akcyza",
        "step_2_generate": "reguły PCC (stawki, PCC-3) + lokalne (DN-1, transport) + akcyza (paliwa, alkohol)",
        "step_3_verify": "pcc_local_excise_auditor.py — walidacja spójności stawek",
        "step_4_emit": "hot-reload pakietów jdg.local_taxes / jdg.pcc / jdg.akcyza",
    },
    "auto_update": "stawki gminne zmieniają się co roku (uchwały rad gmin) → auto-aktualizacja thresholdów lokalnych",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji thresholdów lokalnych (ADR-002, hot-reload)",
    "_legal_basis": "ADR-002; uchwały rad gmin; obwieszczenia MF",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# ── SEKCJA 6: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-12) ────────────────────
# INN-01: pcc3_generator | INN-02: pcc_detector | INN-03: gmina_rates_registry
# INN-04: real_estate_tax_calculator | INN-05: transport_tax_calculator
# INN-06: dn1_tracker | INN-07: excise_fuel_calculator | INN-08: excise_alcohol_calculator
# INN-09: excise_cost_detector | INN-10: gmina_rates_hook | INN-11: excise_warehouse_tracker
# INN-12: pcc_local_excise_compliance_panel

# INN-10: Hook auto-aktualizacji stawek gminnych (thresholdy temporalne).
gmina_rates_hook := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.gmina_rates_hook",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1170,
    "matched": true,
    "source": "data.jdg.thresholds.pcc_local_excise (ADR-002)",
    "trigger": "zmiana stawek gminnych (uchwała rady gminy), nowelizacja ustawy o PCC/akcyzie",
    "steps": ["ingest", "generate", "verify", "emit"],
    "hot_reload": true,
    "_routing": "",
    "_routing_reason": "Hook auto-aktualizacji stawek gminnych (INN-10) — thresholdy temporalne",
    "_legal_basis": "ADR-002; uchwały rad gmin",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-11: Tracker składu podatkowego (akcyza).
excise_warehouse_tracker := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.excise_warehouse_tracker",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1171,
    "matched": true,
    "warehouse_registered": object.get(input.jdg_entrepreneur, "excise_warehouse_registered", false),
    "produces_alcohol": object.get(input.jdg_entrepreneur, "produces_alcohol", false),
    "produces_fuel": object.get(input.jdg_entrepreneur, "produces_fuel", false),
    "warehouse_required": object.get(input.jdg_entrepreneur, "produces_alcohol", false) == true or object.get(input.jdg_entrepreneur, "produces_fuel", false) == true,
    "alert": "produkcja alkoholu/paliw BEZ składu podatkowego = PRZESTĘPSTWO SKARBOWE (art. 65 KKS)",
    "note": "tracker składu podatkowego — obowiązek rejestracji dla producentów wyrobów akcyzowych",
    "_routing": "",
    "_routing_reason": "Tracker składu podatkowego (INN-11) — rejestracja, przestępstwo art. 65 KKS",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220); KKS art. 65",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-12: Panel zgodności PCC + lokalnych + akcyzy.
pcc_local_excise_compliance_panel := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.pcc_local_excise_compliance_panel",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1172,
    "matched": true,
    "checks": {
        "pcc3": "deklaracja PCC-3 w 14 dni (art. 10)",
        "dn1": "deklaracja DN-1 w 14 dni od nabycia nieruchomości",
        "transport": "podatek od środków transportowych >3,5t",
        "akcyza": "akcyza na paliwa/alkohol/tytoń/energię",
        "sklad_podatkowy": "rejestracja składu podatkowego (produkcja)",
        "stawki_gminne": "aktualne stawki gminne (rejestr)",
    },
    "compliance_score": 100 - to_number(object.get(input.jdg_entrepreneur, "pcc_penalties", 0)) * 10 if to_number(object.get(input.jdg_entrepreneur, "pcc_penalties", 0)) * 10 < 100 else 0,
    "_routing": "",
    "_routing_reason": "Panel zgodności PCC + lokalnych + akcyzy — compliance score (INN-12)",
    "_legal_basis": "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789); podatki lokalne; akcyza",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# ── SEKCJA 6b: NOWE INNOWACJE P14 v9.1 (INN-13..INN-17) ───────────────────────
# INN-13: AUTO-DETEKTOR OBOWIĄZKU PCC — analiza transakcji (kupno auta od osoby prywatnej!).
pcc_obligation_detector := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.pcc_obligation_detector",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1173,
    "matched": true,
    "transaction_type": object.get(input.transaction, "type", ""),
    "from_private_party": object.get(input.transaction, "from_private_party", false) == true,
    "vat_applicable": object.get(input.transaction, "vat_applicable", false) == true,
    "amount": to_number(object.get(input.transaction, "amount", 0)),
    "pcc_rate_pct": object.get(pcc_rates, "SALE_VEHICLE_PRIVATE", 2.0) if object.get(input.transaction, "type", "") == "kupno_pojazdu" else object.get(pcc_rates, "SALE_MOVABLE", 2.0) if object.get(input.transaction, "type", "") == "sprzedaz_rzeczy" else 0,
    "pcc_obligation": obligation,
    "tax_due": round2(to_number(object.get(input.transaction, "amount", 0)) * object.get(pcc_rates, "SALE_VEHICLE_PRIVATE", 2.0) / 100) if object.get(input.transaction, "type", "") == "kupno_pojazdu" and obligation else round2(to_number(object.get(input.transaction, "amount", 0)) * object.get(pcc_rates, "SALE_MOVABLE", 2.0) / 100) if object.get(input.transaction, "type", "") == "sprzedaz_rzeczy" and obligation else 0,
    "note": "kupno pojazdu od osoby prywatnej = obowiązek PCC 2% + PCC-3 w 14 dni (transakcje VAT wyłączone — art. 2 pkt 4)",
    "_routing": "TRIAGE_QUEUE" if obligation else "",
    "_routing_reason": "Auto-detektor obowiązku PCC — analiza transakcji, kupno od osoby prywatnej (INN-13)",
    "_legal_basis": "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789) art. 1, 4, 7; art. 2 pkt 4 (wyłączenie VAT)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
    obligation := object.get(input.transaction, "from_private_party", false) == true and object.get(input.transaction, "vat_applicable", false) != true and (object.get(input.transaction, "type", "") == "kupno_pojazdu" or object.get(input.transaction, "type", "") == "sprzedaz_rzeczy")
}

# INN-14: ZERO-CLICK PCC-3 — generowanie deklaracji + countdown 14 dni.
pcc3_zero_click := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.pcc3_zero_click",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1174,
    "matched": true,
    "transaction_type": object.get(input.transaction, "type", "SALE_MOVABLE"),
    "amount": to_number(object.get(input.transaction, "amount", 0)),
    "rate_pct": object.get(pcc_rates, object.get(input.transaction, "type", "SALE_MOVABLE"), 2.0),
    "tax_due": round2(to_number(object.get(input.transaction, "amount", 0)) * object.get(pcc_rates, object.get(input.transaction, "type", "SALE_MOVABLE"), 2.0) / 100),
    "days_elapsed": days_elapsed,
    "days_remaining": pcc3_deadline_days - days_elapsed if days_elapsed < pcc3_deadline_days else 0,
    "countdown": sprintf("PCC-3 w %v dni (termin: 14 dni od powstania obowiązku)", [pcc3_deadline_days - days_elapsed if days_elapsed < pcc3_deadline_days else 0]),
    "form_auto_generated": true,
    "submission_required": days_elapsed < pcc3_deadline_days,
    "urgency_alert": days_elapsed >= pcc3_deadline_days - 3,
    "note": "zero-click PCC-3 — kwota podatku, countdown 14 dni, formularz PCC-3/PCC-3/A",
    "_routing": "TRIAGE_QUEUE" if days_elapsed >= pcc3_deadline_days - 3 else "",
    "_routing_reason": "Zero-click PCC-3 — countdown 14 dni z alertem (INN-14)",
    "_legal_basis": "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789) art. 10",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
    days_elapsed := to_number(object.get(input.transaction, "days_elapsed", 0))
}

# INN-15: MAPA STAWEK GMINNYCH — rejestr per gmina z wersjonowaniem (temporalność).
gmina_rates_map := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.gmina_rates_map",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1175,
    "matched": true,
    "gmina": object.get(input.jdg_entrepreneur, "gmina", "domyślna"),
    "rates_current_year": real_estate_rates,
    "rates_previous_year": object.get(pcc_local_limits, "real_estate_rates_2025", {
        "land_business": 1.34, "building_business": 31.00, "construction_pct_value": 2.0,
    }),
    "land_rate_delta_pct": round2((object.get(real_estate_rates, "land_business", 1.43) - object.get(prev_2025, "land_business", 1.34)) / object.get(prev_2025, "land_business", 1.34) * 100) if object.get(prev_2025, "land_business", 1.34) != 0 else 0,
    "building_rate_delta_pct": round2((object.get(real_estate_rates, "building_business", 33.10) - object.get(prev_2025, "building_business", 31.00)) / object.get(prev_2025, "building_business", 31.00) * 100) if object.get(prev_2025, "building_business", 31.00) != 0 else 0,
    "rates_changed_ytd": object.get(real_estate_rates, "land_business", 1.43) != object.get(prev_2025, "land_business", 1.34) or object.get(real_estate_rates, "building_business", 33.10) != object.get(prev_2025, "building_business", 31.00),
    "versioning": "wersjonowanie stawek gminnych — uchwała + data obowiązywania (Law Radar F5)",
    "note": "mapa stawek gminnych — rejestr per gmina z porównaniem rok do roku",
    "_routing": "",
    "_routing_reason": "Mapa stawek gminnych — rejestr z wersjonowaniem i deltą YoY (INN-15)",
    "_legal_basis": "ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234); obwieszczenia MF",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
    prev_2025 := object.get(pcc_local_limits, "real_estate_rates_2025", {"land_business": 1.34, "building_business": 31.00, "construction_pct_value": 2.0})
}

# INN-16: REKOMENDACJA STRUKTURY TRANSAKCJI — VAT vs PCC (optymalizacja legalna).
vat_vs_pcc_optimizer := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.vat_vs_pcc_optimizer",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1176,
    "matched": true,
    "transaction_type": object.get(input.transaction, "type", "kupno_pojazdu"),
    "amount": to_number(object.get(input.transaction, "amount", 0)),
    "buyer_vat_deductible": object.get(input.transaction, "buyer_vat_deductible", false) == true,
    "vat_cost": round2(to_number(object.get(input.transaction, "amount", 0)) * 0.23) if object.get(input.transaction, "buyer_vat_deductible", false) != true else 0,
    "pcc_cost": round2(to_number(object.get(input.transaction, "amount", 0)) * object.get(pcc_rates, "SALE_VEHICLE_PRIVATE", 2.0) / 100) if object.get(input.transaction, "from_private_party", false) == true else 0,
    "recommendation": "OD_OSOBY_PRYWATNEJ_PCC_2" if object.get(input.transaction, "buyer_vat_deductible", false) != true and object.get(input.transaction, "from_private_party", false) == true else "OD_FIRMY_VAT_ODLICZENIE" if object.get(input.transaction, "buyer_vat_deductible", false) == true else "ANALIZA",
    "note": "legalna optymalizacja struktury transakcji — VAT 23% vs PCC 2% (kupno od osoby prywatnej gdy brak odliczenia)",
    "_routing": "TRIAGE_QUEUE" if object.get(input.transaction, "from_private_party", false) == true and object.get(input.transaction, "buyer_vat_deductible", false) != true else "",
    "_routing_reason": "Rekomendacja struktury transakcji — VAT vs PCC (optymalizacja legalna, INN-16)",
    "_legal_basis": "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789) art. 2 pkt 4; VAT art. 86 (odliczenie)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}

# INN-17: WYKRYWACZ OBOWIĄZKU AKCYZOWEGO W IMPORCIE (spójność z P12).
excise_import_detector := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.excise_import_detector",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1177,
    "matched": true,
    "imported_goods": object.get(input.import_goods, "goods", ""),
    "goods_desc": desc,
    "excise_goods": excise_goods,
    "obligation": "zgłoszenie akcyzowe + zabezpieczenie akcyzowe przy imporcie wyrobów akcyzowych z państwa trzeciego",
    "alcohol_import_note": "import alkoholu — obowiązek banderolowania / skład podatkowy",
    "fuel_import_note": "import paliw — zabezpieczenie akcyzowe przed dopuszczeniem do obrotu",
    "cross_border_integration": "spójność z P12 (cross-border) — dokumenty celne + akcyza",
    "_routing": "TRIAGE_QUEUE" if excise_goods else "",
    "_routing_reason": "Wykrywacz obowiązku akcyzowego w imporcie (INN-17) — spójność P12",
    "_legal_basis": "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) art. 39-41 (import); ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
    desc := lower(object.get(input.import_goods, "goods", ""))
    excise_goods := contains(desc, "benzyna") or contains(desc, "paliwo") or contains(desc, "olej napędowy") or contains(desc, "lpg") or contains(desc, "alkohol") or contains(desc, "wino") or contains(desc, "piwo") or contains(desc, "tytoń") or contains(desc, "papieros") or contains(desc, "węgiel") or contains(desc, "energia")
}

# ── GŁÓWNY DECIDE (P14) — raport syntetyczny PCC + Lokalne + Akcyza ───────────
decide := {
    "rule_id": "jdg.p14_pcc_lokalne_akcyza_innovations.report",
    "package": "jdg.p14_pcc_lokalne_akcyza_innovations",
    "priority": 1157,
    "matched": true,
    "pcc": pcc_audit,
    "local_taxes": local_taxes_audit,
    "excise": excise_audit,
    "gaps": gaps_duplicates_audit,
    "pipeline": local_taxes_pipeline_snapshot,
    "pcc_detector": pcc_obligation_detector,
    "pcc3_click": pcc3_zero_click,
    "gmina_map": gmina_rates_map,
    "vat_pcc": vat_vs_pcc_optimizer,
    "excise_import": excise_import_detector,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny PCC + Lokalne + Akcyza (P14) — czynności, stawki, DN-1, transport, akcyza, luki",
    "_legal_basis": "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789); podatki i opłaty lokalne; ustawa o podatku akcyzowym",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p14_pcc_check", false) == true
}
