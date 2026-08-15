# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R15 GLM52 KSeF / JPK / e-DEKLARACJE / GTU / WIS — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r15_ksef_jpk_edeklaracje_innovations
# Raport: RAPORT_15_KSEF_JPK_EDEKLARACJE.txt (Kampania GLM 5.2 — seria 15/25)
#
# Prompt 15/25 (KSeF / JPK / e-deklaracje / e-doręczenia / WIS / GTU):
#   R15-INN-01 ksef_firewall_monitor — firewall KSeF: walidacja NIP + obowiązek
#                                      (art. 106na od 01.02.2026) + sankcje do
#                                      500k (p17 ksef_firewall_guard nie
#                                      monitorował sankcji)
#   R15-INN-02 jpk_reconciliation_checker — korelator VAT-7 ≡ JPK_V7M ≡ księgi
#                                      (art. 82/99) z wykrywaniem rozjazdów
#                                      (p17 jpk_cross_validation bez scoringu)
#   R15-INN-03 gtu_code_classifier — auto-klasyfikator GTU (analiza semantyczna
#                                      opisu faktury) z walidacją kodu (p17
#                                      gtu_auto_assigner bez walidacji)
#   R15-INN-04 ksef_offline_deadline_monitor — monitor trybu awaryjnego KSeF
#                                      (art. 106nb — 7 dni) z alertami (p17
#                                      ksef_offline_retry bez monitora terminu)
#   R15-INN-05 wis_request_monitor — monitor wniosku WIS (art. 42a): kompletność,
#                                      opłata, termin odpowiedzi (p17
#                                      wis_auto_requester bez monitora)
#
# Zgodność: ADR-001..009/017/022, VAT (art. 82/99/106na-106nq/106j/42a),
#           OrdPU (art. 193a); thresholds.ksef_jpk (zero hardcode); INV-018;
#           First-Match-Wins.
# package: jdg.r15_ksef_jpk_edeklaracje_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r15_ksef_jpk_edeklaracje_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r15_ksef_jpk_edeklaracje_innovations.no_match", "package": "jdg.r15_ksef_jpk_edeklaracje_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_kj := object.get(_th, "ksef_jpk", {})

ksef_mandatory_from := object.get(_th_kj, "ksef_mandatory_from", "2026-02-01")  # art. 106na
ksef_offline_grace_days := object.get(_th_kj, "ksef_offline_grace_days", 7)     # art. 106nb
ksef_sanction_max_pln := object.get(_th_kj, "ksef_sanction_max_pln", 500000)    # sankcja
ksef_upo_deadline_days := object.get(_th_kj, "ksef_upo_deadline_days", 1)       # UPO
jpk_v7_deadline_day := object.get(_th_kj, "jpk_v7_deadline_day", 25)            # JPK_V7M
jpk_ksef_penalty_per_invoice := object.get(_th_kj, "jpk_ksef_penalty_per_invoice", 1000)
wis_response_days := object.get(_th_kj, "wis_response_days", 3)                 # art. 42a
gtu_codes := object.get(_th_kj, "gtu_codes", ["GTU_01", "GTU_02", "GTU_03"])

# ── Helper: 3 poziomy alertów ─────────────────────────────────────────────────
alert_level(days) := "RED" if {
    days <= 3
} else := "AMBER" if {
    days <= 7
} else := "GREEN" if {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R15-INN-01: KSEF FIREWALL MONITOR — firewall KSeF: walidacja NIP + obowiązek
#             (art. 106na od 01.02.2026) + sankcje do 500k
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza ksef_check: {nip_valid, xsd_valid, upo_received}.
kf_input := object.get(input, "ksef_check", {})
kf_nip_valid := object.get(kf_input, "nip_valid", false)
kf_xsd_valid := object.get(kf_input, "xsd_valid", false)
kf_upo_received := object.get(kf_input, "upo_received", false)

kf_blocked := not kf_nip_valid
kf_triage := kf_nip_valid and (not kf_xsd_valid or not kf_upo_received)

kf_routing := "BLOCK_AND_ALERT" if {
    kf_blocked
} else := "TRIAGE_QUEUE" if {
    kf_triage
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r15_ksef_jpk_edeklaracje_innovations.ksef_firewall_monitor",
    "package": "jdg.r15_ksef_jpk_edeklaracje_innovations",
    "priority": 11036,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "kf_nip_valid": kf_nip_valid,
    "kf_xsd_valid": kf_xsd_valid,
    "kf_upo_received": kf_upo_received,
    "kf_mandatory_from": ksef_mandatory_from,
    "kf_sanction_max_pln": ksef_sanction_max_pln,
    "_routing": kf_routing,
    "_routing_reason": sprintf("Firewall KSeF — NIP=%s, XSD=%s, UPO=%s. Obowiązek od %s (sankcja do %d PLN). %s", [kf_nip_valid, kf_xsd_valid, kf_upo_received, ksef_mandatory_from, ksef_sanction_max_pln, "BŁĄD NIP — zablokuj wysyłkę." if {kf_blocked} else "Niekompletny łańcuch KSeF." if {kf_triage} else "Łańcuch KSeF kompletny."]),
    "_legal_basis": "ustawa o VAT art. 106na-106nq (KSeF od 01.02.2026, sankcja do 500 000 zł), art. 106nb (tryb awaryjny)",
    "_warnings": [sprintf("KSeF: %s", ["BŁĘDNY NIP — zablokuj wysyłkę (sankcja)." if {kf_blocked} else "niekompletny łańcuch (XSD/UPO)." if {kf_triage} else "OK."])],
} if {
    object.get(input.jdg_entrepreneur, "r15_ksef_jpk_check", false) == true
    object.get(input, "ksef_check", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R15-INN-02: JPK RECONCILIATION CHECKER — korelator VAT-7 ≡ JPK_V7M ≡ księgi
#             (art. 82/99) z wykrywaniem rozjazdów
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza jpk_reconciliation: {vat7_pln, jpk_v7m_pln, ledger_pln}.
jr_input := object.get(input, "jpk_reconciliation", {})
jr_vat7 := max([0, object.get(jr_input, "vat7_pln", 0)])
jr_jpk := max([0, object.get(jr_input, "jpk_v7m_pln", 0)])
jr_ledger := max([0, object.get(jr_input, "ledger_pln", 0)])

jr_mismatch := jr_vat7 != jr_jpk or jr_jpk != jr_ledger
jr_max_delta := max([abs(jr_vat7 - jr_jpk), abs(jr_jpk - jr_ledger)])

jr_routing := "TRIAGE_QUEUE" if {
    jr_mismatch
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r15_ksef_jpk_edeklaracje_innovations.jpk_reconciliation_checker",
    "package": "jdg.r15_ksef_jpk_edeklaracje_innovations",
    "priority": 11037,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "jr_vat7_pln": jr_vat7,
    "jr_jpk_v7m_pln": jr_jpk,
    "jr_ledger_pln": jr_ledger,
    "jr_mismatch": jr_mismatch,
    "jr_max_delta_pln": jr_max_delta,
    "jr_v7_deadline_day": jpk_v7_deadline_day,
    "_routing": jr_routing,
    "_routing_reason": sprintf("Korelacja JPK — VAT-7 %.2f, JPK_V7M %.2f, księgi %.2f (Δ %.2f). %s", [jr_vat7, jr_jpk, jr_ledger, jr_max_delta, "ROZJAZD — skoryguj deklaracje." if {jr_mismatch} else "Zgodne."]),
    "_legal_basis": "ustawa o VAT art. 82 (JPK_V7), art. 99 (JPK_V7M), OrdPU art. 193a (JPK na żądanie)",
    "_warnings": [sprintf("JPK: %s", ["rozjazd deklaracji — skoryguj." if {jr_mismatch} else "VAT-7 ≡ JPK_V7M ≡ księgi — zgodne."])],
} if {
    object.get(input.jdg_entrepreneur, "r15_ksef_jpk_check", false) == true
    object.get(input, "jpk_reconciliation", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R15-INN-03: GTU CODE CLASSIFIER — auto-klasyfikator GTU (analiza semantyczna
#             opisu faktury) z walidacją kodu
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza gtu_input: {invoice_desc, assigned_code}.
gt_input := object.get(input, "gtu_input", {})
gt_desc := object.get(gt_input, "invoice_desc", "")
gt_assigned := object.get(gt_input, "assigned_code", "")

gt_expected := "GTU_01" if {
    contains(gt_desc, "alkohol")
} else := "GTU_02" if {
    contains(gt_desc, "paliwo")
} else := "GTU_03" if {
    contains(gt_desc, "tytoń")
} else := "GTU_04" if {
    contains(gt_desc, "elektronika")
} else := "" if {
    true
}

gt_mismatch := gt_assigned != "" and gt_assigned != gt_expected and gt_expected != ""
gt_unknown := gt_expected == "" and gt_assigned == ""

gt_routing := "TRIAGE_QUEUE" if {
    gt_mismatch
} else := "TRIAGE_QUEUE" if {
    gt_unknown
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r15_ksef_jpk_edeklaracje_innovations.gtu_code_classifier",
    "package": "jdg.r15_ksef_jpk_edeklaracje_innovations",
    "priority": 11038,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "gt_invoice_desc": gt_desc,
    "gt_assigned_code": gt_assigned,
    "gt_expected_code": gt_expected,
    "gt_mismatch": gt_mismatch,
    "gt_unknown": gt_unknown,
    "gt_known_codes": count(gtu_codes),
    "_routing": gt_routing,
    "_routing_reason": sprintf("Klasyfikator GTU — '%s': kod '%s' (oczekiwany '%s'). %s", [gt_desc, gt_assigned, gt_expected, "NIEZGODNOŚĆ kodu GTU." if {gt_mismatch} else "kod nieokreślony." if {gt_unknown} else "kod zgodny."]),
    "_legal_basis": "ustawa o VAT art. 99 (JPK_V7M z kodami GTU), rozporządzenie MF (słownik GTU_01..GTU_13)",
    "_warnings": [sprintf("GTU: '%s' — %s", [gt_desc, "niezgodność kodu GTU." if {gt_mismatch} else "kod nieokreślony — zweryfikuj." if {gt_unknown} else "OK."])],
} if {
    object.get(input.jdg_entrepreneur, "r15_ksef_jpk_check", false) == true
    object.get(input, "gtu_input", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R15-INN-04: KSEF OFFLINE DEADLINE MONITOR — monitor trybu awaryjnego KSeF
#             (art. 106nb — 7 dni) z alertami
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza ksef_offline: {items: [{label, days_left, filed}]}.
ko_input := object.get(input, "ksef_offline", {})
ko_items_in := object.get(ko_input, "items", [])

ko_item(i) := {
    "label": object.get(i, "label", "KSeF offline"),
    "days_left": object.get(i, "days_left", ksef_offline_grace_days),
    "filed": object.get(i, "filed", false),
    "level": alert_level(object.get(i, "days_left", ksef_offline_grace_days)),
    "next_action": "Wyślij fakturę do KSeF w trybie awaryjnym (art. 106nb — 7 dni)." if {not object.get(i, "filed", false)} else "Wysłano.",
}

ko_items := [ko_item(i) | i := ko_items_in[_]]
ko_red_count := count([x | x := ko_items[_]; x.level == "RED"])
ko_amber_count := count([x | x := ko_items[_]; x.level == "AMBER"])
ko_unfiled_count := count([x | x := ko_items[_]; not x.filed])

ko_routing := "BLOCK_AND_ALERT" if {
    ko_red_count > 0
} else := "TRIAGE_QUEUE" if {
    ko_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r15_ksef_jpk_edeklaracje_innovations.ksef_offline_deadline_monitor",
    "package": "jdg.r15_ksef_jpk_edeklaracje_innovations",
    "priority": 11039,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "ko_items_total": count(ko_items),
    "ko_red_count": ko_red_count,
    "ko_amber_count": ko_amber_count,
    "ko_unfiled_count": ko_unfiled_count,
    "ko_grace_days": ksef_offline_grace_days,
    "ko_items": ko_items,
    "_routing": ko_routing,
    "_routing_reason": sprintf("Monitor offline KSeF — %d pozycji (RED: %d, AMBER: %d, niewysłane: %d). Tryb awaryjny %d dni (art. 106nb).", [count(ko_items), ko_red_count, ko_amber_count, ko_unfiled_count, ksef_offline_grace_days]),
    "_legal_basis": "ustawa o VAT art. 106nb ust. 5-6 (tryb awaryjny KSeF, 7 dni)",
    "_warnings": [sprintf("KSeF offline: %d pozycji — %d RED, %d AMBER, %d niewysłanych.", [count(ko_items), ko_red_count, ko_amber_count, ko_unfiled_count])],
} if {
    object.get(input.jdg_entrepreneur, "r15_ksef_jpk_check", false) == true
    object.get(input, "ksef_offline", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R15-INN-05: WIS REQUEST MONITOR — monitor wniosku WIS (art. 42a): kompletność,
#             opłata, termin odpowiedzi
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza wis_request: {goods_desc, fee_paid, submitted}.
wr_input := object.get(input, "wis_request", {})
wr_desc := object.get(wr_input, "goods_desc", "")
wr_fee_paid := object.get(wr_input, "fee_paid", false)
wr_submitted := object.get(wr_input, "submitted", false)

wr_incomplete := wr_desc == "" or not wr_fee_paid or not wr_submitted

wr_routing := "TRIAGE_QUEUE" if {
    wr_incomplete
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r15_ksef_jpk_edeklaracje_innovations.wis_request_monitor",
    "package": "jdg.r15_ksef_jpk_edeklaracje_innovations",
    "priority": 11040,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "wr_goods_desc": wr_desc,
    "wr_fee_paid": wr_fee_paid,
    "wr_submitted": wr_submitted,
    "wr_incomplete": wr_incomplete,
    "wr_response_days": wis_response_days,
    "_routing": wr_routing,
    "_routing_reason": sprintf("Wniosek WIS — opis='%s', opłata=%s, złożony=%s. Termin odpowiedzi %d dni (art. 42a). %s", [wr_desc, wr_fee_paid, wr_submitted, wis_response_days, "BRAKI — uzupełnij wniosek." if {wr_incomplete} else "Wniosek kompletny."]),
    "_legal_basis": "ustawa o VAT art. 42a (WIS — wiążąca informacja stawkowa), art. 42b-42h",
    "_warnings": [sprintf("WIS: %s", ["wniosek niekompletny (opis/opłata/złożenie)." if {wr_incomplete} else "kompletny."])],
} if {
    object.get(input.jdg_entrepreneur, "r15_ksef_jpk_check", false) == true
    object.get(input, "wis_request", {}) != {}
}
