# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 9.14: Decision Scoring Engine
# v7.0 — Bonus: Scoring decyzji organu z oceną szans odwołania
# Package: jdg.enterprise.decision_scoring
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.decision_scoring

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# DSE-3200: Decision classifier — klasyfikuje typ decyzji organu
# ─────────────────────────────────────────────────────────────────────────────
dse_classify_decision(decision) = classification {
    decision_type := object.get(decision, "type", "UNKNOWN")
    article := object.get(decision, "article", "")

    category_map := {
        "70": "TERMIN",
        "119a": "ANTYABUZYWNA",
        "67": "ULGOWA",
        "26": "SANKCYJNA",
        "21": "KORZYSTNA",
        "20": "SANKCYJNA",
        "14b": "OPINIOWA",
    }
    category := object.get(category_map, article, "UNKNOWN")

    classification := {
        "type": decision_type,
        "article": article,
        "category": category,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# DSE-3210: Appeal chance scorer — ocena szans powodzenia odwołania
# ─────────────────────────────────────────────────────────────────────────────
dse_appeal_chance(decision, judicial_trends) = chance {
    article := object.get(decision, "article", "")
    decision_favorable := object.get(decision, "favorable_to_taxpayer", false)
    procedural_errors := object.get(decision, "procedural_errors", false)
    substantive_errors := object.get(decision, "substantive_errors", false)

    # Baza 50%
    base_chance := 50

    # +25% jeśli błędy proceduralne (art. 210 § 4 OrdPU)
    proc_bonus := 25 { procedural_errors } else := 0

    # +20% jeśli błędy materialne
    subst_bonus := 20 { substantive_errors } else := 0

    # +10% jeśli niekorzystny trend orzeczniczy jest odwracalny
    trend_penalty := -15 { not decision_favorable } else := 10

    total := min([max([base_chance + proc_bonus + subst_bonus + trend_penalty, 0]), 100])

    appeal_level := "HIGH" { total >= 60 }
    appeal_level := "MEDIUM" { total >= 30; total < 60 }
    appeal_level := "LOW" { total < 30 }

    recommendation := "ODWOŁANIE REKOMENDOWANE — wysokie szanse" { total >= 60 }
    recommendation := "ODWOŁANIE MOŻLIWE — umiarkowane szanse" { total >= 30; total < 60 }
    recommendation := "ODWOŁANIE NIEZALECANE — niskie szanse, rozważ inne środki" { total < 30 }

    chance := {
        "article": article,
        "total_score": total,
        "level": appeal_level,
        "factors": {
            "procedural_errors": procedural_errors,
            "substantive_errors": substantive_errors,
            "trend_bonus": trend_penalty,
        },
        "recommendation": recommendation,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# DSE-3220: GAAR decision scorer — scoring decyzji GAAR (art. 119a)
# ─────────────────────────────────────────────────────────────────────────────
dse_gaar_scorer(decision, profile) = gaar_score {
    benefit_amount := object.get(decision, "benefit_amount_pln", 0)
    gaar_threshold := 100000  # Próg 100k PLN (art. 119b)
    business_rationale := object.get(profile, "business_rationale", false)
    artificiality_detected := object.get(decision, "artificiality_detected", false)

    threshold_exceeded := benefit_amount > gaar_threshold
    triple_condition_met := threshold_exceeded and not business_rationale and artificiality_detected

    gaar_appeal_chance := 10 { triple_condition_met }
    gaar_appeal_chance := 40 { threshold_exceeded; not triple_condition_met }
    gaar_appeal_chance := 70 { not threshold_exceeded }

    defense_points := [
        "1. Wykazać racjonalność biznesową operacji",
        "2. Udokumentować substancję ekonomiczną",
        "3. Powołać się na protective opinion (art. 14e OrdPU)",
        "4. Wskazać na brak sztuczności w rozumieniu art. 119c § 2",
    ] { triple_condition_met }
    defense_points := [] { not triple_condition_met }

    gaar_score := {
        "article": "119a",
        "benefit_amount": benefit_amount,
        "threshold_exceeded": threshold_exceeded,
        "artificiality_detected": artificiality_detected,
        "triple_condition_met": triple_condition_met,
        "appeal_chance": gaar_appeal_chance,
        "defense_points": defense_points,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# DSE-3230: Limitation (statute) scorer — scoring decyzji przedawnieniowej
# ─────────────────────────────────────────────────────────────────────────────
dse_limitation_scorer(decision) = lim_score {
    tax_year := object.get(decision, "tax_year", 2019)
    current_year := 2026
    limitation_period := 5
    expiry_year := tax_year + limitation_period + 1  # +1 bo od końca roku

    expired := current_year > expiry_year
    suspended := object.get(decision, "suspended", false)
    interrupted := object.get(decision, "interrupted", false)

    effective_expired := expired and not suspended and not interrupted

    lim_appeal_chance := 95 { effective_expired }
    lim_appeal_chance := 50 { expired; (suspended or interrupted) }
    lim_appeal_chance := 20 { not expired }

    lim_defense := "WNIOSEK O STWIERDZENIE PRZEDAWNIENIA (art. 70 § 6 OrdPU)" { effective_expired }
    lim_defense := "Brak podstaw do przedawnienia — sprawdź zawieszenie/przerwanie" { true }

    lim_score := {
        "article": "70",
        "tax_year": tax_year,
        "expiry_year": expiry_year,
        "expired": expired,
        "suspended": suspended,
        "interrupted": interrupted,
        "effective_expired": effective_expired,
        "appeal_chance": lim_appeal_chance,
        "defense": lim_defense,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# DSE-3240: Deadline compliance scorer — scoring terminowości
# ─────────────────────────────────────────────────────────────────────────────
dse_deadline_scorer(decision) = deadline {
    appeal_days := object.get(decision, "days_to_appeal", 0)
    appeal_window := 14  # Standard: 14 dni na odwołanie (art. 223 § 1 OrdPU)
    days_remaining := max([appeal_window - appeal_days, 0])

    deadline_status := "URGENT" { days_remaining <= 3 }
    deadline_status := "WARNING" { days_remaining > 3; days_remaining <= 7 }
    deadline_status := "OK" { days_remaining > 7 }

    missed := days_remaining <= 0
    remedy := "PRZYWRÓCENIE TERMINU (art. 162 OrdPU)" { missed }
    remedy := "" { not missed }

    deadline := {
        "appeal_window_days": appeal_window,
        "days_elapsed": appeal_days,
        "days_remaining": days_remaining,
        "status": deadline_status,
        "missed_deadline": missed,
        "remedy": remedy,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# DSE-3250: Build DSE warnings
# ─────────────────────────────────────────────────────────────────────────────
build_dse_warnings(classification, appeal_chance, gaar, limitation, deadline) = warnings {
    decision_type := object.get(classification, "type", "UNKNOWN")
    chance_level := object.get(appeal_chance, "level", "MEDIUM")
    recommendation := object.get(appeal_chance, "recommendation", "")
    days_remaining := object.get(deadline, "days_remaining", 0)

    base := [sprintf("🔍 DECISION SCORING ENGINE — Decyzja: %s", [decision_type])]

    chance_warn := array.concat(base, [
        sprintf("   📊 Szansa odwołania: %s (%d/100)", [chance_level, object.get(appeal_chance, "total_score", 50)]),
        sprintf("   💡 %s", [recommendation]),
    ])

    gaar_warn := array.concat(chance_warn, [
        sprintf("   🎯 GAAR: Korzyść %d PLN (próg 100k), 3 warunki: %s",
            [object.get(gaar, "benefit_amount", 0),
             sprintf("%s", [object.get(gaar, "triple_condition_met", false)])]),
    ]) { decision_type == "GAAR" }

    gaar_warn := chance_warn { decision_type != "GAAR" }

    lim_warn := array.concat(gaar_warn, [
        sprintf("   ⏳ PRZEDAWNIENIE: rok %d, upływ %d, skuteczne: %s",
            [object.get(limitation, "tax_year", 0),
             object.get(limitation, "expiry_year", 0),
             sprintf("%s", [object.get(limitation, "effective_expired", false)])]),
    ]) { object.get(limitation, "article", "") == "70" }

    lim_warn := gaar_warn { object.get(limitation, "article", "") != "70" }

    base2 := lim_warn

    dead_warn := array.concat(base2, [
        sprintf("   ⏰ TERMIN ODWOŁANIA: %d dni pozostało — %s!",
            [days_remaining, object.get(deadline, "status", "OK")]),
    ]) { days_remaining <= 7 }

    dead_warn := base2 { days_remaining > 7 }

    warnings := dead_warn
}
