# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR Inventory Layer: Art. 17, 34 Ustawy o rachunkowości
# Package: jdg.uor.inventory — Inventory Accounting Rules
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: Art. 17, 34 UoR; KSR 5
# Coverage: ~30 rules, ~30 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.inventory

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.uor.inventory.no_match",
    "package": "jdg.uor.inventory",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# Inventory Basics — Wycena, metody, inwentaryzacja (15 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.basics.r1",
    "package": "jdg.uor.inventory",
    "priority": 100500,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 5; Art. 34 UoR",
    "_warnings": ["[UoR] Zapasy = towary, materiały, produkty gotowe, produkcja w toku"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_inventory", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.valuation.r1",
    "package": "jdg.uor.inventory",
    "priority": 100501,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 ust. 1 UoR",
    "_warnings": ["[UoR] Wycena początkowna: cena nabycia / koszt wytworzenia"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.fifo.r1",
    "package": "jdg.uor.inventory",
    "priority": 100502,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 ust. 4 pkt 1 UoR",
    "_warnings": ["[UoR] FIFO — 'pierwsze przyszło, pierwsze wyszło'. Najstarsze partie najpierw rozchodowane."],
    "method": "FIFO"
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "inventory_method", "FIFO") == "FIFO"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.lifo.r1",
    "package": "jdg.uor.inventory",
    "priority": 100503,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 ust. 4 pkt 2 UoR",
    "_warnings": ["[UoR] LIFO — 'ostatnie przyszło, pierwsze wyszło'. Najnowsze partie najpierw rozchodowane."],
    "method": "LIFO"
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "inventory_method", "FIFO") == "LIFO"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.avg.r1",
    "package": "jdg.uor.inventory",
    "priority": 100504,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 34 ust. 4 pkt 3 UoR",
    "_warnings": ["[UoR] Średnia ważona — wartość przeciętna wszystkich partii"],
    "method": "WEIGHTED_AVERAGE"
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "inventory_method", "FIFO") == "WEIGHTED_AVERAGE"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.impairment.r1",
    "package": "jdg.uor.inventory",
    "priority": 100505,
    "_routing": "WARNING",
    "_routing_reason": "Wycena bilansowa zapasów — cena nabycia/koszt wytworzenia vs cena sprzedaży netto (niższa z dwóch)!",
    "_legal_basis": "Art. 34 ust. 5 UoR",
    "_warnings": ["[UoR] Zapasy: wycena wg niższej z dwóch: koszt historyczny lub wartość netto sprzedaży!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    object.get(input.jdg_entrepreneur, "has_inventory", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.obsolete.r1",
    "package": "jdg.uor.inventory",
    "priority": 100506,
    "_routing": "WARNING",
    "_routing_reason": "Zapasy zalegające >12 mies. — ryzyko utraty wartości, rozważ odpis!",
    "_legal_basis": "Art. 34 ust. 5 UoR; KSR 5",
    "_warnings": ["[UoR] Zapasy zalegające >12 mies. — wymagają testu na utratę wartości!"]
} {
    inventory_age_days := object.get(input.invoice, "inventory_age_days", 0)
    impairment_booked := object.get(input.invoice, "inventory_impairment_booked", false)
    inventory_age_days > 365
    not impairment_booked
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.physical_count.r1",
    "package": "jdg.uor.inventory",
    "priority": 100507,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 pkt 1 UoR",
    "_warnings": ["[UoR] Inwentaryzacja — spis z natury na dzień bilansowy (co najmniej raz na 2 lata)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.difference.r1",
    "package": "jdg.uor.inventory",
    "priority": 100508,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Różnica inwentaryzacyjna — niedobór lub nadwyżka!",
    "_legal_basis": "Art. 27 UoR",
    "_warnings": ["[UoR] Różnica inwentaryzacyjna — niedobory: pozostałe koszty oper. / nadwyżki: pozostałe przychody oper."]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "inventory_difference", 0) != 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.shortage.r1",
    "package": "jdg.uor.inventory",
    "priority": 100509,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Niedobór inwentaryzacyjny — sprawdź czy zawiniony (NKUP) czy niezawiniony!",
    "_legal_basis": "Art. 27 ust. 2 UoR",
    "_warnings": ["[UoR] Niedobór — zawiniony: NKUP + obciążenie pracownika. Niezawiniony: koszt podatkowy."]
} {
    diff := object.get(input.jdg_entrepreneur, "inventory_difference", 0)
    diff < 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.surplus.r1",
    "package": "jdg.uor.inventory",
    "priority": 100510,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 27 ust. 1 UoR",
    "_warnings": ["[UoR] Nadwyżka inwentaryzacyjna — pozostałe przychody operacyjne"]
} {
    diff := object.get(input.jdg_entrepreneur, "inventory_difference", 0)
    diff > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.continuous.r1",
    "package": "jdg.uor.inventory",
    "priority": 100511,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 2 UoR",
    "_warnings": ["[UoR] Inwentaryzacja ciągła — możliwa przy prowadzeniu ewidencji ilościowo-wartościowej"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "inventory_method_continuous", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Remanent likwidacyjny / Closing Inventory (5 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.remnant.r1",
    "package": "jdg.uor.inventory",
    "priority": 100520,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Remanent likwidacyjny WYMAGANY przy przejściu PKPiR→UoR lub zamknięciu JDG!",
    "_legal_basis": "Art. 24 ust. 3 PIT; Art. 34 UoR",
    "_warnings": ["[UoR] Remanent likwidacyjny — spis z natury na dzień zmiany formy opodatkowania/likwidacji!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "transition_pkpir_to_uor", false) == true
    object.get(input.jdg_entrepreneur, "remnant_inventory_done", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.remnant.r2",
    "package": "jdg.uor.inventory",
    "priority": 100521,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 24 ust. 3 PIT; Art. 34 UoR",
    "_warnings": ["[UoR] Remanent początkowy UoR = remanent końcowy PKPiR + wycena wg zasad UoR"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "transition_pkpir_to_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.remnant.r3",
    "package": "jdg.uor.inventory",
    "priority": 100522,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 44 UoR",
    "_warnings": ["[UoR] Wycena remanentu wg cen zakupu — towary; wg kosztu wytworzenia — produkty; wg ceny rynkowej — odpady"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.tax_on_remnant.r1",
    "package": "jdg.uor.inventory",
    "priority": 100523,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Remanent likwidacyjny — podlega opodatkowaniu PIT 10%! (Art. 44 PIT)",
    "_legal_basis": "Art. 44 ust. 4 PIT",
    "_warnings": ["[UoR] Remanent likwidacyjny: 10% PIT od wartości remanentu przy likwidacji JDG!"],
    "tax_rate": 0.10
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "liquidation_mode", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.inventory.no_inventory.r1",
    "package": "jdg.uor.inventory",
    "priority": 100524,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 5 UoR",
    "_warnings": ["[UoR] JDG bez zapasów (usługowa) — brak obowiązku prowadzenia ewidencji magazynowej"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "has_inventory", false) == false
}
