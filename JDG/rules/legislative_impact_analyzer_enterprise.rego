# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 9.4: Legislative Change Impact Analyzer
# v7.0 — BP-4: Auto-feedback loop for legislative changes → rule recompilation
# Package: jdg.enterprise.legislative_impact
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.legislative_impact

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# LIA-2700: Change parser — analizuje nowelizację i mapuje na reguły
# ─────────────────────────────────────────────────────────────────────────────
lia_parse_amendment(amendment) = parsed {
    law_act := object.get(amendment, "law_act", "OrdPU")
    article := object.get(amendment, "article", "")
    change_type := object.get(amendment, "change_type", "MODIFY")
    vacatio_legis_days := object.get(amendment, "vacatio_legis_days", 14)
    effective_date := time.add_date(time.now_ns(), 0, 0, vacatio_legis_days)

    # Mapowanie artykułu na rule_id
    affected_rules := [sprintf("jdg.micro.ord.%s.r%d", [article, n]) | n := numbers.range(1, 15)]

    # Severity jako osobna zmienna (nie inline guard w obiekcie)
    severity := "HIGH" { change_type == "ADD" or change_type == "DELETE" }
    severity := "MEDIUM" { change_type == "MODIFY" }
    severity := "LOW" { change_type == "CLARIFY" }
    severity := "MEDIUM" { true }  # Fallback dla nieznanych typów zmian

    parsed := {
        "law_act": law_act,
        "article": article,
        "change_type": change_type,
        "vacatio_legis_days": vacatio_legis_days,
        "effective_date_ns": effective_date,
        "affected_rules": affected_rules,
        "severity": severity,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# LIA-2710: Rule dependency graph — które reguły muszą być przekompilowane
# ─────────────────────────────────────────────────────────────────────────────
lia_dependency_graph(article) = deps {
    # Mapowania zależności między artykułami OrdPU
    dep_map := {
        "16": ["plan34_ord", "tax_authority_interaction"],
        "20": ["plan34_ord", "tax_optimization", "audit_defense"],
        "21": ["plan34_ord", "overpayment_auto_claimer"],
        "48": ["plan34_ord"],  # DEPRECATED
        "51": ["plan34_ord"],  # DEPRECATED
        "56": ["plan34_ord", "interest_calculator"],
        "67": ["plan34_ord", "tax_authority_interaction"],
        "70": ["plan34_ord", "proceeding_tracker", "deadline_monitor"],
        "72": ["plan34_ord", "overpayment_auto_claimer"],
        "81": ["plan34_ord", "jpk_corrections_workflow"],
        "119a": ["plan34_ord", "gaar_shield"],
        "138": ["plan34_ord", "poa_manager"],
        "193a": ["plan34_ord", "tax_authority_interaction", "audit_defense"],
    }

    deps := object.get(dep_map, article, ["plan34_ord"])
}

# ─────────────────────────────────────────────────────────────────────────────
# LIA-2720: Impact scorer — ocena wpływu zmiany na JDG
# ─────────────────────────────────────────────────────────────────────────────
lia_impact_scorer(parsed_amendment, jdg_profile) = score {
    change_type := object.get(parsed_amendment, "change_type", "MODIFY")
    severity := object.get(parsed_amendment, "severity", "MEDIUM")
    article := object.get(parsed_amendment, "article", "")

    # Skala 0-100
    base_score := {"ADD": 90, "DELETE": 95, "MODIFY": 60, "CLARIFY": 20}[change_type]

    # Bonus za artykuły kluczowe dla JDG
    critical_articles := {"20", "21", "56", "67a", "67b", "67c", "67d", "67e", "70", "72", "81", "119a"}
    critical_bonus := 10 { critical_articles[article] } else := 0

    # Bonus za vacatio legis poniżej 30 dni
    vacatio_days := object.get(parsed_amendment, "vacatio_legis_days", 14)
    urgency_bonus := 5 { vacatio_days <= 14 } else := 0

    score := min([base_score + critical_bonus + urgency_bonus, 100])
}

# ─────────────────────────────────────────────────────────────────────────────
# LIA-2730: Rule regeneration template — auto-generacja nowej reguły OPA
# ─────────────────────────────────────────────────────────────────────────────
lia_regenerate_rule(article, rule_number, change_type) = rule_template {
    priority_base := {
        "16": 70016, "20": 70022, "21": 70027,
        "48": 70080, "51": 70085, "56": 70105,
        "67": 70120, "70": 70150, "72": 70180,
        "81": 70210, "119a": 70300, "138": 70400,
        "193a": 70500,
    }
    base_priority := object.get(priority_base, article, 70999)
    priority := base_priority + rule_number - 1

    rule_template := {
        "rule_id": sprintf("jdg.micro.ord.%s.r%d", [article, rule_number]),
        "package": "jdg.micro.ord",
        "priority": priority,
        "change_type": change_type,
        "generated": true,
        "generated_at": time.now_ns(),
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# LIA-2740: Compliance calendar — kalendarz zmian prawnych
# ─────────────────────────────────────────────────────────────────────────────
lia_compliance_calendar(amendments) = calendar {
    upcoming := [a | a := amendments[_]; object.get(a, "effective_date_ns", 0) > time.now_ns()]
    in_effect := [a | a := amendments[_]; object.get(a, "effective_date_ns", 0) <= time.now_ns()]

    calendar := {
        "total_amendments": count(amendments),
        "upcoming": count(upcoming),
        "in_effect": count(in_effect),
        "next_effective": object.get(upcoming[0], "effective_date_ns", 0) { count(upcoming) > 0 },
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# LIA-2750: Build LIA warnings
# ─────────────────────────────────────────────────────────────────────────────
build_lia_warnings(parsed, impact_score, deps) = warnings {
    law_act := object.get(parsed, "law_act", "")
    article := object.get(parsed, "article", "")
    change_type := object.get(parsed, "change_type", "")
    vacatio := object.get(parsed, "vacatio_legis_days", 14)

    dep_count := count(deps)

    base := [sprintf("📜 LEGISLATIVE IMPACT ANALYZER — %s art. %s [%s]",
        [law_act, article, change_type])]

    score_warn := array.concat(base, [
        sprintf("   🔴 IMPACT: %d/100 (KRYTYCZNY) — wymaga natychmiastowej rekompilacji %d modułów",
            [impact_score, dep_count]),
        sprintf("   ⏰ Vacatio legis: %d dni", [vacatio]),
    ]) { impact_score >= 75 }

    score_warn := array.concat(base, [
        sprintf("   🟡 IMPACT: %d/100 (ŚREDNI) — rekompilacja %d modułów",
            [impact_score, dep_count]),
        sprintf("   ⏰ Vacatio legis: %d dni", [vacatio]),
    ]) { impact_score < 75; impact_score >= 40 }

    score_warn := array.concat(base, [
        sprintf("   🟢 IMPACT: %d/100 (NISKI) — %d modułów", [impact_score, dep_count]),
    ]) { impact_score < 40 }

    warnings := score_warn
}
