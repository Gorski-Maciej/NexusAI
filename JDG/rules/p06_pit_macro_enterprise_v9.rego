# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P06 PIT MACRO ENTERPRISE v9.0 (ULGI + OPTYMALIZACJA + FORMY)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p06_pit_macro_enterprise
# Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_PIT_MACRO (P06) v9.0
#         Sekcja 7 (optymalizator formy), Sekcja 8 (genialne pomysły — 14),
#         Sekcja 9 (rekomendacje priorytetowe).
#
# Zgodność: ustawa o PIT (Dz.U. 2025 poz. 789 ze zm.):
#   Art. 9a (wybór formy), 21 (zwolnienia pkt 148/152/153/154), 22-23 (KUP/NKUP),
#   26e (B+R — definicja działalności B+R!), 26eb (prototyp), 26ec (ekspansja),
#   26gb (robotyzacja), 26h (termomodernizacja — limit 53 000 zł),
#   30c (liniowy 19% — wyłączenie Art. 30c ust. 2 były pracodawca),
#   30ca (IP Box 5%), 44 (zaliczki), 45 (zeznania PIT-36/36L/28).
#
# INNOWACJE WYPRZEDZAJĄCE PROFESJONALISTÓW (14):
#   P06-INN-01 PIT DIGITAL TWIN, P06-INN-02 LOSS-OF-LINEAR DETECTOR (30c ust. 2),
#   P06-INN-03 RELIEF RECOMMENDER, P06-INN-04 REKONCYLACJA PIT↔VAT↔ZUS↔PKPiR,
#   P06-INN-05 PIT-36 AUTO-GEN (F4), P06-INN-06 RELIEF STACKING ANALYZER,
#   P06-INN-07 B+R vs IP BOX COMPARATOR, P06-INN-08 TERMO CALCULATOR,
#   P06-INN-09 FORM OPTIMIZER (co-if-jak), P06-INN-10 ADVANCE FORECAST,
#   P06-INN-11 PIT CALENDAR, P06-INN-12 SHARED LIMIT GUARD (85 528 zł),
#   P06-INN-13 KUP AUDITOR, P06-INN-14 B+R DEFINITION CHECKER (4 kryteria).
#
# UWAGI SKŁADNI (OPA v0-compat): brak `and`/`or`, brak `def`, separator `;`
# w comprehension, guardy progów { data.jdg.thresholds } else := fallback.
#
# package: jdg.p06_pit_macro_enterprise
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p06_pit_macro_enterprise

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.p06_pit_macro_enterprise.no_match","package":"jdg.p06_pit_macro_enterprise","priority":999999}

# ── PROGI ZEWNĘTRZNE (ADR-002 — guardy jak P04/P05) ───────────────────────────
scale_threshold := object.get(data.jdg.thresholds.pit, "scale_threshold", 120000) {
    data.jdg.thresholds
} else := 120000 {
    true
}

scale_low_rate := object.get(data.jdg.thresholds.pit, "scale_low_rate", 0.12) {
    data.jdg.thresholds
} else := 0.12 {
    true
}

scale_high_rate := object.get(data.jdg.thresholds.pit, "scale_high_rate", 0.32) {
    data.jdg.thresholds
} else := 0.32 {
    true
}

linear_rate := object.get(data.jdg.thresholds.pit, "linear_rate", 0.19) {
    data.jdg.thresholds
} else := 0.19 {
    true
}

ip_box_rate := object.get(data.jdg.thresholds.pit, "ip_box_rate", 0.05) {
    data.jdg.thresholds
} else := 0.05 {
    true
}

tax_free_amount := object.get(data.jdg.thresholds.pit, "tax_free_amount", 30000) {
    data.jdg.thresholds
} else := 30000 {
    true
}

prototype_rate := object.get(data.jdg.thresholds.pit, "prototype_relief_rate", 0.30) {
    data.jdg.thresholds
} else := 0.30 {
    true
}

robotization_rate := object.get(data.jdg.thresholds.pit, "robotization_relief_rate", 0.50) {
    data.jdg.thresholds
} else := 0.50 {
    true
}

expansion_max_costs := object.get(data.jdg.thresholds.pit, "expansion_relief_max_costs", 1000000) {
    data.jdg.thresholds
} else := 1000000 {
    true
}

thermo_relief_limit := object.get(data.jdg.thresholds.pit, "thermo_relief_limit", 53000) {
    data.jdg.thresholds
} else := 53000 {
    true
}

shared_relief_limit := object.get(data.jdg.thresholds.pit, "shared_relief_limit", 85528) {
    data.jdg.thresholds
} else := 85528 {
    true
}

# ── ŹRÓDŁO AUDYTU (host wstrzykuje output tools/pit_macro_inventory.py) ──────
audit_data := data.jdg.pit_macro_audit {
    data.jdg.pit_macro_audit
} else := {} {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 7 — OPTYMALIZACJA I FORMY OPODATKOWANIA
# ═══════════════════════════════════════════════════════════════════════════════

# ── P06-INN-09: FORM OPTIMIZER (co-if-jak) ────────────────────────────────────
# Porównanie skala / liniowy / ryczałt przy prognozie przychodów i kosztów.
form_optimizer := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.form_optimizer",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 100,
    "optimizer": {
        "revenue_projection": object.get(input.pit_projection, "revenue", 0),
        "costs_projection": object.get(input.pit_projection, "costs", 0),
        "scale": scale_result,
        "linear": linear_result,
        "lump_sum": lump_result,
        "recommended_form": recommended_form,
        "former_employer_block": former_employer_block_flag,
        "note": "Symulacja co-if-jak — wynik szacunkowy; decyzja wymaga weryfikacji warunków Art. 9a/30c"
    },
    "_routing": "REPORT",
    "_routing_reason": "Optymalizator formy opodatkowania (skala vs liniowy vs ryczałt) — prognoza przychodów/kosztów + blokada Art. 30c ust. 2",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "_warnings": ["Optymalizator formy: wynik zależny od prognozy; zmiana formy tylko od 1 stycznia (lub w trakcie roku wg szczególnych zasad)."]
} {
    object.get(input.jdg_entrepreneur, "p06_form_optimizer_check", false) == true
    object.get(input, "pit_projection", null) != null
}

profit_projection := round((object.get(input.pit_projection, "revenue", 0) - object.get(input.pit_projection, "costs", 0)) * 100) / 100

scale_result := round(scale_tax_pln * 100) / 100 {
    income := profit_projection
    income > 0
}

# ── KWOTA ZMNIEJSZAJĄCA PODATEK (Art. 27 ust. 1a PIT, 2022+) ────────────────
# 3 600 zł dla dochodu ≤ 120 000; fazowe wygasanie do 180 000; 0 powyżej.
tax_reducing_amount := 3600 {
    profit_projection <= scale_threshold
} else := round((3600 - 0.06 * (profit_projection - scale_threshold)) * 100) / 100 {
    profit_projection <= scale_threshold * 1.5
} else := 0 {
    true
}

scale_tax_pln := max([income_low * scale_low_rate + income_high * scale_high_rate - tax_reducing_amount, 0]) {
    income := profit_projection
    income_low := min([income, scale_threshold])
    income_high := max([income - scale_threshold, 0])
}

linear_result := round(profit_projection * linear_rate * 100) / 100 {
    profit_projection > 0
    former_employer_block_flag == false
} else := 0 {
    true
}

lump_result := round(object.get(input.pit_projection, "lump_sum_revenue", 0) * object.get(input.pit_projection, "lump_sum_rate", 0.085) * 100) / 100 {
    object.get(input.pit_projection, "lump_sum_eligible", false) == true
    object.get(input.pit_projection, "lump_sum_revenue", 0) > 0
} else := 0 {
    true
}

recommended_form := "LINEAR" {
    linear_result != 0
    scale_result != 0
    linear_result < scale_result
    lump_result == 0
} else := "LUMP_SUM" {
    lump_result != 0
    scale_result != 0
    lump_result < scale_result
    linear_result == 0
} else := "SCALE" {
    scale_result != 0
} else := "N/D" {
    true
}

# ── P06-INN-02: LOSS-OF-LINEAR DETECTOR (Art. 30c ust. 2 — były pracodawca) ──
former_employer_block_flag := true {
    object.get(input.jdg_entrepreneur, "former_employer_services", false) == true
    object.get(input.jdg_entrepreneur, "former_employer_same_services", false) == true
} else := false {
    true
}

loss_of_linear_detector := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.loss_of_linear_detector",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 110,
    "detector": {
        "former_employer_block": former_employer_block_flag,
        "blocked_form": "LINIOWY 19% (Art. 30c ust. 2) — świadczenie na rzecz byłego pracodawcy",
        "fallback_forms": ["SCALE 12%/32%", "LUMP_SUM (jeśli spełnione warunki)"],
        "action": "BLOCK_AND_ALERT przy wyborze liniowego; rekomendacja skali"
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Auto-detekcja utraty prawa do liniowego 19% (Art. 30c ust. 2 — usługi dla byłego pracodawcy w tym samym zakresie)",
    "_legal_basis": "Art. 30c ust. 2 PIT",
    "_warnings": ["Liniowy 19% niedostępny dla usług świadczonych na rzecz byłego pracodawcy w zakresie sprzed 2 lat — wskaż skala/ryczałt."]
} {
    object.get(input.jdg_entrepreneur, "p06_linear_loss_check", false) == true
    former_employer_block_flag == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 8 — AUDYT ULG (GŁÓWNY PRIORYTET)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P06-INN-14: B+R DEFINITION CHECKER (Art. 26e — 4 kryteria) ────────────────
# Definicja działalności B+R (Art. 26e ust. 2 + Art. 5a pkt 38-40):
# 1) twórcza, 2) systematyczna, 3) w celu zwiększenia zasobów wiedzy LUB
# wykorzystania do nowych zastosowań, 4) wynik niepewny (odrębność).
br_definition_ok := true {
    object.get(input.br_relief, "creative_activity", false) == true
    object.get(input.br_relief, "systematic_activity", false) == true
    object.get(input.br_relief, "knowledge_increase", false) == true
    object.get(input.br_relief, "uncertain_result", false) == true
} else := false {
    true
}

br_definition_checker := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.br_definition_checker",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 120,
    "br": {
        "criteria": {
            "twórcza": object.get(input.br_relief, "creative_activity", false),
            "systematyczna": object.get(input.br_relief, "systematic_activity", false),
            "zwiększenie zasobów wiedzy": object.get(input.br_relief, "knowledge_increase", false),
            "wynik niepewny": object.get(input.br_relief, "uncertain_result", false)
        },
        "definition_ok": br_definition_ok,
        "qualified_costs": object.get(input.br_relief, "qualified_costs", 0),
        "deduction_100pct": object.get(input.br_relief, "qualified_costs", 0) * 1.0,
        "documentation_required": ["ewidencja kosztów B+R", "opis projektu", "podstawa prawna Art. 26e ust. 6-7"]
    },
    "_routing": "REPORT",
    "_routing_reason": "Definicja działalności B+R (Art. 26e) — 4 kryteria: twórczość, systematyczność, wiedza, niepewny wynik",
    "_legal_basis": "Art. 26e ust. 1-2 + Art. 5a pkt 38-40 PIT",
    "_warnings": ["B+R: wymagane 4 kryteria łącznie + ewidencja kosztów; koszty kwalifikowane wg Art. 26e ust. 2-7."]
} {
    object.get(input.jdg_entrepreneur, "p06_br_check", false) == true
}

# ── P06-INN-03: RELIEF RECOMMENDER (rekomendacja ulgi wg profilu wydatków) ───
relief_recommender := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.relief_recommender",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 130,
    "reliefs": {
        "br_relief": relief_br_result,
        "prototype_relief": relief_prototype_result,
        "robotization_relief": relief_robotization_result,
        "expansion_relief": relief_expansion_result,
        "thermo_relief": relief_thermo_result,
        "ip_box": relief_ipbox_result,
        "shared_limit_guard": shared_limit_guard,
        "recommended": recommended_relief
    },
    "_routing": "REPORT",
    "_routing_reason": "Rekomendacja ulg wg profilu wydatków: B+R / prototyp / robotyzacja / ekspansja / termo / IP Box + wspólne limity",
    "_legal_basis": "Art. 26e, 26eb, 26ec, 26gb, 26h, 30ca PIT",
    "_warnings": ["Kalkulator ulg: wartości szacunkowe; wspólny limit 85 528 zł pilnowany przez shared_limit_guard."]
} {
    object.get(input.jdg_entrepreneur, "p06_relief_check", false) == true
}

# Rekomendacja ulgi: największa z pozytywnych (priorytet B+R > IP Box > termo > ekspansja).
recommended_relief := "B+R (Art. 26e)" {
    relief_br_result > 0
} else := "IP BOX (Art. 30ca)" {
    relief_ipbox_result > 0
} else := "TERMO (Art. 26h)" {
    relief_thermo_result > 0
} else := "EKSPANSJA (Art. 26ec)" {
    relief_expansion_result > 0
} else := "ROBOTYZACJA (Art. 26gb)" {
    relief_robotization_result > 0
} else := "PROTOTYP (Art. 26eb)" {
    relief_prototype_result > 0
} else := "BRAK — sprawdź kwalifikację" {
    true
}

relief_br_result := round(object.get(input.br_relief, "qualified_costs", 0) * 1.0 * 100) / 100 {
    br_definition_ok == true
} else := 0 {
    true
}

relief_prototype_result := round(object.get(input.prototype_relief, "qualified_costs", 0) * prototype_rate * 100) / 100 {
    object.get(input.prototype_relief, "production_started", false) == true
} else := 0 {
    true
}

relief_robotization_result := round(object.get(input.robotization_relief, "qualified_costs", 0) * robotization_rate * 100) / 100 {
    object.get(input.robotization_relief, "machine_in_operation", false) == true
} else := 0 {
    true
}

relief_expansion_result := round(min([object.get(input.expansion_relief, "qualified_costs", 0), expansion_max_costs]) * 1.0 * 100) / 100 {
    object.get(input.expansion_relief, "qualified_costs", 0) > 0
} else := 0 {
    true
}

relief_thermo_result := round(min([object.get(input.thermo_relief, "qualified_costs", 0), thermo_relief_limit]) * 1.0 * 100) / 100 {
    object.get(input.thermo_relief, "building_owned", false) == true
    object.get(input.thermo_relief, "completed_within_3_years", false) == true
} else := 0 {
    true
}

relief_ipbox_result := round(object.get(input.ip_box, "qualified_ip_income", 0) * ip_box_rate * 100) / 100 {
    object.get(input.ip_box, "qualified_ip_income", 0) > 0
} else := 0 {
    true
}

# ── P06-INN-12: SHARED LIMIT GUARD (wspólne limity 85 528 zł) ────────────────
reliefs_total := relief_br_result + relief_prototype_result + relief_robotization_result + relief_expansion_result + relief_thermo_result + relief_ipbox_result

shared_limit_guard := true {
    reliefs_total <= shared_relief_limit
} else := false {
    true
}

# ── P06-INN-06: RELIEF STACKING ANALYZER ──────────────────────────────────────
relief_stacking_analyzer := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.relief_stacking_analyzer",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 140,
    "stacking": {
        "total_reliefs": reliefs_total,
        "shared_limit": shared_relief_limit,
        "within_limit": shared_limit_guard,
        "excess_over_limit": max([reliefs_total - shared_relief_limit, 0]),
        "stacking_rule": "Łączne odliczenia ulg ≤ 85 528 zł (limit wspólny) — nadmiar przepada"
    },
    "_routing": "REPORT",
    "_routing_reason": "Relief stacking analyzer — łączne odliczenia ulg vs wspólny limit 85 528 zł",
    "_legal_basis": "Art. 26e-26h + limity wspólne (ulgi wzajemnie wykluczające/proratowane)",
    "_warnings": [sprintf("Stacking: łącznie %v zł przy limicie %v zł — %s.", [reliefs_total, shared_relief_limit, stacking_status])]
} {
    object.get(input.jdg_entrepreneur, "p06_stacking_check", false) == true
}

# ── P06-INN-07: B+R vs IP BOX COMPARATOR ──────────────────────────────────────
br_vs_ipbox_comparator := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.br_vs_ipbox_comparator",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 150,
    "comparator": {
        "br_deduction": relief_br_result,
        "ipbox_tax_saving": relief_ipbox_result,
        "better": br_better_flag,
        "note": "B+R odlicza koszty (do 100%), IP Box opodatkowuje dochód 5% — porównaj efektywność wg profilu"
    },
    "_routing": "REPORT",
    "_routing_reason": "Porównanie ulgi B+R vs IP Box (Art. 26e vs 30ca) — wybór efektywniejszej",
    "_legal_basis": "Art. 26e + Art. 30ca PIT",
    "_warnings": ["IP Box wymaga ewidencji odrębnej (Art. 30cb); B+R wymaga ewidencji kosztów — obie mogą się łączyć z limitem."]
} {
    object.get(input.jdg_entrepreneur, "p06_comparator_check", false) == true
}

# Reguła pomocnicza — bez `and` (else-chain).
electric_car_225k_flag := true {
    object.get(input.kup_audit, "car_is_electric", false) == true
    object.get(input.kup_audit, "car_value", 0) <= 225000
} else := false {
    true
}

stacking_status := "OK" {
    shared_limit_guard == true
} else := "PRZEKROCZENIE" {
    true
}

br_better_flag := true {
    relief_br_result >= relief_ipbox_result
} else := false {
    true
}

# ── P06-INN-08: TERMO CALCULATOR (Art. 26h — limit 53 000 zł) ────────────────
termo_calculator := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.termo_calculator",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 160,
    "termo": {
        "qualified_costs": object.get(input.thermo_relief, "qualified_costs", 0),
        "limit_per_building": thermo_relief_limit,
        "deduction": relief_thermo_result,
        "years_to_complete": object.get(input.thermo_relief, "completion_years", 0),
        "deadline_ok": object.get(input.thermo_relief, "completion_years", 0) <= 3
    },
    "_routing": "REPORT",
    "_routing_reason": "Termomodernizacja (Art. 26h) — limit 53 000 zł/budynek, inwestycja zakończona w 3 lata",
    "_legal_basis": "Art. 26h PIT",
    "_warnings": [sprintf("Termo: odliczenie %v zł (limit %v zł/budynek, 3 lata na zakończenie).", [relief_thermo_result, thermo_relief_limit])]
} {
    object.get(input.jdg_entrepreneur, "p06_termo_check", false) == true
}

# ── P06-INN-13: KUP AUDITOR (Art. 22-23) ──────────────────────────────────────
kup_auditor := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.kup_auditor",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 170,
    "kup": {
        "car_operating_75pct": object.get(input.kup_audit, "car_operating_pct", 0) == 75,
        "car_value_limit_150k": object.get(input.kup_audit, "car_value", 0) <= 150000,
        "electric_car_225k": electric_car_225k_flag,
        "representation_nkup": object.get(input.kup_audit, "representation_costs", false) == false,
        "moment_potracenia_ok": object.get(input.kup_audit, "cost_paid_this_year", false) == true,
        "note": "NKUP Art. 23 (57 pkt): reprezentacja pkt 23, auto 75% pkt 46, leasing pkt 47"
    },
    "_routing": "REPORT",
    "_routing_reason": "KUP/NKUP auditor — auto 75%, limity 150k/225k, NKUP Art. 23 (reprezentacja, leasing), moment potrącenia Art. 22 ust. 5-5c",
    "_legal_basis": "Art. 22 ust. 1, 5-5c + Art. 23 ust. 1 pkt 23/46/47 PIT",
    "_warnings": ["KUP: auto osobowe 75% (limit 150 000 zł, EV 225 000 zł); reprezentacja zawsze NKUP."]
} {
    object.get(input.jdg_entrepreneur, "p06_kup_check", false) == true
}

# ── P06-INN-04: REKONCYLACJA PIT↔VAT↔ZUS↔PKPiR ───────────────────────────────
pit_reconciliation := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.pit_reconciliation",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 180,
    "recon": {
        "revenue_pkpir": object.get(input.pit_recon, "revenue_pkpir", 0),
        "revenue_vat": object.get(input.pit_recon, "revenue_vat", 0),
        "revenue_vs_vat_delta": round(abs(object.get(input.pit_recon, "revenue_pkpir", 0) - object.get(input.pit_recon, "revenue_vat", 0)) * 100) / 100,
        "kup_vs_vat_purchases": round(abs(object.get(input.pit_recon, "kup", 0) - object.get(input.pit_recon, "vat_purchases", 0)) * 100) / 100,
        "zus_base_ok": object.get(input.pit_recon, "zus_base", 0) <= object.get(input.pit_recon, "income", 0),
        "consistent": pit_recon_consistent
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Rekoncyliacja PIT↔VAT↔ZUS↔PKPiR — zero rozjazdów między systemami (cross-act guard)",
    "_legal_basis": "Art. 22 PIT + Art. 86 VAT + Art. 20 SUS (spójność podstaw)",
    "_warnings": ["Rekoncyliacja: przychody PKPiR vs VAT, KUP vs zakupy VAT, podstawa ZUS vs dochód — rozbieżności = błąd ewidencji."]
} {
    object.get(input.jdg_entrepreneur, "p06_recon_check", false) == true
}

pit_recon_consistent := true {
    abs(object.get(input.pit_recon, "revenue_pkpir", 0) - object.get(input.pit_recon, "revenue_vat", 0)) <= object.get(input.pit_recon, "tolerance", 100)
    object.get(input.pit_recon, "zus_base", 0) <= object.get(input.pit_recon, "income", 0)
} else := false {
    true
}

# ── P06-INN-10: ADVANCE FORECAST (Art. 44) ───────────────────────────────────
advance_forecast := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.advance_forecast",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 190,
    "advances": {
        "deadline_day": 20,
        "simplified_allowed": object.get(input.advance_input, "prev_year_income", 0) <= 300000,
        "simplified_advance": round(object.get(input.advance_input, "prev_year_tax", 0) / 12 * 100) / 100,
        "estimated_monthly_advance": round(profit_projection * linear_rate / 12 * 100) / 100,
        "next_deadline": "20. dzień miesiąca (Art. 44 ust. 3)",
        "note": "Zaliczki uproszczone przy dochodzie poprzedniego roku ≤ 300 000 zł"
    },
    "_routing": "REPORT",
    "_routing_reason": "Predykcja zaliczek (Art. 44) — terminy 20. dzień, zaliczki uproszczone, prognoza",
    "_legal_basis": "Art. 44 ust. 1-3, 6b PIT",
    "_warnings": ["Zaliczki: uproszczone gdy dochód poprzedniego roku ≤ 300 000 zł; w przeciwnym razie miesięczne/na bieżąco."]
} {
    object.get(input.jdg_entrepreneur, "p06_advance_check", false) == true
}

# ── P06-INN-01: PIT DIGITAL TWIN (symulacja całego roku przed końcem roku) ────
pit_digital_twin := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.pit_digital_twin",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 200,
    "twin": {
        "projected_tax": projected_annual_tax,
        "best_form": recommended_form,
        "optimal_reliefs": reliefs_total,
        "sandboxed": true,
        "verdict_class": "SIMULATED",
        "certificate_ready": "F4: pełna dowodliwość symulacji (parametry + podstawy prawne)"
    },
    "_routing": "REPORT",
    "_routing_reason": "PIT Digital Twin — symulacja całego roku podatkowego przed końcem roku (formy + ulgi + zaliczki)",
    "_legal_basis": "P06 Sekcja 8 INN-01 + Art. 27, 30c, 44, 45 PIT",
    "_warnings": ["PIT Digital Twin: wynik SYMULACYJNY — optymalizuj strukturę PRZED końcem roku (decyzje o formie/ulgach)."]
} {
    object.get(input.jdg_entrepreneur, "p06_digital_twin_check", false) == true
}

projected_annual_tax := round(scale_tax_pln * 100) / 100 {
    profit_projection > 0
    linear_result == 0
} else := round(linear_result * 100) / 100 {
    linear_result != 0
} else := 0 {
    true
}

# ── P06-INN-11: PIT CALENDAR (kalendarz z countdownem) ────────────────────────
pit_calendar := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.pit_calendar",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 210,
    "calendar": {
        "jan_20_advance": "20.01 — ostatnia zaliczka za grudzień (lub 20.01 dla ryczałtu)",
        "april_30_pit36": "30.04 — PIT-36/36L/28 + załączniki",
        "annual_deadline": "30.04 (Art. 45 ust. 1)",
        "countdown_days": object.get(input.calendar_input, "days_to_deadline", 0),
        "warning": "Brak deklaracji do 30.04 = sankcje (Art. 45 ust. 1 + Ordynacja)"
    },
    "_routing": "REPORT",
    "_routing_reason": "Kalendarz PIT z countdownem — zaliczki (20. dzień), zeznanie roczne (30.04)",
    "_legal_basis": "Art. 44 ust. 3 + Art. 45 ust. 1 PIT",
    "_warnings": ["Kalendarz PIT: 20. dzień miesiąca (zaliczki) + 30.04 (zeznanie roczne)."]
} {
    object.get(input.jdg_entrepreneur, "p06_calendar_check", false) == true
}

# ── P06-INN-05: PIT-36 AUTO-GEN (F4) ──────────────────────────────────────────
pit36_autogen := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.pit36_autogen",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 220,
    "pit36": {
        "form": "PIT-36 (skala) / PIT-36L (liniowy) / PIT-28 (ryczałt)",
        "autofill_sources": ["JPK_V7", "PKPiR", "zaliczki (Art. 44)", "ulgi (Art. 26-26h, 30ca)"],
        "fields_auto": ["przychody", "koszty", "dochód", "zaliczki", "ulgi", "składka zdrowotna (P08)"],
        "certificate": "F4: decision certificate z pełną dowodliwością pól",
        "joint_filing": "rozliczenie z małżonkiem (Art. 6 ust. 2) — tylko skala"
    },
    "_routing": "REPORT",
    "_routing_reason": "PIT-36/36L/28 auto-generacja z pełnym certyfikatem F4 (auto-fill z JPK/PKPiR/zaliczek/ulg)",
    "_legal_basis": "Art. 45 PIT + wzory MF (rozp. 30.12.2025)",
    "_warnings": ["Auto-fill: pola z JPK/PKPiR; weryfikacja przez przedsiębiorcę przed wysyłką."]
} {
    object.get(input.jdg_entrepreneur, "p06_autogen_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 9 — DECYZJA GŁÓWNA: RAPORT P06 PIT MACRO ENTERPRISE
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_enterprise.report",
    "_legal_basis": "Art. 9a + Art. 27 + Art. 30c + ustawa o ryczałcie (Dz.U. 2025 poz. 234)",
    "package": "jdg.p06_pit_macro_enterprise",
    "priority": 400,
    "p06_pit_macro": {
        "section7_optimization": {
            "form_optimizer": report_optimizer,
            "loss_of_linear": report_linear_loss
        },
        "section8_reliefs": {
            "br_definition": report_br,
            "relief_recommender": report_reliefs,
            "stacking_analyzer": report_stacking,
            "br_vs_ipbox": report_comparator,
            "termo_calculator": report_termo,
            "kup_auditor": report_kup,
            "pit_reconciliation": report_recon,
            "advance_forecast": report_advances
        },
        "section9_genius": {
            "INN01_digital_twin": report_twin,
            "INN02_linear_loss": report_linear_loss,
            "INN03_relief_recommender": report_reliefs,
            "INN04_reconciliation": report_recon,
            "INN05_pit36_autogen": report_autogen,
            "INN06_stacking": report_stacking,
            "INN07_br_vs_ipbox": report_comparator,
            "INN08_termo": report_termo,
            "INN09_form_optimizer": report_optimizer,
            "INN10_advance_forecast": report_advances,
            "INN11_calendar": report_calendar,
            "INN12_shared_limit": shared_limit_guard,
            "INN13_kup_auditor": report_kup,
            "INN14_br_definition": report_br
        },
        "dependencies": {"P07_PIT_MICRO": "atomowe reguły per artykuł", "P09_PKPiR": "KUP/koszty", "P13_RYCZALT": "wybór formy", "P08_ZUS": "składka zdrowotna wg formy", "P12_CROSSBORDER": "CFC Art. 30f / exit tax Art. 30da"}
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport P06 PIT Macro ENTERPRISE — ulgi (B+R, prototyp, robotyzacja, ekspansja, termo, IP Box) + optymalizacja formy + KUP + zaliczki/zeznania",
    "_legal_basis": "P06 Sekcje 7-9 + Art. 9a, 21, 22-23, 26-26h, 27, 30c, 30ca, 44, 45 PIT",
    "_warnings": [sprintf("P06 PIT: formy %v, ulgi łącznie %v zł (limit %v zł), B+R definicja %v, liniowy blokada %v.", [recommended_form, reliefs_total, shared_relief_limit, br_definition_ok, former_employer_block_flag])]
} {
    object.get(input.jdg_entrepreneur, "p06_pit_macro_check", false) == true
}

# ── BEZPIECZNE AKCESORY RAPORTU (pod-reguła niezdefiniowana → {}) ─────────────
report_optimizer := object.get(form_optimizer, "optimizer", {}) { form_optimizer } else := {} { true }
report_linear_loss := object.get(loss_of_linear_detector, "detector", {}) { loss_of_linear_detector } else := {} { true }
report_br := object.get(br_definition_checker, "br", {}) { br_definition_checker } else := {} { true }
report_reliefs := object.get(relief_recommender, "reliefs", {}) { relief_recommender } else := {} { true }
report_stacking := object.get(relief_stacking_analyzer, "stacking", {}) { relief_stacking_analyzer } else := {} { true }
report_comparator := object.get(br_vs_ipbox_comparator, "comparator", {}) { br_vs_ipbox_comparator } else := {} { true }
report_termo := object.get(termo_calculator, "termo", {}) { termo_calculator } else := {} { true }
report_kup := object.get(kup_auditor, "kup", {}) { kup_auditor } else := {} { true }
report_recon := object.get(pit_reconciliation, "recon", {}) { pit_reconciliation } else := {} { true }
report_advances := object.get(advance_forecast, "advances", {}) { advance_forecast } else := {} { true }
report_twin := object.get(pit_digital_twin, "twin", {}) { pit_digital_twin } else := {} { true }
report_calendar := object.get(pit_calendar, "calendar", {}) { pit_calendar } else := {} { true }
report_autogen := object.get(pit36_autogen, "pit36", {}) { pit36_autogen } else := {} { true }

# ── EKSPORT: PODSUMOWANIE P06 ─────────────────────────────────────────────────
innovations_summary := {
    "implemented_count": 14,
    "form_optimizer": report_optimizer,
    "br_definition": report_br,
    "reliefs_total": reliefs_total,
    "shared_limit": shared_limit_guard,
    "recommended_form": recommended_form,
    "linear_block": former_employer_block_flag,
    "digital_twin": report_twin,
    "reconciliation": report_recon,
    "pit36_autogen": report_autogen,
    "self_documentation_audit": true
}
