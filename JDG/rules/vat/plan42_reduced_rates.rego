# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.vat.reduced_rates (v7.0 ENHANCED R10)
# CN Code Validation + Cross-check dla stawek obniżonych 8% i 5%
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.vat.reduced_rates
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.vat.reduced_rates.no_match","package":"jdg.vat.reduced_rates","priority":99999}

# ── CN → Stawka VAT mapping (Rozp. MF z 4.12.2024, Załączniki 1-4) ──────────
# v7.0 R10: Walidacja stawek na podstawie kodów CN zamiast WARNING-only
# CN code prefix → expected VAT rate
cn_vat_rate_map := {
    # Załącznik 1: Stawka 8% — sprzęt medyczny, budownictwo, farmacja
    "3004": 0.08,  # Leki — 8%
    "3005": 0.08,  # Bandaże, gazy — 8%
    "3822": 0.08,  # Odczynniki diagnostyczne — 8%
    "4403": 0.08,  # Drewno opałowe — 8%
    "4901": 0.05,  # Książki drukowane — 5%
    "4902": 0.05,  # Gazety, czasopisma — 5%
    "4903": 0.05,  # Książki dla dzieci — 5%
    # Załącznik 2: Stawka 5% — żywność podstawowa, książki, produkty dla niemowląt
    "0701": 0.05,  # Ziemniaki — 5%
    "0702": 0.05,  # Pomidory — 5%
    "1001": 0.05,  # Pszenica — 5%
    "1005": 0.05,  # Kukurydza — 5%
    "1101": 0.05,  # Mąka pszenna — 5%
    "1501": 0.05,  # Tłuszcze zwierzęce — 5%
    "1601": 0.05,  # Kiełbasy — 5%
    "1905": 0.05,  # Pieczywo — 5%
    "2001": 0.05,  # Przetwory warzywne — 5%
    "2201": 0.23,  # Woda mineralna — 23% (nie 5%!)
    "2202": 0.23,  # Napoje — 23% (nie 5%!)
    "6115": 0.05,  # Rajstopy lecznicze — 5%
    "6301": 0.05,  # Koce — 5%
    "9619": 0.05,  # Pieluchy — 5%
}

# ── RATE-1: Walidacja stawki 8% wg kodu CN ──────────────────────────────────
decide := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.cn_8pct_validation",
    "package":"jdg.vat.reduced_rates","priority":61,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "cn_vat_validated": true,
    "cn_vat_match": cn_match,
    "cn_vat_expected_rate": expected_rate,
    "cn_vat_actual_rate": actual_rate,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis":"Rozporządzenie MF z 4.12.2024 r., Załącznik nr 1",
    "_warnings": warnings
} {
    cn_code := object.get(input.invoice, "cn_code", "")
    cn_code != ""
    cn_prefix := substring(cn_code, 0, 4)
    expected_rate := cn_vat_rate_map[cn_prefix]
    expected_rate == 0.08
    actual_rate := object.get(input.invoice, "vat_rate", 0.0)
    actual_rate == 0.08
    cn_match = "OK"
    routing = ""
    routing_reason = ""
    warnings := [sprintf("Kod CN %s potwierdza stawkę 8%% VAT — prawidłowo", [cn_code])]
} else := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.cn_8pct_mismatch",
    "package":"jdg.vat.reduced_rates","priority":61,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "cn_vat_validated": false,
    "cn_vat_match": "MISMATCH",
    "cn_vat_expected_rate": expected_rate,
    "cn_vat_actual_rate": actual_rate,
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason": sprintf("Kod CN %s wskazuje stawkę %.0f%% a nie 8%% — sprawdź klasyfikację!", [cn_code, expected_rate*100]),
    "_legal_basis":"Rozporządzenie MF z 4.12.2024 r., Załącznik nr 1",
    "_warnings":[sprintf("NIEZGODNOŚĆ STAWEK: kod CN %s → stawka %.0f%% VAT (wg rozporządzenia MF), ale zastosowano 8%%. Sprawdź klasyfikację towaru!", [cn_code, expected_rate*100])]
} {
    cn_code := object.get(input.invoice, "cn_code", "")
    cn_code != ""
    cn_prefix := substring(cn_code, 0, 4)
    expected_rate := cn_vat_rate_map[cn_prefix]
    expected_rate != 0.08
    actual_rate := object.get(input.invoice, "vat_rate", 0.0)
    actual_rate == 0.08
}

# ── RATE-2: Walidacja stawki 5% wg kodu CN ──────────────────────────────────
else := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.cn_5pct_validation",
    "package":"jdg.vat.reduced_rates","priority":62,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "cn_vat_validated": true,
    "cn_vat_match": "OK",
    "cn_vat_expected_rate": 0.05,
    "cn_vat_actual_rate": 0.05,
    "_routing":"",
    "_routing_reason":"",
    "_legal_basis":"Rozporządzenie MF z 4.12.2024 r., Załącznik nr 2",
    "_warnings":[sprintf("Kod CN %s potwierdza stawkę 5%% VAT — prawidłowo", [cn_code])]
} {
    cn_code := object.get(input.invoice, "cn_code", "")
    cn_code != ""
    cn_prefix := substring(cn_code, 0, 4)
    expected_rate := cn_vat_rate_map[cn_prefix]
    expected_rate == 0.05
    actual_rate := object.get(input.invoice, "vat_rate", 0.0)
    actual_rate == 0.05
} else := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.cn_5pct_mismatch",
    "package":"jdg.vat.reduced_rates","priority":62,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "cn_vat_validated": false,
    "cn_vat_match": "MISMATCH",
    "cn_vat_expected_rate": expected_rate,
    "cn_vat_actual_rate": actual_rate,
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason": sprintf("Kod CN %s wskazuje stawkę %.0f%% a nie 5%% — sprawdź klasyfikację!", [cn_code, expected_rate*100]),
    "_legal_basis":"Rozporządzenie MF z 4.12.2024 r., Załącznik nr 2",
    "_warnings":[sprintf("NIEZGODNOŚĆ STAWEK: kod CN %s → stawka %.0f%% VAT (wg rozporządzenia MF), ale zastosowano 5%%. Sprawdź klasyfikację towaru!", [cn_code, expected_rate*100])]
} {
    cn_code := object.get(input.invoice, "cn_code", "")
    cn_code != ""
    cn_prefix := substring(cn_code, 0, 4)
    expected_rate := cn_vat_rate_map[cn_prefix]
    expected_rate != 0.05
    actual_rate := object.get(input.invoice, "vat_rate", 0.0)
    actual_rate == 0.05
}

# ── RATE-3: Walidacja stawki 23% — potwierdzenie prawidłowości catch-all ────
else := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.standard_23pct_validation",
    "package":"jdg.vat.reduced_rates","priority":63,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "cn_vat_validated": true,
    "cn_vat_match": "OK_23PCT",
    "_routing":"",
    "_routing_reason":"",
    "_legal_basis":"Art. 41 ust. 1 VAT",
    "_warnings":[]
} {
    cn_code := object.get(input.invoice, "cn_code", "")
    cn_code != ""
    cn_prefix := substring(cn_code, 0, 4)
    expected_rate := cn_vat_rate_map[cn_prefix]
    expected_rate == 0.23
    actual_rate := object.get(input.invoice, "vat_rate", 0.0)
    actual_rate == 0.23
}

# ── RATE-4: Stawka 8% dla budownictwa mieszkaniowego z walidacją powierzchni ─
else := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.construction_8pct_validated",
    "package":"jdg.vat.reduced_rates","priority":68,
    "vat_rate":sprintf("%.2f", [data.jdg.thresholds.vat.reduced_rate_8]),"rounding_level":"position","gtu_code":"GTU_08",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "construction_rate_valid":true,"construction_area_ok":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 41 ust. 12-12c VAT + Rozp. MF z 4.12.2024 r.",
    "_warnings":["Budownictwo mieszkaniowe 8% VAT — domy ≤300 m² / mieszkania ≤150 m². Prawidłowo."]
} {
    input.invoice.category_code == "CONSTRUCTION_RESIDENTIAL"
    input.invoice.building_type in {"RESIDENTIAL_HOUSE","RESIDENTIAL_FLAT","SOCIAL_HOUSING"}
    area := object.get(input.invoice,"building_area_m2",0)
    not (input.invoice.building_type == "RESIDENTIAL_HOUSE" and area > 300)
    not (input.invoice.building_type == "RESIDENTIAL_FLAT" and area > 150)
} else := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.construction_area_exceeded",
    "package":"jdg.vat.reduced_rates","priority":68,
    "vat_rate":sprintf("%.2f", [data.jdg.thresholds.vat.standard_rate]),"rounding_level":"position","gtu_code":"GTU_08",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "construction_rate_valid":false,"construction_area_exceeded":true,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":sprintf("Powierzchnia %.0f m² przekracza limit dla budownictwa 8%% (dom ≤300 m², mieszkanie ≤150 m²) — stawka 23%%!", [area]),
    "_legal_basis":"Art. 41 ust. 12b-12c VAT",
    "_warnings":[sprintf("PRZEKROCZENIE LIMITU — budynek %.0f m². Stawka 8%% tylko do 300 m² (dom) / 150 m² (mieszkanie). Nadwyżka = 23%% VAT!", [area])]
} {
    input.invoice.category_code == "CONSTRUCTION_RESIDENTIAL"
    area := object.get(input.invoice,"building_area_m2",0)
    (input.invoice.building_type == "RESIDENTIAL_HOUSE" and area > 300) or
    (input.invoice.building_type == "RESIDENTIAL_FLAT" and area > 150)
}

# ── RATE-5: Sprzęt medyczny 8% z walidacją CN ───────────────────────────────
else := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.medical_8pct_validated",
    "package":"jdg.vat.reduced_rates","priority":70,
    "vat_rate":sprintf("%.2f", [data.jdg.thresholds.vat.reduced_rate_8]),"rounding_level":"position","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "medical_device_valid":true,"medical_ce_marked":true,
    "cn_medical_validated": cn_ok,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozp. MF z 4.12.2024 r., Załącznik nr 1, poz. 87-105",
    "_warnings":["Sprzęt medyczny 8% VAT — certyfikat CE + kod CN potwierdzony."]
} {
    input.invoice.category_code == "MEDICAL_EQUIPMENT"
    input.invoice.is_medical_device == true
    input.invoice.has_ce_marking == true
    not input.invoice.is_used_goods
    cn_code := object.get(input.invoice, "cn_code", "")
    cn_prefix := substring(cn_code, 0, 4)
    cn_ok = true { cn_code == "" }
    cn_ok = true { cn_prefix in {"3004", "3005", "3822"} }
}

# ── RATE-6: Książki 5% z walidacją ISBN ─────────────────────────────────────
else := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.books_5pct_validated",
    "package":"jdg.vat.reduced_rates","priority":71,
    "vat_rate":sprintf("%.2f", [data.jdg.thresholds.vat.reduced_rate_5]),"rounding_level":"position","gtu_code":"GTU_01",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "books_5pct_valid":true,"books_isbn_validated":true,
    "books_cn_validated": cn_ok,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozp. MF z 4.12.2024 r., Załącznik nr 2",
    "_warnings":["Książka/e-book 5% VAT — ISBN/digital ID + kod CN potwierdzone."]
} {
    input.invoice.category_code in {"BOOKS","EBOOKS","AUDIOBOOKS"}
    input.invoice.has_isbn_or_digital_id == true
    not input.invoice.is_academic_textbook
    not input.invoice.is_adult_content
    cn_code := object.get(input.invoice, "cn_code", "")
    cn_prefix := substring(cn_code, 0, 4)
    cn_ok = true { cn_code == "" }
    cn_ok = true { cn_prefix in {"4901", "4902", "4903"} }
}

# ── RATE-7: Cross-check obniżonych stawek ────────────────────────────────────
else := {
    "matched":true,"rule_id":"jdg.vat.reduced_rates.cross_check_all_reduced",
    "package":"jdg.vat.reduced_rates","priority":99,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "reduced_rates_audit": true,
    "reduced_rates_count": reduced_count,
    "reduced_rates_total": reduced_total,
    "_routing":"WARNING",
    "_routing_reason": sprintf("Audyt stawek obniżonych: %d transakcji na łączną kwotę %.2f PLN", [reduced_count, reduced_total]),
    "_legal_basis":"Art. 64 KKS — procedury audytowe",
    "_warnings":[sprintf("CROSS-CHECK OBNIŻONYCH STAWEK: %d transakcji ze stawkami 8%%/5%%/0%% na łączną kwotę %.2f PLN. Nietypowy udział obniżonych stawek może wzbudzić kontrolę KAS.", [reduced_count, reduced_total])]
} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
    reduced_count := object.get(input.jdg_entrepreneur, "reduced_rates_transaction_count", 0)
    reduced_total := object.get(input.jdg_entrepreneur, "reduced_rates_total_amount", 0)
    total := object.get(input.jdg_entrepreneur, "annual_turnover_net", 0)
    total > 0
    reduced_count > 10  # ≥ 10 transakcji — wartość audytu
}
