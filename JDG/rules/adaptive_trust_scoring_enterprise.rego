# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ADAPTIVE TRUST SCORING (P02 Warstwa Decyzyjna Core — Sekcja 1)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.adaptive_trust
# Raport: RAPORT_P02_JDG_WARSTWA_DECYZYJNA_CORE v8.0 — Sekcja 1 (Ryzyko i Trust Score)
#
# ADAPTACYJNY SCORING ML (zamiast stałych progów 0.92/0.75):
#   AT-01 Base Trust Score — z pewności pól OCR + jakości dokumentu.
#   AT-02 Domain Corrections — accuracy historyczna per pakiet koryguje bazę
#        (data.jdg.trust_feedback — pętla sprzężenia zwrotnego z P01).
#   AT-03 Adaptive Thresholds — progi AUTO_POST/SUGGEST per pakiet (nie globalne).
#   AT-04 Counterparty Risk — sankcje, biała lista, graf fraudowy, NIP.
#   AT-05 Fraud Pattern Detection — schematy fraudowe (okrągłe kwoty, szybkie
#        obroty, self-invoicing, zmiana NIP).
#   AT-06 Cross-Rule Correlation — sygnały z wielu pakietów składają się na
#        finalny trust (konflikt sygnałów obniża pewność).
#
# Zgodność: risk.rego (P1/P2), routing.rego, P02 Sekcja 1, P01 INN-09.
# package: jdg.adaptive_trust
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.adaptive_trust

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.adaptive_trust.no_match","package":"jdg.adaptive_trust","priority":999999}

# ── AT-01: Base Trust Score z pewności pól ───────────────────────────────────
# 0.0 - 1.0; bazuje na confidence OCR poszczególnych pól (im więcej pól
# pewnych, tym wyższy bazowy trust).
base_trust_score := score {
    fc_vat := object.get(input.confidence, "fc_vat_rate", 1.0)
    fc_nip := object.get(input.confidence, "fc_vendor_nip", 1.0)
    fc_date := object.get(input.confidence, "fc_date", 1.0)
    fc_amount := object.get(input.confidence, "fc_amount", 1.0)
    avg := (fc_vat + fc_nip + fc_date + fc_amount) / 4
    score := round(avg * 1000) / 1000
}

# ── AT-02: Korekta per pakiet z accuracy historycznej ───────────────────────
# accuracy_package = correct/(correct+incorrect) z data.jdg.trust_feedback.packages.
# Brak feedbacku = neutralne 0.90 (nie 1.0 — zero danych nie jest dowodem
# perfekcji; neutralna baza zapobiega zawyżaniu trust powyżej 1.0).
package_accuracy(pkg) = acc {
    feedback := object.get(data.jdg, "trust_feedback", {})
    packages := object.get(feedback, "packages", {})
    p := object.get(packages, pkg, {})
    correct := object.get(p, "correct", 0)
    incorrect := object.get(p, "incorrect", 0)
    total := correct + incorrect
    total == 0
    acc := 0.90
} else := acc {
    feedback := object.get(data.jdg, "trust_feedback", {})
    packages := object.get(feedback, "packages", {})
    p := object.get(packages, pkg, {})
    correct := object.get(p, "correct", 0)
    incorrect := object.get(p, "incorrect", 0)
    total := correct + incorrect
    total > 0
    acc := correct / total
}

# ── AT-03: Adaptive thresholds per pakiet ────────────────────────────────────
# AUTO_POST dla pakietu = 0.92 + (accuracy - 0.90) * 0.05 (im lepsza historia
# pakietu, tym pewniej automat postujemy).
auto_post_threshold(pkg) = t {
    acc := package_accuracy(pkg)
    t := round((0.92 + (acc - 0.90) * 0.05) * 1000) / 1000
}

suggest_threshold(pkg) = t {
    acc := package_accuracy(pkg)
    t := round((0.75 + (acc - 0.90) * 0.05) * 1000) / 1000
}

# ── AT-04: Counterparty Risk ─────────────────────────────────────────────────
# Ryzyko kontrahenta: sankcje / brak białej listy / graf fraudowy / zgłoszenia.
counterparty_risk_level := "HIGH" {
    object.get(input.vendor, "on_sanctions_list", false) == true
} else := "HIGH" {
    object.get(input.vendor, "fraud_graph_match", false) == true
} else := "MEDIUM" {
    object.get(input.vendor, "on_whitelist", false) == false
    input.invoice.amount_net > 15000
} else := "LOW" {
    true
}

# ── AT-05: Fraud Pattern Detection ───────────────────────────────────────────
fraud_patterns := [pattern |
    some p in ["ROUND_AMOUNTS", "SELF_INVOICING", "RAPID_TURNOVER", "NIP_CHANGE", "CASH_SPLIT"]
    fraud_pattern_detected(p) == true
    pattern := p
]

# Pojedyncza funkcja z else-chain (JEDNA reguła) — unika eval-conflict między
# regułą specyficzną a catch-all (wiele reguł o tej samej nazwie/arnosci
# dopasowujących się jednocześnie = błąd OPA).
fraud_pattern_detected(p) = true {
    p == "ROUND_AMOUNTS"
    amount := object.get(input.invoice, "amount_net", 0)
    amount > 0
    amount == round(amount / 100) * 100
    amount >= 1000
} else = true {
    p == "SELF_INVOICING"
    object.get(input.invoice, "buyer_nip", "") == object.get(input.vendor, "nip", "")
    object.get(input.invoice, "buyer_nip", "") != ""
} else = true {
    p == "RAPID_TURNOVER"
    object.get(input.invoice, "issue_date", "") == object.get(input.invoice, "sale_date", "")
    object.get(input.invoice, "rapid_turnover_flag", false) == true
} else = true {
    p == "NIP_CHANGE"
    object.get(input.vendor, "nip_changed_recently", false) == true
} else = true {
    p == "CASH_SPLIT"
    object.get(input.invoice, "cash_split_flag", false) == true
} else = false {
    true
}

# ── AT-06: Finalny Trust Score (z korektą pakietu i sygnałów fraud) ─────────
# trust = base - kara fraud - kara ryzyka kontrahenta + korekta pakietu.
# risk_penalty wyliczany top-level regułą (inline else w ciele funkcji = błąd opa).
counterparty_risk_penalty := 0.15 {
    counterparty_risk_level == "HIGH"
} else := 0.05 {
    counterparty_risk_level == "MEDIUM"
} else := 0.0 {
    true
}

final_trust_score(pkg) = t {
    base := base_trust_score
    fraud_penalty := count(fraud_patterns) * 0.10
    risk_penalty := counterparty_risk_penalty
    pkg_bonus := package_accuracy(pkg) - 0.90
    raw := base - fraud_penalty - risk_penalty + pkg_bonus
    t := round(raw * 1000) / 1000
}

# ── DECYZJA: AUTO_POST GATE ──────────────────────────────────────────────────
# Trust >= próg AUTO_POST pakietu i brak fraud → AUTO_POST.
decide := {
    "matched": true,
    "rule_id": "jdg.adaptive_trust.auto_post_gate",
    "package": "jdg.adaptive_trust",
    "priority": 100,
    "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST",
    "trust": {
        "base": base_trust_score,
        "final": final_trust_score(main_package),
        "threshold_auto_post": auto_post_threshold(main_package),
        "threshold_suggest": suggest_threshold(main_package),
        "counterparty_risk": counterparty_risk_level,
        "fraud_patterns": fraud_patterns,
        "package": main_package
    },
    "_routing": "AUTO_POST",
    "_routing_reason": "Trust score >= próg AUTO_POST pakietu, brak sygnałów fraud — decyzja automatyczna",
    "_legal_basis": "P02 Sekcja 1 — Adaptive Trust Scoring + risk.rego P1",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "trust_check", false) == true
    main_package := object.get(input.jdg_entrepreneur, "primary_package", "jdg.vat")
    final_trust_score(main_package) >= auto_post_threshold(main_package)
    count(fraud_patterns) == 0
}

# ── DECYZJA: SUGGEST GATE ────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.adaptive_trust.suggest_gate",
    "package": "jdg.adaptive_trust",
    "priority": 110,
    "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST",
    "trust": {
        "base": base_trust_score,
        "final": final_trust_score(main_package),
        "threshold_auto_post": auto_post_threshold(main_package),
        "threshold_suggest": suggest_threshold(main_package),
        "counterparty_risk": counterparty_risk_level,
        "fraud_patterns": fraud_patterns
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Trust score w przedziale SUGGEST — wymagany 1 klik weryfikacji",
    "_legal_basis": "P02 Sekcja 1 — Adaptive Trust Scoring",
    "_warnings": ["SUGGEST: decyzja wymaga weryfikacji księgowego (1 klik)."]
} {
    object.get(input.jdg_entrepreneur, "trust_check", false) == true
    main_package := object.get(input.jdg_entrepreneur, "primary_package", "jdg.vat")
    final_trust_score(main_package) >= suggest_threshold(main_package)
    final_trust_score(main_package) < auto_post_threshold(main_package)
}

# ── DECYZJA: TRIAGE / BLOCK ──────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.adaptive_trust.triage_gate",
    "package": "jdg.adaptive_trust",
    "priority": 120,
    "trust": {
        "base": base_trust_score,
        "final": final_trust_score(main_package),
        "counterparty_risk": counterparty_risk_level,
        "fraud_patterns": fraud_patterns
    },
    "_routing": triage_routing,
    "_routing_reason": "Trust score poniżej progu SUGGEST LUB wykryto sygnały fraud/ryzyko kontrahenta",
    "_legal_basis": "P02 Sekcja 1 + risk.rego (BLOCK_AND_ALERT)",
    "_warnings": ["Weryfikacja ręczna wymagana (2-3 kliknięcia) — możliwe ryzyko fraud."]
} {
    object.get(input.jdg_entrepreneur, "trust_check", false) == true
    main_package := object.get(input.jdg_entrepreneur, "primary_package", "jdg.vat")
    triage_routing := triage_routing_level
}

# Routing dla bramki TRIAGE (top-level else-chain — poprawny Rego).
triage_routing_level := "BLOCK_AND_ALERT" {
    count(fraud_patterns) > 0
} else := "BLOCK_AND_ALERT" {
    counterparty_risk_level == "HIGH"
} else := "TRIAGE_QUEUE" {
    true
}

# ── EKSPORT: RAPORT TRUST (dla monitoringu/UI) ───────────────────────────────
trust_report := {
    "base_score": base_trust_score,
    "final_score": final_trust_score(object.get(input.jdg_entrepreneur, "primary_package", "jdg.vat")),
    "counterparty_risk": counterparty_risk_level,
    "fraud_patterns": fraud_patterns,
    "adaptive_thresholds": {
        "auto_post": auto_post_threshold(object.get(input.jdg_entrepreneur, "primary_package", "jdg.vat")),
        "suggest": suggest_threshold(object.get(input.jdg_entrepreneur, "primary_package", "jdg.vat"))
    }
}
