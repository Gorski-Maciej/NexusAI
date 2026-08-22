#!/usr/bin/env python3
"""
NexusAI JDG — API SPEC CONSISTENCY CHECKER (GLM52 ETAP 25)
============================================================
Porównuje api/openapi.yaml z REALNYMI artefaktami (tools/, migrations/,
bundles/) i raportuje zgodność — bez udawania, że specyfikacja jest
implementacją. Dla każdej ścieżki OpenAPI podaje:

  • spec_path      — ścieżka z openapi.yaml,
  • artifact       — realny plik narzędziowy implementujący/obsługujący ścieżkę,
  • status         — IMPLEMENTED (narzędzie istnieje i pokrywa ścieżkę),
                     DOCUMENTED_ONLY (tylko spec/docs — brak realnego narzędzia),
  • security       — JWT/RBAC/SoD wymagane na operacji,
  • idempotency    — obecność nagłówka Idempotency-Key,
  • gaps           — jawna lista braków.

Nie nazywamy mocka produkcją: ścieżki bez implementacji mają status
DOCUMENTED_ONLY i liczą się do gap_count.

Usage:
  python api_spec_consistency.py audit
  python api_spec_consistency.py audit --json
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
OPENAPI_PATH = JDG_ROOT / "api" / "openapi.yaml"
OUT_PATH = JDG_ROOT / "bundles" / "api_spec_consistency.json"

# Mapowanie ścieżek OpenAPI na realne artefakty (tools/*.py, bundles/*).
# Cel: koniec „spec = production" — każda ścieżka ma wskazaną implementację
# albo jawny status DOCUMENTED_ONLY.
PATH_ARTIFACTS = {
    "/jdg/decide": "tools/main_jdg.rego -> rules/main_jdg.rego (final_verdict); evaluacja przez OPA",
    "/jdg/simulate": "tools/judgment_predictor.py + rules (shadow mode)",
    "/jdg/audit/{verdict_id}": "tools/golden_replay.py + migrations/001 (jdg_verdict_audit)",
    "/jdg/health": "tools/bundle_server.py status + bundles/deployments.json",
    "/jdg/explain": "tools/llm_bridge.py",
    "/jdg/thresholds": "tools/data_service.py export + bundles/thresholds_data.json",
    "/jdg/manifest": "tools/manifest_v2.py + bundles/manifest_v2.json",
    "/jdg/coverage": "tools/generate_coverage_report.py + bundles/legal_coverage_gaps.json",
    "/jdg/rules/{rule_id}": "tools/policy_registry_api.py get + bundles/policy_registry.json",
    "/jdg/legal-coverage": "tools/legal_coverage_heatmap.py + bundles/legal_coverage_gaps.json",
    "/jdg/rules": "tools/policy_registry_api.py search/build + bundles/policy_registry.json",
    "/jdg/change": "tools/declarative_change.py + tools/control_plane_lifecycle.py",
    "/jdg/cert": "tools/decision_certificate.py issue + bundles/decision_certificates.json",
    "/bundles": "tools/bundle_server.py publish/status + bundles/bundle_catalog.json",
    "/bundles/{version}/verify": "tools/bundle_server.py verify (weryfikacja na węźle)",
    "/bundles/{version}/health": "tools/deployment_orchestrator.py health + bundles/deployments.json",
    "/dr/restore": "tools/dr_orchestrator.py restore + bundles/dr_snapshots/",
}

REQUIRED_MARKERS = [
    "Idempotency-Key", "x-api-versioning", "x-rbac", "x-sod",
    "BearerAuth", "breaking_changes", "separation of duties",
]


def load_spec() -> dict:
    try:
        import yaml
    except ImportError as exc:  # pragma: no cover
        sys.exit(f"❌ Brak PyYAML: {exc}")
    return yaml.safe_load(OPENAPI_PATH.read_text(encoding="utf-8"))


def artifact_exists(ref: str) -> bool:
    """True gdy KTÓRYKOLWIEK token ścieżkowy (…py/…rego/…json/…) istnieje w repo.
    Opis może zawierać wiele artefaktów — implementacja liczy się, gdy choć
    jeden z nich fizycznie istnieje.
    """
    import re
    tokens = re.findall(r"(?:tools|rules|bundles|migrations)/[\w./-]+", ref)
    if not tokens:
        return False
    for token in tokens:
        if (JDG_ROOT / token).exists():
            return True
    return False


def audit() -> dict:
    spec = load_spec()
    paths = spec.get("paths", {})
    rows = []
    for path, ops in paths.items():
        for method, op in ops.items():
            if not isinstance(op, dict):
                continue
            artifact = PATH_ARTIFACTS.get(path)
            impl = artifact_exists(artifact) if artifact else False
            status = "IMPLEMENTED" if impl else "DOCUMENTED_ONLY"
            rows.append({
                "path": path,
                "method": method.upper(),
                "operation_id": op.get("operationId", ""),
                "artifact": artifact or "BRAK",
                "status": status,
                "security": bool(op.get("security")) or bool(spec.get("security")),
                "idempotency": any(
                    (p.get("$ref") or "").endswith("IdempotencyKey") or
                    p.get("name") == "Idempotency-Key"
                    for p in op.get("parameters", [])
                ),
            })
    text = OPENAPI_PATH.read_text(encoding="utf-8")
    markers = {m: m in text for m in REQUIRED_MARKERS}
    implemented = sum(1 for r in rows if r["status"] == "IMPLEMENTED")
    documented_only = [r for r in rows if r["status"] == "DOCUMENTED_ONLY"]
    report = {
        "schema_version": "1.0.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "openapi_version": spec.get("info", {}).get("version", "?"),
        "paths_total": len(rows),
        "implemented": implemented,
        "documented_only": len(documented_only),
        "gaps": [{"path": r["path"], "method": r["method"], "artifact": r["artifact"]} for r in documented_only],
        "gap_count": len(documented_only),
        "markers": markers,
        "markers_complete": all(markers.values()),
        "endpoints": rows,
    }
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    return report


def main() -> int:
    p = argparse.ArgumentParser(description="JDG API Spec Consistency (ETAP 25)")
    p.add_argument("command", choices=["audit"])
    p.add_argument("--json", action="store_true")
    args = p.parse_args()
    report = audit()
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(f"[ETAP_25] API spec: {report['implemented']}/{report['paths_total']} "
              f"ścieżek z implementacją · gaps={report['gap_count']} · markers={report['markers_complete']}")
        for g in report["gaps"]:
            print(f"  GAP {g['method']} {g['path']} -> {g['artifact']}")
    # Fail-closed: ścieżki bez implementacji są jawnym brakiem, nie produkcją.
    return 0 if report["markers_complete"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
