#!/usr/bin/env python3
"""
NexusAI JDG — V3-P66 CHAOS I ODPORNOŚĆ — COMMON (konwencja P51–P65).
Pomocnicze: czytniki PRAWDZIWYCH źródeł odporności:
karty eksperymentów (tools/v3_p66_experiment_cards.json — I02/I08 eksperymenty
jako dane), chaos_runner (P18: 8 eksperymentów CI), chaos_engineering (12
mutacji), chaos drill P43 + P16 KSeF + P57 chaos input (8/8), P49 chaos suite
(12 scenariuszy + 171 missing-field), P65-I09 (196 mutacji, 0 przełamań),
P07 kill switch SLA, deployments.json (auto_rollback_armed, production_active),
healthy_versions.json (P38 rollback), metryki P58 (error budget, advice
spread), self_healing_engine (naprawa z 4-eyes), ksef offline queue/outbox,
dr_snapshots + dr_orchestrator, verify_verdict_invariants, health_tier_engine,
rule_impact_simulator (blast radius reguł), digital_twin_simulator (P33),
odczyt progów ADR-002 z thresholds_jdg.rego (jedno źródło prawdy — silniki
czytają TE SAME klucze co Rego P66; parser list/string/bool/int/float).
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
DOCS_DIR = JDG_ROOT / "docs"
TOOLS_DIR = JDG_ROOT / "tools"
RULES_DIR = JDG_ROOT / "rules"
TESTS_AUTO = JDG_ROOT / "tests" / "auto"
TESTS_REGO = JDG_ROOT / "tests" / "rego"
REPORTS_DIR = JDG_ROOT / "raporty_glm52_v3"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
MAIN_JDG_REGO = RULES_DIR / "main_jdg.rego"

# ── PRAWDZIWE źródła komponowane (rozszerzane, nie dublowane — protokół 08) ──
EXPERIMENT_CARDS = TOOLS_DIR / "v3_p66_experiment_cards.json"
CHAOS_RUNNER = TOOLS_DIR / "chaos_runner.py"
CHAOS_ENGINEERING = TOOLS_DIR / "chaos_engineering.py"
SELF_HEALING = TOOLS_DIR / "self_healing_engine.py"
DIGITAL_TWIN = TOOLS_DIR / "digital_twin_simulator.py"
RULE_IMPACT = TOOLS_DIR / "rule_impact_simulator.py"
KSEF_OFFLINE_QUEUE = TOOLS_DIR / "ksef_offline_queue.py"
KSEF_OUTBOX = TOOLS_DIR / "ksef_outbox.py"
DR_ORCHESTRATOR = TOOLS_DIR / "dr_orchestrator.py"
VERIFY_INVARIANTS = TOOLS_DIR / "verify_verdict_invariants.py"
HEALTH_TIER = TOOLS_DIR / "health_tier_engine.py"
KILL_SWITCH_P07 = TOOLS_DIR / "v3_p07_kill_switch_sla.py"
P07_KILL_SWITCH_BUNDLE = BUNDLES / "v3_p07_kill_switch_sla.json"
P43_CHAOS_DRILL = BUNDLES / "v3_p43_chaos_drill.json"
P16_KSEF_DRILL = BUNDLES / "v3_p16_chaos_ksef_drill.json"
P57_CHAOS = BUNDLES / "v3_p57_chaos.json"
P49_CHAOS_INPUT = BUNDLES / "v3_p49_chaos_input.json"
P49_MISSING_FIELD = BUNDLES / "v3_p49_missing_field_coverage.json"
P49_FAIL_OPEN = BUNDLES / "v3_p49_fail_open_registry.json"
P65_I09_ENGINE = BUNDLES / "v3_p65_i09_engine.json"
P65_WORM_TAMPER = BUNDLES / "v3_p65_i08_engine.json"
P58_ERROR_BUDGET = BUNDLES / "v3_p58_error_budget.json"
P58_ADVICE_SPREAD = BUNDLES / "v3_p58_advice_spread.json"
P58_ESCALATION = BUNDLES / "v3_p58_escalation.json"
DEPLOYMENTS = BUNDLES / "deployments.json"
HEALTHY_VERSIONS = BUNDLES / "healthy_versions.json"
DR_SNAPSHOTS_DIR = BUNDLES / "dr_snapshots"
P64_SWEEP_REGISTER = BUNDLES / "v3_p64_sweep_register.json"
WORKFLOWS = JDG_ROOT.parent / ".github" / "workflows"


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def read_json(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(read_text(path))
    except json.JSONDecodeError:
        return None


def write_json(path: Path, payload) -> bool:
    try:
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2),
                        encoding="utf-8")
        return True
    except OSError:
        return False


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def read_threshold(key: str):
    """Progi ADR-002 z thresholds_jdg.rego — to samo źródło co Rego P66.
    Obsługuje: listy stringów, stringi, bool, int, float (konwencja P62/P65)."""
    src = read_text(THRESHOLDS_REGO)
    m = re.search(
        rf'"{key}"\s*:\s*(\[[^\]]*\]|"(?:[^"\\]|\\.)*"|true|false|-?\d+(?:\.\d+)?)',
        src)
    if not m:
        return None
    raw = m.group(1)
    if raw.startswith("["):
        items = re.findall(r'"([^"]+)"', raw)
        return items if items else None
    if raw.startswith('"'):
        return raw[1:-1]
    if raw == "true":
        return True
    if raw == "false":
        return False
    return float(raw) if "." in raw else int(raw)


def audit_header(analyses: dict) -> dict:
    return {
        "schema": "jdg.v3_p66.chaos.audit.v1",
        "part": "P66",
        "slug": "CHAOS_ODPORNOSC",
        "generated_at": None,
        "analyses": analyses,
    }


def keyword_scan(paths, keywords: list[str]) -> list[str]:
    """Deterministyczny skan: które słowa kluczowe występują w źródłach."""
    hay = "\n".join(read_text(Path(p)) for p in paths)
    return [k for k in keywords if re.search(k, hay, re.IGNORECASE)]


def load_cards() -> dict:
    """Karty eksperymentów P66 (I02/I08 — eksperymenty jako dane)."""
    return read_json(EXPERIMENT_CARDS) or {}


def deployment_evidence() -> dict:
    """Dowód z deployments.json (P38): fail-closed, auto-rollback, production."""
    d = read_json(DEPLOYMENTS) or {}
    dep = d.get("deployments", {})
    armed, fail_closed, prod_active = 0, 0, 0
    if isinstance(dep, dict):
        for v in dep.values():
            if not isinstance(v, dict):
                continue
            armed += 1 if v.get("auto_rollback_armed") else 0
            fail_closed += 1 if v.get("fail_closed") else 0
            prod_active += 1 if v.get("production_active") else 0
    return {"deployments_total": len(dep) if isinstance(dep, dict) else 0,
            "auto_rollback_armed": armed,
            "fail_closed": fail_closed,
            "production_active_count": prod_active}
