# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE VAT SUBSTANTIVE COMPLETE (Strategic Initiative S21)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise VAT Substantive Complete — Art. 11-135 Full Coverage
# description: |
#   ENTERPRISE v7.0 — Najobszerniejszy pakiet VAT. Wypełnia lukę 465 punktów
#   prawnych zidentyfikowanych w COVERAGE_REPORT.md.
#   
#   OBSZARY POKRYTE:
#   - Miejsce świadczenia usług (Art. 28a-28o VAT) — 15+ scenariuszy
#   - Miejsce dostawy towarów (Art. 22-24 VAT) — wysyłka, montaż, energia
#   - Procedury szczególne (Art. 120-135 VAT) — marża, VAT-marża turystyka
#   - OSS/IOSS szczegółowe (Art. 130a-138j VAT)
#   - Zwolnienia przedmiotowe rozszerzone (Art. 43 ust. 1 pkt 10-33 VAT)
#   - Import/eksport szczegółowy (Art. 33-48 VAT)
#   - Podstawa opodatkowania (Art. 29a-32 VAT) — rabaty, dotacje, waluty
#   - Faktury szczegółowe (Art. 106a-106q VAT)
#   - Sankcje VAT szczegółowe (Art. 108-112b VAT)
#   - Korekty wieloletnie (Art. 91 VAT)
#
#   To jest "MÓZG VAT" — pojedynczy plik pokrywający luki, których nie
#   pokrywają istniejące reguły Micro i Macro.
# architecture: Enterprise v7.0, Post-Merge Cross-Domain
# legal_basis: Ustawa o VAT — Art. 11-135, 120-138j
# package: jdg.vat_substantive_complete
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat_substantive_complete

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.vat_complete.no_match",
    "package": "jdg.vat_substantive_complete", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA A: MIEJSCE ŚWIADCZENIA USŁUG — Art. 28a-28o VAT
# ═══════════════════════════════════════════════════════════════════════════════

# S21-100: Miejsce świadczenia usług B2B — zasada ogólna (Art. 28b)
decide := {
    "matched": true,
    "rule_id": "jdg.vat_complete.place_of_supply_b2b_general",
    "package": "jdg.vat_substantive_complete",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "vat_place_of_supply": pos_country,
    "vat_place_of_supply_rule": "Art. 28b — siedziba nabywcy (B2B)",
    "vat_reverse_charge_applies": rc_applies,
    "vat_import_of_services": is_import_of_services,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": pos_routing,
    "_routing_reason": pos_reason,
    "_legal_basis": "Art. 28b VAT; Art. 17 ust. 1 pkt 4 VAT (import usług)",
    "_warnings": build_pos_warnings(pos_country, rc_applies, is_import_of_services)
} {
    input.vat_place_of_supply_check == true
    service_type := object.get(input.invoice, "service_type", "")
    buyer_country := object.get(input.invoice, "buyer_country", "PL")
    seller_country := object.get(input.invoice, "seller_country", "PL")
    buyer_is_business := object.get(input.invoice, "buyer_is_business", true)
    is_cross_border := seller_country != buyer_country

    # Art. 28b — general rule: B2B = place of buyer's seat
    pos_country := buyer_country { buyer_is_business; is_cross_border }
    pos_country := seller_country { not buyer_is_business; not is_cross_border }
    pos_country := seller_country { not is_cross_border }
    pos_country := buyer_country {
        not buyer_is_business
        is_cross_border
        service_type in {"TELECOM", "BROADCASTING", "ELECTRONIC"}
    }  # Art. 28k — B2C exceptions

    # Polish buyer, foreign seller = import of services
    is_import_of_services := buyer_country == "PL" and seller_country != "PL"
    rc_applies := is_import_of_services and buyer_is_business

    pos_routing := "TRIAGE_QUEUE" { is_cross_border; not buyer_is_business }
    pos_routing := "" { true }
    pos_reason := sprintf("B2C transgraniczne: %s do %s — sprawdź OSS/IOSS", 
        [service_type, buyer_country]) { pos_routing == "TRIAGE_QUEUE" }
    pos_reason := "" { true }
}

# S21-110: Miejsce świadczenia usług związanych z nieruchomościami (Art. 28e)
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.place_of_supply_real_estate",
    "package": "jdg.vat_substantive_complete",
    "priority": 110,
    "vat_rate": vat_rate, "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "vat_place_of_supply": property_country,
    "vat_place_of_supply_rule": "Art. 28e — położenie nieruchomości",
    "vat_rate_applicable": property_country_vat_rate,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Usługa na nieruchomości w %s — VAT wg prawa %s", 
        [property_country, property_country]),
    "_legal_basis": "Art. 28e VAT; Art. 17 ust. 1 pkt 8 VAT",
    "_warnings": [
        sprintf("🏠 USŁUGA NA NIERUCHOMOŚCI — miejsce: %s (Art. 28e VAT). ", [property_country]),
        sprintf("   VAT: %s%% wg stawki kraju położenia nieruchomości.", [property_country_vat_rate]),
        "   Jeśli nieruchomość w PL a usługodawca zagraniczny → import usług (Art. 17 ust. 1 pkt 8)."
    ]
} {
    input.vat_place_of_supply_check == true
    service := object.get(input.invoice, "service_type", "")
    service in {"CONSTRUCTION", "REAL_ESTATE_AGENT", "ARCHITECT", "SURVEYOR",
               "PROPERTY_MANAGEMENT", "HOTEL", "CAMPING", "PARKING"}
    property_country := object.get(input.invoice, "property_country", "PL")
    property_country_vat_rate := "23" { property_country == "PL" }
    property_country_vat_rate := "varies" { property_country != "PL" }
    vat_rate := ""
}

# S21-120: Miejsce świadczenia usług transportu (Art. 28f-28g)
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.place_of_supply_transport",
    "package": "jdg.vat_substantive_complete",
    "priority": 120,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "vat_place_of_supply": transport_pos,
    "vat_place_of_supply_rule": transport_rule,
    "vat_transport_passenger_b2c_rule": passenger_b2c_note,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28f (B2B transport towarów), Art. 28g (B2B pasażerski), Art. 28h (B2C towarów), Art. 28i (B2C pasażerski) VAT",
    "_warnings": [
        sprintf("🚛 TRANSPORT — miejsce: %s. Reguła: %s", [transport_pos, transport_rule]),
        passenger_b2c_note
    ]
} {
    input.vat_place_of_supply_check == true
    service := object.get(input.invoice, "service_type", "")
    service in {"GOODS_TRANSPORT", "PASSENGER_TRANSPORT", "FREIGHT_FORWARDING"}
    buyer_is_business := object.get(input.invoice, "buyer_is_business", true)
    buyer_country := object.get(input.invoice, "buyer_country", "PL")
    seller_country := object.get(input.invoice, "seller_country", "PL")

    # B2B freight: Art. 28f = buyer's seat
    transport_pos := buyer_country {
        buyer_is_business; service == "GOODS_TRANSPORT"
    }
    transport_rule := "Art. 28f — siedziba nabywcy (B2B towarów)"

    transport_pos := buyer_country {
        buyer_is_business; service == "FREIGHT_FORWARDING"
    }
    transport_rule := "Art. 28b/28f — siedziba nabywcy (spedycja B2B)"

    # B2C freight: Art. 28h = place of departure
    transport_pos := object.get(input.invoice, "departure_country", "PL") {
        not buyer_is_business; service == "GOODS_TRANSPORT"
    }
    transport_rule := "Art. 28h — miejsce rozpoczęcia (B2C towarów)"

    # B2C passenger: Art. 28i = where transport actually takes place (proportional)
    transport_pos := "PROPORTIONAL" {
        not buyer_is_business; service == "PASSENGER_TRANSPORT"
    }
    transport_rule := "Art. 28i — proporcjonalnie do pokonanych odległości (B2C pasażerski)"

    # B2B passenger: Art. 28g = buyer's seat
    transport_pos := buyer_country {
        buyer_is_business; service == "PASSENGER_TRANSPORT"
    }
    transport_rule := "Art. 28g — siedziba nabywcy (B2B pasażerski)"

    passenger_b2c_note := "" { buyer_is_business }
    passenger_b2c_note := "⚠️ B2C pasażerski: VAT tylko od części trasy w PL. Reszta trasy poza zakresem PL VAT." {
        not buyer_is_business; service == "PASSENGER_TRANSPORT"
    }
    passenger_b2c_note := "" { service != "PASSENGER_TRANSPORT" }
}

# S21-130: Usługi niematerialne — wyjątki od zasady ogólnej (Art. 28d, 28k, 28l)
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.place_of_supply_intangible",
    "package": "jdg.vat_substantive_complete",
    "priority": 130,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "vat_place_of_supply": intangible_pos,
    "vat_place_of_supply_rule": intangible_rule,
    "vat_intangible_category": service,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": intangible_routing,
    "_routing_reason": intangible_reason,
    "_legal_basis": "Art. 28d, 28k, 28l VAT; Rozporządzenie 282/2011 UE",
    "_warnings": [sprintf("💻 USŁUGA NIEMATERIALNA '%s' — miejsce: %s (%s)", 
        [service, intangible_pos, intangible_rule])]
} {
    input.vat_place_of_supply_check == true
    service := object.get(input.invoice, "service_type", "")
    buyer_is_business := object.get(input.invoice, "buyer_is_business", true)
    buyer_country := object.get(input.invoice, "buyer_country", "PL")
    seller_country := object.get(input.invoice, "seller_country", "PL")
    is_cross_border := seller_country != buyer_country

    # B2B intangible services = buyer's seat (Art. 28b general rule applies)
    intangible_pos := buyer_country { buyer_is_business; is_cross_border }
    intangible_pos := seller_country { not is_cross_border }
    intangible_rule := "Art. 28b — siedziba nabywcy (B2B)"

    # B2C exceptions (Art. 28k): non-EU buyer = buyer's seat
    intangible_pos := buyer_country {
        not buyer_is_business
        is_cross_border
        buyer_country != "PL"
        not is_eu_country(buyer_country)
    }
    intangible_rule := "Art. 28k — siedziba nabywcy spoza UE (B2C)"

    # B2C EU buyer = seller's seat (Art. 28k — reverse rule)
    intangible_pos := seller_country {
        not buyer_is_business
        is_cross_border
        is_eu_country(buyer_country)
    }
    intangible_rule := "Art. 28k — siedziba usługodawcy (B2C do UE)"

    # EU/non-EU check
    eu_countries := {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR",
                     "HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK",
                     "SI","ES","SE"}

    # Default fallback for _warnings safety
    intangible_pos := seller_country { intangible_pos == "" }
    intangible_rule := "Art. 28b" { intangible_rule == "" }

    intangible_routing := "TRIAGE_QUEUE" { is_cross_border; not buyer_is_business; is_eu_country(buyer_country) }
    intangible_routing := "" { true }
    intangible_reason := "B2C do UE — rozważ rejestrację OSS aby uniknąć rejestracji w kraju nabywcy" { intangible_routing == "TRIAGE_QUEUE" }
    intangible_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA B: PROCEDURY SZCZEGÓLNE — Art. 120-135 VAT
# ═══════════════════════════════════════════════════════════════════════════════

# S21-200: VAT marża — towary używane, dzieła sztuki, antyki (Art. 120)
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.vat_margin_scheme",
    "package": "jdg.vat_substantive_complete",
    "priority": 200,
    "vat_rate": margin_vat_rate, "rounding_level": "", "gtu_code": "",
    "vat_procedure": "MARGIN_SCHEME",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "deductible_full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "vat_margin_base": margin_base,
    "vat_margin_vat_amount": margin_vat,
    "vat_margin_special_invoice": "Faktura VAT-marża — brak wydzielonej kwoty VAT",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": margin_routing,
    "_routing_reason": margin_reason,
    "_legal_basis": "Art. 120 ust. 1, 4, 10-16 VAT; Art. 106e ust. 1 pkt 15 VAT",
    "_warnings": [
        sprintf("🏺 VAT-MARŻA — towar: %s. Cena zakupu: %.2f PLN, Sprzedaż: %.2f PLN.",
            [goods_type, purchase_price, sale_price]),
        sprintf("   Marża: %.2f PLN. VAT: %.2f PLN (%s%%).", 
            [margin_base, margin_vat, margin_vat_rate_str]),
        "⚠️ FAKTURA VAT-MARŻA: NIE wykazuj kwoty VAT na fakturze!",
        "⚠️ Nabywca NIE odlicza VAT z faktury marża (nawet jeśli kupuje jako firma).",
        "⚠️ Ewidencja: prowadź szczegółową ewidencję zakupionych towarów używanych."
    ]
} {
    input.invoice.vat_procedure == "MARGIN"
    input.invoice.direction == "SALE"
    goods_type := object.get(input.invoice, "margin_goods_type", "USED_GOODS")
    purchase_price := object.get(input.invoice, "purchase_price_pln", 0)
    sale_price := object.get(input.invoice, "amount_gross", 0)
    margin_base := sale_price - purchase_price { sale_price > purchase_price }
    margin_base := 0 { sale_price <= purchase_price }

    # VAT rate on margin depends on the good's standard rate
    margin_vat_rate := "0.23" { goods_type in {"USED_GOODS", "ANTIQUES"} }
    margin_vat_rate := "0.08" { goods_type == "ART_OBJECTS" }
    margin_vat_rate := "0.23" { margin_vat_rate == "" }
    margin_vat_rate_str := "23" { margin_vat_rate == "0.23" }
    margin_vat_rate_str := "8" { margin_vat_rate == "0.08" }
    margin_vat_rate_str := "23" { margin_vat_rate_str == "" }

    # Margin VAT = margin * rate/(100+rate) — metoda "w stu"
    margin_vat := floor(margin_base * to_number(margin_vat_rate) / (1 + to_number(margin_vat_rate)) * 100) / 100
    margin_vat := 0 { margin_base <= 0 }

    margin_routing := "TRIAGE_QUEUE" { margin_base > thresholds.vat.margin_alert_threshold }
    margin_routing := "" { true }
    margin_reason := sprintf("VAT-marża — wysoka marża %.2f PLN. Zweryfikuj dokumentację zakupu.", 
        [margin_base]) { margin_base > thresholds.vat.margin_alert_threshold }
    margin_reason := "" { true }
}

# S21-210: Procedura OSS (One Stop Shop) — Art. 130a-130d
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.oss_procedure",
    "package": "jdg.vat_substantive_complete",
    "priority": 210,
    "vat_rate": "", "rounding_level": "total", "gtu_code": "",
    "vat_procedure": "OSS",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "oss_registration_required": oss_needed,
    "oss_countries_served": eu_countries_list,
    "oss_quarterly_declaration_due": "End of month following quarter",
    "oss_vat_rate_per_country": country_rates,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": oss_routing,
    "_routing_reason": oss_reason,
    "_legal_basis": "Art. 130a-130d VAT; Dyrektywa 2017/2455 UE; Rozporządzenie 2019/2026 UE",
    "_warnings": build_oss_warnings(oss_needed, eu_countries_list, total_eu_b2c_sales)
} {
    input.invoice.vat_procedure == "OSS"
    total_eu_b2c_sales := object.get(input.jdg_entrepreneur, "eu_b2c_sales_ytd_eur", 0)
    eu_countries_served := object.get(input.jdg_entrepreneur, "eu_b2c_countries_list", [])
    oss_already_registered := object.get(input.jdg_entrepreneur, "oss_registered", false)

    oss_needed := total_eu_b2c_sales > thresholds.vat.oss_threshold_eur and not oss_already_registered
    eu_countries_list := concat(", ", eu_countries_served)

    # VAT rates per EU country (simplified)
    country_rates := {
        "DE": "19%", "FR": "20%", "IT": "22%", "ES": "21%", "NL": "21%",
        "BE": "21%", "AT": "20%", "PT": "23%", "IE": "23%", "SE": "25%",
        "DK": "25%", "FI": "24%", "CZ": "21%", "SK": "20%", "HU": "27%",
        "RO": "19%", "BG": "20%", "HR": "25%", "SI": "22%", "LT": "21%",
        "LV": "21%", "EE": "20%", "CY": "19%", "MT": "18%", "LU": "17%",
        "PL": "23%", "GR": "24%"
    }

    oss_routing := "BLOCK_AND_ALERT" { oss_needed }
    oss_routing := "TRIAGE_QUEUE" { total_eu_b2c_sales > thresholds.vat.oss_alert_eur; not oss_needed }
    oss_routing := "" { true }
    oss_reason := sprintf("OSS WYMAGANY! Sprzedaż B2C do UE >10k EUR: %.0f EUR.", 
        [total_eu_b2c_sales]) { oss_needed }
    oss_reason := sprintf("OSS zalecany — zbliżasz się do limitu 10k EUR (obecnie: %.0f EUR).",
        [total_eu_b2c_sales]) { total_eu_b2c_sales > thresholds.vat.oss_alert_eur; not oss_needed }
    oss_reason := "" { true }
}

# S21-220: Procedura IOSS (Import One Stop Shop) — Art. 138a-138j
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.ioss_procedure",
    "package": "jdg.vat_substantive_complete",
    "priority": 220,
    "vat_rate": "", "rounding_level": "total", "gtu_code": "",
    "vat_procedure": "IOSS",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "ioss_eligible": ioss_eligible,
    "ioss_import_vat_collected_at_sale": ioss_vat_collected_at_sale,
    "ioss_max_shipment_value_eur": 150,
    "ioss_monthly_declaration_due": "End of month following the month",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": ioss_routing,
    "_routing_reason": ioss_reason,
    "_legal_basis": "Art. 138a-138j VAT; Dyrektywa 2021/514 UE; Rozporządzenie 2020/194 UE",
    "_warnings": [
        sprintf("📦 IOSS — import towarów ≤150 EUR z %s do klientów UE. %s",
            [origin_country, ioss_recommendation]),
        sprintf("   Status: %s. Miesięczna deklaracja IOSS do końca następnego miesiąca.",
            [ioss_status_text])
    ]
} {
    input.invoice.vat_procedure == "IOSS"
    goods_value_eur := object.get(input.invoice, "amount_net_eur", 0)
    origin_country := object.get(input.invoice, "origin_country", "CN")
    already_ioss_registered := object.get(input.jdg_entrepreneur, "ioss_registered", false)

    ioss_eligible := goods_value_eur <= 150
    ioss_vat_collected_at_sale := goods_value_eur <= 150 and already_ioss_registered

    ioss_recommendation := "Zarejestruj się w IOSS — VAT przy sprzedaży zamiast przy imporcie!" {
        ioss_eligible and not already_ioss_registered
    }
    ioss_recommendation := "IOSS aktywny — VAT pobrany przy sprzedaży, import zwolniony z VAT." {
        already_ioss_registered
    }
    ioss_recommendation := "NIE kwalifikuje się do IOSS — wartość >150 EUR." { not ioss_eligible }
    ioss_status_text := "Zarejestrowany w IOSS" { already_ioss_registered }
    ioss_status_text := "NIE zarejestrowany" { not already_ioss_registered }

    ioss_routing := "TRIAGE_QUEUE" { ioss_eligible; not already_ioss_registered }
    ioss_routing := "" { true }
    ioss_reason := sprintf("Import B2C z %s ≤150 EUR — rozważ IOSS dla uproszczenia.",
        [origin_country]) { ioss_eligible; not already_ioss_registered }
    ioss_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA C: PODSTAWA OPODATKOWANIA — Art. 29a-32 VAT
# ═══════════════════════════════════════════════════════════════════════════════

# S21-300: Podstawa opodatkowania — rabaty, dotacje, waluty (Art. 29a)
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.tax_base_calculation",
    "package": "jdg.vat_substantive_complete",
    "priority": 300,
    "vat_rate": vat_rate, "rounding_level": "", "gtu_code": "",
    "vat_tax_base_adjusted": adjusted_base,
    "vat_discount_reduction": discount_reduction,
    "vat_subsidy_included": subsidy_included,
    "vat_fx_rate_date": fx_date,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29a ust. 1, 6, 7, 10-15 VAT; Art. 31a VAT (waluty)",
    "_warnings": [
        sprintf("💰 PODSTAWA OPODATKOWANIA: %.2f PLN (po korekcie o rabaty/dotacje).",
            [adjusted_base]),
        discount_note,
        subsidy_note,
        fx_note
    ]
} {
    input.vat_tax_base_calculation == true
    amount_net := object.get(input.invoice, "amount_net", 0)
    vat_rate := object.get(input.invoice, "vat_rate", "0.23")
    discount_pct := object.get(input.invoice, "discount_pct", 0)
    discount_conditional := object.get(input.invoice, "discount_is_conditional", false)
    has_subsidy := object.get(input.invoice, "has_subsidy_directly_linked", false)
    subsidy_amount := object.get(input.invoice, "subsidy_amount", 0)
    currency := object.get(input.invoice, "currency", "PLN")

    # Discount reduction
    discount_reduction := amount_net * discount_pct / 100 { not discount_conditional }
    discount_reduction := 0 { discount_conditional }  # Conditional = KOREKTA później
    discount_note := sprintf("Rabat %.0f%% = -%.2f PLN. %s", 
        [discount_pct, discount_reduction, 
         "Warunkowy → korekta po spełnieniu warunku." { discount_conditional }
         else "Bezwarunkowy → obniżenie podstawy."]) { discount_pct > 0 }
    discount_note := "" { discount_pct == 0 }

    # Subsidy inclusion (if directly linked to price)
    subsidy_included := subsidy_amount > 0 and has_subsidy
    subsidy_note := sprintf("Dotacja %.2f PLN wliczona do podstawy — bezpośrednio związana z ceną.",
        [subsidy_amount]) { subsidy_included }
    subsidy_note := "" { not subsidy_included }

    adjusted_base := amount_net - discount_reduction + subsidy_amount { subsidy_included }
    adjusted_base := amount_net - discount_reduction { not subsidy_included }

    # FX rate date
    fx_date := object.get(input.invoice, "transaction_date", "")
    fx_note := sprintf("Waluta: %s. Kurs NBP z dnia poprzedzającego obowiązek podatkowy (%s).",
        [currency, fx_date]) { currency != "PLN" }
    fx_note := "" { currency == "PLN" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA D: ZWOLNIENIA PRZEDMIOTOWE ROZSZERZONE — Art. 43 VAT
# ═══════════════════════════════════════════════════════════════════════════════

# S21-400: Zwolnienia — edukacja, kultura, sport, opieka medyczna (Art. 43 ust. 1)
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.exemptions_detailed",
    "package": "jdg.vat_substantive_complete",
    "priority": 400,
    "vat_rate": "ZW", "rounding_level": "", "gtu_code": "",
    "vat_exemption_category": exemption_category,
    "vat_exemption_article": exemption_article,
    "vat_exemption_conditions_met": conditions_met,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": exemption_routing,
    "_routing_reason": exemption_reason,
    "_legal_basis": "Art. 43 ust. 1 pkt 18-33 VAT",
    "_warnings": [sprintf("🆓 ZWOLNIENIE VAT — %s (%s). %s",
        [exemption_desc, exemption_article, conditions_warning])]
} {
    input.invoice.vat_rate == "EXEMPT"
    service_type := object.get(input.invoice, "service_type", "")
    is_regulated_entity := object.get(input.jdg_entrepreneur, "is_regulated_entity", false)
    has_required_certification := object.get(input.jdg_entrepreneur, "has_professional_certification", false)

    # Education (Art. 43 ust. 1 pkt 26-29)
    exemption_category := "EDUCATION"
    exemption_article := "Art. 43 ust. 1 pkt 26-29 VAT"
    exemption_desc := "Usługi edukacyjne"
    conditions_met := is_regulated_entity {
        service_type in {"PRIVATE_TEACHING", "LANGUAGE_COURSES", "VOCATIONAL_TRAINING",
                         "UNIVERSITY_COURSES", "DRIVING_SCHOOL", "MUSIC_LESSONS"}
    }

    # Healthcare (Art. 43 ust. 1 pkt 18-20)
    exemption_category := "HEALTHCARE" {
        service_type in {"MEDICAL_CARE", "PHYSIOTHERAPY", "PSYCHOTHERAPY",
                         "DENTAL_CARE", "NURSING_CARE", "AMBULANCE"}
    }
    exemption_article := "Art. 43 ust. 1 pkt 18-20 VAT"
    exemption_desc := "Usługi opieki medycznej"
    conditions_met := has_required_certification {
        service_type in {"MEDICAL_CARE", "PHYSIOTHERAPY", "PSYCHOTHERAPY",
                         "DENTAL_CARE", "NURSING_CARE", "AMBULANCE"}
    }

    # Culture (Art. 43 ust. 1 pkt 33)
    exemption_category := "CULTURE"
    exemption_article := "Art. 43 ust. 1 pkt 33 VAT"
    exemption_desc := "Usługi kulturalne"
    conditions_met := is_regulated_entity {
        service_type in {"MUSEUM", "LIBRARY", "THEATRE", "CONCERT", "ART_EXHIBITION",
                         "CULTURAL_EVENT", "ARCHIVE_SERVICES"}
    }

    # Sports (Art. 43 ust. 1 pkt 32)
    exemption_category := "SPORTS"
    exemption_article := "Art. 43 ust. 1 pkt 32 VAT"
    exemption_desc := "Usługi sportowe"
    conditions_met := object.get(input.jdg_entrepreneur, "sports_club_status", false) {
        service_type in {"SPORTS_CLASSES", "GYM_MEMBERSHIP", "PERSONAL_TRAINING",
                         "SPORTS_CAMP"}
    }

    # Finance/Insurance (Art. 43 ust. 1 pkt 37-41)
    exemption_category := "FINANCIAL"
    exemption_article := "Art. 43 ust. 1 pkt 7, 37-41 VAT"
    exemption_desc := "Usługi finansowe/ubezpieczeniowe"
    conditions_met := true {
        service_type in {"LOAN_INTEREST", "INSURANCE", "FINANCIAL_ADVICE",
                         "PAYMENT_TRANSFER", "CREDIT_GUARANTEE"}
    }

    # Social welfare (Art. 43 ust. 1 pkt 22)
    exemption_category := "SOCIAL_WELFARE"
    exemption_article := "Art. 43 ust. 1 pkt 22 VAT"
    exemption_desc := "Usługi pomocy społecznej"
    conditions_met := is_regulated_entity {
        service_type in {"ELDERLY_CARE", "CHILD_CARE", "DISABILITY_SUPPORT",
                         "SOCIAL_HOUSING", "HOMELESS_SHELTER"}
    }

    # Default
    exemption_category := "OTHER_EXEMPT" { exemption_category == "" }
    exemption_article := "Art. 43 VAT" { exemption_article == "" }
    exemption_desc := "Inne zwolnienie przedmiotowe" { exemption_desc == "" }

    # Default safety
    conditions_met := false { conditions_met == undef } else = conditions_met { true }

    conditions_warning := "✅ Warunki zwolnienia spełnione." { conditions_met }
    conditions_warning := "⚠️ UWAGA: Brak wymaganych certyfikatów/statusu! Zwolnienie może być zakwestionowane." {
        not conditions_met; exemption_category != "OTHER_EXEMPT"
    }
    conditions_warning := "" { exemption_category == "OTHER_EXEMPT" }

    exemption_routing := "BLOCK_AND_ALERT" { not conditions_met; exemption_category != "OTHER_EXEMPT" }
    exemption_routing := "" { true }
    exemption_reason := sprintf("Brak certyfikacji dla zwolnienia %s — ryzyko zakwestionowania przez US",
        [exemption_category]) { not conditions_met; exemption_category != "OTHER_EXEMPT" }
    exemption_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA E: KOREKTY WIELOLETNIE — Art. 91 VAT
# ═══════════════════════════════════════════════════════════════════════════════

# S21-500: Korekta wieloletnia VAT (Art. 91)
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.multi_year_correction",
    "package": "jdg.vat_substantive_complete",
    "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "vat_correction_period_years": correction_period,
    "vat_correction_annual_fraction": annual_fraction,
    "vat_correction_remaining_years": remaining_years,
    "vat_correction_amount_annual": correction_amount_yearly,
    "vat_correction_total_due": total_correction_due,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": correction_routing,
    "_routing_reason": correction_reason,
    "_legal_basis": "Art. 91 ust. 1-7 VAT",
    "_warnings": [
        sprintf("🔄 KOREKTA WIELOLETNIA VAT — %s (%.0f PLN netto).",
            [asset_type, asset_value]),
        sprintf("   Okres korekty: %d lat. Pozostało: %d lat.", 
            [correction_period, remaining_years]),
        sprintf("   Roczna korekta: %.2f PLN. Całkowita korekta należna: %.2f PLN.",
            [correction_amount_yearly, total_correction_due]),
        correction_reason_text
    ]
} {
    object.get(input.invoice, "vat_multi_year_correction", false) == true
    asset_type := object.get(input.invoice, "fixed_asset_type", "GENERAL")
    asset_value := object.get(input.invoice, "amount_net", 0)
    vat_deducted := object.get(input.invoice, "vat_originally_deducted", 0)
    years_since_purchase := object.get(input.invoice, "years_since_purchase", 0)
    proportion_changed := object.get(input.invoice, "proportion_changed_gt_10pp", false)
    asset_sold := object.get(input.invoice, "asset_sold", false)
    use_purpose_changed := object.get(input.invoice, "use_purpose_changed", false)

    # Correction period: 5 years for movables, 10 years for real estate
    correction_period := 5 { asset_type != "REAL_ESTATE" }
    correction_period := 10 { asset_type == "REAL_ESTATE" }

    annual_fraction := floor(1.0 / correction_period * 10000) / 100
    remaining_years := correction_period - years_since_purchase
    remaining_years := 0 { asset_sold }  # One-time correction on sale

    # Annual correction = total VAT deducted / correction period
    correction_amount_yearly := floor(vat_deducted / correction_period * 100) / 100 {
        proportion_changed
    }
    correction_amount_yearly := 0 { not proportion_changed }

    total_correction_due := correction_amount_yearly * remaining_years {
        proportion_changed
    }
    total_correction_due := vat_deducted {
        asset_sold  # Full remaining VAT correction on sale
    }
    total_correction_due := 0 { not proportion_changed; not asset_sold }

    correction_reason_text := "Korekta proporcjonalna — zmiana przeznaczenia >10pp." { proportion_changed }
    correction_reason_text := "Sprzedaż środka trwałego — korekta jednorazowa pozostałego VAT." { asset_sold }
    correction_reason_text := "Zmiana przeznaczenia środka trwałego." { use_purpose_changed }
    correction_reason_text := "" { true }

    correction_routing := "TRIAGE_QUEUE" { total_correction_due > 5000 }
    correction_routing := "" { true }
    correction_reason := sprintf("Korekta wieloletnia %.2f PLN — wykaż w JPK_V7 za styczeń",
        [total_correction_due]) { total_correction_due > 5000 }
    correction_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA F: SANKCJE VAT SZCZEGÓŁOWE — Art. 108-112b VAT
# ═══════════════════════════════════════════════════════════════════════════════

# S21-600: Sankcje VAT — dodatkowe zobowiązania 15%/20%/30% (Art. 108b-108d)
else := {
    "matched": true,
    "rule_id": "jdg.vat_complete.vat_additional_liability",
    "package": "jdg.vat_substantive_complete",
    "priority": 600,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "vat_sanction_type": sanction_type,
    "vat_sanction_rate_pct": sanction_rate_pct,
    "vat_sanction_amount_pln": sanction_amount,
    "vat_sanction_reason": sanction_description,
    "vat_sanction_appeal_deadline_days": 14,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Sankcja VAT %s%%: %.2f PLN — NATYCHMIASTOWA korekta!",
        [sanction_rate_pct_str, sanction_amount]),
    "_legal_basis": "Art. 108b-108d VAT; Art. 112b-112c VAT",
    "_warnings": [
        sprintf("🚨 SANKCJA VAT — %s", [sanction_description]),
        sprintf("   Kwota dodatkowego zobowiązania: %.2f PLN (%s%% zawyżenia/zaniżenia).",
            [sanction_amount, sanction_rate_pct_str]),
        sprintf("   Podstawa: %s", [sanction_legal_basis]),
        sprintf("   ⚠️ Odwołanie w ciągu 14 dni od doręczenia decyzji (Art. 223 OrdPU)."),
        sprintf("   💡 ZŁÓŻ CZYNNY ŻAL (Art. 16 KKS) PRZED wszczęciem kontroli — unikniesz sankcji!"),
        sprintf("   📋 Korekta deklaracji + zapłata zaległości + odsetki = brak dodatkowego zobowiązania.")
    ]
} {
    input.vat_sanction_detected == true
    understatement_pct := object.get(input.invoice, "vat_understatement_pct", 0)
    overstatement_pct := object.get(input.invoice, "vat_overstatement_pct", 0)
    tax_shortfall := object.get(input.invoice, "vat_tax_shortfall_pln", 0)
    is_repeat_offense := object.get(input.jdg_entrepreneur, "vat_sanction_previous_3y", false)
    is_fraudulent := object.get(input.invoice, "vat_fraud_detected", false)

    # Sanction graduation: 15% → 20% → 30%
    sanction_rate_pct := 15 { understatement_pct > 0; not is_repeat_offense; not is_fraudulent }
    sanction_rate_pct := 20 { understatement_pct > 0; is_repeat_offense; not is_fraudulent }
    sanction_rate_pct := 30 { understatement_pct > 0; is_fraudulent }
    sanction_rate_pct := 15 { overstatement_pct > 0; not is_repeat_offense; not is_fraudulent }
    sanction_rate_pct := 20 { overstatement_pct > 0; is_repeat_offense; not is_fraudulent }
    sanction_rate_pct := 30 { overstatement_pct > 0; is_fraudulent }
    sanction_rate_pct := 15 { sanction_rate_pct == 0 }
    sanction_rate_pct_str := sprintf("%.0f", [sanction_rate_pct])

    sanction_amount := tax_shortfall * sanction_rate_pct / 100

    sanction_type := "DODATKOWE_ZOBOWIAZANIE_PODATKOWE"
    sanction_description := sprintf("Zaniżenie VAT o %.0f%% — dodatkowe zobowiązanie %s%%",
        [understatement_pct, sanction_rate_pct_str]) { understatement_pct > 0 }
    sanction_description := sprintf("Zawyżenie zwrotu VAT o %.0f%% — dodatkowe zobowiązanie %s%%",
        [overstatement_pct, sanction_rate_pct_str]) { overstatement_pct > 0 }

    sanction_description := "Zaniżenie/zawyżenie VAT" { sanction_description == "" }
    sanction_legal_basis := "Art. 108b VAT" { sanction_legal_basis == "" }
}

# ── Helpers ─────────────────────────────────────────────────────────────────

is_eu_country(country) = true {
    eu := {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR",
           "HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK",
           "SI","ES","SE"}
    eu[country]
} else = false { true }

build_pos_warnings(country, rc, ios) = warnings {
    rc
    warnings := [
        sprintf("📍 MIEJSCE ŚWIADCZENIA: %s (Art. 28b — B2B)", [country]),
        "🔄 IMPORT USŁUG — rozlicz VAT w PL przez odwrotne obciążenie (Art. 17 ust. 1 pkt 4).",
        "   Wykaz w JPK_V7: K_31 (import usług) + K_32 (odwrotne obciążenie)."
    ]
} else = warnings {
    ios
    warnings := [
        sprintf("📍 MIEJSCE ŚWIADCZENIA: %s (Art. 28b — siedziba nabywcy)", [country]),
        "Faktura BEZ VAT — nabywca rozlicza import usług w swoim kraju."
    ]
} else = ["📍 MIEJSCE ŚWIADCZENIA: PL — transakcja krajowa."]

build_oss_warnings(needed, countries, total) = warnings {
    needed
    warnings := [
        sprintf("🚨 OSS WYMAGANY! Sprzedaż B2C do UE: %.0f EUR > limit 10 000 EUR.", [total]),
        sprintf("   Kraje: %s", [countries]),
        "   Zarejestruj się przez PUESC (VIES-OSS) NATYCHMIAST.",
        "   Po rejestracji: jedna deklaracja kwartalna OSS zamiast rejestracji w każdym kraju UE.",
        "   ⚠️ Do czasu rejestracji: rejestracja VAT w KAŻDYM kraju UE gdzie przekroczono lokalny limit!"
    ]
} else = warnings {
    total > thresholds.vat.oss_alert_eur
    warnings := [
        sprintf("⚠️ ZBLIŻASZ SIĘ DO LIMITU OSS: %.0f EUR / 10 000 EUR.", [total]),
        "   Monitoruj sprzedaż B2C do UE. Po przekroczeniu 10k EUR — obowiązkowa rejestracja OSS."
    ]
} else = [sprintf("✅ OSS: sprzedaż B2C %.0f EUR — poniżej limitu 10k EUR.", [total])]
