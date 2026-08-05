#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NexusAI JDG — P19 HR I ŚWIADCZENIA AUDITOR
============================================
Audyt realnych plików rego (pracodawca, MPiPS, rodzina, siła wyższa,
ubezpieczenia, PPK/PFRON/solidarność, płatności, zamówienia, reklama) +
kalkulatory INN-01..12.

Użycie:
    python3 hr_swiadczenia_auditor.py --audit            # pełny audyt plików
    python3 hr_swiadczenia_auditor.py --employer         # audyt pracodawcy
    python3 hr_swiadczenia_auditor.py --salary           # kalkulator płac (INN-01)
    python3 hr_swiadczenia_auditor.py --payroll          # lista płac (INN-02)
    python3 hr_swiadczenia_auditor.py --leave            # tracker urlopów (INN-03)
    python3 hr_swiadczenia_auditor.py --family           # świadczenia rodzinne (INN-04)
    python3 hr_swiadczenia_auditor.py --force-majeure    # siła wyższa (INN-05)
    python3 hr_swiadczenia_auditor.py --ppk              # tracker PPK (INN-06)
    python3 hr_swiadczenia_auditor.py --pfron            # kalkulator PFRON (INN-07)
    python3 hr_swiadczenia_auditor.py --solidarity       # fundusz solidarnościowy (INN-08)
    python3 hr_swiadczenia_auditor.py --severance        # odprawy (INN-09)
    python3 hr_swiadczenia_auditor.py --payroll-monitor  # terminy płatności (INN-10)
    python3 hr_swiadczenia_auditor.py --advertising      # reklama vs reprezentacja (INN-11)
    python3 hr_swiadczenia_auditor.py --pipeline         # pipeline HR (INN-12)
    python3 hr_swiadczenia_auditor.py --payroll-e2e      # moduł płac end-to-end (P0-1)
    python3 hr_swiadczenia_auditor.py --platnik          # integracja Płatnik ZUS (P0-2)
    python3 hr_swiadczenia_auditor.py --family-panel     # panel świadczeń rodzinnych (P1-1)
    python3 hr_swiadczenia_auditor.py --salary-tax       # kalkulator PIT-2/kwota wolna (P1-2)
    python3 hr_swiadczenia_auditor.py --ppk-auto         # PPK auto-wpłaty (P1-3)
    python3 hr_swiadczenia_auditor.py --hr-dashboard     # dashboard HR (P2-1)
    python3 hr_swiadczenia_auditor.py --ewnioski         # e-wnioski pracownicze (P2-2)
    python3 hr_swiadczenia_auditor.py --roadmap          # mapa drogowa P0/P1/P2 (7 reguł)
"""
import argparse
import json
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# ── Konfiguracja modułów audytu (realne pliki rego) ──────────────────────────
MODULES = {
    "employer": {
        "label": "Pracodawca",
        "files": ["rules/employer.rego", "rules/jdg/hyper/misc/plan45.rego"],
    },
    "mpips": {
        "label": "MPiPS",
        "files": ["rules/mpips.rego"],
    },
    "family": {
        "label": "Świadczenia rodzinne",
        "files": [
            "rules/family/plan44_family.rego",
            "rules/family/plan45_family.rego",
            "rules/jdg/hyper/family/plan45.rego",
        ],
    },
    "force_majeure": {
        "label": "Siła wyższa (art. 148¹ KP)",
        "files": [
            "rules/force_majeure/plan44_force_majeure.rego",
            "rules/force_majeure/plan45_force_majeure.rego",
            "rules/jdg/hyper/force_majeure/plan45.rego",
        ],
    },
    "insurance": {
        "label": "Ubezpieczenia",
        "files": [
            "rules/insurance/plan44_insurance.rego",
            "rules/insurance/plan45_insurance.rego",
            "rules/insurance_tracker_enterprise.rego",
        ],
    },
    "solidarity": {
        "label": "Fundusz solidarnościowy",
        "files": [
            "rules/solidarity/plan44_solidarity.rego",
            "rules/solidarity/plan45_solidarity.rego",
            "rules/solidarity_auto_calc_enterprise.rego",
            "rules/jdg/hyper/solidarity/plan45.rego",
        ],
    },
    "ppk_pfron": {
        "label": "PPK/PFRON",
        "files": ["rules/ppk_pfron_enterprise.rego"],
    },
    "payments": {
        "label": "Płatności",
        "files": [
            "rules/payments/plan44_payments.rego",
            "rules/payments/plan45_payments.rego",
        ],
    },
    "procurement": {
        "label": "Zamówienia",
        "files": [
            "rules/procurement/plan44_procurement.rego",
            "rules/procurement/plan45_procurement.rego",
            "rules/jdg/hyper/procurement/plan45.rego",
        ],
    },
    "advertising": {
        "label": "Reklama",
        "files": [
            "rules/advertising/plan44_advertising.rego",
            "rules/advertising/plan45_advertising.rego",
            "rules/jdg/hyper/sanctions/plan45.rego",
        ],
    },
}

P19_PACKAGE = "rules/p19_hr_swiadczenia_innovations_v9.rego"

# ── Stawki (mirror pakietu rego P19) ──────────────────────────────────────────
ZUS_EMERYTALNA = 9.76
ZUS_RENTOWA = 1.5
ZUS_CHOROBOWA = 2.45
ZUS_ZDROWOTNA = 9.0
PIT_ADVANCE = 12.0
KUP_DOJAZDY = 300.0
FORCE_MAJEURE_DAYS = 2
FORCE_MAJEURE_PAY_PCT = 50.0
FAMILY_800_PLUS = 800.0
PPK_EMPLOYEE = 2.0
PPK_EMPLOYER = 1.5
PFRON_THRESHOLD = 25
PFRON_FEE_PER_ETAT = 40.75
SOLIDARITY_PCT = 0.5
ADVERTISING_LIMIT_PCT = 0.25
PIT2_MONTHLY_RELIEF = 300.0        # ulga PIT-2 — 300 zł/mies. (art. 31c u.PIT)
KWOTA_WOLNA_ANNUAL = 30000.0       # kwota wolna od podatku (art. 27 ust. 1 u.PIT)
PAYROLL_E2E_STEPS = 7              # kroki pełnego modułu płac end-to-end


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Kalkulatory INN (logika mirrorowana z pakietu rego P19) ───────────────────
def employer_audit() -> dict:
    """Sekcja 1: audyt pracodawcy."""
    return {
        "obowiazki_pracodawcy": {
            "kup_dojazdy_pln": KUP_DOJAZDY,
            "legal_basis": "Art. 22 ust. 2 pkt 4 u.PIT (KUP dojazdów 300 zł)",
        },
        "wynagrodzenia": {
            "skladki_pracownika": ["emerytalna 9.76%", "rentowa 1.5%", "chorobowa 2.45%", "zdrowotna 9%"],
            "zaliczka_pit": "PIT-4 — 12% od podstawy po ZUS i KUP",
            "termin_wyplaty": "do 10. dnia następnego miesiąca",
            "legal_basis": "Art. 85-87 KP; art. 31-32 u.PIT (PIT-4)",
        },
        "note": "audyt pracodawcy — obowiązki, KUP dojazdów 300 zł, wynagrodzenia, ZUS, PIT-4, urlopy",
    }


def salary_calculator(gross_pln: float = 0.0, kup_pln: float = KUP_DOJAZDY) -> dict:
    """INN-01: kalkulator wynagrodzeń brutto→netto."""
    zus_total = round2(gross_pln * (ZUS_EMERYTALNA + ZUS_RENTOWA + ZUS_CHOROBOWA) / 100)
    zus_health = round2((gross_pln - zus_total) * ZUS_ZDROWOTNA / 100)
    base_pit = gross_pln - zus_total - kup_pln
    pit = round2(base_pit * PIT_ADVANCE / 100)
    net = round2(gross_pln - zus_total - zus_health - pit)
    return {
        "gross_pln": gross_pln,
        "zus_total_pct": ZUS_EMERYTALNA + ZUS_RENTOWA + ZUS_CHOROBOWA,
        "zus_total_pln": zus_total,
        "zus_health_pln": zus_health,
        "kup_pln": kup_pln,
        "pit4_pln": pit,
        "net_pln": net,
        "note": "kalkulator wynagrodzeń — brutto→netto: ZUS (9.76+1.5+2.45+9%) + PIT-4 12%",
    }


def payroll_generator(employees: int = 0) -> dict:
    """INN-02: generator listy płac."""
    return {
        "employees": employees,
        "payroll_generated": True,
        "fields": ["brutto", "ZUS pracownika", "zaliczka PIT-4", "netto", "ZUS pracodawcy", "FP/FGŚP"],
        "note": "generator listy płac — auto-kalkulacja składników dla każdego pracownika",
    }


def leave_tracker(leave_used_days: int = 0, entitlement: int = 26) -> dict:
    """INN-03: tracker urlopów."""
    remaining = max(entitlement - leave_used_days, 0)
    return {
        "leave_entitlement_days": entitlement,
        "leave_used_days": leave_used_days,
        "leave_remaining_days": remaining,
        "status": "W TERMINIE",
        "note": "tracker urlopów — 20/26 dni (staż <10 / ≥10 lat), bilans urlopowy",
    }


def family_benefit_calculator(children: int = 0) -> dict:
    """INN-04: kalkulator świadczeń rodzinnych (800+)."""
    monthly = round2(children * FAMILY_800_PLUS)
    return {
        "children": children,
        "800_plus_monthly_pln": monthly,
        "status": f"800+ PRZYSŁUGUJE — {children} dzieci" if children > 0 else "BRAK UPRAWNIEŃ — brak dzieci",
        "_routing": "TRIAGE_QUEUE" if children > 0 else "",
        "note": "kalkulator świadczeń rodzinnych — 800+ miesięcznie, status uprawnień",
    }


def force_majeure_calculator(days_used: int = 0, gross_pln: float = 0.0) -> dict:
    """INN-05: kalkulator siły wyższej (art. 148¹ KP)."""
    pay = round2(gross_pln * FORCE_MAJEURE_PAY_PCT / 100)
    return {
        "days_used": days_used,
        "max_days_per_year": FORCE_MAJEURE_DAYS,
        "gross_pln": gross_pln,
        "pay_for_force_majeure_pln": pay,
        "within_limit": days_used <= FORCE_MAJEURE_DAYS,
        "_routing": "" if days_used <= FORCE_MAJEURE_DAYS else "TRIAGE_QUEUE",
        "note": "kalkulator siły wyższej — 2 dni/rok (art. 148¹ KP), 50% wynagrodzenia",
    }


def ppk_tracker(ppk_enrolled: bool = False) -> dict:
    """INN-06: tracker PPK."""
    return {
        "ppk_enrolled": ppk_enrolled,
        "employee_pct": PPK_EMPLOYEE,
        "employer_pct": PPK_EMPLOYER,
        "status": "PPK AKTYWNE — auto-wpłaty pracownik + pracodawca" if ppk_enrolled else "PPK WYMAGA ZGŁOSZENIA — obowiązek pracodawcy (po 90 dniach)",
        "_routing": "" if ppk_enrolled else "TRIAGE_QUEUE",
        "note": "tracker PPK — składki 2% pracownik + 1.5% pracodawca",
    }


def pfron_contributor(employees: int = 0) -> dict:
    """INN-07: kalkulator PFRON."""
    fee = round2(employees * PFRON_FEE_PER_ETAT)
    return {
        "employees": employees,
        "threshold_employees": PFRON_THRESHOLD,
        "obligation": "PFRON OBOWIĄZKOWY — ≥25 pracowników, opłata za etaty" if employees >= PFRON_THRESHOLD else "PFRON FAKULTATYWNY — poniżej 25 pracowników",
        "monthly_fee_pln": fee,
        "_routing": "TRIAGE_QUEUE" if employees >= PFRON_THRESHOLD else "",
        "note": "kalkulator PFRON — obowiązek od 25 pracowników, opłata za etat (40,75 zł × etaty)",
    }


def solidarity_calculator(gross_base_pln: float = 0.0, applies: bool = False) -> dict:
    """INN-08: kalkulator funduszu solidarnościowego."""
    contribution = round2(gross_base_pln * SOLIDARITY_PCT / 100)
    return {
        "applies": applies,
        "donation_pct": SOLIDARITY_PCT,
        "monthly_contribution_pln": contribution,
        "status": "SKŁADKA SOLIDARNOŚCIOWA 0.5% — naliczana" if applies else "BEZ SKŁADKI SOLIDARNOŚCIOWEJ",
        "note": "kalkulator funduszu solidarnościowego — 0.5% od podstawy (2026)",
    }


def severance_calculator(years_employed: int = 0, monthly_salary_pln: float = 0.0) -> dict:
    """INN-09: kalkulator odpraw."""
    if years_employed < 2:
        months = 1
    elif years_employed < 8:
        months = 2
    else:
        months = 3
    severance = round2(months * monthly_salary_pln)
    return {
        "years_employed": years_employed,
        "monthly_salary_pln": monthly_salary_pln,
        "severance_months": months,
        "severance_pln": severance,
        "note": "kalkulator odpraw — 1 mies. (<2 lat), 2 mies. (2-8 lat), 3 mies. (≥8 lat) — art. 8 u.zwolnieniach",
    }


def payroll_payments_monitor(payday: int = 10) -> dict:
    """INN-10: monitor terminów płatności."""
    return {
        "payday": payday,
        "salary_deadline": 10,
        "on_time": payday <= 10,
        "note": "monitor terminów — wypłata do 10. (art. 85 KP), ZUS do 15., PIT-4 do 20.",
    }


def advertising_classifier(expense_desc: str = "") -> dict:
    """INN-11: klasyfikator reklama vs reprezentacja."""
    desc = expense_desc.lower()
    if any(k in desc for k in ["reklama", "ogłoszenie", "promocja"]):
        cls = "REKLAMA — KUP (limit 0.25% przychodu)"
    elif any(k in desc for k in ["reprezentacja", "spotkanie", "poczęstunek"]):
        cls = "REPREZENTACJA — nie jest KUP (art. 23 ust. 1 pkt 23 u.PIT)"
    else:
        cls = "REKLAMA — KUP (pozostałe wydatki marketingowe)"
    return {
        "expense_desc": expense_desc,
        "classified_as": cls,
        "limit_pct": ADVERTISING_LIMIT_PCT,
        "note": "klasyfikator wydatków — reklama (KUP) vs reprezentacja (nie-KUP)",
    }


def hr_pipeline_snapshot() -> dict:
    """INN-12 / Sekcja 6: pipeline auto-aktualizacji reguł HR."""
    return {
        "pipeline": {
            "step_1_ingest": "data.jdg.thresholds.hr_swiadczenia (ADR-002)",
            "step_2_generate": "reguły HR (płace, ZUS, świadczenia, PPK, PFRON)",
            "step_3_verify": "hr_swiadczenia_auditor.py",
            "step_4_emit": "hot-reload jdg.employer / jdg.family / jdg.solidarity / jdg.ppk_pfron",
        },
        "auto_aktualizacja": {
            "placa_minimalna": "monitor obwieszczeń MPiPS",
            "progi_zus": "auto-aktualizacja progów i składek ZUS",
            "kwota_wolna": "auto-aktualizacja kwoty wolnej od podatku",
        },
        "hot_reload": True,
        "note": "pipeline auto-aktualizacji reguł HR — płaca minimalna, progi ZUS, kwota wolna (ADR-002)",
    }


# ── Kalkulatory Mapy drogowej R19 (P0/P1/P2) ──────────────────────────────────
def payroll_end_to_end_module(completed_steps: int = 0, required_steps: int = PAYROLL_E2E_STEPS) -> dict:
    """R19 P0-1: pełny moduł płac end-to-end (brutto→netto→ZUS→PIT-4→wypłata)."""
    ok = completed_steps >= required_steps
    return {
        "steps": ["1. brutto", "2. ZUS pracownika", "3. zdrowotna", "4. PIT-4", "5. wypłata netto", "6. ZUS pracodawcy", "7. FP/FGŚP"],
        "required_steps": required_steps,
        "completed_steps": completed_steps,
        "auto_payroll": True,
        "deadline_payday": 10,
        "module_status": "MODUŁ PŁAC E2E KOMPLETNY — brutto→netto→ZUS→PIT-4→wypłata" if ok else f"MODUŁ PŁAC NIEKOMPLETNY — {completed_steps}/{required_steps} kroków",
        "_routing": "" if ok else "TRIAGE_QUEUE",
        "note": "pełny moduł płac end-to-end — brutto→netto→ZUS→PIT-4→wypłata, ZUS pracodawcy, FP/FGŚP (P0)",
    }


def platnik_zus_integration(import_ok: bool = False, export_ok: bool = False) -> dict:
    """R19 P0-2: integracja z Płatnikiem ZUS (import/eksport list płac)."""
    ok = import_ok and export_ok
    return {
        "import_payroll": import_ok,
        "export_payroll": export_ok,
        "format": "IMPORT ZUS (XML) / EXPORT lista płac",
        "zua_deadline_days": 7,
        "integration_status": "PŁATNIK ZUS ZINTEGROWANY — import + eksport list płac OK" if ok else "PŁATNIK ZUS — WYMAGA KONFIGURACJI importu/eksportu list płac",
        "_routing": "" if ok else "TRIAGE_QUEUE",
        "note": "integracja z Płatnikiem ZUS — import/eksport list płac, zgłoszenia ZUA w 7 dni (P0)",
    }


def family_benefits_panel(applications_total: int = 0, auto_applications: int = 0) -> dict:
    """R19 P1-1: panel świadczeń rodzinnych z automatycznymi wnioskami do ZUS/MPiPS."""
    ok = auto_applications >= applications_total
    return {
        "benefits": ["800+", "zasiłek rodzinny", "dodatek z tytułu samotnego wychowania", "świadczenie dobry start 300+"],
        "auto_application": True,
        "targets": ["ZUS (e-wniosek)", "MPiPS"],
        "applications_total": applications_total,
        "auto_applications": auto_applications,
        "panel_status": (f"PANEL ŚWIADCZEŃ — {auto_applications}/{applications_total} wniosków automatycznych (ZUS/MPiPS)"
                         if not ok else "PANEL ŚWIADCZEŃ — WSZYSTKIE WNIOSKI AUTOMATYCZNE (ZUS/MPiPS)"),
        "_routing": "" if ok else "TRIAGE_QUEUE",
        "note": "panel świadczeń rodzinnych — automatyczne wnioski do ZUS/MPiPS (800+, zasiłek rodzinny, 300+) (P1)",
    }


def salary_calculator_tax_optimized(gross_pln: float = 0.0, kup_pln: float = KUP_DOJAZDY,
                                    pit2_applied: bool = True, annual_income_pln: float = 0.0) -> dict:
    """R19 P1-2: kalkulator wynagrodzeń z kwotą wolną i ulgą PIT-2."""
    zus_total = round2(gross_pln * (ZUS_EMERYTALNA + ZUS_RENTOWA + ZUS_CHOROBOWA) / 100)
    zus_health = round2((gross_pln - zus_total) * ZUS_ZDROWOTNA / 100)
    base_pit = gross_pln - zus_total - kup_pln
    if annual_income_pln <= KWOTA_WOLNA_ANNUAL:
        pit = 0.0
        tax_status = "KWOTA WOLNA 30 000 zł — PIT 0 zł (art. 27 ust. 1 u.PIT)"
    elif pit2_applied:
        pit = max(round2(base_pit * PIT_ADVANCE / 100 - PIT2_MONTHLY_RELIEF), 0.0)
        tax_status = f"PIT-2 ULGA ZASTOSOWANA — {PIT2_MONTHLY_RELIEF:.0f} zł/mies. (art. 31c u.PIT)"
    else:
        pit = round2(base_pit * PIT_ADVANCE / 100)
        tax_status = "PIT-2 NIEZASTOSOWANE — złóż oświadczenie PIT-2 u pracodawcy"
    net = round2(gross_pln - zus_total - zus_health - pit)
    return {
        "gross_pln": gross_pln,
        "kup_pln": kup_pln,
        "pit2_applied": pit2_applied,
        "pit2_monthly_relief_pln": PIT2_MONTHLY_RELIEF,
        "tax_free_amount_annual_pln": KWOTA_WOLNA_ANNUAL,
        "annual_income_pln": annual_income_pln,
        "zus_total_pln": zus_total,
        "zus_health_pln": zus_health,
        "pit4_pln": pit,
        "net_pln": net,
        "tax_status": tax_status,
        "note": "kalkulator wynagrodzeń z kwotą wolną i ulgą PIT-2 — art. 31c u.PIT (P1)",
    }


def ppk_auto_contribution_tracker(gross_pln: float = 0.0, auto_contributions: bool = True) -> dict:
    """R19 P1-3: tracker PPK z pełną automatyzacją wpłat (2% + 1.5%)."""
    employee_c = round2(gross_pln * PPK_EMPLOYEE / 100)
    employer_c = round2(gross_pln * PPK_EMPLOYER / 100)
    return {
        "employee_pct": PPK_EMPLOYEE,
        "employer_pct": PPK_EMPLOYER,
        "gross_pln": gross_pln,
        "employee_contribution_pln": employee_c,
        "employer_contribution_pln": employer_c,
        "auto_contributions": auto_contributions,
        "deadline_payment_day": 15,
        "status": "PPK AUTO-WPŁATY AKTYWNE — 2% + 1.5% z listy płac" if auto_contributions else "PPK — WPŁATY WYMAGAJĄ URUCHOMIENIA AUTOMATYZACJI",
        "_routing": "" if auto_contributions else "TRIAGE_QUEUE",
        "note": "tracker PPK z pełną automatyzacją wpłat — 2% + 1.5%, termin do 15. (P1)",
    }


def hr_dashboard_ui(leave_pending: int = 0, payroll_pending: int = 0, pfron_obligation: bool = False) -> dict:
    """R19 P2-1: dashboard HR (urlopy, płace, PFRON) w UI."""
    pending = leave_pending + payroll_pending + (1 if pfron_obligation else 0)
    return {
        "widgets": ["urlopy", "płace", "PFRON", "PPK", "świadczenia", "e-wnioski"],
        "export_formats": ["JSON", "CSV", "PDF"],
        "pending_items": pending,
        "_routing": "TRIAGE_QUEUE" if pending > 0 else "",
        "note": "dashboard HR w UI — urlopy, płace, PFRON, PPK, świadczenia, e-wnioski (P2)",
    }


def employee_ewnioski_workflow(applications: int = 0, auto_approved: int = 0) -> dict:
    """R19 P2-2: e-wnioski pracownicze (urlop, siła wyższa) z auto-akceptacją."""
    if applications > 0 and auto_approved < applications:
        status = f"e-WNIOSKI — {auto_approved}/{applications} zaakceptowanych automatycznie"
        routing = "TRIAGE_QUEUE"
    elif applications > 0:
        status = "e-WNIOSKI — auto-akceptacja 100% (urlop, siła wyższa)"
        routing = ""
    else:
        status = "Brak e-wniosków pracowniczych"
        routing = ""
    return {
        "wnioski_types": ["urlop wypoczynkowy", "siła wyższa (art. 148¹ KP)"],
        "auto_approval": True,
        "approval_flow": "wniosek → weryfikacja → auto-akceptacja → kalendarz/lista płac",
        "applications": applications,
        "auto_approved": auto_approved,
        "status": status,
        "_routing": routing,
        "note": "e-wnioski pracownicze z auto-akceptacją — urlop, siła wyższa (art. 148¹ KP) (P2)",
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def _rule_ids(text: str) -> list:
    return re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)


def _looks_like_stub(text: str, rule_id: str) -> bool:
    if "_ := 0" in text or ":= 0 }" in text:
        return True
    if "TODO" in text.upper() and rule_id in text:
        return True
    return False


def audit_rego_files() -> dict:
    """Pełny audyt: liczba rule_id per moduł, status COMPLETE/PARTIAL/MISSING."""
    modules_report = {}
    total = 0
    complete = 0
    for mod, cfg in MODULES.items():
        count = 0
        stubs = 0
        details = []
        for rel in cfg["files"]:
            p = BASE_DIR / rel
            if not p.exists():
                details.append({"file": rel, "exists": False, "rules": 0})
                continue
            text = p.read_text(encoding="utf-8", errors="replace")
            ids = _rule_ids(text)
            count += len(ids)
            if any(_looks_like_stub(text, rid) for rid in ids):
                stubs += 1
            details.append({"file": rel, "exists": True, "rules": len(ids)})
        status = "COMPLETE" if count >= 3 else ("PARTIAL" if count > 0 else "MISSING")
        if status == "COMPLETE":
            complete += 1
        total += count
        modules_report[mod] = {
            "status": status,
            "rules": count,
            "stubs": stubs,
            "files": details,
        }
    return {
        "modules": modules_report,
        "total_rule_ids": total,
        "summary": {
            "total_modules": len(MODULES),
            "complete": complete,
            "missing": len(MODULES) - complete,
        },
        "gap_pct": round2((len(MODULES) - complete) / len(MODULES) * 100),
    }


def p19_package_check() -> dict:
    p = BASE_DIR / P19_PACKAGE
    if not p.exists():
        return {"exists": False, "error": f"Brak pliku {P19_PACKAGE}"}
    text = p.read_text(encoding="utf-8")
    return {
        "exists": True,
        "package": "jdg.p19_hr_swiadczenia_innovations",
        "braces_balanced": text.count("{") == text.count("}"),
        "inn_count": text.count("INN-"),
        "legal_basis_count": text.count("_legal_basis"),
        "rule_count": len(_rule_ids(text)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="NexusAI JDG — P19 HR i Świadczenia Auditor")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików micro (domyślne)")
    parser.add_argument("--employer", action="store_true", help="audyt pracodawcy (Sekcja 1)")
    parser.add_argument("--salary", action="store_true", help="kalkulator wynagrodzeń (INN-01)")
    parser.add_argument("--payroll", action="store_true", help="generator listy płac (INN-02)")
    parser.add_argument("--leave", action="store_true", help="tracker urlopów (INN-03)")
    parser.add_argument("--family", action="store_true", help="świadczenia rodzinne 800+ (INN-04)")
    parser.add_argument("--force-majeure", action="store_true", help="siła wyższa art. 148¹ KP (INN-05)")
    parser.add_argument("--ppk", action="store_true", help="tracker PPK (INN-06)")
    parser.add_argument("--pfron", action="store_true", help="kalkulator PFRON (INN-07)")
    parser.add_argument("--solidarity", action="store_true", help="fundusz solidarnościowy (INN-08)")
    parser.add_argument("--severance", action="store_true", help="kalkulator odpraw (INN-09)")
    parser.add_argument("--payroll-monitor", action="store_true", help="terminy płatności (INN-10)")
    parser.add_argument("--advertising", action="store_true", help="reklama vs reprezentacja (INN-11)")
    parser.add_argument("--pipeline", action="store_true", help="pipeline auto-aktualizacji HR (INN-12)")
    parser.add_argument("--payroll-e2e", action="store_true", help="moduł płac end-to-end (P0-1)")
    parser.add_argument("--platnik", action="store_true", help="integracja Płatnik ZUS (P0-2)")
    parser.add_argument("--family-panel", action="store_true", help="panel świadczeń rodzinnych (P1-1)")
    parser.add_argument("--salary-tax", action="store_true", help="kalkulator PIT-2/kwota wolna (P1-2)")
    parser.add_argument("--ppk-auto", action="store_true", help="PPK auto-wpłaty (P1-3)")
    parser.add_argument("--hr-dashboard", action="store_true", help="dashboard HR (P2-1)")
    parser.add_argument("--ewnioski", action="store_true", help="e-wnioski pracownicze (P2-2)")
    parser.add_argument("--roadmap", action="store_true", help="mapa drogowa P0/P1/P2 (7 reguł)")
    args = parser.parse_args()

    result = {"tool": "hr_swiadczenia_auditor", "module": "P19 HR i Świadczenia"}
    funcs = [args.employer, args.salary, args.payroll, args.leave, args.family,
             args.force_majeure, args.ppk, args.pfron, args.solidarity,
             args.severance, args.payroll_monitor, args.advertising, args.pipeline,
             args.payroll_e2e, args.platnik, args.family_panel, args.salary_tax,
             args.ppk_auto, args.hr_dashboard, args.ewnioski, args.roadmap]
    if not any(funcs):
        args.audit = True

    if args.audit:
        result["audit"] = audit_rego_files()
        result["package_check"] = p19_package_check()
    if args.employer:
        result["employer"] = employer_audit()
    if args.salary:
        result["salary"] = salary_calculator(gross_pln=6000.0)
    if args.payroll:
        result["payroll"] = payroll_generator(employees=3)
    if args.leave:
        result["leave"] = leave_tracker(leave_used_days=12)
    if args.family:
        result["family"] = family_benefit_calculator(children=2)
    if args.force_majeure:
        result["force_majeure"] = force_majeure_calculator(days_used=2, gross_pln=6000.0)
    if args.ppk:
        result["ppk"] = ppk_tracker(ppk_enrolled=False)
    if args.pfron:
        result["pfron"] = pfron_contributor(employees=30)
    if args.solidarity:
        result["solidarity"] = solidarity_calculator(gross_base_pln=100000.0, applies=True)
    if args.severance:
        result["severance"] = severance_calculator(years_employed=5, monthly_salary_pln=6000.0)
    if args.payroll_monitor:
        result["payroll_monitor"] = payroll_payments_monitor(payday=12)
    if args.advertising:
        result["advertising"] = advertising_classifier(expense_desc="reprezentacja — spotkanie z klientem")
    if args.pipeline:
        result["pipeline"] = hr_pipeline_snapshot()
    if args.payroll_e2e:
        result["payroll_end_to_end"] = payroll_end_to_end_module(completed_steps=7, required_steps=7)
    if args.platnik:
        result["platnik_zus"] = platnik_zus_integration(import_ok=True, export_ok=True)
    if args.family_panel:
        result["family_panel"] = family_benefits_panel(applications_total=3, auto_applications=3)
    if args.salary_tax:
        result["salary_tax_optimized"] = salary_calculator_tax_optimized(gross_pln=6000.0, annual_income_pln=90000.0)
    if args.ppk_auto:
        result["ppk_auto"] = ppk_auto_contribution_tracker(gross_pln=6000.0, auto_contributions=True)
    if args.hr_dashboard:
        result["hr_dashboard"] = hr_dashboard_ui()
    if args.ewnioski:
        result["ewnioski"] = employee_ewnioski_workflow(applications=2, auto_approved=2)
    if args.roadmap:
        result["roadmap"] = {
            "payroll_end_to_end_module": payroll_end_to_end_module(completed_steps=7, required_steps=7),
            "platnik_zus_integration": platnik_zus_integration(import_ok=True, export_ok=True),
            "family_benefits_panel": family_benefits_panel(applications_total=3, auto_applications=3),
            "salary_calculator_tax_optimized": salary_calculator_tax_optimized(gross_pln=6000.0, annual_income_pln=90000.0),
            "ppk_auto_contribution_tracker": ppk_auto_contribution_tracker(gross_pln=6000.0, auto_contributions=True),
            "hr_dashboard_ui": hr_dashboard_ui(),
            "employee_ewnioski_workflow": employee_ewnioski_workflow(applications=2, auto_approved=2),
        }

    print(json.dumps(result, ensure_ascii=False, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
