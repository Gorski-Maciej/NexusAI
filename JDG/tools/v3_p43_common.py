#!/usr/bin/env python3
"""NexusAI JDG — V3-P43 shared evidence helper (kampania V3 FORTRESS).

Wspólne narzędzia dla 12 tooli dowodowych V3-P43-I01..I12: skan reguł w
rules/v3_p43_security_dr_enterprise.rego, skan parametrów w
rules/thresholds_jdg.rego (blok v3_p43), wiring main_jdg (final_verdict_p107)
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

P43_RULES = RULES / "v3_p43_security_dr_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
SECURITY_REGISTER = BUNDLES / "v3_p43_security_dr_register.json"
SYSTEM_REGISTER_P42 = BUNDLES / "v3_p42_system_register.json"

# Dowody wejściowe (Sekcja 6 promptu P43 — istnieją, mierzone w sesji)
WORM_STORAGE = TOOLS / "worm_storage.py"
CHAOS_RUNNER = TOOLS / "chaos_runner.py"
CHAOS_ENGINEERING = TOOLS / "chaos_engineering.py"
DEPLOY_ORCHESTRATOR = TOOLS / "deployment_orchestrator.py"
SELF_HEALING = TOOLS / "self_healing_engine.py"
CERT_SERVICE = TOOLS / "certificate_service.py"
QUANTUM_SAFE = TOOLS / "quantum_safe_encryption.py"
DR_SNAPSHOTS = BUNDLES / "dr_snapshots"
RUNBOOKS = DOCS / "runbooks"
RODO_DOC = DOCS / "RODO_AML_BEZPIECZENSTWO_P16.md"

# Narzędzia V3-P43 (12 innowacji)
P43_TOOLS = [
    "v3_p43_threat_model", "v3_p43_rule_quarantine", "v3_p43_dual_control",
    "v3_p43_secrets_rotation", "v3_p43_chaos_drill", "v3_p43_restore_drill",
    "v3_p43_paper_mode", "v3_p43_tamper_history", "v3_p43_ransomware_playbook",
    "v3_p43_breach_taxonomy", "v3_p43_zero_standing", "v3_p43_dr_continuity",
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
    hay = hay if hay is not None else read(P43_RULES)
    return rule_id in hay


def threshold_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def main_jdg_wired(alias: str = "v3_p43_security_dr") -> bool:
    main = read(MAIN_JDG)
    return (f"import data.jdg.{alias} as {alias}" in main
            and f'"jdg.{alias}": {alias}.decide' in main
            and "final_verdict_p107" in main)


def emit(bundle: dict, name: str) -> int:
    (BUNDLES / f"{name}.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    gate = bundle.get("gate", "FAIL")
    print(f"[{bundle.get('innovation', name)}] gate={gate} "
          f"checks={len(bundle.get('checks', []))} findings={len(bundle.get('findings', []))}")
    return 1 if gate == "FAIL" else 0
