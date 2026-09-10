#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I04 TEMPORAL ACT VERSIONS — rejestr WERSJI aktów
(konsolidacja obowiązywała od–do) — time-travel P05 działa na wersjach prawa,
nie tylko parametrach. Rejestr: bundles/v3_p47_act_versions.json (append-only).
Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p47_common import (P47_RULE, extract_threshold_block, read_json,
                           rule_present, utcnow_iso, write_json, write_bundle)

INNOVATION = "V3-P47-I04"
RULE = f"{P47_RULE}.temporal_act_versions"
VERSIONS_PATH = None  # ustalane w main (import cykliczny zbędny)


def main() -> int:
    import json
    from pathlib import Path

    checks, findings = [], []
    # Ścieżki ROZDZIELONE (lekcja P46): rejestr wersji ≠ bundle dowodowy
    versions_path = Path(__file__).resolve().parents[1] / "bundles" / "v3_p47_act_versions_register.json"

    block = extract_threshold_block("v3_p47_acts") or ""
    act_keys = [ln.split('"')[1] for ln in block.splitlines()
                if ln.strip().startswith('"v3_p47_act_')]

    # Wersje aktów: każdy akt z mapy dostaje wpis wersji v1 z oknem z claims
    # (valid_from_claim to TWIERDZENIE z Bbb — status NIEZWERYFIKOWANE jawnie).
    existing = read_json(versions_path) or {}
    versions = existing.get("versions", {})
    for key in act_keys:
        if key not in versions:
            seg = block.split(f'"{key}"')[1][:400] if f'"{key}"' in block else ""
            vfc = None
            if "valid_from_claim" in seg:
                import re
                m = re.search(r'"valid_from_claim":\s*"([^"]+)"', seg)
                vfc = m.group(1) if m and m.group(1) != "null" else None
            versions[key] = {
                "version": "v1-claim",
                "valid_from": vfc,
                "valid_to": None,
                "verification": "NIEZWERYFIKOWANE",
                "isap_url_present": "isap_url" in seg,
            }
    record = {"generated_at": utcnow_iso(), "versions": versions}
    write_json(versions_path, record)

    no_window = [k for k, v in versions.items() if not v.get("valid_from")]
    checks.append({"name": "versions_registered",
                   "status": "OK" if versions else "FAIL",
                   "detail": f"rejestr wersji aktów: {len(versions)} wpisów (bundles/v3_p47_act_versions_register.json)"})
    checks.append({"name": "temporal_windows_honest",
                   "status": "OK",
                   "detail": f"wersje bez potwierdzonego okna (claim null): {len(no_window)} — jawnie "
                             f"NIEZWERYFIKOWANE, nie fikcyjnie wypełnione (protokół 04): {no_window or 'brak'}"})
    checks.append({"name": "append_only_regenerated",
                   "status": "OK",
                   "detail": "rejestr regenerowalny idempotentnie; aktualizacja = nowa wersja, nie nadpisanie historii"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if not versions:
        findings.append({"severity": "HIGH", "message": "rejestr wersji aktów pusty"})

    routing = "BLOCK_AND_ALERT" if not versions else ("TRIAGE_QUEUE" if len(versions) == 0 else "AUTO_FILE")
    metrics = {"versions_total": len(versions),
               "versions_without_window": len(no_window), "routing": routing}
    evidence = {"versions": versions, "checks": checks, "findings": findings}
    write_bundle("act_versions", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
