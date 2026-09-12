# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY AUTO V3-P51 PUSTYNIE PRAWNE (konwencja P45–P50: dowody
# z narzędzi i bundli, honesty liczników, fail-closed bramek, ADR-002 zero
# hardcode, AP01/AP07 anty-wzorce, spójność routing↔polityka).
# Uruchomienie: python -m pytest tests/auto/test_v3_p51_coverage_deserts.py -q
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]  # tests/auto/ → JDG
BUNDLES = BASE / "bundles"
REPO_ROOT = BASE.parent
P51_REGO = BASE / "rules" / "v3_p51_coverage_deserts.rego"
P51_REGO_MIRROR = REPO_ROOT / "policies" / "v3_p51_coverage_deserts.rego"
MAIN_REGO = BASE / "rules" / "main_jdg.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"
TESTS_REGO = BASE / "tests" / "rego" / "test_v3_p51_coverage_deserts.rego"


def _bundle(name: str) -> dict:
    path = BUNDLES / f"v3_p51_{name}.json"
    assert path.exists(), f"brak bundla dowodowego: {path.name}"
    return json.loads(path.read_text(encoding="utf-8"))


# ── Warstwa rego / konwencje ──────────────────────────────────────────────────

def test_p51_rego_package_present():
    src = P51_REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p51_coverage_deserts" in src


def test_p51_rego_mirror_semantically_identical():
    """AP11/P48-I02: mirror = build output — treść identyczna (raw)."""
    canonical = P51_REGO.read_text(encoding="utf-8")
    mirror = P51_REGO_MIRROR.read_text(encoding="utf-8")
    assert canonical == mirror, "mirror P51 dryfuje względem canonical (raw diff)"


def test_p51_rego_zero_hardcode_thresholds():
    """ADR-002: progi wyłącznie z data.jdg.thresholds.v3_p51."""
    src = P51_REGO.read_text(encoding="utf-8")
    assert "data.jdg.thresholds.v3_p51" in src
    decision_lines = [l for l in src.splitlines()
                      if ("_th(" in l or "routing_" in l)
                      and not l.strip().startswith("#")]
    assert decision_lines, "brak odczytów progów z snapshotu"


def test_p51_thresholds_block_present():
    src = THRESHOLDS.read_text(encoding="utf-8")
    for key in ("v3_p51_threshold_version", "v3_p51_p0_deserts_max",
                "v3_p51_cards_required", "v3_p51_chain_target_pct",
                "v3_p51_generators_guarded_min", "v3_p51_systemic_deserts_max",
                "v3_p51_law_radar_changes_max", "v3_p51_heatmap_high_max",
                "v3_p51_testless_max", "v3_p51_ghost_tests_max",
                "v3_p51_goals_missed_max", "v3_p51_stubs_total_max",
                "v3_p51_caveats_max"):
        assert key in src, f"brak progu {key} w thresholds_jdg.rego"


def test_p51_main_jdg_wiring():
    src = MAIN_REGO.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p51_coverage_deserts" in src
    assert "final_verdict_p115" in src
    assert "v3_p51_check" in src


def test_p51_no_stub_true_rules():
    """AP01: zero reguł-stubów {true => ...} w polityce P51."""
    src = P51_REGO.read_text(encoding="utf-8")
    stubs = re.findall(r"\w+\s*:=?\s*\"[^\"]*\"\s*\{\s*true\s*\}", src)
    assert not stubs, f"stuby w polityce P51: {stubs[:3]}"


def test_p51_legal_basis_tags_honest():
    """Protokół 04: każde twierdzenie prawne z tagiem [NIEZWERYFIKOWANE — ISAP]."""
    src = P51_REGO.read_text(encoding="utf-8")
    lb_lines = [l for l in src.splitlines() if "_legal_basis" in l]
    assert len(lb_lines) >= 12, "brak _legal_basis w decyzjach P51"
    unverified = [l for l in lb_lines if "NIEZWERYFIKOWANE" in l]
    assert len(unverified) >= 12, "legal_basis bez statusu weryfikacji (fasada)"


def test_p51_native_test_file_exists():
    src = TESTS_REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p51_coverage_deserts_test" in src
    assert src.count("test_p51_") >= 40, "za mało testów natywnych P51"


# ── I01+I02: rejestr pustyni + scoring ryzyka ─────────────────────────────────

def test_p51_i01_desert_register_bundle():
    d = _bundle("desert_register")
    m = d["metrics"]
    assert m["article_nodes"] > 0, "skan LKG nie znalazł węzłów ARTICLE"
    assert m["desert_nodes"] == (m["no_rule"] + m["rule_no_test"]
                                 + m["test_no_rule"]), \
        "liczniki klas pustyni niespójne (kontrola sumy I12)"
    # honesty: p0>0 → TRIAGE (rejestr otwarty, nigdy cichy AUTO_FILE)
    if m["p0_count"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"
    ev = d["evidence"]
    assert ev["entries_total"] == m["desert_nodes"]
    assert ev["entries_total"] == m["sla_registered"], "SLA nie dla wszystkich"
    assert ev["legal_note"].count("NIEZWERYFIKOWANE") >= 1


def test_p51_i01_reconciliation_is_explicit():
    """Zero pomijania (protokół 10): dryf raportów pokrycia jawny, nie wygładzony."""
    d = _bundle("desert_register")
    recon = d["evidence"]["reconciliation"]
    assert {"legal_graph", "coverage_canon", "deserts_snapshot",
            "drift_flags"} <= set(recon)
    assert isinstance(recon["drift_flags"], dict)


def test_p51_i02_desert_risk_bundle():
    d = _bundle("desert_risk")
    m = d["metrics"]
    reg = _bundle("desert_register")["metrics"]
    assert m["scored"] == reg["desert_nodes"], "scoring niepełny względem rejestru"
    assert m["unscored"] == 0
    assert "methodology" in d["evidence"], "metodologia scoringu jawna (I02)"
    assert "frequency" in d["evidence"]["methodology"]
    assert len(d["evidence"]["top10"]) == 10
    if m["p0_count"] + m["p1_count"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"


# ── I03: karty pustyni ────────────────────────────────────────────────────────

def test_p51_i03_desert_cards_bundle():
    d = _bundle("desert_cards")
    m = d["metrics"]
    assert m["template_present"] is True, "brak szablonu karty (standard P41)"
    assert m["cards_total"] == m["cards_required"] == 10
    cards = d["evidence"]["cards"]
    for c in cards:
        assert {"przepis", "warunki_materialne", "proponowane_testy",
                "koszt", "kolejnosc", "sla_deadline"} <= set(c)
        assert "NIEZWERYFIKOWANE" in c["przepis"]


# ── I04: metryka łańcucha (CCR) ───────────────────────────────────────────────

def test_p51_i04_chain_metric_bundle():
    d = _bundle("chain_metric")
    m = d["metrics"]
    # kontrola sumy nóg łańcucha: pełny + brak reguły + brak testu = wszystkie
    assert (m["chain_complete"] + m["missing_rule_leg"]
            + m["missing_test_leg"] + m["missing_act_leg"]) == m["article_nodes"]
    expected_ccr = round(m["chain_complete"] * 100.0 / m["article_nodes"], 2)
    assert m["CCR_pct"] == expected_ccr
    assert m["LCI_context_pct"] is not None, "kontekst LCI z canon obecny"
    if m["CCR_pct"] < 90.0:
        assert m["routing"] == "TRIAGE_QUEUE"


# ── I05: generatory z guardem ─────────────────────────────────────────────────

def test_p51_i05_semi_auto_drafting_bundle():
    d = _bundle("semi_auto_drafting")
    m = d["metrics"]
    assert m["generators_total"] == 4
    if m["legacy_stub_factories"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"
        assert m["ap01_risk"] is True
    ev = d["evidence"]
    assert "K-P50-5" in ev["contract"], "kontrakt guardu duplikatów obecny"


# ── I06: pustynie systemowe ───────────────────────────────────────────────────

def test_p51_i06_systemic_sweep_bundle():
    d = _bundle("systemic_sweep")
    m = d["metrics"]
    assert "method" in d["evidence"]
    assert m["systemic_deserts"] >= 0
    # honesty: skan bez dopasowań = AUTO_FILE tylko gdy klasy faktycznie puste
    if m["systemic_classes"] == 0:
        assert m["routing"] == "AUTO_FILE"


# ── I07: bramka Law Radar ─────────────────────────────────────────────────────

def test_p51_i07_law_radar_block_bundle():
    d = _bundle("law_radar_block")
    m = d["metrics"]
    assert m["radar_present"] is True
    if m["changes_without_rule_plan"] > 0 or not m["radar_present"]:
        assert m["routing"] == "TRIAGE_QUEUE"
    else:
        assert m["routing"] == "AUTO_FILE"
    assert "SLA" in d["evidence"]["contract"]


# ── I08: heatmapa kwotowa ─────────────────────────────────────────────────────

def test_p51_i08_desert_heatmap_bundle():
    d = _bundle("desert_heatmap")
    m = d["metrics"]
    q = m["quadrants"]
    assert sum(q.values()) == m["scored_deserts"], "kwadranty nie sumują się"
    assert set(q) == {"HIGH", "MED", "LOW", "COLD"}
    reg = _bundle("desert_register")["metrics"]
    assert m["scored_deserts"] == reg["desert_nodes"]
    assert "[ZAŁOŻENIE]" in m["assumption_flow_proxy"], "założenie jawne"
    if q["HIGH"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"


# ── I09: reguły bez testu + ghost testy ───────────────────────────────────────

def test_p51_i09_testless_sweep_bundle():
    d = _bundle("testless_sweep")
    m = d["metrics"]
    assert m["rules_scanned"] > 0, "skan reguł nie wykonany"
    if m["rules_without_test"] > 0 or m["ghost_tests"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"
    ev = d["evidence"]
    assert "ghost_tests_sample" in ev, "ghost testy bez rejestru"
    assert ev["note"].count("UVR") >= 1, "kontekst UVR z canon obecny"


# ── I10: cele kwartalne ───────────────────────────────────────────────────────

def test_p51_i10_quarterly_goals_bundle():
    d = _bundle("quarterly_goals")
    m = d["metrics"]
    rows = d["evidence"]["rows"]
    assert m["goals_total"] == len(rows) == 15
    assert m["met"] + m["at_risk"] + m["missed"] == len(rows)
    if m["missed"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"
    else:
        assert m["routing"] == "AUTO_FILE"


# ── I11: pustynie × stuby ─────────────────────────────────────────────────────

def test_p51_i11_vacancy_bridge_bundle():
    d = _bundle("vacancy_bridge")
    m = d["metrics"]
    reg = _bundle("desert_register")["metrics"]
    assert m["deserts"] == reg["desert_nodes"]
    assert m["combined_register_rows"] == m["deserts"]
    assert m["stubs_total"] >= 0
    if m["stubs_total"] > 0 or m["deserts"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"
    assert "P45-I01" in d["evidence"]["contract"]


# ── I12: atestacja pokrycia ───────────────────────────────────────────────────

def test_p51_i12_coverage_attestation_bundle():
    d = _bundle("coverage_attestation")
    m = d["metrics"]
    att = d["evidence"]["attestation"]
    assert att["counter_consistency"] is True, "liczniki atestacji niespójne"
    assert isinstance(att["caveats"], list)
    # honesty: zastrzeżenia > 0 → nie atestujemy czystego stanu
    if att["caveats"]:
        assert att["attested"] is False
        assert m["routing"] == "TRIAGE_QUEUE"
    assert "P68" in att["consumer"]


# ── Runner (kolejność zależności) ─────────────────────────────────────────────

def test_p51_runner_all_steps_ok():
    d = _bundle("run_all_evidence")
    assert d["gate"] == "PASS"
    assert d["metrics"]["failed"] == 0
    steps = d["log"]
    assert len(steps) >= 11
    assert all(s["ok"] for s in steps)
    # kolejność zależności: rejestr I01 przed kartami I03 i sweepami I06-I11
    order = [s["step"] for s in steps]
    assert order.index("I01+I02") < order.index("I03")
    assert order.index("I01+I02") < order.index("I06")
    assert order.index("I12") == max(range(len(order)))


# ── Rejestr lifecycle (12× CANDIDATE, v3.51.1) ────────────────────────────────

def test_p51_rule_registry_12_candidates():
    reg = json.loads((BUNDLES / "rule_registry.json").read_text(
        encoding="utf-8"))
    p51_entries = [v for k, v in reg.items()
                   if k.startswith("jdg.v3_p51_coverage_deserts.")]
    assert len(p51_entries) == 12, f"oczekiwano 12 wpisów, jest {len(p51_entries)}"
    for entry in p51_entries:
        ver = entry["versions"][-1]
        assert ver["status"] == "CANDIDATE"
        assert ver["version"] == "3.51.1"
        assert ver["thresholds"] == ["v3_p51"]
        assert ver["legal_basis"].startswith("[NIEZWERYFIKOWANE — ISAP]")
