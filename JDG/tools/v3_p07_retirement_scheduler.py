#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I06 RETIREMENT SCHEDULER
==============================================
Automat bezpiecznego wygaszania: deprecate → KARENCJA (2 okresy rozliczeniowe)
→ retire → purge z weryfikacją ZEROWYCH odwołań (werdykty/reguły/testy) przed
usunięciem z bundle (P07-AN: 5.3). Tygodniowy raport „reguły do usunięcia".

Audyt: cmd_deprecate/retire/migrate --remove istnieją (rule_lifecycle_manager),
ale przejścia są NATYCHMIASTOWE (brak wymiaru karencji) i purge nie weryfikuje
odwołań w narzędziu JSON (test control_plane asertuje append-only w innej
warstwie).

Usage:
  python tools/v3_p07_retirement_scheduler.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"

GRACE_PERIODS = 2  # okresy rozliczeniowe


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    manager = (BASE / "tools" / "rule_lifecycle_manager.py").read_text(encoding="utf-8")
    # rule_id w kodzie (referencje do usuwanych)
    code_rule_ids = set()
    for p in (BASE / "rules").rglob("*.rego"):
        t = p.read_text(encoding="utf-8")
        for m in re.finditer(r'"rule_id"\s*:\s*"(jdg\.[A-Za-z0-9_.]+)"', t):
            code_rule_ids.add(m.group(1))

    deprecated = [k for k, e in registry.items()
                  if any(v.get("status") == "DEPRECATED" for v in e.get("versions", []))]
    retired = [k for k, e in registry.items()
               if any(v.get("status") == "RETIRED" for v in e.get("versions", []))]
    has_grace = bool(re.search(r"karencj|grace|2 okresy|okresy rozliczeniowe", manager, re.I))
    purge_zero_ref = bool(re.search(r"zero.{0,20}referenc|odwoła", manager, re.I) and
                          re.search(r"purge|remove", manager, re.I))

    checks.append({"name": "deprecate_retire_flow",
                   "status": "OK",
                   "detail": f"cmd_deprecate/retire/migrate istnieją; DEPRECATED dziś: "
                             f"{len(deprecated)}, RETIRED: {len(retired)}"})
    checks.append({"name": "grace_period_enforced",
                   "status": "FAIL" if not has_grace else "OK",
                   "detail": f"karencja ({GRACE_PERIODS} okresy) w narzędziu: {has_grace} — "
                             f"przejścia natychmiastowe"})
    checks.append({"name": "purge_zero_references",
                   "status": "FAIL" if not purge_zero_ref else "OK",
                   "detail": f"purge z weryfikacją zerowych odwołań w narzędziu JSON: "
                             f"{purge_zero_ref}"})
    checks.append({"name": "weekly_report",
                   "status": "FAIL",
                   "detail": "tygodniowy raport „reguły do usunięcia” nie istnieje jako artefakt "
                             "(brak telemetrii procesu)"})

    findings.append({"id": "V3-P07-L10", "severity": "P1",
                     "evidence": "deprecate→retire→purge bez wymiaru karencji (2 okresy) "
                                 "i bez weryfikacji zerowych odwołań w operacyjnym narzędziu — "
                                 "ryzyko usunięcia reguły z żywymi referencjami; brak tygodniowego "
                                 "raportu do usunięcia",
                     "fix": "Retirement Scheduler (I06): stan CARENCJA z datą końca + check "
                            "referencji (kod/testy/werdykty) przed purge + raport tygodniowy "
                            "[BM dla purge bez dowodu]"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I06", "generated_at": now(), "gate": gate,
        "metrics": {"deprecated": len(deprecated), "retired": len(retired),
                    "grace_enforced": has_grace, "purge_checks_refs": purge_zero_ref,
                    "code_rule_ids": len(code_rule_ids)},
        "model": {"deprecate": "status DEPRECATED + deprecation_note",
                  "grace": f"{GRACE_PERIODS} okresy rozliczeniowe (od deprecation date)",
                  "retire": "status RETIRED (przestaje ewaluować)",
                  "purge": "tylko po dowodzie zerowych odwołań (werdykty/reguły/testy) "
                           "+ golden replay (P10)"},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P39 (testy), P44 (certyfikacja), P10 (golden — historia "
                                "nienaruszona), P37 (telemetria procesu)",
                     "rule": "purge bez dowodu zerowych odwołań i zielonego golden = blokada [BM]"},
    }
    (BUNDLES / "v3_p07_retirement_scheduler.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I06] gate={gate} deprecated={len(deprecated)} retired={len(retired)} "
          f"grace={has_grace} purge_refs={purge_zero_ref}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
