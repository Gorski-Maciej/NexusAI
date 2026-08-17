#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — AML / CBDD ENGINE (GLM52 P15)
# Silnik CDD/CBDD: checklista weryfikacji per klient, monitor transakcji
# okazjonalnych > 15 000 EUR (art. 34), scorer ryzyka AML (art. 34 — matryca),
# detektor beneficjentów rzeczywistych. Ustawa z 1.03.2018 (Dz.U. 2025 poz. 213).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

LEGAL_AML = ("ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy "
             "oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)")

CASH_THRESHOLD_EUR = 15_000   # art. 34 — transakcje okazjonalne
STR_DEADLINE_HOURS = 48       # art. 74-80 — zawiadomienie GIIF

CDD_CHECKLIST = [
    "Weryfikacja tożsamości (dokument tożsamości)",
    "Ustalenie beneficjenta rzeczywistego (CRBR)",
    "Ocena celu i charakteru relacji gospodarczej",
    "Weryfikacja statusu PEP / sankcje",
    "Ocena ryzyka (art. 34 — matryca)",
]

RISK_FACTORS = {
    "high_risk_jurisdiction": 3,
    "pep": 4,
    "cash_over_15k_eur": 2,
    "unusual_pattern": 3,
    "sanctions_list": 5,
}


def cbdd_checklist() -> dict:
    """Checklista CDD (art. 28a-34 AML)."""
    return {
        "checklist": CDD_CHECKLIST,
        "required": True,
        "legal_basis": f"Art. 28a-34 {LEGAL_AML}",
    }


def cash_monitor(cash_amount_eur: float) -> dict:
    """Monitor transakcji okazjonalnych > 15 000 EUR (art. 34)."""
    return {
        "cash_amount_eur": cash_amount_eur,
        "threshold_eur": CASH_THRESHOLD_EUR,
        "cdd_required": cash_amount_eur > CASH_THRESHOLD_EUR,
        "legal_basis": f"Art. 34 {LEGAL_AML}",
    }


def risk_scorer(factors: list[str]) -> dict:
    """Scorer ryzyka AML (art. 34 — matryca)."""
    score = sum(RISK_FACTORS.get(f, 0) for f in factors)
    if score >= 5:
        level = "HIGH"
    elif score >= 3:
        level = "MEDIUM"
    else:
        level = "LOW"
    return {
        "factors": factors,
        "score": score,
        "risk_level": level,
        "edd_required": level == "HIGH",
        "legal_basis": f"Art. 34 {LEGAL_AML}",
    }


def beneficiary_detector(ownership_structure: list[dict]) -> list[str]:
    """Detektor beneficjentów rzeczywistych (art. 28a, próg >25%)."""
    beneficiaries = [
        p["name"] for p in ownership_structure
        if p.get("ownership_pct", 0) > 25
    ]
    return beneficiaries


if __name__ == "__main__":
    import json

    print(json.dumps(cbdd_checklist(), ensure_ascii=False, indent=1))
    print(json.dumps(cash_monitor(20_000), ensure_ascii=False, indent=1))
    print(json.dumps(risk_scorer(["pep", "sanctions_list"]),
                     ensure_ascii=False, indent=1))
