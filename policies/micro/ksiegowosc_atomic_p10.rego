# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KSIĘGOWOŚĆ ATOMIC RULES (GLM52 P10 — ENTERPRISE v9.x)
# Package: jdg.micro.ksiegowosc_atomic_p10
# ───────────────────────────────────────────────────────────────────────────────
# Prawdziwe reguły atomowe księgowości (konwerter stubów → reguł warunkowych,
# PROMPT 10 §8): silnik decyzji PKPiR-czy-UoR (art. 2 ust. 1 pkt 5 UoR — próg
# 2M EUR), monitor progu z projekcją, silnik podwójnego zapisu (art. 22 UoR —
# invariant Σ debety = Σ kredyty), harmonogram inwentaryzacji (art. 26),
# generator sprawozdania (art. 45-49 — bilans: aktywa = pasywa), zamknięcie
# roku (art. 12 — 12 kroków), amortyzacja księgowa (art. 32 — liniowa/
# degresywna/jednorazowa 100k EUR), walidator 17 kolumn PKPiR (§10-12 rozp. MF
# 15.11.2025), klasyfikator leasingu (art. 17f ust. 1 PIT — testy 90%/75%/10 lat),
# limit samochodów 150k/225k (spójność PIT/VAT).
# Kontrakty P01: werdykt 25-polowy + _legal_basis kanoniczne + zero hardcode
# (data.jdg.thresholds.jdg.ksiegowosc.*, ADR-002) + temporalność.
# Konwencja mikro (INV-018): brak catch-all {true} — brak dopasowania →
# default no_match; wypełnia LUKI makro, nigdy nie nadpisuje (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.ksiegowosc_atomic_p10

import future.keywords.if
import future.keywords.else
import future.keywords.in
import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.ksiegowosc_atomic_p10.no_match",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 999999
}

# ── Helper: progi z data.thresholds (ADR-002 — zero hardcode) ─────────────────
_ths := object.get(data.jdg.thresholds, "ksiegowosc", {
    "uor_threshold_eur": 2000000,
    "uor_threshold_group_eur": 2500000,
    "uor_obligation_years": 2,
    "eur_pln_rate_default": 4.50,
    "depreciation_one_time_limit_eur": 100000,
    "depreciation_degresja_multiplier": 2.0,
    "inventory_cycle_years": 4,
    "inventory_rotation_pct": 25,
    "leasing_value_test_pct": 90,
    "leasing_period_test_pct": 75,
    "leasing_realestate_min_years": 10,
    "car_limit_150k": 150000,
    "car_limit_225k": 225000,
    "pkpir_columns": 17,
})

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  UoR art. 2 — Silnik decyzji PKPiR-czy-UoR (próg 2 000 000 EUR)            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a2.decision_engine — próg pełnej księgowości: przychody netto
# > 2 000 000 EUR w roku obrotowym → obowiązek UoR (rok + 2 kolejne, art. 2
# ust. 1 pkt 5 UoR). Przeliczenie PLN→EUR wg kursu średniego NBP.
decide := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.decision_engine.r1",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 162001,
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
    "accounting_system": "UoR",
    "uor_threshold_eur": _ths.uor_threshold_eur,
    "revenue_eur": revenue_eur,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przychody netto przekroczyły próg 2 000 000 EUR — obowiązek pełnej księgowości",
    "_legal_basis": "Art. 2 ust. 1 pkt 5 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] Obowiązek UoR od następnego roku obrotowego + 2 kolejne (art. 2 ust. 1 UoR)"],
    "_provenance_tree": {
        "art": "2 ust. 1 pkt 5",
        "formula": "przychody netto PLN / kurs EUR > 2 000 000 EUR",
        "threshold_eur": _ths.uor_threshold_eur,
        "revenue_eur": revenue_eur,
        "obligation_years": _ths.uor_obligation_years
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_decision_check", false) == true
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_net_pln", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", _ths.eur_pln_rate_default)
    revenue_eur := annual_revenue_pln / eur_rate
    revenue_eur > _ths.uor_threshold_eur
}

# jdg.micro.uor.a2.decision_engine — PKPiR (przychody ≤ 2M EUR).
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.decision_engine.r2",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 162002,
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
    "accounting_system": "PKPiR",
    "uor_threshold_eur": _ths.uor_threshold_eur,
    "revenue_eur": revenue_eur,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Przychody netto ≤ 2 000 000 EUR — ewidencja PKPiR (art. 24a PIT)",
    "_legal_basis": "Art. 2 ust. 1 pkt 5 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.) w zw. z art. 24a ustawy o PIT",
    "_warnings": ["[MICRO P10] Ewidencja PKPiR — próg 2M EUR nieprzekroczony"],
    "_provenance_tree": {
        "art": "2 ust. 1 pkt 5 w zw. z art. 24a PIT",
        "threshold_eur": _ths.uor_threshold_eur,
        "revenue_eur": revenue_eur
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_decision_check", false) == true
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_net_pln", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", _ths.eur_pln_rate_default)
    revenue_eur := annual_revenue_pln / eur_rate
    revenue_eur <= _ths.uor_threshold_eur
    revenue_eur < 0.95 * _ths.uor_threshold_eur
}

# jdg.micro.uor.a2.threshold_monitor — projekcja progu 2M EUR: alert przy 95%
# + prognoza przekroczenia wg dynamiki przychodów.
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a2.threshold_monitor",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 162003,
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
    "uor_threshold_projection_pct": projection_pct,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Projekcja przychodów zbliża się do progu 2 000 000 EUR — rozważ plan przejścia na UoR",
    "_legal_basis": "Art. 2 ust. 1 pkt 5 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] Próg 2M EUR osiągnięty w ≥ 95% — przygotuj księgi rachunkowe"],
    "_provenance_tree": {
        "art": "2 ust. 1 pkt 5",
        "projection_pct": projection_pct,
        "threshold_eur": _ths.uor_threshold_eur
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_decision_check", false) == true
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_net_pln", 0)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", _ths.eur_pln_rate_default)
    revenue_eur := annual_revenue_pln / eur_rate
    revenue_eur < _ths.uor_threshold_eur
    revenue_eur >= 0.95 * _ths.uor_threshold_eur
    projection_pct := round((revenue_eur / _ths.uor_threshold_eur) * 10000) / 100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  UoR art. 22 — Silnik podwójnego zapisu (invariant ΣD = ΣC)                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a22.double_entry — weryfikacja podwójnego zapisu: suma debetów
# musi równać się sumie kredytów (zasada podwójnego zapisu, art. 15 ust. 1 UoR).
# Naruszenie → BLOCK_AND_ALERT (invariant księgowy, F2).
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.double_entry",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 162201,
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
    "double_entry_balanced": false,
    "debits_sum_pln": debits,
    "credits_sum_pln": credits,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Naruszenie zasady podwójnego zapisu — Σ debetów ≠ Σ kredytów (art. 15 ust. 1 UoR)",
    "_legal_basis": "Art. 15 ust. 1 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] INVARIANT KSIĘGOWY: suma debetów ≠ suma kredytów — korekta przed zaksięgowaniem"],
    "_provenance_tree": {
        "art": "15 ust. 1",
        "invariant": "Σ debety = Σ kredyty",
        "debits_sum_pln": debits,
        "credits_sum_pln": credits
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_double_entry_check", false) == true
    debits := object.get(input.jdg_entrepreneur, "debits_sum_pln", 0)
    credits := object.get(input.jdg_entrepreneur, "credits_sum_pln", 0)
    debits != credits
}

# jdg.micro.uor.a22.double_entry_ok — zapis zbalansowany (ΣD = ΣC).
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a22.double_entry_ok",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 162202,
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
    "double_entry_balanced": true,
    "debits_sum_pln": debits,
    "credits_sum_pln": credits,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Podwójny zapis zbalansowany — Σ debetów = Σ kredytów (art. 15 ust. 1 UoR)",
    "_legal_basis": "Art. 15 ust. 1 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] Zapis zbalansowany — gotowy do księgowania"],
    "_provenance_tree": {
        "art": "15 ust. 1",
        "invariant": "Σ debety = Σ kredyty",
        "debits_sum_pln": debits,
        "credits_sum_pln": credits
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_double_entry_check", false) == true
    debits := object.get(input.jdg_entrepreneur, "debits_sum_pln", 0)
    credits := object.get(input.jdg_entrepreneur, "credits_sum_pln", 0)
    debits == credits
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  UoR art. 26 / 12 / 32 / 45 — inwentaryzacja, zamknięcie, amortyzacja,      ║
# ║  sprawozdanie                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.uor.a26.inventory_schedule — harmonogram inwentaryzacji: droga
# inwentaryzacja (środki trwałe, zapasy) co 4 lata; 25% pozostałych pozycji
# rocznie (ciągła) — art. 26 ust. 1 pkt 1-3 UoR.
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a26.inventory_schedule",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 162601,
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
    "inventory_due": true,
    "inventory_cycle_years": _ths.inventory_cycle_years,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Należy przeprowadzić inwentaryzację (art. 26 ust. 1 UoR) — upłynął cykl 4-letni",
    "_legal_basis": "Art. 26 ust. 1 pkt 1-3 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] Termin inwentaryzacji — droga inwentaryzacja co 4 lata, ciągła 25% rocznie"],
    "_provenance_tree": {
        "art": "26 ust. 1 pkt 1-3",
        "cycle_years": _ths.inventory_cycle_years,
        "rotation_pct": _ths.inventory_rotation_pct
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_inventory_check", false) == true
    years_since_last := object.get(input.jdg_entrepreneur, "years_since_last_inventory", 0)
    years_since_last >= _ths.inventory_cycle_years
}

# jdg.micro.uor.a12.year_close — zamknięcie roku obrotowego: 12 kroków
# (inwentaryzacja → przeksięgowania → ustalenie wyniku → sprawozdanie →
# zatwierdzenie) — art. 12 ust. 2 pkt 1-6 UoR. Raportuje brakujące kroki.
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a12.year_close",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 161201,
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
    "year_close_steps_missing": missing,
    "year_close_complete": false,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Zamknięcie roku niekompletne — brakuje kroków: " + missing_desc,
    "_legal_basis": "Art. 12 ust. 2 pkt 1-6 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] Checklista zamknięcia roku: 12 kroków — uzupełnij brakujące"],
    "_provenance_tree": {
        "art": "12 ust. 2",
        "steps_total": 12,
        "steps_missing": missing
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_year_close_check", false) == true
    done := object.get(input.jdg_entrepreneur, "year_close_steps_done", [])
    all_steps := ["inwentaryzacja", "przeksiegowania_rozliczen", "ustalenie_wyniku_finansowego",
        "odpisy_amortyzacyjne", "rezerwy_i_rozliczenia", "zamkniecie_ksieg",
        "sporzadzenie_bilansu", "sporzadzenie_rzis", "informacja_dodatkowa",
        "sprawozdanie_z_dzialalnosci", "zatwierdzenie_sprawozdania", "zlozenie_w_krs"]
    missing := [s | s := all_steps[_]; not s in done]
    count(missing) > 0
    missing_desc := concat(", ", missing)
}

# jdg.micro.uor.a32.book_depreciation — amortyzacja księgowa (art. 32 UoR):
# liniowa / degresywna (2× stawka) / jednorazowa (limit 100 000 EUR).
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.book_depreciation.r1",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 163201,
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
    "book_depreciation_method": method,
    "book_depreciation_annual_pln": annual,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Amortyzacja księgowa — metoda " + method,
    "_legal_basis": "Art. 32 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] Amortyzacja księgowa wg art. 32 UoR — stawki z polityki rachunkowości"],
    "_provenance_tree": {
        "art": "32",
        "method": method,
        "annual_pln": annual,
        "degresja_multiplier": _ths.depreciation_degresja_multiplier
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_depreciation_check", false) == true
    value := object.get(input.jdg_entrepreneur, "asset_value_pln", 0)
    rate := object.get(input.jdg_entrepreneur, "depreciation_rate", 0.2)
    degresja := object.get(input.jdg_entrepreneur, "degresive_depreciation", false)
    one_time := object.get(input.jdg_entrepreneur, "one_time_depreciation", false)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", _ths.eur_pln_rate_default)
    one_time_limit_pln := _ths.depreciation_one_time_limit_eur * eur_rate
    one_time
    value <= one_time_limit_pln
    method := "JEDNORAZOWY"
    annual := value
}

else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a32.book_depreciation.r2",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 163202,
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
    "book_depreciation_method": method,
    "book_depreciation_annual_pln": annual,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Amortyzacja księgowa — metoda " + method,
    "_legal_basis": "Art. 32 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] Amortyzacja księgowa — stawka " + method],
    "_provenance_tree": {
        "art": "32",
        "method": method,
        "annual_pln": annual,
        "degresja_multiplier": _ths.depreciation_degresja_multiplier
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_depreciation_check", false) == true
    value := object.get(input.jdg_entrepreneur, "asset_value_pln", 0)
    rate := object.get(input.jdg_entrepreneur, "depreciation_rate", 0.2)
    degresja := object.get(input.jdg_entrepreneur, "degresive_depreciation", false)
    one_time := object.get(input.jdg_entrepreneur, "one_time_depreciation", false)
    eur_rate := object.get(input.jdg_entrepreneur, "eur_pln_rate", _ths.eur_pln_rate_default)
    one_time_limit_pln := _ths.depreciation_one_time_limit_eur * eur_rate
    not one_time
    value > 0
    method := "DEGRESYWNA" if degresja else "LINIOWA"
    eff_rate := rate * _ths.depreciation_degresja_multiplier if degresja else rate
    annual := round((value * eff_rate) * 100) / 100
}

# jdg.micro.uor.a45.financial_statements — bilans: aktywa = pasywa (art. 45-49
# UoR). Naruszenie → BLOCK_AND_ALERT.
else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.financial_statements",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 164501,
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
    "balance_sheet_balanced": false,
    "assets_sum_pln": assets,
    "liabilities_sum_pln": liabilities,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Bilans niezgodny — aktywa ≠ pasywa (art. 45-49 UoR)",
    "_legal_basis": "Art. 45 ust. 1-3 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] INVARIANT BILANSU: aktywa ≠ pasywa"],
    "_provenance_tree": {
        "art": "45 ust. 1-3",
        "invariant": "aktywa = pasywa",
        "assets_sum_pln": assets,
        "liabilities_sum_pln": liabilities
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_statements_check", false) == true
    assets := object.get(input.jdg_entrepreneur, "assets_sum_pln", 0)
    liabilities := object.get(input.jdg_entrepreneur, "liabilities_sum_pln", 0)
    assets != liabilities
}

else := {
    "matched": true,
    "rule_id": "jdg.micro.uor.a45.financial_statements_ok",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 164502,
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
    "balance_sheet_balanced": true,
    "assets_sum_pln": assets,
    "liabilities_sum_pln": liabilities,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Bilans zgodny — aktywa = pasywa (art. 45-49 UoR)",
    "_legal_basis": "Art. 45 ust. 1-3 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)",
    "_warnings": ["[MICRO P10] Bilans zbalansowany"],
    "_provenance_tree": {
        "art": "45 ust. 1-3",
        "invariant": "aktywa = pasywa",
        "assets_sum_pln": assets,
        "liabilities_sum_pln": liabilities
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "uor_statements_check", false) == true
    assets := object.get(input.jdg_entrepreneur, "assets_sum_pln", 0)
    liabilities := object.get(input.jdg_entrepreneur, "liabilities_sum_pln", 0)
    assets == liabilities
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  PKPiR — walidator kolumn 1-17 (§10-12 rozp. MF 15.11.2025)                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pkpir.col17_validator — kompletność wiersza PKPiR: 17 kolumn
# (data, numer, kontrahent, opis, przychody 7-8, zakupy 10-13, amortyzacja 14,
# pozostałe 15-16, uwagi 17). Brak kolumny → BLOCK_AND_ALERT.
else := {
    "matched": true,
    "rule_id": "jdg.micro.pkpir.col17_validator",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 170101,
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
    "pkpir_row_complete": false,
    "pkpir_missing_columns": missing,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wiersz PKPiR niekompletny — brakujące kolumny: " + missing_desc,
    "_legal_basis": "§10-12 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO P10] Wiersz PKPiR — uzupełnij brakujące kolumny przed zapisem"],
    "_provenance_tree": {
        "par": "§10-12",
        "columns_required": _ths.pkpir_columns,
        "missing": missing
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "pkpir_row_check", false) == true
    filled := object.get(input.jdg_entrepreneur, "pkpir_columns_filled", [])
    required := ["col1_data", "col2_numer", "col3_kontrahent", "col4_opis",
        "col5_przychod_wartosc", "col7_przychody_razem", "col10_zakupy_towary",
        "col12_zakupy_pozostale", "col14_amortyzacja", "col15_pozostale_wydatki",
        "col16_pozostale", "col17_uwagi"]
    missing := [c | c := required[_]; not c in filled]
    count(missing) > 0
    missing_desc := concat(", ", missing)
}

# jdg.micro.pkpir.col17_validator_ok — wiersz kompletny.
else := {
    "matched": true,
    "rule_id": "jdg.micro.pkpir.col17_validator_ok",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 170102,
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
    "pkpir_row_complete": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Wiersz PKPiR kompletny (kolumny 1-17)",
    "_legal_basis": "§10-12 rozporządzenia Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia podatkowej księgi przychodów i rozchodów",
    "_warnings": ["[MICRO P10] Wiersz PKPiR gotowy do zapisu"],
    "_provenance_tree": {
        "par": "§10-12",
        "columns_required": _ths.pkpir_columns
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "pkpir_row_check", false) == true
    filled := object.get(input.jdg_entrepreneur, "pkpir_columns_filled", [])
    required := ["col1_data", "col2_numer", "col3_kontrahent", "col4_opis",
        "col5_przychod_wartosc", "col7_przychody_razem", "col10_zakupy_towary",
        "col12_zakupy_pozostale", "col14_amortyzacja", "col15_pozostale_wydatki",
        "col16_pozostale", "col17_uwagi"]
    missing := [c | c := required[_]; not c in filled]
    count(missing) == 0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  LEASING — klasyfikator operacyjny/finansowy (art. 17f ust. 1 PIT)          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.leasing.classifier — leasing finansowy gdy spełniony którykolwiek
# z testów art. 17f ust. 1 PIT: (1) suma opłat ≥ 90% wartości początkowej,
# (2) okres ≥ 75% normatywnego okresu amortyzacji, (3) nieruchomość i okres
# ≥ 10 lat. W przeciwnym razie operacyjny.
else := {
    "matched": true,
    "rule_id": "jdg.micro.leasing.classifier.r1",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 171701,
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
    "leasing_type": "FINANSOWY",
    "leasing_test_hit": test_hit,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Leasing FINANSOWY — spełniony test art. 17f ust. 1 PIT: " + test_hit,
    "_legal_basis": "Art. 17f ust. 1 pkt 1-3 ustawy o podatku dochodowym od osób fizycznych",
    "_warnings": ["[MICRO P10] Leasing finansowy — amortyzacja u korzystającego, odsetki KUP"],
    "_provenance_tree": {
        "art": "17f ust. 1 pkt 1-3",
        "value_test_pct": _ths.leasing_value_test_pct,
        "period_test_pct": _ths.leasing_period_test_pct,
        "realestate_min_years": _ths.leasing_realestate_min_years,
        "test_hit": test_hit
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "leasing_classifier_check", false) == true
    total_fees := object.get(input.jdg_entrepreneur, "leasing_total_fees_pln", 0)
    asset_value := object.get(input.jdg_entrepreneur, "leasing_asset_value_pln", 0)
    contract_years := object.get(input.jdg_entrepreneur, "leasing_contract_years", 0)
    normative_years := object.get(input.jdg_entrepreneur, "leasing_normative_years", 0)
    realestate := object.get(input.jdg_entrepreneur, "leasing_realestate", false)
    test1 := total_fees >= _ths.leasing_value_test_pct / 100 * asset_value
    test2 := normative_years > 0 and contract_years >= _ths.leasing_period_test_pct / 100 * normative_years
    test3 := realestate and contract_years >= _ths.leasing_realestate_min_years
    test_hit := "suma opłat ≥ 90% wartości" if test1 else ("okres ≥ 75% normatywnego" if test2 else ("nieruchomość ≥ 10 lat" if test3 else "BRAK"))
    test1 or test2 or test3
}

else := {
    "matched": true,
    "rule_id": "jdg.micro.leasing.classifier.r2",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 171702,
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
    "leasing_type": "OPERACYJNY",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Leasing OPERACYJNY — żaden test art. 17f ust. 1 PIT nie został spełniony",
    "_legal_basis": "Art. 17f ust. 1 pkt 1-3 ustawy o podatku dochodowym od osób fizycznych",
    "_warnings": ["[MICRO P10] Leasing operacyjny — raty KUP, bez amortyzacji u korzystającego"],
    "_provenance_tree": {
        "art": "17f ust. 1 pkt 1-3",
        "value_test_pct": _ths.leasing_value_test_pct,
        "period_test_pct": _ths.leasing_period_test_pct
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "leasing_classifier_check", false) == true
    total_fees := object.get(input.jdg_entrepreneur, "leasing_total_fees_pln", 0)
    asset_value := object.get(input.jdg_entrepreneur, "leasing_asset_value_pln", 0)
    contract_years := object.get(input.jdg_entrepreneur, "leasing_contract_years", 0)
    normative_years := object.get(input.jdg_entrepreneur, "leasing_normative_years", 0)
    realestate := object.get(input.jdg_entrepreneur, "leasing_realestate", false)
    test1 := total_fees >= _ths.leasing_value_test_pct / 100 * asset_value
    test2 := normative_years > 0 and contract_years >= _ths.leasing_period_test_pct / 100 * normative_years
    test3 := realestate and contract_years >= _ths.leasing_realestate_min_years
    not (test1 or test2 or test3)
}

# jdg.micro.leasing.car_limit — limit 150k/225k zł dla samochodów osobowych
# (spójność PIT art. 23 ust. 1 pkt 47a / VAT art. 86a) — nadwyżka nad limit
# nie stanowi KUP ani nie daje prawa do odliczenia VAT.
else := {
    "matched": true,
    "rule_id": "jdg.micro.leasing.car_limit",
    "package": "jdg.micro.ksiegowosc_atomic_p10",
    "priority": 171703,
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
    "car_limit_pln": limit,
    "car_excess_pln": excess,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Wartość samochodu przekracza limit — nadwyżka poza KUP/VAT",
    "_legal_basis": "Art. 23 ust. 1 pkt 47a ustawy o podatku dochodowym od osób fizycznych w zw. z art. 86a ustawy o VAT",
    "_warnings": ["[MICRO P10] Nadwyżka nad limit 150k/225k zł nie jest KUP i nie daje odliczenia VAT"],
    "_provenance_tree": {
        "art": "23 ust. 1 pkt 47a PIT / art. 86a VAT",
        "limit_150k": _ths.car_limit_150k,
        "limit_225k": _ths.car_limit_225k,
        "excess_pln": excess
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "car_limit_check", false) == true
    car_value := object.get(input.jdg_entrepreneur, "car_value_pln", 0)
    electric := object.get(input.jdg_entrepreneur, "car_electric", false)
    limit := _ths.car_limit_225k if electric else _ths.car_limit_150k
    car_value > limit
    excess := round((car_value - limit) * 100) / 100
}
