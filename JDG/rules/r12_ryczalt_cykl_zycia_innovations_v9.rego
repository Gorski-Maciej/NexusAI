# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R12 GLM52 RYCZAŁT / CEIDG / CYKL ŻYCIA — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r12_ryczalt_cykl_zycia_innovations
# Raport: RAPORT_12_RYCZALT_CYKL_ZYCIE.txt (Kampania GLM 5.2 — seria 12/25)
#
# Prompt 12/25 (ryczałt / CEIDG / prawo przedsiębiorców / sukcesja /
# budownictwo / cykl życia firmy):
#   R12-INN-01 ryczalt_limit_monitor — monitor limitu 2 mln EUR (art. 6)
#                                     ryczałtu z 3 poziomami alertów + projekcja
#                                     forward (p13 ryczalt_limit_tracker liczył
#                                     % bez alarmów)
#   R12-INN-02 pkwiu_rate_classifier — klasyfikator PKWiU → stawka ryczałtu
#                                     3%-25% (art. 12 ust. 1) z walidacją
#                                     deklarowanej stawki (p13 miał kalkulator
#                                     pojedynczy bez walidacji)
#   R12-INN-03 lifecycle_phase_planner — planner faz cyklu życia JDG z
#                                     kalendarzem obowiązków per faza + alert
#                                     pominiętych kroków (p13 lifecycle_assistant
#                                     dawał opis bez kalendarza)
#   R12-INN-04 succession_deadline_monitor — monitor terminów sukcesji (wpis
#                                     CEIDG 14 dni, 2 lata + do 5 lat,
#                                     art. 3-15 u.z.s.) z alertami (p13
#                                     succession_tracker dawał listę kroków)
#   R12-INN-05 tax_form_arbitrator — arbiter formy opodatkowania (ryczałt vs
#                                     skala vs liniowy) + zawieszenie vs
#                                     zamknięcie (art. 22-25 PP)
#
# Zgodność: ADR-001..009/017/022, ustawa o ryczałcie (art. 6, 12, 21-28),
#           Prawo przedsiębiorców (art. 5-6, 18, 22-25), ustawa o zarządzie
#           sukcesyjnym (art. 3-15), CEIDG (art. 5-15); thresholds.
#           business_lifecycle (zero hardcode); INV-018; First-Match-Wins.
# package: jdg.r12_ryczalt_cykl_zycia_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r12_ryczalt_cykl_zycia_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r12_ryczalt_cykl_zycia_innovations.no_match", "package": "jdg.r12_ryczalt_cykl_zycia_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_bl := object.get(_th, "business_lifecycle", {})

ryczalt_limit_eur := object.get(_th_bl, "ryczalt_limit_eur", 2000000)   # art. 6
eur_pln_reference := object.get(_th_bl, "eur_pln_reference", 4.3)
ryczalt_warning_pct := object.get(_th_bl, "ryczalt_warning_pct", 75)
ryczalt_rate_min := object.get(_th_bl, "ryczalt_rate_min", 0.03)
ryczalt_rate_max := object.get(_th_bl, "ryczalt_rate_max", 0.25)
karta_max_employees := object.get(_th_bl, "karta_max_employees", 5)
ceidg_registration_days := object.get(_th_bl, "ceidg_registration_days", 7)
succession_ceidg_days := object.get(_th_bl, "succession_ceidg_days", 14)
succession_default_months := object.get(_th_bl, "succession_default_months", 24)
succession_extended_months := object.get(_th_bl, "succession_extended_months", 60)
unregistered_min_wage_pct := object.get(_th_bl, "unregistered_min_wage_pct", 0.5)
min_wage_pln := object.get(_th_bl, "min_wage_pln", 4800.0)
suspension_max_months := object.get(_th_bl, "suspension_max_months", 24)
lifecycle_ulga_start_months := object.get(_th_bl, "lifecycle_ulga_start_months", 6)
lifecycle_pref_zus_months := object.get(_th_bl, "lifecycle_pref_zus_months", 24)
lifecycle_vat_threshold_pln := object.get(_th_bl, "lifecycle_vat_threshold_pln", 200000)

# ── Helper: zaokrąglenie 2 miejsca ────────────────────────────────────────────
round2(x) := floor((x * 100) + 0.5) / 100

# ── Helper: 3 poziomy alertów (spójne z R08/R11) ──────────────────────────────
alert_level(pct) := "RED" if {
    pct >= 100
} else := "AMBER" if {
    pct >= ryczalt_warning_pct
} else := "GREEN" if {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R12-INN-01: RYCZAŁT LIMIT MONITOR — monitor limitu 2 mln EUR (art. 6)
#             z 3 poziomami alertów + projekcja forward
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza ryczalt_limit: {ytd_revenue_pln, projected_annual_pln}.
rl_input := object.get(input, "ryczalt_limit", {})
rl_ytd_pln := max([0, object.get(rl_input, "ytd_revenue_pln", 0)])
rl_projected_pln := max([0, object.get(rl_input, "projected_annual_pln", rl_ytd_pln)])

rl_ytd_eur := round2(rl_ytd_pln / eur_pln_reference)
rl_projected_eur := round2(rl_projected_pln / eur_pln_reference)
rl_pct := round2(rl_projected_eur / ryczalt_limit_eur * 100)
rl_projected_pct := round2(rl_projected_eur / ryczalt_limit_eur * 100)
rl_level := alert_level(rl_projected_pct)

rl_routing := "BLOCK_AND_ALERT" if {
    rl_level == "RED"
} else := "TRIAGE_QUEUE" if {
    rl_level == "AMBER"
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r12_ryczalt_cykl_zycia_innovations.ryczalt_limit_monitor",
    "package": "jdg.r12_ryczalt_cykl_zycia_innovations",
    "priority": 11021,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "rl_ytd_revenue_pln": rl_ytd_pln,
    "rl_ytd_revenue_eur": rl_ytd_eur,
    "rl_projected_annual_eur": rl_projected_eur,
    "rl_limit_eur": ryczalt_limit_eur,
    "rl_limit_pct": rl_projected_pct,
    "rl_warning_pct": ryczalt_warning_pct,
    "rl_alert_level": rl_level,
    "_routing": rl_routing,
    "_routing_reason": sprintf("Monitor limitu ryczałtu — YTD %.2f EUR, projekcja %.2f EUR = %.2f%% limitu (próg ostrzeżenia %d%%). Poziom: %s.", [rl_ytd_eur, rl_projected_eur, rl_projected_pct, ryczalt_warning_pct, rl_level]),
    "_legal_basis": "ustawa o ryczałcie art. 6 ust. 1 (limit 2 mln EUR), art. 6 ust. 4 (utrata ryczałtu)",
    "_warnings": [sprintf("RYCZAŁT: %.2f%% limitu 2 mln EUR (projekcja %.2f EUR). %s", [rl_projected_pct, rl_projected_eur, "UTRATA RYCZAŁTU — przekroczony limit (art. 6 ust. 4)." if {rl_level == "RED"} else "Ostrzeżenie — blisko limitu." if {rl_level == "AMBER"} else "W normie."])],
} if {
    object.get(input.jdg_entrepreneur, "r12_ryczalt_cykl_zycia_check", false) == true
    object.get(input, "ryczalt_limit", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R12-INN-02: PKWIU RATE CLASSIFIER — klasyfikator PKWiU → stawka ryczałtu
#             3%-25% (art. 12 ust. 1) z walidacją deklarowanej stawki
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza pkwiu_rate: {pkwiu_code, declared_rate, activity_desc}.
# Kategorie stawki wg PKWiU (uproszczona mapa — art. 12 ust. 1):
#   LOW (3%)   — handel detaliczny, gastronomia
#   MID (8.5%) — usługi budowlane, transport
#   HIGH (17%) — usługi IT, doradztwo
pk_input := object.get(input, "pkwiu_rate", {})
pk_code := object.get(pk_input, "pkwiu_code", "")
pk_declared := object.get(pk_input, "declared_rate", 0)
pk_desc := object.get(pk_input, "activity_desc", "")

pk_expected := ryczalt_rate_max if {
    contains(pk_desc, "IT")
} else := ryczalt_rate_max if {
    contains(pk_desc, "doradztwo")
} else := 0.085 if {
    contains(pk_desc, "budowl")
} else := 0.085 if {
    contains(pk_desc, "transport")
} else := ryczalt_rate_min if {
    true
}

pk_mismatch := pk_declared != 0 and pk_declared != pk_expected

pk_routing := "TRIAGE_QUEUE" if {
    pk_mismatch
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r12_ryczalt_cykl_zycia_innovations.pkwiu_rate_classifier",
    "_legal_basis": "ustawa o ryczałcie art. 6 ust. 1 (limit 2 mln EUR), art. 6 ust. 4 (utrata ryczałtu)",
    "package": "jdg.r12_ryczalt_cykl_zycia_innovations",
    "priority": 11022,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "pk_pkwiu_code": pk_code,
    "pk_activity_desc": pk_desc,
    "pk_declared_rate": pk_declared,
    "pk_expected_rate": pk_expected,
    "pk_rate_mismatch": pk_mismatch,
    "pk_rate_min": ryczalt_rate_min,
    "pk_rate_max": ryczalt_rate_max,
    "_routing": pk_routing,
    "_routing_reason": sprintf("Klasyfikator PKWiU — '%s' → oczekiwana stawka %.4f, deklarowana %.4f. %s", [pk_desc, pk_expected, pk_declared, "Niezgodność stawki — TRIAGE." if {pk_mismatch} else "Stawka zgodna."]),
    "_legal_basis": "ustawa o ryczałcie art. 12 ust. 1 (stawki wg PKWiU 3%-25%), art. 4 (przedmiot)",
    "_warnings": [sprintf("PKWiU: '%s' — stawka %.2f%% (oczekiwana %.2f%%). %s", [pk_desc, pk_declared * 100, pk_expected * 100, "NIEGODNOŚĆ — zweryfikuj stawkę." if {pk_mismatch} else "OK."])],
} if {
    object.get(input.jdg_entrepreneur, "r12_ryczalt_cykl_zycia_check", false) == true
    object.get(input, "pkwiu_rate", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R12-INN-03: LIFECYCLE PHASE PLANNER — planner faz cyklu życia JDG z
#             kalendarzem obowiązków per faza + alert pominiętych kroków
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza lifecycle: {months_operating, vat_registered, done_steps[]}.
lc_input := object.get(input, "lifecycle", {})
lc_months := max([0, object.get(lc_input, "months_operating", 0)])
lc_vat := object.get(lc_input, "vat_registered", false)
lc_done := object.get(lc_input, "done_steps", [])

lc_phase := "REJESTRACJA_CEIDG" if {
    lc_months < 1
} else := "ULGA_NA_START" if {
    lc_months <= lifecycle_ulga_start_months
} else := "PREFERENCYJNY_ZUS" if {
    lc_months <= lifecycle_ulga_start_months + lifecycle_pref_zus_months
} else := "WZROST" if {
    not lc_vat
} else := "DOJRZALOSC" if {
    true
}

lc_required := ["wpis_ceidg", "vat_r_optional", "zus_zgłoszenie", "ksiegowosc_wybrana"]
lc_missing := [s | s := lc_required[_]; not (s in lc_done)]

lc_routing := "TRIAGE_QUEUE" if {
    count(lc_missing) > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r12_ryczalt_cykl_zycia_innovations.lifecycle_phase_planner",
    "package": "jdg.r12_ryczalt_cykl_zycia_innovations",
    "priority": 11023,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "lc_months_operating": lc_months,
    "lc_phase": lc_phase,
    "lc_vat_registered": lc_vat,
    "lc_missing_steps": lc_missing,
    "lc_required_steps": lc_required,
    "lc_vat_threshold_pln": lifecycle_vat_threshold_pln,
    "_routing": lc_routing,
    "_routing_reason": sprintf("Planner cyklu życia — faza %s (miesiąc %d). Pominięte kroki: %d.", [lc_phase, lc_months, count(lc_missing)]),
    "_legal_basis": "Prawo przedsiębiorców art. 5-15 (CEIDG), ustawa o ryczałcie art. 21-28, ustawa o ZUS (ulga na start), ustawa o VAT art. 113 (próg 200k)",
    "_warnings": [sprintf("CYKL ŻYCIA: faza %s — %s", [lc_phase, sprintf("pominięte: %v.", [lc_missing]) if {count(lc_missing) > 0} else "wszystkie kroki wykonane."])],
} if {
    object.get(input.jdg_entrepreneur, "r12_ryczalt_cykl_zycia_check", false) == true
    object.get(input, "lifecycle", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R12-INN-04: SUCCESSION DEADLINE MONITOR — monitor terminów sukcesji
#             (wpis CEIDG 14 dni, 2 lata + do 5 lat, art. 3-15 u.z.s.)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza succession_monitor: {items: [{label, days_left, filed}]}.
sc_input := object.get(input, "succession_monitor", {})
sc_items_in := object.get(sc_input, "items", [])

sc_level(days) := "RED" if {
    days <= 3
} else := "AMBER" if {
    days <= 7
} else := "GREEN" if {
    true
}

sc_item(i) := {
    "label": object.get(i, "label", "Sukcesja"),
    "days_left": object.get(i, "days_left", succession_ceidg_days),
    "filed": object.get(i, "filed", false),
    "level": sc_level(object.get(i, "days_left", succession_ceidg_days)),
    "next_action": "Dokonaj wpisu zarządcy sukcesyjnego do CEIDG (14 dni) — art. 3-15 u.z.s." if {not object.get(i, "filed", false)} else "Termin dotrzymany.",
}

sc_items := [sc_item(i) | i := sc_items_in[_]]
sc_red_count := count([x | x := sc_items[_]; x.level == "RED"])
sc_amber_count := count([x | x := sc_items[_]; x.level == "AMBER"])
sc_unfiled_count := count([x | x := sc_items[_]; not x.filed])

sc_routing := "BLOCK_AND_ALERT" if {
    sc_red_count > 0
} else := "TRIAGE_QUEUE" if {
    sc_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r12_ryczalt_cykl_zycia_innovations.succession_deadline_monitor",
    "package": "jdg.r12_ryczalt_cykl_zycia_innovations",
    "priority": 11024,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "sc_items_total": count(sc_items),
    "sc_red_count": sc_red_count,
    "sc_amber_count": sc_amber_count,
    "sc_unfiled_count": sc_unfiled_count,
    "sc_ceidg_days": succession_ceidg_days,
    "sc_default_months": succession_default_months,
    "sc_extended_months": succession_extended_months,
    "sc_items": sc_items,
    "_routing": sc_routing,
    "_routing_reason": sprintf("Monitor sukcesji — %d pozycji (RED: %d, AMBER: %d, niezłożone: %d). Wpis CEIDG %d dni; okres %d mies. (+ do %d).", [count(sc_items), sc_red_count, sc_amber_count, sc_unfiled_count, succession_ceidg_days, succession_default_months, succession_extended_months]),
    "_legal_basis": "ustawa o zarządzie sukcesyjnym art. 3-15 (zarządca, wpis CEIDG 14 dni, 2 lata + do 5 lat)",
    "_warnings": [sprintf("SUKCESJA: %d terminów — %d RED (≤3 dni), %d AMBER (≤7 dni), %d niezłożonych.", [count(sc_items), sc_red_count, sc_amber_count, sc_unfiled_count])],
} if {
    object.get(input.jdg_entrepreneur, "r12_ryczalt_cykl_zycia_check", false) == true
    object.get(input, "succession_monitor", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R12-INN-05: TAX FORM ARBITRATOR — arbiter formy opodatkowania (ryczałt vs
#             skala vs liniowy) + zawieszenie vs zamknięcie (art. 22-25 PP)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza tax_form: {annual_revenue, annual_costs, employees,
# suspended_months}.
tf_input := object.get(input, "tax_form", {})
tf_revenue := max([0, object.get(tf_input, "annual_revenue", 0)])
tf_costs := max([0, object.get(tf_input, "annual_costs", 0)])
tf_employees := max([0, object.get(tf_input, "employees", 0)])
tf_suspended := max([0, object.get(tf_input, "suspended_months", 0)])

tf_profit := tf_revenue - tf_costs
tf_cost_ratio := tf_costs / tf_revenue if {
    tf_revenue > 0
} else := 0 if {
    true
}

tf_recommended := "RYCZALT" if {
    tf_cost_ratio < 0.3
    tf_employees <= karta_max_employees
} else := "LINIOWY" if {
    tf_profit > 120000
} else := "SKALA" if {
    true
}

tf_suspend_recommend := "ZAWIES_20" if {
    tf_profit <= 0
} else := "KONTYNUUJ" if {
    true
}

tf_routing := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r12_ryczalt_cykl_zycia_innovations.tax_form_arbitrator",
    "package": "jdg.r12_ryczalt_cykl_zycia_innovations",
    "priority": 11025,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "tf_annual_revenue": tf_revenue,
    "tf_annual_costs": tf_costs,
    "tf_profit": tf_profit,
    "tf_cost_ratio": tf_cost_ratio,
    "tf_employees": tf_employees,
    "tf_recommended_form": tf_recommended,
    "tf_suspension_recommend": tf_suspend_recommend,
    "tf_suspension_max_months": suspension_max_months,
    "_routing": tf_routing,
    "_routing_reason": sprintf("Arbiter formy — przychód %.2f, koszty %.2f (%.2f%%), zysk %.2f. Rekomendacja: %s. %s", [tf_revenue, tf_costs, tf_cost_ratio * 100, tf_profit, tf_recommended, tf_suspend_recommend]),
    "_legal_basis": "ustawa o ryczałcie art. 6 (limit), art. 12 (stawki), PIT (skala/liniowy), Prawo przedsiębiorców art. 22-25 (zawieszenie)",
    "_warnings": [sprintf("FORMA: %s — %s", [tf_recommended, "rozważ zawieszenie (strata)." if {tf_suspend_recommend == "ZAWIES_20"} else "kontynuuj działalność."])],
} if {
    object.get(input.jdg_entrepreneur, "r12_ryczalt_cykl_zycia_check", false) == true
    object.get(input, "tax_form", {}) != {}
}
