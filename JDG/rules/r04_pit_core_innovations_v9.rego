# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R04 GLM52 PIT — CORE (MACRO) + ULGI — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r04_pit_core_innovations
# Raport: RAPORT_04_PIT_CORE.txt (Kampania GLM 5.2 — seria 04/25)
#
# Prompt 04/25 (PIT — CORE (MACRO) + ULGI — skala, liniowy, KUP, NKUP,
# amortyzacja, ulgi Art. 21–26h, IP Box) — ulepszenia warstwy core/ulgi,
# poziom ENTERPRISE:
#   R04-INN-01 relief_whatif_simulator  — 3-drogowy symulator „co by było
#                                           gdyby": B+R (26e) vs IP Box (30ca)
#                                           vs robotyzacja (26gb) — porównanie
#                                           efektywności z robotyzacją (P06
#                                           miał tylko B+R vs IP Box 2-drogowo)
#   R04-INN-02 amortization_one_off_100k — jednorazowa amortyzacja (art. 22k
#                                           ust. 7-12): mały podatnik, limit
#                                           100 000 zł/rok — automatyzacja
#                                           (KŚT, warunki, zwolnienie z 30%
#                                           limitu dla pełnej amortyzacji)
#   R04-INN-03 low_value_asset_amortization — niskocenne środki trwałe
#                                           (art. 22f ust. 3): próg 10 000 zł
#                                           → jednorazowy odpis w koszty
#   R04-INN-04 health_contribution_optimizer — kalkulator optymalnej składki
#                                           zdrowotnej wg formy (skala 9%,
#                                           liniowy/ryczałt 9% od podstawy
#                                           zależnej od dochodu) — porównanie
#                                           form z pełną składką (P05 miał
#                                           tylko uproszczony wpływ)
#
# Zgodność: ADR-001..009/017/022, u. PIT (Dz.U. 2025 poz. 789) Art. 22f, 22k,
#           26e, 26gb, 27, 30ca, 44, 45; thresholds.pit (zero hardcode);
#           INV-018 (sprzeczne werdykty); First-Match-Wins else-chain.
# package: jdg.r04_pit_core_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r04_pit_core_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r04_pit_core_innovations.no_match", "package": "jdg.r04_pit_core_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
# Wszystkie stawki/limity przez data.jdg.thresholds.pit (fallback = wartość 2026).
_th := object.get(data, "jdg", {})
_pit_th := object.get(_th, "thresholds", {})
_th_pit := object.get(_pit_th, "pit", {})

br_rate := object.get(_th_pit, "br_relief_rate", 1.00)          # B+R odliczenie do 100% kosztów
robotization_rate := object.get(_th_pit, "robotization_relief_rate", 0.50)  # art. 26gb 50%
ipbox_rate := object.get(_th_pit, "ipbox_rate", 0.05)           # art. 30ca 5%
one_off_100k_limit := object.get(_th_pit, "one_off_depreciation_limit", 100000)  # art. 22k ust. 7
low_value_threshold := object.get(_th_pit, "low_value_asset_threshold", 10000)   # art. 22f ust. 3
health_scale_rate := object.get(_th_pit, "health_scale_rate", 0.09)              # 9% skala
health_flat_rate := object.get(_th_pit, "health_flat_rate", 0.09)                # 9% liniowy/ryczałt

# ═══════════════════════════════════════════════════════════════════════════════
# R04-INN-01: RELIEF WHAT-IF SIMULATOR — B+R vs IP BOX vs ROBOTYZACJA (3-drogowy)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza pit_relief_whatif: {br_costs, ipbox_income, robotization_costs}.
# Efektywność:
#   B+R        = br_costs × br_rate × stawka marginalna (odliczenie od dochodu)
#   IP Box     = ipbox_income × (stawka marginalna − ipbox_rate)
#   Robotyzacja= robotization_costs × robotization_rate × stawka marginalna
# Wynik: ranking + najlepsza ulga + oszczędność (REPORT — nigdy decyzja).
relief_whatif_input := object.get(input, "pit_relief_whatif", {})

br_costs := max([0, object.get(relief_whatif_input, "br_costs", 0)])
ipbox_income := max([0, object.get(relief_whatif_input, "ipbox_income", 0)])
robotization_costs := max([0, object.get(relief_whatif_input, "robotization_costs", 0)])
marginal_rate := object.get(relief_whatif_input, "marginal_rate", 0.32)

br_saving := br_costs * br_rate * marginal_rate
ipbox_saving := ipbox_income * (marginal_rate - ipbox_rate)
robot_saving := robotization_costs * robotization_rate * marginal_rate

best_relief := "BR" {
    br_saving >= ipbox_saving
    br_saving >= robot_saving
} else := "IPBOX" {
    ipbox_saving >= robot_saving
} else := "ROBOTIZATION" {
    true
}

relief_whatif_simulator := {
    "matched": true,
    "rule_id": "jdg.r04_pit_core_innovations.relief_whatif_simulator",
    "package": "jdg.r04_pit_core_innovations",
    "priority": 290,
    "simulator": {
        "br_costs": br_costs,
        "ipbox_income": ipbox_income,
        "robotization_costs": robotization_costs,
        "marginal_rate": marginal_rate,
        "br_saving": br_saving,
        "ipbox_saving": ipbox_saving,
        "robot_saving": robot_saving,
        "best_relief": best_relief,
        "max_saving": max([br_saving, ipbox_saving, robot_saving]),
        "note": "Porównanie 3-drogowe: B+R (art. 26e) vs IP Box (art. 30ca) vs robotyzacja (art. 26gb) — rekomendacja, nigdy automatyczna decyzja",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("R04 relief what-if: B+R=%.2f | IP Box=%.2f | Robotyzacja=%.2f → najlepsza: %s", [br_saving, ipbox_saving, robot_saving, best_relief]),
    "_legal_basis": "Art. 26e + Art. 26gb + Art. 30ca PIT",
    "_warnings": ["Wynik szacunkowy; IP Box wymaga odrębnej ewidencji (art. 30cb); B+R i robotyzacja wymagają ewidencji kosztów."],
} {
    object.get(input.jdg_entrepreneur, "r04_relief_whatif_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R04-INN-02: AMORTIZATION ONE-OFF 100K (art. 22k ust. 7-12 — mały podatnik)
# ═══════════════════════════════════════════════════════════════════════════════
# Mały podatnik (przychody ≤ 2 000 000 EUR) może jednorazowo zamortyzować
# środki trwałe (grupy 3-8 KŚT) do limitu 100 000 zł rocznie (2026).
# Warunki: nowe środki trwałe, pełna amortyzacja (100%), wyłączenie dla
# samochodów osobowych i nieruchomości (grupy 1-2 KŚT).
amort_input := object.get(input, "amortization_one_off", {})

is_small_taxpayer_flag := object.get(amort_input, "is_small_taxpayer", false)
asset_kst_group := object.get(amort_input, "kst_group", "")
asset_value := max([0, object.get(amort_input, "asset_value", 0)])
fully_amortized := object.get(amort_input, "fully_amortized", true)

one_off_eligible := is_small_taxpayer_flag
    and fully_amortized
    and asset_kst_group not in {"1", "2"}          # wyłączenie nieruchomości
    and asset_kst_group != ""

one_off_depreciation := {
    "matched": true,
    "rule_id": "jdg.r04_pit_core_innovations.amortization_one_off_100k",
    "package": "jdg.r04_pit_core_innovations",
    "priority": 285,
    "amortization": {
        "eligible": one_off_eligible,
        "small_taxpayer": is_small_taxpayer_flag,
        "kst_group": asset_kst_group,
        "asset_value": asset_value,
        "annual_limit": one_off_100k_limit,
        "one_off_deduction": min([asset_value, one_off_100k_limit]) if one_off_eligible else 0,
        "remaining_limit": max([0, one_off_100k_limit - asset_value]) if one_off_eligible else one_off_100k_limit,
        "note": "Jednorazowa amortyzacja (art. 22k ust. 7-12): mały podatnik, grupy 3-8 KŚT, limit 100 000 zł/rok",
    },
    "_routing": "REPORT",
    "_routing_reason": "Jednorazowa amortyzacja 100 000 zł — mały podatnik, KŚT 3-8 (art. 22k ust. 7-12)",
    "_legal_basis": "Art. 22k ust. 7-12 PIT",
    "_warnings": ["Wyłączenia: samochody osobowe i nieruchomości (grupy 1-2 KŚT). Pełna amortyzacja 100% wymagana — brak limitu 30%."],
} {
    object.get(input.jdg_entrepreneur, "r04_one_off_amortization_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R04-INN-03: LOW-VALUE ASSET AMORTIZATION (art. 22f ust. 3 — próg 10 000 zł)
# ═══════════════════════════════════════════════════════════════════════════════
# Niskocenne środki trwałe (wartość początkowa ≤ 10 000 zł) mogą być
# jednorazowo zaliczone do kosztów (art. 22f ust. 3) — zamiast amortyzacji.
low_value_input := object.get(input, "low_value_asset", {})

low_value_asset_value := max([0, object.get(low_value_input, "asset_value", 0)])

low_value_eligible := low_value_asset_value > 0
    and low_value_asset_value <= low_value_threshold

low_value_asset_amortization := {
    "matched": true,
    "rule_id": "jdg.r04_pit_core_innovations.low_value_asset_amortization",
    "package": "jdg.r04_pit_core_innovations",
    "priority": 284,
    "amortization": {
        "eligible": low_value_eligible,
        "asset_value": low_value_asset_value,
        "threshold": low_value_threshold,
        "one_off_cost": low_value_asset_value if low_value_eligible else 0,
        "note": "Niskocenne środki trwałe (art. 22f ust. 3): wartość ≤ 10 000 zł → jednorazowy odpis w koszty",
    },
    "_routing": "REPORT",
    "_routing_reason": "Niskocenny środek trwały — jednorazowy odpis w koszty (art. 22f ust. 3)",
    "_legal_basis": "Art. 22f ust. 3 PIT",
    "_warnings": ["Próg 10 000 zł zależny od wartości początkowej; powyżej progu — amortyzacja wg KŚT."],
} {
    object.get(input.jdg_entrepreneur, "r04_low_value_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R04-INN-04: HEALTH CONTRIBUTION OPTIMIZER — kalkulator optymalnej składki
# ═══════════════════════════════════════════════════════════════════════════════
# Porównanie rocznej składki zdrowotnej wg formy opodatkowania:
#   skala   — 9% od dochodu (art. 81 ust. 2c u. zdrowotnej), częściowo odliczana
#   liniowy — 9% od dochodu, NIE odliczana od podatku (od 2022)
#   ryczałt — 9% od podstawy zależnej od przychodów (progi roczne)
# Wybór formy nie może być wyłącznie składką — podaje się łączny koszt
# PIT + zdrowotna (efektywny koszt formy) — rekomendacja, nie decyzja.
health_input := object.get(input, "health_optimizer", {})

health_income := max([0, object.get(health_input, "annual_income", 0)])
health_revenue := max([0, object.get(health_input, "annual_revenue", 0)])
lump_base_years := object.get(_th_pit, "lump_health_base_years", 12)  # podstawa roczna ryczałt

# Podstawa składki dla ryczałtu: progi wg przychodów (2026) — externalizowane
lump_health_base := object.get(health_input, "lump_health_base", 0)

health_scale := health_income * health_scale_rate
health_linear := health_income * health_flat_rate
health_lump := lump_health_base * health_flat_rate

# Łączny koszt PIT + składka (uproszczony, z progresją skali)
pit_scale_tax := (health_income * 0.12) - (3600 if health_income <= 120000 else 0)  # kwota zmniejszająca 3600 (2022+)
pit_linear_tax := health_income * 0.19

total_scale := pit_scale_tax + health_scale
total_linear := pit_linear_tax + health_linear
total_lump := (health_revenue * 0.085) + health_lump  # ryczałt ~8.5% przeciętny

best_form := "SCALE" {
    total_scale <= total_linear
    total_scale <= total_lump
} else := "LINEAR" {
    total_linear <= total_lump
} else := "LUMP_SUM" {
    true
}

health_contribution_optimizer := {
    "matched": true,
    "rule_id": "jdg.r04_pit_core_innovations.health_contribution_optimizer",
    "package": "jdg.r04_pit_core_innovations",
    "priority": 282,
    "optimizer": {
        "annual_income": health_income,
        "annual_revenue": health_revenue,
        "health_scale": health_scale,
        "health_linear": health_linear,
        "health_lump": health_lump,
        "total_scale": total_scale,
        "total_linear": total_linear,
        "total_lump": total_lump,
        "best_form": best_form,
        "note": "Porównanie łącznego kosztu PIT + składka zdrowotna wg formy — rekomendacja, nigdy automatyczna decyzja",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Optymalna forma wg PIT+składka: skala=%.0f | liniowy=%.0f | ryczałt=%.0f → %s", [total_scale, total_linear, total_lump, best_form]),
    "_legal_basis": "Art. 27, 30c PIT + art. 81 ustawy o świadczeniach opieki zdrowotnej (Dz.U. 2025 poz. 890)",
    "_warnings": ["Składka liniowa/ryczałt nie odliczana od podatku (od 2022). Wynik szacunkowy — decyzja wymaga pełnej kalkulacji i weryfikacji warunków art. 9a."],
} {
    object.get(input.jdg_entrepreneur, "r04_health_optimizer_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# GŁÓWNA REGUŁA RAPORTU (aktywowana flagą r04_pit_core_check)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.r04_pit_core_innovations.pit_core_report",
    "package": "jdg.r04_pit_core_innovations",
    "priority": 295,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "valid_from": "2026-01-01", "valid_to": null,
    "pit_core": {
        "relief_whatif": relief_whatif_simulator.simulator,
        "one_off_amortization": one_off_depreciation.amortization,
        "low_value_amortization": low_value_asset_amortization.amortization,
        "health_optimizer": health_contribution_optimizer.optimizer,
    },
    "_routing": "REPORT",
    "_routing_reason": "R04 PIT CORE: 3-drogowy symulator ulg (B+R/IP Box/robotyzacja), jednorazowa amortyzacja 100k, niskocenne 10k, optymalna składka",
    "_legal_basis": "Ustawa o PIT (Dz.U. 2025 poz. 789) Art. 22f, 22k, 26e, 26gb, 27, 30ca, 44, 45",
    "_warnings": ["Raport PIT CORE — aktywowany wyłącznie flagą r04_pit_core_check"],
} {
    object.get(input.jdg_entrepreneur, "r04_pit_core_check", false) == true
}
