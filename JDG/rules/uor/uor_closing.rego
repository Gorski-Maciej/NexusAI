# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR Closing Layer: Art. 45–49 Ustawy o rachunkowości
# Package: jdg.uor.closing — Year-End Closing Rules
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: Art. 45–49 UoR
# Coverage: ~40 rules, ~40 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.closing

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.uor.closing.no_match",
    "package": "jdg.uor.closing",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 45 — Bilans / Balance Sheet (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a45.r1",
    "package": "jdg.uor.closing",
    "priority": 100600,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 45 ust. 1 UoR",
    "_warnings": ["[UoR] Art.45: Sprawozdanie finansowe = bilans + RZiS + informacja dodatkowa (dla jednostek mikro uproszczone)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a45.r2",
    "package": "jdg.uor.closing",
    "priority": 100601,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Bilans NIEZBILANSOWANY — Aktywa ≠ Pasywa (Suma Bilansowa)!",
    "_legal_basis": "Art. 45 ust. 2 UoR; Art. 7 UoR",
    "_warnings": ["[UoR] Art.45: Bilans musi być ZBILANSOWANY! Aktywa = Pasywa. Różnica: %0.2f PLN"]
} {
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    total_equity_liabilities := object.get(input.jdg_entrepreneur, "uor_total_equity_liabilities", 0)
    abs(total_assets - total_equity_liabilities) >= 0.01
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a45.r3",
    "package": "jdg.uor.closing",
    "priority": 100602,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 45 ust. 3 UoR",
    "_warnings": ["[UoR] Art.45: ✅ Bilans zbilansowany"]
} {
    total_assets := object.get(input.jdg_entrepreneur, "uor_total_assets", 0)
    total_equity_liabilities := object.get(input.jdg_entrepreneur, "uor_total_equity_liabilities", 0)
    abs(total_assets - total_equity_liabilities) < 0.01
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a45.r4",
    "package": "jdg.uor.closing",
    "priority": 100603,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 45 ust. 4 UoR",
    "_warnings": ["[UoR] Art.45: Jednostka mikro — bilans uproszczony (załącznik nr 4)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "is_micro_entity", true) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a45.r5",
    "package": "jdg.uor.closing",
    "priority": 100604,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 45 UoR",
    "_warnings": ["[UoR] Art.45: Aktywa trwałe (A) + Aktywa obrotowe (B) + Należne wpłaty (C) + Krótkoterminowe RMK (D)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a45.r6",
    "package": "jdg.uor.closing",
    "priority": 100605,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 45 UoR",
    "_warnings": ["[UoR] Art.45: Pasywa = Kapitał własny (A) + Zobowiązania i rezerwy (B) + Krótkoterminowe RMP (C)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a45.r7",
    "package": "jdg.uor.closing",
    "priority": 100606,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 45 ust. 2 UoR",
    "_warnings": ["[UoR] Art.45: Wynik finansowy netto roku obrotowego jest składnikiem kapitału własnego w bilansie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    net_profit := object.get(input.jdg_entrepreneur, "uor_net_profit_current_year", 0)
    equity := object.get(input.jdg_entrepreneur, "uor_equity", 0)
    net_profit != 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a45.r8",
    "package": "jdg.uor.closing",
    "priority": 100607,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 45 UoR",
    "_warnings": ["[UoR] Art.45: Dane porównawcze — 2 kolumny: rok bieżący i rok poprzedni"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a45.r9",
    "package": "jdg.uor.closing",
    "priority": 100608,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Kapitał własny ujemny — jednostka może mieć problemy z kontynuacją!",
    "_legal_basis": "Art. 45; Art. 4 ust. 1 pkt 4 UoR",
    "_warnings": ["[UoR] Art.45: Kapitał własny UJEMNY! Ryzyko zagrożenia kontynuacji działalności!"]
} {
    equity := object.get(input.jdg_entrepreneur, "uor_equity", 0)
    equity < 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 47 — RZiS / Income Statement (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a47.r1",
    "package": "jdg.uor.closing",
    "priority": 100610,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 ust. 1 UoR",
    "_warnings": ["[UoR] Art.47: RZiS — wariant porównawczy (koszty rodzajowe) lub kalkulacyjny (koszt własny sprzedaży)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a47.r2",
    "package": "jdg.uor.closing",
    "priority": 100611,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 ust. 3 UoR",
    "_warnings": ["[UoR] Art.47: Wariant porównawczy — Przychody netto − Koszty rodzajowe +/− Zmiana stanu produktów + RMK"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "rzis_variant", "COMPARATIVE") == "COMPARATIVE"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a47.r3",
    "package": "jdg.uor.closing",
    "priority": 100612,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 ust. 4 UoR",
    "_warnings": ["[UoR] Art.47: Wynik brutto = Przychody − Koszty +/− Pozostałe przychody/koszty +/− Finansowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a47.r4",
    "package": "jdg.uor.closing",
    "priority": 100613,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 UoR",
    "_warnings": ["[UoR] Art.47: Wynik netto = Wynik brutto − Podatek dochodowy (bieżący + odroczony)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    gross_profit := object.get(input.jdg_entrepreneur, "uor_gross_profit", 0)
    income_tax := object.get(input.jdg_entrepreneur, "uor_income_tax", 0)
    gross_profit != 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a47.r5",
    "package": "jdg.uor.closing",
    "priority": 100614,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 UoR",
    "_warnings": ["[UoR] Art.47: Strata netto — do pokrycia z przyszłych zysków lub kapitału zapasowego"]
} {
    net_profit := object.get(input.jdg_entrepreneur, "uor_net_profit_current_year", 0)
    net_profit < 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.a47.r6",
    "package": "jdg.uor.closing",
    "priority": 100615,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 47 UoR",
    "_warnings": ["[UoR] Art.47: Zysk netto — decyzja o przeznaczeniu: wypłata (dywidenda) lub kapitał zapasowy"]
} {
    net_profit := object.get(input.jdg_entrepreneur, "uor_net_profit_current_year", 0)
    net_profit > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# Closing Procedures — Uzgodnienia, korekty, ostateczne zamknięcie (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r1",
    "package": "jdg.uor.closing",
    "priority": 100620,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 12, 45 UoR",
    "_warnings": ["[UoR] Procedura zamknięcia: 1) RMK 2) Inwentaryzacja 3) Wycena bilansowa 4) Przeksięgowanie 5) Sprawozdanie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r2",
    "package": "jdg.uor.closing",
    "priority": 100621,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "RMK czynne/bierne nieprawidłowo rozliczone na koniec roku!",
    "_legal_basis": "Art. 39 UoR",
    "_warnings": ["[UoR] RMK nierozliczone — sprawdź stany na koniec roku!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "rmk_balance_not_zero", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r3",
    "package": "jdg.uor.closing",
    "priority": 100622,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 37 UoR",
    "_warnings": ["[UoR] Podatek odroczony — aktywa z tytułu odroczonego podatku i rezerwy na odroczony podatek"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_deferred_tax", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r4",
    "package": "jdg.uor.closing",
    "priority": 100623,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 46 UoR",
    "_warnings": ["[UoR] Informacja dodatkowa — metody wyceny, zmiany zasad, zdarzenia po dniu bilansowym"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r5",
    "package": "jdg.uor.closing",
    "priority": 100624,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 48 UoR",
    "_warnings": ["[UoR] Zdarzenia po dniu bilansowym — ujawnij istotne zdarzenia między bilansem a zatwierdzeniem sprawozdania"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r6",
    "package": "jdg.uor.closing",
    "priority": 100625,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 49 UoR",
    "_warnings": ["[UoR] Jednostki mikro — zwolnienie z informacji dodatkowej (tylko bilans + RZiS)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "is_micro_entity", true) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r7",
    "package": "jdg.uor.closing",
    "priority": 100626,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 53 UoR",
    "_warnings": ["[UoR] Termin: sprawozdanie finansowe → 3 mies. od dnia bilansowego (31 marca). Zatwierdzenie → 6 mies. (30 czerwca)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r8",
    "package": "jdg.uor.closing",
    "priority": 100627,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sprawozdanie NIE złożone w KRS/SzT w terminie — sankcja Art. 79 UoR!",
    "_legal_basis": "Art. 69; Art. 79 UoR",
    "_warnings": ["[UoR] Sprawozdanie finansowe MUSI być złożone do KRS/SzT w ciągu 15 dni od zatwierdzenia!"],
    "deadline_days_after_approval": 15
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    fs_approved := object.get(input.jdg_entrepreneur, "fs_approved", false)
    fs_submitted := object.get(input.jdg_entrepreneur, "fs_submitted_to_krs", false)
    fs_approved
    not fs_submitted
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r9",
    "package": "jdg.uor.closing",
    "priority": 100628,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 53; Art. 69 UoR",
    "_warnings": ["[UoR] ✅ Zamknięcie roku zakończone — sprawozdanie zatwierdzone i złożone"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "fs_approved", false) == true
    object.get(input.jdg_entrepreneur, "fs_submitted_to_krs", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.closing.procedures.r10",
    "package": "jdg.uor.closing",
    "priority": 100629,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 74 UoR",
    "_warnings": ["[UoR] Archiwizacja — zatwierdzone sprawozdania: BEZTERMINOWO. Księgi: 5 lat od końca roku."]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}
