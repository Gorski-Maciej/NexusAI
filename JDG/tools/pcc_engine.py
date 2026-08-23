#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PCC ENGINE (GLM52 P14)
# Auto-detektor czynności PCC + generator deklaracji PCC-3 (0 ręki, 14 dni).
# Ustawa z 9.09.2000 o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789):
# art. 1 (przedmiot), art. 2 pkt 4 (wyłączenie VAT), art. 4 (obowiązek — nabywca),
# art. 6 (podstawa — wartość rynkowa), art. 7 (stawki 0,5-2%), art. 9 (zwolnienie
# ≤1000 zł), art. 10 (PCC-3 w 14 dni), art. 10 ust. 3 (odpowiedzialność notariusza).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

try:
    from .p14_thresholds import load_thresholds
except ImportError:  # direct ``python JDG/tools/...py`` invocation
    from p14_thresholds import load_thresholds

_P14 = load_thresholds()

LEGAL_PCC = ("ustawy z dnia 9 września 2000 r. o podatku od czynności "
             "cywilnoprawnych (Dz.U. 2025 poz. 789)")

# Stawki PCC (art. 7) — ułamki dziesiętne
RATES = {
    "sale": _P14.pcc_sale_rate,       # art. 7 ust. 1 pkt 1 — sprzedaż rzeczy/praw majątkowych
    "loan": _P14.pcc_loan_rate,         # art. 7 ust. 1 pkt 4 — pożyczka
    "company": _P14.pcc_company_rate,   # art. 7 ust. 1 pkt 9 — umowa spółki
    "exchange": 0.01,                   # art. 7 ust. 1 pkt 2 — zamiana
    "mortgage": _P14.pcc_mortgage_rate, # art. 7 ust. 1 pkt 7 — hipoteka
}

EXEMPTION_LIMIT = _P14.pcc_exemption_limit  # art. 9 pkt 1 — kwoty ≤ 1000 zł zwolnione
PCC3_DEADLINE_DAYS = _P14.pcc3_deadline_days   # art. 10 — PCC-3 w 14 dni


def rate_pct(transaction_type: str) -> float:
    """Stawka PCC w % dla typu czynności."""
    return RATES.get(transaction_type, 0.0) * 100


def detect_transaction(transaction_type: str, amount: float,
                       vat_applicable: bool = False) -> dict:
    """Detektor obowiązku PCC dla czynności cywilnoprawnej.

    Zwraca stawkę, podatek, flagę zwolnienia (art. 9) i wyłączenia VAT
    (art. 2 pkt 4 — arbiter VAT vs PCC).
    """
    amount = float(amount)
    if vat_applicable:
        return {
            "transaction_type": transaction_type,
            "amount": amount,
            "vat_applicable": True,
            "pcc_obligation": False,
            "rate_pct": 0.0,
            "tax_due": 0.0,
            "reason": "Czynność objęta VAT — wyłączona z PCC (art. 2 pkt 4 u.p.c.c.)",
            "legal_basis": f"Art. 2 pkt 4 {LEGAL_PCC}",
        }
    rate = RATES.get(transaction_type, 0.0)
    exempt = amount <= EXEMPTION_LIMIT
    tax = 0.0 if exempt else round(amount * rate, 2)
    return {
        "transaction_type": transaction_type,
        "amount": amount,
        "vat_applicable": False,
        "pcc_obligation": rate > 0,
        "rate_pct": rate * 100,
        "tax_due": tax,
        "small_value_exempt": exempt,
        "reason": (f"Kwota ≤ {EXEMPTION_LIMIT:g} zł — zwolniona (art. 9 pkt 1 u.p.c.c.)"
                   if exempt else
                   f"PCC {rate * 100:g}% od czynności {transaction_type} (art. 7 u.p.c.c.)"),
        "legal_basis": f"Art. 1, 4, 6-7 {LEGAL_PCC}",
    }


def generate_pcc3(transaction_type: str, amount: float, days_elapsed: int = 0,
                  vat_applicable: bool = False) -> dict:
    """Generator deklaracji PCC-3 (formularz + kwota + countdown 14 dni)."""
    det = detect_transaction(transaction_type, amount, vat_applicable)
    days_remaining = max(PCC3_DEADLINE_DAYS - days_elapsed, 0)
    return {
        "form": "PCC-3 (deklaracja) + PCC-3/A (załącznik)",
        "transaction_type": transaction_type,
        "amount": amount,
        "rate_pct": det["rate_pct"],
        "tax_due": det["tax_due"],
        "small_value_exempt": det["small_value_exempt"],
        "deadline_days": PCC3_DEADLINE_DAYS,
        "days_elapsed": days_elapsed,
        "days_remaining": days_remaining,
        "urgency_alert": days_remaining <= 3 and not det["small_value_exempt"]
                         and det["pcc_obligation"],
        "submission_required": det["pcc_obligation"] and not det["small_value_exempt"],
        "notary_liable": True,   # art. 10 ust. 3 — odpowiedzialność solidarna notariusza
        "legal_basis": f"Art. 10 {LEGAL_PCC}",
    }


if __name__ == "__main__":
    import json
    import sys

    if len(sys.argv) > 2 and sys.argv[1] == "--pcc3":
        print(json.dumps(generate_pcc3(sys.argv[2], float(sys.argv[3])),
                         ensure_ascii=False, indent=1))
    else:
        print(json.dumps(detect_transaction("sale", 100000), ensure_ascii=False, indent=1))
        print(json.dumps(generate_pcc3("sale", 100000, days_elapsed=12),
                         ensure_ascii=False, indent=1))
