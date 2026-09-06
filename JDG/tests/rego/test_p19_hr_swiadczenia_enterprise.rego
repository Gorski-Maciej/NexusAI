# NexusAI JDG — testy rego P19 (HR i Świadczenia)
# Package: jdg.tests.p19_hr_swiadczenia
package jdg.tests.p19_hr_swiadczenia

import future.keywords.in

test_p19_coverage_report {
    result := data.jdg.p19_hr_swiadczenia_innovations.hr_coverage_report with input as {"jdg_entrepreneur": {"p19_hr_check": true}}
    result.rule_id == "jdg.p19_hr_swiadczenia_innovations.hr_coverage_report"
    result.matched == true
    count(result.modules) == 10
}

test_employer_audit {
    result := data.jdg.p19_hr_swiadczenia_innovations.employer_audit with input as {"jdg_entrepreneur": {"p19_hr_check": true}}
    result.rule_id == "jdg.p19_hr_swiadczenia_innovations.employer_audit"
    result.obowiazki_pracodawcy.kup_dojazdy_pln == 300
}

test_salary_calculator {
    result := data.jdg.p19_hr_swiadczenia_innovations.salary_calculator with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"gross_pln": 6000}}
    result.matched == true
    result.gross_pln == 6000
    result.net_pln > 0
}

test_payroll_generator {
    result := data.jdg.p19_hr_swiadczenia_innovations.payroll_generator with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"employees": 3}}
    result.payroll_generated == true
    count(result.fields) == 6
}

test_leave_tracker {
    result := data.jdg.p19_hr_swiadczenia_innovations.leave_tracker with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"leave_used_days": 12}}
    result.leave_entitlement_days == 26
    result.leave_remaining_days == 14
}

test_family_benefits_audit {
    result := data.jdg.p19_hr_swiadczenia_innovations.family_benefits_audit with input as {"jdg_entrepreneur": {"p19_hr_check": true}}
    result.rule_id == "jdg.p19_hr_swiadczenia_innovations.family_benefits_audit"
    result.swiadczenia["800_plus_pln"] == 800
}

test_family_benefit_calculator_2children {
    result := data.jdg.p19_hr_swiadczenia_innovations.family_benefit_calculator with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "family": {"children": 2}}
    result["800_plus_monthly_pln"] == 1600
    result._routing == "TRIAGE_QUEUE"
}

test_family_benefit_calculator_nochildren {
    result := data.jdg.p19_hr_swiadczenia_innovations.family_benefit_calculator with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "family": {"children": 0}}
    result["800_plus_monthly_pln"] == 0
    result._routing == ""
}

test_force_majeure_insurance_audit {
    result := data.jdg.p19_hr_swiadczenia_innovations.force_majeure_insurance_audit with input as {"jdg_entrepreneur": {"p19_hr_check": true}}
    result.sila_wyzsza.max_days_per_year == 2
    result.sila_wyzsza.pay_pct == 50
}

test_force_majeure_calculator_within {
    result := data.jdg.p19_hr_swiadczenia_innovations.force_majeure_calculator with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "force_majeure": {"days_used": 2, "gross_pln": 6000}}
    result.within_limit == true
    result.pay_for_force_majeure_pln == 3000
    result._routing == ""
}

test_force_majeure_calculator_exceeded {
    result := data.jdg.p19_hr_swiadczenia_innovations.force_majeure_calculator with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "force_majeure": {"days_used": 3, "gross_pln": 6000}}
    result.within_limit == false
    result._routing == "TRIAGE_QUEUE"
}

test_ppk_tracker_notenrolled {
    result := data.jdg.p19_hr_swiadczenia_innovations.ppk_tracker with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"ppk_enrolled": false}}
    result.status == "PPK WYMAGA ZGŁOSZENIA — obowiązek pracodawcy (po 90 dniach)"
    result._routing == "TRIAGE_QUEUE"
}

test_ppk_pfron_solidarity_audit {
    result := data.jdg.p19_hr_swiadczenia_innovations.ppk_pfron_solidarity_audit with input as {"jdg_entrepreneur": {"p19_hr_check": true}}
    result.rule_id == "jdg.p19_hr_swiadczenia_innovations.ppk_pfron_solidarity_audit"
    result.pfron.threshold_employees == 25
}

test_pfron_contributor_over {
    result := data.jdg.p19_hr_swiadczenia_innovations.pfron_contributor with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"employees": 30}}
    result.obligation == "PFRON OBOWIĄZKOWY — ≥25 pracowników, opłata za etaty"
    result._routing == "TRIAGE_QUEUE"
}

test_pfron_contributor_below {
    result := data.jdg.p19_hr_swiadczenia_innovations.pfron_contributor with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"employees": 10}}
    result.obligation == "PFRON FAKULTATYWNY — poniżej 25 pracowników"
    result._routing == ""
}

test_solidarity_calculator {
    result := data.jdg.p19_hr_swiadczenia_innovations.solidarity_calculator with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "solidarity": {"gross_base_pln": 100000, "applies": true}}
    result.monthly_contribution_pln == 500
    result.status == "SKŁADKA SOLIDARNOŚCIOWA 0.5% — naliczana"
}

test_severance_calculator_2_8 {
    result := data.jdg.p19_hr_swiadczenia_innovations.severance_calculator with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"years_employed": 5, "monthly_salary_pln": 6000}}
    result.severance_months == 2
    result.severance_pln == 12000
}

test_payments_procurement_advertising_audit {
    result := data.jdg.p19_hr_swiadczenia_innovations.payments_procurement_advertising_audit with input as {"jdg_entrepreneur": {"p19_hr_check": true}}
    result.rule_id == "jdg.p19_hr_swiadczenia_innovations.payments_procurement_advertising_audit"
    result.platnosci.wynagrodzenia == "do 10. dnia następnego miesiąca (art. 85 KP)"
}

test_payroll_payments_monitor_late {
    result := data.jdg.p19_hr_swiadczenia_innovations.payroll_payments_monitor with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"payday": 12}}
    result.on_time == false
}

test_advertising_classifier_reprezentacja {
    result := data.jdg.p19_hr_swiadczenia_innovations.advertising_classifier with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "advertising": {"expense_desc": "reprezentacja — spotkanie z klientem"}}
    result.classified_as == "REPREZENTACJA — nie jest KUP (art. 23 ust. 1 pkt 23 u.PIT)"
}

test_hr_pipeline_snapshot {
    result := data.jdg.p19_hr_swiadczenia_innovations.hr_pipeline_snapshot with input as {"jdg_entrepreneur": {"p19_hr_check": true}}
    result.hot_reload == true
    result.auto_aktualizacja.placa_minimalna == "monitor obwieszczeń MPiPS — auto-aktualizacja progów płac"
}

test_p19_main_decide {
    result := data.jdg.p19_hr_swiadczenia_innovations.decide with input as {"jdg_entrepreneur": {"p19_hr_check": true}}
    result.rule_id == "jdg.p19_hr_swiadczenia_innovations.report"
    result.employer.rule_id == "jdg.p19_hr_swiadczenia_innovations.employer_audit"
    result.family.rule_id == "jdg.p19_hr_swiadczenia_innovations.family_benefits_audit"
}

test_p19_default_no_match {
    result := data.jdg.p19_hr_swiadczenia_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.rule_id == "jdg.p19_hr_swiadczenia_innovations.no_match"
}

# ── Mapa drogowa R19 (P0/P1/P2) — 7 reguł ─────────────────────────────────────
test_roadmap_payroll_end_to_end_module_ok {
    result := data.jdg.p19_hr_swiadczenia_innovations.payroll_end_to_end_module with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"payroll_steps_completed": 7}}
    result.rule_id == "jdg.p19_hr_swiadczenia_innovations.payroll_end_to_end_module"
    result.module_status == "MODUŁ PŁAC E2E KOMPLETNY — brutto→netto→ZUS→PIT-4→wypłata"
    result._routing == ""
}

test_roadmap_payroll_end_to_end_module_incomplete {
    result := data.jdg.p19_hr_swiadczenia_innovations.payroll_end_to_end_module with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"payroll_steps_completed": 5}}
    result._routing == "TRIAGE_QUEUE"
    result.module_status == "MODUŁ PŁAC NIEKOMPLETNY — 5/7 kroków"
}

test_roadmap_platnik_zus_ok {
    result := data.jdg.p19_hr_swiadczenia_innovations.platnik_zus_integration with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"platnik_import_ok": true, "platnik_export_ok": true}}
    result._routing == ""
    result.integration_status == "PŁATNIK ZUS ZINTEGROWANY — import + eksport list płac OK"
}

test_roadmap_platnik_zus_missing {
    result := data.jdg.p19_hr_swiadczenia_innovations.platnik_zus_integration with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"platnik_import_ok": false, "platnik_export_ok": true}}
    result._routing == "TRIAGE_QUEUE"
}

test_roadmap_family_benefits_panel_ok {
    result := data.jdg.p19_hr_swiadczenia_innovations.family_benefits_panel with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "family": {"applications_total": 3, "auto_applications": 3}}
    result._routing == ""
    result.panel_status == "PANEL ŚWIADCZEŃ — WSZYSTKIE WNIOSKI AUTOMATYCZNE (ZUS/MPiPS)"
}

test_roadmap_family_benefits_panel_pending {
    result := data.jdg.p19_hr_swiadczenia_innovations.family_benefits_panel with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "family": {"applications_total": 3, "auto_applications": 1}}
    result._routing == "TRIAGE_QUEUE"
}

test_roadmap_salary_tax_optimized_pit2 {
    result := data.jdg.p19_hr_swiadczenia_innovations.salary_calculator_tax_optimized with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"gross_pln": 6000, "annual_income_pln": 90000, "pit2_applied": true}}
    result.tax_status == "PIT-2 ULGA ZASTOSOWANA — 300 zł/mies. (art. 31c u.PIT)"
    result.net_pln > 0
}

test_roadmap_salary_tax_optimized_tax_free {
    result := data.jdg.p19_hr_swiadczenia_innovations.salary_calculator_tax_optimized with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"gross_pln": 2000, "annual_income_pln": 24000, "pit2_applied": true}}
    result.tax_free_amount_annual_pln == 30000
    result.tax_status == "KWOTA WOLNA 30 000 zł — PIT 0 zł (art. 27 ust. 1 u.PIT)"
}

test_roadmap_ppk_auto_ok {
    result := data.jdg.p19_hr_swiadczenia_innovations.ppk_auto_contribution_tracker with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"gross_pln": 6000, "ppk_auto_contributions": true}}
    result.employee_contribution_pln == 120
    result.employer_contribution_pln == 90
    result._routing == ""
}

test_roadmap_ppk_auto_off {
    result := data.jdg.p19_hr_swiadczenia_innovations.ppk_auto_contribution_tracker with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "hr": {"gross_pln": 6000, "ppk_auto_contributions": false}}
    result._routing == "TRIAGE_QUEUE"
    result.status == "PPK — WPŁATY WYMAGAJĄ URUCHOMIENIA AUTOMATYZACJI"
}

test_roadmap_hr_dashboard_pending {
    result := data.jdg.p19_hr_swiadczenia_innovations.hr_dashboard_ui with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "dashboard": {"leave_pending": 2, "payroll_pending": 1, "pfron_obligation": true}}
    result.pending_items == 4
    result._routing == "TRIAGE_QUEUE"
}

test_roadmap_hr_dashboard_clean {
    result := data.jdg.p19_hr_swiadczenia_innovations.hr_dashboard_ui with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "dashboard": {}}
    result.pending_items == 0
    result._routing == ""
}

test_roadmap_ewnioski_ok {
    result := data.jdg.p19_hr_swiadczenia_innovations.employee_ewnioski_workflow with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "ewnioski": {"applications": 2, "auto_approved": 2}}
    result._routing == ""
    result.status == "e-WNIOSKI — auto-akceptacja 100% (urlop, siła wyższa)"
}

test_roadmap_ewnioski_pending {
    result := data.jdg.p19_hr_swiadczenia_innovations.employee_ewnioski_workflow with input as {"jdg_entrepreneur": {"p19_hr_check": true}, "ewnioski": {"applications": 2, "auto_approved": 1}}
    result._routing == "TRIAGE_QUEUE"
    result.status == "e-WNIOSKI — 1/2 zaakceptowanych automatycznie"
}

test_p19_roadmap_decide {
    result := data.jdg.p19_hr_swiadczenia_innovations.decide with input as {"jdg_entrepreneur": {"p19_hr_check": true}}
    result.roadmap.payroll_end_to_end_module.rule_id == "jdg.p19_hr_swiadczenia_innovations.payroll_end_to_end_module"
    result.roadmap.platnik_zus_integration.rule_id == "jdg.p19_hr_swiadczenia_innovations.platnik_zus_integration"
    result.roadmap.family_benefits_panel.rule_id == "jdg.p19_hr_swiadczenia_innovations.family_benefits_panel"
    result.roadmap.salary_calculator_tax_optimized.rule_id == "jdg.p19_hr_swiadczenia_innovations.salary_calculator_tax_optimized"
    result.roadmap.ppk_auto_contribution_tracker.rule_id == "jdg.p19_hr_swiadczenia_innovations.ppk_auto_contribution_tracker"
    result.roadmap.hr_dashboard_ui.rule_id == "jdg.p19_hr_swiadczenia_innovations.hr_dashboard_ui"
    result.roadmap.employee_ewnioski_workflow.rule_id == "jdg.p19_hr_swiadczenia_innovations.employee_ewnioski_workflow"
}
