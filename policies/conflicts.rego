# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Cross-Domain Conflict Detection (R0586-R0612)
# ═══════════════════════════════════════════════════════════════════════════════
#
# DOCUMENTATION METADATA (kept as comments; not an OPA metadata annotation)
# title: Cross-Domain Conflict Detection — IP Box vs B+R, Reprezentacja vs
#        Marketing, Auto VAT vs KUP, Bad Debt Timing, Depreciation FX conflicts
# description: |
#   PAS 8 Post-Merge Conflict Detection. First-Match-Wins else-chain.
#   Wykrywa konflikty między domenami, które zostały ukryte przez object.union().
#   Działa jako ostatni pas przed finalnym werdyktem — analizuje już scalony
#   werdykt i wykrywa niespójności między decyzjami z różnych pakietów.
#
#   Architektura: Post-merge — pobiera final_verdict jako input, analizuje
#   wszystkie pola i flaguje konflikty z rekomendacją priorytetu domeny.
#   NIE zmienia wartości — tylko raportuje konflikty do _cross_domain_conflicts.
# architecture: Post-Merge Cross-Domain (ADR-001, PAS 8)
# legal_basis: Art. 30ca PIT (IP Box), Art. 26e PIT (B+R), Art. 23 ust. 1 pkt 23
#              PIT (reprezentacja), Art. 86a VAT (auto), Art. 89a VAT (złe długi),
#              Art. 26i PIT (złe długi PIT), Art. 22a-22o PIT (amortyzacja)
# edge_cases:
#   - IP Box + B+R na tym samym dochodzie → konflikt (wybierz jeden)
#   - Reprezentacja vs marketing — borderline (restauracje, eventy)
#   - Auto bez ewidencji → VAT 50%, KUP 75% → uzasadniona asymetria
#   - Złe długi: VAT 90 dni vs PIT 90 dni → zharmonizowane (SLIM VAT 3/2023)
# package: jdg.conflicts
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.conflicts

import future.keywords.in
import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.conflicts.no_conflicts",
    "package": "jdg.conflicts",
    "priority": 619
}

# ═══════════════════════════════════════════════════════════════════════════════
# R0586-R0592: IP Box vs B+R (R&D) — Konflikty ulg innowacyjnych
# ═══════════════════════════════════════════════════════════════════════════════
# Problem: IP Box (Art. 30ca PIT, 5%) i B+R (Art. 26e PIT, 100%/200%)
# nie mogą być stosowane do tego samego dochodu. Podatnik musi wybrać JEDNĄ
# ulgę dla danego kwalifikowanego IP.
# Źródło: Art. 30ca ust. 3 PIT — wyłączenie stosowania IP Box do dochodu
# już objętego ulgą B+R.
# ═══════════════════════════════════════════════════════════════════════════════

# R0586: ip_box_vs_rd_same_income — IP Box + B+R na tym samym dochodzie
decide := {
    "matched": true,
    "rule_id": "jdg.conflicts.ip_box_vs_rd_same_income",
    "package": "jdg.conflicts",
    "priority": 586,
    "cross_domain_conflict": true,
    "conflict_domains": ["allowances", "allowances"],
    "conflict_severity": "CRITICAL",
    "conflict_resolution": "PREFER_IP_BOX_OR_RD_USER_CHOICE",
    "conflict_message": "IP Box (5%) i B+R (100-200%) nie mogą być stosowane do tego samego dochodu — wybierz jedną ulgę (Art. 30ca ust. 3 PIT)",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Konflikt IP Box vs B+R — ten sam dochód objęty dwiema ulgami",
    "_legal_basis": "Art. 30ca ust. 3 PIT, Art. 26e PIT",
    "_warnings": ["IP BOX vs B+R: ten sam przychód z kwalifikowanego IP nie może być jednocześnie objęty IP Box (5%) i ulgą B+R. Wybierz JEDNĄ ulgę dla tego składnika."],
    "valid_from": "2019-01-01",
    "valid_to": null,
    "decision_mode": "SUGGEST",
} {
    input.jdg_entrepreneur.has_rd_status == true
    input.invoice.expense_type == "IP_INCOME"
    # IP Box + B+R na tym samym dochodzie = konflikt (auto-detekcja)
    input.invoice.ip_box_claimed == true
    input.invoice.rd_relief_claimed == true
}

# R0587: ip_box_no_nexus_indicator — Brak wskaźnika Nexus
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.ip_box_no_nexus_indicator",
    "package": "jdg.conflicts",
    "priority": 587,
    "cross_domain_conflict": true,
    "conflict_domains": ["allowances"],
    "conflict_severity": "HIGH",
    "conflict_resolution": "DENY_IP_BOX",
    "conflict_message": "IP Box wymaga wyliczenia wskaźnika Nexus (Art. 30ca ust. 4 PIT) — brak wskaźnika = odmowa ulgi",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "IP Box — brak obowiązkowego wskaźnika Nexus",
    "_legal_basis": "Art. 30ca ust. 4-7 PIT",
    "_warnings": ["IP BOX: wymagany wskaźnik Nexus (kalkulacja: dochód kwalifikowany × wskaźnik). Bez wskaźnika IP Box NIE MOŻE być zastosowany."]
} {
    input.invoice.expense_type == "IP_INCOME"
    input.invoice.ip_box_claimed == true
    input.invoice.nexus_indicator_calculated == false
}

# R0588: ip_box_no_separate_records — Brak wyodrębnionej ewidencji IP Box
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.ip_box_no_separate_records",
    "package": "jdg.conflicts",
    "priority": 588,
    "cross_domain_conflict": true,
    "conflict_domains": ["allowances", "accounting"],
    "conflict_severity": "CRITICAL",
    "conflict_resolution": "DENY_IP_BOX",
    "conflict_message": "IP Box wymaga wyodrębnionej ewidencji rachunkowej (Art. 30cb PIT)",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "IP Box — brak wyodrębnionej ewidencji kosztów i przychodów",
    "_legal_basis": "Art. 30cb ust. 1-2 PIT",
    "_warnings": ["IP BOX: WYMAGANA wyodrębniona ewidencja rachunkowa dla każdego kwalifikowanego IP. Konta analityczne: przychody, koszty bezpośrednie, koszty pośrednie, wskaźnik Nexus."]
} {
    input.invoice.expense_type == "IP_INCOME"
    input.invoice.ip_box_claimed == true
    input.invoice.has_separate_ip_records == false
}

# R0589: ip_box_rd_double_counting_costs — Podwójne liczenie kosztów B+R w IP Box
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.ip_box_rd_double_counting_costs",
    "package": "jdg.conflicts",
    "priority": 589,
    "cross_domain_conflict": true,
    "conflict_domains": ["allowances"],
    "conflict_severity": "HIGH",
    "conflict_resolution": "DEDUPLICATE_COSTS",
    "conflict_message": "Koszty B+R nie mogą być jednocześnie odliczane jako ulga B+R i koszty IP Box",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Podwójne liczenie kosztów B+R w IP Box — potencjalne zawyżenie ulgi",
    "_legal_basis": "Art. 30ca ust. 3 PIT, Art. 26e PIT",
    "_warnings": ["PODWÓJNE KOSZTY: te same koszty kwalifikowane B+R ujęte zarówno w uldze B+R jak i w kalkulacji dochodu IP Box. Usuń duplikację."]
} {
    # Podwójne liczenie: koszty B+R > 0 w IP Box + przedsiębiorca ma status B+R
    input.jdg_entrepreneur.has_rd_status == true
    input.invoice.rd_costs_in_ip_box > 0
}

# R0590: ip_box_income_threshold_exceeded — Przekroczenie progu IP Box z B+R
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.ip_box_income_threshold_exceeded",
    "package": "jdg.conflicts",
    "priority": 590,
    "cross_domain_conflict": true,
    "conflict_domains": ["allowances"],
    "conflict_severity": "WARNING",
    "conflict_resolution": "CAP_IP_BOX",
    "conflict_message": "Dochód IP Box + B+R przekracza całkowity dochód — ograniczono",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30ca ust. 1 PIT",
    "_warnings": [sprintf("IP BOX LIMIT: dochód z IP Box (%.2f PLN) + ulga B+R (%.2f PLN) > dochód całkowity (%.2f PLN). Ograniczono do dochodu.", [ip_income, rd_relief, total_income])]
} {
    ip_income := object.get(input.invoice, "ip_box_income", 0)
    rd_relief := object.get(input.invoice, "rd_relief_amount", 0)
    total_income := object.get(input.invoice, "taxable_income", 0)
    total_income > 0
    ip_income + rd_relief > total_income
}

# R0591: ip_box_other_relief_same_asset — IP Box + inna ulga na ten sam składnik IP
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.ip_box_other_relief_same_asset",
    "package": "jdg.conflicts",
    "priority": 591,
    "cross_domain_conflict": true,
    "conflict_domains": ["allowances"],
    "conflict_severity": "HIGH",
    "conflict_resolution": "PREFER_IP_BOX_OR_OTHER_USER_CHOICE",
    "conflict_message": "Ten sam składnik IP nie może być objęty IP Box i inną ulgą podatkową jednocześnie",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Konflikt ulg na tym samym składniku IP",
    "_legal_basis": "Art. 30ca ust. 3 PIT",
    "_warnings": [sprintf("KONFLIKT ULG: składnik IP '%s' objęty IP Box (5%%) oraz ulgą: %s. Wybierz jedną ulgę.", [asset_name, other_relief_type])]
} {
    input.invoice.expense_type == "IP_INCOME"
    asset_name := object.get(input.invoice, "ip_asset_name", "")
    other_relief_type := object.get(input.invoice, "other_relief_on_same_asset", "")
    other_relief_type != ""
}

# R0592: ip_box_qualification_failed — Kwalifikowane IP nie spełnia definicji
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.ip_box_qualification_failed",
    "package": "jdg.conflicts",
    "priority": 592,
    "cross_domain_conflict": true,
    "conflict_domains": ["allowances"],
    "conflict_severity": "CRITICAL",
    "conflict_resolution": "DENY_IP_BOX",
    "conflict_message": "Dochód nie spełnia definicji kwalifikowanego IP (Art. 30ca ust. 2 PIT)",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "IP Box — dochód nie jest z kwalifikowanego IP",
    "_legal_basis": "Art. 30ca ust. 2 PIT",
    "_warnings": ["IP BOX ODMOWA: dochód nie pochodzi z kwalifikowanego IP (wymagane: patent, prawo ochronne na wzór użytkowy, prawo z rejestracji wzoru przemysłowego, topografia układu scalonego, autorskie prawo do programu komputerowego)."]
} {
    input.invoice.expense_type == "IP_INCOME"
    input.invoice.ip_box_claimed == true
    qualified_types := {"SOFTWARE", "PATENT", "UTILITY_MODEL", "INDUSTRIAL_DESIGN", "INTEGRATED_CIRCUIT"}
    ip_type := object.get(input.invoice, "ip_asset_type", "")
    not qualified_types[ip_type]
}

# ═══════════════════════════════════════════════════════════════════════════════
# R0593-R0598: Reprezentacja vs Marketing — Konflikt klasyfikacji wydatków
# ═══════════════════════════════════════════════════════════════════════════════
# Problem: Reprezentacja (Art. 23 ust. 1 pkt 23 PIT) jest NKUP, ale marketing
# może być KUP. Granica jest płynna — restauracje, eventy, upominki.
# Kluczowe rozróżnienie: czy wydatek buduje wizerunek (reprezentacja → NKUP)
# czy promuje konkretny produkt/usługę (marketing/reklama → KUP).
# ═══════════════════════════════════════════════════════════════════════════════

# R0593: representation_vs_marketing_classification — Klasyfikacja wydatku
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.representation_vs_marketing_classification",
    "package": "jdg.conflicts",
    "priority": 593,
    "cross_domain_conflict": true,
    "conflict_domains": ["pit", "accounting"],
    "conflict_severity": "HIGH",
    "conflict_resolution": "PREFER_PIT_KUP_NKUP",
    "conflict_message": "Wydatek sklasyfikowany jako reprezentacja (NKUP) i marketing (KUP) jednocześnie — rozstrzygnij",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Niejednoznaczna klasyfikacja: reprezentacja vs marketing",
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT",
    "_warnings": [sprintf("KLASYFIKACJA SPORNA: wydatek '%s' (%.2f PLN) — reprezentacja (NKUP) czy marketing (KUP)? Restauracje/eventy/upominki wymagają udokumentowania celu biznesowego.", [expense_desc, expense_amount])]
} {
    input.invoice.expense_type in {"REPRESENTATION", "MARKETING", "ADVERTISING"}
    expense_desc := object.get(input.invoice, "description", "brak opisu")
    expense_amount := object.get(input.invoice, "amount_net", 0)
    # Konflikt: pit/kup twierdzi NKUP, ale accounting twierdzi KUP
    input.invoice.representation_classification_conflict == true
}

# R0594: borderline_expense_restaurant — Wydatek restauracyjny — potencjalna reprezentacja
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.borderline_expense_restaurant",
    "package": "jdg.conflicts",
    "priority": 594,
    "cross_domain_conflict": true,
    "conflict_domains": ["pit", "vat"],
    "conflict_severity": "WARNING",
    "conflict_resolution": "REQUIRE_BUSINESS_PURPOSE_DOCUMENTATION",
    "conflict_message": "Wydatek restauracyjny — może być reprezentacją (NKUP) lub kosztem firmowym (KUP)",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Wydatek restauracyjny — wymagane udokumentowanie celu biznesowego",
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT, interpretacje podatkowe",
    "_warnings": [sprintf("RESTAURACJA: %.2f PLN — udokumentuj cel spotkania (kontrahent, omawiane tematy). Bez dokumentacji = reprezentacja NKUP.", [meal_amount])]
} {
    input.invoice.category_code == "RESTAURANT"
    meal_amount := object.get(input.invoice, "amount_net", 0)
    input.invoice.has_business_purpose_doc == false
}

# R0595: borderline_expense_event — Wydatek na event — potencjalna reprezentacja
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.borderline_expense_event",
    "package": "jdg.conflicts",
    "priority": 595,
    "cross_domain_conflict": true,
    "conflict_domains": ["pit", "accounting"],
    "conflict_severity": "WARNING",
    "conflict_resolution": "REQUIRE_EVENT_AGENDA_AND_ATTENDEE_LIST",
    "conflict_message": "Wydatek na event/konferencję — borderline reprezentacja vs marketing",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Event bez agendy merytorycznej = reprezentacja NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT, wyrok NSA II FSK 2345/17",
    "_warnings": [sprintf("EVENT: %.2f PLN — wymagana agenda merytoryczna + lista uczestników. Bez tego = reprezentacja NKUP.", [event_amount])]
} {
    input.invoice.category_code in {"EVENT", "CONFERENCE", "BANQUET"}
    event_amount := object.get(input.invoice, "amount_net", 0)
    input.invoice.has_event_agenda == false
}

# R0596: representation_with_business_purpose — Reprezentacja z udokumentowanym celem
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.representation_with_business_purpose",
    "package": "jdg.conflicts",
    "priority": 596,
    "cross_domain_conflict": true,
    "conflict_domains": ["pit", "accounting"],
    "conflict_severity": "INFO",
    "conflict_resolution": "ALLOW_KUP_IF_DOCUMENTED",
    "conflict_message": "Reprezentacja z udokumentowanym celem biznesowym — może być KUP (interpretacja podatkowa)",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Interpretacja ogólna MF z 25.11.2019, wyroki NSA",
    "_warnings": [sprintf("REPREZENTACJA UDOKUMENTOWANA: %.2f PLN — cel biznesowy: %s. Może być KUP (zgodnie z linią orzeczniczą). Zachowaj dokumentację na wypadek kontroli.", [expense_amount, business_purpose])]
} {
    input.invoice.expense_type == "REPRESENTATION"
    expense_amount := object.get(input.invoice, "amount_net", 0)
    business_purpose := object.get(input.invoice, "business_purpose_desc", "")
    business_purpose != ""
    input.invoice.business_purpose_credible == true
}

# R0597: advertising_vs_representation_distinction — Reklama vs reprezentacja
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.advertising_vs_representation_distinction",
    "package": "jdg.conflicts",
    "priority": 597,
    "cross_domain_conflict": true,
    "conflict_domains": ["pit", "vat"],
    "conflict_severity": "INFO",
    "conflict_resolution": "ALLOW_BOTH_IF_SEPARATE",
    "conflict_message": "Reklama (KUP, VAT 100%) i reprezentacja (NKUP, VAT 0%) — klasyfikuj osobno",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT, Art. 86a VAT",
    "_warnings": [sprintf("REKLAMA vs REPREZENTACJA: wydatek %.2f PLN — reklama promuje produkt/usługę (KUP+VAT), reprezentacja buduje wizerunek (NKUP, bez VAT). Rozdziel na fakturze.", [mixed_amount])]
} {
    input.invoice.expense_type == "MIXED_ADVERTISING_REPRESENTATION"
    mixed_amount := object.get(input.invoice, "amount_net", 0)
    mixed_amount > 0
}

# R0598: representation_limit_exceeded — Próg 0.25% przychodu dla reprezentacji
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.representation_limit_exceeded",
    "package": "jdg.conflicts",
    "priority": 598,
    "cross_domain_conflict": true,
    "conflict_domains": ["pit", "accounting"],
    "conflict_severity": "WARNING",
    "conflict_resolution": "FLAG_EXCESSIVE_REPRESENTATION",
    "conflict_message": "Koszty reprezentacji > 0.25% przychodu — ryzyko kontroli",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Wysokie koszty reprezentacji — ryzyko zakwestionowania przez US",
    "_legal_basis": "Praktyka kontroli skarbowych, Art. 23 ust. 1 pkt 23 PIT",
    "_warnings": [sprintf("REPREZENTACJA LIMIT: %.2f PLN (%.2f%% przychodu) — powyżej typowego progu 0.25%%. US może zakwestionować.", [repr_total, repr_pct])]
} {
    repr_total := object.get(input.invoice, "representation_annual_total", 0)
    annual_revenue := object.get(input.invoice, "annual_revenue", 0)
    annual_revenue > 0
    repr_pct := repr_total / annual_revenue * 100
    repr_pct > 0.25
}

# ═══════════════════════════════════════════════════════════════════════════════
# R0599-R0604: Auto mieszane — VAT vs KUP (asymetria stawek)
# ═══════════════════════════════════════════════════════════════════════════════
# Problem: Samochód firmowy używany prywatnie bez ewidencji przebiegu:
#   VAT: odliczenie 50% (Art. 86a ust. 1 VAT)
#   PIT: KUP 75% (Art. 23 ust. 1 pkt 46 PIT)
# Asymetria 50% vs 75% jest PRAWIDŁOWA (różne podstawy prawne), ale może
# być myląca. Konflikt występuje tylko gdy ewidencja istnieje ale nie jest
# kompletna, lub gdy podatnik próbuje odliczyć 100% VAT bez ewidencji.
# ═══════════════════════════════════════════════════════════════════════════════

# R0599: car_vat_vs_kup_asymmetry — Naturalna asymetria VAT 50% vs KUP 75%
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.car_vat_vs_kup_asymmetry",
    "package": "jdg.conflicts",
    "priority": 599,
    "cross_domain_conflict": true,
    "conflict_domains": ["vat", "pit"],
    "conflict_severity": "INFO",
    "conflict_resolution": "ACCEPT_ASYMMETRY",
    "conflict_message": "Auto bez ewidencji: VAT 50% vs KUP 75% — asymetria prawidłowa (różne podstawy prawne)",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86a VAT vs Art. 23 ust. 1 pkt 46 PIT",
    "_warnings": ["AUTO MIESZANE: VAT 50% / KUP 75% — asymetria jest PRAWIDŁOWA. VAT ograniczony ustawą o VAT, KUP ograniczony ustawą o PIT. Różne reżimy prawne."]
} {
    input.invoice.category_code == "CAR"
    input.invoice.private_use_percent > 0
    input.invoice.has_mileage_log == false
    input.invoice.vat_deduction_percent == 50
    input.invoice.kup_percent == 75
}

# R0600: car_with_mileage_log_full_deduction — Auto z ewidencją → 100% VAT i KUP
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.car_with_mileage_log_full_deduction",
    "package": "jdg.conflicts",
    "priority": 600,
    "cross_domain_conflict": false,
    "conflict_domains": ["vat", "pit", "accounting"],
    "conflict_severity": "INFO",
    "conflict_resolution": "ALLOW_FULL_DEDUCTION",
    "conflict_message": "Auto z ewidencją przebiegu — VAT 100%, KUP 100%, brak konfliktu",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86a ust. 3-4 VAT, Art. 23 ust. 1 pkt 46 PIT",
    "_warnings": ["AUTO Z EWIDENCJĄ: prowadzona ewidencja przebiegu — pełne odliczenie VAT 100% i KUP 100%. Pamiętaj o zgłoszeniu VAT-26 do US!"]
} {
    input.invoice.category_code == "CAR"
    input.invoice.has_mileage_log == true
    input.invoice.mileage_log_complete == true
}

# R0601: car_no_mileage_log_100pct_vat_blocked — Próba 100% VAT bez ewidencji
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.car_no_mileage_log_100pct_vat_blocked",
    "package": "jdg.conflicts",
    "priority": 601,
    "cross_domain_conflict": true,
    "conflict_domains": ["vat"],
    "conflict_severity": "CRITICAL",
    "conflict_resolution": "DENY_100PCT_VAT_WITHOUT_LOG",
    "conflict_message": "Odliczenie 100% VAT bez ewidencji przebiegu i VAT-26 — NIEDOZWOLONE",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Auto — próba odliczenia 100% VAT bez ewidencji przebiegu",
    "_legal_basis": "Art. 86a ust. 1 VAT",
    "_warnings": ["AUTO VAT BLOKADA: 100% VAT niedozwolone bez prowadzenia ewidencji przebiegu i złożenia VAT-26. Maksymalne odliczenie: 50% VAT."]
} {
    input.invoice.category_code == "CAR"
    input.invoice.has_mileage_log == false
    input.invoice.vat_deduction_percent > 50
}

# R0602: car_declared_business_but_private_use — Deklarowane jako firmowe, używane prywatnie
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.car_declared_business_but_private_use",
    "package": "jdg.conflicts",
    "priority": 602,
    "cross_domain_conflict": true,
    "conflict_domains": ["vat", "pit", "accounting"],
    "conflict_severity": "HIGH",
    "conflict_resolution": "REDUCE_TO_STATUTORY_LIMITS",
    "conflict_message": "Samochód deklarowany jako 100% firmowy, ale wykryto użytek prywatny",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Auto — deklarowane jako firmowe, ale wykryto użytek prywatny",
    "_legal_basis": "Art. 86a VAT, Art. 23 ust. 1 pkt 46 PIT",
    "_warnings": [sprintf("AUTO NIEPRAWIDŁOWA KLASYFIKACJA: deklarowane 100%% firmowe, ale private_use_percent=%.0f%%. Ograniczono VAT do 50%% i KUP do 75%%.", [private_pct])]
} {
    input.invoice.category_code == "CAR"
    private_pct := object.get(input.invoice, "private_use_percent", 0)
    private_pct > 0
    input.invoice.declared_business_only == true
}

# R0603: car_lease_vs_purchase_depreciation_conflict — Leasing vs zakup — różne limity
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.car_lease_vs_purchase_depreciation_conflict",
    "package": "jdg.conflicts",
    "priority": 603,
    "cross_domain_conflict": true,
    "conflict_domains": ["pit", "accounting"],
    "conflict_severity": "WARNING",
    "conflict_resolution": "APPLY_CORRECT_LIMIT_PER_METHOD",
    "conflict_message": "Leasing operacyjny vs zakup na firmę — różne limity KUP i VAT",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 47a PIT (leasing), Art. 22a-22o PIT (amortyzacja)",
    "_warnings": [sprintf("AUTO LEASING vs ZAKUP: leasing operacyjny — KUP pełny od rat (limit 150k/225k EV). Zakup — amortyzacja limitowana do 150k/225k. Wybrano: %s.", [acquisition_method])]
} {
    input.invoice.category_code == "CAR"
    acquisition_method := object.get(input.invoice, "car_acquisition_method", "")
    acquisition_method in {"LEASE", "PURCHASE", "RENTAL"}
}

# R0604: car_insurance_repair_vat_deduction — Ubezpieczenie/naprawa auta mieszanego
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.car_insurance_repair_vat_deduction",
    "package": "jdg.conflicts",
    "priority": 604,
    "cross_domain_conflict": true,
    "conflict_domains": ["vat", "pit"],
    "conflict_severity": "WARNING",
    "conflict_resolution": "APPLY_SAME_PERCENT_AS_MAIN_CAR",
    "conflict_message": "Ubezpieczenie/naprawa auta mieszanego — VAT i KUP proporcjonalnie jak dla auta",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86a VAT, Art. 23 ust. 1 pkt 46-47 PIT",
    "_warnings": [sprintf("AUTO NAPRAWA/UBEZPIECZENIE: %.2f PLN — stosuj tę samą proporcję VAT/KUP co dla głównego pojazdu (%d%% VAT, %d%% KUP).", [expense_amount, car_vat_pct, car_kup_pct])]
} {
    input.invoice.category_code in {"CAR_INSURANCE", "CAR_REPAIR", "CAR_MAINTENANCE"}
    expense_amount := object.get(input.invoice, "amount_net", 0)
    car_vat_pct := object.get(input.invoice, "car_vat_deduction_pct", 50)
    car_kup_pct := object.get(input.invoice, "car_kup_percent", 75)
    expense_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# R0606-R0610: Bad Debt — VAT i PIT (zharmonizowane 90 dni, SLIM VAT 3/2023)
# ═══════════════════════════════════════════════════════════════════════════════
# Problem: Ulga na złe długi w VAT (Art. 89a VAT, 90 dni od SLIM VAT 3/2023)
# i PIT (Art. 26i PIT, 90 dni) mają teraz zharmonizowane progi czasowe.
# R0605 (timing_diff_150_vs_90) został usunięty jako nieaktualny.
# Nadal istnieją różnice w warunkach formalnych między VAT i PIT.
# ═══════════════════════════════════════════════════════════════════════════════

# R0605: [USUNIĘTA — SLIM VAT 3/2023 zharmonizował terminy VAT i PIT do 90 dni]

# R0606: bad_debt_creditor_vat_corrected_but_not_pit — VAT skorygowany, PIT nie
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.bad_debt_creditor_vat_corrected_but_not_pit",
    "package": "jdg.conflicts",
    "priority": 606,
    "cross_domain_conflict": true,
    "conflict_domains": ["vat", "pit"],
    "conflict_severity": "HIGH",
    "conflict_resolution": "REQUIRE_PIT_CORRECTION_IF_ELIGIBLE",
    "conflict_message": "Wierzyciel skorygował VAT (złe długi) ale nie PIT — potencjalna niespójność",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Złe długi: VAT skorygowany, PIT nie — sprawdź czy PIT też się należy",
    "_legal_basis": "Art. 89a VAT, Art. 26i PIT",
    "_warnings": [sprintf("NIESPÓJNOŚĆ ZŁE DŁUGI: wierzyciel skorygował VAT (%.2f PLN) ale nie PIT. Jeśli >90 dni i spełnione warunki Art. 26i PIT — rozważ korektę PIT.", [vat_correction_amount])]
} {
    input.invoice.days_overdue >= 90
    input.invoice.vat_bad_debt_corrected == true
    input.invoice.pit_bad_debt_corrected == false
    vat_correction_amount := object.get(input.invoice, "vat_correction_amount", 0)
    vat_correction_amount > 0
}

# R0607: bad_debt_debtor_vat_vs_pit_income — Dłużnik: korekta VAT vs zwiększenie dochodu PIT
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.bad_debt_debtor_vat_vs_pit_income",
    "package": "jdg.conflicts",
    "priority": 607,
    "cross_domain_conflict": true,
    "conflict_domains": ["vat", "pit"],
    "conflict_severity": "HIGH",
    "conflict_resolution": "ENFORCE_BOTH_CORRECTIONS",
    "conflict_message": "Dłużnik: OBOWIĄZEK korekty VAT (Art. 89b) ORAZ zwiększenia dochodu PIT (Art. 26i ust. 9)",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Dłużnik złych długów — sprawdź obie korekty (VAT i PIT)",
    "_legal_basis": "Art. 89b VAT, Art. 26i ust. 9 PIT",
    "_warnings": [sprintf("DŁUŻNIK ZŁE DŁUGI: %.2f PLN niezapłacone >90 dni. OBOWIĄZEK: (1) korekta VAT naliczonego w JPK_V7, (2) zwiększenie dochodu PIT o niezapłaconą kwotę netto.", [unpaid_amount])]
} {
    input.invoice.days_overdue >= 90
    input.invoice.is_paid == false
    input.invoice.i_am_debtor == true
    unpaid_amount := object.get(input.invoice, "amount_net", 0)
    unpaid_amount > 0
}

# R0608: bad_debt_sold_to_collector — Wierzytelność sprzedana — brak ulgi
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.bad_debt_sold_to_collector",
    "package": "jdg.conflicts",
    "priority": 608,
    "cross_domain_conflict": true,
    "conflict_domains": ["vat", "pit"],
    "conflict_severity": "CRITICAL",
    "conflict_resolution": "DENY_BAD_DEBT_RELIEF",
    "conflict_message": "Wierzytelność sprzedana do windykatora — ulga na złe długi NIEDOZWOLONA",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Złe długi — wierzytelność zbyta, ulga niedozwolona",
    "_legal_basis": "Art. 89a ust. 7 VAT, Art. 26i ust. 6 PIT",
    "_warnings": ["ZŁE DŁUGI BLOKADA: wierzytelność została sprzedana/zbyta — NIE MOŻNA skorzystać z ulgi na złe długi (VAT ani PIT)."]
} {
    input.invoice.days_overdue >= 90
    input.invoice.receivable_sold_to_collector == true
}

# R0609: bad_debt_partial_payment_proportional — Częściowa zapłata — proporcjonalna korekta
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.bad_debt_partial_payment_proportional",
    "package": "jdg.conflicts",
    "priority": 609,
    "cross_domain_conflict": true,
    "conflict_domains": ["vat", "pit"],
    "conflict_severity": "WARNING",
    "conflict_resolution": "APPLY_PROPORTIONAL_CORRECTION",
    "conflict_message": "Częściowa zapłata — korekta VAT i PIT tylko od niezaplaconej części",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89a ust. 1 VAT, Art. 26i ust. 1 PIT",
    "_warnings": [sprintf("ZŁE DŁUGI CZĘŚCIOWA WPŁATA: zapłacono %.2f PLN z %.2f PLN (%.0f%%). Korekta tylko od niezaplaconej części: %.2f PLN.", [paid_amount, total_amount, paid_pct, unpaid_portion])]
} {
    input.invoice.days_overdue >= 90
    total_amount := object.get(input.invoice, "amount_net", 0)
    paid_amount := object.get(input.invoice, "amount_paid", 0)
    total_amount > 0
    paid_amount > 0
    paid_amount < total_amount
    unpaid_portion := total_amount - paid_amount
    paid_pct := paid_amount / total_amount * 100
}

# R0610: bad_debt_restructuring_vs_bankruptcy — Restrukturyzacja vs upadłość
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.bad_debt_restructuring_vs_bankruptcy",
    "package": "jdg.conflicts",
    "priority": 610,
    "cross_domain_conflict": true,
    "conflict_domains": ["vat", "pit"],
    "conflict_severity": "WARNING",
    "conflict_resolution": "CHECK_RESTRUCTURING_EXCEPTION",
    "conflict_message": "Dłużnik w restrukturyzacji — ulga na złe długi może być wyłączona",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Złe długi — dłużnik w restrukturyzacji/upadłości",
    "_legal_basis": "Art. 89a ust. 2 pkt 3 VAT, Art. 26i ust. 4 PIT",
    "_warnings": [sprintf("RESTRUKTURYZACJA/UPADŁOŚĆ: dłużnik '%s' w trakcie %s. Ulga na złe długi może być wyłączona. Sprawdź stan postępowania.", [debtor_name, proceeding_type])]
} {
    input.invoice.days_overdue >= 90
    debtor_name := object.get(input.invoice, "debtor_name", "")
    proceeding_type := object.get(input.invoice, "insolvency_proceeding", "")
    proceeding_type in {"RESTRUCTURING", "BANKRUPTCY", "LIQUIDATION"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# P904: allowances_vs_loss — Ulgi nie mogą być odliczane przy stracie (Doc 36)
# ═══════════════════════════════════════════════════════════════════════════════

# P904: allowances_vs_loss — Strata blokuje ulgi osobiste (poza B+R carry-forward)
allowance_claimed(profile) {
    object.get(profile, "relief_donation_total", 0) > 0
}

allowance_claimed(profile) {
    object.get(profile, "relief_rehabilitation_total", 0) > 0
}

allowance_claimed(profile) {
    object.get(profile, "relief_internet_total", 0) > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.conflicts.allowances_vs_loss",
    "package": "jdg.conflicts",
    "priority": 904,
    "cross_domain_conflict": true,
    "conflict_domains": ["allowances", "pit"],
    "conflict_severity": "HIGH",
    "conflict_resolution": "BLOCK_NON_RD_ALLOWANCES",
    "conflict_message": "JDG wykazuje stratę — ulgi osobiste nie mogą być odliczane (wyjątek: B+R carry-forward 6 lat)",
    "annual_income": annual_income,
    "non_rd_allowances_claimed": true,
    "rd_carry_forward_allowed": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Strata JDG — ulgi osobiste zablokowane",
    "_legal_basis": "Art. 26 ust. 1 PIT, Art. 26e ust. 8 PIT",
    "_warnings": [sprintf("STRATA %.2f PLN — ulgi osobiste NIE mogą być odliczane! Wyjątek: ulga B+R (carry-forward 6 lat).", [annual_loss])]
} {
    profile := object.get(input, "jdg_entrepreneur", {})
    annual_income := object.get(profile, "annual_income", 0)
    annual_income <= 0
    annual_loss := 0 - annual_income
    allowance_claimed(profile)
}

# ═══════════════════════════════════════════════════════════════════════════════
# R0611-R0612: Konflikty pozostałe — Amortyzacja, Kursy FX
# ═══════════════════════════════════════════════════════════════════════════════

# R0611: depreciation_method_conflict_vat_vs_pit — Metoda amortyzacji konflikt
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.depreciation_method_conflict_vat_vs_pit",
    "package": "jdg.conflicts",
    "priority": 611,
    "cross_domain_conflict": true,
    "conflict_domains": ["pit", "accounting"],
    "conflict_severity": "HIGH",
    "conflict_resolution": "PREFER_PIT_DEPRECIATION_RULES",
    "conflict_message": "Konflikt metody amortyzacji — PIT (liniowa/jednorazowa) vs księgi (UoR)",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Rozbieżność amortyzacji PIT vs UoR — może wymagać odrębnej ewidencji",
    "_legal_basis": "Art. 22a-22o PIT, Art. 28-34 UoR",
    "_warnings": [sprintf("AMORTYZACJA KONFLIKT: PIT=%s (%.2f%%), UoR=%s (%.2f%%). Możliwa rozbieżność — prowadź odrębną ewidencję podatkową i bilansową.", [pit_method, pit_rate, uor_method, uor_rate])]
} {
    input.invoice.expense_type == "FIXED_ASSET"
    pit_method := object.get(input.invoice, "depreciation_method", "")
    uor_method := object.get(input.invoice, "uor_depreciation_method", "")
    pit_rate := object.get(input.invoice, "depreciation_rate", 0)
    uor_rate := object.get(input.invoice, "uor_depreciation_rate", 0)
    uor_method != ""
    uor_method != pit_method
}

# R0612: fx_rate_source_conflict_nbp_a_vs_c — Konflikt kursu NBP A vs C
else := {
    "matched": true,
    "rule_id": "jdg.conflicts.fx_rate_source_conflict_nbp_a_vs_c",
    "package": "jdg.conflicts",
    "priority": 612,
    "cross_domain_conflict": true,
    "conflict_domains": ["accounting", "vat"],
    "conflict_severity": "WARNING",
    "conflict_resolution": "PREFER_CUSTOMS_TABLE_C_FOR_IMPORT",
    "conflict_message": "Transakcja walutowa z importem — Tabela A vs C NBP (różne kursy)",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14c PIT, Art. 30a-c VAT, Tabela C NBP dla ceł",
    "_warnings": [sprintf("KURS NBP KONFLIKT: transakcja %s — Tabela A=%.4f, Tabela C=%.4f PLN/%s. Import/eksport: użyj Tabeli C (celnej).", [currency, rate_a, rate_c, currency])]
} {
    input.invoice.currency != "PLN"
    currency := input.invoice.currency
    input.invoice.is_customs_transaction == true
    rate_a := object.get(input.invoice, "fx_rate_nbp_a", 0)
    rate_c := object.get(input.invoice, "fx_rate_nbp_c", 0)
    rate_a > 0
    rate_c > 0
    rate_a != rate_c
}

# ═══════════════════════════════════════════════════════════════════════════════
# Helpers: Cross-domain conflict severity by domain pair
# ═══════════════════════════════════════════════════════════════════════════════

# Helper: liczy liczbę konfliktów dla pary domen
conflict_count_by_domain(domain_a, domain_b) = cnt {
    conflicts := [c |
        c := input._cross_domain_conflicts[_]
        c.domains == [domain_a, domain_b]
    ]
    cnt := count(conflicts)
} else = 0 {
    true
}
