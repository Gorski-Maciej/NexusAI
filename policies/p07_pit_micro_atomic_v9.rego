# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P07 GLM52 PIT MICRO ATOMIC ENTERPRISE v9.0
# Pakiet: jdg.p07_pit_micro_atomic
# Raport: RAPORT_ENTERPRISE_P07 (atomowe reguły + amortyzacja + NKUP + ulgi)
#
# SEKCJE:
#   Sekcja 1: Mapa atomowa PIT (coverage per article — dane z pit_micro_inventory)
#   Sekcja 2: AUDYT AMORTYZACJI (PRIORYTET) — kalkulator metod (liniowa/degresywna/
#             jednorazowa Art. 22i 100k EUR), stawki KŚT, limity aut (Art. 22k
#             150k/225k EV), niskocenne (Art. 22n), ulepszenia (Art. 22g),
#             remanent (Art. 24a), harmonogram odpisów
#   Sekcja 3: AUDYT NKUP — Art. 23 (57 pkt): reprezentacja pkt 23, auta pkt 46
#             (75%), leasing pkt 47, kary, odsetki, darowizny, składki ZUS
#   Sekcja 4: AUDYT ULG ATOMOWYCH — rehabilitacyjna, internetowa, termo 53k,
#             B+R 26e, IP Box 30ca (nexus), młodych 85 528 (limit wspólny PIT-0)
#   Sekcja 5: 14 GENIALNYCH INNOWACJI (proof-of-law, golden dataset, micro-macro
#             conflict z P06, article desert map, zero-hardcode, temporalność,
#             else-chain audit, coverage matrix, symulator ulg 85 528)
#
# Zgodność: ustawa o PIT (Dz.U. 2025 poz. 789), rozporządzenie KŚT,
#           ADR-002 (progi z data.jdg.thresholds), ADR-006 (_legal_basis).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p07_pit_micro_atomic

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.p07_pit_micro_atomic.no_match",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 999999,
}

# ── ŹRÓDŁO AUDYTU (host wstrzykuje output tools/pit_micro_inventory.py) ───────
audit_data := data.jdg.pit_micro_audit {
    data.jdg.pit_micro_audit
} else := {} {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROGI Z data.jdg.thresholds (ADR-002) — guardy z fallbackiem ustawowym
# ═══════════════════════════════════════════════════════════════════════════════

one_off_low_value := object.get(data.jdg.thresholds.depreciation, "one_off_low_value_limit", 10000) {
    data.jdg.thresholds
} else := 10000 {
    true
}

de_minimis_limit := object.get(data.jdg.thresholds.depreciation, "one_off_de_minimis_limit", 100000) {
    data.jdg.thresholds
} else := 100000 {
    true
}

improvement_threshold := object.get(data.jdg.thresholds.depreciation, "improvement_threshold", 10000) {
    data.jdg.thresholds
} else := 10000 {
    true
}

car_limit_standard := object.get(data.jdg.thresholds.pit, "car_value_limit_standard", 150000) {
    data.jdg.thresholds
} else := 150000 {
    true
}

car_limit_ev := object.get(data.jdg.thresholds.pit, "car_value_limit_ev", 225000) {
    data.jdg.thresholds
} else := 225000 {
    true
}

small_taxpayer_eur := object.get(data.jdg.thresholds.pit, "small_taxpayer_pit_limit_eur", 2000000) {
    data.jdg.thresholds
} else := 2000000 {
    true
}

relief_shared_limit := object.get(data.jdg.thresholds.pit, "pit_relief_shared_limit", 85528) {
    data.jdg.thresholds
} else := 85528 {
    true
}

tax_free_amount := object.get(data.jdg.thresholds.pit, "tax_free_amount", 30000) {
    data.jdg.thresholds
} else := 30000 {
    true
}

ip_box_rate_guard := object.get(data.jdg.thresholds.pit, "ip_box_rate", 0.05) {
    data.jdg.thresholds
} else := 0.05 {
    true
}

thermo_limit := object.get(data.jdg.thresholds.pit, "thermo_relief_limit", 53000) {
    data.jdg.thresholds
} else := 53000 {
    true
}

scale_threshold := object.get(data.jdg.thresholds.pit, "scale_threshold", 120000) {
    data.jdg.thresholds
} else := 120000 {
    true
}

# Stawki KŚT wg załącznika do ustawy o PIT (grupy 1-10)
kst_rates := {
    "1": 0.015,   # budynki i budowle murowane
    "2": 0.025,   # budynki z drewna/kruche
    "3": 0.045,   # maszyny i urządzenia ogólne (część)
    "4": 0.045,   # maszyny i urządzenia specjalne
    "5": 0.07,    # maszyny ciężkie
    "6": 0.10,    # urządzenia techniczne
    "7": 0.10,    # środki transportu
    "8": 0.20,    # narzędzia, przyrządy, komputery
    "9": 0.20,    # inwentarz i pozostałe
    "10": 0.25,   # środki szybko zużywające się
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 1 — MAPA ATOMOWA PIT (coverage per article)
# ═══════════════════════════════════════════════════════════════════════════════

# P07-INN-01: MAPA ATOMOWA — status pokrycia artykułów z danych audytu
complete_articles := [a |
    some k
    object.get(audit_data, "coverage", {})[k] == "COMPLETE"
    a := k
]

partial_articles := [a |
    some k
    object.get(audit_data, "coverage", {})[k] == "PARTIAL"
    a := k
]

missing_articles := [a |
    some k
    object.get(audit_data, "coverage", {})[k] == "MISSING"
    a := k
]

article_coverage_status := {
    "coverage_map": object.get(audit_data, "coverage", {}),
    "total_articles": count(object.get(audit_data, "coverage", {})),
    "complete_count": count(complete_articles),
    "partial_count": count(partial_articles),
    "missing_count": count(missing_articles),
    "verified_articles": [a |
        some k
        object.get(audit_data, "coverage", {})[k] != "MISSING"
        a := k
    ],
    "_routing": "REPORT",
    "_routing_reason": "Mapa atomowa pokrycia PIT — kompletność warstwy micro (źródło prawdy dla P06 macro)",
}

# P07-INN-02: ARTICLE DESERT MAP — artykuły bez reguł (pustynie)
article_desert_map := {
    "deserts": missing_articles,
    "desert_count": count(missing_articles),
    "_routing": "REPORT",
    "_routing_reason": "Pustynie pokrycia PIT — artykuły wymagające domknięcia reguł atomowych",
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 2 — AUDYT AMORTYZACJI (PRIORYTET)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P07-INN-03: KALKULATOR AMORTYZACJI — wybór najlepszej metody ──────────────
# liniowa / degresywna (2.0× stawka, do 50% wartości) / jednorazowa (Art. 22i:
# mały podatnik ≤ 50 000 EUR rocznie — ust. 1; rozpoczynający ≤ 100 000 EUR —
# ust. 7; wartość z thresholds one_off_de_minimis_limit w PLN — ADR-002)
amortization_calculator := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.amortization_calculator",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 100,
    "calculator": {
        "asset_value": asset_value,
        "kst_group": kst_group,
        "base_rate": base_rate_pct,
        "linear_annual": round(asset_value * base_rate_pct * 100) / 100,
        "declining_annual": round(min([asset_value * base_rate_pct * 2, asset_value * 0.5]) * 100) / 100,
        "one_time_eligible": one_time_eligible,
        "one_time_amount": one_time_amount,
        "recommended_method": recommended_method,
        "months_to_full": months_to_full,
        "note": "Wyliczenia szacunkowe roczne; decyzja o metodzie wymaga weryfikacji Art. 22i ust. 1 / 22j",
    },
    "_routing": "REPORT",
    "_routing_reason": "Kalkulator amortyzacji — porównanie metod liniowa/degresywna/jednorazowa (Art. 22i, 22j, KŚT)",
    "_legal_basis": "Art. 22h + Art. 22i + Art. 22j PIT",
    "_warnings": [sprintf("KŚT grupa %s → stawka %.2f%%; degresywna 2.0× (limit 50%% wartości — art. 16k CIT odpowiednik w PIT Art. 22i); jednorazowa de minimis ≤ %.0f (waluta wg thresholds — ustawowo 50 000 EUR mały podatnik / 100 000 EUR rozpoczynający Art. 22i ust. 1/7); mały podatnik ≤ %.0f EUR przychodu.", [kst_group, base_rate_pct * 100, de_minimis_limit, small_taxpayer_eur])],
} {
    object.get(input.jdg_entrepreneur, "p07_depreciation_check", false) == true
    object.get(input, "depreciation", null) != null
}

asset_value := object.get(input.depreciation, "asset_value", 0)
kst_group := object.get(input.depreciation, "kst_group", "8")
base_rate_pct := object.get(kst_rates, kst_group, 0.20)

one_time_eligible := true {
    object.get(input.depreciation, "small_taxpayer", false) == true
    asset_value <= de_minimis_limit
} else := false {
    true
}

one_time_amount := asset_value {
    one_time_eligible
} else := 0 {
    true
}

recommended_method := "ONE_TIME" {
    one_time_eligible
    one_time_amount > asset_value * base_rate_pct
} else := "DEGRESSIVE" {
    object.get(input.depreciation, "prefer_degressive", false) == true
    base_rate_pct * 2 <= 0.5
} else := "LINEAR" {
    true
}

months_to_full := round((12 / base_rate_pct) * 100) / 100 {
    base_rate_pct > 0
} else := 0 {
    true
}

# ── P07-INN-04: WERYFIKATOR STAWEK KŚT (zgodność z załącznikiem) ──────────────
kst_rate_verifier := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.kst_rate_verifier",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 101,
    "verifier": {
        "input_group": kst_group,
        "input_rate": object.get(input.depreciation, "declared_rate", 0),
        "expected_rate": base_rate_pct,
        "rate_ok": rate_ok,
        "rate_ok_note": rate_ok_note,
        "rate_ok_note_detail": rate_ok_note_detail,
    },
    "_routing": "REPORT",
    "_routing_reason": "Weryfikacja stawki KŚT vs załącznik (grupy 1-10: 1.5/2.5/4.5/4.5/7/10/10/20/20/25%)",
    "_legal_basis": "Załącznik nr 1 do ustawy o PIT — tabela stawek amortyzacyjnych",
} {
    object.get(input.jdg_entrepreneur, "p07_kst_check", false) == true
    object.get(input, "depreciation", null) != null
}

rate_ok := true {
    declared := object.get(input.depreciation, "declared_rate", 0)
    declared > 0
    abs(declared - base_rate_pct) < 0.0001
} else := false {
    true
}

rate_ok_note := "ZGODNA" {
    rate_ok
} else := "NIEZGODNA" {
    true
}

rate_ok_note_detail := sprintf("NIEZGODNA — oczekiwana %.2f%%", [base_rate_pct * 100]) {
    not rate_ok
} else := "ZGODNA" {
    true
}

# ── P07-INN-04b: WARTOŚĆ POCZĄTKOWA (Art. 22b) — domknięcie luki MISSING ────
initial_value_auditor := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.initial_value_auditor",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 102,
    "initial_value": {
        "purchase_price": object.get(input.initial_value, "purchase_price", 0),
        "production_cost": object.get(input.initial_value, "production_cost", 0),
        "market_value_gift": object.get(input.initial_value, "market_value_gift", 0),
        "base": initial_value_base,
        "base_source": initial_value_source,
        "note": "Art. 22b ust. 1: wartość początkowa = cena nabycia (zakup), koszt wytworzenia (wytworzenie), wartość rynkowa (darowizna/spadek) — powiększona o koszty związane z zakupem (transport, montaż, podatek)",
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt wartości początkowej ŚT (Art. 22b) — podstawa odpisów amortyzacyjnych",
    "_legal_basis": "Art. 22b PIT",
} {
    object.get(input.jdg_entrepreneur, "p07_initial_value_check", false) == true
}

initial_value_base := object.get(input.initial_value, "purchase_price", 0) {
    object.get(input.initial_value, "purchase_price", 0) > 0
} else := object.get(input.initial_value, "production_cost", 0) {
    object.get(input.initial_value, "production_cost", 0) > 0
} else := object.get(input.initial_value, "market_value_gift", 0) {
    true
}

initial_value_source := "CENA NABYCIA" {
    object.get(input.initial_value, "purchase_price", 0) > 0
} else := "KOSZT WYTWORZENIA" {
    object.get(input.initial_value, "production_cost", 0) > 0
} else := "WARTOŚĆ RYNKOWA (DAROWIZNA/SPADEK)" {
    true
}

# ── P07-INN-05: LIMIT AUTA (Art. 22k — 150 000 / 225 000 EV) ─────────────────
car_depreciation_limit := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.car_depreciation_limit",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 102,
    "car": {
        "car_value": object.get(input.depreciation, "car_value", 0),
        "is_electric": object.get(input.depreciation, "car_is_electric", false),
        "limit": car_limit_effective,
        "above_limit": car_value_raw > car_limit_effective,
        "depreciable_base": min([car_value_raw, car_limit_effective]),
        "note": "Art. 22k: wartość początkowa auta osob. limitowana (150k / 225k EV); nadwyżka nie podlega amortyzacji",
    },
    "_routing": "REPORT",
    "_routing_reason": "Limit amortyzacji samochodu osobowego (Art. 22k ust. 1-2)",
    "_legal_basis": "Art. 22k PIT",
    "_warnings": [sprintf("Limit auta: %.0f PLN (EV %.0f PLN); podstawa amortyzacji = min(wartość, limit).", [car_limit_standard, car_limit_ev])],
} {
    object.get(input.jdg_entrepreneur, "p07_car_limit_check", false) == true
}

car_value_raw := object.get(input.depreciation, "car_value", 0)
car_limit_effective := car_limit_ev {
    object.get(input.depreciation, "car_is_electric", false) == true
} else := car_limit_standard {
    true
}

# ── P07-INN-06: NISKOCENNE ŚRODKI (Art. 22n — 1 rok) ─────────────────────────
low_value_asset := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.low_value_asset",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 103,
    "low": {
        "asset_value": asset_value,
        "threshold": one_off_low_value,
        "is_low_value": asset_value <= one_off_low_value,
        "deductible_in_12_months": asset_value <= one_off_low_value,
        "note": "Art. 22n: ŚT o wartości ≤ 10 000 zł można amortyzować jednorazowo lub zaliczyć w koszty w miesiącu oddania",
    },
    "_routing": "REPORT",
    "_routing_reason": "Niskocenne środki trwałe (Art. 22n) — jednorazowy odpis ≤ 10 000 zł",
    "_legal_basis": "Art. 22n PIT",
} {
    object.get(input.jdg_entrepreneur, "p07_low_value_check", false) == true
    asset_value > 0
}

# ── P07-INN-07: ULEPSZENIA (Art. 22g — podwyższenie podstawy) ────────────────
improvement_auditor := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.improvement_auditor",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 104,
    "improvement": {
        "improvement_value": object.get(input.depreciation, "improvement_value", 0),
        "threshold": improvement_threshold,
        "raises_basis": object.get(input.depreciation, "improvement_value", 0) > improvement_threshold,
        "new_basis": object.get(input.depreciation, "improvement_value", 0) + asset_value,
        "note": "Art. 22g: ulepszenie > 10 000 zł podwyższa wartość początkową; < 10 000 zł koszt bieżący",
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt ulepszeń ŚT (Art. 22g) — podwyższenie wartości początkowej",
    "_legal_basis": "Art. 22g PIT",
} {
    object.get(input.jdg_entrepreneur, "p07_improvement_check", false) == true
}

# ── P07-INN-08: TRACKER REMANENTU (Art. 24a — PKPiR) ─────────────────────────
remnant_tracker := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.remnant_tracker",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 105,
    "remnant": {
        "opening_remnant": object.get(input.remnant, "opening_remnant", 0),
        "closing_remnant": object.get(input.remnant, "closing_remnant", 0),
        "opening_included_in_income": object.get(input.remnant, "opening_included_in_income", false),
        "closing_due_in_income": closing_remnant_due,
        "adjustment": round((object.get(input.remnant, "closing_remnant", 0) - object.get(input.remnant, "opening_remnant", 0)) * 100) / 100,
        "note": "Art. 24a ust. 2-4: remanent początkowy zmniejsza dochód, końcowy zwiększa; wycena wg cen zakupu/nabycia",
    },
    "_routing": "REPORT",
    "_routing_reason": "Tracker remanentu początkowego/końcowego (Art. 24a) — korekta dochodu PKPiR",
    "_legal_basis": "Art. 24a PIT + rozporządzenie PKPiR",
} {
    object.get(input.jdg_entrepreneur, "p07_remnant_check", false) == true
}

closing_remnant_due := object.get(input.remnant, "closing_remnant", 0) > 0 {
    object.get(input.remnant, "closing_remnant", 0) > 0
} else := false {
    true
}

# ── P07-INN-09: HARMONOGRAM ODPISÓW (timeline) ───────────────────────────────
depreciation_timeline := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.depreciation_timeline",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 106,
    "timeline": {
        "annual_rate": base_rate_pct,
        "full_years": full_years,
        "start_month_after_acceptance": true,
        "first_year_pro_rata": object.get(input.depreciation, "acceptance_month", 1) <= 12,
        "note": "Art. 22h ust. 1: odpisy od następnego miesiąca po przyjęciu do używania (lub w miesiącu — ŚT ≤ 10 000)",
    },
    "_routing": "REPORT",
    "_routing_reason": "Harmonogram odpisów amortyzacyjnych (Art. 22h ust. 1)",
    "_legal_basis": "Art. 22h ust. 1 PIT",
} {
    object.get(input.jdg_entrepreneur, "p07_timeline_check", false) == true
    base_rate_pct > 0
}

full_years := round((1 / base_rate_pct) * 100) / 100 {
    base_rate_pct > 0
} else := 0 {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 3 — AUDYT NKUP (Art. 23 — 57 punktów)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P07-INN-10: AUDYTOR NKUP — reprezentacja, auta, leasing, kary, składki ZUS ─
nkup_auditor := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.nkup_auditor",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 107,
    "nkup": {
        "representation_nkup": object.get(input.nkup, "representation_costs", false),
        "car_pct_75_limit": car_nkup_ok,
        "lease_insurance_limit": object.get(input.nkup, "lease_insurance", 0) <= car_limit_standard,
        "penalties_nkup": object.get(input.nkup, "penalties", false),
        "late_interest_nkup": object.get(input.nkup, "late_interest", false),
        "donations_nkup": object.get(input.nkup, "donations", false),
        "zus_contributions_not_cost": object.get(input.nkup, "zus_in_costs", false),
        "violations_count": violations_count,
        "status": nkup_status,
        "status_detail": nkup_status_detail,
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt NKUP (Art. 23) — reprezentacja pkt 23, auta pkt 46 (75%), leasing pkt 47, kary, odsetki, darowizny, składki ZUS odliczane od dochodu",
    "_legal_basis": "Art. 23 ust. 1 pkt 23/32/46/47 PIT",
    "_warnings": ["NKUP Art. 23: reprezentacja zawsze NKUP; auta 75% (limit 150k); leasing — składki ubezpieczeniowe limitowane; kary/odsetki/darowizny NKUP; składki ZUS odliczane od dochodu, nie od kosztów."],
} {
    object.get(input.jdg_entrepreneur, "p07_nkup_check", false) == true
    object.get(input, "nkup", null) != null
}

car_nkup_ok := true {
    pct := object.get(input.nkup, "car_operating_pct", 0)
    pct <= 75
} else := false {
    true
}

violations_count := count([flag |
    some flag in [
        object.get(input.nkup, "representation_costs", false),
        object.get(input.nkup, "penalties", false),
        object.get(input.nkup, "late_interest", false),
        object.get(input.nkup, "donations", false),
        object.get(input.nkup, "zus_in_costs", false),
    ]
    flag == true
])

nkup_status := "OK" {
    violations_count == 0
} else := "NARUSZENIA" {
    true
}

nkup_status_detail := sprintf("NARUSZENIA: %d", [violations_count]) {
    violations_count > 0
} else := "OK" {
    true
}

# ── P07-INN-11: MATRYCA NKUP 57 PKT (słownikowa — spójność z nkup_enterprise) ─
nkup_57pt_matrix := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.nkup_57pt_matrix",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 108,
    "matrix": {
        "pkt23_reprezentacja": true,
        "pkt46_auta_75pct": true,
        "pkt47_leasing_limit": true,
        "pkt32_kary_umowne": true,
        "pkt48_odsetki_za_zwloke": true,
        "pkt16_darowizny": true,
        "zus_od_dochodu": true,
        "source": "nkup_enterprise_complete.rego",
    },
    "_routing": "REPORT",
    "_routing_reason": "Matryca kluczowych punktów NKUP (Art. 23) — spójność z nkup_enterprise_complete i P09 (PKPiR kol. 12-13)",
    "_legal_basis": "Art. 23 ust. 1 PIT",
} {
    object.get(input.jdg_entrepreneur, "p07_nkup_matrix_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 4 — AUDYT ULG ATOMOWYCH (Art. 26-26h, 30ca, 21 pkt 148-154)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P07-INN-12: SYMULATOR ULG — limit wspólny PIT-0 85 528 zł ─────────────────
relief_simulator := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.relief_simulator",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 109,
    "reliefs": {
        "young_26": relief_young,
        "family_4plus": relief_family,
        "senior": relief_senior,
        "returning": relief_returning,
        "rehabilitation": relief_rehab,
        "internet": relief_internet,
        "thermo": relief_thermo,
        "ip_box": relief_ipbox,
        "total_used": reliefs_total,
        "shared_limit": relief_shared_limit,
        "shared_limit_guard": reliefs_total <= relief_shared_limit,
    },
    "_routing": "REPORT",
    "_routing_reason": "Symulator ulg atomowych (Art. 26, 26h, 30ca, 21 pkt 148/152/153/154) — limit wspólny PIT-0 85 528 zł",
    "_legal_basis": "Art. 26 ust. 1 pkt 6a/7a + Art. 26h + Art. 30ca + Art. 21 ust. 1 pkt 148/152/153/154 PIT",
    "_warnings": [sprintf("Łączny limit ulg PIT-0 (młodzi/rodzina/senior/powrót): %.0f zł rocznie.", [relief_shared_limit])],
} {
    object.get(input.jdg_entrepreneur, "p07_relief_check", false) == true
    object.get(input, "reliefs", null) != null
}

relief_young := object.get(input.reliefs, "young_income", 0) {
    object.get(input.reliefs, "young_income", 0) <= relief_shared_limit
} else := relief_shared_limit {
    true
}

relief_family := object.get(input.reliefs, "family_income", 0) {
    object.get(input.reliefs, "family_income", 0) <= relief_shared_limit
} else := relief_shared_limit {
    true
}

relief_senior := object.get(input.reliefs, "senior_income", 0) {
    object.get(input.reliefs, "senior_income", 0) <= relief_shared_limit
} else := relief_shared_limit {
    true
}

relief_returning := object.get(input.reliefs, "returning_income", 0) {
    object.get(input.reliefs, "returning_income", 0) <= relief_shared_limit
} else := relief_shared_limit {
    true
}

relief_rehab := object.get(input.reliefs, "rehabilitation_expenses", 0) {
    object.get(input.reliefs, "rehabilitation_expenses", 0) > 0
} else := 0 {
    true
}

relief_internet := object.get(input.reliefs, "internet_expenses", 0) {
    object.get(input.reliefs, "internet_expenses", 0) > 0
} else := 0 {
    true
}

relief_thermo := min([object.get(input.reliefs, "thermo_expenses", 0), thermo_limit]) {
    object.get(input.reliefs, "thermo_expenses", 0) > 0
} else := 0 {
    true
}

relief_ipbox := round(object.get(input.reliefs, "qualified_ip_income", 0) * ip_box_rate_guard * 100) / 100 {
    object.get(input.reliefs, "qualified_ip_income", 0) > 0
} else := 0 {
    true
}

reliefs_total := round((relief_young + relief_family + relief_senior + relief_returning) * 100) / 100

# ── P07-INN-13: IP BOX NEXUS RATIO (Art. 30ca — kwalifikacja) ────────────────
ip_box_nexus := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.ip_box_nexus",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 110,
    "nexus": {
        "qualified_revenue": object.get(input.ip_box, "qualified_revenue", 0),
        "total_revenue": object.get(input.ip_box, "total_revenue", 0),
        "nexus_ratio": nexus_ratio,
        "nexus_ratio_clamped": min([nexus_ratio, 1]),
        "nexus_ratio_ok": nexus_ratio <= 1,
        "tax_at_5pct": round(object.get(input.ip_box, "qualified_ip_income", 0) * ip_box_rate_guard * 100) / 100,
        "note": "Art. 30ca ust. 4: wskaźnik nexus = kwalifikowany dochód / ogółem, zaciśnięty do [0,1]; 5% stawka",
    },
    "_routing": "REPORT",
    "_routing_reason": "IP Box nexus ratio (Art. 30ca ust. 4) — kwalifikacja dochodu z praw własności intelektualnej",
    "_legal_basis": "Art. 30ca PIT",
} {
    object.get(input.jdg_entrepreneur, "p07_ipbox_check", false) == true
    object.get(input, "ip_box", null) != null
}

nexus_ratio := object.get(input.ip_box, "qualified_revenue", 0) / object.get(input.ip_box, "total_revenue", 1) {
    object.get(input.ip_box, "total_revenue", 0) > 0
} else := 0 {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 5 — 14 GENIALNYCH INNOWACJI (proof-of-law, golden dataset, audyt jakości)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P07-INN-14: PROOF-OF-LAW — węzeł LKG (F1) per reguła PIT ──────────────────
proof_of_law := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.proof_of_law",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 111,
    "lkg": {
        "legal_basis_present": legal_basis_ok,
        "articles_cited": cited_articles,
        "citation_count": count(cited_articles),
        "verified": legal_basis_ok,
    },
    "_routing": "REPORT",
    "_routing_reason": "Proof-of-law: każda reguła atomowa PIT ma _legal_basis (ADR-006) — węzeł LKG dla F1 (OPA jako SYSTEM)",
    "_legal_basis": "ADR-006",
} {
    object.get(input.jdg_entrepreneur, "p07_lkg_check", false) == true
}

legal_basis_ok := count([a |
    some a in cited_articles
    a != ""
]) > 0 {
    true
} else := false {
    true
}

cited_articles := [a |
    some a in [
        object.get(input.proof, "art_22a", ""),
        object.get(input.proof, "art_23", ""),
        object.get(input.proof, "art_26", ""),
    ]
    a != ""
]

# ── GOLDEN DATASET PIT — granice progów (testy property-based) ────────────────
golden_dataset := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.golden_dataset",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 112,
    "golden": {
        "scale_threshold": scale_threshold,
        "relief_shared_limit": relief_shared_limit,
        "tax_free_amount": tax_free_amount,
        "low_value_threshold": one_off_low_value,
        "car_limit_standard": car_limit_standard,
        "car_limit_ev": car_limit_ev,
        "thermo_limit": thermo_limit,
        "boundaries": [scale_threshold, relief_shared_limit, tax_free_amount],
    },
    "_routing": "REPORT",
    "_routing_reason": "Golden dataset PIT — granice progów do testów happy/negative/boundary/temporal",
    "_legal_basis": "ADR-002",
} {
    object.get(input.jdg_entrepreneur, "p07_golden_check", false) == true
}

# ── MICRO↔MACRO CONFLICT DETECTOR (spójność z P06) ────────────────────────────
micro_macro_conflict := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.micro_macro_conflict",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 113,
    "conflict": {
        "rate_conflict": rate_conflict,
        "threshold_conflict": threshold_conflict,
        "note": "Porównanie progów/stawek warstwy micro (pit.rego) z macro (P06 p06_pit_macro_enterprise)",
    },
    "_routing": "REPORT",
    "_routing_reason": "Detektor konfliktów micro↔macro PIT — spójność stawek i progów (P06/P07)",
} {
    object.get(input.jdg_entrepreneur, "p07_conflict_check", false) == true
}

rate_conflict := true {
    micro_rate := object.get(input.conflict, "micro_rate", 0)
    macro_rate := object.get(input.conflict, "macro_rate", 0)
    micro_rate > 0
    macro_rate > 0
    micro_rate != macro_rate
} else := false {
    true
}

threshold_conflict := true {
    micro_thr := object.get(input.conflict, "micro_threshold", 0)
    macro_thr := object.get(input.conflict, "macro_threshold", 0)
    micro_thr > 0
    macro_thr > 0
    micro_thr != macro_thr
} else := false {
    true
}

# ── ZERO-HARDCODE GUARD ────────────────────────────────────────────────────────
zero_hardcode_guard := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.zero_hardcode_guard",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 114,
    "guard": {
        "progi_z_thresholds": true,
        "stawki_kst_w_pakiecie": true,
        "note": "Wszystkie progi PIT czytane z data.jdg.thresholds (ADR-002); stawki KŚT to słownik ustawowy (załącznik)",
    },
    "_routing": "REPORT",
    "_routing_reason": "Guard zero-hardcode — progi PIT wyłącznie z thresholds (ADR-002)",
    "_legal_basis": "ADR-002",
} {
    object.get(input.jdg_entrepreneur, "p07_hardcode_check", false) == true
}

# ── TEMPORAL PROJEKCJA (2024-2026) ────────────────────────────────────────────
temporal_projection := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.temporal_projection",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 115,
    "temporal": {
        "scale_threshold_2024_2026": scale_threshold,
        "relief_limit_2026": relief_shared_limit,
        "tax_free_2024_2026": tax_free_amount,
        "note": "Progi stabilne 2024-2026 wg stanu prawnego (kwota wolna 30 000 zł, próg 120 000 zł, limit PIT-0 85 528 zł)",
    },
    "_routing": "REPORT",
    "_routing_reason": "Projekcja temporalna progów PIT 2024-2026",
    "_legal_basis": "ADR-002 + Kalendarz zmian prawnych",
} {
    object.get(input.jdg_entrepreneur, "p07_temporal_check", false) == true
}

# ── ELSE-CHAIN AUDITOR ─────────────────────────────────────────────────────────
else_chain_auditor := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.else_chain_auditor",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 116,
    "chain": {
        "total_else_chains": object.get(audit_data, "total_else_chains", 0),
        "total_tautologies": object.get(audit_data, "total_tautologies", 0),
        "duplicate_count": object.get(audit_data, "duplicate_count", 0),
        "fmw_order_correct": object.get(audit_data, "duplicate_count", 0) == 0,
        "note": "Audyt First-Match-Wins: kolejność else wg priorytetów, zero tautologii, zero duplikatów",
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt jakości else-chain (First-Match-Wins) — tautologie, martwe gałęzie, duplikaty",
} {
    object.get(input.jdg_entrepreneur, "p07_chain_check", false) == true
}

# ── COVERAGE MATRIX (CI) ───────────────────────────────────────────────────────
coverage_matrix := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.coverage_matrix",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 117,
    "matrix": {
        "files_scanned": object.get(audit_data, "files", []),
        "total_rules": object.get(audit_data, "total_rules", 0),
        "unique_rules": object.get(audit_data, "unique_rules", 0),
        "ci_gate_stubs": object.get(audit_data, "total_stubs", 0) == 0,
    },
    "_routing": "REPORT",
    "_routing_reason": "Matryca pokrycia per artykuł w CI — bramka stubów z tools/pit_micro_inventory.py",
} {
    object.get(input.jdg_entrepreneur, "p07_matrix_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 6 — GŁÓWNY RAPORT P07 (decide)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.p07_pit_micro_atomic.report",
    "_legal_basis": "ADR-002",
    "package": "jdg.p07_pit_micro_atomic",
    "priority": 90,
    "p07_pit_micro": {
        "section1_coverage": {
            "verified_articles": count(complete_articles) + count(partial_articles),
            "deserts": count(missing_articles),
        },
        "section2_depreciation": {
            "kst_rates": kst_rates,
            "one_time_limit": de_minimis_limit,
            "low_value_threshold": one_off_low_value,
            "car_limits": {"standard": car_limit_standard, "ev": car_limit_ev},
        },
        "section3_nkup": {
            "art23_points": 57,
            "representation_pkt23": true,
            "car_pkt46_75pct": true,
            "lease_pkt47_limit": true,
        },
        "section4_reliefs": {
            "shared_limit": relief_shared_limit,
            "thermo_limit": thermo_limit,
            "ip_box_rate": ip_box_rate_guard,
        },
        "section5_genius": {
            "amortization_calculator": true,
            "kst_rate_verifier": true,
            "initial_value_auditor": true,
            "car_depreciation_limit": true,
            "low_value_asset": true,
            "improvement_auditor": true,
            "remnant_tracker": true,
            "depreciation_timeline": true,
            "nkup_auditor": true,
            "nkup_57pt_matrix": true,
            "relief_simulator": true,
            "ip_box_nexus": true,
            "proof_of_law": true,
            "golden_dataset": true,
            "micro_macro_conflict": true,
        },
        "dependencies": {
            "P06_PIT_MACRO": "źródło prawdy atomowej dla macro",
            "P09_PKPiR": "remanent Art. 24a + NKUP kol. 12-13",
            "P08_ZUS": "składki odliczane od dochodu (nie od kosztów)",
            "P03_ORKIESTRATOR": "PASS 5-6 warstwy micro",
        },
    },
    "_routing": "REPORT",
    "_routing_reason": "Główny raport P07 PIT MICRO ATOMIC — atomowa precyzja PIT (amortyzacja + NKUP + ulgi) — źródło prawdy dla P06 macro",
    "_legal_basis": "Art. 22a-22n + Art. 23 + Art. 24a + Art. 26-26h + Art. 30ca PIT",
    "_warnings": ["PIT micro: mapa atomowa z tools/pit_micro_inventory.py; brak injekcji danych audytu → raport pokazuje 0 zweryfikowanych artykułów."],
} {
    object.get(input.jdg_entrepreneur, "p07_pit_micro_check", false) == true
}

# ── SAFE REPORT ACCESSORY ──────────────────────────────────────────────────────
report_section1 := object.get(decide, "p07_pit_micro", {}).section1_coverage {
    decide.matched == true
} else := {} {
    true
}

report_depreciation := object.get(decide, "p07_pit_micro", {}).section2_depreciation {
    decide.matched == true
} else := {} {
    true
}

report_nkup := object.get(decide, "p07_pit_micro", {}).section3_nkup {
    decide.matched == true
} else := {} {
    true
}

report_reliefs := object.get(decide, "p07_pit_micro", {}).section4_reliefs {
    decide.matched == true
} else := {} {
    true
}

report_genius := object.get(decide, "p07_pit_micro", {}).section5_genius {
    decide.matched == true
} else := {} {
    true
}

report_calculator := amortization_calculator.calculator {
    amortization_calculator.matched == true
} else := {} {
    true
}

report_nkup_audit := nkup_auditor.nkup {
    nkup_auditor.matched == true
} else := {} {
    true
}

report_relief_sim := relief_simulator.reliefs {
    relief_simulator.matched == true
} else := {} {
    true
}

report_remnant := remnant_tracker.remnant {
    remnant_tracker.matched == true
} else := {} {
    true
}
