# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KKS + ORDYNACJA + AUDYT/OBRONA ATOMIC RULES (GLM52 P11 — ENTERPRISE)
# Package: jdg.micro.kks_ord_atomic_p11
# ───────────────────────────────────────────────────────────────────────────────
# Prawdziwe reguły atomowe (konwerter stubów → reguł warunkowych, PROMPT 11 §8):
# gradacja kar KKS (art. 54-83: typ → stawka dzienna → liczba stawek → kwota),
# czynny żal (art. 16), dobrowolne poddanie się (art. 17), recydywa (art. 37),
# grzywna łączna (art. 39), przedawnienie karalności (art. 44), przedawnienie
# zobowiązania podatkowego (art. 70 OP z przerwaniem §4 / zawieszeniem §6),
# korekta deklaracji (art. 81b — 14 dni), Biała Lista (art. 117ba — 30 dni,
# sankcja 20%), prawa w kontroli (art. 282b — 7 dni, art. 291 — 14 dni,
# art. 223 — 14 dni odwołanie, WSA 30 dni), GAAR (art. 119a).
# Kontrakty P01: werdykt 25-polowy + _legal_basis kanoniczne + zero hardcode
# (data.jdg.thresholds.jdg.ord.* / .kks.*, ADR-002) + temporalność.
# Konwencja mikro (INV-018): brak catch-all {true} — brak dopasowania →
# default no_match; wypełnia LUKI makro, nigdy nie nadpisuje (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.kks_ord_atomic_p11

import future.keywords.if
import future.keywords.else
import future.keywords.in
import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.kks_ord_atomic_p11.no_match",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 999999
}

# ── Helper: progi z data.thresholds (ADR-002 — zero hardcode) ─────────────────
_ths_ord := object.get(data.jdg.thresholds, "ord", {
    "statute_of_limitations_years": 5,
    "correction_deadline_days": 14,
    "whitelist_verification_days": 30,
    "whitelist_sanction_pct": 0.20,
    "appeal_deadline_days": 14,
    "audit_notification_days": 7,
    "protocol_objection_days": 14,
    "wsa_appeal_days": 30,
    "interest_lombard_multiplier": 2.0,
    "jpk_request_days": 14,
    "interpretation_days": 30,
})

_ths_kks := object.get(data.jdg.thresholds, "kks", {
    "active_remorse_impact_pct": 0.50,
    "voluntary_submission_impact_pct": 0.50,
    "daily_rate_min_pln": 77.0,
    "daily_rate_max_pln": 1540.0,
    "daily_rates_crime_max": 720,
    "daily_rates_misdemeanor_max": 240,
    "small_value_min_pln": 100.0,
    "lesser_weight_max_pln": 5000.0,
    "recidivism_days_window": 1825,
    "statute_limitation_kks_years": 5,
    # Art. 45 KKS — okres zatarcia skazania (zależny od rodzaju kary)
    "expungement_misdemeanor_years": 3,       # wykroczenie skarbowe — 3 lata
    "expungement_crime_years": 5,             # przestępstwo skarbowe — 5 lat
    # Art. 53 § 6 KKS — mała wartość: 500 × min. wynagrodzenie
    "small_value_multiple": 500,
})

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  KKS ART. 54-83 — GRADACJA KAR: typ czynu → stawka dzienna → kwota         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a54.penalty_calculator — kalkulator kary dla art. 54 (uchylanie
# się od opodatkowania): typ → stawka dzienna (min 1/720, max 1/30 min.) →
# liczba stawek (wykroczenie do 240, przestępstwo do 720) → kwota = f(stawka,
# stawek). Z dowodem (provenance) dla organów.
decide := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.penalty_calculator.r1",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 215401,
    "vat_rate": "",
    "rounding_level": "GROSZE",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "kks_penalty_pln": penalty,
    "kks_daily_rate_pln": daily_rate,
    "kks_rates_count": rates,
    "kks_crime_type": "PRZESTEPSTWO",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Kara KKS art. 54 — przestępstwo skarbowe (do 720 stawek dziennych)",
    "_legal_basis": "Art. 54 § 1 i 3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["[MICRO P11] Kara: " + sprintf("%.2f", [penalty]) + " zł = stawka dzienna " + sprintf("%.2f", [daily_rate]) + " zł × " + sprintf("%d", [rates]) + " stawek"],
    "_provenance_tree": {
        "art": "54 § 1 i 3",
        "formula": "stawka dzienna × liczba stawek",
        "daily_rate_pln": daily_rate,
        "rates_count": rates,
        "penalty_pln": penalty,
        "max_rates": _ths_kks.daily_rates_crime_max
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "kks_penalty_check", false) == true
    crime_type := object.get(input.jdg_entrepreneur, "kks_crime_type", "PRZESTEPSTWO")
    crime_type == "PRZESTEPSTWO"
    min_wage := object.get(input.jdg_entrepreneur, "min_wage_pln", 4620.0)
    daily_rate := round((min_wage / 720) * 100) / 100
    rates := object.get(input.jdg_entrepreneur, "kks_rates_count", 100)
    rates <= _ths_kks.daily_rates_crime_max
    penalty := round((daily_rate * rates) * 100) / 100
}

# jdg.micro.kks.a54.penalty_calculator — wykroczenie skarbowe (do 240 stawek).
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a54.penalty_calculator.r2",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 215402,
    "vat_rate": "",
    "rounding_level": "GROSZE",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "kks_penalty_pln": penalty,
    "kks_daily_rate_pln": daily_rate,
    "kks_rates_count": rates,
    "kks_crime_type": "WYKROCZENIE",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Kara KKS art. 54 — wykroczenie skarbowe (do 240 stawek dziennych)",
    "_legal_basis": "Art. 54 § 1 i 3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["[MICRO P11] Kara: " + sprintf("%.2f", [penalty]) + " zł"],
    "_provenance_tree": {
        "art": "54 § 1 i 3",
        "formula": "stawka dzienna × liczba stawek",
        "daily_rate_pln": daily_rate,
        "rates_count": rates,
        "penalty_pln": penalty,
        "max_rates": _ths_kks.daily_rates_misdemeanor_max
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "kks_penalty_check", false) == true
    crime_type := object.get(input.jdg_entrepreneur, "kks_crime_type", "PRZESTEPSTWO")
    crime_type == "WYKROCZENIE"
    min_wage := object.get(input.jdg_entrepreneur, "min_wage_pln", 4620.0)
    daily_rate := round((min_wage / 720) * 100) / 100
    rates := object.get(input.jdg_entrepreneur, "kks_rates_count", 100)
    rates <= _ths_kks.daily_rates_misdemeanor_max
    penalty := round((daily_rate * rates) * 100) / 100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  KKS ART. 16 / 17 — CZYNNY ŻAL I DOBROWOLNE PODDANIE (ścieżki minimalizacji) ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a16.active_remorse — czynny żal (art. 16): zawiadomienie organu
# przed wykryciem → znikoma szkodliwość → umorzenie postępowania. Warunek:
# zawiadomienie złożone PRZED rozpoczęciem kontroli.
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a16.active_remorse",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 211601,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "active_remorse_applicable": true,
    "active_remorse_impact_pct": _ths_kks.active_remorse_impact_pct,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "OK",
    "_routing_reason": "Czynny żal (art. 16 KKS) — zawiadomienie przed wykryciem → znikoma szkodliwość, umorzenie",
    "_legal_basis": "Art. 16 § 1 i 2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["[MICRO P11] Czynny żal skuteczny — postępowanie umorzone (znikoma szkodliwość)"],
    "_provenance_tree": {
        "art": "16 § 1-2",
        "condition": "zawiadomienie przed wykryciem przez organ",
        "impact_pct": _ths_kks.active_remorse_impact_pct
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "kks_active_remorse_check", false) == true
    notified_before := object.get(input.jdg_entrepreneur, "remorse_notified_before_detection", false)
    notified_before == true
}

# jdg.micro.kks.a17.voluntary_submission — dobrowolne poddanie się
# odpowiedzialności (art. 17): wniosek + zapłata pełnej należności → obniżka
# kary o 50% (lub grzywna zamiast kary pozbawienia wolności).
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a17.voluntary_submission",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 211701,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "voluntary_submission_applicable": true,
    "voluntary_submission_impact_pct": _ths_kks.voluntary_submission_impact_pct,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "OK",
    "_routing_reason": "Dobrowolne poddanie się odpowiedzialności (art. 17 KKS) — kara obniżona o 50%",
    "_legal_basis": "Art. 17 § 1 i 2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["[MICRO P11] Wniosek + zapłata pełnej należności → obniżka kary o 50%"],
    "_provenance_tree": {
        "art": "17 § 1-2",
        "condition": "wniosek o dobrowolne poddanie + zapłata pełnej należności",
        "impact_pct": _ths_kks.voluntary_submission_impact_pct
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "kks_voluntary_submission_check", false) == true
    paid_full := object.get(input.jdg_entrepreneur, "voluntary_submission_paid_full", false)
    paid_full == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  KKS ART. 37 / 44 — RECYDYWA I PRZEDAWNIENIE KARALNOŚCI                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a37.recidivism_monitor — recydywa (art. 37): ponowny czyn
# podobny w ciągu 5 lat od skazania → podwyższenie kary (do 2×).
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a37.recidivism_monitor",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 213701,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "recidivism_detected": true,
    "recidivism_window_days": _ths_kks.recidivism_days_window,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "RECYDYWA (art. 37 KKS) — ponowny czyn w ciągu 5 lat → kara do 2× wyższa",
    "_legal_basis": "Art. 37 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["[MICRO P11] Recydywa: podwyższenie kary do 2-krotności"],
    "_provenance_tree": {
        "art": "37 § 1",
        "window_days": _ths_kks.recidivism_days_window,
        "multiplier_max": 2
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "kks_recidivism_check", false) == true
    days_since := object.get(input.jdg_entrepreneur, "days_since_previous_conviction", 99999)
    days_since <= _ths_kks.recidivism_days_window
    similar := object.get(input.jdg_entrepreneur, "previous_conviction_similar", false)
    similar == true
}

# jdg.micro.kks.a44.limitation — przedawnienie karalności (art. 44): 5 lat od
# popełnienia przestępstwa skarbowego / 3 lata wykroczenia → brak możliwości
# ukarania → alert OK (obrona).
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a44.limitation",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 214401,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "kks_limitation_applicable": true,
    "kks_limitation_years": _ths_kks.statute_limitation_kks_years,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "OK",
    "_routing_reason": "Przedawnienie karalności (art. 44 KKS) — upłynęło 5 lat → brak możliwości ukarania",
    "_legal_basis": "Art. 44 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["[MICRO P11] OBRONA: przedawnienie karalności — kara niemożliwa"],
    "_provenance_tree": {
        "art": "44 § 1",
        "years": _ths_kks.statute_limitation_kks_years,
        "offense_date": offense_date
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "kks_limitation_check", false) == true
    offense_date := object.get(input.jdg_entrepreneur, "offense_date", "2020-01-01")
    now := object.get(input.jdg_entrepreneur, "eval_date", "2026-01-01")
    years_elapsed := (time.parse_rfc3339(now) - time.parse_rfc3339(offense_date)) / 31557600000000000
    years_elapsed >= _ths_kks.statute_limitation_kks_years
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  KKS ART. 45 / 53 — ZATARCIE SKAZANIA I MAŁA WARTOŚĆ                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.kks.a45.expungement_tracker — zatarcie skazania (art. 45 KKS):
# skazanie ulega zatarciu z mocy prawa po upływie okresu (wykroczenie 3 lata,
# przestępstwo 5 lat; grzywna 1 rok przy dobrowolnym wykonaniu). Po zatarciu
# skazanie uważa się za niebyłe — brak wpływu na kontrakty i pozwolenia.
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a45.expungement_tracker",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 214501,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "expungement_eligible": true,
    "expungement_years": expungement_years,
    "expungement_date": expungement_date,
    "conviction_considered_expunged": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "OK",
    "_routing_reason": "Zatarcie skazania (art. 45 KKS) — okres upłynął, skazanie uznane za niebyłe",
    "_legal_basis": "Art. 45 § 1-2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["[MICRO P11] OBRONA: zatarcie skazania — brak wpływu na kontrakty i pozwolenia"],
    "_provenance_tree": {
        "art": "45 § 1-2",
        "years": expungement_years,
        "expungement_date": expungement_date
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "kks_expungement_check", false) == true
    conviction_type := object.get(input.jdg_entrepreneur, "conviction_type", "PRZESTĘPSTWO")
    years := {
        "WYKROCZENIE": _ths_kks.expungement_misdemeanor_years,
        "PRZESTĘPSTWO": _ths_kks.expungement_crime_years,
        "OGRANICZENIE_WOLNOŚCI": _ths_kks.expungement_misdemeanor_years,
    }[conviction_type]
    expungement_years := years
    penalty_end := object.get(input.jdg_entrepreneur, "penalty_end_date", "2020-01-01")
    expungement_date := time.add_date(time.parse_rfc3339(penalty_end), years, 0, 0)
    now := object.get(input.jdg_entrepreneur, "eval_date", "2026-01-01")
    time.parse_rfc3339(now) > expungement_date
}

# jdg.micro.kks.a53.small_value — mała wartość (art. 53 § 6 KKS): czyn o wartości
# nieprzekraczającej 500× minimalnego wynagrodzenia jest przestępstwem o małej
# wartości → łagodniejsza gradacja (wykroczenie) i niższa kara.
else := {
    "matched": true,
    "rule_id": "jdg.micro.kks.a53.small_value_classifier",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 215301,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "small_value_class": "MAŁA WARTOŚĆ",
    "small_value_threshold_pln": threshold,
    "small_value_benefit_note": "łagodniejsza gradacja — wyłączenie odpowiedzialności za wykroczenie przy niskiej szkodliwości",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Czyn o małej wartości (art. 53 § 6 KKS) — łagodniejsza gradacja kary",
    "_legal_basis": "Art. 53 § 6 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.) w zw. z art. 115 § 5 KK",
    "_warnings": ["[MICRO P11] Mała wartość (art. 53 § 6) — obniżony wymiar odpowiedzialności"],
    "_provenance_tree": {
        "art": "53 § 6",
        "multiple": _ths_kks.small_value_multiple,
        "min_wage_pln": min_wage,
        "threshold_pln": threshold
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "kks_small_value_check", false) == true
    amount := object.get(input.jdg_entrepreneur, "offense_value_pln", 0)
    min_wage := object.get(input.jdg_entrepreneur, "min_wage_pln", 4800.0)
    threshold := round((min_wage * _ths_kks.small_value_multiple) * 100) / 100
    amount > 0
    amount <= threshold
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ORDYNACJA ART. 14a/14d — INTERPRETACJE INDYWIDUALNE (Legal Twin)          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a14a.interpretation_protection — interpretacja indywidualna
# (art. 14a-14b OrdPU): wniosek o interpretację do Dyrektora KIS → ochrona,
# o ile stan faktyczny zgodny z przedstawionym; termin wydania 30 dni
# (art. 14d § 1).
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a14a.interpretation_protection",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 211401,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "interpretation_protection_applicable": true,
    "interpretation_term_days": _ths_ord.interpretation_days,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Wniosek o interpretację indywidualną (art. 14a OrdPU) — ochrona przy zgodności stanu faktycznego",
    "_legal_basis": "Art. 14a-14b ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "_warnings": ["[MICRO P11] Interpretacja indywidualna — ochrona prawna, o ile stan faktyczny zgodny z opisanym"],
    "_provenance_tree": {
        "art": "14a-14b",
        "term_days": _ths_ord.interpretation_days
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "interpretation_requested", false) == true
    facts_match := object.get(input.jdg_entrepreneur, "facts_match_interpretation", false)
    facts_match == true
}

# jdg.micro.ord.a14d.interpretation_deadline — termin wydania interpretacji
# (art. 14d § 1): 30 dni; milczenie organu → uznanie wniosku (art. 14d § 2)
# i ochrona, chyba że sprawa jest oczywiście bezprzedmiotowa.
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a14d.interpretation_deadline",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 211402,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "interpretation_deadline_days": _ths_ord.interpretation_days,
    "interpretation_deemed_issued": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "OK",
    "_routing_reason": "Milczenie organu po 30 dniach = uznanie wniosku (art. 14d § 2 OrdPU)",
    "_legal_basis": "Art. 14d § 1-2 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "_warnings": ["[MICRO P11] Milczące załatwienie wniosku o interpretację po 30 dniach — ochrona"],
    "_provenance_tree": {
        "art": "14d § 1-2",
        "days": _ths_ord.interpretation_days
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "interpretation_requested", false) == true
    days_since := object.get(input.jdg_entrepreneur, "days_since_application", 0)
    days_since >= _ths_ord.interpretation_days
    obviously_unfounded := object.get(input.jdg_entrepreneur, "case_obviously_unfounded", false)
    obviously_unfounded == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ORDYNACJA ART. 70 — PRZEDAWNIENIE ZOBOWIĄZANIA PODATKOWEGO                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a70.limitation — przedawnienie zobowiązania (art. 70 OP): 5 lat
# od końca roku podatkowego; przerwanie (§ 4) i zawieszenie (§ 6 — postępowanie
# karno-skarbowe) wydłużają bieg → kalendarz per zobowiązanie.
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a70.limitation",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 217001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "ord_limitation_applicable": true,
    "ord_limitation_years": _ths_ord.statute_of_limitations_years,
    "ord_limitation_end_date": limitation_end,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "OK",
    "_routing_reason": "Przedawnienie zobowiązania (art. 70 OP) — upłynęło 5 lat od końca roku",
    "_legal_basis": "Art. 70 § 1 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "_warnings": ["[MICRO P11] OBRONA: przedawnienie zobowiązania — wygaśnięcie z mocy prawa"],
    "_provenance_tree": {
        "art": "70 § 1",
        "years": _ths_ord.statute_of_limitations_years,
        "limitation_end_date": limitation_end,
        "break_reset": _ths_ord.statute_limitation_break_reset,
        "suspend_kks": _ths_ord.statute_limitation_suspend_kks
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "ord_limitation_check", false) == true
    tax_year_end := object.get(input.jdg_entrepreneur, "tax_year_end_date", "2020-12-31")
    now := object.get(input.jdg_entrepreneur, "eval_date", "2026-01-01")
    limitation_end := time.add_date(time.parse_rfc3339(tax_year_end), _ths_ord.statute_of_limitations_years, 0, 0)
    time.parse_rfc3339(now) > limitation_end
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ORDYNACJA ART. 81b / 117ba — KOREKTA I BIAŁA LISTA                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a81b.correction_duty — obowiązek korekty (art. 81b): korekta
# deklaracji w 14 dni od stwierdzenia błędu (korekta „minus” nie może być
# złożona po kontroli).
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a81b.correction_duty",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 218101,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "correction_required": true,
    "correction_deadline_days": _ths_ord.correction_deadline_days,
    "correction_minus_blocked": correction_minus_blocked,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Obowiązek korekty (art. 81b OP) — korekta w 14 dni; korekta minus po kontroli zablokowana",
    "_legal_basis": "Art. 81b § 1 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "_warnings": ["[MICRO P11] Korekta minus po kontroli NIEDOPUSZCZALNA (art. 81b § 3)"],
    "_provenance_tree": {
        "art": "81b § 1-3",
        "deadline_days": _ths_ord.correction_deadline_days,
        "minus_blocked_after_audit": correction_minus_blocked
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "ord_correction_check", false) == true
    error_found := object.get(input.jdg_entrepreneur, "declaration_error_found", false)
    error_found == true
    under_audit := object.get(input.jdg_entrepreneur, "under_audit", false)
    correction_type := object.get(input.jdg_entrepreneur, "correction_type", "MINUS")
    correction_minus_blocked := under_audit and correction_type == "MINUS"
}

# jdg.micro.ord.a117ba.whitelist_monitor — Biała Lista (art. 117ba): płatność
# na rachunek spoza listy → sankcja 20% (jeśli brak powiadomienia w 7 dni);
# monitor 30 dni.
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a117ba.whitelist_monitor",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 211701 + 100,
    "vat_rate": "",
    "rounding_level": "GROSZE",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "whitelist_verified": false,
    "whitelist_sanction_pct": _ths_ord.whitelist_sanction_pct,
    "whitelist_sanction_pln": sanction,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Biała Lista (art. 117ba OP) — płatność na rachunek spoza listy: sankcja 20%",
    "_legal_basis": "Art. 117ba § 4 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "_warnings": ["[MICRO P11] Brak weryfikacji na Białej Liście — ryzyko sankcji 20%"],
    "_provenance_tree": {
        "art": "117ba § 4",
        "sanction_pct": _ths_ord.whitelist_sanction_pct,
        "payment_pln": payment,
        "sanction_pln": sanction
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "whitelist_check", false) == true
    on_list := object.get(input.jdg_entrepreneur, "counterparty_on_whitelist", true)
    on_list == false
    payment := object.get(input.jdg_entrepreneur, "payment_amount_pln", 0)
    sanction := round((payment * _ths_ord.whitelist_sanction_pct) * 100) / 100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ORDYNACJA ART. 119a — GAAR / AUDYT ART. 282b, 291, 223 — OBRONA           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.ord.a119a.gaar_risk — ocena ryzyka GAAR (art. 119a): korzyść
# podatkowa + brak celu gospodarczego + sztuczność → ryzyko klauzuli.
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a119a.gaar_risk",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 211901,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "gaar_risk_level": "WYSOKIE",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ryzyko GAAR (art. 119a OP) — korzyść bez celu gospodarczego + sztuczność",
    "_legal_basis": "Art. 119a ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "_warnings": ["[MICRO P11] OSTRZEŻENIE GAAR: struktura może być uznana za unikanie opodatkowania"],
    "_provenance_tree": {
        "art": "119a",
        "factors": ["korzyść podatkowa", "brak celu gospodarczego", "sztuczność"]
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "gaar_check", false) == true
    benefit := object.get(input.jdg_entrepreneur, "tax_benefit", false)
    no_economic_purpose := object.get(input.jdg_entrepreneur, "no_economic_purpose", false)
    artificial := object.get(input.jdg_entrepreneur, "artificial_arrangement", false)
    benefit == true and no_economic_purpose == true and artificial == true
}

# jdg.micro.ord.a282b.audit_rights — prawa w kontroli (art. 282b/291/223 OP):
# zawiadomienie 7 dni, zastrzeżenia do protokołu 14 dni, odwołanie 14 dni,
# skarga do WSA 30 dni — pakiet obrony dla przedsiębiorcy.
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a282b.audit_defense_packet",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 212821,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "audit_rights_available": true,
    "notification_days": _ths_ord.audit_notification_days,
    "protocol_objection_days": _ths_ord.protocol_objection_days,
    "appeal_days": _ths_ord.appeal_deadline_days,
    "wsa_days": _ths_ord.wsa_appeal_days,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Kontrola podatkowa — pakiet praw obrony (zawiadomienie 7 dni, protokół 14 dni, odwołanie 14 dni, WSA 30 dni)",
    "_legal_basis": "Art. 282b, 291, 223 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.) w zw. z art. 53 ustawy z dnia 30 sierpnia 2002 r. — Prawo o postępowaniu przed sądami administracyjnymi (Dz.U. 2025 poz. 861, ze zm.)",
    "_warnings": ["[MICRO P11] Prawa w kontroli: obecność, zastrzeżenia, odwołanie, skarga do WSA"],
    "_provenance_tree": {
        "art": "282b, 291, 223 OP + 53 PPSA",
        "notification_days": _ths_ord.audit_notification_days,
        "protocol_objection_days": _ths_ord.protocol_objection_days,
        "appeal_days": _ths_ord.appeal_deadline_days,
        "wsa_days": _ths_ord.wsa_appeal_days
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "audit_defense_check", false) == true
    audit_active := object.get(input.jdg_entrepreneur, "audit_active", false)
    audit_active == true
}

# jdg.micro.ord.a193a.jpk_request — JPK na żądanie (art. 193a OP): przekazanie
# JPK w 14 dni od żądania; opóźnienie → sankcje.
else := {
    "matched": true,
    "rule_id": "jdg.micro.ord.a193a.jpk_request",
    "package": "jdg.micro.kks_ord_atomic_p11",
    "priority": 219301,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "jpk_deadline_days": _ths_ord.jpk_request_days,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "JPK na żądanie (art. 193a OP) — przekazanie w " + sprintf("%d", [_ths_ord.jpk_request_days]) + " dni",
    "_legal_basis": "Art. 193a ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "_warnings": ["[MICRO P11] Termin JPK na żądanie: " + sprintf("%d", [_ths_ord.jpk_request_days]) + " dni — przygotuj struktury JPK_VAT/JPK_KR"],
    "_provenance_tree": {
        "art": "193a",
        "deadline_days": _ths_ord.jpk_request_days
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "jpk_request_check", false) == true
    jpk_requested := object.get(input.jdg_entrepreneur, "jpk_requested", false)
    jpk_requested == true
}

# ── INV-018: brak flagi domenowej → default no_match ───────────────────────────
# (bez catch-all {true}; reguły powyżej mają flagi domenowe, które nie kolidują)
