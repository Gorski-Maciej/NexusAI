#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — STR GENERATOR (GLM52 P15)
# Generator zawiadomienia STR/GIIF o podejrzanej transakcji (art. 74-80 AML,
# Dz.U. 2025 poz. 213) — zawiadomienie w 48 h od podejrzenia, countdown.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

LEGAL_AML = ("ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy "
             "oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)")
STR_DEADLINE_HOURS = 48  # art. 74-80 — 48 h od podejrzenia


def generate_str(transaction_id: str, amount_pln: float, reason: str,
                 hours_elapsed: int = 0) -> dict:
    """Generator zawiadomienia STR (formularz + countdown 48 h)."""
    remaining = max(STR_DEADLINE_HOURS - hours_elapsed, 0)
    return {
        "form": "STR — zawiadomienie GIIF",
        "transaction_id": transaction_id,
        "amount_pln": amount_pln,
        "reason": reason,
        "deadline_hours": STR_DEADLINE_HOURS,
        "hours_elapsed": hours_elapsed,
        "hours_remaining": remaining,
        "urgency_alert": remaining <= 12,
        "report_to": "GIIF (Generalny Inspektor Informacji Finansowej)",
        "legal_basis": f"Art. 74-80 {LEGAL_AML}",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(generate_str("TX-2026-0001", 250_000,
                                  "transakcja niezgodna z profilem", 40),
                     ensure_ascii=False, indent=1))
