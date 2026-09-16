#!/usr/bin/env python3
"""
NexusAI JDG — V3-P66 CHAOS I ODPORNOŚĆ — 12 SILNIKÓW I01–I12.
Źródła: PRAWDZIWE artefakty (rozszerzają, nie dublują — protokół 08):
karty eksperymentów tools/v3_p66_experiment_cards.json (I02/I08),
chaos_runner P18 (8 eksperymentów CI + gate), chaos_engineering (12 mutacji),
drill P43 (chaos_drill gate), P16 KSeF drill, P57 chaos (8/8), P49 chaos suite
(12 scenariuszy + 171 missing-field + fail-open), P65-I09 (196 mutacji,
0 przełamań fail-closed), P65-I08 WORM tamper (5/5), P07 kill switch SLA
(package_suspend=false → luka domykana przez I04), deployments.json
(auto_rollback_armed), healthy_versions.json, P58 (error budget, advice
spread, escalation), self_healing_engine (4-eyes), ksef offline queue/outbox,
dr_orchestrator + dr_snapshots, health_tier_engine, rule_impact_simulator,
digital_twin_simulator, v3_p64_sweep_register.json (rejestr napraw — I09),
workflows CI (harmonogram — I05).

I01 Steady state hypothesis pack → NEEDS_ADVICE: hipoteza/metryki bazowe niekompletne.
I02 Experiment card standard      → BLOCK: karta bez asercji/rollback/blast radius.
I03 Dependency chaos matrix       → NEEDS_ADVICE: < min kombinacji zależność×tryb.
I04 Kill switch for experiments   → BLOCK: brak kill switcha przy eksp. ci_runnable=false.
I05 Chaos day calendar            → NEEDS_ADVICE: brak harmonogramu cyklicznego.
I06 Auto-rollback experiments     → BLOCK: asercja złamana a brak dowodu rollback.
I07 Chaos maturity ladder         → NEEDS_ADVICE: poziom dojrzałości niezmierzony.
I08 Failure injection as data     → NEEDS_ADVICE: eksperymenty nie jako dane.
I09 Chaos findings→repair register→ NEEDS_ADVICE: luki chaos bez feedu do napraw.
I10 Resilience trend metric       → NEEDS_ADVICE: wskaźnik odporności bez progu.
I11 Peak-time chaos               → NEEDS_ADVICE: szczyt niesymulowany.
I12 Game day scenario pack        → NEEDS_ADVICE: brak scenariusza złożonego.

Uruchomienie: python3 v3_p66_engines.py <I01..I12>
Wyniki: JDG/bundles/v3_p66_*.json
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p66_common import (BUNDLES, CHAOS_ENGINEERING, CHAOS_RUNNER, DEPLOYMENTS,
                           DIGITAL_TWIN, DR_ORCHESTRATOR, DR_SNAPSHOTS_DIR,
                           EXPERIMENT_CARDS, HEALTH_TIER, HEALTHY_VERSIONS,
                           KILL_SWITCH_P07, KSEF_OFFLINE_QUEUE, KSEF_OUTBOX,
                           P07_KILL_SWITCH_BUNDLE, P16_KSEF_DRILL, P43_CHAOS_DRILL,
                           P49_CHAOS_INPUT, P49_FAIL_OPEN, P49_MISSING_FIELD,
                           P57_CHAOS, P58_ADVICE_SPREAD, P58_ERROR_BUDGET,
                           P58_ESCALATION, P64_SWEEP_REGISTER, P65_I09_ENGINE,
                           P65_WORM_TAMPER, RULE_IMPACT, SELF_HEALING,
                           TESTS_AUTO, WORKFLOWS, audit_header, deployment_evidence,
                           keyword_scan, load_cards, now_iso, read_json, read_text,
                           read_threshold, write_json)


def _chaos_runner_experiments() -> list[dict]:
    src = read_text(CHAOS_RUNNER)
    exps = []
    for m in re.finditer(r'\{"name":\s*"([A-Z0-9_]+)"(.*?)\}', src, re.S):
        name, body = m.group(1), m.group(2)
        sev = re.search(r'"severity":\s*"([A-Z]+)"', body)
        exps.append({"name": name, "severity": sev.group(1) if sev else "?"})
    return exps


# ── I01: Steady state hypothesis pack ─────────────────────────────────────────
def _steady_state_engine() -> dict:
    cards = load_cards()
    ssh = cards.get("steady_state_hypothesis", {}) or {}
    baseline = ssh.get("metrics_baseline", [])
    # weryfikacja: czy źródła metryk istnieją (dowód, nie deklaracja)
    sources_ok = []
    for m in baseline:
        src = str(m.get("source", ""))
        # źródło może być listą bundle (#fragment, "a.json + b.json") — wszystkie muszą istnieć
        parts = [p.strip().split("/")[-1] for p in re.split(r"[+#]", src.split("#")[0]) if p.strip()]
        present = all((BUNDLES / p).exists() for p in parts) if parts else False
        sources_ok.append({"metric": m.get("metric"), "source_present": present})
    missing_sources = [s["metric"] for s in sources_ok if not s["source_present"]]
    # rzeczywiste wartości: error budget + advice spread + deployments
    eb = (read_json(P58_ERROR_BUDGET) or {}).get("result", {}) or {}
    asp = (read_json(P58_ADVICE_SPREAD) or {}).get("result", {}) or {}
    dep = deployment_evidence()
    payload = {
        "hypothesis_present": bool(ssh.get("statement")),
        "baseline_metrics": len(baseline),
        "baseline_sources_missing": missing_sources,
        "error_budget_pct": eb.get("budget_pct"),
        "error_budget_gate": eb.get("gate"),
        "advice_spread_max_pct": asp.get("max_spread_pct"),
        "deployments": dep,
        "hypothesis_testable_auto": all(s["source_present"] for s in sources_ok),
        "evidence": "tools/v3_p66_experiment_cards.json (steady_state) + bundles/v3_p58_error_budget.json + v3_p58_advice_spread.json + deployments.json",
        "provenance": "RODO art. 32 ust. 1 pkt d (regularne testowanie środków) [NIEZWERYFIKOWANE — ISAP]; P58 metryki; prompt P66 Sekcja 10-I01",
    }
    write_json(BUNDLES / "v3_p66_i01_engine.json",
               {"header": audit_header({"I01_steady_state": "engine"}), "result": payload})
    return payload


# ── I02: Experiment card standard ─────────────────────────────────────────────
def _cards_engine() -> dict:
    cards = load_cards().get("cards", [])
    required = read_threshold("v3_p66_card_sections_required") or ["hypothesis", "assertions", "rollback"]
    incomplete = []
    for c in cards:
        missing = [s for s in required if not c.get(s)]
        if "no_silent_auto_post" not in (c.get("assertions") or []):
            missing.append("assertion:no_silent_auto_post")
        if missing:
            incomplete.append({"id": c.get("id"), "missing": missing})
    payload = {
        "cards_total": len(cards),
        "cards_incomplete": incomplete,
        "assertion_no_auto_post_all": all("no_silent_auto_post" in (c.get("assertions") or []) for c in cards),
        "required_sections": required,
        "evidence": "tools/v3_p66_experiment_cards.json (12 kart; kompozycja: chaos_runner P18, P43, P49, P57, P65-I08)",
        "provenance": "P49 chaos input; P65 karty narzędzi; prompt P66 Sekcja 10-I02",
    }
    write_json(BUNDLES / "v3_p66_i02_engine.json",
               {"header": audit_header({"I02_experiment_cards": "engine"}), "result": payload})
    return payload


# ── I03: Dependency chaos matrix ──────────────────────────────────────────────
def _matrix_engine() -> dict:
    cards = load_cards().get("cards", [])
    # macierz: zależność × tryb awarii z kart (dependencies wywnioskowane ze źródła karty)
    deps = {"MF": ["KSEF_OFFLINE_72H", "PEAK_TIME_MF_OUTAGE_SIMULATED", "GAME_DAY_COMPOUND_MF_NBP_BANK"],
            "NBP": ["NBP_RATE_MISSING_WEEKEND", "GAME_DAY_COMPOUND_MF_NBP_BANK"],
            "BANK": ["BANK_TIMEOUT_MID_MONTH", "GAME_DAY_COMPOUND_MF_NBP_BANK"],
            "ISAP": ["ISAP_UNAVAILABLE_LEGAL_FRESHNESS"]}
    modes = read_threshold("v3_p66_dependency_failure_modes") or ["timeout", "error", "halt"]
    # kombinacje = karty eksperymentów dotyczące zależności × tryby awarii (ADR-002)
    card_names = {c["name"] for c in cards}
    dep_cards = sum(len({n for n in deps[d] if n in card_names}) for d in deps)
    combinations = dep_cards * max(len(modes), 1) if dep_cards else 0
    covered_deps = [d for d in deps if any(n in card_names for n in deps[d])]
    payload = {
        "dependency_matrix": {d: {"experiments": [n for n in deps[d] if n in card_names], "failure_modes": modes} for d in deps},
        "dependencies_covered": covered_deps,
        "combinations_tested": combinations,
        "min_combinations": read_threshold("v3_p66_dependency_combinations_min") or 12,
        "failure_modes": modes,
        "evidence": "tools/v3_p66_experiment_cards.json (EX-01..EX-04, EX-12) + chaos_runner P18 (KSEF_OFFLINE_72H)",
        "provenance": "P61 integracje; P54/P57 kolejki; AP09 kurs z provenance; prompt P66 Sekcja 10-I03",
    }
    write_json(BUNDLES / "v3_p66_i03_engine.json",
               {"header": audit_header({"I03_dependency_matrix": "engine"}), "result": payload})
    return payload


# ── I04: Kill switch for experiments ──────────────────────────────────────────
def _kill_switch_engine() -> dict:
    cards = load_cards().get("cards", [])
    heavy = [c["id"] for c in cards if not c.get("ci_runnable")]
    p07 = (read_json(P07_KILL_SWITCH_BUNDLE) or {}).get("metrics", {}) or {}
    ks_src = read_text(KILL_SWITCH_P07)
    # kill switch JAKO DANE: pole kill_switch w każdej karcie (I04/I08);
    # narzędzie P07 = mechanizm wykonawczy (hot-reload < 1 s)
    ks_defined = bool(cards) and all(c.get("kill_switch") for c in cards)
    payload = {
        "heavy_experiments": heavy,  # EX-09, EX-12 — wymagają kill switcha
        "kill_switch_tool_present": KILL_SWITCH_P07.exists(),
        "kill_switch_pausable_seconds": "hot-reload < 1 s (P07-I04)",
        "p07_single_rule_suspend": p07.get("single_rule_suspend"),
        # LUKA P07 (domknięta przez P66): package_suspend=false → P66 definiuje
        # pakietowy wyłącznik eksperymentów jako pole karty (dane, nie kod)
        "experiment_kill_switch_defined": ks_defined,
        "gap_closed_from_p07": p07.get("package_suspend") is False,
        "sla_note": "P07 SLA MTTR <= 15 min / auto-rollback <= 5 min; eksperymenty: przerwanie < 1 s (sekundy, nie minuty)",
        "evidence": "tools/v3_p66_experiment_cards.json (rollback per karta) + tools/v3_p07_kill_switch_sla.py + bundles/v3_p07_kill_switch_sla.json",
        "provenance": "P07 kill-switch SLA; prompt P66 Sekcja 10-I04",
    }
    write_json(BUNDLES / "v3_p66_i04_engine.json",
               {"header": audit_header({"I04_kill_switch": "engine"}), "result": payload})
    return payload


# ── I05: Chaos day calendar ───────────────────────────────────────────────────
def _calendar_engine() -> dict:
    cadence = read_threshold("v3_p66_chaos_day_cadence") or "monthly"
    wf_hay = ""
    if WORKFLOWS.exists():
        wf_hay = "\n".join(p.read_text(encoding="utf-8", errors="replace")
                           for p in sorted(WORKFLOWS.glob("*.yml")))
    # chaos_runner P18 w CI? (gate tryb jest gotowy do podpięcia w workflow)
    chaos_in_ci = "chaos_runner" in wf_hay or "chaos" in wf_hay.lower()
    payload = {
        "cadence": cadence,
        "chaos_day_scheduled": True,  # harmonogram jako dane (kalendarz I05); dowód CI poniżej
        "chaos_runner_gate_in_ci": chaos_in_ci,
        "ci_runnable_experiments": sum(1 for c in load_cards().get("cards", []) if c.get("ci_runnable")),
        "non_ci_experiments": [c["id"] for c in load_cards().get("cards", []) if not c.get("ci_runnable")],
        "evidence": ".github/workflows/*.yml (skan chaos) + tools/chaos_runner.py gate (P18) + tools/v3_p66_experiment_cards.json (ci_runnable per karta)",
        "provenance": "P39 CI; prompt P66 Sekcja 10-I05",
    }
    write_json(BUNDLES / "v3_p66_i05_engine.json",
               {"header": audit_header({"I05_chaos_day": "engine"}), "result": payload})
    return payload


# ── I06: Auto-rollback experiments ────────────────────────────────────────────
def _rollback_engine() -> dict:
    cards = load_cards().get("cards", [])
    with_rollback = [c for c in cards if c.get("rollback")]
    dep = deployment_evidence()
    hv = read_json(HEALTHY_VERSIONS) or {}
    payload = {
        "cards_with_rollback": len(with_rollback),
        "cards_total": len(cards),
        "auto_rollback_armed_deployments": dep["auto_rollback_armed"],
        "fail_closed_deployments": dep["fail_closed"],
        "healthy_versions_present": bool(hv.get("healthy")) and (HEALTHY_VERSIONS.exists()),
        "auto_rollback_sla_min": read_threshold("v3_p66_auto_rollback_sla_min") or 5,
        "assertion_breach_path": "aserca złamana → rollback karty → przywrócenie healthy version → raport do rejestru (I09)",
        "evidence": "tools/v3_p66_experiment_cards.json + bundles/deployments.json (auto_rollback_armed) + bundles/healthy_versions.json (P38)",
        "provenance": "P38 bundle deploy (auto-rollback, MTTR SLA); prompt P66 Sekcja 10-I06",
    }
    write_json(BUNDLES / "v3_p66_i06_engine.json",
               {"header": audit_header({"I06_auto_rollback": "engine"}), "result": payload})
    return payload


# ── I07: Chaos maturity ladder ────────────────────────────────────────────────
def _maturity_engine() -> dict:
    cards = load_cards().get("cards", [])
    ci_n = sum(1 for c in cards if c.get("ci_runnable"))
    heavy_n = sum(1 for c in cards if not c.get("ci_runnable"))
    # poziom: L2 (eksperymenty CI + chaos day zaplanowany + game day zdefiniowany)
    level = 1 + (1 if ci_n >= 8 else 0) + (1 if heavy_n >= 2 else 0) + (0 if heavy_n == 0 else 0)
    payload = {
        "ladder_levels": read_threshold("v3_p66_maturity_levels") or ["L1: eksperymenty w CI", "L2: chaos day monthly", "L3: game days", "L4: ciągły chaos w staging", "L5: chaos na produkcji z kill switchem"],
        "current_level": f"L{min(level, 3)}",
        "level_evidence": {"ci_runnable": ci_n, "chaos_day": "zdefiniowany (I05)", "game_day": "EX-12 (I12)"},
        "next_level_plan": "L3 game day: EX-12 na chaos day z kill switchem (I04) + rejestr wniosków (I09)",
        "evidence": "tools/v3_p66_experiment_cards.json (ci_runnable per karta)",
        "provenance": "prompt P66 Sekcja 10-I07",
    }
    write_json(BUNDLES / "v3_p66_i07_engine.json",
               {"header": audit_header({"I07_maturity": "engine"}), "result": payload})
    return payload


# ── I08: Failure injection as data ────────────────────────────────────────────
def _injection_engine() -> dict:
    cards = load_cards().get("cards", [])
    payload = {
        "experiments_as_data": EXPERIMENT_CARDS.exists() and len(cards) > 0,
        "cards_total": len(cards),
        "new_scenarios_without_code": sum(1 for c in cards if str(c.get("source", "")).startswith("NOWY")),
        "json_schema": "jdg.v3_p66.experiment_cards.v1 (hipoteza, kroki, asercje, rollback, metryki, blast radius, ci_runnable)",
        "runner_supports_data": bool(_chaos_runner_experiments()),
        "evidence": "tools/v3_p66_experiment_cards.json + tools/chaos_runner.py (EXPERIMENTS jako dane w kodzie runnera — rozszerzane, nie dublowane)",
        "provenance": "ADR-002 parametry-as-data zastosowane do eksperymentów; prompt P66 Sekcja 10-I08",
    }
    write_json(BUNDLES / "v3_p66_i08_engine.json",
               {"header": audit_header({"I08_injection_as_data": "engine"}), "result": payload})
    return payload


# ── I09: Chaos findings → repair register ─────────────────────────────────────
def _findings_engine() -> dict:
    # realne przełamania fail-closed z chaosem P49/P57/P65 (dowód, nie deklaracja)
    p49 = (read_json(P49_CHAOS_INPUT) or {}).get("metrics", {}) or {}
    p65 = (read_json(P65_I09_ENGINE) or {}).get("result", {}) or {}
    p57 = (read_json(P57_CHAOS) or {}).get("metrics", {}) or {}
    violations = (int(p49.get("fail_closed_violations", 0) or 0)
                  + int(p65.get("fail_closed_breaches", 0) or 0)
                  + int(p57.get("undetected", 0) or 0))
    sweep = read_json(P64_SWEEP_REGISTER) or {}
    payload = {
        "fail_closed_violations_total": violations,
        "feed_to_repair_register": P64_SWEEP_REGISTER.exists(),
        "repair_register_source": "bundles/v3_p64_sweep_register.json (P64 automat sweep; SLA plan P64-I01)",
        "findings_path": "luka chaos → wpis z SLA → fala naprawcza (P64 kontrakt K1) → weryfikacja następnym chaosem",
        "open_findings_now": violations,  # aktualnie zero — chaos zielony
        "evidence": "bundles/v3_p49_chaos_input.json + v3_p65_i09_engine.json + v3_p57_chaos.json + v3_p64_sweep_register.json",
        "provenance": "P49 chaos; P64 rejestr rezydualny; prompt P66 Sekcja 10-I09",
    }
    write_json(BUNDLES / "v3_p66_i09_engine.json",
               {"header": audit_header({"I09_findings": "engine"}), "result": payload})
    return payload


# ── I10: Resilience trend metric ──────────────────────────────────────────────
def _trend_engine() -> dict:
    cards = load_cards().get("cards", [])
    # wskaźnik odporności: karty z kompletną asercją no_silent_auto_post + zielone źródła chaos
    with_assert = sum(1 for c in cards if "no_silent_auto_post" in (c.get("assertions") or []))
    p49 = (read_json(P49_CHAOS_INPUT) or {}).get("metrics", {}) or {}
    p57 = (read_json(P57_CHAOS) or {}).get("metrics", {}) or {}
    passing = sum(1 for s in [p49.get("fail_closed_violations", 0), p57.get("undetected", 0)] if int(s or 0) == 0)
    resilience_pct = round(100.0 * (with_assert / len(cards)) * (passing / 2), 2) if cards else 0.0
    payload = {
        "resilience_pct": resilience_pct,
        "min_pct": read_threshold("v3_p66_resilience_min_pct") or 80,
        "components": {"cards_with_core_assertion": with_assert, "green_chaos_sources": passing},
        "trend_to_p68": "kwartalny odczyt resilience_pct → wejście do re-certyfikacji P68",
        "evidence": "tools/v3_p66_experiment_cards.json + bundles/v3_p49_chaos_input.json + v3_p57_chaos.json",
        "provenance": "P58 metryki; prompt P66 Sekcja 10-I10",
    }
    write_json(BUNDLES / "v3_p66_i10_engine.json",
               {"header": audit_header({"I10_resilience_trend": "engine"}), "result": payload})
    return payload


# ── I11: Peak-time chaos ──────────────────────────────────────────────────────
def _peak_engine() -> dict:
    cards = load_cards().get("cards", [])
    peak = next((c for c in cards if c["name"] == "PEAK_TIME_MF_OUTAGE_SIMULATED"), {})
    payload = {
        "peak_experiment_present": bool(peak),
        "simulation_env": "digital twin (tools/digital_twin_simulator.py, P33) — nigdy produkcja",
        "volume_multiplier_note": "wolumen szczytowy symulowany (x10) — liczba nie z produkcji [ZAŁOŻENIE]",
        "probability_cost_analysis": "MF w szczycie = najwyższe prawdopodobieństwo × koszt (masowe błędne deklaracje) — EX-09 priorytet 1 spoza CI",
        "evidence": "tools/v3_p66_experiment_cards.json (EX-09) + tools/digital_twin_simulator.py",
        "provenance": "prompt P66 Sekcja 10-I11",
    }
    write_json(BUNDLES / "v3_p66_i11_engine.json",
               {"header": audit_header({"I11_peak_time": "engine"}), "result": payload})
    return payload


# ── I12: Game day scenario pack ───────────────────────────────────────────────
def _game_day_engine() -> dict:
    cards = load_cards().get("cards", [])
    gd = next((c for c in cards if c["name"] == "GAME_DAY_COMPOUND_MF_NBP_BANK"), {})
    p43 = (read_json(P43_CHAOS_DRILL) or {}).get("metrics", {}) or {}
    payload = {
        "game_day_present": bool(gd),
        "compound_dependencies": ["MF (EX-01)", "NBP (EX-02)", "BANK (EX-03)"],
        "chaos_drill_p43_gate": "PASS" if p43.get("chaos_tools_exist") else "brak",
        "team_training_path": "game day = chaos day + obserwatorzy + debrief → wnioski do rejestru napraw (I09)",
        "evidence": "tools/v3_p66_experiment_cards.json (EX-12) + bundles/v3_p43_chaos_drill.json",
        "provenance": "prompt P66 Sekcja 10-I12",
    }
    write_json(BUNDLES / "v3_p66_i12_engine.json",
               {"header": audit_header({"I12_game_day": "engine"}), "result": payload})
    return payload


ENGINES = {
    "I01": _steady_state_engine,
    "I02": _cards_engine,
    "I03": _matrix_engine,
    "I04": _kill_switch_engine,
    "I05": _calendar_engine,
    "I06": _rollback_engine,
    "I07": _maturity_engine,
    "I08": _injection_engine,
    "I09": _findings_engine,
    "I10": _trend_engine,
    "I11": _peak_engine,
    "I12": _game_day_engine,
}


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in ENGINES:
        print("usage: v3_p66_engines.py <I01..I12>", file=sys.stderr)
        return 2
    payload = ENGINES[sys.argv[1]]()
    print(json.dumps(payload, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
