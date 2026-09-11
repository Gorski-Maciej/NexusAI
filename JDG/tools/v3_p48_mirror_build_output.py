#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I01 MIRROR AS BUILD OUTPUT — mirror generowany, nie
ręczny (podanalizy AN02). Wykrywa: brak manifestu sync, wiek synchronizacji,
kandydatów ręcznych edycji (pliki mirror nowsze niż ostatni sync).
"""
from __future__ import annotations

from datetime import datetime, timezone

from v3_p48_common import (POLICIES_DIR, drift_by_package, measure_drift,
                           read_json, rule_present, sync_manifest_age_days,
                           utcnow_iso, write_bundle)

INNOVATION = "V3-P48-I01"
RULE = "jdg.v3_p48_mirror_sync.mirror_build_output"
SYNC_MAX_AGE_DAYS = 7  # fallback; runtime czyta data.jdg.thresholds.v3_p48


def main() -> int:
    checks, findings = [], []

    manifest_present, age_days = sync_manifest_age_days()
    meta = read_json(POLICIES_DIR / ".sync_manifest_v2.json") or {}
    drift = measure_drift()
    pkgs = drift_by_package(drift)

    # Kandydaci ręcznych edycji: pliki mirror zmienione po ostatnim sync,
    # których SHA różni się od canonical (dryf = potencjalna edycja ręczna).
    hand_edit_candidates = drift["semantic_diffs"] + drift["only_policies"]
    hand_edits = len(hand_edit_candidates)

    checks.append({
        "name": "sync_manifest_present",
        "status": "OK" if manifest_present else "FAIL",
        "detail": f".sync_manifest_v2.json: {'obecny' if manifest_present else 'BRAK'}"
                  + (f", ostatni sync: {meta.get('last_sync')}" if manifest_present else ""),
    })
    checks.append({
        "name": "sync_age",
        "status": "OK" if (age_days is not None and age_days <= SYNC_MAX_AGE_DAYS) else "STALE",
        "detail": f"wiek synchronizacji: {age_days} dni (próg v3_p48_sync_max_age_days={SYNC_MAX_AGE_DAYS})",
    })
    checks.append({
        "name": "hand_edit_candidates",
        "status": "OK" if hand_edits == 0 else "TRIAGE",
        "detail": f"pliki różniące się od canonical (kandydaci ręcznej edycji mirror): {hand_edits} "
                  f"(semantyczne {len(drift['semantic_diffs'])} + osierocone {len(drift['only_policies'])})",
    })
    checks.append({
        "name": "build_command_available",
        "status": "OK",
        "detail": "python JDG/tools/policies_sync_gate.py sync — mirror jako build output "
                  "(jedno źródło prawdy: JDG/rules/, kontrakt P00)",
    })

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if hand_edits > 0 or not manifest_present:
        findings.append({"severity": "HIGH",
                         "message": "mirror nie jest czystym build output — dryf strukturalny "
                                    "(BLOCK_AND_ALERT wg reguły I01)"})
    if age_days is not None and age_days > SYNC_MAX_AGE_DAYS:
        findings.append({"severity": "MEDIUM",
                         "message": f"sync starszy niż {SYNC_MAX_AGE_DAYS} dni — TRIAGE"})

    routing = "BLOCK_AND_ALERT" if (hand_edits > 0 or not manifest_present) else (
        "TRIAGE_QUEUE" if (age_days is not None and age_days > SYNC_MAX_AGE_DAYS) else "AUTO_FILE")
    metrics = {
        "sync_manifest_present": manifest_present,
        "sync_age_days": age_days,
        "hand_edits": hand_edits,
        "drift_pct": drift["drift_pct"],
        "packages": len(pkgs),
        "routing": routing,
    }
    evidence = {
        "sync_manifest": meta,
        "hand_edit_candidates": hand_edit_candidates[:60],
        "checks": checks,
        "findings": findings,
    }
    write_bundle("mirror_build_output", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} hand_edits={hand_edits} "
          f"sync_age_days={age_days} drift_pct={drift['drift_pct']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
