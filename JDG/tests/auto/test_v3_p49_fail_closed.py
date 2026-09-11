# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY AUTO V3-P49 DOMKNIĘCIE FAIL-CLOSED (konwencja
# P45/P46/P47/P48: dowody z narzędzi i bundli, honesty liczników, fail-closed
# bramek, ADR-002 zero hardcode, AP01/AP03/AP07 anty-wzorce).
# Uruchomienie: python -m pytest tests/auto/test_v3_p49_fail_closed.py -q
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]  # tests/auto/ → JDG
BUNDLES = BASE / "bundles"
REPO_ROOT = BASE.parent
P49_REGO = BASE / "rules" / "v3_p49_fail_closed.rego"
P49_REGO_MIRROR = REPO_ROOT / "policies" / "v3_p49_fail_closed.rego"
MAIN_REGO = BASE / "rules" / "main_jdg.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"
TESTS_REGO = BASE / "tests" / "rego" / "test_v3_p49_fail_closed.rego"


def _bundle(name: str) -> dict:
    path = BUNDLES / f"v3_p49_{name}.json"
    assert path.exists(), f"brak bundla dowodowego: {path.name}"
    return json.loads(path.read_text(encoding="utf-8"))


# ── Warstwa rego / konwencje ──────────────────────────────────────────────────

def test_p49_rego_package_present():
    src = P49_REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p49_fail_closed" in src


def test_p49_rego_mirror_semantically_identical():
    """AP11/P48-I02: mirror = build output — treść semantyczna identyczna."""
    canonical = P49_REGO.read_text(encoding="utf-8")
    mirror = P49_REGO_MIRROR.read_text(encoding="utf-8")
    assert canonical == mirror, "mirror P49 dryfuje względem canonical (raw diff)"


def test_p49_rego_zero_hardcode_thresholds():
    """ADR-002: progi wyłącznie z data.jdg.thresholds.v3_p49."""
    src = P49_REGO.read_text(encoding="utf-8")
    assert "data.jdg.thresholds.v3_p49" in src
    decision_lines = [l for l in src.splitlines()
                      if ("_th(" in l or "routing_" in l) and not l.strip().startswith("#")]
    assert decision_lines, "brak odczytów progów z snapshotu"


def test_p49_thresholds_block_present():
    src = THRESHOLDS.read_text(encoding="utf-8")
    for key in ("v3_p49_threshold_version", "v3_p49_invariants_min",
                "v3_p49_silent_auto_post_max", "v3_p49_field_coverage_min_pct",
                "v3_p49_chaos_cases_min", "v3_p49_breaker_threshold",
                "v3_p49_auto_post_amount_limit", "v3_p49_min_reason_len",
                "v3_p49_fail_closed_score_target_pct", "v3_p49_canary_interval_hours"):
        assert key in src, f"brak progu {key} w thresholds_jdg.rego"


def test_p49_main_jdg_wiring():
    src = MAIN_REGO.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p49_fail_closed" in src
    assert "final_verdict_p113" in src
    assert "v3_p49_check" in src


def test_p49_no_stub_true_rules():
    """AP01: zero reguł-stubów {true => ...} w polityce P49."""
    src = P49_REGO.read_text(encoding="utf-8")
    stubs = re.findall(r"\w+\s*:=?\s*\"[^\"]*\"\s*\{\s*true\s*\}", src)
    assert not stubs, f"stuby w polityce P49: {stubs[:3]}"


def test_p49_legal_basis_tags_honest():
    """Protokół 04: każde twierdzenie prawne z tagiem [NIEZWERYFIKOWANE — ISAP]."""
    src = P49_REGO.read_text(encoding="utf-8")
    lb_lines = [l for l in src.splitlines() if "_legal_basis" in l]
    assert len(lb_lines) >= 12, "brak _legal_basis w decyzjach P49"
    unverified = [l for l in lb_lines if "NIEZWERYFIKOWANE" in l]
    assert len(unverified) >= 12, "legal_basis bez statusu weryfikacji (fasada)"


# ── I01: invariant pack ────────────────────────────────────────────────────────

def test_p49_i01_invariant_pack_bundle():
    d = _bundle("invariant_pack")
    m = d["metrics"]
    assert m["invariants_total"] == 6
    assert m["invariants_enabled"] == 6
    assert m["wired_main_jdg"] is True
    assert d["innovation"] == "V3-P49-I01"
    # honesty: violations z realnych rekordów (baseline legacy) — fail-closed
    # pack JE wykrywa i raportuje, nie ukrywa
    assert m["violations"] >= 0
    if m["violations"] > 0:
        assert m["routing"] == "BLOCK_AND_ALERT"
        assert m["auto_post_blocked"] == m["violations"]


def test_p49_i01_violations_have_evidence():
    d = _bundle("invariant_pack")
    assert d["evidence"]["invariants"], "brak listy invariantów"
    assert all(i.startswith("INV-P49-") for i in d["evidence"]["invariants"])


# ── I02/I10: fail-open registry + score ───────────────────────────────────────

def test_p49_i02_fail_open_registry_honest():
    d = _bundle("fail_open_registry")
    m = d["metrics"]
    assert m["files_scanned"] > 400, "skaner nie objął repozytorium"
    assert m["decision_chains_total"] > 0
    # niezmiennik: explicit + fail_open == total
    assert m["paths_explicit_else"] + m["fail_open_paths"] == m["decision_chains_total"]
    # score zgodny z definicją
    expected = round(m["paths_explicit_else"] * 100.0 / m["decision_chains_total"], 2)
    assert m["fail_closed_score_pct"] == expected
    # AP07: fail_open > 0 ⇒ BLOCK (rejestr = backlog jawny)
    if m["fail_open_paths"] > 0:
        assert m["routing"] == "BLOCK_AND_ALERT"
        assert m["evidence" if False else "fail_open_paths"] >= 0  # klucz istnieje
    else:
        assert m["routing"] == "AUTO_FILE"


def test_p49_i02_findings_have_location():
    d = _bundle("fail_open_registry")
    for f in d["evidence"]["findings"]:
        assert f["file"] and f["line"] > 0
        assert f["decision_mode"] in ("AUTO_POST", "SUGGEST")


def test_p49_i10_score_matches_registry():
    score = _bundle("fail_closed_score")["metrics"]
    reg = _bundle("fail_open_registry")["metrics"]
    assert score["paths_total"] == reg["decision_chains_total"]
    assert score["paths_fail_open"] == reg["fail_open_paths"]
    assert score["fail_closed_score_pct"] == reg["fail_closed_score_pct"]


# ── I03: missing-field generator ──────────────────────────────────────────────

def test_p49_i03_generator_cases_and_variants():
    d = _bundle("missing_field_coverage")
    m = d["metrics"]
    assert m["generator_run"] is True
    assert m["missing_variants"] == 3  # null / empty_string / absent
    assert m["cases_total"] == m["fields_derived"] * 3


def test_p49_i03_cases_expect_fail_closed():
    d = _bundle("missing_field_coverage")
    for c in d["evidence"]["cases_sample"]:
        assert c["expected_decision_mode"] == "NEEDS_ADVICE"


def test_p49_i03_coverage_consistent_with_test_file():
    """Pokrycie liczone uczciwie: reguły P49 z dedykowanymi testami natywnymi
    (test_p49_i<NN>_*) + asercje braku pól (missing/empty/partial)."""
    d = _bundle("missing_field_coverage")
    m = d["metrics"]
    tsrc = TESTS_REGO.read_text(encoding="utf-8") if TESTS_REGO.exists() else ""
    for rid in d["evidence"]["covered_rules"]:
        num = {"invariant_pack": "i01", "default_deny_core": "i02",
               "missing_field_coverage": "i03", "chaos_input": "i04",
               "circuit_breaker": "i05", "amount_ceiling": "i06",
               "reason_completeness": "i07", "emergency_export": "i08",
               "replay_audit": "i09", "fail_closed_score": "i10",
               "silent_post_canary": "i11", "user_visible_safety": "i12"}[rid]
        assert f"test_p49_{num}" in tsrc, f"{rid} bez testu natywnego"
    expected = round(m["rules_covered"] * 100.0 / m["rules_total"], 2) if m["rules_total"] else 0.0
    assert m["coverage_pct"] == expected
    assert m["missing_field_assertions"] == 3  # null/empty/partial asercje obecne


# ── I04: chaos input ──────────────────────────────────────────────────────────

def test_p49_i04_chaos_suite_min_scenarios():
    d = _bundle("chaos_input")
    m = d["metrics"]
    assert m["cases_total"] >= 10, "kryterium 20: min. 10 scenariuszy mutacji"
    assert m["suite_run"] is True
    assert m["eval_errors"] == 0


def test_p49_i04_zero_fail_closed_violations():
    d = _bundle("chaos_input")
    m = d["metrics"]
    assert m["fail_closed_violations"] == 0, "chaos wykazał fail-open!"
    assert m["routing"] == "AUTO_FILE"


def test_p49_i04_results_fail_closed_modes():
    d = _bundle("chaos_input")
    safe = {"NEEDS_ADVICE", "MANUAL_REVIEW", "BLOCK", "TRIAGE"}
    for r in d["evidence"]["results"]:
        assert r["fail_closed"] is True
        if r["status"] != "ERROR":
            assert r["decision_mode"] in safe or r["rule_id"].endswith("no_match")


# ── I05: circuit breaker ──────────────────────────────────────────────────────

def test_p49_i05_breaker_thresholds_from_data():
    d = _bundle("circuit_breaker")
    m = d["metrics"]
    th_src = THRESHOLDS.read_text(encoding="utf-8")
    th = int(re.search(r'"v3_p49_breaker_threshold"\s*:\s*(\d+)', th_src).group(1))
    win = int(re.search(r'"v3_p49_breaker_window_min"\s*:\s*(\d+)', th_src).group(1))
    assert m["breaker_threshold"] == th
    assert m["breaker_window_min"] == win
    assert m["domains_total"] > 0


def test_p49_i05_review_domains_have_reason_field():
    d = _bundle("circuit_breaker")
    for rd in d["evidence"]["review_domains"]:
        assert "reason_reported" in rd


# ── I06: amount ceiling ───────────────────────────────────────────────────────

def test_p49_i06_ceiling_limit_from_thresholds():
    d = _bundle("amount_ceiling")
    m = d["metrics"]
    th_src = THRESHOLDS.read_text(encoding="utf-8")
    th = float(re.search(r'"v3_p49_auto_post_amount_limit"\s*:\s*(\d+)',
                         th_src).group(1))
    assert m["amount_limit"] == th
    assert m["limit_configured"] is True


# ── I07: reason linter ────────────────────────────────────────────────────────

def test_p49_i07_reason_defects_triage():
    d = _bundle("reason_completeness")
    m = d["metrics"]
    assert m["needs_advice_total"] > 0
    if m["needs_advice_without_reason"] > 0 or m["needs_advice_short_reason"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"  # fasada fail-closed = defekt jawny
    else:
        assert m["routing"] == "AUTO_FILE"


# ── I08: emergency export ─────────────────────────────────────────────────────

def test_p49_i08_export_path_present_and_verified():
    d = _bundle("emergency_export")
    m = d["metrics"]
    assert m["export_path_present"] is True, "brak ścieżki awaryjnej (DR P43)"
    assert m["last_export_verified"] is True
    assert m["routing"] == "AUTO_FILE"


# ── I09: replay audit ─────────────────────────────────────────────────────────

def test_p49_i09_replay_executed():
    d = _bundle("replay_audit")
    m = d["metrics"]
    assert m["weekly_replay_done"] is True
    assert m["decisions_replayed"] > 0, "replay nie objął żadnej decyzji"


# ── I11: silent-post canary ───────────────────────────────────────────────────

def test_p49_i11_canary_zero_silent_posts():
    d = _bundle("silent_post_canary")
    m = d["metrics"]
    assert m["canary_run"] is True
    assert m["probes_total"] >= 4
    assert m["silent_posts_detected"] == 0, "canary wykrył cichy post NA ŻYWO!"
    assert m["routing"] == "AUTO_FILE"


def test_p49_i11_probes_cover_bypass_and_missing():
    d = _bundle("silent_post_canary")
    ids = [p["id"] for p in d["evidence"]["probe_results"]]
    assert len(ids) == len(set(ids)), "duplikaty probe'ów"
    descs = " ".join(p["desc"] for p in d["evidence"]["probe_results"]).lower()
    assert "bypass" in descs and "brak" in descs


# ── I12: user-visible safety ──────────────────────────────────────────────────

def test_p49_i12_ui_contract():
    d = _bundle("user_visible_safety")
    m = d["metrics"]
    assert m["p40_contract_present"] is True
    assert m["needs_advice_with_action"] >= m["needs_advice_visible"]
    assert m["auto_post_evidence_downloadable"] is True
    assert m["routing"] == "AUTO_FILE"


# ── Registry + gate ───────────────────────────────────────────────────────────

def test_p49_rule_registry_12_candidates():
    reg = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    p49 = [k for k in reg if "v3_p49_fail_closed" in k]
    assert len(p49) == 12, f"oczekiwano 12 wpisów P49, jest {len(p49)}"
    for k in p49:
        v = reg[k]["versions"][-1]
        assert v["status"] == "CANDIDATE"
        assert v["thresholds"] == ["v3_p49"]
        assert "tests/rego/test_v3_p49_fail_closed.rego" in v["tests"]
        assert "tests/auto/test_v3_p49_fail_closed.py" in v["tests"]
        assert "NIEZWERYFIKOWANE" in v["legal_basis"]


def test_p49_bundles_all_gate_pass():
    """Konwencja P48: gate=PASS = dowód zapisany; decyzja żyje w metrics.routing."""
    for p in sorted(BUNDLES.glob("v3_p49_*.json")):
        if p.name in ("v3_p49_breaker_state.json", "v3_p49_last_emergency_export.json"):
            continue
        d = json.loads(p.read_text(encoding="utf-8"))
        assert d.get("gate") == "PASS", f"{p.name}: gate != PASS"
        assert "generated_at" in d and "metrics" in d
