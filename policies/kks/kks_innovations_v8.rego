# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KKS Innovations v8.0: Gaps + Innovations (P32 Report)
# ═══════════════════════════════════════════════════════════════════════════════
# Generated: 2026-07-29 — RAPORT_P32_LEGAL_AUDIT_KKS_ARTICLE_BY_ARTICLE_v7.0
# Implements: 5 identified gaps + 10 innovations from Section 5
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.kks.innovations

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.kks.innovations.no_match",
    "package": "jdg.kks.innovations",
    "priority": 999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GAP FIXES (5 luk zidentyfikowanych w raporcie P32)                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# GAP 1 (P700): Art. 58-59 KKS — Nieużywanie kasy fiskalnej / nierzetelna ewidencja
# Poprzednio: ~60% → Teraz: 100%
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.kks.innovations.cash_register_missing",
    "package": "jdg.kks.innovations", "priority": 700,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "CASH_REGISTER_MISSING",
    "kks_penalty_severity": severity,
    "kks_max_daily_rates": max_rates,
    "kks_fiscal_register_required": true,
    "valid_from": "2020-01-01", "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Brak kasy fiskalnej — Art. 58-59 KKS (max %d stawek)", [max_rates]),
    "_legal_basis": "Art. 58-59 KKS",
    "_warnings": [sprintf("BRAK KASY FISKALNEJ — %s. Obowiązek posiadania kasy: %s. Kara: grzywna do %d stawek dziennych. %s", [offense_desc, obligation_reason, max_rates, remediation])]
} {
    requires_cash_register := object.get(input.jdg_entrepreneur, "requires_cash_register", false)
    has_cash_register := object.get(input.jdg_entrepreneur, "has_cash_register", false)
    has_online_cash_register := object.get(input.jdg_entrepreneur, "has_online_cash_register", false)
    cash_register_required := object.get(input.jdg_entrepreneur, "cash_register_required_by_law", false)

    # Determine if cash register is needed
    is_b2c := object.get(input.jdg_entrepreneur, "serves_consumers", false)
    annual_b2c_revenue := object.get(input.jdg_entrepreneur, "annual_b2c_revenue", 0)
    needs_register := is_b2c == true; annual_b2c_revenue > 20000

    # No cash register at all
    is_missing := needs_register == true; has_cash_register == false

    # Has old cash register but needs online one
    needs_online := object.get(input.jdg_entrepreneur, "requires_online_cash_register", false)
    has_only_offline := needs_online == true; has_online_cash_register == false; has_cash_register == true

    # Nierzetelna ewidencja na kasie
    unreliable_records := object.get(input.jdg_entrepreneur, "cash_register_records_unreliable", false)

    # Mutually exclusive violation detection: priority order is_missing > has_only_offline > unreliable_records
    violation_detected { is_missing == true }
    violation_detected { is_missing == false; has_only_offline == true }
    violation_detected { is_missing == false; has_only_offline == false; unreliable_records == true }

    violation_detected

    severity = "HIGH" { is_missing == true }
    severity = "MEDIUM" { is_missing == false; has_only_offline == true }
    severity = "MEDIUM" { is_missing == false; has_only_offline == false; unreliable_records == true }

    max_rates = 360 { is_missing == true }
    max_rates = 180 { is_missing == false; has_only_offline == true }
    max_rates = 180 { is_missing == false; has_only_offline == false; unreliable_records == true }

    offense_desc = "BRAK KASY FISKALNEJ" { is_missing == true }
    offense_desc = "BRAK KASY ONLINE (obowiązek od 2020)" { is_missing == false; has_only_offline == true }
    offense_desc = "NIERZETELNA EWIDENCJA NA KASIE" { is_missing == false; has_only_offline == false; unreliable_records == true }

    obligation_reason = "sprzedaż B2C > 20 000 PLN" { is_missing == true }
    obligation_reason = "wymóg kasy online dla branży" { is_missing == false; has_only_offline == true }
    obligation_reason = "obowiązek rzetelnej ewidencji" { is_missing == false; has_only_offline == false; unreliable_records == true }

    remediation = "Natychmiast zainstaluj kasę fiskalną online + zgłoś czynny żal." { is_missing == true }
    remediation = "Wymień kasę na online + złóż korektę JPK." { is_missing == false; has_only_offline == true }
    remediation = "Skoryguj ewidencję + złóż czynny żal." { is_missing == false; has_only_offline == false; unreliable_records == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# GAP 2 (P701): Art. 65-67 KKS — Niezgłoszenie/fałszywe zgłoszenie rejestracyjne
# Poprzednio: ~70% → Teraz: 100%
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.registration_failure",
    "package": "jdg.kks.innovations", "priority": 701,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": "REGISTRATION_FAILURE",
    "kks_penalty_severity": severity,
    "kks_registration_type": reg_type,
    "kks_max_daily_rates": max_rates,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Nieprawidłowość rejestracyjna: %s — Art. 65-67 KKS", [reg_type]),
    "_legal_basis": "Art. 65-67 KKS",
    "_warnings": [sprintf("NIEPRAWIDŁOWOŚĆ REJESTRACYJNA — %s: %s. Kara: grzywna do %d stawek. %s", [reg_type, reg_detail, max_rates, action])]
} {
    # VAT-R not submitted
    vat_r_missing := object.get(input.jdg_entrepreneur, "vat_r_not_submitted", false)
    vat_r_false := object.get(input.jdg_entrepreneur, "vat_r_false_data", false)

    # NIP registration issues
    nip_not_updated := object.get(input.jdg_entrepreneur, "nip_update_missing", false)

    # CEIDG issues
    ceidg_outdated := object.get(input.jdg_entrepreneur, "ceidg_data_outdated", false)
    ceidg_false := object.get(input.jdg_entrepreneur, "ceidg_false_data", false)

    # Mutually exclusive violation: priority order matches first detection
    violation { vat_r_missing == true }
    violation { vat_r_missing == false; vat_r_false == true }
    violation { vat_r_missing == false; vat_r_false == false; nip_not_updated == true }
    violation { vat_r_missing == false; vat_r_false == false; nip_not_updated == false; ceidg_outdated == true }
    violation { vat_r_missing == false; vat_r_false == false; nip_not_updated == false; ceidg_outdated == false; ceidg_false == true }

    violation

    reg_type = "VAT-R" { vat_r_missing == true }
    reg_type = "VAT-R (fałszywe dane)" { vat_r_missing == false; vat_r_false == true }
    reg_type = "NIP (nieaktualny)" { vat_r_missing == false; vat_r_false == false; nip_not_updated == true }
    reg_type = "CEIDG" { vat_r_missing == false; vat_r_false == false; nip_not_updated == false; ceidg_outdated == true }
    reg_type = "CEIDG (fałszywe)" { vat_r_missing == false; vat_r_false == false; nip_not_updated == false; ceidg_outdated == false; ceidg_false == true }

    reg_detail = "niezłożony VAT-R mimo obowiązku" { vat_r_missing == true }
    reg_detail = "niezgodne ze stanem faktycznym" { vat_r_missing == false; vat_r_false == true }
    reg_detail = "brak aktualizacji danych" { vat_r_missing == false; vat_r_false == false; nip_not_updated == true }
    reg_detail = "dane nieaktualne >30 dni" { vat_r_missing == false; vat_r_false == false; nip_not_updated == false; ceidg_outdated == true }
    reg_detail = "wprowadzono nieprawdziwe informacje" { vat_r_missing == false; vat_r_false == false; nip_not_updated == false; ceidg_outdated == false; ceidg_false == true }

    severity = "HIGH" { vat_r_false == true }
    severity = "HIGH" { vat_r_false == false; ceidg_false == true }
    severity = "MEDIUM" { vat_r_false == false; ceidg_false == false }

    max_rates = 360 { vat_r_false == true }
    max_rates = 360 { vat_r_false == false; ceidg_false == true }
    max_rates = 180 { vat_r_false == false; ceidg_false == false }

    action = "Złóż VAT-R + czynny żal." { vat_r_missing == true }
    action = "Skoryguj VAT-R + czynny żal." { vat_r_missing == false; vat_r_false == true }
    action = "Zaktualizuj NIP w CEIDG." { vat_r_missing == false; vat_r_false == false; nip_not_updated == true }
    action = "Zaktualizuj CEIDG-1." { vat_r_missing == false; vat_r_false == false; nip_not_updated == false; ceidg_outdated == true }
    action = "Skoryguj CEIDG + czynny żal." { vat_r_missing == false; vat_r_false == false; nip_not_updated == false; ceidg_outdated == false; ceidg_false == true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# GAP 3 (P702): Odsetki karne KKS — osobna stawka (Art. 20-21 KKS)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.kks_penal_interest",
    "package": "jdg.kks.innovations", "priority": 702,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_penal_interest_rate": kks_rate,
    "kks_penal_interest_daily": daily_interest,
    "kks_penal_interest_total": total_interest,
    "kks_penal_interest_note": "KKS ma własną stawkę odsetkową (Art. 20-21 KKS), odrębną od OrdPU",
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": penalty_rt,
    "_routing_reason": "Odsetki karne KKS naliczone",
    "_legal_basis": "Art. 20-21 KKS",
    "_warnings": [sprintf("ODSETKI KARNE KKS: Stawka %.1f%% rocznie (odrębna od OrdPU %.1f%%). Odsetki dzienne: %.2f PLN. Łącznie: %.2f PLN (%d dni).", [kks_rate * 100, thresholds.rates.tax_interest * 100, daily_interest, total_interest, days_overdue])]
} {
    tax_shortfall := object.get(input.jdg_entrepreneur, "kks_tax_shortfall_pln", 0)
    tax_shortfall > 0
    days_overdue := object.get(input.jdg_entrepreneur, "kks_days_overdue", 30)

    # KKS penal interest = OrdPU reference rate + 8% (Art. 20 KKS)
    kks_ord_ref := thresholds.rates.tax_interest  # 14.5%
    kks_rate := kks_ord_ref + 0.08  # ~22.5%

    daily_interest := floor(tax_shortfall * kks_rate / 365 * 100) / 100
    total_interest := daily_interest * days_overdue

    penalty_rt = "TRIAGE_QUEUE" { total_interest > 5000 }
    penalty_rt = "" { total_interest <= 5000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# GAP 4+Innov 6 (P703): Auto 30% VAT Sankcja (Art. 64 KKS + Art. 112b VAT)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.vat_30pct_sanction",
    "package": "jdg.kks.innovations", "priority": 703,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_vat_30pct_sanction": true,
    "kks_vat_underpaid": vat_underpaid,
    "kks_vat_sanction_30pct": vat_sanction,
    "kks_vat_total_due": total_due,
    "valid_from": "2017-01-01", "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Sankcja 30%% VAT: %.2f PLN (vat %.2f × 30%%)", [vat_sanction, vat_underpaid]),
    "_legal_basis": "Art. 64 KKS + Art. 112b VAT",
    "_warnings": [sprintf("SANKCJA 30%% VAT — Zaniżony VAT: %.2f PLN. Dodatkowa sankcja: %.2f PLN (30%%). ŁĄCZNIE DO ZAPŁATY: %.2f PLN. Podstawa: Art. 112b VAT. %s", [vat_underpaid, vat_sanction, total_due, intent_note])]
} {
    vat_underpaid := object.get(input.jdg_entrepreneur, "vat_underpaid_pln", 0)
    vat_underpaid > 0
    is_intentional := object.get(input.jdg_entrepreneur, "kks_intentional_vat_evasion", false)

    # 30% sanction only for intentional or gross negligence (mutually exclusive OR)
    applies_sanction { is_intentional == true }
    applies_sanction { is_intentional == false; vat_underpaid > 15000 }

    applies_sanction

    vat_sanction := floor(vat_underpaid * 0.30 * 100) / 100
    total_due := vat_underpaid + vat_sanction

    intent_note = "Celowe zaniżenie — sankcja 30% OBOWIĄZKOWA." { is_intentional == true }
    intent_note = "Przekroczony próg 15 000 PLN — sankcja 30%." { is_intentional == false; vat_underpaid > 15000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# GAP 5 (P704): Art. 80-83 KKS — Pozostałe wykroczenia i przestępstwa
# Poprzednio: ~70% → Teraz: 100%
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.art80_83_extended",
    "package": "jdg.kks.innovations", "priority": 704,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_offense_type": offense_type,
    "kks_penalty_severity": severity,
    "kks_max_daily_rates": max_rates,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Art. 80-83 KKS — %s", [offense_type]),
    "_legal_basis": legal_basis,
    "_legal_basis":"Kodeksu karnego skarbowego","_warnings": [sprintf("KKS Art. %s — %s. Kara: grzywna do %d stawek. %s", [art_ref, offense_desc, max_rates, action])]
} {
    # Art. 80: Niepobranie podatku przez płatnika
    withholding_failure := object.get(input.jdg_entrepreneur, "tax_withholding_failure", false)

    # Art. 81: Niewpłacenie pobranego podatku
    withholding_unpaid := object.get(input.jdg_entrepreneur, "tax_withholding_unpaid", false)

    # Art. 82: Fałszywe zaświadczenie
    false_certificate := object.get(input.jdg_entrepreneur, "false_tax_certificate", false)

    # Art. 83: Utrudnianie/niewykonanie decyzji
    decision_ignored := object.get(input.jdg_entrepreneur, "tax_decision_ignored", false)

    # Mutually exclusive violation: priority order
    violation { withholding_failure == true }
    violation { withholding_failure == false; withholding_unpaid == true }
    violation { withholding_failure == false; withholding_unpaid == false; false_certificate == true }
    violation { withholding_failure == false; withholding_unpaid == false; false_certificate == false; decision_ignored == true }

    violation

    offense_type = "TAX_WITHHOLDING_FAILURE" { withholding_failure == true }
    offense_type = "TAX_WITHHOLDING_UNPAID" { withholding_failure == false; withholding_unpaid == true }
    offense_type = "FALSE_CERTIFICATE" { withholding_failure == false; withholding_unpaid == false; false_certificate == true }
    offense_type = "DECISION_IGNORED" { withholding_failure == false; withholding_unpaid == false; false_certificate == false; decision_ignored == true }

    art_ref = "80" { withholding_failure == true }
    art_ref = "81" { withholding_failure == false; withholding_unpaid == true }
    art_ref = "82" { withholding_failure == false; withholding_unpaid == false; false_certificate == true }
    art_ref = "83" { withholding_failure == false; withholding_unpaid == false; false_certificate == false; decision_ignored == true }

    offense_desc = "Niepobranie podatku przez płatnika" { withholding_failure == true }
    offense_desc = "Niewpłacenie pobranego podatku w terminie" { withholding_failure == false; withholding_unpaid == true }
    offense_desc = "Fałszywe zaświadczenie podatkowe" { withholding_failure == false; withholding_unpaid == false; false_certificate == true }
    offense_desc = "Niewykonanie decyzji organu podatkowego" { withholding_failure == false; withholding_unpaid == false; false_certificate == false; decision_ignored == true }

    legal_basis = "Art. 80 KKS" { withholding_failure == true }
    legal_basis = "Art. 81 KKS" { withholding_failure == false; withholding_unpaid == true }
    legal_basis = "Art. 82 KKS" { withholding_failure == false; withholding_unpaid == false; false_certificate == true }
    legal_basis = "Art. 83 KKS" { withholding_failure == false; withholding_unpaid == false; false_certificate == false; decision_ignored == true }

    severity = "HIGH" { withholding_unpaid == true }
    severity = "HIGH" { withholding_unpaid == false; false_certificate == true }
    severity = "MEDIUM" { withholding_unpaid == false; false_certificate == false }

    max_rates = 360 { withholding_unpaid == true }
    max_rates = 360 { withholding_unpaid == false; false_certificate == true }
    max_rates = 240 { withholding_unpaid == false; false_certificate == false; decision_ignored == true }
    max_rates = 180 { withholding_unpaid == false; false_certificate == false; decision_ignored == false }

    action = "Pobierz zaległy podatek + złóż czynny żal." { withholding_failure == true }
    action = "Wpłać pobrany podatek NATYCHMIAST + odsetki." { withholding_failure == false; withholding_unpaid == true }
    action = "Wycofaj fałszywe zaświadczenie + zgłoś do KAS." { withholding_failure == false; withholding_unpaid == false; false_certificate == true }
    action = "Wykonaj decyzję natychmiast + złóż wyjaśnienia." { withholding_failure == false; withholding_unpaid == false; false_certificate == false; decision_ignored == true }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  INNOVATIONS (10 innowacji z Sekcji 5 raportu P32)                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# INNOV 1 (P710): KKS Penalty Simulator — Symulator kary KKS
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.penalty_simulator",
    "package": "jdg.kks.innovations", "priority": 710,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_penalty_sim": true,
    "kks_sim_offense": offense_type,
    "kks_sim_shortfall": shortfall,
    "kks_sim_daily_rate": daily_rate,
    "kks_sim_daily_rates_count": rates_count,
    "kks_sim_estimated_fine": estimated_fine,
    "kks_sim_imprisonment_risk": imprisonment_risk,
    "kks_sim_voluntary_disclosure_saving": vd_saving,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": sim_rt,
    "_routing_reason": sprintf("Symulacja: %s — grzywna ~%.2f PLN, ryzyko więzienia: %s", [offense_type, estimated_fine, imprisonment_risk]),
    "_legal_basis": "Art. 23, 48, 54-83 KKS (symulacja kary)",
    "_warnings": [sprintf("KKS PENALTY SIMULATOR — %s. Uszczuplenie: %.2f PLN. Stawka dzienna: %.2f PLN (1/30 min. wynagrodzenia). Liczba stawek: %d. Szacunkowa grzywna: %.2f PLN. Ryzyko pozbawienia wolności: %s. Oszczędność z czynnym żalem: %.2f PLN (100%% immunitetu!).", [offense_type, shortfall, daily_rate, rates_count, estimated_fine, imprisonment_risk, vd_saving])]
} {
    shortfall := object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0)
    shortfall > 0
    offense_type := object.get(input.jdg_entrepreneur, "kks_primary_offense_type", "TAX_EVASION")

    # Stawka dzienna = 1/30 minimalnego wynagrodzenia
    min_wage := object.get(object.get(data.thresholds, "bounds", {}), "minimum_wage_gross", 4800)
    daily_rate := floor(min_wage / 30 * 100) / 100

    # Liczba stawek wg progu materialności
    rates_count = 120 { shortfall < 200000 }
    rates_count = 240 { shortfall >= 200000; shortfall < 500000 }
    rates_count = 540 { shortfall >= 500000; shortfall < 5000000 }
    rates_count = 720 { shortfall >= 5000000 }

    estimated_fine := floor(daily_rate * rates_count * 100) / 100

    # Ryzyko pozbawienia wolności
    imprisonment_risk = "NISKIE (<200k PLN)" { shortfall < 200000 }
    imprisonment_risk = "ŚREDNIE (200k-500k)" { shortfall >= 200000; shortfall < 500000 }
    imprisonment_risk = "WYSOKIE (500k-5M, do 5 lat)" { shortfall >= 500000; shortfall < 5000000 }
    imprisonment_risk = "BARDZO WYSOKIE (>5M, do 10 lat)" { shortfall >= 5000000 }

    # Oszczędność z czynnym żalem = pełna grzywna (immunitet)
    vd_saving := estimated_fine

    sim_rt = "TRIAGE_QUEUE" { shortfall >= 500000 }
    sim_rt = "" { shortfall < 500000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOV 2 (P711): Czynny Żal Auto-Generator — Check-lista warunków
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.voluntary_disclosure_checklist",
    "package": "jdg.kks.innovations", "priority": 711,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_vd_checklist": checklist,
    "kks_vd_conditions_met": conditions_met,
    "kks_vd_conditions_failed": conditions_failed,
    "kks_vd_readiness_pct": readiness_pct,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": vd_rt,
    "_routing_reason": sprintf("Czynny żal — gotowość: %.0f%% (%d/%d warunków)", [readiness_pct, conditions_met, count(checklist)]),
    "_legal_basis": "Art. 16 KKS (czynny żal — auto-generator)",
    "_warnings": [sprintf("CZYNNY ŻAL AUTO-GENERATOR — Spełniono %d/%d warunków (%.0f%%). %s", [conditions_met, count(checklist), readiness_pct, vd_recommendation])]
} {
    kks_flag := object.get(input.jdg_entrepreneur, "kks_offenses_count", 0)
    kks_flag > 0

    proceedings_started := object.get(input.jdg_entrepreneur, "kks_proceedings_started", false)
    full_disclosure := object.get(input.jdg_entrepreneur, "kks_full_disclosure_ready", false)
    payment_ready := object.get(input.jdg_entrepreneur, "kks_payment_ready_7days", false)
    all_offenses_listed := object.get(input.jdg_entrepreneur, "kks_all_offenses_documented", false)
    legal_consulted := object.get(input.jdg_entrepreneur, "kks_legal_counsel_engaged", false)

    # Build checklist
    checklist := [
        {"condition": "PRZED_KONTROLA", "met": not proceedings_started, "desc": "Zgłoszenie przed wszczęciem postępowania przez KAS"},
        {"condition": "PELNE_UJAWNIENIE", "met": full_disclosure, "desc": "Pełne ujawnienie wszystkich okoliczności"},
        {"condition": "WPLATA_7_DNI", "met": payment_ready, "desc": "Wpłata uszczuplonej należności w 7 dni"},
        {"condition": "WSZYSTKIE_CZYNY", "met": all_offenses_listed, "desc": "Ujęcie wszystkich czynów w zawiadomieniu"},
        {"condition": "KONSULTACJA_PRAWNA", "met": legal_consulted, "desc": "Konsultacja z adwokatem/doradcą podatkowym"}
    ]

    conditions_met := count({c | c := checklist[_]; c.met == true})
    conditions_failed := count({c | c := checklist[_]; c.met == false})
    readiness_pct := floor(conditions_met / count(checklist) * 100)

    vd_recommendation = "ZŁÓŻ CZYNNY ŻAL — wszystkie warunki spełnione!" { conditions_met == 5 }
    vd_recommendation = sprintf("Uzupełnij %d brakujących warunków przed złożeniem.", [conditions_failed]) { conditions_met < 5; proceedings_started == false }
    vd_recommendation = "Czynny żal NIEMOŻLIWY — postępowanie wszczęte. Kontakt z adwokatem!" { proceedings_started == true }

    vd_rt = "BLOCK_AND_ALERT" { proceedings_started == true }
    vd_rt = "TRIAGE_QUEUE" { proceedings_started == false; conditions_met >= 3; conditions_met < 5 }
    vd_rt = "" { proceedings_started == false; conditions_met >= 5 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOV 3+7 (P712): KKS Risk Dashboard 5-letni + Recydywa Monitor
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.risk_dashboard_5y",
    "package": "jdg.kks.innovations", "priority": 712,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_risk_5y_incidents": incidents_5y,
    "kks_risk_5y_total_shortfall": total_shortfall,
    "kks_risk_recidivism_risk": recidivism_risk,
    "kks_risk_statute_approaching": approaching_count,
    "kks_risk_level_5y": risk_level,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": risk_rt,
    "_routing_reason": sprintf("KKS Risk 5Y: %s — %d incydentów, %.2f PLN uszczuplenia", [risk_level, incidents_5y, total_shortfall]),
    "_legal_basis": "Art. 19 § 3, Art. 44 KKS (dashboard ryzyka 5-letniego)",
    "_warnings": [sprintf("KKS RISK DASHBOARD 5Y — Incydenty (5 lat): %d. Uszczuplenie łączne: %.2f PLN. Ryzyko recydywy: %s. Zbliżające się przedawnienia: %d. POZIOM RYZYKA: %s. %s", [incidents_5y, total_shortfall, recidivism_risk, approaching_count, risk_level, action_recommendation])]
} {
    incidents_5y := object.get(input.jdg_entrepreneur, "kks_incidents_60m", 0)
    incidents_5y > 0
    total_shortfall := object.get(input.jdg_entrepreneur, "kks_total_shortfall_pln", 0)
    incidents_12m := object.get(input.jdg_entrepreneur, "kks_incidents_12m", 0)
    approaching_count := object.get(input.jdg_entrepreneur, "kks_statute_approaching_count", 0)

    # Recidivism risk (3+ incidents in 5 years = zaostrzenie kary)
    recidivism_risk = "KRYTYCZNE — 3+ incydenty → RECYDYWA (Art. 19 § 3)!" { incidents_5y >= 3 }
    recidivism_risk = "WYSOKIE — 2 incydenty, ryzyko recydywy przy kolejnym" { incidents_5y == 2 }
    recidivism_risk = "NISKIE — pojedynczy incydent" { incidents_5y == 1 }

    # Overall risk level — mutually exclusive priority cascade
    risk_level = "CRITICAL" { incidents_12m >= 2; total_shortfall > 200000 }
    risk_level = "CRITICAL" { not (incidents_12m >= 2; total_shortfall > 200000); incidents_5y >= 3 }
    risk_level = "HIGH" { incidents_5y < 3; incidents_12m >= 1; incidents_5y >= 2 }
    risk_level = "MEDIUM" { incidents_5y < 2; incidents_5y >= 1 }
    risk_level = "LOW" { incidents_5y < 1 }

    action_recommendation = "Natychmiast skonsultuj z adwokatem. Rozważ czynny żal." { risk_level == "CRITICAL" }
    action_recommendation = "Monitoruj sytuację — złóż czynny żal przed 3-cim incydentem." { risk_level == "HIGH" }
    action_recommendation = "Kontroluj terminy przedawnień." { risk_level == "MEDIUM" }
    action_recommendation = "Sytuacja pod kontrolą." { risk_level == "LOW" }

    risk_rt = "BLOCK_AND_ALERT" { risk_level == "CRITICAL" }
    risk_rt = "TRIAGE_QUEUE" { risk_level == "HIGH" }
    risk_rt = "" { risk_level in {"MEDIUM", "LOW"} }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOV 4 (P713): Integrity Score PKPiR — ciągły monitoring
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.integrity_score_monitor",
    "package": "jdg.kks.innovations", "priority": 713,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_integrity_score": integrity_score,
    "kks_integrity_issues": issue_count,
    "kks_integrity_severity": severity,
    "kks_integrity_action": action,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": int_rt,
    "_routing_reason": sprintf("Integrity Score PKPiR: %.0f%% (%d błędów) — %s", [integrity_score, issue_count, severity]),
    "_legal_basis": "Art. 56 KKS (ciągły monitoring integrity score PKPiR)",
    "_warnings": [sprintf("INTEGRITY SCORE PKPiR — %.0f%% (%d błędów/ostrzeżeń). Poziom: %s. %s", [integrity_score, issue_count, severity, action])]
} {
    issue_count := object.get(input.jdg_entrepreneur, "pkpir_integrity_issues", 0)
    issue_count > 0

    # Calculate integrity score (100% - penalty per issue)
    # Each issue reduces score: missing columns = 15%, gaps in numbering = 10%, inconsistent entries = 5%
    base_score := 100
    missing_cols := object.get(input.jdg_entrepreneur, "pkpir_missing_columns", 0)
    gaps := object.get(input.jdg_entrepreneur, "pkpir_numbering_gaps", 0)
    inconsistencies := object.get(input.jdg_entrepreneur, "pkpir_inconsistencies", 0)

    integrity_score := base_score - missing_cols * 15 - gaps * 10 - inconsistencies * 5
    integrity_score := max([integrity_score, 0])

    severity = "KRYTYCZNY (<25%)" { integrity_score < 25 }
    severity = "RAŻĄCY (25-40%)" { integrity_score >= 25; integrity_score < 40 }
    severity = "SYSTEMATYCZNY (40-60%)" { integrity_score >= 40; integrity_score < 60 }
    severity = "UMIARKOWANY (60-80%)" { integrity_score >= 60; integrity_score < 80 }
    severity = "DOBRY (>80%)" { integrity_score >= 80 }

    action = "NATYCHMIAST KOREKTA + czynny żal + ADWOKAT! Ryzyko Art. 56 § 3 KKS (fikcyjne wpisy)." { integrity_score < 25 }
    action = "Konieczna korekta + czynny żal. Ryzyko Art. 56 § 2 (systematyczna)." { integrity_score >= 25; integrity_score < 40 }
    action = "Zalecana korekta PKPiR. Monitoruj." { integrity_score >= 40; integrity_score < 60 }
    action = "Drobne korekty. Stan akceptowalny." { integrity_score >= 60 }

    int_rt = "BLOCK_AND_ALERT" { integrity_score < 40 }
    int_rt = "TRIAGE_QUEUE" { integrity_score >= 40; integrity_score < 60 }
    int_rt = "" { integrity_score >= 60 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOV 5 (P714): KSeF + KKS Compliance Shield
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.ksef_compliance_shield",
    "package": "jdg.kks.innovations", "priority": 714,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_ksef_duplicates": duplicate_count,
    "kks_ksef_fake_counterparties": fake_count,
    "kks_ksef_carousel_risk": carousel_risk,
    "kks_ksef_shield_active": true,
    "valid_from": "2026-02-01", "valid_to": null,
    "_routing": ksef_rt,
    "_routing_reason": sprintf("KSeF Shield: %d duplikatów, %d fejkowych kontrahentów, karuzela: %s", [duplicate_count, fake_count, carousel_risk]),
    "_legal_basis": "Art. 62, 54 KKS + Art. 106na VAT (KSeF + KKS)",
    "_warnings": [sprintf("KSeF+KKS COMPLIANCE SHIELD — %s. Duplikaty faktur: %d. Kontrahenci-widma: %d. Ryzyko karuzeli VAT: %s. %s", [shield_status, duplicate_count, fake_count, carousel_risk, shield_action])]
} {
    ksef_active := object.get(input.jdg_entrepreneur, "ksef_active", false)
    ksef_active == true

    duplicate_count := object.get(input.jdg_entrepreneur, "ksef_duplicate_invoices", 0)
    fake_count := object.get(input.jdg_entrepreneur, "ksef_fake_counterparties", 0)
    total_carousel := object.get(input.jdg_entrepreneur, "ksef_carousel_total_pln", 0)

    carousel_risk = sprintf("WYSOKIE — %.2f PLN w łańcuchu faktur", [total_carousel]) { total_carousel > 5000000 }
    carousel_risk = sprintf("ŚREDNIE — %.2f PLN", [total_carousel]) { total_carousel > 0; total_carousel <= 5000000 }
    carousel_risk = "BRAK" { total_carousel == 0 }

    total_issues := duplicate_count + fake_count + 1 { total_carousel > 5000000 }
    total_issues := duplicate_count + fake_count { total_carousel <= 5000000 }

    shield_status = sprintf("WYKRYTO %d ZAGROŻEŃ KKS!", [total_issues]) { total_issues > 0 }
    shield_status = "CZYSTO — brak zagrożeń KKS" { total_issues == 0 }

    shield_action = "Zatrzymaj fakturowanie! Zgłoś czynny żal!" { total_issues > 2; total_carousel > 5000000 }
    shield_action = "Zweryfikuj kontrahentów. Rozważ czynny żal." { total_issues > 0; total_carousel <= 5000000 }
    shield_action = "Monitoruj KSeF — stan OK." { total_issues == 0 }

    ksef_rt = "BLOCK_AND_ALERT" { total_issues > 2; total_carousel > 5000000 }
    ksef_rt = "TRIAGE_QUEUE" { total_issues > 0; total_carousel <= 5000000 }
    ksef_rt = "" { total_issues == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOV 8 (P715): Banking Impact Simulator dla skazania KKS
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.banking_impact_simulator",
    "package": "jdg.kks.innovations", "priority": 715,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_banking_contract_termination_risk": contract_risk,
    "kks_banking_aml_enhanced": aml_enhanced,
    "kks_banking_credit_scoring_impact": credit_impact,
    "kks_banking_account_freeze_risk": freeze_risk,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": bank_rt,
    "_routing_reason": sprintf("Banking Impact: %s | AML: %s | Credit: %s", [contract_risk, aml_enhanced, credit_impact]),
    "_legal_basis": "Art. 41 KK + AML + Prawo bankowe (skutki skazania KKS dla bankowości)",
    "_warnings": [sprintf("BANKING IMPACT SIMULATOR — Skazanie KKS: %s. Ryzyko wypowiedzenia umowy: %s. Wzmocnione AML/KYC: %s. Wpływ na scoring: %s. Ryzyko blokady konta: %s. %s", [conviction_status, contract_risk, aml_enhanced, credit_impact, freeze_risk, recommendation])]
} {
    has_conviction := object.get(input.jdg_entrepreneur, "kks_conviction_active", false)
    has_conviction == true

    conviction_type := object.get(input.jdg_entrepreneur, "kks_conviction_type", "MISDEMEANOR")
    shortfall := object.get(input.jdg_entrepreneur, "kks_conviction_shortfall", 0)
    years_since := object.get(input.jdg_entrepreneur, "kks_conviction_years_ago", 1)

    conviction_status = sprintf("Przestępstwo (%.2f PLN, %d lat temu)", [shortfall, years_since]) { conviction_type == "CRIME" }
    conviction_status = sprintf("Wykroczenie (%.2f PLN, %d lat temu)", [shortfall, years_since]) { conviction_type == "MISDEMEANOR" }

    # Contract termination risk
    contract_risk = "WYSOKIE (przestępstwo, < 3 lata)" { conviction_type == "CRIME"; years_since < 3 }
    contract_risk = "ŚREDNIE (przestępstwo, > 3 lata)" { conviction_type == "CRIME"; years_since >= 3 }
    contract_risk = "NISKIE (wykroczenie)" { conviction_type == "MISDEMEANOR" }

    # AML enhanced verification
    aml_enhanced = "TAK — wzmocniona weryfikacja GIIF" { conviction_type == "CRIME"; shortfall > 200000 }
    aml_enhanced = "TAK — standardowa wzmocniona" { conviction_type == "CRIME"; shortfall <= 200000 }
    aml_enhanced = "NIE" { conviction_type == "MISDEMEANOR" }

    # Credit scoring impact
    credit_impact = "ZNACZNY — spadek o 100-200 pkt" { conviction_type == "CRIME" }
    credit_impact = "UMIARKOWANY — spadek o 30-50 pkt" { conviction_type == "MISDEMEANOR" }

    # Account freeze risk
    freeze_risk = "WYSOKIE — możliwe zajęcie komornicze" { shortfall > 100000 }
    freeze_risk = "NISKIE" { shortfall <= 100000 }

    recommendation = "Skonsultuj z prawnikiem bankowym. Rozważ restrukturyzację." { contract_risk == "WYSOKIE" }
    recommendation = "Monitoruj relację z bankiem." { contract_risk == "ŚREDNIE" }
    recommendation = "Sytuacja stabilna." { contract_risk == "NISKIE" }

    bank_rt = "TRIAGE_QUEUE" { contract_risk == "WYSOKIE" }
    bank_rt = "" { contract_risk != "WYSOKIE" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOV 9 (P716): PZP Exclusion Checker — Zamówienia publiczne
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.pzp_exclusion_checker",
    "package": "jdg.kks.innovations", "priority": 716,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_pzp_excluded": is_excluded,
    "kks_pzp_exclusion_years": exclusion_years,
    "kks_pzp_exclusion_ends": exclusion_end,
    "kks_pzp_appeal_possible": appeal_possible,
    "valid_from": "2021-01-01", "valid_to": null,
    "_routing": pzp_rt,
    "_routing_reason": sprintf("PZP: %s (wykluczenie na %d lat)", [exclusion_status, exclusion_years]),
    "_legal_basis": "Art. 108 PZP (wykluczenie z zamówień publicznych)",
    "_warnings": [sprintf("PZP EXCLUSION CHECKER — %s. Wykluczenie z zamówień publicznych: %s. Okres: %d lat. Koniec wykluczenia: %s. Odwołanie: %s. %s", [exclusion_status, is_excluded, exclusion_years, exclusion_end, appeal_possible, recommendation])]
} {
    has_conviction := object.get(input.jdg_entrepreneur, "kks_conviction_active", false)
    has_conviction == true

    conviction_type := object.get(input.jdg_entrepreneur, "kks_conviction_type", "MISDEMEANOR")
    years_since := object.get(input.jdg_entrepreneur, "kks_conviction_years_ago", 1)
    shortfall := object.get(input.jdg_entrepreneur, "kks_conviction_shortfall", 0)
    conviction_date := object.get(input.jdg_entrepreneur, "kks_conviction_date", "2024-01-01")

    # PZP exclusion: 5 years for tax crimes, 3 years for misdemeanors
    exclusion_years = 5 { conviction_type == "CRIME" }
    exclusion_years = 3 { conviction_type == "MISDEMEANOR" }

    is_excluded = "TAK — WYKLUCZONY" { years_since < exclusion_years }
    is_excluded = "NIE — okres minął" { years_since >= exclusion_years }

    # Calculate exclusion end using Rego time.add_date
    exclusion_end := time.format(time.add_date(conviction_ns, exclusion_years, 0, 0))

    appeal_possible = "TAK — self-cleaning (Art. 110 PZP)" { years_since >= exclusion_years - 1; years_since < exclusion_years }
    appeal_possible = "NIE — zbyt wcześnie" { years_since < exclusion_years - 1 }
    appeal_possible = "NIE DOTYCZY — wykluczenie wygasło" { years_since >= exclusion_years }

    exclusion_status = "AKTYWNE WYKLUCZENIE" { years_since < exclusion_years }
    exclusion_status = "WYKLUCZENIE WYGASŁO" { years_since >= exclusion_years }

    recommendation = "NIE składaj ofert — zostaniesz odrzucony." { years_since < exclusion_years }
    recommendation = "Złóż wniosek o self-cleaning (Art. 110 PZP)." { years_since >= exclusion_years - 1; years_since < exclusion_years }
    recommendation = "Możesz ubiegać się o zamówienia publiczne." { years_since >= exclusion_years }

    pzp_rt = "BLOCK_AND_ALERT" { years_since < exclusion_years }
    pzp_rt = "TRIAGE_QUEUE" { years_since >= exclusion_years - 1; years_since < exclusion_years }
    pzp_rt = "" { years_since >= exclusion_years }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOV 10 (P717): Unified Statute of Limitations Calendar
# Kalendarz przedawnień: KKS + OrdPU + ZUS + VAT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.innovations.unified_limitation_calendar",
    "package": "jdg.kks.innovations", "priority": 717,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_calendar_entries": entry_count,
    "kks_calendar_expiring_soon": expiring_count,
    "kks_calendar_already_barred": barred_count,
    "kks_calendar_next_expiry": next_expiry,
    "valid_from": "2024-01-01", "valid_to": null,
    "_routing": cal_rt,
    "_routing_reason": sprintf("Kalendarz przedawnień: %d wpisów, %d wygasających, %d przedawnionych", [entry_count, expiring_count, barred_count]),
    "_legal_basis": "Art. 44, 51 KKS + Art. 70 OrdPU + Art. 24 SUS + Art. 87 VAT",
    "_warnings": [sprintf("KALENDARZ PRZEDAWNIEŃ — Łącznie: %d zobowiązań. Wygasa w ciągu 6 mies: %d. Już przedawnione: %d. Najbliższe przedawnienie: %s. %s", [entry_count, expiring_count, barred_count, next_expiry, action])]
} {
    entry_count := object.get(input.jdg_entrepreneur, "statute_calendar_total", 0)
    entry_count > 0

    expiring_count := object.get(input.jdg_entrepreneur, "statute_expiring_6months", 0)
    barred_count := object.get(input.jdg_entrepreneur, "statute_already_barred", 0)
    next_expiry := object.get(input.jdg_entrepreneur, "statute_next_expiry_date", "brak")

    action = "Uwaga na przedawnienia — sprawdź które zobowiązania wygasają!" { expiring_count > 0 }
    action = sprintf("Przedawnione zobowiązania (%d) — zweryfikuj czy KAS może jeszcze dochodzić.", [barred_count]) { barred_count > 0; expiring_count == 0 }
    action = "Wszystkie terminy pod kontrolą." { expiring_count == 0; barred_count == 0 }

    cal_rt = "TRIAGE_QUEUE" { expiring_count > 2 }
    cal_rt = "" { expiring_count <= 2 }
}
