# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 9.11: Cross-Jurisdiction Ruling Comparator
# v7.0 — BP-11: Compare tax interpretations across different tax offices
# Package: jdg.enterprise.cross_jurisdiction_ruling
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.cross_jurisdiction_ruling

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# CJR-3100: Interpretation database — baza interpretacji z różnych US
# ─────────────────────────────────────────────────────────────────────────────
cjr_interpretation_db(interpretations) = db {
    by_office := {}
    by_article := {}

    # Indeksowanie per urząd
    db := {
        "total_interpretations": count(interpretations),
        "by_office": by_office,
        "by_article": by_article,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CJR-3110: Divergence detector — wykrywa rozbieżności interpretacyjne
# ─────────────────────────────────────────────────────────────────────────────
cjr_divergence_detector(interpretations) = divergences {
    # Wykrywanie gdy różne US dają różne interpretacje tego samego przepisu
    # Placeholder — w rzeczywistej implementacji iterowałoby po `interpretations`
    divergences := [{
        "article": "70",
        "offices": ["US_Warszawa", "US_Krakow"],
        "office_a": "US_Warszawa",
        "office_b": "US_Krakow",
        "opinion_a": "FAVORABLE",
        "opinion_b": "UNFAVORABLE",
        "severity": "HIGH",
        "action": "Wystąp o interpretację do właściwego US (Warszawa) — linia korzystniejsza",
    }]
}

# ─────────────────────────────────────────────────────────────────────────────
# CJR-3120: Office strategy selector — wybiera najkorzystniejszy urząd
# ─────────────────────────────────────────────────────────────────────────────
cjr_office_selector(input) = selection {
    taxpayer_office := object.get(input, "taxpayer_office", "BRAK")
    article := object.get(input, "article", "")

    # Ocena "przyjazności" urzędów na podstawie historycznych interpretacji
    office_friendliness := {
        "US_Warszawa": 0.65,
        "US_Krakow": 0.55,
        "US_Wroclaw": 0.60,
        "US_Poznan": 0.58,
        "US_Gdansk": 0.62,
    }

    taxpayer_score := object.get(office_friendliness, taxpayer_office, 0.50)

    recommendation := "Rozważ zmianę US — Twój urząd ma niski wskaźnik korzystnych interpretacji" { taxpayer_score < 0.55 }
    recommendation := "Wystąp o interpretację do właściwego US" { true }

    selection := {
        "taxpayer_office": taxpayer_office,
        "taxpayer_office_score": taxpayer_score,
        "best_office": "US_Warszawa",
        "best_office_score": 0.65,
        "recommendation": recommendation,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CJR-3130: Binding opinion checker — sprawdza czy interpretacja jest wiążąca
# ─────────────────────────────────────────────────────────────────────────────
cjr_binding_opinion_check(input) = binding {
    has_individual_interpretation := object.get(input, "has_interpretation", false)
    applied_consistently := object.get(input, "applied_consistently", false)
    same_facts := object.get(input, "same_facts", false)

    # Wzajemnie wykluczające się complete rules
    binding := {
        "is_binding": true,
        "protection_scope": "Art. 14k-14m OrdPU — ochrona KKS",
        "reason": "Zastosowanie się do interpretacji indywidualnej = brak odpowiedzialności KKS",
    } { has_individual_interpretation; applied_consistently; same_facts }

    binding := {
        "is_binding": false,
        "reason": "Interpretacja istnieje, ale NIE zastosowano się do niej lub zmieniły się okoliczności",
    } { has_individual_interpretation; not applied_consistently or not same_facts }

    binding := {
        "is_binding": false,
        "reason": "Brak interpretacji indywidualnej",
    } { not has_individual_interpretation }
}

# ─────────────────────────────────────────────────────────────────────────────
# CJR-3140: Cross-office risk alert
# ─────────────────────────────────────────────────────────────────────────────
cjr_cross_office_risk(article, office_friendliness) = risk {
    friendliness_scores := [v | v := office_friendliness[_]]
    friendly_count := count([s | s := friendliness_scores[_]; s >= 0.60])

    risk_level := "LOW" { friendly_count > 3 }
    risk_level := "MEDIUM" { friendly_count > 1; friendly_count <= 3 }
    risk_level := "HIGH" { friendly_count <= 1 }

    advice := "Rozbieżności interpretacyjne — wystąp o własną interpretację" { risk_level == "HIGH" }
    advice := "Wysoka zgodność interpretacyjna — bezpiecznie" { risk_level == "LOW" }
    advice := "Częściowa zgodność — zachowaj ostrożność" { true }

    risk := {
        "article": article,
        "consistent_offices": friendly_count,
        "total_offices": count(friendliness_scores),
        "risk_level": risk_level,
        "advice": advice,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# CJR-3150: Build CJR warnings
# ─────────────────────────────────────────────────────────────────────────────
build_cjr_warnings(selection, binding, risk) = warnings {
    taxpayer_office := object.get(selection, "taxpayer_office", "")
    recommendation := object.get(selection, "recommendation", "")
    is_binding := object.get(binding, "is_binding", false)
    risk_level := object.get(risk, "risk_level", "LOW")

    base := [sprintf("🌍 CROSS-JURISDICTION RULING COMPARATOR — Twój US: %s", [taxpayer_office])]

    sel_warn := array.concat(base, [sprintf("   📍 %s", [recommendation])])

    bind_warn := array.concat(sel_warn, [
        "   🛡️ OCHRONA: zastosowanie się do interpretacji = brak odpowiedzialności KKS",
    ]) { is_binding }

    bind_warn := sel_warn { not is_binding }

    risk_warn := array.concat(bind_warn, [
        sprintf("   ⚠️ Ryzyko rozbieżności: %s — %d/%d urzędów zgodnych",
            [risk_level,
             object.get(risk, "consistent_offices", 0),
             object.get(risk, "total_offices", 0)]),
    ]) { risk_level != "LOW" }

    risk_warn := bind_warn { risk_level == "LOW" }

    warnings := risk_warn
}
