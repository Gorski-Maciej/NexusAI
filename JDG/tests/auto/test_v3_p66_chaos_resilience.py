"""Testy pytest V3-P66 CHAOS I ODPORNOŚĆ (konwencja P51–P65).

Pokrywają: 12 silników I01–I12 vs bundla (jedno źródło), karty eksperymentów
(asercja no_silent_auto_post w każdej karcie), chaos_runner gate (P18),
progi z ADR-002 (brak hardcode), wiring main_jdg p130, mirror hash-parity,
fail-closed (zero AUTO_POST), kompozycja z P18/P33/P38/P43/P49/P57/P58/P64/P65/P07.
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
RULE = RULES / "v3_p66_chaos_resilience.rego"
TOOLS = JDG / "tools"
CARDS = TOOLS / "v3_p66_experiment_cards.json"


def _load(name: str) -> dict:
    return json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))


def _run(script: str, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(TOOLS / script), *args],
                          capture_output=True, text=True, timeout=120)


# ═══ 1. Run-all gate ═══
def test_run_all_gate_pass():
    d = _load("v3_p66_run_all")
    assert d["gate"] == "PASS", d["failures"]
    assert d["engines_run"] == 12
    assert d["failures"] == []
    assert d["rego_gate"] == "PASS"  # natywne testy OPA (kontrakt C2 z P65)


# ═══ 2. Karty eksperymentów jako dane (I02/I08) ═══
def test_experiment_cards_as_data():
    cards = json.loads(CARDS.read_text(encoding="utf-8"))
    assert len(cards["cards"]) >= 10  # prompt P66: katalog 10–15
    for c in cards["cards"]:
        assert c.get("hypothesis"), f"{c['id']}: brak hipotezy"
        assert "no_silent_auto_post" in c.get("assertions", []), \
            f"{c['id']}: brak asercji no_silent_auto_post (AP07)"
        assert c.get("rollback"), f"{c['id']}: brak rollback"
        assert c.get("blast_radius"), f"{c['id']}: brak blast radius"
        assert c.get("metrics"), f"{c['id']}: brak metryk P58"
    # steady state hypothesis pack
    ssh = cards["steady_state_hypothesis"]
    assert len(ssh["metrics_baseline"]) >= 4


# ═══ 3. I01: steady state hypothesis pack ═══
def test_i01_steady_state():
    r = _load("v3_p66_i01_engine")["result"]
    assert r["hypothesis_present"] is True
    assert r["baseline_metrics"] >= 4
    assert r["baseline_sources_missing"] == []
    assert r["error_budget_gate"] == "PASS"  # P58 error budget
    assert r["deployments"]["fail_closed"] >= 20  # deployments.json (P38): 24/44 fail_closed


# ═══ 4. I02: karty eksperymentów ═══
def test_i02_cards():
    r = _load("v3_p66_i02_engine")["result"]
    assert r["cards_total"] >= 10
    assert r["cards_incomplete"] == []
    assert r["assertion_no_auto_post_all"] is True


# ═══ 5. I03: macierz zależności ═══
def test_i03_dependency_matrix():
    r = _load("v3_p66_i03_engine")["result"]
    assert r["combinations_tested"] >= 12  # min z ADR-002
    assert set(r["failure_modes"]) == {"timeout", "error", "halt"}
    for dep in ["MF", "NBP", "BANK", "ISAP"]:
        assert dep in r["dependency_matrix"], f"brak zależności {dep}"


# ═══ 6. I04: kill switch eksperymentów ═══
def test_i04_kill_switch():
    r = _load("v3_p66_i04_engine")["result"]
    assert r["kill_switch_tool_present"] is True  # tools/v3_p07_kill_switch_sla.py
    assert r["experiment_kill_switch_defined"] is True
    assert len(r["heavy_experiments"]) >= 2  # EX-09 peak + EX-12 game day
    assert r["gap_closed_from_p07"] is True  # domknięcie package_suspend=false


# ═══ 7. I05: chaos day calendar ═══
def test_i05_chaos_day():
    r = _load("v3_p66_i05_engine")["result"]
    assert r["chaos_day_scheduled"] is True
    assert r["cadence"] == "monthly"
    assert r["ci_runnable_experiments"] >= 9  # 10 z 12 kart runnable w CI


# ═══ 8. I06: auto-rollback ═══
def test_i06_auto_rollback():
    r = _load("v3_p66_i06_engine")["result"]
    assert r["cards_with_rollback"] == r["cards_total"]
    assert r["auto_rollback_armed_deployments"] >= 5  # P38 armed (7/44)
    assert r["healthy_versions_present"] is True
    assert r["auto_rollback_sla_min"] == 5


# ═══ 9. I07: maturity ladder ═══
def test_i07_maturity():
    r = _load("v3_p66_i07_engine")["result"]
    assert len(r["ladder_levels"]) == 5
    assert r["current_level"] in ("L1", "L2", "L3", "L4", "L5")


# ═══ 10. I08: failure injection as data ═══
def test_i08_injection_as_data():
    r = _load("v3_p66_i08_engine")["result"]
    assert r["experiments_as_data"] is True
    assert r["cards_total"] >= 10
    assert r["new_scenarios_without_code"] >= 4  # EX-02/03/04/09/12


# ═══ 11. I09: findings → repair register ═══
def test_i09_findings():
    r = _load("v3_p66_i09_engine")["result"]
    assert r["fail_closed_violations_total"] == 0  # chaos zielony (P49+P57+P65)
    assert r["feed_to_repair_register"] is True  # v3_p64_sweep_register.json


# ═══ 12. I10: resilience trend ═══
def test_i10_resilience():
    r = _load("v3_p66_i10_engine")["result"]
    assert r["resilience_pct"] >= 80  # próg ADR-002
    assert r["components"]["cards_with_core_assertion"] >= 10


# ═══ 13. I11 + I12: peak-time + game day ═══
def test_i11_peak_time():
    r = _load("v3_p66_i11_engine")["result"]
    assert r["peak_experiment_present"] is True
    assert "digital twin" in r["simulation_env"]  # symulacja, nigdy produkcja


def test_i12_game_day():
    r = _load("v3_p66_i12_engine")["result"]
    assert r["game_day_present"] is True
    assert len(r["compound_dependencies"]) == 3  # MF + NBP + BANK


# ═══ 14. chaos_runner P18: gate (kompozycja, nie duplikacja) ═══
def test_chaos_runner_gate():
    proc = _run("chaos_runner.py", "gate")
    assert proc.returncode == 0
    d = json.loads(proc.stdout)
    assert d["gate"] == "PASS"
    assert d["experiments_run"] == 8


# ═══ 15. Progi z ADR-002 (zero hardcode) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p66_steady_state_metrics_min", "v3_p66_card_sections_required",
              "v3_p66_dependency_failure_modes", "v3_p66_dependency_combinations_min",
              "v3_p66_chaos_day_cadence", "v3_p66_auto_rollback_sla_min",
              "v3_p66_maturity_levels", "v3_p66_resilience_min_pct"]:
        assert k in hay, f"brak klucza ADR-002: {k}"
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert '"v3_p66_threshold_version": "chaos-resilience-v3p66-2026.09"' in th
    assert th.count('"v3_p66_') >= 9  # threshold_version + legal_basis + 7+ kluczy I01–I12


def test_thresholds_temporal_window():
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    blk = th[th.index("v3_p66 := {"):]
    assert '"valid_from": "2026-01-01"' in blk and '"valid_to": null' in blk


# ═══ 16. Wiring main_jdg p130 ═══
def test_wiring_main_jdg():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p66_chaos_resilience as v3_p66_chaos_resilience" in main
    assert "final_verdict_p130 = safe_merge(final_verdict_p129" in main
    assert "v3_p66_chaos_resilience.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    # Kotwica POST-MERGE przesunięta na p131 (wiring P67, kampania V3).
    assert "final_verdict_p131" in post[:400]


# ═══ 17. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p66_chaos_resilience", "v3_p65_tool_forge", "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 18. Fail-closed statycznie: router nie ma ścieżki AUTO_POST ═══
def test_fail_closed_static():
    hay = RULE.read_text(encoding="utf-8")
    assert hay.count('"AUTO_POST"') == 0
    assert "NO_MATCH" in hay and "NEEDS_ADVICE" in hay
    # final_verdict_p130 tylko w komentarzu nagłówka (konwencja P59–P66) —
    # rega P66 nie wykonuje host-wiringu.
    assert hay.count("final_verdict_p130") == 1


# ═══ 19. Rego struktura: pakiety, priorytety, unikalność ═══
def test_rego_structure():
    t = RULE.read_text(encoding="utf-8")
    assert t.count("{") == t.count("}")
    assert "package jdg.v3_p66_chaos_resilience" in t
    for n in range(1, 13):
        assert f"4660{n:02d}" in t, f"brak priorytetu I{n:02d}"


# ═══ 20. Natywne testy OPA obecne i kompletność źródeł ═══
def test_native_opa_tests_present():
    t = (JDG / "tests" / "rego" / "test_v3_p66_chaos_resilience.rego").read_text(encoding="utf-8")
    assert t.count("test_") >= 19
    hay = ((TOOLS / "v3_p66_engines.py").read_text(encoding="utf-8")
           + (TOOLS / "v3_p66_common.py").read_text(encoding="utf-8"))
    for src in ["chaos_runner.py", "chaos_engineering.py", "v3_p07_kill_switch_sla.py",
                "ksef_offline_queue.py", "ksef_outbox.py", "self_healing_engine.py",
                "digital_twin_simulator.py", "rule_impact_simulator.py",
                "v3_p49_chaos_input.json", "v3_p57_chaos.json",
                "v3_p65_i09_engine.json", "deployments.json", "healthy_versions.json",
                "v3_p58_error_budget.json", "v3_p64_sweep_register.json",
                "dr_orchestrator.py", "health_tier_engine.py",
                "verify_verdict_invariants.py"]:
        assert src in hay, f"brak powiązania z prawdziwym źródłem: {src}"


# ═══ 21. Silniki: determinizm (2 przebiegi I01 identyczne) ═══
def test_engines_deterministic():
    p1 = _run("v3_p66_engines.py", "I01")
    p2 = _run("v3_p66_engines.py", "I01")
    assert p1.returncode == p2.returncode == 0
    a, b = json.loads(p1.stdout), json.loads(p2.stdout)
    assert a == b  # drugi przebieg = identyczny wynik
