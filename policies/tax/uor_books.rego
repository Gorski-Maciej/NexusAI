# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — UoR Bookkeeping Rules (P320, P321, P326)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły księgowe wg Ustawy o Rachunkowości:
#   - P320: Podwójny zapis (Wn = Ma) — Art. 22 ust. 1 UoR
#   - P321: Zamknięcie ksiąg rachunkowych — Art. 12 ust. 2 pkt 1 UoR
#   - P326: Obowiązkowe elementy dowodu księgowego — Art. 21 ust. 1 UoR
#
# package: tax.uor_books
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.uor_books

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.uor_books.no_match",
    "package": "tax.uor_books",
    "priority": 399
}

# ── Helper: sum_by_side ───────────────────────────────────────────────────────
# Oblicza sumę kwot dla danej strony (debit/credit) zapisu księgowego
sum_by_side(side) := total {
    total := sum([line.amount | line := input.document.lines[_]; line.side == side])
}

# ═══════════════════════════════════════════════════════════════════════════════
# P320: uor_double_entry_validation (Priority 320)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Walidacja integralności księgowej — kontrola zbilansowania
#   Wn = Ma na poziomie każdego dekretu.
# Przesłanki: document.type == journal_entry AND abs(sum(debet) - sum(kredyt)) > 0.01
# Podstawa prawna: Art. 22 ust. 1 UoR

# ── P320: uor_double_entry_validation ─────────────────────────────────────────
# Cel biznesowy: Zabezpieczenie integralności — Wn musi = Ma
# Przesłanki: journal_entry + debet != kredyt
# Podstawa prawna: Art. 22 ust. 1 UoR
# Priorytet: 320
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.uor_books.double_entry_validation",
    "package": "tax.uor_books",
    "priority": 320,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": concat("", [
        "Niezgodność podwójnego zapisu: Wn=", sprintf("%.2f", [sum_by_side("debit")]),
        " Ma=", sprintf("%.2f", [sum_by_side("credit")])
    ]),
    "_legal_basis": "Art. 22 ust. 1 UoR",
    "_warnings": ["Zapis księgowy niezbilansowany — naruszenie zasady podwójnego zapisu"]
} {
    input.document.type == "journal_entry"
    abs(sum_by_side("debit") - sum_by_side("credit")) > 0.01
}

# ═══════════════════════════════════════════════════════════════════════════════
# P321: uor_closing_books_mandatory (Priority 321)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Blokada księgowania operacji w zamkniętym już roku obrotowym
#   po zatwierdzeniu sprawozdania finansowego.
# Przesłanki: Data faktury <= data zamknięcia + sprawozdanie zatwierdzone
# Podstawa prawna: Art. 12 ust. 2 pkt 1 UoR

# ── P321: uor_closing_books_mandatory ─────────────────────────────────────────
# Cel biznesowy: Blokada księgowania w zamkniętym roku obrotowym
# Przesłanki: issue_date <= closed_financial_year_end + fs approved
# Podstawa prawna: Art. 12 ust. 2 pkt 1 UoR
# Priorytet: 321
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.uor_books.books_closed",
    "package": "tax.uor_books",
    "priority": 321,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Próba księgowania w zamkniętym roku obrotowym",
    "_legal_basis": "Art. 12 ust. 2 pkt 1 UoR",
    "_warnings": ["Księgi zamknięte — użyj korekty błędu podstawowego (Art. 54 UoR)"]
} {
    input.invoice.issue_date <= input.company.closed_financial_year_end
    input.company.is_fs_approved == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P326: uor_evidence_mandatory_fields (Priority 326)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Odrzucenie dokumentów niespełniających wymogów Art. 21 UoR —
#   brak określenia stron lub opisu operacji gospodarczej.
# Przesłanki: Brak identyfikacji stron LUB brak opisu operacji
# Podstawa prawna: Art. 21 ust. 1 UoR

# ── P326: uor_evidence_mandatory_fields ───────────────────────────────────────
# Cel biznesowy: Walidacja obowiązkowych elementów dowodu księgowego
# Przesłanki: !parties_identified lub !has_operation_description
# Podstawa prawna: Art. 21 ust. 1 UoR
# Priorytet: 326
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.uor_books.evidence_invalid",
    "package": "tax.uor_books",
    "priority": 326,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Dowód księgowy nie spełnia wymogów Art. 21 UoR",
    "evidence_status": "INVALID",
    "_legal_basis": "Art. 21 ust. 1 UoR",
    "_warnings": evidence_warnings
} {
    not input.document.parties_identified
}

else := {
    "matched": true,
    "rule_id": "tax.uor_books.evidence_invalid",
    "package": "tax.uor_books",
    "priority": 326,
    "vat_rate": "",
    "rounding_level": "",
    "income_tax_qualification": "",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Dowód księgowy nie spełnia wymogów Art. 21 UoR",
    "evidence_status": "INVALID",
    "_legal_basis": "Art. 21 ust. 1 UoR",
    "_warnings": evidence_warnings
} {
    not input.document.has_operation_description
}

# Dynamiczne budowanie listy ostrzeżeń — zbiera wszystkie braki
# UWAGA: Ponieważ są to dwie reguły w łańcuchu else, tylko PIERWSZA dopasowana
# zostanie zwrócona. Jeśli oba pola są niepoprawne, użytkownik zobaczy tylko
# ostrzeżenie o pierwszym dopasowaniu. Kolejna iteracja może połączyć te
# reguły w jedną z dynamicznym budowaniem listy warningów.
evidence_warnings := ["Brak określenia stron — dowód wadliwy"] {
    input.document.parties_identified == false
}

evidence_warnings := ["Brak opisu operacji gospodarczej — dowód wadliwy"] {
    input.document.has_operation_description == false
}
