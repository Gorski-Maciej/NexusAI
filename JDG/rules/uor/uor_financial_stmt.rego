# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR Financial Statements Layer: Art. 45–50 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)
# Package: jdg.uor.financial_stmt — Financial Statement Generation & Validation
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: Art. 45–50 UoR
# Coverage: ~40 rules, ~40 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.financial_stmt

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.uor.financial_stmt.no_match",
    "package": "jdg.uor.financial_stmt",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# Bilans — Struktura i walidacja (12 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.a.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100700,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1 do UoR (dla jednostek mikro — zał. nr 4)",
    "_warnings": ["[UoR] Bilans — AKTYWA: A. Aktywa trwałe, B. Aktywa obrotowe, C. Należne wpłaty, D. Krótkoterminowe RMK"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.p.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100701,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1 do UoR",
    "_warnings": ["[UoR] Bilans — PASYWA: A. Kapitał własny, B. Zobowiązania i rezerwy, C. Krótkoterminowe RMP"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.integrity.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100702,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Suma bilansowa niezgodna — Aktywa ≠ Pasywa!",
    "_legal_basis": "Art. 7 ust. 1 UoR",
    "_warnings": ["[UoR] Walidacja bilansu: Aktywa MUSZĄ być równe Pasywom (Suma Bilansowa)!"]
} {
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    total_passive := object.get(input.jdg_entrepreneur, "uor_total_equity_liabilities", 0)
    abs(total_assets - total_passive) >= 0.01
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.fixed_assets.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100703,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, sekcja A",
    "_warnings": ["[UoR] A.I WNiP, A.II Rzeczowe aktywa trwałe (ŚT, ŚT w budowie), A.III Należności długoterminowe, A.IV Inwestycje długoterm, A.V Długoterm RMK"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.current_assets.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100704,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, sekcja B",
    "_warnings": ["[UoR] B.I Zapasy, B.II Należności krótkoterm, B.III Inwestycje krótkoterm (środki pieniężne), B.IV Krótkoterm RMK"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.equity.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100705,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, sekcja A pasywów",
    "_warnings": ["[UoR] A.I Kapitał podstawowy, A.II Kapitał zapasowy, A.III Kapitał z aktualizacji wyceny, A.IV Pozostałe, A.V Zysk/strata netto"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.liabilities.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100706,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, sekcja B pasywów",
    "_warnings": ["[UoR] B.I Rezerwy, B.II Zobowiązania długoterm, B.III Zobowiązania krótkoterm, B.IV Rozliczenia międzyokresowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.comparative.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100707,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 46 ust. 2 UoR",
    "_warnings": ["[UoR] Dane porównawcze — obowiązkowo: stan na koniec bieżącego i poprzedniego roku obrotowego"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.micro.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100708,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 4 do UoR (jednostki mikro)",
    "_warnings": ["[UoR] Bilans mikro — uproszczona struktura (tylko litery, bez cyfr rzymskich)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "is_micro_entity", true) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.wip.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100709,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, A.II.2",
    "_warnings": ["[UoR] Środki trwałe w budowie — wykazywane w A.II.2 aktywów (do czasu oddania do użytkowania)"]
} {
    has_construction_in_progress := object.get(input.jdg_entrepreneur, "has_assets_in_construction", false)
    has_construction_in_progress
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.cash.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100710,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, B.III.1",
    "_warnings": ["[UoR] Środki pieniężne — B.III.1b: środki na rachunku bankowym (firmowym + prywatnym dla JDG)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.balance.zus_health.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100711,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, B.III",
    "_warnings": ["[UoR] ZUS/Zdrowotna — w bilansie JDG: należności od ZUS (nadpłata) lub zobowiązania wobec ZUS"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    zus_overpaid := object.get(input.jdg_entrepreneur, "zus_overpaid", 0)
    zus_underpaid := object.get(input.jdg_entrepreneur, "zus_underpaid", 0)
    [zus_overpaid > 0, zus_underpaid > 0] != [false, false]
}

# ═══════════════════════════════════════════════════════════════════════════════
# RZiS — Rachunek Zysków i Strat (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.rzis.comparative.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100720,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, wariant porównawczy",
    "_warnings": ["[UoR] RZiS porównawczy: A. Przychody netto, B. Koszty działalności operacyjnej (rodzajowe)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "rzis_variant", "COMPARATIVE") == "COMPARATIVE"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.rzis.calc.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100721,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, wariant kalkulacyjny",
    "_warnings": ["[UoR] RZiS kalkulacyjny: A. Przychody netto, B. Koszt własny sprzedaży (produktów/usług/towarów)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "rzis_variant", "COMPARATIVE") == "CALCULATION"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.rzis.operating.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100722,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, sekcje C-H",
    "_warnings": ["[UoR] C. Zysk/Strata ze sprzedaży, D. Pozostałe przychody operacyjne, E. Pozostałe koszty operacyjne"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.rzis.financial.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100723,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, sekcje F-G",
    "_warnings": ["[UoR] F. Przychody finansowe, G. Koszty finansowe, H. Zysk/Strata brutto"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.rzis.net.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100724,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Załącznik nr 1, sekcje I-L",
    "_warnings": ["[UoR] I. Podatek dochodowy, J. Pozostałe obowiązkowe zmniejszenia, K. Zysk/Strata netto"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.rzis.pit_jdg.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100725,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 UoR; Art. 27/30c/30ca PIT",
    "_warnings": ["[UoR] PIT w RZiS — dla JDG podatek liczony od dochodu z działalności (skala/liniowy/IP Box)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    profit := object.get(input.jdg_entrepreneur, "uor_gross_profit", 0)
    profit > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.rzis.revenue_detail.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100726,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 UoR",
    "_warnings": ["[UoR] Struktura przychodów: krajowe/zagraniczne, towary/usługi/produkty — w informacji dodatkowej"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Informacja dodatkowa / Additional Notes (5 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.notes.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100730,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 48 UoR; Załącznik nr 1 — Dodatkowe informacje i objaśnienia",
    "_warnings": ["[UoR] Informacja dodatkowa: 1) Metody wyceny 2) Zmiany zasad 3) Zdarzenia po dniu bil 4) RMK 5) Zobowiązania warunkowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    not object.get(input.jdg_entrepreneur, "is_micro_entity", true)
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.notes.valuation.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100731,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 48 ust. 1 pkt 1 UoR",
    "_warnings": ["[UoR] Noty: metoda amortyzacji, metoda wyceny zapasów, kursy walut, próg istotności"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.notes.post_balance.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100732,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 48 ust. 1 pkt 4 UoR",
    "_warnings": ["[UoR] Noty: istotne zdarzenia po dniu bilansowym (np. otrzymanie dotacji, pożar, zmiana formy prawnej)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_post_balance_events", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.notes.contingent.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100733,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 48 ust. 1 pkt 5 UoR",
    "_warnings": ["[UoR] Noty: zobowiązania warunkowe (gwarancje, poręczenia, weksle, sprawy sądowe)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_contingent_liabilities", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dane porównawcze i spójność (5 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.consistency.r1",
    "package": "jdg.uor.financial_stmt",
    "priority": 100740,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "BO bieżącego roku ≠ BZ poprzedniego roku — niezgodność danych porównawczych!",
    "_legal_basis": "Art. 46 ust. 1 UoR",
    "_warnings": ["[UoR] Bilans otwarcia ≠ bilans zamknięcia poprzedniego roku! Sprawdź przeksięgowania!"]
} {
    opening_balance := object.get(input.jdg_entrepreneur, "opening_balance_current_year", 0)
    closing_balance_previous := object.get(input.jdg_entrepreneur, "closing_balance_previous_year", 0)
    abs(opening_balance - closing_balance_previous) >= 0.01
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.consistency.r2",
    "package": "jdg.uor.financial_stmt",
    "priority": 100741,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1; Art. 8 UoR",
    "_warnings": ["[UoR] Zasada ciągłości — te same zasady rachunkowości rok do roku (zmiana tylko w uzasadnionych przypadkach)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "accounting_policy_changed", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.consistency.r3",
    "package": "jdg.uor.financial_stmt",
    "priority": 100742,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 49 UoR",
    "_warnings": ["[UoR] Sprawozdanie za I rok działalności — brak danych porównawczych (pola puste)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_first_year", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.financial_stmt.consistency.r4",
    "package": "jdg.uor.financial_stmt",
    "priority": 100743,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 ust. 4 UoR",
    "_warnings": ["[UoR] RZiS netto = Bilans zmiana kapitału własnego (z wyłączeniem wpłat/wypłat właściciela)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    net_profit := object.get(input.jdg_entrepreneur, "uor_net_profit_current_year", 0)
    equity_change := object.get(input.jdg_entrepreneur, "equity_change_excl_owner", 0)
    abs(net_profit - equity_change) < 0.01
}
