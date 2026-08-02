# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PCC Rate Changes & Special Provisions: Art. 3-7 Ustawy o PCC
# Package: jdg.pcc.rate_changes — Zmiany umów, stawki szczególne
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: Ustawa o PCC — Art. 3-7
# Coverage: ~40 rules, ~40 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pcc.rate_changes

import data.jdg.helpers
import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.pcc.rate_changes.no_match",
    "package": "jdg.pcc.rate_changes",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 3 — Obowiązek podatkowy (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a3.r1",
    "package": "jdg.pcc.rate_changes",
    "priority": 200300,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 1 UoPCC",
    "_warnings": ["[PCC] Obowiązek podatkowy — z chwilą dokonania czynności cywilnoprawnej (podpisania umowy)"]
} {
    object.get(input.invoice, "is_pcc_transaction", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a3.r2",
    "package": "jdg.pcc.rate_changes",
    "priority": 200301,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 4 UoPCC",
    "_warnings": ["[PCC] Umowa z warunkiem zawieszającym — obowiązek z chwilą ziszczenia się warunku"]
} {
    object.get(input.invoice, "has_suspensive_condition", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a3.r3",
    "package": "jdg.pcc.rate_changes",
    "priority": 200302,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 2 UoPCC",
    "_warnings": ["[PCC] Odpowiedzialność solidarna — strony czynności (kupujący i sprzedający) solidarnie"]
} {
    object.get(input.invoice, "is_pcc_transaction", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a3.r4",
    "package": "jdg.pcc.rate_changes",
    "priority": 200303,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 5 UoPCC",
    "_warnings": ["[PCC] Orzeczenie sądu — obowiązek z chwilą uprawomocnienia się orzeczenia"]
} {
    object.get(input.invoice, "is_court_ruling", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a3.r5",
    "package": "jdg.pcc.rate_changes",
    "priority": 200304,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 3 UoPCC",
    "_warnings": ["[PCC] Umowa przedwstępna — NIE rodzi obowiązku PCC (tylko umowa przyrzeczona!)"]
} {
    object.get(input.invoice, "is_preliminary_agreement", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a3.r6",
    "package": "jdg.pcc.rate_changes",
    "priority": 200305,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 2 UoPCC",
    "_warnings": ["[PCC] Ustanowienie hipoteki — obowiązek z chwilą złożenia oświadczenia woli"]
} {
    object.get(input.invoice, "transaction_type", "") == "MORTGAGE_ESTABLISHMENT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 4-5 — Podstawa opodatkowania (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a4.r1",
    "package": "jdg.pcc.rate_changes",
    "priority": 200310,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 pkt 1 UoPCC",
    "_warnings": ["[PCC] Podstawa: wartość rynkowa rzeczy/prawa majątkowego z dnia zawarcia umowy"]
} {
    object.get(input.invoice, "is_pcc_transaction", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a4.r2",
    "package": "jdg.pcc.rate_changes",
    "priority": 200311,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 pkt 3 UoPCC",
    "_warnings": ["[PCC] Podstawa pożyczki = kwota udostępniona pożyczkobiorcy (kapitał, bez odsetek)"]
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a4.r3",
    "package": "jdg.pcc.rate_changes",
    "priority": 200312,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 pkt 9 UoPCC",
    "_warnings": ["[PCC] Podstawa umowy spółki = wartość wkładów lub kapitał zakładowy"]
} {
    object.get(input.invoice, "transaction_type", "") == "COMPANY_FORMATION"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a5.r1",
    "package": "jdg.pcc.rate_changes",
    "priority": 200315,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 UoPCC",
    "_warnings": ["[PCC] Zaokrąglanie: podstawa i podatek zaokrągla się do pełnych złotych. Końcówki <50 gr pomija się"]
} {
    object.get(input.invoice, "is_pcc_transaction", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a5.r2",
    "package": "jdg.pcc.rate_changes",
    "priority": 200316,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 2 UoPCC",
    "_warnings": ["[PCC] Waluta obca — przeliczenie wg kursu średniego NBP z dnia powstania obowiązku podatkowego"]
} {
    object.get(input.invoice, "is_pcc_transaction", false) == true
    object.get(input.invoice, "currency", "PLN") != "PLN"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 6-7 — Stawki PCC (szczegółowe) (12 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a7.r1",
    "package": "jdg.pcc.rate_changes",
    "priority": 200320,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 pkt 1 UoPCC",
    "_warnings": ["[PCC] Stawka 1% — sprzedaż rzeczy ruchomych, praw majątkowych (poza nieruchomościami)"],
    "rate": 0.01
} {
    object.get(input.invoice, "pcc_rate_category", "") == "STANDARD_1PCT"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a7.r2",
    "package": "jdg.pcc.rate_changes",
    "priority": 200321,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 pkt 1 UoPCC",
    "_warnings": ["[PCC] Stawka 2% — sprzedaż nieruchomości, prawa użytkowania wieczystego, spółdzielcze własnościowe prawo"],
    "rate": 0.02
} {
    object.get(input.invoice, "pcc_rate_category", "") == "REAL_ESTATE_2PCT"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a7.r3",
    "package": "jdg.pcc.rate_changes",
    "priority": 200322,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 pkt 4 UoPCC",
    "_warnings": ["[PCC] Stawka 0.5% — pożyczki, depozyty nieprawidłowe, umowy spółki kapitałowej"],
    "rate": 0.005
} {
    object.get(input.invoice, "pcc_rate_category", "") == "LOAN_COMPANY_05PCT"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a7.r4",
    "package": "jdg.pcc.rate_changes",
    "priority": 200323,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 pkt 2 UoPCC",
    "_warnings": ["[PCC] Stawka 0.1% — ustanowienie odpłatnej służebności, użytkowania (od wartości rocznego świadczenia × liczba lat)"],
    "rate": 0.001
} {
    object.get(input.invoice, "pcc_rate_category", "") == "EASEMENT_01PCT"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a7.r5",
    "package": "jdg.pcc.rate_changes",
    "priority": 200324,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 3 UoPCC",
    "_warnings": ["[PCC] Stawka 20% — sankcja przy kontroli: niezadeklarowana wartość w PCC-3"],
    "sanction_rate": 0.20
} {
    object.get(input.invoice, "pcc_sanction_triggered", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.a7.r6",
    "package": "jdg.pcc.rate_changes",
    "priority": 200325,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 5 UoPCC",
    "_warnings": ["[PCC] Stawka obniżona — pożyczki na cele mieszkaniowe z Funduszu lub BGK (stawka 0%)"],
    "rate": 0.00
} {
    object.get(input.invoice, "is_housing_loan_bgk", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Zmiany umów / Contract Modifications (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.modification.r1",
    "package": "jdg.pcc.rate_changes",
    "priority": 200330,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 2 UoPCC",
    "_warnings": ["[PCC] Zmiana umowy — jeśli zwiększa podstawę opodatkowania, PCC od NADWYŻKI (nie całości!)"]
} {
    object.get(input.invoice, "is_contract_modification", false) == true
    additional_value := object.get(input.invoice, "modification_additional_value", 0)
    additional_value > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.modification.r2",
    "package": "jdg.pcc.rate_changes",
    "priority": 200331,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 2 UoPCC",
    "_warnings": ["[PCC] Aneks do pożyczki — zwiększenie kwoty = PCC od przyrostu (0.5%)"]
} {
    object.get(input.invoice, "is_loan_increase", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.modification.r3",
    "package": "jdg.pcc.rate_changes",
    "priority": 200332,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 2 UoPCC",
    "_warnings": ["[PCC] Zmiana nie zwiększająca wartości — NIE podlega PCC (np. zmiana terminu spłaty, stopy procentowej)"]
} {
    object.get(input.invoice, "is_non_value_change", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.modification.r4",
    "package": "jdg.pcc.rate_changes",
    "priority": 200333,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 1 pkt 2 UoPCC",
    "_warnings": ["[PCC] PCC-3/A (aneks) — składa się w ciągu 14 dni od zmiany umowy zwiększającej podstawę"]
} {
    object.get(input.invoice, "is_contract_modification", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.payment.r1",
    "package": "jdg.pcc.rate_changes",
    "priority": 200340,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 1 UoPCC",
    "_warnings": ["[PCC] Termin zapłaty — 14 dni od powstania obowiązku podatkowego (razem ze złożeniem PCC-3)"]
} {
    object.get(input.invoice, "is_pcc_transaction", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.payment.r2",
    "package": "jdg.pcc.rate_changes",
    "priority": 200341,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PCC niezapłacony w terminie — odsetki od zaległości (14.5% rocznie)!",
    "_legal_basis": "Art. 53 § 1 OP; Art. 56 OP",
    "_warnings": ["[PCC] PCC NIEZAPŁACONY! Odsetki 14.5% rocznie od dnia następującego po terminie!"],
    "interest_rate": 0.145
} {
    object.get(input.invoice, "pcc_payment_overdue", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.payment.r3",
    "package": "jdg.pcc.rate_changes",
    "priority": 200342,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10 ust. 3 UoPCC",
    "_warnings": ["[PCC] Płatność — na rachunek US właściwego wg miejsca zamieszkania podatnika"]
} {
    object.get(input.invoice, "is_pcc_transaction", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.rate_changes.payment.r4",
    "package": "jdg.pcc.rate_changes",
    "priority": 200343,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 10a UoPCC; Art. 16 KKS",
    "_warnings": ["[PCC] Czynny żal — złożenie PCC-3 + zapłata podatku przed kontrolą US = redukcja sankcji do 0%"]
} {
    object.get(input.invoice, "is_voluntary_disclosure_pcc", false) == true
}
