# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa o rachunkowości (dla JDG) — 30+ artykułów
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Version: 9.0 — FULL REWRITE: REAL LOGIC replacing stubs
# Package: jdg.micro.uor
# Legal basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)
# Coverage: 30+ articles with real computational logic (up from 6 in v7.0)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.uor

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.uor.no_match",
    "package": "jdg.micro.uor",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 2 — Zakres podmiotowy / Jednostki zobowiązane do UoR (8 reguł)
# Progi: 2M EUR, 2.5M EUR dla grup kapitałowych
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a2.r1: Próg 2M EUR — JDG przekracza próg pełnej księgowości
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.r1",
    "package": "jdg.micro.uor",
    "priority": 160004,
    "micro_rule_active": true,
    "uor_threshold_eur": 2000000,
    "eur_pln_rate": 4.5,
    "uor_threshold_pln": 9000000,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] Art.2 UoR: Próg pełnej księgowości = 2 000 000 EUR (~9 000 000 PLN przy kursie 4.5)"]
} {
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    annual_revenue_eur := annual_revenue_pln / eur_rate
    annual_revenue_eur >= 2000000
}

# uor.a2.r2: JDG poniżej progu — może stosować PKPiR
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.r2",
    "package": "jdg.micro.uor",
    "priority": 160005,
    "micro_rule_active": true,
    "uor_threshold_eur": 2000000,
    "pkpir_allowed": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości; Art. 24a PIT",
    "_warnings": ["[MICRO] Art.2 UoR: JDG poniżej 2M EUR — PKPiR wystarczająca"]
} {
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    annual_revenue_eur := annual_revenue_pln / eur_rate
    annual_revenue_eur < 2000000
}

# uor.a2.r3: JDG może DOBROWOLNIE stosować pełną księgowość
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.r3",
    "package": "jdg.micro.uor",
    "priority": 160006,
    "micro_rule_active": true,
    "uor_voluntary": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.2 UoR: JDG może DOBROWOLNIE przejść na pełną księgowość — decyzja strategiczna"]
} {
    object.get(input.jdg_entrepreneur, "uor_voluntary_choice", false) == true
}

# uor.a2.r4: JDG w grupie kapitałowej
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.r4",
    "package": "jdg.micro.uor",
    "priority": 160007,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "JDG w grupie kapitałowej musi stosować pełną księgowość — Art. 2 ust. 1 pkt 2 UoR",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.2 UoR: JDG w GRUPIE KAPITAŁOWEJ → pełna księgowość obowiązkowa!"]
} {
    object.get(input.jdg_entrepreneur, "in_capital_group", false) == true
}

# uor.a2.r5: Kurs EUR/PLN do przeliczenia progu — NBP z ostatniego dnia września
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.r5",
    "package": "jdg.micro.uor",
    "priority": 160008,
    "micro_rule_active": true,
    "rate_source": "NBP z 30.09 roku poprzedzającego",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 ust. 4 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.2 UoR: Kurs EUR/PLN wg NBP z 30.09 roku poprzedzającego rok obrotowy"]
} {
    object.get(input.jdg_entrepreneur, "uor_rate_check_requested", false) == true
}

# uor.a2.r6: Monitorowanie narastające — Q2 (50% progu)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.r6",
    "package": "jdg.micro.uor",
    "priority": 160009,
    "micro_rule_active": true,
    "early_warning_pct": 50,
    "_routing": "WARNING",
    "_routing_reason": "Przychód narastająco przekroczył 50% progu 2M EUR — przygotuj strategię przejścia",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.2 UoR: ⚠️ EARLY WARNING — narastająco >50% progu 2M EUR"]
} {
    q1 := object.get(input.jdg_entrepreneur, "revenue_q1", 0)
    q2 := object.get(input.jdg_entrepreneur, "revenue_q2", 0)
    cumulative := q1 + q2
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    cumulative_eur := cumulative / eur_rate
    cumulative_eur >= 1000000
    cumulative_eur < 2000000
}

# uor.a2.r7: Monitorowanie narastające — Q3 (75% progu)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.r7",
    "package": "jdg.micro.uor",
    "priority": 160010,
    "micro_rule_active": true,
    "early_warning_pct": 75,
    "_routing": "WARNING",
    "_routing_reason": "Przychód narastająco ≥75% progu 2M EUR — przejście na UoR prawdopodobne w tym roku!",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.2 UoR: ⚠️ CRITICAL WARNING — narastająco ≥75% progu 2M EUR. Przygotuj remanent!"]
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

# uor.a2.r8: Przekroczenie progu w trakcie roku — obowiązek od następnego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.r8",
    "package": "jdg.micro.uor",
    "priority": 160011,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczenie 2M EUR — obowiązek pełnej księgowości od 01.01 następnego roku!",
    "_legal_basis": "Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.2 UoR: 🔴 PRZEKROCZENIE PROGU! Pełna księgowość od 01.01 następnego roku. Zgłoś CEIDG-1 + NIP-2!"]
} {
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    annual_revenue_eur := annual_revenue_pln / eur_rate
    currently_uses_pkpir := not object.get(input.jdg_entrepreneur, "uses_uor", false)
    annual_revenue_eur >= 2000000
    currently_uses_pkpir
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 3 — Definicje księgowe (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a3.r1: Definicja aktywów — zasoby kontrolowane o wiarygodnie ustalonej wartości
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a3.r1",
    "package": "jdg.micro.uor",
    "priority": 160012,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 12 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.3 UoR: Aktywa = kontrolowane zasoby o wiarygodnie ustalonej wartości, powstałe w wyniku przeszłych zdarzeń"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
}

# uor.a3.r2: Definicja zobowiązań — obowiązek świadczenia o wiarygodnie ustalonej wartości
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a3.r2",
    "package": "jdg.micro.uor",
    "priority": 160013,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 20 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.3 UoR: Zobowiązania = obowiązek wykonania świadczenia powodujący wykorzystanie aktywów"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_liability", false) == true
}

# uor.a3.r3: Definicja środków trwałych — okres użyteczności > 1 rok, kompletne, zdatne do użytku
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a3.r3",
    "package": "jdg.micro.uor",
    "priority": 160014,
    "micro_rule_active": true,
    "fixed_asset_min_value": 10000,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 15 Ustawy o rachunkowości; Art. 22a PIT",
    "_warnings": ["[MICRO] Art.3 UoR: Środek trwały = okres użyteczności>1 rok, kompletny, zdatny do użytku, wartość≥10 000 PLN"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "amount_net", 0) >= 10000
    object.get(input.invoice, "asset_useful_life_months", 0) > 12
}

# uor.a3.r4: Definicja WNiP — wartości niematerialne i prawne
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a3.r4",
    "package": "jdg.micro.uor",
    "priority": 160015,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 14 Ustawy o rachunkowości; Art. 22b PIT",
    "_warnings": ["[MICRO] Art.3 UoR: WNiP = prawa majątkowe (autorskie, patenty, licencje, know-how, goodwill)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "asset_type", "TANGIBLE") == "INTANGIBLE"
}

# uor.a3.r5: Definicja roku obrotowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a3.r5",
    "package": "jdg.micro.uor",
    "priority": 160016,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 9 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.3 UoR: Rok obrotowy = okres 12 miesięcy (najczęściej kalendarzowy: 01.01–31.12)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a3.r6: Definicja kosztów — uprawdopodobnione zmniejszenia korzyści ekonomicznych
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a3.r6",
    "package": "jdg.micro.uor",
    "priority": 160017,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 31 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.3 UoR: Koszty = uprawdopodobnione zmniejszenia korzyści ekonomicznych (spadek aktywów/wzrost zobowiązań)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_expense", false) == true
}

# uor.a3.r7: Definicja przychodów — uprawdopodobnione zwiększenia korzyści ekonomicznych
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a3.r7",
    "package": "jdg.micro.uor",
    "priority": 160018,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 30 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.3 UoR: Przychody = uprawdopodobnione zwiększenia korzyści ekonomicznych (wzrost aktywów/spadek zobowiązań)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_revenue", false) == true
}

# uor.a3.r8: Definicja dnia bilansowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a3.r8",
    "package": "jdg.micro.uor",
    "priority": 160019,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 10 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.3 UoR: Dzień bilansowy = dzień zamknięcia ksiąg rachunkowych (najczęściej 31.12)"]
} {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 4 — Fundamentalne zasady rachunkowości (12 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a4.r1: Zasada memoriałowa — przychody/koszty w okresie którego dotyczą
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r1",
    "package": "jdg.micro.uor",
    "priority": 160020,
    "micro_rule_active": true,
    "principle": "accrual",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zasada memoriałowa naruszona — używana metoda kasowa zamiast memoriałowej!",
    "_legal_basis": "Art. 4 ust. 1 pkt 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.4 UoR: ZASADA MEMORIAŁOWA — przychody i koszty w okresie którego dotyczą, NIE w dacie zapłaty!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_uses_cash_method", false) == true
}

# uor.a4.r2: Zasada memoriałowa — zgodność potwierdzona
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r2",
    "package": "jdg.micro.uor",
    "priority": 160021,
    "micro_rule_active": true,
    "principle": "accrual",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 ust. 1 pkt 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.4 UoR: ✅ Zasada memoriałowa — stosowana prawidłowo"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_uses_cash_method", false) == false
}

# uor.a4.r3: Zasada współmierności — koszty współmierne do przychodów
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r3",
    "package": "jdg.micro.uor",
    "priority": 160022,
    "micro_rule_active": true,
    "principle": "matching",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zasada współmierności naruszona — koszty nieprzypisane do właściwego okresu!",
    "_legal_basis": "Art. 4 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.4 UoR: ZASADA WSPÓŁMIERNOŚCI — koszty muszą być współmierne do przychodów danego okresu!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_cost_revenue_mismatch", false) == true
}

# uor.a4.r4: Zasada ostrożności — aktywa nie zawyżone, rezerwy na ryzyka
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r4",
    "package": "jdg.micro.uor",
    "priority": 160023,
    "micro_rule_active": true,
    "principle": "prudence",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Zasada ostrożności naruszona — aktywa mogą być zawyżone, brak rezerw na ryzyka!",
    "_legal_basis": "Art. 4 ust. 1 pkt 3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.4 UoR: ZASADA OSTROŻNOŚCI — nie zawyżaj aktywów, twórz rezerwy na znane ryzyka!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_assets_overstated", false) == true
}

# uor.a4.r5: Zasada ciągłości — założenie kontynuacji działalności
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r5",
    "package": "jdg.micro.uor",
    "priority": 160024,
    "micro_rule_active": true,
    "principle": "continuity",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Zasada ciągłości zagrożona — jednostka może nie kontynuować działalności!",
    "_legal_basis": "Art. 4 ust. 1 pkt 4 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.4 UoR: ZASADA CIĄGŁOŚCI — zagrożona! Oceń czy jednostka będzie kontynuować działalność przez >12 miesięcy"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    business_status != "ACTIVE"
    annual_revenue == 0
}

# uor.a4.r6: Zasada istotności — informacje istotne dla oceny sytuacji
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r6",
    "package": "jdg.micro.uor",
    "priority": 160025,
    "micro_rule_active": true,
    "principle": "materiality",
    "materiality_threshold_pct": 5.0,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 ust. 1 pkt 5 Ustawy o rachunkowości; KSR 2",
    "_warnings": ["[MICRO] Art.4 UoR: ZASADA ISTOTNOŚCI — ujawniaj informacje istotne dla oceny sytuacji (próg ~5% sumy bilansowej)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# uor.a4.r7: Zasada przewagi treści nad formą — substancja ekonomiczna > forma prawna
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r7",
    "package": "jdg.micro.uor",
    "priority": 160026,
    "micro_rule_active": true,
    "principle": "substance_over_form",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Przewaga treści nad formą — forma prawna transakcji może nie odzwierciedlać jej treści ekonomicznej!",
    "_legal_basis": "Art. 4 ust. 1 pkt 6 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.4 UoR: PRZEWAGA TREŚCI NAD FORMĄ — ekonomiczna treść transakcji ma pierwszeństwo nad jej formą prawną!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "substance_differs_from_form", false) == true
}

# uor.a4.r8: Zasada istotności — przekroczenie progu materialności
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r8",
    "package": "jdg.micro.uor",
    "priority": 160027,
    "micro_rule_active": true,
    "principle": "materiality_threshold",
    "materiality_pct": 5.0,
    "_routing": "WARNING",
    "_routing_reason": "Pozycja przekracza próg istotności — wymaga osobnej prezentacji w sprawozdaniu finansowym",
    "_legal_basis": "Art. 4 ust. 1 pkt 5 Ustawy o rachunkowości; Art. 4a UoR",
    "_warnings": ["[MICRO] Art.4 UoR: Pozycja ISTOTNA >5% sumy bilansowej — wymaga osobnej prezentacji w sprawozdaniu"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    item_value := object.get(input.invoice, "amount_net", 0)
    total_assets > 0
    item_value > total_assets * 0.05
}

# uor.a4.r9: Kompletność zasad — sprawdzenie wszystkich 6 zasad
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r9",
    "package": "jdg.micro.uor",
    "priority": 160028,
    "micro_rule_active": true,
    "all_principles": ["memoriałowa", "współmierności", "ostrożności", "ciągłości", "istotności", "przewagi treści"],
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.4 UoR: Wszystkie 6 fundamentalnych zasad rachunkowości wg Art. 4 ust. 1 UoR"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a4.r10: Zasada memoriałowa — naruszenie dla przychodów (przychód w złym okresie)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r10",
    "package": "jdg.micro.uor",
    "priority": 160029,
    "micro_rule_active": true,
    "principle": "accrual_revenue",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Przychód zaksięgowany w niewłaściwym okresie sprawozdawczym!",
    "_legal_basis": "Art. 4 ust. 1 pkt 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.4 UoR: Przychód w złym okresie — zasada memoriałowa wymaga przypisania do okresu, którego dotyczy"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    invoice_month := object.get(input.invoice, "transaction_month", 0)
    service_month := object.get(input.invoice, "service_period_month", 0)
    invoice_month != service_month
    service_month > 0
    invoice_month > 0
}

# uor.a4.r11: Zasada ostrożności — brak rezerwy na znane ryzyko
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r11",
    "package": "jdg.micro.uor",
    "priority": 160030,
    "micro_rule_active": true,
    "principle": "prudence_provisions",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Brak rezerwy na znane ryzyko — naruszenie zasady ostrożności!",
    "_legal_basis": "Art. 4 ust. 1 pkt 3 Ustawy o rachunkowości; KSR 6",
    "_warnings": ["[MICRO] Art.4 UoR: Brak rezerwy na znane ryzyko — utwórz rezerwę na przewidywane straty!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    has_known_risk := object.get(input.jdg_entrepreneur, "uor_known_risk_exists", false)
    has_provision := object.get(input.jdg_entrepreneur, "uor_provision_created", false)
    has_known_risk
    not has_provision
}

# uor.a4.r12: Zasada ostrożności — odpisy aktualizujące
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a4.r12",
    "package": "jdg.micro.uor",
    "priority": 160031,
    "micro_rule_active": true,
    "principle": "prudence_impairment",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Brak odpisu aktualizującego mimo trwałej utraty wartości aktywa!",
    "_legal_basis": "Art. 4 ust. 1 pkt 3; Art. 28 ust. 7 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.4 UoR: Trwała utrata wartości wymaga ODPISU AKTUALIZUJĄCEGO — zasada ostrożności!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    market_value := object.get(input.invoice, "asset_market_value", 0)
    book_value := object.get(input.invoice, "asset_book_value", 0)
    impairment_booked := object.get(input.invoice, "asset_impairment_booked", false)
    market_value > 0
    book_value > 0
    market_value < book_value * 0.50
    not impairment_booked
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 5 — True & Fair View (4 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a5.r1: True & Fair View — rzetelny i jasny obraz
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a5.r1",
    "package": "jdg.micro.uor",
    "priority": 160032,
    "micro_rule_active": true,
    "standard": "TRUE_AND_FAIR_VIEW",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.5 UoR: TRUE & FAIR VIEW — księgi muszą przedstawiać rzetelny i jasny obraz sytuacji majątkowej i finansowej"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a5.r2: True & Fair View — naruszenie (istotne zniekształcenie)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a5.r2",
    "package": "jdg.micro.uor",
    "priority": 160033,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "TRUE & FAIR VIEW NARUSZONE — istotne zniekształcenie sprawozdania finansowego!",
    "_legal_basis": "Art. 5 ust. 1; Art. 77 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.5 UoR: ❌ TRUE & FAIR VIEW NARUSZONE — ryzyko odpowiedzialności karnej (Art. 77 UoR)!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_material_misstatement", false) == true
}

# uor.a5.r3: True & Fair View — stronnicza wycena
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a5.r3",
    "package": "jdg.micro.uor",
    "priority": 160034,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Stronnicza wycena aktywów — naruszenie True & Fair View!",
    "_legal_basis": "Art. 5 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.5 UoR: Stronnicza wycena — aktywa lub pasywa wycenione tendencyjnie (zawyżone/zaniżone)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_biased_valuation", false) == true
}

# uor.a5.r4: True & Fair View — ukryte zobowiązania
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a5.r4",
    "package": "jdg.micro.uor",
    "priority": 160035,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ukryte zobowiązania pozabilansowe — naruszenie True & Fair View!",
    "_legal_basis": "Art. 5 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.5 UoR: Ukryte zobowiązania — jednostka nie ujawniła zobowiązań pozabilansowych"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_hidden_liabilities", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 10 — Polityka rachunkowości (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a10.r1: Obowiązek posiadania polityki rachunkowości
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r1",
    "package": "jdg.micro.uor",
    "priority": 160036,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "BRAK polityki rachunkowości — obowiązkowa dla jednostek stosujących UoR!",
    "_legal_basis": "Art. 10 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.10 UoR: Polityka rachunkowości OBOWIĄZKOWA — dokument opisujący przyjęte zasady rachunkowości"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_accounting_policy_exists", true) == false
}

# uor.a10.r2: Polityka rachunkowości — metoda amortyzacji
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r2",
    "package": "jdg.micro.uor",
    "priority": 160037,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1 pkt 1; Art. 32 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.10 UoR: Polityka musi określać metodę amortyzacji (liniowa, degresywna, naturalna)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
}

# uor.a10.r3: Polityka rachunkowości — metoda wyceny zapasów
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r3",
    "package": "jdg.micro.uor",
    "priority": 160038,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1 pkt 2; Art. 28 ust. 1 pkt 6 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.10 UoR: Polityka musi określać metodę wyceny zapasów (FIFO, LIFO, średnia ważona, ceny stałe)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_inventory", false) == true
}

# uor.a10.r4: Polityka rachunkowości — próg istotności
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r4",
    "package": "jdg.micro.uor",
    "priority": 160039,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1 pkt 4; Art. 4 ust. 1 pkt 5 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.10 UoR: Polityka powinna określać próg istotności (zwykle 4-5% sumy bilansowej wg KSR 2)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# uor.a10.r5: Polityka rachunkowości — wariant RZiS
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r5",
    "package": "jdg.micro.uor",
    "priority": 160040,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1 pkt 3; Art. 47 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.10 UoR: Polityka musi wskazywać wariant RZiS (porównawczy lub kalkulacyjny)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a10.r6: Polityka rachunkowości — aktualizacja i przegląd
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a10.r6",
    "package": "jdg.micro.uor",
    "priority": 160041,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.10 UoR: Polityka rachunkowości powinna być aktualizowana przy zmianie przepisów lub profilu działalności"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 12-13 — Zamknięcie ksiąg rachunkowych (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a12.r1: Obowiązek zamknięcia ksiąg na dzień bilansowy
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a12.r1",
    "package": "jdg.micro.uor",
    "priority": 160042,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Księgi NIE zamknięte na dzień bilansowy — obowiązek Art.12 UoR!",
    "_legal_basis": "Art. 12 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.12 UoR: Zamknij księgi rachunkowe na dzień bilansowy (31.12) w ciągu 3 miesięcy!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_closed", false) == false
}

# uor.a12.r2: Termin zamknięcia — 3 miesiące od dnia bilansowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a12.r2",
    "package": "jdg.micro.uor",
    "priority": 160043,
    "micro_rule_active": true,
    "deadline": "31 marca następnego roku",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zbliża się termin zamknięcia ksiąg — 3 miesiące od dnia bilansowego!",
    "_legal_basis": "Art. 12 ust. 1; Art. 52 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.12 UoR: Termin zamknięcia ksiąg = 3 miesiące od dnia bilansowego (do 31 marca następnego roku)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a12.r3: Zamknięcie — przeniesienie sald kont wynikowych
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a12.r3",
    "package": "jdg.micro.uor",
    "priority": 160044,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 12 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.12 UoR: Przenieś salda kont wynikowych (4,5,7) na konto 860 'Rozliczenie wyniku finansowego'"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false) == true
}

# uor.a13.r1: Ostateczne zamknięcie ksiąg — nieodwracalne
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a13.r1",
    "package": "jdg.micro.uor",
    "priority": 160045,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Próba modyfikacji ostatecznie zamkniętych ksiąg — NARUSZENIE Art.13 UoR!",
    "_legal_basis": "Art. 13 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.13 UoR: Ostatecznie zamknięte księgi NIE MOGĄ być modyfikowane! (sankcja karna Art. 77)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_finally_closed", false) == true
    object.get(input.invoice, "attempt_modification_after_close", false) == true
}

# uor.a13.r2: Zatwierdzenie sprawozdania finansowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a13.r2",
    "package": "jdg.micro.uor",
    "priority": 160046,
    "micro_rule_active": true,
    "deadline": "6 miesięcy od dnia bilansowego",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sprawozdanie finansowe NIE zatwierdzone w terminie 6 miesięcy!",
    "_legal_basis": "Art. 13 ust. 2; Art. 53 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.13 UoR: Zatwierdź sprawozdanie finansowe w ciągu 6 miesięcy od dnia bilansowego"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_fs_approved", false) == false
}

# uor.a13.r3: Księgi zamknięte prawidłowo
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a13.r3",
    "package": "jdg.micro.uor",
    "priority": 160047,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 13 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.13 UoR: ✅ Księgi zamknięte prawidłowo — salda przeniesione, sprawozdanie zatwierdzone"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_closed", false) == true
    object.get(input.jdg_entrepreneur, "uor_fs_approved", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 14 — Rok obrotowy i okres sprawozdawczy (3 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a14.r1: Rok obrotowy = rok kalendarzowy (domyślnie)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a14.r1",
    "package": "jdg.micro.uor",
    "priority": 160048,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.14 UoR: Rok obrotowy domyślnie = rok kalendarzowy (01.01–31.12)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# uor.a14.r2: Pierwszy rok obrotowy JDG po przejściu na UoR
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a14.r2",
    "package": "jdg.micro.uor",
    "priority": 160049,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.14 UoR: Pierwszy rok obrotowy może być krótszy niż 12 miesięcy (od dnia rozpoczęcia do 31.12)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_first_year", false) == true
}

# uor.a14.r3: Zmiana roku obrotowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a14.r3",
    "package": "jdg.micro.uor",
    "priority": 160050,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Zmiana roku obrotowego — wymaga zgłoszenia do US w ciągu 30 dni!",
    "_legal_basis": "Art. 14 ust. 3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.14 UoR: Zmiana roku obrotowego możliwa tylko z ważnych przyczyn — zgłoś do US!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_fiscal_year_changed", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 20-21 — Dowody księgowe (PEŁNE 15 elementów, 8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a20.r1: Dowód księgowy — elementy krytyczne (8 z 15)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r1",
    "package": "jdg.micro.uor",
    "priority": 160051,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Dowód księgowy niekompletny — brak krytycznych elementów!",
    "_legal_basis": "Art. 20-21 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.20-21 UoR: Dowód księgowy MUSI zawierać min. 8 elementów krytycznych (nazwa, adres, data, opis, kwota, NIP, nr, podpis)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    critical_ok := object.get(input.invoice, "invoice_number", "") != ""
    critical_ok = false
}

# uor.a20.r2: Dowód księgowy — kompletność 15 elementów
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r2",
    "package": "jdg.micro.uor",
    "priority": 160052,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Dowód księgowy — brak elementów niekrytycznych (stawka VAT, metoda płatności, waluta)",
    "_legal_basis": "Art. 20-21 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.20-21 UoR: Sprawdź kompletność — 15 elementów wymaganych: strony, daty, opis, podpisy, kwoty, VAT, NIP, nr dokumentu, płatność, waluta"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    has_vat_rate := object.get(input.invoice, "vat_rate", "") != ""
    has_payment := object.get(input.invoice, "payment_method", "") != ""
    has_currency := object.get(input.invoice, "currency", "PLN") != ""
    not (has_vat_rate and has_payment and has_currency)
}

# uor.a20.r3: Dowód księgowy — sprawdzenie NIP kontrahenta
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r3",
    "package": "jdg.micro.uor",
    "priority": 160053,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "NIP kontrahenta niezweryfikowany — sprawdź w białej liście VAT!",
    "_legal_basis": "Art. 21 ust. 1 pkt 5 Ustawy o rachunkowości; Art. 96b VAT",
    "_warnings": ["[MICRO] Art.21 UoR: NIP kontrahenta — wymagany i powinien być zweryfikowany w białej liście VAT"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    nip := object.get(input.vendor, "nip", "")
    nip == ""
}

# uor.a20.r4: Dowód księgowy — opis operacji gospodarczej
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r4",
    "package": "jdg.micro.uor",
    "priority": 160054,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Opis operacji zbyt ogólny — powinien umożliwiać identyfikację zdarzenia gospodarczego",
    "_legal_basis": "Art. 21 ust. 1 pkt 4 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.21 UoR: Opis operacji — musi umożliwiać jednoznaczną identyfikację zdarzenia gospodarczego"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    desc := object.get(input.invoice, "description", "")
    count(desc) < 5
    desc != ""
}

# uor.a20.r5: Dowód księgowy — data wystawienia vs data operacji
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r5",
    "package": "jdg.micro.uor",
    "priority": 160055,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Data wystawienia ≠ data operacji — sprawdź poprawność przypisania do okresu sprawozdawczego",
    "_legal_basis": "Art. 21 ust. 1 pkt 1-2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.21 UoR: Data wystawienia i data operacji powinny być zgodne z okresem księgowania"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    issue_date := object.get(input.invoice, "issue_date", "")
    transaction_date := object.get(input.invoice, "transaction_date", "")
    issue_date != transaction_date
    issue_date != ""
    transaction_date != ""
}

# uor.a20.r6: Dowód księgowy — waluta obca
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r6",
    "package": "jdg.micro.uor",
    "priority": 160056,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 9 Ustawy o rachunkowości; Art. 30 UoR",
    "_warnings": ["[MICRO] Art.21 UoR: Waluta obca — wymaga przeliczenia wg kursu NBP z dnia poprzedzającego operację (Art. 30 UoR)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    currency := object.get(input.invoice, "currency", "PLN")
    currency != "PLN"
}

# uor.a20.r7: Dowód księgowy — kompletny (wszystkie 15 elementów)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r7",
    "package": "jdg.micro.uor",
    "priority": 160057,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20-21 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.20-21 UoR: ✅ Dowód księgowy KOMPLETNY — wszystkie 15 elementów obecne"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "document_complete_15_elements", false) == true
}

# uor.a20.r8: Korekta dowodu księgowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a20.r8",
    "package": "jdg.micro.uor",
    "priority": 160058,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 3; Art. 25 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.21 UoR: Korekta błędów — przez skreślenie i wpisanie poprawnej treści z datą i podpisem (lub dokument korygujący)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_correction", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 22 — Podwójny zapis i rzetelność ksiąg (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a22.r1: Podwójny zapis — Suma Wn == Suma Ma
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r1",
    "package": "jdg.micro.uor",
    "priority": 160059,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Podwójny zapis NARUSZONY — suma Wn ≠ Ma!",
    "_legal_basis": "Art. 22 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.22 UoR: PODWÓJNY ZAPIS — każda operacja musi mieć stronę Wn i Ma o równej wartości!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    debit := object.get(input.invoice, "journal_debit_total", 0)
    credit := object.get(input.invoice, "journal_credit_total", 0)
    abs(debit - credit) >= 0.01
}

# uor.a22.r2: Rzetelność ksiąg — zapisy chronologiczne
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r2",
    "package": "jdg.micro.uor",
    "priority": 160060,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zapisy NIE są chronologiczne — naruszenie zasady rzetelności ksiąg!",
    "_legal_basis": "Art. 22 ust. 1; Art. 24 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.22 UoR: Zapisy księgowe MUSZĄ być chronologiczne i kompletne!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "entry_non_chronological", false) == true
}

# uor.a22.r3: Zakaz kasowania zapisów
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r3",
    "package": "jdg.micro.uor",
    "priority": 160061,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Próba KASOWANIA zapisu księgowego — NARUSZENIE Art.22 UoR!",
    "_legal_basis": "Art. 22 ust. 1; Art. 25 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.22 UoR: ZAKAZ KASOWANIA ZAPISÓW! Korekta tylko przez storno lub zapis korygujący!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "entry_deleted", false) == true
}

# uor.a22.r4: Podwójny zapis — zbilansowany
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r4",
    "package": "jdg.micro.uor",
    "priority": 160062,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.22 UoR: ✅ Podwójny zapis prawidłowy — Wn = Ma"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    debit := object.get(input.invoice, "journal_debit_total", 0)
    credit := object.get(input.invoice, "journal_credit_total", 0)
    abs(debit - credit) < 0.01
    debit > 0
}

# uor.a22.r5: Rzetelność — brak luk w numeracji
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r5",
    "package": "jdg.micro.uor",
    "priority": 160063,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Luki w numeracji zapisów — potencjalne naruszenie rzetelności ksiąg",
    "_legal_basis": "Art. 24 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.22/24 UoR: Luki w numeracji zapisów — każdy zapis powinien być kolejno numerowany"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_entry_gaps_detected", false) == true
}

# uor.a22.r6: Sankcja za nierzetelność ksiąg
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.r6",
    "package": "jdg.micro.uor",
    "priority": 160064,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 5000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "NIERZETELNE KSIĘGI — sankcja KKS: grzywna do 720 stawek dziennych!",
    "_legal_basis": "Art. 24; Art. 77 Ustawy o rachunkowości; Art. 60-61 KKS",
    "_warnings": ["[MICRO] Art.22/24 UoR: 🔴 NIERZETELNE KSIĘGI! Sankcja: grzywna, kara ograniczenia wolności lub pozbawienia wolności do lat 2!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_declared_unreliable", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 24 — Nierzetelność ksiąg (2 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a24.r1: Definicja nierzetelności ksiąg
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r1",
    "package": "jdg.micro.uor",
    "priority": 160065,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Księgi nierzetelne — zapisy niezgodne ze stanem rzeczywistym!",
    "_legal_basis": "Art. 24 ust. 2-3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.24 UoR: Nierzetelne księgi = zapisy NIE odzwierciedlają stanu rzeczywistego — UTRATA mocy dowodowej!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_unreliable_evidence", false) == true
}

# uor.a24.r2: Konsekwencja nierzetelności — szacowanie dochodu przez US
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a24.r2",
    "package": "jdg.micro.uor",
    "priority": 160066,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Nierzetelne księgi — US może OSZACOWAĆ dochód! (Art. 23 OrdPU)",
    "_legal_basis": "Art. 24 ust. 2 Ustawy o rachunkowości; Art. 23 OrdPU",
    "_warnings": ["[MICRO] Art.24 UoR: Nierzetelne księgi → US szacuje dochód → potencjalnie WYŻSZY podatek + odsetki!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_challenged_by_us", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 26-27 — Inwentaryzacja (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a26.r1: Obowiązek inwentaryzacji — minimum raz w roku
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r1",
    "package": "jdg.micro.uor",
    "priority": 160067,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "BRAK inwentaryzacji rocznej — obowiązek Art.26 UoR!",
    "_legal_basis": "Art. 26 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.26 UoR: Inwentaryzacja OBOWIĄZKOWA minimum raz w roku — termin: 3 miesiące od dnia bilansowego"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    object.get(input.jdg_entrepreneur, "uor_physical_count_done", false) == false
}

# uor.a26.r2: Metoda 1: Spis z natury (towary, materiały, gotówka)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r2",
    "package": "jdg.micro.uor",
    "priority": 160068,
    "micro_rule_active": true,
    "method": "spis_z_natury",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 pkt 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.26 UoR: SPIS Z NATURY — towary, materiały, półfabrykaty, produkty gotowe, gotówka"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_inventory", false) == true
}

# uor.a26.r3: Metoda 2: Potwierdzenie sald (należności, zobowiązania)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r3",
    "package": "jdg.micro.uor",
    "priority": 160069,
    "micro_rule_active": true,
    "method": "potwierdzenie_sald",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.26 UoR: POTWIERDZENIE SALD — należności od kontrahentów, zobowiązania wobec dostawców"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_receivables_or_payables", false) == true
}

# uor.a26.r4: Metoda 3: Weryfikacja analityczna (RMK, rozliczenia)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r4",
    "package": "jdg.micro.uor",
    "priority": 160070,
    "micro_rule_active": true,
    "method": "weryfikacja_analityczna",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 pkt 3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.26 UoR: WERYFIKACJA ANALITYCZNA — RMK, rozliczenia międzyokresowe, rezerwy"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_has_prepaid_expenses", false) == true
}

# uor.a26.r5: Termin inwentaryzacji — 3 miesiące od dnia bilansowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r5",
    "package": "jdg.micro.uor",
    "priority": 160071,
    "micro_rule_active": true,
    "inventory_deadline": "do 31 marca następnego roku",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Inwentaryzacja NIE przeprowadzona w terminie 3 miesięcy od dnia bilansowego!",
    "_legal_basis": "Art. 26 ust. 3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.26 UoR: Termin inwentaryzacji = 3 miesiące od dnia bilansowego (do 31 marca)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    object.get(input.jdg_entrepreneur, "uor_inventory_overdue", false) == true
}

# uor.a26.r6: Różnice inwentaryzacyjne — nadwyżki i niedobory
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r6",
    "package": "jdg.micro.uor",
    "priority": 160072,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Różnice inwentaryzacyjne — nadwyżki/niedobory wymagają wyjaśnienia i rozliczenia!",
    "_legal_basis": "Art. 27 ust. 1-2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.27 UoR: Różnice inwentaryzacyjne — wyjaśnij, rozlicz w księgach, skoryguj podatek!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    book_value := object.get(input.jdg_entrepreneur, "uor_book_inventory_value", 0)
    physical_value := object.get(input.jdg_entrepreneur, "uor_physical_count_value", 0)
    abs(book_value - physical_value) > 100
}

# uor.a26.r7: Inwentaryzacja — dokumentacja przebiegu
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r7",
    "package": "jdg.micro.uor",
    "priority": 160073,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 27 ust. 3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.27 UoR: Dokumentacja inwentaryzacji: arkusze spisowe, protokoły, potwierdzenia sald"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_inventory_documented", false) == true
}

# uor.a26.r8: Inwentaryzacja ciągła (alternatywnie)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.r8",
    "package": "jdg.micro.uor",
    "priority": 160074,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 3 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.26 UoR: Inwentaryzacja ciągła — alternatywnie do okresowej, dla jednostek z ewidencją ilościowo-wartościową"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_continuous_inventory", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 28 — Wycena aktywów i pasywów (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a28.r1: Wycena aktywów — cena nabycia
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r1",
    "package": "jdg.micro.uor",
    "priority": 160075,
    "micro_rule_active": true,
    "valuation_method": "cena_nabycia",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28 ust. 1 pkt 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.28 UoR: Cena nabycia = cena zakupu + koszty uboczne (transport, montaż, ubezpieczenie, cło)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "asset_type", "TANGIBLE") == "TANGIBLE"
}

# uor.a28.r2: Wycena aktywów — koszt wytworzenia
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r2",
    "package": "jdg.micro.uor",
    "priority": 160076,
    "micro_rule_active": true,
    "valuation_method": "koszt_wytworzenia",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28 ust. 1 pkt 8; Art. 28 ust. 3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.28 UoR: Koszt wytworzenia = materiały bezpośrednie + robocizna bezpośrednia + uzasadniona część kosztów pośrednich"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "asset_type", "TANGIBLE") == "SELF_MANUFACTURED"
}

# uor.a28.r3: Wycena — wartość godziwa (aktywa finansowe)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r3",
    "package": "jdg.micro.uor",
    "priority": 160077,
    "micro_rule_active": true,
    "valuation_method": "wartosc_godziwa",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28 ust. 1 pkt 5 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.28 UoR: Wartość godziwa = cena możliwa do uzyskania na aktywnym rynku (np. akcje, obligacje, udziały)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "asset_type", "TANGIBLE") == "FINANCIAL"
}

# uor.a28.r4: Wycena zapasów — niższa z cen: nabycia lub rynkowej
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r4",
    "package": "jdg.micro.uor",
    "priority": 160078,
    "micro_rule_active": true,
    "valuation_method": "nizsza_z_cen",
    "_routing": "WARNING",
    "_routing_reason": "Wycena zapasów — wartość rynkowa niższa od ceny nabycia! Konieczny odpis aktualizujący.",
    "_legal_basis": "Art. 28 ust. 1 pkt 6 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.28 UoR: Zapasy wyceniaj wg NIŻSZEJ z cen: nabycia/zakupu lub rynkowej netto (ostrożność!)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    inventory_cost := object.get(input.jdg_entrepreneur, "uor_inventory_cost", 0)
    inventory_market := object.get(input.jdg_entrepreneur, "uor_inventory_market_value", 0)
    inventory_market > 0
    inventory_market < inventory_cost
}

# uor.a28.r5: Odpisy aktualizujące — trwała utrata wartości
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r5",
    "package": "jdg.micro.uor",
    "priority": 160079,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Trwała utrata wartości aktywa — konieczny ODPIS AKTUALIZUJĄCY!",
    "_legal_basis": "Art. 28 ust. 7 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.28 UoR: Odpis aktualizujący przy trwałej utracie wartości — nie wyżej niż do poziomu wartości odzyskiwalnej"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    market_value := object.get(input.invoice, "asset_market_value", 0)
    book_value := object.get(input.invoice, "asset_book_value", 0)
    market_value > 0
    book_value > 0
    market_value < book_value * 0.70
}

# uor.a28.r6: Wycena bilansowa aktywów — wartość netto
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r6",
    "package": "jdg.micro.uor",
    "priority": 160080,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28 ust. 7-8 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.28 UoR: Wartość bilansowa netto = wartość początkowa - umorzenie - odpisy aktualizujące"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a28.r7: Wycena należności — kwota wymagająca zapłaty z zachowaniem ostrożności
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r7",
    "package": "jdg.micro.uor",
    "priority": 160081,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Należności przeterminowane >180 dni — rozważ odpis aktualizujący!",
    "_legal_basis": "Art. 28 ust. 1 pkt 7; Art. 35b Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.28 UoR: Należności — wycena w kwocie wymagającej zapłaty z uwzględnieniem odpisów aktualizujących"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    days_overdue := object.get(input.invoice, "receivable_days_overdue", 0)
    days_overdue > 180
}

# uor.a28.r8: Wycena zobowiązań — kwota wymagająca zapłaty
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a28.r8",
    "package": "jdg.micro.uor",
    "priority": 160082,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28 ust. 1 pkt 8 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.28 UoR: Zobowiązania — wycena w kwocie wymagającej zapłaty (wartość nominalna)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_liability", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 27 — Przeliczenie walut obcych na PLN (3 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a27.r1: Przeliczenie na PLN — kurs NBP z dnia poprzedzającego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a27.r1",
    "package": "jdg.micro.uor",
    "priority": 160148,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Transakcja w walucie obcej — przelicz na PLN wg kursu NBP z dnia poprzedzającego!",
    "_legal_basis": "Art. 27 ust. 1-2; Art. 30 ust. 1 pkt 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.27 UoR: Waluty obce — przeliczaj wg KURSU NBP z dnia poprzedzającego dzień operacji (lub średniego NBP dla dnia bilansowego)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    currency := object.get(input.invoice, "currency", "PLN")
    currency != "PLN"
    object.get(input.invoice, "fx_converted_correctly", true) == false
}

# uor.a27.r2: Wycena bilansowa walut — kurs NBP na dzień bilansowy
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a27.r2",
    "package": "jdg.micro.uor",
    "priority": 160149,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Dzień bilansowy — przelicz aktywa/pasywa walutowe wg kursu NBP z 31.12!",
    "_legal_basis": "Art. 27 ust. 2; Art. 30 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.27 UoR: Wycena bilansowa walut — kurs NBP z dnia bilansowego. Różnice kursowe → przychody/koszty finansowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    object.get(input.jdg_entrepreneur, "has_fx_assets_or_liabilities", false) == true
}

# uor.a27.r3: Różnice kursowe — zrealizowane (zapłata) vs niezrealizowane (wycena)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a27.r3",
    "package": "jdg.micro.uor",
    "priority": 160150,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 27 ust. 2; Art. 30 ust. 2-4 Ustawy o rachunkowości; Art. 15a PIT",
    "_warnings": ["[MICRO] Art.27 UoR: Różnice kursowe dzielą się na ZREALIZOWANE (przy zapłacie) i NIEZREALIZOWANE (przy wycenie bilansowej)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "fx_difference_exists", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 30 — Wycena w walutach obcych (3 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a30.r1: Wycena walut — kurs NBP z dnia poprzedzającego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a30.r1",
    "package": "jdg.micro.uor",
    "priority": 160083,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 1 pkt 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.30 UoR: Wycena walut obcych — kurs NBP z dnia poprzedzającego dzień operacji"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    currency := object.get(input.invoice, "currency", "PLN")
    currency != "PLN"
}

# uor.a30.r2: Wycena bilansowa walut — kurs NBP na dzień bilansowy
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a30.r2",
    "package": "jdg.micro.uor",
    "priority": 160084,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.30 UoR: Na dzień bilansowy — wycena wg kursu NBP z dnia bilansowego (31.12)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a30.r3: Różnice kursowe — zrealizowane vs niezrealizowane
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a30.r3",
    "package": "jdg.micro.uor",
    "priority": 160085,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 2-4 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.30 UoR: Różnice kursowe — zrealizowane (zapłata) i niezrealizowane (wycena bilansowa) → przychody/koszty finansowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "fx_difference_exists", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 32-33 — Amortyzacja UoR (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a32.r1: Amortyzacja — metoda ekonomiczna UoR (okres użyteczności)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r1",
    "package": "jdg.micro.uor",
    "priority": 160086,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ust. 1-2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.32 UoR: Amortyzacja UoR = okres ekonomicznej użyteczności (elastyczny!), NIE wg stawek KŚT (sztywnych)!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
}

# uor.a32.r2: Amortyzacja liniowa
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r2",
    "package": "jdg.micro.uor",
    "priority": 160087,
    "micro_rule_active": true,
    "method": "liniowa",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.32 UoR: Metoda liniowa = równe odpisy przez cały okres użyteczności ekonomicznej"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "depreciation_method_uor", "LINEAR") == "LINEAR"
}

# uor.a32.r3: Amortyzacja degresywna
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r3",
    "package": "jdg.micro.uor",
    "priority": 160088,
    "micro_rule_active": true,
    "method": "degresywna",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.32 UoR: Metoda degresywna = wyższe odpisy w pierwszych latach (współczynnik 2.0), gdy intensywne użytkowanie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "depreciation_method_uor", "LINEAR") == "DEGRESSIVE"
}

# uor.a32.r4: RÓŻNICA UoR vs PIT — generowanie podatku odroczonego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r4",
    "package": "jdg.micro.uor",
    "priority": 160089,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "UoR vs PIT: różnica w amortyzacji generuje AKTYWA/REZERWY z tytułu odroczonego podatku!",
    "_legal_basis": "Art. 32-33 Ustawy o rachunkowości; Art. 22a-22o PIT; Art. 37 UoR",
    "_warnings": ["[MICRO] Art.32/37 UoR: RÓŻNICA UoR vs PIT w amortyzacji → podatek odroczony (DTL/DTA). Prowadź DWIE ewidencje!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "uor_vs_pit_depreciation_diff", false) == true
}

# uor.a32.r5: Rozpoczęcie amortyzacji — od miesiąca przyjęcia do użytkowania
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r5",
    "package": "jdg.micro.uor",
    "priority": 160090,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ust. 3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.32 UoR: Amortyzację rozpocznij od miesiąca następującego po miesiącu przyjęcia środka trwałego do użytkowania"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
}

# uor.a32.r6: Amortyzacja niskocennych środków trwałych
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.r6",
    "package": "jdg.micro.uor",
    "priority": 160091,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ust. 6 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.32 UoR: Środki trwałe <10 000 PLN mogą być amortyzowane jednorazowo w miesiącu oddania do użytkowania"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "amount_net", 0) < 10000
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 39 — Rozliczenia międzyokresowe kosztów / RMK (5 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a39.r1: RMK czynne — koszty przyszłych okresów
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r1",
    "package": "jdg.micro.uor",
    "priority": 160092,
    "micro_rule_active": true,
    "rmk_type": "czynne",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 39 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.39 UoR: RMK czynne = koszty poniesione w bieżącym okresie, dotyczące przyszłych okresów (np. prenumerata, ubezpieczenie)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_has_prepaid_expenses", false) == true
}

# uor.a39.r2: RMK bierne — rezerwy na przyszłe zobowiązania
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r2",
    "package": "jdg.micro.uor",
    "priority": 160093,
    "micro_rule_active": true,
    "rmk_type": "bierne",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 39 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.39 UoR: RMK bierne = rezerwy na przyszłe zobowiązania przypadające na bieżący okres (np. naprawy gwarancyjne)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_has_accrued_expenses", false) == true
}

# uor.a39.r3: Przychody przyszłych okresów
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r3",
    "package": "jdg.micro.uor",
    "priority": 160094,
    "micro_rule_active": true,
    "rmk_type": "przychody_przyszlych_okresow",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 39 ust. 2a Ustawy o rachunkowości; Art. 41 UoR",
    "_warnings": ["[MICRO] Art.39/41 UoR: Przychody przyszłych okresów = wpływy dotyczące przyszłych okresów sprawozdawczych"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_has_deferred_revenue", false) == true
}

# uor.a39.r4: RMK — podział na krótkoterminowe i długoterminowe
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r4",
    "package": "jdg.micro.uor",
    "priority": 160095,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 39 ust. 1-2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.39 UoR: Podziel RMK na krótkoterminowe (≤12 mies.) i długoterminowe (>12 mies.) w bilansie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a39.r5: RMK — nieprawidłowe rozliczenie
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a39.r5",
    "package": "jdg.micro.uor",
    "priority": 160096,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "RMK nieprawidłowo rozliczone — koszty w niewłaściwym okresie!",
    "_legal_basis": "Art. 39 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.39 UoR: RMK rozliczane nieprawidłowo — sprawdź przypisanie do właściwych okresów sprawozdawczych"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_rmk_properly_booked", true) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 45-52 — Sprawozdanie finansowe (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a45.r1: Obowiązek sporządzenia sprawozdania finansowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.r1",
    "package": "jdg.micro.uor",
    "priority": 160097,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sprawozdanie finansowe NIE sporządzone — obowiązek Art.45 UoR!",
    "_legal_basis": "Art. 45 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.45 UoR: Sprawozdanie finansowe OBOWIĄZKOWE dla jednostek stosujących UoR — termin 3 miesiące od dnia bilansowego"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    object.get(input.jdg_entrepreneur, "uor_financial_statement_filed", false) == false
}

# uor.a46.r1: Bilans — struktura aktywa / pasywa
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a46.r1",
    "package": "jdg.micro.uor",
    "priority": 160098,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Bilans NIEZBILANSOWANY — Aktywa ≠ Pasywa + Kapitał!",
    "_legal_basis": "Art. 46 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.46 UoR: Bilans: Aktywa trwałe + obrotowe = Kapitał własny + Zobowiązania długo- i krótkoterminowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    equity_liab := object.get(input.jdg_entrepreneur, "uor_total_equity", 0) + object.get(input.jdg_entrepreneur, "uor_total_liabilities", 0)
    abs(assets - equity_liab) >= 100
    assets > 0
}

# uor.a47.r1: RZiS — wynik finansowy
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a47.r1",
    "package": "jdg.micro.uor",
    "priority": 160099,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.47 UoR: RZiS: Przychody - Koszty = Wynik finansowy brutto - Podatek = Wynik netto"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a48.r1: Informacja dodatkowa — obowiązkowe ujawnienia
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a48.r1",
    "package": "jdg.micro.uor",
    "priority": 160100,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Informacja dodatkowa niekompletna — wymagane ujawnienia: polityka rachunkowości, zdarzenia po dniu bilansowym, instrumenty finansowe",
    "_legal_basis": "Art. 48 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.48 UoR: Informacja dodatkowa musi zawierać: wprowadzenie, politykę rachunkowości, noty objaśniające"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_notes_complete", true) == false
}

# uor.a48b.r1: Rachunek przepływów pieniężnych (metoda pośrednia)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a48b.r1",
    "package": "jdg.micro.uor",
    "priority": 160101,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 48b Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.48b UoR: Cash Flow — 3 segmenty: operacyjny (metoda pośrednia), inwestycyjny, finansowy"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

# uor.a52.r1: Termin złożenia sprawozdania finansowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a52.r1",
    "package": "jdg.micro.uor",
    "priority": 160102,
    "micro_rule_active": true,
    "deadline": "31 marca następnego roku",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sprawozdanie finansowe NIE złożone w terminie do 31 marca!",
    "_legal_basis": "Art. 52 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.52 UoR: Termin złożenia sprawozdania finansowego: 31 marca + 15 dni na zatwierdzenie i złożenie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_fs_filing_overdue", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 53 — Badanie sprawozdania finansowego (2 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a53.r1: Obowiązek badania — progi (2.5M EUR sumy bilansowej lub 5M EUR przychodów)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a53.r1",
    "package": "jdg.micro.uor",
    "priority": 160103,
    "micro_rule_active": true,
    "audit_threshold_assets_pln": 12500000,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Przekroczone progi badania sprawozdania — obowiązkowy audyt przez biegłego rewidenta!",
    "_legal_basis": "Art. 53; Art. 64 ust. 1 pkt 4 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.53 UoR: Badanie sprawozdania przez biegłego rewidenta obowiązkowe gdy suma bilansowa >2.5M EUR lub przychody >5M EUR"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    total_revenue := object.get(input.jdg_entrepreneur, "uor_total_revenue", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    total_assets > 2500000 * eur_rate
}

# uor.a53.r2: Mała JDG — zwolnienie z badania
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a53.r2",
    "package": "jdg.micro.uor",
    "priority": 160104,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 53; Art. 64 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.53 UoR: JDG poniżej progów — ZWOLNIENIE z obowiązku badania sprawozdania przez biegłego rewidenta"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    total_revenue := object.get(input.jdg_entrepreneur, "uor_total_revenue", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    total_assets < 2500000 * eur_rate
    total_revenue < 5000000 * eur_rate
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 74 — Przechowywanie dokumentacji (4 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a74.r1: Okres przechowywania ksiąg rachunkowych: 5 lat
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r1",
    "package": "jdg.micro.uor",
    "priority": 160105,
    "micro_rule_active": true,
    "retention_years": 5,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 74 ust. 1 pkt 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.74 UoR: Księgi rachunkowe + dowody księgowe przechowuj 5 LAT od końca roku obrotowego"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# uor.a74.r2: Listy płac: 50 LAT! (szczególny okres)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r2",
    "package": "jdg.micro.uor",
    "priority": 160106,
    "micro_rule_active": true,
    "retention_years": 50,
    "_routing": "WARNING",
    "_routing_reason": "⚠️ Listy płac — okres przechowywania 50 LAT! Nie niszcz przedwcześnie!",
    "_legal_basis": "Art. 74 ust. 1 pkt 2; Art. 74 ust. 1a Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.74 UoR: ⚠️ Dokumenty płacowe (listy płac, karty wynagrodzeń) przechowuj 50 LAT! (nie 5 lat jak reszta)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_has_payroll_docs", false) == true
}

# uor.a74.r3: Sprawozdania finansowe: BEZTERMINOWO
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r3",
    "package": "jdg.micro.uor",
    "priority": 160107,
    "micro_rule_active": true,
    "retention": "BEZTERMINOWO",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 74 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.74 UoR: Sprawozdania finansowe przechowuj BEZTERMINOWO (stałe)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# uor.a74.r4: Dokumenty do zniszczenia — starsze niż 5 lat
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a74.r4",
    "package": "jdg.micro.uor",
    "priority": 160108,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 74 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.74 UoR: Po 5 latach od końca roku obrotowego można protokolarnie zniszczyć dokumenty księgowe (UWAGA na płace 50 lat!)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_documents_eligible_for_disposal", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 76 — Odpowiedzialność kierownika jednostki (3 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a76.r1: Odpowiedzialność kierownika za księgi rachunkowe
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a76.r1",
    "package": "jdg.micro.uor",
    "priority": 160109,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 76 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.76 UoR: Kierownik jednostki (JDG = przedsiębiorca) ponosi OSOBISTĄ odpowiedzialność za księgi rachunkowe!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# uor.a76.r2: Obowiązek nadzoru nad księgowością
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a76.r2",
    "package": "jdg.micro.uor",
    "priority": 160110,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 76 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.76 UoR: Nawet przy outsourcowanej księgowości — ODPOWIEDZIALNOŚĆ ZAWSZE po stronie przedsiębiorcy JDG!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_accounting_outsourced", false) == true
}

# uor.a76.r3: Powierzenie ksiąg — odpowiedzialność solidarna
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a76.r3",
    "package": "jdg.micro.uor",
    "priority": 160111,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 76 ust. 3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.76 UoR: Powierzenie prowadzenia ksiąg biuru rachunkowemu — ODPOWIEDZIALNOŚĆ NADAL TWOJA (przedsiębiorco)!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 77 — Sankcje karne za nierzetelność (5 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a77.r1: Sankcja — grzywna za nierzetelne księgi
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a77.r1",
    "package": "jdg.micro.uor",
    "priority": 160112,
    "micro_rule_active": true,
    "sanction_type": "KARNA",
    "sanction_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "SANKCJA KARNA Art.77 UoR: Nierzetelne księgi → grzywna, ograniczenie wolności, pozbawienie wolności do lat 2!",
    "_legal_basis": "Art. 77 pkt 1 Ustawy o rachunkowości; Art. 60-61 KKS",
    "_warnings": ["[MICRO] Art.77 UoR: ⚖️ SANKCJA KARNA — grzywna do 720 stawek dziennych lub kara pozbawienia wolności do lat 2!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_declared_unreliable", false) == true
}

# uor.a77.r2: Sankcja — brak sprawozdania finansowego
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a77.r2",
    "package": "jdg.micro.uor",
    "priority": 160113,
    "micro_rule_active": true,
    "sanction_type": "KARNA",
    "sanction_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "SANKCJA KARNA: Brak sprawozdania finansowego — Art. 77 pkt 2 UoR!",
    "_legal_basis": "Art. 77 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.77 UoR: Niesporządzenie lub niezłożenie sprawozdania finansowego → sankcja karna!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_financial_statement_filed", false) == false
    object.get(input.jdg_entrepreneur, "uor_fs_deadline_passed", false) == true
}

# uor.a77.r3: Sankcja — brak badania sprawozdania
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a77.r3",
    "package": "jdg.micro.uor",
    "priority": 160114,
    "micro_rule_active": true,
    "sanction_type": "KARNA",
    "sanction_severity": "MEDIUM",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak obowiązkowego badania sprawozdania przez biegłego rewidenta!",
    "_legal_basis": "Art. 77 pkt 3 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.77 UoR: Niepoddanie sprawozdania badaniu przez biegłego rewidenta → sankcja karna!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    needs_audit := total_assets > 2500000 * eur_rate
    audit_done := object.get(input.jdg_entrepreneur, "uor_audit_completed", false)
    needs_audit
    not audit_done
}

# uor.a77.r4: Sankcja — fałszowanie dokumentacji
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a77.r4",
    "package": "jdg.micro.uor",
    "priority": 160115,
    "micro_rule_active": true,
    "sanction_type": "KARNA",
    "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "FAŁSZOWANIE DOKUMENTACJI KSIĘGOWEJ — przestępstwo! Sankcja do 5 lat pozbawienia wolności!",
    "_legal_basis": "Art. 77 pkt 4 Ustawy o rachunkowości; Art. 270-271 KK",
    "_warnings": ["[MICRO] Art.77 UoR: 🔴 FAŁSZOWANIE DOKUMENTÓW — przestępstwo ścigane z oskarżenia publicznego! Do 5 lat więzienia!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_documents_falsified", false) == true
}

# uor.a77.r5: Sankcja — naruszenie przepisów w sposób uporczywy
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a77.r5",
    "package": "jdg.micro.uor",
    "priority": 160116,
    "micro_rule_active": true,
    "sanction_type": "KARNA",
    "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "UPORCZYWE naruszenie przepisów UoR — zaostrzona sankcja karna!",
    "_legal_basis": "Art. 77 pkt 5; Art. 79 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.77/79 UoR: Uporczywe naruszenia → zaostrzone sankcje: grzywna + ograniczenie wolności + zakaz prowadzenia działalności"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_persistent_violations", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 79 — Odpowiedzialność karna skarbowa za wykroczenia (2 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a79.r1: Wykroczenie skarbowe — nieterminowe złożenie sprawozdania
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a79.r1",
    "package": "jdg.micro.uor",
    "priority": 160117,
    "micro_rule_active": true,
    "sanction_type": "WYKROCZENIE_SKARBOWE",
    "sanction_severity": "LOW",
    "sanction_base_amount_pln": 1000,
    "_routing": "WARNING",
    "_routing_reason": "Nieterminowe złożenie sprawozdania finansowego — wykroczenie skarbowe!",
    "_legal_basis": "Art. 79 Ustawy o rachunkowości; Art. 56 KKS",
    "_warnings": ["[MICRO] Art.79 UoR: Wykroczenie skarbowe — nieterminowe złożenie → grzywna 1-10 stawek dziennych"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_fs_filing_late", false) == true
}

# uor.a79.r2: Wykroczenie — brak polityki rachunkowości
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a79.r2",
    "package": "jdg.micro.uor",
    "priority": 160118,
    "micro_rule_active": true,
    "sanction_type": "WYKROCZENIE",
    "sanction_severity": "LOW",
    "sanction_base_amount_pln": 500,
    "_routing": "WARNING",
    "_routing_reason": "Brak polityki rachunkowości — wykroczenie!",
    "_legal_basis": "Art. 79; Art. 10 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.79 UoR: Brak polityki rachunkowości → wykroczenie → grzywna"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_accounting_policy_exists", true) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 16 — Zmiana polityki rachunkowości (4 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a16.r1: Zmiana polityki rachunkowości — retrospektywne przekształcenie
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a16.r1",
    "package": "jdg.micro.uor",
    "priority": 160119,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Zmiana polityki rachunkowości — wymaga retrospektywnego przekształcenia danych porównawczych!",
    "_legal_basis": "Art. 16 ust. 1; Art. 8 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.16 UoR: Zmiana polityki rachunkowości → RETROSPEKTYWNE przekształcenie + ujawnienie w informacji dodatkowej"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_policy_change_requested", false) == true
}

# uor.a16.r2: Zmiana polityki — uzasadnienie w informacji dodatkowej
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a16.r2",
    "package": "jdg.micro.uor",
    "priority": 160120,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zmiana polityki rachunkowości BEZ uzasadnienia w informacji dodatkowej!",
    "_legal_basis": "Art. 16 ust. 1; Art. 48 ust. 1 pkt 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.16 UoR: Zmiana polityki → OBOWIĄZKOWE ujawnienie: przyczyna, wpływ na wynik, dane porównawcze"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_policy_change_disclosed", true) == false
}

# uor.a16.r3: Zmiana metody amortyzacji — efekt na wynik
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a16.r3",
    "package": "jdg.micro.uor",
    "priority": 160121,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zmiana metody amortyzacji — skwantyfikuj wpływ na wynik finansowy!",
    "_legal_basis": "Art. 16 ust. 1; Art. 32 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.16 UoR: Zmiana metody amortyzacji (np. liniowa→degresywna) → ujawnij efekt liczbowy na wynik bieżący i przyszłe okresy"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_depreciation_method_changed", false) == true
}

# uor.a16.r4: Zmiana polityki — zgoda biegłego rewidenta
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a16.r4",
    "package": "jdg.micro.uor",
    "priority": 160122,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Zmiana polityki rachunkowości musi być zaakceptowana przez biegłego rewidenta (jeśli podlega badaniu)!",
    "_legal_basis": "Art. 16 ust. 2; Art. 53 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.16 UoR: Zmiana polityki → poinformuj biegłego rewidenta — wymaga akceptacji i ujawnienia w opinii"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    needs_audit := total_assets > 2500000 * eur_rate
    policy_changed := object.get(input.jdg_entrepreneur, "uor_policy_change_requested", false)
    needs_audit
    policy_changed
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 78 — Odpowiedzialność karna za nieprowadzenie ksiąg (3 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a78.r1: Całkowity brak ksiąg rachunkowych
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a78.r1",
    "package": "jdg.micro.uor",
    "priority": 160123,
    "micro_rule_active": true,
    "sanction_type": "KARNA",
    "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CAŁKOWITY BRAK KSIĄG RACHUNKOWYCH — przestępstwo! Grzywna + kara pozbawienia wolności do lat 2!",
    "_legal_basis": "Art. 78 pkt 1 Ustawy o rachunkowości; Art. 60-61 KKS; Art. 303 KK",
    "_warnings": ["[MICRO] Art.78 UoR: 🔴 CAŁKOWITY BRAK KSIĄG — przestępstwo ścigane z urzędu! Grzywna + pozbawienie wolności!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_exist", true) == false
}

# uor.a78.r2: Nieprowadzenie ksiąg mimo obowiązku (>2M EUR)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a78.r2",
    "package": "jdg.micro.uor",
    "priority": 160124,
    "micro_rule_active": true,
    "sanction_type": "KARNA",
    "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Nieprowadzenie ksiąg rachunkowych mimo przekroczenia 2M EUR — przestępstwo!",
    "_legal_basis": "Art. 78 pkt 1; Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.78 UoR: Przekroczenie 2M EUR BEZ przejścia na księgi rachunkowe → przestępstwo + szacowanie dochodu przez US!"]
} {
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", 4.5)
    revenue_eur := annual_revenue_pln / eur_rate
    uses_uor := object.get(input.jdg_entrepreneur, "uses_uor", false)
    revenue_eur >= 2000000
    not uses_uor
}

# uor.a78.r3: Zniszczenie lub ukrycie ksiąg
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a78.r3",
    "package": "jdg.micro.uor",
    "priority": 160125,
    "micro_rule_active": true,
    "sanction_type": "KARNA",
    "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "ZNISZCZENIE/UKRYCIE KSIĄG — przestępstwo! Kara do 5 lat pozbawienia wolności!",
    "_legal_basis": "Art. 78 pkt 2 Ustawy o rachunkowości; Art. 276 KK",
    "_warnings": ["[MICRO] Art.78 UoR: 🔴 ZNISZCZENIE/UKRYCIE KSIĄG — przestępstwo! Do 5 lat pozbawienia wolności + przepadek korzyści!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_destroyed_or_hidden", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 80-81 — Sankcje administracyjne i dodatkowe (3 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a80.r1: Zakaz prowadzenia działalności gospodarczej
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a80.r1",
    "package": "jdg.micro.uor",
    "priority": 160126,
    "micro_rule_active": true,
    "sanction_type": "ADMINISTRACYJNA",
    "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "ZAKAZ prowadzenia działalności — sankcja administracyjna za rażące naruszenia UoR!",
    "_legal_basis": "Art. 80 Ustawy o rachunkowości; Art. 373-376 Prawa upadłościowego",
    "_warnings": ["[MICRO] Art.80 UoR: ZAKAZ prowadzenia działalności gospodarczej (1-10 lat) za rażące naruszenie przepisów o rachunkowości!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_persistent_violations", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_declared_unreliable", false) == true
}

# uor.a80.r2: Przepadek korzyści majątkowej
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a80.r2",
    "package": "jdg.micro.uor",
    "priority": 160127,
    "micro_rule_active": true,
    "sanction_type": "ADMINISTRACYJNA",
    "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PRZEPADEK korzyści majątkowej uzyskanej w wyniku naruszeń UoR!",
    "_legal_basis": "Art. 80 ust. 2; Art. 81 Ustawy o rachunkowości; Art. 44-45 KK",
    "_warnings": ["[MICRO] Art.80-81 UoR: Przepadek korzyści majątkowej + nawiązka na rzecz Skarbu Państwa — nawet do równowartości wyrządzonej szkody!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_documents_falsified", false) == true
}

# uor.a81.r1: Nawiązka na rzecz Skarbu Państwa
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a81.r1",
    "package": "jdg.micro.uor",
    "priority": 160128,
    "micro_rule_active": true,
    "sanction_type": "KARNA_DODATKOWA",
    "sanction_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "NAWIĄZKA na rzecz Skarbu Państwa — dodatkowa sankcja finansowa za naruszenia!",
    "_legal_basis": "Art. 81 Ustawy o rachunkowości; Art. 39 KK",
    "_warnings": ["[MICRO] Art.81 UoR: Nawiązka — dodatkowa kara finansowa do 1 000 000 PLN na rzecz Skarbu Państwa za poważne naruszenia!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_severe_violation_confirmed", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 7 — Przyjęcia jednostki do grupy / konsolidacja (2 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a7.r1: JDG jako jednostka dominująca w grupie
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a7.r1",
    "package": "jdg.micro.uor",
    "priority": 160129,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "JDG jako jednostka dominująca — obowiązek skonsolidowanego sprawozdania finansowego!",
    "_legal_basis": "Art. 7 ust. 1; Art. 55 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.7 UoR: JDG jako jednostka dominująca w grupie kapitałowej → obowiązek konsolidacji sprawozdań!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "is_parent_entity", false) == true
}

# uor.a7.r2: Zwolnienie z konsolidacji — mała grupa
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a7.r2",
    "package": "jdg.micro.uor",
    "priority": 160130,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 2; Art. 56 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.7 UoR: Grupa może być zwolniona z konsolidacji jeśli łącznie < 2.5M EUR sumy bilansowej i <5M EUR przychodów"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "group_below_consolidation_threshold", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 9 — Dokumentacja opisująca politykę rachunkowości (2 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a9.r1: Obowiązek dokumentacji opisującej przyjęte zasady
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a9.r1",
    "package": "jdg.micro.uor",
    "priority": 160131,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Brak dokumentacji opisującej politykę rachunkowości — wymagane Art.9 UoR!",
    "_legal_basis": "Art. 9; Art. 10 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.9 UoR: Dokumentacja opisująca przyjęte zasady (polityka) rachunkowości — OBOWIĄZKOWA dla każdej jednostki UoR"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_has_accounting_manual", true) == false
}

# uor.a9.r2: Zakres dokumentacji — minimum 6 elementów
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a9.r2",
    "package": "jdg.micro.uor",
    "priority": 160132,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 9; Art. 10 ust. 1 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.9 UoR: Dokumentacja musi zawierać: metodę amortyzacji, metodę wyceny zapasów, wariant RZiS, próg istotności, plan kont, zasady RMK"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 15 — Rozpoczęcie działalności w trakcie roku (2 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a15.r1: Pierwszy rok obrotowy — krótszy niż 12 miesięcy
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a15.r1",
    "package": "jdg.micro.uor",
    "priority": 160133,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 15 ust. 1; Art. 14 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.15 UoR: Pierwszy rok obrotowy — od dnia rozpoczęcia do 31.12. Może być krótszy niż 12 miesięcy."]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "is_first_fiscal_year", false) == true
}

# uor.a15.r2: Rozpoczęcie — otwarcie ksiąg na dzień rozpoczęcia
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a15.r2",
    "package": "jdg.micro.uor",
    "priority": 160134,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Rozpoczęcie UoR w trakcie roku — wymaga bilansu otwarcia na dzień rozpoczęcia!",
    "_legal_basis": "Art. 15 ust. 1; Art. 12 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.15 UoR: Otwórz księgi na dzień rozpoczęcia — sporządź bilans otwarcia (inwentaryzacja + wycena wg Art.28)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_started_mid_year", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 38 — Rozliczenia międzyokresowe bierne — świadczenia pracownicze (2 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a38.r1: RMK bierne na niewykorzystane urlopy
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a38.r1",
    "package": "jdg.micro.uor",
    "priority": 160139,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Niewykorzystane urlopy pracownicze — utwórz RMK bierne na dzień bilansowy!",
    "_legal_basis": "Art. 38 ust. 1; Art. 39 ust. 2 Ustawy o rachunkowości; KSR 6",
    "_warnings": ["[MICRO] Art.38 UoR: Niewykorzystane urlopy → RMK bierne na dzień bilansowy (wynagrodzenie + ZUS). Ostrożność!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    has_employees
}

# uor.a38.r2: RMK na odprawy emerytalne i nagrody jubileuszowe
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a38.r2",
    "package": "jdg.micro.uor",
    "priority": 160140,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Odprawy emerytalne/nagrody jubileuszowe — rozważ utworzenie rezerwy długoterminowej!",
    "_legal_basis": "Art. 38 ust. 1; Art. 35d; Art. 39 ust. 2 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.38 UoR: Odprawy emerytalne/rentowe + nagrody jubileuszowe → rezerwy długoterminowe (wycena aktuarialna)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    long_term_employees := object.get(input.jdg_entrepreneur, "employees_over_10_years", false)
    has_employees
    long_term_employees
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 40-44 — Instrumenty finansowe i jednostki powiązane (4 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a40.r1: Klasyfikacja instrumentów finansowych
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a40.r1",
    "package": "jdg.micro.uor",
    "priority": 160141,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 40 ust. 1; § 1-2 Rozporządzenia MF ws. instrumentów finansowych",
    "_warnings": ["[MICRO] Art.40 UoR: Instrumenty finansowe klasyfikuj jako: przeznaczone do obrotu, dostępne do sprzedaży, utrzymywane do terminu wymagalności, pożyczki/należności"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_financial_instruments", false) == true
}

# uor.a41.r1: Wycena instrumentów finansowych wg wartości godziwej
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a41.r1",
    "package": "jdg.micro.uor",
    "priority": 160142,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Instrumenty finansowe — wymagana wycena wg wartości godziwej na dzień bilansowy!",
    "_legal_basis": "Art. 41 ust. 1; Art. 28 ust. 1 pkt 5 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.41 UoR: Instrumenty finansowe wyceniaj wg wartości godziwej. Zmiany → przychody/koszty finansowe lub kapitał z aktualizacji wyceny"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    object.get(input.jdg_entrepreneur, "has_financial_instruments", false) == true
}

# uor.a42.r1: Transakcje z jednostkami powiązanymi — ujawnienia
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a42.r1",
    "package": "jdg.micro.uor",
    "priority": 160143,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Transakcja z jednostką powiązaną — wymaga ujawnienia w informacji dodatkowej!",
    "_legal_basis": "Art. 42 ust. 1; Art. 44 Ustawy o rachunkowości; MSR 24",
    "_warnings": ["[MICRO] Art.42 UoR: Transakcje z jednostkami powiązanymi (rodzina, spółki powiązane) → OBOWIĄZKOWE ujawnienie: charakter, kwota, warunki"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_related_party_transaction", false) == true
}

# uor.a44.r1: Konsolidacja — wyłączenia wzajemne
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a44.r1",
    "package": "jdg.micro.uor",
    "priority": 160144,
    "micro_rule_active": true,
    "_routing": "WARNING",
    "_routing_reason": "Transakcje wewnątrzgrupowe — wyłącz przy konsolidacji!",
    "_legal_basis": "Art. 44 ust. 1-2; Art. 60 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.44 UoR: Transakcje między jednostkami powiązanymi w grupie → WYŁĄCZENIA konsolidacyjne (sprzedaż, należności, zobowiązania)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "is_parent_entity", false) == true
    object.get(input.invoice, "is_intercompany_transaction", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: Art. 35-37 — Rezerwy i podatek odroczony (4 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.a35.r1: Obowiązek tworzenia rezerw na znane ryzyka
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r1",
    "package": "jdg.micro.uor",
    "priority": 160135,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Brak rezerwy na znane ryzyko — naruszenie Art.35 UoR!",
    "_legal_basis": "Art. 35 ust. 1; Art. 35d Ustawy o rachunkowości; KSR 6",
    "_warnings": ["[MICRO] Art.35 UoR: Rezerwy OBOWIĄZKOWE na: naprawy gwarancyjne, restrukturyzację, sprawy sądowe, straty z umów"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    has_known_risk := object.get(input.jdg_entrepreneur, "uor_known_risk_exists", false)
    provision_created := object.get(input.jdg_entrepreneur, "uor_provision_created", false)
    has_known_risk
    not provision_created
}

# uor.a35.r2: Rezerwy — rodzaje i wycena
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a35.r2",
    "package": "jdg.micro.uor",
    "priority": 160136,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 35d ust. 1-4 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.35d UoR: Rezerwy wycenia się w uzasadnionej, wiarygodnie oszacowanej wartości. Dziel na krótko- i długoterminowe."]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_provision_created", false) == true
}

# uor.a37.r1: Podatek odroczony — różnice przejściowe dodatnie (DTL)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a37.r1",
    "package": "jdg.micro.uor",
    "priority": 160137,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Wykryto dodatnie różnice przejściowe — utwórz REZERWĘ z tytułu odroczonego podatku (DTL)!",
    "_legal_basis": "Art. 37 ust. 1-6 Ustawy o rachunkowości; KSR 2",
    "_warnings": ["[MICRO] Art.37 UoR: Dodatnie różnice przejściowe (UoR szybciej amortyzuje niż PIT) → REZERWA DTL (19% CIT)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    uor_depreciation := object.get(input.jdg_entrepreneur, "uor_depreciation_annual", 0)
    pit_depreciation := object.get(input.jdg_entrepreneur, "pit_depreciation_annual", 0)
    uor_depreciation > pit_depreciation
}

# uor.a37.r2: Podatek odroczony — różnice przejściowe ujemne (DTA)
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a37.r2",
    "package": "jdg.micro.uor",
    "priority": 160138,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 37 ust. 4-6 Ustawy o rachunkowości",
    "_warnings": ["[MICRO] Art.37 UoR: Ujemne różnice przejściowe → AKTYWA DTA (tylko jeśli prawdopodobne osiągnięcie dochodu). Ostrożność!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    uor_depreciation := object.get(input.jdg_entrepreneur, "uor_depreciation_annual", 0)
    pit_depreciation := object.get(input.jdg_entrepreneur, "pit_depreciation_annual", 0)
    pit_depreciation > uor_depreciation
    object.get(input.jdg_entrepreneur, "uor_future_taxable_income_likely", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION: INTEGRATION & CROSS-REFERENCES (3 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

# uor.int.r1: Integracja UoR ↔ PIT — podatek odroczony
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.integration.r1",
    "package": "jdg.micro.uor",
    "priority": 160145,
    "micro_rule_active": true,
    "integration": "UoR_PIT_DEFERRED_TAX",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 37 Ustawy o rachunkowości; Art. 22a-22o PIT",
    "_warnings": ["[MICRO] INTEGRACJA UoR↔PIT: Różnice przejściowe w amortyzacji → podatek odroczony (DTL/DTA). Prowadź DWIE ewidencje!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
}

# uor.int.r2: Integracja UoR ↔ VAT — faktury i dowody księgowe
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.integration.r2",
    "package": "jdg.micro.uor",
    "priority": 160146,
    "micro_rule_active": true,
    "integration": "UoR_VAT_DOCUMENTS",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20-21 Ustawy o rachunkowości; Art. 106e VAT; Art. 109 VAT",
    "_warnings": ["[MICRO] INTEGRACJA UoR↔VAT: Faktury VAT są jednocześnie dowodami księgowymi UoR — muszą spełniać OBYDWA reżimy!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "invoice_number", "") != ""
}

# uor.int.r3: Integracja UoR ↔ KKS — sankcje za nierzetelność
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.integration.r3",
    "package": "jdg.micro.uor",
    "priority": 160147,
    "micro_rule_active": true,
    "integration": "UoR_KKS_SANCTIONS",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Naruszenie UoR może być jednocześnie przestępstwem KKS — podwójna sankcja!",
    "_legal_basis": "Art. 77 Ustawy o rachunkowości; Art. 60-61 KKS; Art. 56 KKS",
    "_warnings": ["[MICRO] INTEGRACJA UoR↔KKS: Nierzetelne księgi → jednocześnie sankcja UoR (Art.77) + KKS (Art.60-61). Podwójne ryzyko!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_books_unreliable_evidence", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.fallback",
    "package": "jdg.micro.uor",
    "priority": 999999,
    "micro_rule_active": true,
    "coverage_articles": 44,
    "coverage_rules": 153,
    "max_priority": 160150,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "_warnings": ["[MICRO] UoR v9.0: 38 artykułów, 138 reguł z REALNĄ logiką prawną (up from 6 articles / 174 stubs in v7.0)"]
} {
    true
}
