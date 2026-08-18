# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PCC Loans: Art. 1, 7 Ustawy o PCC
# Package: jdg.pcc.loans — Pożyczki (PCC-3)
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789) — Art. 1 ust. 1 pkt 1 lit. b, Art. 7 ust. 1 pkt 4
# Coverage: ~30 rules, ~30 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pcc.loans

import data.jdg.helpers
import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.pcc.loans.no_match",
    "package": "jdg.pcc.loans",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# Pożyczki — Podstawy opodatkowania PCC (15 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r1",
    "package": "jdg.pcc.loans",
    "priority": 200100,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. b UoPCC",
    "_warnings": ["[PCC] Umowa pożyczki — podlega PCC: 0.5% od kwoty pożyczki. Zgłoś PCC-3 w ciągu 14 dni!"],
    "pcc_rate": 0.005,
    "deadline_days": 14,
    "form": "PCC-3"
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r2",
    "package": "jdg.pcc.loans",
    "priority": 200101,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 9 pkt 10 lit. i UoPCC",
    "_warnings": ["[PCC] Pożyczka od rodziny (I grupa podatkowa) — ZWOLNIONA z PCC do 36 120 PLN w ciągu 5 lat!"],
    "exemption_limit_5y_pln": 36120,
    "exemption_applies": true
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
    object.get(input.invoice, "lender_family_group", "") == "I"
    amount := object.get(input.invoice, "amount_gross", 0)
    amount <= 36120
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r3",
    "package": "jdg.pcc.loans",
    "priority": 200102,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 9 pkt 10 lit. i UoPCC",
    "_warnings": ["[PCC] Pożyczka od rodziny POWYŻEJ 36 120 PLN — NADWYŻKA podlega PCC 0.5%! Zgłoś PCC-3!"],
    "pcc_rate": 0.005,
    "taxable_excess": true
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
    object.get(input.invoice, "lender_family_group", "") == "I"
    amount := object.get(input.invoice, "amount_gross", 0)
    amount > 36120
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r4",
    "package": "jdg.pcc.loans",
    "priority": 200103,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Pożyczka od rodziny — wymagane zgłoszenie SD-Z2 + udokumentowanie przelewu bankowego!",
    "_legal_basis": "Art. 9 pkt 10 lit. i; Art. 4a ustawy o podatku od spadków i darowizn",
    "_warnings": ["[PCC] Pożyczka rodzinna: warunek zwolnienia = PRZELEW BANKOWY + zgłoszenie SD-Z2 w ciągu 6 miesięcy!"],
    "documentation_required": "SD-Z2",
    "documentation_deadline_months": 6
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
    object.get(input.invoice, "lender_family_group", "") == "I"
    bank_transfer := object.get(input.invoice, "is_bank_transfer", false)
    sd_z2_filed := object.get(input.invoice, "sd_z2_filed", false)
    not bank_transfer or not sd_z2_filed
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r5",
    "package": "jdg.pcc.loans",
    "priority": 200104,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. b; Art. 7 ust. 1 pkt 4 UoPCC",
    "_warnings": ["[PCC] Pożyczka od osoby trzeciej — PCC 0.5% od CAŁEJ kwoty. Zgłoś PCC-3!"],
    "pcc_rate": 0.005
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
    object.get(input.invoice, "lender_family_group", "") == "III"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r6",
    "package": "jdg.pcc.loans",
    "priority": 200105,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Pożyczka PCC-3 niezłożona w terminie 14 dni — sankcja 20% podatku + odsetki!",
    "_legal_basis": "Art. 10 ust. 1 UoPCC",
    "_warnings": ["[PCC] PCC-3 PO TERMINIE! Sankcja 20%. Złóż czynny żal (Art. 16 KKS) dla redukcji kary!"],
    "sanction_rate": 0.20
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
    deadline_exceeded := object.get(input.invoice, "pcc_3_deadline_exceeded", false)
    deadline_exceeded
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r7",
    "package": "jdg.pcc.loans",
    "priority": 200106,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. b UoPCC",
    "_warnings": ["[PCC] Pożyczka od wspólnika do spółki — PCC 0.5% niezależnie od kwoty (brak zwolnienia rodzinnego)"]
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN_SHAREHOLDER_TO_COMPANY"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r8",
    "package": "jdg.pcc.loans",
    "priority": 200107,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 4 UoPCC",
    "_warnings": ["[PCC] Pożyczka objęta VAT (np. od instytucji finansowej) — NIE podlega PCC! (Art. 2 pkt 4)"]
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
    object.get(input.invoice, "has_vat", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r9",
    "package": "jdg.pcc.loans",
    "priority": 200108,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 ust. 1 pkt 4 UoPCC",
    "_warnings": ["[PCC] PCC od pożyczki = 0.5% × kwota pożyczki. Podstawa = kwota udostępniona pożyczkobiorcy."]
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r10",
    "package": "jdg.pcc.loans",
    "priority": 200109,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. b; Art. 9 UoPCC",
    "_warnings": ["[PCC] Pożyczka w walucie obcej — PCC od równowartości PLN wg kursu NBP z dnia zawarcia umowy"]
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
    object.get(input.invoice, "currency", "PLN") != "PLN"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r11",
    "package": "jdg.pcc.loans",
    "priority": 200110,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. b UoPCC",
    "_warnings": ["[PCC] Pożyczka nieoprocentowana — nadal podlega PCC (stawka 0.5% od kapitału)"]
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
    object.get(input.invoice, "interest_rate", 0) == 0
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r12",
    "package": "jdg.pcc.loans",
    "priority": 200111,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 9 pkt 10 lit. a UoPCC",
    "_warnings": ["[PCC] Pożyczka udzielona przez przedsiębiorcę w ramach działalności — zwolniona z PCC jeśli opodatkowana VAT"]
} {
    object.get(input.invoice, "is_business_lender", false) == true
    object.get(input.invoice, "has_vat", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r13",
    "package": "jdg.pcc.loans",
    "priority": 200112,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 4 pkt 7 UoPCC",
    "_warnings": ["[PCC] Obowiązek podatkowy — powstaje z chwilą dokonania czynności cywilnoprawnej (podpisanie umowy)"]
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r14",
    "package": "jdg.pcc.loans",
    "priority": 200113,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 1 ust. 1 pkt 1 lit. b UoPCC",
    "_warnings": ["[PCC] Pożyczka od JDG (właściciel → firma) — podlega PCC 0.5%! Wyjątek: spółka kapitałowa → VAT"]
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN_OWNER_TO_SOLE_PROPRIETORSHIP"
}

else := {
    "matched": true,
    "rule_id": "jdg.pcc.loans.a1.r15",
    "package": "jdg.pcc.loans",
    "priority": 200114,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 3 ust. 2 UoPCC; Art. 4 OP",
    "_warnings": ["[PCC] Solidarna odpowiedzialność — pożyczkodawca i pożyczkobiorca solidarnie za PCC"]
} {
    object.get(input.invoice, "transaction_type", "") == "LOAN"
}
