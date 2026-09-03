#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I01 PARAMETER SCHEMA v2
=============================================
Pełny schemat parametru: key, value, unit, valid_from/valid_to, source_act,
article, changed_by, scope (global/domain/context) + walidacja przy zapisie.

Audyt stanu: thresholds_data.json (hot-reload store) vs warstwa danych w kodzie
(rules/thresholds_jdg.rego — data.thresholds.jdg.*, 63 mapy, 617 parametrów
liściowych). Wykrywa parametry-duchy: reguły odwołują się do map, których JSON
nie wersjonuje → ciche defaulty (object.get) w decyzjach.

Usage:
  python tools/v3_p06_parameter_schema.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
DATA_JSON = BUNDLES / "thresholds_data.json"
THRESHOLDS_REGO = BASE / "rules" / "thresholds_jdg.rego"

SCHEMA_V2_FIELDS = ["key", "value", "unit", "valid_from", "valid_to",
                    "source_act", "article", "changed_by", "changed_at", "scope"]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []

    data = json.loads(DATA_JSON.read_text(encoding="utf-8"))
    params = data.get("parameters", {})
    audit = data.get("changed_by_audit", [])

    # 1) pokrycie store vs kod (liściowe parametry numeric w thresholds_jdg.rego)
    t = THRESHOLDS_REGO.read_text(encoding="utf-8")
    leafs = re.findall(r'^\s{4}"([A-Za-z0-9_]+)"\s*:\s*(-?\d+(?:\.\d+)?)', t, re.M)
    leaf_names = sorted({k for k, _ in leafs})
    in_code = len(leaf_names)
    in_json = len(params)

    # 2) schema v2 per wpis JSON
    schema_ok = 0
    schema_issues = []
    for key, entry in params.items():
        vers = entry.get("versions", [])
        for v in vers:
            missing = [f for f in ("valid_from", "source_act", "changed_by") if f not in v]
            if missing:
                schema_issues.append(f"{key}: brak {missing}")
            schema = entry.get("schema", {})
            # typ: schema min/max jako string vs value float — bug data_service.validate
            if isinstance(schema.get("min"), str) or isinstance(schema.get("max"), str):
                schema_issues.append(f"{key}: schema min/max typ STRING vs value {type(v['value']).__name__}"
                                     f" (TypeError w data_service.validate)")
            else:
                schema_ok += 1

    # 3) mapy używane przez reguły (data.thresholds.jdg.<map>) vs zdefiniowane
    top_maps = re.findall(r'^([a-z][a-z0-9_]*)\s*:?=\s*\{', t, re.M)
    referenced = {}
    for p in (BASE / "rules").rglob("*.rego"):
        tt = p.read_text(encoding="utf-8")
        for m in re.finditer(r"data\.thresholds\.jdg\.([A-Za-z0-9_]+)", tt):
            referenced.setdefault(m.group(1), set()).add(str(p.relative_to(BASE / "rules")))
    ghosts = sorted(k for k in referenced if k not in set(top_maps))

    checks.append({"name": "json_store_coverage",
                   "status": "FAIL" if in_json < in_code else "OK",
                   "detail": f"parametry w JSON store: {in_json}, w warstwie danych kodu: {in_code} "
                             f"(liściowe) — pokrycie {100.0*in_json/max(in_code,1):.2f}%"})
    checks.append({"name": "schema_v2_fields",
                   "status": "FAIL" if schema_issues else "OK",
                   "detail": f"wpisów wg schema v2: {schema_ok}/{len(params)}; problemy: {len(schema_issues)}"})
    checks.append({"name": "ghost_references",
                   "status": "FAIL" if ghosts else "OK",
                   "detail": f"referencje do niezdefiniowanych map: {ghosts}"})

    if in_json < in_code:
        findings.append({"id": "V3-P06-L01", "severity": "P0",
                         "evidence": f"thresholds_data.json wersjonuje {in_json} parametr(ów), "
                                     f"a warstwa danych kodu definiuje {in_code} liściowych wartości "
                                     f"w {len(top_maps)} mapach — reguły czytają defaulty z kodu, "
                                     f"hot-reload danych nie obejmuje zdecydowanej większości progów",
                         "fix": "migracja wartości do JSON store wg schema v2 (P06-I03 lineage) "
                                "+ eksport OPA Data API"})
    if schema_issues:
        findings.append({"id": "V3-P06-L05", "severity": "P1",
                         "evidence": f"data_service.validate TypeError (schema min/max jako string): "
                                     f"{schema_issues[:3]}",
                         "fix": "schema min/max przechowywane jako number (typ zgodny z value); "
                                "walidacja typów przy zapisie"})
    if ghosts:
        findings.append({"id": "V3-P06-L06", "severity": "P1",
                         "evidence": f"referencje data.thresholds.jdg.* do map nieobecnych w warstwie "
                                     f"danych: {ghosts}",
                         "fix": "deklaratywna rejestracja map (P06-I07) lub naprawa referencji"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I01", "generated_at": now(), "gate": gate,
        "metrics": {"params_in_json": in_json, "leaf_params_in_code": in_code,
                    "top_level_maps": len(top_maps), "maps_referenced": len(referenced),
                    "ghost_refs": len(ghosts), "audit_entries": len(audit)},
        "schema_v2": SCHEMA_V2_FIELDS,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P07–P36 domenowe (migracja wartości), P38 (hot-reload), P39 (CI)",
                     "rule": "parametr bez source_act/article/valid_from = odrzucenie zapisu"},
    }
    (BUNDLES / "v3_p06_parameter_schema.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I01] gate={gate} json={in_json} code_leafs={in_code} "
          f"maps={len(top_maps)} used={len(referenced)} ghosts={len(ghosts)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
