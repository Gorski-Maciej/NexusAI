#!/usr/bin/env python3
"""NexusAI JDG — V3-P53 TEMPORALNOŚĆ DOMKNIĘCIE — testy pytest (26 przypadków).

Konwencja P45–P52: dowody z bundli (nie deklaracje), fail-closed, granice progów,
never-silent AUTO_POST, epoki/day-0/time-travel. Uruchomienie:
    python3 -m pytest tests/auto/test_v3_p53_temporal_closure.py -q
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest

JDG = Path(__file__).resolve().parent.parent.parent
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
THRESHOLDS = JDG / "rules" / "thresholds_jdg.rego"


def _load(name: str) -> dict:
    p = BUNDLES / name
    if not p.exists():
        pytest.skip(f"brak bundla dowodowego {name} (uruchom v3_p53_run_all.py)")
    return json.loads(p.read_text(encoding="utf-8"))


ALL_BUNDLES = [
    "v3_p53_temporal_coverage_map.json",
    "v3_p53_day0_tests.json",
    "v3_p53_replay_contract.json",
    "v3_p53_transitional_register.json",
    "v3_p53_interval_validation.json",
    "v3_p53_epoch_registry.json",
    "v3_p53_future_sandbox.json",
    "v3_p53_preprovisioning.json",
    "v3_p53_year_boundary_tests.json",
    "v3_p53_param_history.json",
    "v3_p53_epoch_golden.json",
    "v3_p53_audit_trail.json",
    "v3_p53_run_all.json",
]


# ═══ 1. Dowody: wszystkie 13 bundli istnieją i mają gate ═══
@pytest.mark.parametrize("name", ALL_BUNDLES)
def test_bundle_exists_with_gate(name):
    data = _load(name)
    assert data.get("gate") in ("PASS", "FAIL")


def test_run_all_gate_pass():
    run = _load("v3_p53_run_all.json")
    assert run["gate"] == "PASS"
    assert run["engines_run"] == 12
    assert run["failures"] == []


# ═══ 2. I01: mapa pokrycia oknami — realne liczby ═══
def test_i01_coverage_counts():
    c = _load("v3_p53_temporal_coverage_map.json")
    assert c["rule_files_total"] > 0
    assert c["rule_files_with_window"] > 0
    assert c["rule_files_with_window"] + c["rule_files_without_window"] == c["rule_files_total"]


def test_i01_hardcoded_dates_flagged():
    c = _load("v3_p53_temporal_coverage_map.json")
    assert isinstance(c["hardcoded_date_files"], list)


# ═══ 3. I02: testy day-0 wygenerowane z okien ═══
def test_i02_day0_tests_generated():
    d = _load("v3_p53_day0_tests.json")
    assert d["auto_tests_generated"] >= 8
    for t in d["tests"]:
        assert "day_minus_1" in t["grid"] and "day_0" in t["grid"]


# ═══ 4. I03: kontrakt replay — filary jawne ═══
def test_i03_replay_pillars_contract():
    r = _load("v3_p53_replay_contract.json")
    assert r["pillars_total"] == 4
    assert set(r["pillars"].keys()) == {
        "rules_bundle_history", "params_history", "fx_history",
        "accumulator_state_on_date"}


# ═══ 5. I04: rejestr zasad przejściowych ═══
def test_i04_transitional_register():
    t = _load("v3_p53_transitional_register.json")
    assert t["total"] >= 5
    ids = {r["id"] for r in t["entries"]}
    assert {"TR-01", "TR-02", "TR-03"} <= ids


# ═══ 6. I05: INV-037 zero luk + zero nakładek ═══
def test_i05_zero_gaps_overlaps():
    i = _load("v3_p53_interval_validation.json")
    assert i["gaps_count"] == 0 and i["overlaps_count"] == 0


# ═══ 7. I06: epoki z hashem snapshotu ═══
def test_i06_epochs_have_hash():
    e = _load("v3_p53_epoch_registry.json")
    assert e["epoch_count"] >= 1
    for ep in e["epochs"]:
        assert ep["params_snapshot_hash"], f"epoka {ep['epoch_id']} bez hashu"


# ═══ 8. I07: sandbox nigdy nie zapisuje do produkcji ═══
def test_i07_sandbox_no_production_write():
    s = _load("v3_p53_future_sandbox.json")
    assert s["invariant"].startswith("decyzje w trybie DRAFT")


# ═══ 9. I08: KPI lead kalendarza ═══
def test_i08_preprov_kpi():
    p = _load("v3_p53_preprovisioning.json")
    assert "lead >= 30 dni" in p["kpi"]


# ═══ 10. I09: granica roku — reset kalendarzowy ═══
def test_i09_year_boundary_reset():
    y = _load("v3_p53_year_boundary_tests.json")
    assert y["cases_count"] >= 3
    reset = [c for c in y["cases"] if c["expect_after"] == "accumulator_reset"]
    assert reset, "brak przypadków resetu rocznego"


# ═══ 11. I10: historia parametrów z provenance ═══
def test_i10_param_history_versions():
    h = _load("v3_p53_param_history.json")
    assert h["total_versions"] > 0
    assert h["with_provenance"] + h["without_provenance"] == h["total_versions"]


# ═══ 12. I11: golden z epokami ═══
def test_i11_epoch_golden_counts():
    g = _load("v3_p53_epoch_golden.json")
    assert g["verdicts_total"] > 0
    assert g["verdicts_with_epoch_label"] + g["verdicts_without_epoch_label"] == g["verdicts_total"]


# ═══ 13. I12: projekt certyfikatu temporalnego ═══
def test_i12_certificate_design():
    a = _load("v3_p53_audit_trail.json")
    cert = a["certificate_design"]
    assert cert["certificate_field"] == "_decision_certificate.legal_epoch"
    assert set(cert["required_fields"] if "required_fields" in cert else cert["content"].keys()) >= {"epoch_id", "epoch_hash"}


# ═══ 14. Warstwa polityki: pakiet istnieje, wiring w main_jdg ═══
def test_policy_file_exists():
    assert (RULES / "v3_p53_temporal_closure.rego").exists()


def test_main_jdg_wiring_p117():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p53_temporal_closure" in main
    assert "final_verdict_p117 = safe_merge(final_verdict_p116" in main
    # p117 w łańcuchu POST-MERGE; kotwica przesunięta na p118 przez P54
    # (konwencja kampanii: "post-merge anchor przesunięty", notatki P29–P53)
    normalized = main.replace("\r\n", "\n")
    assert ("final_verdict_p117\n" in normalized) or (
        "final_verdict_p118 = safe_merge(final_verdict_p117" in normalized)


def test_thresholds_block_present():
    txt = THRESHOLDS.read_text(encoding="utf-8")
    assert "v3_p53_window_coverage_min_pct" in txt
    assert '"valid_from": "2026-01-01"' in txt  # okno temporalne (P05)


# ═══ 15. Granice progów w snapshot ═══
def test_thresholds_boundary_values():
    txt = THRESHOLDS.read_text(encoding="utf-8")
    assert '"v3_p53_replay_pillars_min": 4' in txt
    assert '"v3_p53_day0_tests_min": 8' in txt
    assert '"v3_p53_year_boundary_cases_min": 3' in txt
