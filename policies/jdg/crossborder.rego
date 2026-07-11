# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Crossborder: WNT, WDT, import, eksport, trójstronne (P40-P49)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Crossborder Package — Intra-EU & Non-EU Transactions
# description: |
#   PAS 3 Multi-Pass. First-Match-Wins else-chain. Obsługuje transakcje zagraniczne:
#   WNT reverse charge (P40), import usług UE (P41), WDT 0% (P42), WDT bez dokumentów
#   → stawka krajowa (P42c), import spoza UE (P45), eksport towarów (P48),
#   transakcje trójstronne (P49).
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

# ══════ P42: wdt_intracommunity_supply — WDT 0% VAT ══════
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

# ══════ P42_c: wdt_documentation_evidence — Wymóg dokumentów WDT ══════
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

# ══════ P49: triangular_transaction — Transakcja trójstronna ══════
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
