# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R14 GLM52 RODO / AML-CBDD / BDO / ŚRODOWISKO — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r14_rodo_aml_bdo_innovations
# Raport: RAPORT_14_RODO_AML_BDO.txt (Kampania GLM 5.2 — seria 14/25)
#
# Prompt 14/25 (RODO / AML-CBDD / BDO / środowisko / sekurytyzacja):
#   R14-INN-01 rodo_register_monitor — automatyczny rejestr czynności (art. 30
#                                     RODO): mapa przetwarzania + fail-closed
#                                     przy brakach (p16 rodo_register_automation
#                                     generował bez alertów kompletności)
#   R14-INN-02 aml_transaction_risk_scorer — scoring transakcji AML (art. 34:
#                                     >15 000 EUR) z czynn. ryzyka (gotówka,
#                                     kraj wysokiego ryzyka) (p16 liczył próg
#                                     bez scoringu)
#   R14-INN-03 rodo_sanction_calculator — kalkulator sankcji RODO (art. 83:
#                                     10M/2% vs 20M/4%) wg severity (p16 miał
#                                     statyczny kalkulator)
#   R14-INN-04 str_gijf_deadline_monitor — monitor STR do GIIF (art. 74-80):
#                                     1 dzień roboczy, checklista, alerty (p16
#                                     str_gijf_auto_submission bez monitora
#                                     terminu)
#   R14-INN-05 bdo_obligation_monitor — monitor obowiązków BDO (art. 49-53):
#                                     rejestracja, ewidencja, KPO, terminy
#                                     z alertami (p15 bdo_deadline_tracker
#                                     dawał listę bez alarmów)
#
# Zgodność: ADR-001..009/017/022, RODO (art. 17/28/30/33/83), ustawa AML
#           (art. 34/72/74-80/153), UoO (art. 49-53); thresholds.rodo_aml_bdo
#           (zero hardcode); INV-018; First-Match-Wins.
# package: jdg.r14_rodo_aml_bdo_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r14_rodo_aml_bdo_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r14_rodo_aml_bdo_innovations.no_match", "package": "jdg.r14_rodo_aml_bdo_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_rab := object.get(_th, "rodo_aml_bdo", {})

rodo_sanction_min_eur := object.get(_th_rab, "rodo_sanction_min_eur", 10000000)  # art. 83 ust. 4
rodo_sanction_max_eur := object.get(_th_rab, "rodo_sanction_max_eur", 20000000)  # art. 83 ust. 5
rodo_breach_deadline_hours := object.get(_th_rab, "rodo_breach_deadline_hours", 72)  # art. 33
rodo_erasure_deadline_days := object.get(_th_rab, "rodo_erasure_deadline_days", 30)  # art. 17
aml_threshold_eur := object.get(_th_rab, "aml_threshold_eur", 15000)        # art. 34
aml_str_deadline_days := object.get(_th_rab, "aml_str_deadline_days", 1)    # art. 74-80
aml_sanction_max_pln := object.get(_th_rab, "aml_sanction_max_pln", 1000000)  # art. 153
bdo_registration_days := object.get(_th_rab, "bdo_registration_days", 30)   # art. 49-53
bdo_kpo_electronic := object.get(_th_rab, "bdo_kpo_electronic", true)
bdo_fee_micro_pln := object.get(_th_rab, "bdo_fee_micro_pln", 100)

# ── Helper: 3 poziomy alertów ─────────────────────────────────────────────────
alert_level(days) := "RED" if {
    days <= 3
} else := "AMBER" if {
    days <= 7
} else := "GREEN" if {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R14-INN-01: RODO REGISTER MONITOR — automatyczny rejestr czynności (art. 30
#             RODO): mapa przetwarzania + fail-closed przy brakach
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza rodo_register: {data_categories[], purposes[], recipients[],
# complete}.
rg_input := object.get(input, "rodo_register", {})
rg_categories := object.get(rg_input, "data_categories", [])
rg_purposes := object.get(rg_input, "purposes", [])
rg_recipients := object.get(rg_input, "recipients", [])
rg_complete := object.get(rg_input, "complete", false)

rg_cat_count := count(rg_categories)
rg_purp_count := count(rg_purposes)
rg_recip_count := count(rg_recipients)
rg_incomplete := rg_cat_count == 0 or rg_purp_count == 0 or rg_recip_count == 0 or not rg_complete

rg_routing := "TRIAGE_QUEUE" if {
    rg_incomplete
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r14_rodo_aml_bdo_innovations.rodo_register_monitor",
    "_legal_basis": "RODO art. 30 (rejestr czynności przetwarzania), art. 5 (zasady)",
    "package": "jdg.r14_rodo_aml_bdo_innovations",
    "priority": 11031,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "rg_data_categories_count": rg_cat_count,
    "rg_purposes_count": rg_purp_count,
    "rg_recipients_count": rg_recip_count,
    "rg_complete": rg_complete,
    "rg_incomplete": rg_incomplete,
    "_routing": rg_routing,
    "_routing_reason": sprintf("Rejestr czynności — kategorie %d, cele %d, odbiorcy %d, kompletny=%s. %s", [rg_cat_count, rg_purp_count, rg_recip_count, rg_complete, "BRAKI — uzupełnij rejestr (art. 30)." if {rg_incomplete} else "Rejestr kompletny."]),
    "_legal_basis": "RODO art. 30 (rejestr czynności przetwarzania), art. 5 (zasady)",
    "_warnings": [sprintf("RODO rejestr: %s", ["niekompletny — uzupełnij kategorie/cele/odbiorców." if {rg_incomplete} else "kompletny."])],
} if {
    object.get(input.jdg_entrepreneur, "r14_rodo_aml_bdo_check", false) == true
    object.get(input, "rodo_register", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R14-INN-02: AML TRANSACTION RISK SCORER — scoring transakcji AML (art. 34:
#             >15 000 EUR) z czynnikami ryzyka
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza aml_transaction: {amount_eur, cash, high_risk_country}.
at_input := object.get(input, "aml_transaction", {})
at_amount := max([0, object.get(at_input, "amount_eur", 0)])
at_cash := object.get(at_input, "cash", false)
at_hrc := object.get(at_input, "high_risk_country", false)

at_over_threshold := at_amount > aml_threshold_eur
at_risk_score := (1 if {at_cash} else 0) + (1 if {at_hrc} else 0) + (1 if {at_over_threshold} else 0)
at_high_risk := at_risk_score >= 2

at_routing := "BLOCK_AND_ALERT" if {
    at_high_risk
} else := "TRIAGE_QUEUE" if {
    at_over_threshold
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r14_rodo_aml_bdo_innovations.aml_transaction_risk_scorer",
    "_legal_basis": "RODO art. 30 (rejestr czynności przetwarzania), art. 5 (zasady)",
    "package": "jdg.r14_rodo_aml_bdo_innovations",
    "priority": 11032,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "at_amount_eur": at_amount,
    "at_cash": at_cash,
    "at_high_risk_country": at_hrc,
    "at_over_threshold": at_over_threshold,
    "at_risk_score": at_risk_score,
    "at_high_risk": at_high_risk,
    "at_threshold_eur": aml_threshold_eur,
    "_routing": at_routing,
    "_routing_reason": sprintf("Scoring AML — transakcja %.2f EUR (próg %d), gotówka=%s, kraj HR=%s. Ryzyko %d/3. %s", [at_amount, aml_threshold_eur, at_cash, at_hrc, at_risk_score, "WYSOKIE — weryfikacja wzmożona (CDD)." if {at_high_risk} else "Średnie — monitoruj." if {at_over_threshold} else "Niskie."]),
    "_legal_basis": "ustawa AML art. 34 (transakcje > 15 000 EUR), art. 72 (próg gotówkowy), art. 74-80 (STR)",
    "_warnings": [sprintf("AML: transakcja %.2f EUR — ryzyko %d/3. %s", [at_amount, at_risk_score, "WZMOCNIONA CDD." if {at_high_risk} else "OK."])],
} if {
    object.get(input.jdg_entrepreneur, "r14_rodo_aml_bdo_check", false) == true
    object.get(input, "aml_transaction", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R14-INN-03: RODO SANCTION CALCULATOR — kalkulator sankcji RODO (art. 83:
#             10M/2% vs 20M/4%) wg severity
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza rodo_breach: {severity, intentional, duration_months}.
rb_input := object.get(input, "rodo_breach", {})
rb_severity := object.get(rb_input, "severity", "MINOR")
rb_intentional := object.get(rb_input, "intentional", false)
rb_duration := max([0, object.get(rb_input, "duration_months", 0)])

rb_upper_tier := rb_severity == "CRITICAL" or rb_intentional or rb_duration >= 12
rb_max_eur := rodo_sanction_max_eur if {
    rb_upper_tier
} else := rodo_sanction_min_eur if {
    true
}

rb_routing := "TRIAGE_QUEUE" if {
    rb_upper_tier
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r14_rodo_aml_bdo_innovations.rodo_sanction_calculator",
    "_legal_basis": "RODO art. 30 (rejestr czynności przetwarzania), art. 5 (zasady)",
    "package": "jdg.r14_rodo_aml_bdo_innovations",
    "priority": 11033,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "rb_severity": rb_severity,
    "rb_intentional": rb_intentional,
    "rb_duration_months": rb_duration,
    "rb_upper_tier": rb_upper_tier,
    "rb_max_sanction_eur": rb_max_eur,
    "rb_tier_min_eur": rodo_sanction_min_eur,
    "rb_tier_max_eur": rodo_sanction_max_eur,
    "_routing": rb_routing,
    "_routing_reason": sprintf("Sankcje RODO — severity %s, umyślne=%s, trwanie %d mies. %s", [rb_severity, rb_intentional, rb_duration, "GÓRNY PRZEDZIAŁ (20 mln EUR / 4%%)." if {rb_upper_tier} else "DOLNY PRZEDZIAŁ (10 mln EUR / 2%%)."]),
    "_legal_basis": "RODO art. 83 ust. 4-5 (sankcje 10 mln/2% i 20 mln/4%)",
    "_warnings": [sprintf("RODO: maks. sankcja %d EUR — %s", [rb_max_eur, "górny przedział (art. 83 ust. 5)." if {rb_upper_tier} else "dolny przedział (art. 83 ust. 4)."])],
} if {
    object.get(input.jdg_entrepreneur, "r14_rodo_aml_bdo_check", false) == true
    object.get(input, "rodo_breach", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R14-INN-04: STR GIJF DEADLINE MONITOR — monitor STR do GIIF (art. 74-80):
#             1 dzień roboczy, checklista, alerty
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza str_monitor: {items: [{label, days_left, filed}]}.
sm_input := object.get(input, "str_monitor", {})
sm_items_in := object.get(sm_input, "items", [])

sm_item(i) := {
    "label": object.get(i, "label", "STR"),
    "days_left": object.get(i, "days_left", aml_str_deadline_days),
    "filed": object.get(i, "filed", false),
    "level": alert_level(object.get(i, "days_left", aml_str_deadline_days)),
    "next_action": "Złóż STR do GIIF NATYCHMIAST (art. 74 — 1 dzień roboczy)." if {not object.get(i, "filed", false)} else "STR złożone.",
}

sm_items := [sm_item(i) | i := sm_items_in[_]]
sm_red_count := count([x | x := sm_items[_]; x.level == "RED"])
sm_amber_count := count([x | x := sm_items[_]; x.level == "AMBER"])
sm_unfiled_count := count([x | x := sm_items[_]; not x.filed])

sm_routing := "BLOCK_AND_ALERT" if {
    sm_red_count > 0
} else := "TRIAGE_QUEUE" if {
    sm_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r14_rodo_aml_bdo_innovations.str_gijf_deadline_monitor",
    "package": "jdg.r14_rodo_aml_bdo_innovations",
    "priority": 11034,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "sm_items_total": count(sm_items),
    "sm_red_count": sm_red_count,
    "sm_amber_count": sm_amber_count,
    "sm_unfiled_count": sm_unfiled_count,
    "sm_str_deadline_days": aml_str_deadline_days,
    "sm_items": sm_items,
    "_routing": sm_routing,
    "_routing_reason": sprintf("Monitor STR — %d zgłoszeń (RED: %d, AMBER: %d, niezłożone: %d). Termin %d dzień roboczy (art. 74-80).", [count(sm_items), sm_red_count, sm_amber_count, sm_unfiled_count, aml_str_deadline_days]),
    "_legal_basis": "ustawa AML art. 74-80 (STR do GIIF, 1 dzień roboczy), art. 153 (sankcje)",
    "_warnings": [sprintf("STR/GIIF: %d zgłoszeń — %d RED, %d AMBER, %d niezłożonych.", [count(sm_items), sm_red_count, sm_amber_count, sm_unfiled_count])],
} if {
    object.get(input.jdg_entrepreneur, "r14_rodo_aml_bdo_check", false) == true
    object.get(input, "str_monitor", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R14-INN-05: BDO OBLIGATION MONITOR — monitor obowiązków BDO (art. 49-53):
#             rejestracja, ewidencja, KPO, terminy z alertami
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza bdo_monitor: {items: [{label, days_left, filed}]}.
bd_input := object.get(input, "bdo_monitor", {})
bd_items_in := object.get(bd_input, "items", [])

bd_item(i) := {
    "label": object.get(i, "label", "BDO"),
    "days_left": object.get(i, "days_left", bdo_registration_days),
    "filed": object.get(i, "filed", false),
    "level": alert_level(object.get(i, "days_left", bdo_registration_days)),
    "next_action": "Dokonaj obowiązku BDO (rejestracja/ewidencja/KPO — art. 49-53)." if {not object.get(i, "filed", false)} else "Obowiązek spełniony.",
}

bd_items := [bd_item(i) | i := bd_items_in[_]]
bd_red_count := count([x | x := bd_items[_]; x.level == "RED"])
bd_amber_count := count([x | x := bd_items[_]; x.level == "AMBER"])
bd_unfiled_count := count([x | x := bd_items[_]; not x.filed])

bd_routing := "BLOCK_AND_ALERT" if {
    bd_red_count > 0
} else := "TRIAGE_QUEUE" if {
    bd_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r14_rodo_aml_bdo_innovations.bdo_obligation_monitor",
    "package": "jdg.r14_rodo_aml_bdo_innovations",
    "priority": 11035,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "bd_items_total": count(bd_items),
    "bd_red_count": bd_red_count,
    "bd_amber_count": bd_amber_count,
    "bd_unfiled_count": bd_unfiled_count,
    "bd_registration_days": bdo_registration_days,
    "bd_kpo_electronic": bdo_kpo_electronic,
    "bd_fee_micro_pln": bdo_fee_micro_pln,
    "bd_items": bd_items,
    "_routing": bd_routing,
    "_routing_reason": sprintf("Monitor BDO — %d obowiązków (RED: %d, AMBER: %d, niespełnione: %d). Rejestracja %d dni; KPO elektroniczna=%s.", [count(bd_items), bd_red_count, bd_amber_count, bd_unfiled_count, bdo_registration_days, bdo_kpo_electronic]),
    "_legal_basis": "Ustawa o odpadach art. 49-53 (rejestracja BDO, ewidencja, KPO, opłata produktowa)",
    "_warnings": [sprintf("BDO: %d obowiązków — %d RED, %d AMBER, %d niespełnionych.", [count(bd_items), bd_red_count, bd_amber_count, bd_unfiled_count])],
} if {
    object.get(input.jdg_entrepreneur, "r14_rodo_aml_bdo_check", false) == true
    object.get(input, "bdo_monitor", {}) != {}
}
