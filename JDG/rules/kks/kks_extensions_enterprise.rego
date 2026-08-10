# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KKS EXTENSIONS (RAPORT 07 — P0 Gap Closure)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.kks.extensions

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.kks.extensions.no_match",
    "package": "jdg.kks.extensions", "priority": 99999
}

# ═══ R900: GAAR SHIELD DEEP SCANNER — Klauzula obejścia prawa ═══
decide := {
    "matched": true, "rule_id": "jdg.kks.extensions.gaar_deep_scanner",
    "package": "jdg.kks.extensions", "priority": 900,
    "gaar_risk_score": gaar_score,
    "gaar_artificial_arrangement": is_artificial,
    "gaar_tax_benefit_primary_purpose": is_primary_purpose,
    "gaar_contrary_to_law_intent": is_contrary,
    "gaar_risk_level": risk_level,
    "_routing": gaar_rt,
    "_routing_reason": sprintf("GAAR: score %d/100 — %s", [gaar_score, risk_level]),
    "_legal_basis": "Art. 119a Ordynacji podatkowej (klauzula GAAR)",
    "_warnings": [sprintf("🔍 GAAR SCANNER — Score: %d/100 (%s). Sztuczna konstrukcja: %s. Cel podatkowy: %s. Sprzeczność z ustawą: %s",
        [gaar_score, risk_level, is_artificial, is_primary_purpose, is_contrary])]
} {
    input.gaar_scan_requested == true
    is_artificial := object.get(input.invoice, "gaar_artificial_arrangement", false)
    is_primary_purpose := object.get(input.invoice, "gaar_tax_benefit_primary_purpose", false)
    is_contrary := object.get(input.invoice, "gaar_contrary_to_law_intent", false)
    gaar_score := 0
    gaar_score := gaar_score + 40 { is_artificial }
    gaar_score := gaar_score + 35 { is_primary_purpose }
    gaar_score := gaar_score + 25 { is_contrary }
    risk_level = "NISKIE" { gaar_score < 30 }
    risk_level = "ŚREDNIE" { gaar_score >= 30; gaar_score < 60 }
    risk_level = "WYSOKIE — GAAR może mieć zastosowanie!" { gaar_score >= 60 }
    gaar_rt = "BLOCK_AND_ALERT" { gaar_score >= 60 }
    gaar_rt = "TRIAGE_QUEUE" { gaar_score >= 30; gaar_score < 60 }
    gaar_rt = "" { true }
}

# ═══ R901: DEFENSE_BUILDER — Automatyczny kreator strategii obrony ═══
else := {
    "matched": true, "rule_id": "jdg.kks.extensions.defense_builder",
    "package": "jdg.kks.extensions", "priority": 901,
    "kks_defense_strategies": [
        "1. BRAK CZYNU — działanie nie wyczerpuje znamion przestępstwa skarbowego",
        "2. BRAK WINY — nieświadomość bezprawności (usprawiedliwiony błąd co do prawa)",
        "3. ZNIKOMA SZKODLIWOŚĆ — uszczuplenie < 5000 PLN, czynny żal",
        "4. NADZWYCZAJNE ZŁAGODZENIE — naprawienie szkody + współpraca z KAS"
    ],
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Defense builder — 4 strategie obrony KKS",
    "_legal_basis": "Art. 16-19 KKS; Art. 10 KKS",
    "_warnings": ["🛡️ DEFENSE BUILDER — 4 strategie obrony: (1) Brak czynu, (2) Brak winy, (3) Znikoma szkodliwość, (4) Nadzwyczajne złagodzenie. Wybierz strategię i przygotuj dokumentację."]
} {
    input.jdg_entrepreneur.kks_defense_needed == true
}

# ═══ R902: KKS_LIMITS_VERIFICATION — Weryfikacja stawek KKS ═══
else := {
    "matched": true, "rule_id": "jdg.kks.extensions.limits_verification",
    "package": "jdg.kks.extensions", "priority": 902,
    "kks_penalty_limits": {
        "daily_rate_min": floor(min_wage / 30 * 100) / 100,
        "daily_rate_max": floor(min_wage / 30 * 400 * 100) / 100,
        "max_daily_rates": 720,
        "max_total_fine": floor(min_wage / 30 * 400 * 720 * 100) / 100,
        "crime_statute_years": 5,
        "misdemeanor_statute_years": 3,
        "max_statute_years": 10,
        "ksef_sanction_max": 500000,
        "empty_invoice_max_years": 25,
        "mdr_sanction_max": 2000000,
    },
    "_routing": "",
    "_routing_reason": "Weryfikacja limitów KKS — zgodne z Dz.U. 2024 poz. 628",
    "_legal_basis": "KKS Art. 23, 44, 48, 51, 62; OrdPU Art. 86a",
    "_warnings": [sprintf("📋 LIMITY KKS: stawka dzienna %.2f-%.2f PLN, max grzywna %.0f PLN, przedawnienie 5/3 lat, KSeF 500k PLN, MDR 2M PLN, puste faktury 25 lat",
        [floor(min_wage / 30 * 100) / 100, floor(min_wage / 30 * 400 * 100) / 100, floor(min_wage / 30 * 400 * 720 * 100) / 100])]
} {
    min_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4800)
    true
}

# ═══ R999: coverage summary ═══
else := {
    "matched": true, "rule_id": "jdg.kks.extensions.coverage_summary",
    "package": "jdg.kks.extensions", "priority": 999,
    "kks_gaps_covered": {
        "GAAR_SCANNER": "R900 ✅ NOWE",
        "DEFENSE_BUILDER": "R901 ✅ NOWE",
        "LIMITS_VERIFICATION": "R902 ✅ NOWE"
    },
    "total_new_rules": 3,
    "generated_from": "RAPORT_07_KKS.txt",
    "_warnings": ["📋 RAPORT 07 P0 — 3 reguły: GAAR scanner, defense builder, limits verification"]
} {
    1 == 1
}
