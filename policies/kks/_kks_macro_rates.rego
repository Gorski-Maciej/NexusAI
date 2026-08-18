# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KKS Macro Rates & Gap-Filler (P09 Report Implementation)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.kks.rates
# Purpose:     Corrected thresholds, missing article rules, recidivism calc
# Fixes:       Art. 53, 55, 62§3, recidivism ×1.5, crime threshold 200× min_wage
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.kks.rates

import future.keywords.in
import future.keywords.if

recidivism_multiplier_value(is_recidivist) = 1.5 if { is_recidivist } else = 1.0
rehabilitation_period_value(offense_type) = 5 if { offense_type in {"TAX_EVASION", "EMPTY_INVOICE", "FAKE_INVOICE", "UNRELIABLE_BOOKS", "VAT_CAROUSEL"} } else = 3 if { offense_type in {"DECLARATION_NOT_FILED", "INCORRECT_DATA", "TAX_UNPAID"} } else = 5

# ═══════════════════════════════════════════════════════════════════════════════
# CORRECTED THRESHOLDS (2026)
# ═══════════════════════════════════════════════════════════════════════════════

min_wage_2026 := 4800.00
avg_salary_2026 := 8190.00

# CORRECTED: 200× minimalnego wynagrodzenia ≈ 933 200 PLN (NOT 200 000!)
kks_crime_threshold_correct := min_wage_2026 * 200   # 933 200 PLN

# Daily rate: 1/30 of minimum wage (NOT monthly income!)
kks_daily_rate_min := round(min_wage_2026 / 30 * 100) / 100   # 155.53 PLN
kks_daily_rate_max := min_wage_2026 * 400                      # 1 866 400 PLN

# Mandatory prison threshold (Art. 62 §3)
kks_mandatory_prison_threshold := 5000000

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 53 KKS — PRZEKROCZENIE GRANIC UPRAWNIEŃ (GAP FIX)
# ═══════════════════════════════════════════════════════════════════════════════

default kks_art53_applies := false

kks_art53_applies := true {
    input.jdg_entrepreneur.authority_limit_exceeded == true
}

kks_art53_assessment := result {
    kks_art53_applies
    result := {
        "article": "Art. 53 KKS",
        "offense": "Przekroczenie granic uprawnień lub niedopełnienie obowiązku",
        "severity": "HIGH",
        "routing": "TRIAGE_QUEUE",
        "max_rates": 240,
        "defense": "Udokumentuj zakres uprawnień — statut, umowa spółki, pełnomocnictwo",
        "legal_basis": "Art. 53 KKS — Odpowiedzialność za przekroczenie granic uprawnień",
        "warning": "PRZEKROCZENIE UPRAWNIEŃ — sprawdź czy działałeś w granicach umocowania!"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 55 KKS — FORMA PRZESTĘPSTWA SKARBOWEGO (GAP FIX)
# ═══════════════════════════════════════════════════════════════════════════════

kks_intent_forms := {
    "UMYSLNOSC_BEZPOSREDNIA": {
        "name": "Umyślność bezpośrednia (dolus directus)",
        "description": "Sprawca chce popełnić czyn zabroniony",
        "penalty_multiplier": 1.0
    },
    "UMYSLNOSC_EWENTUALNA": {
        "name": "Umyślność ewentualna (dolus eventualis)",
        "description": "Sprawca przewiduje możliwość popełnienia czynu i godzi się na to",
        "penalty_multiplier": 0.85
    },
    "NIEUMYSLNOSC": {
        "name": "Nieumyślność (culpa)",
        "description": "Sprawca nie zachował ostrożności wymaganej w danych okolicznościach",
        "penalty_multiplier": 0.5
    },
}

default kks_intent_form := "UMYSLNOSC_BEZPOSREDNIA"

kks_intent_form := intent {
    intent := object.get(input.jdg_entrepreneur, "kks_intent_form", "UMYSLNOSC_BEZPOSREDNIA")
    intent in kks_intent_forms
}

kks_art55_assessment := result {
    kks_intent_form != ""
    intent_str := kks_intent_form
    form := kks_intent_forms[intent_str]
    result := {
        "article": "Art. 55 KKS",
        "offense": "Forma przestępstwa skarbowego",
        "intent_form": kks_intent_form,
        "intent_name": form.name,
        "intent_description": form.description,
        "penalty_multiplier": form.penalty_multiplier,
        "routing": "TRIAGE_QUEUE",
        "legal_basis": "Art. 55 KKS — Forma przestępstwa (umyślność/nieumyślność)",
        "warning": sprintf("FORMA: %s — wpływa na wymiar kary (×%.0f%%)", [form.name, form.penalty_multiplier * 100])
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 62 §3 KKS — OBLIGATORYJNE POZBAWIENIE WOLNOŚCI >5M PLN (GAP FIX)
# ═══════════════════════════════════════════════════════════════════════════════

default kks_mandatory_prison_applies := false

kks_mandatory_prison_applies := true {
    benefit := object.get(input.jdg_entrepreneur, "estimated_tax_benefit_unpaid", 0)
    benefit > kks_mandatory_prison_threshold
}

kks_art62_par3_assessment := result {
    kks_mandatory_prison_applies
    benefit := object.get(input.jdg_entrepreneur, "estimated_tax_benefit_unpaid", 0)
    result := {
        "article": "Art. 62 §3 KKS",
        "offense": "Korzyść majątkowa >5M PLN — obligatoryjne pozbawienie wolności",
        "benefit_pln": benefit,
        "threshold_pln": kks_mandatory_prison_threshold,
        "severity": "CRITICAL",
        "routing": "BLOCK_AND_ALERT",
        "max_rates": 1080,
        "max_pw_years": 15,
        "mandatory_prison": true,
        "legal_basis": "Art. 62 §3 KKS — Obligatoryjne pozbawienie wolności",
        "warning": sprintf("OBLIGATORYJNE PW! Korzyść %.2f PLN > 5M PLN. Natychmiast adwokat!", [benefit]),
        "defense_note": "TYLKO CZYNNY ŻAL MOŻE URATOWAĆ — złóż zanim KAS wykryje!"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 19 §3 KKS — RECIDIVISM CALCULATOR ×1.5
# ═══════════════════════════════════════════════════════════════════════════════

default kks_is_recidivist := false

kks_is_recidivist := true {
    incidents := object.get(input.jdg_entrepreneur, "kks_incidents_60m", 0)
    incidents >= 3
}

kks_recidivism_multiplier := recidivism_multiplier_value(kks_is_recidivist)

kks_rehabilitation_period_years := rehabilitation_period_value(object.get(input.invoice, "kks_offense_type", ""))

kks_recidivism_assessment := result {
    kks_is_recidivist
    incidents := object.get(input.jdg_entrepreneur, "kks_incidents_60m", 0)
    result := {
        "article": "Art. 19 §3 KKS",
        "offense": "Recydywa skarbowa — nadzwyczajne obostrzenie kary",
        "incidents_60m": incidents,
        "penalty_multiplier": kks_recidivism_multiplier,
        "rehabilitation_years": kks_rehabilitation_period_years,
        "severity": "HIGH",
        "routing": "BLOCK_AND_ALERT",
        "legal_basis": "Art. 19 §3 KKS — Recydywa skarbowa",
        "warning": sprintf("RECYDYWA SKARBOWA! %d incydentów w 5 lat. Kara ×%.1f!", [incidents, kks_recidivism_multiplier]),
        "defense_note": sprintf("Rehabilitacja po %d latach od wykonania kary", [kks_rehabilitation_period_years])
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CORRECTED CRIME vs MISDEMEANOR CLASSIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

kks_classify_offense(amount, severity) = "PRZESTĘPSTWO" if {
    amount > kks_crime_threshold_correct
} else = "PRZESTĘPSTWO" if {
    severity in {"HIGH", "CRITICAL"}
} else = "WYKROCZENIE" if {
    amount <= kks_crime_threshold_correct
    severity in {"LOW", "MEDIUM"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# FINE CALCULATOR (CORRECTED)
# ═══════════════════════════════════════════════════════════════════════════════

kks_calculate_fine(daily_rate, rates_count) := result {
    rate := max([kks_daily_rate_min, min([kks_daily_rate_max, daily_rate])])
    fine := round(rate * rates_count * 100) / 100
    result := {
        "daily_rate_pln": rate,
        "rates_count": rates_count,
        "fine_pln": fine,
        "recidivism_multiplier": kks_recidivism_multiplier,
        "final_fine_pln": round(fine * kks_recidivism_multiplier * 100) / 100,
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PW RISK CALCULATOR
# ═══════════════════════════════════════════════════════════════════════════════

kks_pw_risk(amount_pln, offense_type) = {"level": "OBLIGATORYJNE", "years": 15} if {
    amount_pln > kks_mandatory_prison_threshold
} else = {"level": "BARDZO WYSOKIE", "years": 10} if {
    amount_pln > 1000000
    amount_pln <= kks_mandatory_prison_threshold
} else = {"level": "WYSOKIE", "years": 5} if {
    amount_pln > 500000
    amount_pln <= 1000000
} else = {"level": "ŚREDNIE", "years": 3} if {
    amount_pln > 200000
    amount_pln <= 500000
} else = {"level": "NISKIE", "years": 0} if {
    amount_pln <= 200000
}

# ═══════════════════════════════════════════════════════════════════════════════
# COMPREHENSIVE KKS ASSESSMENT
# ═══════════════════════════════════════════════════════════════════════════════

default kks_comprehensive_assessment := {}

kks_comprehensive_assessment := {
    "thresholds_corrected": {
        "crime_threshold_200x_min_wage": kks_crime_threshold_correct,
        "daily_rate_min": kks_daily_rate_min,
        "daily_rate_max": kks_daily_rate_max,
        "mandatory_prison_threshold": kks_mandatory_prison_threshold,
    },
    "intent_forms_available": count(kks_intent_forms),
    "recidivism_active": kks_is_recidivist,
    "recidivism_multiplier": kks_recidivism_multiplier,
    "mandatory_prison_active": kks_mandatory_prison_applies,
    "version": "P09_COMPLETE_IMPLEMENTATION",
    "fixes_applied": [
        "CORRECTED: crime threshold 200x min_wage (933 200 PLN, not 200 000)",
        "ADDED: Art. 53 KKS — authority limits",
        "ADDED: Art. 55 KKS — intent form classification",
        "ADDED: Art. 62 §3 KKS — mandatory prison >5M PLN",
        "ADDED: Art. 19 §3 KKS — recidivism ×1.5 calculator",
        "CORRECTED: daily rate based on min_wage/30, not monthly income",
        "ADDED: PW risk calculator with graduated levels",
        "ADDED: Fine calculator with recidivism multiplier",
    ],
}
