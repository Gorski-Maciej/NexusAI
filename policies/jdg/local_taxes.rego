# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Local: PCC, nieruchomości, transport (P1300-P1320)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.local
#
# METADATA
# title: JDG Package — local
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.local
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.local.no_match","package":"jdg.local","priority":1330}

# ══════ P1300: pcc_mandatory — PCC 2% od zakupu od osób prywatnych ══════
decide := {
    "matched":true,"rule_id":"jdg.local.pcc_mandatory",
    "package":"jdg.local","priority":1300,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","local_tax_rate":"0.02",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o podatku od czynności cywilnoprawnych",
    "_warnings":["PCC 2% — zakup od osoby prywatnej! Deklaracja PCC-3 w 14 dni."]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.is_company == false
    input.invoice.is_asset_purchase == true
}

# ══════ P1310: real_estate_commercial — Podatek od nieruchomości firmowych ══════
else := {
    "matched":true,"rule_id":"jdg.local.real_estate_commercial",
    "package":"jdg.local","priority":1310,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"REAL_ESTATE","local_tax_land_rate":1.15,"local_tax_building_rate":33.00,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o podatkach i opłatach lokalnych",
    "_warnings":["Podatek od nieruchomości firmowych — deklaracja DN-1 do 31 stycznia"]
} {
    input.invoice.category_code == "REAL_ESTATE"
    input.invoice.is_commercial == true
}

# ══════ P1320: transport_tax — Podatek od środków transportowych ══════
else := {
    "matched":true,"rule_id":"jdg.local.transport_tax",
    "package":"jdg.local","priority":1320,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"TRANSPORT","local_tax_applicable":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o podatkach i opłatach lokalnych",
    "_warnings":["Podatek od środków transportowych — deklaracja DT-1"]
} {
    input.invoice.category_code == "VEHICLE"
    input.invoice.vehicle_dmc >= 3.5
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1301-P1304 — PCC ROZSZERZONE: Pożyczki, udziały, zwolnienia            ║
# ║  Ustawa o podatku od czynności cywilnoprawnych (PCC)                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════ P1301: pcc_loan_agreement — PCC 0.5% od pożyczki ══════
else := {
    "matched":true,"rule_id":"jdg.local.pcc_loan_agreement",
    "package":"jdg.local","priority":1301,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","local_tax_rate":"0.005",
    "pcc_transaction_type":"LOAN","pcc_declaration":"PCC-3","pcc_deadline_days":14,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PCC od pożyczki — 0.5% od kwoty, deklaracja PCC-3 w 14 dni",
    "_legal_basis":"Art. 7 ust. 1 pkt 4 Ustawy o PCC",
    "_warnings":[sprintf("PCC OD POŻYCZKI — %.2f PLN (0.5%% od %.2f PLN). %s. Deklaracja PCC-3 w 14 dni od zawarcia umowy", [pcc_amount, loan_amount, exemption_info])]
} {
    input.invoice.transaction_type == "LOAN_RECEIVED"
    loan_amount := object.get(input.invoice, "amount_net", 0)
    loan_amount > 0

    # Zwolnienie: pożyczka od rodziny (grupa 0) do 36 120 PLN
    is_family := object.get(input.invoice, "loan_from_family", false)
    is_under_limit := loan_amount <= 36120

    is_exempt = true { is_family == true; is_under_limit == true }
    is_exempt = false { is_family == false }
    is_exempt = false { is_under_limit == false }

    pcc_amount = loan_amount * 0.005 { is_exempt == false }
    pcc_amount = 0 { is_exempt == true }
    exemption_info = "ZWOLNIONE (pożyczka rodzinna ≤ 36 120 PLN)" { is_exempt == true }
    exemption_info = "Pełna stawka 0.5%" { is_exempt == false }
}

# ══════ P1302: pcc_share_purchase — PCC 1% od zakupu udziałów/akcji ══════
else := {
    "matched":true,"rule_id":"jdg.local.pcc_share_purchase",
    "package":"jdg.local","priority":1302,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","local_tax_rate":"0.01",
    "pcc_transaction_type":"SHARE_PURCHASE","pcc_declaration":"PCC-3","pcc_deadline_days":14,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PCC od zakupu udziałów — 1% od wartości, deklaracja PCC-3",
    "_legal_basis":"Art. 7 ust. 1 pkt 1 lit. a Ustawy o PCC",
    "_warnings":[sprintf("PCC OD ZAKUPU UDZIAŁÓW — %.2f PLN (1%% od %.2f PLN). Deklaracja PCC-3 w 14 dni! Uwaga: jeśli transakcja podlega VAT, PCC jest wyłączone", [pcc_amount, share_value])]
} {
    input.invoice.transaction_type == "SHARE_PURCHASE"
    input.invoice.vat_applies == false
    share_value := object.get(input.invoice, "amount_net", 0)
    share_value > 0
    pcc_amount = share_value * 0.01
}

# ══════ P1303: pcc_sale_agreement — PCC 2% od umowy sprzedaży rzeczy ruchomych ══════
else := {
    "matched":true,"rule_id":"jdg.local.pcc_sale_agreement",
    "package":"jdg.local","priority":1303,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","local_tax_rate":"0.02",
    "pcc_transaction_type":"SALE_AGREEMENT","pcc_declaration":"PCC-3","pcc_deadline_days":14,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"PCC od umowy sprzedaży poza VAT — 2% od wartości rynkowej",
    "_legal_basis":"Art. 7 ust. 1 pkt 1 lit. a Ustawy o PCC",
    "_warnings":[sprintf("PCC OD UMOWY SPRZEDAŻY — %.2f PLN (2%% od %.2f PLN). Dotyczy sprzedaży poza VAT (osoba prywatna nieprowadząca działalności). Deklaracja PCC-3 w 14 dni", [pcc_amount, sale_value])]
} {
    input.invoice.transaction_type == "GOODS_SALE_PRIVATE"
    input.invoice.direction == "PURCHASE"
    input.vendor.is_company == false
    input.invoice.vat_applies == false
    sale_value := object.get(input.invoice, "amount_net", 0)
    sale_value > 1000
    pcc_amount = sale_value * 0.02
}

# ══════ P1304: pcc_exemption_check — Zwolnienia z PCC — kontrola progów ══════
else := {
    "matched":true,"rule_id":"jdg.local.pcc_exemption_check",
    "package":"jdg.local","priority":1304,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","local_tax_type":"PCC","pcc_exemption_applies": exemption_applies,
    "pcc_exemption_type": exemption_type,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 9 Ustawy o PCC",
    "_warnings":[sprintf("PCC — KONTROLA ZWOLNIEŃ: %s", [exemption_info])]
} {
    input.invoice.pcc_transaction == true

    amount := object.get(input.invoice, "amount_net", 0)

    # Próg 1000 PLN — poniżej brak PCC
    below_threshold := amount <= 1000

    # VAT wyłącza PCC (Art. 2 pkt 4 PCC)
    vat_applies := object.get(input.invoice, "vat_applies", false)
    vat_excludes_pcc := vat_applies == true

    # Notarialna czynność (np. umowa spółki) — inna stawka
    is_notarial := object.get(input.invoice, "pcc_notarial_act", false)

    exemption_applies = true { below_threshold }
    exemption_applies = true { vat_excludes_pcc }
    exemption_applies = false { not below_threshold; not vat_excludes_pcc }

    exemption_type = "PONIŻEJ_PROGU_1000PLN" { below_threshold == true }
    exemption_type = "VAT_WYŁĄCZA_PCC" { vat_applies == true }
    exemption_type = "OPODATKOWANE_0.5-2%" { below_threshold == false; vat_applies == false }

    exemption_info = "Zwolnione: kwota ≤ 1000 PLN" { below_threshold == true }
    exemption_info = "Zwolnione: transakcja podlega VAT" { vat_applies == true }
    exemption_info = sprintf("Opodatkowane PCC. Kwota %.2f PLN > 1000 PLN, brak VAT", [amount]) { below_threshold == false; vat_applies == false }
}
