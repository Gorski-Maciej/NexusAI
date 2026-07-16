# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Crossborder: WNT, WDT, import, eksport, trójstronne (P40-P49)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Crossborder Package — Intra-EU & Non-EU Transactions (P40-P49 — AKTYWNE, NIE deprecated)
# description: |
#   PAS 3 Multi-Pass. First-Match-Wins else-chain. Obsługuje transakcje zagraniczne:
#   WNT reverse charge (P40), import usług UE (P41), WDT 0% (P42), WDT bez dokumentów
#   → stawka krajowa (P42c), import spoza UE (P45), eksport towarów (P48),
#   transakcje trójstronne (P49). Wszystkie reguły AKTYWNE — błędnie oznaczone
#   jako DEPRECATED w dokumencie PELNE_POKRYCIE_PRAWNE.txt (dotyczyło starego policies/jdg/).
# architecture: Multi-Pass PAS 3 (ADR-001)
# legal_basis: Art. 17, 28b, 41-42, 135-138 VAT
# edge_cases:
#   - P42c: WDT bez transport_docs → stawka 23% zamiast 0%
#   - P41 vs P40: import usług (type=SERVICE) vs WNT (towary)
#   - EU countries set: 27 państw członkowskich
# package: jdg.crossborder
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.crossborder
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.crossborder.no_match","package":"jdg.crossborder","priority":59}

eu_countries := {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE"}

# ══════ P40: eu_reverse_charge — WNT ══════
decide := {
    "matched":true,"rule_id":"jdg.crossborder.eu_reverse_charge",
    "package":"jdg.crossborder","priority":40,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"GTU_12",
    "procedure":"VAT_REVERSE_CHARGE","vat_exemption":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 17 ust. 1 pkt 3 VAT",
    "_warnings":["WNT — reverse charge: VAT rozlicza nabywca"]
} {
    input.vendor.country in eu_countries
    input.vendor.country != "PL"
    input.vendor.vat_status == "active"
    input.invoice.procedure == "WNT"
}

# ══════ P42_c: wdt_documentation_evidence — Wymóg dokumentów WDT ══════
# ⚠️ Musi być PRZED P42 (ogólne WDT) — bardziej szczegółowa reguła
else := {
    "matched":true,"rule_id":"jdg.crossborder.wdt_no_docs",
    "package":"jdg.crossborder","priority":42,
    "vat_rate":"0.23","rounding_level":"position","gtu_code":"",
    "procedure":"WDT_INVALID","vat_exemption":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Brak dokumentów potwierdzających wywóz WDT",
    "_legal_basis":"Art. 42 ust. 1 pkt 1-2 VAT",
    "_warnings":["WDT BEZ dokumentów potwierdzających wywóz — stawka 0% NIEDOZWOLONA! Stawka krajowa 23%."]
} {
    input.invoice.procedure == "WDT"
    input.invoice.has_transport_docs == false
}

# ══════ P42b: wdt_vat_refund_accelerated — WDT przyśpieszony zwrot 25 dni ══════
# Doc 26 §VI: Wszystkie faktury zakupowe opłacone przelewem → zwrot VAT w 25 dni
# ⚠️ Musi być PRZED P42 (ogólne WDT) — bardziej szczegółowa reguła
else := {
    "matched":true,"rule_id":"jdg.crossborder.wdt_refund_accelerated",
    "package":"jdg.crossborder","priority":53,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"",
    "procedure":"WDT","vat_exemption":"",
    "vat_refund_deadline_days":25,
    "vat_refund_accelerated":true,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"WDT — przyśpieszony zwrot VAT w 25 dni",
    "_legal_basis":"Art. 87 ust. 6 pkt 1 VAT",
    "_warnings":["WDT — przyśpieszony zwrot VAT w 25 dni (wszystkie faktury zakupowe opłacone przelewem bankowym)"]
} {
    input.invoice.procedure == "WDT"
    input.invoice.direction == "SALE"
    input.jdg_entrepreneur.is_vat_payer == true
    all_purchases_paid_by_transfer := object.get(input.jdg_entrepreneur, "all_purchases_paid_by_transfer", false)
    all_purchases_paid_by_transfer == true
}

# ══════ P143: platform_app_store_b2b_export — App Store/Google Play export B2B ══════
# Doc 26 §VI: Sprzedaż app przez platformy do UE — reverse charge, VAT nabywcy
# ⚠️ Musi być PRZED P42 (ogólne WDT) — usługi cyfrowe ≠ towary
else := {
    "matched":true,"rule_id":"jdg.crossborder.platform_app_store_export",
    "package":"jdg.crossborder","priority":55,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"",
    "procedure":"EXPORT_SERVICES_B2B","vat_exemption":"",
    "vat_ue_summary_required":true,
    "platform_type":platform_type,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"App Store/Google Play — eksport usług B2B do UE",
    "_legal_basis":"Art. 28b VAT (miejsce świadczenia = siedziba nabywcy B2B)",
    "_warnings":[sprintf("%s — eksport usług B2B do UE. VAT rozlicza nabywca (reverse charge). Obowiązek VAT-UE.", [platform_type])]
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"IT_SERVICES", "SOFTWARE_DEVELOPMENT", "SAAS", "MOBILE_APP"}
    input.vendor.is_b2b_buyer == true
    input.vendor.country in eu_countries
    input.vendor.country != "PL"
    platform := object.get(input.invoice, "distribution_platform", "")
    platform in {"APP_STORE", "GOOGLE_PLAY", "MICROSOFT_STORE", "STEAM", "EPIC_GAMES"}
    platform_type = "App Store/Google Play" { platform in {"APP_STORE", "GOOGLE_PLAY"} }
    platform_type = "Microsoft Store" { platform == "MICROSOFT_STORE" }
    platform_type = "Steam/Epic Games" { platform in {"STEAM", "EPIC_GAMES"} }
}

# ══════ P42: wdt_intracommunity_supply — WDT 0% VAT ══════
# Catch-all dla sprzedaży B2B do UE (ostatnia w grupie WDT), głównie towary
else := {
    "matched":true,"rule_id":"jdg.crossborder.wdt_intracommunity_supply",
    "package":"jdg.crossborder","priority":42,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"",
    "procedure":"WDT","vat_exemption":"","vat_ue_summary_required":true,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 42 VAT",
    "_warnings":["WDT — stawka 0% VAT przy spełnieniu warunków dokumentacyjnych"]
} {
    input.invoice.direction == "SALE"
    input.vendor.country in eu_countries
    input.vendor.country != "PL"
    input.vendor.vat_eu_active == true
}

# ══════ P45: import_non_eu — Import spoza UE ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.import_non_eu",
    "package":"jdg.crossborder","priority":45,
    "vat_rate":"0.23","rounding_level":"position","gtu_code":"",
    "procedure":"IMPORT","vat_exemption":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 17 ust. 1 pkt 1 VAT",
    "_warnings":["Import spoza UE — VAT należny w imporcie"]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.country == "NON_EU"
}

# ══════ P48: export_goods — Eksport towarów 0% VAT ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.export_goods",
    "package":"jdg.crossborder","priority":48,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"",
    "procedure":"EXPORT","vat_exemption":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 41 ust. 4-11 VAT",
    "_warnings":["Eksport towarów — stawka 0% VAT"]
} {
    input.invoice.direction == "SALE"
    input.vendor.country == "NON_EU"
    input.invoice.procedure == "EXPORT"
}

# ══════ P144: platform_import_services — Import usług z platform (Upwork/Fiverr) ══════
# Doc 26 §VI: Prowizje platform freelancerskich — import usług, reverse charge
# ⚠️ Musi być PRZED P41 (ogólny import usług) — bardziej szczegółowa reguła
else := {
    "matched":true,"rule_id":"jdg.crossborder.platform_import_services",
    "package":"jdg.crossborder","priority":56,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"",
    "procedure":"IMPORT_SERVICES_REVERSE_CHARGE","vat_exemption":"",
    "import_from_platform":true,
    "platform_provider":platform_name,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"Import usług z platformy — reverse charge VAT",
    "_legal_basis":"Art. 17 ust. 1 pkt 4 VAT, Art. 28b VAT",
    "_warnings":[sprintf("%s — prowizje/platforma. Import usług spoza PL. JDG rozlicza VAT w PL (reverse charge). Obowiązek podatkowy = data wykonania usługi.", [platform_name])]
} {
    input.invoice.direction == "PURCHASE"
    platform := object.get(input.invoice, "vendor_platform", "")
    platform in {"UPWORK", "FIVERR", "FREELANCER", "TOPTAL", "GURU"}
    platform_name = "Upwork" { platform == "UPWORK" }
    platform_name = "Fiverr" { platform == "FIVERR" }
    platform_name = "Freelancer" { platform == "FREELANCER" }
    platform_name = "Toptal" { platform == "TOPTAL" }
    platform_name = "Guru" { platform == "GURU" }
    platform_name = "Platforma freelancerska"
}

# ══════ P41: eu_import_services — Import usług z UE ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.eu_import_services",
    "package":"jdg.crossborder","priority":41,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"",
    "procedure":"VAT_REVERSE_CHARGE","vat_exemption":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 28b VAT",
    "_warnings":["Import usług B2B z UE — reverse charge: VAT rozlicza nabywca"]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.country in eu_countries
    input.vendor.country != "PL"
    input.invoice.type == "SERVICE"
}

# ══════ P49b: triangular_simplified — Procedura uproszczona trójstronna ══════
# Doc 26 §VI: 3 podmioty z 3 krajów UE, towar bezpośrednio od I do III
# ⚠️ Musi być PRZED P49 (ogólne trójstronne) — bardziej szczegółowa reguła
else := {
    "matched":true,"rule_id":"jdg.crossborder.triangular_simplified",
    "package":"jdg.crossborder","priority":54,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"",
    "procedure":"TRIANGULAR_SIMPLIFIED","vat_exemption":"",
    "vat_ue_summary_required":true,
    "triangular_simplified_valid":true,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"Transakcja trójstronna — procedura uproszczona",
    "_legal_basis":"Art. 135-138 VAT",
    "_warnings":["Transakcja trójstronna uproszczona — JDG jako drugi podmiot nie rejestruje VAT w kraju przeznaczenia. Faktura musi zawierać adnotację o procedurze uproszczonej."]
} {
    input.invoice.procedure == "TRIANGULAR"
    input.invoice.triangular_simplified == true
    input.jdg_entrepreneur.triangular_role == "INTERMEDIARY"
    input.invoice.vat_ue_annotation_present == true
}

# ══════ P49: triangular_transaction — Transakcja trójstronna ══════
# Catch-all dla transakcji trójstronnych
else := {
    "matched":true,"rule_id":"jdg.crossborder.triangular_transaction",
    "package":"jdg.crossborder","priority":49,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"",
    "procedure":"TRIANGULAR","vat_exemption":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 135-138 VAT",
    "_warnings":["Transakcja trójstronna — procedura uproszczona"]
} {
    input.invoice.procedure == "TRIANGULAR"
}

# ══════ P46: vida_digital_reporting — ViDA — VAT in Digital Age (DRR) ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.vida_digital_reporting",
    "package":"jdg.crossborder","priority":46,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "procedure":"VIDA_DRR","vat_exemption":"","vida_drr_required":true,
    "vida_reporting_frequency":"REAL_TIME","vida_platform_liable":is_platform,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"ViDA DRR — cyfrowe raportowanie transgraniczne",
    "_legal_basis":"ViDA (EU 2022/890) — Digital Reporting Requirements",
    "_warnings":[sprintf("ViDA DRR — raportowanie transgraniczne w czasie rzeczywistym. Kontrahent z %s. Platforma odpowiedzialna za VAT: %s. Transakcje B2C przez platformy cyfrowe", [object.get(input.vendor, "country", "UE"), platform_info])]
} {
    input.invoice.cross_border_digital == true
    input.vendor.country in eu_countries
    input.vendor.country != "PL"
    is_platform := object.get(input.invoice, "via_digital_platform", false)
    platform_info = "TAK" { is_platform == true }
    platform_info = "NIE" { is_platform == false }
}

# ══════ P47: icow_import_control — ICOW — Import Control System ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.icow_import_control",
    "package":"jdg.crossborder","priority":47,
    "vat_rate":"0.23","rounding_level":"position","gtu_code":"",
    "procedure":"ICOW_IMPORT","vat_exemption":"","icow_ics2_required":true,
    "icow_entry_summary_declaration":"ENS_REQUIRED",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"ICOW ICS2 — przywozowa deklaracja skrócona",
    "_legal_basis":"ICS2 (EU 2021/348) — Import Control System 2",
    "_warnings":[sprintf("ICOW ICS2 — import spoza UE. Wymagana przywozowa deklaracja skrócona (ENS). Towar: %s, wartość: %.2f PLN", [object.get(input.invoice, "commodity_description", "importowany towar"), object.get(input.invoice, "amount_net", 0)])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure == "IMPORT"
    input.vendor.country == "NON_EU"
}

# ══════ P43: customs_warehouse — Skład celny / procedura zawieszenia ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.customs_warehouse",
    "package":"jdg.crossborder","priority":43,
    "vat_rate":"0.00","rounding_level":"total","gtu_code":"",
    "procedure":"CUSTOMS_WAREHOUSE","vat_exemption":"","customs_suspension":true,
    "vat_deferred_until_release":true,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 33-33a VAT + UKC (EU 952/2013)",
    "_warnings":["SKŁAD CELNY — VAT zawieszony do czasu dopuszczenia do obrotu"]
} {
    input.invoice.procedure == "CUSTOMS_WAREHOUSE"
    input.invoice.customs_suspension == true
}

# ══════ P44: tp_jdg_family — Ceny transferowe JDG-rodzina (Art. 23o PIT) ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.tp_jdg_family",
    "package":"jdg.crossborder","priority":44,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "procedure":"TP_FAMILY","vat_exemption":"",
    "tp_risk":"HIGH","tp_documentation_required":true,
    "tp_threshold_exceeded":threshold_exceeded,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Ceny transferowe JDG-rodzina — ryzyko Art. 23o PIT",
    "_legal_basis":"Art. 23o-23zf PIT (TP dla JDG)",
    "_warnings":[sprintf("CENY TRANSFEROWE — transakcja z podmiotem powiązanym (rodzina). %.2f PLN. %s", [object.get(input.invoice, "amount_net", 0), threshold_info])]
} {
    input.vendor.is_related_party == true
    object.get(input.invoice, "amount_net", 0) > 0
    tp_annual := object.get(input.jdg_entrepreneur, "tp_annual_total", 0)
    threshold_exceeded := tp_annual > 500000
    threshold_info = "PRÓG PRZEKROCZONY — dokumentacja TP obligatoryjna!" { threshold_exceeded == true }
    threshold_info = "Poniżej progu 500k PLN — dokumentacja uproszczona" { threshold_exceeded == false }
}

# ══════ P50: cfc_jdg_controlled — CFC — zagraniczna spółka kontrolowana ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.cfc_jdg_controlled",
    "package":"jdg.crossborder","priority":50,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "procedure":"CFC","vat_exemption":"",
    "cfc_risk_detected":true,"cfc_effective_tax_rate":etr_pct,
    "cfc_reporting_required":true,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"CFC — zagraniczna spółka kontrolowana. Obowiązek opodatkowania w PL!",
    "_legal_basis":"Art. 30f PIT (CFC dla JDG)",
    "_warnings":[sprintf("CFC — zagraniczna spółka kontrolowana! JDG posiada >50%% udziałów w spółce z %s. Efektywna stawka: %.1f%%. Jeśli < PL → opodatkowanie CFC w PL stawką 19%%!", [cfc_country, etr_pct])]
} {
    input.jdg_entrepreneur.has_cfc == true
    cfc_country := object.get(input.jdg_entrepreneur, "cfc_country", "")
    cfc_etr := object.get(input.jdg_entrepreneur, "cfc_effective_tax_rate", 0)
    etr_pct := cfc_etr * 100
    cfc_country != "PL"
}

# ══════ P51: cross_border_services_wht — Usługi transgraniczne + WHT ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.cross_border_services_wht",
    "package":"jdg.crossborder","priority":51,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "procedure":"CROSS_BORDER_SERVICES_WHT","vat_exemption":"",
    "wht_applicable":true,"wht_rate":wht_rate,"wht_tax_amount":wht_amount,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"TRIAGE_QUEUE","_routing_reason":"WHT — podatek u źródła od usług transgranicznych",
    "_legal_basis":"Art. 29-30a PIT (WHT)",
    "_warnings":[sprintf("WHT — podatek u źródła od usług z %s. Stawka: %.0f%%, kwota: %.2f PLN. Sprawdź umowę o UPO — może obniżyć stawkę!", [object.get(input.vendor, "country", "zagranica"), wht_rate_pct, wht_amount])]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.country != "PL"
    input.invoice.expense_type in {"SERVICE", "CONSULTING", "IT_SERVICES", "ROYALTIES", "LICENSE"}
    amount_net := object.get(input.invoice, "amount_net", 0)
    amount_net > 0
    has_dtt := object.get(input.vendor, "double_tax_treaty", false)
    wht_rate = "0.05" { has_dtt == true }
    wht_rate = "0.20" { has_dtt == false }
    wht_rate_pct = 5 { has_dtt == true }
    wht_rate_pct = 20 { has_dtt == false }
    wht_amount := amount_net * to_number(wht_rate)
}

# ══════ P52: pe_permanent_establishment — Zagraniczny zakład JDG (PE) ══════
else := {
    "matched":true,"rule_id":"jdg.crossborder.pe_permanent_establishment",
    "package":"jdg.crossborder","priority":52,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "procedure":"PE_ESTABLISHMENT","vat_exemption":"",
    "pe_risk_detected":true,"pe_country":pe_country,
    "pe_registration_required":true,
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"PE — ryzyko powstania zagranicznego zakładu JDG",
    "_legal_basis":"Art. 4a pkt 11 PIT + Model Tax Convention (OECD)",
    "_warnings":[sprintf("ZAGRANICZNY ZAKŁAD (PE) — ryzyko stałego miejsca prowadzenia działalności w %s! Jeśli PE istnieje: rejestracja podatkowa za granicą + opodatkowanie dochodu PE za granicą", [pe_country])]
} {
    input.jdg_entrepreneur.has_permanent_establishment_risk == true
    pe_country := object.get(input.jdg_entrepreneur, "pe_country", "")
    pe_country != "PL"
    pe_country != ""
}



# ══════ P450-P454: IMPORT USŁUG SZCZEGÓŁOWY — Doc 36 §14 (5 reguł) ══════

# P450: import_services_non_eu_b2b — Import usług spoza UE B2B
else := {
    "matched":true,"rule_id":"jdg.crossborder.import_services_non_eu_b2b",
    "package":"jdg.crossborder","priority":450,
    "vat_rate":"0.00","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"IMPORT_SERVICES_NON_EU",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","reverse_charge":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 17 ust. 1 pkt 4 VAT",
    "_warnings":["IMPORT USŁUG NON-EU B2B — reverse charge. JDG rozlicza VAT należny i naliczony. NP na fakturze."]
} {
    input.vendor.country not in EU_COUNTRIES
    input.vendor.country!="PL"
    input.invoice.direction=="PURCHASE"
    input.invoice.category in {"SERVICES","IT","CONSULTING","MARKETING"}
    vendor_is_taxable:=object.get(input.vendor,"is_taxable_person",false)
    vendor_is_taxable==true
}

# P451: import_services_non_eu_b2c — B2C spoza UE
else := {
    "matched":true,"rule_id":"jdg.crossborder.import_services_non_eu_b2c",
    "package":"jdg.crossborder","priority":451,
    "vat_rate":"0.23","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"IMPORT_B2C",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 28k-28l VAT",
    "_warnings":["Import usług B2C spoza UE — VAT należny w PL (23%). Sprawdź czy nie dotyczy Cię OSS/IOSS."]
} {
    input.vendor.country not in EU_COUNTRIES
    input.vendor.country!="PL"
    input.invoice.direction=="PURCHASE"
    object.get(input.vendor,"is_taxable_person",true)==false
}

# P452: import_services_tax_point — Moment powstania obowiązku
else := {
    "matched":true,"rule_id":"jdg.crossborder.import_services_tax_point",
    "package":"jdg.crossborder","priority":452,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","tax_point":"EARLIER_OF_DELIVERY_OR_PAYMENT",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 19a ust. 1 VAT",
    "_warnings":["Import usług — obowiązek VAT powstaje w dacie wykonania usługi LUB zapłaty (wcześniejsza). JPK_V7 w okresie powstania obowiązku."]
} {
    input.invoice.procedure=="IMPORT_SERVICES"
}

# P453: import_services_fx_rate — Kurs NBP z dnia poprzedzającego
else := {
    "matched":true,"rule_id":"jdg.crossborder.import_services_fx_rate",
    "package":"jdg.crossborder","priority":453,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","fx_source":"NBP_DAY_BEFORE_TAX_POINT",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 31a ust. 1 VAT",
    "_warnings":["Kurs waluty dla importu usług — NBP z dnia poprzedzającego powstanie obowiązku podatkowego."]
} {
    input.invoice.currency!="PLN"
    input.invoice.procedure=="IMPORT_SERVICES"
}

# P454: import_services_tax_base — Podstawa opodatkowania = netto
else := {
    "matched":true,"rule_id":"jdg.crossborder.import_services_tax_base",
    "package":"jdg.crossborder","priority":454,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","tax_base":"NET_AMOUNT_DUE_TO_SUPPLIER",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 29a ust. 1 VAT",
    "_warnings":["Podstawa opodatkowania importu usług = kwota netto należna dostawcy. Nie uwzględniaj własnych kosztów dodatkowych."]
} {
    input.invoice.procedure=="IMPORT_SERVICES"
}
