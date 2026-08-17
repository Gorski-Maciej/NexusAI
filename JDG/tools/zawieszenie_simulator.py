#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ZAWIESZENIE SIMULATOR (GLM52 P13)
# Symulator skutków zawieszenia działalności (art. 22-25 PP — Dz.U. 2025 poz. 123):
# raport skutków we wszystkich domenach (ZUS/VAT/PIT/kalendarz), monitor 24 mies.,
# kalkulator działalności nieewidencjonowanej (50% płacy minimalnej, art. 5 PP).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

MIN_SUSPENSION_DAYS = 30
MAX_SUSPENSION_MONTHS = 24
UNREGISTERED_PCT = 0.50


def simulate(suspension_days: int, vat_registered: bool = True,
             zus_contributions_monthly_pln: float = 0.0,
             health_contribution_monthly_pln: float = 0.0) -> dict:
    """Symulacja skutków zawieszenia we wszystkich domenach."""
    violations = []
    if suspension_days < MIN_SUSPENSION_DAYS:
        violations.append(
            f"Zawieszenie {suspension_days} dni < minimum 30 dni (art. 22 ust. 3 PP)"
        )
    months = suspension_days / 30.0
    if months > MAX_SUSPENSION_MONTHS:
        violations.append(
            f"Zawieszenie {months:.1f} mies. > max 24 mies. (art. 22 ust. 1 PP)"
        )

    zus_savings = zus_contributions_monthly_pln * (suspension_days / 30.0) if not violations else 0.0
    health_savings = health_contribution_monthly_pln * (suspension_days / 30.0) if not violations else 0.0

    return {
        "suspension_days": suspension_days,
        "valid": not violations,
        "violations": violations,
        "effects": {
            "zus": {
                "status": "BRAK SKŁADEK" if not violations else "SKŁADKI WYMAGANE",
                "savings_pln": round(zus_savings + health_savings, 2),
                "note": "W okresie zawieszenia przedsiębiorca nie opłaca składek ZUS "
                        "(społeczne i zdrowotne) — art. 22-25 PP",
            },
            "vat": {
                "status": "ZAWIESZONY" if vat_registered and not violations else "AKTYWNY",
                "note": "VAT zawieszony — brak obowiązku składania deklaracji i ewidencji "
                        "(art. 25 PP w zw. z u. VAT)",
            },
            "pit": {
                "status": "BRAK PRZYCHODÓW",
                "note": "W zawieszeniu nie uzyskuje się przychodów — brak obowiązku "
                        "ewidencji (art. 24 ust. 10 PIT)",
            },
            "calendar": {
                "resumption_notice": "7 dni na zgłoszenie wznowienia do CEIDG",
                "vat_r_resumption": "VAT-R w 7 dni od wznowienia (jeśli VAT rejestrowany)",
            },
        },
        "legal_basis": "art. 22-25 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców "
                       "(Dz.U. 2025 poz. 123)",
    }


def suspension_monitor(months_suspended: int) -> dict:
    """Monitor 24 miesięcy zawieszenia z alertem przy 90%."""
    pct = months_suspended / MAX_SUSPENSION_MONTHS
    return {
        "months_suspended": months_suspended,
        "max_months": MAX_SUSPENSION_MONTHS,
        "usage_pct": round(pct * 100, 2),
        "alert_90": pct >= 0.90,
        "status": "OK" if pct < 0.90 else "ALERT" if pct < 1.0 else "EXCEEDED",
        "legal_basis": "art. 22 ust. 1 ustawy z dnia 6 marca 2018 r. — Prawo "
                       "przedsiębiorców (Dz.U. 2025 poz. 123)",
    }


def unregistered_calculator(monthly_revenue_pln: float, min_wage_pln: float = 4800.0) -> dict:
    """Kalkulator działalności nieewidencjonowanej (art. 5-6 PP): 50% minimalnej."""
    limit = min_wage_pln * UNREGISTERED_PCT
    allowed = monthly_revenue_pln <= limit
    return {
        "monthly_revenue_pln": monthly_revenue_pln,
        "min_wage_pln": min_wage_pln,
        "limit_pln": limit,
        "allowed": allowed,
        "status": "DOZWOLONA" if allowed else "WYMAGA REJESTRACJI CEIDG",
        "note": "Działalność nieewidencjonowana: przychód ≤ 50% płacy minimalnej "
                "miesięcznie, bez ZUS i VAT (art. 5-6 PP)",
        "legal_basis": "art. 5-6 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców "
                       "(Dz.U. 2025 poz. 123)",
    }


if __name__ == "__main__":
    import json
    import sys

    days = int(sys.argv[1]) if len(sys.argv) > 1 else 60
    print(json.dumps(simulate(days), ensure_ascii=False, indent=1))
    print(json.dumps(suspension_monitor(22), ensure_ascii=False, indent=1))
    print(json.dumps(unregistered_calculator(2300), ensure_ascii=False, indent=1))
