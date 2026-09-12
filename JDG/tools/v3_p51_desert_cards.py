#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I03 DESERT CARD TEMPLATE — karta pustyni (standard raportu).

Karta pustyni: przepis (akt+art, [NIEZWERYFIKOWANE — ISAP]) → warunki
materiałne (szkielet propozycji reguły) → wymagane testy (granice,
temporalne) → koszt wdrożenia (S/M/L) → kolejność (z I02). Generowane dla
TOP-10 pustyni wg ryzyka (kontrakt akceptacji #20) + szablon pusty do
kolejnych kart. Wiąże P41 (dokumentacja) i P36 (generator szkiców, I05).
"""
from __future__ import annotations

from v3_p51_common import read_json, write_p51_bundle

COST_BY_PRIORITY = {"P0": "S", "P1": "S", "P2": "M", "P3": "L"}
TEST_TEMPLATE = [
    "granica progu (day-1/day-0/day+1 względem valid_from)",
    "negatywna (próg nieosiągnięty → NEEDS_ADVICE / brak dopasowania)",
    "fail-closed (brak input → NEEDS_ADVICE, nigdy cichy AUTO_POST)",
]
RULE_SKELETON = (
    "package jdg.<domena>\n"
    "# warunki materiałne z treści przepisu (art. {article}): do wypełnienia\n"
    "# przez człowieka (4-eyes, protokół 04); szkielet NIE jest pokryciem.\n"
)


def main() -> int:
    reg = read_json(BASE_REG() or "nonexistent") or {}
    entries = reg.get("evidence", {}).get("entries", [])
    top = entries[:10]
    cards = []
    for e in top:
        cards.append({
            "card_id": f"CARD-{e['legal_node_id']}",
            "legal_node_id": e["legal_node_id"],
            "przepis": f"{e['act']} — Art. {e['article']} "
                       f"(Dz.U. {e.get('act_dz_u')}) "
                       "[NIEZWERYFIKOWANE — ISAP]",
            "warunki_materialne": RULE_SKELETON.format(article=e["article"]),
            "proponowane_testy": TEST_TEMPLATE,
            "koszt": COST_BY_PRIORITY.get(e["priority"], "M"),
            "kolejnosc": e["priority"],
            "sla_deadline": e["sla_deadline"],
            "generator_eligible": e["desert_class"] == "rule_no_test",
        })
    metrics = {
        "analysis": "desert_cards",
        "routing": "TRIAGE_QUEUE" if cards else "AUTO_FILE",
        "cards_total": len(cards),
        "cards_required": 10,
        "template_present": True,
    }
    write_p51_bundle("desert_cards", "V3-P51-I03", metrics, {
        "cards": cards,
        "empty_template": {
            "card_id": "CARD-<legal_node_id>",
            "przepis": "<akt> — Art. <n> (Dz.U. <poz>) [NIEZWERYFIKOWANE — ISAP]",
            "warunki_materialne": RULE_SKELETON,
            "proponowane_testy": TEST_TEMPLATE,
            "koszt": "S|M|L",
            "kolejnosc": "P0|P1|P2|P3",
            "sla_deadline": "YYYY-MM-DD",
            "generator_eligible": False,
        },
    })
    return 0


def BASE_REG():
    from pathlib import Path
    from v3_p51_common import BUNDLES_DIR
    return BUNDLES_DIR / "v3_p51_desert_entries.json"


if __name__ == "__main__":
    raise SystemExit(main())
