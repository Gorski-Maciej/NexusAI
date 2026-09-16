"""Testy pytest V3-P67 SELF-LEARNING (konwencja P51–P66).

Pokrywają: 12 silników I01–I12 vs bundla (jedno źródło), rejestr danych
uczących (sugestie jako dane z guardrails), progi z ADR-002 (brak hardcode),
wiring main_jdg p131, mirror hash-parity, fail-closed (zero AUTO_POST),
guardrails (sugestia bez SMT/replay/4-eyes = odrzucona), epoki prawne P53,
kompozycja z P07/P10/P11/P33/P35/P51/P53/P58/P62/P65/P66.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

JDG = Path(__file__).resolve().parents[2]
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
RULE = RULES / "v3_p67_self_learning.rego"
TOOLS = JDG / "tools"
DATA = TOOLS / "v3_p67_learning_data.json"


def _load(name: str) -> dict:
    return json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))


def _run(script: str, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(TOOLS / script), *args],
                          capture_output=True, text=True, timeout=120)


# ═══ 1. Run-all gate ═══
def test_run_all_gate_pass():
    d = _load("v3_p67_run_all")
    assert d["gate"] == "PASS", d["failures"]
    assert d["engines_run"] == 12
    assert d["failures"] == []
    assert d["rego_gate"] == "PASS"  # natywne testy OPA (kontrakt C2 z P65)


# ═══ 2. Rejestr danych uczących (decyzje jako dane) ═══
def test_learning_data_as_data():
    d = json.loads(DATA.read_text(encoding="utf-8"))
    assert len(d["advice_clusters"]) >= 3  # prompt P67: klaster NEEDS_ADVICE
    for c in d["advice_clusters"]:
        assert c.get("reason_code"), f"{c['cluster_id']}: brak powodu"
        assert c.get("suggestion_id"), f"{c['cluster_id']}: brak sugestii"
        assert c.get("target_status") == "SHADOW", f"{c['cluster_id']}: cel lifecycle"
        assert c.get("legal_basis"), f"{c['cluster_id']}: brak podstawy prawnej"
    assert d["suggestion_pipeline"]["required_validations"] == \
        ["smt_z3", "golden_replay", "four_eyes"]
    assert len(d["suggestion_pipeline"]["four_eyes_roles"]) >= 4


# ═══ 3. Guardrails: sugestia bez walidacji = odrzucona ═══
def test_guardrails_rejections_registered():
    d = json.loads(DATA.read_text(encoding="utf-8"))
    rejected = [s for s in d["suggestions"] if s["status"] == "REJECTED"]
    assert len(rejected) >= 1  # dowód działania guardrail (I09)
    for s in rejected:
        assert s["rejected_by"] in ("smt_z3", "golden_replay", "four_eyes")
    for s in d["suggestions"]:
        assert s.get("law_epoch"), f"{s['suggestion_id']}: sugestia bez epoki (I04)"


# ═══ 4–15. Silniki I01–I12 vs bundla ═══
def test_i01_pipeline():
    r = _load("v3_p67_i01_engine")
    assert r["gate"] == "PASS"
    assert r["decision"] == "PASS"
    assert r["metrics"]["clusters"] >= 3 and r["metrics"]["stages"] >= 5


def test_i02_corrections():
    r = _load("v3_p67_i02_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["corrections"] >= 1
    assert r["metrics"]["verdicts"] >= 30


def test_i03_telemetry_p58():
    r = _load("v3_p67_i03_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["metrics_defined"] >= 6
    assert r["metrics"]["p58_engines"] >= 4  # wspólne źródło P58


def test_i04_epoch_expiry():
    r = _load("v3_p67_i04_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["epochs"] >= 1  # rejestr epok P53


def test_i05_guardrails():
    r = _load("v3_p67_i05_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["p33_tools"] >= 6  # warstwa AI P33


def test_i06_dashboard():
    r = _load("v3_p67_i06_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["rows"] >= 4


def test_i07_data_readiness():
    r = _load("v3_p67_i07_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["sources"] >= 6
    assert r["metrics"]["missing"] >= 1  # rejestr zawiera też braki (plan)


def test_i08_feedback_loop():
    r = _load("v3_p67_i08_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["reviews"] >= 1


def test_i09_safety_metrics():
    r = _load("v3_p67_i09_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["rejections"] >= 1


def test_i10_knowledge_base():
    r = _load("v3_p67_i10_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["verdicts"] >= 30


def test_i11_curriculum():
    r = _load("v3_p67_i11_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["queue"] == sorted(r["metrics"]["queue"], reverse=True)


def test_i12_replay():
    r = _load("v3_p67_i12_engine")
    assert r["gate"] == "PASS"
    assert r["metrics"]["replays"] >= 30
    assert r["metrics"]["pillars"] >= 1  # kontrakt replay P53


# ═══ 16. Progi z ADR-002 (zero hardcode w Rego) ═══
def test_thresholds_adr002():
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    blk = th[th.index("v3_p67 := {"):]
    for key in ["v3_p67_clusters_min", "v3_p67_pipeline_stages_min",
                "v3_p67_telemetry_metrics_min", "v3_p67_data_sources_min",
                "v3_p67_knowledge_verdicts_min", "v3_p67_replay_cases_min",
                "v3_p67_curriculum_roi_min", "v3_p67_suggestion_rejections_min"]:
        assert f'"{key}"' in blk, f"brak progu {key} (ADR-002)"
    assert '"valid_from": "2026-01-01"' in blk and '"valid_to": null' in blk


# ═══ 17. Wiring main_jdg p131 ═══
def test_wiring_main_jdg():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p67_self_learning as v3_p67_self_learning" in main
    assert "final_verdict_p131 = safe_merge(final_verdict_p130" in main
    assert "v3_p67_self_learning.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    # Kotwica POST-MERGE przesunięta na p131 (wiring P67, kampania V3).
    assert "final_verdict_p131" in post[:400]


# ═══ 18. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p67_self_learning", "v3_p66_chaos_resilience",
                 "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 19. Fail-closed statycznie: router nie ma ścieżki AUTO_POST ═══
def test_fail_closed_static():
    hay = RULE.read_text(encoding="utf-8")
    assert hay.count('"AUTO_POST"') == 0
    assert "NO_MATCH" in hay and "NEEDS_ADVICE" in hay and "BLOCK" in hay
    # final_verdict_p131 tylko w komentarzu nagłówka (konwencja P59–P66) —
    # Rego P67 nie wykonuje host-wiringu.
    assert hay.count("final_verdict_p131") == 1


# ═══ 20. Rego struktura: pakiety, priorytety ═══
def test_rego_structure():
    t = RULE.read_text(encoding="utf-8")
    assert t.count("{") == t.count("}")
    assert "package jdg.v3_p67_self_learning" in t
    for n in range(1, 13):
        assert f"4670{n:02d}" in t, f"brak priorytetu I{n:02d}"


# ═══ 21. Natywne testy OPA obecne i kompletność źródeł ═══
def test_native_opa_tests_present():
    t = (JDG / "tests" / "rego" / "test_v3_p67_self_learning.rego").read_text(encoding="utf-8")
    assert t.count("test_p67_") >= 19
    hay = ((TOOLS / "v3_p67_engines.py").read_text(encoding="utf-8")
           + (TOOLS / "v3_p67_common.py").read_text(encoding="utf-8"))
    for src in ["decision_certificates.json", "golden_verdicts.json",
                "rule_registry.json", "v3_p35_operator_feedback.json",
                "metrics_pewnosci.json", "smt_proofs.json",
                "v3_p53_epoch_registry.json", "v3_p53_replay_contract.json",
                "v3_p51_desert_register.json", "rule_lifecycle_manager.py",
                "adaptive_trust_score.py", "smt_z3_verification.py",
                "ai_augmented_rule_generator.py", "llm_bridge.py",
                "judgment_predictor.py", "confidence_dashboard.py",
                "digital_twin_simulator.py", "neural_mesh_innovations_auditor.py"]:
        assert src in hay, f"brak powiązania z prawdziwym źródłem: {src}"


# ═══ 22. Silniki: determinizm (2 przebiegi I01 identyczne) ═══
def test_engines_deterministic():
    p1 = _run("v3_p67_engines.py", "I01")
    p2 = _run("v3_p67_engines.py", "I01")
    assert p1.returncode == p2.returncode == 0
    a, b = json.loads(p1.stdout), json.loads(p2.stdout)
    assert a == b  # drugi przebieg = identyczny wynik
