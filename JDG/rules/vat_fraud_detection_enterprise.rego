# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT FRAUD DETECTION (P03 VAT Macro — Sekcja 6)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.vat_fraud_detection
# Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_VAT_MACRO (P03) v8.0 — Sekcja 6
#
# FRAUD DETECTION VAT (poziom ENTERPRISE):
#   FD-01 Puste faktury — faktura bez realnej transakcji (brak dostawy/usługi,
#        brak śladów w transporcie, cena nieadekwatna).
#   FD-02 Karuzele VAT — łańcuch transakcji tymi samymi towarami, brak realnego
#        zużycia, te same kontrahenci w kółko (data.jdg.vat.fraud_graph).
#   FD-03 Znikający podatnik (MTIC) — dostawca zarejestrowany, ale bez
#        deklaracji / nieaktywny / nie figuruje w bazach (biała lista, VIES).
#   FD-04 Odpowiedzialność solidarna (art. 105a-105c) — wiedza o nieuczciwym
#        dostawcy / cena poniżej rynku → solidarna odpowiedzialność.
#   FD-05 Scoring ryzyka fraudu — per kontrahent (0-100) i per transakcja:
#        składniki: wiek firmy, aktywność VAT, zgodność białej listy, odchylenie
#        ceny od rynku, powtarzalność, anomalie (okrągłe kwoty, backdating).
#   FD-06 Anomalie transakcyjne — faktura wystawiona przed zawarciem umowy,
#        korekta tożsamości NIP, szybkie następstwo transakcji.
#
# Zgodność: art. 105a-105c, 108b VAT, ustawy o KAS (sygnały), P03 Sekcja 6.
# package: jdg.vat_fraud_detection
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat_fraud_detection

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.vat_fraud_detection.no_match","package":"jdg.vat_fraud_detection","priority":999999}

# ── FD-05: SCORING RYZYKA FRAUDU per kontrahent ──────────────────────────────
# Składniki (0-100): sum() comprehensions z guardami (idiomatyczny Rego — bez
# reassignment w rule body). Próg: ≥ 60 = HIGH.
counterparty_risk_score := sum([
    25 | object.get(input.vendor, "on_sanctions_list", false) == true
] + [
    20 | object.get(input.vendor, "is_vat_active", false) == false
] + [
    15 | object.get(input.vendor, "vat_eu_registered", false) == false and object.get(input.vendor, "country", "PL") != "PL"
] + [
    15 | object.get(input.vendor, "on_whitelist", false) == false and object.get(input.vendor, "country", "PL") == "PL"
] + [
    10 | object.get(input.vendor, "company_age_years", 10) < 1
] + [
    10 | object.get(input.vendor, "missing_declarations", false) == true
] + [
    5 | object.get(input.vendor, "nip_changed_recently", false) == true
])

transaction_risk_score := sum([
    25 | object.get(input.invoice, "is_fraud_graph_match", false) == true
] + [
    20 | object.get(input.invoice, "amount_net", 0) > 0 and round(object.get(input.invoice, "amount_net", 0) / 100) * 100 == object.get(input.invoice, "amount_net", 0) and object.get(input.invoice, "amount_net", 0) >= 1000
] + [
    15 | object.get(input.invoice, "price_below_market_pct", 0) >= 30
] + [
    10 | object.get(input.invoice, "issued_before_contract", false) == true
] + [
    10 | object.get(input.invoice, "rapid_resale_flag", false) == true
] + [
    10 | object.get(input.invoice, "backdated_invoice", false) == true
] + [
    5 | object.get(input.invoice, "cash_only", false) == true
])

fraud_score_decision := "HIGH" {
    counterparty_risk_score >= 60
} else := "HIGH" {
    transaction_risk_score >= 50
} else := "MEDIUM" {
    counterparty_risk_score >= 30
} else := "MEDIUM" {
    transaction_risk_score >= 25
} else := "LOW" {
    true
}

# ── FD-01: PUSTA FAKTURA ─────────────────────────────────────────────────────
# Faktura bez realnej transakcji: brak dowodu dostawy, brak transportu,
# kontrahent fikcyjny (NIP nieaktywny), cena nierynkowa.
empty_invoice_detection := {
    "matched": true,
    "rule_id": "jdg.vat_fraud_detection.empty_invoice",
    "package": "jdg.vat_fraud_detection",
    "priority": 100,
    "fraud": {
        "type": "EMPTY_INVOICE",
        "signals": empty_invoice_signals,
        "signal_count": count(empty_invoice_signals)
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sygnały pusteJ faktury — brak realnej transakcji (ryzyko przestępstwa skarbowego)",
    "_legal_basis": "Art. 62-63, 76-77 KKS + art. 108 VAT",
    "_warnings": ["PUSTA FAKTURA: brak dowodów realnej transakcji. Odliczenie VAT może być zakwestionowane — ryzyko KKS."]
} {
    object.get(input.jdg_entrepreneur, "vat_fraud_check", false) == true
    count(empty_invoice_signals) >= 2
}

empty_invoice_signals := [
    "NO_DELIVERY_EVIDENCE" | object.get(input.invoice, "has_delivery_evidence", false) == false
] + [
    "NO_TRANSPORT_EVIDENCE" | object.get(input.invoice, "has_transport_evidence", false) == false and object.get(input.invoice, "category_code", "") in {"GOODS", "MERCHANDISE", "FUEL", "STEEL"}
] + [
    "VENDOR_NOT_ACTIVE_VAT" | object.get(input.vendor, "is_vat_active", false) == false
] + [
    "PRICE_BELOW_MARKET_30" | object.get(input.invoice, "price_below_market_pct", 0) >= 30
] + [
    "NO_CONTRACT" | object.get(input.invoice, "has_contract", false) == false
]

# ── FD-02: KARUZELA VAT (MTIC) ───────────────────────────────────────────────
# Łańcuch: ten sam towar, szybka odsprzedaż, brak zużycia w łańcuchu,
# kontrahenci z grafu fraudowego (data.jdg.vat.fraud_graph).
carousel_detection := {
    "matched": true,
    "rule_id": "jdg.vat_fraud_detection.carousel",
    "package": "jdg.vat_fraud_detection",
    "priority": 200,
    "fraud": {
        "type": "VAT_CAROUSEL",
        "signals": carousel_signals,
        "signal_count": count(carousel_signals)
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sygnały karuzeli VAT — szybka odsprzedaż tych samych towarów w łańcuchu",
    "_legal_basis": "art. 105a-105c VAT (odpowiedzialność solidarna) + wyrok TSUE C-131/13",
    "_warnings": ["KARUZELA VAT: transakcja w łańcuchu z grafu fraudowego. Wymagana szczególna ostrożność — solidarna odpowiedzialność możliwa przy wiedzy o nadużyciu."]
} {
    object.get(input.jdg_entrepreneur, "vat_fraud_check", false) == true
    count(carousel_signals) >= 2
}

carousel_signals := [
    "FRAUD_GRAPH_MATCH" | object.get(input.invoice, "is_fraud_graph_match", false) == true
] + [
    "RAPID_RESALE" | object.get(input.invoice, "rapid_resale_flag", false) == true
] + [
    "SAME_GOODS_CHAIN" | object.get(input.invoice, "same_goods_chain", false) == true
] + [
    "NO_ECONOMIC_SUBSTANCE" | object.get(input.invoice, "no_economic_substance", false) == true
] + [
    "INTERMEDIARY_PATTERN" | object.get(input.invoice, "intermediary_pattern", false) == true
]

# ── FD-03: ZNIKAJĄCY PODATNIK (MTIC) ─────────────────────────────────────────
vanishing_trader_detection := {
    "matched": true,
    "rule_id": "jdg.vat_fraud_detection.vanishing_trader",
    "package": "jdg.vat_fraud_detection",
    "priority": 300,
    "fraud": {
        "type": "VANISHING_TRADER",
        "signals": vanishing_signals,
        "signal_count": count(vanishing_signals)
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Dostawca-zjawisko (znikający podatnik) — zarejestrowany ale nieaktywny/błądzący",
    "_legal_basis": "art. 105a-105c VAT + art. 55-57 KKS",
    "_warnings": ["ZNIKAJĄCY PODATNIK: dostawca nie wykazuje transakcji w JPK/deklaracjach. Ryzyko zakwestionowania odliczenia VAT naliczonego."]
} {
    object.get(input.jdg_entrepreneur, "vat_fraud_check", false) == true
    count(vanishing_signals) >= 1
}

vanishing_signals := [
    "MISSING_DECLARATIONS" | object.get(input.vendor, "missing_declarations", false) == true
] + [
    "NOT_ON_WHITELIST_ACTIVE" | object.get(input.vendor, "on_whitelist", false) == false and object.get(input.vendor, "country", "PL") == "PL"
] + [
    "NEWLY_REGISTERED" | object.get(input.vendor, "company_age_years", 10) < 1
] + [
    "FREQUENT_ADDRESS_CHANGE" | object.get(input.vendor, "frequent_address_change", false) == true
]

# ── FD-04: ODPOWIEDZIALNOŚĆ SOLIDARNA (art. 105a-105c) ───────────────────────
# Wiedza/brak staranności przy transakcji z nieuczciwym dostawcą lub cena
# rażąco poniżej rynku → solidarna odpowiedzialność nabywcy za VAT.
solidary_fraud_liability := {
    "matched": true,
    "rule_id": "jdg.vat_fraud_detection.solidary_liability",
    "package": "jdg.vat_fraud_detection",
    "priority": 400,
    "fraud": {
        "type": "SOLIDARY_LIABILITY",
        "basis": solidary_basis,
        "price_below_market_pct": object.get(input.invoice, "price_below_market_pct", 0)
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Solidarna odpowiedzialność nabywcy za VAT (art. 105a-105c) — wiedza o nieuczciwości dostawcy",
    "_legal_basis": "Art. 105a-105c VAT",
    "_warnings": ["SOLIDARNA ODPOWIEDZIALNOŚĆ: transakcja z dostawcą, co do którego zachodzi wiedza o nieuczciwości (lub cena rażąco odbiega od rynku). Nabywca odpowiada za VAT dostawcy."]
} {
    object.get(input.jdg_entrepreneur, "vat_fraud_check", false) == true
    solidary_basis != ""
}

solidary_basis := "KNOWLEDGE_OF_FRAUD" {
    object.get(input.jdg_entrepreneur, "had_knowledge_of_fraud", false) == true
} else := "PRICE_GROSSLY_BELOW_MARKET" {
    object.get(input.invoice, "price_below_market_pct", 0) >= 50
} else := "FRAUD_GRAPH" {
    object.get(input.invoice, "is_fraud_graph_match", false) == true
} else := "" {
    true
}

# ── DECYZJA: RAPORT FRAUD DETECTION ──────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.vat_fraud_detection.report",
    "package": "jdg.vat_fraud_detection",
    "priority": 500,
    "fraud_audit": {
        "counterparty_score": counterparty_risk_score,
        "transaction_score": transaction_risk_score,
        "overall_level": fraud_score_decision,
        "empty_invoice_signals": empty_invoice_signals,
        "carousel_signals": carousel_signals,
        "vanishing_signals": vanishing_signals,
        "solidary_basis": solidary_basis
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport fraud detection VAT (Sekcja 6 P03) — scoring per kontrahent i transakcja",
    "_legal_basis": "Art. 105a-105c VAT + P03 Sekcja 6",
    "_warnings": [sprintf("Fraud: kontrahent %d/100, transakcja %d/100, poziom %s", [counterparty_risk_score, transaction_risk_score, fraud_score_decision])]
} {
    object.get(input.jdg_entrepreneur, "vat_fraud_check", false) == true
}
