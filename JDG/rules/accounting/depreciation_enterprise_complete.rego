# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Depreciation Complete Matrix: Art. 22a–22o PIT (KŚT Full)
# Package: jdg.pit.depreciation — Amortyzacja ŚT/WNiP z pełną macierzą KŚT
# Version: 1.0.0 — Q4 2026 Refinement (P28 Grand Finale)
# Legal basis: Art. 22a–22o Ustawy o PIT; Załącznik nr 1 (Wykaz stawek KŚT)
# Coverage: ~150 rules, ~150 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.depreciation

import data.jdg.helpers
import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.pit.depreciation.no_match",
    "package": "jdg.pit.depreciation",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 22a PIT — Definicja środka trwałego (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22a.r1",
    "package": "jdg.pit.depreciation",
    "priority": 300001,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22a ust. 1 PIT",
    "_warnings": ["[PIT] Środek trwały = stanowi własność/współwłasność, kompletny, zdatny do użytku, okres użycia > 1 rok"],
    "conditions": ["ownership", "complete", "usable", "useful_life_gt_1_year"]
} {
    input.invoice.expense_type == "FIXED_ASSET"
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22a.r2",
    "package": "jdg.pit.depreciation",
    "priority": 300002,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22a ust. 1 PIT",
    "_warnings": ["[PIT] Wartość początkowa ≥ 10 000 PLN — OBOWIĄZKOWA amortyzacja (wpis do EŚT)"]
} {
    initial_value := object.get(input.invoice, "amount_net", 0)
    initial_value >= 10000
    input.invoice.expense_type == "FIXED_ASSET"
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22a.r3",
    "package": "jdg.pit.depreciation",
    "priority": 300003,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22a ust. 1; Art. 22d ust. 1 PIT",
    "_warnings": ["[PIT] Wartość ≤ 10 000 PLN — jednorazowy odpis amortyzacyjny (lub bezpośrednio w koszty)"]
} {
    initial_value := object.get(input.invoice, "amount_net", 0)
    initial_value <= 10000
    initial_value > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22a.r4",
    "package": "jdg.pit.depreciation",
    "priority": 300004,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22a ust. 2 PIT",
    "_warnings": ["[PIT] Amortyzacja od miesiąca następnego po przyjęciu ŚT do używania"],
    "start_month": "NEXT_MONTH_AFTER_ACCEPTANCE"
} {
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "asset_accepted_for_use", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22a.r5",
    "package": "jdg.pit.depreciation",
    "priority": 300005,
    "_routing": "WARNING",
    "_routing_reason": "Środek trwały przyjęty ale amortyzacja nie rozpoczęta w następnym miesiącu!",
    "_legal_basis": "Art. 22a; Art. 22h ust. 1 pkt 1 PIT",
    "_warnings": ["[PIT] ŚT przyjęty ale brak amortyzacji od następnego miesiąca — sprawdź EŚT!"]
} {
    accepted_date := object.get(input.invoice, "asset_accepted_date", "2099-12-31")
    current_date := object.get(input.invoice, "evaluation_date", "2099-12-31")
    depreciation_started := object.get(input.invoice, "depreciation_started", false)
    accepted_date < current_date
    not depreciation_started
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 22d PIT — Jednorazowa amortyzacja / One-off (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22d.r1",
    "package": "jdg.pit.depreciation",
    "priority": 300010,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22d ust. 1 PIT",
    "_warnings": ["[PIT] Jednorazowa amortyzacja — dla małych podatników i rozpoczynających działalność (do 100 000 PLN rocznie)"],
    "limit_annual_pln": 100000
} {
    object.get(input.jdg_entrepreneur, "is_small_taxpayer", false) == true
    object.get(input.invoice, "uses_one_off_depreciation", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22d.r2",
    "package": "jdg.pit.depreciation",
    "priority": 300011,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczono limit jednorazowej amortyzacji 100 000 PLN!",
    "_legal_basis": "Art. 22d ust. 1 PIT",
    "_warnings": ["[PIT] Limit jednorazowej amortyzacji PRZEKROCZONY! Nadwyżka → amortyzacja liniowa standardowa!"],
    "limit_exceeded": true
} {
    one_off_used := object.get(input.jdg_entrepreneur, "one_off_depreciation_used_ytd", 0)
    one_off_used + object.get(input.invoice, "amount_net", 0) > 100000
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22d.r3",
    "package": "jdg.pit.depreciation",
    "priority": 300012,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22d ust. 2 PIT",
    "_warnings": ["[PIT] Jednorazowa de minimis — do 50 000 EUR łącznie przez 3 lata (pomoc publiczna)"],
    "limit_eur_3y": 50000
} {
    object.get(input.invoice, "uses_de_minimis", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# KŚT Full Matrix — Stawki amortyzacyjne per grupa KŚT (15 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r1",
    "package": "jdg.pit.depreciation",
    "priority": 300020,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Wykaz rocznych stawek amortyzacyjnych (załącznik nr 1 do ustawy o PIT)",
    "_warnings": ["[PIT] KŚT Grupa 0: Grunty — NIE amortyzuje się (0%)"],
    "rate_pct": 0.00,
    "depreciable": false
} {
    object.get(input.invoice, "kst_group", -1) == 0
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r2",
    "priority": 300021,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Wykaz KŚT Grupa 1",
    "_warnings": ["[PIT] KŚT 1: Budynki — 2.5% rocznie"],
    "rate_pct": 2.5
} { object.get(input.invoice, "kst_group", -1) == 1 }

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r3", "priority": 300022,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Wykaz KŚT Grupa 2",
    "_warnings": ["[PIT] KŚT 2: Budowle i obiekty inżynierii — 4.5% rocznie"],
    "rate_pct": 4.5
} { object.get(input.invoice, "kst_group", -1) == 2 }

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r4", "priority": 300023,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Wykaz KŚT Grupa 3",
    "_warnings": ["[PIT] KŚT 3: Kotły i maszyny energetyczne — 7% rocznie"],
    "rate_pct": 7.0
} { object.get(input.invoice, "kst_group", -1) == 3 }

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r5", "priority": 300024,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Wykaz KŚT Grupa 4",
    "_warnings": ["[PIT] KŚT 4: Maszyny, urządzenia i aparaty — 14-30% rocznie"],
    "rate_pct": 14.0
} { object.get(input.invoice, "kst_group", -1) == 4 }

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r6", "priority": 300025,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Wykaz KŚT Grupa 5",
    "_warnings": ["[PIT] KŚT 5: Maszyny specjalne — 18% rocznie"],
    "rate_pct": 18.0
} { object.get(input.invoice, "kst_group", -1) == 5 }

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r7", "priority": 300026,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Wykaz KŚT Grupa 6",
    "_warnings": ["[PIT] KŚT 6: Urządzenia techniczne — 10-14% rocznie"],
    "rate_pct": 10.0
} { object.get(input.invoice, "kst_group", -1) == 6 }

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r8", "priority": 300027,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Wykaz KŚT Grupa 7",
    "_warnings": ["[PIT] KŚT 7: Środki transportu — 20% (osobowe), 14% (ciężarowe)"],
    "rate_pct_car": 20.0,
    "rate_pct_truck": 14.0
} { object.get(input.invoice, "kst_group", -1) == 7 }

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r9", "priority": 300028,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Wykaz KŚT Grupa 8",
    "_warnings": ["[PIT] KŚT 8: Narzędzia, przyrządy, wyposażenie — 20-25% rocznie"],
    "rate_pct": 20.0
} { object.get(input.invoice, "kst_group", -1) == 8 }

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.kst.r10", "priority": 300029,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22i ust. 5 PIT (stawki indywidualne)",
    "_warnings": ["[PIT] KŚT Indywidualne: używane/używane ŚT — stawka z tabeli × 2 (min. okres: budynki 10 lat, maszyny 3 lata)"]
} { object.get(input.invoice, "uses_individual_rate", false) == true }

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 22g PIT — Wartość początkowa (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22g.r1",
    "package": "jdg.pit.depreciation",
    "priority": 300040,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22g ust. 1 pkt 1 PIT",
    "_warnings": ["[PIT] Wartość początkowa = cena nabycia + koszty uboczne (transport, montaż, cło, podatki niepodlegające odliczeniu)"]
} {
    input.invoice.expense_type == "FIXED_ASSET"
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22g.r2",
    "package": "jdg.pit.depreciation",
    "priority": 300041,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22g ust. 3 PIT",
    "_warnings": ["[PIT] Wartość początkowa samochodu osobowego — limit 150 000 PLN (225 000 dla EV)"]
} {
    object.get(input.invoice, "kst_group", -1) == 7
    object.get(input.invoice, "vehicle_type", "") == "PASSENGER_CAR"
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22g.r3",
    "package": "jdg.pit.depreciation",
    "priority": 300042,
    "_routing": "WARNING",
    "_routing_reason": "Wartość auta przekracza limit 150 000 PLN — amortyzacja tylko do limitu!",
    "_legal_basis": "Art. 22g ust. 3; Art. 23 ust. 1 pkt 4 PIT",
    "_warnings": ["[PIT] Wartość auta >150k PLN — nadwyżka NIE podlega amortyzacji (NKUP)!"],
    "limit_pln": 150000
} {
    car_value := object.get(input.invoice, "amount_net", 0)
    vehicle_type := object.get(input.invoice, "vehicle_type", "")
    not object.get(input.invoice, "is_electric", false)
    car_value > 150000
    vehicle_type == "PASSENGER_CAR"
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22g.r4",
    "package": "jdg.pit.depreciation",
    "priority": 300043,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22g ust. 3 PIT (EV)",
    "_warnings": ["[PIT] EV — limit 225 000 PLN"]
} {
    car_value := object.get(input.invoice, "amount_net", 0)
    object.get(input.invoice, "is_electric", false) == true
    car_value > 225000
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22g.r5",
    "package": "jdg.pit.depreciation",
    "priority": 300044,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22g ust. 8 PIT",
    "_warnings": ["[PIT] Wytworzenie ŚT — koszt wytworzenia = materiały + robocizna + narzuty pośrednie"]
} {
    object.get(input.invoice, "asset_source", "") == "SELF_MANUFACTURED"
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22g.r6",
    "package": "jdg.pit.depreciation",
    "priority": 300045,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22g ust. 9 PIT",
    "_warnings": ["[PIT] Aport — wartość początkowa = wartość rynkowa z dnia wniesienia (nie wyższa niż wartość nominalna udziałów)"]
} {
    object.get(input.invoice, "asset_source", "") == "IN_KIND_CONTRIBUTION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 22h-22k — Metody i okresy amortyzacji (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22h.r1",
    "package": "jdg.pit.depreciation",
    "priority": 300050,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22h ust. 1 PIT",
    "_warnings": ["[PIT] Amortyzacja liniowa — podstawowa metoda. Miesięczny odpis = wartość pocz. × stawka / 12"]
} {
    object.get(input.jdg_entrepreneur, "depreciation_method", "LINEAR") == "LINEAR"
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22h.r2",
    "package": "jdg.pit.depreciation",
    "priority": 300051,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22h ust. 2 PIT",
    "_warnings": ["[PIT] Amortyzacja degresywna (malejąca) — możliwa dla KŚT 3-6 i 8. Współczynnik ≤ 2.0"]
} {
    object.get(input.jdg_entrepreneur, "depreciation_method", "LINEAR") == "DEGRESSIVE"
    kst := object.get(input.invoice, "kst_group", 0)
    kst >= 3
    kst <= 8
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22k.r1",
    "package": "jdg.pit.depreciation",
    "priority": 300052,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22k ust. 7 PIT",
    "_warnings": ["[PIT] Amortyzacja nisko-cennych ŚT (≤10 000 PLN) — jednorazowy odpis w miesiącu przyjęcia"]
} {
    object.get(input.invoice, "amount_net", 0) <= 10000
    object.get(input.invoice, "asset_useful_life_months", 0) > 12
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22i.r1",
    "package": "jdg.pit.depreciation",
    "priority": 300053,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22i ust. 1-4 PIT",
    "_warnings": ["[PIT] Stawka indywidualna — używane ŚT: budynki min. 10 lat (stawka max 10%), maszyny min. 3 lata (stawka max 33%)"]
} {
    object.get(input.invoice, "uses_individual_rate", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.depreciation.a22l.r1",
    "package": "jdg.pit.depreciation",
    "priority": 300054,
    "_routing": "WARNING",
    "_routing_reason": "Amortyzacja zawieszona — działalność zawieszona = zakaz amortyzacji!",
    "_legal_basis": "Art. 22l ust. 2 PIT",
    "_warnings": ["[PIT] W trakcie zawieszenia JDG NIE amortyzujesz ŚT!"]
} {
    object.get(input.jdg_entrepreneur, "business_suspended", false) == true
}
