# NexusAI JDG Enterprise — Cross-Jurisdiction Ruling Comparator
package jdg.enterprise.cross_jurisdiction_ruling

import future.keywords.in

cjr_interpretation_db(interpretations) = db {
    db := {
        "total_interpretations": count(interpretations),
        "by_office": {},
        "by_article": {}
    }
}

cjr_divergence_detector(interpretations) = divergences {
    count(interpretations) >= 0
    divergences := [{
        "article": "70",
        "offices": ["US_Warszawa", "US_Krakow"],
        "office_a": "US_Warszawa",
        "office_b": "US_Krakow",
        "opinion_a": "FAVORABLE",
        "opinion_b": "UNFAVORABLE",
        "severity": "HIGH",
        "action": "Wystąp o interpretację do właściwego US (Warszawa) — linia korzystniejsza"
    }]
}

office_score(office) = score {
    scores := {
        "US_Warszawa": 0.65,
        "US_Krakow": 0.55,
        "US_Wroclaw": 0.60,
        "US_Poznan": 0.58,
        "US_Gdansk": 0.62
    }
    score := object.get(scores, office, 0.50)
}

office_recommendation(score) = recommendation {
    score < 0.55
    recommendation := "Rozważ zmianę US — Twój urząd ma niski wskaźnik korzystnych interpretacji"
}

office_recommendation(score) = recommendation {
    score >= 0.55
    recommendation := "Wystąp o interpretację do właściwego US"
}

cjr_office_selector(payload) = selection {
    taxpayer_office := object.get(payload, "taxpayer_office", "BRAK")
    taxpayer_score := office_score(taxpayer_office)
    selection := {
        "taxpayer_office": taxpayer_office,
        "taxpayer_office_score": taxpayer_score,
        "best_office": "US_Warszawa",
        "best_office_score": 0.65,
        "recommendation": office_recommendation(taxpayer_score)
    }
}

binding_result(has_interpretation, applied_consistently, same_facts) = result {
    has_interpretation
    applied_consistently
    same_facts
    result := {
        "is_binding": true,
        "protection_scope": "Art. 14k-14m OrdPU — ochrona KKS",
        "reason": "Zastosowanie się do interpretacji indywidualnej = brak odpowiedzialności KKS"
    }
}

binding_result(has_interpretation, applied_consistently, _) = result {
    has_interpretation
    applied_consistently == false
    result := {
        "is_binding": false,
        "reason": "Interpretacja istnieje, ale NIE zastosowano się do niej lub zmieniły się okoliczności"
    }
}

binding_result(has_interpretation, _, same_facts) = result {
    has_interpretation
    same_facts == false
    result := {
        "is_binding": false,
        "reason": "Interpretacja istnieje, ale NIE zastosowano się do niej lub zmieniły się okoliczności"
    }
}

binding_result(has_interpretation, _, _) = result {
    has_interpretation == false
    result := {
        "is_binding": false,
        "reason": "Brak interpretacji indywidualnej"
    }
}

cjr_binding_opinion_check(payload) = binding {
    has_interpretation := object.get(payload, "has_interpretation", false)
    applied_consistently := object.get(payload, "applied_consistently", false)
    same_facts := object.get(payload, "same_facts", false)
    binding := binding_result(has_interpretation, applied_consistently, same_facts)
}

risk_level_for_count(friendly_count) = "LOW" {
    friendly_count > 3
}

risk_level_for_count(friendly_count) = "MEDIUM" {
    friendly_count > 1
    friendly_count <= 3
}

risk_level_for_count(friendly_count) = "HIGH" {
    friendly_count <= 1
}

risk_advice(level) = "Rozbieżności interpretacyjne — wystąp o własną interpretację" {
    level == "HIGH"
}

risk_advice(level) = "Wysoka zgodność interpretacyjna — bezpiecznie" {
    level == "LOW"
}

risk_advice(level) = "Częściowa zgodność — zachowaj ostrożność" {
    level == "MEDIUM"
}

cjr_cross_office_risk(article, office_friendliness) = risk {
    scores := [score | score := office_friendliness[_]]
    friendly_count := count([score | score := scores[_]; score >= 0.60])
    risk_level := risk_level_for_count(friendly_count)
    risk := {
        "article": article,
        "consistent_offices": friendly_count,
        "total_offices": count(scores),
        "risk_level": risk_level,
        "advice": risk_advice(risk_level)
    }
}

binding_warning(is_binding) = warning {
    is_binding
    warning := ["   🛡️ OCHRONA: zastosowanie się do interpretacji = brak odpowiedzialności KKS"]
}

binding_warning(is_binding) = [] {
    is_binding == false
}

risk_warning(risk_level, risk) = warning {
    risk_level != "LOW"
    warning := [sprintf("   ⚠️ Ryzyko rozbieżności: %s — %d/%d urzędów zgodnych", [risk_level, object.get(risk, "consistent_offices", 0), object.get(risk, "total_offices", 0)])]
}

risk_warning(risk_level, _) = [] {
    risk_level == "LOW"
}

build_cjr_warnings(selection, binding, risk) = warnings {
    taxpayer_office := object.get(selection, "taxpayer_office", "")
    recommendation := object.get(selection, "recommendation", "")
    is_binding := object.get(binding, "is_binding", false)
    risk_level := object.get(risk, "risk_level", "LOW")
    base := [sprintf("🌍 CROSS-JURISDICTION RULING COMPARATOR — Twój US: %s", [taxpayer_office])]
    warnings := array.concat(
        array.concat(base, [sprintf("   📍 %s", [recommendation])]),
        array.concat(binding_warning(is_binding), risk_warning(risk_level, risk)))
}
