#!/usr/bin/env python3
"""NexusAI JDG — V3-P45 STUB KILLER — testy pytest (konwencja P39
negative-first).

Pokrycie: 12 bundli dowodowych (gate=PASS), rego (60/60 ×2 OPA), progi jako
dane (ADR-002), wiring final_verdict_p109, rejestr stubów z SLA (I01),
mutation score ≥90 (I05), konwersje CANDIDATE/SHADOW (I09), raport P45,
ledger kampanii.
"""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
P45_RULES = BASE / "rules" / "v3_p45_stub_killer.rego"
P45_CONVERSIONS = BASE / "rules" / "v3_p45_conversions.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"
MAIN_JDG = BASE / "rules" / "main_jdg.rego"
TESTS_REGO = BASE / "tests" / "rego" / "test_v3_p45_stub_killer.rego"
TESTS_CONV_REGO = BASE / "tests" / "rego" / "test_v3_p45_conversions.rego"
BUNDLES = BASE / "bundles"
REPO_ROOT = BASE.parent

BUNDLE_TO_INNOVATION = {
    "v3_p45_stub_register": "V3-P45-I01",
    "v3_p45_stub_forensics": "V3-P45-I02",
    "v3_p45_auto_convert_pipeline": "V3-P45-I03",
    "v3_p45_negative_assertion": "V3-P45-I04",
    "v3_p45_mutation_gate": "V3-P45-I05",
    "v3_p45_stub_free_badge": "V3-P45-I06",
    "v3_p45_template_policy": "V3-P45-I07",
    "v3_p45_stub_enabling_tests": "V3-P45-I08",
    "v3_p45_provenance": "V3-P45-I09",
    "v3_p45_stub_census": "V3-P45-I10",
    "v3_p45_legal_empty": "V3-P45-I11",
    "v3_p45_isap_parity": "V3-P45-I12",
}

P45_RULE_IDS = [
    "jdg.v3_p45_stub_killer.stub_register",
    "jdg.v3_p45_stub_killer.stub_forensics",
    "jdg.v3_p45_stub_killer.auto_convert_pipeline",
    "jdg.v3_p45_stub_killer.negative_assertion",
    "jdg.v3_p45_stub_killer.mutation_score_gate",
    "jdg.v3_p45_stub_killer.stub_free_badge",
    "jdg.v3_p45_stub_killer.template_policy",
    "jdg.v3_p45_stub_killer.stub_enabling_tests",
    "jdg.v3_p45_stub_killer.provenance_of_truth",
    "jdg.v3_p45_stub_killer.stub_census",
    "jdg.v3_p45_stub_killer.legal_empty",
    "jdg.v3_p45_stub_killer.isap_parity",
]

CONV_RULE_IDS = [
    "jdg.v3_p45_conversions.uor_a2_threshold",
    "jdg.v3_p45_conversions.uor_a3_conditions",
    "jdg.v3_p45_conversions.mdr_hallmark_a",
    "jdg.v3_p45_conversions.pcc_a1_condition",
    "jdg.v3_p45_conversions.wht_foreign_service",
    "jdg.v3_p45_conversions.needs_advice",
]

P45_THRESHOLD_KEYS = [
    "v3_p45_threshold_version",
    "v3_p45_critical_domain_stubs_max",
    "v3_p45_mutation_score_min",
    "v3_p45_tautological_test_files_max",
    "v3_p45_census_max_age_days",
]

CONV_THRESHOLD_KEYS = [
    "v3_p45_conv_uor_threshold_eur",
    "v3_p45_conv_mdr_main_benefit",
    "v3_p45_conv_pcc_min_pln",
    "v3_p45_conv_wht_rate_pct",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _opa(binary: str, subcmd: str, paths: list[Path]) -> tuple[int, str]:
    exe = REPO_ROOT / "bin" / binary
    cmd = [str(exe), subcmd]
    if binary == "opa19":
        cmd.append("--v0-compatible")
    cmd += [str(p) for p in paths]
    proc = subprocess.run(cmd, cwd=REPO_ROOT, capture_output=True, text=True,
                          timeout=300)
    return proc.returncode, proc.stdout + proc.stderr


def _opa_test_count(binary: str, paths: list[Path]) -> int:
    _, out = _opa(binary, "test", paths)
    m = re.search(r"PASS: (\d+)/(\d+)", out)
    return int(m.group(2)) if m else 0


# ── Rego, progi, wiring ────────────────────────────────────────────────────────

def test_rego_all_12_rule_ids_present():
    hay = _read(P45_RULES)
    missing = [r for r in P45_RULE_IDS if r not in hay]
    assert not missing, f"Brakujące rule_id w rego: {missing}"


def test_rego_conversions_rule_ids_present():
    hay = _read(P45_CONVERSIONS)
    missing = [r for r in CONV_RULE_IDS if r not in hay]
    assert not missing, f"Brakujące rule_id konwersji: {missing}"


def test_conversions_are_conditional_not_stubs():
    """I03/I04: każda konwersja ma gałąź else — zero {true} w kodzie (nie komentarzach)."""
    hay = _read(P45_CONVERSIONS)
    assert hay.count("else := decision") >= 5
    code_lines = [ln for ln in hay.splitlines() if not ln.strip().startswith("#")]
    for ln in code_lines:
        assert not re.search(r"\{\s*true\s*\}", ln), f"stub w kodzie: {ln.strip()}"


def test_rego_negative_assertions_present():
    hay = _read(TESTS_REGO) + _read(TESTS_CONV_REGO)
    assert "BLOCK_AND_ALERT" in hay and "TRIAGE_QUEUE" in hay
    assert hay.count("test_p45") >= 40


def test_rego_native_suite_passes_opa_068():
    paths = [TESTS_REGO, TESTS_CONV_REGO, P45_RULES, P45_CONVERSIONS, THRESHOLDS]
    rc, out = _opa("opa", "test", paths)
    n = _opa_test_count("opa", paths)
    assert rc == 0 and n >= 55, f"OPA 0.68 suite: rc={rc}, PASS={n}\n{out[-400:]}"


def test_rego_native_suite_passes_opa_19():
    paths = [TESTS_REGO, TESTS_CONV_REGO, P45_RULES, P45_CONVERSIONS, THRESHOLDS]
    rc, out = _opa("opa19", "test", paths)
    n = _opa_test_count("opa19", paths)
    assert rc == 0 and n >= 55, f"OPA 1.9 suite: rc={rc}, PASS={n}\n{out[-400:]}"


def test_thresholds_as_data():
    th = _read(THRESHOLDS)
    for key in P45_THRESHOLD_KEYS + CONV_THRESHOLD_KEYS:
        assert re.search(rf'"{re.escape(key)}"\s*:', th), f"brak progu: {key}"


def test_no_hardcoded_thresholds_in_conversions():
    """ADR-002: progi konwersji pochodzą z data.thresholds, nie z literałów."""
    hay = _read(P45_CONVERSIONS)
    assert "data.jdg.thresholds.v3_p45_conversions" in hay


def test_main_jdg_wiring_p109():
    main = _read(MAIN_JDG)
    assert "import data.jdg.v3_p45_stub_killer as v3_p45_stub_killer" in main
    assert '"jdg.v3_p45_stub_killer": v3_p45_stub_killer.decide' in main
    assert "final_verdict_p109" in main


# ── Bundle dowodowe (12 innowacji) ─────────────────────────────────────────────

def test_all_12_bundles_exist_and_pass():
    for bundle, innovation in BUNDLE_TO_INNOVATION.items():
        p = BUNDLES / f"{bundle}.json"
        assert p.exists(), f"brak bundla: {p.name}"
        data = json.loads(p.read_text(encoding="utf-8"))
        assert data.get("innovation") == innovation, f"{bundle}: złe innovation"
        assert data.get("gate") == "PASS", f"{bundle}: gate={data.get('gate')}"


def test_stub_register_complete_with_sla():
    """I01: rejestr = 39 wpisów, każdy z SLA (deadline+owner+plan)."""
    reg = json.loads((BUNDLES / "stub_register.json").read_text(encoding="utf-8"))
    assert reg["total"] == 39
    assert reg["critical_domain_total"] == 3
    for e in reg["entries"]:
        assert e["deadline"] and e["owner"] and e["repair_plan"], f"brak SLA: {e['rule_id']}"


def test_stub_register_by_layer_and_domain():
    reg = json.loads((BUNDLES / "stub_register.json").read_text(encoding="utf-8"))
    assert sum(reg["by_layer"].values()) == 39
    assert sum(reg["by_domain"].values()) == 39


def test_mutation_score_above_threshold():
    """I05: mutation score z realnego silnika, ≥90."""
    res = json.loads((BUNDLES / "mutation_results.json").read_text(encoding="utf-8"))
    assert res["total_mutants"] >= 10, "za mało mutantów dla wiarygodnego pomiaru"
    assert res["mutation_score"] >= 90


def test_registry_has_17_p45_entries():
    """I09/I06: 12 CANDIDATE + 5 SHADOW w rule_registry."""
    reg = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    p45 = [k for k in reg if "v3_p45" in k]
    assert len(p45) >= 17
    statuses = {k: reg[k]["versions"][-1]["status"] for k in p45}
    candidates = sum(1 for s in statuses.values() if s == "CANDIDATE")
    shadows = sum(1 for s in statuses.values() if s == "SHADOW")
    assert candidates == 12 and shadows == 5, statuses


def test_provenance_chain_in_registry():
    """I09: każdy wpis P45 ma legal_basis + valid_from (łańcuch dowodu)."""
    reg = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    for k in reg:
        if "v3_p45" not in k:
            continue
        v = reg[k]["versions"][-1]
        assert v.get("legal_basis"), f"{k}: brak legal_basis"
        assert v.get("valid_from"), f"{k}: brak valid_from"


def test_isap_parity_all_unverified_marked():
    """I12/protokół 04: zero fikcyjnych podstaw — wszystkie [NIEZWERYFIKOWANE]."""
    bundle = json.loads((BUNDLES / "v3_p45_isap_parity.json").read_text(encoding="utf-8"))
    for p in bundle["parity"]:
        assert "NIEZWERYFIKOWANE" in p["dz_u"]


def test_mediation_register_for_p47():
    med = json.loads((BUNDLES / "v3_p45_isap_mediation_register.json").read_text(encoding="utf-8"))
    assert len(med["entries"]) == 5
    assert all(e["status"] == "NIEZWERYFIKOWANE" for e in med["entries"])


def test_ci_gate_merge_mode_pass():
    proc = subprocess.run(["python", str(BASE / "tools" / "v3_p45_gate.py")],
                          cwd=BASE, capture_output=True, text=True, timeout=120)
    assert proc.returncode == 0, f"gate merge BLOCK:\n{proc.stdout}{proc.stderr}"


def test_todo_debt_register_exists():
    """I07: TODO-długi z właścicielem w rejestrze; zero surowych placeholdingów."""
    debt = json.loads((BUNDLES / "v3_p45_todo_debt_register.json").read_text(encoding="utf-8"))
    assert isinstance(debt["managed_debt"], list)
    for d in debt["managed_debt"]:
        assert d["owner_part"], d


# ── Raport i ledger ────────────────────────────────────────────────────────────

def test_report_p45_exists_with_status():
    report = BASE / "raporty_glm52_v3" / "RAPORT_V3_P45_STUB_KILLER.txt"
    assert report.exists(), "brak raportu P45"
    head = report.read_text(encoding="utf-8", errors="ignore")[:2000]
    assert re.search(r"Status:\s*WDROŻONY_100", head), "raport bez statusu WDROŻONY_100"


def test_ledger_marks_p45_wdrozony():
    ledger = json.loads((BUNDLES / "v3_campaign_ledger.json").read_text(encoding="utf-8"))
    p45 = ledger["parts"]["P45"]
    assert p45["status"] == "WDROŻONY_100"
    assert p45["innovations"] == 12
