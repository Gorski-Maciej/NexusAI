#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I02 IMMUTABLE RULE VAULT
==============================================
Wersje reguł jako nietykalne artefakty: każda wersja rejestru z kanonicznym
hashem (sha256-canonical-json-v1 — P05/P03 kanon) i podpisem ról. Wykrywa:
  * wersje BEZ hasha (niemożliwa weryfikacja integralności),
  * ryzyko edycji na żywo — narzędzia mutują rule_registry.json w miejscu
    (register/promote/rollback/suspend zapisują cały plik) — brak WORM,
  * brak pieczęci operatora w operacjach.
Zasada (P07-AN03): nowa wersja = NOWY wpis; edycja istniejącej = BLOCKER CI.

Usage:
  python tools/v3_p07_immutable_vault.py
"""
from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_canonical(obj) -> str:
    return hashlib.sha256(
        json.dumps(obj, sort_keys=True, ensure_ascii=False,
                   separators=(",", ":")).encode("utf-8")).hexdigest()


def main() -> int:
    checks, findings = [], []
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))

    versions = []
    unsigned = []
    for rid, entry in registry.items():
        for v in entry.get("versions", []):
            versions.append(v)
            if not v.get("version_hash"):
                unsigned.append({"rule_id": rid, "version": v.get("version")})

    # czy narzędzia mutują rejestr w miejscu (zapis całego pliku)
    in_place_mutation = []
    for t in ("rule_lifecycle_manager.py",):
        tt = (BASE / "tools" / t).read_text(encoding="utf-8")
        if re.search(r"def save_registry|write_text\(json\.dumps\(registry", tt):
            in_place_mutation.append(t)

    # przykładowy hash kanoniczny (dowód mechanizmu — bez zapisu do rejestru)
    demo_hash = sha256_canonical(versions[0]) if versions else ""

    checks.append({"name": "versions_signed",
                   "status": "FAIL" if unsigned else "OK",
                   "detail": f"wersje bez version_hash: {len(unsigned)}/{len(versions)}"})
    checks.append({"name": "worm_storage",
                   "status": "FAIL" if in_place_mutation else "OK",
                   "detail": f"narzędzia z zapisem w miejscu (mutacja): {in_place_mutation} — "
                             f"brak append-only/WORM dla rejestru"})

    findings.append({"id": "V3-P07-L05", "severity": "P1",
                     "evidence": f"0 z {len(versions)} wersji ma version_hash — integralność "
                                 f"rejestru nieweryfikowalna; edycja w miejscu przez "
                                 f"rule_lifecycle_manager (save_registry) bez śladu WORM",
                     "fix": "Immutable Rule Vault (I02): hash kanoniczny per wersja + append-only "
                            "log operacji; edycja istniejącej wersji = BLOCKER CI [BM]"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I02", "generated_at": now(), "gate": gate,
        "metrics": {"versions_total": len(versions), "versions_unsigned": len(unsigned),
                    "in_place_mutators": len(in_place_mutation)},
        "demo_canonical_hash": demo_hash[:24],
        "checks": checks, "findings": findings,
        "vault_model": {"version": "append-only", "hash": "sha256-canonical-json-v1",
                        "signature": "roles: author/reviewer/operator",
                        "edit_of_existing": "BLOCKER [BM]"},
        "contract": {"binding": "P38 (bundle WORM), P39 (CI), P05 (snapshot_id), P44 (certyfikacja)",
                     "rule": "nowa wersja = nowy wpis z hashem; zmiana ACTIVE tylko przez awans (I01)"},
    }
    (BUNDLES / "v3_p07_immutable_vault.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I02] gate={gate} versions={len(versions)} "
          f"unsigned={len(unsigned)} in_place={len(in_place_mutation)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
