#!/usr/bin/env python3
"""
NexusAI JDG — Testy GLM52 P07 (ULGI PIT + OPTYMALIZACJA)
================================================================
Pokrycie: relief_detector.py (detektor ulg z Trust Score), ipbox_nexus_calculator.py
(art. 30ca), brd_project_tracker.py (art. 26e), estonian_cit_simulator.py
(art. 28c-28t CIT), reguły ulg (missing_reliefs: prototyp 26eb; thermo 26h z
data.thresholds), okablowanie main_jdg (importy, rejestr), thresholds P07.
"""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys_path_hack = __import__("sys")
sys_path_hack.path.insert(0, str(ROOT / "tools"))

from relief_detector import RELIEF_CATALOG, _detect_from_profile, render_table  # noqa: E402
from ipbox_nexus_calculator import compute_nexus  # noqa: E402
from brd_project_tracker import compute_tracker  # noqa: E402
from estonian_cit_simulator import (  # noqa: E402
    pit_linear_tax,
    pit_scale_tax,
    simulate as estonian_simulate,
)

MAIN_REGO = ROOT / "rules" / "main_jdg.rego"
THRESHOLDS = ROOT / "rules" / "thresholds_jdg.rego"
MISSING_RELIEFS = ROOT / "rules" / "pit" / "missing_reliefs_enterprise.rego"
THERMO = ROOT / "rules" / "pit" / "thermo_relief_enterprise.rego"


# ═══════════════ RELIEF DETECTOR — detektor ulg ═══════════════

class TestReliefDetector:
    def test_catalog_covers_priority_reliefs(self):
        # Priorytet P07: B+R, IP Box, termo, prototyp, robotyzacja, ekspansja, PIT-0
        for rid in ["BRD", "IPBOX", "THERMO", "PROTOTYPE", "ROBOTIZATION",
                    "EXPANSION", "REHAB", "INTERNET", "BLOOD", "CHILD",
                    "IKZE", "PIT0", "ABOLITION"]:
            assert rid in RELIEF_CATALOG, f"Brak ulgi {rid} w katalogu"

    def test_brd_detection_100pct(self):
        hits = _detect_from_profile({
            "tax_form": "PIT_SCALE",
            "rd_staff_costs_qualified": 100000,
            "rd_materials_costs_qualified": 50000,
        })
        brd = [h for h in hits if h.relief_id == "BRD"]
        assert brd and brd[0].estimated_saving == 150000
        assert brd[0].trust_score > 0.9

    def test_brd_center_200pct(self):
        hits = _detect_from_profile({
            "tax_form": "PIT_SCALE",
            "is_rd_center": True,
            "rd_staff_costs_qualified": 50000,
        })
        brd = [h for h in hits if h.relief_id == "BRD"]
        assert brd and brd[0].estimated_saving == 100000

    def test_thermo_detection_limit_53k(self):
        hits = _detect_from_profile({
            "tax_form": "PIT_SCALE",
            "thermo_expenses_annual_total": 60000,
        })
        thermo = [h for h in hits if h.relief_id == "THERMO"]
        assert thermo and thermo[0].estimated_saving == 53000

    def test_prototype_detection_30pct(self):
        hits = _detect_from_profile({
            "tax_form": "PIT_SCALE",
            "prototype_trial_production_costs": 40000,
        })
        proto = [h for h in hits if h.relief_id == "PROTOTYPE"]
        assert proto and proto[0].estimated_saving == 12000

    def test_robotization_50pct(self):
        hits = _detect_from_profile({
            "tax_form": "PIT_SCALE",
            "robotization_purchase_costs": 200000,
        })
        rob = [h for h in hits if h.relief_id == "ROBOTIZATION"]
        assert rob and rob[0].estimated_saving == 100000

    def test_child_scale_only(self):
        hits = _detect_from_profile({"tax_form": "PIT_SCALE", "children_count": 2})
        child = [h for h in hits if h.relief_id == "CHILD"]
        assert child and child[0].estimated_saving == 2224.08
        # liniowy → brak ulgi na dziecko
        hits_linear = _detect_from_profile({"tax_form": "PIT_LINEAR", "children_count": 2})
        assert not [h for h in hits_linear if h.relief_id == "CHILD"]

    def test_pit0_detection(self):
        hits = _detect_from_profile({"tax_form": "PIT_SCALE", "age": 24, "annual_income": 60000})
        pit0 = [h for h in hits if h.relief_id == "PIT0"]
        assert pit0 and pit0[0].estimated_saving == 60000

    def test_detector_returns_legal_basis_everywhere(self):
        hits = _detect_from_profile({
            "tax_form": "PIT_SCALE",
            "rd_staff_costs_qualified": 1000,
            "thermo_expenses_annual_total": 2000,
            "children_count": 1,
        })
        assert hits
        for h in hits:
            assert h.legal_basis.startswith("Art.")

    def test_render_table_has_all(self):
        table = render_table()
        for rid in ["BRD", "IPBOX", "THERMO"]:
            assert rid in table


# ═══════════════ IP BOX NEXUS CALCULATOR — art. 30ca ═══════════════

class TestIpboxNexusCalculator:
    def test_nexus_full_uplift(self):
        r = compute_nexus(a=100000, b=0, c=0, d=0, qualifying_income=200000)
        assert r.nexus == 1.0  # (100k×1.3)/100k = 1.3 → capped 1.0
        assert r.qualifying_income == 200000
        assert r.tax_5pct == 10000

    def test_nexus_reduced_by_related_party(self):
        r = compute_nexus(a=100000, b=0, c=0, d=30000, qualifying_income=200000)
        expected = (100000 * 1.3) / 130000
        assert r.nexus == pytest.approx(expected, abs=1e-9)
        assert any("powiązanych" in e for e in r.evidence)

    def test_nexus_capped_at_1(self):
        r = compute_nexus(a=100000, b=50000, c=0, d=0, qualifying_income=100000)
        assert r.nexus == 1.0

    def test_nexus_zero_when_no_costs(self):
        r = compute_nexus(a=0, b=0, c=0, d=0, qualifying_income=50000)
        assert r.nexus == 0.0
        assert r.tax_5pct == 0.0

    def test_evidence_chain_present(self):
        r = compute_nexus(a=80000, b=20000, c=10000, d=5000, qualifying_income=300000)
        assert len(r.evidence) >= 4
        assert r.nexus <= 1.0


# ═══════════════ BRD PROJECT TRACKER — art. 26e ═══════════════

class TestBrdProjectTracker:
    def test_single_project_100pct(self):
        r = compute_tracker([{
            "project_id": "P1", "name": "Projekt A", "year": 2026,
            "costs": {"staff": 80000, "zus": 11000, "materials": 20000},
            "staff_brd_percent": 80,
        }], rd_income=200000)
        assert r["summary"]["total_qualifying_costs"] == 111000
        assert r["summary"]["total_deduction"] == 111000
        assert r["risks"] == []

    def test_center_200pct(self):
        r = compute_tracker([{
            "project_id": "P1", "name": "Centrum", "year": 2026,
            "is_rd_center": True, "costs": {"staff": 50000},
            "staff_brd_percent": 90,
        }], rd_income=200000)
        assert r["summary"]["total_deduction"] == 100000

    def test_limit_art_26e_ust6(self):
        r = compute_tracker([{
            "project_id": "P1", "name": "Projekt", "year": 2026,
            "costs": {"staff": 150000}, "staff_brd_percent": 80,
        }], rd_income=100000)
        assert r["summary"]["excess_over_limit"] == 50000

    def test_staff_time_risk_detected(self):
        r = compute_tracker([{
            "project_id": "P1", "name": "Projekt", "year": 2026,
            "costs": {"staff": 50000}, "staff_brd_percent": 30,
        }], rd_income=200000)
        assert any("50%" in x for x in r["risks"])

    def test_categories_legal_points(self):
        r = compute_tracker([{
            "project_id": "P1", "name": "Projekt", "year": 2026,
            "costs": {"staff": 1000, "expertise": 500, "patent": 300},
            "staff_brd_percent": 90,
        }], rd_income=50000)
        detail = r["projects"][0]["costs_detail"]
        assert detail["staff"]["legal"] == "art. 26e ust. 2 pkt 1"
        assert detail["patent"]["legal"] == "art. 26e ust. 2 pkt 5"


# ═══════════════ ESTONIAN CIT SIMULATOR — art. 28c-28t CIT ═══════════════

class TestEstonianCitSimulator:
    def test_retained_zero_tax(self):
        r = estonian_simulate([150000, 180000, 200000], revenue_eur=1500000, distribute_pct=0.0)
        assert r.eligible is True
        assert r.forecasts[0].estonian_retained == 0.0

    def test_revenue_limit_blocked(self):
        r = estonian_simulate([100000], revenue_eur=2500000, distribute_pct=0.0)
        assert r.eligible is False
        assert any("limit" in n.lower() for n in r.eligibility_notes)

    def test_distribution_10pct_low_bracket(self):
        r = estonian_simulate([100000], revenue_eur=1000000, distribute_pct=1.0)
        f = r.forecasts[0]
        assert f.estonian_distributed == pytest.approx(10000, abs=0.01)  # 100k × 10%

    def test_distribution_20pct_high_bracket(self):
        r = estonian_simulate([3000000], revenue_eur=1000000, distribute_pct=1.0)
        f = r.forecasts[0]
        # 2 000 000 × 10% + 1 000 000 × 20%
        assert f.estonian_distributed == pytest.approx(200000 + 200000, abs=0.01)

    def test_scale_vs_linear_brackets(self):
        assert pit_scale_tax(100000) == pytest.approx(12000, abs=0.01)
        assert pit_scale_tax(150000) == pytest.approx(120000 * 0.12 + 30000 * 0.32, abs=0.01)
        assert pit_linear_tax(100000) == pytest.approx(19000, abs=0.01)

    def test_verdict_reinwestycja(self):
        r = estonian_simulate([150000, 180000, 200000], revenue_eur=1500000, distribute_pct=0.0)
        assert "ESTOŃSKI CIT" in r.verdict


# ═══════════════ REGUŁY — prototyp 26eb + thermo thresholds ═══════════════

class TestReliefsRulesStructure:
    def test_prototype_rule_in_missing_reliefs(self):
        text = MISSING_RELIEFS.read_text(encoding="utf-8")
        assert "jdg.pit.missing_reliefs.prototype" in text
        assert "Art. 26eb PIT" in text
        assert "prototype_trial_production_costs" in text

    def test_prototype_before_robotization_order(self):
        text = MISSING_RELIEFS.read_text(encoding="utf-8")
        assert text.index("missing_reliefs.prototype") < text.index("missing_reliefs.robotization")

    def test_coverage_summary_includes_prototype(self):
        text = MISSING_RELIEFS.read_text(encoding="utf-8")
        assert "PROTOTYPE" in text
        assert "total_new_rules" in text

    def test_thermo_uses_thresholds(self):
        text = THERMO.read_text(encoding="utf-8")
        assert "import data.jdg.thresholds" in text
        assert "pit_thermo_limit" in text

    def test_thermo_limit_threshold_present(self):
        text = THRESHOLDS.read_text(encoding="utf-8")
        assert '"pit_thermo_limit": 53000' in text
        assert '"pit_thermo_carry_years": 3' in text

    def test_braces_balanced_reliefs(self):
        for f in [MISSING_RELIEFS, THERMO]:
            src = f.read_text(encoding="utf-8")
            clean = re.sub(r"#.*", "", src)
            clean = re.sub(r'"(?:[^"\\]|\\.)*"', '""', clean)
            assert clean.count("{") == clean.count("}"), f"{f.name}: niezbalansowane nawiasy"


# ═══════════════ OKABLOWANIE — main_jdg.rego ═══════════════

class TestReliefsWiring:
    def test_relief_packages_imported(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        for pkg in ["thermo_relief", "rd_relief", "ipbox", "cross_relief",
                    "donation_relief", "missing_reliefs", "family_estonian",
                    "estonian_cit"]:
            assert f"import data.jdg.pit.{pkg}" in text or f"import data.jdg.{pkg}" in text, \
                f"Brak importu {pkg}"

    def test_relief_packages_in_registry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        for key in ['"jdg.pit.thermo_relief"', '"jdg.pit.rd_relief"', '"jdg.pit.ipbox"',
                    '"jdg.pit.cross_relief"', '"jdg.pit.donation_relief"',
                    '"jdg.pit.missing_reliefs"', '"jdg.pit.family_estonian"',
                    '"jdg.estonian_cit"']:
            assert key in text, f"Brak {key} w rejestrze"

    def test_post_merge_chain_continues(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p45" in text
        assert "final_verdict_post_merge = object.union(final_verdict_p45," in text

    def test_p07_tools_exist(self):
        for tool in ["relief_detector", "ipbox_nexus_calculator",
                     "brd_project_tracker", "estonian_cit_simulator"]:
            assert (ROOT / "tools" / f"{tool}.py").exists(), f"Brak tools/{tool}.py"

    def test_native_reliefs_test_exists(self):
        assert (ROOT / "tests" / "rego" / "test_native_reliefs.rego").exists()
