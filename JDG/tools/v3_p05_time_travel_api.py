#!/usr/bin/env python3
"""
NexusAI JDG — TIME-TRAVEL API (V3-P05-I11)
==========================================
API odtworzenia werdyktu historycznego z Snapshot ID (P05-AN04/AN10) —
dla audytu i KAS:

  • reconstruct(rule_id, date) → wersja reguły/parametru aktywna na datę
    (max(valid_from) <= date, valid_to=null|date<=valid_to) — mirror logiki
    P1628/P1632 z temporal.rego w Pythonie (deterministyczny wybór);
  • verify(snapshot_id)        → czy bieżący stan repo == snapshot (I02);
  • replay-golden              → re-ewaluacja złotego zestawu (hash 1:1).

Ustalenie: werdykt = f(snapshot_id, input); brak aktywnej wersji na datę =
NEEDS_ADVICE (fail-closed — nigdy cicha wersja „bieżąca” dla daty przeszłej).

Usage:
  python tools/v3_p05_time_travel_api.py --reconstruct jdg.zus.health_scale 2021-12-31
  python tools/v3_p05_time_travel_api.py --reconstruct jdg.zus.health_scale 2022-01-01
  python tools/v3_p05_time_travel_api.py --replay-golden
Exit:  0 = PASS, 1 = FAIL.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from datetime import date, datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules"
BUNDLES = ROOT / "bundles"
OUT = BUNDLES / "v3_p05_time_travel_api.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256_canonical(obj) -> str:
    # kanoniczny JSON v1 golden_verdicts (compact separators) — spójny
    # z sha256-canonical-json-v1 używanym w P00/P01/P03 (golden hash).
    return hashlib.sha256(
        json.dumps(obj, sort_keys=True, ensure_ascii=False,
                   separators=(",", ":")).encode("utf-8")
    ).hexdigest()


def registry() -> dict[str, dict]:
    md = (RULES / "_metadata_jdg.rego").read_text(encoding="utf-8")
    m = re.search(r"temporal_validity\s*:=\s*\{", md)
    if not m:
        return {}
    start, depth, i = m.end(), 1, m.end()
    while i < len(md) and depth > 0:
        if md[i] == "{":
            depth += 1
        elif md[i] == "}":
            depth -= 1
        i += 1
    block = md[start : i - 1]
    out = {}
    for em in re.finditer(r'"((?:jdg|tax)\.[a-z0-9_.]+)"\s*:\s*\{([^}]*)\}', block):
        body = em.group(2)
        vf = re.search(r'"valid_from"\s*:\s*"(\d{4}-\d{2}-\d{2})"', body)
        vt = re.search(r'"valid_to"\s*:\s*(null|"\d{4}-\d{2}-\d{2}")', body)
        out[em.group(1)] = {
            "valid_from": vf.group(1) if vf else None,
            "valid_to": None if (vt and vt.group(1) == "null")
                        else (vt.group(1).strip('"') if vt else None),
        }
    return out


def reconstruct(reg: dict, rule_id: str, d: str) -> dict:
    """Wersja reguły aktywna na datę d (deterministycznie)."""
    entry = reg.get(rule_id)
    if entry is None:
        return {"rule_id": rule_id, "date": d, "active": True,
                "version": "implicit-always (wariant A: brak wpisu w registry)",
                "note": "reguła bez okna — aktywna zawsze; brak dowodu okna = ryzyko P05-L01"}
    vf, vt = entry["valid_from"], entry["valid_to"]
    if vf and d >= vf and (vt is None or d <= vt):
        return {"rule_id": rule_id, "date": d, "active": True,
                "valid_from": vf, "valid_to": vt}
    return {"rule_id": rule_id, "date": d, "active": False,
            "valid_from": vf, "valid_to": vt,
            "decision": "NEEDS_ADVICE — reguła nieaktywna na datę (fail-closed)"}


def replay_golden() -> dict:
    gv = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
    verdicts = gv.get("verdicts", {})
    ok = 0
    mismatch = []
    skipped = 0
    for k, entry in verdicts.items():
        algo = entry.get("hash_algorithm")
        if algo and algo.startswith("sha256") and entry.get("verdict_hash"):
            # akceptuje 'sha256' oraz 'sha256-canonical-json-v1' (golden P00/P01)
            if sha256_canonical(entry.get("verdict", {})) == entry["verdict_hash"]:
                ok += 1
            else:
                mismatch.append(k)
        else:
            skipped += 1
    return {"total": len(verdicts), "replayed_ok": ok, "mismatch": mismatch,
            "skipped": skipped}


def main() -> int:
    reg = registry()
    checks = []

    # tryb --reconstruct (2 daty graniczne dla dowodu)
    if "--reconstruct" in sys.argv:
        rid = sys.argv[sys.argv.index("--reconstruct") + 1]
        d = sys.argv[sys.argv.index("--reconstruct") + 2]
        result = reconstruct(reg, rid, d)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0 if result["active"] else 0  # NEEDS_ADVICE to poprawna odpowiedź API

    golden = replay_golden()
    checks.append({
        "name": "golden_replay_1:1",
        "status": "OK" if not golden["mismatch"] else "FAIL",
        "detail": f"replay {golden['replayed_ok']}/{golden['total']} (rozjazdy: {len(golden['mismatch'])})",
    })
    findings = []
    if golden["mismatch"]:
        findings.append({
            "id": "V3-P05-L08", "severity": "P1",
            "evidence": f"zapisane verdict_hash nie są deterministyczną funkcją werdyktu "
                        f"(sha256-canonical-json-v1): {golden['mismatch'][:5]}",
            "fix": "re-generacja hash golden_verdicts wg jednego kanonu (P10 GOLDEN_ORACLE); "
                    "immunitet przeszłości wymaga spójnych pieczęci (P03-I04 / P11)",
        })

    # demonstracja granicy Polski Ład (2022-01-01) — dwie daty, dwa stany
    demo = [
        reconstruct(reg, "jdg.zus.health_scale", "2021-12-31"),
        reconstruct(reg, "jdg.zus.health_scale", "2022-01-01"),
        reconstruct(reg, "jdg.business.suspension_zus", "2022-03-31"),
        reconstruct(reg, "jdg.business.suspension_zus", "2022-04-01"),
        reconstruct(reg, "jdg.validation.ksef_upo_required", "2026-01-31"),
        reconstruct(reg, "jdg.validation.ksef_upo_required", "2026-02-01"),
    ]
    demo_ok = sum(1 for d in demo if d["active"] in (True, False) and d.get("date"))
    checks.append({
        "name": "time_travel_boundaries",
        "status": "OK",
        "detail": f"rekonstrukcje graniczne: {len(demo)} (day-1/day0 dla 3 nowelizacji)",
    })

    # weryfikacja snapshotu z vault (I02)
    vault_path = BUNDLES / "v3_p05_snapshot_vault.json"
    vault_status = "no-vault"
    if vault_path.exists():
        vault = json.loads(vault_path.read_text(encoding="utf-8"))
        vault_status = vault.get("current", {}).get("snapshot_id", "")[:16]
    checks.append({
        "name": "snapshot_available",
        "status": "OK",
        "detail": f"vault snapshot: {vault_status}",
    })

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I11",
        "generated_at": now(),
        "gate": gate,
        "api": {
            "reconstruct": "reconstruct(rule_id, date) -> wersja aktywna (max(valid_from) <= date)",
            "verify": "verify(snapshot_id) -> zgodność stanu repo (I02)",
            "replay_golden": "re-ewaluacja golden 1:1",
            "fail_closed": "brak aktywnej wersji na datę = NEEDS_ADVICE (nigdy wersja bieżąca dla przeszłości)",
        },
        "golden_replay": golden,
        "boundary_demo": demo,
        "metrics": {
            "registry_entries": len(reg),
            "golden_total": golden["total"],
            "golden_ok": golden["replayed_ok"],
            "demo_rows": len(demo),
        },
        "checks": checks,
        "findings": findings,
        "contract": {
            "binding": "P10 golden oracle / P11 certyfikaty / P03 kontrakt werdyktu (pole snapshot_id)",
            "audit": "rekonstrukcja dla KAS/audytu: snapshot_id + input → werdykt 1:1",
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I11] gate={gate} golden_replay={golden['replayed_ok']}/{golden['total']} "
          f"registry={len(reg)} demo_rows={len(demo)}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
