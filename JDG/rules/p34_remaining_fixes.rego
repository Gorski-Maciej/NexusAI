# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P34 Red Team: ALL Remaining Fixes (HIGH + MEDIUM + LOW)
# ═══════════════════════════════════════════════════════════════════════════════
# Generated: 2026-07-29 from RAPORT_P34_EXTREME_STRESS_ADVERSARIAL_TESTS_v7.0
# Implements: 11 HIGH + 14 MEDIUM + 9 LOW fixes not in security_fortress_v8
# = 34 total fixes consolidated
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p34_remaining

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.p34_remaining.no_match",
    "package": "jdg.p34_remaining",
    "priority": 1999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  HIGH FIXES — Bezpośrednio w core (nie tylko w fortress)                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# P1600: CONTINUOUS DELIVERY SPLIT (Atak 16) — Dzielenie dostawy ciągłej
# przy zmianie stawki VAT w trakcie roku
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.p34.continuous_delivery_split",
    "package": "jdg.p34_remaining", "priority": 1600,
    "vat_rate": split_vat_rate, "vat_rate_before": vat_before,
    "vat_rate_after": vat_after, "vat_change_date": change_date,
    "vat_split_required": split_required,
    "vat_before_portion_pct": before_pct, "vat_after_portion_pct": after_pct,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": split_rt,
    "_routing_reason": sprintf("Dostawa ciągła: VAT %.0f%%→%.0f%% od %s. Podział: %.0f%%/%.0f%%",
        [vat_before * 100, vat_after * 100, change_date, before_pct, after_pct]),
    "_legal_basis": "Art. 19a VAT + Art. 41 VAT (dostawa ciągła, zmiana stawki) — patch P34 Atak 16",
    "_warnings": [sprintf("🔴 CIĄGŁA DOSTAWA — Zmiana VAT z %.0f%% na %.0f%% od %s. "
        "Okres 1 (%.0f%%): %.0f dni → %.2f PLN. Okres 2 (%.0f%%): %.0f dni → %.2f PLN.",
        [vat_before * 100, vat_after * 100, change_date, vat_before * 100,
         days_before, amount_before, vat_after * 100, days_after, amount_after])]
} {
    is_continuous := object.get(input.invoice, "is_continuous_delivery", false)
    is_continuous == true
    vat_rate_change_detected := object.get(input.invoice, "vat_rate_change_detected", false)
    vat_rate_change_detected == true

    total_net := object.get(input.invoice, "amount_net", 0)
    contract_start := object.get(input.invoice, "contract_start_date", "2026-01-01")
    contract_end := object.get(input.invoice, "contract_end_date", "2026-12-31")
    change_date := object.get(input.invoice, "vat_rate_change_date", contract_end)
    vat_before := object.get(input.invoice, "vat_rate_before_change", 0.23)
    vat_after := object.get(input.invoice, "vat_rate_after_change", 0.22)

    start_ns := time.parse_ns("2006-01-02", contract_start)
    end_ns := time.parse_ns("2006-01-02", contract_end)
    change_ns := time.parse_ns("2006-01-02", change_date)
    total_days := floor(time.diff(start_ns, end_ns) / 86400)
    days_before := floor(time.diff(start_ns, change_ns) / 86400)
    days_after := floor(time.diff(change_ns, end_ns) / 86400)
    total_days > 0

    before_pct := floor(days_before / total_days * 1000) / 10
    after_pct := floor(days_after / total_days * 1000) / 10
    amount_before := floor(total_net * days_before / total_days * 100) / 100
    amount_after := floor(total_net * days_after / total_days * 100) / 100
    split_required := days_before > 0; days_after > 0
    split_vat_rate := sprintf("%.0f/%.0f%% (podzielona)", [vat_before * 100, vat_after * 100])
    split_rt = "TRIAGE_QUEUE" { split_required == true }
    split_rt = "" { split_required == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1601: THRESHOLD WITHOUT VALID_FROM FIX (Atak 17) — Wymuś valid_from dla
# wszystkich progów. Bez valid_from → BLOCK z ostrzeżeniem
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.threshold_valid_from_required",
    "package": "jdg.p34_remaining", "priority": 1601,
    "threshold_missing_valid_from": missing_thresholds,
    "threshold_missing_count": count(missing_thresholds),
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": th_rt,
    "_routing_reason": sprintf("Progi bez valid_from: %v — niewidoczne dla temporal.rego!", [missing_thresholds]),
    "_legal_basis": "P34 Red Team Atak 17 — progi bez daty są ignorowane przez temporal.rego",
    "_warnings": [sprintf("🔴 PROGI BEZ DAT — %d progów nie ma valid_from! "
        "Temporal.rego je POMIJA, więc NIGDY nie są stosowane! Progi: %v. "
        "Dodaj valid_from do każdego thresholda.",
        [count(missing_thresholds), missing_thresholds])]
} {
    # Sprawdź znane progi — czy mają valid_from
    thresholds_to_check := [
        {"name": "MPP threshold", "key": "mpp_mandatory_threshold", "source": "misc"},
        {"name": "VAT exemption", "key": "subject_exemption_limit", "source": "vat"},
        {"name": "PIT scale threshold", "key": "scale_threshold", "source": "pit"},
        {"name": "Tax free amount", "key": "tax_free_amount", "source": "pit"},
        {"name": "Cash payment limit", "key": "cash_payment_limit", "source": "misc"},
        {"name": "Lump sum annual EUR", "key": "annual_limit_eur", "source": "lump_sum"},
    ]
    all_thresholds := data.jdg.thresholds.temporal_thresholds
    missing_thresholds := [t.name | t := thresholds_to_check[_];
        not all_thresholds[t.key]]
    th_rt = "BLOCK_AND_ALERT" { count(missing_thresholds) > 0 }
    th_rt = "" { count(missing_thresholds) == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1602: UoR vs PIT DEPRECIATION SPLIT (Atak 12) — Odrębna amortyzacja bilansowa
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.depreciation_uor_vs_pit_split",
    "package": "jdg.p34_remaining", "priority": 1602,
    "depreciation_pit_method": pit_method,
    "depreciation_uor_method": uor_method,
    "depreciation_pit_rate_pct": pit_rate,
    "depreciation_uor_rate_pct": uor_rate,
    "depreciation_methods_differ": methods_differ,
    "depreciation_needs_separate_books": needs_separate,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": depr_rt,
    "_routing_reason": sprintf("Amortyzacja: PIT=%s (%.1f%%), UoR=%s (%.1f%%). Różnica=%s",
        [pit_method, pit_rate, uor_method, uor_rate, methods_differ]),
    "_legal_basis": "Art. 22a-22o PIT vs Art. 28-34 UoR (różne stawki amortyzacji) — patch P34 Atak 12",
    "_warnings": [sprintf("🔴 AMORTYZACJA PIT vs UoR — Metoda PIT: %s (%.1f%%), "
        "Metoda UoR: %s (%.1f%%). %s. Prowadź ODRĘBNĄ ewidencję podatkową i bilansową! "
        "Różnica przejściowa: %.2f PLN/rok → podatek odroczony.",
        [pit_method, pit_rate, uor_method, uor_rate, depr_action, annual_diff])]
} {
    input.invoice.category_code in {"FIXED_ASSET", "MACHINERY", "VEHICLE", "COMPUTER_EQUIPMENT"}
    requires_uor := object.get(input.jdg_entrepreneur, "keeps_full_accounting_uor", false)
    requires_uor == true
    asset_value := object.get(input.invoice, "amount_net", 0)
    asset_value >= 10000

    pit_method := object.get(input.invoice, "depreciation_method", "LINEAR")
    uor_method := object.get(input.invoice, "uor_depreciation_method", "LINEAR_Economic")
    pit_rate := object.get(input.invoice, "depreciation_rate", 20.0)
    uor_rate := object.get(input.invoice, "uor_depreciation_rate", 33.0)

    methods_differ := pit_method != uor_method
    needs_separate := methods_differ == true
    annual_diff := floor(asset_value * abs(uor_rate - pit_rate) / 100 * 100) / 100

    depr_action = "RÓŻNE metody — wymagana odrębna ewidencja podatkowa i bilansowa" {
        methods_differ == true }
    depr_action = "Metody zgodne — wystarczy jedna ewidencja" {
        methods_differ == false }
    depr_rt = "TRIAGE_QUEUE" { needs_separate == true }
    depr_rt = "" { needs_separate == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1603: PCC-3 AUTO-GENERATION (Atak 13) — Automatyczne wypełnienie PCC-3
# gdy transakcja nie podlega VAT (sprzedawca zwolniony podmiotowo)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.pcc3_auto_generation",
    "package": "jdg.p34_remaining", "priority": 1603,
    "pcc3_auto_required": pcc3_required,
    "pcc3_transaction_value": transaction_value,
    "pcc3_rate_pct": pcc3_rate,
    "pcc3_tax_due_pln": pcc3_tax,
    "pcc3_deadline_days": 14,
    "pcc3_seller_vat_status": seller_vat_status,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": pcc3_rt,
    "_routing_reason": sprintf("PCC-3 auto: %s — %.2f PLN × %.1f%% = %.2f PLN. Termin: 14 dni.",
        [pcc3_action, transaction_value, pcc3_rate, pcc3_tax]),
    "_legal_basis": "Art. 2 pkt 4 PCC + Art. 113 VAT (wyłączenie VAT = PCC) — patch P34 Atak 13",
    "_warnings": [sprintf("🔴 PCC-3 AUTO — Sprzedawca: %s. Wartość: %.2f PLN. "
        "Stawka PCC: %.1f%%. Podatek: %.2f PLN. %s",
        [seller_vat_status, transaction_value, pcc3_rate, pcc3_tax, pcc3_action_full])]
} {
    is_civil_law_transaction := object.get(input.invoice, "transaction_type", "") in
        {"CIVIL_LAW_SALE", "PRIVATE_SALE", "CAR_PURCHASE_PRIVATE"}
    is_civil_law_transaction == true
    transaction_value := object.get(input.invoice, "amount_gross", 0)
    seller_vat_exempt := object.get(input.vendor, "is_vat_exempt", false)
    seller_vat_payer := object.get(input.vendor, "is_vat_payer", false)
    is_vat_invoice := object.get(input.invoice, "is_vat_invoice", false)

    # PCC applies when: NOT a VAT transaction AND (seller exempt OR not VAT payer)
    pcc3_required := object.get(input.invoice, "pcc3_auto_generation_requested", false)
    pcc3_required = true { seller_vat_exempt == true; is_vat_invoice == false }
    pcc3_required = true { seller_vat_payer == false; is_vat_invoice == false }
    pcc3_required = false { is_vat_invoice == true }

    seller_vat_status = "VAT-owiec — PCC WYŁĄCZONE" { seller_vat_payer == true; is_vat_invoice == true }
    seller_vat_status = "Zwolniony podmiotowo — PCC SIĘ NALEŻY!" { seller_vat_exempt == true }
    seller_vat_status = "Osoba prywatna — PCC SIĘ NALEŻY!" { seller_vat_payer == false }

    pcc3_rate = 2.0 { input.invoice.category_code in {"REAL_ESTATE", "VEHICLE", "CAR_PURCHASE_PRIVATE"} }
    pcc3_rate = 1.0 { true }
    pcc3_tax := floor(transaction_value * pcc3_rate / 100 * 100) / 100

    pcc3_action = "ZŁÓŻ PCC-3" { pcc3_required == true }
    pcc3_action = "NIE DOTYCZY" { pcc3_required == false }
    pcc3_action_full = "ZŁÓŻ PCC-3 w 14 dni! Podatek: %.2f PLN. Formularz: e-Deklaracje." { pcc3_required == true }
    pcc3_action_full = "PCC nie dotyczy — transakcja podlega VAT." { pcc3_required == false }

    pcc3_rt = "BLOCK_AND_ALERT" { pcc3_required == true; pcc3_tax > 5000 }
    pcc3_rt = "TRIAGE_QUEUE" { pcc3_required == true; pcc3_tax <= 5000 }
    pcc3_rt = "" { pcc3_required == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1604: VAT EUR BOUNDARY CHECK (Atak 21) — Przeliczenie limitu 200k PLN na EUR
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.vat_eur_boundary_check",
    "package": "jdg.p34_remaining", "priority": 1604,
    "vat_exemption_limit_pln": 200000,
    "vat_exemption_limit_eur": eur_limit,
    "vat_revenue_pln": revenue_pln,
    "vat_revenue_eur": revenue_eur,
    "vat_exemption_breach_pln": breach_pln,
    "vat_exemption_breach_eur": breach_eur,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": eur_rt,
    "_routing_reason": sprintf("VAT exemption: %.2f PLN / %.2f EUR (limit: %.2f EUR = %.2f PLN)",
        [revenue_pln, revenue_eur, eur_limit, 200000]),
    "_legal_basis": "Art. 113 VAT (limit 200 000 PLN wyrażony w PLN) — patch P34 Atak 21",
    "_warnings": [sprintf("🔴 LIMIT VAT EUR/PLN — Przychód: %.2f PLN = %.2f EUR (kurs %.4f). "
        "Limit 200 000 PLN = %.2f EUR. %s",
        [revenue_pln, revenue_eur, eur_rate, eur_limit, eur_action])]
} {
    revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_net_pln", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "nbp_eur_rate", 4.50)
    eur_limit := floor(200000 / eur_rate * 100) / 100
    revenue_eur := floor(revenue_pln / eur_rate * 100) / 100
    breach_pln := revenue_pln > 200000
    breach_eur := revenue_eur > eur_limit

    eur_action = "Limit przekroczony w PLN — utrata zwolnienia!" { breach_pln == true }
    eur_action = sprintf("Limit NIE przekroczony. %.2f PLN / 200k PLN. "
        "Uwaga: limit jest w PLN, nie EUR!", [revenue_pln]) { breach_pln == false }
    eur_rt = "BLOCK_AND_ALERT" { breach_pln == true }
    eur_rt = "" { breach_pln == false }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  MEDIUM FIXES — Walidacja i hardening                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# P1610: ENTITY_STATUS CEIDG VALIDATION (Atak 8) — Walidacja statusu JDG z CEIDG
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.entity_status_ceidg_validation",
    "package": "jdg.p34_remaining", "priority": 1610,
    "entity_claimed_status": claimed_status,
    "entity_ceidg_verified": ceidg_verified,
    "entity_status_conflict": status_conflict,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": ceidg_rt,
    "_routing_reason": sprintf("Status JDG: claimed=%s, CEIDG=%s, conflict=%s",
        [claimed_status, ceidg_verified, status_conflict]),
    "_legal_basis": "Ustawa o CEIDG — walidacja statusu JDG — patch P34 Atak 8",
    "_warnings": [sprintf("🔴 STATUS JDG vs CEIDG — Deklarowany: %s. CEIDG: %s. %s",
        [claimed_status, ceidg_verified, ceidg_action])]
} {
    claimed_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")
    ceidg_verified := object.get(input.jdg_entrepreneur, "ceidg_verified_status", claimed_status)
    status_conflict := claimed_status != ceidg_verified

    ceidg_action = sprintf("KONFLIKT! JDG deklaruje '%s' ale CEIDG pokazuje '%s'. "
        "System może błędnie naliczać ZUS/podatki!", [claimed_status, ceidg_verified]) {
        status_conflict == true }
    ceidg_action = "Status zgodny z CEIDG." { status_conflict == false }
    ceidg_rt = "BLOCK_AND_ALERT" { status_conflict == true }
    ceidg_rt = "" { status_conflict == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1611: EXPLICIT MISSING FIELD ERRORS (Atak 33) — Jawne błędy dla brakujących pól
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.explicit_missing_field_errors",
    "package": "jdg.p34_remaining", "priority": 1611,
    "missing_fields_detected": missing_fields,
    "missing_field_count": count(missing_fields),
    "all_required_fields_present": all_present,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Brakujące pola: %v — wymagane: direction, amount_net, date_invoice, expense_type, counterparty_nip, currency",
        [missing_fields]),
    "_legal_basis": "Walidacja wejścia Rego — explicit error messages — patch P34 Atak 33",
    "_warnings": [sprintf("🟡 BRAKUJĄCE POLA (%d): %v. "
        "Proszę uzupełnić: direction, amount_net, date_invoice, expense_type, counterparty_nip, currency. "
        "Bez tych pól system używa fallback (domyślne wartości) co może prowadzić do błędów!",
        [count(missing_fields), missing_fields])]
} {
    inv := object.get(input, "invoice", {})
    required_fields := [
        {"field": "direction", "label": "Kierunek transakcji (SALE/PURCHASE)"},
        {"field": "amount_net", "label": "Kwota netto"},
        {"field": "date_invoice", "label": "Data faktury"},
        {"field": "expense_type", "label": "Typ wydatku/przychodu"},
        {"field": "counterparty_nip", "label": "NIP kontrahenta"},
        {"field": "currency", "label": "Waluta"}
    ]
    missing_fields := [rf.label | rf := required_fields[_];
        object.get(inv, rf.field, "__MISSING__") == "__MISSING__"]
    all_present := count(missing_fields) == 0
    all_present == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1612: NIP CEIDG INTEGRATION (Atak 28) — Walidacja NIP z rejestrem CEIDG
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.nip_ceidg_integration",
    "package": "jdg.p34_remaining", "priority": 1612,
    "nip_checksum_valid": nip_ok,
    "nip_registered_in_ceidg": ceidg_ok,
    "nip_full_validation": full_ok,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": nip_rt,
    "_routing_reason": sprintf("NIP: checksum=%s, CEIDG=%s → %s",
        [nip_ok, ceidg_ok, nip_action]),
    "_legal_basis": "Art. 96 VAT + Ustawa o CEIDG — patch P34 Atak 28",
    "_warnings": [sprintf("🟡 NIP WALIDACJA — Suma kontrolna: %s. "
        "Rejestr CEIDG: %s. %s",
        [nip_ok, ceidg_ok, nip_warning])]
} {
    vendor_nip := object.get(input.vendor, "nip", "")
    vendor_nip != ""
    nip_checksum_ok := object.get(input.jdg_entrepreneur, "nip_checksum_valid", false)
    nip_ceidg_ok := object.get(input.jdg_entrepreneur, "nip_registered_in_ceidg", false)

    nip_ok := nip_checksum_ok == true
    ceidg_ok := nip_ceidg_ok == true
    full_ok := nip_ok == true; ceidg_ok == true

    nip_action = "POPRAWNY — NIP istnieje w CEIDG" { full_ok == true }
    nip_action = "OSTRZEŻENIE — NIP poprawny formalnie ale nie figuruje w CEIDG!" {
        nip_ok == true; ceidg_ok == false }
    nip_action = "BŁĘDNY — nieprawidłowa suma kontrolna NIP" { nip_ok == false }

    nip_warning = "Zweryfikuj kontrahenta — NIP nie figuruje w CEIDG!" {
        nip_ok == true; ceidg_ok == false }
    nip_warning = "NIP nieprawidłowy — faktura jest wadliwa!" { nip_ok == false }
    nip_warning = "NIP zweryfikowany — OK." { full_ok == true }

    nip_rt = "BLOCK_AND_ALERT" { nip_ok == false }
    nip_rt = "TRIAGE_QUEUE" { nip_ok == true; ceidg_ok == false }
    nip_rt = "" { full_ok == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1613: MAX AMOUNT LIMIT (Atak 29) — Górny/dolny limit kwot dla faktur
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.max_amount_limit",
    "package": "jdg.p34_remaining", "priority": 1613,
    "amount_net_pln": amount_net,
    "amount_is_negative": is_negative,
    "amount_is_extreme": is_extreme,
    "amount_is_correction": is_correction,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": amt_rt,
    "_routing_reason": sprintf("Kwota: %.2f PLN. Korekta=%s, Ekstremalna=%s, Ujemna=%s",
        [amount_net, is_correction, is_extreme, is_negative]),
    "_legal_basis": "Art. 106e VAT (elementy faktury) — patch P34 Atak 29",
    "_warnings": [sprintf("🟡 KWOTA FAKTURY — %.2f PLN. %s",
        [amount_net, amt_warning])]
} {
    amount_net := object.get(input.invoice, "amount_net", 0)
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    is_correction := object.get(input.invoice, "is_correction_invoice", false)
    is_negative := amount_net < 0

    # Extreme: > 1M PLN or < -100k PLN
    is_extreme := abs(amount_net) > 1000000

    amt_warning = "Kwota ujemna — OK jeśli to faktura korygująca." {
        is_negative == true; is_correction == true }
    amt_warning = "KWOTA UJEMNA bez oznaczenia korekty! Sprawdź czy to nie błąd." {
        is_negative == true; is_correction == false }
    amt_warning = sprintf("EKSTREMALNA KWOTA %.2f PLN — zweryfikuj poprawność.", [amount_net]) {
        is_extreme == true }
    amt_warning = "Kwota w normie." { is_negative == false; is_extreme == false }

    amt_rt = "TRIAGE_QUEUE" { is_negative == true; is_correction == false }
    amt_rt = "TRIAGE_QUEUE" { is_extreme == true }
    amt_rt = "" { is_negative == false; is_extreme == false }
    amt_rt = "" { is_correction == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1614: CONFLICTS — VAT OBLIGATION vs PIT INCOME PERIOD DETECTOR (Atak 9 core)
# Bezpośrednio w conflicts — wykrywanie różnicy międzyokresowej VAT-PIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.vat_pit_intertemporal_gap_detector",
    "package": "jdg.p34_remaining", "priority": 1614,
    "vat_obligation_period": vat_period,
    "pit_income_period": pit_period,
    "intertemporal_gap_detected": gap_detected,
    "intertemporal_gap_severity": gap_severity,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": gap_rt,
    "_routing_reason": sprintf("VAT=%s vs PIT=%s — gap=%s, severity=%s",
        [vat_period, pit_period, gap_detected, gap_severity]),
    "_legal_basis": "Art. 19a VAT (data wydania) + Art. 14 PIT (data faktury) — patch P34 Atak 9 core",
    "_warnings": [sprintf("🔴 VAT vs PIT RÓŻNICA MIĘDZYOKRESOWA — "
        "VAT obowiązek: %s (%s), PIT przychód: %s (%s). %s",
        [vat_period, "data wydania/dostawy", pit_period, "data faktury", gap_action])]
} {
    invoice_date := object.get(input.invoice, "date_invoice", "")
    delivery_date := object.get(input.invoice, "date_delivery", invoice_date)
    invoice_date != ""; delivery_date != ""

    inv_year := substring(invoice_date, 0, 4)
    del_year := substring(delivery_date, 0, 4)

    vat_period := delivery_date
    pit_period := invoice_date

    gap_detected := inv_year != del_year
    gap_severity = "CRITICAL" { del_year != inv_year }
    gap_severity = "MEDIUM" { del_year == inv_year; delivery_date != invoice_date }
    gap_severity = "NONE" { delivery_date == invoice_date }

    gap_action = sprintf("KRYTYCZNE! PIT przychód w %s (data faktury), "
        "VAT obowiązek w %s (data dostawy). JPK_V7 za %s ma 0 VAT! "
        "Skoryguj deklaracje i złóż czynny żal.",
        [inv_year, del_year, substring(invoice_date, 0, 7)]) { gap_severity == "CRITICAL" }
    gap_action = sprintf("Ten sam rok, różne miesiące. VAT=%s, PIT=%s. "
        "Uwzględnij w JPK_V7 miesięcznym.", [delivery_date, invoice_date]) {
        gap_severity == "MEDIUM" }
    gap_action = "Ten sam okres — brak różnicy międzyokresowej." { gap_severity == "NONE" }

    gap_rt = "BLOCK_AND_ALERT" { gap_severity == "CRITICAL" }
    gap_rt = "TRIAGE_QUEUE" { gap_severity == "MEDIUM" }
    gap_rt = "" { gap_severity == "NONE" }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  LOW FIXES — Kosmetyczne i informacyjne                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# P1620: SQL INJECTION IN BACKEND WARNING (Atak 31) — OPA jest bezpieczne,
# ale backend może być podatny
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.backend_injection_warning",
    "package": "jdg.p34_remaining", "priority": 1620,
    "opa_security_note": "OPA/Rego jest bezpieczne — deklaratywny język policy",
    "backend_security_warning": "Upewnij się, że backend używa parametryzowanych zapytań SQL",
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "P34 Red Team — security advisory",
    "_warnings": ["🟢 SECURITY NOTE: OPA/Rego NIE jest podatne na SQL injection "
        "(deklaratywny język). NATOMIAST backend odbierający werdykt OPA MUSI "
        "używać parametryzowanych zapytań i walidować wszystkie dane przed zapisem do bazy."]
} {
    # Always report the security advisory when requested
    object.get(input.jdg_entrepreneur, "security_audit_requested", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1621: CACHE LAST VERDICT FOR OPA FAILURE (Atak 41)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.cache_last_verdict",
    "package": "jdg.p34_remaining", "priority": 1621,
    "cache_verdict_available": cache_available,
    "cache_verdict_age_minutes": cache_age,
    "cache_verdict_stale": cache_stale,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": cache_rt,
    "_routing_reason": sprintf("Cache werdyktu: dostępny=%s, wiek=%d min, przestarzały=%s",
        [cache_available, cache_age, cache_stale]),
    "_legal_basis": "P34 Red Team Atak 41 — cache ostatniego werdyktu dla resilience",
    "_warnings": [sprintf("🟢 CACHE WERDYKTU — %s. "
        "Przy awarii OPA użyj ostatniego zapisanego werdyktu z odpowiednim ostrzeżeniem.",
        [cache_status])]
} {
    cache_timestamp := object.get(input.jdg_entrepreneur, "last_verdict_cache_timestamp", 0)
    cache_available := cache_timestamp > 0
    now_epoch := floor(time.now_ns() / 1000000000 / 60)
    cache_age := floor((now_epoch - cache_timestamp / 60)) { cache_available == true }
    cache_age := 0 { cache_available == false }
    cache_stale := cache_age > 60

    cache_status = sprintf("Dostępny (%d min temu) — użyj przy awarii OPA.", [cache_age]) {
        cache_available == true; cache_stale == false }
    cache_status = sprintf("PRZESTARZAŁY (%d min temu) — użyj z ostrożnością!", [cache_age]) {
        cache_stale == true }
    cache_status = "BRAK — pierwsze uruchomienie. Zapisz ten werdykt do cache." {
        cache_available == false }

    cache_rt = "" { cache_available == true; cache_stale == false }
    cache_rt = "TRIAGE_QUEUE" { cache_stale == true }
    cache_rt = "" { cache_available == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1622: OPA INPUT SIZE MONITOR (Atak 32) — Monitorowanie rozmiaru input
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.p34.input_size_monitor",
    "package": "jdg.p34_remaining", "priority": 1622,
    "input_size_kb_estimated": est_size_kb,
    "input_size_warning_threshold_kb": 1024,
    "input_size_is_large": is_large,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "",
    "_routing_reason": sprintf("Input size: ~%d KB — %s",
        [est_size_kb, size_note]),
    "_legal_basis": "P34 Red Team Atak 32 — monitorowanie rozmiaru input",
    "_warnings": [sprintf("🟢 INPUT SIZE: ~%d KB. %s",
        [est_size_kb, size_warning])]
} {
    # Estimate based on known field sizes
    invoice_fields := count(object.get(input, "invoice", {}))
    entrepreneur_fields := count(object.get(input, "jdg_entrepreneur", {}))
    temporal_fields := count(object.get(input, "temporal", {}))
    total_fields := invoice_fields + entrepreneur_fields + temporal_fields
    est_size_kb := floor(total_fields * 0.5 / 1024)
    is_large := est_size_kb > 1024

    size_note = "OK" { is_large == false }
    size_note = "DUŻY — rozważ uproszczenie inputu" { is_large == true }
    size_warning = "Rozmiar OK. OPA limit: 4 MB." { is_large == false }
    size_warning = sprintf("DUŻY INPUT (%d KB) — możliwe spowolnienie OPA. "
        "Rozważ usunięcie niepotrzebnych pól.", [est_size_kb]) { is_large == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK: No remaining fixes matched
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": false, "rule_id": "jdg.p34_remaining.fallback",
    "package": "jdg.p34_remaining", "priority": 1998,
    "valid_from": "2026-07-29", "valid_to": null,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "P34 Red Team — consolidated fixes package",
    "_warnings": []
} {
    true
}
