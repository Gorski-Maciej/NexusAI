#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — LIFECYCLE NAVIGATOR (GLM52 P13)
# Nawigator cyklu życia JDG: faza → checklista obowiązków → auto-formularze,
# health scorecard (poziomy A-E), tracker terminów per faza.
# Fazy: START → GROWTH → SUSPENSION → TRANSFORMATION → SUCCESSION → TERMINATION.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

PHASES = {
    "START": {
        "label": "Start (rejestracja)",
        "obligations": [
            ("CEIDG-1", "Wpis do CEIDG (7 dni od rozpoczęcia)", "CEIDG"),
            ("ZUS ZUA", "Zgłoszenie do ubezpieczeń społecznych", "ZUS"),
            ("VAT-R", "Rejestracja VAT (jeśli limit przekroczony)", "VAT"),
            ("e-Doręczenia", "Adres do doręczeń elektronicznych", "P04"),
            ("Wybór formy opodatkowania", "Skala / liniowy / ryczałt / karta", "P05"),
        ],
    },
    "GROWTH": {
        "label": "Wzrost",
        "obligations": [
            ("Zatrudnienie", "Zgłoszenie pracowników do ZUS", "ZUS"),
            ("Gig economy", "Weryfikacja statusu zleceniobiorców", "P13"),
            ("Limit ryczałtu", "Monitor 2M EUR (art. 6 ust. 4 u.z.p.d.)", "P13"),
            ("Ewidencja przychodów", "Art. 15 u.z.p.d. — miesięczna ewidencja", "P13"),
        ],
    },
    "SUSPENSION": {
        "label": "Zawieszenie",
        "obligations": [
            ("Zawieszenie CEIDG", "Min. 30 dni, max 24 mies. (art. 22-25 PP)", "P13"),
            ("ZUS", "Brak składek w zawieszeniu", "P08"),
            ("VAT", "VAT zawieszony — bez ewidencji", "P02"),
            ("Wznowienie", "Wniosek o wznowienie (7 dni na VAT-R)", "P13"),
        ],
    },
    "TRANSFORMATION": {
        "label": "Transformacja (JDG → spółka)",
        "obligations": [
            ("Test przedsiębiorcy", "p16_entrepreneur_test — JDG vs spółka", "P16"),
            ("Przekształcenie", "KSH art. 584 — przekształcenie JDG w sp. z o.o.", "P13"),
            ("Wycena składników", "Remanent, wycena WNiP", "P10"),
        ],
    },
    "SUCCESSION": {
        "label": "Sukcesja (zarząd sukcesyjny)",
        "obligations": [
            ("Wpis zarządcy CEIDG", "14 dni (art. 3-4 u.z.s.)", "P13"),
            ("Okres zarządu", "2 lata + do 3 lat przedłużenia (art. 12-13)", "P13"),
            ("ZUS", "Zgłoszenie śmierci (30 dni), płatnik", "P08"),
            ("PIT", "Kontynuacja rozliczeń w zarządzie", "P05"),
        ],
    },
    "TERMINATION": {
        "label": "Zakończenie (likwidacja)",
        "obligations": [
            ("VAT-Z", "Wyrejestrowanie z VAT", "P02"),
            ("ZWUA", "Wyrejestrowanie z ZUS", "P08"),
            ("Remanent likwidacyjny", "PIT — remanent, 10% (art. 24 ust. 3 PIT)", "P10"),
            ("PIT-36 końcowy", "Rozliczenie końcowe działalności", "P05"),
        ],
    },
}


def navigate(current_status: str) -> dict:
    phase = PHASES.get(current_status)
    if not phase:
        return {"error": f"Nieznany status: {current_status}", "valid": list(PHASES)}
    return {
        "phase": current_status,
        "label": phase["label"],
        "obligations": [
            {"task": t, "description": d, "domain": dom} for t, d, dom in phase["obligations"]
        ],
        "forms_auto": [t for t, _, _ in phase["obligations"]],
    }


def health_scorecard(completed: int, total: int, compliance_rate: float) -> dict:
    """Health scorecard JDG — poziomy A-E."""
    pct = compliance_rate
    if pct >= 0.99:
        level, color = "A", "green"
    elif pct >= 0.95:
        level, color = "B", "lightgreen"
    elif pct >= 0.90:
        level, color = "C", "yellow"
    elif pct >= 0.80:
        level, color = "D", "orange"
    else:
        level, color = "E", "red"
    return {
        "level": level,
        "color": color,
        "completed": completed,
        "total": total,
        "compliance_rate": round(pct * 100, 2),
        "verdict": "ZDROWA JDG" if level in ("A", "B") else
                   "MONITOROWANA" if level in ("C", "D") else "KRYTYCZNA",
    }


def deadlines_report(phase: str) -> list[dict]:
    """Terminy per faza (dni od zdarzenia)."""
    deadlines = {
        "START": [("CEIDG-1", 7), ("ZUS ZUA", 7), ("VAT-R", 0)],
        "SUSPENSION": [("Min. zawieszenie", 30), ("Wznowienie VAT-R", 7)],
        "SUCCESSION": [("Wpis zarządcy CEIDG", 14), ("Zgłoszenie ZUS", 30)],
        "TERMINATION": [("VAT-Z", 0), ("Remanent", 30)],
    }
    return [
        {"obligation": ob, "days": d, "phase": phase}
        for ob, d in deadlines.get(phase, [])
    ]


if __name__ == "__main__":
    import json
    import sys

    status = sys.argv[1] if len(sys.argv) > 1 else "START"
    print(json.dumps(navigate(status), ensure_ascii=False, indent=1))
    print(json.dumps(health_scorecard(96, 100, 0.96), ensure_ascii=False, indent=1))
    print(json.dumps(deadlines_report(status), ensure_ascii=False, indent=1))
