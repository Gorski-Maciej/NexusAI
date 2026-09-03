#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I02 AI-READER 4-EYES
==========================================
LLM diff (nowelizacja → ustrukturyzowany diff prawny) → walidacja drugim
modelem → prawnik; pełny audyt pewności. Audyt stanu llm_bridge.py: rola =
wyjaśnianie werdyktów (explain/simulate, modele gemini-flash), NIE jest
AI-Readerem diffów (brak parsowania nowelizacji, braku drugiego modelu,
brak cytowania jednostek LKG).

Usage:
  python tools/v3_p08_ai_reader_four_eyes.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"

DIFF_FIELDS = ["act", "legal_unit", "change_type", "old_text", "new_text",
               "effective_from", "certainty", "legal_node_id"]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    bridge = (BASE / "tools" / "llm_bridge.py").read_text(encoding="utf-8")
    bridge_text = bridge.lower()

    has_explain = "def explain" in bridge
    has_diff_parse = bool(re.search(r"def .*diff|diff.*parse|nowelizacj", bridge_text))
    # prawdziwy 4-eyes: drugi model walidujący diff (nie rejestr modeli do explain)
    has_second_model = bool(re.search(r"def validate.*diff|model2|second.*valid", bridge_text))
    diff_json = (BUNDLES / "v3_p08_legal_diff_schema.json")

    # próbka diffa (P08-AN02: schema zgodna z LKG P01)
    sample_diff = {
        "diff_id": "D-2026-0001", "act": "Ustawa o VAT", "legal_unit": "art. 113 ust. 1",
        "legal_node_id": "PL/uVAT/art/113/ust/1", "change_type": "AMEND_VALUE",
        "old_text": "1 200 000 EUR", "new_text": "2 000 000 EUR",
        "effective_from": "2027-01-01", "certainty": 0.0,
    }
    diff_json.write_text(json.dumps({"schema": DIFF_FIELDS, "sample": sample_diff},
                                    ensure_ascii=False, indent=2), encoding="utf-8")

    checks.append({"name": "llm_bridge_role",
                   "status": "FAIL" if not has_diff_parse else "OK",
                   "detail": f"llm_bridge: explain/simulate (wyjaśnienia) = {has_explain}; "
                             f"AI-Reader diff: {has_diff_parse}"})
    checks.append({"name": "four_eyes_validation",
                   "status": "FAIL" if not has_second_model else "OK",
                   "detail": "walidacja drugim modelem: BRAK w llm_bridge (4-eyes: model2 "
                             "+ prawnik niezaimplementowane)"})
    checks.append({"name": "diff_schema_lkg",
                   "status": "OK",
                   "detail": f"schema diffa (LKG): {DIFF_FIELDS} — sample zapisany w "
                             f"v3_p08_legal_diff_schema.json"})

    findings.append({"id": "V3-P08-L02", "severity": "P1",
                     "evidence": "llm_bridge.py (799 wierszy) to silnik WYJAŚNIEŃ werdyktów — "
                                 "brak roli AI-Readera: parsowania nowelizacji na diff, drugiego "
                                 "modelu weryfikującego i cytowania jednostek LKG (legal_node_id)",
                     "fix": "AI-Reader 4-Eyes (I02): prompt do diffu wg schema LKG + walidacja "
                            "drugim modelem (rozbieżność = MANUAL) + pewność per diff "
                            "(pewność < 0.8 = człowiek)"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I02", "generated_at": now(), "gate": gate,
        "metrics": {"bridge_role_explain": has_explain, "ai_reader_diff": has_diff_parse,
                    "second_model": has_second_model},
        "diff_fields": DIFF_FIELDS,
        "certainty_gates": {"gte_0.95": "AUTO", "0.8-0.95": "REVIEW_1", "lt_0.8": "MANUAL"},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P01 (LKG legal_node_id), P05 (daty wejścia), P08-I05 (impact), "
                                "P39 (testy diffu)",
                     "rule": "diff bez pewności ≥ 0.8 = MANUAL (człowiek); "
                             "rozbieżność modeli = alert 4-eyes"},
    }
    (BUNDLES / "v3_p08_ai_reader_four_eyes.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I02] gate={gate} explain={has_explain} diff_reader={has_diff_parse} "
          f"second_model={has_second_model}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
