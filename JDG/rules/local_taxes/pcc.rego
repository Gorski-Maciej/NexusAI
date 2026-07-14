# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Local Taxes: PCC (P1300-P1304)
# Doc 26: Podatki lokalne — PCC od zakupów, pożyczek, zwolnienia
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Package — local_taxes/pcc
# description: PCC — podatek od czynności cywilnoprawnych dla JDG
# architecture: Multi-Pass (ADR-001)
# package: jdg.local_taxes.pcc
# doc_source: Plan OPA/26_JDG_COMPREHENSIVE_EXPANSION.md §VIII
#
package jdg.local_taxes.pcc

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.local_taxes.pcc.no_match",
    "package": "jdg.local_taxes.pcc",
    "priority": 1309
}

# ══════ P1300: pcc_mandatory_purchase_from_private — PCC 2% od zakupu od osoby prywatnej ══════
# Cel biznesowy: Wykrycie obowiązku PCC przy zakupie towarów od osoby prywatnej
# niebędącej podatnikiem VAT. Transakcje z VAT NIE podlegają PCC.
decide := {
    "matched": true,
    "rule_id": "jdg.local_taxes.pcc.pcc_mandatory_purchase",
    "package": "jdg.local_taxes.pcc",
    "priority": 1300,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "vat_exemption": "",
    "procedure": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "local_tax_type": "PCC",
    "local_tax_rate": "0.02",
    "pcc_transaction_type": "PURCHASE_FROM_PRIVATE",
    "pcc_amount": pcc_amount,
    "pcc_declaration": "PCC-3",
    "pcc_deadline_days": 14,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "PCC od zakupu od osoby prywatnej — 2% wartości rynkowej",
    "_legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959), Art. 1-2, Art. 7",
    "_warnings": [sprintf("PCC 2%% — zakup od osoby prywatnej za %.2f PLN. Podatek: %.2f PLN. Deklaracja PCC-3 w 14 dni od daty umowy. UWAGA: jeśli transakcja podlega VAT, PCC jest wyłączone.", [purchase_value, pcc_amount])]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.country == "PL"
    input.vendor.is_company == false
    input.invoice.vat_taxable == false

    # Dotyczy zakupu rzeczy (nie usług)
    is_goods_purchase := object.get(input.invoice, "is_asset_purchase", false)
    is_goods_purchase == true

    purchase_value := object.get(input.invoice, "amount_gross", 0)

    # Próg 1000 PLN z thresholds (Art. 9 pkt 4 Ustawy o PCC)
    pcc_exemption_limit := object.get(
        object.get(object.get(data.thresholds, "jdg", {}), "limits", {}),
        "pcc_exemption_limit", 1000
    )
    purchase_value > pcc_exemption_limit

    # Stawka 2% z thresholds
    pcc_rate := object.get(
        object.get(object.get(data.thresholds, "jdg", {}), "rates", {}),
        "pcc_standard", 0.02
    )
    pcc_amount = purchase_value * pcc_rate
}

# ══════ P1302: pcc_loan_from_private — PCC 0.5% od pożyczki od osoby prywatnej ══════
# Cel biznesowy: Obowiązek PCC od pożyczki od osoby prywatnej na cele JDG
else := {
    "matched": true,
    "rule_id": "jdg.local_taxes.pcc.pcc_loan_from_private",
    "package": "jdg.local_taxes.pcc",
    "priority": 1302,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "vat_exemption": "",
    "procedure": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "local_tax_type": "PCC",
    "local_tax_rate": "0.005",
    "pcc_transaction_type": "LOAN_FROM_PRIVATE",
    "pcc_amount": pcc_loan_amount,
    "pcc_declaration": "PCC-3",
    "pcc_deadline_days": 14,
    "loan_from_family": is_family,
    "loan_exempt": is_exempt,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "PCC od pożyczki od osoby prywatnej — 0.5% od kwoty",
    "_legal_basis": "Ustawa o PCC, Art. 7 ust. 1 pkt 4",
    "_warnings": [sprintf("PCC OD POŻYCZKI — %.2f PLN (0.5%% od %.2f PLN). %s. Deklaracja PCC-3 w 14 dni od zawarcia umowy.", [pcc_loan_amount, loan_amount, exemption_note])]
} {
    input.invoice.transaction_type == "LOAN_RECEIVED"
    input.vendor.is_company == false
    loan_amount := object.get(input.invoice, "amount_net", 0)
    loan_amount > 0

    # Zwolnienie: pożyczka od rodziny (grupa 0) do limitu z thresholds — Art. 9 pkt 2 Ustawy o PCC
    family_loan_exempt_limit := object.get(
        object.get(object.get(data.thresholds, "jdg", {}), "limits", {}),
        "pcc_family_loan_exempt_limit", 36120
    )

    is_family := object.get(input.invoice, "loan_from_family", false)
    under_limit := loan_amount <= family_loan_exempt_limit

    is_exempt = true { is_family == true; under_limit == true }
    is_exempt = false { is_family == false }
    is_exempt = false { under_limit == false }

    # Stawka 0.5% z thresholds
    pcc_loan_rate := object.get(
        object.get(object.get(data.thresholds, "jdg", {}), "rates", {}),
        "pcc_other", 0.005
    )

    pcc_loan_amount = loan_amount * pcc_loan_rate { is_exempt == false }
    pcc_loan_amount = 0 { is_exempt == true }
    exemption_note = "ZWOLNIONE (pożyczka rodzinna ≤ 36 120 PLN)" { is_exempt == true }
    exemption_note = "Pełna stawka 0.5%" { is_exempt == false }
}

# ══════ P1304: pcc_company_formation_exempt — JDG nie podlega PCC od wkładów kapitałowych ══════
# Cel biznesowy: JDG (osoba fizyczna) NIE podlega PCC od wpłat na kapitał —
# PCC dotyczy tylko spółek kapitałowych. Reguła informacyjna.
else := {
    "matched": true,
    "rule_id": "jdg.local_taxes.pcc.pcc_formation_exempt",
    "package": "jdg.local_taxes.pcc",
    "priority": 1304,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "vat_exemption": "",
    "procedure": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "local_tax_type": "PCC",
    "pcc_not_applicable": true,
    "pcc_exemption_reason": "JDG_OSOBA_FIZYCZNA",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o PCC — opodatkowaniu podlegają tylko czynności dot. spółek kapitałowych",
    "_warnings": ["JDG jako osoba fizyczna nie podlega PCC od wkładów kapitałowych — PCC dotyczy tylko spółek kapitałowych."]
} {
    input.invoice.expense_type == "CAPITAL_CONTRIBUTION"
    input.jdg_entrepreneur.business_type == "JDG"
}
