# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 9.6: Judicial Trend Analyzer
# v7.0 — BP-6: WSA/NSA case law analysis with precedence weighting
# Package: jdg.enterprise.judicial_trend
# Expands: judicial_interpretations_enterprise.rego
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.judicial_trend

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# JTR-2900: Ruling importer — import i normalizacja orzeczeń
# ─────────────────────────────────────────────────────────────────────────────
jtr_import_ruling(raw_ruling) = normalized {
    court := object.get(raw_ruling, "court", "WSA")
    case_number := object.get(raw_ruling, "case_number", "")
    ruling_date := object.get(raw_ruling, "ruling_date", "")
    articles := object.get(raw_ruling, "articles", [])
    outcome := object.get(raw_ruling, "outcome", "UNKNOWN")

    # Normalizacja outcome — osobne zmienne zamiast inline guard
    norm_outcome := "TAXPAYER_FAVORABLE" { contains(outcome, "uchylono") or contains(outcome, "korzystna") }
    norm_outcome := "TAXPAYER_UNFAVORABLE" { contains(outcome, "oddalono") or contains(outcome, "niekorzystna") }
    norm_outcome := "NEUTRAL" { true }

    normalized := {
        "court": court,
        "case_number": case_number,
        "ruling_date": ruling_date,
        "articles": articles,
        "outcome": outcome,
        "normalized_outcome": norm_outcome,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# JTR-2910: Precedence weight calculator
# ─────────────────────────────────────────────────────────────────────────────
jtr_precedence_weight(ruling) = weight {
    court := object.get(ruling, "court", "WSA")

    weights := {
        "WSA": 1,
        "NSA_3": 3,
        "NSA_7": 5,
        "NSA_FULL": 8,
        "TK": 10,
        "TSUE": 10,
    }

    weight := object.get(weights, court, 1)
}

# ─────────────────────────────────────────────────────────────────────────────
# JTR-2920: Trend detector — wykrywanie trendów w linii orzeczniczej
# ─────────────────────────────────────────────────────────────────────────────
jtr_trend_detector(rulings) = trend {
    favorable_count := count([r | r := rulings[_]
        ; object.get(r, "normalized_outcome", "") == "TAXPAYER_FAVORABLE"])
    unfavorable_count := count([r | r := rulings[_]
        ; object.get(r, "normalized_outcome", "") == "TAXPAYER_UNFAVORABLE"])
    total := count(rulings)

    favorable_pct := favorable_count * 100 / max([total, 1])
    unfavorable_pct := unfavorable_count * 100 / max([total, 1])

    trend_direction := "UNFAVORABLE" { unfavorable_pct >= 60 }
    trend_direction := "FAVORABLE" { favorable_pct >= 60 }
    trend_direction := "MIXED" { true }

    trend := {
        "total_rulings": total,
        "favorable": favorable_count,
        "unfavorable": unfavorable_count,
        "favorable_pct": favorable_pct,
        "direction": trend_direction,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# JTR-2930: Article mapper — mapuje orzeczenia na artykuły podatkowe
# ─────────────────────────────────────────────────────────────────────────────
jtr_map_to_articles(rulings) = article_map {
    article_map := {
        "a16": {
            "label": "Czynny żal (KKS)",
            "trends": jtr_trend_detector([r | r := rulings[_]
                ; object.get(r, "articles", [])[_] == "16"]),
        },
        "a70": {
            "label": "Przedawnienie",
            "trends": jtr_trend_detector([r | r := rulings[_]
                ; object.get(r, "articles", [])[_] == "70"]),
        },
        "a119a": {
            "label": "GAAR",
            "trends": jtr_trend_detector([r | r := rulings[_]
                ; object.get(r, "articles", [])[_] == "119a"]),
        },
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# JTR-2940: Risk alerter — alerty o niekorzystnych trendach
# ─────────────────────────────────────────────────────────────────────────────
jtr_risk_alerter(article_trends, profile_articles) = alerts {
    # Buduj alerty przez list comprehension — unikamy dead code z redeklaracją
    alerts := [sprintf(
        "🚨 NIEKORZYSTNY TREND dla art. %s: %d%% orzeczeń przeciwko podatnikom",
        [a, object.get(
            object.get(article_trends, a, {"trends": {"unfavorable_pct": 0}}),
            "trends", {"unfavorable_pct": 0},
        ).unfavorable_pct, 0],
    ) | a := profile_articles[_]
        ; object.get(
            object.get(article_trends, a, {"trends": {"unfavorable_pct": 0}}),
            "trends", {"unfavorable_pct": 0},
        ).unfavorable_pct >= 60
    ]
}

# ─────────────────────────────────────────────────────────────────────────────
# JTR-2950: Precedence scorer
# ─────────────────────────────────────────────────────────────────────────────
jtr_precedence_scorer(article, rulings) = score {
    relevant := [r | r := rulings[_]; object.get(r, "articles", [])[_] == article]
    rel_count := count(relevant)

    prec_direction := "NEUTRAL" { rel_count == 0 }
    prec_direction := "ESTABLISHED" { rel_count > 0 }

    confidence := "HIGH" { rel_count >= 15 }
    confidence := "MEDIUM" { rel_count >= 5; rel_count < 15 }
    confidence := "LOW" { rel_count < 5 }

    score := {
        "article": article,
        "relevant_count": rel_count,
        "precedence_direction": prec_direction,
        "confidence": confidence,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# JTR-2960: Build JTR warnings
# ─────────────────────────────────────────────────────────────────────────────
build_jtr_warnings(article_map, alerts, profile_articles) = warnings {
    base := ["⚖️ JUDICIAL TREND ANALYZER — Analiza orzecznictwa"]

    trend_lines := base

    art_warn := array.concat(trend_lines, [
        sprintf("   Art. %s: %d orzeczeń, trend: %s (confidence: %s)",
            [a,
             object.get(object.get(article_map, a, {"trends": {"total_rulings": 0}}), "trends", {"total_rulings": 0}).total_rulings,
             object.get(object.get(article_map, a, {"trends": {"direction": "UNKNOWN"}}), "trends", {"direction": "UNKNOWN"}).direction,
             object.get(jtr_precedence_scorer(a, []), "confidence", "LOW"),
            ]),
    ]) { count(profile_articles) > 0; a := profile_articles[_] }

    art_warn := trend_lines { count(profile_articles) == 0 }

    alert_warn := array.concat(art_warn, alerts) { count(alerts) > 0 }
    alert_warn := art_warn { count(alerts) == 0 }

    warnings := alert_warn
}
