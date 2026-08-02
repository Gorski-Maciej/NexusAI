# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR Books Layer: Art. 11–24 Ustawy o rachunkowości
# Package: jdg.uor.books — Books of Account Rules
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: Ustawa o rachunkowości — Art. 11–24
# Coverage: ~70 rules, ~70 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.books

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.uor.books.no_match",
    "package": "jdg.uor.books",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 11 — Otwarcie ksiąg (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.uor.books.a11.r1",
    "package": "jdg.uor.books",
    "priority": 100050,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Księgi nieotwarte na początek roku obrotowego!",
    "_legal_basis": "Art. 11 ust. 1 UoR",
    "_warnings": ["[UoR] Art.11: Otwórz księgi rachunkowe na dzień rozpoczęcia działalności / 01.01!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "books_opened", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a11.r2",
    "package": "jdg.uor.books",
    "priority": 100051,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 11 ust. 2 UoR",
    "_warnings": ["[UoR] Art.11: Otwarcie ksiąg = bilans otwarcia (aktywa = pasywa)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    opening_assets := object.get(input.jdg_entrepreneur, "opening_assets", 0)
    opening_liabilities := object.get(input.jdg_entrepreneur, "opening_equity_liabilities", 0)
    abs(opening_assets - opening_liabilities) < 0.01
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a11.r3",
    "package": "jdg.uor.books",
    "priority": 100052,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Bilans otwarcia NIEZBILANSOWANY! Aktywa ≠ Pasywa!",
    "_legal_basis": "Art. 11 ust. 2; Art. 7 ust. 1 UoR",
    "_warnings": ["[UoR] Art.11: Bilans otwarcia musi być ZBILANSOWANY. Sprawdź wprowadzone dane!"]
} {
    opening_assets := object.get(input.jdg_entrepreneur, "opening_assets", 0)
    opening_liabilities := object.get(input.jdg_entrepreneur, "opening_equity_liabilities", 0)
    abs(opening_assets - opening_liabilities) >= 0.01
    opening_assets > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a11.r4",
    "package": "jdg.uor.books",
    "priority": 100053,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 11 ust. 3 UoR",
    "_warnings": ["[UoR] Art.11: Salda kont pomocniczych muszą być zgodne z kontami syntetycznymi"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a11.r5",
    "package": "jdg.uor.books",
    "priority": 100054,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 11 ust. 4 UoR",
    "_warnings": ["[UoR] Art.11: Pierwsze otwarcie ksiąg — spis z natury + wycena składników majątku"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_first_year", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a11.r6",
    "package": "jdg.uor.books",
    "priority": 100055,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 11 ust. 1-4 UoR",
    "_warnings": ["[UoR] Art.11: ✅ Księgi otwarte prawidłowo"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "books_opened", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 12–13 — Zamknięcie ksiąg (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a12.r1",
    "package": "jdg.uor.books",
    "priority": 100056,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Księgi NIE zamknięte na dzień bilansowy!",
    "_legal_basis": "Art. 12 ust. 1 UoR",
    "_warnings": ["[UoR] Art.12: Zamknij księgi na dzień bilansowy w ciągu 3 miesięcy!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
    object.get(input.jdg_entrepreneur, "books_closed", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a12.r2",
    "package": "jdg.uor.books",
    "priority": 100057,
    "_routing": "WARNING",
    "_routing_reason": "Zbliża się termin zamknięcia ksiąg — 3 miesiące od dnia bilansowego",
    "_legal_basis": "Art. 12 ust. 1; Art. 52 UoR",
    "_warnings": ["[UoR] Art.12: Termin zamknięcia = 3 mies. od dnia bilansowego (do 31 marca)"],
    "deadline": "31 marca następnego roku"
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a12.r3",
    "package": "jdg.uor.books",
    "priority": 100058,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 12 ust. 2 UoR",
    "_warnings": ["[UoR] Art.12: Przenieś salda kont wynikowych (4,5,7) na konto 860"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a12.r4",
    "package": "jdg.uor.books",
    "priority": 100059,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 12 ust. 3 UoR",
    "_warnings": ["[UoR] Art.12: Uzgodnienie obrotów i sald kont analitycznych z syntetycznymi"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a12.r5",
    "package": "jdg.uor.books",
    "priority": 100060,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 12 ust. 4 UoR",
    "_warnings": ["[UoR] Art.12: Inwentaryzacja aktywów i pasywów przed zamknięciem"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a13.r1",
    "package": "jdg.uor.books",
    "priority": 100061,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Próba modyfikacji ostatecznie zamkniętych ksiąg — NARUSZENIE!",
    "_legal_basis": "Art. 13 ust. 1 UoR",
    "_warnings": ["[UoR] Art.13: Ostatecznie zamknięte księgi NIE MOGĄ być modyfikowane!"],
    "immutable": true
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "books_finally_closed", false) == true
    object.get(input.invoice, "attempt_modification_after_close", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a13.r2",
    "package": "jdg.uor.books",
    "priority": 100062,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sprawozdanie finansowe NIE zatwierdzone w terminie 6 miesięcy!",
    "_legal_basis": "Art. 13 ust. 2; Art. 53 UoR",
    "_warnings": ["[UoR] Art.13: Zatwierdź sprawozdanie w ciągu 6 mies. od dnia bilansowego!"],
    "deadline": "30 czerwca następnego roku"
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "fs_approved", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a13.r3",
    "package": "jdg.uor.books",
    "priority": 100063,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 13 ust. 3 UoR",
    "_warnings": ["[UoR] Art.13: ✅ Księgi zamknięte i sprawozdanie zatwierdzone"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "books_closed", false) == true
    object.get(input.jdg_entrepreneur, "fs_approved", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a13.r4",
    "package": "jdg.uor.books",
    "priority": 100064,
    "_routing": "WARNING",
    "_routing_reason": "Korekta po zamknięciu ksiąg — dozwolona tylko przed zatwierdzeniem!",
    "_legal_basis": "Art. 13 ust. 4; Art. 54 UoR",
    "_warnings": ["[UoR] Art.13: Korekty po zamknięciu tylko przed zatwierdzeniem sprawozdania!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_correction_after_close", false) == true
    object.get(input.jdg_entrepreneur, "fs_approved", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a13.r5",
    "package": "jdg.uor.books",
    "priority": 100065,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Korekta PO zatwierdzeniu sprawozdania — ZABRONIONE! Tylko w następnym roku!",
    "_legal_basis": "Art. 13 ust. 4; Art. 54 ust. 2 UoR",
    "_warnings": ["[UoR] Art.13: ❌ Korekta PO zatwierdzeniu — księguj w bieżącym roku jako błąd lat ubiegłych!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_correction_after_close", false) == true
    object.get(input.jdg_entrepreneur, "fs_approved", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 14–16 — Rok obrotowy, okres sprawozdawczy (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a14.r1",
    "package": "jdg.uor.books",
    "priority": 100066,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 ust. 1 UoR",
    "_warnings": ["[UoR] Art.14: Rok obrotowy = 01.01–31.12 (chyba że zmieniony)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a14.r2",
    "package": "jdg.uor.books",
    "priority": 100067,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14 ust. 2 UoR",
    "_warnings": ["[UoR] Art.14: Pierwszy rok obrotowy może być krótszy niż 12 miesięcy"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "uor_first_year", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a14.r3",
    "package": "jdg.uor.books",
    "priority": 100068,
    "_routing": "WARNING",
    "_routing_reason": "Zmiana roku obrotowego — zgłoś do US w ciągu 30 dni!",
    "_legal_basis": "Art. 14 ust. 3 UoR",
    "_warnings": ["[UoR] Art.14: Zmiana roku obrotowego — zgłoszenie NIP-2 w ciągu 30 dni!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "fiscal_year_changed", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a15.r1",
    "package": "jdg.uor.books",
    "priority": 100069,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 15 UoR",
    "_warnings": ["[UoR] Art.15: Okresem sprawozdawczym jest miesiąc (dla celów VAT i zaliczek PIT)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a16.r1",
    "package": "jdg.uor.books",
    "priority": 100070,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 16 UoR",
    "_warnings": ["[UoR] Art.16: Sprawozdanie na dzień poprzedzający zmianę roku obrotowego"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "fiscal_year_changed", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 17 — Księgi rachunkowe — dziennik, księga główna, księgi pomocnicze (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a17.r1",
    "package": "jdg.uor.books",
    "priority": 100071,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Dziennik nieprowadzony — OBOWIĄZKOWY element ksiąg!",
    "_legal_basis": "Art. 17 ust. 1 pkt 1 UoR",
    "_warnings": ["[UoR] Art.17: Dziennik — obowiązkowy, zapisy chronologiczne, kolejno numerowane!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "journal_exists", true) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a17.r2",
    "package": "jdg.uor.books",
    "priority": 100072,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Księga główna nieprowadzona — OBOWIĄZKOWY element ksiąg!",
    "_legal_basis": "Art. 17 ust. 1 pkt 2 UoR",
    "_warnings": ["[UoR] Art.17: Księga główna — obowiązkowa, konta syntetyczne wg ZPK!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "general_ledger_exists", true) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a17.r3",
    "package": "jdg.uor.books",
    "priority": 100073,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 3 UoR",
    "_warnings": ["[UoR] Art.17: Księgi pomocnicze — konta analityczne dla kont syntetycznych"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a17.r4",
    "package": "jdg.uor.books",
    "priority": 100074,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 4 UoR",
    "_warnings": ["[UoR] Art.17: Zestawienie obrotów i sald — miesięczne uzgodnienie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a17.r5",
    "package": "jdg.uor.books",
    "priority": 100075,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 5 UoR",
    "_warnings": ["[UoR] Art.17: Inwentarz — spis aktywów i pasywów potwierdzający salda"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a17.r6",
    "package": "jdg.uor.books",
    "priority": 100076,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Luki w numeracji dziennika — potencjalne naruszenie rzetelności!",
    "_legal_basis": "Art. 17 ust. 2; Art. 24 ust. 1 UoR",
    "_warnings": ["[UoR] Art.17: Luki w numeracji — sprawdź kompletność zapisów!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "journal_gaps_detected", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a17.r7",
    "package": "jdg.uor.books",
    "priority": 100077,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 2 UoR",
    "_warnings": ["[UoR] Art.17: Sumy miesięczne obrotów dziennika muszą być zgodne z obrotami kont księgi głównej"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a17.r8",
    "package": "jdg.uor.books",
    "priority": 100078,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 UoR",
    "_warnings": ["[UoR] Art.17: ✅ Komplet ksiąg: dziennik + księga główna + księgi pomocnicze + ZOiS + inwentarz"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "journal_exists", false) == true
    object.get(input.jdg_entrepreneur, "general_ledger_exists", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 20–21 — Dowody księgowe (12 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r1",
    "package": "jdg.uor.books",
    "priority": 100079,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Dowód księgowy niekompletny — brak elementów krytycznych!",
    "_legal_basis": "Art. 20-21 UoR",
    "_warnings": ["[UoR] Art.20: Dowód MUSI zawierać: nazwa, adres, NIP, data, opis, kwota, nr dokumentu, podpisy!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    invoice_number := object.get(input.invoice, "invoice_number", "")
    invoice_number == ""
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r2",
    "package": "jdg.uor.books",
    "priority": 100080,
    "_routing": "WARNING",
    "_routing_reason": "Dowód księgowy niekompletny — brak elementów uzupełniających",
    "_legal_basis": "Art. 20-21 UoR",
    "_warnings": ["[UoR] Art.20: Sprawdź kompletność 15 elementów dowodu księgowego!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    has_vat_rate := object.get(input.invoice, "vat_rate", "") != ""
    has_payment := object.get(input.invoice, "payment_method", "") != ""
    has_currency := object.get(input.invoice, "currency", "PLN") != ""
    not (has_vat_rate and has_payment and has_currency)
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r3",
    "package": "jdg.uor.books",
    "priority": 100081,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "NIP kontrahenta niezweryfikowany — sprawdź w białej liście VAT!",
    "_legal_basis": "Art. 21 ust. 1 pkt 5 UoR; Art. 96b VAT",
    "_warnings": ["[UoR] Art.21: NIP kontrahenta — zweryfikuj w białej liście VAT (Art. 96b VAT)!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    nip := object.get(input.vendor, "nip", "")
    nip == ""
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r4",
    "package": "jdg.uor.books",
    "priority": 100082,
    "_routing": "WARNING",
    "_routing_reason": "Opis operacji zbyt ogólny — nie umożliwia identyfikacji zdarzenia!",
    "_legal_basis": "Art. 21 ust. 1 pkt 4 UoR",
    "_warnings": ["[UoR] Art.21: Opis operacji zbyt krótki (<5 znaków) — dodaj szczegółowy opis!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    desc := object.get(input.invoice, "description", "")
    count(desc) < 5
    desc != ""
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r5",
    "package": "jdg.uor.books",
    "priority": 100083,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Data wystawienia ≠ data operacji — sprawdź okres księgowania!",
    "_legal_basis": "Art. 21 ust. 1 pkt 1-2 UoR",
    "_warnings": ["[UoR] Art.21: Różne daty wystawienia i operacji!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    issue_date := object.get(input.invoice, "issue_date", "")
    transaction_date := object.get(input.invoice, "transaction_date", "")
    issue_date != transaction_date
    issue_date != ""
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r6",
    "package": "jdg.uor.books",
    "priority": 100084,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 9 UoR; Art. 30 UoR",
    "_warnings": ["[UoR] Art.21: Waluta obca — przelicz wg kursu NBP (Art. 30 UoR)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    currency := object.get(input.invoice, "currency", "PLN")
    currency != "PLN"
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r7",
    "package": "jdg.uor.books",
    "priority": 100085,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 2 UoR",
    "_warnings": ["[UoR] Art.21: Dowód zbiorczy — musi zawierać listę pojedynczych dowodów źródłowych"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_collective_document", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r8",
    "package": "jdg.uor.books",
    "priority": 100086,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 ust. 3 UoR",
    "_warnings": ["[UoR] Art.22: Korekta błędu — przez skreślenie + data + podpis (lub dokument korygujący)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_correction", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r9",
    "package": "jdg.uor.books",
    "priority": 100087,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 20-21 UoR",
    "_warnings": ["[UoR] Art.20: ✅ Dowód księgowy kompletny — wszystkie elementy obecne"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "document_complete_15_elements", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r10",
    "package": "jdg.uor.books",
    "priority": 100088,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak podpisu na dowodzie księgowym!",
    "_legal_basis": "Art. 21 ust. 1 pkt 8 UoR",
    "_warnings": ["[UoR] Art.21: Podpis wystawcy i odbiorcy OBOWIĄZKOWY na dowodzie księgowym!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "signature_present", true) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r11",
    "package": "jdg.uor.books",
    "priority": 100089,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 6 UoR",
    "_warnings": ["[UoR] Art.21: Numer identyfikacyjny dowodu — nadany przez jednostkę"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "internal_doc_number", "") != ""
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a20.r12",
    "package": "jdg.uor.books",
    "priority": 100090,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22 UoR",
    "_warnings": ["[UoR] Art.22: Każdy zapis w dzienniku musi być powiązany z dowodem księgowym!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ART. 23–24 — Zapisy księgowe, rzetelność, trwałość (14 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a23.r1",
    "package": "jdg.uor.books",
    "priority": 100091,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Podwójny zapis NARUSZONY — Wn ≠ Ma!",
    "_legal_basis": "Art. 23 ust. 1 UoR",
    "_warnings": ["[UoR] Art.23: PODWÓJNY ZAPIS — suma Wn musi być równa sumie Ma!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    debit := object.get(input.invoice, "journal_debit_total", 0)
    credit := object.get(input.invoice, "journal_credit_total", 0)
    abs(debit - credit) >= 0.01
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a23.r2",
    "package": "jdg.uor.books",
    "priority": 100092,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 UoR",
    "_warnings": ["[UoR] Art.23: ✅ Podwójny zapis prawidłowy — Wn = Ma"]
} {
    debit := object.get(input.invoice, "journal_debit_total", 0)
    credit := object.get(input.invoice, "journal_credit_total", 0)
    abs(debit - credit) < 0.01
    debit > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a24.r1",
    "package": "jdg.uor.books",
    "priority": 100093,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zapisy NIE są chronologiczne!",
    "_legal_basis": "Art. 24 ust. 1 UoR",
    "_warnings": ["[UoR] Art.24: Zapisy MUSZĄ być chronologiczne i systematyczne!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "entry_non_chronological", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a24.r2",
    "package": "jdg.uor.books",
    "priority": 100094,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Próba KASOWANIA zapisu księgowego — NARUSZENIE!",
    "_legal_basis": "Art. 24 ust. 1; Art. 25 UoR",
    "_warnings": ["[UoR] Art.24: ZAKAZ KASOWANIA ZAPISÓW! Tylko storno lub korekta!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "entry_deleted", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a24.r3",
    "package": "jdg.uor.books",
    "priority": 100095,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 24 ust. 2 UoR",
    "_warnings": ["[UoR] Art.24: Storno czarne (zapis odwrotny) lub czerwone (zmniejszające)"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a24.r4",
    "package": "jdg.uor.books",
    "priority": 100096,
    "_routing": "WARNING",
    "_routing_reason": "Luki w numeracji zapisów — potencjalne naruszenie rzetelności!",
    "_legal_basis": "Art. 24 ust. 1 UoR",
    "_warnings": ["[UoR] Art.24: Luki w numeracji zapisów — sprawdź kompletność!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "journal_gaps_detected", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a24.r5",
    "package": "jdg.uor.books",
    "priority": 100097,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 24 ust. 4 UoR",
    "_warnings": ["[UoR] Art.24: Okres przechowywania: księgi 5 lat, zatwierdzone sprawozdania — bezterminowo!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a24.r6",
    "package": "jdg.uor.books",
    "priority": 100098,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 24 ust. 3 UoR",
    "_warnings": ["[UoR] Art.24: Korekta zapisu — data korekty, podpis osoby upoważnionej, uzasadnienie"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_correction", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a24.r7",
    "package": "jdg.uor.books",
    "priority": 100099,
    "_routing": "WARNING",
    "_routing_reason": "Zapisy księgowe sprzed >5 lat — archiwizuj ale nie kasuj przed upływem terminu!",
    "_legal_basis": "Art. 24 ust. 4; Art. 74 UoR",
    "_warnings": ["[UoR] Art.24: Archiwizacja zapisów >5 lat — sprawdź terminy przechowywania!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    current_year := object.get(input.invoice, "transaction_year", 0)
    years_ago := 2026 - current_year
    years_ago > 5
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a24.r8",
    "package": "jdg.uor.books",
    "priority": 100100,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Zmiana zapisu po zamknięciu — NARUSZENIE Art. 24!",
    "_legal_basis": "Art. 24 ust. 1; Art. 25 UoR",
    "_warnings": ["[UoR] Art.24: Zapis po zamknięciu = NIENARUSZALNY!"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.jdg_entrepreneur, "books_closed", false) == true
    object.get(input.invoice, "entry_modified_after_close", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.uor.books.a24.r9",
    "package": "jdg.uor.books",
    "priority": 100101,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 24 UoR",
    "_warnings": ["[UoR] Art.24: ✅ Księgi prowadzone rzetelnie, bezbłędnie, sprawdzalnie i na bieżąco"]
} {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
}
