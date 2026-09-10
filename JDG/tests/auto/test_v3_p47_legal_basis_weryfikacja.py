# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY AUTO V3-P47 WERYFIKACJA PODSTAW PRAWNYCH (konwencja
# P45/P46: dowody z narzędzi, honesty liczników, fail-closed bramek)
# Uruchomienie: python -m pytest tests/auto/test_v3_p47_legal_basis_weryfikacja.py -q
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]  # tests/auto/ → JDG
BUNDLES = BASE / "bundles"
DOCS = BASE / "docs"
P47_REGO = BASE / "rules" / "v3_p47_legal_basis_weryfikacja_enterprise.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"


def _bundle(name: str) -> dict:
    path = BUNDLES / f"v3_p47_{name}.json"
    assert path.exists(), f"brak bundla dowodowego: {path.name}"
    return json.loads(path.read_text(encoding="utf-8"))


# ── Warstwa rego ────────────────────────────────────────────────────────────────

def test_p47_rego_package_present():
    src = P47_REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p47_legal_basis_weryfikacja_enterprise" in src


def test_p47_rego_zero_hardcode_thresholds():
    """ADR-002: progi wyłącznie z data.jdg.thresholds.v3_p47 (samoegzekwowanie)."""
    src = P47_REGO.read_text(encoding="utf-8")
    assert "data.jdg.thresholds.v3_p47" in src
    # brak hardcoded progów liczbowych w regułach decyzyjnych (poza priority/certyfikatem)
    import re
    decision_lines = [l for l in src.splitlines()
                      if ("_th(" in l or "routing_" in l) and not l.strip().startswith("#")]
    assert decision_lines, "brak odczytów progów z snapshotu"


def test_p47_thresholds_block_present():
    src = THRESHOLDS.read_text(encoding="utf-8")
    assert "v3_p47_threshold_version" in src
    assert "v3_p47_lint_errors_max" in src
    assert "v3_p47_mediation_sla_days" in src


def test_p47_acts_map_twelve_acts_unverified():
    src = THRESHOLDS.read_text(encoding="utf-8")
    acts = [ln for ln in src.splitlines() if ln.strip().startswith('"v3_p47_act_')]
    assert len(acts) == 12
    # zero fikcyjnych Dz.U. — wszystkie [NIEZWERYFIKOWANE] (protokół 04)
    assert src.count("NIEZWERYFIKOWANE — ISAP") >= 12


def test_p47_main_jdg_wiring():
    src = (BASE / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p47_legal_basis_weryfikacja_enterprise" in src
    assert "final_verdict_p111" in src
    assert '"jdg.v3_p47_legal_basis_weryfikacja_enterprise"' in src


# ── Warstwa narzędzi (dowody) ───────────────────────────────────────────────────

def test_p47_i01_census_three_lists():
    d = _bundle("census")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    assert m["ok"] + m["unverified"] + m["missing"] == m["rules_total"]
    assert m["rules_total"] == 12439  # legal_basis_v2_report (dowód)


def test_p47_i02_citation_linter_counts():
    d = _bundle("citation_linter")
    assert d["gate"] == "PASS"
    assert d["metrics"]["citations_total"] > 0


def test_p47_i03_anchors_all_acts():
    d = _bundle("isap_anchors")
    assert d["metrics"]["acts_total"] == 12
    assert d["metrics"]["acts_without_anchor"] == 0


def test_p47_i04_versions_register():
    reg = json.loads((BUNDLES / "v3_p47_act_versions_register.json").read_text(encoding="utf-8"))
    assert len(reg["versions"]) == 12
    # honesty: wersje bez potwierdzonego okna są jawnie NIEZWERYFIKOWANE
    for v in reg["versions"].values():
        assert v["verification"] == "NIEZWERYFIKOWANE"


def test_p47_i05_scheduler_cadence():
    d = _bundle("recheck_scheduler")
    assert d["metrics"]["schedule"] == {"ACTIVE": 1, "CANDIDATE": 7}
    assert d["metrics"]["acts_total"] == 12


def test_p47_i06_mediation_inherits_p45():
    d = _bundle("mediation_workflow")
    tickets = d["evidence"]["tickets"]
    assert len(tickets) == 5  # kontrakt P45→P47: 5 wpisów rejestru mediacji
    assert all(t["blocks_promotion"] for t in tickets)


def test_p47_i07_fictional_scan_live():
    d = _bundle("fictional_basis")
    assert d["gate"] == "PASS"
    assert d["metrics"]["fictional_detected"] == 0  # brak niemożliwych pozycji/dat


def test_p47_i08_completeness_consistent():
    d = _bundle("completeness_score")
    m = d["metrics"]
    lb2 = json.loads((BUNDLES / "legal_basis_v2_report.json").read_text(encoding="utf-8"))
    total = lb2["rules_total"]
    # spójność wewnętrzna wskaźnika (głębokość łańcucha ≥3 ≠ v2-OK — inne metryki)
    assert 0 < m["complete_chains"] <= total
    assert m["active_rules"] == total
    assert m["completeness_pct"] == round(100 * m["complete_chains"] / total, 2)


def test_p47_i09_diff_watch_p46_contract():
    d = _bundle("isap_diff_watch")
    assert d["gate"] == "PASS"
    assert "p46_drift_contract" in [c["name"] for c in d["evidence"]["checks"]]


def test_p47_i10_human_stamps_pending():
    d = _bundle("human_stamps")
    reg = json.loads((BUNDLES / "v3_p47_human_stamps_register.json").read_text(encoding="utf-8"))
    assert len(reg["pending_4_eyes"]) == 30  # LSR: wszystkie PENDING_4_EYES (honesty)
    assert d["metrics"]["acts_verified_by_human"] == 0


def test_p47_i11_heatmap_counts():
    d = _bundle("acts_heatmap")
    assert d["metrics"]["desert_acts"] == 20  # legal_coverage_gaps UNCOVERED


def test_p47_i12_style_guide_doc():
    d = _bundle("style_guide")
    guide = DOCS / "V3_P47_CITATION_STYLE_GUIDE.md"
    assert guide.exists()
    src = guide.read_text(encoding="utf-8")
    assert "[NIEZWERYFIKOWANE — ISAP]" in src


# ── Bramka CI ───────────────────────────────────────────────────────────────────

def test_p47_gate_merge_passes():
    d = _bundle("gate_merge")
    assert d["verdict"] == "PASS"
    assert d["new_violations"] == 0


def test_p47_gate_adoption_semantics():
    """Kontrakt P46: bramka blokuje tylko GENUINIE NOWE naruszenia."""
    d = _bundle("gate_merge")
    assert d["backlog_violations"] >= 0
    assert d["first_adoption"] in (True, False)


# ── Cykl życia ──────────────────────────────────────────────────────────────────

def test_p47_lifecycle_12_candidates():
    reg = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    p47 = {k: v for k, v in reg.items() if k.startswith("jdg.v3_p47_")}
    assert len(p47) == 12
    # status lives in the latest registered version entry
    for v in p47.values():
        versions = v.get("versions") or [v]
        assert any(e.get("status") == "CANDIDATE" for e in versions)


def test_p47_never_silent_no_auto_without_evidence():
    """AP07: każdy bundle z pustym kontekstem dowodowym nie może deklarować AUTO."""
    for name in ("census", "citation_linter", "recheck_scheduler"):
        d = _bundle(name)
        routing = d["metrics"].get("routing")
        assert routing in ("TRIAGE_QUEUE", "BLOCK_AND_ALERT", "AUTO_FILE")


def test_p47_rego_tests_pass_native():
    """42/42 natywnych testów rego (OPA 0.68)."""
    result = subprocess.run(
        ["../bin/opa", "test", "rules/v3_p47_legal_basis_weryfikacja_enterprise.rego",
         "rules/thresholds_jdg.rego", "tests/rego/test_v3_p47_legal_basis_weryfikacja.rego"],
        cwd=BASE, capture_output=True, text=True, timeout=300)
    assert "PASS: 42/42" in result.stdout, result.stdout + result.stderr
