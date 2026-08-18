# NexusAI JDG — Enterprise proactive defense strategy builder.
# Legal basis: Art. 281-292 and 193a OrdPU; Art. 16 and 80 KKS.

package jdg.defense_builder

import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.defense_builder.no_match",
    "package": "jdg.defense_builder",
    "priority": 9999
}

base_fields := {
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false
}

checklist := object.get(input, "def_checklist", {})
total_items := object.get(checklist, "total", 9)
completed_items := object.get(checklist, "completed", 0)
readiness_pct := completed_items * 100 / max([total_items, 1])
critical_missing := object.get(checklist, "critical_missing", 0)

checklist_routing(critical, readiness) = "BLOCK_AND_ALERT" if {
    critical > 0
} else = "TRIAGE_QUEUE" if {
    readiness < 75
} else = "" if {
    true
}

checklist_reason(critical, readiness) = sprintf("CHECKLISTA: %d krytycznych braków — przygotuj przed kontrolą!", [critical]) if {
    critical > 0
} else = sprintf("Gotowość %.0f%% — uzupełnij brakujące punkty.", [readiness]) if {
    readiness < 75
} else = "" if {
    true
}

checklist_warning_label(critical) = "🚨" if {
    critical > 0
} else = "✅" if {
    true
}

# DEF-3150: audit preparation checklist.
decide := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.defense_builder.audit_prep_checklist",
    "package": "jdg.defense_builder",
    "priority": 3150,
    "def_checklist_total_items": total_items,
    "def_checklist_completed": completed_items,
    "def_checklist_readiness_pct": readiness_pct,
    "def_checklist_critical_missing": critical_missing,
    "_routing": checklist_routing(critical_missing, readiness_pct),
    "_routing_reason": checklist_reason(critical_missing, readiness_pct),
    "_legal_basis": "Art. 281-292 OrdPU; Art. 193a OrdPU; Art. 16 KKS",
    "_warnings": [
        sprintf("🛡️ CHECKLISTA PRZYGOTOWANIA DO KONTROLI — %.0f%% gotowości", [readiness_pct]),
        sprintf("   Ukończone: %d/%d", [completed_items, total_items]),
        sprintf("   Krytyczne braki: %d %s", [critical_missing, checklist_warning_label(critical_missing)]),
        "─────────────────────────────────────────",
        "📋 KLUCZOWE PUNKTY:",
        "   1. Kompletność JPK_V7 i KSeF ✓/✗",
        "   2. Zgodność PKD CEIDG z faktyczną działalnością",
        "   3. Dokumentacja cen transferowych (jeśli dotyczy)",
        "   4. Limit 15k PLN — transakcje bezgotówkowe",
        "   5. Archiwum UPO KSeF (5 lat retencji)"
    ]
}) if {
    object.get(input, "defense_prep_checklist", false) == true
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.defense_builder.mock_audit",
    "package": "jdg.defense_builder",
    "priority": 3160,
    "def_mock_audit_score": mock_audit_score,
    "def_mock_audit_risk_areas": mock_risk_areas,
    "def_mock_audit_recommendations": mock_recommendations,
    "_routing": mock_audit_routing_value,
    "_routing_reason": mock_audit_reason_value,
    "_legal_basis": "Art. 281-292 OrdPU (symulacja kontroli)",
    "_warnings": build_mock_warnings(mock_audit_score, mock_risk_areas, mock_recommendations)
}) if {
    object.get(input, "defense_mock_audit", false) == true
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.defense_builder.article_193a_planner",
    "package": "jdg.defense_builder",
    "priority": 3170,
    "def_jpk_requested": jpk_requested,
    "def_jpk_file_types_needed": jpk_file_types,
    "def_jpk_response_deadline_days": jpk_deadline_days,
    "def_jpk_preparation_status": jpk_prep_status,
    "def_jpk_penalty_for_noncompliance": jpk_penalty,
    "_routing": jpk_routing,
    "_routing_reason": jpk_reason,
    "_legal_basis": "Art. 193a OrdPU; Art. 80 KKS (brak JPK na żądanie)",
    "_warnings": [
        "📊 JPK NA ŻĄDANIE (Art. 193a OrdPU)",
        sprintf("   Żądane pliki: %s", [concat(", ", jpk_file_types)]),
        sprintf("   Termin: %d dni | Status: %s", [jpk_deadline_days, jpk_prep_status]),
        sprintf("   ⚠️ %s", [jpk_penalty]),
        "📋 Generuj automatycznie: JPK_V7, JPK_PKPIR, JPK_FA, JPK_KR/ST"
    ]
}) if {
    object.get(input, "defense_193a_plan", false) == true
}

# DEF-3160: mock audit helpers.
jpk_issues := object.get(input, "def_mock_jpk_issues", 0)
ksef_missing := object.get(input, "def_mock_ksef_missing", 0)
cash_violations := object.get(input, "def_mock_cash_violations", 0)
late_filings := object.get(input, "def_mock_late_filings", 0)

mock_risk_count := bool_score(jpk_issues > 3) + bool_score(ksef_missing > 0) + bool_score(cash_violations > 0) + bool_score(late_filings > 3)
mock_audit_score := max([100 - mock_risk_count * 20, 0])
mock_risk_areas := mock_risk_area_list(jpk_issues, ksef_missing, cash_violations, late_filings)
mock_recommendations := [
    "Złóż czynny żal dla wszystkich spóźnionych deklaracji",
    "Uzupełnij faktury KSeF przed kontrolą",
    "Przygotuj uzasadnienie dla wszystkich korekt >10k PLN",
    "Zweryfikuj zgodność PKD z faktyczną działalnością"
]

mock_audit_routing(score) = "BLOCK_AND_ALERT" if {
    score < 40
} else = "TRIAGE_QUEUE" if {
    score < 80
} else = "" if {
    true
}

mock_audit_reason(score, count) = sprintf("MOCK AUDIT: score %d/100 — %d obszarów wysokiego ryzyka.", [score, count]) if {
    count > 0
} else = sprintf("MOCK AUDIT: score %d/100 — niskie ryzyko kontroli.", [score]) if {
    true
}

mock_audit_routing_value := mock_audit_routing(mock_audit_score)
mock_audit_reason_value := mock_audit_reason(mock_audit_score, mock_risk_count)

bool_score(value) = 1 if {
    value == true
} else = 0 if {
    true
}

risk_label(condition, label) = [label] if {
    condition == true
} else = [] if {
    true
}

mock_risk_area_list(jpk, ksef, cash, late) = areas if {
    areas := array.concat(
        array.concat(
            array.concat(
                risk_label(jpk > 3, "JPK/VAT — niespójności"),
                risk_label(ksef > 0, "KSeF — brakujące faktury")
            ),
            risk_label(cash > 0, "Limit gotówkowy — naruszenia")
        ),
        risk_label(late > 3, "Deklaracje — opóźnienia")
    )
}

build_mock_warnings(score, areas, recommendations) = final if {
    area_lines := [sprintf("   ⚠️ %s", [area]) | area := areas[_]]
    rec_lines := [sprintf("   📋 %s", [recommendation]) | recommendation := recommendations[_]]
    final := array.concat(
        array.concat(
            [sprintf("🔍 SYMULACJA KONTROLI SKARBOWEJ — Score %d/100", [score])],
            area_lines
        ),
        array.concat(["", "REKOMENDACJE:"], rec_lines)
    )
}

# DEF-3170: Article 193a planner helpers.
jpk_requested := object.get(input, "def_jpk_requested", true)
jpk_file_types := object.get(input, "def_jpk_file_types", ["JPK_V7M", "JPK_PKPIR"])
jpk_deadline_days := object.get(input, "def_jpk_deadline_days", 14)
jpk_files_ready := object.get(input, "def_jpk_files_ready", false)
jpk_prep_status := "GOTOWE ✓" if {
    jpk_files_ready == true
} else = sprintf("W TRAKCIE — %d dni do deadline", [jpk_deadline_days]) if {
    true
}

jpk_penalty := "Kara do 5 000 PLN + odpowiedzialność KKS (Art. 80 KKS) za brak JPK!" if {
    jpk_files_ready == false
} else = "Brak ryzyka — wszystkie pliki gotowe." if {
    true
}

jpk_routing = "BLOCK_AND_ALERT" if {
    jpk_files_ready == false
    jpk_deadline_days <= 3
} else = "TRIAGE_QUEUE" if {
    jpk_files_ready == false
} else = "" if {
    true
}

jpk_reason = sprintf("JPK na żądanie: %s — termin za %d dni!", [jpk_prep_status, jpk_deadline_days]) if {
    jpk_files_ready == false
} else = "" if {
    true
}
