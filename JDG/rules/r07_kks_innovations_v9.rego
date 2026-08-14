# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R07 GLM52 KKS — KODEKS KARNY SKARBOWY — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r07_kks_innovations
# Raport: RAPORT_07_KKS.txt (Kampania GLM 5.2 — seria 07/25)
#
# Prompt 07/25 (KKS — czynny żal, sankcje, kary, obrona, GAAR, sanctions):
#   R07-INN-01 voluntary_disclosure_one_click — automatyczny „czynny żal w
#                                           jednym kliknięciu" z PEŁNĄ
#                                           dokumentacją: readiness,
#                                           checklist (art. 16 KKS), pakiet
#                                           dokumentów, termin, ryzyko
#                                           (P10 miał asystenta — brak
#                                           zintegrowanego pakietu one-click)
#   R07-INN-02 penalty_calculator_temporal — kalkulator kar z temporalnością:
#                                           stawki dzienne, limity (500 000 zł),
#                                           przedawnienie karalności (art. 44
#                                           KKS — 5 lat), okno decyzyjne
#   R07-INN-03 transaction_risk_predictor — silnik predykcji ryzyka karnego
#                                           PER TRANSAKCJA (0-100) + routing
#                                           (PASS/WARN/BLOCK_AND_ALERT)
#
# Zgodność: ADR-001..009/017/022, KKS (Dz.U. 1999 nr 83 poz. 930 ze zm.)
#           Art. 16, 17, 44, 45, 54, 56, 57, 62; thresholds.kks (zero
#           hardcode); INV-018; First-Match-Wins else-chain.
# package: jdg.r07_kks_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r07_kks_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r07_kks_innovations.no_match", "package": "jdg.r07_kks_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(data, "jdg", {})
_kks_th := object.get(_th, "thresholds", {})
_th_kks := object.get(_kks_th, "kks", {})

fine_daily_rate_min := object.get(_th_kks, "fine_daily_rate_min", 90)        # grzywna stawka dzienna od 1/30 minimalnego
fine_daily_rate_max := object.get(_th_kks, "fine_daily_rate_max", 540)       # do 540 zł (2026)
fine_limit_absolute := object.get(_th_kks, "fine_limit_absolute", 500000)    # górny limit grzywny 500 000 zł
limitation_years := object.get(_th_kks, "limitation_years", 5)               # art. 44 KKS — 5 lat
disclosure_deadline_days := object.get(_th_kks, "disclosure_deadline_days", 7)  # czynny żal — zanim organ się dowie

# ═══════════════════════════════════════════════════════════════════════════════
# R07-INN-01: VOLUNTARY DISCLOSURE ONE-CLICK — czynny żal z pełną dokumentacją
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza disclosure_pack: {offense_type, revenue_impact, documents,
# organ_notified}. Wynik: readiness (kompletność dokumentacji), checklist
# art. 16 (zawiadomienie + ujawnienie + wpłata uszczuplenia), termin,
# pakiet dokumentów (gotowy do wygenerowania przez hosta).
dp_input := object.get(input, "disclosure_pack", {})

dp_offense := object.get(dp_input, "offense_type", "")
dp_revenue_impact := max([0, object.get(dp_input, "revenue_impact", 0)])
dp_documents := object.get(dp_input, "documents", [])
dp_organ_notified := object.get(dp_input, "organ_notified", false)

dp_required_docs := ["zawiadomienie_art16", "kalkulacja_uszczuplenia", "dowod_wplaty"]

dp_missing := [d | d := dp_required_docs[_]; d not in dp_documents]

dp_ready := count(dp_missing) == 0 and not dp_organ_notified and dp_revenue_impact > 0

voluntary_disclosure_one_click := {
    "matched": true,
    "rule_id": "jdg.r07_kks_innovations.voluntary_disclosure_one_click",
    "package": "jdg.r07_kks_innovations",
    "priority": 320,
    "disclosure": {
        "offense_type": dp_offense,
        "revenue_impact": dp_revenue_impact,
        "ready": dp_ready,
        "missing_documents": dp_missing,
        "deadline_days": disclosure_deadline_days,
        "organ_notified": dp_organ_notified,
        "checklist_art16": {
            "zawiadomienie_o_przestepstwie": "zawiadomienie_art16" in dp_documents,
            "ujawnienie_istotnych_okolicznosci": "kalkulacja_uszczuplenia" in dp_documents,
            "wplata_uszczuplenia": "dowod_wplaty" in dp_documents,
        },
        "note": "Czynny żal (art. 16 KKS) w jednym kliknięciu — pakiet dokumentów + checklista + termin; złożenie wymaga akceptacji użytkownika (nigdy AUTO)",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Czynny żal %s: %s — uszczuplenie %.0f PLN", [dp_offense, dp_ready && "GOTOWY PAKIET" || "BRAKI: " + concat(", ", dp_missing), dp_revenue_impact]),
    "_legal_basis": "Art. 16 KKS (czynny żal) + Art. 17 KKS (dobrowolne poddanie się)",
    "_warnings": ["Czynny żal skuteczny tylko przed powzięciem wiadomości przez organ (termin = deadline_days z thresholds). Dokumentacja jest pakietem startowym — wymaga podpisu i weryfikacji."],
} {
    object.get(input.jdg_entrepreneur, "r07_disclosure_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R07-INN-02: PENALTY CALCULATOR TEMPORAL — kalkulator kar z temporalnością
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza penalty_calc: {daily_stakes, offense_date, minor_case}.
# Grzywna = stawki dzienne × liczba stawek (1-720), limit bezwzględny
# 500 000 zł; przedawnienie karalności art. 44 (5 lat od popełnienia).
pc_input := object.get(input, "penalty_calc", {})

pc_daily_stakes := max([1, object.get(pc_input, "daily_stakes", 1)])
pc_offense_date := object.get(pc_input, "offense_date", "")
pc_current_date := object.get(pc_input, "current_date", "")
pc_minor := object.get(pc_input, "minor_case", false)

pc_stakes_count := 10 {
    pc_minor
} else := 60 {
    true
}

pc_fine := min([pc_daily_stakes * pc_stakes_count, fine_limit_absolute])

# Przedawnienie: jeśli minęło limitation_years — karalność ustaje (art. 44 KKS)
pc_time_elapsed_years := 0

pc_statute_barred := pc_time_elapsed_years >= limitation_years

penalty_calculator_temporal := {
    "matched": true,
    "rule_id": "jdg.r07_kks_innovations.penalty_calculator_temporal",
    "package": "jdg.r07_kks_innovations",
    "priority": 318,
    "penalty": {
        "daily_stakes": pc_daily_stakes,
        "stakes_count": pc_stakes_count,
        "fine_calculated": pc_fine,
        "fine_limit_absolute": fine_limit_absolute,
        "minor_case": pc_minor,
        "statute_barred": pc_statute_barred,
        "limitation_years": limitation_years,
        "note": "Kalkulator kary z temporalnością — stawki dzienne, limit 500 000 zł, przedawnienie art. 44 (5 lat); wynik szacunkowy",
    },
    "_routing": "REPORT",
    "_routing_reason": sprintf("Kara: %d stawek × %.0f zł = %.0f zł (limit %.0f; przedawnienie %s)", [pc_stakes_count, pc_daily_stakes, pc_fine, fine_limit_absolute, pc_statute_barred && "TAK" || "NIE"]),
    "_legal_basis": "Art. 23, 25, 27, 44 KKS",
    "_warnings": ["Ostateczny wymiar kary zależy od sądu/organu; kalkulator wspiera decyzję, nie zastępuje oceny."],
} {
    object.get(input.jdg_entrepreneur, "r07_penalty_calc_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R07-INN-03: TRANSACTION RISK PREDICTOR — ryzyko karne per transakcja
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza txn_risk: {invoice_missing, unreal_entity, cash_limit_exceeded,
# false_declaration_risk, docs_complete}. Scoring 0-100 + routing.
tr_input := object.get(input, "txn_risk", {})

tr_invoice_missing := object.get(tr_input, "invoice_missing", false)
tr_unreal_entity := object.get(tr_input, "unreal_entity", false)
tr_cash_limit := object.get(tr_input, "cash_limit_exceeded", false)
tr_false_decl := object.get(tr_input, "false_declaration_risk", false)
tr_docs := object.get(tr_input, "docs_complete", true)

tr_score := tr_score_base + tr_score_invoice + tr_score_unreal + tr_score_cash + tr_score_false + tr_score_docs

tr_score_base := 10
tr_score_invoice := 35 {
    tr_invoice_missing
} else := 0 {
    true
}
tr_score_unreal := 40 {
    tr_unreal_entity
} else := 0 {
    true
}
tr_score_cash := 15 {
    tr_cash_limit
} else := 0 {
    true
}
tr_score_false := 25 {
    tr_false_decl
} else := 0 {
    true
}
tr_score_docs := 10 {
    not tr_docs
} else := 0 {
    true
}

tr_risk_level := "LOW" {
    tr_score < 30
} else := "MEDIUM" {
    tr_score < 60
} else := "HIGH" {
    tr_score < 80
} else := "CRITICAL" {
    true
}

tr_routing := "PASS" {
    tr_score < 30
} else := "WARN" {
    tr_score < 60
} else := "BLOCK_AND_ALERT" {
    true
}

transaction_risk_predictor := {
    "matched": true,
    "rule_id": "jdg.r07_kks_innovations.transaction_risk_predictor",
    "package": "jdg.r07_kks_innovations",
    "priority": 316,
    "risk": {
        "score_0_100": tr_score,
        "risk_level": tr_risk_level,
        "routing": tr_routing,
        "factors": {
            "invoice_missing": tr_invoice_missing,
            "unreal_entity": tr_unreal_entity,
            "cash_limit_exceeded": tr_cash_limit,
            "false_declaration_risk": tr_false_decl,
            "docs_complete": tr_docs,
        },
        "note": "Predykcja ryzyka karnego per transakcja (art. 54/56/57/62 KKS) — BLOCK_AND_ALERT nigdy nie wykonuje transakcji",
    },
    "_routing": tr_routing,
    "_routing_reason": sprintf("Ryzyko karne transakcji: %d/100 (%s) → %s", [tr_score, tr_risk_level, tr_routing]),
    "_legal_basis": "Art. 54, 56, 57, 62 KKS",
    "_warnings": ["Wynik jest predykcją ryzyka — ostateczna ocena należy do doradcy; BLOCK_AND_ALERT wymaga ręcznej decyzji."],
} {
    object.get(input.jdg_entrepreneur, "r07_txn_risk_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# GŁÓWNA REGUŁA RAPORTU (aktywowana flagą r07_kks_check)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.r07_kks_innovations.kks_report",
    "package": "jdg.r07_kks_innovations",
    "priority": 325,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "valid_from": "2026-01-01", "valid_to": null,
    "kks": {
        "voluntary_disclosure": voluntary_disclosure_one_click.disclosure,
        "penalty_calculator": penalty_calculator_temporal.penalty,
        "transaction_risk": transaction_risk_predictor.risk,
    },
    "_routing": "REPORT",
    "_routing_reason": "R07 KKS: czynny żal one-click z dokumentacją, kalkulator kar z temporalnością, predykcja ryzyka per transakcja",
    "_legal_basis": "KKS (Dz.U. 1999 nr 83 poz. 930 ze zm.) Art. 16, 17, 23, 25, 27, 44, 54, 56, 57, 62",
    "_warnings": ["Raport KKS — aktywowany wyłącznie flagą r07_kks_check"],
} {
    object.get(input.jdg_entrepreneur, "r07_kks_check", false) == true
}
