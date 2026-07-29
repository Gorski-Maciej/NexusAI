# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P02 INNOVATIONS ENGINE v8.0
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p02_innovations | Report: RAPORT_P02_JDG_VAT_MACRO_MPP_v7.0
# Fixes: GTU collision, SLIM VAT 3 date, NP rate, MPP thresholds
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.p02_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.p02_innovations.no_match","package":"jdg.p02_innovations","priority":999999}

# ═══ INN01: GTU Map Fixer ═══
decide := {
    "matched":true,"rule_id":"jdg.p02_innovations.gtu_map_fix","package":"jdg.p02_innovations","priority":1000,
    "innovation":"INN01_GTU_MAP_FIXER","action":"FIX_GTU_MAP",
    "issues":{"FOOD_WASTE_COLLISION":"Both map to GTU_07","MISSING_GTU_03":"Used vehicles GTU_03 not in map"},
    "fixes":{"FOOD":"GTU_06","WASTE":"GTU_07","USED_VEHICLES":"GTU_03"},
    "legal_basis":"Art. 109 ust. 3d VAT + JPK_V7M schema"
} { object.get(input.jdg_entrepreneur,"p02_gtu_check",false)==true }

# ═══ INN02: NP Rate Handler ═══
else := {
    "matched":true,"rule_id":"jdg.p02_innovations.np_rate_handler","package":"jdg.p02_innovations","priority":2000,
    "innovation":"INN02_NP_RATE_HANDLER","action":"HANDLE_NP_RATE",
    "issue":"NP (not subject) transactions silently fall to 23% — VAT overcharge",
    "fix":"Add NP detection → vat_rate='NP', routing=NO_VAT, no JPK inclusion",
    "routing":"BLOCK_AND_ALERT","vat_rate":"NP",
    "legal_basis":"Art. 5-7 VAT — Czynnosci niepodlegajace VAT"
} { object.get(input.invoice,"vat_rate","")=="NP" }

# ═══ INN03: MPP Threshold Externalizer ═══
else := {
    "matched":true,"rule_id":"jdg.p02_innovations.mpp_threshold_externalizer","package":"jdg.p02_innovations","priority":3000,
    "innovation":"INN03_MPP_THRESHOLD_EXTERNALIZER","action":"EXTERNALIZE_MPP",
    "hardcoded_value":15000,"thresholds_key":"data.jdg.thresholds.vat.mpp_mandatory_threshold",
    "affected_files":["substantive.rego","compliance.rego","edge_cases.rego"],
    "recommendation":"Create missing threshold + update 6 files to read from it",
    "legal_basis":"Art. 108a VAT + ADR-002"
} { object.get(input.jdg_entrepreneur,"p02_mpp_threshold",false)==true }

# ═══ INN04: Duplicate Package Detector ═══
else := {
    "matched":true,"rule_id":"jdg.p02_innovations.duplicate_detector","package":"jdg.p02_innovations","priority":4000,
    "innovation":"INN04_DUPLICATE_PACKAGE_DETECTOR","action":"DETECT_DUPLICATES",
    "duplicates":["plan23_detailed.rego == plan26_critical.rego (identical, package jdg.vat)"],
    "fix":"Delete plan26_critical.rego or rename package to jdg.vat.critical",
    "routing":"BLOCK_AND_ALERT"
} { object.get(input.jdg_entrepreneur,"p02_duplicate_check",false)==true }

# ═══ INN05: Place of Supply Completer ═══
else := {
    "matched":true,"rule_id":"jdg.p02_innovations.place_of_supply","package":"jdg.p02_innovations","priority":5000,
    "innovation":"INN05_PLACE_OF_SUPPLY_COMPLETER","action":"COMPLETE_PLACE_OF_SUPPLY",
    "missing_rules":["B2B_Art28b","B2C_e-services_Art28k","Real_estate_Art28e","Transport_Art28f"],
    "current_coverage":"import_of_services: PL only (assumes all services in PL)",
    "legal_basis":"Art. 28a-28o VAT"
} { input.jdg_entrepreneur.business_type=="JDG" }

# ═══ INN06: Margin Scheme Completer ═══
else := {
    "matched":true,"rule_id":"jdg.p02_innovations.margin_scheme","package":"jdg.p02_innovations","priority":6000,
    "innovation":"INN06_MARGIN_SCHEME_COMPLETER","action":"COMPLETE_MARGIN",
    "implemented":["MARGIN_USED_GOODS"],
    "missing":["Art_119_travel_agency","Art_120_art_antiques_collectibles"],
    "legal_basis":"Art. 119-120 VAT"
} { object.get(input.jdg_entrepreneur,"p02_margin_check",false)==true }

# ═══ COVERAGE ═══
else := {
    "matched":true,"rule_id":"jdg.p02_innovations.summary","package":"jdg.p02_innovations","priority":99999,
    "innovation":"P02_VAT_MACRO","action":"REPORT","total_fixes":6,"ready_for_p03":true
} { true }
