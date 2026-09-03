#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I03 PARAMETER LINEAGE
===========================================
Dwukierunkowy graf reguła↔parametr z automatyczną analizą wpływu nowelizacji.
  * reguła → mapa parametrów (data.thresholds.jdg.<map>[.<leaf>])
  * mapa → reguły (które pliki/pakiety czytają daną mapę)
  * ORPHAN  — mapa zdefiniowana w thresholds_jdg.rego, nieużywana przez reguły
  * GHOST   — referencja do mapy niezdefiniowanej (cichy brak danych)
  * DEFAULT — object.get fallback (liczba wystąpień per mapa)

Usage:
  python tools/v3_p06_parameter_lineage.py
"""
from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
RULES = BASE / "rules"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    t = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    top_maps = re.findall(r'^([a-z][a-z0-9_]*)\s*:?=\s*\{', t, re.M)
    defined = set(top_maps)

    map_to_rules = defaultdict(set)
    default_count = Counter()
    for p in sorted(RULES.rglob("*.rego")):
        rel = str(p.relative_to(RULES))
        if p.name == "thresholds_jdg.rego":
            continue
        tt = p.read_text(encoding="utf-8")
        for m in re.finditer(r"data\.thresholds\.jdg\.([A-Za-z0-9_]+)", tt):
            map_to_rules[m.group(1)].add(rel)
        for m in re.finditer(r"object\.get\(\s*data\.thresholds\.jdg\.([A-Za-z0-9_]+)"
                             r"\s*,\s*\"[A-Za-z0-9_.]+\"\s*,\s*[^)]*\)", tt):
            default_count[m.group(1)] += 1

    used_maps = set(map_to_rules)
    orphan = sorted(defined - used_maps)
    ghost = sorted(used_maps - defined)
    leafs = re.findall(r'^\s{4}"([A-Za-z0-9_]+)"\s*:\s*(\-?\d+(?:\.\d+)?)', t, re.M)
    leaf_of = defaultdict(list)
    for k, v in leafs:
        leaf_of[k].append(v)

    # top użycia
    usage = Counter({k: len(v) for k, v in map_to_rules.items()})

    checks.append({"name": "orphan_maps",
                   "status": "FAIL" if orphan else "OK",
                   "detail": f"mapy zdefiniowane a nieużywane: {len(orphan)} z {len(defined)}"})
    checks.append({"name": "ghost_maps",
                   "status": "FAIL" if ghost else "OK",
                   "detail": f"referencje do niezdefiniowanych map: {ghost}"})
    checks.append({"name": "silent_defaults",
                   "status": "WARN" if default_count else "OK",
                   "detail": f"object.get z fallbackiem: {sum(default_count.values())} wystąpień "
                             f"w {len(default_count)} mapach"})

    if orphan:
        findings.append({"id": "V3-P06-L03", "severity": "P1",
                         "evidence": f"mapy ORPHAN (dane martwe, 617 liści w {len(orphan)} mapach): "
                                     f"{orphan[:12]}... — koszt utrzymania i ryzyko rozjazdu",
                         "fix": "przegląd i usunięcie/przeniesienie do JSON store tylko używanych; "
                                "rejestr deklaratywny map (P06-I07)"})
    if ghost:
        findings.append({"id": "V3-P06-L06", "severity": "P1",
                         "evidence": f"referencje GHOST do niezdefiniowanych map: {ghost} — "
                                     f"reguła liczy na dane, których warstwa danych nie dostarcza",
                         "fix": "definicja map w thresholds_jdg.rego lub poprawa referencji"})
    if default_count:
        findings.append({"id": "V3-P06-L07", "severity": "P2",
                         "evidence": f"{sum(default_count.values())} cichych fallbacków object.get "
                                     f"(top: {default_count.most_common(5)}) — wartość z kodu zamiast "
                                     f"danych; brak sygnału przy braku parametru",
                         "fix": "fail-closed: brak parametru = NEEDS_ADVICE zamiast defaultu; "
                                "fallback tylko dla pól niekrytycznych"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I03", "generated_at": now(), "gate": gate,
        "metrics": {"maps_defined": len(defined), "maps_used": len(used_maps),
                    "orphan_maps": len(orphan), "ghost_maps": len(ghost),
                    "silent_defaults": sum(default_count.values()),
                    "leaf_params": len(leafs)},
        "usage_top": usage.most_common(10),
        "orphan": orphan, "ghost": ghost,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06-I03 → analiza wpływu nowelizacji (P08 Law Radar), "
                                "P07 lifecycle, P10 golden",
                     "rule": "każda zmiana parametru = lista dotkniętych reguł z lineage "
                             "(mapa→reguły) + testy [BM]"},
    }
    (BASE / "bundles" / "v3_p06_parameter_lineage.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I03] gate={gate} maps={len(defined)} used={len(used_maps)} "
          f"orphan={len(orphan)} ghost={len(ghost)} defaults={sum(default_count.values())}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
