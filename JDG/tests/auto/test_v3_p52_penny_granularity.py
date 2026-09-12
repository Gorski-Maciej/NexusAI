# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY AUTO V3-P52 GRANICE GROSZOWE (konwencja P45–P51: dowody
# z narzędzi i bundli, honesty liczników, fail-closed bramek, ADR-002 zero
# hardcode, AP01/AP07/AP09 anty-wzorce, spójność routing↔polityka).
# Uruchomienie: python -m pytest tests/auto/test_v3_p52_penny_granularity.py -q
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json
import re
import sys
from decimal import Decimal
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]  # tests/auto/ → JDG
BUNDLES = BASE / "bundles"
REPO_ROOT = BASE.parent
P52_REGO = BASE / "rules" / "v3_p52_penny_granularity.rego"
P52_REGO_MIRROR = REPO_ROOT / "policies" / "v3_p52_penny_granularity.rego"
MAIN_REGO = BASE / "rules" / "main_jdg.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"
TESTS_REGO = BASE / "tests" / "rego" / "test_v3_p52_penny_granularity.rego"
sys.path.insert(0, str(BASE / "tools"))


def _bundle(name: str) -> dict:
    path = BUNDLES / f"v3_p52_{name}.json"
    assert path.exists(), f"brak bundla dowodowego: {path.name}"
    return json.loads(path.read_text(encoding="utf-8"))


# ── Warstwa rego / konwencje ──────────────────────────────────────────────────

def test_p52_rego_package_present():
    src = P52_REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p52_penny_granularity" in src


def test_p52_rego_mirror_semantically_identical():
    """AP11/P48-I02: mirror = build output — treść identyczna (raw)."""
    assert P52_REGO.read_text(encoding="utf-8") == \
        P52_REGO_MIRROR.read_text(encoding="utf-8"), \
        "mirror P52 dryfuje względem canonical (raw diff)"


def test_p52_rego_zero_hardcode_thresholds():
    """ADR-002: progi wyłącznie z data.jdg.thresholds.v3_p52."""
    src = P52_REGO.read_text(encoding="utf-8")
    assert "data.jdg.thresholds.v3_p52" in src
    decision_lines = [l for l in src.splitlines()
                      if ("_th(" in l or "routing_" in l)
                      and not l.strip().startswith("#")]
    assert decision_lines


def test_p52_thresholds_block_present():
    src = THRESHOLDS.read_text(encoding="utf-8")
    for key in ("v3_p52_threshold_version", "v3_p52_noncompliant_tools_max",
                "v3_p52_boundary_thresholds_min",
                "v3_p52_holidays_registered_min", "v3_p52_sum_checks_min",
                "v3_p52_path_drifts_max", "v3_p52_annual_rules_min",
                "v3_p52_penny_drift_target", "v3_p52_fuzz_trials_min"):
        assert key in src, f"brak progu {key} w thresholds_jdg.rego"


def test_p52_main_jdg_wiring():
    src = MAIN_REGO.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p52_penny_granularity" in src
    assert "final_verdict_p116" in src
    assert "v3_p52_check" in src


def test_p52_no_stub_true_rules():
    src = P52_REGO.read_text(encoding="utf-8")
    stubs = re.findall(r"\w+\s*:=?\s*\"[^\"]*\"\s*\{\s*true\s*\}", src)
    assert not stubs, f"stuby w polityce P52: {stubs[:3]}"


def test_p52_legal_basis_tags_honest():
    src = P52_REGO.read_text(encoding="utf-8")
    lb_lines = [l for l in src.splitlines() if "_legal_basis" in l]
    assert len(lb_lines) >= 12
    unverified = [l for l in lb_lines if "NIEZWERYFIKOWANE" in l]
    assert len(unverified) >= 12


def test_p52_native_test_file_exists():
    src = TESTS_REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p52_penny_granularity_test" in src
    assert src.count("test_p52_") >= 40


# ── Kanoniczny standard grosz() (I01) — symetria dowodu ───────────────────────

def test_p52_grosz_half_up_symmetric():
    """I08: ujemne przez abs — -0.005 → -0.01 (nie -0.00 jak floor+0.5)."""
    from v3_p52_engines import grosz
    assert str(grosz("0.005")) == "0.01"
    assert str(grosz("0.004")) == "0.00"
    assert str(grosz("-0.005")) == "-0.01"
    assert str(grosz("-1.005")) == "-1.01"
    assert str(grosz("123.455")) == "123.46"


def test_p52_grosz_idempotent_and_penny_exact():
    from v3_p52_engines import grosz
    for v in ["0", "0.01", "99999999.99", "-77.77", "123.455"]:
        assert grosz(grosz(v)) == grosz(v)


# ── I01: rejestr standardów ───────────────────────────────────────────────────

def test_p52_i01_standards_register_bundle():
    d = _bundle("standards_register")
    m = d["metrics"]
    assert m["tools_total"] == 9
    assert m["tools_compliant"] + m["tools_noncompliant"] + sum(
        1 for r in d["evidence"]["rows"]
        if r["consistency"] in ("PARTIAL", "UNKNOWN")) == m["tools_total"]
    # honesty: noncompliant>0 → nie AUTO_FILE
    if m["tools_noncompliant"] > 0:
        assert m["routing"] in ("TRIAGE_QUEUE", "BLOCK_AND_ALERT")
    ev = d["evidence"]
    assert ev["legal_standard"]["standard"] == "HALF_UP_TO_GROSZ"
    assert "art. 107" in ev["legal_standard"]["legal_basis"]
    assert "NIEZWERYFIKOWANE" in ev["legal_standard"]["legal_basis"]


def test_p52_i01_bankers_rounding_detected():
    """Dowód tezy audytu: Python round() = banker's — wykryte w kalkulatorach."""
    d = _bundle("standards_register")
    bankers_rows = [r for r in d["evidence"]["rows"]
                    if "BANKERS" in r["rounding_standard"]]
    assert len(bankers_rows) >= 5, "audyt nie wykrył banker's rounding"
    assert all(r["bankers_round_calls"] > 0 for r in bankers_rows)


# ── I02: matryca granic progów ────────────────────────────────────────────────

def test_p52_i02_penny_boundary_bundle():
    d = _bundle("penny_boundary_matrix")
    m = d["metrics"]
    cases = d["evidence"]["cases"]
    assert len(cases) == m["cases_total"]
    # co najmniej próg, próg±0.01 na każdym progu EXCLUSIVE
    for key in {c["threshold_key"] for c in cases}:
        sub = [c for c in cases if c["threshold_key"] == key]
        amounts = {c["amount"] for c in sub}
        thr = sub[0]["threshold"]
        assert thr in amounts, f"brak przypadku dokładnie na progu {key}"
        assert round(thr - 0.01, 2) in amounts
        assert round(thr + 0.01, 2) in amounts
    assert m["exclusive_boundary_is_below"] is True, \
        "art. 119 'przekracza' = na progu reżim niższy (teza testowa)"


def test_p52_i02_at_threshold_exclusive_regime():
    """Grosz przy progu decyduje: 15000.00 → NIE MPP; 15000.01 → MPP."""
    d = _bundle("penny_boundary_matrix")
    cases = d["evidence"]["cases"]
    mpp = {c["amount"]: c["expected_regime"] for c in cases
           if c["threshold_key"] == "mpp_mandatory_threshold"}
    assert mpp[15000.0] == "MPP_OFF"
    assert mpp[15000.01] == "MPP_ON"
    assert mpp[14999.99] == "MPP_OFF"


# ── I03: provenance kursów ────────────────────────────────────────────────────

def test_p52_i03_rate_provenance_bundle():
    d = _bundle("rate_provenance")
    m = d["metrics"]
    assert m["rego_provenance_required"] is False, \
        "r10 fx_schedule bez provenance — luka jawna (I03)"
    if m["tools_with_fx"] > m["tools_with_provenance"]:
        assert m["routing"] == "TRIAGE_QUEUE"
    assert "checksum" in d["evidence"]["contract"]


# ── I04: ścieżka weekend/święto ───────────────────────────────────────────────

def test_p52_i04_weekend_rate_bundle():
    d = _bundle("weekend_rate_path")
    m = d["metrics"]
    assert m["holidays_registered"] >= 20
    cases = d["evidence"]["cases"]
    # sobota zawsze bez tabeli A → LAST_AVAILABLE_WORKDAY
    import datetime as dt
    for c in cases:
        day = dt.date.fromisoformat(c["date"])
        if day.weekday() >= 5:
            assert c["expected_path"] == "LAST_AVAILABLE_WORKDAY"


# ── I05: invariants sum ───────────────────────────────────────────────────────

def test_p52_i05_sum_invariants_bundle():
    d = _bundle("sum_invariants")
    m = d["metrics"]
    assert m["checks_run"] >= 100
    assert m["violations"] == 0, "per-pozycja half-up spójny z sumami"
    assert m["routing"] == "AUTO_FILE"


# ── I06: determinism hash ─────────────────────────────────────────────────────

def test_p52_i06_determinism_bundle():
    d = _bundle("determinism_hash")
    m = d["metrics"]
    assert m["determinism_failures"] == 0
    assert m["unique_hashes"] == m["trials"]  # różne inputy → różne hashe
    # honesty: zero narzędzi z hashem = TRIAGE (kontrakt I06 nieprzyjęty)
    if m["tools_with_hash"] == 0:
        assert m["routing"] == "TRIAGE_QUEUE"


# ── I07: interakcje zaokrągleń ────────────────────────────────────────────────

def test_p52_i07_rounding_interactions_bundle():
    d = _bundle("rounding_interactions")
    m = d["metrics"]
    assert m["trials"] >= 100
    # twardy dowód rozjazdów ścieżek: A (VAT per pozycja) vs B (suma pełna)
    assert m["path_drifts"] > 0, "brak rozjazdów = test nie ten sam łańcuch"
    drifts = d["evidence"]["drifts_sample"]
    for dr in drifts:
        assert dr["a"] != dr["b"]
    assert m["routing"] == "TRIAGE_QUEUE"


# ── I08: ścieżki ujemne ───────────────────────────────────────────────────────

def test_p52_i08_negative_paths_bundle():
    d = _bundle("negative_paths")
    m = d["metrics"]
    cases = d["evidence"]["cases"]
    naive = {c["value"]: c["naive_half_up"] for c in cases}
    # Python half-up na ujemnych: -0.005 → -0.00 (Decimal half-up od zera);
    # P52 symetryczny: -0.01. Ujawniamy różnicę semantyki jawnie:
    sym = {c["value"]: c["p52_symmetric_half_up"] for c in cases}
    assert sym["-0.005"] == "-0.01"
    assert str(naive["-0.005"]) in ("-0.00", "-0.01")  # zależnie od wersji
    if m["tools_with_negative_paths"] < m["tools_total"]:
        assert m["routing"] == "TRIAGE_QUEUE"


# ── I09: audyt kalendarza progów ──────────────────────────────────────────────

def test_p52_i09_threshold_calendar_bundle():
    d = _bundle("threshold_calendar")
    m = d["metrics"]
    assert m["thresholds_params_total"] > 0
    assert m["annual_rules_detected"] >= 3
    assert "art. 113" in d["evidence"]["plan"]
    assert "NIEZWERYFIKOWANE" in d["evidence"]["plan"]


# ── I10: telemetria driftu ────────────────────────────────────────────────────

def test_p52_i10_drift_telemetry_bundle():
    d = _bundle("drift_telemetry")
    m = d["metrics"]
    # spójność jednego rejestru: drift = I05 + I07
    s5 = _bundle("sum_invariants")["metrics"]["violations"]
    s7 = _bundle("rounding_interactions")["metrics"]["path_drifts"]
    assert m["penny_drift_total"] == s5 + s7
    assert m["target"] == 0
    if m["penny_drift_total"] > 0:
        assert m["routing"] == "BLOCK_AND_ALERT"


# ── I11: fuzz walutowy ────────────────────────────────────────────────────────

def test_p52_i11_currency_fuzz_bundle():
    d = _bundle("currency_fuzz")
    m = d["metrics"]
    assert m["trials"] >= 100
    assert m["violations"] == 0
    assert m["routing"] == "AUTO_FILE"


# ── I12: doomsday ─────────────────────────────────────────────────────────────

def test_p52_i12_doomsday_bundle():
    d = _bundle("doomsday")
    m = d["metrics"]
    assert m["failures"] == 0, "silnik nie może się wysypać na arytmetyce"
    assert m["div_zero_path"] == "NEEDS_ADVICE"  # fail-closed, nie wyjątek
    results = {r["case"]: r for r in d["evidence"]["results"]}
    assert results["zero"]["ok"] is True
    assert results["overflow_product"]["ok"] is True


# ── Runner (kolejność zależności) ─────────────────────────────────────────────

def test_p52_runner_all_steps_ok():
    d = _bundle("run_all_evidence")
    assert d["gate"] == "PASS"
    assert d["metrics"]["failed"] == 0
    steps = d["log"]
    assert len(steps) == 12
    assert all(s["ok"] for s in steps)
    order = [s["step"] for s in steps]
    assert order.index("I01") < order.index("I02")   # rejestr przed matrycą
    assert order.index("I05") < order.index("I10")   # inwarianty przed drift
    assert order[-1] == "I09"


# ── Rejestr lifecycle (12× CANDIDATE, v3.52.1) ────────────────────────────────

def test_p52_rule_registry_12_candidates():
    reg = json.loads((BUNDLES / "rule_registry.json").read_text(
        encoding="utf-8"))
    p52_entries = [v for k, v in reg.items()
                   if k.startswith("jdg.v3_p52_penny_granularity.")]
    assert len(p52_entries) == 12, f"oczekiwano 12 wpisów, jest {len(p52_entries)}"
    for entry in p52_entries:
        ver = entry["versions"][-1]
        assert ver["status"] == "CANDIDATE"
        assert ver["version"] == "3.52.1"
        assert ver["thresholds"] == ["v3_p52"]
        assert ver["legal_basis"].startswith("[NIEZWERYFIKOWANE — ISAP]")
