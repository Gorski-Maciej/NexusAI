# NexusAI JDG Enterprise — Decision Scoring Engine.
# Classifies authority decisions and scores appeal, GAAR, limitation and deadline risk.

package jdg.enterprise.decision_scoring

import data.jdg.helpers

# DSE-3200: Decision classifier.
dse_classify_decision(decision) = classification if {
    decision_type := object.get(decision, "type", "UNKNOWN")
    article := object.get(decision, "article", "")
    category_map := {
        "70": "TERMIN",
        "119a": "ANTYABUZYWNA",
        "67": "ULGOWA",
        "26": "SANKCYJNA",
        "21": "KORZYSTNA",
        "20": "SANKCYJNA",
        "14b": "OPINIOWA"
    }
    classification := {
        "type": decision_type,
        "article": article,
        "category": object.get(category_map, article, "UNKNOWN")
    }
}

appeal_level_for(score) = "HIGH" if {
    score >= 60
} else = "MEDIUM" if {
    score >= 30
} else = "LOW" if {
    true
}

appeal_recommendation_for(score) = "ODWOŁANIE REKOMENDOWANE — wysokie szanse" if {
    score >= 60
} else = "ODWOŁANIE MOŻLIWE — umiarkowane szanse" if {
    score >= 30
} else = "ODWOŁANIE NIEZALECANE — niskie szanse, rozważ inne środki" if {
    true
}

# DSE-3210: Appeal chance scorer.
dse_appeal_chance(decision, judicial_trends) = chance if {
    article := object.get(decision, "article", "")
    decision_favorable := object.get(decision, "favorable_to_taxpayer", false)
    procedural_errors := object.get(decision, "procedural_errors", false)
    substantive_errors := object.get(decision, "substantive_errors", false)
    trend_context := object.get(judicial_trends, "reversal_context", false)
    base_chance := 50
    proc_bonus := bool_score(procedural_errors, 25)
    subst_bonus := bool_score(substantive_errors, 20)
    trend_bonus := trend_score(decision_favorable, trend_context)
    total := min([max([base_chance + proc_bonus + subst_bonus + trend_bonus, 0]), 100])
    chance := {
        "article": article,
        "total_score": total,
        "level": appeal_level_for(total),
        "factors": {
            "procedural_errors": procedural_errors,
            "substantive_errors": substantive_errors,
            "trend_bonus": trend_bonus
        },
        "recommendation": appeal_recommendation_for(total)
    }
}

bool_score(value, score) = score if {
    value == true
} else = 0 if {
    true
}

trend_score(decision_favorable, trend_context) = -15 if {
    decision_favorable == false
} else = 10 if {
    decision_favorable == true
    trend_context == true
} else = 10 if {
    true
}

# DSE-3220: GAAR decision scorer.
gaar_appeal_chance_for(triple_condition, threshold_exceeded) = 10 if {
    triple_condition == true
} else = 40 if {
    threshold_exceeded == true
} else = 70 if {
    true
}

defense_points_for(triple_condition) = [
    "1. Wykazać racjonalność biznesową operacji",
    "2. Udokumentować substancję ekonomiczną",
    "3. Powołać się na protective opinion (art. 14e OrdPU)",
    "4. Wskazać na brak sztuczności w rozumieniu art. 119c § 2"
] if {
    triple_condition == true
} else = [] if {
    true
}

triple_condition_for(threshold_exceeded, business_rationale, artificiality_detected) = true if {
    threshold_exceeded == true
    business_rationale == false
    artificiality_detected == true
} else = false if {
    true
}

dse_gaar_scorer(decision, profile) = gaar_score if {
    benefit_amount := object.get(decision, "benefit_amount_pln", 0)
    threshold_exceeded := benefit_amount > 100000
    business_rationale := object.get(profile, "business_rationale", false)
    artificiality_detected := object.get(decision, "artificiality_detected", false)
    triple_condition_met := triple_condition_for(threshold_exceeded, business_rationale, artificiality_detected)
    gaar_score := {
        "article": "119a",
        "benefit_amount": benefit_amount,
        "threshold_exceeded": threshold_exceeded,
        "artificiality_detected": artificiality_detected,
        "triple_condition_met": triple_condition_met,
        "appeal_chance": gaar_appeal_chance_for(triple_condition_met, threshold_exceeded),
        "defense_points": defense_points_for(triple_condition_met)
    }
}

# DSE-3230: Limitation scorer.
limitation_appeal_chance(expired, effective_expired, suspended, interrupted) = 95 if {
    effective_expired == true
} else = 50 if {
    expired == true
    suspended == true
} else = 50 if {
    expired == true
    interrupted == true
} else = 20 if {
    true
}

limitation_defense(effective_expired) = "WNIOSEK O STWIERDZENIE PRZEDAWNIENIA (art. 70 § 6 OrdPU)" if {
    effective_expired == true
} else = "Brak podstaw do przedawnienia — sprawdź zawieszenie/przerwanie" if {
    true
}

dse_limitation_scorer(decision) = lim_score if {
    tax_year := object.get(decision, "tax_year", 2019)
    current_year := 2026
    limitation_period := 5
    expiry_year := tax_year + limitation_period + 1
    expired := current_year > expiry_year
    suspended := object.get(decision, "suspended", false)
    interrupted := object.get(decision, "interrupted", false)
    effective_expired := expired
    not suspended
    not interrupted
    lim_score := {
        "article": "70",
        "tax_year": tax_year,
        "expiry_year": expiry_year,
        "expired": expired,
        "suspended": suspended,
        "interrupted": interrupted,
        "effective_expired": effective_expired,
        "appeal_chance": limitation_appeal_chance(expired, effective_expired, suspended, interrupted),
        "defense": limitation_defense(effective_expired)
    }
} else = lim_score if {
    tax_year := object.get(decision, "tax_year", 2019)
    current_year := 2026
    limitation_period := 5
    expiry_year := tax_year + limitation_period + 1
    expired := current_year > expiry_year
    suspended := object.get(decision, "suspended", false)
    interrupted := object.get(decision, "interrupted", false)
    effective_expired := false
    lim_score := {
        "article": "70",
        "tax_year": tax_year,
        "expiry_year": expiry_year,
        "expired": expired,
        "suspended": suspended,
        "interrupted": interrupted,
        "effective_expired": effective_expired,
        "appeal_chance": limitation_appeal_chance(expired, effective_expired, suspended, interrupted),
        "defense": limitation_defense(effective_expired)
    }
}

# DSE-3240: Deadline compliance scorer.
deadline_status_for(days_remaining) = "URGENT" if {
    days_remaining <= 3
} else = "WARNING" if {
    days_remaining <= 7
} else = "OK" if {
    true
}

dse_deadline_scorer(decision) = deadline if {
    appeal_days := object.get(decision, "days_to_appeal", 0)
    appeal_window := 14
    days_remaining := max([appeal_window - appeal_days, 0])
    missed := days_remaining <= 0
    remedy := remedy_for_deadline(missed)
    deadline := {
        "appeal_window_days": appeal_window,
        "days_elapsed": appeal_days,
        "days_remaining": days_remaining,
        "status": deadline_status_for(days_remaining),
        "missed_deadline": missed,
        "remedy": remedy
    }
}

remedy_for_deadline(missed) = "PRZYWRÓCENIE TERMINU (art. 162 OrdPU)" if {
    missed == true
} else = "" if {
    true
}

# DSE-3250: warning builder.
build_dse_warnings(classification, appeal_chance, gaar, limitation, deadline) = warnings if {
    decision_type := object.get(classification, "type", "UNKNOWN")
    chance_level := object.get(appeal_chance, "level", "MEDIUM")
    recommendation := object.get(appeal_chance, "recommendation", "")
    days_remaining := object.get(deadline, "days_remaining", 0)
    base := [sprintf("🔍 DECISION SCORING ENGINE — Decyzja: %s", [decision_type])]
    chance_warn := array.concat(base, [
        sprintf("   📊 Szansa odwołania: %s (%d/100)", [chance_level, object.get(appeal_chance, "total_score", 50)]),
        sprintf("   💡 %s", [recommendation])
    ])
    gaar_warn := gaar_warning_for(decision_type, chance_warn, gaar)
    lim_warn := limitation_warning_for(gaar_warn, limitation)
    warnings := deadline_warning_for(lim_warn, days_remaining, deadline)
}

gaar_warning_for(decision_type, chance_warn, gaar) = warnings if {
    decision_type == "GAAR"
    warnings := array.concat(chance_warn, [sprintf("   🎯 GAAR: Korzyść %d PLN (próg 100k), 3 warunki: %s", [object.get(gaar, "benefit_amount", 0), sprintf("%s", [object.get(gaar, "triple_condition_met", false)])])])
} else = chance_warn if {
    true
}

limitation_warning_for(current, limitation) = warnings if {
    object.get(limitation, "article", "") == "70"
    warnings := array.concat(current, [sprintf("   ⏳ PRZEDAWNIENIE: rok %d, upływ %d, skuteczne: %s", [object.get(limitation, "tax_year", 0), object.get(limitation, "expiry_year", 0), sprintf("%s", [object.get(limitation, "effective_expired", false)])])])
} else = current if {
    true
}

deadline_warning_for(current, days_remaining, deadline) = warnings if {
    days_remaining <= 7
    warnings := array.concat(current, [sprintf("   ⏰ TERMIN ODWOŁANIA: %d dni pozostało — %s!", [days_remaining, object.get(deadline, "status", "OK")])])
} else = current if {
    true
}
