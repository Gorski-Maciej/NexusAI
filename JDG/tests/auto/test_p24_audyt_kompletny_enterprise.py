#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P24 AUDYT KOMPLETNY + SYNTEZA MASTER — Testy pytest (enterprise)
# ═══════════════════════════════════════════════════════════════════════════════
# 1) Mirror logiki pakietu jdg.p24_audyt_kompletny_innovations (synteza,
#    zastąpienie księgowego, pokrycie prawne, forteca, adaptacja, master plan).
# 2) Audyt REALNEGO stanu modułu (manifest.json, liczba plików rego,
#    okablowanie main_jdg.rego, raporty R01-R24).
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR / "tools"))

from audyt_kompletny_auditor import (  # noqa: E402
    ADAPTATION_HOURS_MAX,
    ASK_USER_MAX_PCT,
    AUTO_POST_TARGET_PCT,
    COMPLETENESS_TARGET,
    FORTRESS_SCORE_TARGET,
    KNOWLEDGE_GRAPH_NODES,
    PROOF_OF_CORRECTNESS_MIN,
    TARGET_COVERAGE_PCT,
    accountant_replacement,
    autonomous_annual_settlement,
    automation_kpi,
    bbb_act_check,
    decision_dna,
    decision_modes,
    decision_quality_continuous,
    dependency_impact_simulator,
    fortress_architecture,
    fortress_layers,
    fortress_readiness_score,
    jdg_simulation_twin,
    knowledge_graph,
    legal_adaptation_24h,
    legal_coverage_final,
    legal_gap_closure,
    master_plan,
    multi_pass_orchestrator,
    opa_adaptation_system,
    proof_of_correctness,
    self_learning_system,
    state_synthesis,
    tax_risk_map,
    virtual_accountant,
    voice_accountant_assistant,
    zero_downtime_updates,
)

RULES_DIR = BASE_DIR / "rules"


# ── Sekcja 1: SYNTEZA STANU ───────────────────────────────────────────────────
def test_state_synthesis():
    res = state_synthesis()
    assert res["audit_type"] == "STATE_SYNTHESIS"
    assert res["rego_files"] >= 300
    assert res["unique_rule_ids"] >= 9000
    assert res["completeness_score"] < COMPLETENESS_TARGET  # 78 < 100


def test_state_real_manifest():
    manifest = json.loads((BASE_DIR / "bundles" / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["metadata"]["rules_count"] >= 10000
    assert manifest["metadata"]["unique_rule_ids"] >= 9000


def test_virtual_accountant():
    res = virtual_accountant(auto_post=60.0, suggest=30.0, ask=10.0)
    assert res["mode"] == "AUTONOMOUS_END_TO_END"
    assert res["auto_post_pct"] == 60.0


# ── Sekcja 2: ZASTĄPIENIE KSIĘGOWEGO (PRIORYTET ★) ────────────────────────────
def test_accountant_replacement():
    res = accountant_replacement(auto_post=60.0, suggest=30.0, ask=10.0, clicks=5)
    assert res["audit_type"] == "ACCOUNTANT_REPLACEMENT"
    assert "AUTOMATYZACJA MOŻLIWA" in res["status"]
    assert AUTO_POST_TARGET_PCT == 60.0
    assert ASK_USER_MAX_PCT == 10.0


def test_accountant_weak():
    res = accountant_replacement(auto_post=40.0, suggest=30.0, ask=30.0, clicks=30)
    assert "POTRZEBNA OPTYMALIZACJA" in res["status"]


def test_automation_kpi():
    res = automation_kpi(tracked=True)
    assert len(res["kpi"]) == 6
    assert res["kpi_tracked"] is True


def test_decision_modes():
    res = decision_modes()
    assert res["modes"] == ["AUTO_POST", "SUGGEST", "ASK_USER"]
    assert res["mode_config_active"] is True


# ── Sekcja 3: POKRYCIE PRAWNE ─────────────────────────────────────────────────
def test_legal_coverage_final():
    res = legal_coverage_final(acts=13, fully_covered=10, coverage=96.0, gaps=3)
    assert res["audit_type"] == "LEGAL_COVERAGE_FINAL"
    assert res["coverage_pct"] == 96.0
    assert TARGET_COVERAGE_PCT == 100


def test_legal_gap_closure():
    res = legal_gap_closure(gaps=3, active=True)
    assert len(res["closure_plan"]) == 4
    assert res["closure_target_pct"] == 100


def test_bbb_act_check():
    res = bbb_act_check(verified=13, gaps=3, isap=True)
    assert res["verification_tool"] == "validate_legal_basis.py"
    assert res["isap_synced"] is True


# ── Sekcja 4: FORTECA (PRIORYTET ★) ───────────────────────────────────────────
def test_fortress_architecture():
    res = fortress_architecture(score=78)
    assert len(res["layers"]) == 6
    assert "FORTECA W BUDOWIE" in res["status"]
    assert FORTRESS_SCORE_TARGET == 95


def test_fortress_reached():
    res = fortress_architecture(score=97)
    assert "FORTECA OSIĄGNIĘTA" in res["status"]


def test_knowledge_graph():
    res = knowledge_graph(nodes=10509, edges=50000)
    assert res["nodes"] == KNOWLEDGE_GRAPH_NODES
    assert res["transitive_closure"] is True


def test_proof_of_correctness():
    res = proof_of_correctness(with_proof=10509)
    assert res["proof_min"] == PROOF_OF_CORRECTNESS_MIN
    assert res["proof_coverage_pct"] == 100.0


def test_jdg_simulation_twin():
    res = jdg_simulation_twin(match_rate=0.97)
    assert res["twin_mode"] == "FULL_JDG"
    assert res["production_match_rate"] == 0.97


def test_self_learning_system():
    res = self_learning_system(learned=5000, updates=120)
    assert res["learning_mode"] == "REAL_VERDICTS"
    assert res["trust_score_updates"] == 120


def test_tax_risk_map():
    res = tax_risk_map(high_risk=25)
    assert "VAT_karuzela" in res["risk_zones"]
    assert res["high_risk_rules"] == 25


def test_autonomous_annual_settlement():
    res = autonomous_annual_settlement(auto_filled=5)
    assert len(res["annual_forms"]) == 5
    assert res["forms_total"] == 5


def test_voice_assistant():
    res = voice_accountant_assistant(queries=50, voice=False)
    assert res["assistant_mode"] == "VOICE"
    assert res["voice_active"] is False


def test_multi_pass_orchestrator():
    res = multi_pass_orchestrator(passes_active=9)
    assert len(res["passes"]) == 9
    assert res["orchestrator_active"] is True


def test_fortress_layers():
    res = fortress_layers(active=6)
    assert res["layers_total"] == 6
    assert res["block_on_layer_fail"] is True


def test_decision_dna():
    res = decision_dna(tracked=True)
    assert len(res["dna_fields"]) == 7
    assert res["dna_auditable"] is True


# ── Sekcja 5: ADAPTACJA ───────────────────────────────────────────────────────
def test_opa_adaptation():
    res = opa_adaptation_system(hours=24, zero_downtime=True)
    assert "ADAPTACJA W 24h" in res["status"]
    assert res["max_hours"] == ADAPTATION_HOURS_MAX


def test_opa_adaptation_slow():
    res = opa_adaptation_system(hours=96, zero_downtime=True)
    assert "ADAPTACJA ZA WOLNA" in res["status"]


def test_legal_adaptation_24h():
    res = legal_adaptation_24h(active=True)
    assert res["target_hours"] == 24
    assert res["bundle_rebuilt"] is True


def test_zero_downtime():
    res = zero_downtime_updates(canary=5, downtime_ms=0)
    assert res["update_mode"] == "ZERO_DOWNTIME"
    assert res["downtime_ms"] == 0


def test_quality_continuous():
    res = decision_quality_continuous(quality=0.97, anomalies=0)
    assert res["quality_threshold"] == 0.95
    assert res["anomalies"] == 0


def test_dependency_simulator():
    res = dependency_impact_simulator(affected=12, transitive=45)
    assert res["transitive_dependencies"] == 45
    assert res["simulation_before_deploy"] is True


# ── Sekcja 6: MASTER PLAN ─────────────────────────────────────────────────────
def test_master_plan():
    res = master_plan(phase="P1_DOMKNIECIE_LUK")
    assert res["plan_phases"] == ["P0_FUNDAMENT", "P1_DOMKNIECIE_LUK", "P2_AUTOMATYZACJA", "P3_FORTECA"]
    assert res["phase0_done"] is True
    assert "P1_DOMKNIECIE_LUK" in res["status"]


def test_fortress_readiness_score():
    res = fortress_readiness_score(coverage=96, zero_defect=100, automation=60, adaptation=80, test_shield=85, observability=75)
    assert res["fortress_score"] == 82.67  # (96+100+60+80+85+75)/6 = 82.67
    assert "FORTECA W BUDOWIE" in res["status"]


def test_fortress_readiness_reached():
    res = fortress_readiness_score(coverage=98, zero_defect=100, automation=90, adaptation=95, test_shield=95, observability=92)
    assert res["fortress_score"] >= 95
    assert "FORTECA OSIĄGNIĘTA" in res["status"]


# ── WIRING: P24 wpięty w main_jdg.rego ────────────────────────────────────────
def test_p24_wiring_in_main():
    main = (RULES_DIR / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p24_audyt_kompletny_innovations" in main
    assert '"jdg.p24_audyt_kompletny_innovations": p24_audyt_kompletny_innovations.decide' in main
    assert "final_verdict_p24 = safe_merge(final_verdict_p23," in main


# ── KOMPLETNOŚĆ PLIKÓW ────────────────────────────────────────────────────────
def test_p24_files_exist():
    expected = [
        RULES_DIR / "p24_audyt_kompletny_innovations_v9.rego",
        BASE_DIR / "tools" / "audyt_kompletny_auditor.py",
        BASE_DIR / "tests" / "rego" / "test_p24_audyt_kompletny_enterprise.rego",
        BASE_DIR / "docs" / "AUDYT_KOMPLETNY_P24.md",
        BASE_DIR / "raporty_glm52" / "RAPORT_16_SYSTEM_OPA.txt",
    ]
    for path in expected:
        assert path.exists(), f"brakuje pliku: {path}"


def test_p24_rego_package_name():
    text = (RULES_DIR / "p24_audyt_kompletny_innovations_v9.rego").read_text(encoding="utf-8")
    assert "package jdg.p24_audyt_kompletny_innovations" in text
    assert "INN-01" in text and "INN-20" in text
    assert "fortress_readiness_score" in text
    assert "accountant_replacement" in text


def test_p24_no_collision_with_old():
    old = (RULES_DIR / "p24_innovations_enterprise.rego").read_text(encoding="utf-8") if (RULES_DIR / "p24_innovations_enterprise.rego").exists() else ""
    new = (RULES_DIR / "p24_audyt_kompletny_innovations_v9.rego").read_text(encoding="utf-8")
    assert "package jdg.p24_innovations" not in new
    assert "package jdg.p24_audyt_kompletny_innovations" in new
    assert old  # stary pakiet v7 nadal istnieje


def test_p24_smoke_cli():
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "audyt_kompletny_auditor.py"), "--audit", "--accountant", "--score"],
        capture_output=True, text=True, cwd=BASE_DIR.parent, timeout=60,
    )
    assert proc.returncode == 0, proc.stderr
    out = json.loads(proc.stdout)
    assert "state" in out["audit"]
    assert "STATE_SYNTHESIS" == out["audit"]["state"]["audit_type"]
    assert "AUTOMATYZACJA MOŻLIWA" in out["accountant_replacement"]["status"]
    assert "fortress_score" in out["audit"]["score"]
    assert "fortress_score" in out["fortress_readiness_score"]


# ── FINALNE: STATUS 24/24 ─────────────────────────────────────────────────────
def test_status_24_of_24():
    """Kanoniczny RAPORT_16 (SYSTEM OPA, P21–P24) istnieje i jest WDROŻONY_100."""
    r = BASE_DIR / "raporty_glm52" / "RAPORT_16_SYSTEM_OPA.txt"
    assert r.exists(), "Brak kanonicznego raportu RAPORT_16_SYSTEM_OPA.txt"
    text = r.read_text(encoding="utf-8")
    assert "Status: WDROZONY_100" in text
    assert "P24" in text
