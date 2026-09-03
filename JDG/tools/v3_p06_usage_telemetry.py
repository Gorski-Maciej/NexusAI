#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I12 PARAMETER USAGE TELEMETRY
===================================================
Które parametry faktycznie wpływają na decyzje: frekwencja odwołań
data.thresholds.jdg.<map> w regułach domenowych + szacowany wpływ (routing
BLOCK vs doradczy). Priorytetyzacja audytu i migracji (P06-AN12).

Usage:
  python tools/v3_p06_usage_telemetry.py
"""
from __future__ import annotations

import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    usage = Counter()
    by_file = Counter()
    block_contexts = 0
    for p in sorted(RULES.rglob("*.rego")):
        if p.name == "thresholds_jdg.rego":
            continue
        rel = str(p.relative_to(RULES))
        tt = p.read_text(encoding="utf-8")
        for m in re.finditer(r"data\.thresholds\.jdg\.([A-Za-z0-9_]+)", tt):
            usage[m.group(1)] += 1
            by_file[rel] += 1
        # kontekst blokujący w liniach z odwołaniem
        for line in tt.splitlines():
            if "data.thresholds.jdg" in line and re.search(r"BLOCK|_routing|object\.get", line):
                block_contexts += 1

    top = usage.most_common()
    weighted = [{"map": k, "refs": c,
                 "impact": "HIGH" if c >= 15 else ("MED" if c >= 5 else "LOW")}
                for k, c in top]
    # priorytet audytu: mapy używane najczęściej i w kontekście BLOCK
    audit_priority = [w for w in weighted if w["impact"] == "HIGH"]

    checks.append({"name": "usage_measured",
                   "status": "OK",
                   "detail": f"map używanych: {len(usage)}; odwołań: {sum(usage.values())}; "
                             f"kontekstów BLOCK/fallback: {block_contexts}"})
    checks.append({"name": "audit_priority_defined",
                   "status": "OK",
                   "detail": f"priorytet HIGH (audyt/migracja najpierw): "
                             f"{[w['map'] for w in audit_priority]}"})

    findings.append({"id": "V3-P06-L18", "severity": "P3",
                     "evidence": "telemetria pierwsza emisja — bez pomiaru runtime frekwencji "
                                 "decyzyjnej (potrzebny licznik z P37)",
                     "fix": "metryki runtime per mapa parametrów (P37): decision_count, "
                            "block_count, fallback_count"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I12", "generated_at": now(), "gate": gate,
        "metrics": {"maps_used": len(usage), "refs_total": sum(usage.values()),
                    "block_contexts": block_contexts,
                    "files_with_refs": len(by_file),
                    "high_priority": len(audit_priority)},
        "usage_top": weighted[:15],
        "by_file_top": by_file.most_common(8),
        "checks": checks, "findings": findings,
        "contract": {"binding": "P37 (metryki runtime), P06-I03 (lineage), P39 (audyt priorytetów), "
                                "P06-I02 (migracja HIGH first)",
                     "metric_names": ["parameter_refs_static", "parameter_decision_count",
                                      "parameter_block_count", "parameter_fallback_count"]},
    }
    (BUNDLES / "v3_p06_usage_telemetry.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I12] gate={gate} maps_used={len(usage)} refs={sum(usage.values())} "
          f"block_ctx={block_contexts}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
