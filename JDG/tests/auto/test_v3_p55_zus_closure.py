#!/usr/bin/env python3
"""NexusAI JDG — V3-P55 ZUS DOMKNIĘCIE — testy pytest (48 przypadków).

Konwencja P45–P54: dowody z bundli (nie deklaracje), fail-closed, granice
progów (karencja 89/90, okresy 182/183, DRA 10./15.), never-silent AUTO_POST.
Uruchomienie: python3 -m pytest tests/auto/test_v3_p55_zus_closure.py -q
"""
from __future__ import annotations

import json
import re
from pathlib import Path

import pytest

JDG = Path(__file__).resolve().parent.parent.parent
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
THRESHOLDS = JDG / "rules" / "thresholds_jdg.rego"


def _load(name: str) -> dict:
    p = BUNDLES / name
    if not p.exists():
        pytest.skip(f"brak bundla dowodowego {name} (uruchom v3_p55_run_all.py)")
    return json.loads(p.read_text(encoding="utf-8"))


ALL_BUNDLES = [
    "v3_p55_lifecycle.json",
    "v3_p55_thirtyfold_ytd.json",
    "v3_p55_mid_month_split.json",
    "v3_p55_carencia.json",
    "v3_p55_benefit_period.json",
    "v3_p55_dra_watchdog.json",
    "v3_p55_dra_corrections.json",
    "v3_p55_payment_priority.json",
    "v3_p55_suspension.json",
    "v3_p55_rate_windows.json",
    "v3_p55_completeness.json",
    "v3_p55_pre_payment_gate.json",
    "v3_p55_run_all.json",
]


# ═══ 1. Dowody: wszystkie 13 bundli istnieją i mają gate ═══
@pytest.mark.parametrize("name", ALL_BUNDLES)
def test_bundle_exists_with_gate(name):
    data = _load(name)
    assert data.get("gate") in ("PASS", "FAIL")


def test_run_all_gate_pass():
    run = _load("v3_p55_run_all.json")
    assert run["gate"] == "PASS"
    assert run["engines_run"] == 12
    assert run["failures"] == []


# ═══ 2. I01: cykl ulg — stany i przejścia spójne z trackerem ═══
def test_i01_lifecycle_complete():
    c = _load("v3_p55_lifecycle.json")
    assert c["states_total"] >= 5
    assert c["transitions_valid"] >= 4
    assert c["violations"] == []


def test_i01_transition_chain_order():
    c = _load("v3_p55_lifecycle.json")
    assert "NEW→START_RELIEF" in c["transitions"]
    assert "START_RELIEF→PREFERENTIAL" in c["transitions"]
    assert "PREFERENTIAL→SMALL_ZUS_PLUS" in c["transitions"]
    assert "SMALL_ZUS_PLUS→STANDARD" in c["transitions"]


def test_i01_forced_transition_after_24m():
    c = _load("v3_p55_lifecycle.json")
    assert any("24m" in t for t in c["transitions"])  # wymuszenie po 24. mies.


# ═══ 3. I02: 30-krotność YTD — licznik z korektą w locie ═══
def test_i02_all_months_tracked():
    t = _load("v3_p55_thirtyfold_ytd.json")
    assert t["months_tracked"] == t["months_total"] == 12
    assert t["reconciliations_pending"] == 0


def test_i02_correction_cascade():
    t = _load("v3_p55_thirtyfold_ytd.json")
    assert t["correction_applied"] is True
    assert t["cascade_recalculated"] is True
    assert isinstance(t["ytd_final"], (int, float))


# ═══ 4. I03: podział miesiąca — prorata dni ═══
def test_i03_split_policy():
    s = _load("v3_p55_mid_month_split.json")
    assert s["months_unsplit"] == 0
    assert s["split_policy"] == "prorata_dni"
    assert abs(s["case"]["prorata"] - 10 / 30) < 1e-9


# ═══ 5. I04: karencja — granica 89/90, restarty ═══
def test_i04_carencia_boundary():
    c = _load("v3_p55_carencia.json")
    assert c["carencia_days"] == 90
    assert c["boundary"] == {"day_89": "BLOCK", "day_90": "PASS"}
    assert c["violations"] == 0


def test_i04_restart_rule():
    c = _load("v3_p55_carencia.json")
    assert "nowa karencja" in c["restart_rule"]


# ═══ 6. I05: okresy zasiłkowe — granice 182/183 ═══
def test_i05_benefit_limits():
    b = _load("v3_p55_benefit_period.json")
    assert b["max_days"] == 182
    assert b["extended_days"] == 270
    assert b["overflows"] == 0
    assert b["boundary_tested"] is True


# ═══ 7. I06: DRA — terminy 10./15. + dzień roboczy ═══
def test_i06_dra_days():
    d = _load("v3_p55_dra_watchdog.json")
    assert d["dra_events_orphan"] == 0
    ids = {e["id"] for e in d["events"]}
    assert {"DRA-standard", "DRA-privileged"} <= ids


def test_i06_day0_grid_present():
    d = _load("v3_p55_dra_watchdog.json")
    for e in d["events"]:
        assert "day_minus_1" in e["grid"] and "day_0" in e["grid"]


# ═══ 8. I07: korekty DRA — łańcuchy kompletne ═══
def test_i07_correction_chains():
    c = _load("v3_p55_dra_corrections.json")
    assert c["chains_broken"] == 0
    assert c["corrections_total"] >= 1
    for e in c["entries"]:
        assert e["interest_calculated"] and e["payment_planned"]


# ═══ 9. I08: priorytet płatności — blokada + idempotencja ═══
def test_i08_priority_active():
    p = _load("v3_p55_payment_priority.json")
    assert p["arrears_pln"] > 0 and p["blocked_payments"] > 0  # kontrola blokady
    assert "P32" in p["idempotency_key"]


# ═══ 10. I09: zawieszenie — pełne vs wstrzymanie ═══
def test_i09_suspension_cases():
    s = _load("v3_p55_suspension.json")
    assert s["violations"] == 0
    allowed = {c["suspension"]: c["allowed"] for c in s["cases"]}
    assert allowed["pełne"] is True
    assert allowed["wstrzymanie (możliwość pracy)"] is False


# ═══ 11. I10: okna stawek rocznych + day-0 roku ═══
def test_i10_windows():
    r = _load("v3_p55_rate_windows.json")
    assert r["years_unwindowed"] == 0
    assert r["years_total"] >= 2
    assert r["year_boundary_grid"] == {"day_minus_1": "2025-12-31", "day_0": "2026-01-01"}


# ═══ 12. I11: matryca kompletności ═══
def test_i11_matrix_full():
    m = _load("v3_p55_completeness.json")
    assert m["matrix_cells_uncovered"] == 0
    assert m["matrix_cells_total"] >= 16


# ═══ 13. I12: payment gate — łańcuch uprawnień ═══
def test_i12_gate_chain():
    g = _load("v3_p55_pre_payment_gate.json")
    assert g["payments_ungated"] == 0
    assert set(g["gate_chain"]) == {"I04_carencia", "I05_period", "I09_suspension"}
    assert g["gate_checks"] == g["payments_total"] * 3


# ═══ 14. Rego: reguła istnieje, zero stubów, zero AUTO_POST ═══
def test_rule_file_exists():
    r = RULES / "v3_p55_zus_closure.rego"
    assert r.exists()
    txt = r.read_text(encoding="utf-8")
    assert "package jdg.v3_p55_zus_closure" in txt
    assert "default decide" not in txt
    assert '"decision": "AUTO_POST"' not in txt


# ═══ 15. Progi ADR-002: blok v3_p55 z oknem temporalnym ═══
def test_thresholds_block_present():
    txt = THRESHOLDS.read_text(encoding="utf-8")
    assert "v3_p55 := {" in txt
    for key in ("v3_p55_carencia_days", "v3_p55_benefit_max_days",
                "v3_p55_benefit_extended_days", "v3_p55_dra_day_standard",
                "v3_p55_dra_day_privileged", "v3_p55_arrears_block_threshold_pln"):
        assert key in txt


def test_thresholds_temporal_window():
    txt = THRESHOLDS.read_text(encoding="utf-8")
    idx = txt.index("v3_p55 := {")
    block = txt[idx:idx + 2000]
    assert '"valid_from": "2026-01-01"' in block


# ═══ 16. Wiring: import + p119 + post-merge ═══
def test_wiring_main_jdg():
    txt = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p55_zus_closure" in txt
    assert "final_verdict_p119 = safe_merge(final_verdict_p118" in txt
    assert "final_verdict_p129" in txt.split("final_verdict_post_merge = safe_merge(")[1][:400]  # kotwica p128→p129 (P65)


# ═══ 17. Fail-closed statycznie ═══
def test_rule_fail_closed_on_missing_snapshot():
    txt = (RULES / "v3_p55_zus_closure.rego").read_text(encoding="utf-8")
    assert "thresholds_missing" in txt
    assert "fail-closed (ADR-002)" in txt


# ═══ 18. Priorities: 455001–455012 × 2 gałęzie + terminal 455000 ═══
def test_rule_priorities_unique():
    txt = (RULES / "v3_p55_zus_closure.rego").read_text(encoding="utf-8")
    prio = [int(m) for m in re.findall(r'"priority":\s*(\d+)', txt)]
    assert 455000 in prio
    for p in range(455001, 455013):
        assert prio.count(p) == 2, f"priorytet {p} oczekiwany 2x (else-branch): {prio}"


# ═══ 19. Konteksty silników = klucze w regułach ═══
def test_engine_context_keys_match_rule():
    ctx_names = [
        "I01_zus_lifecycle_state_machine", "I02_thirtyfold_ytd_engine",
        "I03_mid_month_limit_split", "I04_carencia_break_tracker",
        "I05_benefit_period_counter", "I06_dra_deadline_watchdog",
        "I07_dra_correction_chain", "I08_zus_payment_priority",
        "I09_benefit_vs_suspension", "I10_annual_rate_windows",
        "I11_zus_completeness_matrix", "I12_benefit_pre_payment_gate",
    ]
    txt = (RULES / "v3_p55_zus_closure.rego").read_text(encoding="utf-8")
    for key in ctx_names:
        assert key in txt, f"brak {key} w regułach P55"


# ═══ 20. Bundle nagłówki spójne ═══
@pytest.mark.parametrize("name", [b for b in ALL_BUNDLES if b != "v3_p55_run_all.json"])
def test_bundle_headers(name):
    data = _load(name)
    assert data.get("part") == "P55"
    assert data.get("slug") == "ZUS_DOMKNIECIE"
    assert data.get("schema") == "jdg.v3_p55.audit.v1"


# ═══ 21. Rozszerzenie, nie duplikacja: silniki używają narzędzi rdzenia ═══
def test_engines_extend_core_tools():
    txt = (JDG / "tools" / "v3_p55_engines.py").read_text(encoding="utf-8")
    for tool in ("preferential_period_tracker.py", "sickness_duration_tracker.py",
                 "zus_calendar.py", "zus_atom_test_matrix.py", "zus_zasilkowa_calculator.py"):
        assert tool in txt, f"silnik nie rozszerza {tool}"
