#!/usr/bin/env python3
"""NexusAI JDG — CONTRACT DIFF CI GATE (V3-P03-I05)
=====================================================
Bramka: każdy diff OpenAPI wymaga diffu testów (korelacja zmian).
Domknięcie P03-AN06/AN11: zmiana specyfikacji bez zmiany testów = fail merge.

  • fingerprint zmian OpenAPI (VerdictResponse properties) w czasie T0;
  • fingerprint testów kontraktu (tests/test_orchestrator_data_contract.py +
    tests/test_enterprise_operating_contract.py) w czasie T0;
  • para (spec_hash, test_hash) zapisana; kolejne uruchomienie: zmiana spec
    bez zmiany testów → GATE FAIL.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_contract_diff_gate.json"
STATE_FILE = BASE_DIR / "bundles" / "v3_p03_contract_diff_state.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def file_hash(p: Path) -> str:
    if not p.exists():
        return "MISSING"
    return "sha256:" + hashlib.sha256(p.read_bytes()).hexdigest()


def spec_fingerprint() -> str:
    t = (BASE_DIR / "api" / "openapi.yaml").read_text(encoding="utf-8")
    i = t.find("VerdictResponse:")
    if i < 0:
        return "sha256:no-spec"
    j = t.find("properties:", i)
    if j < 0:
        return "sha256:no-props"
    nxt = re.search(r"\n    [A-Za-z_][A-Za-z0-9_]*:", t[j + 11:])
    block = t[j + 11: j + 11 + (nxt.start() if nxt else 4000)]
    fields = re.findall(r"^\s{8}([a-z_][a-z_0-9]*):", block, re.M)
    return "sha256:" + hashlib.sha256("\n".join(sorted(fields)).encode()).hexdigest()


def tests_fingerprint() -> str:
    parts = []
    for p in ("tests/test_orchestrator_data_contract.py",
              "tests/test_enterprise_operating_contract.py",
              "tools/orchestrator_data_contract.py",
              "tools/validate_enterprise_contract.py"):
        parts.append(file_hash(BASE_DIR / p))
    return "sha256:" + hashlib.sha256("|".join(parts).encode()).hexdigest()


def build() -> dict:
    spec = spec_fingerprint()
    tests = tests_fingerprint()

    prev = {}
    if STATE_FILE.exists():
        try:
            prev = json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            prev = {}

    if not prev:
        # Pierwsze uruchomienie: rejestrujemy stan bazowy.
        state = "BASELINE_REGISTERED"
        gate_pass = True
        reason = "pierwsze uruchomienie — zarejestrowano baseline (spec+testy)"
    else:
        spec_changed = prev.get("spec_hash") != spec
        tests_changed = prev.get("tests_hash") != tests
        if spec_changed and not tests_changed:
            state = "DRIFT_SPEC_WITHOUT_TESTS"
            gate_pass = False
            reason = "zmieniono OpenAPI (VerdictResponse) BEZ zmiany testów kontraktu — GATE FAIL (P03-AN11)"
        elif spec_changed and tests_changed:
            state = "CORRELATED_CHANGE"
            gate_pass = True
            reason = "zmiana specyfikacji skorelowana ze zmianą testów — OK"
        else:
            state = "NO_CHANGE"
            gate_pass = True
            reason = "brak zmian specyfikacji i testów"

    return {
        "innovation": "V3-P03-I05",
        "name": "Contract Diff CI Gate — spec↔testy korelacja (P03-AN11)",
        "generated_at": now(),
        "spec_hash": spec,
        "tests_hash": tests,
        "previous": prev,
        "state": state,
        "correlation_rule": "diff OpenAPI (VerdictResponse) bez diffu testów = fail merge; "
                            "testy obejmują: test_orchestrator_data_contract.py, "
                            "test_enterprise_operating_contract.py, validate_enterprise_contract.py",
        "gate": {"pass": gate_pass, "rule": reason},
        "note": "Bramka dwufazowa: (1) baseline, (2) korelacja. Stan w "
                "bundles/v3_p03_contract_diff_state.json — bramka w CI wołana po każdym "
                "diffie OpenAPI; parę (spec,tests) można wymusić przez --force-baseline.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Contract Diff CI Gate (V3-P03-I05)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    ap.add_argument("--force-baseline", action="store_true")
    args = ap.parse_args()

    if args.force_baseline and STATE_FILE.exists():
        STATE_FILE.unlink()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        STATE_FILE.write_text(json.dumps(
            {"spec_hash": data["spec_hash"], "tests_hash": data["tests_hash"],
             "baseline_at": now()}, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)} + stan bramki")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P03-I05 Contract Diff Gate: state={data['state']} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: dryf spec↔testy — zmieniono OpenAPI bez testów")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())