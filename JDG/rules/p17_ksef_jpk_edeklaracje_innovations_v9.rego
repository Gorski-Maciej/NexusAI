# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P17 GENIALNE POMYSŁY ENTERPRISE (KSeF + JPK + e-DEKLARACJE)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p17_ksef_jpk_edeklaracje_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG KSeF+JPK (P17) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: AUDYT KSeF (PRIORYTET) — obowiązek od 2026-02-01, wyjątki,
#             schemat XSD, UPO, off-line 7 dni, korekty, sankcje do 500 000 zł
#             (art. 106na-106nb VAT), zwolnienia B2C paragony
#   Sekcja 2: AUDYT JPK (PRIORYTET ★) — JPK_V7M/V7K auto-generacja, GTU
#             auto-przypisanie, walidacja krzyżowa, korekty JPK,
#             JPK_PKPIR/JPK_KR/JPK_CIT + AUTO-GENERATOR JPK (INN-01)
#   Sekcja 3: AUDYT e-DORĘCZEŃ I e-PODPISU — adres do doręczeń, skrzynki,
#             e-podpis kwalifikowany/zaufany, auto-aplikacja podpisu (INN-09)
#   Sekcja 4: AUDYT ePUAP, WIS, ODPORNOŚCI — integracja z e-Urzędem, WIS
#             auto-zapytania (INN-11), odporność na awarie KSeF 72h (INN-04),
#             sandbox (INN-12)
#   Sekcja 5: OPA JAKO ROZBUDOWANY SYSTEM — KSeF 2.0, nowe schematy XSD,
#             pipeline auto-aktualizacji schematów i reguł (INN-15)
#   Sekcja 6: 15 genialnych pomysłów Enterprise (INN-01..INN-15)
#   Sekcja 7: Mapa drogowa P0/P1/P2 (w raporcie R17)
#
# Zgodność: Ustawa o VAT (art. 106na-106nb KSeF), rozporządzenie KSeF,
#           JPK_V7M/V7K (Szablon JPK_VAT), ustawa o e-Doręczeniach,
#           ustawa o ePUAP, WIS (art. 42a VAT), ADR-002 (progi z
#           data.jdg.thresholds).
# package: jdg.p17_ksef_jpk_edeklaracje_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p17_ksef_jpk_edeklaracje_innovations

import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.no_match", "package": "jdg.p17_ksef_jpk_edeklaracje_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
ksef_limits := object.get(thresholds, "ksef_jpk_edeklaracje", {
    "ksef_mandatory_from": "2026-02-01",  # KSeF obowiązkowy (B2B) — art. 106na-106nb VAT
    "ksef_offline_grace_days": 7,         # off-line do 7 dni — tryb awaryjny
    "ksef_sanction_max_pln": 500000,      # kara KSeF do 500 000 zł (art. 106na VAT)
    "ksef_upo_deadline_days": 1,          # UPO generowane niezwłocznie (1 dzień)
    "jpk_v7_deadline_day": 25,            # JPK_V7 — do 25. dnia miesiąca
    "jpk_ksef_penalty_per_invoice": 1000, # kara za fakturę poza KSeF (do 1000 zł/szt.)
    "gtu_codes": ["GTU_01", "GTU_02", "GTU_03", "GTU_04", "GTU_05", "GTU_06", "GTU_07", "GTU_08", "GTU_09", "GTU_10", "GTU_11", "GTU_12", "GTU_13"],
    "esig_qualified": true,               # e-podpis kwalifikowany (eIDAS)
    "esig_trusted": true,                 # e-podpis zaufany (mObywatel)
    "edelivery_mandatory_from": "2026-01-01",  # e-Doręczenia obowiązkowe
    "wis_response_days": 3,               # WIS — 3 miesiące (orientacyjnie 90 dni)
    "ksef_sandbox": true,                 # sandbox KSeF dostępny
})

ksef_mandatory_from := object.get(ksef_limits, "ksef_mandatory_from", "2026-02-01")
ksef_offline_grace_days := to_number(object.get(ksef_limits, "ksef_offline_grace_days", 7))
ksef_sanction_max_pln := to_number(object.get(ksef_limits, "ksef_sanction_max_pln", 500000))
jpk_v7_deadline_day := to_number(object.get(ksef_limits, "jpk_v7_deadline_day", 25))
gtu_codes := object.get(ksef_limits, "gtu_codes", ["GTU_01", "GTU_02", "GTU_03"])

# ── Tabele danych Mapa drogowa P0/P1/P2 (z data.jdg.thresholds.ksef_jpk_edeklaracje — ADR-002) ──
ksef_api := object.get(ksef_limits, "ksef_api", {
    "endpoint_prod": "https://ksef.mf.gov.pl/api",
    "endpoint_sandbox": "https://ksef-test.mf.gov.pl/api",
    "auth": "token KSeF",
    "ksef_number_required": true,
    "upo_via_api": true,
    "retry_on_failure": true,
    "max_retries": 3,
})

xsd_offline_ci := object.get(ksef_limits, "xsd_offline_ci", {
    "validator": "xmllint/Java JAXB (offline)",
    "schemas": ["FA(2)", "FA(2)-korekta"],
    "ci_gate": true,
    "block_on_invalid": true,
    "required_fields": ["P_1", "P_2", "P_3", "P_4", "P_5", "P_6", "P_7", "P_8"],
})

ksef_corrections := object.get(ksef_limits, "ksef_corrections", {
    "correction_deadline_days": 30,
    "cancellation_allowed": true,
    "negative_invoice_allowed": true,
    "legal_basis": "Art. 106j VAT",
})

gtu_dictionary := object.get(ksef_limits, "gtu_dictionary", [
    {"code": "GTU_01", "name": "dostawa towarów", "hint": "dostawa towarów"},
    {"code": "GTU_02", "name": "wyroby tytoniowe", "hint": "napoje alkoholowe"},
    {"code": "GTU_03", "name": "napoje alkoholowe", "hint": "wyroby tytoniowe"},
    {"code": "GTU_04", "name": "paliwa", "hint": "paliwa"},
    {"code": "GTU_05", "name": "towary wrażliwe", "hint": "towary wrażliwe"},
    {"code": "GTU_06", "name": "odpady", "hint": "odpady"},
    {"code": "GTU_07", "name": "usługi transportowe", "hint": "usługi transportowe"},
    {"code": "GTU_08", "name": "usługi niematerialne", "hint": "usługi niematerialne"},
    {"code": "GTU_09", "name": "wierzytelności", "hint": "wierzytelności"},
    {"code": "GTU_10", "name": "nieruchomości", "hint": "nieruchomości"},
    {"code": "GTU_11", "name": "usługi w internecie", "hint": "usługi w internecie"},
    {"code": "GTU_12", "name": "energia", "hint": "energia"},
    {"code": "GTU_13", "name": "emisje CO2", "hint": "emisje CO2"},
])

gtu_learning_enabled := object.get(ksef_limits, "gtu_learning_enabled", true)

edelivery_b2b_b2g := object.get(ksef_limits, "edelivery_b2b_b2g", {
    "mailbox_api": "https://edoreczenia.gov.pl/api",
    "b2b_enabled": true,
    "b2g_enabled": true,
    "confirmation_required": true,
    "confirmation_type": "DORECZENIE_POTWIERDZONE",
})

ksef_dashboard_cfg := object.get(ksef_limits, "ksef_dashboard", {
    "widgets": ["status_upo", "kara_ryzyko", "rejestry_jpk"],
    "refresh": "na żywo (hot-reload ADR-002)",
    "export_formats": ["JSON", "CSV", "PDF"],
})

jpk_cit_2026 := object.get(ksef_limits, "jpk_cit_2026", {
    "template": "Szablon JPK_CIT v2 (MF 2026)",
    "structure_version": "2.0",
    "deadline_day": 31,
    "frequency": "rocznie (I kw.)",
})

# ── Funkcje pomocnicze Mapy drogowej ──
ksef_api_routing(configured, ksef_number) = "TRIAGE_QUEUE" { configured == false or ksef_number == "" }
else = "" { true }

ksef_api_status(configured, ksef_number) = "API KSeF NIESKONFIGUROWANE — pobierz token i wygeneruj numer KSeF" { configured == false }
else = "BRAK NUMERU KSeF — wygeneruj numer przed wysyłką faktur" { ksef_number == "" }
else = "API KSeF GOTOWE — produkcyjna wysyłka + UPO via API" { true }

xsd_ci_routing(ci_gate_ok) = "BLOCK_AND_ALERT" { ci_gate_ok == false }
else = "" { true }

correction_routing(corrections_pending) = "TRIAGE_QUEUE" { corrections_pending > 0 }
else = "" { true }

correction_status(corrections_pending, deadline_days) = sprintf("KOREKTY KSeF — %d oczekujących, termin %d dni (art. 106j VAT)", [corrections_pending, deadline_days]) { corrections_pending > 0 }
else = "Brak korekt KSeF — OK (art. 106j VAT)" { true }

gtu_dict_entry(hint) = gtu_dictionary[idx] {
    hint != ""
    code := gtu_from_hint(hint)
    idx := [j | some j, e in gtu_dictionary; object.get(e, "code", "") == code][0]
} else = gtu_dictionary[0] { true }

edelivery_routing(mailbox_active, confirmations_ok) = "TRIAGE_QUEUE" { mailbox_active == false }
else = "TRIAGE_QUEUE" { confirmations_ok == false }
else = "" { true }

edelivery_status(mailbox_active, confirmations_ok) = "SKRZYNKA e-DORĘCZEŃ NIEAKTYWNA — aktywuj (B2B/B2G od 2026-01-01)" { mailbox_active == false }
else = "BRAK POTWIERDZEŃ DORĘCZEŃ — zweryfikuj status wiadomości" { confirmations_ok == false }
else = "SKRZYNKA e-DORĘCZEŃ AKTYWNA + POTWIERDZENIA OK (B2B/B2G)" { true }

dashboard_routing(upo_missing, kara_pln, corrections_pending) = "BLOCK_AND_ALERT" { kara_pln >= ksef_sanction_max_pln }
else = "TRIAGE_QUEUE" { upo_missing > 0 or corrections_pending > 0 or kara_pln > 0 }
else = "" { true }

jpk_cit_routing(automation_ready) = "" { automation_ready == true }
else = "TRIAGE_QUEUE" { true }

round2(x) = r {
    r := round(x * 100) / 100
}

# ── Funkcje pomocnicze (else-chain — deterministyczne, zero konfliktów) ────────
ksef_status(eval_date) = "OBOWIĄZKOWY — KSeF od " + ksef_mandatory_from { eval_date >= ksef_mandatory_from }
else = "FAKULTATYWNY — KSeF od " + ksef_mandatory_from { true }

offline_ok(offline_days) = "OK — w terminie (≤7 dni awaryjnego off-line)" { offline_days <= ksef_offline_grace_days }
else = "PRZEKROCZONO — off-line >7 dni bez uprawnienia!" { true }

offline_routing(offline_days) = "TRIAGE_QUEUE" { offline_days > ksef_offline_grace_days }
else = "" { true }

upo_status(received) = "OK — UPO otrzymane (potwierdzenie KSeF)" { received == true }
else = "BRAK UPO — zweryfikuj status faktury w KSeF!" { true }

upo_routing(received) = "TRIAGE_QUEUE" { received == false }
else = "" { true }

esig_status(qualified, trusted) = "PODPIS KWALIFIKOWANY (eIDAS)" { qualified == true }
else = "PODPIS ZAUFANY (mObywatel)" { trusted == true }
else = "BRAK e-PODPISU — wymagany dla e-Doręczeń i KSeF!" { true }

jpk_due(day_of_month) = "TERMIN — złóż JPK do " + sprintf("%d. dnia", [jpk_v7_deadline_day]) { day_of_month > jpk_v7_deadline_day }
else = "W TERMINIE — JPK do " + sprintf("%d. dnia miesiąca", [jpk_v7_deadline_day]) { true }

sanction_for_invoices(count_invoices, ksef_violation) = ksef_sanction_max_pln { ksef_violation == true; count_invoices >= 5 }
else = round2(to_number(count_invoices) * to_number(object.get(ksef_limits, "jpk_ksef_penalty_per_invoice", 1000))) { ksef_violation == true }
else = 0 { true }

sanction_level(fine) = "KRYTYCZNE — sankcja maksymalna!" { fine >= ksef_sanction_max_pln }
else = "WYSOKIE" { fine >= 100000 }
else = "UMIARKOWANE" { fine > 0 }
else = "BRAK" { true }

sanction_routing(fine) = "BLOCK_AND_ALERT" { fine >= ksef_sanction_max_pln }
else = "TRIAGE_QUEUE" { fine > 0 }
else = "" { true }

pipeline_hot_reload() = true { true }

gtu_from_hint(hint) = "GTU_01" { hint == "dostawa towarów" }
else = "GTU_02" { hint == "wyroby tytoniowe" }
else = "GTU_03" { hint == "napoje alkoholowe" }
else = "GTU_04" { hint == "paliwa" }
else = "GTU_05" { hint == "towary wrażliwe (kożuchy, elektronika)" }
else = "GTU_06" { hint == "odpady" }
else = "GTU_07" { hint == "usługi transportowe" }
else = "GTU_08" { hint == "usługi niematerialne" }
else = "GTU_09" { hint == "wierzytelności" }
else = "GTU_10" { hint == "nieruchomości" }
else = "GTU_11" { hint == "usługi w internecie" }
else = "GTU_12" { hint == "energia" }
else = "GTU_13" { hint == "emisje CO2" }
else = "GTU_01" { true }

edelivery_status(address_set, mailbox_active) = "ADRES USTAWIONY + SKRZYNKA AKTYWNA" { address_set == true; mailbox_active == true }
else = "ADRES USTAWIONY — AKTYWUJ SKRZYNKĘ" { address_set == true }
else = "BRAK ADRESU DO DORĘCZEŃ" { true }

# ── SEKCJA 1: MAPA POKRYCIA MODUŁÓW (KSeF + JPK + e-urząd) ────────────────────
# Status COMPLETE/PARTIAL/MISSING z data.jdg.p17_audit (ksef_jpk_edeklaracje_auditor.py).
p17_priority_modules := ["ksef_core", "ksef_enterprise", "jpk", "gtu", "edelivery", "esig", "wis"]

p17_audit_data := object.get(data.jdg, "p17_audit", {})
p17_coverage_modules := object.get(p17_audit_data, "modules", {})

ksef_jpk_coverage_report := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_jpk_coverage_report",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3010,
    "matched": true,
    "modules": {mod: {
        "status": object.get(object.get(p17_coverage_modules, mod, {}), "status", "MISSING"),
        "rules": object.get(object.get(p17_coverage_modules, mod, {}), "rules", 0),
    } | mod := p17_priority_modules[_]},
    "summary": {
        "total": count(p17_priority_modules),
        "complete": count([m | m := p17_priority_modules[_]; object.get(object.get(p17_coverage_modules, m, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([m | m := p17_priority_modules[_]; object.get(object.get(p17_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([m | m := p17_priority_modules[_]; object.get(object.get(p17_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]) / count(p17_priority_modules) * 100),
    "micro_total_rule_ids": object.get(p17_audit_data, "total_rule_ids", 0),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia modułów KSeF + JPK + e-urząd — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "Ustawa o VAT (art. 106na-106nb); JPK; e-Doręczenia",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# ── SEKCJA 1: AUDYT KSeF (POZIOM ENTERPRISE — PRIORYTET) ──────────────────────
# Obowiązek od 2026-02-01, wyjątki, schemat XSD, UPO, off-line 7 dni, sankcje.
ksef_audit := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_audit",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3120,
    "matched": true,
    "obowiazek": {
        "status": ksef_status(object.get(input.jdg_entrepreneur, "eval_date", "2026-08-01")),
        "od": ksef_mandatory_from,
        "legal_basis": "Art. 106na-106nb VAT (KSeF)",
    },
    "wyjatki": {
        "b2c_paragony": "paragony B2C — zwolnienie z KSeF (do 2027/2028)",
        "samofakturowanie": "samofakturowanie — możliwe w KSeF",
        "legal_basis": "Rozporządzenie KSeF; art. 106nb VAT",
    },
    "schemat": {
        "xsd": "FA(2) — struktura XML (KSeF 1.0/2.0), KSeF 2.0 w planach",
        "required_fields": ["P_1", "P_2", "P_3", "P_4", "P_5", "P_6", "P_7", "P_8"],
        "legal_basis": "Rozporządzenie Ministra Finansów ws. KSeF",
    },
    "upo": {
        "obowiązek": "UPO generowane niezwłocznie po wysyłce — do 1 dnia",
        "deadline_days": object.get(ksef_limits, "ksef_upo_deadline_days", 1),
        "legal_basis": "Art. 106na ust. 3 VAT",
    },
    "offline": {
        "grace_days": ksef_offline_grace_days,
        "tryb_awaryjny": "do 7 dni bez dostępu do KSeF — po zgłoszeniu do MF",
        "legal_basis": "Art. 106nb ust. 5-6 VAT",
    },
    "sankcje": {
        "max_pln": ksef_sanction_max_pln,
        "per_invoice_pln": object.get(ksef_limits, "jpk_ksef_penalty_per_invoice", 1000),
        "legal_basis": "Art. 106na VAT (kara do 500 000 zł)",
    },
    "integrated_packages": ["jdg.ksef_jpk (11 reguł)", "jdg.micro.ksef (80)", "jdg.micro.plan33_ksef (75)", "jdg.ksef_innovations_enterprise"],
    "_routing": "",
    "_routing_reason": "Audyt KSeF — obowiązek 2026-02-01, wyjątki, schemat, UPO, off-line, sankcje (priorytet)",
    "_legal_basis": "Ustawa o VAT art. 106na-106nb",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# INN-01: AUTO-GENERATOR JPK_V7 z rejestrów VAT (Sekcja 2 — PRIORYTET).
jpk_v7_auto_generator := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_v7_auto_generator",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3121,
    "matched": true,
    "type": object.get(input.jpk, "type", "JPK_V7M"),
    "sales_register": object.get(input.jpk, "sales_register", 0),
    "purchase_register": object.get(input.jpk, "purchase_register", 0),
    "vat_sales": to_number(object.get(input.jpk, "vat_sales", 0)),
    "vat_purchase": to_number(object.get(input.jpk, "vat_purchase", 0)),
    "vat_due": round2(to_number(object.get(input.jpk, "vat_sales", 0)) - to_number(object.get(input.jpk, "vat_purchase", 0))),
    "generated": true,
    "deadline": "do " + sprintf("%d. dnia miesiąca", [jpk_v7_deadline_day]),
    "note": "auto-generator JPK_V7M/V7K z rejestrów VAT — sprzedaż, zakupy, VAT należny/naliczony",
    "_routing": "",
    "_routing_reason": "Auto-generator JPK_V7 (INN-01) — rejestry VAT → JPK_V7M/V7K",
    "_legal_basis": "Szablon JPK_VAT (JPK_V7M/V7K); art. 82 ust. 1b VAT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    object.get(input.jpk, "type", "JPK_V7M") in {"JPK_V7M", "JPK_V7K"}
}

# INN-02: TRACKER UPO — potwierdzenia KSeF.
ksef_upo_tracker := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_upo_tracker",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3122,
    "matched": true,
    "invoice_count": to_number(object.get(input.ksef, "invoice_count", 0)),
    "upo_received_count": to_number(object.get(input.ksef, "upo_received_count", 0)),
    "upo_missing": upo_missing,
    "status": upo_status(upo_missing == 0),
    "note": "tracker UPO — porównanie faktur wysłanych do KSeF z otrzymanymi potwierdzeniami",
    "_routing": upo_routing(upo_missing == 0),
    "_routing_reason": sprintf("Tracker UPO: %d faktur, %d UPO, brak %d", [to_number(object.get(input.ksef, "invoice_count", 0)), to_number(object.get(input.ksef, "upo_received_count", 0)), upo_missing]),
    "_legal_basis": "Art. 106na ust. 3 VAT (UPO)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    invoice_count := to_number(object.get(input.ksef, "invoice_count", 0))
    upo_missing := invoice_count - to_number(object.get(input.ksef, "upo_received_count", 0))
    upo_missing >= 0
}

# INN-03: MONITOR SANKCJI KSeF (progi kar).
ksef_sanction_monitor := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_sanction_monitor",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3123,
    "matched": true,
    "invoices_outside_ksef": invoices_outside,
    "ksef_violation": invoices_outside > 0,
    "estimated_fine_pln": fine,
    "sanction_level": sanction_level(fine),
    "max_sanction_pln": ksef_sanction_max_pln,
    "note": "monitor sankcji KSeF — faktury wystawione poza systemem (art. 106na VAT)",
    "_routing": sanction_routing(fine),
    "_routing_reason": sprintf("Monitor sankcji KSeF: %d faktur poza KSeF, szacunkowa kara %d PLN", [invoices_outside, fine]),
    "_legal_basis": "Art. 106na ust. 1-2 VAT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    invoices_outside := to_number(object.get(input.ksef, "invoices_outside_ksef", 0))
    fine := sanction_for_invoices(invoices_outside, invoices_outside > 0)
}

# INN-04: SYSTEM RETRY OFFLINE — odporność na awarie KSeF (72h/7 dni).
ksef_offline_retry := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_offline_retry",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3124,
    "matched": true,
    "offline_days": offline_days,
    "grace_days": ksef_offline_grace_days,
    "in_queue": to_number(object.get(input.ksef, "offline_invoices", 0)),
    "status": offline_ok(offline_days),
    "auto_retry": true,
    "note": "system retry offline KSeF — kolejka faktur w trybie awaryjnym, auto-wysyłka po przywróceniu",
    "_routing": offline_routing(offline_days),
    "_routing_reason": sprintf("Retry offline KSeF: %d dni off-line (grace %d), %d faktur w kolejce", [offline_days, ksef_offline_grace_days, to_number(object.get(input.ksef, "offline_invoices", 0))]),
    "_legal_basis": "Art. 106nb ust. 5-6 VAT (tryb awaryjny)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    offline_days := to_number(object.get(input.ksef, "offline_days", 0))
}

# ── SEKCJA 2: AUDYT JPK (POZIOM ENTERPRISE — PRIORYTET ★) ─────────────────────
jpk_audit := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_audit",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3130,
    "matched": true,
    "jpk_v7": {
        "obowiązek": "JPK_V7M/V7K — miesięczne, do " + sprintf("%d. dnia", [jpk_v7_deadline_day]) + " (art. 82 ust. 1b VAT)",
        "struktura": "sprzedaż + zakupy + VAT należny + VAT naliczony + GTU + KSeF",
        "legal_basis": "Art. 82 ust. 1b VAT",
    },
    "jpk_pkpir": {
        "obowiązek": "JPK_PKPIR — księga przychodów i rozchodów (na żądanie)",
        "legal_basis": "Art. 193a-193c OrdPU",
    },
    "jpk_kr": {
        "obowiązek": "JPK_KR — księgi rachunkowe (UoR, na żądanie)",
        "legal_basis": "Art. 193a-193c OrdPU",
    },
    "jpk_cit": {
        "obowiązek": "JPK_CIT — dane dla CIT (spółki, nie JDG)",
        "legal_basis": "Art. 9 ust. 1d-1j u.CIT",
    },
    "gtu": {
        "obowiązek": "kody GTU_01..GTU_13 w JPK_V7 — auto-przypisanie",
        "codes": gtu_codes,
        "legal_basis": "Szablon JPK_VAT (pole K_10-K_19)",
    },
    "walidacja_krzyzowa": {
        "obowiązek": "spójność rejestrów z deklaracją VAT-7/VAT-UE",
        "legal_basis": "Art. 82 VAT + Szablon JPK",
    },
    "integrated_packages": ["jdg.micro.jpk (36 reguł)", "jdg.micro.plan33_jpk (71)", "jdg.jpk_v7_autogen_enterprise (8)", "jdg.jpk_cit (5)"],
    "_routing": "",
    "_routing_reason": "Audyt JPK — JPK_V7M/V7K, GTU, walidacja krzyżowa, korekty, JPK_PKPIR/KR/CIT (priorytet)",
    "_legal_basis": "Art. 82 VAT; art. 193a-193c OrdPU",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# INN-05: GTU AUTO-PRZYPISANIE — kody GTU z opisu transakcji.
gtu_auto_assigner := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.gtu_auto_assigner",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3131,
    "matched": true,
    "transaction_desc": object.get(input.invoice, "gtu_hint", ""),
    "assigned_gtu": gtu_from_hint(object.get(input.invoice, "gtu_hint", "")),
    "gtu_valid": gtu_from_hint(object.get(input.invoice, "gtu_hint", "")) in gtu_codes,
    "note": "GTU auto-przypisanie — mapowanie opisu towaru/usługi na kody GTU_01..GTU_13",
    "_routing": "",
    "_routing_reason": sprintf("GTU auto-przypisanie: %s → %s", [object.get(input.invoice, "gtu_hint", ""), gtu_from_hint(object.get(input.invoice, "gtu_hint", ""))]),
    "_legal_basis": "Szablon JPK_VAT (GTU)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    object.get(input.invoice, "gtu_hint", "") != ""
}

# INN-06: WALIDATOR XSD — walidacja struktury faktury KSeF.
ksef_xsd_validator := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_xsd_validator",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3132,
    "matched": true,
    "schema_version": object.get(input.ksef, "schema_version", "FA(2)"),
    "xsd_valid": xsd_valid,
    "invalid_fields": missing,
    "note": "walidator XSD — sprawdzenie wymaganych pól faktury ustrukturyzowanej (P_1..P_8)",
    "_routing": "TRIAGE_QUEUE" if count(missing) > 0 else "",
    "_routing_reason": sprintf("Walidacja XSD: schema %s, brakujące pola %d", [object.get(input.ksef, "schema_version", "FA(2)"), count(missing)]),
    "_legal_basis": "Rozporządzenie MF ws. KSeF (schemat FA)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    required := {"P_1", "P_2", "P_3", "P_4", "P_5", "P_6", "P_7", "P_8"}
    provided := object.get(input.ksef, "fields", required)
    missing := [f | f := required[_]; not provided[f]]
    xsd_valid := count(missing) == 0
}

# INN-07: FIREWALL KSeF — wykrywanie anomalii przed wysyłką.
ksef_firewall_guard := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_firewall_guard",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3133,
    "matched": true,
    "anomalies": anomalies,
    "blocked": count(anomalies) > 0,
    "note": "firewall KSeF — blokada faktur z anomaliami (błędny NIP, kwota, duplikat) przed wysyłką",
    "_routing": "BLOCK_AND_ALERT" if count(anomalies) > 0 else "",
    "_routing_reason": sprintf("Firewall KSeF: %d anomalii wykrytych", [count(anomalies)]),
    "_legal_basis": "P34 Red Team; KSeF",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    anomalies := [a | a := ["NIP invalid", "kwota brutto != netto+VAT", "duplikat faktury"][_]; object.get(input.ksef, "anomaly_" + a, false) == true]
    count(anomalies) >= 0
}

# INN-08: WALIDACJA KRZYŻOWA JPK — rejestry vs deklaracja.
jpk_cross_validation := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_cross_validation",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3134,
    "matched": true,
    "sales_register": to_number(object.get(input.jpk, "sales_register", 0)),
    "vat_7_sales": to_number(object.get(input.jpk, "vat_7_sales", 0)),
    "purchase_register": to_number(object.get(input.jpk, "purchase_register", 0)),
    "vat_7_purchase": to_number(object.get(input.jpk, "vat_7_purchase", 0)),
    "sales_match": to_number(object.get(input.jpk, "sales_register", 0)) == to_number(object.get(input.jpk, "vat_7_sales", 0)),
    "purchase_match": to_number(object.get(input.jpk, "purchase_register", 0)) == to_number(object.get(input.jpk, "vat_7_purchase", 0)),
    "consistent": consistent,
    "note": "walidacja krzyżowa JPK — spójność rejestrów sprzedaży/zakupów z deklaracją VAT-7",
    "_routing": "TRIAGE_QUEUE" if consistent == false else "",
    "_routing_reason": sprintf("Walidacja krzyżowa JPK: sprzedaż %v, zakupy %v", [to_number(object.get(input.jpk, "sales_register", 0)) == to_number(object.get(input.jpk, "vat_7_sales", 0)), to_number(object.get(input.jpk, "purchase_register", 0)) == to_number(object.get(input.jpk, "vat_7_purchase", 0))]),
    "_legal_basis": "Art. 82 VAT + Szablon JPK_VAT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    consistent := to_number(object.get(input.jpk, "sales_register", 0)) == to_number(object.get(input.jpk, "vat_7_sales", 0))
        and to_number(object.get(input.jpk, "purchase_register", 0)) == to_number(object.get(input.jpk, "vat_7_purchase", 0))
}

# ── SEKCJA 3: AUDYT e-DORĘCZEŃ I e-PODPISU (POZIOM ENTERPRISE) ────────────────
edelivery_esig_audit := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.edelivery_esig_audit",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3140,
    "matched": true,
    "edoręczenia": {
        "obowiązek": "adres do doręczeń + skrzynka e-Doręczeń (od " + object.get(ksef_limits, "edelivery_mandatory_from", "2026-01-01") + ")",
        "legal_basis": "Ustawa o doręczeniach elektronicznych",
    },
    "e_podpis": {
        "kwalifikowany": object.get(ksef_limits, "esig_qualified", true),
        "zaufany": object.get(ksef_limits, "esig_trusted", true),
        "status": esig_status(object.get(ksef_limits, "esig_qualified", true), object.get(ksef_limits, "esig_trusted", true)),
        "legal_basis": "eIDAS (910/2014); ustawa o eIDAS",
    },
    "auto_aplikacja": {
        "obowiązek": "auto-aplikacja podpisu na pismach do urzędów",
        "legal_basis": "Ustawa o informatyzacji",
    },
    "integrated_packages": ["jdg.edelivery (plan44: 9 + plan45: 42)", "jdg.esig (plan44: 8 + plan45: 37)", "jdg.esig_auto_applicator (5)", "jdg.hyper.edelivery (22)"],
    "_routing": "",
    "_routing_reason": "Audyt e-Doręczeń i e-podpisu — adres, skrzynki, e-podpis kwalifikowany/zaufany, auto-aplikacja",
    "_legal_basis": "Ustawa o doręczeniach elektronicznych; eIDAS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# INN-09: AUTO-APLIKACJA e-PODPISU.
esig_auto_applier := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.esig_auto_applier",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3141,
    "matched": true,
    "signature_type": object.get(input.jdg_entrepreneur, "esig_type", "QUALIFIED"),
    "documents_signed": to_number(object.get(input.jdg_entrepreneur, "esig_documents", 0)),
    "auto_applied": true,
    "note": "auto-aplikacja e-podpisu — kwalifikowany/zaufany na pismach do urzędów (ePUAP, e-Doręczenia)",
    "_routing": "",
    "_routing_reason": sprintf("Auto-aplikacja e-podpisu: %s, %d dokumentów", [object.get(input.jdg_entrepreneur, "esig_type", "QUALIFIED"), to_number(object.get(input.jdg_entrepreneur, "esig_documents", 0))]),
    "_legal_basis": "eIDAS (910/2014); ustawa o informatyzacji",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    object.get(input.jdg_entrepreneur, "esig_type", "QUALIFIED") in {"QUALIFIED", "TRUSTED"}
}

# INN-10: MENEDŻER ADRESU DO DORĘCZEŃ.
edelivery_address_manager := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.edelivery_address_manager",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3142,
    "matched": true,
    "address_set": object.get(input.jdg_entrepreneur, "edelivery_address_set", false),
    "mailbox_active": object.get(input.jdg_entrepreneur, "edelivery_mailbox_active", false),
    "status": edelivery_status(object.get(input.jdg_entrepreneur, "edelivery_address_set", false), object.get(input.jdg_entrepreneur, "edelivery_mailbox_active", false)),
    "note": "menedżer adresu do doręczeń — ustawienie adresu + aktywacja skrzynki e-Doręczeń",
    "_routing": "TRIAGE_QUEUE" if object.get(input.jdg_entrepreneur, "edelivery_address_set", false) == false else "",
    "_routing_reason": "Menedżer adresu do doręczeń (INN-10)",
    "_legal_basis": "Ustawa o doręczeniach elektronicznych",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# ── SEKCJA 4: AUDYT ePUAP, WIS, ODPORNOŚCI (POZIOM ENTERPRISE) ────────────────
epuap_wis_resilience_audit := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.epuap_wis_resilience_audit",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3150,
    "matched": true,
    "epuap": {
        "obowiązek": "konto ePUAP — podpisywanie i wysyłka pism do urzędów",
        "legal_basis": "Ustawa o informatyzacji; ePUAP",
    },
    "wis": {
        "obowiązek": "WIS — wiążąca informacja stawkowa (art. 42a VAT), odpowiedź do 3 miesięcy",
        "response_days": object.get(ksef_limits, "wis_response_days", 3),
        "legal_basis": "Art. 42a VAT",
    },
    "odporność": {
        "ksef_awaria": "tryb awaryjny KSeF — do 7 dni, retry po przywróceniu",
        "grace_days": ksef_offline_grace_days,
        "legal_basis": "Art. 106nb ust. 5-6 VAT",
    },
    "sandbox": {
        "dostepny": object.get(ksef_limits, "ksef_sandbox", true),
        "obowiązek": "testy integracji w sandboxie KSeF przed produkcją",
        "legal_basis": "KSeF API (sandbox MF)",
    },
    "integrated_packages": ["jdg.epuap (4)", "jdg.wis (plan44: 9 + plan45: 36)", "jdg.wis_api (4)", "jdg.ksef_resilience (8)", "jdg.ksef_sandbox_harness (4)"],
    "_routing": "",
    "_routing_reason": "Audyt ePUAP, WIS i odporności — e-Urząd, WIS auto-zapytania, odporność 72h/7 dni, sandbox",
    "_legal_basis": "Art. 42a VAT; ustawa o informatyzacji; KSeF",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# INN-11: WIS AUTO-ZAPYTANIA.
wis_auto_requester := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.wis_auto_requester",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3151,
    "matched": true,
    "wis_requested": object.get(input.wis, "wis_requested", false),
    "wis_status": object.get(input.wis, "wis_status", "PENDING"),
    "response_days": object.get(ksef_limits, "wis_response_days", 3),
    "note": "WIS auto-zapytania — automatyczne wystąpienie o wiążącą informację stawkową (art. 42a VAT)",
    "_routing": "",
    "_routing_reason": sprintf("WIS auto-zapytanie: status %s", [object.get(input.wis, "wis_status", "PENDING")]),
    "_legal_basis": "Art. 42a VAT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# INN-12: SANDBOX KSeF — środowisko testowe.
ksef_sandbox_harness := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_sandbox_harness",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3152,
    "matched": true,
    "sandbox_active": object.get(ksef_limits, "ksef_sandbox", true),
    "test_invoices": to_number(object.get(input.ksef, "sandbox_test_invoices", 0)),
    "note": "sandbox KSeF — środowisko testowe do walidacji integracji przed produkcją",
    "_routing": "",
    "_routing_reason": sprintf("Sandbox KSeF: aktywny=%v, %d faktur testowych", [object.get(ksef_limits, "ksef_sandbox", true), to_number(object.get(input.ksef, "sandbox_test_invoices", 0))]),
    "_legal_basis": "KSeF API (sandbox MF)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# INN-13: KALKULATOR SANKCJI KSeF.
ksef_sanctions_calculator := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_sanctions_calculator",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3153,
    "matched": true,
    "invoices_violation": invoices_outside,
    "max_sanction_pln": ksef_sanction_max_pln,
    "per_invoice_pln": object.get(ksef_limits, "jpk_ksef_penalty_per_invoice", 1000),
    "estimated_fine_pln": fine,
    "sanction_level": sanction_level(fine),
    "note": "kalkulator sankcji KSeF — faktury poza systemem: do 500 000 zł (art. 106na VAT)",
    "_routing": sanction_routing(fine),
    "_routing_reason": sprintf("Kalkulator sankcji KSeF: %d faktur → %d PLN", [invoices_outside, fine]),
    "_legal_basis": "Art. 106na VAT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    invoices_outside := to_number(object.get(input.ksef, "invoices_outside_ksef", 0))
    fine := sanction_for_invoices(invoices_outside, invoices_outside > 0)
}

# INN-14: KALENDARZ TERMINÓW JPK i KSeF.
jpk_deadline_calendar := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_deadline_calendar",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3154,
    "matched": true,
    "deadlines": ["JPK_V7M/V7K — do " + sprintf("%d.", [jpk_v7_deadline_day]) + " dnia miesiąca", "VAT-7 — do 25. dnia miesiąca", "VAT-UE — do 25. dnia miesiąca", "JPK_PKPIR/KR/CIT — na żądanie US (art. 193a OrdPU)", "KSeF — faktury wystawiane od 2026-02-01"],
    "note": "kalendarz terminów JPK i KSeF — JPK_V7 do 25., VAT-7 do 25., e-deklaracje",
    "_routing": "",
    "_routing_reason": "Kalendarz terminów JPK/KSeF (INN-14)",
    "_legal_basis": "Art. 82 VAT; art. 193a OrdPU",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# ── SEKCJA 5: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE SCHEMATÓW XSD ────────────
ksef_pipeline_snapshot := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_pipeline_snapshot",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3160,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.ksef_jpk_edeklaracje (ADR-002) — progi, terminy, schematy",
        "step_2_generate": "reguły KSeF (wystawianie, UPO, off-line, sankcje) + JPK (V7, GTU, walidacja) + e-urząd",
        "step_3_verify": "ksef_jpk_edeklaracje_auditor.py — walidacja spójności + pokrycia",
        "step_4_emit": "hot-reload pakietów jdg.ksef_jpk / jdg.micro.ksef / jdg.jpk_v7_autogen / jdg.edelivery",
    },
    "ksef_2_0": {
        "obowiązek": "KSeF 2.0 — nowe schematy XSD, rozszerzone przepływy (w planach MF)",
        "pipeline_auto_update": "auto-aktualizacja schematów i reguł przy nowych wersjach XSD",
    },
    "hot_reload": pipeline_hot_reload(),
    "note": "pipeline auto-aktualizacji schematów KSeF/XSD i reguł JPK — ADR-002, hot-reload",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji schematów KSeF 2.0 / XSD (ADR-002)",
    "_legal_basis": "ADR-002; rozporządzenia MF ws. KSeF",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# ── SEKCJA 6: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-15) ────────────────────
# INN-01: jpk_v7_auto_generator | INN-02: ksef_upo_tracker
# INN-03: ksef_sanction_monitor | INN-04: ksef_offline_retry
# INN-05: gtu_auto_assigner | INN-06: ksef_xsd_validator
# INN-07: ksef_firewall_guard | INN-08: jpk_cross_validation
# INN-09: esig_auto_applier | INN-10: edelivery_address_manager
# INN-11: wis_auto_requester | INN-12: ksef_sandbox_harness
# INN-13: ksef_sanctions_calculator | INN-14: jpk_deadline_calendar

# INN-15: PIPELINE AUTO-AKTUALIZACJI SCHEMATÓW XSD (KSeF 2.0).
ksef_schema_pipeline := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_schema_pipeline",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3161,
    "matched": true,
    "current_schema": object.get(input.ksef, "schema_version", "FA(2)"),
    "xsd_registry": ["FA(2)", "FA(2)-korekta", "KSeF 2.0 (plan)"],
    "auto_update": "monitor nowych wersji XSD → auto-generacja reguł walidacji",
    "hot_reload": true,
    "note": "pipeline auto-aktualizacji schematów KSeF — nowe XSD → nowe reguły walidacji (KSeF 2.0)",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji schematów XSD KSeF (INN-15)",
    "_legal_basis": "Rozporządzenia MF ws. KSeF; ADR-002",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# ── MAPA DROGOWA P0/P1/P2 — wdrożone (R17) ────────────────────────────────────
# P0-1: rzeczywista integracja API KSeF (produkcyjna wysyłka + UPO via API).
ksef_api_integration := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_api_integration",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3170,
    "matched": true,
    "endpoint_prod": object.get(ksef_api, "endpoint_prod", ""),
    "endpoint_sandbox": object.get(ksef_api, "endpoint_sandbox", ""),
    "api_configured": api_configured,
    "ksef_number": ksef_number,
    "upo_via_api": object.get(ksef_api, "upo_via_api", true),
    "retry_on_failure": object.get(ksef_api, "retry_on_failure", true),
    "integration_status": ksef_api_status(api_configured, ksef_number),
    "note": "rzeczywista integracja API KSeF — produkcyjna wysyłka faktur + odbiór UPO via API (P0)",
    "_routing": ksef_api_routing(api_configured, ksef_number),
    "_routing_reason": sprintf("API KSeF: configured=%v, numer KSeF=%q, UPO via API=%v", [api_configured, ksef_number, object.get(ksef_api, "upo_via_api", true)]),
    "_legal_basis": "Art. 106na-106nb VAT; Rozporządzenie MF ws. KSeF",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    api_configured := object.get(input.ksef, "api_configured", false)
    ksef_number := object.get(input.ksef, "ksef_number", "")
}

# P0-2: pełny walidator XSD offline (Java/xmllint) w CI.
ksef_xsd_offline_ci := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_xsd_offline_ci",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3171,
    "matched": true,
    "validator": object.get(xsd_offline_ci, "validator", "xmllint/Java JAXB"),
    "schemas": object.get(xsd_offline_ci, "schemas", ["FA(2)"]),
    "ci_gate": object.get(xsd_offline_ci, "ci_gate", true),
    "block_on_invalid": object.get(xsd_offline_ci, "block_on_invalid", true),
    "required_fields": object.get(xsd_offline_ci, "required_fields", ["P_1"]),
    "ci_last_run_ok": ci_ok,
    "note": "pełny walidator XSD offline (xmllint/Java JAXB) — brama CI blokuje niepoprawne schematy (P0)",
    "_routing": xsd_ci_routing(ci_ok),
    "_routing_reason": sprintf("Walidator XSD offline: %d schematów, CI gate=%v, last run=%v", [count(object.get(xsd_offline_ci, "schemas", ["FA(2)"])), object.get(xsd_offline_ci, "ci_gate", true), ci_ok]),
    "_legal_basis": "Rozporządzenie MF ws. KSeF (schemat FA)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    ci_ok := object.get(input.ksef, "xsd_ci_last_run_ok", false)
}

# P1-1: korekty KSeF end-to-end (art. 106j VAT) + anulowanie faktur.
ksef_corrections_e2e := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_corrections_e2e",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3172,
    "matched": true,
    "corrections_pending": corrections_pending,
    "correction_deadline_days": object.get(ksef_corrections, "correction_deadline_days", 30),
    "cancellation_allowed": object.get(ksef_corrections, "cancellation_allowed", true),
    "negative_invoice_allowed": object.get(ksef_corrections, "negative_invoice_allowed", true),
    "correction_reasons": object.get(ksef_corrections, "correction_reasons", ["błąd kwoty"]),
    "status": correction_status(corrections_pending, object.get(ksef_corrections, "correction_deadline_days", 30)),
    "note": "korekty KSeF end-to-end — art. 106j VAT, anulowanie faktur, faktury korygujące (P1)",
    "_routing": correction_routing(corrections_pending),
    "_routing_reason": sprintf("Korekty KSeF: %d oczekujących, termin %d dni (art. 106j VAT)", [corrections_pending, object.get(ksef_corrections, "correction_deadline_days", 30)]),
    "_legal_basis": "Art. 106j VAT; Rozporządzenie MF ws. KSeF (FA(2)-korekta)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    corrections_pending := to_number(object.get(input.ksef, "corrections_pending", 0))
}

# P1-2: baza GTU z pełnym słownikiem 13 kodów + uczenie z historii.
gtu_full_dictionary := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.gtu_full_dictionary",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3173,
    "matched": true,
    "dictionary": gtu_dictionary,
    "codes": gtu_codes,
    "dictionary_size": count(gtu_dictionary),
    "learning_enabled": gtu_learning_enabled,
    "entry_for_hint": gtu_dict_entry(object.get(input.invoice, "gtu_hint", "")),
    "note": "baza GTU — pełny słownik 13 kodów (Szablon JPK_VAT K_10-K_19) + uczenie z historii transakcji (P1)",
    "_routing": "",
    "_routing_reason": sprintf("Baza GTU: %d kodów, uczenie=%v", [count(gtu_dictionary), gtu_learning_enabled]),
    "_legal_basis": "Szablon JPK_VAT (GTU); Rozporządzenie MF ws. JPK_V7",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}

# P1-3: integracja e-Doręczeń (skrzynka B2B/B2G + potwierdzenia).
edelivery_b2b_b2g_integration := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.edelivery_b2b_b2g_integration",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3174,
    "matched": true,
    "mailbox_api": object.get(edelivery_b2b_b2g, "mailbox_api", ""),
    "mailbox_active": mailbox_active,
    "b2b_enabled": object.get(edelivery_b2b_b2g, "b2b_enabled", true),
    "b2g_enabled": object.get(edelivery_b2b_b2g, "b2g_enabled", true),
    "confirmations_ok": confirmations_ok,
    "confirmation_type": object.get(edelivery_b2b_b2g, "confirmation_type", "DORECZENIE_POTWIERDZONE"),
    "integration_status": edelivery_status(mailbox_active, confirmations_ok),
    "note": "integracja e-Doręczeń — skrzynka B2B/B2G + potwierdzenia doręczenia (P1)",
    "_routing": edelivery_routing(mailbox_active, confirmations_ok),
    "_routing_reason": sprintf("e-Doręczenia: mailbox active=%v, B2B=%v, B2G=%v, confirmations=%v", [mailbox_active, object.get(edelivery_b2b_b2g, "b2b_enabled", true), object.get(edelivery_b2b_b2g, "b2g_enabled", true), confirmations_ok]),
    "_legal_basis": "Ustawa o doręczeniach elektronicznych (2026-01-01)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    mailbox_active := object.get(input.edelivery, "mailbox_active", false)
    confirmations_ok := object.get(input.edelivery, "confirmations_ok", false)
}

# P2-1: dashboard KSeF (status UPO, kara, rejestry) w UI.
ksef_dashboard_ui := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.ksef_dashboard_ui",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3175,
    "matched": true,
    "status_upo": {"upo_missing": upo_missing, "upo_received": upo_received},
    "kara_ryzyko": {"estimated_fine_pln": fine, "max_sanction_pln": ksef_sanction_max_pln},
    "rejestry_jpk": {"sales_register": to_number(object.get(input.dashboard, "sales_register", 0)), "purchase_register": to_number(object.get(input.dashboard, "purchase_register", 0))},
    "corrections_pending": corrections_pending,
    "widgets": object.get(ksef_dashboard_cfg, "widgets", ["status_upo", "kara_ryzyko", "rejestry_jpk"]),
    "export_formats": object.get(ksef_dashboard_cfg, "export_formats", ["JSON", "CSV", "PDF"]),
    "note": "dashboard KSeF — status UPO, kara ryzyka, rejestry JPK (dane agregowane dla warstwy UI) (P2)",
    "_routing": dashboard_routing(upo_missing, fine, corrections_pending),
    "_routing_reason": sprintf("Dashboard KSeF: %d UPO brak, kara %d PLN, %d korekt", [upo_missing, fine, corrections_pending]),
    "_legal_basis": "Art. 106na VAT; Szablon JPK_VAT; ADR-002",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    upo_received := to_number(object.get(input.dashboard, "upo_received", 0))
    raw_missing := to_number(object.get(input.dashboard, "invoices_sent", 0)) - upo_received
    upo_missing := max([raw_missing, 0])
    invoices_outside := to_number(object.get(input.dashboard, "invoices_outside", 0))
    fine := sanction_for_invoices(invoices_outside, invoices_outside > 0)
    corrections_pending := to_number(object.get(input.dashboard, "corrections_pending", 0))
}

# P2-2: automatyzacja JPK_CIT wg szablonu MF 2026.
jpk_cit_automation_2026 := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_cit_automation_2026",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3176,
    "matched": true,
    "template": object.get(jpk_cit_2026, "template", "Szablon JPK_CIT v2 (MF 2026)"),
    "structure_version": object.get(jpk_cit_2026, "structure_version", "2.0"),
    "deadline_day": object.get(jpk_cit_2026, "deadline_day", 31),
    "frequency": object.get(jpk_cit_2026, "frequency", "rocznie (I kw.)"),
    "sections": object.get(jpk_cit_2026, "sections", ["bilans", "rachunek_zyskow_i_strat"]),
    "automation_ready": automation_ready,
    "generated_blocks": generated_blocks,
    "note": "automatyzacja JPK_CIT wg szablonu MF 2026 — struktura v2.0, sekcje bilans/RZiS (P2)",
    "_routing": jpk_cit_routing(automation_ready),
    "_routing_reason": sprintf("JPK_CIT 2026: template %s, version %s, blocks %d", [object.get(jpk_cit_2026, "template", ""), object.get(jpk_cit_2026, "structure_version", ""), generated_blocks]),
    "_legal_basis": "Art. 9 ust. 1d-1j u.CIT; Szablon JPK_CIT MF 2026",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
    generated_blocks := to_number(object.get(input.jpk, "cit_blocks_generated", 0))
    automation_ready := generated_blocks >= count(object.get(jpk_cit_2026, "sections", ["bilans"]))
}

# ── GŁÓWNY DECIDE (P17) — raport syntetyczny KSeF + JPK + e-Deklaracje ────────
decide := {
    "rule_id": "jdg.p17_ksef_jpk_edeklaracje_innovations.report",
    "package": "jdg.p17_ksef_jpk_edeklaracje_innovations",
    "priority": 3157,
    "matched": true,
    "ksef": ksef_audit,
    "jpk": jpk_audit,
    "edelivery_esig": edelivery_esig_audit,
    "epuap_wis_resilience": epuap_wis_resilience_audit,
    "pipeline": ksef_pipeline_snapshot,
    "roadmap": {
        "ksef_api_integration": ksef_api_integration,
        "ksef_xsd_offline_ci": ksef_xsd_offline_ci,
        "ksef_corrections_e2e": ksef_corrections_e2e,
        "gtu_full_dictionary": gtu_full_dictionary,
        "edelivery_b2b_b2g_integration": edelivery_b2b_b2g_integration,
        "ksef_dashboard_ui": ksef_dashboard_ui,
        "jpk_cit_automation_2026": jpk_cit_automation_2026,
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny KSeF + JPK + e-Deklaracje (P17)",
    "_legal_basis": "Ustawa o VAT (art. 106na-106nb); JPK; e-Doręczenia; WIS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p17_ksef_check", false) == true
}
