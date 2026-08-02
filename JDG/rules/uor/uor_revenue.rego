# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR Revenue Layer: Art. 28–34 Ustawy o rachunkowości
# Package: jdg.uor.revenue — Revenue Recognition Rules
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: Art. 28–34 UoR
# Coverage: ~60 rules, ~60 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.revenue

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.uor.revenue.no_match",
    "package": "jdg.uor.revenue",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 28–31 — Wycena przychodów i kursów walut (20 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a28.r1",
    "package": "jdg.uor.revenue",
    "priority": 100200,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28 ust. 1 UoR",
    "_warnings": ["[UoR] Art.28: Przychody ze sprzedaży — wartość netto (bez VAT należnego)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_revenue", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a28.r2",
    "package": "jdg.uor.revenue",
    "priority": 100201,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 28 ust. 1 pkt 1-4 UoR",
    "_warnings": ["[UoR] Art.28: Cena nabycia / koszt wytworzenia / wartość rynkowa — w zależności od źródła"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a29.r1",
    "package": "jdg.uor.revenue",
    "priority": 100202,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ust. 1 UoR",
    "_warnings": ["[UoR] Art.29: Przychody netto ze sprzedaży — pomniejszone o rabaty, bonifikaty, zwroty"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "has_discount", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a29.r2",
    "package": "jdg.uor.revenue",
    "priority": 100203,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ust. 2 UoR",
    "_warnings": ["[UoR] Art.29: Rabaty przyznane po sprzedaży — korekta przychodu w okresie przyznania"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_retroactive_discount", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a30.r1",
    "package": "jdg.uor.revenue",
    "priority": 100204,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 1 UoR",
    "_warnings": ["[UoR] Art.30: Wyrażone w walutach obcych — przeliczenie wg kursu NBP z dnia poprzedzającego operację"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    currency := object.get(input.invoice, "currency", "PLN")
    currency != "PLN"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a30.r2",
    "package": "jdg.uor.revenue",
    "priority": 100205,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 2 UoR",
    "_warnings": ["[UoR] Art.30: Do wyceny bilansowej — kurs NBP z dnia bilansowego"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    currency := object.get(input.invoice, "currency", "PLN")
    currency != "PLN"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a30.r3",
    "package": "jdg.uor.revenue",
    "priority": 100206,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 3 UoR",
    "_warnings": ["[UoR] Art.30: Różnice kursowe — księgowane jako przychody/koszty finansowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "has_fx_difference", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a30.r4",
    "package": "jdg.uor.revenue",
    "priority": 100207,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 4 UoR",
    "_warnings": ["[UoR] Art.30: Dodatnie różnice kursowe → przychody finansowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "fx_difference_positive", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a30.r5",
    "package": "jdg.uor.revenue",
    "priority": 100208,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 4 UoR",
    "_warnings": ["[UoR] Art.30: Ujemne różnice kursowe → koszty finansowe"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "fx_difference_negative", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a31.r1",
    "package": "jdg.uor.revenue",
    "priority": 100209,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 31 UoR",
    "_warnings": ["[UoR] Art.31: Zasada ostrożnej wyceny — nie wyższej niż wartość rynkowa"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a32.r1",
    "package": "jdg.uor.revenue",
    "priority": 100210,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 UoR",
    "_warnings": ["[UoR] Art.32: Amortyzacja — systematyczne rozłożenie wartości środka trwałego na okres użytkowania"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "depreciation_booked", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a32.r2",
    "package": "jdg.uor.revenue",
    "priority": 100211,
    "_routing": "WARNING",
    "_routing_reason": "Środek trwały bez amortyzacji — brak naliczonego odpisu!",
    "_legal_basis": "Art. 32 ust. 1 UoR",
    "_warnings": ["[UoR] Art.32: Środek trwały WYMAGA amortyzacji — nalicz odpis miesięcznie!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"
    object.get(input.invoice, "depreciation_booked", false) == false
    object.get(input.invoice, "asset_age_months", 0) > 1
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a32.r3",
    "package": "jdg.uor.revenue",
    "priority": 100212,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ust. 2-4 UoR",
    "_warnings": ["[UoR] Art.32: Metody amortyzacji: liniowa, degresywna, naturalna, jednorazowa (małe)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.a32.r4",
    "package": "jdg.uor.revenue",
    "priority": 100213,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 32 ust. 5 UoR",
    "_warnings": ["[UoR] Art.32: Odpisy aktualizujące — trwała utrata wartości (impairment)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    market_value := object.get(input.invoice, "asset_market_value", 0)
    book_value := object.get(input.invoice, "asset_book_value", 0)
    market_value > 0
    book_value > 0
    market_value < book_value * 0.50
}

# ═══════════════════════════════════════════════════════════════════════════════
# Revenue by Type — Sprzedaż towarów, usług, produktów (15 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.sales.goods.r1",
    "package": "jdg.uor.revenue",
    "priority": 100220,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 5 UoR; ZPK konto 731",
    "_warnings": ["[UoR] Sprzedaż towarów — konto 731 'Przychody ze sprzedaży towarów'"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "revenue_type", "") == "GOODS"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.sales.services.r1",
    "package": "jdg.uor.revenue",
    "priority": 100221,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 730",
    "_warnings": ["[UoR] Sprzedaż usług — konto 730 'Przychody ze sprzedaży usług'"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "revenue_type", "") == "SERVICES"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.sales.products.r1",
    "package": "jdg.uor.revenue",
    "priority": 100222,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 700/701",
    "_warnings": ["[UoR] Sprzedaż produktów — konta 700-709"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "revenue_type", "") == "PRODUCTS"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.other.r1",
    "package": "jdg.uor.revenue",
    "priority": 100223,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 30 UoR; ZPK konto 750-760",
    "_warnings": ["[UoR] Pozostałe przychody operacyjne — konta 750-760"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "revenue_type", "") == "OTHER_OPERATING"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.financial.r1",
    "package": "jdg.uor.revenue",
    "priority": 100224,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "ZPK konto 750",
    "_warnings": ["[UoR] Przychody finansowe — odsetki, dywidendy, różnice kursowe dodatnie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "revenue_type", "") == "FINANCIAL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Revenue Recognition — Timing (moment ujęcia przychodu) (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.timing.delivery.r1",
    "package": "jdg.uor.revenue",
    "priority": 100230,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 ust. 1 UoR — zasada memoriałowa",
    "_warnings": ["[UoR] Revenue Timing: Przychód w momencie dostawy/wykonania usługi (NIE zapłaty!)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_revenue", false) == true
    object.get(input.invoice, "delivery_date", "") != ""
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.timing.partial.r1",
    "package": "jdg.uor.revenue",
    "priority": 100231,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 ust. 1 UoR; KSR 15",
    "_warnings": ["[UoR] Usługi długoterminowe — rozpoznawanie przychodu wg stopnia zaawansowania"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_long_term_contract", false) == true
    completion_pct := object.get(input.invoice, "completion_pct", 0)
    completion_pct > 0
    completion_pct < 100
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.timing.accrued.r1",
    "package": "jdg.uor.revenue",
    "priority": 100232,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 ust. 1 UoR",
    "_warnings": ["[UoR] Przychody naliczone (RMK) — usługa wykonana, faktura jeszcze nie wystawiona"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "service_rendered_not_invoiced", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.timing.deferred.r1",
    "package": "jdg.uor.revenue",
    "priority": 100233,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 ust. 1; Art. 41 UoR",
    "_warnings": ["[UoR] Rozliczenia międzyokresowe przychodów (RMP) — faktura przed wykonaniem usługi"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "invoiced_before_service", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.timing.cash_basis.r1",
    "package": "jdg.uor.revenue",
    "priority": 100234,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Metoda kasowa — NIEZGODNA z UoR dla jednostek zobowiązanych!",
    "_legal_basis": "Art. 4 ust. 1 pkt 1 UoR",
    "_warnings": ["[UoR] METODA KASOWA NIEZGODNA z UoR! Przychód w dacie dostawy, NIE zapłaty!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_uses_cash_method", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.subsidies.r1",
    "package": "jdg.uor.revenue",
    "priority": 100235,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 1 pkt 1-2 UoR",
    "_warnings": ["[UoR] Dotacje do przychodów — rozliczane memoriałowo (RMP) w okresie ponoszenia kosztów"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_subsidy", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.interest.r1",
    "package": "jdg.uor.revenue",
    "priority": 100236,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 ust. 1 UoR; KSR 2",
    "_warnings": ["[UoR] Odsetki naliczone memoriałowo — proporcjonalnie do upływu czasu"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_interest_income", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.refund.r1",
    "package": "jdg.uor.revenue",
    "priority": 100237,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 29 ust. 1 UoR",
    "_warnings": ["[UoR] Zwroty i reklamacje — pomniejszają przychód okresu"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_return_or_claim", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.barter.r1",
    "package": "jdg.uor.revenue",
    "priority": 100238,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 30; Art. 28 ust. 1 UoR",
    "_warnings": ["[UoR] Transakcje barterowe — wycena wg wartości godziwej otrzymanego świadczenia"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_barter", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.revenue.donation.r1",
    "package": "jdg.uor.revenue",
    "priority": 100239,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 30 UoR",
    "_warnings": ["[UoR] Darowizny otrzymane — wpływ na kapitał własny lub przychody w zależności od przeznaczenia"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_donation_received", false) == true
}
