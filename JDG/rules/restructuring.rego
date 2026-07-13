# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Restrukturyzacja, przekształcenie, sukcesja (P843-P845, P1500-P1505)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.restructuring
#
# METADATA
# title: JDG Package — restructuring
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.restructuring
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.restructuring.no_match","package":"jdg.restructuring","priority":1515}

# ══ P1500: jdg_to_sp_zoo_transformation — Przekształcenie JDG → Sp. z o.o. ══
decide := {
    "matched":true,"rule_id":"jdg.restructuring.jdg_to_spzoo_transformation",
    "package":"jdg.restructuring","priority":1500,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"TRANSFORMATION_IN_PROGRESS",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Przekształcenie JDG → Sp. z o.o. — skutki podatkowe do rozliczenia",
    "_legal_basis":"Art. 551 § 5 KSH + Art. 112 Ordynacja podatkowa",
    "_warnings":["Przekształcenie JDG w Sp. z o.o. — sukcesja podatkowa (Art. 112 Ord. pod.). Spółka wstępuje we wszystkie prawa i obowiązki JDG. NIP przechodzi na spółkę. Remanent likwidacyjny obowiązkowy."]
} {
    input.restructuring.type == "JDG_TO_SPZOO"
}

# ══ P1501: transformation_opening_balance — Bilans otwarcia przekształcenia ══
else := {
    "matched":true,"rule_id":"jdg.restructuring.opening_balance_sheet",
    "package":"jdg.restructuring","priority":1501,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"TRANSFORMATION_BALANCE_SHEET_REQUIRED",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Bilans otwarcia wymagany przy przekształceniu",
    "_legal_basis":"Art. 559 § 1 KSH + Art. 24a PIT",
    "_warnings":["Sporządzenie bilansu otwarcia na dzień przekształcenia. Wycena składników majątku wg wartości rynkowej. Podatek od remanentu likwidacyjnego (10% PIT od nadwyżki remanentowej)."]
} {
    input.restructuring.type == "JDG_TO_SPZOO"
    input.restructuring.opening_balance_prepared == false
}

# ══ P1502: business_transfer_tax_exempt — Sprzedaż przedsiębiorstwa zwolniona z VAT ══
else := {
    "matched":true,"rule_id":"jdg.restructuring.business_transfer_tax_exempt",
    "package":"jdg.restructuring","priority":1502,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"","vat_exemption":"ZCP","procedure":"ZCP_TRANSFER",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"ZCP_TRANSFER_IN_PROGRESS",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 6 pkt 1 VAT (zbycie ZCP wyłączone z VAT)",
    "_warnings":["Zbycie ZCP (zorganizowanej części przedsiębiorstwa) — wyłączone z VAT. Podlega PCC 2% po stronie nabywcy. Sprzedający rozpoznaje przychód w PIT."]
} {
    input.restructuring.type == "ZCP_SALE"
    input.invoice.is_zcp_transfer == true
}

# ══ P843: nabywca_odpowiedzialnosc — Odpowiedzialność nabywcy za zaległości ══
else := {
    "matched":true,"rule_id":"jdg.restructuring.acquirer_liability_tax_arrears",
    "package":"jdg.restructuring","priority":1503,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","acquirer_liable_for_tax_arrears":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Nabywca odpowiada solidarnie za zaległości podatkowe zbywcy",
    "_legal_basis":"Art. 112 Ordynacja podatkowa",
    "_warnings":["Nabywca przedsiębiorstwa odpowiada solidarnie za zaległości podatkowe zbywcy. Odpowiedzialność do wartości nabytego majątku. Zaleca się uzyskanie zaświadczenia o niezaleganiu."]
} {
    input.restructuring.type == "ZCP_SALE"
    input.restructuring.acquirer_verified_fiscal_clearance == false
}

# ══ P1504: business_succession_manager — Sukcesja — zarządca sukcesyjny ══
else := {
    "matched":true,"rule_id":"jdg.restructuring.succession_manager",
    "package":"jdg.restructuring","priority":1504,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"SUCCESSION_ACTIVE",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Zarządca sukcesyjny — obowiązek zgłoszenia do CEIDG w terminie 2 miesięcy",
    "_legal_basis":"Art. 51-54 Ustawy o zarządzie sukcesyjnym",
    "_warnings":["Zarządca sukcesyjny. Powołanie w terminie 2 miesięcy od śmierci przedsiębiorcy. Zgłoszenie do CEIDG. Prowadzenie JDG przez max 2 lata od śmierci."]
} {
    input.restructuring.type == "SUCCESSION"
    input.restructuring.succession_manager_appointed == false
}

# ══ P1505: business_closure_ceidg — Zamknięcie JDG — CEIDG ══
else := {
    "matched":true,"rule_id":"jdg.restructuring.business_closure",
    "package":"jdg.restructuring","priority":1505,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"CLOSED",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Zamknięcie JDG — VAT-Z, remanent likwidacyjny, PIT-36L/PIT-36 do dnia zaprzestania",
    "_legal_basis":"Art. 14 PIT + Art. 96 ust. 6 VAT + Art. 27 Ustawy CEIDG",
    "_warnings":["Zamknięcie JDG. Obowiązki: 1) VAT-Z w 7 dni, 2) remanent likwidacyjny + podatek 10% od nadwyżki remanentowej, 3) PIT do 30 kwietnia następnego roku, 4) wyrejestrowanie z CEIDG, 5) ZUS ZWUA."]
} {
    input.restructuring.type == "CLOSURE"
    input.restructuring.closure_procedures_completed == false
}

# ══ P1503: merger_demerger_tax — Podział/łączenie JDG — skutki podatkowe ══
else := {
    "matched":true,"rule_id":"jdg.restructuring.merger_tax",
    "package":"jdg.restructuring","priority":1506,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"RESTRUCTURING_TAX_NEUTRAL","restructuring_tax_neutral":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 21 ust. 1 pkt 50b PIT (wymiana udziałów)",
    "_warnings":["Restrukturyzacja neutralna podatkowo przy spełnieniu warunków Art. 21 ust. 1 pkt 50b PIT. Uwaga: JDG nie może być stroną łączenia w rozumieniu KSH. Dotyczy tylko przekształcenia JDG → Sp. z o.o."]
} {
    input.restructuring.tax_neutral_claimed == true
    input.restructuring.documentation_complete == true
}
