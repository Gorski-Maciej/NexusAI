# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Accounting: PKPiR, amortyzacja, leasing (P800-P870)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Accounting Package — PKPiR Columns, Depreciation, Leasing, Mixed-Use
# description: |
#   PAS 7 Multi-Pass. First-Match-Wins else-chain. Obsługuje księgowość JDG:
#   mapowanie na kolumny PKPiR (P800-P802), amortyzację liniową (P840) i
#   jednorazową dla małych podatników (P842), wydatki mieszane: home office
#   proporcjonalnie (P850), samochód 75%/50% bez ewidencji (P852), leasing
#   operacyjny (P860), różnice kursowe (P870).
# architecture: Multi-Pass PAS 7 (ADR-001)
# legal_basis: Rozp. MF PKPiR, Art. 22a-22o PIT, Art. 86a VAT
# edge_cases:
#   - P842: tylko dla małych podatników + kwota ≤ 100k PLN
#   - P850: home_office_area_percent musi być > 0
#   - P852: private_use_percent > 0 AND has_mileage_log = false → 75% KUP/50% VAT
# package: jdg.accounting
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.accounting
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.accounting.no_match","package":"jdg.accounting","priority":880}

pkpir_map := {
    "GOODS_REVENUE":10, "OTHER_REVENUE":11, "GOODS_PURCHASE":12,
    "ANCILLARY_COSTS":13, "SALARIES":14, "OTHER_EXPENSES":15,
    "NON_KUP":16, "FIXED_ASSET":17, "ZUS_SOCIAL_ENTREPRENEUR":15,
    "ZUS_HEALTH_ENTREPRENEUR":16, "RENT":15, "UTILITIES":15,
    "OFFICE_SUPPLIES":15, "SOFTWARE":15, "ACCOUNTING_SERVICES":15,
    "LEGAL_SERVICES":15, "MARKETING":15, "ADVERTISING":15,
    "CONSULTING":15, "TRAINING":15, "TELECOMMUNICATIONS":15,
    "TRANSPORT_GOODS":15, "MAINTENANCE":15, "SECURITY":15
}

# ══════ P800: pkpir_column_mapping — Mapowanie wydatku na kolumnę PKPiR ══════
decide := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_column_mapping",
    "package":"jdg.accounting","priority":800,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_column":col_num,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozporządzenie MF w sprawie PKPiR",
    "_warnings":[]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    expense_type := object.get(input.invoice,"expense_type","OTHER_EXPENSES")
    col_num := object.get(pkpir_map,expense_type,15)
}

# ══════ P801: pkpir_revenue_recognition — Moment rozpoznania przychodu ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_revenue_recognition",
    "package":"jdg.accounting","priority":801,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_revenue_date":revenue_date,"pkpir_column":10,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 20-21 rozporządzenia PKPiR",
    "_warnings":[]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "SALE"
    revenue_date := object.get(input.invoice,"issue_date","")
}

# ══════ P802: pkpir_expense_recognition — Moment ujęcia kosztu ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.pkpir_expense_recognition",
    "package":"jdg.accounting","priority":802,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_expense_date":expense_date,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"§ 20 rozporządzenia PKPiR",
    "_warnings":[]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    input.invoice.direction == "PURCHASE"
    expense_date := object.get(input.invoice,"issue_date","")
}

# ══════ P840: depreciation_linear_jdg — Amortyzacja liniowa ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.depreciation_linear",
    "package":"jdg.accounting","priority":840,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_column":17,
    "depreciation_method":"LINEAR","depreciation_rate":depreciation_rate,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22a-22o PIT",
    "_warnings":[]
} {
    input.invoice.expense_type == "FIXED_ASSET"
    kst_group := object.get(input.invoice,"kst_group",0)
    depreciation_rates := {1:0.025,2:0.025,3:0.04,4:0.10,5:0.20,6:0.30,7:0.20,8:0.20,9:0.20,10:0.10}
    depreciation_rate := object.get(depreciation_rates,kst_group,0.20)
}

# ══════ P842: depreciation_one_off_jdg — Jednorazowa amortyzacja dla małych podatników ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.depreciation_one_off",
    "package":"jdg.accounting","priority":842,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"pkpir_column":17,
    "depreciation_method":"ONE_OFF","depreciation_rate":"1.00",
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22k ust. 7 PIT",
    "_warnings":["Jednorazowa amortyzacja — limit 50 000 EUR rocznie dla małych podatników"]
} {
    input.jdg_entrepreneur.is_small_taxpayer == true
    input.invoice.expense_type == "FIXED_ASSET"
    input.invoice.amount_net <= 100000
}

# ══════ P850: private_mixed_home_office — Home office proporcja ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.private_mixed_home_office",
    "package":"jdg.accounting","priority":850,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"partial","kus_percent":ku_percent,
    "vat_deduction_percent":ku_percent,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 1 PIT, Art. 86 ust. 1 VAT",
    "_warnings":["Home office — KUP i VAT proporcjonalnie do powierzchni firmowej"]
} {
    input.invoice.is_home_office == true
    ho_pct := object.get(input.invoice,"home_office_area_percent",0)
    ho_pct > 0
    ku_percent := ho_pct
}

# ══════ P852: private_mixed_car — Samochód mieszany 75% KUP ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.private_mixed_car",
    "package":"jdg.accounting","priority":852,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"partial","kus_percent":75,
    "vat_deduction_percent":50,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 23 ust. 1 pkt 46 PIT, Art. 86a VAT",
    "_warnings":["Samochód bez ewidencji przebiegu — KUP 75%, VAT 50%"]
} {
    input.invoice.category_code == "CAR"
    input.invoice.private_use_percent > 0
    input.invoice.has_mileage_log == false
}

# ══════ P860: operating_lease_full_kup — Leasing operacyjny → KUP ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.operating_lease_full_kup",
    "package":"jdg.accounting","priority":860,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"full","kus_percent":100,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 ust. 1 PIT",
    "_warnings":[]
} {
    input.invoice.expense_type == "LEASE"
    input.invoice.lease_type == "OPERATING"
}

# ══════ P870: fx_differences_recognition — Różnice kursowe ══════
else := {
    "matched":true,"rule_id":"jdg.accounting.fx_differences_recognition",
    "package":"jdg.accounting","priority":870,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 14 ust. 2c PIT",
    "_warnings":["Transakcja walutowa — różnice kursowe podatkowe"]
} {
    input.invoice.currency != "PLN"
    input.invoice.is_paid == true
}
