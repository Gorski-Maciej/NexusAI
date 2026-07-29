# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — PIT: 4 formy opodatkowania (P500-P539)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: PIT Forms — 4 Tax Regimes: Scale, Linear, Lump Sum, Tax Card
# description: |
#   PAS 5a Multi-Pass. First-Match-Wins else-chain. 4 formy opodatkowania JDG:
#   skala 12/32% (P500), wspólne rozliczenie (P502), liniowy 19% (P510),
#   blokada byłego pracodawcy → skala (P512), ryczałt (P520),
#   limit 2M EUR → skala (P523), karta podatkowa (P530).
# architecture: Multi-Pass PAS 5a (ADR-001), używa data.thresholds
# legal_basis: Art. 27, 30c PIT, ustawa o ryczałcie
# edge_cases:
#   - P512: former_employer_services → automatycznie SCALE zamiast LINEAR
#   - P523: helpers.jdg_amount_eur > 2M → BLOCK_AND_ALERT
#   - P530: karta podatkowa nie ma zeznania rocznego
# package: jdg.pit.forms
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
#
# First-Match-Wins else-chain
# Podstawa: Doc 34 Sec 4.6 + Doc 33 (Art. 27, 30c PIT + ryczałt + karta)
#
# package: jdg.pit.forms
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.forms

import data.jdg.helpers
import data.jdg.thresholds

# ── Default ────────────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.pit.forms.no_match",
    "package": "jdg.pit.forms",
    "priority": 549
}

# ═══════════════════════════════════════════════════════════════════════════════
# P500: pit_form_scale — Skala podatkowa 12%/32% (domyślna)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.pit.forms.scale",
    "package": "jdg.pit.forms", "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": pit_rate, "pit_bracket": pit_bracket,
    "pit_annual_return_type": "PIT-36",
    "pit_tax_free_amount": thresholds.limits.pit_tax_free_amount, "pit_tax_free_reduction": floor(thresholds.limits.pit_tax_free_amount * thresholds.rates.pit_scale_low),
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "business_status": "", "ceidg_registration_required": false,
    "relief_joint_filing": false, "relief_type": "",
    "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 27 ust. 1 PIT",
    "valid_from": "2022-07-01",
    "valid_to": null,
    "_warnings": []
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    accumulated := object.get(input.jdg_entrepreneur, "cumulative_income_current_year", 0)
    bracket_limit := object.get(object.get(data.thresholds, "jdg", {}), "bounds", {})
    threshold := object.get(bracket_limit, "pit_scale_threshold", 120000)

    pit_bracket = "LOW" { accumulated <= threshold }
    pit_bracket = "LOW" { accumulated <= threshold }
    pit_rate = sprintf("%.2f", [thresholds.rates.pit_scale_low]) { accumulated <= threshold }
    pit_bracket = "HIGH" { accumulated > threshold }
    pit_rate = sprintf("%.2f", [thresholds.rates.pit_scale_high]) { accumulated > threshold }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P502: pit_scale_joint_filing — Wspólne rozliczenie małżonków
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.scale_joint_filing",
    "package": "jdg.pit.forms", "priority": 502,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "pit_tax_free_amount": thresholds.limits.pit_tax_free_amount, "pit_tax_free_reduction": floor(thresholds.limits.pit_tax_free_amount * thresholds.rates.pit_scale_low),
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "business_status": "", "ceidg_registration_required": false,
    "relief_joint_filing": true,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 6 ust. 2 PIT",
    "_warnings": ["Wspólne rozliczenie małżonków — efektywny próg 240 000 PLN"]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    input.jdg_entrepreneur.joint_filing == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P508: pit_revenue_exclusions — Wyłączenia z przychodów PIT
# ═══════════════════════════════════════════════════════════════════════════════
# Doc 38a: Art. 14 ust. 3 PIT — zwrot VAT, nadpłata ZUS, odszkodowania
# NIE stanowią przychodu podatkowego. Krytyczne dla poprawnego obliczenia dochodu.
else := {
    "matched": true, "rule_id": "jdg.pit.pit_revenue_exclusions",
    "package": "jdg.pit.forms", "priority": 508,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pit_revenue_excluded": true, "revenue_exclusion_type": exclusion_type,
    "pkpir_excluded": true,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 14 ust. 3 pkt 1-4 PIT",
    "_warnings": [sprintf("Ten wpływ (%s) NIE stanowi przychodu podatkowego — wyłączony na podstawie Art. 14 ust. 3 PIT", [exclusion_type])]
} {
    # Tylko wpływy (SALE lub ogólny INFLOW) — nie wykluczamy kategorii zakupowych
    is_inflow := object.get(input.invoice, "direction", "") == "SALE"
    is_inflow == true
    inflow_code := object.get(input.invoice, "category_code", "")
    # Kategorie wyłączone z przychodu (Art. 14 ust. 3 PIT)
    excluded_categories := {"VAT_REFUND", "ZUS_OVERPAYMENT_REFUND", "INSURANCE_COMPENSATION_PERSONAL", "DAMAGES_AWARD_PERSONAL"}
    inflow_code in excluded_categories
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    exclusion_type = "Zwrot VAT" { inflow_code == "VAT_REFUND" }
    exclusion_type = "Zwrot nadpłaconych składek ZUS" { inflow_code == "ZUS_OVERPAYMENT_REFUND" }
    exclusion_type = "Odszkodowanie osobowe (szkoda na osobie)" { inflow_code == "INSURANCE_COMPENSATION_PERSONAL" }
    exclusion_type = "Zadośćuczynienie/odszkodowanie" { inflow_code == "DAMAGES_AWARD_PERSONAL" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P510: pit_form_linear — Podatek liniowy 19%
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.linear",
    "package": "jdg.pit.forms", "priority": 510,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_linear]), "pit_bracket": "",
    "pit_annual_return_type": "PIT-36L",
    "pit_tax_free_amount": 0, "pit_tax_free_reduction": 0,
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "",    "zus_health_rate": "0.049",
    "zus_health_deductible_from_income": true, "zus_health_annual_limit": thresholds.zus.health_linear_deduction_limit,
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 30c PIT",
    "valid_from": "2022-07-01",
    "valid_to": null,
    "_warnings": ["Podatek liniowy 19% — BRAK kwoty wolnej, BRAK wspólnego rozliczenia"]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P512: linear_former_employer_restriction — Blokada liniowego dla byłego pracodawcy
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.linear_former_employer_block",
    "package": "jdg.pit.forms", "priority": 512,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Usługi dla byłego pracodawcy — podatek liniowy NIEDOZWOLONY",
    "_legal_basis": "Art. 30c ust. 2 PIT",
    "_warnings": ["Usługi dla byłego pracodawcy — NIE możesz używać podatku liniowego! Automatycznie: skala 12%."]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    input.jdg_entrepreneur.former_employer_services == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P520: pit_form_lump_sum — Ryczałt ewidencjonowany
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.lump_sum",
    "package": "jdg.pit.forms", "priority": 520,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LUMP_SUM", "pit_rate": lump_sum_rate, "pit_bracket": "",
    "pit_annual_return_type": "PIT-28", "pit_annual_return_deadline": "02-28",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "zus_health_limit_type": "LUMP_SUM_TIER",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 12 ustawy o ryczałcie ewidencjonowanym",
    "_warnings": ["Ryczałt ewidencjonowany — podatek od przychodu (NIE dochodu!). PIT-28 do 28 lutego!"]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    pkwiu := object.get(input.invoice, "pkwiu_code", "")
    lump_sum_rate := lump_sum_rate_by_pkwiu(pkwiu)
}

# ── Lump sum rate determination by PKWiU (from thresholds — ADR-002) ──────────
lump_sum_rate_by_pkwiu(pkwiu) = rate {
    code := pkwiu_2digit(pkwiu)
    rate = thresholds.rates.lump_2pct    { code in {"01", "02", "03"} }
    else = thresholds.rates.lump_3pct    { code in {"10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","56"} }
    else = thresholds.rates.lump_5_5pct  { code in {"41", "42", "43", "64", "65", "66"} }
    else = thresholds.rates.lump_12pct   { code in {"62", "63"} }
    else = thresholds.rates.lump_8_5pct  { code in {"58", "59", "60", "61", "72"} }
    else = thresholds.rates.lump_15pct   { code == "68" }
    else = thresholds.rates.lump_17pct   { code in {"69","70","71","73","74","75","77","78","79","80","81","82"} }
    else = thresholds.rates.lump_8_5pct  # default fallback
}

pkwiu_2digit(pkwiu) = code {
    parts := split(pkwiu, ".")
    code := parts[0]
}

# ═══════════════════════════════════════════════════════════════════════════════
# P523: lump_sum_annual_limit — Limit 2M EUR dla ryczałtu
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.lump_sum_limit_exceeded",
    "package": "jdg.pit.forms", "priority": 523,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczony limit ryczałtu — obowiązek przejścia na skalę",
    "_legal_basis": "Art. 6 ust. 4 ustawy o ryczałcie",
    "_warnings": ["Przekroczony limit 2M EUR dla ryczałtu — OBOWIĄZKOWA zmiana na skalę podatkową!"]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    helpers.jdg_amount_eur > 2000000
}

# ═══════════════════════════════════════════════════════════════════════════════
# P524: lump_sum_statutory_exclusions — Wyłączenia z ryczałtu (apteki, kantory, części)
# Doc 26 §III: Bezwzględna blokada ryczałtu dla branż ustawowo wyłączonych
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.lump_sum_exclusions",
    "package": "jdg.pit.forms", "priority": 524,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "lump_sum_not_allowed": true,
    "lump_sum_exclusion_reason": exclusion_reason,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Branża wyłączona z ryczałtu — wymagana skala lub liniowy",
    "_legal_basis": "Art. 8 ust. 1-2 ustawy o ryczałcie (Dz.U. 2025 poz. 234)",
    "_warnings": [sprintf("Branża wyłączona z ryczałtu (%s) — NIE możesz używać ryczałtu! Automatycznie: skala podatkowa.", [exclusion_reason])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    pkd := object.get(input.jdg_entrepreneur, "pkd_main", "")

    # Katalog PKD wyłączonych z ryczałtu (Art. 8 ust. 1-2)
    excluded_pkd := {"47.73.Z", "64.99.Z", "45.31.Z", "45.32.Z", "46.12.Z", "66.19.Z", "69.10.Z"}
    pkd in excluded_pkd

    exclusion_reason = "Apteka" { pkd == "47.73.Z" }
    exclusion_reason = "Kantor/dział. finansowa" { pkd == "64.99.Z" }
    exclusion_reason = "Handel częściami samochodowymi" { pkd in {"45.31.Z", "45.32.Z"} }
    exclusion_reason = "Pośrednictwo w handlu paliwami" { pkd == "46.12.Z" }
    exclusion_reason = "Doradztwo finansowe" { pkd == "66.19.Z" }
    exclusion_reason = "Usługi prawne" { pkd == "69.10.Z" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P525: lump_sum_loss_of_right — Utrata ryczałtu w trakcie roku
# Doc 26 §III: Automatyczna utrata: >2M EUR, zmiana PKD, były pracodawca
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.lump_sum_loss_of_right",
    "package": "jdg.pit.forms", "priority": 525,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "lump_sum_right_lost": true,
    "requires_multiple_annual_returns": true,
    "loss_reason": loss_reason,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Utrata prawa do ryczałtu — przejście na skalę",
    "_legal_basis": "Art. 20 ustawy o ryczałcie",
    "_warnings": [sprintf("UTRATA RYCZAŁTU — %s. Od dnia utraty obowiązuje skala podatkowa. Złożysz PIT-28 za okres ryczałtu + PIT-36 za okres skali.", [loss_reason])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"

    # Utrata z powodu byłego pracodawcy (Art. 8 ust. 2)
    has_ex_employer := object.get(input.jdg_entrepreneur, "former_employer_services", false)

    # Utrata z powodu zmiany PKD na wyłączone
    pkd := object.get(input.jdg_entrepreneur, "pkd_main", "")
    excluded_pkd := {"47.73.Z", "64.99.Z", "45.31.Z", "45.32.Z", "46.12.Z"}
    pkd_changed_to_excluded := pkd in excluded_pkd

    loss_cause = "Były pracodawca" { has_ex_employer == true }
    loss_cause = "Zmiana PKD na wyłączone" { pkd_changed_to_excluded == true }
    loss_reason = loss_cause

    has_ex_employer == true
}

# ══════ P526: lump_sum_election_deadline — Termin oświadczenia o ryczałcie ══════
# Doc 26 §III: Oświadczenie do 20. dnia miesiąca po pierwszym przychodzie (nowa JDG)
# lub do 20 stycznia (kontynuacja). Brak oświadczenia → skala podatkowa.
else := {
    "matched": true, "rule_id": "jdg.pit.forms.lump_sum_election_deadline",
    "package": "jdg.pit.forms", "priority": 526,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_scale_low]), "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "lump_sum_election_invalid": true,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Oświadczenie o ryczałcie niezłożone w terminie — obowiązek przejścia na skalę",
    "_legal_basis": "Art. 9 ust. 1-4 ustawy o ryczałcie (Dz.U. 2025 poz. 234)",
    "_warnings": ["Oświadczenie o wyborze ryczałtu NIE zostało złożone w terminie! Składa się je do 20. dnia miesiąca po pierwszym przychodzie (nowa JDG) lub do 20 stycznia (kontynuacja). Automatycznie: skala podatkowa."]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    input.jdg_entrepreneur.lump_sum_election_filed == false
    first_revenue_earned := object.get(input.jdg_entrepreneur, "first_revenue_earned", true)
    first_revenue_earned == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P530: pit_form_tax_card — Karta podatkowa
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.pit.forms.tax_card",
    "package": "jdg.pit.forms", "priority": 530,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "TAX_CARD", "pit_rate": "", "pit_bracket": "",
    "pit_monthly_amount": monthly_rate,
    "pit_annual_return_type": "", "pit_advance_due_day": 7,
    "kus_qualification": "none", "kus_percent": 0,
    "requires_pkpir": false, "requires_lump_sum_evidence": false,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "", "relief_limit": 0, "relief_deductible": 0, "relief_carry_forward_years": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 21-30 ustawy o ryczałcie (rozdział 3)",
    "_warnings": ["Karta podatkowa — stała kwota podatku z decyzji US. Brak zeznania rocznego!"]
} {
    input.jdg_entrepreneur.tax_form == "TAX_CARD"
    monthly_rate := object.get(input.jdg_entrepreneur, "tax_card_monthly_rate", 0)
}

# ══════ P490-P496: FORMY OPODATKOWANIA SZCZEGÓŁY — Doc 36 §18 (7 reguł) ══════

# P490: tax_form_linear_deadline_jan20 — Wybór liniowego do 20 stycznia
else := {"matched":true,"rule_id":"jdg.pit.forms.linear_deadline_jan20","package":"jdg.pit.forms","priority":490,"vat_rate":"","rounding_level":"","gtu_code":"",    "pit_form": "LINEAR", "pit_rate": sprintf("%.2f", [thresholds.rates.pit_linear]), "pit_bracket": "",
    "pit_annual_return_type": "PIT-36L","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","linear_deadline":"JANUARY_20","_routing":"BLOCK_AND_ALERT","_routing_reason":"Wybór liniowego — oświadczenie do 20 stycznia!","_legal_basis":"Art. 9a ust. 2 PIT","_warnings":["Wybór podatku liniowego — złóż oświadczenie CEIDG do 20 stycznia. Po terminie: automatycznie skala PIT!"]} {object.get(input.jdg_entrepreneur,"wants_linear_tax",false)==true;object.get(input.jdg_entrepreneur,"tax_form_chosen",true)==false}

# P491: tax_form_lump_sum_deadline_jan20 — Ryczałt do 20 stycznia
else := {"matched":true,"rule_id":"jdg.pit.forms.lump_sum_deadline_jan20","package":"jdg.pit.forms","priority":491,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"LUMP_SUM","pit_rate":"","pit_bracket":"","pit_annual_return_type":"PIT-28","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","lump_sum_deadline":"JANUARY_20","_routing":"BLOCK_AND_ALERT","_routing_reason":"Wybór ryczałtu — oświadczenie do 20 stycznia!","_legal_basis":"Art. 9 ust. 1 ustawy o ryczałcie","_warnings":["Wybór ryczałtu — złóż oświadczenie CEIDG do 20 stycznia lub do 20. dnia po pierwszym przychodzie (nowa JDG)."]} {object.get(input.jdg_entrepreneur,"wants_lump_sum",false)==true;object.get(input.jdg_entrepreneur,"tax_form_chosen",true)==false}

# P492: tax_form_lump_sum_excluded — Wykluczone usługi z ryczałtu
else := {"matched":true,"rule_id":"jdg.pit.forms.lump_sum_excluded_services","package":"jdg.pit.forms","priority":492,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","lump_sum_excluded":true,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Usługi wykluczone z ryczałtu","_legal_basis":"Art. 8 ustawy o ryczałcie","_warnings":["USŁUGI WYKLUCZONE Z RYCZAŁTU — apteki, kantory, lombardy, handel częściami samochodowymi. Musisz wybrać skalę lub liniowy!"]} {input.jdg_entrepreneur.tax_form=="LUMP_SUM";object.get(input.jdg_entrepreneur,"pkd_in_excluded_list",false)==true}

# P493: tax_form_linear_no_joint_filing — Liniowy = brak wspólnego rozliczenia
else := {"matched":true,"rule_id":"jdg.pit.forms.linear_no_joint_filing","package":"jdg.pit.forms","priority":493,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"LINEAR","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","joint_filing":"BLOCKED","_routing":"BLOCK_AND_ALERT","_routing_reason":"Liniowy — brak wspólnego rozliczenia","_legal_basis":"Art. 30c PIT","_warnings":["Podatek liniowy — NIE MOŻESZ rozliczyć się wspólnie z małżonkiem! Tylko skala PIT umożliwia joint filing."]} {input.jdg_entrepreneur.tax_form=="LINEAR";object.get(input.jdg_entrepreneur,"wants_joint_filing",false)==true}

# P494: tax_form_linear_no_child_tax_credit — Liniowy = brak ulgi na dzieci
else := {"matched":true,"rule_id":"jdg.pit.forms.linear_no_child_tax_credit","package":"jdg.pit.forms","priority":494,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"LINEAR","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","child_tax_credit":"BLOCKED","_routing":"BLOCK_AND_ALERT","_routing_reason":"Liniowy — brak ulgi na dzieci","_legal_basis":"Art. 27f PIT","_warnings":["Podatek liniowy — NIE przysługuje ulga na dzieci! Tylko skala PIT. Rozważ zmianę formy jeśli masz dzieci."]} {input.jdg_entrepreneur.tax_form=="LINEAR";object.get(input.jdg_entrepreneur,"child_tax_credit_claimed",0)>0}

# P495: tax_form_lump_sum_no_tax_free — Ryczałt = brak kwoty wolnej
else := {"matched":true,"rule_id":"jdg.pit.forms.lump_sum_no_tax_free","package":"jdg.pit.forms","priority":495,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"LUMP_SUM","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","tax_free_amount":0,"_routing":"","_routing_reason":"","_legal_basis":"Art. 12 ustawy o ryczałcie","_warnings":["Ryczałt — BRAK kwoty wolnej od podatku! Podatek od każdej złotówki przychodu."]} {input.jdg_entrepreneur.tax_form=="LUMP_SUM"}

# P496: tax_form_tax_card_eligibility — Karta podatkowa — warunki
else := {"matched":true,"rule_id":"jdg.pit.forms.tax_card_eligibility","package":"jdg.pit.forms","priority":496,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"TAX_CARD","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","tax_card_conditions":"MAX_5_EMPLOYEES_NO_SPECIALIZED_SERVICES","_routing":"","_routing_reason":"","_legal_basis":"Rozdział 3 ustawy o zryczałtowanym PIT","_warnings":["Karta podatkowa — max 5 pracowników, brak usług specjalistycznych dla byłego pracodawcy. Sztywna kwota podatku."]} {input.jdg_entrepreneur.tax_form=="TAX_CARD"}

# ══ P497: tax_card_loss_of_right — Utrata prawa do karty podatkowej ══
else := {"matched":true,"rule_id":"jdg.pit.forms.tax_card_loss","package":"jdg.pit.forms","priority":497,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"SCALE","pit_rate":sprintf("%.2f", [thresholds.rates.pit_scale_low]),"pit_bracket":"LOW","pit_annual_return_type":"PIT-36","kus_qualification":"full","kus_percent":100,"zus_social_base_type":"","zus_health_rate":"","business_status":"","tax_card_retained":false,"tax_card_loss_reason":loss_reason,"_routing":"BLOCK_AND_ALERT","_routing_reason":sprintf("UTRATA KARTY PODATKOWEJ — %s. Automatycznie: skala PIT.",[loss_reason]),"_legal_basis":"Art. 25-30 ustawy o zryczałtowanym PIT","_warnings":[sprintf("UTRATA KARTY PODATKOWEJ! %s Od dnia utraty obowiązuje skala podatkowa (12%%/32%%). Złóż PIT-36 za ten rok.",[loss_reason])]} {input.jdg_entrepreneur.tax_form=="TAX_CARD";employees:=object.get(input.jdg_entrepreneur,"employee_count",0);uses_specialized:=object.get(input.jdg_entrepreneur,"provides_specialized_services",false);services_former_employer:=object.get(input.jdg_entrepreneur,"former_employer_services",false);(employees>5)|(services_former_employer==true)|(uses_specialized==true);loss_reason=sprintf("Przekroczono limit 5 pracowników (obecnie %d)",[employees]){employees>5};loss_reason=sprintf("Usługi dla byłego pracodawcy — karta WYKLUCZONA",[]){employees<=5;services_former_employer==true};loss_reason=sprintf("Usługi specjalistyczne — karta WYKLUCZONA",[]){employees<=5;not services_former_employer;uses_specialized==true}}
