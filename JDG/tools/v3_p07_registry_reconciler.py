#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I09 REGISTRY RECONCILER
=============================================
Rekonsyliacja rule_registry.json ↔ kod (P07-AN10) w CI:
  * rule_id w KODZIE (unikalne) vs rule_id w REJESTRZE,
  * reguły w kodzie BEZ wpisu rejestru (niezarządzane lifecycle),
  * wpisy rejestru NIEOBECNE w kodzie (ghost registry — usunięte z kodu?),
  * dryf = luka zarządzania cyklem życia.

Usage:
  python tools/v3_p07_registry_reconciler.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    registered = set(registry.keys())

    code_ids = set()
    for p in (BASE / "rules").rglob("*.rego"):
        t = p.read_text(encoding="utf-8")
        for m in re.finditer(r'"rule_id"\s*:\s*"(jdg\.[A-Za-z0-9_.]+)"', t):
            code_ids.add(m.group(1))

    unmanaged = code_ids - registered
    ghosts = registered - code_ids
    coverage = 100.0 * len(registered) / max(len(code_ids), 1)

    checks.append({"name": "registry_coverage",
                   "status": "FAIL" if coverage < 95 else "OK",
                   "detail": f"pokrycie rejestru: {len(registered)}/{len(code_ids)} "
                             f"({coverage:.2f}%)"})
    checks.append({"name": "ghost_entries",
                   "status": "FAIL" if ghosts else "OK",
                   "detail": f"wpisy rejestru bez reguły w kodzie: {sorted(ghosts) or 'brak'}"})

    findings.append({"id": "V3-P07-L01", "severity": "P0",
                     "evidence": f"rule_registry.json zarządza {len(registered)} z "
                                 f"{len(code_ids)} reguł w kodzie (pokrycie {coverage:.2f}%) — "
                                 f"{len(unmanaged)} reguł poza cyklem życia "
                                 f"(brak shadow/candidate/rollback dla nich)",
                     "fix": "Registry Reconciler (I09): automatyczna rejestracja nowych rule_id "
                            "w CI (CANDIDATE) + alert na dryf > 1%; docelowo pełne pokrycie "
                            "przez P07–P36"})
    if ghosts:
        findings.append({"id": "V3-P07-L14", "severity": "P1",
                         "evidence": f"wpisy rejestru bez reguły w kodzie (ghost registry): "
                                     f"{sorted(ghosts)} — reguła usunięta z kodu, rejestr "
                                     f"niezaktualizowany",
                         "fix": "retire/purge (I06) wpisów ghost po weryfikacji zerowych odwołań"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I09", "generated_at": now(), "gate": gate,
        "metrics": {"code_rule_ids": len(code_ids), "registered": len(registered),
                    "unmanaged": len(unmanaged), "ghosts": len(ghosts),
                    "coverage_pct": round(coverage, 2)},
        "ghost_entries": sorted(ghosts),
        "unmanaged_sample": sorted(unmanaged)[:10],
        "checks": checks, "findings": findings,
        "contract": {"binding": "P07–P36 (rejestracja reguł domenowych), P39 (CI — rekonsyliacja "
                                "[BM]), P00 (mapa kanoniczna rule_id)",
                     "rule": "nowy rule_id w kodzie bez wpisu rejestru = alert; po P09 — blokada "
                             "merge [BM]"},
    }
    (BUNDLES / "v3_p07_registry_reconciler.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I09] gate={gate} code={len(code_ids)} registered={len(registered)} "
          f"coverage={coverage:.2f}% ghosts={len(ghosts)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
