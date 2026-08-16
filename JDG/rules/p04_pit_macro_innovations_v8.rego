# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P04 INNOVATIONS ENGINE v8.0
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p04_innovations | Report: RAPORT_P04_JDG_PIT_MACRO_v7.0
# Fixes: health limit 12900→14100, 85528 externalization, rates, NKUP, leasing
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.p04_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.p04_innovations.no_match","package":"jdg.p04_innovations","priority":999999}

# ═══ INN01: Health Limit 12900→14100 ═══
decide := {
    "matched":true,"rule_id":"jdg.p04_innovations.health_limit_fix", "_legal_basis": "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)","package":"jdg.p04_innovations","priority":1000,
    "_routing": "",
    "innovation":"INN01_HEALTH_LIMIT_14100","action":"FIX_HEALTH_LIMIT",
    "old_value":12900,"new_value":14100,"year":2026,
    "affected":["forms.rego L140","kup.rego P570"],
    "recommendation":"Read from data.thresholds.zus.health_linear_deduction_limit (already fixed in P07 H111)",
    "legal_basis":"Art. 30c ust. 2 PIT — 2026 limit"
} { object.get(input.jdg_entrepreneur,"p04_health_limit",false)==true }

# ═══ INN02: 85528 Externalizer ═══
else := {
    "matched":true,"rule_id":"jdg.p04_innovations.pit0_limit_externalizer", "_legal_basis": "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)","package":"jdg.p04_innovations","priority":2000,
    "_routing": "",
    "innovation":"INN02_85528_EXTERNALIZER","action":"EXTERNALIZE_85528",
    "hardcoded_value":85528,"occurrences":"20+ in art21/exemptions/family_estonian",
    "thresholds_key":"data.jdg.thresholds.pit.pit0_shared_limit",
    "legal_basis":"Art. 21 ust. 1 pkt 148-154 PIT + ADR-002"
} { object.get(input.jdg_entrepreneur,"p04_pit0_limit",false)==true }

# ═══ INN03: PIT Rates Externalizer ═══
else := {
    "matched":true,"rule_id":"jdg.p04_innovations.pit_rates_externalizer", "_legal_basis": "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)","package":"jdg.p04_innovations","priority":3000,
    "_routing": "",
    "innovation":"INN03_PIT_RATES_EXTERNALIZER","action":"EXTERNALIZE_RATES",
    "rates":{"scale_low":"0.12","scale_high":"0.32","linear":"0.19","ipbox":"0.05"},
    "thresholds_keys":["pit_scale_rate_low","pit_scale_rate_high","pit_linear_rate","pit_ipbox_rate"],
    "occurrences":"20+ hardcoded in forms/kup/rd_relief/ipbox",
    "legal_basis":"Art. 27, 30c, 30ca PIT + ADR-002"
} { input.jdg_entrepreneur.business_type=="JDG" }

# ═══ INN04: Car Expense 75% Limit ═══
else := {
    "matched":true,"rule_id":"jdg.p04_innovations.car_expense_75pct", "_legal_basis": "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)","package":"jdg.p04_innovations","priority":4000,
    "_routing": "",
    "innovation":"INN04_CAR_EXPENSE_75PCT","action":"ADD_75PCT_LIMIT",
    "current":"Only 150k/225k car value limit","missing":"75% limit on fuel/service/insurance without mileage log",
    "full_deduction_condition":"Mileage log (ewidencja przebiegu) → 100% deduction",
    "legal_basis":"Art. 23 ust. 1 pkt 47a PIT"
} { object.get(input.invoice,"vehicle_expense",false)==true }

# ═══ INN05: Leasing Type Differentiator ═══
else := {
    "matched":true,"rule_id":"jdg.p04_innovations.leasing_differentiator", "_legal_basis": "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)","package":"jdg.p04_innovations","priority":5000,
    "_routing": "",
    "innovation":"INN05_LEASING_DIFFERENTIATOR","action":"DIFFERENTIATE_LEASING",
    "types":{"OPERATIONAL":"Full lease payment KUP","FINANCIAL":"Only interest KUP + depreciation"},
    "limit_operational":"150k/225k proportional limit on lease payments",
    "legal_basis":"Art. 22-23 PIT + Art. 3 ust. 4 UoR"
} { object.get(input.invoice,"leasing_type","")!="" }

# ═══ INN06: Advert vs Representation ═══
else := {
    "matched":true,"rule_id":"jdg.p04_innovations.advert_vs_representation", "_legal_basis": "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)","package":"jdg.p04_innovations","priority":6000,
    "_routing": "",
    "innovation":"INN06_ADVERT_VS_REPRESENTATION","action":"DIFFERENTIATE",
    "representation":"NKUP (Art. 23 ust. 1 pkt 23)","advertising":"KUP (Art. 22 ust. 1)",
    "criteria":["Target: clients vs general public","Content: product-focused vs prestige-focused","Venue: trade fair vs restaurant"],
    "routing":"TRIAGE_QUEUE","legal_basis":"Art. 22-23 PIT"
} { object.get(input.invoice,"expense_type","")=="MARKETING" }

# ═══ COVERAGE ═══
else := {
    "matched":true,"rule_id":"jdg.p04_innovations.summary", "_legal_basis": "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)","package":"jdg.p04_innovations","priority":99999,
    "_routing": "",
    "innovation":"P04_PIT_MACRO","action":"REPORT","total_fixes":6,"ready_for_p05":true
} { true }
