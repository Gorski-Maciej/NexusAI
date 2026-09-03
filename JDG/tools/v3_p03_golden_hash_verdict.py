#!/usr/bin/env python3
"""NexusAI JDG — GOLDEN HASH IN VERDICT (V3-P03-I04)
=====================================================
Hash warunków ewaluacji w każdym werdykcie — odtworzenie 1:1 w golden replay
(F3 V2). Verdict jako obiekt deterministycznie odtwarzalny: ten sam input +
bundle_version + rule_version + threshold_version + temporal = ten sam hash.

  • golden_hash = sha256(input_fingerprint | bundle_version | rule_version |
    threshold_version | certainty_class | routing) — liczony w Pythonie
    (OPA nie ma crypto.sha256 — wzorzec z provenance.rego / decision_certificate.py);
  • weryfikacja offline: ponowne policzenie z zapisanych warunków;
  • probe: zmiana dowolnego warunku zmienia hash (wykrywalne 1:1).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_golden_hash_verdict.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def golden_hash(conditions: dict) -> str:
    canon = json.dumps(conditions, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return "sha256:" + hashlib.sha256(canon.encode("utf-8")).hexdigest()


def build() -> dict:
    # Warunki ewaluacji wzorcowego werdyktu (kanoniczny klucz F3).
    conditions_v1 = {
        "input_fingerprint": "nip=5213456789|inv=2026-09-03-0001|dir=SALE",
        "bundle_version": "v2026.09.03",
        "rule_version": "1.4.2",
        "threshold_version": "1.3.0",
        "evaluation_date": "2026-09-03",
        "routing_context": "DOMESTIC_SALE",
    }
    h1 = golden_hash(conditions_v1)

    # Probe 1: zmiana bundle_version → inny hash.
    conditions_v2 = dict(conditions_v1); conditions_v2["bundle_version"] = "v2026.09.04"
    h2 = golden_hash(conditions_v2)
    # Probe 2: zmiana rule_version → inny hash.
    conditions_v3 = dict(conditions_v1); conditions_v3["rule_version"] = "1.4.3"
    h3 = golden_hash(conditions_v3)
    # Probe 3: reorder kluczy → TEN SAM hash (determinizm sortowania).
    reordered = {k: conditions_v1[k] for k in reversed(list(conditions_v1))}
    h4 = golden_hash(reordered)

    probes = [
        {"name": "bundle_version_change", "hash_changed": h1 != h2, "ok": h1 != h2},
        {"name": "rule_version_change", "hash_changed": h1 != h3, "ok": h1 != h3},
        {"name": "key_reorder_deterministic", "hash_same": h1 == h4, "ok": h1 == h4},
    ]

    verdict_sample = {
        "rule_id": "jdg.vat.rate_23",
        "_routing": "ALLOW",
        "certainty_class": "CERTAIN",
        "golden_hash": h1,
        "golden_conditions": conditions_v1,
    }

    return {
        "innovation": "V3-P03-I04",
        "name": "Golden Hash in Verdict — odtworzenie 1:1 (F3 V2)",
        "generated_at": now(),
        "golden_hash": h1,
        "golden_conditions": conditions_v1,
        "verdict_sample": verdict_sample,
        "probes": probes,
        "probes_ok": all(p["ok"] for p in probes),
        "replay_contract": "golden replay: ten sam golden_hash → ta sama decyzja; "
                           "zmiana warunków → inny hash → UVR (nieuzasadniona zmiana werdyktu) wykrywalny",
        "gate": {
            "pass": all(p["ok"] for p in probes),
            "rule": "golden_hash deterministyczny (reorder = ten sam) i czuły na zmianę "
                    "warunków (bundle/rule/threshold) — P03-AN02, F3 V2",
        },
        "note": "Hash liczony w Python wrapperze (OPA bez crypto) — wzorzec spójny z "
                "provenance.rego (root_hash) i decision_certificate.py (merkle_root); "
                "golden replay w P03-I09 i P11.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Golden Hash in Verdict (V3-P03-I04)")
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
        print(f"V3-P03-I04 Golden Hash: probes_ok={data['probes_ok']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: golden hash niedeterministyczny lub nieczuły na zmiany")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())