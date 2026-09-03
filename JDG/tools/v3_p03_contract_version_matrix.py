#!/usr/bin/env python3
"""NexusAI JDG — CONTRACT VERSION MATRIX (V3-P03-I01)
=====================================================
Macierz wersji kontraktu werdyktu × pola × klienci z planem deprecation.

  • wersja bazowa 1.0 = 25-polowy słownik kanoniczny (r01_orchestrator_core_innovations_v9.rego);
  • wersja 1.1 = rozszerzenia additive (certainty_class, invariant_refs,
    legal_basis_refs, golden_hash) — bez breaking change;
  • diff per pole: canonical(25) vs OpenAPI VerdictResponse vs RESPONSE_FIELDS
    (tools/orchestrator_data_contract.py) — wykrywa dryf spec↔kod;
  • plan deprecation: pole usuwane tylko w major (2.0) z okresem współistnienia.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_contract_version_matrix.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def canonical_25() -> list[str]:
    """25-polowy słownik kanoniczny z r01_orchestrator_core_innovations_v9.rego."""
    t = (BASE_DIR / "rules" / "r01_orchestrator_core_innovations_v9.rego").read_text(encoding="utf-8")
    m = re.search(r"verdict_25_fields := \[(.*?)\]", t, re.S)
    if not m:
        return []
    return re.findall(r'"([a-z_]+)"', m.group(1))


def openapi_fields() -> list[str]:
    """Pola VerdictResponse z api/openapi.yaml (bez pyyaml — parsowanie liniowe)."""
    p = BASE_DIR / "api" / "openapi.yaml"
    if not p.exists():
        return []
    t = p.read_text(encoding="utf-8")
    # VerdictResponse: … properties: (pola 4-spacjowe) … do kolejnego schematu.
    i = t.find("VerdictResponse:")
    if i < 0:
        return []
    j = t.find("properties:", i)
    if j < 0:
        return []
    nxt = re.search(r"\n    [A-Za-z_][A-Za-z0-9_]*:", t[j + 11:])
    block = t[j + 11: j + 11 + (nxt.start() if nxt else 4000)]
    return re.findall(r"^\s{8}([a-z_][a-z_0-9]*):", block, re.M)


def response_fields_contract() -> list[str]:
    """Pola VERDICT_FIELDS z tools/orchestrator_data_contract.py."""
    t = (BASE_DIR / "tools" / "orchestrator_data_contract.py").read_text(encoding="utf-8")
    m = re.search(r"VERDICT_FIELDS = \{(.*?)\n\}", t, re.S)
    if not m:
        return []
    return re.findall(r'"([a-z_][a-z_0-9]*)"\s*:', m.group(1))


def build() -> dict:
    canon = canonical_25()
    oas = openapi_fields()
    contract = response_fields_contract()

    rows = []
    for f in canon:
        in_oas = f in oas
        in_contract = f in contract
        state = "SYNC" if in_oas and in_contract else ("DRYF_OAS" if in_contract else "DRYF_BOTH")
        rows.append({
            "field": f, "version_added": "1.0",
            "in_openapi": in_oas, "in_tool_contract": in_contract,
            "state": state,
        })

    extensions = [
        {"field": "certainty_class", "version_added": "1.1", "source": "F4 V2 §5.2 / runtime_invariants", "breaking": False},
        {"field": "certainty_guard", "version_added": "1.1", "source": "F4 V2 §5.2 / runtime_invariants", "breaking": False},
        {"field": "invariant_refs", "version_added": "1.1", "source": "P03-I06 / INV-032", "breaking": False},
        {"field": "legal_basis_refs", "version_added": "1.1", "source": "P03-I06 / P01 legal_node_id", "breaking": False},
        {"field": "golden_hash", "version_added": "1.1", "source": "P03-I04 / F3 V2", "breaking": False},
    ]

    dryf = [r for r in rows if r["state"] != "SYNC"]
    return {
        "innovation": "V3-P03-I01",
        "name": "Contract Version Matrix — wersje kontraktu × pola × klienci",
        "generated_at": now(),
        "canonical_version": "1.0",
        "canonical_field_count": len(canon),
        "openapi_field_count": len(oas),
        "tool_contract_field_count": len(contract),
        "rows": rows,
        "additive_extensions_1_1": extensions,
        "drift_fields": dryf,
        "drift_count": len(dryf),
        "deprecation_plan": {
            "rule": "pole usuwane wyłącznie w major 2.0; minor (1.x) tylko additive; "
                    "okres współistnienia >= 2 minor; klient nieznany = nie usuwaj",
            "periods": ["1.0 (bazowy)", "1.1 (additive: certainty/golden/refs)", "2.0 (major: usunięcia)"],
        },
        "gate": {
            "pass": len(dryf) == 0,
            "rule": "każde pole kanoniczne obecne w OpenAPI i kontrakcie narzędzia; "
                    "dryf spec↔kod = luka P0 (P03-AN06, AP11)",
        },
        "note": "Realny dryf: 11 pól kanonicznych brakuje w VerdictResponse OpenAPI "
                "(package, priority, rounding_level, gtu_code, procedure, pit_bracket, "
                "pit_annual_return_type, kus_percent, ceidg_registration_required, "
                "valid_from, valid_to) — bramka FAIL do domknięcia w P41.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Contract Version Matrix (V3-P03-I01)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P03-I01 Contract Version Matrix: canon={data['canonical_field_count']} "
              f"oas={data['openapi_field_count']} drift={data['drift_count']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: dryf spec↔kod — pola kanoniczne poza OpenAPI/kontraktem")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())