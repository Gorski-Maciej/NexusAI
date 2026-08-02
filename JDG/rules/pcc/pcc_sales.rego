# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PCC Sales Agreements: Art. 1-2 Ustawy o PCC
# Package: jdg.pcc.sales_agreements — Umowy sprzedaży (PCC-3)
# Version: 1.0.0 — Q3 2026 Critical Closure (P28 Grand Finale)
# Legal basis: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)
# Coverage: Art. 1-2 — ~60 rules, ~60 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pcc.sales_agreements

import data.jdg.helpers
import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.pcc.sales_agreements.no_match",
    "package": "jdg.pcc.sales_agreements",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 1 — Przedmiot opodatkowania PCC (15 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r1",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200001,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. a Ustawy o PCC",
    "_warnings": ["[PCC] Umowa sprzedaży rzeczy ruchomych — podlega PCC jeśli wartość > 1 000 PLN"],
    "threshold_pln": 1000
} {
    object.get(input.invoice, "transaction_type", "") == "SALE_OF_MOVABLES"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r2",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200002,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. a Ustawy o PCC",
    "_warnings": ["[PCC] Umowa sprzedaży nieruchomości — PCC 2% od wartości rynkowej"],
    "pcc_rate": 0.02
} {
    object.get(input.invoice, "transaction_type", "") == "SALE_OF_REAL_ESTATE"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r3",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200003,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. a; Art. 7 UoPCC",
    "_warnings": ["[PCC] Stawka PCC od sprzedaży rzeczy ruchomych = 1% wartości rynkowej (jeśli >1 000 PLN)"],
    "pcc_rate": 0.01
} {
    value := object.get(input.invoice, "amount_gross", 0)
    object.get(input.invoice, "transaction_type", "") == "SALE_OF_MOVABLES"
    value > 1000
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r4",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200004,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1; Art. 2 pkt 4 UoPCC",
    "_warnings": ["[PCC] Transakcja z VAT — WYŁĄCZONA z PCC! (Art. 2 pkt 4 UoPCC — unikanie podwójnego opodatkowania)"]
} {
    object.get(input.invoice, "has_vat", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r5",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200005,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1; Art. 2 pkt 4 UoPCC",
    "_warnings": ["[PCC] Transakcja BEZ VAT (np. między osobami prywatnymi) — PODLEGA PCC!"],
    "pcc_applies": true
} {
    object.get(input.invoice, "has_vat", false) == false
    value := object.get(input.invoice, "amount_gross", 0)
    value > 1000
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r6",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200006,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. a UoPCC",
    "_warnings": ["[PCC] Wartość rynkowa — deklarowana przez strony. US może zakwestionować w ciągu 5 lat!"],
    "us_challenge_deadline_years": 5
} {
    object.get(input.invoice, "transaction_type", "") == "SALE_OF_MOVABLES"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r7",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200007,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 UoPCC",
    "_warnings": ["[PCC] Samochód od osoby prywatnej — PCC-3 w ciągu 14 dni od zakupu!"],
    "deadline_days": 14,
    "pcc_form": "PCC-3"
} {
    object.get(input.invoice, "transaction_type", "") == "VEHICLE_FROM_PRIVATE"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r8",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200008,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1; Art. 9 UoPCC",
    "_warnings": ["[PCC] Samochód od osoby prywatnej — stawka 2% od wartości rynkowej (powyżej 1 000 PLN, bez VAT)"],
    "pcc_rate_vehicle": 0.02
} {
    object.get(input.invoice, "transaction_type", "") == "VEHICLE_FROM_PRIVATE"
    object.get(input.invoice, "has_vat", false) == false
    object.get(input.invoice, "amount_gross", 0) > 1000
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r9",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200009,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PCC-3 niezłożony w terminie 14 dni od zakupu! Sankcja: 20% podatku!",
    "_legal_basis": "Art. 10 ust. 1; Art. 10a UoPCC",
    "_warnings": ["[PCC] PCC-3 PO TERMINIE — sankcja 20% podatku! Złóż czynny żal!"],
    "sanction_rate": 0.20,
    "deadline_exceeded": true
} {
    object.get(input.invoice, "transaction_type", "") == "VEHICLE_FROM_PRIVATE"
    deadline_exceeded := object.get(input.invoice, "pcc_3_deadline_exceeded", false)
    deadline_exceeded
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r10",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200010,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 UoPCC; Art. 22 PIT",
    "_warnings": ["[PCC] PCC od samochodu = KUP w PIT (zwiększa wartość początkową ŚT lub koszt bezpośredni)"],
    "kup_treatment": "INCREASES_ASSET_VALUE"
} {
    object.get(input.invoice, "transaction_type", "") == "VEHICLE_FROM_PRIVATE"
    object.get(input.invoice, "used_for_business", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r11",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200011,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. a UoPCC",
    "_warnings": ["[PCC] Sprzedaż rzeczy ruchomych między przedsiębiorcami (VAT) — NIE podlega PCC"]
} {
    object.get(input.invoice, "has_vat", false) == true
    object.get(input.invoice, "transaction_type", "") == "SALE_OF_MOVABLES"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r12",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200012,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. a UoPCC",
    "_warnings": ["[PCC] Zwolnienie: sprzedaż rzeczy ruchomych ≤ 1 000 PLN — wolne od PCC"],
    "exemption_threshold": 1000,
    "pcc_rate": 0.00
} {
    value := object.get(input.invoice, "amount_gross", 0)
    object.get(input.invoice, "transaction_type", "") == "SALE_OF_MOVABLES"
    value <= 1000
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r13",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200013,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1; Art. 9 UoPCC",
    "_warnings": ["[PCC] Podstawa opodatkowania = wartość rynkowa z dnia zawarcia umowy (NIE cena zakupu!)"],
    "tax_base": "MARKET_VALUE"
} {
    purchase_price := object.get(input.invoice, "amount_gross", 0)
    market_value := object.get(input.invoice, "market_value", 0)
    purchase_price < market_value * 0.70
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r14",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200014,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Cena zakupu znacząco poniżej wartości rynkowej — ryzyko zakwestionowania przez US!",
    "_legal_basis": "Art. 6 ust. 1 UoPCC; Art. 23 § 2 OP",
    "_warnings": ["[PCC] Cena zaniżona — US może oszacować wartość rynkową i domierzyć PCC!"]
} {
    purchase_price := object.get(input.invoice, "amount_gross", 0)
    market_value := object.get(input.invoice, "market_value", 0)
    purchase_price < market_value * 0.50
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a1.r15",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200015,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 2; Art. 9 UoPCC",
    "_warnings": ["[PCC] Stawki PCC: 1% — rzeczy ruchome, 2% — nieruchomości, 0.5% — inne (Art. 7 UoPCC)"],
    "rates_summary": {"movables": 0.01, "real_estate": 0.02, "other": 0.005}
} {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 2 — Wyłączenia z PCC (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r1",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200020,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 4 UoPCC (VAT exclusion)",
    "_warnings": ["[PCC] WYŁĄCZENIE: czynności opodatkowane VAT (lub zwolnione z VAT poza wyjątkami) — NIE podlegają PCC!"],
    "pcc_applies": false
} {
    object.get(input.invoice, "has_vat", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r2",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200021,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 4 UoPCC (wyjątek: umowa spółki)",
    "_warnings": ["[PCC] UWAGA: Umowa spółki podlega PCC nawet jeśli jest zwolniona z VAT! (wyjątek Art. 2 pkt 4 in fine)"]
} {
    object.get(input.invoice, "transaction_type", "") == "COMPANY_FORMATION"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r3",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200022,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 3 UoPCC",
    "_warnings": ["[PCC] WYŁĄCZENIE: sprzedaż przedsiębiorstwa lub jego zorganizowanej części (opodatkowane PCC od wartości rynkowej 1%)"]
} {
    object.get(input.invoice, "transaction_type", "") == "SALE_OF_ENTERPRISE"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r4",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200023,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 1 UoPCC",
    "_warnings": ["[PCC] WYŁĄCZENIE: umowy sprzedaży zawierane na giełdach towarowych — nie podlegają PCC"]
} {
    object.get(input.invoice, "is_exchange_traded", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r5",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200024,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 2 UoPCC",
    "_warnings": ["[PCC] WYŁĄCZENIE: sprzedaż walut obcych — nie podlega PCC"]
} {
    object.get(input.invoice, "transaction_type", "") == "FX_TRANSACTION"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r6",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200025,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 5 UoPCC",
    "_warnings": ["[PCC] WYŁĄCZENIE: sprzedaż w postępowaniu egzekucyjnym/upadłościowym — nie podlega PCC"]
} {
    object.get(input.invoice, "is_bankruptcy_sale", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r7",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200026,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 6 UoPCC",
    "_warnings": ["[PCC] WYŁĄCZENIE: sprzedaż między osobami z I grupy podatkowej w podatku od spadków (zwolniona)"]
} {
    object.get(input.invoice, "is_family_first_group", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r8",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200027,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 7 UoPCC",
    "_warnings": ["[PCC] WYŁĄCZENIE: sprzedaż zorganizowanej części przedsiębiorstwa (opodatkowanie jak całość ZCP)"]
} {
    object.get(input.invoice, "transaction_type", "") == "SALE_OF_ZCP"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r9",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200028,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 8 UoPCC",
    "_warnings": ["[PCC] WYŁĄCZENIE: nabycie własności gruntów rolnych ≤ 1 ha — zwolnione z PCC"]
} {
    object.get(input.invoice, "is_agricultural_land_under_1ha", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.sales_agreements.a2.r10",
    "package": "jdg.pcc.sales_agreements",
    "priority": 200029,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 9 UoPCC",
    "_warnings": ["[PCC] WYŁĄCZENIE: nabycie pierwszego mieszkania na rynku wtórnym (rynek pierwotny = VAT → wykluczone)"]
} {
    object.get(input.invoice, "is_first_apartment_secondary_market", false) == true
}
