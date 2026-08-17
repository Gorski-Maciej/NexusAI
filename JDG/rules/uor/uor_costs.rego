# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR Costs Layer: Art. 35–42 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)
# Package: jdg.uor.costs — Cost Accounting Rules
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: Art. 35–42 UoR
# Coverage: ~70 rules, ~70 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.costs

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.uor.costs.no_match",
    "package": "jdg.uor.costs",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 35–38 — Koszty działalności operacyjnej (25 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.uor.costs.a35.r1",
    "package": "jdg.uor.costs",
    "priority": 100300,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 35 UoR; ZPK konta 4xx",
    "_warnings": ["[UoR] Art.35: Koszty w układzie rodzajowym — amortyzacja, materiały, energia, usługi obce, podatki, wynagrodzenia, ubezpieczenia, pozostałe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.depreciation.r1",
    "package": "jdg.uor.costs",
    "priority": 100301,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32; ZPK konto 400",
    "_warnings": ["[UoR] Amortyzacja — konto 400. Systematyczny odpis wartości środków trwałych i WNiP"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "DEPRECIATION"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.materials.r1",
    "package": "jdg.uor.costs",
    "priority": 100302,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 401",
    "_warnings": ["[UoR] Zużycie materiałów i energii — konto 401"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_type", "") == "MATERIALS"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.external_services.r1",
    "package": "jdg.uor.costs",
    "priority": 100303,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 402",
    "_warnings": ["[UoR] Usługi obce — konto 402 (najem, transport, telekom, prawnicze, księgowe, IT)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_type", "") == "EXTERNAL_SERVICES"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.taxes_charges.r1",
    "package": "jdg.uor.costs",
    "priority": 100304,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 403",
    "_warnings": ["[UoR] Podatki i opłaty — konto 403 (PCC, akcyza, podatek od nieruchomości, opłaty)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_type", "") == "TAXES_CHARGES"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.salaries.r1",
    "package": "jdg.uor.costs",
    "priority": 100305,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 404",
    "_warnings": ["[UoR] Wynagrodzenia — konto 404. Brutto + składki ZUS pracodawcy"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_type", "") == "SALARIES"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.social_insurance.r1",
    "package": "jdg.uor.costs",
    "priority": 100306,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 405",
    "_warnings": ["[UoR] Ubezpieczenia społeczne i inne świadczenia — konto 405"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_type", "") == "SOCIAL_INSURANCE"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.other_basic.r1",
    "package": "jdg.uor.costs",
    "priority": 100307,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 409",
    "_warnings": ["[UoR] Pozostałe koszty rodzajowe — konto 409 (podróże, reprezentacja, reklama limitowana)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_type", "") == "OTHER"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.cogs.r1",
    "package": "jdg.uor.costs",
    "priority": 100308,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 731 / 530",
    "_warnings": ["[UoR] Wartość sprzedanych towarów (WST) — konto 731. Koszt własny sprzedaży"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_cogs", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.other_operating.r1",
    "package": "jdg.uor.costs",
    "priority": 100309,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 751-761",
    "_warnings": ["[UoR] Pozostałe koszty operacyjne — konta 751-761 (kary, odszkodowania, darowizny, strata ze zbycia)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_type", "") == "OTHER_OPERATING"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.financial.r1",
    "package": "jdg.uor.costs",
    "priority": 100310,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 751",
    "_warnings": ["[UoR] Koszty finansowe — odsetki, prowizje bankowe, ujemne różnice kursowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_type", "") == "FINANCIAL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Cost Timing — Memoriałowe ujęcie kosztów (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.timing.accrual.r1",
    "package": "jdg.uor.costs",
    "priority": 100320,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 ust. 1 pkt 1 UoR",
    "_warnings": ["[UoR] Koszty memoriałowo — w okresie, którego dotyczą (NIE w dacie zapłaty!)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_expense", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.timing.prepaid.r1",
    "package": "jdg.uor.costs",
    "priority": 100321,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 39 ust. 1 UoR",
    "_warnings": ["[UoR] RMK czynne — koszty zapłacone z góry, dotyczące przyszłych okresów (konto 640)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_prepaid_expense", false) == true
    service_period_month := object.get(input.invoice, "service_period_month", 0)
    transaction_month := object.get(input.invoice, "transaction_month", 0)
    service_period_month > transaction_month
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.timing.accrued.r1",
    "package": "jdg.uor.costs",
    "priority": 100322,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 39 ust. 2 UoR",
    "_warnings": ["[UoR] RMK bierne — koszty dotyczące bieżącego okresu, jeszcze nie zapłacone (konto 641/647)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_accrued_expense", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.timing.reserves.r1",
    "package": "jdg.uor.costs",
    "priority": 100323,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 35d UoR; KSR 6",
    "_warnings": ["[UoR] Rezerwy na zobowiązania — znane ryzyka, przyszłe zobowiązania (konto 640/647)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_provision", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.cash_basis_violation.r1",
    "package": "jdg.uor.costs",
    "priority": 100324,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Koszty w metodzie kasowej — NIEZGODNE z UoR!",
    "_legal_basis": "Art. 4 ust. 1 pkt 1 UoR",
    "_warnings": ["[UoR] Metoda kasowa NIEZGODNA z UoR — koszty w okresie, którego dotyczą!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_uses_cash_method", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.leasing.r1",
    "package": "jdg.uor.costs",
    "priority": 100325,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 4-6 UoR; KSR 5",
    "_warnings": ["[UoR] Leasing — finansowy: aktywowanie w bilansie + amortyzacja + odsetki; operacyjny: w koszty"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_lease", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.leasing.finance.r1",
    "package": "jdg.uor.costs",
    "priority": 100326,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Leasing finansowy — przedmiot NIE wykazany w bilansie!",
    "_legal_basis": "Art. 3 ust. 4 UoR",
    "_warnings": ["[UoR] Leasing finansowy — przedmiot MUSI być w aktywach (ŚT) + zobowiązanie w pasywach!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_finance_lease", false) == true
    object.get(input.invoice, "asset_on_balance_sheet", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.representation.r1",
    "package": "jdg.uor.costs",
    "priority": 100327,
    "_routing": "WARNING",
    "_routing_reason": "Reprezentacja — limitowana 0.25% przychodu dla celów PIT!",
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT",
    "_warnings": ["[UoR] Reprezentacja — w UoR pełny koszt, ale limit NKUP dla PIT (Art. 23 PIT)!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "expense_type", "") == "REPRESENTATION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Cost Allocation — Układ kalkulacyjny (wariant kalkulacyjny RZiS) (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.allocation.direct.r1",
    "package": "jdg.uor.costs",
    "priority": 100330,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konta 5xx",
    "_warnings": ["[UoR] Koszty bezpośrednie — dające się przypisać do konkretnego produktu/usługi"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_allocation", "") == "DIRECT"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.allocation.indirect.r1",
    "package": "jdg.uor.costs",
    "priority": 100331,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 520-530",
    "_warnings": ["[UoR] Koszty pośrednie — wydziałowe, zarządu, sprzedaży — rozliczane kluczem"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "cost_allocation", "") == "INDIRECT"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.pkpir_comparison.r1",
    "package": "jdg.uor.costs",
    "priority": 100332,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 24a PIT vs Art. 35 UoR",
    "_warnings": ["[UoR] RÓŻNICA PKPiR vs UoR: PKPiR = metoda kasowa (kol.10-17), UoR = memoriałowa (wszystkie koszty)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.nkup.r1",
    "package": "jdg.uor.costs",
    "priority": 100333,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 PIT",
    "_warnings": ["[UoR] NKUP — w UoR są kosztem księgowym, ale NIE są kosztem podatkowym w PIT"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_nkup", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.car_usage.r1",
    "package": "jdg.uor.costs",
    "priority": 100334,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 46 PIT; Art. 35 UoR",
    "_warnings": ["[UoR] Auto prywatne w firmie — koszty UoR: 100% (z kilometrówką), PIT: 20%/75%/100%"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "expense_type", "") == "CAR_USAGE"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.one_off_writeoff.r1",
    "package": "jdg.uor.costs",
    "priority": 100335,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22d PIT; Art. 32 ust. 7 UoR",
    "_warnings": ["[UoR] Jednorazowa amortyzacja — dozwolona dla małych podatników i nowych ŚT (do 100k PLN)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_one_off_depreciation", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.costs.donation.r1",
    "package": "jdg.uor.costs",
    "priority": 100336,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 42 UoR",
    "_warnings": ["[UoR] Darowizny — koszt księgowy, ale limitowane w PIT (6% dochodu)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "expense_type", "") == "DONATION"
}
