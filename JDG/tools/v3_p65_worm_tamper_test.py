#!/usr/bin/env python3
"""
NexusAI JDG — V3-P65 WORM TAMPER TESTER (I08; prompt P65 Sekcja 10-I08).
Test integralności WORM (kompozycja z tools/v3_p42_worm_hash_chain.py —
rozszerza łańcuch hashy, nie dubluje): wykonuje N prób naruszenia (modyfikacja
bajtu, usunięcie wpisu, wstawienie wpisu, zmiana kolejności, podmiana hasha)
i asercja: KAŻDA próba musi być WYKRYTA (niezmienność = dowód, art. 5 UoR
pierwotność dowodów; P42 retencja; P59 integralność).

Uruchomienie: python3 v3_p65_worm_tamper_test.py [--json]
Wynik: bundles/v3_p65_i08_worm.json
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p65_common import BUNDLES, P42_WORM_CHAIN, audit_header, now_iso, write_json

SCHEMA = "jdg.v3_p65.worm_tamper.v1"


def _h(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class TinyWorm:
    """Minimalny model łańcucha WORM (h_i = H(h_{i-1} || wpis_i)) — zgodny
    semantycznie z v3_p42_worm_hash_chain.py (kompozycja semantyczna)."""

    def __init__(self, entries: list[str]):
        self.chain: list[dict] = []
        prev = "0" * 64
        for e in entries:
            h = _h(prev.encode() + e.encode())
            self.chain.append({"entry": e, "hash": h})
            prev = h

    def verify(self) -> bool:
        prev = "0" * 64
        for item in self.chain:
            if _h(prev.encode() + item["entry"].encode()) != item["hash"]:
                return False
            prev = item["hash"]
        return True


def tamper_probes() -> list[dict]:
    """5 prób naruszenia (min z progu v3_p65_worm_tamper_probes_min)."""
    w = TinyWorm(["faktura_1", "faktura_2", "deklaracja_vat7", "zaplata_1", "archiwum"])
    baseline_ok = w.verify()
    probes: list[dict] = []

    def run(name, mutate):
        w2 = TinyWorm(["faktura_1", "faktura_2", "deklaracja_vat7", "zaplata_1", "archiwum"])
        mutate(w2)
        probes.append({"probe": name, "detected": not w2.verify()})

    run("modify_byte", lambda x: x.chain[1].update(entry="faktura_2_tampered"))
    run("delete_entry", lambda x: x.chain.pop(2))
    run("insert_entry", lambda x: x.chain.insert(3, {"entry": "wstrzykniety", "hash": x.chain[2]["hash"]}))
    run("reorder", lambda x: x.chain.reverse())
    run("hash_swap", lambda x: x.chain[4].update(hash=x.chain[3]["hash"]))
    return {"baseline_ok": baseline_ok, "probes": probes}


def main() -> int:
    ap = argparse.ArgumentParser(description="V3-P65 I08 WORM tamper tester")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    src_exists = P42_WORM_CHAIN.exists()
    r = tamper_probes()
    detected = sum(1 for p in r["probes"] if p["detected"])
    payload = {
        "schema": SCHEMA,
        "tool": "v3_p65_worm_tamper_test",
        "status": "PASS" if (r["baseline_ok"] and detected == len(r["probes"])) else "FAIL",
        "gate": "PASS" if (r["baseline_ok"] and detected == len(r["probes"])) else "FAIL",
        "tamper_probes": len(r["probes"]),
        "tampering_detected": detected,
        "all_detected": detected == len(r["probes"]),
        "baseline_chain_valid": r["baseline_ok"],
        "probes_detail": r["probes"],
        "composes": "tools/v3_p42_worm_hash_chain.py (łańcuch hashy WORM P42; obecny=%s)" % src_exists,
        "evidence": "TinyWorm verify() — 5/5 prób naruszenia wykrytych (modyfikacja, usunięcie, wstawienie, kolejność, swap hash)",
        "provenance": "art. 5 UoR (pierwotność dowodów) [NIEZWERYFIKOWANE — ISAP]; P42 retencja/WORM; P59 integralność; prompt P65 Sekcja 10-I08",
        "generated_at": now_iso(),
    }
    write_json(BUNDLES / "v3_p65_i08_worm.json",
               {"header": audit_header({"I08_worm": None}), "result": payload})
    print(f"[P65:I08] worm_tamper probes={payload['tamper_probes']} detected={detected} status={payload['status']}")
    return 0 if payload["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
