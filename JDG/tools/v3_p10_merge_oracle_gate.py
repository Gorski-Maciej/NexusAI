#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I03 MERGE ORACLE GATE
============================================
Bramka CI: merge zablokowany dopóki każda delta golden nie ma wyroku
(zero nieuzasadnionych zmian = UVR 0). Sprawdza, czy w CI istnieje
wywołanie golden_replay report/gate i czy jest BLOKUJĄCE (nie || true).

Usage:
  python tools/v3_p10_merge_oracle_gate.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
CI_DIR = BASE.parent / ".github" / "workflows"
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    ci_text = ""
    if CI_DIR.exists():
        for wf in CI_DIR.glob("*.yml"):
            ci_text += wf.read_text(encoding="utf-8", errors="replace")

    has_golden_call = "golden_replay" in ci_text or "golden" in ci_text.lower()
    # bramka musi być twarda: wywołanie bez '|| true' i z kodem wyjścia
    blocking = bool(re_search_blocking(ci_text))

    checks.append({"name": "golden_in_ci", "status": "OK" if has_golden_call else "FAIL",
                   "detail": f"golden oracle obecny w CI: {has_golden_call}"})
    checks.append({"name": "blocking_gate", "status": "OK" if blocking else "FAIL",
                   "detail": "bramka blokująca merge (bez || true): "
                             f"{'TAK' if blocking else 'NIE — wywołanie z || true (miękkie)'}"})

    if has_golden_call and not blocking:
        findings.append({"id": "V3-P10-L03", "severity": "P0",
                         "evidence": "jdg-quality-gates-blocking.yml woła "
                                     "'golden_replay.py report >/dev/null 2>&1 || true' — bramka "
                                     "miękka: UVR>0 nie blokuje merge (fail-open na poziomie CI)",
                         "fix": "I03: zamienić na twardą bramkę 'golden_replay.py gate' (exit 1 przy "
                                "UVR>0 lub delcie bez wyroku) w jdg-quality-gates-blocking.yml"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I03",
        "name": "Merge Oracle Gate — zero nieuzasadnionych delt przed merge",
        "generated_at": now(),
        "gate": gate,
        "metrics": {"golden_in_ci": has_golden_call, "blocking": blocking},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P39 (testy/CI), P38 (deploy), P07 (awans reguł)",
                     "rule": "merge zablokowany, dopóki UVR > 0 lub delta bez wyroku (P10-I02)"}}
    (BUNDLES / "v3_p10_merge_oracle_gate.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I03] gate={gate} in_ci={has_golden_call} blocking={blocking}")
    return 1 if gate == "FAIL" else 0


def re_search_blocking(text: str) -> bool:
    import re
    # znajdź wywołania golden bez '|| true' w tej samej linii
    for line in text.splitlines():
        if "golden" in line.lower() and "||" not in line and "echo" not in line:
            return True
    return False


if __name__ == "__main__":
    raise SystemExit(main())
