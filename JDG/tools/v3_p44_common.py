#!/usr/bin/env python3
"""NexusAI JDG — V3-P44 shared evidence helper (kampania V3 FORTRESS).

Wspólne narzędzia dla 12 tooli dowodowych V3-P44-I01..I12: skan reguł w
rules/v3_p44_certyfikacja_finalna.rego, skan parametrów w
rules/thresholds_jdg.rego (blok v3_p44), wiring main_jdg (final_verdict_p108)
i zapis bundle dowodowych do bundles/.
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
RULES = BASE / "rules"
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
TESTS = BASE / "tests"
DOCS = BASE / "docs"
REPORTS_V3 = BASE / "raporty_glm52_v3"

P44_RULES = RULES / "v3_p44_certyfikacja_finalna.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
CERT_REGISTER = BUNDLES / "v3_p44_final_certification.json"

# Dowody wejściowe (Sekcja 6 promptu P44 — istnieją, mierzone w sesji)
LEDGER = BUNDLES / "v3_campaign_ledger.json"
LEGAL_GRAPH = BUNDLES / "legal_graph.json"
GOLDEN_VERDICTS = BUNDLES / "golden_verdicts.json"
DECISION_CERTIFICATES = BUNDLES / "decision_certificates.json"
FINAL_CERT_V4_EVIDENCE = BUNDLES / "final_certification_v4_evidence.json"
CONTROL_PLANE_STATE = BUNDLES / "control_plane_state.json"
COVERAGE_CANON = BUNDLES / "coverage_canon.json"
COVERAGE_DESERTS = BUNDLES / "coverage_deserts.json"
DEPLOYMENTS = BUNDLES / "deployments.json"
HEALTHY_VERSIONS = BUNDLES / "healthy_versions.json"
DOC_REGISTRY_P41 = BUNDLES / "v3_p41_doc_registry.json"
SYSTEM_REGISTER_P42 = BUNDLES / "v3_p42_system_register.json"
SECURITY_REGISTER_P43 = BUNDLES / "v3_p43_security_dr_register.json"
TEST_STRATEGY_P39 = BUNDLES / "v3_p39_test_strategy.json"
FINAL_V4_GATE = TOOLS / "final_certification_v4_gate.py"
WORM_STORAGE = TOOLS / "worm_storage.py"
CERT_SERVICE = TOOLS / "certificate_service.py"
RUNBOOKS = DOCS / "runbooks"
HOLY_DOC_1 = DOCS / "ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md"
HOLY_DOC_2 = DOCS / "WIZJA_OPA_ENTERPRISE_V2.md"
OPENAPI = BASE / "api" / "openapi.yaml"

# Narzędzia V3-P44 (12 innowacji)
P44_TOOLS = [
    "v3_p44_hard_gate_certificate", "v3_p44_pillar_scoreboard",
    "v3_p44_aggregate_ledger", "v3_p44_owner_decision_map",
    "v3_p44_inheritance_contract", "v3_p44_metric_freeze",
    "v3_p44_worm_signature", "v3_p44_knowledge_transfer",
    "v3_p44_renewal_policy", "v3_p44_legacy_cleanup",
    "v3_p44_owner_attestation", "v3_p44_self_portrait",
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def read_json(path: Path):
    """Wczytaj JSON albo {} gdy plik nie istnieje/uszkodzony (fail-closed: {})."""
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8", errors="ignore"))
    except json.JSONDecodeError:
        return {}


def rule_present(rule_id: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(P44_RULES)
    return rule_id in hay


def threshold_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def main_jdg_wired(alias: str = "v3_p44_certyfikacja_finalna") -> bool:
    main = read(MAIN_JDG)
    return (f"import data.jdg.{alias} as {alias}" in main
            and f'"jdg.{alias}": {alias}.decide' in main
            and "final_verdict_p108" in main)


def ledger_wdrozony_count() -> int:
    led = read_json(LEDGER)
    parts = led.get("parts", {})
    if isinstance(parts, dict):
        return sum(1 for v in parts.values()
                   if isinstance(v, dict) and v.get("status") == "WDROŻONY_100")
    return 0


def emit(bundle: dict, name: str) -> int:
    (BUNDLES / f"{name}.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    gate = bundle.get("gate", "FAIL")
    print(f"[{bundle.get('innovation', name)}] gate={gate} "
          f"checks={len(bundle.get('checks', []))} findings={len(bundle.get('findings', []))}")
    return 1 if gate == "FAIL" else 0
