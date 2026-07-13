# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.vat
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 16
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.vat
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.vat.no_match","package":"jdg.vat","priority":99999}

# jdg.vat.simplified_receipt_deduction — Paragon z NIP do 450 PLN jako faktura uproszczona
decide :=   {"matched":true,"rule_id":"jdg.vat.simplified_receipt_deduction","package":"jdg.vat","priority":36,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Paragon z NIP do 450 PLN jako faktura uproszczona","_legal_basis":"Art. 106e ust. 5 pkt 3 VAT","_warnings":["Paragon z NIP — odliczenie VAT do 450 PLN brutto"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "invoice_type", "") == "INVOICE"; object.get(input.invoice, "invoice_type", "") == "RECEIPT"
}

# jdg.vat.registration_status_block — Blokada faktur VAT bez rejestracji VAT-R
else :=   {"matched":true,"rule_id":"jdg.vat.registration_status_block","package":"jdg.vat","priority":39,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Blokada faktur VAT bez rejestracji VAT-R","_legal_basis":"Art. 96 ust. 1, 4-5 VAT","_warnings":["Brak VAT-R — nie możesz wystawiać faktur z VAT!"]} {
    input.jdg_entrepreneur.vat_status != "ACTIVE"
}

# jdg.vat.subject_exemption_startup_proportion — Limit zwolnienia proporcjonalny dla JDG w trakcie roku
else :=   {"matched":true,"rule_id":"jdg.vat.subject_exemption_startup_proportion","package":"jdg.vat","priority":59,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Limit zwolnienia proporcjonalny dla JDG w trakcie roku","_legal_basis":"Art. 113 ust. 9 VAT","_warnings":["Zwolnienie proporcjonalne — limit = (dni/365) × 200k"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.jdg_entrepreneur, "has_mixed_vat_activity", false) == true
}

# jdg.vat.object_exemption_pkd — Zwolnienie przedmiotowe VAT wg PKD
else :=   {"matched":true,"rule_id":"jdg.vat.object_exemption_pkd","package":"jdg.vat","priority":61,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie przedmiotowe VAT wg PKD","_legal_basis":"Art. 43 VAT","_warnings":["Zwolnienie przedmiotowe VAT — usługa zwolniona na podstawie PKD"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "vat_exemption", "") != ""
}

# jdg.vat.exemption_financial — Zwolnienie VAT dla usług finansowych
else :=   {"matched":true,"rule_id":"jdg.vat.exemption_financial","package":"jdg.vat","priority":62,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie VAT dla usług finansowych","_legal_basis":"Art. 43 ust. 1 pkt 37-41 VAT","_warnings":["Usługa finansowa zwolniona z VAT — wyjątek: doradztwo, factoring"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "category_code", "") == "FINANCIAL"
}

# jdg.vat.exemption_insurance — Zwolnienie VAT dla usług ubezpieczeniowych
else :=   {"matched":true,"rule_id":"jdg.vat.exemption_insurance","package":"jdg.vat","priority":63,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie VAT dla usług ubezpieczeniowych","_legal_basis":"Art. 43 ust. 1 pkt 37 VAT","_warnings":["Usługa ubezpieczeniowa zwolniona z VAT"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "category_code", "") == "FINANCIAL"
}

# jdg.vat.blocked_categories_no_deduction — Blokada odliczenia VAT — hotele, restauracje (poza cateringiem)
else :=   {"matched":true,"rule_id":"jdg.vat.blocked_categories_no_deduction","package":"jdg.vat","priority":183,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Blokada odliczenia VAT — hotele, restauracje (poza cateringiem)","_legal_basis":"Art. 88 VAT","_warnings":["Wydatek z kategorii wyłączonej z odliczenia VAT — Art. 88 VAT"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.bad_debt_debtor_mandatory_correction — OBOWIĄZEK korekty VAT przez dłużnika po 90 dniach
else :=   {"matched":true,"rule_id":"jdg.vat.bad_debt_debtor_mandatory_correction","package":"jdg.vat","priority":184,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"OBOWIĄZEK korekty VAT przez dłużnika po 90 dniach","_legal_basis":"Art. 89b VAT","_warnings":["OBOWIĄZKOWA korekta VAT! Niezapłacona faktura >90 dni — zwróć odliczony VAT!"]} {
    object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.pre_proportion_mixed — Pre-współczynnik VAT dla sprzedaży mieszanej
else :=   {"matched":true,"rule_id":"jdg.vat.pre_proportion_mixed","package":"jdg.vat","priority":185,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pre-współczynnik VAT dla sprzedaży mieszanej","_legal_basis":"Art. 90 VAT","_warnings":["Sprzedaż mieszana — VAT odliczany proporcjonalnie"]} {
    object.get(input.invoice, "private_use_percent", 0) > 0; object.get(input.jdg_entrepreneur, "has_mixed_vat_activity", false) == true
}

# jdg.vat.vehicle_50_deduction — Ograniczenie odliczenia VAT do 50% dla aut mieszanych
else :=   {"matched":true,"rule_id":"jdg.vat.vehicle_50_deduction","package":"jdg.vat","priority":186,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Ograniczenie odliczenia VAT do 50% dla aut mieszanych","_legal_basis":"Art. 86a VAT","_warnings":["Samochód mieszany — odliczenie VAT tylko 50%"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "private_use_percent", 0) > 0
}

# jdg.vat.annual_correction_assets — Korekta roczna VAT — 1/5 (ruchomości) lub 1/10 (nieruchomości)
else :=   {"matched":true,"rule_id":"jdg.vat.annual_correction_assets","package":"jdg.vat","priority":187,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta roczna VAT — 1/5 (ruchomości) lub 1/10 (nieruchomości)","_legal_basis":"Art. 91 VAT","_warnings":[]} {
    object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.deduction_deadline_3m — Odliczenie VAT w ciągu 3 okresów miesięcznych
else :=   {"matched":true,"rule_id":"jdg.vat.deduction_deadline_3m","package":"jdg.vat","priority":188,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Odliczenie VAT w ciągu 3 okresów miesięcznych","_legal_basis":"Art. 86 ust. 11 VAT","_warnings":["Odliczenie VAT — max 3 miesiące od otrzymania faktury"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.bad_debt_relief_creditor — Ulga na złe długi — wierzyciel po 90 dniach
else :=   {"matched":true,"rule_id":"jdg.vat.bad_debt_relief_creditor","package":"jdg.vat","priority":189,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Ulga na złe długi — wierzyciel po 90 dniach","_legal_basis":"Art. 89a VAT","_warnings":["Ulga na złe długi — korekta in minus po 90 dniach braku płatności"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "is_paid", true) == false; object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.vat.refund_timing_and_interest — Terminy zwrotu VAT: 25/60/180 dni + odsetki
else :=   {"matched":true,"rule_id":"jdg.vat.refund_timing_and_interest","package":"jdg.vat","priority":192,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Terminy zwrotu VAT: 25/60/180 dni + odsetki","_legal_basis":"Art. 87 ust. 2-7 VAT","_warnings":["Zwrot VAT przeterminowany — należą się odsetki"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0
}

# jdg.vat.deregistration_vat_z — VAT-Z — obowiązek przy zaprzestaniu lub zwolnieniu
else :=   {"matched":true,"rule_id":"jdg.vat.deregistration_vat_z","package":"jdg.vat","priority":233,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"VAT-Z — obowiązek przy zaprzestaniu lub zwolnieniu","_legal_basis":"Art. 96 ust. 6-8 VAT","_warnings":["Obowiązek VAT-Z — 7 dni od zaprzestania działalności"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0
}

# jdg.vat.payment_deadline_and_interest — Termin płatności VAT do 25. + odsetki
else :=   {"matched":true,"rule_id":"jdg.vat.payment_deadline_and_interest","package":"jdg.vat","priority":234,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Termin płatności VAT do 25. + odsetki","_legal_basis":"Art. 103 ust. 1 VAT","_warnings":["VAT niezapłacony do 25. — naliczono odsetki"]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}
