# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE GTU COMPLETENESS CHECKER (Innovation 8.13, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise GTU Completeness Checker — Full 13-code GTU Validation
# description: |
#   ENTERPRISE v7.0 — Rozszerzony walidator kompletności kodów GTU dla JPK_V7.
#   Sprawdza czy wszystkie wymagane kody GTU (GTU_01..GTU_13) są poprawnie
#   przypisane dla towarów/usług wrażliwych wg Załącznika nr 15 do ustawy VAT.
#
#   KLUCZOWE FUNKCJE:
#   - Pełna mapa 13 kodów GTU z kategoriami towarów/usług
#   - Wykrywanie brakujących kodów GTU w ewidencji sprzedaży
#   - Walidacja poprawności przypisania GTU (czy towar X ma kod Y)
#   - Raport kompletności GTU dla okresu JPK_V7
#   - Automatyczne proponowanie korekty przy błędnym GTU
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 106e ust. 1 pkt 18a VAT; Załącznik nr 15 do ustawy VAT
# package: jdg.gtu_checker
# deprecated: false
# priority_range: 2120-2149
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.gtu_checker

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.gtu_checker.no_match",
    "package": "jdg.gtu_checker", "priority": 9999
}

# Pełna mapa 13 kodów GTU (Załącznik nr 15 do ustawy VAT)
gtu_full_map := {
    "GTU_01": {"description": "Napoje alkoholowe (>1.2% alkoholu)", "categories": ["ALCOHOL", "SPIRITS", "BEER", "WINE"]},
    "GTU_02": {"description": "Towary energetyczne (paliwa, oleje)", "categories": ["FUEL", "PETROL", "DIESEL", "OIL"]},
    "GTU_03": {"description": "Olej opałowy i smary", "categories": ["HEATING_OIL", "LUBRICANTS"]},
    "GTU_04": {"description": "Wyroby tytoniowe i nikotynowe", "categories": ["TOBACCO", "CIGARETTES", "E_LIQUID"]},
    "GTU_05": {"description": "Odpady (w tym niebezpieczne, elektronika)", "categories": ["ELECTRONICS_WASTE", "HAZARDOUS_WASTE"]},
    "GTU_06": {"description": "Urządzenia elektroniczne, procesory", "categories": ["ELECTRONICS", "PROCESSORS", "CHIPS"]},
    "GTU_07": {"description": "Pojazdy i części samochodowe", "categories": ["VEHICLES", "VEHICLE_PARTS", "MOTORCYCLES"]},
    "GTU_08": {"description": "Metale szlachetne i nieszlachetne", "categories": ["PRECIOUS_METALS", "GOLD", "SILVER", "STEEL"]},
    "GTU_09": {"description": "Leki i wyroby medyczne", "categories": ["PHARMA_MEDICAL", "MEDICAL_DEVICES", "DRUGS"]},
    "GTU_10": {"description": "Budynki, budowle, grunty", "categories": ["BUILDINGS_REAL_ESTATE", "CONSTRUCTION", "LAND"]},
    "GTU_11": {"description": "Usługi o charakterze niematerialnym (doradcze, księgowe, prawne, zarządzanie)", "categories": ["CONSULTING_ADVISORY", "ACCOUNTING", "MANAGEMENT"]},
    "GTU_12": {"description": "Usługi niematerialne IT, prawne, reklamowe", "categories": ["CONSULTING", "LEGAL", "IT_SERVICES", "INTANGIBLE_SERVICES", "ADVERTISING", "MARKETING"]},
    "GTU_13": {"description": "Usługi transportowe i magazynowe", "categories": ["TRANSPORT_LOGISTICS", "WAREHOUSING", "FREIGHT", "SHIPPING"]}
}

# ═══════════════════════════════════════════════════════════════════════════════
# GTC-2120: GTU COMPLETENESS AUDIT — Audyt kompletności GTU dla okresu JPK
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.gtu_checker.completeness_audit",
    "package": "jdg.gtu_checker",
    "priority": 2120,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "gtu_audit_period": period,
    "gtu_audit_total_gtu_items": total_gtu_items,
    "gtu_audit_missing_gtu": missing_gtu_count,
    "gtu_audit_incorrect_gtu": incorrect_gtu_count,
    "gtu_audit_completeness_pct": completeness_pct,
    "gtu_audit_missing_codes": missing_codes_list,
    "_routing": gtu_routing,
    "_routing_reason": gtu_reason,
    "_legal_basis": "§ 10 rozporządzenia JPK_VAT; Załącznik nr 15 do ustawy VAT",
    "_warnings": build_gtu_audit_warnings(period, total_gtu_items, missing_gtu_count, incorrect_gtu_count, completeness_pct, missing_codes_list)
} {
    input.gtu_completeness_audit == true
    period := object.get(input, "gtu_audit_period", "2026-07")
    total_gtu_items := object.get(input, "gtu_total_taxable_items", 0)
    gtu_assigned := object.get(input, "gtu_correctly_assigned", 0)
    missing_gtu_count := object.get(input, "gtu_missing_count", 0)
    incorrect_gtu_count := object.get(input, "gtu_incorrect_count", 0)
    missing_codes_list := object.get(input, "gtu_missing_codes", [])

    completeness_pct := gtu_assigned * 100 / max([total_gtu_items, 1])

    gtu_routing := "BLOCK_AND_ALERT" { missing_gtu_count + incorrect_gtu_count > 0; total_gtu_items > 0 }
    gtu_routing := "" { true }
    gtu_reason := sprintf("GTU AUDIT: %d brakujących / %d błędnych kodów — popraw przed wysyłką JPK_V7!", [missing_gtu_count, incorrect_gtu_count]) { missing_gtu_count + incorrect_gtu_count > 0 }
    gtu_reason := "" { true }
}

build_gtu_audit_warnings(period, total, missing, incorrect, pct, missing_codes) = warnings {
    base := [
        sprintf("🔍 GTU COMPLETENESS AUDIT — OKRES %s", [period]),
        sprintf("   Pozycji wymagających GTU: %d", [total]),
        sprintf("   Kompletność: %.0f%% | Brakujące: %d | Błędne: %d", [pct, missing, incorrect]),
    ]
    with_missing := array.concat(base, [sprintf("   ⚠️ Brakujące kody GTU: %s", [concat(", ", missing_codes)])]) { count(missing_codes) > 0 }
    with_missing := base { count(missing_codes) == 0 }
    final := array.concat(with_missing, ["   📋 13 kodów GTU (GTU_01..GTU_13) — Załącznik nr 15 do ustawy VAT"])
    warnings := final
}

# ═══════════════════════════════════════════════════════════════════════════════
# GTC-2125: GTU VALIDATION PER INVOICE — Walidacja GTU dla pojedynczej faktury
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.gtu_checker.per_invoice_validation",
    "package": "jdg.gtu_checker",
    "priority": 2125,
    "vat_rate": "", "rounding_level": "", "gtu_code": current_gtu,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "gtu_product_category": product_category,
    "gtu_expected_codes": expected_codes,
    "gtu_current_code": current_gtu,
    "gtu_is_correct": gtu_correct,
    "_routing": invoice_gtu_routing,
    "_routing_reason": invoice_gtu_reason,
    "_legal_basis": "Art. 106e ust. 1 pkt 18a VAT; Załącznik nr 15",
    "_warnings": build_invoice_gtu_warnings(product_category, expected_codes, current_gtu, gtu_correct)
} {
    input.gtu_validate_invoice == true
    product_category := object.get(input, "product_category", "GENERAL")
    current_gtu := object.get(input.invoice, "gtu_code", "")

    # Określ oczekiwane kody GTU dla tej kategorii produktu
    # Iteruj przez gtu_full_map, znajdź kody gdzie categories zawierają product_category
    expected_codes := [code |
        code := gtu_full_map[_];
        some cat;
        cat := object.get(gtu_full_map[code], "categories", [])[_];
        cat == product_category
    ]

    requires_gtu := count(expected_codes) > 0
    gtu_correct := current_gtu in expected_codes { requires_gtu }
    gtu_correct := true { not requires_gtu; current_gtu == "" }
    gtu_correct := false { not requires_gtu; current_gtu != "" }

    invoice_gtu_routing := "BLOCK_AND_ALERT" { not gtu_correct; requires_gtu }
    invoice_gtu_routing := "" { true }
    invoice_gtu_reason := sprintf("GTU MISMATCH: kategoria '%s' oczekuje %s, otrzymano '%s'", [product_category, concat(" lub ", expected_codes), current_gtu]) { not gtu_correct; requires_gtu }
    invoice_gtu_reason := "" { true }
}

build_invoice_gtu_warnings(cat, expected, current, correct) = warnings {
    correct
    warnings := [sprintf("✅ GTU OK: kategoria '%s' → kod '%s' — zgodne z Zał. nr 15.", [cat, current])]
} else = warnings {
    count(expected) > 0
    warnings := [sprintf("⚠️ GTU BŁĄD: kategoria '%s' → kod '%s'. Oczekiwano: %s.", [cat, current, concat(" lub ", expected)])]
} else = warnings {
    current != ""
    warnings := [sprintf("⚠️ GTU: kategoria '%s' nie wymaga GTU, ale przypisano kod '%s'.", [cat, current])]
} else = ["✅ GTU: kategoria nie wymaga oznaczenia GTU."]

# ═══════════════════════════════════════════════════════════════════════════════
# GTC-2130: GTU CORRECTION PROPOSAL — Propozycja korekty błędnego GTU
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.gtu_checker.correction_proposal",
    "package": "jdg.gtu_checker",
    "priority": 2130,
    "vat_rate": "", "rounding_level": "", "gtu_code": proposed_gtu,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "gtu_correction_invoice": invoice_ref,
    "gtu_correction_current": current_gtu,
    "gtu_correction_proposed": proposed_gtu,
    "gtu_correction_reason": correction_reason,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("KOREKTA GTU: faktura %s — zmień '%s' → '%s'. Powód: %s", [invoice_ref, current_gtu, proposed_gtu, correction_reason]),
    "_legal_basis": "Art. 106j VAT (faktura korygująca); Załącznik nr 15 do ustawy VAT",
    "_warnings": [
        sprintf("📝 KOREKTA GTU — faktura %s:", [invoice_ref]),
        sprintf("   Obecny kod: %s → Proponowany: %s", [current_gtu, proposed_gtu]),
        sprintf("   Powód: %s", [correction_reason]),
        "📋 Wystaw fakturę korygującą przez KSeF z poprawnym kodem GTU."
    ]
} {
    input.gtu_propose_correction == true
    product_category := object.get(input, "product_category", "")
    current_gtu := object.get(input.invoice, "gtu_code", "")
    invoice_ref := object.get(input.invoice, "invoice_number", "")

    # Znajdź poprawny kod GTU dla kategorii
    expected := [code | code := gtu_full_map[_]; some cat; cat := object.get(gtu_full_map[code], "categories", [])[_]; cat == product_category]
    count(expected) > 0
    current_gtu not in expected

    proposed_gtu := expected[0]
    correction_reason := sprintf("Kategoria '%s' wymaga kodu %s (Zał. nr 15 VAT)", [product_category, proposed_gtu])
}
