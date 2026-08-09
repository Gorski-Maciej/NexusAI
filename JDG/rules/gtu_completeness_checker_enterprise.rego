# NexusAI JDG — Enterprise GTU completeness checker.
# Package: jdg.gtu_checker. Legacy metadata retained as ordinary comments.

package jdg.gtu_checker

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.gtu_checker.no_match",
    "package": "jdg.gtu_checker",
    "priority": 9999,
}

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
    "GTU_11": {"description": "Usługi niematerialne doradcze, księgowe, prawne", "categories": ["CONSULTING_ADVISORY", "ACCOUNTING", "MANAGEMENT"]},
    "GTU_12": {"description": "Usługi niematerialne IT, prawne, reklamowe", "categories": ["CONSULTING", "LEGAL", "IT_SERVICES", "INTANGIBLE_SERVICES", "ADVERTISING", "MARKETING"]},
    "GTU_13": {"description": "Usługi transportowe i magazynowe", "categories": ["TRANSPORT_LOGISTICS", "WAREHOUSING", "FREIGHT", "SHIPPING"]},
}

bool_text(value) := sprintf("%v", [value])
bool_not(value) := object.get({"true": false, "false": true}, bool_text(value), false)
both_true(a, b) := object.get({"true|true": true}, sprintf("%v|%v", [a, b]), false)
percentage(value, denominator) := value * 100 / denominator if {
    denominator > 0
} else := 0 if {
    denominator == 0
}

build_gtu_audit_warnings(period, total, missing, incorrect, pct, missing_codes) := [
    sprintf("🔍 GTU COMPLETENESS AUDIT — OKRES %s", [period]),
    sprintf("   Pozycji wymagających GTU: %d", [total]),
    sprintf("   Kompletność: %.0f%% | Brakujące: %d | Błędne: %d", [pct, missing, incorrect]),
    sprintf("   Brakujące kody GTU: %s", [concat(", ", missing_codes)]),
    "   📋 13 kodów GTU (GTU_01..GTU_13) — Załącznik nr 15 do ustawy VAT",
]

expected_codes_for(category) := [code |
    some code
    details := gtu_full_map[code]
    category in object.get(details, "categories", [])
]

invoice_warning(category, expected, current, correct) := [sprintf("✅ GTU OK: kategoria '%s' → kod '%s' — zgodne z Zał. nr 15.", [category, current])] if {
    correct
} else := [sprintf("⚠️ GTU BŁĄD: kategoria '%s' → kod '%s'. Oczekiwano: %s.", [category, current, concat(" lub ", expected)])] if {
    count(expected) > 0
} else := [sprintf("⚠️ GTU: kategoria '%s' nie wymaga GTU, ale przypisano kod '%s'.", [category, current])] if {
    current != ""
} else := ["✅ GTU: kategoria nie wymaga oznaczenia GTU."]

# GTC-2120: GTU completeness audit.
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
    "_warnings": build_gtu_audit_warnings(period, total_gtu_items, missing_gtu_count, incorrect_gtu_count, completeness_pct, missing_codes_list),
} if {
    input.gtu_completeness_audit == true
    period := object.get(input, "gtu_audit_period", "2026-07")
    total_gtu_items := object.get(input, "gtu_total_taxable_items", 0)
    gtu_assigned := object.get(input, "gtu_correctly_assigned", 0)
    missing_gtu_count := object.get(input, "gtu_missing_count", 0)
    incorrect_gtu_count := object.get(input, "gtu_incorrect_count", 0)
    missing_codes_list := object.get(input, "gtu_missing_codes", [])
    completeness_pct := percentage(gtu_assigned, max([total_gtu_items, 1]))
    issue_count := missing_gtu_count + incorrect_gtu_count
    has_issue := issue_count > 0
    has_items := total_gtu_items > 0
    gtu_routing := object.get({"true": "BLOCK_AND_ALERT", "false": ""}, bool_text(both_true(has_issue, has_items)), "")
    gtu_reason := object.get({"true": sprintf("GTU AUDIT: %d brakujących / %d błędnych kodów — popraw przed wysyłką JPK_V7!", [missing_gtu_count, incorrect_gtu_count]), "false": ""}, bool_text(has_issue), "")
} else := {
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
    "_warnings": invoice_warning(product_category, expected_codes, current_gtu, gtu_correct),
} if {
    input.gtu_validate_invoice == true
    product_category := object.get(input, "product_category", "GENERAL")
    current_gtu := object.get(input.invoice, "gtu_code", "")
    expected_codes := expected_codes_for(product_category)
    requires_gtu := count(expected_codes) > 0
    gtu_correct := object.get({"true": current_gtu in expected_codes, "false": current_gtu == ""}, bool_text(requires_gtu), false)
    invoice_gtu_routing := object.get({"true": "BLOCK_AND_ALERT", "false": ""}, bool_text(bool_not(gtu_correct)), "")
    invoice_gtu_reason := object.get({"true": sprintf("GTU MISMATCH: kategoria '%s' oczekuje %s, otrzymano '%s'", [product_category, concat(" lub ", expected_codes), current_gtu]), "false": ""}, bool_text(bool_not(gtu_correct)), "")
} else := {
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
    "_warnings": [sprintf("📝 KOREKTA GTU — faktura %s: %s → %s", [invoice_ref, current_gtu, proposed_gtu])],
} if {
    input.gtu_propose_correction == true
    product_category := object.get(input, "product_category", "")
    current_gtu := object.get(input.invoice, "gtu_code", "")
    invoice_ref := object.get(input.invoice, "invoice_number", "")
    expected := expected_codes_for(product_category)
    count(expected) > 0
    bool_not(current_gtu in expected)
    proposed_gtu := expected[0]
    correction_reason := sprintf("Kategoria '%s' wymaga kodu %s (Zał. nr 15 VAT)", [product_category, proposed_gtu])
}
