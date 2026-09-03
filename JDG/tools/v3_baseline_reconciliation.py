#!/usr/bin/env python3
"""
NexusAI JDG — BASELINE RECONCILIATION REPORT (P00-I11)
=======================================================
Porównanie baseline P00 (v3_canonical_snapshot.json) z baseline
z dokumentu ANALIZA_STANU_OPA_JAKO_SYSTEM.md (luki L1–L12, 2026-08-07):
co zmieniło się od analizy i które luki L1–L12 pozostały otwarte.

Usage:
  python v3_baseline_reconciliation.py       # raport rekoncyliacji
  python v3_baseline_reconciliation.py --json
  python v3_baseline_reconciliation.py --write
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
SNAPSHOT_PATH = BUNDLES_DIR / "v3_canonical_snapshot.json"
OUT_JSON = BUNDLES_DIR / "v3_baseline_reconciliation.json"

# Stan deklarowany w ANALIZA_STANU_OPA_JAKO_SYSTEM.md (2026-08-07)
OLD_BASELINE = {
    "document": "docs/ANALIZA_STANU_OPA_JAKO_SYSTEM.md",
    "dated": "2026-08-07",
    "declared_ranges": {
        "rego_files": "439 vs 383 vs 176 (rozbieżne deklaracje)",
        "rule_ids": "11452 vs 10878 vs 10827",
        "tools": "57 vs 98 vs 130",
    },
    "luki_L1_L12": {
        "L1": "Brak realnego control plane",
        "L2": "Niespójność danych dokumentacyjnych",
        "L3": "Niesfinalizowana deduplikacja i higiena reguł",
        "L4": "Zero-Hardcoded tylko częściowo",
        "L5": "Dwuwładztwo rules/ vs policies/",
        "L6": "Brak opisanego cyklu awaryjnego i DR/BCP",
        "L7": "Testy natywne — luka między deklaracją a planem",
        "L8": "Brak opisanego modelu uprawnień operacyjnych",
        "L9": "Brak pełnej obserwowalności procesu zmiany",
        "L10": "Brak metryk SLA/SLO i jakości w czasie",
        "L11": "Bezpieczeństwo łańcucha dostaw",
        "L12": "Proces dodania reguły — dokumentowany, ale z lukami",
    },
}

# Dowody zamknięcia luk L1–L12 wg artefaktów w repo (weryfikowane istnieniem pliku)
LUKA_CLOSURE_EVIDENCE = {
    "L1": ["JDG/tools/control_plane_lifecycle.py", "JDG/rules/rule_lifecycle_enterprise.rego", "JDG/docs/CONTROL_PLANE_RULE_LIFECYCLE.md"],
    "L2": ["JDG/tools/manifest_v2.py", "JDG/bundles/manifest_v2.json", "JDG/docs/MANIFEST_2_0.md"],
    "L3": ["JDG/tools/fix_p00_duplicates.py", "JDG/tools/dedup_micro_plan33.py", "JDG/tools/dead_rule_detector.py"],
    "L4": ["JDG/tools/hardcoded_audit.py", "JDG/tools/hardcoded_audit_gate.py", "JDG/bundles/thresholds_data.json"],
    "L5": ["JDG/tools/policies_sync_gate.py", "JDG/tools/v3_mirror_delta.py", "JDG/rules/policies_mirror_sync_etap26_v1.rego"],
    "L6": ["JDG/tools/dr_orchestrator.py", "JDG/tools/worm_storage.py"],
    "L7": ["JDG/tests/rego", "JDG/tools/generate_test_suite.py"],
    "L8": ["JDG/tools/policy_registry_api.py", "JDG/rules/security"],
    "L9": ["JDG/tools/enterprise_dashboard.py", "JDG/tools/confidence_dashboard.py"],
    "L10": ["JDG/tools/metrics_generator.py", "JDG/bundles/metrics_pewnosci.json"],
    "L11": ["JDG/tools/quantum_safe_encryption.py", "JDG/tools/blockchain_audit_trail.py"],
    "L12": ["JDG/docs/DEVELOPER_GUIDE.md", "JDG/docs/OPA_REGO_DEVELOPER_GUIDE.md", "JDG/tools/rule_lifecycle_manager.py"],
}


def luka_status(luka: str) -> dict:
    evidence = LUKA_CLOSURE_EVIDENCE.get(luka, [])
    existing = []
    for rel in evidence:
        # ścieżki są względne do korzenia repo (BASE_DIR = JDG/)
        rel_clean = rel.removeprefix("JDG/")
        path = BASE_DIR / rel_clean
        if path.exists():
            existing.append(rel)
    return {
        "luka": luka,
        "description": OLD_BASELINE["luki_L1_L12"][luka],
        "evidence_checked": len(evidence),
        "evidence_found": len(existing),
        "evidence_list": existing,
        "status": "DOMKNIĘTA" if existing else "OTWARTA",
    }


def build() -> dict:
    snapshot = {}
    if SNAPSHOT_PATH.exists():
        try:
            snapshot = json.loads(SNAPSHOT_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            snapshot = {"__error__": "invalid JSON"}
    luki = [luka_status(f"L{i}") for i in range(1, 13)]
    counts = snapshot.get("counts", {}) if isinstance(snapshot, dict) else {}
    return {
        "schema_version": "1.0.0",
        "report": "V3_BASELINE_RECONCILIATION",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "old_baseline": OLD_BASELINE,
        "new_baseline": {
            "source": "bundles/v3_canonical_snapshot.json (P00-I01)",
            "rego_files": counts.get("rego_files"),
            "rule_id_unique": counts.get("rego_rule_id_unique"),
            "tools_py": counts.get("tools_py"),
            "pytest_files": counts.get("pytest_files"),
            "native_rego_tests": counts.get("native_rego_tests"),
        },
        "luki_L1_L12": luki,
        "domkniete": sum(1 for l in luki if l["status"] == "DOMKNIĘTA"),
        "otwarte": sum(1 for l in luki if l["status"] == "OTWARTA"),
        "status": "REKONCYLACJA_OK",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 Baseline Reconciliation")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    data = build()
    if args.write:
        OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3 BASELINE RECONCILIATION: {data['domkniete']}/12 luk L1–L12 z dowodem w repo")
        for l in data["luki_L1_L12"]:
            icon = "✅" if l["status"] == "DOMKNIĘTA" else "⚠️"
            print(f"  {icon} {l['luka']} {l['description']}: {l['status']} ({l['evidence_found']}/{l['evidence_checked']} dowodów)")
    return 0


if __name__ == "__main__":
    sys.exit(main())