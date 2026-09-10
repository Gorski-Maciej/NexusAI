#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I05 SIGNED PARAMETER BUNDLES — podpis integralności
parametrów jak kod (P38): checksuma SHA-256 dokumentu thresholds_data, wpis do
rejestru wersji (append-only WORM-lite), weryfikacja manipulacji (--verify
porównuje checksumę bieżącą z ostatnią zarejestrowaną — rozjazd = tampered).
Usage: python tools/v3_p46_sign_bundles.py [--verify]
"""
from __future__ import annotations

import argparse

from v3_p46_common import (BUNDLES_DIR, THRESHOLDS_DATA, read_json, sha256_file,
                           utcnow_iso, write_bundle, write_json)

REGISTER = BUNDLES_DIR / "v3_p46_parameter_versions.json"


def load_register() -> dict:
    reg = read_json(REGISTER, {}) or {}
    if "records" not in reg:
        reg = {
            "register_version": "v3_p46_param_versions-2026.09",
            "append_only": True,
            "records": [],
        }
    return reg


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    reg = load_register()
    checksum = sha256_file(THRESHOLDS_DATA)
    last = reg["records"][-1] if reg["records"] else None
    tampered = bool(args.verify and last and last.get("sha256") != checksum)
    if not args.verify:
        if not last or last.get("sha256") != checksum:
            reg["records"].append({
                "recorded_at": utcnow_iso(),
                "sha256": checksum,
                "algorithm": "SHA-256",
                "worm_append_only": True,
            })
            write_json(REGISTER, reg)
    without_checksum = [] if checksum else ["thresholds_data.json"]
    metrics = {
        "signed_bundles": 1,
        "without_checksum": len(without_checksum),
        "tampered": 1 if tampered else 0,
        "records": len(reg["records"]),
        "sha256": checksum,
        "routing": ("BLOCK_AND_ALERT" if tampered
                    else "BLOCK_AND_ALERT" if without_checksum else "AUTO_FILE"),
    }
    write_bundle("signed_bundles", "V3-P46-I05", metrics, {
        "document": "bundles/thresholds_data.json",
        "register": "bundles/v3_p46_parameter_versions.json",
        "verify_mode": args.verify,
        "note": "Integralność wartości = integralność reguł (P38); rozjazd checksum = tampered.",
    })
    print(f"[v3_p46_sign_bundles] sha256={checksum[:16]}… tampered={tampered} "
          f"records={len(reg['records'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
