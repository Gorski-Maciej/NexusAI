# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R09 GLM52 UoR / PKPiR / KSIĘGOWOŚĆ — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r09_ksiegowosc_pkpir_uor_innovations
# Raport: RAPORT_09_UOR_KSIEGOWOSC.txt (Kampania GLM 5.2 — seria 09/25)
#
# Prompt 09/25 (UoR / PKPiR / KSIĘGOWOŚĆ — pełna księgowość, księgi, kolumny
# PKPiR, amortyzacja, transformacja):
#   R09-INN-01 uor_threshold_simulator — symulator progu UoR z projekcją
#                                           forward (12/24 mies.): "PKPiR czy
#                                           UoR?" + kiedy nastąpi przekroczenie
#                                           2M EUR (p09 uor_obligation_engine
#                                           robił tylko ocenę punktową)
#   R09-INN-02 pkpir_ledger_reconciliation — uzgodnienie 3-drożne PKPiR↔VAT↔
#                                           bank (kol. 7 sprzedaż netto vs baza
#                                           VAT vs wpływy bankowe) z tolerancją
#                                           (p09 pkpir_validator_realtime badał
#                                           tylko matematykę wewnętrzną kolumn)
#   R09-INN-03 amortization_plan_optimizer — optymalizator planu amortyzacji
#                                           (liniowa vs degresywna vs
#                                           jednorazowa 100k EUR) per środek
#                                           trwały, rekomendacja metody (p09
#                                           amortization_dual_calculator liczył
#                                           pojedynczy rok)
#   R09-INN-04 inventory_deadline_monitor — monitor terminów inwentaryzacji
#                                           (art. 26 UoR) z 3 poziomami
#                                           alertów (RED/AMBER/GREEN) per typ
#                                           (gotówka co rok / zapasy koniec
#                                           roku / ŚT co 4 lata) + next_action
#                                           (p09 inventory_scheduler dawał
#                                           statyczny harmonogram)
#   R09-INN-05 financial_statement_autopack — auto-pakiet sprawozdania
#                                           finansowego (bilans + RZiS +
#                                           informacja dodatkowa + uchwała)
#                                           z terminami (31.03/15.10),
#                                           retencją 5 lat (art. 74 UoR) i
#                                           kompletnością fail-closed (p09
#                                           financial_statements_generator dawał
#                                           tylko strukturę)
#
# Zgodność: ADR-001..009/017/022, ustawa o rachunkowości (Dz.U. 2023 poz. 120),
#           art. 2/4/10-12/20-22/26-28/32/45-49/52/74 UoR, art. 22a/22i/22k/
#           23a/23b/23f/24 ust. 2 PIT, rozp. MF o PKPiR (kolumny 1-17),
#           art. 193a OrdPU; thresholds.accounting (zero hardcode); INV-018;
#           First-Match-Wins else-chain.
# package: jdg.r09_ksiegowosc_pkpir_uor_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r09_ksiegowosc_pkpir_uor_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r09_ksiegowosc_pkpir_uor_innovations.no_match", "package": "jdg.r09_ksiegowosc_pkpir_uor_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_acc := object.get(_th, "accounting", {})
_th_dep := object.get(_th, "depreciation", {})

uor_threshold_eur := object.get(_th_acc, "uor_threshold_eur", 2000000)      # art. 2 ust. 1 pkt 5 UoR — 2M EUR
eur_pln_reference := object.get(_th_acc, "eur_pln_reference", 4.5)          # kurs referencyjny NBP
early_warning_pct := object.get(_th_acc, "early_warning_pct", 75)           # 75% progu — ostrzeżenie
one_time_depreciation_eur := object.get(_th_acc, "one_time_depreciation_eur", 100000)  # art. 22k ust. 7-12 PIT
car_limit_standard := object.get(_th_acc, "car_limit_standard", 150000)     # art. 23a pkt 47a PIT
car_limit_electric := object.get(_th_acc, "car_limit_electric", 225000)     # art. 23a pkt 47a PIT (EV)
inventory_fixed_assets_years := object.get(_th_acc, "inventory_fixed_assets_years", 4)  # art. 26 UoR
fs_retention_years := object.get(_th_acc, "fs_retention_years", 5)          # art. 74 UoR
fs_approval_deadline := object.get(_th_acc, "fs_approval_deadline", "03-31")
fs_filing_deadline := object.get(_th_acc, "fs_filing_deadline", "10-15")

# ── Helper: zaokrąglenie 2 miejsca (spójne z p09/round2) ─────────────────────
round2(x) := floor((x * 100) + 0.5) / 100

# ═══════════════════════════════════════════════════════════════════════════════
# R09-INN-01: UOR THRESHOLD SIMULATOR — symulator progu UoR z projekcją forward
#             (art. 2 ust. 1 pkt 5 UoR — próg 2 000 000 EUR, 75% ostrzeżenie)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza uor_simulation: {ytd_revenue_pln, monthly_avg_pln,
# months_elapsed}. Wynik: bieżąca decyzja PKPiR/UoR, % progu, 75% warning,
# projekcja roczna i liczba miesięcy do przekroczenia progu.
uos_input := object.get(input, "uor_simulation", {})
uos_ytd_pln := max([0, object.get(uos_input, "ytd_revenue_pln", 0)])
uos_monthly_avg_pln := max([0, object.get(uos_input, "monthly_avg_pln", 0)])
uos_months_elapsed := max([1, object.get(uos_input, "months_elapsed", 12)])

uos_current_eur := round2(uos_ytd_pln / eur_pln_reference)
uos_annualized_pln := uos_monthly_avg_pln * 12
uos_projected_eur := round2(uos_annualized_pln / eur_pln_reference)
uos_threshold_pct := round2(uos_current_eur * 100 / uor_threshold_eur)

uos_early_warning := true if {
    uos_current_eur >= uor_threshold_eur * early_warning_pct / 100
    uos_current_eur < uor_threshold_eur
} else := false if {
    true
}

uos_decision := "UoR" if {
    uos_current_eur >= uor_threshold_eur
} else := "PKPiR" if {
    true
}

uos_monthly_eur := uos_monthly_avg_pln / eur_pln_reference

uos_months_to_threshold := ceil((uor_threshold_eur - uos_current_eur) / uos_monthly_eur) if {
    uos_monthly_eur > 0
    uos_current_eur < uor_threshold_eur
} else := 0 if {
    true
}

uos_routing := "TRIAGE_QUEUE" if {
    uos_early_warning
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r09_ksiegowosc_pkpir_uor_innovations.uor_threshold_simulator",
    "_legal_basis": "UoR art. 2 ust. 1 pkt 5 (próg 2 000 000 EUR), art. 2 ust. 2 (PKPiR poniżej progu); PIT art. 24a (PKPiR)",
    "package": "jdg.r09_ksiegowosc_pkpir_uor_innovations",
    "priority": 11006,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "uos_ytd_pln": uos_ytd_pln,
    "uos_current_eur": uos_current_eur,
    "uos_annualized_pln": uos_annualized_pln,
    "uos_projected_eur": uos_projected_eur,
    "uos_threshold_pct": uos_threshold_pct,
    "uos_early_warning": uos_early_warning,
    "uos_decision": uos_decision,
    "uos_months_to_threshold": uos_months_to_threshold,
    "uos_months_elapsed": uos_months_elapsed,
    "_routing": uos_routing,
    "_routing_reason": sprintf("Symulator progu UoR — %.2f%% progu 2M EUR (%.2f EUR bieżąco, projekcja %.2f EUR). Decyzja: %s%s.", [uos_threshold_pct, uos_current_eur, uos_projected_eur, uos_decision, sprintf(" | przekroczenie za ~%d mies.", [uos_months_to_threshold]) if {uos_current_eur < uor_threshold_eur; uos_monthly_eur > 0} else ""]),
    "_legal_basis": "UoR art. 2 ust. 1 pkt 5 (próg 2 000 000 EUR), art. 2 ust. 2 (PKPiR poniżej progu); PIT art. 24a (PKPiR)",
    "_warnings": [sprintf("UoR: %.2f%% progu (%.2f EUR z 2 000 000 EUR). %s", [uos_threshold_pct, uos_current_eur, "Zbliżasz się do progu UoR — planuj przejście na pełną księgowość (75% ostrzeżenie)." if {uos_early_warning} else "Poniżej progu — PKPiR wystarczający."])],
} if {
    object.get(input.jdg_entrepreneur, "r09_ksiegowosc_check", false) == true
    object.get(input, "uor_simulation", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R09-INN-02: PKPIR LEDGER RECONCILIATION — uzgodnienie 3-drożne PKPiR↔VAT↔bank
#             (kol. 7 sprzedaż netto vs baza VAT vs wpływy bankowe)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza ledger_reconciliation: {pkpir_col7_sales_net, vat_sales_base,
# bank_inflows, tolerance_pct}. Wynik: vat_ok / bank_ok / reconciled +
# różnice kwotowe. Naruszenie → TRIAGE_QUEUE (zero rozjazdów).
lrecon_input := object.get(input, "ledger_reconciliation", {})
lrecon_pkpir := object.get(lrecon_input, "pkpir_col7_sales_net", 0)
lrecon_vat := object.get(lrecon_input, "vat_sales_base", 0)
lrecon_bank := object.get(lrecon_input, "bank_inflows", 0)
lrecon_tolerance := object.get(lrecon_input, "tolerance_pct", 1.0)

lrecon_diff_vat := abs(lrecon_pkpir - lrecon_vat)
lrecon_diff_bank := abs(lrecon_pkpir - lrecon_bank)
lrecon_tol_vat := max([lrecon_pkpir * lrecon_tolerance / 100, 1.0])
lrecon_tol_bank := max([lrecon_pkpir * lrecon_tolerance / 100, 1.0])

lrecon_vat_ok := lrecon_diff_vat <= lrecon_tol_vat
lrecon_bank_ok := lrecon_diff_bank <= lrecon_tol_bank

lrecon_reconciled := true if {
    lrecon_vat_ok
    lrecon_bank_ok
} else := false if {
    true
}

lrecon_mismatches_vat := [r |
    r := {"source": "VAT", "expected": lrecon_pkpir, "actual": lrecon_vat, "diff": round2(lrecon_diff_vat)}
    not lrecon_vat_ok
]

lrecon_mismatches_bank := [r |
    r := {"source": "BANK", "expected": lrecon_pkpir, "actual": lrecon_bank, "diff": round2(lrecon_diff_bank)}
    not lrecon_bank_ok
]

lrecon_mismatches := array.concat(lrecon_mismatches_vat, lrecon_mismatches_bank)

lrecon_routing := "" if {
    lrecon_reconciled
} else := "TRIAGE_QUEUE" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r09_ksiegowosc_pkpir_uor_innovations.pkpir_ledger_reconciliation",
    "_legal_basis": "UoR art. 2 ust. 1 pkt 5 (próg 2 000 000 EUR), art. 2 ust. 2 (PKPiR poniżej progu); PIT art. 24a (PKPiR)",
    "package": "jdg.r09_ksiegowosc_pkpir_uor_innovations",
    "priority": 11007,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "lrecon_pkpir_sales_net": lrecon_pkpir,
    "lrecon_vat_sales_base": lrecon_vat,
    "lrecon_bank_inflows": lrecon_bank,
    "lrecon_diff_vat": round2(lrecon_diff_vat),
    "lrecon_diff_bank": round2(lrecon_diff_bank),
    "lrecon_vat_ok": lrecon_vat_ok,
    "lrecon_bank_ok": lrecon_bank_ok,
    "lrecon_reconciled": lrecon_reconciled,
    "lrecon_mismatches": lrecon_mismatches,
    "_routing": lrecon_routing,
    "_routing_reason": sprintf("Uzgodnienie 3-drożne PKPiR↔VAT↔bank — PKPiR kol.7=%.2f vs VAT=%.2f vs bank=%.2f. %s", [lrecon_pkpir, lrecon_vat, lrecon_bank, "ZGODNE (w tolerancji)." if {lrecon_reconciled} else "ROZJAZD — TRIAGE_QUEUE (zero rozjazdów międzyksięgowych)."]),
    "_legal_basis": "rozp. MF o PKPiR (kol. 7 — sprzedaż netto); VAT art. 109 ust. 3 (ewidencja); OrdPU art. 193a (JPK_PKPIR na żądanie)",
    "_warnings": [sprintf("UZGODNIENIE: PKPiR=%.2f / VAT=%.2f / bank=%.2f — %s. Różnica VAT=%.2f, bank=%.2f (tolerancja %.2f%%).", [lrecon_pkpir, lrecon_vat, lrecon_bank, "OK" if {lrecon_reconciled} else "NIEZGODNOŚĆ", round2(lrecon_diff_vat), round2(lrecon_diff_bank), lrecon_tolerance])],
} if {
    object.get(input.jdg_entrepreneur, "r09_ksiegowosc_check", false) == true
    object.get(input, "ledger_reconciliation", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R09-INN-03: AMORTIZATION PLAN OPTIMIZER — optymalizator planu amortyzacji
#             (liniowa vs degresywna vs jednorazowa 100k EUR) per środek trwały
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza asset_plan: {asset_value, kst_group, is_small_taxpayer,
# is_electric}. Wynik: roczna amortyzacja liniowa / degresywna / jednorazowa
# + rekomendacja optymalnej metody podatkowej.
plan_input := object.get(input, "asset_plan", {})
plan_value := max([0, object.get(plan_input, "asset_value", 0)])
plan_kst_group := object.get(plan_input, "kst_group", "0")
plan_small := object.get(plan_input, "is_small_taxpayer", false)
plan_electric := object.get(plan_input, "is_electric", false)

# Stawki KŚT (roczne %) — grupy 0-8 (rozporządzenie RM ws. KŚT); fallback 20%.
plan_kst_rates := {"0": 0.025, "1": 0.04, "2": 0.10, "3": 0.20, "4": 0.30, "5": 0.20, "6": 0.20, "7": 0.05, "8": 0.05}
plan_kst_rate := object.get(plan_kst_rates, plan_kst_group, 0.20)

plan_linear_annual := round2(plan_value * plan_kst_rate)
plan_degressive_rate := min([plan_kst_rate * 2, 0.40])   # degresywna max 40% (art. 22i ust. 5)
plan_degressive_annual := round2(plan_value * plan_degressive_rate)

plan_one_off_limit_pln := one_time_depreciation_eur * eur_pln_reference
plan_one_off_eligible := true if {
    plan_small
    plan_value <= plan_one_off_limit_pln
} else := false if {
    true
}

plan_car_limit := car_limit_electric if {
    plan_electric
} else := car_limit_standard if {
    true
}
plan_car_excess := max([0, plan_value - plan_car_limit])

plan_best_method := "ONE_OFF" if {
    plan_one_off_eligible
} else := "DEGRESSIVE" if {
    plan_degressive_annual > plan_linear_annual
} else := "LINEAR" if {
    true
}

plan_routing := "TRIAGE_QUEUE" if {
    plan_car_excess > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r09_ksiegowosc_pkpir_uor_innovations.amortization_plan_optimizer",
    "_legal_basis": "UoR art. 2 ust. 1 pkt 5 (próg 2 000 000 EUR), art. 2 ust. 2 (PKPiR poniżej progu); PIT art. 24a (PKPiR)",
    "package": "jdg.r09_ksiegowosc_pkpir_uor_innovations",
    "priority": 11008,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "plan_asset_value": plan_value,
    "plan_kst_group": plan_kst_group,
    "plan_kst_rate_pct": round2(plan_kst_rate * 100),
    "plan_linear_annual": plan_linear_annual,
    "plan_degressive_annual": plan_degressive_annual,
    "plan_one_off_eligible": plan_one_off_eligible,
    "plan_one_off_limit_pln": plan_one_off_limit_pln,
    "plan_car_limit_pln": plan_car_limit,
    "plan_car_excess_pln": round2(plan_car_excess),
    "plan_best_method": plan_best_method,
    "_routing": plan_routing,
    "_routing_reason": sprintf("Optymalizator amortyzacji — wartość %.2f PLN (KŚT grupa %s, %.2f%%/rok). Metoda: %s. %s", [plan_value, plan_kst_group, plan_kst_rate * 100, plan_best_method, "Limit auta przekroczony — KUP proporcjonalny (art. 23a pkt 47a PIT)." if {plan_car_excess > 0} else "Plan gotowy."]),
    "_legal_basis": "PIT art. 22a (KŚT), art. 22i (metoda liniowa/degresywna), art. 22k ust. 7-12 (jednorazowa 100k EUR — mały podatnik), art. 23a pkt 47a (limity aut 150k/225k)",
    "_warnings": [sprintf("AMORTYZACJA: liniowa %.2f / degresywna %.2f / jednorazowa %s. Rekomendacja: %s. Limit auta: %.2f PLN (nadwyżka %.2f).", [plan_linear_annual, plan_degressive_annual, "TAK" if {plan_one_off_eligible} else "NIE", plan_best_method, plan_car_limit, round2(plan_car_excess)])],
} if {
    object.get(input.jdg_entrepreneur, "r09_ksiegowosc_check", false) == true
    object.get(input, "asset_plan", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R09-INN-04: INVENTORY DEADLINE MONITOR — monitor terminów inwentaryzacji
#             (art. 26 UoR) z 3 poziomami alertów per typ
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza inventory_monitor: {items: [{label, type, days_left}]}.
# Typy: CASH (co rok), STOCK (koniec roku), FIXED_ASSETS (co 4 lata).
# Poziom: RED ≤30 dni (BLOCK_AND_ALERT), AMBER ≤90 dni (TRIAGE_QUEUE), GREEN.
inv_input := object.get(input, "inventory_monitor", {})
inv_items_in := object.get(inv_input, "items", [])

inv_level(days) := "RED" if {
    days <= 30
} else := "AMBER" if {
    days <= 90
} else := "GREEN" if {
    true
}

inv_next_action(itype) := "Przeprowadź inwentaryzację środków pieniężnych (art. 26 ust. 1 pkt 1 UoR — co rok, na dzień bilansowy)." if {
    itype == "CASH"
} else := "Przeprowadź inwentaryzację zapasów (art. 26 ust. 1 pkt 2 UoR — na koniec roku obrotowego)." if {
    itype == "STOCK"
} else := "Przeprowadź inwentaryzację środków trwałych (art. 26 ust. 1 pkt 3 UoR — co 4 lata, drogą weryfikacji)." if {
    itype == "FIXED_ASSETS"
} else := "Monitoruj termin inwentaryzacji — przygotuj zespół spisowy i arkusze." if {
    true
}

inv_item(i) := {
    "label": object.get(i, "label", "inwentaryzacja"),
    "type": object.get(i, "type", "STOCK"),
    "days_left": object.get(i, "days_left", 999),
    "level": inv_level(object.get(i, "days_left", 999)),
    "next_action": inv_next_action(object.get(i, "type", "STOCK")),
}

inv_items := [inv_item(i) | i := inv_items_in[_]]
inv_red_count := count([x | x := inv_items[_]; x.level == "RED"])
inv_amber_count := count([x | x := inv_items[_]; x.level == "AMBER"])

inv_routing := "BLOCK_AND_ALERT" if {
    inv_red_count > 0
} else := "TRIAGE_QUEUE" if {
    inv_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r09_ksiegowosc_pkpir_uor_innovations.inventory_deadline_monitor",
    "package": "jdg.r09_ksiegowosc_pkpir_uor_innovations",
    "priority": 11009,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "inv_items_total": count(inv_items),
    "inv_red_count": inv_red_count,
    "inv_amber_count": inv_amber_count,
    "inv_fixed_assets_years": inventory_fixed_assets_years,
    "inv_items": inv_items,
    "_routing": inv_routing,
    "_routing_reason": sprintf("Monitor inwentaryzacji — %d pozycji (RED: %d, AMBER: %d). %s", [count(inv_items), inv_red_count, inv_amber_count, "RED ≤30 dni / AMBER ≤90 dni / GREEN (art. 26 UoR)."]),
    "_legal_basis": "UoR art. 26 ust. 1 (inwentaryzacja), art. 27 (terminy); art. 4 ust. 3 (rzetelność)",
    "_warnings": [sprintf("INWENTARYZACJA: %d pozycji — %d RED (≤30 dni), %d AMBER (≤90 dni). Środki trwałe co %d lata (art. 26 ust. 1 pkt 3 UoR).", [count(inv_items), inv_red_count, inv_amber_count, inventory_fixed_assets_years])],
} if {
    object.get(input.jdg_entrepreneur, "r09_ksiegowosc_check", false) == true
    object.get(input, "inventory_monitor", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R09-INN-05: FINANCIAL STATEMENT AUTOPACK — auto-pakiet sprawozdania
#             finansowego (art. 45-49, 52, 74 UoR) z kompletnością fail-closed
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza financial_statements: {year, has_balance_sheet, has_rzis,
# has_notes, has_approval}. Wynik: lista brakujących sekcji, ready,
# terminy (zatwierdzenie 31.03 / złożenie 15.10), retencja 5 lat.
fs_input := object.get(input, "financial_statements", {})
fs_year := object.get(fs_input, "year", 2025)
fs_has_bilans := object.get(fs_input, "has_balance_sheet", false)
fs_has_rzis := object.get(fs_input, "has_rzis", false)
fs_has_notes := object.get(fs_input, "has_notes", false)
fs_has_approval := object.get(fs_input, "has_approval", false)

fs_sections := [
    {"name": "Bilans", "present": fs_has_bilans},
    {"name": "Rachunek zysków i strat", "present": fs_has_rzis},
    {"name": "Informacja dodatkowa", "present": fs_has_notes},
    {"name": "Uchwała o zatwierdzeniu", "present": fs_has_approval},
]

fs_missing := [s.name | s := fs_sections[_]; not s.present]
fs_ready := count(fs_missing) == 0

fs_routing := "" if {
    fs_ready
} else := "TRIAGE_QUEUE" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r09_ksiegowosc_pkpir_uor_innovations.financial_statement_autopack",
    "_legal_basis": "UoR art. 2 ust. 1 pkt 5 (próg 2 000 000 EUR), art. 2 ust. 2 (PKPiR poniżej progu); PIT art. 24a (PKPiR)",
    "package": "jdg.r09_ksiegowosc_pkpir_uor_innovations",
    "priority": 11010,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "fs_year": fs_year,
    "fs_sections_total": count(fs_sections),
    "fs_missing": fs_missing,
    "fs_ready": fs_ready,
    "fs_approval_deadline": sprintf("%d-%s", [fs_year + 1, fs_approval_deadline]),
    "fs_filing_deadline": sprintf("%d-%s", [fs_year + 1, fs_filing_deadline]),
    "fs_retention_years": fs_retention_years,
    "fs_retention_until": sprintf("%d-12-31", [fs_year + 1 + fs_retention_years]),
    "_routing": fs_routing,
    "_routing_reason": sprintf("Auto-pakiet sprawozdania finansowego %d — %s. %s", [fs_year, "KOMPLETNY" if {fs_ready} else "NIEKOMPLETNY", "Brakujące sekcje: " + concat(", ", fs_missing) if {not fs_ready} else "Gotowy do zatwierdzenia i złożenia."]),
    "_legal_basis": "UoR art. 45-49 (sprawozdanie finansowe), art. 52 (zatwierdzenie), art. 69-70 (złożenie do KRS/US), art. 74 (retencja 5 lat)",
    "_warnings": [sprintf("SPRAWOZDANIE %d: %s. Termin zatwierdzenia %s, złożenia %s, retencja do %s.", [fs_year, "kompletne" if {fs_ready} else "niekompletne (" + concat(", ", fs_missing) + ")", sprintf("%d-%s", [fs_year + 1, fs_approval_deadline]), sprintf("%d-%s", [fs_year + 1, fs_filing_deadline]), sprintf("%d-12-31", [fs_year + 1 + fs_retention_years])])],
} if {
    object.get(input.jdg_entrepreneur, "r09_ksiegowosc_check", false) == true
    object.get(input, "financial_statements", {}) != {}
}
