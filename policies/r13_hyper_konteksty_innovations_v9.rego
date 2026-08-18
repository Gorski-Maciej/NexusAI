# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R13 GLM52 HYPER PLAN45 / KONTEKSTY SPECJALNE — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r13_hyper_konteksty_innovations
# Raport: RAPORT_13_HYPER_CYKL_FIRMY.txt (Kampania GLM 5.2 — seria 13/25)
#
# Prompt 13/25 (hyper Plan45 / reprezentacja / działalność regulowana /
# konteksty specjalne):
#   R13-INN-01 cross_domain_conflict_detector — detektor konfliktów
#                                     międzydomenowych (IP Box vs B+R,
#                                     art. 30ca PIT) POST-MERGE (p17
#                                     conflict_matrix był ad hoc)
#   R13-INN-02 solidarity_tax_monitor — monitor daniny solidarnościowej
#                                     (art. 30h PIT): próg 1 mln PLN, 4% od
#                                     nadwyżki, alert (p17/hyper.solidarity
#                                     liczył threshold bez alarmów)
#   R13-INN-03 prokura_deadline_monitor — monitor wpisu prokury (art.
#                                     109¹-109⁸ KC): 7 dni, typy samoistna/
#                                     łączna, alerty (representation miał
#                                     statyczny wpis)
#   R13-INN-04 annual_deadline_calendar — inteligentny kalendarz terminów
#                                     rocznych (art. 45 PIT — 30 kwietnia)
#                                     z przesunięciem weekend/święto
#                                     (calendar/plan45 dawał daty statyczne)
#   R13-INN-05 qualified_signature_selector — selektor podpisu kwalifikowanego
#                                     (eIDAS art. 25-26, art. 126 § 5 OP):
#                                     które dokumenty wymagają podpisu kwalif.
#                                     (esig_auto_applicator dawał sygnaturę
#                                     bez progu wartości)
#
# Zgodność: ADR-001..009/017/022, PIT (art. 30ca/30h/45), KC (art. 109¹-109⁸),
#           KK (art. 41), eIDAS (art. 25-26), OrdPU (art. 126 § 5);
#           thresholds.hyper_contexts (zero hardcode); INV-018;
#           First-Match-Wins.
# package: jdg.r13_hyper_konteksty_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r13_hyper_konteksty_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r13_hyper_konteksty_innovations.no_match", "package": "jdg.r13_hyper_konteksty_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_hc := object.get(_th, "hyper_contexts", {})

solidarity_threshold_pln := object.get(_th_hc, "solidarity_threshold_pln", 1000000)  # art. 30h
solidarity_rate := object.get(_th_hc, "solidarity_rate", 0.04)
ip_box_rate := object.get(_th_hc, "ip_box_rate", 0.05)               # art. 30ca
rd_relief_rate := object.get(_th_hc, "rd_relief_rate", 0.30)         # art. 26e
prokura_deadline_days := object.get(_th_hc, "prokura_deadline_days", 7)  # art. 109¹ KC
pit_annual_deadline := object.get(_th_hc, "pit_annual_deadline", "04-30")  # art. 45
qualified_signature_value_threshold := object.get(_th_hc, "qualified_signature_value_threshold", 10000)

# ── Helper: zaokrąglenie 2 miejsca ────────────────────────────────────────────
round2(x) := floor((x * 100) + 0.5) / 100

# ── Helper: 3 poziomy alertów ─────────────────────────────────────────────────
alert_level(days) := "RED" if {
    days <= 3
} else := "AMBER" if {
    days <= 7
} else := "GREEN" if {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R13-INN-01: CROSS-DOMAIN CONFLICT DETECTOR — detektor konfliktów
#             międzydomenowych (IP Box vs B+R, art. 30ca PIT) POST-MERGE
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza conflict_check: {ip_box_income, rd_relief_income, total_income}.
cd_input := object.get(input, "conflict_check", {})
cd_ip_box := max([0, object.get(cd_input, "ip_box_income", 0)])
cd_rd := max([0, object.get(cd_input, "rd_relief_income", 0)])
cd_total := max([0, object.get(cd_input, "total_income", 0)])

cd_overlap := min([cd_ip_box, cd_rd])
cd_conflict := cd_overlap > 0

cd_routing := "BLOCK_AND_ALERT" if {
    cd_conflict
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r13_hyper_konteksty_innovations.cross_domain_conflict_detector",
    "_legal_basis": "ustawa o PIT art. 30ca (IP Box), art. 26e (ulga B+R), art. 26ea (zbieg ulg)",
    "package": "jdg.r13_hyper_konteksty_innovations",
    "priority": 11026,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "cd_ip_box_income": cd_ip_box,
    "cd_rd_relief_income": cd_rd,
    "cd_total_income": cd_total,
    "cd_overlap_amount": cd_overlap,
    "cd_conflict": cd_conflict,
    "cd_ip_box_rate": ip_box_rate,
    "cd_rd_relief_rate": rd_relief_rate,
    "_routing": cd_routing,
    "_routing_reason": sprintf("Detektor konfliktów — IP Box %d, B+R %d (nakładanie %d). %s", [cd_ip_box, cd_rd, cd_overlap, "KONFLIKT art. 30ca — ten sam dochód nie może korzystać z obu ulg." if {cd_conflict} else "Brak konfliktu."]),
    "_legal_basis": "ustawa o PIT art. 30ca (IP Box), art. 26e (ulga B+R), art. 26ea (zbieg ulg)",
    "_warnings": [sprintf("KONFLIKT: dochód %d objęty jednocześnie IP Box (5%%) i ulgą B+R (30%%) — wybierz jedną ulgę (art. 30ca).", [cd_overlap]) if {cd_conflict} else "Brak konfliktu ulg (art. 30ca)."],
} if {
    object.get(input.jdg_entrepreneur, "r13_hyper_konteksty_check", false) == true
    object.get(input, "conflict_check", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R13-INN-02: SOLIDARITY TAX MONITOR — monitor daniny solidarnościowej
#             (art. 30h PIT): próg 1 mln PLN, 4% od nadwyżki, alert
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza solidarity: {annual_income_pln}.
st_input := object.get(input, "solidarity", {})
st_income := max([0, object.get(st_input, "annual_income_pln", 0)])

st_excess := max([0, st_income - solidarity_threshold_pln])
st_due := round2(st_excess * solidarity_rate)
st_applies := st_excess > 0

st_routing := "TRIAGE_QUEUE" if {
    st_applies
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r13_hyper_konteksty_innovations.solidarity_tax_monitor",
    "_legal_basis": "ustawa o PIT art. 30ca (IP Box), art. 26e (ulga B+R), art. 26ea (zbieg ulg)",
    "package": "jdg.r13_hyper_konteksty_innovations",
    "priority": 11027,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "st_annual_income_pln": st_income,
    "st_threshold_pln": solidarity_threshold_pln,
    "st_excess_pln": st_excess,
    "st_solidarity_due_pln": st_due,
    "st_applies": st_applies,
    "st_rate": solidarity_rate,
    "_routing": st_routing,
    "_routing_reason": sprintf("Danina solidarnościowa — dochód %.2f, nadwyżka %.2f (próg %.0f). %s", [st_income, st_excess, solidarity_threshold_pln, sprintf("danina %.2f PLN (4%%).", [st_due]) if {st_applies} else "poniżej progu."]),
    "_legal_basis": "ustawa o PIT art. 30h (danina solidarnościowa 4% od nadwyżki ponad 1 mln PLN)",
    "_warnings": [sprintf("DANINA SOLIDARNOŚCIOWA: %.2f PLN (4%% od nadwyżki %.2f).", [st_due, st_excess]) if {st_applies} else "Poniżej progu daniny (1 mln PLN)."],
} if {
    object.get(input.jdg_entrepreneur, "r13_hyper_konteksty_check", false) == true
    object.get(input, "solidarity", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R13-INN-03: PROKURA DEADLINE MONITOR — monitor wpisu prokury (art. 109¹-109⁸
#             KC): 7 dni, typy samoistna/łączna, alerty
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza prokura_monitor: {items: [{label, days_left, filed, type}]}.
pk_input := object.get(input, "prokura_monitor", {})
pk_items_in := object.get(pk_input, "items", [])

pk_item(i) := {
    "label": object.get(i, "label", "Prokura"),
    "days_left": object.get(i, "days_left", prokura_deadline_days),
    "filed": object.get(i, "filed", false),
    "type": object.get(i, "type", "SAMOISTNA"),
    "level": alert_level(object.get(i, "days_left", prokura_deadline_days)),
    "next_action": "Wpisz prokurę do CEIDG/KRS (7 dni) — art. 109¹ KC." if {not object.get(i, "filed", false)} else "Prokura wpisana.",
}

pk_items := [pk_item(i) | i := pk_items_in[_]]
pk_red_count := count([x | x := pk_items[_]; x.level == "RED"])
pk_amber_count := count([x | x := pk_items[_]; x.level == "AMBER"])
pk_unfiled_count := count([x | x := pk_items[_]; not x.filed])

pk_routing := "BLOCK_AND_ALERT" if {
    pk_red_count > 0
} else := "TRIAGE_QUEUE" if {
    pk_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r13_hyper_konteksty_innovations.prokura_deadline_monitor",
    "package": "jdg.r13_hyper_konteksty_innovations",
    "priority": 11028,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "pk_items_total": count(pk_items),
    "pk_red_count": pk_red_count,
    "pk_amber_count": pk_amber_count,
    "pk_unfiled_count": pk_unfiled_count,
    "pk_deadline_days": prokura_deadline_days,
    "pk_items": pk_items,
    "_routing": pk_routing,
    "_routing_reason": sprintf("Monitor prokury — %d wpisów (RED: %d, AMBER: %d, niezłożone: %d). Termin %d dni (art. 109¹ KC).", [count(pk_items), pk_red_count, pk_amber_count, pk_unfiled_count, prokura_deadline_days]),
    "_legal_basis": "Kodeks cywilny art. 109¹-109⁸ (prokura samoistna/łączna, wpis do rejestru)",
    "_warnings": [sprintf("PROKURA: %d wpisów — %d RED, %d AMBER, %d niezłożonych. Termin %d dni.", [count(pk_items), pk_red_count, pk_amber_count, pk_unfiled_count, prokura_deadline_days])],
} if {
    object.get(input.jdg_entrepreneur, "r13_hyper_konteksty_check", false) == true
    object.get(input, "prokura_monitor", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R13-INN-04: ANNUAL DEADLINE CALENDAR — inteligentny kalendarz terminów
#             rocznych (art. 45 PIT — 30 kwietnia) z przesunięciem
#             weekend/święto + 3 poziomy alertów
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza deadline_calendar: {items: [{label, days_left, filed,
# weekend_shift}]}.
dl_input := object.get(input, "deadline_calendar", {})
dl_items_in := object.get(dl_input, "items", [])

dl_item(i) := {
    "label": object.get(i, "label", "PIT roczny"),
    "days_left": object.get(i, "days_left", 30),
    "filed": object.get(i, "filed", false),
    "weekend_shift": object.get(i, "weekend_shift", false),
    "deadline": object.get(i, "deadline", pit_annual_deadline),
    "level": alert_level(object.get(i, "days_left", 30)),
    "next_action": "Złóż PIT roczny (art. 45 — 30 kwietnia; przesunięcie weekend/święto)." if {not object.get(i, "filed", false)} else "Termin dotrzymany.",
}

dl_items := [dl_item(i) | i := dl_items_in[_]]
dl_red_count := count([x | x := dl_items[_]; x.level == "RED"])
dl_amber_count := count([x | x := dl_items[_]; x.level == "AMBER"])
dl_unfiled_count := count([x | x := dl_items[_]; not x.filed])
dl_shifted_count := count([x | x := dl_items[_]; x.weekend_shift])

dl_routing := "BLOCK_AND_ALERT" if {
    dl_red_count > 0
} else := "TRIAGE_QUEUE" if {
    dl_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r13_hyper_konteksty_innovations.annual_deadline_calendar",
    "package": "jdg.r13_hyper_konteksty_innovations",
    "priority": 11029,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "dl_items_total": count(dl_items),
    "dl_red_count": dl_red_count,
    "dl_amber_count": dl_amber_count,
    "dl_unfiled_count": dl_unfiled_count,
    "dl_shifted_count": dl_shifted_count,
    "dl_pit_annual_deadline": pit_annual_deadline,
    "dl_items": dl_items,
    "_routing": dl_routing,
    "_routing_reason": sprintf("Kalendarz terminów — %d pozycji (RED: %d, AMBER: %d, niezłożone: %d, przesunięte: %d). PIT roczny: %s.", [count(dl_items), dl_red_count, dl_amber_count, dl_unfiled_count, dl_shifted_count, pit_annual_deadline]),
    "_legal_basis": "ustawa o PIT art. 45 (termin 30 kwietnia), OrdPU art. 12 (przesunięcie weekend/święto)",
    "_warnings": [sprintf("TERMINY: %d pozycji — %d RED, %d AMBER, %d niezłożonych, %d z przesunięciem weekend/święto.", [count(dl_items), dl_red_count, dl_amber_count, dl_unfiled_count, dl_shifted_count])],
} if {
    object.get(input.jdg_entrepreneur, "r13_hyper_konteksty_check", false) == true
    object.get(input, "deadline_calendar", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R13-INN-05: QUALIFIED SIGNATURE SELECTOR — selektor podpisu kwalifikowanego
#             (eIDAS art. 25-26, art. 126 § 5 OP): które dokumenty wymagają
#             podpisu kwalifikowanego
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza signature_check: {document_type, value_pln}.
sg_input := object.get(input, "signature_check", {})
sg_type := object.get(sg_input, "document_type", "")
sg_value := max([0, object.get(sg_input, "value_pln", 0)])

sg_high_value := sg_value >= qualified_signature_value_threshold
sg_qualified_required := sg_high_value or sg_type == "PEŁNOMOCNICTWO" or sg_type == "UMOWA_NOTARIALNA"

sg_routing := "TRIAGE_QUEUE" if {
    sg_qualified_required
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r13_hyper_konteksty_innovations.qualified_signature_selector",
    "_legal_basis": "ustawa o PIT art. 30ca (IP Box), art. 26e (ulga B+R), art. 26ea (zbieg ulg)",
    "package": "jdg.r13_hyper_konteksty_innovations",
    "priority": 11030,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "sg_document_type": sg_type,
    "sg_value_pln": sg_value,
    "sg_qualified_required": sg_qualified_required,
    "sg_value_threshold": qualified_signature_value_threshold,
    "_routing": sg_routing,
    "_routing_reason": sprintf("Selektor podpisu — typ '%s', wartość %.2f. %s", [sg_type, sg_value, "WYMAGANY podpis kwalifikowany (eIDAS)." if {sg_qualified_required} else "Podpis zwykły wystarczy."]),
    "_legal_basis": "eIDAS art. 25-26 (podpis kwalifikowany), OrdPU art. 126 § 5 (wyjątki)",
    "_warnings": [sprintf("PODPIS: typ '%s' — %s", [sg_type, "podpis kwalifikowany (eIDAS art. 25-26)." if {sg_qualified_required} else "podpis zwykły (art. 126 § 5 OP)."])],
} if {
    object.get(input.jdg_entrepreneur, "r13_hyper_konteksty_check", false) == true
    object.get(input, "signature_check", {}) != {}
}
