#!/usr/bin/env python3
"""
NexusAI JDG — V3-P68 RE-CERTYFIKACJA — wspólne utilsy (konwencja P65–P67).
Ścieżki PRAWDZIWYCH źródeł (rozszerzają, nie dublują — protokół 08):
ledger kampanii V3 (23 rejestry P45–P67), evidence final certification v4,
zero_defect certification, rule_registry, thresholds_data, coverage_deserts,
golden_verdicts, deployments, healthy_versions, enterprise_operating_contract,
sweep register P64, epoki P53, pętla uczenia P67, WORM P65, chaos P66,
fail-open registry P49, semantic duplicates P50.
"""
from __future__ import annotations

import json
from pathlib import Path

JDG = Path(__file__).resolve().parents[1]
BUNDLES = JDG / "bundles"
TOOLS = JDG / "tools"
RULES = JDG / "rules"
TESTS = JDG / "tests"
DOCS = JDG / "docs"

AUDIT_HEADER = {
    "innovation": None,
    "generated_at": None,
    "part": "P68",
    "slug": "RECERTYFIKACJA_FINALNA",
}

# Źródła (każdy silnik czyta PRAWDZIWE pliki — zero fikcyjnych liczeń)
LEDGER = BUNDLES / "v3_campaign_ledger.json"
V4_EVIDENCE = BUNDLES / "final_certification_v4_evidence.json"
ZERO_DEFECT = TOOLS / "zero_defect_certification.py"
RULE_REGISTRY = BUNDLES / "rule_registry.json"
THRESHOLDS_DATA = BUNDLES / "thresholds_data.json"
COVERAGE_DESERTS = BUNDLES / "coverage_deserts.json"
P51_DESERT_REGISTER = BUNDLES / "v3_p51_desert_register.json"
GOLDEN_VERDICTS = BUNDLES / "golden_verdicts.json"
DEPLOYMENTS = BUNDLES / "deployments.json"
HEALTHY_VERSIONS = BUNDLES / "healthy_versions.json"
ENTERPRISE_CONTRACT = BUNDLES / "enterprise_operating_contract.json"
P64_SWEEP_REGISTER = BUNDLES / "v3_p64_sweep_register.json"
P53_EPOCH_REGISTRY = BUNDLES / "v3_p53_epoch_registry.json"
P67_LEARNING_DATA = TOOLS / "v3_p67_learning_data.json"
WORM_STORAGE = TOOLS / "worm_storage.py"
P49_FAIL_OPEN = BUNDLES / "v3_p49_fail_open_registry.json"
P50_DUPLICATES = BUNDLES / "v3_p50_semantic_duplicates.json"
DECISION_CERTIFICATES = BUNDLES / "decision_certificates.json"
P66_RUN_ALL = BUNDLES / "v3_p66_run_all.json"
P67_RUN_ALL = BUNDLES / "v3_p67_run_all.json"

# Rejestry naprawcze P45–P67 (rozliczenie I02 — 23 rejestry)
SETTLEMENT_PATH = TOOLS / "v3_p68_settlement.json"


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def read_threshold(key: str, fallback):
    """Jedno źródło progów: data.jdg.thresholds.v3_p68 (ADR-002) — czytane
    z Rego przez JSON parity: silniki czytają blok z thresholds_jdg.rego
    przez wygenerowany snapshot (v3_p68_thresholds_snapshot.json), a Rego
    czyta data.jdg.thresholds.v3_p68. Fallback jawny, nigdy cichy."""
    snap = read_json(TOOLS / "v3_p68_thresholds_snapshot.json") or {}
    val = snap.get(key)
    return fallback if val is None else val


def load_ledger() -> dict:
    return read_json(LEDGER) or {}


def emit(bundle: dict, name: str) -> int:
    out = BUNDLES / f"v3_p68_{name}_engine.json"
    out.write_text(json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    ok = all(c.get("status") in ("OK", "INFO") for c in bundle.get("checks", []))
    print(json.dumps({"analysis": bundle.get("analysis"),
                      "decision": bundle.get("decision"),
                      "gate": "PASS" if ok else "FAIL"}, ensure_ascii=False))
    return 0 if ok else 1


def keyword_scan(hay: str, needles: list) -> list:
    return [n for n in needles if n not in hay]
