# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PCC Companies & Exchanges: Art. 1-2 Ustawy o PCC
# Package: jdg.pcc.exchanges_companies — Umowy spółki, zamiany
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789) — Art. 1 ust. 1 pkt 1 lit. c-k, Art. 3, 6-7
# Coverage: ~40 rules, ~40 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pcc.exchanges_companies

import data.jdg.helpers
import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.pcc.exchanges_companies.no_match",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# Umowy spółki / Company Formation (12 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r1",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200200,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. k; Art. 1 ust. 3 UoPCC",
    "_warnings": ["[PCC] Umowa spółki — podlega PCC 0.5% od wartości wkładów do spółki kapitałowej"],
    "pcc_rate": 0.005
} {
    object.get(input.invoice, "transaction_type", "") == "COMPANY_FORMATION"
    object.get(input.invoice, "company_type", "") == "CAPITAL"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r2",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200201,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 2 UoPCC",
    "_warnings": ["[PCC] Zmiana umowy spółki (podwyższenie kapitału) — PCC 0.5% od kwoty podwyższenia"],
    "pcc_rate": 0.005
} {
    object.get(input.invoice, "transaction_type", "") == "CAPITAL_INCREASE"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r3",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200202,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. k; Art. 9 pkt 11 UoPCC",
    "_warnings": ["[PCC] Spółka z o.o. — PCC od wkładów: 0.5%. Zwolnienie: spółka komandytowo-akcyjna (do 2024)"]
} {
    object.get(input.invoice, "company_type", "") == "LLC"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r4",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200203,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. k; Art. 6 ust. 1 pkt 8 UoPCC",
    "_warnings": ["[PCC] Podstawa opodatkowania umowy spółki = wartość wkładów wniesionych do spółki"]
} {
    object.get(input.invoice, "transaction_type", "") == "COMPANY_FORMATION"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r5",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200204,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 2; Art. 2 pkt 6 UoPCC",
    "_warnings": ["[PCC] Połączenie spółek — PCC 0.5% od wartości majątku przejmowanego"]
} {
    object.get(input.invoice, "transaction_type", "") == "COMPANY_MERGER"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r6",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200205,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 3 UoPCC",
    "_warnings": ["[PCC] Przekształcenie spółki — podlega PCC od wartości kapitału zakładowego nowej formy"]
} {
    object.get(input.invoice, "transaction_type", "") == "COMPANY_TRANSFORMATION"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r7",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200206,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1; Art. 10a UoPCC",
    "_warnings": ["[PCC] PCC-3 od umowy spółki — termin 14 dni od zawarcia umowy (aktu notarialnego)"],
    "deadline_days": 14
} {
    object.get(input.invoice, "transaction_type", "") == "COMPANY_FORMATION"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r8",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200207,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 4 UoPCC; Dyrektywa 2008/7/WE",
    "_warnings": ["[PCC] Wniesienie wkładu niepieniężnego (aport) objętego VAT — PCC nie nalicza się (Art. 2 pkt 4)"]
} {
    object.get(input.invoice, "transaction_type", "") == "IN_KIND_CONTRIBUTION"
    object.get(input.invoice, "has_vat", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r9",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200208,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. k; Art. 6 UoPCC",
    "_warnings": ["[PCC] Aport bez VAT (np. nieruchomość przez osobę fizyczną nieprowadzącą działalności) — PCC 0.5%"]
} {
    object.get(input.invoice, "transaction_type", "") == "IN_KIND_CONTRIBUTION"
    object.get(input.invoice, "has_vat", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r10",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200209,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 9 pkt 11 lit. a UoPCC",
    "_warnings": ["[PCC] ZWOLNIENIE: wniesienie przedsiębiorstwa lub ZCP jako aport do spółki — zwolnione z PCC"]
} {
    object.get(input.invoice, "transaction_type", "") == "APPORT_OF_ENTERPRISE"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.company.r11",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200210,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1a; Art. 3 ust. 1 pkt 3 UoPCC",
    "_warnings": ["[PCC] Solidarna odpowiedzialność — wspólnicy solidarnie ze spółką za PCC od umowy spółki"]
} {
    object.get(input.invoice, "transaction_type", "") == "COMPANY_FORMATION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Umowy zamiany / Exchange Agreements (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.exchange.r1",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200220,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. a; Art. 7 ust. 1 pkt 1 UoPCC",
    "_warnings": ["[PCC] Umowa zamiany — PCC 1% od wartości wyższej z zamienianych rzeczy (jeśli brak VAT)"],
    "pcc_rate": 0.01
} {
    object.get(input.invoice, "transaction_type", "") == "BARTER_EXCHANGE"
    object.get(input.invoice, "has_vat", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.exchange.r2",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200221,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 4 UoPCC",
    "_warnings": ["[PCC] Umowa zamiany objęta VAT — NIE podlega PCC (Art. 2 pkt 4)"]
} {
    object.get(input.invoice, "transaction_type", "") == "BARTER_EXCHANGE"
    object.get(input.invoice, "has_vat", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.exchange.r3",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200222,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 6 ust. 1 pkt 1 UoPCC",
    "_warnings": ["[PCC] Podstawa PCC przy zamianie = wartość wyższej z zamienianych rzeczy/praw"]
} {
    object.get(input.invoice, "transaction_type", "") == "BARTER_EXCHANGE"
    item_a_value := object.get(input.invoice, "item_a_value", 0)
    item_b_value := object.get(input.invoice, "item_b_value", 0)
    item_a_value > 0
    item_b_value > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.exchange.r4",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200223,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. a UoPCC",
    "_warnings": ["[PCC] Zamiana nieruchomości — PCC 2% od wyższej wartości (chyba że objęta VAT)"],
    "pcc_rate_real_estate": 0.02
} {
    object.get(input.invoice, "transaction_type", "") == "BARTER_EXCHANGE_REAL_ESTATE"
    object.get(input.invoice, "has_vat", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.donation.r1",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200230,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 2 UoPCC (darowizna — wyłączona, regulowana ustawą o SD)",
    "_warnings": ["[PCC] Darowizna NIE podlega PCC — regulowana ustawą o podatku od spadków i darowizn!"]
} {
    object.get(input.invoice, "transaction_type", "") == "DONATION_CIVIL_LAW"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.donation.r2",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200231,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa o podatku od spadków i darowizn — Art. 4a (zwolnienie dla najbliższej rodziny)",
    "_warnings": ["[PCC] Darowizna od rodziny — SD-Z2 w ciągu 6 miesięcy dla zwolnienia (I grupa)"]
} {
    object.get(input.invoice, "transaction_type", "") == "DONATION_CIVIL_LAW"
    object.get(input.invoice, "donor_family_group", "") == "I"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.annuity.r1",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200240,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. e UoPCC",
    "_warnings": ["[PCC] Umowa renty — PCC 1% od wartości rynkowej świadczeń (suma rocznych rent × 10)"],
    "pcc_rate": 0.01
} {
    object.get(input.invoice, "transaction_type", "") == "ANNUITY_AGREEMENT"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.exchanges_companies.usufruct.r1",
    "package": "jdg.pcc.exchanges_companies",
    "priority": 200241,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. g UoPCC",
    "_warnings": ["[PCC] Ustanowienie użytkowania — PCC 1% od wartości rocznego świadczenia × 10 (lub wartości rzeczy)"],
    "pcc_rate": 0.01
} {
    object.get(input.invoice, "transaction_type", "") == "USUFRUCT_ESTABLISHMENT"
}
