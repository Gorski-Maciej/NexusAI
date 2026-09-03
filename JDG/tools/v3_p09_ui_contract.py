#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I12 DECLARATIVE UI CONTRACT
=================================================
Kontrakt formularza deklaracji dla UI (P41): pola, walidacje, podpowiedzi
z LKG (autocomplete akt/artykuł/parametr), stany deklaracji do wyświetlenia.
UI nie zna logiki — zna kontrakt.

Usage:
  python tools/v3_p09_ui_contract.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

UI_CONTRACT = {
    "form": {
        "fields": [
            {"name": "change_type", "type": "select",
             "options": ["RATE_CHANGE", "THRESHOLD_CHANGE", "NEW_LIMIT",
                         "DEADLINE_CHANGE", "REPEAL", "DEFINITION_CHANGE"]},
            {"name": "target_key", "type": "autocomplete",
             "source": "data.thresholds (P06) / rule_registry (P07)",
             "validation": "klucz musi istnieć w store"},
            {"name": "new_value", "type": "number", "validation": "zakres wg schema P06"},
            {"name": "valid_from", "type": "date", "validation": ">= dziś; <= valid_to"},
            {"name": "legal_basis.act", "type": "autocomplete", "source": "LKG (P01)"},
            {"name": "legal_basis.article", "type": "autocomplete",
             "source": "węzły LKG aktu"},
            {"name": "justification", "type": "textarea", "minLength": 10},
        ],
        "state_machine": ["DRAFT", "REVIEW_1", "REVIEW_2", "APPROVED",
                          "EXECUTED", "ROLLED_BACK"],
    },
    "lkg_hints": "podpowiedzi: akt → artykuł → parametr/reguła (legal_node_id)",
    "api": "POST /api/v1/declarations (I12 P09) — walidacja po stronie API",
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    # czy istnieje endpoint deklaracji? (framework importowany + ścieżka deklaracji)
    api_files = []
    for p in (BASE / "tools").glob("*.py"):
        txt = p.read_text(encoding="utf-8", errors="ignore")
        imports_fw = bool(re.search(r"^(from|import) (fastapi|flask|aiohttp)", txt,
                                    re.MULTILINE))
        has_decl_route = bool(re.search(r"declaration", txt, re.IGNORECASE)
                              and ("@app" in txt or "routes" in txt or "router" in txt))
        if imports_fw and has_decl_route:
            api_files.append(p.name)
    # form optimizer (kontekst) — reguła z form_optimizer_enterprise.rego
    fo = (BASE / "rules" / "form_optimizer_enterprise.rego").exists()

    checks.append({"name": "ui_contract", "status": "OK",
                   "detail": f"kontrakt formularza: {len(UI_CONTRACT['form']['fields'])} pól, "
                             "autocomplete LKG"})
    checks.append({"name": "declarations_api", "status": "FAIL" if not api_files else "OK",
                   "detail": f"API deklaracji: {api_files or 'BRAK — brak endpointu dla UI'}"})
    checks.append({"name": "form_context", "status": "OK" if fo else "FAIL",
                   "detail": "form_optimizer_enterprise.rego istnieje (kontekst formularza)"})

    findings.append({"id": "V3-P09-L12", "severity": "P2",
                     "evidence": "brak kontraktu UI formularza deklaracji i endpointu API — "
                                 "formularz (P41) nie ma z czego zbudować pól/podpowiedzi "
                                 "LKG; declarative_change.py template to tylko JSON CLI, nie "
                                 "kontrakt UI",
                     "fix": "I12 Declarative UI Contract (ten artefakt): pola + walidacje + "
                            "autocomplete LKG + state machine; API POST /api/v1/"
                            "declarations dla P41"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I12", "generated_at": now(), "gate": gate,
        "metrics": {"fields": len(UI_CONTRACT["form"]["fields"]),
                    "api_files": api_files, "form_context": fo},
        "ui_contract": UI_CONTRACT,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P41 (UI), P09-I01 (schema), P09-I06 (stany), P06 (store)",
                     "rule": "UI renderuje wyłącznie pola z kontraktu; walidacja serwerowa "
                             "zgodna z SCHEMA_V1; podpowiedzi z LKG"}}
    (BUNDLES / "v3_p09_ui_contract.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I12] gate={gate} api={api_files or 'none'}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
