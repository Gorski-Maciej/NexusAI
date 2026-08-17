#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RODO REGISTER GENERATOR (GLM52 P15)
# Generator rejestru czynności przetwarzania (art. 30 RODO) — auto-z arkuszy
# danych (cel, podstawa, kategorie danych, odbiorcy, retencja, transfery).
# Rozporządzenie Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

LEGAL_RODO = "rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)"

# Wzorce czynności przetwarzania (art. 30 ust. 1 RODO)
TEMPLATES = {
    "klienci": {
        "purpose": "Obsługa klientów i realizacja umów",
        "legal_basis": "Art. 6 ust. 1 lit. b RODO (umowa)",
        "data_categories": ["dane identyfikacyjne", "dane kontaktowe", "dane transakcyjne"],
        "recipients": ["księgowość", "dostawca CRM"],
        "retention": "6 lat od zakończenia umowy",
    },
    "pracownicy": {
        "purpose": "Zatrudnienie i rozliczenia ZUS",
        "legal_basis": "Art. 6 ust. 1 lit. c RODO (obowiązek prawny)",
        "data_categories": ["dane identyfikacyjne", "dane płacowe", "dane zdrowotne"],
        "recipients": ["ZUS", "US", "firma kadrowa"],
        "retention": "50 lat (akta pracownicze)",
    },
    "marketing": {
        "purpose": "Marketing bezpośredni (newsletter)",
        "legal_basis": "Art. 6 ust. 1 lit. a RODO (zgoda)",
        "data_categories": ["adres e-mail", "imię i nazwisko"],
        "recipients": ["dostawca newsletter"],
        "retention": "do wycofania zgody",
    },
}


def generate_register(categories: list[str]) -> dict:
    """Generator rejestru czynności przetwarzania (art. 30 RODO)."""
    records = []
    for cat in categories:
        t = TEMPLATES.get(cat, TEMPLATES["klienci"])
        records.append({
            "category": cat,
            "controller": "JDG (przedsiębiorca)",
            **t,
        })
    return {
        "form": "Rejestr czynności przetwarzania (art. 30 RODO)",
        "records": records,
        "records_count": len(records),
        "dpo_required": "pracownicy" in categories,
        "legal_basis": f"Art. 30 {LEGAL_RODO}",
    }


def breach_notification(breach_date: str, detected_hours: int = 0) -> dict:
    """Tracker naruszeń — zgłoszenie w 72 h (art. 33 RODO)."""
    deadline_hours = 72
    remaining = max(deadline_hours - detected_hours, 0)
    return {
        "breach_date": breach_date,
        "deadline_hours": deadline_hours,
        "hours_elapsed": detected_hours,
        "hours_remaining": remaining,
        "alert": remaining <= 12,
        "report_to": "Prezes UODO",
        "legal_basis": f"Art. 33 {LEGAL_RODO}",
    }


def fine_calculator(revenue_eur: float, tier: str = "tier2") -> dict:
    """Kalkulator sankcji RODO (art. 83) — 20 mln EUR / 4% (tier2)."""
    if tier == "tier2":
        max_eur = 20_000_000
        pct = 4.0
    else:
        max_eur = 10_000_000
        pct = 2.0
    return {
        "tier": tier,
        "max_fixed_eur": max_eur,
        "max_pct_revenue": pct,
        "revenue_eur": revenue_eur,
        "pct_amount_eur": round(revenue_eur * pct / 100, 2),
        "effective_cap_eur": min(max_eur, round(revenue_eur * pct / 100, 2)),
        "legal_basis": f"Art. 83 ust. 4-5 {LEGAL_RODO}",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(generate_register(["klienci", "pracownicy"]),
                     ensure_ascii=False, indent=1))
    print(json.dumps(breach_notification("2026-08-17", 60),
                     ensure_ascii=False, indent=1))
    print(json.dumps(fine_calculator(1_000_000), ensure_ascii=False, indent=1))
