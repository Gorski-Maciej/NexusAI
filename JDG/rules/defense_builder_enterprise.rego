# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE PROACTIVE DEFENSE STRATEGY BUILDER (Innovation 9.12 / BP-12, P19 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Proactive Defense Strategy Builder — Audit Preparation Engine
# description: |
#   ENTERPRISE v7.0 — Budowniczy strategii obrony przed kontrolą. Rozszerza
#   audit_defense_enterprise.rego o proaktywne planowanie i scoring.
#
#   KLUCZOWE FUNKCJE:
#   - Scoring ryzyka kontroli (KSeF, JPK, limity gotówkowe, branża)
#   - Checklista przygotowawcza do kontroli
#   - Symulacja kontroli skarbowej (mock audit)
#   - Scenariusze odpowiedzi na art. 193a (JPK na żądanie)
#   - Plan korekt przedkontrolnych (czynny żal)
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 281-292 OrdPU; Art. 16 KKS; Art. 193a OrdPU
# package: jdg.defense_builder
# deprecated: false
# priority_range: 3150-3179
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.defense_builder

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.defense_builder.no_match",
    "package": "jdg.defense_builder", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# DEF-3150: AUDIT PREPARATION CHECKLIST — Checklista przed kontrolą
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.defense_builder.audit_prep_checklist",
    "package": "jdg.defense_builder",
    "priority": 3150,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "def_checklist_total_items": total_items,
    "def_checklist_completed": completed,
    "def_checklist_readiness_pct": readiness,
    "def_checklist_critical_missing": critical_missing,
    "_routing": def_routing,
    "_routing_reason": def_reason,
    "_legal_basis": "Art. 281-292 OrdPU; Art. 193a OrdPU; Art. 16 KKS",
    "_warnings": [
        sprintf("🛡️ CHECKLISTA PRZYGOTOWANIA DO KONTROLI — %.0f%% gotowości", [readiness]),
        sprintf("   Ukończone: %d/%d", [completed, total_items]),
        sprintf("   Krytyczne braki: %d %s", [critical_missing, "🚨" { critical_missing > 0 } else "✅"]),
        "─────────────────────────────────────────",
        "📋 KLUCZOWE PUNKTY:",
        "   1. Kompletność JPK_V7 i KSeF ✓/✗",
        "   2. Zgodność PKD CEIDG z faktyczną działalnością",
        "   3. Dokumentacja cen transferowych (jeśli dotyczy)",
        "   4. Limit 15k PLN — transakcje bezgotówkowe",
        "   5. Archiwum UPO KSeF (5 lat retencji)",
    ]
} {
    input.defense_prep_checklist == true
    checklist := object.get(input, "def_checklist", {})
    total_items := object.get(checklist, "total", 9)
    completed := object.get(checklist, "completed", 0)
    readiness := completed * 100 / max([total_items, 1])
    critical_missing := object.get(checklist, "critical_missing", 0)

    def_routing := "BLOCK_AND_ALERT" { critical_missing > 0 }
    def_routing := "TRIAGE_QUEUE" { readiness < 75 }
    def_routing := "" { true }
    def_reason := sprintf("CHECKLISTA: %d krytycznych braków — przygotuj przed kontrolą!", [critical_missing]) { critical_missing > 0 }
    def_reason := sprintf("Gotowość %.0f%% — uzupełnij brakujące punkty.", [readiness]) { readiness < 75 }
    def_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# DEF-3160: MOCK AUDIT SIMULATOR — Symulacja kontroli skarbowej
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.defense_builder.mock_audit",
    "package": "jdg.defense_builder",
    "priority": 3160,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "def_mock_audit_score": audit_score,
    "def_mock_audit_risk_areas": risk_areas,
    "def_mock_audit_recommendations": recommendations,
    "_routing": mock_routing,
    "_routing_reason": mock_reason,
    "_legal_basis": "Art. 281-292 OrdPU (symulacja kontroli)",
    "_warnings": build_mock_warnings(audit_score, risk_areas, recommendations)
} {
    input.defense_mock_audit == true

    # Detect risk areas
    risk_areas := []
    high_risk_count := 0

    jpk_flag := 1 { jpk_issues > 3 }
    jpk_flag := 0 { jpk_issues <= 3 }
    ksef_flag := 1 { ksef_missing > 0 }
    ksef_flag := 0 { ksef_missing <= 0 }
    cash_flag := 1 { cash_violations > 0 }
    cash_flag := 0 { cash_violations <= 0 }
    late_flag := 1 { late_filings > 3 }
    late_flag := 0 { late_filings <= 3 }
    high_risk_count := jpk_flag + ksef_flag + cash_flag + late_flag

    audit_score := 100 - (high_risk_count * 20)
    audit_score := max([audit_score, 0])

    recommendations := [
        "Złóż czynny żal dla wszystkich spóźnionych deklaracji",
        "Uzupełnij faktury KSeF przed kontrolą",
        "Przygotuj uzasadnienie dla wszystkich korekt >10k PLN",
        "Zweryfikuj zgodność PKD z faktyczną działalnością",
    ]

    mock_routing := "BLOCK_AND_ALERT" { audit_score < 40 }
    mock_routing := "TRIAGE_QUEUE" { audit_score < 80 }
    mock_routing := "" { true }
    mock_reason := sprintf("MOCK AUDIT: score %d/100 — %d obszarów wysokiego ryzyka.", [audit_score, high_risk_count]) { high_risk_count > 0 }
    mock_reason := sprintf("MOCK AUDIT: score %d/100 — niskie ryzyko kontroli.", [audit_score])
}

build_mock_warnings(score, areas, recs) = final {
    base := [sprintf("🔍 SYMULACJA KONTROLI SKARBOWEJ — Score %d/100", [score])]
    with_areas := array.concat(base, [sprintf("   ⚠️ %s", [a]) | a := areas[_]]) { count(areas) > 0 }
    with_areas := base { count(areas) == 0 }
    with_recs := array.concat(with_areas, ["", "REKOMENDACJE:"])
    with_rec_lines := array.concat(with_recs, [sprintf("   📋 %s", [r]) | r := recs[_]])
    final := with_rec_lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# DEF-3170: ART. 193A RESPONSE PLANNER — Plan odpowiedzi na JPK na żądanie
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.defense_builder.article_193a_planner",
    "package": "jdg.defense_builder",
    "priority": 3170,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "def_jpk_requested": jpk_requested,
    "def_jpk_file_types_needed": file_types,
    "def_jpk_response_deadline_days": deadline_days,
    "def_jpk_preparation_status": prep_status,
    "def_jpk_penalty_for_noncompliance": penalty,
    "_routing": jpk193_routing,
    "_routing_reason": jpk193_reason,
    "_legal_basis": "Art. 193a OrdPU; Art. 80 KKS (brak JPK na żądanie)",
    "_warnings": [
        sprintf("📊 JPK NA ŻĄDANIE (Art. 193a OrdPU)", []),
        sprintf("   Żądane pliki: %s", [concat(", ", file_types)]),
        sprintf("   Termin: %d dni | Status: %s", [deadline_days, prep_status]),
        sprintf("   ⚠️ %s", [penalty]),
        "📋 Generuj automatycznie: JPK_V7, JPK_PKPIR, JPK_FA, JPK_KR/ST",
    ]
} {
    input.defense_193a_plan == true
    jpk_requested := object.get(input, "def_jpk_requested", true)
    file_types := object.get(input, "def_jpk_file_types", ["JPK_V7M", "JPK_PKPIR"])
    deadline_days := object.get(input, "def_jpk_deadline_days", 14)
    all_files_ready := object.get(input, "def_jpk_files_ready", false)
    prep_status := "GOTOWE ✓" { all_files_ready }
    prep_status := sprintf("W TRAKCIE — %d dni do deadline", [deadline_days]) { not all_files_ready }
    penalty := "Kara do 5 000 PLN + odpowiedzialność KKS (Art. 80 KKS) za brak JPK!" { not all_files_ready }
    penalty := "Brak ryzyka — wszystkie pliki gotowe." { all_files_ready }

    jpk193_routing := "BLOCK_AND_ALERT" { not all_files_ready; deadline_days <= 3 }
    jpk193_routing := "TRIAGE_QUEUE" { not all_files_ready }
    jpk193_routing := "" { true }
    jpk193_reason := sprintf("JPK na żądanie: %s — termin za %d dni!", [prep_status, deadline_days]) { not all_files_ready }
    jpk193_reason := "" { true }
}
