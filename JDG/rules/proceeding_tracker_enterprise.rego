# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE TAX PROCEEDING TIMELINE TRACKER (Innovation 9.9 / BP-9, P19 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Tax Proceeding Timeline Tracker — Deadline & Escalation Engine
# description: |
#   ENTERPRISE v7.0 — Rejestr postępowań podatkowych z kalendarzem terminów
#   ustawowych i eskalacjami. Wypełnia lukę L3 z raportu P19.
#
#   KLUCZOWE FUNKCJE:
#   - Rejestr wszystkich postępowań (kontrola, odwołanie, interpretacja, nadpłata)
#   - Kalendarz terminów ustawowych:
#     * 14 dni — odwołanie od decyzji (Art. 223 OrdPU)
#     * 30 dni — zwrot nadpłaty (Art. 77 OrdPU)
#     * 3 miesiące — interpretacja indywidualna (Art. 14d OrdPU)
#     * 7 dni — odpowiedź na wezwanie (Art. 155 OrdPU)
#   - Eskalacja po przekroczeniu terminów
#   - Audit trail wszystkich interakcji
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 14d, 77, 139-140, 155, 220-247 OrdPU
# package: jdg.proceeding_tracker
# deprecated: false
# priority_range: 3090-3119
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.proceeding_tracker

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.proceeding_tracker.no_match",
    "package": "jdg.proceeding_tracker", "priority": 9999
}

# Deadline types with statutory days
statutory_deadlines := {
    "APPEAL": {"days": 14, "law": "Art. 223 OrdPU", "desc": "Odwołanie od decyzji"},
    "OVERPAYMENT_REFUND": {"days": 30, "law": "Art. 77 OrdPU", "desc": "Zwrot nadpłaty"},
    "INTERPRETATION": {"days": 90, "law": "Art. 14d OrdPU", "desc": "Wydanie interpretacji indywidualnej"},
    "SUMMON_RESPONSE": {"days": 7, "law": "Art. 155 OrdPU", "desc": "Odpowiedź na wezwanie"},
    "CORRECTION": {"days": 14, "law": "Art. 81 OrdPU", "desc": "Korekta deklaracji"},
    "JPK_ON_DEMAND": {"days": 14, "law": "Art. 193a OrdPU", "desc": "JPK na żądanie"},
    "INSTALLMENT_APPROVAL": {"days": 30, "law": "Art. 67a OrdPU", "desc": "Rozpatrzenie wniosku o raty"},
    "GAAR_OPINION": {"days": 90, "law": "Art. 119f OrdPU", "desc": "Opinia zabezpieczająca GAAR"},
}

# ═══════════════════════════════════════════════════════════════════════════════
# PRT-3090: PROCEEDING REGISTRY — Rejestr wszystkich postępowań
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.proceeding_tracker.proceeding_registry",
    "package": "jdg.proceeding_tracker",
    "priority": 3090,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "prt_total_proceedings": total,
    "prt_active_proceedings": active,
    "prt_proceedings_within_deadline": within_deadline,
    "prt_proceedings_overdue": overdue,
    "prt_next_escalation_date": next_escalation,
    "_routing": prt_routing,
    "_routing_reason": prt_reason,
    "_legal_basis": "Art. 139-140 OrdPU (terminy załatwiania spraw)",
    "_warnings": build_prt_warnings(total, active, within_deadline, overdue, next_escalation)
} {
    input.proceeding_tracker_check == true
    proceedings := object.get(input, "prt_proceedings", [])
    total := count(proceedings)
    active := count([p | p := proceedings[_]; object.get(p, "status", "") not in {"CLOSED", "RESOLVED"}])
    days_remaining_arr := [d | p := proceedings[_]; d := object.get(p, "days_to_deadline", 999)]
    within_deadline := count([d | d := days_remaining_arr[_]; d > 0])
    overdue := active - within_deadline
    next_escalation := min(days_remaining_arr) { count(days_remaining_arr) > 0 }
    next_escalation := 999 { count(days_remaining_arr) == 0 }

    prt_routing := "BLOCK_AND_ALERT" { overdue > 0 }
    prt_routing := "TRIAGE_QUEUE" { next_escalation <= 7; overdue == 0 }
    prt_routing := "" { true }
    prt_reason := sprintf("%d POSTĘPOWAŃ PO TERMINIE — natychmiastowa eskalacja!", [overdue]) { overdue > 0 }
    prt_reason := sprintf("Najbliższa eskalacja za %d dni.", [next_escalation]) { next_escalation <= 7 }
    prt_reason := "" { true }
}

build_prt_warnings(total, active, within, overdue, escalation) = warnings {
    warnings := [
        sprintf("📋 REJESTR POSTĘPOWAŃ PODATKOWYCH", []),
        sprintf("   Łącznie: %d | Aktywne: %d", [total, active]),
        sprintf("   W terminie: %d | Po terminie: %d %s", [within, overdue, "🚨" { overdue > 0 } else "✅"]),
        sprintf("   Najbliższa eskalacja: %s", [sprintf("za %d dni ⚠️" { escalation <= 7 } else "za %d dni" { escalation > 7 } else "brak", [escalation])]),
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# PRT-3100: DEADLINE ESCALATOR — Eskalacja po przekroczeniu terminów
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.proceeding_tracker.deadline_escalator",
    "package": "jdg.proceeding_tracker",
    "priority": 3100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "prt_escalation_proceeding_ref": proceeding_ref,
    "prt_escalation_type": proceeding_type,
    "prt_escalation_days_overdue": days_overdue,
    "prt_escalation_action_required": action_required,
    "prt_escalation_legal_consequence": consequence,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("ESKALACJA: '%s' %d dni po terminie — %s", [proceeding_type, days_overdue, action_required]),
    "_legal_basis": "Art. 139-141 OrdPU; Art. 36-38 KPA",
    "_warnings": [
        sprintf("🚨 ESKALACJA POSTĘPOWANIA — %s", [proceeding_ref]),
        sprintf("   Typ: %s | Po terminie: %d dni", [proceeding_type, days_overdue]),
        sprintf("   ⚠️ %s", [consequence]),
        sprintf("   📋 DZIAŁANIE: %s", [action_required]),
    ]
} {
    input.proceeding_escalation_check == true
    proceeding_ref := object.get(input, "prt_escalation_ref", "")
    proceeding_type := object.get(input, "prt_escalation_type", "APPEAL")
    days_overdue := object.get(input, "prt_days_overdue", 0)
    deadline_info := object.get(statutory_deadlines, proceeding_type, {"days": 14, "law": "?", "desc": "?"})
    deadline_days := deadline_info.days

    action_required := "Złóż odwołanie z wnioskiem o przywrócenie terminu (Art. 162 OrdPU)." { proceeding_type == "APPEAL" }
    action_required := "Złóż ponaglenie do Naczelnika US (Art. 141 OrdPU)." { proceeding_type == "OVERPAYMENT_REFUND" }
    action_required := sprintf("Odpowiedz NATYCHMIAST na wezwanie — termin minął %d dni temu!", [days_overdue]) { proceeding_type == "SUMMON_RESPONSE" }
    action_required := sprintf("Skontaktuj się z organem — %d dni opóźnienia.", [days_overdue])

    consequence := "Utrata prawa do odwołania — decyzja staje się ostateczna." { proceeding_type == "APPEAL" }
    consequence := "Odsetki od nadpłaty — US płaci odsetki za każdy dzień zwłoki." { proceeding_type == "OVERPAYMENT_REFUND" }
    consequence := "Kara porządkowa do 2 800 PLN (Art. 262 OrdPU) + domiar podatku." { proceeding_type == "SUMMON_RESPONSE" }
    consequence := "Ryzyko negatywnych konsekwencji procesowych."

    days_overdue > 0
}
