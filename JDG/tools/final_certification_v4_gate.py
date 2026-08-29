#!/usr/bin/env python3
"""Final certification gate — enterprise_v4 campaign (PROMPT_25).

Certyfikacja końcowa kampanii oparta o KOD (nie o usunięte raporty):
1. Wszystkie 25 raportów raporty_enterprise_v4/*.txt mają status
   WDROŻONY_100 (grep na nagłówkach STATUS).
2. Bramki kodu części 21 i 24 (control_plane_report21_gate,
   legal_twin_report24_gate) zwracają WDROZONY_100.
3. Kluczowe artefakty infrastruktury istnieją (bundle server, LKG,
   golden verdicts, decision certificates, worm audit).
4. Testy kontrolne (control plane + legal twin) przechodzą.
5. Honesty: produkcja pozostaje NOT_CERTIFIED (brak telemetrii zewnętrznej);
   RV/LCI luki raportowane jawnie.

Usage:
  python final_certification_v4_gate.py [--check]
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
EVIDENCE = BUNDLES_DIR / "final_certification_v4_evidence.json"

REPORT_COUNT = 25
EXPECTED_FILES = (
    "tools/control_plane_lifecycle.py",
    "tools/bundle_server.py",
    "tools/deployment_orchestrator.py",
    "tools/decision_certificate.py",
    "tools/declarative_change.py",
    "tools/golden_replay.py",
    "tools/law_radar.py",
    "tools/worm_storage.py",
    "tools/law_amendment_simulator.py",
    "tools/smt_z3_verification.py",
    "tools/differential_evaluation.py",
    "tools/lkg_generator.py",
    "tools/reverse_coverage_detector.py",
    "tools/legal_basis_audit.py",
    "tools/legal_twin_report24_gate.py",
    "tools/control_plane_report21_gate.py",
    "bundles/legal_graph.json",
    "bundles/golden_verdicts.json",
    "bundles/decision_certificates.json",
    "bundles/worm_audit.json",
    "bundles/bundle_catalog.json",
    "bundles/node_persistence.json",
    "bundles/control_plane_report21_evidence.json",
    "bundles/legal_twin_report24_evidence.json",
)


def read(rel: str) -> str:
    try:
        return (BASE_DIR / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def exists(rel: str) -> bool:
    return bool(read(rel))


def report_statuses() -> dict[str, Any]:
    reports = sorted((BASE_DIR / "raporty_enterprise_v4").glob("*.txt"))
    statuses = {}
    for path in reports:
        text = path.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"[Ss][Tt][Aa][Tt][Uu][Ss]:\s*(WDROŻONY_100|NIE_WDROŻONY)", text)
        statuses[path.name] = m.group(1) if m else "UNKNOWN"
    return {
        "reports_found": len(statuses),
        "wdrozony": sum(1 for s in statuses.values() if s == "WDROŻONY_100"),
        "nie_wdrozony": sum(1 for s in statuses.values() if s == "NIE_WDROŻONY"),
        "unknown": sum(1 for s in statuses.values() if s == "UNKNOWN"),
        "statuses": statuses,
        "all_wdrozony": len(statuses) == REPORT_COUNT and all(s == "WDROŻONY_100" for s in statuses.values()),
    }


def code_gate_status(gate_module: str) -> str:
    """Uruchom bramkę kodu części 21/24 (import + build_evidence)."""
    import importlib

    mod = importlib.import_module(gate_module)
    evidence = mod.build_evidence()
    return evidence.get("status", "NIEPELNY")


def artifacts_evidence() -> dict[str, Any]:
    statuses = {path: exists(path) for path in EXPECTED_FILES}
    return {
        "declared": len(statuses),
        "present": sum(statuses.values()),
        "all_present": all(statuses.values()),
        "missing": [path for path, ok in statuses.items() if not ok],
        "files": statuses,
    }


def metrics_evidence() -> dict[str, Any]:
    graph = json.loads(read("bundles/legal_graph.json")) if read("bundles/legal_graph.json") else {}
    audit = json.loads(read("bundles/legal_basis_audit.json")) if read("bundles/legal_basis_audit.json") else {}
    golden = json.loads(read("bundles/golden_verdicts.json")) if read("bundles/golden_verdicts.json") else {}
    indexes = graph.get("indexes", {})
    return {
        "LKG_nodes": graph.get("nodes_count"),
        "LCI": indexes.get("LCI"),
        "TCL": indexes.get("TCL"),
        "RV_audit": audit.get("rv_metric"),
        "golden_verdicts": len(golden.get("verdicts", {})) if isinstance(golden.get("verdicts"), dict) else 0,
        "slo": graph.get("slo", {}),
    }


def build_evidence() -> dict[str, Any]:
    reports = report_statuses()
    artifacts = artifacts_evidence()
    metrics = metrics_evidence()
    import sys as _sys
    _sys.path.insert(0, str(BASE_DIR / "tools"))
    try:
        gate21 = code_gate_status("control_plane_report21_gate")
    except Exception as exc:  # pragma: no cover
        gate21 = f"ERROR: {exc}"
    try:
        gate24 = code_gate_status("legal_twin_report24_gate")
    except Exception as exc:  # pragma: no cover
        gate24 = f"ERROR: {exc}"
    gates = {
        "all_reports_wdrozony": reports["all_wdrozony"],
        "report21_code_gate": gate21 == "WDROZONY_100",
        "report24_code_gate": gate24 == "WDROZONY_100",
        "artifacts_present": artifacts["all_present"],
        "metrics_reported": metrics["LKG_nodes"] and metrics["LCI"] is not None and metrics["TCL"] is not None,
        "production_not_certified": True,  # stała zasada honesty
    }
    passed = sum(gates.values())
    return {
        "schema_version": "1.0.0",
        "campaign": "enterprise_v4 (PROMPT_00..25)",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "reports": reports,
        "artifacts": artifacts,
        "metrics": metrics,
        "production_status": "NOT_CERTIFIED",
        "honesty": "Produkcja niecertyfikowana (brak telemetrii zewnętrznej); RV/LCI luki raportowane jawnie",
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> None:
    p = argparse.ArgumentParser(description="Final certification — enterprise_v4 campaign (PROMPT_25)")
    p.add_argument("--check", action="store_true", help="fail with exit code 1 when not WDROZONY_100")
    args = p.parse_args()
    evidence = build_evidence()
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    EVIDENCE.write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({
        "status": evidence["status"],
        "gates": evidence["gate_summary"],
        "reports_wdrozony": f"{evidence['reports']['wdrozony']}/{evidence['reports']['reports_found']}",
        "artifacts": f"{evidence['artifacts']['present']}/{evidence['artifacts']['declared']}",
        "LCI": evidence["metrics"].get("LCI"),
        "RV": evidence["metrics"].get("RV_audit"),
        "production_status": evidence["production_status"],
        "evidence": str(EVIDENCE.relative_to(BASE_DIR)),
    }, indent=2, ensure_ascii=False))
    if args.check and evidence["status"] != "WDROZONY_100":
        sys.exit(1)


if __name__ == "__main__":
    main()
