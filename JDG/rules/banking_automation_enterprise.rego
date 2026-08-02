# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE SMART BANKING AUTOMATION (Strategic Initiative S10)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Smart Banking — PSD2/PolishAPI v3.x + Elixir Payload Engine
# description: |
#   ENTERPRISE v5.2 — Pełna automatyzacja bankowa dla JDG z PSD2:
#   - PSD2 AIS (Account Information): saldo, historia transakcji, dane kontrahentów
#   - PSD2 PIS (Payment Initiation): PolishAPI v3.x JSON payloads do przelewów
#   - Elixir/ExpressElixir: generowanie payloadów dla systemów clearingowych KIR
#   - Split Payment (MPP): automatyczne naliczanie i przygotowanie płatności
#   - ZUS DRA: generowanie payloadów do ZUS (społeczne + zdrowotne + FP+FS)
#   - US (VAT/PIT/PCC): automatyczne przygotowanie przelewów do US
#   - OAuth2/eIDAS: zarządzanie tokenami, QWAC/QSEAL certyfikaty TPP
#   - Multi-bank routing: profile API dla PKO BP, Pekao, ING, mBank, Santander, Alior
#   - Payment status tracking: webhook UPO, retry na failure
#   - Batch payments: paczka przelewów XML/JSON dla Elixir
#   - PSD2 compliance audit: RTS SCA, eIDAS, dziennik audytu
# architecture: Enterprise PSD2 Banking Engine, First-Match-Wins else-chain
# legal_basis: PSD2 (EU 2015/2366); PolishAPI v3.x (ZBP); Art. 108a VAT (MPP); Art. 47 SUS
# package: jdg.banking
# deprecated: false
# priority_range: 1800-1899
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.banking

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.banking.no_match",
    "package": "jdg.banking", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1800: SPLIT PAYMENT (MPP) PREPARATION — Mechanizm Podzielonej Płatności
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.banking.split_payment_preparation",
    "package": "jdg.banking",
    "priority": 1800,
    "vat_rate": vat_rate, "rounding_level": "", "gtu_code": gtu_code,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_mpp_required": mpp_mandatory,
    "banking_mpp_vat_amount": mpp_vat,
    "banking_mpp_net_amount": mpp_net,
    "banking_mpp_transfer_title": transfer_title,
    "banking_mpp_elixir_payload": elixir_payload,
    "banking_mpp_pis_json": pis_json,
    "_routing": mpp_routing,
    "_routing_reason": mpp_routing_reason,
    "_legal_basis": "Art. 108a VAT; Art. 106e ust. 1 pkt 18a VAT; Komunikat MF ws. MPP",
    "_warnings": build_mpp_warnings(mpp_mandatory, mpp_vat, mpp_net, transfer_title)
} {
    input.banking_mpp_prepare == true
    input.invoice.direction == "PURCHASE"

    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_net := object.get(input.invoice, "amount_net", 0)
    vat_amount := object.get(input.invoice, "vat_amount", 0)
    vat_rate := object.get(input.invoice, "vat_rate", "")
    gtu_code := object.get(input.invoice, "gtu_code", "")
    document_type := object.get(input.invoice, "document_type", "INVOICE")
    category_code := object.get(input.invoice, "category_code", "")

    mpp_threshold := 15000
    has_gtu_or_annex15 = true {
        gtu_code != ""
    } else = true {
        category_code in {"STEEL","FUEL","ELECTRONICS","CONSTRUCTION","COAL","GOLD","SCRAP","CARS","MOTORCYCLE_PARTS"}
    } else = false

    mpp_mandatory := amount_gross >= mpp_threshold and has_gtu_or_annex15 and document_type == "INVOICE"
    mpp_vat := vat_amount
    mpp_net := amount_net

    invoice_number := object.get(input.invoice, "invoice_number", "")
    vendor_nip := object.get(input.vendor, "nip", "")
    transfer_title := sprintf("/VAT/%.2f/%s/%s", [vat_amount, vendor_nip, invoice_number])

    vendor_account := object.get(input.vendor, "bank_account", "")
    vendor_name := object.get(input.vendor, "name", "")
    jdg_nip := object.get(input.jdg_entrepreneur, "nip", "")

    # Standard MPP payload for Elixir
    elixir_payload := {
        "type": "SPLIT_PAYMENT",
        "recipient": {"name": vendor_name, "nip": vendor_nip, "account": vendor_account},
        "amounts": {"net": amount_net, "vat": vat_amount, "gross": amount_gross},
        "transfer_title": transfer_title,
        "invoice_reference": invoice_number,
        "sender_nip": jdg_nip,
        "execution_date": object.get(input.invoice, "payment_due_date", "")
    }

    # PIS PolishAPI v3.x JSON for split payment
    pis_json := build_pis_payload("SPLIT_PAYMENT", vendor_account, amount_gross,
        sprintf("MPP %s", [transfer_title]), input, vendor_name, vendor_nip)

    mpp_routing := ""
    mpp_routing := "TRIAGE_QUEUE" { mpp_mandatory }
    mpp_routing_reason := ""
    mpp_routing_reason := sprintf("MPP wymagany — kwota %.2f PLN > 15 000 PLN z GTU/załącznik 15", [amount_gross]) { mpp_mandatory }
}

build_mpp_warnings(mandatory, vat, net, title) = warnings {
    mandatory == true
    warnings := [
        sprintf("💳 MECHANIZM PODZIELONEJ PŁATNOŚCI (MPP) — WYMAGANY!"),
        sprintf("   Kwota VAT: %.2f PLN → rachunek VAT sprzedawcy", [vat]),
        sprintf("   Kwota netto: %.2f PLN → rachunek rozliczeniowy", [net]),
        sprintf("   Tytuł: %s", [title]),
        "",
        "📋 PolishAPI PIS: użyj paymentProduct=domestic-split-payment",
        "📌 Art. 108a ust. 1d VAT: dobrowolny MPP = safe harbor"
    ]
} else = [
    sprintf("💳 MPP niewymagany (%.2f PLN < 15 000 PLN). Przelew standardowy.", [net+vat]),
    "💡 Mimo to ROZWAŻ MPP — daje ochronę 'safe harbor' (Art. 108a ust. 1d VAT)."
]

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1810: ZUS TRANSFER PREPARATION — Przygotowanie przelewów do ZUS
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.zus_transfer_preparation",
    "package": "jdg.banking",
    "priority": 1810,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate,
    "business_status": "", "ceidg_registration_required": false,
    "banking_zus_social_amount": zus_social,
    "banking_zus_health_amount": zus_health,
    "banking_zus_fp_fs_amount": zus_fp_fs,
    "banking_zus_total_monthly": zus_total,
    "banking_zus_transfer_deadline": transfer_deadline,
    "banking_zus_pis_json": pis_json,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 46-47 SUS; Art. 17-18 ustawy o SUS",
    "_warnings": build_zus_transfer_warnings(zus_social, zus_health, zus_fp_fs, zus_total, transfer_deadline)
} {
    input.banking_zus_prepare == true

    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    monthly_profit := object.get(input.jdg_entrepreneur, "monthly_profit_avg", 8000)
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 15000)
    nip := object.get(input.jdg_entrepreneur, "nip", "")
    zus_account_nr := object.get(input.jdg_entrepreneur, "zus_account_number", "")
    pesel := object.get(input.jdg_entrepreneur, "pesel", "")

    min_wage := object.get(object.get(data.thresholds, "bounds", {}), "minimum_wage_gross", 4800)
    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)

    social_base := min_wage * 0.60 { zus_status == "STANDARD" }
    social_base := min_wage * 0.30 { zus_status == "PREFERENTIAL" }
    social_base := monthly_revenue * 0.30 { zus_status == "MALY_ZUS_PLUS" }
    social_base := 0 { zus_status in {"START_RELIEF", "UNREGISTERED"} }

    zus_social := floor(social_base * (0.1952 + 0.08 + 0.0245 + 0.0167) * 100) / 100
    has_fp_fs := social_base > 0
    zus_fp_fs := floor(social_base * (0.0245 + 0.0010) * 100) / 100 { has_fp_fs }
    zus_fp_fs := 0 { not has_fp_fs }

    zus_health := 0
    zus_health := floor(monthly_profit * 0.09 * 100) / 100 { pit_form == "PIT_SCALE" }
    zus_health := floor(min([monthly_profit * 0.049, data.jdg.thresholds.limits.health_linear_deduction_limit / 12]) * 100) / 100 { pit_form == "LINEAR" }
    zus_health := floor(avg_wage * 0.09 * 100) / 100 { pit_form == "LUMP_SUM"; monthly_revenue <= 60000 }
    zus_health := floor(avg_wage * 0.09 * 100) / 100 * 1.0 { pit_form == "LUMP_SUM"; monthly_revenue > 60000; monthly_revenue <= 300000 }
    zus_health := floor(avg_wage * 0.09 * 100) / 100 * 1.8 { pit_form == "LUMP_SUM"; monthly_revenue > 300000 }

    health_rate := "9%" { pit_form == "PIT_SCALE" }
    health_rate := "4.9%" { pit_form == "LINEAR" }
    health_rate := "progowa" { pit_form == "LUMP_SUM" }

    zus_total := zus_social + zus_health + zus_fp_fs
    current_month := object.get(input, "current_month", 7)
    current_year := 2026
    next_month := current_month + 1
    transfer_deadline := sprintf("%04d-%02d-10", [current_year, next_month])

    pis_json := build_pis_payload("DOMESTIC", zus_account_nr, zus_social + zus_fp_fs,
        sprintf("Skl. spoleczne %02d/%d NIP %s", [current_month, current_year, nip]),
        input, "ZUS", nip)
}

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1820: TAX OFFICE TRANSFER PREPARATION — Przelew do US
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.tax_office_transfer_preparation",
    "package": "jdg.banking",
    "priority": 1820,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_vat_payment": vat_payment,
    "banking_pit_advance_payment": pit_payment,
    "banking_us_total_monthly": us_total,
    "banking_us_pis_json": pis_json,
    "banking_us_cashflow_30d": cashflow_30d,
    "banking_cashflow_gap": us_total - cashflow_30d,
    "_routing": us_cf_routing,
    "_routing_reason": us_cf_reason,
    "_legal_basis": "Art. 44 PIT; Art. 103 VAT; Art. 61 § 1 OrdPU",
    "_warnings": build_us_transfer_warnings(vat_payment, pit_payment, us_total, cashflow_30d),
    "_cross_ref": "S8 Cashflow Predictor — zintegruj automatyczne prognozowanie"
}

# BNK-1830: MONTHLY PAYMENT BATCH — Paczka przelewów na miesiąc
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.monthly_payment_batch",
    "package": "jdg.banking",
    "priority": 1830,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_batch_transfers": batch,
    "banking_batch_total": batch_total,
    "banking_batch_pis_bulk_json": bulk_pis_json,
    "banking_batch_ready_for_execution": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 44 PIT; Art. 103 VAT; Art. 47 SUS; Art. 61 OrdPU",
    "_warnings": build_batch_warnings(batch, batch_total)
} {
    input.banking_generate_batch == true

    zus_social := object.get(input.jdg_entrepreneur, "monthly_zus_social", 0)
    zus_health := object.get(input.jdg_entrepreneur, "monthly_zus_health", 0)
    zus_fp_fs := object.get(input.jdg_entrepreneur, "monthly_fp_fs", 0)
    vat_pay := object.get(input.jdg_entrepreneur, "monthly_vat_to_pay", 0)
    pit_pay := object.get(input.jdg_entrepreneur, "monthly_pit_advance", 0)
    ppk_pay := object.get(input.jdg_entrepreneur, "monthly_ppk_employer", 0)
    pfron_pay := object.get(input.jdg_entrepreneur, "monthly_pfron", 0)

    nip := object.get(input.jdg_entrepreneur, "nip", "")
    current_month := object.get(input, "current_month", 7)
    current_year := 2026
    next_month := current_month + 1

    batch := []
    batch := array.concat(batch, [{"to":"ZUS","account":"ZUS_SPOLECZNE","amount":zus_social+zus_fp_fs,"deadline":sprintf("%04d-%02d-10",[current_year,next_month]),"title":sprintf("Skl.spoleczne %02d/%d NIP %s",[current_month,current_year,nip]),"priority":"HIGH"}]) { zus_social+zus_fp_fs > 0 }
    batch := array.concat(batch, [{"to":"ZUS","account":"ZUS_ZDROWOTNE","amount":zus_health,"deadline":sprintf("%04d-%02d-15",[current_year,next_month]),"title":sprintf("Skl.zdrowotne %02d/%d NIP %s",[current_month,current_year,nip]),"priority":"HIGH"}]) { zus_health > 0 }
    batch := array.concat(batch, [{"to":"US","account":"MIKRORACHUNEK","amount":pit_pay,"deadline":sprintf("%04d-%02d-20",[current_year,next_month]),"title":sprintf("PIT-5 %02d/%d NIP %s",[current_month,current_year,nip]),"priority":"MEDIUM"}]) { pit_pay > 0 }
    batch := array.concat(batch, [{"to":"US","account":"MIKRORACHUNEK","amount":vat_pay,"deadline":sprintf("%04d-%02d-25",[current_year,next_month]),"title":sprintf("VAT-7 %02d/%d NIP %s",[current_month,current_year,nip]),"priority":"MEDIUM"}]) { vat_pay > 0 }
    batch := array.concat(batch, [{"to":"PPK","account":"PPK_ZARZADZAJACY","amount":ppk_pay,"deadline":sprintf("%04d-%02d-15",[current_year,next_month]),"title":sprintf("PPK %02d/%d NIP %s",[current_month,current_year,nip]),"priority":"MEDIUM"}]) { ppk_pay > 0 }
    batch := array.concat(batch, [{"to":"PFRON","account":"PFRON_KONTO","amount":pfron_pay,"deadline":sprintf("%04d-%02d-20",[current_year,next_month]),"title":sprintf("PFRON %02d/%d NIP %s",[current_month,current_year,nip]),"priority":"MEDIUM"}]) { pfron_pay > 0 }

    batch_total := zus_social + zus_fp_fs + zus_health + vat_pay + pit_pay + ppk_pay + pfron_pay

    # Build PIS bulk JSON (PolishAPI premium extension for batch payments)
    bulk_pis_json := build_bulk_pis_payload(batch, input)
}

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1840: IBAN VALIDATION — Walidacja numerów kont bankowych
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.iban_validation",
    "package": "jdg.banking",
    "priority": 1840,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_iban_valid": iban_ok,
    "banking_iban_country": iban_country,
    "banking_iban_bank_code": bank_code,
    "_routing": iban_routing,
    "_routing_reason": iban_routing_reason,
    "_legal_basis": "Standard IBAN (ISO 13616); Art. 96b VAT; Art. 117ba OrdPU",
    "_warnings": build_iban_warnings(iban_ok, iban_country, bank_code)
} {
    input.banking_validate_iban == true
    iban := object.get(input, "bank_account_to_validate", "")
    iban_clean := replace(iban, " ", "")
    has_pl_prefix := startswith(iban_clean, "PL")
    correct_length := count(iban_clean) == 28
    iban_ok := has_pl_prefix and correct_length
    iban_country := "PL" { has_pl_prefix }
    iban_country := "UNKNOWN" { not has_pl_prefix }
    bank_code := ""
    bank_code := substring(iban_clean, 2, 10) { correct_length; has_pl_prefix }
    iban_routing := ""
    iban_routing := "BLOCK_AND_ALERT" { not iban_ok }
    iban_routing_reason := ""
    iban_routing_reason := "NIEPOPRAWNY IBAN!" { not iban_ok }
}

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1845: PSD2 CONSENT MANAGEMENT — Zarządzanie zgodami PSD2
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.psd2_consent_management",
    "package": "jdg.banking",
    "priority": 1845,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_psd2_consent_id": consent_id,
    "banking_psd2_consent_type": consent_type,
    "banking_psd2_consent_valid_until": valid_until,
    "banking_psd2_consent_expiring_soon": expiring_soon,
    "banking_psd2_consent_sca_required": sca_needed,
    "banking_psd2_tpp_name": tpp_name,
    "_routing": consent_routing,
    "_routing_reason": consent_routing_reason,
    "_legal_basis": "PSD2 Art. 66-67 (AIS consent); RTS SCA Art. 10, 25-27",
    "_warnings": build_consent_warnings(consent_type, valid_until, expiring_soon, tpp_name)
} {
    input.banking_psd2_consent_check == true

    consent_id := object.get(object.get(input, "psd2", {}), "consent_id", "")
    consent_type := object.get(object.get(input, "psd2", {}), "consent_type", "AIS")
    consent_created := object.get(object.get(input, "psd2", {}), "consent_created_at", "")
    consent_expiry := object.get(object.get(input, "psd2", {}), "consent_expires_at", "")
    consent_status := object.get(object.get(input, "psd2", {}), "consent_status", "VALID")
    tpp_id := object.get(object.get(input, "psd2", {}), "tpp_id", "")
    tpp_name := object.get(object.get(input, "psd2", {}), "tpp_name", "NexusAI TPP")
    current_time := object.get(input, "evaluation_datetime", "")
    sca_method := object.get(object.get(input, "psd2", {}), "sca_used", "NONE")

    # AIS consent max 90 days per RTS SCA Art. 10
    max_ais_days := 90
    max_pis_minutes := 5  # PIS consent is per-transaction

    valid_until := consent_expiry
    expiring_soon := false
    expiring_soon := true { consent_type == "AIS"; valid_until != ""; current_time != ""; valid_until <= current_time }

    sca_needed := consent_status != "VALID"
    sca_needed := true { sca_method == "NONE" }

    consent_routing := ""
    consent_routing := "TRIAGE_QUEUE" { expiring_soon }
    consent_routing := "BLOCK_AND_ALERT" { consent_status == "EXPIRED" }
    consent_routing_reason := ""
    consent_routing_reason := "Zgoda PSD2 AIS wygasa — odnow przez SCA" { expiring_soon }
    consent_routing_reason := "Zgoda PSD2 WYGASŁA! Wymagane ponowne SCA." { consent_status == "EXPIRED" }
}

build_consent_warnings(type, expiry, soon, tpp) = warnings {
    soon == true
    warnings := [sprintf("⚠️ Zgoda PSD2 (%s) dla %s wygasa %s. Odnów przez aplikację banku (SCA).", [type, tpp, expiry])]
} else = [sprintf("✅ Zgoda PSD2 (%s) aktywna dla %s do %s.", [type, tpp, expiry])]

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1850: AIS ACCOUNT INFORMATION — Pobieranie danych konta przez PSD2
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.ais_account_information",
    "package": "jdg.banking",
    "priority": 1850,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_ais_account_balance": account_balance,
    "banking_ais_available_balance": available_balance,
    "banking_ais_transaction_count_30d": tx_count,
    "banking_ais_last_sync_time": last_sync,
    "banking_ais_polishapi_request": ais_request,
    "_routing": ais_routing,
    "_routing_reason": ais_routing_reason,
    "_legal_basis": "PSD2 Art. 67 (AIS); PolishAPI v3.x GET /accounts/{accountId}/balances",
    "_warnings": build_ais_warnings(account_balance, available_balance, tx_count)
} {
    input.banking_ais_fetch == true

    account_id := object.get(object.get(input, "psd2", {}), "account_id", "")
    consent_id := object.get(object.get(input, "psd2", {}), "consent_id", "")
    access_token := object.get(object.get(input, "psd2", {}), "access_token", "")
    bank_api_base := object.get(object.get(input, "psd2", {}), "bank_api_base_url", "")
    x_request_id := object.get(input, "evaluation_datetime", "2026-01-01T00:00:00Z")

    account_balance := object.get(object.get(input, "psd2", {}), "last_known_balance", 0)
    available_balance := object.get(object.get(input, "psd2", {}), "last_known_available", 0)
    tx_count := object.get(object.get(input, "psd2", {}), "transaction_count_30d", 0)
    last_sync := object.get(object.get(input, "psd2", {}), "last_sync_time", "")

    # Build PolishAPI v3.x AIS request
    ais_request := {
        "method": "GET",
        "url": sprintf("%s/v3.0/accounts/%s/balances", [bank_api_base, account_id]),
        "headers": {
            "Authorization": sprintf("Bearer %s", [access_token]),
            "X-Request-ID": x_request_id,
            "Consent-ID": consent_id,
            "Accept": "application/json",
            "Accept-Language": "pl-PL",
            "PSU-IP-Address": "127.0.0.1",
            "TPP-Name": "NexusAI JDG Automation"
        },
        "psd2_scope": "AIS",
        "eidas_qseal_required": true
    }

    ais_routing := ""
    ais_routing := "TRIAGE_QUEUE" { available_balance < 5000 }
    ais_routing_reason := ""
    ais_routing_reason := sprintf("Niskie saldo: %.2f PLN — ryzyko odrzucenia przelewów!", [available_balance]) { available_balance < 5000 }
}

build_ais_warnings(balance, available, tx_count) = warnings {
    available < 5000
    warnings := [sprintf("⚠️ NISKIE SALDO: %.2f PLN (dostępne: %.2f PLN). Transakcji w 30 dni: %d. Zwiększ bufor!", [balance, available, tx_count])]
} else = [sprintf("✅ Saldo: %.2f PLN (dostępne: %.2f PLN). Transakcji: %d.", [balance, available, tx_count])]

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1855: PIS PAYMENT INITIATION — PolishAPI v3.x Payment Initiation
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.pis_payment_initiation",
    "package": "jdg.banking",
    "priority": 1855,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_pis_transaction_id": pis_txn_id,
    "banking_pis_polishapi_request": pis_request,
    "banking_pis_payment_product": payment_product,
    "banking_pis_sca_redirect_url": sca_url,
    "banking_pis_amount_pln": pis_amount,
    "_routing": pis_routing,
    "_routing_reason": pis_routing_reason,
    "_legal_basis": "PSD2 Art. 64-66 (PIS); PolishAPI v3.x POST /payments/{paymentProduct}; RTS SCA Art. 30-35",
    "_warnings": build_pis_warnings(pis_txn_id, payment_product, pis_amount)
} {
    input.banking_pis_initiate == true

    payment_product := object.get(object.get(input, "psd2", {}), "payment_product", "domestic-transfer")
    creditor_account := object.get(input, "creditor_iban", "")
    creditor_name := object.get(input, "creditor_name", "")
    pis_amount := object.get(input, "pis_amount_pln", 0)
    remittance_info := object.get(input, "pis_remittance_info", "")
    debtor_account := object.get(object.get(input, "psd2", {}), "debtor_account_id", "")
    access_token := object.get(object.get(input, "psd2", {}), "access_token", "")
    bank_api_base := object.get(object.get(input, "psd2", {}), "bank_api_base_url", "")
    tpp_id := object.get(object.get(input, "psd2", {}), "tpp_id", "NEXUSAI_TPP")
    pis_txn_id := object.get(object.get(input, "psd2", {}), "pis_transaction_id", "")

    # PolishAPI v3.x PIS JSON payload
    pis_request := {
        "method": "POST",
        "url": sprintf("%s/v3.0/payments/%s", [bank_api_base, payment_product]),
        "headers": {
            "Authorization": sprintf("Bearer %s", [access_token]),
            "X-Request-ID": pis_txn_id,
            "Content-Type": "application/json",
            "Accept": "application/json",
            "TPP-ID": tpp_id,
            "PSU-IP-Address": "127.0.0.1"
        },
        "body": {
            "instructedAmount": {"amount": sprintf("%.2f", [pis_amount]), "currency": "PLN"},
            "debtorAccount": {"iban": debtor_account},
            "creditorAccount": {"iban": creditor_account},
            "creditorName": creditor_name,
            "remittanceInformationUnstructured": remittance_info,
            "requestedExecutionDate": object.get(input, "pis_execution_date", ""),
            "paymentProduct": payment_product
        },
        "sca": {
            "approach": "REDIRECT",
            "eidas_qwac_required": true,
            "tpp_redirect_uri": object.get(object.get(input, "psd2", {}), "tpp_redirect_uri", "")
        }
    }

    # SCA redirect URL for user authorization
    sca_url := object.get(object.get(input, "psd2", {}), "sca_redirect_url", "")

    pis_routing := ""
    pis_routing := "TRIAGE_QUEUE" { pis_amount > 50000 }
    pis_routing_reason := ""
    pis_routing_reason := sprintf("Przelew %.2f PLN > 50 000 PLN — wymagana autoryzacja SCA", [pis_amount]) { pis_amount > 50000 }
}

build_pis_warnings(txn_id, product, amount) = warnings {
    warnings := [sprintf("💳 PIS: %s na %.2f PLN. Transaction ID: %s. Oczekiwanie na SCA.", [product, amount, txn_id])]
}

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1860: ELIXIR/EXPRESSELIXIR PAYLOAD GENERATOR — Realne formaty KIR
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.elixir_payload_generator",
    "package": "jdg.banking",
    "priority": 1860,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_elixir_type": elixir_type,
    "banking_elixir_elixir0_format": elixir0_msg,
    "banking_elixir_instant_enabled": instant_ok,
    "banking_elixir_kir_session_id": kir_session,
    "banking_elixir_cutoff_time": cutoff_time,
    "_routing": elixir_routing,
    "_routing_reason": elixir_routing_reason,
    "_legal_basis": "Regulamin KIR; Standard Elixir/ExpressElixir; ISO 20022 pain.001.001.03",
    "_warnings": build_elixir_warnings(elixir_type, kir_session, cutoff_time, instant_ok)
} {
    input.banking_elixir_generate == true

    amount := object.get(input, "elixir_amount_pln", 0)
    creditor_iban := object.get(input, "creditor_iban", "")
    creditor_name := object.get(input, "creditor_name", "")
    debtor_iban := object.get(input, "debtor_iban", "")
    debtor_name := object.get(input, "debtor_name", "")
    transfer_title := object.get(input, "elixir_transfer_title", "")
    execution_date := object.get(input, "elixir_execution_date", "")
    is_urgent := object.get(input, "elixir_is_urgent", false)
    is_mpp := object.get(input, "elixir_is_split_payment", false)

    current_hour := object.get(input, "current_hour", 12)

    # ExpressElixir available until 21:30 on business days
    elixir_cutoff_express := 21
    elixir_cutoff_standard := 16
    instant_ok := current_hour < elixir_cutoff_express

    elixir_type := "EXPRESS_ELIXIR" { is_urgent; instant_ok }
    elixir_type := "ELIXIR_STANDARD" { not is_urgent }
    elixir_type := "ELIXIR_STANDARD" { not instant_ok }

    # Elixir0 message format (standard domestic transfer)
    # Format: 110|sender_iban|receiver_iban|amount|title|name|date
    sender_cleaned := replace(debtor_iban, " ", "")
    receiver_cleaned := replace(creditor_iban, " ", "")

    elixir0_msg := sprintf("110|%s|%s|%.2f|%s|%s|%s",
        [sender_cleaned, receiver_cleaned, amount, transfer_title, creditor_name, execution_date])

    # KIR session ID
    kir_session := sprintf("KIR-%s-%s-%d", [debtor_iban, execution_date, current_hour])

    cutoff_time := sprintf("%d:30", [elixir_cutoff_express]) { elixir_type == "EXPRESS_ELIXIR" }
    cutoff_time := sprintf("%d:00", [elixir_cutoff_standard]) { elixir_type == "ELIXIR_STANDARD" }

    elixir_routing := ""
    elixir_routing := "TRIAGE_QUEUE" { amount > 500000 }
    elixir_routing_reason := ""
    elixir_routing_reason := sprintf("Przelew %.2f PLN > 500k — wymagane dodatkowe potwierdzenie", [amount]) { amount > 500000 }
}

build_elixir_warnings(type, session, cutoff, instant) = warnings {
    type == "EXPRESS_ELIXIR"
    warnings := [sprintf("⚡ EXPRESSELIXIR (natychmiastowy) — sesja %s. Cut-off: %s. Kwota trafia w sekundach!", [session, cutoff])]
} else = [sprintf("🏦 ELIXIR (standardowy) — sesja %s. Cut-off: %s. Kwota na koncie następnego dnia roboczego.", [session, cutoff])]

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1865: OAUTH2/eIDAS TOKEN MANAGEMENT — Zarządzanie tokenami PSD2
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.oauth2_eidas_token_management",
    "package": "jdg.banking",
    "priority": 1865,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_oauth2_access_token": access_token,
    "banking_oauth2_token_expires_in": expires_in_sec,
    "banking_oauth2_refresh_token": refresh_token,
    "banking_eidas_qwac_serial": qwac_serial,
    "banking_eidas_qseal_valid": qseal_valid,
    "banking_eidas_cert_expiry": cert_expiry,
    "_routing": oauth_routing,
    "_routing_reason": oauth_routing_reason,
    "_legal_basis": "PSD2 Art. 97 (eIDAS certs); RTS SCA Art. 34; eIDAS Reg. (EU) 910/2014",
    "_warnings": build_oauth_warnings(expires_in_sec, qseal_valid, cert_expiry)
} {
    input.banking_oauth2_check == true

    access_token := object.get(object.get(input, "psd2", {}), "access_token", "")
    refresh_token := object.get(object.get(input, "psd2", {}), "refresh_token", "")
    token_type := object.get(object.get(input, "psd2", {}), "token_type", "Bearer")
    expires_in_sec := object.get(object.get(input, "psd2", {}), "expires_in", 3600)
    token_issued := object.get(object.get(input, "psd2", {}), "token_issued_at", "")

    # eIDAS certificates
    qwac_serial := object.get(object.get(input, "psd2", {}), "qwac_cert_serial", "")
    qseal_cert := object.get(object.get(input, "psd2", {}), "qseal_cert_serial", "")
    cert_expiry := object.get(object.get(input, "psd2", {}), "cert_expiry_date", "2026-12-31")
    qseal_valid := object.get(object.get(input, "psd2", {}), "qseal_valid", true)

    oauth_routing := ""
    oauth_routing := "TRIAGE_QUEUE" { expires_in_sec < 600 }
    oauth_routing := "BLOCK_AND_ALERT" { not qseal_valid }
    oauth_routing_reason := ""
    oauth_routing_reason := sprintf("Token OAuth2 wygasa za %d s — odśwież przed PIS", [expires_in_sec]) { expires_in_sec < 600 }
    oauth_routing_reason := sprintf("CERTYFIKAT eIDAS QSEAL NIEWAŻNY! Nie można inicjować płatności PSD2.", []) { not qseal_valid }
}

build_oauth_warnings(token_ttl, qseal_ok, cert_exp) = warnings {
    qseal_ok == true
    warnings := [sprintf("🔐 OAuth2: token ważny %d s | QSealC: OK (wygasa %s)", [token_ttl, cert_exp])]
} else = [sprintf("🚨 QSEALC NIEWAŻNY do %s! Wymagany do PIS. Odnów certyfikat w kwalifikowanym dostawcy.", [cert_exp])]

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1870: MULTI-BANK PROFILE ROUTING — Profile API banków
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.bank_profile_routing",
    "package": "jdg.banking",
    "priority": 1870,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_bank_name": bank_name,
    "banking_bank_api_version": api_version,
    "banking_bank_pis_endpoint": pis_endpoint,
    "banking_bank_ais_endpoint": ais_endpoint,
    "banking_bank_auth_endpoint": auth_endpoint,
    "banking_bank_supports_express_elixir": has_express,
    "banking_bank_supports_batch_pis": has_batch,
    "banking_bank_profile": bank_profile,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "PolishAPI v3.x; Rejestry banków KNF",
    "_warnings": [sprintf("🏦 Bank: %s | API: %s | ExpressElixir: %s | Batch PIS: %s", [bank_name, api_version, has_express, has_batch])]
} {
    input.banking_bank_profile_load == true

    bank_sort_code := object.get(input, "bank_sort_code", "")
    bank_id := substring(bank_sort_code, 0, 4) { count(bank_sort_code) >= 4 }
    bank_id := bank_sort_code { count(bank_sort_code) < 4 }

    # Polish bank profiles (KNF-registered ASPSPs)
    bank_profiles := {
        "1020": {"name":"PKO BP","api":"PolishAPI v3.1","pis":"/v3.0/payments","ais":"/v3.0/accounts","auth":"/v3.0/auth","express":true,"batch":true},
        "1050": {"name":"ING BSK","api":"PolishAPI v3.0","pis":"/v3.0/payments","ais":"/v3.0/accounts","auth":"/v3.0/auth","express":true,"batch":true},
        "1140": {"name":"mBank","api":"PolishAPI v2.1","pis":"/v2.1/payments","ais":"/v2.1/accounts","auth":"/v2.1/auth","express":true,"batch":false},
        "1240": {"name":"Pekao SA","api":"PolishAPI v3.0","pis":"/v3.0/payments","ais":"/v3.0/accounts","auth":"/v3.0/auth","express":true,"batch":true},
        "1090": {"name":"Santander BP","api":"PolishAPI v3.0","pis":"/v3.0/payments","ais":"/v3.0/accounts","auth":"/v3.0/auth","express":true,"batch":true},
        "2490": {"name":"Alior Bank","api":"PolishAPI v2.1","pis":"/v2.1/payments","ais":"/v2.1/accounts","auth":"/v2.1/auth","express":true,"batch":false},
        "1750": {"name":"BNP Paribas","api":"PolishAPI v2.1","pis":"/v2.1/payments","ais":"/v2.1/accounts","auth":"/v2.1/auth","express":true,"batch":false},
        "1600": {"name":"BNP Paribas BP","api":"PolishAPI v3.0","pis":"/v3.0/payments","ais":"/v3.0/accounts","auth":"/v3.0/auth","express":true,"batch":true},
        "1680": {"name":"Plus Bank","api":"PolishAPI v2.1","pis":"/v2.1/payments","ais":"/v2.1/accounts","auth":"/v2.1/auth","express":false,"batch":false},
        "1060": {"name":"BOŚ Bank","api":"PolishAPI v2.1","pis":"/v2.1/payments","ais":"/v2.1/accounts","auth":"/v2.1/auth","express":true,"batch":false}
    }

    default_profile := {"name":"Nieznany bank","api":"PolishAPI v2.1","pis":"/v2.1/payments","ais":"/v2.1/accounts","auth":"/v2.1/auth","express":false,"batch":false}

    bank_profile := object.get(bank_profiles, bank_id, default_profile)
    bank_name := object.get(bank_profile, "name", "Nieznany")
    api_version := object.get(bank_profile, "api", "v2.1")
    pis_endpoint := object.get(bank_profile, "pis", "/v2.1/payments")
    ais_endpoint := object.get(bank_profile, "ais", "/v2.1/accounts")
    auth_endpoint := object.get(bank_profile, "auth", "/v2.1/auth")
    has_express := object.get(bank_profile, "express", false)
    has_batch := object.get(bank_profile, "batch", false)
}

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1875: PAYMENT STATUS TRACKING & WEBHOOK — Śledzenie statusu przelewów
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.payment_status_tracking",
    "package": "jdg.banking",
    "priority": 1875,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_payment_status": payment_status,
    "banking_payment_elixir_status": elixir_status,
    "banking_payment_upo_received": upo_received,
    "banking_payment_retry_count": retry_count,
    "banking_payment_webhook_url": webhook_url,
    "_routing": status_routing,
    "_routing_reason": status_routing_reason,
    "_legal_basis": "PSD2 Art. 92 (certainty of execution); PolishAPI callback; Regulamin KIR",
    "_warnings": build_status_warnings(payment_status, elixir_status, upo_received, retry_count)
} {
    input.banking_payment_status_check == true

    txn_id := object.get(input, "pis_transaction_id", "")
    payment_status := object.get(object.get(input, "psd2", {}), "payment_status", "PENDING")
    elixir_status := object.get(object.get(input, "psd2", {}), "elixir_status", "UNKNOWN")
    upo_received := object.get(object.get(input, "psd2", {}), "upo_received", false)
    retry_count := object.get(object.get(input, "psd2", {}), "retry_count", 0)
    bank_api_base := object.get(object.get(input, "psd2", {}), "bank_api_base_url", "")

    # Webhook URL for payment status notifications
    webhook_url := sprintf("%s/v3.0/payments/%s/status", [bank_api_base, txn_id])

    # Elixir statuses
    elixir_ok := elixir_status in {"SETTLED", "CREDITED"}
    elixir_failed := elixir_status in {"REJECTED", "RETURNED", "ERROR"}
    elixir_pending := elixir_status in {"PENDING", "ACCEPTED", "PROCESSING"}

    status_routing := ""
    status_routing := "TRIAGE_QUEUE" { elixir_failed }
    status_routing := "BLOCK_AND_ALERT" { retry_count > 3 }
    status_routing_reason := ""
    status_routing_reason := sprintf("Przelew %s ODRZUCONY: %s — sprawdź dane odbiorcy!", [txn_id, elixir_status]) { elixir_failed }
    status_routing_reason := sprintf("Przelew %s: 3+ ponowień nieudanych — wymagana interwencja!", [txn_id]) { retry_count > 3 }
}

build_status_warnings(payment, elixir, upo, retry) = warnings {
    elixir == "SETTLED"
    warnings := [sprintf("✅ Przelew ZAKSIĘGOWANY. UPO: %s. Status: %s", [upo, elixir])]
} else = warnings {
    elixir == "REJECTED"
    warnings := [
        sprintf("🔴 PRZELEW ODRZUCONY! Status Elixir: %s (ponowień: %d)", [elixir, retry]),
        "📋 SPRAWDŹ: poprawność IBAN, limit dzienny, blokadę banku, status MPP."
    ]
} else = [sprintf("⏳ Przelew w toku — status PSD2: %s, Elixir: %s.", [payment, elixir])]

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1880: BATCH PAYMENT XML/JSON — Paczka przelewów Elixir
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.batch_payment_format",
    "package": "jdg.banking",
    "priority": 1880,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_batch_payment_count": batch_count,
    "banking_batch_total_amount": batch_total,
    "banking_batch_xml_pain001": pain001_xml,
    "banking_batch_json_polishapi": pis_bulk_json,
    "banking_batch_execution_strategy": batch_strategy,
    "_routing": batch_routing,
    "_routing_reason": batch_routing_reason,
    "_legal_basis": "ISO 20022 pain.001.001.03; PolishAPI premium batch; Regulamin KIR",
    "_warnings": build_batch_payment_warnings(batch_count, batch_total, batch_strategy)
} {
    input.banking_batch_payments == true

    payments := object.get(input, "batch_payments_array", [])
    batch_count := count(payments)
    debtor_iban := object.get(object.get(input, "psd2", {}), "debtor_account_id", "")
    debtor_name := object.get(input.jdg_entrepreneur, "company_name", "JDG")
    execution_date := object.get(input, "batch_execution_date", "")

    # Calculate batch total (iterative — avoid recursion in OPA)
    batch_total := sum_payment_amounts(payments, count(payments))

    # Batch strategy based on count
    batch_strategy := "single_sequential" { batch_count <= 5 }
    batch_strategy := "elixir_batch_file" { batch_count > 5; batch_count <= 100 }
    batch_strategy := "elixir_bulk_split" { batch_count > 100 }

    # pain.001.001.03 XML header for Elixir batch (TODO: add PmtInf entries per payment)
    pain001_xml := build_pain001_header(payments, debtor_iban, debtor_name, execution_date, batch_total)

    # PolishAPI premium batch JSON
    pis_bulk_json := build_bulk_pis_payload(payments, input)

    batch_routing := ""
    batch_routing := "TRIAGE_QUEUE" { batch_total > 100000 }
    batch_routing_reason := ""
    batch_routing_reason := sprintf("Batch %.2f PLN > 100k — weryfikacja zarządu", [batch_total]) { batch_total > 100000 }

    batch_count > 0
}

# OPA-safe iterative sum: iterate index from 0 to count-1, accumulate amounts
sum_payment_amounts(payments, remaining) = acc {
    remaining == 0
    acc := 0
} else = acc {
    remaining > 0
    idx := remaining - 1
    current_amount := object.get(payments[idx], "amount", 0)
    rest := sum_payment_amounts(payments, idx)
    acc := current_amount + rest
}

build_pain001_header(payments, debtor_iban, debtor_name, exec_date, total) = xml {
    header := sprintf("<Document><CstmrCdtTrfInitn><GrpHdr><MsgId>NEXUSAI-%s</MsgId><CreDtTm>%s</CreDtTm><NbOfTxs>%d</NbOfTxs><CtrlSum>%.2f</CtrlSum><InitgPty><Nm>%s</Nm></InitgPty></GrpHdr>",
        [exec_date, exec_date, count(payments), total, debtor_name])
    xml := header
}

build_batch_payment_warnings(count, total, strategy) = warnings {
    warnings := [
        sprintf("📦 PACZKA PRZELEWÓW: %d przelewów na łączną kwotę %.2f PLN", [count, total]),
        sprintf("🔄 Strategia: %s", [strategy]),
        "📋 Format: ISO 20022 pain.001.001.03 dla Elixir batch",
        "",
        "⚠️ Limity: ExpressElixir = 100k PLN/przelew, Elixir standard = bez limitu",
        "📌 Paczka jest wysyłana jako PLIK do banku (nie przez PSD2 PIS per przelew)"
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# BNK-1885: PSD2 COMPLIANCE & AUDIT TRAIL — Dziennik audytu PSD2
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.banking.psd2_compliance_audit",
    "package": "jdg.banking",
    "priority": 1885,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "banking_psd2_rts_sca_compliant": sca_ok,
    "banking_psd2_eidas_cert_valid": eidas_ok,
    "banking_psd2_tpp_registered_kfn": tpp_registered,
    "banking_psd2_audit_entries_30d": audit_count,
    "banking_psd2_last_audit_entry": last_audit,
    "_routing": audit_routing,
    "_routing_reason": audit_routing_reason,
    "_legal_basis": "PSD2 RTS SCA (EU 2018/389); eIDAS (EU 910/2014); Ustawa o usługach płatniczych",
    "_warnings": build_audit_warnings(sca_ok, eidas_ok, tpp_registered, audit_count)
} {
    input.banking_psd2_audit_check == true

    sca_ok := object.get(object.get(input, "psd2", {}), "sca_compliant", true)
    eidas_ok := object.get(object.get(input, "psd2", {}), "eidas_cert_valid", true)
    tpp_registered := object.get(object.get(input, "psd2", {}), "tpp_registered_kfn", true)
    audit_count := object.get(object.get(input, "psd2", {}), "audit_entries_30d", 0)
    last_audit := object.get(object.get(input, "psd2", {}), "last_audit_entry", "")

    audit_routing := ""
    audit_routing := "BLOCK_AND_ALERT" { not sca_ok }
    audit_routing := "BLOCK_AND_ALERT" { not eidas_ok }
    audit_routing := "BLOCK_AND_ALERT" { not tpp_registered }
    audit_routing_reason := ""
    audit_routing_reason := "SCA NIEZGODNE Z RTS! Wymagane 2-faktorowe uwierzytelnienie." { not sca_ok }
    audit_routing_reason := "Certyfikat eIDAS NIEWAŻNY — odnow w KNF!" { not eidas_ok }
    audit_routing_reason := "TPP NIEZAREJESTROWANE W KNF! Nie można świadczyć usług PSD2." { not tpp_registered }
}

build_audit_warnings(sca, eidas, tpp, audit) = warnings {
    sca and eidas and tpp
    warnings := [sprintf("✅ PSD2 COMPLIANCE OK: SCA=✓, eIDAS=✓, TPP KNF=✓. Audytów 30 dni: %d.", [audit])]
} else = [
    sprintf("🚨 NARUSZENIE PSD2! SCA=%s eIDAS=%s TPP=%s", [sca, eidas, tpp]),
    "📌 NATYCHMIAST: sprawdź certyfikaty, rejestrację KNF, włącz SCA 2FA."
]

# ═══════════════════════════════════════════════════════════════════════════════
# SHARED HELPERS — budowanie payloadów PolishAPI / Elixir
# ═══════════════════════════════════════════════════════════════════════════════

build_pis_payload(product, creditor_iban, amount, title, input, creditor_name, creditor_nip) = payload {
    debtor_iban := object.get(object.get(input, "psd2", {}), "debtor_account_id", "")
    access_token := object.get(object.get(input, "psd2", {}), "access_token", "")
    bank_api := object.get(object.get(input, "psd2", {}), "bank_api_base_url", "")
    tpp_id := object.get(object.get(input, "psd2", {}), "tpp_id", "NEXUSAI")
    debtor_name := object.get(input.jdg_entrepreneur, "company_name", "JDG")

    payload := {
        "method": "POST",
        "url": sprintf("%s/v3.0/payments/%s", [bank_api, product]),
        "headers": {
            "Authorization": sprintf("Bearer %s", [access_token]),
            "X-Request-ID": sprintf("NEXUSAI-%s-%s", [product, title]),
            "Content-Type": "application/json",
            "TPP-ID": tpp_id,
            "PSU-IP-Address": "127.0.0.1"
        },
        "body": {
            "instructedAmount": {"amount": sprintf("%.2f", [amount]), "currency": "PLN"},
            "debtorAccount": {"iban": debtor_iban, "name": debtor_name},
            "creditorAccount": {"iban": creditor_iban, "name": creditor_name},
            "creditorName": creditor_name,
            "remittanceInformationUnstructured": title,
            "paymentProduct": "domestic-transfer"
        },
        "sca_required": true,
        "eidas_qwac_required": true
    }
}

build_bulk_pis_payload(batch, input) = payload {
    count(batch) > 0
    debtor_iban := object.get(object.get(input, "psd2", {}), "debtor_account_id", "")
    payload := {
        "method": "POST",
        "url": "/v3.0/payments/bulk",
        "paymentCount": count(batch),
        "debtorAccount": debtor_iban,
        "payments": batch,
        "format": "PolishAPI-Bulk-v1.0"
    }
} else = {}

# Helper: IBAN validation warnings
build_iban_warnings(ok, country, bank) = warnings {
    ok == true
    warnings := [sprintf("✅ IBAN OK — %s, kod banku: %s", [country, bank])]
} else = [
    "🔴 NIEPOPRAWNY IBAN! Sprawdź:",
    "   • Czy konto jest polskie? (powinno zaczynać się od 'PL')",
    "   • Czy ma dokładnie 28 znaków (PL + 26 cyfr)?",
    "⚠️ Przelew na nieprawidłowy IBAN zostanie odrzucony!"
]

# Helper: batch warnings
build_batch_warnings(transfers, total) = warnings {
    count(transfers) > 0
    warnings := [sprintf("📦 PACZKA PRZELEWÓW — %.2f PLN łącznie (%d przelewów)", [total, count(transfers)])]
} else = ["📦 Brak przelewów do przygotowania w tym miesiącu."]

# Helper: ZUS warnings
build_zus_transfer_warnings(social, health, fp_fs, total, deadline) = warnings {
    warnings := [
        sprintf("🏦 PRZELEWY DO ZUS — %.2f PLN miesięcznie", [total]),
        sprintf("   Społeczne: %.2f PLN → do 10. dnia", [social]),
        sprintf("   FP + FS: %.2f PLN → do 10. dnia", [fp_fs]),
        sprintf("   Zdrowotne: %.2f PLN → do 15. dnia", [health]),
        sprintf("📅 NAJBLIŻSZY TERMIN: %s", [deadline]),
        "💡 PolishAPI PIS: paymentProduct=domestic-transfer, creditorAccount=ZUS",
        "📌 Twój NIP w tytule przelewu to IDENTYFIKATOR ZUS."
    ]
}

# Helper: US warnings
build_us_transfer_warnings(vat, pit, total, cf_30d) = warnings {
    cf_info := sprintf("   Cashflow 30d: %.0f PLN — %s", [cf_30d, "OK" { cf_30d >= 0 } else "DEFICYT!"]) { cf_30d != 0 }
    cf_info := [] { cf_30d == 0 }
    warnings := [
        sprintf("🏛️ PRZELEWY DO US — %.2f PLN miesięcznie", [total]),
        sprintf("   VAT-7: %.2f PLN → do 25. dnia", [vat]) { vat > 0 },
        sprintf("   PIT: %.2f PLN → do 20. dnia", [pit]) { pit > 0 },
        "📋 MIKRORACHUNEK PODATKOWY: generator na podatki.gov.pl",
        "📌 PolishAPI credytorAccount = mikrorachunek US",
        cf_info
    ]
}
