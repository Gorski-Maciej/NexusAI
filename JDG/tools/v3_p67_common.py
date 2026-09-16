#!/usr/bin/env python3
"""
NexusAI JDG — V3-P67 SELF-LEARNING — COMMON (konwencja P51–P66).
Pomocnicze: czytniki PRAWDZIWYCH źródeł pętli uczenia:
rejestr danych uczących (tools/v3_p67_learning_data.json — I01/I02/I07/I08
decyzje jako dane), decision_certificates.json (P11 certyfikaty decyzji),
golden_verdicts.json (31 orzeczeń + replays — P10), rule_registry.json
(P07 lifecycle), v3_p35_operator_feedback.json (P35-I09 feedback
operatorów), metrics_pewnosci.json (pewnność LCI/TCL/RV/UVR),
smt_proofs.json (P33/P42 SMT/Z3 — dowody), v3_p53_epoch_registry.json
(P53 epoki prawne — unieważnianie sugestii), rule_lifecycle_manager
(SHADOW→CANDIDATE→ACTIVE), v3_p51_desert_register.json (przyspieszenie
domykania pustyni), P58 metryki (wspólne źródło telemetrii),
adaptive_trust_score / judgment_predictor / ai_augmented_rule_generator /
llm_bridge / smt_z3_verification / digital_twin_simulator /
confidence_dashboard / neural_mesh_innovations_auditor (warstwa AI P33),
pewnosc_metrics, main_jdg (kotwica p130 — wiring p131),
odczyt progów ADR-002 z thresholds_jdg.rego (jedno źródło prawdy — silniki
czytają TE SAME klucze co Rego P67; parser list/string/bool/int/float).
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
LEARNING_DATA = TOOLS_DIR / "v3_p67_learning_data.json"
DECISION_CERTIFICATES = BUNDLES / "decision_certificates.json"
GOLDEN_VERDICTS = BUNDLES / "golden_verdicts.json"
RULE_REGISTRY = BUNDLES / "rule_registry.json"
P35_OPERATOR_FEEDBACK = BUNDLES / "v3_p35_operator_feedback.json"
P35_GOLDEN_CASES = BUNDLES / "v3_p35_golden_case_registry.json"
METRICS_PEWNOSCI = BUNDLES / "metrics_pewnosci.json"
SMT_PROOFS = BUNDLES / "smt_proofs.json"
P53_EPOCH_REGISTRY = BUNDLES / "v3_p53_epoch_registry.json"
P53_REPLAY_CONTRACT = BUNDLES / "v3_p53_replay_contract.json"
P51_DESERT_REGISTER = BUNDLES / "v3_p51_desert_register.json"
P51_DESERT_CARDS = BUNDLES / "v3_p51_desert_cards.json"
P58_ENGINES = [p for p in sorted(BUNDLES.glob("v3_p58_*.json"))
               if p.name != "v3_p58_run_all.json"]
P58_RUN_ALL = BUNDLES / "v3_p58_run_all.json"
P62_RUN_ALL = BUNDLES / "v3_p62_run_all.json"
LIFECYCLE_MANAGER = TOOLS_DIR / "rule_lifecycle_manager.py"
ADAPTIVE_TRUST = TOOLS_DIR / "adaptive_trust_score.py"
JUDGMENT_PREDICTOR = TOOLS_DIR / "judgment_predictor.py"
AI_RULE_GENERATOR = TOOLS_DIR / "ai_augmented_rule_generator.py"
LLM_BRIDGE = TOOLS_DIR / "llm_bridge.py"
SMT_Z3_TOOL = TOOLS_DIR / "smt_z3_verification.py"
NEURAL_MESH_AUDITOR = TOOLS_DIR / "neural_mesh_innovations_auditor.py"
DIGITAL_TWIN = TOOLS_DIR / "digital_twin_simulator.py"
CONFIDENCE_DASHBOARD = TOOLS_DIR / "confidence_dashboard.py"
PEWNOSC_METRICS = TOOLS_DIR / "pewnosc_metrics.py"
WORM_STORAGE = TOOLS_DIR / "worm_storage.py"
RULE_LIFECYCLE_DOC = DOCS_DIR / "RULE_LIFECYCLE.md"

AUDIT_HEADER = ("innovation", "generated_at", "gate", "metrics", "checks", "findings")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def audit_header(analysis: str, checks: list, gate: str, extra: dict | None = None) -> dict:
    d = {"analysis": analysis, "generated_at": now_iso(), "gate": gate,
         "checks": checks}
    if extra:
        d.update(extra)
    return d


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


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8")


def keyword_scan(path: Path, terms: list[str]) -> int:
    """Liczba trafień słów kluczowych w pliku (dowód użycia źródła)."""
    hay = read_text(path)
    return sum(1 for t in terms if t in hay)


def load_learning_data() -> dict:
    d = read_json(LEARNING_DATA)
    return d if isinstance(d, dict) else {}


def read_threshold(key: str):
    """Czytaj próg z data.jdg.thresholds (ADR-002) — parser Rego JSON-literal.
    Obsługuje: listy, stringi, bool, int, float. Zwraca None gdy brak klucza."""
    src = read_text(THRESHOLDS_REGO)
    m = re.search(rf'"{re.escape(key)}"\s*:\s*(\[[^\]]*\]|"(?:[^"\\]|\\.)*"|true|false|-?\d+(?:\.\d+)?)', src)
    if not m:
        return None
    raw = m.group(1)
    try:
        return json.loads(raw)
    except Exception:
        return raw


def emit(bundle: dict, name: str) -> int:
    """Zapisz bundle dowodowy silnika (lowercase, konwencja P51–P66)."""
    write_json(BUNDLES / f"v3_p67_{name.lower()}_engine.json", bundle)
    return 0 if bundle.get("gate") == "PASS" else 1
