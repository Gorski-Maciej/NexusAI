# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P18 GENIALNE POMYSŁY ENTERPRISE (AUTOMATYZACJA KSIĘGOWOŚCI)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p18_automatyzacja_ksiegowosci_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG AUTOMATYZACJA KSIĘGOWOŚCI (P18) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: AUDYT BANKOWOŚCI (PSD2/PolishAPI) — AIS/PIS, OAuth2/eIDAS,
#             Elixir/ExpressElixir (cutoff 14:30/15:30), batch XML/JSON,
#             auto-księgowanie wyciągów, auto-oznaczanie płatności,
#             monitor PSD2, rozliczanie przelewów do deklaracji
#   Sekcja 2: AUDYT e-DORĘCZEŃ I e-PODPISU (PRIORYTET ★) — adres do
#             doręczeń, skrzynki, auto-podpis, "jedno kliknięcie" —
#             pełny obieg pisma z urzędem
#   Sekcja 3: AUDYT FORMULARZY I DEKLARACJI — auto-generacja PIT-36/36L/28,
#             VAT-7, JPK, ZUS DRA/RCA/RZA, PCC-3 — silnik auto-fill
#   Sekcja 4: AUDYT KALENDARZA I TERMINÓW — terminy ZUS/VAT/PIT/JPK/KSeF,
#             tracker z alertami, auto-przypomnienia, priorytetyzacja,
#             "nieśmiertelny kalendarz podatnika"
#   Sekcja 5: AUDYT KORESPONDENCJI I PRZEPŁYWÓW — tax_correspondence_engine,
#             cashflow predictors, overpayment_auto_claimer
#   Sekcja 6: OPA JAKO ROZBUDOWANY SYSTEM — pipeline auto-adaptacji
#             integracji (zmiany API banków i urzędów)
#   Sekcja 7: 15 genialnych pomysłów Enterprise (INN-01..INN-15)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R18)
#
# Zgodność: PSD2 (2015/2366), PolishAPI, eIDAS (910/2014), ustawa o
#           doręczeniach elektronicznych, ustawa o informatyzacji,
#           Ordynacja podatkowa (terminy, odsetki), ADR-002 (progi z
#           data.jdg.thresholds).
# package: jdg.p18_automatyzacja_ksiegowosci_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p18_automatyzacja_ksiegowosci_innovations

import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.no_match", "package": "jdg.p18_automatyzacja_ksiegowosci_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
accounting_limits := object.get(thresholds, "automatyzacja_ksiegowosci", {
    "elixir_cutoff_time": "14:30",              # Elixir — zlecenia do 14:30
    "express_elixir_cutoff_time": "15:30",      # Express Elixir — do 15:30 (usługa dodatkowa)
    "sca_exempt_threshold_pln": 100,            # PSD2 SCA — zwolnienie do 100 zł (RTS 2018/389)
    "sca_exempt_max_per_tx": 5,                 # max 5 transakcji SCA-exempt między uwierzytelnieniami
    "mpp_threshold_pln": 15000,                 # mechanizm podzielonej płatności — 15 000 zł
    "vat7_deadline_day": 25,                    # VAT-7 — do 25. dnia miesiąca
    "zus_dra_deadline_day": 10,                 # ZUS DRA — do 10. dnia miesiąca
    "pit_deadline_annual": "2026-04-30",        # PIT-36/36L/28 — do 30 kwietnia
    "pcc3_deadline_days": 14,                   # PCC-3 — 14 dni od czynności
    "wis_response_days": 3,                     # WIS — odpowiedź do 3 miesięcy
    "overpayment_interest_days": 30,            # nadpłata — odsetki po 30 dniach
    "transfer_reconciliation_gap_pln": 0.01,    # tolerancja koncyliacji bank
    "jpk_v7_deadline_day": 25,                  # JPK_V7 — do 25. dnia miesiąca
})

elixir_cutoff := object.get(accounting_limits, "elixir_cutoff_time", "14:30")
express_elixir_cutoff := object.get(accounting_limits, "express_elixir_cutoff_time", "15:30")
sca_exempt_threshold_pln := to_number(object.get(accounting_limits, "sca_exempt_threshold_pln", 100))
sca_exempt_max_per_tx := to_number(object.get(accounting_limits, "sca_exempt_max_per_tx", 5))
mpp_threshold_pln := to_number(object.get(accounting_limits, "mpp_threshold_pln", 15000))
vat7_deadline_day := to_number(object.get(accounting_limits, "vat7_deadline_day", 25))
zus_dra_deadline_day := to_number(object.get(accounting_limits, "zus_dra_deadline_day", 10))
pcc3_deadline_days := to_number(object.get(accounting_limits, "pcc3_deadline_days", 14))
wis_response_days := to_number(object.get(accounting_limits, "wis_response_days", 3))
jpk_v7_deadline_day := to_number(object.get(accounting_limits, "jpk_v7_deadline_day", 25))
recon_gap_pln := to_number(object.get(accounting_limits, "transfer_reconciliation_gap_pln", 0.01))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── Funkcje pomocnicze (else-chain — deterministyczne, zero konfliktów) ────────
sca_required(amount_pln, tx_count_since_auth) = "SCA WYMAGANE — kwota > 100 zł (RTS 2018/389)" { amount_pln > sca_exempt_threshold_pln }
else = "SCA EXEMPT — kwota ≤ 100 zł" { tx_count_since_auth < sca_exempt_max_per_tx }
else = "SCA WYMAGANE — limit 5 transakcji exempt wyczerpany" { true }

mpp_required(amount_pln) = "MPP ZALECANE — mechanizm podzielonej płatności (≥15 000 zł)" { amount_pln >= mpp_threshold_pln }
else = "MPP FAKULTATYWNE — poniżej progu 15 000 zł" { true }

psd2_monitor_routing(breaches) = "BLOCK_AND_ALERT" { count(breaches) > 0 }
else = "OK" { true }

edelivery_status(address_set, mailbox_active) = "PEŁNY OBIEG — adres + skrzynka aktywna (jedno kliknięcie)" { address_set == true; mailbox_active == true }
else = "ADRES USTAWIONY — AKTYWUJ SKRZYNKĘ e-DORĘCZEŃ" { address_set == true }
else = "BRAK ADRESU DO DORĘCZEŃ — obieg niepełny" { true }

edelivery_routing(address_set, mailbox_active) = "TRIAGE_QUEUE" { address_set == false or mailbox_active == false }
else = "" { true }

form_status(filled_fields, required_fields) = "AUTO-FILL KOMPLETNY — gotowy do podpisu i wysyłki" { count(filled_fields) >= count(required_fields) }
else = "AUTO-FILL NIEPEŁNY — uzupełnij " + sprintf("%d pól", [count(required_fields) - count(filled_fields)]) { true }

form_routing(filled_fields, required_fields) = "TRIAGE_QUEUE" { count(filled_fields) < count(required_fields) }
else = "" { true }

deadline_status(day_of_month, deadline_day) = "PRZED TERMINEM — " + sprintf("%d dni zapasu", [deadline_day - day_of_month]) { day_of_month < deadline_day }
else = "DZIŚ TERMIN — złóż deklarację!" { day_of_month == deadline_day }
else = "PO TERMINIE — naliczane odsetki!" { true }

reconciliation_status(matched_pln, bank_pln, gap_pln) = "ZGODNE — różnica ≤ " + sprintf("%.2f zł", [gap_pln]) { abs(matched_pln - bank_pln) <= gap_pln }
else = "ROZBIEŻNOŚĆ — różnica " + sprintf("%.2f zł", [abs(matched_pln - bank_pln)]) { true }

reconciliation_routing(matched_pln, bank_pln, gap_pln) = "TRIAGE_QUEUE" { abs(matched_pln - bank_pln) > gap_pln }
else = "" { true }

overpayment_status(days_after_declaration) = "NADPŁATA — złóż wniosek o zwrot (odsetki po " + sprintf("%d dniach", [to_number(object.get(accounting_limits, "overpayment_interest_days", 30))]) + ")" { days_after_declaration >= 0 }
else = "" { true }

api_adaptation_status(api_version, supported_versions) = "ZGODNY — API " + api_version + " obsługiwane" { api_version in supported_versions }
else = "WYMAGA ADAPTACJI — API " + api_version + " poza wsparciem" { true }

priority_label(urgent_count, today_deadlines) = "KRYTYCZNE — " + sprintf("%d terminów DZIŚ", [count(today_deadlines)]) { count(today_deadlines) > 0 }
else = "UWAGA — " + sprintf("%d terminów w ciągu 3 dni", [urgent_count]) { urgent_count > 0 }
else = "BEZ TERMINÓW PILNYCH" { true }

booking_routing(auto_booked) = "TRIAGE_QUEUE" { auto_booked == 0 }
else = "" { true }

settlement_routing(consistent) = "TRIAGE_QUEUE" { consistent == false }
else = "" { true }

urgent_routing(today_count) = "URGENT" { today_count > 0 }
else = "OK" { true }

negative_routing(balance_pln) = "TRIAGE_QUEUE" { balance_pln < 0 }
else = "" { true }

overpayment_routing(amount_pln) = "TRIAGE_QUEUE" { amount_pln > 0 }
else = "" { true }

payment_category(purpose) = "VAT" { contains(purpose, "VAT") }
else = "VAT" { contains(purpose, "podatek") }
else = "ZUS" { contains(purpose, "ZUS") }
else = "PIT" { contains(purpose, "PIT") }
else = "PCC" { contains(purpose, "PCC") }
else = "KOSZT" { true }

# ── SEKCJA 1: MAPA POKRYCIA MODUŁÓW (Automatyzacja księgowości) ────────────────
# Status COMPLETE/PARTIAL/MISSING z data.jdg.p18_audit (automatyzacja_ksiegowosci_auditor.py).
p18_priority_modules := ["banking", "edelivery", "esig", "wis", "forms", "calendar", "cashflow"]

p18_audit_data := object.get(data.jdg, "p18_audit", {})
p18_coverage_modules := object.get(p18_audit_data, "modules", {})

automatyzacja_coverage_report := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.automatyzacja_coverage_report",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3210,
    "matched": true,
    "modules": {mod: {
        "status": object.get(object.get(p18_coverage_modules, mod, {}), "status", "MISSING"),
        "rules": object.get(object.get(p18_coverage_modules, mod, {}), "rules", 0),
    } | mod := p18_priority_modules[_]},
    "summary": {
        "total": count(p18_priority_modules),
        "complete": count([m | m := p18_priority_modules[_]; object.get(object.get(p18_coverage_modules, m, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([m | m := p18_priority_modules[_]; object.get(object.get(p18_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([m | m := p18_priority_modules[_]; object.get(object.get(p18_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]) / count(p18_priority_modules) * 100),
    "micro_total_rule_ids": object.get(p18_audit_data, "total_rule_ids", 0),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia modułów automatyzacji księgowości — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "ADR-002 (progi z data.jdg.thresholds)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# ── SEKCJA 1: AUDYT BANKOWOŚCI (PSD2/PolishAPI — POZIOM ENTERPRISE) ────────────
banking_audit := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.banking_audit",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3220,
    "matched": true,
    "psd2": {
        "podstawa": "PSD2 (2015/2366/UE) + RTS 2018/389 — SCA, AIS/PIS",
        "sca_exempt_threshold_pln": sca_exempt_threshold_pln,
        "sca_exempt_max_per_tx": sca_exempt_max_per_tx,
        "legal_basis": "PSD2 art. 97; RTS 2018/389 art. 11-12",
    },
    "polish_api": {
        "standard": "PolishAPI — krajowy standard API bankowego (AIS/PIS, OAuth2)",
        "oauth2": true,
        "eidas": "eIDAS — uwierzytelnianie transgraniczne (910/2014)",
        "legal_basis": "PolishAPI v1.0+; eIDAS",
    },
    "elixir": {
        "cutoff": elixir_cutoff,
        "express_elixir_cutoff": express_elixir_cutoff,
        "batch": "batch XML/JSON — eksport/import zleceń",
        "legal_basis": "Regulamin KIR (Elixir/Express Elixir)",
    },
    "auto_ksiegowanie": {
        "wyciagi": "auto-księgowanie wyciągów bankowych — dokument → dane → księgowanie",
        "oznaczanie": "auto-oznaczanie płatności (VAT, ZUS, PIT, PCC)",
        "rozliczanie": "rozliczanie przelewów do deklaracji (VAT-7, ZUS DRA)",
    },
    "integrated_packages": ["jdg.banking_automation (15)", "jdg.payments (plan44: 10 + plan45: 51)", "jdg.vat_mpp_split_payment (5)"],
    "_routing": "",
    "_routing_reason": "Audyt bankowości — PSD2/PolishAPI, AIS/PIS, OAuth2/eIDAS, Elixir/ExpressElixir, batch, auto-księgowanie",
    "_legal_basis": "PSD2 (2015/2366); RTS 2018/389; PolishAPI; eIDAS (910/2014)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-01: AUTO-KSIĘGOWANIE WYCIĄGÓW BANKOWYCH (Sekcja 1 — PRIORYTET).
bank_statement_auto_booking := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.bank_statement_auto_booking",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3221,
    "matched": true,
    "transactions": to_number(object.get(input.banking, "statement_transactions", 0)),
    "auto_booked": auto_booked,
    "unmatched": to_number(object.get(input.banking, "statement_transactions", 0)) - auto_booked,
    "note": "auto-księgowanie wyciągów bankowych — transakcje → rejestry PKPiR/UoR bez udziału człowieka",
    "_routing": booking_routing(auto_booked),
    "_routing_reason": sprintf("Auto-księgowanie wyciągu: %d transakcji, %d zaksięgowanych", [to_number(object.get(input.banking, "statement_transactions", 0)), auto_booked]),
    "_legal_basis": "Art. 24a u.PIT (PKPiR); UoR art. 15",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
    auto_booked := to_number(object.get(input.banking, "auto_booked_count", 0))
    auto_booked <= to_number(object.get(input.banking, "statement_transactions", 0))
}

# INN-02: AUTO-OZNACZANIE PŁATNOŚCI.
payment_auto_tagging := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.payment_auto_tagging",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3222,
    "matched": true,
    "payment_purpose": object.get(input.banking, "payment_purpose", ""),
    "assigned_category": category,
    "note": "auto-oznaczanie płatności — mapowanie tytułu przelewu na kategorie (VAT, ZUS, PIT, PCC, koszt)",
    "_routing": "",
    "_routing_reason": sprintf("Auto-oznaczanie płatności: %s → %s", [object.get(input.banking, "payment_purpose", ""), category]),
    "_legal_basis": "Art. 24a u.PIT; praktyka księgowa",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
    category := payment_category(object.get(input.banking, "payment_purpose", ""))
}

# INN-03: MONITOR PSD2 — SCA, limity, ekspozycje.
psd2_monitor := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.psd2_monitor",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3223,
    "matched": true,
    "sca_exempt_threshold_pln": sca_exempt_threshold_pln,
    "sca_exempt_max_per_tx": sca_exempt_max_per_tx,
    "tx_count_since_auth": to_number(object.get(input.banking, "tx_count_since_auth", 0)),
    "sca_decision": sca_required(to_number(object.get(input.banking, "payment_amount_pln", 0)), to_number(object.get(input.banking, "tx_count_since_auth", 0))),
    "breaches": breaches,
    "note": "monitor PSD2 — kontrola SCA (RTS 2018/389), limity exempt, naruszenia",
    "_routing": psd2_monitor_routing(breaches),
    "_routing_reason": sprintf("Monitor PSD2: %d naruszeń SCA, decyzja: %s", [count(breaches), sca_required(to_number(object.get(input.banking, "payment_amount_pln", 0)), to_number(object.get(input.banking, "tx_count_since_auth", 0)))]),
    "_legal_basis": "PSD2 art. 97; RTS 2018/389 art. 11-12",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
    breaches := [b | b := ["SCA limit przekroczony", "transakcje bez zgody PIS", "session timeout"][_]; object.get(input.banking, "breach_" + b, false) == true]
    count(breaches) >= 0
}

# INN-04: ROZLICZANIE PRZELEWÓW DO DEKLARACJI.
transfer_to_declaration_settlement := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.transfer_to_declaration_settlement",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3224,
    "matched": true,
    "transfers": to_number(object.get(input.banking, "tax_transfers", 0)),
    "settled_to_declarations": to_number(object.get(input.banking, "settled_transfers", 0)),
    "reconciliation_gap_pln": recon_gap_pln,
    "consistent": to_number(object.get(input.banking, "tax_transfers", 0)) == to_number(object.get(input.banking, "settled_transfers", 0)),
    "note": "rozliczanie przelewów do deklaracji — powiązanie płatności (VAT, ZUS, PIT) z pozycjami deklaracji",
    "_routing": settlement_routing(to_number(object.get(input.banking, "tax_transfers", 0)) == to_number(object.get(input.banking, "settled_transfers", 0))),
    "_routing_reason": sprintf("Rozliczanie przelewów do deklaracji: %d/%d rozliczone", [to_number(object.get(input.banking, "settled_transfers", 0)), to_number(object.get(input.banking, "tax_transfers", 0))]),
    "_legal_basis": "Art. 62-63 OrdPU (zapłata podatku); art. 108a VAT (MPP)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# ── SEKCJA 2: AUDYT e-DORĘCZEŃ I e-PODPISU (POZIOM ENTERPRISE — PRIORYTET ★) ──
edelivery_esig_audit := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.edelivery_esig_audit",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3230,
    "matched": true,
    "e_doreczenia": {
        "obowiązek": "adres do doręczeń + skrzynka e-Doręczeń (2026)",
        "status": edelivery_status(object.get(input.jdg_entrepreneur, "edelivery_address_set", false), object.get(input.jdg_entrepreneur, "edelivery_mailbox_active", false)),
        "legal_basis": "Ustawa o doręczeniach elektronicznych",
    },
    "e_podpis": {
        "kwalifikowany": true,
        "zaufany": true,
        "auto_aplikacja": "auto-podpis na pismach do urzędów (ePUAP, e-Doręczenia)",
        "legal_basis": "eIDAS (910/2014); ustawa o informatyzacji",
    },
    "jedno_klikniecie": {
        "obieg": "PEŁNY OBIEG PISMA — dokument → auto-fill → auto-podpis → auto-wysyłka do urzędu",
        "urzady": ["US (VAT-7, PIT, PCC-3)", "ZUS (DRA, RCA, RZA)", "e-Urząd Skarbowy", "KSeF"],
        "legal_basis": "Ustawa o doręczeniach elektronicznych; ePUAP",
    },
    "integrated_packages": ["jdg.edelivery (plan44: 9 + plan45: 42)", "jdg.esig (plan44: 8 + plan45: 37)", "jdg.esig_auto_applicator (5)", "jdg.epuap (4)", "jdg.edelivery_gateway (4+2)"],
    "_routing": edelivery_routing(object.get(input.jdg_entrepreneur, "edelivery_address_set", false), object.get(input.jdg_entrepreneur, "edelivery_mailbox_active", false)),
    "_routing_reason": "Audyt e-Doręczeń i e-podpisu — adres, skrzynki, auto-podpis, jedno kliknięcie obiegu pisma (priorytet)",
    "_legal_basis": "Ustawa o doręczeniach elektronicznych; eIDAS; ustawa o informatyzacji",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-05: "JEDNO KLIKNIĘCIE" — PEŁNY OBIEG PISMA Z URZĘDEM.
one_click_letter_flow := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.one_click_letter_flow",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3231,
    "matched": true,
    "flow_steps": ["1. dokument (faktura/decyzja) → dane", "2. auto-fill formularza", "3. auto-podpis (eIDAS)", "4. auto-wysyłka do urzędu (e-Doręczenia/ePUAP)", "5. potwierdzenie doręczenia + archiwizacja"],
    "fully_automated": object.get(input.jdg_entrepreneur, "edelivery_address_set", false) == true and object.get(input.jdg_entrepreneur, "edelivery_mailbox_active", false) == true,
    "note": "'jedno kliknięcie' — pełny obieg pisma z urzędem bez udziału człowieka (e-Doręczenia + e-podpis)",
    "_routing": "",
    "_routing_reason": sprintf("Jedno kliknięcie: pełna automatyzacja = %v", [object.get(input.jdg_entrepreneur, "edelivery_address_set", false) == true and object.get(input.jdg_entrepreneur, "edelivery_mailbox_active", false) == true]),
    "_legal_basis": "Ustawa o doręczeniach elektronicznych; eIDAS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# ── SEKCJA 3: AUDYT FORMULARZY I DEKLARACJI (POZIOM ENTERPRISE) ────────────────
forms_declarations_audit := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.forms_declarations_audit",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3240,
    "matched": true,
    "formularze": {
        "PIT-36/36L/28": "auto-generacja z rejestrów PKPiR/UoR (do 30 kwietnia)",
        "VAT-7": "auto-generacja z rejestrów VAT (do 25. dnia)",
        "JPK_V7M/V7K": "auto-generacja z rejestrów (do 25. dnia)",
        "ZUS DRA/RCA/RZA": "auto-generacja z list płac i składek (do 10. dnia)",
        "PCC-3": "auto-generacja (14 dni od czynności)",
        "legal_basis": "Art. 45 u.PIT; art. 99 VAT; art. 47 u.ZUS; art. 10 u.PCC",
    },
    "auto_fill": {
        "silnik": "auto-fill formularzy z danych księgowych (rejestry, wyciągi, faktury)",
        "zrodla": ["PKPiR/UoR", "rejestry VAT", "wyciągi bankowe", "faktury KSeF", "listy płac"],
        "legal_basis": "ADR-002",
    },
    "integrated_packages": ["jdg.form_optimizer (6)", "jdg.p16_autoform_generator (8)", "jdg.p16_enhanced_sca (4)", "jdg.accounting (plan42_pkpir + pkpir_enterprise_live)"],
    "_routing": "",
    "_routing_reason": "Audyt formularzy i deklaracji — PIT-36/36L/28, VAT-7, JPK, ZUS DRA/RCA/RZA, PCC-3, silnik auto-fill",
    "_legal_basis": "Art. 45 u.PIT; art. 99 VAT; art. 47 u.ZUS; art. 10 u.PCC",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-06: SILNIK AUTO-FILL FORMULARZY Z DANYCH KSIĘGOWYCH.
form_autofill_engine := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.form_autofill_engine",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3241,
    "matched": true,
    "form_type": object.get(input.forms, "form_type", "VAT-7"),
    "required_fields": required,
    "filled_fields": filled,
    "fill_status": form_status(filled, required),
    "ready_to_send": count(filled) >= count(required),
    "note": "silnik auto-fill formularzy — automatyczne wypełnianie PIT/VAT/JPK/ZUS/PCC z danych księgowych",
    "_routing": form_routing(filled, required),
    "_routing_reason": sprintf("Auto-fill %s: %d/%d pól wypełnionych", [object.get(input.forms, "form_type", "VAT-7"), count(filled), count(required)]),
    "_legal_basis": "Art. 45 u.PIT; art. 99 VAT; art. 47 u.ZUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
    required := object.get(input.forms, "required_fields", ["P_1", "P_2", "P_3"])
    filled := object.get(input.forms, "filled_fields", required)
}

# ── SEKCJA 4: AUDYT KALENDARZA I TERMINÓW (POZIOM ENTERPRISE) ─────────────────
calendar_deadlines_audit := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.calendar_deadlines_audit",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3250,
    "matched": true,
    "terminy": {
        "ZUS DRA": "do " + sprintf("%d.", [zus_dra_deadline_day]) + " dnia miesiąca (art. 47 u.ZUS)",
        "VAT-7": "do " + sprintf("%d.", [vat7_deadline_day]) + " dnia miesiąca (art. 99 VAT)",
        "JPK_V7": "do " + sprintf("%d.", [jpk_v7_deadline_day]) + " dnia miesiąca (art. 82 VAT)",
        "PIT-36/36L/28": "do 30 kwietnia (art. 45 u.PIT)",
        "PCC-3": "14 dni od czynności (art. 10 u.PCC)",
        "KSeF": "faktury od 2026-02-01 (art. 106na VAT)",
        "legal_basis": "Art. 47 u.ZUS; art. 99 VAT; art. 82 VAT; art. 45 u.PIT; art. 10 u.PCC",
    },
    "tracker": {
        "alerty": "auto-przypomnienia o terminach (T-7, T-3, T-0)",
        "priorytetyzacja": "KRYTYCZNE (dziś) / UWAGA (3 dni) / OK",
        "legal_basis": "Art. 47 u.ZUS; art. 99 VAT",
    },
    "integrated_packages": ["jdg.calendar (plan44: 7 + plan45: 36)", "jdg.calendar_notifier (0)", "jdg.deadline_monitor (3)", "jdg.hyper.deadlines (plan45)"],
    "_routing": "",
    "_routing_reason": "Audyt kalendarza i terminów — ZUS/VAT/PIT/JPK/KSeF, tracker z alertami, priorytetyzacja",
    "_legal_basis": "Art. 47 u.ZUS; art. 99 VAT; art. 82 VAT; art. 45 u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-07: "NIEŚMIERTELNY KALENDARZ PODATNIKA" — tracker z alertami.
immortal_tax_calendar := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.immortal_tax_calendar",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3251,
    "matched": true,
    "today_day": to_number(object.get(input.calendar, "day_of_month", 1)),
    "zus_dra": deadline_status(to_number(object.get(input.calendar, "day_of_month", 1)), zus_dra_deadline_day),
    "vat7": deadline_status(to_number(object.get(input.calendar, "day_of_month", 1)), vat7_deadline_day),
    "jpk_v7": deadline_status(to_number(object.get(input.calendar, "day_of_month", 1)), jpk_v7_deadline_day),
    "alert_level": priority_label(to_number(object.get(input.calendar, "urgent_count", 0)), object.get(input.calendar, "today_deadlines", [])),
    "note": "'nieśmiertelny kalendarz podatnika' — tracker terminów ZUS/VAT/PIT/JPK z alertami T-7/T-3/T-0",
    "_routing": "",
    "_routing_reason": "Nieśmiertelny kalendarz podatnika — terminy ZUS/VAT/PIT/JPK/KSeF (INN-07)",
    "_legal_basis": "Art. 47 u.ZUS; art. 99 VAT; art. 82 VAT; art. 45 u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-08: TRACKER TERMINÓW Z ALERTAMI (priorytetyzacja).
deadline_alert_tracker := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.deadline_alert_tracker",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3252,
    "matched": true,
    "deadlines_today": object.get(input.calendar, "today_deadlines", []),
    "deadlines_3_days": to_number(object.get(input.calendar, "urgent_count", 0)),
    "alert_level": priority_label(to_number(object.get(input.calendar, "urgent_count", 0)), object.get(input.calendar, "today_deadlines", [])),
    "note": "tracker terminów z alertami — auto-przypomnienia T-7/T-3/T-0, priorytetyzacja KRYTYCZNE/UWAGA",
    "_routing": urgent_routing(count(object.get(input.calendar, "today_deadlines", []))),
    "_routing_reason": sprintf("Tracker terminów: %d dziś, %d w 3 dni", [count(object.get(input.calendar, "today_deadlines", [])), to_number(object.get(input.calendar, "urgent_count", 0))]),
    "_legal_basis": "Art. 47 u.ZUS; art. 99 VAT; art. 45 u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# ── SEKCJA 5: AUDYT KORESPONDENCJI I PRZEPŁYWÓW (POZIOM ENTERPRISE) ────────────
correspondence_cashflow_audit := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.correspondence_cashflow_audit",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3260,
    "matched": true,
    "korespondencja": {
        "silnik": "tax_correspondence_engine — auto-generator pism do US (wezwania, zażalenia, wnioski)",
        "komponenty": ["decision_composer (3)", "proceeding_tracker (3)", "interest_calculator (4)"],
        "legal_basis": "OrdPU art. 120-129 (korespondencja)",
    },
    "przeplywy": {
        "cashflow_tax_predictor": "predykcja przepływów podatkowych (7 reguł)",
        "vat_cashflow_predictor": "predykcja VAT cashflow (5 reguł)",
        "nadplata": "overpayment_auto_claimer — auto-wnioskowanie o zwrot nadpłat (3 reguły)",
        "legal_basis": "Art. 74-80 OrdPU (nadpłaty)",
    },
    "integrated_packages": ["jdg.tax_correspondence_engine (0)", "jdg.cashflow_tax_predictor (7)", "jdg.vat_cashflow_predictor (5)", "jdg.overpayment_auto_claimer (3)", "jdg.interest_calculator (4)", "jdg.proceeding_tracker (3)"],
    "_routing": "",
    "_routing_reason": "Audyt korespondencji i przepływów — pisma do US, cashflow predictors, overpayment_auto_claimer",
    "_legal_basis": "OrdPU art. 74-80 (nadpłaty), art. 120-129 (korespondencja)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-09: AUTO-KONCYLIACJA BANK (wyciągi vs rejestry).
bank_reconciliation_engine := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.bank_reconciliation_engine",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3261,
    "matched": true,
    "bank_balance_pln": to_number(object.get(input.banking, "bank_balance_pln", 0)),
    "register_balance_pln": to_number(object.get(input.banking, "register_balance_pln", 0)),
    "gap_pln": round2(abs(to_number(object.get(input.banking, "bank_balance_pln", 0)) - to_number(object.get(input.banking, "register_balance_pln", 0)))),
    "recon_status": reconciliation_status(to_number(object.get(input.banking, "register_balance_pln", 0)), to_number(object.get(input.banking, "bank_balance_pln", 0)), recon_gap_pln),
    "note": "auto-koncyliacja bank — automatyczne porównanie wyciągów bankowych z rejestrami księgowymi",
    "_routing": reconciliation_routing(to_number(object.get(input.banking, "register_balance_pln", 0)), to_number(object.get(input.banking, "bank_balance_pln", 0)), recon_gap_pln),
    "_routing_reason": sprintf("Auto-koncyliacja: bank %.2f vs rejestry %.2f (gap %.2f)", [to_number(object.get(input.banking, "bank_balance_pln", 0)), to_number(object.get(input.banking, "register_balance_pln", 0)), round2(abs(to_number(object.get(input.banking, "bank_balance_pln", 0)) - to_number(object.get(input.banking, "register_balance_pln", 0))))]),
    "_legal_basis": "Art. 24a u.PIT (PKPiR); UoR art. 15",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-10: PREDYKCJA PRZEPŁYWÓW (CASHFLOW + VAT).
cashflow_forecaster := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.cashflow_forecaster",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3262,
    "matched": true,
    "inflows_pln": to_number(object.get(input.cashflow, "inflows_pln", 0)),
    "outflows_pln": to_number(object.get(input.cashflow, "outflows_pln", 0)),
    "tax_liabilities_pln": to_number(object.get(input.cashflow, "tax_liabilities_pln", 0)),
    "projected_balance_pln": round2(to_number(object.get(input.cashflow, "inflows_pln", 0)) - to_number(object.get(input.cashflow, "outflows_pln", 0)) - to_number(object.get(input.cashflow, "tax_liabilities_pln", 0))),
    "note": "predykcja przepływów — cashflow + VAT predictor, projekcja salda z uwzględnieniem zobowiązań podatkowych",
    "_routing": negative_routing(to_number(object.get(input.cashflow, "inflows_pln", 0)) - to_number(object.get(input.cashflow, "outflows_pln", 0)) - to_number(object.get(input.cashflow, "tax_liabilities_pln", 0))),
    "_routing_reason": sprintf("Predykcja przepływów: saldo projekcji %.2f PLN", [round2(to_number(object.get(input.cashflow, "inflows_pln", 0)) - to_number(object.get(input.cashflow, "outflows_pln", 0)) - to_number(object.get(input.cashflow, "tax_liabilities_pln", 0)))]),
    "_legal_basis": "OrdPU; u.PIT; VAT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-11: AUTO-WNIOSKOWANIE O NADPŁATĘ.
overpayment_auto_claimer := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.overpayment_auto_claimer",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3263,
    "matched": true,
    "overpayment_pln": to_number(object.get(input.overpayment, "overpayment_pln", 0)),
    "days_after_declaration": to_number(object.get(input.overpayment, "days_after_declaration", 0)),
    "status": overpayment_status(to_number(object.get(input.overpayment, "days_after_declaration", 0))),
    "auto_claim": to_number(object.get(input.overpayment, "overpayment_pln", 0)) > 0 and to_number(object.get(input.overpayment, "days_after_declaration", 0)) >= 0,
    "note": "auto-wnioskowanie o zwrot nadpłat — wykrywanie nadpłaty, wniosek do US (art. 74-80 OrdPU)",
    "_routing": overpayment_routing(to_number(object.get(input.overpayment, "overpayment_pln", 0))),
    "_routing_reason": sprintf("Auto-wnioskowanie o nadpłatę: %.2f PLN, %d dni po deklaracji", [to_number(object.get(input.overpayment, "overpayment_pln", 0)), to_number(object.get(input.overpayment, "days_after_declaration", 0))]),
    "_legal_basis": "Art. 74-80 OrdPU (nadpłaty i zwroty)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-12: AUTO-GENERATOR PISM DO URZĘDÓW (korespondencja).
correspondence_auto_generator := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.correspondence_auto_generator",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3264,
    "matched": true,
    "document_type": object.get(input.correspondence, "document_type", "WEZWANIE"),
    "auto_generated": true,
    "composer_integrated": true,
    "note": "auto-generator pism — wezwania, zażalenia, wnioski, odpowiedzi na pisma US (tax_correspondence_engine)",
    "_routing": "",
    "_routing_reason": sprintf("Auto-generator pism: %s wygenerowane", [object.get(input.correspondence, "document_type", "WEZWANIE")]),
    "_legal_basis": "OrdPU art. 120-129",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# ── SEKCJA 6: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE AUTO-ADAPTACJI API ───────
api_adaptation_pipeline := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.api_adaptation_pipeline",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3270,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.automatyzacja_ksiegowosci (ADR-002) — progi, terminy, API",
        "step_2_generate": "reguły bankowości (PSD2/PolishAPI) + e-urząd (ePUAP/e-Doręczenia/WIS) + formularze",
        "step_3_verify": "automatyzacja_ksiegowosci_auditor.py — walidacja spójności + pokrycia",
        "step_4_emit": "hot-reload pakietów jdg.banking_automation / jdg.edelivery / jdg.wis / jdg.calendar",
    },
    "api_adaptation": {
        "banki": "zmiany API banków (PolishAPI wersje) — auto-adaptacja integracji AIS/PIS",
        "urzedy": "zmiany API urzędów (ePUAP, e-Doręczenia, KSeF) — auto-adaptacja schematów",
        "status": api_adaptation_status(object.get(input.api, "api_version", "PolishAPI 2.0"), object.get(input.api, "supported_versions", ["PolishAPI 1.0", "PolishAPI 2.0"])),
    },
    "hot_reload": true,
    "note": "pipeline auto-adaptacji integracji — zmiany API banków i urzędów → auto-aktualizacja reguł (ADR-002)",
    "_routing": "",
    "_routing_reason": "Pipeline auto-adaptacji API banków/urzędów (ADR-002, hot-reload)",
    "_legal_basis": "ADR-002; PSD2; PolishAPI",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-15) ────────────────────
# INN-01: bank_statement_auto_booking | INN-02: payment_auto_tagging
# INN-03: psd2_monitor | INN-04: transfer_to_declaration_settlement
# INN-05: one_click_letter_flow | INN-06: form_autofill_engine
# INN-07: immortal_tax_calendar | INN-08: deadline_alert_tracker
# INN-09: bank_reconciliation_engine | INN-10: cashflow_forecaster
# INN-11: overpayment_auto_claimer | INN-12: correspondence_auto_generator

# INN-13: PRIORYTETYZACJA TERMINÓW PODATKOWYCH (KRYTYCZNE/UWAGA/OK).
tax_deadline_priority := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.tax_deadline_priority",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3271,
    "matched": true,
    "today_deadlines": object.get(input.calendar, "today_deadlines", []),
    "urgent_count": to_number(object.get(input.calendar, "urgent_count", 0)),
    "priority": priority_label(to_number(object.get(input.calendar, "urgent_count", 0)), object.get(input.calendar, "today_deadlines", [])),
    "note": "priorytetyzacja terminów — KRYTYCZNE (dziś) / UWAGA (3 dni) / BEZ TERMINÓW PILNYCH",
    "_routing": urgent_routing(count(object.get(input.calendar, "today_deadlines", []))),
    "_routing_reason": sprintf("Priorytetyzacja terminów: %s", [priority_label(to_number(object.get(input.calendar, "urgent_count", 0)), object.get(input.calendar, "today_deadlines", []))]),
    "_legal_basis": "Art. 47 u.ZUS; art. 99 VAT; art. 45 u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-14: WIRTUALNY ASYSTENT KSIĘGOWEGO — agregacja automatyzacji.
virtual_bookkeeper_assistant := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.virtual_bookkeeper_assistant",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3272,
    "matched": true,
    "assistant": {
        "ksiegowanie": "auto-księgowanie wyciągów (INN-01) + auto-koncyliacja (INN-09)",
        "deklaracje": "auto-fill formularzy (INN-06) + rozliczanie przelewów (INN-04)",
        "terminy": "nieśmiertelny kalendarz (INN-07) + priorytetyzacja (INN-13)",
        "pisma": "auto-generator pism (INN-12) + jedno kliknięcie (INN-05)",
        "nadplaty": "auto-wnioskowanie o zwrot (INN-11)",
    },
    "note": "wirtualny asystent księgowego — jeden panel: dokument → dane → decyzja → księgowanie → wysyłka",
    "_routing": "",
    "_routing_reason": "Wirtualny asystent księgowego — agregacja wszystkich INN automatyzacji księgowości",
    "_legal_basis": "ADR-002",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# INN-15: MPP — MECHANIZM PODZIELONEJ PŁATNOŚCI (auto-zalecenie).
split_payment_adviser := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.split_payment_adviser",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3273,
    "matched": true,
    "invoice_amount_pln": to_number(object.get(input.banking, "invoice_amount_pln", 0)),
    "mpp_threshold_pln": mpp_threshold_pln,
    "recommendation": mpp_required(to_number(object.get(input.banking, "invoice_amount_pln", 0))),
    "note": "doradca MPP — mechanizm podzielonej płatności (art. 108a VAT): zalecenie dla faktur ≥ 15 000 zł",
    "_routing": "",
    "_routing_reason": sprintf("Doradca MPP: kwota %.2f PLN, zalecenie: %s", [to_number(object.get(input.banking, "invoice_amount_pln", 0)), mpp_required(to_number(object.get(input.banking, "invoice_amount_pln", 0)))]),
    "_legal_basis": "Art. 108a-108d VAT (MPP)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}

# ── GŁÓWNY DECIDE (P18) — raport syntetyczny automatyzacji księgowości ─────────
decide := {
    "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.report",
    "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
    "priority": 3257,
    "matched": true,
    "banking": banking_audit,
    "edelivery_esig": edelivery_esig_audit,
    "forms": forms_declarations_audit,
    "calendar": calendar_deadlines_audit,
    "correspondence_cashflow": correspondence_cashflow_audit,
    "api_pipeline": api_adaptation_pipeline,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny automatyzacji księgowości (P18)",
    "_legal_basis": "PSD2; PolishAPI; eIDAS; ustawa o doręczeniach elektronicznych; OrdPU",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p18_automatyzacja_check", false) == true
}
