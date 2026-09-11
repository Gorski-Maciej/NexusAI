#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I11 MIRROR LIFECYCLE ALIGNMENT — mirror dziedziczy
lifecycle z canonical: SHADOW w canonical = SHADOW w mirror; zero rozjazdu
statusów (podanalizy AN02). Porównuje rule_registry.json (canonical statuses)
z rejestrem mirrorowanym (mirror dziedziczy 1:1, o ile plik mirror == canonical).
"""
from __future__ import annotations

import hashlib
import json

from v3_p48_common import (BASE, POLICIES_DIR, RULES_DIR, read_json,
                           rule_present, sha256, write_bundle)

INNOVATION = "V3-P48-I11"
RULE = "jdg.v3_p48_mirror_sync.lifecycle_alignment"


def main() -> int:
    checks, findings = [], []

    registry = read_json(BASE / "bundles" / "rule_registry.json") or {}
    p48_entries = {k: v for k, v in registry.items() if k.startswith("jdg.v3_p48_")}

    compared = 0
    mismatches = 0
    mismatch_detail = []
    for rid, entry in sorted(p48_entries.items()):
        versions = entry.get("versions") or [entry]
        latest = versions[-1] if versions else {}
        status = latest.get("status", "UNKNOWN")
        # Mirror dziedziczy 1:1 z canonical (build output, I01): porównanie
        # SHA-256 pliku canonical vs mirror (o ile plik istnieje w obu).
        src_file = RULES_DIR / "v3_p48_mirror_sync.rego"
        mirror_file = POLICIES_DIR / "v3_p48_mirror_sync.rego"
        if src_file.exists() and mirror_file.exists():
            compared += 1
            if sha256(src_file) != sha256(mirror_file):
                mismatches += 1
                mismatch_detail.append({"rule_id": rid, "status": status,
                                        "issue": "canonical != mirror (SHA-256)"})
        else:
            compared += 1
            mismatches += 1
            mismatch_detail.append({"rule_id": rid, "status": status,
                                    "issue": "brak pliku w canonical lub mirror"})

    checks.append({
        "name": "registry_p48_entries",
        "status": "OK",
        "detail": f"wpisy v3_p48 w rule_registry: {len(p48_entries)}",
    })
    checks.append({
        "name": "lifecycle_inheritance",
        "status": "OK" if mismatches == 0 else "BLOCK",
        "detail": f"porównane dziedziczenia: {compared}, rozjazdy: {mismatches} "
                  "(mirror dziedziczy status z canonical przez build output)",
    })
    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if mismatches:
        findings.append({"severity": "HIGH",
                         "message": "rozjazd lifecycle canonical vs mirror — mirror musi dziedziczyć "
                                    "status przez build output (BLOCK_AND_ALERT wg reguły I11)"})

    routing = "BLOCK_AND_ALERT" if mismatches else ("TRIAGE_QUEUE" if compared == 0 else "AUTO_FILE")
    metrics = {
        "compared_rules": compared,
        "status_mismatches": mismatches,
        "registry_entries": len(p48_entries),
        "routing": routing,
    }
    evidence = {"mismatch_detail": mismatch_detail[:20], "checks": checks, "findings": findings}
    write_bundle("lifecycle_alignment", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} compared={compared} mismatches={mismatches}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
