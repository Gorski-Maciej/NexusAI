# -*- coding: utf-8 -*-
"""Testy P19 — HR i Świadczenia (NexusAI JDG)."""
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))

from hr_swiadczenia_auditor import (  # noqa: E402
    advertising_classifier,
    audit_rego_files,
    employer_audit,
    family_benefit_calculator,
    force_majeure_calculator,
    hr_pipeline_snapshot,
    leave_tracker,
    payroll_generator,
    payroll_payments_monitor,
    pfron_contributor,
    ppk_tracker,
    salary_calculator,
    severance_calculator,
    solidarity_calculator,
)


# ── Sekcja 1: Pracodawca ──────────────────────────────────────────────────────
def test_employer_audit_structure():
    res = employer_audit()
    assert res["obowiazki_pracodawcy"]["kup_dojazdy_pln"] == 300
    assert res["wynagrodzenia"]["termin_wyplaty"] == "do 10. dnia następnego miesiąca"


def test_salary_calculator_net():
    res = salary_calculator(gross_pln=6000.0)
    assert res["gross_pln"] == 6000.0
    assert res["zus_total_pln"] > 0
    assert res["pit4_pln"] > 0
    assert res["net_pln"] > 0
    assert res["net_pln"] < 6000.0


def test_salary_calculator_math():
    res = salary_calculator(gross_pln=6000.0)
    # ZUS 13.71% = 822.60; zdrowotna 9% z (6000-822.60)=465.97; PIT 12% z (6000-822.60-300)=585.29
    assert res["zus_total_pln"] == 822.6
    assert res["pit4_pln"] == 585.29
    assert res["net_pln"] == round(6000 - 822.6 - 465.97 - 585.29, 2)


def test_payroll_generator():
    res = payroll_generator(employees=3)
    assert res["payroll_generated"] is True
    assert len(res["fields"]) == 6


def test_leave_tracker():
    res = leave_tracker(leave_used_days=12)
    assert res["leave_entitlement_days"] == 26
    assert res["leave_remaining_days"] == 14


# ── Sekcja 2: Świadczenia rodzinne ────────────────────────────────────────────
def test_family_benefit_calculator_2children():
    res = family_benefit_calculator(children=2)
    assert res["800_plus_monthly_pln"] == 1600.0
    assert res["_routing"] == "TRIAGE_QUEUE"
    assert "2 dzieci" in res["status"]


def test_family_benefit_calculator_nochildren():
    res = family_benefit_calculator(children=0)
    assert res["800_plus_monthly_pln"] == 0.0
    assert res["_routing"] == ""


# ── Sekcja 3: Siła wyższa i ubezpieczenia ─────────────────────────────────────
def test_force_majeure_calculator_within():
    res = force_majeure_calculator(days_used=2, gross_pln=6000.0)
    assert res["within_limit"] is True
    assert res["pay_for_force_majeure_pln"] == 3000.0  # 50%
    assert res["_routing"] == ""


def test_force_majeure_calculator_exceeded():
    res = force_majeure_calculator(days_used=3, gross_pln=6000.0)
    assert res["within_limit"] is False
    assert res["_routing"] == "TRIAGE_QUEUE"


def test_ppk_tracker_notenrolled():
    res = ppk_tracker(ppk_enrolled=False)
    assert "PPK WYMAGA ZGŁOSZENIA" in res["status"]
    assert res["_routing"] == "TRIAGE_QUEUE"


# ── Sekcja 4: PPK/PFRON/Solidarność ───────────────────────────────────────────
def test_pfron_contributor_over():
    res = pfron_contributor(employees=30)
    assert "PFRON OBOWIĄZKOWY" in res["obligation"]
    assert res["_routing"] == "TRIAGE_QUEUE"
    assert res["monthly_fee_pln"] == 1222.5  # 30 × 40.75


def test_pfron_contributor_below():
    res = pfron_contributor(employees=10)
    assert "PFRON FAKULTATYWNY" in res["obligation"]
    assert res["_routing"] == ""


def test_solidarity_calculator():
    res = solidarity_calculator(gross_base_pln=100000.0, applies=True)
    assert res["monthly_contribution_pln"] == 500.0  # 0.5%
    assert "SKŁADKA SOLIDARNOŚCIOWA" in res["status"]


def test_severance_calculator():
    res = severance_calculator(years_employed=5, monthly_salary_pln=6000.0)
    assert res["severance_months"] == 2
    assert res["severance_pln"] == 12000.0


def test_severance_calculator_senior():
    res = severance_calculator(years_employed=10, monthly_salary_pln=6000.0)
    assert res["severance_months"] == 3
    assert res["severance_pln"] == 18000.0


# ── Sekcja 5: Płatności, zamówienia, reklama ──────────────────────────────────
def test_payroll_payments_monitor_ok():
    res = payroll_payments_monitor(payday=10)
    assert res["on_time"] is True


def test_payroll_payments_monitor_late():
    res = payroll_payments_monitor(payday=12)
    assert res["on_time"] is False


def test_advertising_classifier_reprezentacja():
    res = advertising_classifier(expense_desc="reprezentacja — spotkanie z klientem")
    assert "REPREZENTACJA" in res["classified_as"]
    assert "nie jest KUP" in res["classified_as"]


def test_advertising_classifier_reklama():
    res = advertising_classifier(expense_desc="reklama w internecie")
    assert "REKLAMA" in res["classified_as"]


# ── Sekcja 6: Pipeline HR ─────────────────────────────────────────────────────
def test_hr_pipeline_snapshot():
    res = hr_pipeline_snapshot()
    assert res["hot_reload"] is True
    assert res["auto_aktualizacja"]["placa_minimalna"] == "monitor obwieszczeń MPiPS"


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    audit = audit_rego_files()
    assert audit["total_rule_ids"] > 400, "Za mało rule_id w modułach P19"
    assert audit["summary"]["total_modules"] == 10
    assert audit["gap_pct"] == 0, "Wszystkie 10 modułów powinny być COMPLETE"


def test_audit_employer_complete():
    audit = audit_rego_files()
    assert audit["modules"]["employer"]["status"] == "COMPLETE"
    assert audit["modules"]["employer"]["rules"] >= 70  # 28 + 50


def test_audit_family_complete():
    audit = audit_rego_files()
    assert audit["modules"]["family"]["status"] == "COMPLETE"
    assert audit["modules"]["family"]["rules"] >= 80  # 11 + 52 + 22


def test_audit_payments_procurement_complete():
    audit = audit_rego_files()
    assert audit["modules"]["payments"]["status"] == "COMPLETE"
    assert audit["modules"]["procurement"]["status"] == "COMPLETE"


def test_audit_advertising_complete():
    audit = audit_rego_files()
    assert audit["modules"]["advertising"]["status"] == "COMPLETE"
    assert audit["modules"]["advertising"]["rules"] >= 95  # 10+38+52


# ── Kontrola pakietu P19 ──────────────────────────────────────────────────────
def test_p19_package_exists():
    p = BASE_DIR / "rules" / "p19_hr_swiadczenia_innovations_v9.rego"
    assert p.exists(), "Brak pliku p19_hr_swiadczenia_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p19_hr_swiadczenia_innovations" in text


def test_p19_braces_balanced():
    text = (BASE_DIR / "rules" / "p19_hr_swiadczenia_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("{") == text.count("}"), "Niezbalansowane nawiasy w pakiecie P19"


def test_p19_innovations_count():
    text = (BASE_DIR / "rules" / "p19_hr_swiadczenia_innovations_v9.rego").read_text(encoding="utf-8")
    for i in range(1, 13):
        marker = f"INN-{i:02d}"
        assert marker in text, f"Brak markera {marker} w pakiecie P19"


def test_p19_legal_basis_present():
    text = (BASE_DIR / "rules" / "p19_hr_swiadczenia_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 15, "Za mało podstaw prawnych w pakiecie P19"


def test_p19_wiring_in_main():
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p19_hr_swiadczenia_innovations" in main
    assert '"jdg.p19_hr_swiadczenia_innovations": p19_hr_swiadczenia_innovations.decide' in main
    assert "final_verdict_p19 = safe_merge(final_verdict_p18," in main


def test_p19_no_collision():
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "jdg.p19_hr_swiadczenia_innovations" in main
    text = (BASE_DIR / "rules" / "p19_hr_swiadczenia_innovations_v9.rego").read_text(encoding="utf-8")
    assert "jdg.p19_hr_swiadczenia_innovations" in text


def test_p19_tool_smoke():
    audit = audit_rego_files()
    assert audit["total_rule_ids"] > 0
    res = force_majeure_calculator(days_used=2, gross_pln=6000.0)
    assert res["pay_for_force_majeure_pln"] == 3000.0


def test_p19_tool_smoke_table():
    res = severance_calculator(years_employed=1, monthly_salary_pln=6000.0)
    assert res["severance_months"] == 1
    res2 = severance_calculator(years_employed=8, monthly_salary_pln=6000.0)
    assert res2["severance_months"] == 3


def test_p19_constants_match():
    """Progi w narzędziu (Python) zgodne z rego (KUP 300, 800+, PFRON 25, siła wyższa 2 dni/50%)."""
    assert employer_audit()["obowiazki_pracodawcy"]["kup_dojazdy_pln"] == 300
    assert family_benefit_calculator(children=1)["800_plus_monthly_pln"] == 800.0
    assert force_majeure_calculator(days_used=2, gross_pln=1000.0)["pay_for_force_majeure_pln"] == 500.0
    assert pfron_contributor(employees=24)["_routing"] == ""
    assert pfron_contributor(employees=25)["_routing"] == "TRIAGE_QUEUE"
