# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR Obligation Layer: Art. 2–10 Ustawy o rachunkowości
# Package: jdg.uor.obligation — Full Accounting Obligation Rules
# Version: 1.0.0 — Q3 2026 Critical Closure (P28 Grand Finale)
# Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)
# Coverage: Art. 2–10 — ~40 rules, ~40 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.obligation

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.uor.obligation.no_match",
    "package": "jdg.uor.obligation",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 2 — Zakres podmiotowy / Próg 2M EUR (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# a2.r1: Przekroczenie progu 2M EUR — obowiązek przejścia na pełną księgowość
decide := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r1",
    "package": "jdg.uor.obligation",
    "priority": 100001,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczenie 2M EUR — OBOWIĄZEK pełnej księgowości od następnego roku obrotowego!",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[UoR] Art.2: Przekroczono próg 2 000 000 EUR. Pełna księgowość obowiązkowa od 01.01 następnego roku. Zgłoś NIP-2!"],
    "threshold_eur": 2000000,
    "mandatory_uor": true
} {
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    annual_revenue_eur := annual_revenue_pln / eur_rate
    currently_uses_pkpir := object.get(input.jdg_entrepreneur, "uses_uor", false) == false
    annual_revenue_eur >= 2000000
    currently_uses_pkpir
}

# a2.r2: Poniżej progu — PKPiR wystarczająca
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r2",
    "package": "jdg.uor.obligation",
    "priority": 100002,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 UoR; Art. 24a PIT",
    "_warnings": ["[UoR] Art.2: Przychód poniżej 2M EUR — PKPiR wystarczająca"],
    "pkpir_allowed": true
} {
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    annual_revenue_eur := annual_revenue_pln / eur_rate
    annual_revenue_eur < 2000000
}

# a2.r3: Dobrowolne przejście na UoR
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r3",
    "package": "jdg.uor.obligation",
    "priority": 100003,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 UoR",
    "_warnings": ["[UoR] Art.2: Dobrowolne przejście na pełną księgowość — decyzja strategiczna"],
    "voluntary_uor": true
} {
    object.get(input.jdg_entrepreneur, "uor_voluntary_choice", false) == true
}

# a2.r4: Grupa kapitałowa — obowiązek UoR bez względu na przychód
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r4",
    "package": "jdg.uor.obligation",
    "priority": 100004,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "JDG w grupie kapitałowej — OBOWIĄZKOWA pełna księgowość niezależnie od przychodu!",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 w zw. z Art. 3 ust. 1 pkt 44 UoR",
    "_warnings": ["[UoR] Art.2: Grupa kapitałowa → pełna księgowość BEZ WZGLĘDU na przychód!"],
    "capital_group_mandatory": true
} {
    object.get(input.jdg_entrepreneur, "in_capital_group", false) == true
}

# a2.r5: Sprawdzenie statusu UoR — NIP-2 złożony
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r5",
    "package": "jdg.uor.obligation",
    "priority": 100005,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "UoR deklarowane ale brak potwierdzenia NIP-2 w US!",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 UoR; Art. 5 ust. 5a Ustawy o NIP",
    "_warnings": ["[UoR] Art.2: JDG deklaruje UoR, ale czy złożono NIP-2? Sprawdź status w CEIDG!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "nip2_submitted", true) == false
}

# a2.r6: Kurs EUR/PLN do przeliczenia progu
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r6",
    "package": "jdg.uor.obligation",
    "priority": 100006,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 ust. 4 UoR",
    "_warnings": ["[UoR] Art.2: Kurs EUR/PLN — średni kurs NBP z 30 września roku poprzedzającego rok obrotowy"],
    "rate_date": "NBP 30.09 roku poprzedzającego"
} {
    true
}

# a2.r7: Monitorowanie Q2 — 50% progu
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r7",
    "package": "jdg.uor.obligation",
    "priority": 100007,
    "_routing": "WARNING",
    "_routing_reason": "Przychód narastająco >50% progu 2M EUR — przygotuj strategię przejścia na UoR",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 UoR",
    "_warnings": ["[UoR] Art.2: ⚠️ EARLY WARNING Q2 — narastająco >50% progu"],
    "early_warning_pct": 50
} {
    q1 := object.get(input.jdg_entrepreneur, "revenue_q1", 0)
    q2 := object.get(input.jdg_entrepreneur, "revenue_q2", 0)
    cumulative := q1 + q2
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    cumulative_eur := cumulative / eur_rate
    cumulative_eur >= 1000000
    cumulative_eur < 2000000
}

# a2.r8: Monitorowanie Q3 — 75% progu
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r8",
    "package": "jdg.uor.obligation",
    "priority": 100008,
    "_routing": "WARNING",
    "_routing_reason": "Przychód narastająco ≥75% progu — przejście na UoR prawdopodobne!",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 UoR",
    "_warnings": ["[UoR] Art.2: ⚠️ CRITICAL Q3 — ≥75% progu 2M EUR. Przygotuj remanent likwidacyjny!"],
    "early_warning_pct": 75
} {
    q1 := object.get(input.jdg_entrepreneur, "revenue_q1", 0)
    q2 := object.get(input.jdg_entrepreneur, "revenue_q2", 0)
    q3 := object.get(input.jdg_entrepreneur, "revenue_q3", 0)
    cumulative := q1 + q2 + q3
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    cumulative_eur := cumulative / eur_rate
    cumulative_eur >= 1500000
    cumulative_eur < 2000000
}

# a2.r9: Mały podatnik UoR — uproszczenia
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r9",
    "package": "jdg.uor.obligation",
    "priority": 100009,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 ust. 3; Art. 3 ust. 1c UoR",
    "_warnings": ["[UoR] Art.2: Status małego podatnika UoR — możliwe uproszczenia księgowe"],
    "small_taxpayer_uor": true,
    "simplifications_available": ["brak_obowiązku_badania", "uproszczone_sprawozdanie", "uproszczona_amortyzacja"]
} {
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    annual_revenue_eur := annual_revenue_pln / eur_rate
    annual_revenue_eur < 2000000
    annual_revenue_eur > 0
}

# a2.r10: Obowiązek badania sprawozdania
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a2.r10",
    "package": "jdg.uor.obligation",
    "priority": 100010,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczono próg badania sprawozdania — OBOWIĄZKOWY audyt!",
    "_legal_basis": "Art. 64 ust. 1 UoR",
    "_warnings": ["[UoR] Art.2: Przekroczono 2 z 3 progów badania — sprawozdanie MUSI być zbadane przez biegłego rewidenta!"],
    "audit_mandatory": true,
    "audit_thresholds": {"total_assets_eur": 2500000, "revenue_eur": 5000000, "employees": 50}
} {
    uses_uor := object.get(input.jdg_entrepreneur, "uses_uor", false)
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets_pln", 0)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    avg_employees := object.get(input.jdg_entrepreneur, "avg_employees_year", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    thresholds_exceeded :=
        count({"assets" | total_assets / eur_rate >= 2500000}) +
        count({"revenue" | annual_revenue / eur_rate >= 5000000}) +
        count({"employees" | avg_employees >= 50})
    uses_uor
    thresholds_exceeded >= 2
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 4 — Fundamentalne zasady rachunkowości (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# a4.r1: Zasada memoriałowa
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a4.r1",
    "package": "jdg.uor.obligation",
    "priority": 100011,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Naruszenie zasady memoriałowej — stosowana metoda kasowa!",
    "_legal_basis": "Art. 4 ust. 1 pkt 1 UoR",
    "_warnings": ["[UoR] Art.4: ZASADA MEMORIAŁOWA — przychody i koszty w okresie którego dotyczą!"],
    "principle": "accrual",
    "violation": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_uses_cash_method", false) == true
}

# a4.r2: Zasada współmierności
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a4.r2",
    "package": "jdg.uor.obligation",
    "priority": 100012,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Koszty nieprzypisane do właściwego okresu — naruszenie zasady współmierności!",
    "_legal_basis": "Art. 4 ust. 1 pkt 2 UoR",
    "_warnings": ["[UoR] Art.4: ZASADA WSPÓŁMIERNOŚCI — koszty muszą być współmierne do przychodów okresu!"],
    "principle": "matching",
    "violation": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_cost_revenue_mismatch", false) == true
}

# a4.r3: Zasada ostrożności — aktywa nie zawyżone
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a4.r3",
    "package": "jdg.uor.obligation",
    "priority": 100013,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Naruszenie zasady ostrożności — aktywa mogą być zawyżone!",
    "_legal_basis": "Art. 4 ust. 1 pkt 3 UoR",
    "_warnings": ["[UoR] Art.4: ZASADA OSTROŻNOŚCI — utwórz rezerwy na znane ryzyka, nie zawyżaj aktywów!"],
    "principle": "prudence",
    "violation": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_assets_overstated", false) == true
}

# a4.r4: Zasada ciągłości
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a4.r4",
    "package": "jdg.uor.obligation",
    "priority": 100014,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Zasada ciągłości zagrożona — jednostka może nie kontynuować działalności!",
    "_legal_basis": "Art. 4 ust. 1 pkt 4 UoR",
    "_warnings": ["[UoR] Art.4: ZASADA CIĄGŁOŚCI zagrożona! Oceń kontynuację działalności przez >12 mies."],
    "principle": "continuity",
    "violation": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    business_status != "ACTIVE"
    annual_revenue == 0
}

# a4.r5: Zasada istotności
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a4.r5",
    "package": "jdg.uor.obligation",
    "priority": 100015,
    "_routing": "WARNING",
    "_routing_reason": "Pozycja przekracza próg istotności — wymaga osobnej prezentacji!",
    "_legal_basis": "Art. 4 ust. 1 pkt 5; Art. 4a UoR",
    "_warnings": ["[UoR] Art.4: Pozycja ISTOTNA >5% sumy bilansowej — osobna prezentacja w sprawozdaniu!"],
    "principle": "materiality",
    "materiality_pct": 5.0
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    item_value := object.get(input.invoice, "amount_net", 0)
    total_assets > 0
    item_value > total_assets * 0.05
}

# a4.r6: Zasada przewagi treści nad formą
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a4.r6",
    "package": "jdg.uor.obligation",
    "priority": 100016,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Forma prawna transakcji może nie odzwierciedlać treści ekonomicznej!",
    "_legal_basis": "Art. 4 ust. 1 pkt 6 UoR",
    "_warnings": ["[UoR] Art.4: PRZEWAGA TREŚCI NAD FORMĄ — substancja ekonomiczna > forma prawna!"],
    "principle": "substance_over_form",
    "violation": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "substance_differs_from_form", false) == true
}

# a4.r7: Zasada memoriałowa — przychód w niewłaściwym okresie
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a4.r7",
    "package": "jdg.uor.obligation",
    "priority": 100017,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Przychód zaksięgowany w niewłaściwym okresie sprawozdawczym!",
    "_legal_basis": "Art. 4 ust. 1 pkt 1 UoR",
    "_warnings": ["[UoR] Art.4: Przychód w złym okresie — zasada memoriałowa wymaga korekty!"],
    "principle": "accrual_revenue"
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    invoice_month := object.get(input.invoice, "transaction_month", 0)
    service_month := object.get(input.invoice, "service_period_month", 0)
    invoice_month != service_month
    service_month > 0
}

# a4.r8: Zasada ostrożności — brak rezerwy
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a4.r8",
    "package": "jdg.uor.obligation",
    "priority": 100018,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Znane ryzyko bez rezerwy — naruszenie zasady ostrożności!",
    "_legal_basis": "Art. 4 ust. 1 pkt 3 UoR; KSR 6",
    "_warnings": ["[UoR] Art.4: Brak rezerwy na znane ryzyko — utwórz rezerwę!"],
    "principle": "prudence_provisions"
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    has_known_risk := object.get(input.jdg_entrepreneur, "uor_known_risk_exists", false)
    has_provision := object.get(input.jdg_entrepreneur, "uor_provision_created", false)
    has_known_risk
    not has_provision
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 5 — True & Fair View (4 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# a5.r1: True & Fair View — fundament
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a5.r1",
    "package": "jdg.uor.obligation",
    "priority": 100019,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 UoR",
    "_warnings": ["[UoR] Art.5: TRUE & FAIR VIEW — rzetelny i jasny obraz sytuacji majątkowej i finansowej"],
    "standard": "TRUE_AND_FAIR_VIEW"
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# a5.r2: True & Fair View — naruszenie
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a5.r2",
    "package": "jdg.uor.obligation",
    "priority": 100020,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "TRUE & FAIR VIEW NARUSZONE — istotne zniekształcenie! Ryzyko Art. 77 UoR!",
    "_legal_basis": "Art. 5 ust. 1; Art. 77 UoR",
    "_warnings": ["[UoR] Art.5: ❌ TRUE & FAIR VIEW NARUSZONE — odpowiedzialność karna (Art. 77 UoR)!"],
    "criminal_risk": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_material_misstatement", false) == true
}

# a5.r3: True & Fair View — stronnicza wycena
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a5.r3",
    "package": "jdg.uor.obligation",
    "priority": 100021,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Stronnicza wycena — naruszenie True & Fair View!",
    "_legal_basis": "Art. 5 ust. 1 UoR",
    "_warnings": ["[UoR] Art.5: Stronnicza wycena aktywów/pasywów!"],
    "biased_valuation": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_biased_valuation", false) == true
}

# a5.r4: True & Fair View — ukryte zobowiązania
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a5.r4",
    "package": "jdg.uor.obligation",
    "priority": 100022,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ukryte zobowiązania pozabilansowe — naruszenie True & Fair View!",
    "_legal_basis": "Art. 5 ust. 1 UoR",
    "_warnings": ["[UoR] Art.5: Ukryte zobowiązania pozabilansowe!"],
    "hidden_liabilities": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_hidden_liabilities", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 8-10 — Polityka rachunkowości (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# a8.r1: Miejsce prowadzenia ksiąg — siedziba jednostki
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a8.r1",
    "package": "jdg.uor.obligation",
    "priority": 100023,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 1 UoR",
    "_warnings": ["[UoR] Art.8: Księgi rachunkowe prowadzi się w siedzibie jednostki (lub w oddziale / powierzonym biurze)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# a8.r2: Powierzenie ksiąg biuru rachunkowemu
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a8.r2",
    "package": "jdg.uor.obligation",
    "priority": 100024,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 8 ust. 2 UoR",
    "_warnings": ["[UoR] Art.8: Księgi powierzone biuru rachunkowemu — wymagana umowa pisemna + zgłoszenie do US (NIP-2)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_outsourced", false) == true
}

# a9.r1: Język i waluta — PLN, język polski
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a9.r1",
    "package": "jdg.uor.obligation",
    "priority": 100025,
    "_routing": "WARNING",
    "_routing_reason": "Księgi prowadzone w walucie obcej — wymagane dodatkowe przeliczenia!",
    "_legal_basis": "Art. 9 UoR",
    "_warnings": ["[UoR] Art.9: Księgi w PLN i języku polskim. Waluta obca wymaga przeliczenia wg Art. 30."]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_currency", "PLN") != "PLN"
}

# a10.r1: Obowiązek posiadania polityki rachunkowości
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a10.r1",
    "package": "jdg.uor.obligation",
    "priority": 100026,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "BRAK polityki rachunkowości — OBOWIĄZKOWA dla jednostek stosujących UoR!",
    "_legal_basis": "Art. 10 ust. 1 UoR",
    "_warnings": ["[UoR] Art.10: Polityka rachunkowości OBOWIĄZKOWA — dokument przyjętych zasad!"],
    "missing_policy": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_accounting_policy_exists", true) == false
}

# a10.r2: Polityka — metoda amortyzacji
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a10.r2",
    "package": "jdg.uor.obligation",
    "priority": 100027,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1 pkt 1; Art. 32 UoR",
    "_warnings": ["[UoR] Art.10: Polityka: metoda amortyzacji (liniowa/degresywna/naturalna)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
}

# a10.r3: Polityka — metoda wyceny zapasów
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a10.r3",
    "package": "jdg.uor.obligation",
    "priority": 100028,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1 pkt 2; Art. 28 ust. 1 pkt 6 UoR",
    "_warnings": ["[UoR] Art.10: Polityka: metoda wyceny zapasów (FIFO/LIFO/średnia ważona/ceny stałe)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_inventory", false) == true
}

# a10.r4: Polityka — próg istotności
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a10.r4",
    "package": "jdg.uor.obligation",
    "priority": 100029,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1 pkt 4; Art. 4 ust. 1 pkt 5 UoR",
    "_warnings": ["[UoR] Art.10: Polityka: próg istotności (4-5% sumy bilansowej wg KSR 2)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# a10.r5: Polityka — wariant RZiS
else := {
    "matched": true,
    "rule_id": "jdg.uor.obligation.a10.r5",
    "package": "jdg.uor.obligation",
    "priority": 100030,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1 pkt 3; Art. 47 UoR",
    "_warnings": ["[UoR] Art.10: Polityka: wariant RZiS (porównawczy lub kalkulacyjny)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}
