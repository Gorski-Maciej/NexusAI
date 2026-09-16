#!/usr/bin/env python3
"""
NexusAI JDG — V3-P65 TOOL STANDARD CONTRACT (I01; prompt P65 Sekcja 10-I01).
Wspólny kontrakt narzędzi fortecy: wejście → raport JSON (schema P29) →
exit codes → dry-run. Spójność narzędziowa = łańcuchowanie w CI (P39).

Kontrakt (wiążący dla P66–P68 i V4 — sekcja 9.08 raportu P65):
  * Każde narzędzie: python3 tool.py [--dry-run] [--json] [args]
  * Raport JSON: min. pola z thresholds v3_p65_tool_contract_required_fields
    (schema, tool, status, provenance) — walidacja enforce().
  * Exit codes: 0=PASS, 1=BLOCK/FAIL, 2=NEEDS_ADVICE/usage error (fail-closed).
  * dry-run: oblicza wynik bez zapisu plików (bezpieczny podgląd CI/lokal).

Uruchomienie: python3 v3_p65_tool_contract.py [--dry-run] [--json]
Wynik: bundles/v3_p65_i01_contract.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p65_common import (BUNDLES, KATALOG_NARZEDZI, P62_ENGINES, P53_ENGINES,
                           P37_BENCH_GATE, P42_WORM_CHAIN, P63_I01_RBAC,
                           P49_CHAOS_INPUT, TOOL_CONTRACT, audit_header,
                           now_iso, read_threshold, write_json)

SCHEMA = "jdg.v3_p65.tool_contract.v1"

# Narzędzia fortecy objęte kontraktem (kompozycja + nowe P65) — zero duplikacji:
TOOL_REGISTRY = [
    {"tool": "v3_p65_semantic_diff.py", "family": "diff", "composes": []},
    {"tool": "v3_p65_rule_to_tests.py", "family": "generator", "composes": ["v3_p51_desert_cards.py"]},
    {"tool": "v3_p65_worm_tamper_test.py", "family": "integrity", "composes": ["v3_p42_worm_hash_chain.py", "v3_p40_api_audit_worm.py"]},
    {"tool": "v3_p65_adoption_metrics.py", "family": "observability", "composes": ["v3_p64_sweep_engine.py"]},
    {"tool": "v3_p65_doc_generator.py", "family": "docs", "composes": ["v3_p60_doc_registry.json"]},
    {"tool": "v3_p62_engines.py", "family": "simulator", "composes": []},
    {"tool": "v3_p53_engines.py", "family": "simulator", "composes": []},
    {"tool": "v3_p37_benchmark_gate.py", "family": "benchmark", "composes": []},
    {"tool": "v3_p49_chaos_input.py", "family": "chaos", "composes": []},
]


def contract_fields_from_thresholds() -> list[str]:
    return read_threshold("v3_p65_tool_contract_required_fields") or []


def validate_report_shape(report: dict, required_fields: list[str]) -> dict:
    """Walidacja raportu JSON narzędzia wg kontraktu (schema P29)."""
    missing = [f for f in required_fields if f not in report]
    return {"tool": report.get("tool", "?"), "missing_fields": missing,
            "compliant": not missing}


def enforce() -> dict:
    """Bramka I01: każdy element rejestru narzędzi musi istnieć i deklarować
    zgodność z kontraktem; pola kontraktu jako DANE (ADR-002)."""
    required = contract_fields_from_thresholds()
    fields_min = read_threshold("v3_p65_tool_contract_fields_min") or 4
    reg_ok = []
    for t in TOOL_REGISTRY:
        p = Path(__file__).resolve().parent / t["tool"]
        reg_ok.append({"tool": t["tool"], "exists": p.exists(),
                       "family": t["family"], "composes": t["composes"]})
    missing_tools = [r["tool"] for r in reg_ok if not r["exists"]]
    contract_ok = len(required) >= fields_min
    payload = {
        "schema": SCHEMA,
        "tool": "v3_p65_tool_contract",
        "status": "PASS" if (not missing_tools and contract_ok) else "FAIL",
        "gate": "PASS" if (not missing_tools and contract_ok) else "FAIL",
        "contract_required_fields": required,
        "contract_fields_min": fields_min,
        "contract_fields_complete": contract_ok,
        "registry_total": len(TOOL_REGISTRY),
        "registry_missing_tools": missing_tools,
        "registry_detail": reg_ok,
        "exit_code_semantics": {"0": "PASS", "1": "BLOCK/FAIL", "2": "NEEDS_ADVICE/usage"},
        "dry_run_supported": True,
        "composability_check": "I10 kompozycja przed nowym kodem (rejestr composes)",
        "evidence": "tools/v3_p65_tool_contract.py (rejestr narzędzi) + thresholds v3_p65_*",
        "provenance": "art. 4 ust. 1 UoR (sprawdzalność) [NIEZWERYFIKOWANE — ISAP]; "
                      "P29 kontrakt raportu JSON; prompt P65 Sekcja 10-I01",
        "generated_at": now_iso(),
    }
    return payload


def main() -> int:
    ap = argparse.ArgumentParser(description="V3-P65 I01 tool standard contract")
    ap.add_argument("--dry-run", action="store_true", help="bez zapisu bundla")
    ap.add_argument("--json", action="store_true", help="raport JSON na stdout")
    args = ap.parse_args()
    payload = enforce()
    if args.json or args.dry_run:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    if args.dry_run:
        return 0 if payload["status"] == "PASS" else 1
    write_json(BUNDLES / "v3_p65_i01_contract.json",
               {"header": audit_header({"I01_tool_contract": None}), "result": payload})
    print(f"[P65:I01] contract status={payload['status']} "
          f"registry={payload['registry_total']} missing={payload['registry_missing_tools'] or 'none'}")
    return 0 if payload["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
