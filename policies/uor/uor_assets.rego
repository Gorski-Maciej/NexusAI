# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR Assets Layer: Art. 28b–28h ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)
# Package: jdg.uor.assets — Asset Accounting & Valuation Rules
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: Art. 28b–28h UoR
# Coverage: ~50 rules, ~50 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.assets

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.uor.assets.no_match",
    "package": "jdg.uor.assets",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 28b — Środki trwałe / Fixed Assets (12 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r1",
    "package": "jdg.uor.assets",
    "priority": 100400,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b ust. 1 UoR",
    "_warnings": ["[UoR] Art.28b: Środki trwałe wyceniane według cen nabycia / kosztów wytworzenia pomniejszonych o umorzenie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r2",
    "package": "jdg.uor.assets",
    "priority": 100401,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b ust. 2 UoR",
    "_warnings": ["[UoR] Art.28b: Cena nabycia = cena zakupu + koszty uboczne (transport, montaż, cło, podatki niepodlegające odliczeniu)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r3",
    "package": "jdg.uor.assets",
    "priority": 100402,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b ust. 3 UoR",
    "_warnings": ["[UoR] Art.28b: Koszt wytworzenia = materiały bezpośrednie + robocizna + uzasadnione koszty pośrednie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "asset_source", "") == "SELF_MANUFACTURED"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r4",
    "package": "jdg.uor.assets",
    "priority": 100403,
    "_routing": "WARNING",
    "_routing_reason": "Środek trwały bez naliczonej amortyzacji od >1 miesiąca",
    "_legal_basis": "Art. 28b; Art. 32 UoR",
    "_warnings": ["[UoR] Art.28b: ŚT bez amortyzacji od >1 mies. — nalicz odpis!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    asset_age_months := object.get(input.invoice, "asset_age_months", 0)
    depreciation_booked := object.get(input.invoice, "depreciation_booked", false)
    asset_age_months > 1
    not depreciation_booked
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r5",
    "package": "jdg.uor.assets",
    "priority": 100404,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b ust. 4 UoR",
    "_warnings": ["[UoR] Art.28b: Ulepszenie ŚT — zwiększa wartość początkową jeśli >10 000 PLN"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_improvement", false) == true
    object.get(input.invoice, "amount_net", 0) >= 10000
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r6",
    "package": "jdg.uor.assets",
    "priority": 100405,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b ust. 4 UoR",
    "_warnings": ["[UoR] Art.28b: Remont (nie ulepszenie) — koszt bieżący, NIE zwiększa wartości ŚT"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_improvement", false) == true
    object.get(input.invoice, "amount_net", 0) < 10000
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r7",
    "package": "jdg.uor.assets",
    "priority": 100406,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b ust. 5 UoR",
    "_warnings": ["[UoR] Art.28b: Likwidacja ŚT — wyksięgowanie wartości netto w pozostałe koszty operacyjne"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "asset_disposal_type", "") == "LIQUIDATION"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r8",
    "package": "jdg.uor.assets",
    "priority": 100407,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b ust. 5 UoR",
    "_warnings": ["[UoR] Art.28b: Sprzedaż ŚT — wynik na sprzedaży = cena sprzedaży − wartość netto"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "asset_disposal_type", "") == "SALE"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r9",
    "package": "jdg.uor.assets",
    "priority": 100408,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b; Art. 32 ust. 7 UoR",
    "_warnings": ["[UoR] Art.28b: Nisko-cenne składniki (<10 000 PLN) — jednorazowy odpis w koszty"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "amount_net", 0) < 10000
    object.get(input.invoice, "asset_useful_life_months", 0) > 12
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r10",
    "package": "jdg.uor.assets",
    "priority": 100409,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b; KŚT 2026",
    "_warnings": ["[UoR] Art.28b: Klasyfikacja Środków Trwałych (KŚT) — grupy 0-9"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "kst_group", "") != ""
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r11",
    "package": "jdg.uor.assets",
    "priority": 100410,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28b UoR",
    "_warnings": ["[UoR] Art.28b: Stawki amortyzacji rocznej wg wykazu stawek (załącznik do ustawy PIT/CIT)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28b.r12",
    "package": "jdg.uor.assets",
    "priority": 100411,
    "_routing": "WARNING",
    "_routing_reason": "ŚT całkowicie umorzony — sprawdź czy nadal używany!",
    "_legal_basis": "Art. 28b; Art. 32 UoR",
    "_warnings": ["[UoR] Art.28b: ŚT w pełni umorzony — czy nadal używany? Jeśli tak, umorzenie zatrzymane."]
} {
    net_value := object.get(input.invoice, "asset_net_value", 0)
    gross_value := object.get(input.invoice, "asset_gross_value", 0)
    net_value == 0
    gross_value > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 28c — WNiP / Intangible Assets (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28c.r1",
    "package": "jdg.uor.assets",
    "priority": 100420,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28c UoR; Art. 22b PIT",
    "_warnings": ["[UoR] Art.28c: WNiP — patenty, licencje, prawa autorskie, know-how, goodwill, koszty prac rozwojowych"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "asset_type", "TANGIBLE") == "INTANGIBLE"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28c.r2",
    "package": "jdg.uor.assets",
    "priority": 100421,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28c ust. 2 UoR",
    "_warnings": ["[UoR] Art.28c: WNiP amortyzowane przez okres ekonomicznej użyteczności (max 5 lat dla goodwill)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "intangible_type", "") == "GOODWILL"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28c.r3",
    "package": "jdg.uor.assets",
    "priority": 100422,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28c ust. 3 UoR",
    "_warnings": ["[UoR] Art.28c: Koszty prac rozwojowych — aktywowane jeśli spełnione kryteria (Art. 33 ust. 2)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "intangible_type", "") == "R_AND_D"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28c.r4",
    "package": "jdg.uor.assets",
    "priority": 100423,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28c ust. 4 UoR",
    "_warnings": ["[UoR] Art.28c: Test na utratę wartości WNiP — corocznie dla goodwill i WNiP nieoddanych do użytku"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    object.get(input.invoice, "intangible_type", "") == "GOODWILL"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28c.r5",
    "package": "jdg.uor.assets",
    "priority": 100424,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28c UoR",
    "_warnings": ["[UoR] Art.28c: Oprogramowanie komputerowe — jako WNiP lub usługa obca w zależności od licencji"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "intangible_type", "") == "SOFTWARE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 28d — Należności / Receivables (5 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28d.r1",
    "package": "jdg.uor.assets",
    "priority": 100430,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28d ust. 1 UoR",
    "_warnings": ["[UoR] Art.28d: Należności — wartość nominalna z uwzględnieniem odpisów aktualizujących"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_receivable", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28d.r2",
    "package": "jdg.uor.assets",
    "priority": 100431,
    "_routing": "WARNING",
    "_routing_reason": "Należność przeterminowana >180 dni — wymaga odpisu aktualizującego!",
    "_legal_basis": "Art. 28d ust. 2; Art. 35b UoR",
    "_warnings": ["[UoR] Art.28d: Należność >180 dni po terminie — utwórz odpis aktualizujący (100%)!"]
} {
    overdue_days := object.get(input.invoice, "payment_overdue_days", 0)
    impairment_booked := object.get(input.invoice, "receivable_impairment_booked", false)
    overdue_days > 180
    not impairment_booked
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28d.r3",
    "package": "jdg.uor.assets",
    "priority": 100432,
    "_routing": "WARNING",
    "_routing_reason": "Należność przeterminowana 90-180 dni — rozważ odpis 50%!",
    "_legal_basis": "Art. 28d ust. 2 UoR",
    "_warnings": ["[UoR] Art.28d: Należność 90-180 dni po terminie — rozważ odpis 50%"]
} {
    overdue_days := object.get(input.invoice, "payment_overdue_days", 0)
    impairment_booked := object.get(input.invoice, "receivable_impairment_booked", false)
    overdue_days >= 90
    overdue_days <= 180
    not impairment_booked
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28d.r4",
    "package": "jdg.uor.assets",
    "priority": 100433,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28d ust. 3 UoR",
    "_warnings": ["[UoR] Art.28d: Należności w walutach obcych — wycena bilansowa wg kursu NBP"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "currency", "PLN") != "PLN"
    object.get(input.invoice, "is_receivable", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28d.r5",
    "package": "jdg.uor.assets",
    "priority": 100434,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28d; KSR 4",
    "_warnings": ["[UoR] Art.28d: Odpis aktualizujący — odwracany gdy ustanie przyczyna (przywrócenie wartości)"]
} {
    impairment_booked := object.get(input.invoice, "receivable_impairment_booked", false)
    payment_received := object.get(input.invoice, "payment_received_after_impairment", false)
    impairment_booked
    payment_received
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 28e — Inwestycje krótkoterminowe / Short-term Investments (4 reguły)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28e.r1",
    "package": "jdg.uor.assets",
    "priority": 100440,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28e UoR",
    "_warnings": ["[UoR] Art.28e: Inwestycje krótkoterminowe — aktywa finansowe przeznaczone do obrotu (<12 mies.)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_short_term_investment", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28e.r2",
    "package": "jdg.uor.assets",
    "priority": 100441,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28e ust. 2 UoR",
    "_warnings": ["[UoR] Art.28e: Wycena — wartość rynkowa lub cena nabycia (niższa z dwóch)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_short_term_investment", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.a28e.r3",
    "package": "jdg.uor.assets",
    "priority": 100442,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28e; Art. 35 ust. 3 UoR",
    "_warnings": ["[UoR] Art.28e: Skutki wyceny inwestycji — do przychodów/kosztów finansowych"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# KŚT — Klasyfikacja Środków Trwałych (8 reguł)
# UWAGA: Kanoniczna definicja KŚT w micro/uor/uor.rego. Ten plik zawiera
# enterprise-level rozszerzenie z dodatkowymi polami (depreciation_rate, kst_group).
# W przypadku konfliktu, micro/uor/uor.rego ma pierwszeństwo dla JDG poniżej 2M EUR.
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.kst.group0.r1",
    "package": "jdg.uor.assets",
    "priority": 100450,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "KŚT Grupa 0",
    "_warnings": ["[UoR] KŚT 0: Grunty, prawo wieczystego użytkowania — NIE podlegają amortyzacji!"],
    "depreciation_rate": 0.00,
    "kst_group": 0
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "kst_group", -1) == 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.kst.group1.r1",
    "package": "jdg.uor.assets",
    "priority": 100451,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "KŚT Grupa 1",
    "_warnings": ["[UoR] KŚT 1: Budynki i lokale — stawka 2.5% rocznie (40 lat)"],
    "depreciation_rate": 2.5,
    "kst_group": 1
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "kst_group", -1) == 1
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.kst.group3.r1",
    "package": "jdg.uor.assets",
    "priority": 100452,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "KŚT Grupa 3",
    "_warnings": ["[UoR] KŚT 3: Kotły i maszyny energetyczne — stawka 7% rocznie"],
    "depreciation_rate": 7.0,
    "kst_group": 3
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "kst_group", -1) == 3
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.kst.group4.r1",
    "package": "jdg.uor.assets",
    "priority": 100453,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "KŚT Grupa 4",
    "_warnings": ["[UoR] KŚT 4: Maszyny i urządzenia — stawka 14% rocznie"],
    "depreciation_rate": 14.0,
    "kst_group": 4
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "kst_group", -1) == 4
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.kst.group5.r1",
    "package": "jdg.uor.assets",
    "priority": 100454,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "KŚT Grupa 5",
    "_warnings": ["[UoR] KŚT 5: Maszyny specjalne — stawka 18% rocznie"],
    "depreciation_rate": 18.0,
    "kst_group": 5
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "kst_group", -1) == 5
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.kst.group6.r1",
    "package": "jdg.uor.assets",
    "priority": 100455,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "KŚT Grupa 6",
    "_warnings": ["[UoR] KŚT 6: Urządzenia techniczne — stawka 10% rocznie"],
    "depreciation_rate": 10.0,
    "kst_group": 6
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "kst_group", -1) == 6
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.kst.group7.r1",
    "package": "jdg.uor.assets",
    "priority": 100456,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "KŚT Grupa 7",
    "_warnings": ["[UoR] KŚT 7: Środki transportu — stawka 20% rocznie (osobowe), 14% (ciężarowe)"],
    "depreciation_rate": 20.0,
    "kst_group": 7
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "kst_group", -1) == 7
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.assets.kst.group8.r1",
    "package": "jdg.uor.assets",
    "priority": 100457,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "KŚT Grupa 8",
    "_warnings": ["[UoR] KŚT 8: Narzędzia, przyrządy, wyposażenie — stawka 20% rocznie"],
    "depreciation_rate": 20.0,
    "kst_group": 8
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "kst_group", -1) == 8
}
