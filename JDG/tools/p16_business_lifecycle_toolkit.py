#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — P16 Business Lifecycle Toolkit v1.0
═══════════════════════════════════════════════════════════════════════════════

12 innowacji Enterprise P16:
  INN01: JDG Lifecycle AI Navigator — nawigacja przez 5 faz
  INN02: Business Form Auto-Selector — optymalna forma opodatkowania
  INN03: Suspension Impact Simulator — symulacja skutków zawieszenia
  INN04: Succession Readiness Score — scoring gotowości sukcesyjnej
  INN05: Gig Economy Tax Optimizer — optymalizacja dla platform
  INN06: Banking Multi-API Aggregator — PSD2/PolishAPI
  INN07: CEIDG Auto-File Engine — auto-wypełnianie CEIDG-1
  INN08: Business Health 360 Dashboard — dashboard zdrowia JDG
  INN09: Exit Strategy Multi-Scenario Simulator — scenariusze wyjścia
  INN10: Growth Phase Revenue Predictor — predykcja przychodów
  INN11: Employee Hiring Auto-Procedure — procedura zatrudnienia
  INN12: Company Transformation Engine — JDG→Sp. z o.o.→SA

Użycie:
    python JDG/tools/p16_business_lifecycle_toolkit.py all --report
    python JDG/tools/p16_business_lifecycle_toolkit.py health --months 12 --revenue 180000
    python JDG/tools/p16_business_lifecycle_toolkit.py exit --reason voluntary --inventory 50000

Autor: NexusAI
Data: 2026-07-29
"""

import argparse, json, sys
from datetime import date, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MIN_WAGE = 4666.00

# ═══ Lifecycle Phases ═══
LIFECYCLE_PHASES = {
    "PRE_START": {"range_months": (-1, 0), "zus_status": "NONE", "description": "Planowanie + rejestracja CEIDG"},
    "STARTUP_RELIEF": {"range_months": (0, 6), "zus_status": "START_RELIEF", "description": "Ulga na start 0-6 mies."},
    "STARTUP_PREFERENTIAL": {"range_months": (6, 30), "zus_status": "PREFERENTIAL", "description": "Preferencyjny ZUS 7-30 mies."},
    "EARLY_GROWTH": {"range_months": (6, 36), "zus_status": "MALY_ZUS_PLUS", "description": "Wzrost, Mały ZUS+"},
    "GROWTH": {"range_months": (12, 60), "zus_status": "STANDARD", "description": "Ekspansja, pracownicy, VAT"},
    "MATURITY": {"range_months": (30, 999), "zus_status": "STANDARD", "description": "Optymalizacja, JDG→Sp. z o.o."},
    "SUSPENDED": {"range_months": (0, 6), "zus_status": "SUSPENDED", "description": "Zawieszenie (max 6 mies.)"},
    "SUCCESSION": {"range_months": (0, 24), "zus_status": "IN_SUCCESSIO", "description": "Sukcesja po śmierci"},
    "CLOSURE": {"range_months": (0, 1), "zus_status": "NONE", "description": "Zamknięcie/likwidacja"},
}

# ═══ ZUS Relief Timeline ═══
ZUS_RELIEF = {
    "START_RELIEF": {"months": 6, "social_base": 0, "health_full": True, "description": "Ulga na start — 0 PLN społeczne"},
    "PREFERENTIAL": {"months": 24, "social_base_pct": 30, "health_full": True, "description": "Preferencyjny — 30% podstawy"},
    "MALY_ZUS_PLUS": {"months": 36, "social_base": "income_based", "health_full": True, "description": "Mały ZUS+ — od dochodu"},
    "STANDARD": {"months": 999, "social_base_pct": 60, "health_full": True, "description": "Standardowy — 60% podstawy"},
}

# ═══ Tax Forms Comparison ═══
TAX_FORMS = {
    "PIT_SCALE": {"rate": "12%/32%", "base": "dochód", "kup": "TAK", "threshold_32pct": 120000, "name": "Skala podatkowa"},
    "LINEAR": {"rate": "19%", "base": "dochód", "kup": "TAK", "threshold_32pct": None, "name": "Podatek liniowy"},
    "LUMP_SUM": {"rate": "2-17%", "base": "przychód", "kup": "NIE", "threshold_32pct": None, "name": "Ryczałt"},
}

# ═══ Exit Strategies ═══
EXIT_SCENARIOS = {
    "VOLUNTARY_CLOSURE": {"steps": 10, "tax_remnant": 0.10, "vat_remnant": 0.23},
    "SUCCESSION": {"steps": 13, "tax_remnant": 0.10, "manager_deadline": 14},
    "BUSINESS_SALE": {"steps": 8, "tax_remnant": 0.10, "note": "Sprzedaż firmy jako zorganizowanej części"},
    "TRANSFORMATION": {"steps": 12, "tax_remnant": 0.00, "note": "JDG→Sp. z o.o. — aport przedsiębiorstwa"},
}

# ═══ Gig Economy Platforms ═══
GIG_PLATFORMS = {
    "UBER": {"vat_rate": 0.08, "pit_type": "LUMP_SUM", "pit_rate_pct": 8.5, "commission_pct": 25},
    "BOLT": {"vat_rate": 0.08, "pit_type": "LUMP_SUM", "pit_rate_pct": 8.5, "commission_pct": 20},
    "GLOVO": {"vat_rate": 0.08, "pit_type": "LUMP_SUM", "pit_rate_pct": 3.0, "commission_pct": 30},
    "WOLT": {"vat_rate": 0.08, "pit_type": "LUMP_SUM", "pit_rate_pct": 3.0, "commission_pct": 30},
}

# ═══ Employee Hiring Costs ═══
EMPLOYEE_COSTS = {
    "min_wage_gross": 4666,
    "employer_zus_pct": 0.205,  # ~20.5% ZUS pracodawcy
    "ppk_employer_pct": 0.015,  # PPK
}


class P16BusinessLifecycleToolkit:
    """P16 Business Lifecycle Toolkit — 12 innovations."""

    # ── INN01: Lifecycle AI Navigator ──
    def navigate_lifecycle(self, months_active, annual_revenue=0, has_employees=False, 
                            employee_count=0, vat_active=False, is_suspended=False,
                            in_succession=False, in_closure=False):
        if in_closure:
            phase = "CLOSURE"
        elif in_succession:
            phase = "SUCCESSION"
        elif is_suspended:
            phase = "SUSPENDED"
        elif months_active < 0:
            phase = "PRE_START"
        elif months_active < 6:
            phase = "STARTUP_RELIEF"
        elif months_active < 30 and annual_revenue < 200000:
            phase = "STARTUP_PREFERENTIAL"
        elif months_active < 36 and annual_revenue < 200000:
            phase = "EARLY_GROWTH"
        elif has_employees or vat_active or annual_revenue >= 200000:
            phase = "GROWTH" if months_active < 30 else "MATURITY"
        else:
            phase = "ESTABLISHED"

        info = LIFECYCLE_PHASES.get(phase, LIFECYCLE_PHASES["PRE_START"])
        months_remaining = max(0, info["range_months"][1] - months_active) if months_active >= 0 else 0

        # Next phase prediction
        next_phase = "STARTUP_PREFERENTIAL" if phase == "STARTUP_RELIEF" and months_active >= 5 else \
                     "EARLY_GROWTH" if phase == "STARTUP_PREFERENTIAL" and annual_revenue > 100000 else \
                     "GROWTH" if phase in ("STARTUP_PREFERENTIAL", "EARLY_GROWTH") and annual_revenue >= 180000 else \
                     "MATURITY" if months_active >= 24 and annual_revenue >= 150000 else \
                     phase

        # Actions
        actions = []
        if phase == "PRE_START":
            actions = ["1. Wybierz formę opodatkowania", "2. Zarejestruj CEIDG-1", "3. Zgłoś ZUS ZUA (7 dni)", "4. Wybierz rachunek bankowy"]
        elif phase == "STARTUP_RELIEF" and months_remaining <= 2:
            actions = [f"⚠️ Za {months_remaining} mies. koniec ulgi na start!", "📋 Przygotuj się na preferencyjny ZUS"]
        elif phase == "STARTUP_PREFERENTIAL" and months_remaining <= 3:
            actions = [f"⚠️ Za {months_remaining} mies. koniec preferencyjnego ZUS!", "📋 Przygotuj się na standardowy ZUS (+80%)"]
        elif phase == "EARLY_GROWTH" and annual_revenue >= 180000:
            actions = [f"⚠️ Zbliżasz się do limitu VAT 200k! {annual_revenue}/200k", "📋 Złóż VAT-R w 7 dni od przekroczenia"]
        elif phase in ("GROWTH", "MATURITY"):
            actions = ["🚀 Rozważ optymalizację: skala→liniowy lub JDG→Sp. z o.o.", "💰 CIT estoński / 9% CIT przy małym podatniku"]

        zus_relief = ZUS_RELIEF.get(info["zus_status"], ZUS_RELIEF["STANDARD"])

        return {
            "current_phase": phase,
            "phase_description": info["description"],
            "months_active": months_active,
            "months_remaining_in_phase": months_remaining,
            "next_phase": next_phase,
            "zus_status": info["zus_status"],
            "zus_relief_description": zus_relief["description"],
            "actions": actions if actions else ["✅ Stabilna faza — kontynuuj działalność"],
            "annual_revenue": annual_revenue,
            "has_employees": has_employees,
            "routing": "BLOCK_AND_ALERT" if months_remaining <= 0 and phase != "PRE_START" else "TRIAGE_QUEUE" if months_remaining <= 2 else "",
        }

    # ── INN02: Business Form Auto-Selector ──
    def select_best_tax_form(self, annual_revenue, annual_costs, is_transport=False, is_freelancer=False):
        annual_profit = max(0, annual_revenue - annual_costs)
        forms = {}
        tax_scale = (annual_profit * 0.12) if annual_profit <= 120000 else (120000 * 0.12 + (annual_profit - 120000) * 0.32)
        forms["PIT_SCALE"] = round(tax_scale, 2)
        forms["LINEAR"] = round(annual_profit * 0.19, 2)
        if is_transport:
            forms["LUMP_SUM_8_5%%"] = round(annual_revenue * 0.085, 2)
        if is_freelancer:
            forms["LUMP_SUM_12%%"] = round(annual_revenue * 0.12, 2)
        if is_transport or is_freelancer:  # Only show lump sum when applicable
            forms["LUMP_SUM_3%%"] = round(annual_revenue * 0.03, 2)

        best = min(forms, key=forms.get)

        return {
            "annual_revenue": annual_revenue,
            "annual_costs": annual_costs,
            "annual_profit": annual_profit,
            "tax_comparison": forms,
            "best_form": best,
            "best_tax_pln": forms[best],
            "savings_vs_scale": round(forms.get("PIT_SCALE", 0) - forms[best], 2) if best != "PIT_SCALE" else 0,
            "recommendation": f"Optymalna forma: {TAX_FORMS.get(best, {}).get('name', best)} — {forms[best]:,.2f} PLN podatku",
        }

    # ── INN03: Suspension Impact Simulator ──
    def simulate_suspension(self, suspension_months, monthly_revenue, monthly_costs_fixed, has_employees=False):
        if has_employees:
            return {"can_suspend": False, "reason": "Zatrudniasz pracowników — NIE można zawiesić JDG!", "legal_basis": "Art. 22-25 Prawa Przedsiębiorców"}

        if suspension_months > 6:
            return {"can_suspend": False, "reason": f"Max 6 mies. zawieszenia ({suspension_months} wnioskowane)", "legal_basis": "Art. 22 Prawa Przedsiębiorców"}

        lost_revenue = suspension_months * monthly_revenue
        saved_costs_variable = suspension_months * (monthly_revenue - monthly_costs_fixed) * 0.5
        ongoing_costs = suspension_months * monthly_costs_fixed
        zus_savings_social = suspension_months * 1600  # ~składki społeczne
        zus_health_ongoing = suspension_months * 700  # zdrowotna NADAL płatna!

        net_impact = lost_revenue - ongoing_costs + zus_savings_social - zus_health_ongoing - saved_costs_variable

        return {
            "can_suspend": True,
            "suspension_months": suspension_months,
            "max_allowed_months": 6,
            "lost_revenue": round(lost_revenue, 2),
            "ongoing_costs": round(ongoing_costs, 2),
            "zus_social_savings": round(zus_savings_social, 2),
            "zus_health_still_due": round(zus_health_ongoing, 2),
            "net_financial_impact": round(net_impact, 2),
            "recommendation": "Zawieszenie opłacalne finansowo" if net_impact > 0 else "Zawieszenie NIEOPŁACALNE — rozważ inne opcje",
            "legal_basis": "Art. 22-25 Prawa Przedsiębiorców, Art. 36a SUS",
            "health_insurance_note": "⚠️ Składka zdrowotna NADAL należna w okresie zawieszenia!",
        }

    # ── INN04: Succession Readiness Score ──
    def score_succession_readiness(self, has_manager_appointed=False, manager_has_consent=False, 
                                     manager_in_ceidg=False, has_succession_plan=False,
                                     months_since_death=0, has_extension=False):
        score = 0
        checks = []

        if has_manager_appointed:
            score += 25
            checks.append("✅ Zarządca powołany")
        else:
            checks.append("❌ Brak zarządcy — POWOŁAJ (za życia lub 2 mies. po śmierci)")

        if manager_has_consent:
            score += 20
            checks.append("✅ Zgoda zarządcy")
        else:
            checks.append("❌ Brak zgody — wymagana")

        if manager_in_ceidg:
            score += 20
            checks.append("✅ Wpis w CEIDG")
        else:
            checks.append("❌ Brak wpisu w CEIDG — zgłoś w 14 dni")

        if has_succession_plan:
            score += 15
            checks.append("✅ Plan sukcesyjny")
        else:
            checks.append("⚠️ Brak planu — przygotuj")

        limit = 60 if has_extension else 24
        time_left = limit - months_since_death
        if time_left > 12:
            score += 20
            checks.append(f"✅ Czas: {time_left} mies. pozostało")
        elif time_left > 0:
            score += 10
            checks.append(f"⚠️ Tylko {time_left} mies. pozostało!")

        ready = score >= 70

        return {
            "succession_score": score,
            "max_score": 100,
            "ready": ready,
            "status": "GOTOWA" if ready else "NIE PRZYGOTOWANA",
            "checks": checks,
            "time_limit_months": limit,
            "time_remaining_months": max(0, time_left),
            "legal_basis": "Art. 3-15, 49 Ustawy o zarządzie sukcesyjnym",
            "urgent_actions": [c for c in checks if c.startswith("❌")] if not ready else [],
        }

    # ── INN05: Gig Economy Tax Optimizer ──
    def optimize_gig_taxes(self, platform="UBER", monthly_gross=15000, has_mileage_log=True, is_vat_payer=False):
        plat = GIG_PLATFORMS.get(platform, GIG_PLATFORMS["UBER"])
        commission = monthly_gross * plat["commission_pct"] / 100
        net_after_commission = monthly_gross - commission

        # PIT
        if plat["pit_type"] == "LUMP_SUM":
            pit_tax = monthly_gross * plat["pit_rate_pct"] / 100
        else:
            pit_tax = net_after_commission * 0.19

        # VAT
        vat = net_after_commission * plat["vat_rate"] if is_vat_payer else 0

        # KUP
        kup_pct = 100 if has_mileage_log else 75
        kup_amount = net_after_commission * kup_pct / 100

        return {
            "platform": platform,
            "monthly_gross": monthly_gross,
            "commission_pct": plat["commission_pct"],
            "commission_pln": round(commission, 2),
            "net_after_commission": round(net_after_commission, 2),
            "pit_rate_pct": plat["pit_rate_pct"],
            "pit_tax_monthly": round(pit_tax, 2),
            "vat_monthly": round(vat, 2),
            "kup_pct": kup_pct,
            "kup_amount": round(kup_amount, 2),
            "mileage_log_required": not has_mileage_log,
            "annual_net_estimate": round((net_after_commission - pit_tax - vat) * 12, 2),
            "recommendation": "Prowadź ewidencję przebiegu! +100% KUP, +50% VAT" if not has_mileage_log else "OK",
        }

    # ── INN06: Banking Multi-API Aggregator ──
    def get_banking_api_info(self, bank_name="mBank"):
        banks = {
            "mBank": {"api": "PolishAPI v3.2", "ais": True, "pis": True, "oauth": "eIDAS", "sandbox": "developer.mbank.pl"},
            "ING": {"api": "PolishAPI v3.1", "ais": True, "pis": True, "oauth": "eIDAS", "sandbox": "developer.ing.pl"},
            "PKO_BP": {"api": "PolishAPI v3.2", "ais": True, "pis": True, "oauth": "eIDAS", "sandbox": "developer.pkobp.pl"},
            "PEKAO": {"api": "PolishAPI v3.1", "ais": True, "pis": True, "oauth": "eIDAS", "sandbox": "developer.pekao.com.pl"},
            "SANTANDER": {"api": "PolishAPI v3.2", "ais": True, "pis": True, "oauth": "eIDAS", "sandbox": "developer.santander.pl"},
        }
        info = banks.get(bank_name, banks["mBank"])

        return {
            "bank": bank_name,
            "api_version": info["api"],
            "psd2_services": {"AIS": info["ais"], "PIS": info["pis"]},
            "auth": f"OAuth2 / {info['oauth']}",
            "sandbox": info["sandbox"],
            "legal_basis": "PSD2 (EU 2015/2366), PolishAPI v3.x, eIDAS",
            "elixir_support": True,
            "express_elixir": True,
        }

    # ── INN07: CEIDG Auto-File Engine ──
    def fill_ceidg1(self, first_name="Jan", last_name="Kowalski", activity_description="Usługi informatyczne",
                     pkd_main="62.01.Z", tax_form="PIT_SCALE", start_date=None):
        sdate = start_date or date.today().isoformat()
        draft = f"""WNIOSEK CEIDG-1 — Rejestracja JDG
────────────────────────────────────────
A. DANE WNIOSKODAWCY:
   Imię: {first_name}
   Nazwisko: {last_name}
   PESEL: [WSTAW PESEL]
   NIP: [WSTAW NIP jeśli nadany]

B. DZIAŁALNOŚĆ:
   Nazwa: {first_name} {last_name} {activity_description[:20]}
   PKD główne: {pkd_main}
   Data rozpoczęcia: {sdate}

C. FORMA OPODATKOWANIA:
   Wybrana forma: {tax_form}
   {TAX_FORMS.get(tax_form, {}).get('name', '')}

D. UBEZPIECZENIA:
   ZUS ZUA — kod 05 10 (7 dni od wpisu)
   Zdrowotne: obowiązkowe

E. RACHUNEK BANKOWY:
   Numer: [WSTAW NR RACHUNKU]

F. OŚWIADCZENIA:
   - Nie jestem ubezpieczony w KRUS
   - Nie figuruję w CEIDG
   - Spełniam warunki Prawa Przedsiębiorców

Podstawa prawna: Art. 5-7 CEIDG, Prawo Przedsiębiorców
"""
        return {"form": "CEIDG-1", "draft": draft.strip(), "pkd_main": pkd_main, "tax_form": tax_form, "zus_deadline_days": 7}

    # ── INN08: Business Health 360 Dashboard ──
    def health_dashboard(self, months_active=12, annual_revenue=120000, annual_profit=50000, 
                          ceidg_valid=True, zus_registered=True, has_accounting=True, 
                          emergency_fund_months=2, risk_flags=0):
        compliance = 100
        if not ceidg_valid:
            compliance -= 20
        if not zus_registered:
            compliance -= 20
        compliance = max(0, compliance)

        financial = 100
        if annual_profit < 0:
            financial -= 20
        if emergency_fund_months < 3:
            financial -= 20
        financial = max(0, financial)

        operational = 100
        if not has_accounting:
            operational -= 30
        operational = max(0, operational)

        risk_score = max(0, 100 - risk_flags * 10)

        health = round(compliance * 0.35 + financial * 0.30 + operational * 0.15 + risk_score * 0.20, 1)

        grade = "A" if health >= 90 else "B" if health >= 75 else "C" if health >= 60 else "D" if health >= 40 else "F"

        attention = []
        if compliance < 70:
            attention.append("COMPLIANCE")
        if financial < 70:
            attention.append("FINANSE")
        if operational < 70:
            attention.append("OPERACJE")
        if risk_score < 70:
            attention.append("RYZYKO")

        return {
            "health_score": health,
            "grade": grade,
            "compliance_score": compliance,
            "financial_score": financial,
            "operational_score": operational,
            "risk_score": risk_score,
            "areas_needing_attention": attention,
            "routing": "BLOCK_AND_ALERT" if health < 40 else "TRIAGE_QUEUE" if health < 60 else "OK",
        }

    # ── INN09: Exit Strategy Multi-Scenario Simulator ──
    def simulate_exit(self, exit_reason="VOLUNTARY_CLOSURE", inventory_value=0, unpaid_taxes=0, 
                       employees=0, fixed_assets=0, is_succession=False):
        scenario = EXIT_SCENARIOS["SUCCESSION"] if is_succession else EXIT_SCENARIOS.get(exit_reason, EXIT_SCENARIOS["VOLUNTARY_CLOSURE"])
        remnant_tax = inventory_value * scenario["tax_remnant"]
        vat_remnant = inventory_value * 0.23

        steps = [
            "1. Wyrejestruj CEIDG (CEIDG-1 — wniosek o wykreślenie)",
            "2. Spisz REMANENT LIKWIDACYJNY",
            f"3. Zapłać 10% podatek od remanentu: {remnant_tax:,.2f} PLN",
            "4. Wyrejestruj VAT (VAT-Z) + VAT od remanentu 23%",
            "5. ZUS ZWUA — wyrejestrowanie w 7 dni",
            "6. Zeznanie końcowe PIT do 30 kwietnia",
            "7. Ostatni JPK_V7M",
            "8. Przechowuj dokumenty 5 lat",
        ]

        if employees > 0:
            steps.append(f"9. Rozwiąż umowy {employees} pracowników — odprawy, PIT-11")

        if is_succession:
            steps.extend([
                "SPECJALNE: Ustanów zarządcę sukcesyjnego (akt notarialny)",
                "SPECJALNE: Zgłoś do CEIDG w 14 dni",
                "SPECJALNE: Zarządca max 2 lata (5 lat z sądem)",
            ])

        return {
            "exit_reason": exit_reason,
            "is_succession": is_succession,
            "total_steps": len(steps),
            "steps": steps,
            "remnant_tax_pln": round(remnant_tax, 2),
            "vat_remnant_pln": round(vat_remnant, 2),
            "total_exit_tax": round(remnant_tax + vat_remnant + unpaid_taxes, 2),
            "legal_basis": "Art. 24 PIT, Art. 14 VAT, Art. 31-36 Prawa Przedsiębiorców",
        }

    # ── INN10: Growth Phase Revenue Predictor ──
    def predict_revenue(self, current_revenue, months_active, growth_rate_pct=15):
        projected = current_revenue * (1 + growth_rate_pct / 100)
        vat_limit = 200000
        will_exceed_vat = projected >= vat_limit

        return {
            "current_annual_revenue": current_revenue,
            "months_active": months_active,
            "growth_rate_pct": growth_rate_pct,
            "projected_12m_revenue": round(projected, 2),
            "vat_limit": vat_limit,
            "will_exceed_vat_limit": will_exceed_vat,
            "warning": f"⚠️ Przekroczysz limit VAT 200k! Złóż VAT-R" if will_exceed_vat else "✅ Poniżej limitu VAT",
        }

    # ── INN11: Employee Hiring Auto-Procedure ──
    def hiring_procedure(self, gross_salary=MIN_WAGE, employee_count=1):
        employer_zus = round(gross_salary * EMPLOYEE_COSTS["employer_zus_pct"], 2)
        total_cost = round(gross_salary + employer_zus, 2)
        ppk_cost = round(gross_salary * EMPLOYEE_COSTS["ppk_employer_pct"], 2)

        steps = [
            "1. Umowa o pracę / zlecenie — podpisz przed rozpoczęciem",
            "2. Zgłoś do ZUS ZUA w ciągu 7 dni od zatrudnienia",
            "3. Zgłoś do PIT-4R / PIT-11",
            f"4. PPK? Składka pracodawcy: {ppk_cost:.2f} PLN/mies.",
            "5. Badania wstępne (medycyna pracy)",
            "6. Szkolenie BHP",
        ]

        return {
            "gross_salary": gross_salary,
            "employee_count": employee_count,
            "employer_zus_monthly": employer_zus,
            "total_monthly_cost_per_employee": total_cost,
            "total_monthly_cost": round(total_cost * employee_count, 2),
            "ppk_employer_monthly": ppk_cost,
            "hiring_steps": steps,
            "legal_basis": "KP, Art. 43 SUS, Art. 32 PIT",
        }

    # ── INN12: Company Transformation Engine ──
    def simulate_transformation(self, current_profit, current_form="PIT_SCALE"):
        scale_tax = current_profit * 0.12 if current_profit <= 120000 else 120000 * 0.12 + (current_profit - 120000) * 0.32
        linear_tax = current_profit * 0.19
        cit_9 = current_profit * 0.09  # Mały podatnik CIT
        cit_19 = current_profit * 0.19

        zus_jdg_annual = 20000  # ~szacunek standardowy ZUS JDG
        zus_spzoo = 0  # Sp. z o.o. — brak ZUS od zysku (tylko od wynagrodzenia)

        return {
            "current_profit": current_profit,
            "current_form": current_form,
            "current_tax_pln": round(scale_tax, 2),
            "current_zus_annual": zus_jdg_annual,
            "current_total_burden": round(scale_tax + zus_jdg_annual, 2),
            "alternatives": {
                "JDG_LINIOWY": {"tax": round(linear_tax, 2), "zus": zus_jdg_annual, "total": round(linear_tax + zus_jdg_annual, 2)},
                "SP_ZOO_CIT_9": {"tax": round(cit_9, 2), "zus": zus_spzoo, "total": round(cit_9, 2), "note": "Mały podatnik <2M EUR"},
                "SP_ZOO_CIT_ESTOŃSKI": {"tax": 0, "zus": zus_spzoo, "total": 0, "note": "Brak podatku przy reinwestycji"},
            },
            "savings_spzoo_9pct": round((scale_tax + zus_jdg_annual) - cit_9, 2),
            "recommendation": "Przekształć w Sp. z o.o. CIT 9% — oszczędność ZUS + niższy podatek!" if current_profit > 120000 else "Zostań przy JDG — różnica niewystarczająca",
            "legal_basis": "Art. 551-584 KSH, Art. 19 CIT",
        }

    def generate_report(self):
        return {"tool": "P16 Business Lifecycle Toolkit v1.0", "innovations": 12, "coverage": "5 faz cyklu życia JDG", "zus_timelines": 4, "exit_scenarios": 4}

    # ── v8.0 NEW: Auto-Form Generator Helpers ──
    def ceidg1_autofill(self, first_name="Jan", last_name="Kowalski", pesel="80010112345", pkd_main="62.01.Z",
                         tax_form="PIT_SCALE", start_date="2026-08-01", vat_registration=False):
        """G1: CEIDG-1 Auto-Fill Engine."""
        return {
            "form_type": "WNIOSEK O WPIS",
            "sections": {
                "dane": {"imie": first_name, "nazwisko": last_name, "pesel": pesel},
                "dzialalnosc": {"pkd_glowne": pkd_main, "data_start": start_date},
                "opodatkowanie": {"forma": tax_form},
                "vat": {"rejestracja": vat_registration, "zwolnienie": not vat_registration},
                "zus": {"kod": "05 10", "termin": "7 dni od wpisu CEIDG"}
            },
            "deadlines": {"zus_zua_dni": 7, "pit_form_dni": 20, "vat_r": "przed 1. transakcją"}
        }

    def zus_zua_autofill(self, is_employee=False, salary_gross=4666):
        """G2: ZUS ZUA Auto-Fill."""
        zus_code = "01 10" if is_employee else "05 10"
        return {
            "form_type": "ZUS ZUA",
            "kod_zus": zus_code,
            "deadline_dni": 7,
            "cost_employer_monthly": round(salary_gross * 0.205, 2) if is_employee else 0
        }

    def vat_z_autofill(self, inventory_value=0):
        """G4: VAT-Z Auto-Fill."""
        return {
            "form_type": "VAT-Z",
            "vat_remnant_23pct": round(inventory_value * 0.23, 2),
            "remnant_tax_10pct": round(inventory_value * 0.10, 2),
            "total_exit_tax": round(inventory_value * 0.33, 2)
        }

    # ── v8.0 NEW: Estonian CIT Helpers ──
    def estonian_cit_eligibility(self, legal_form="JDG", annual_revenue=2000000, employee_count=1, passive_income_pct=5):
        """E1: Estonian CIT eligibility check."""
        legal_ok = legal_form in {"SP_ZOO", "SA", "SP_KOMANDYTOWA"}
        revenue_ok = annual_revenue <= 50000000
        employees_ok = employee_count >= 3
        passive_ok = passive_income_pct < 50
        eligible = legal_ok and revenue_ok and employees_ok and passive_ok
        restrictions = []
        if not legal_ok:
            restrictions.append(f"Forma {legal_form} nie kwalifikuje się — wymagana Sp. z o.o.")
        if not employees_ok:
            restrictions.append(f"Minimum 3 pracowników (masz {employee_count})")
        if not passive_ok:
            restrictions.append(f"Przychody pasywne {passive_income_pct}% > limit 50%")
        return {"eligible": eligible, "restrictions": restrictions}

    def estonian_cit_tax(self, annual_profit=500000, profit_distributed=0):
        """E2: Estonian CIT tax calculator."""
        estonian_rate = 0.20
        cit_classic_rate = 0.09
        ecit_tax = profit_distributed * estonian_rate
        classic_tax = annual_profit * cit_classic_rate
        savings = classic_tax - ecit_tax
        return {
            "estonian_cit_tax": round(ecit_tax, 2),
            "classic_cit_tax": round(classic_tax, 2),
            "savings": round(savings, 2),
            "tax_on_reinvestment": 0,
            "note": "0% przy reinwestycji — podatek tylko od wypłaconych dywidend"
        }

    # ── v8.0 NEW: Entrepreneur Test Helper ──
    def entrepreneur_test(self, client_count=1, has_fixed_hours=False, has_supervisor=False,
                          owns_tools=False, bears_risk=False, has_flexible_schedule=False):
        """ET: Full entrepreneur test score."""
        etat_score = 0
        etat_score += 10 if has_fixed_hours else 0
        etat_score += 10 if has_supervisor else 0
        etat_score += 15 if client_count == 1 else 0

        jdg_score = 0
        jdg_score += 10 if owns_tools else 0
        jdg_score += 15 if bears_risk else 0
        jdg_score += 10 if has_flexible_schedule else 0
        jdg_score += 15 if client_count >= 3 else 0

        final = jdg_score + (100 - etat_score)
        risk = "NISKIE" if final >= 65 else ("SREDNIE" if final >= 40 else "WYSOKIE")
        return {"score": max(0, min(100, final)), "risk": risk, "is_safe_jdg": final >= 65}

    # ── v8.0 NEW: Enhanced SCA Helpers ──
    def sca_required_check(self, amount=100, is_trusted_beneficiary=False, is_recurring=False):
        """SCA: Check if SCA is required."""
        exempt_low_value = amount <= 30
        exempt_trusted = is_trusted_beneficiary and amount <= 500
        exempt_recurring = is_recurring
        exempt = exempt_low_value or exempt_trusted or exempt_recurring
        methods = ["SMS_OTP", "MOBILE_APP_BIOMETRIC", "PUSH_NOTIFICATION", "HARDWARE_TOKEN"]
        return {
            "sca_required": not exempt,
            "exempt_reason": "LOW_VALUE" if exempt_low_value else "TRUSTED" if exempt_trusted else "RECURRING" if exempt_recurring else "NONE",
            "available_methods": methods,
            "preferred": methods[1]
        }


def main():
    parser = argparse.ArgumentParser(description="P16 Business Lifecycle Toolkit v1.0")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--lifecycle", action="store_true")
    parser.add_argument("--months", type=int, default=12)
    parser.add_argument("--revenue", type=float, default=0)
    parser.add_argument("--employees", type=int, default=0)
    parser.add_argument("--vat-active", action="store_true")
    parser.add_argument("--suspended", action="store_true")
    parser.add_argument("--succession", action="store_true")
    parser.add_argument("--closure", action="store_true")
    parser.add_argument("--form-select", action="store_true")
    parser.add_argument("--costs", type=float, default=0)
    parser.add_argument("--is-transport", action="store_true")
    parser.add_argument("--is-freelancer", action="store_true")
    parser.add_argument("--suspension", action="store_true")
    parser.add_argument("--susp-months", type=int, default=3)
    parser.add_argument("--monthly-rev", type=float, default=10000)
    parser.add_argument("--monthly-costs", type=float, default=2000)
    parser.add_argument("--succession-score", action="store_true")
    parser.add_argument("--has-manager", action="store_true")
    parser.add_argument("--manager-consent", action="store_true")
    parser.add_argument("--manager-ceidg", action="store_true")
    parser.add_argument("--has-plan", action="store_true")
    parser.add_argument("--gig", action="store_true")
    parser.add_argument("--platform", type=str, default="UBER")
    parser.add_argument("--has-mileage-log", action="store_true")
    parser.add_argument("--banking", action="store_true")
    parser.add_argument("--bank", type=str, default="mBank")
    parser.add_argument("--ceidg", action="store_true")
    parser.add_argument("--health", action="store_true")
    parser.add_argument("--has-accounting", action="store_true", default=True, help="Has accounting system")
    parser.add_argument("--profit", type=float, default=0)
    parser.add_argument("--emergency-fund", type=float, default=2)
    parser.add_argument("--risk-flags", type=int, default=0)
    parser.add_argument("--exit", action="store_true")
    parser.add_argument("--exit-reason", type=str, default="VOLUNTARY_CLOSURE")
    parser.add_argument("--inventory", type=float, default=0)
    parser.add_argument("--predict", action="store_true")
    parser.add_argument("--growth-rate", type=float, default=15)
    parser.add_argument("--hiring", action="store_true")
    parser.add_argument("--salary", type=float, default=4666)
    parser.add_argument("--transform", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    tk = P16BusinessLifecycleToolkit()
    output = {}

    if args.all or args.lifecycle:
        r = tk.navigate_lifecycle(args.months, args.revenue or 50000, args.employees > 0, args.employees, args.vat_active, args.suspended, args.succession, args.closure)
        output["INN01_lifecycle"] = {"phase": r["current_phase"], "next": r["next_phase"]}
        if not args.json:
            print(f"\n  🔄 LIFECYCLE: {r['current_phase']} → {r['next_phase']} ({r['months_remaining_in_phase']} mies. pozostało)")
            for a in r["actions"]:
                print(f"     {a}")

    if args.form_select:
        r = tk.select_best_tax_form(args.revenue or 120000, args.costs or 30000, args.is_transport, args.is_freelancer)
        output["INN02_form"] = {"best": r["best_form"], "tax": r["best_tax_pln"]}
        if not args.json:
            print(f"\n  📊 FORM SELECTOR: {r['recommendation']}")
            for f, t in r["tax_comparison"].items():
                print(f"     {f}: {t:,.2f} PLN")

    if args.suspension:
        r = tk.simulate_suspension(args.susp_months, args.monthly_rev, args.monthly_costs, args.employees > 0)
        output["INN03_suspension"] = {"can_suspend": r["can_suspend"], "impact": r.get("net_financial_impact", 0)}
        if not args.json:
            print(f"\n  ⏸️  SUSPENSION: {'✅ Można' if r['can_suspend'] else '❌ ' + r.get('reason','')}")
            if r.get("can_suspend"):
                print(f"     Net impact: {r['net_financial_impact']:,.2f} PLN")

    if args.succession_score:
        r = tk.score_succession_readiness(args.has_manager, args.manager_consent, args.manager_ceidg, args.has_plan)
        output["INN04_succession"] = {"score": r["succession_score"], "ready": r["ready"]}
        if not args.json:
            print(f"\n  🔮 SUCCESSION: {r['succession_score']}/100 — {r['status']}")
            for c in r["checks"]:
                print(f"     {c}")

    if args.gig:
        r = tk.optimize_gig_taxes(args.platform, args.revenue or 15000, args.has_mileage_log, args.vat_active)
        output["INN05_gig"] = {"platform": args.platform, "annual_net": r["annual_net_estimate"]}
        if not args.json:
            print(f"\n  🛵 GIG: {args.platform} — {r['annual_net_estimate']:,.2f} PLN/rok netto")
            print(f"     KUP: {r['kup_pct']}% — {r['recommendation']}")

    if args.banking:
        r = tk.get_banking_api_info(args.bank)
        output["INN06_banking"] = {"bank": args.bank, "api": r["api_version"]}
        if not args.json:
            print(f"\n  🏦 BANKING: {r['bank']} — {r['api_version']}, AIS/PIS: OK, Auth: {r['auth']}")

    if args.ceidg:
        r = tk.fill_ceidg1()
        output["INN07_ceidg"] = {"pkd": r["pkd_main"]}
        print(f"\n  📝 CEIDG-1 AUTO-FILL:")
        print(r["draft"])

    if args.all or args.health:
        r = tk.health_dashboard(args.months, args.revenue or 100000, args.profit or 40000, has_accounting=args.has_accounting, emergency_fund_months=args.emergency_fund, risk_flags=args.risk_flags)
        output["INN08_health"] = {"score": r["health_score"], "grade": r["grade"]}
        if not args.json:
            print(f"\n  🏥 HEALTH: {r['health_score']}/100 — Grade {r['grade']}")
            print(f"     Compliance:{r['compliance_score']} | Financial:{r['financial_score']} | Ops:{r['operational_score']} | Risk:{r['risk_score']}")
            if r["areas_needing_attention"]:
                print(f"     ⚠️  Areas: {', '.join(r['areas_needing_attention'])}")

    if args.exit:
        r = tk.simulate_exit(args.exit_reason, args.inventory, 0, args.employees, 0, args.succession)
        output["INN09_exit"] = {"reason": args.exit_reason, "steps": r["total_steps"], "tax": r["total_exit_tax"]}
        if not args.json:
            print(f"\n  🚪 EXIT: {r['exit_reason']} — {r['total_steps']} steps, {r['total_exit_tax']:,.2f} PLN tax")
            for s in r["steps"][:3]:
                print(f"     {s}")

    if args.predict:
        r = tk.predict_revenue(args.revenue or 100000, args.months, args.growth_rate)
        output["INN10_predict"] = {"projected": r["projected_12m_revenue"], "vat_warning": r["will_exceed_vat_limit"]}
        if not args.json:
            print(f"\n  📈 PREDICT: {r['projected_12m_revenue']:,.2f} PLN — {r['warning']}")

    if args.hiring:
        r = tk.hiring_procedure(args.salary, args.employees or 1)
        output["INN11_hiring"] = {"cost_per_employee": r["total_monthly_cost_per_employee"]}
        if not args.json:
            print(f"\n  👥 HIRING: {r['employee_count']} pracownik × {r['gross_salary']:,.0f} PLN = {r['total_monthly_cost']:,.2f} PLN/mies. całkowity koszt")

    if args.transform:
        r = tk.simulate_transformation(args.profit or args.revenue or 200000)
        output["INN12_transform"] = {"current_tax": r["current_tax_pln"], "savings_spzoo_9": r["savings_spzoo_9pct"]}
        if not args.json:
            print(f"\n  🏢 TRANSFORMATION: {r['recommendation']}")
            print(f"     JDG: {r['current_total_burden']:,.2f} PLN vs Sp. z o.o. CIT 9%: {r['alternatives']['SP_ZOO_CIT_9']['total']:,.2f} PLN")
            print(f"     Oszczędność: {r['savings_spzoo_9pct']:,.2f} PLN/rok")

    if args.all and not args.json:
        print(f"\n  ✅ P16 Toolkit: {len(output)} checks completed")

    if args.json and output:
        print(json.dumps(output, indent=2, ensure_ascii=False, default=str))

    if args.report:
        path = PROJECT_ROOT / "JDG" / "reports" / "RAPORT_P16_BUSINESS_LIFECYCLE_TOOLKIT_v1.0.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write("P16 Business Lifecycle Toolkit v1.0\n12 innovations\n")
        print(f"  📄 Report: {path}")


if __name__ == "__main__":
    main()
