#!/usr/bin/env python3
"""
Auto-Tests dla P05 PIT MACRO v9.0 (prompts_glm52/P05_PIT_Macro.txt)
Sekcje: 1 (formy), 2 (ulgi — PRIORYTET), 3 (KUP/NKUP), 4 (zaliczki/zeznanie),
        5 (Art. 21), 6 (thresholdy temporalne), 7 (genius ideas), 8 (mapa drogowa).
Wygenerowano: 2026-08-02
"""

import sys
from pathlib import Path

import pytest

TOOLS_DIR = Path(__file__).resolve().parent.parent.parent / "tools"
BASE_DIR = Path(__file__).resolve().parent.parent.parent


# ═══════════════════════════════════════════════════════════════════════════
# NARZĘDZIE — PIT RELIEFS OPTIMIZER
# ═══════════════════════════════════════════════════════════════════════════

class TestPitReliefsOptimizer:
    def test_scale_tax_below_threshold(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        assert round(pro.scale_tax(100000), 2) == 12000.0  # 12%

    def test_scale_tax_above_threshold(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        # 120000*0.12 + (150000-120000)*0.32 = 14400 + 9600 = 24000
        assert round(pro.scale_tax(150000), 2) == 24000.0

    def test_linear_tax(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        assert round(pro.linear_tax(100000), 2) == 19000.0

    def test_what_if_best(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        bases = dict(pro.DEFAULT_BASES)
        bases["IP_BOX"] = 100000
        wi = pro.what_if(bases)
        assert wi["best"] == "IP_BOX"

    def test_ranking_sorted_desc(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        bases = {"BR": 100000, "THERMO": 20000, "IP_BOX": 10000}
        ranking = pro.rank_reliefs(bases, set(pro.DEFAULT_ELIGIBLE), set())
        savings = [r["estimated_saving"] for r in ranking]
        assert savings == sorted(savings, reverse=True)

    def test_unused_detector(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        bases = {"BR": 10000, "THERMO": 20000}
        eligible = {"BR", "THERMO"}
        claimed = {"BR"}
        unused = pro.detect_unused(bases, eligible, claimed)
        assert unused["unused"] == ["THERMO"]
        assert unused["estimated_missed_saving"] > 0

    def test_advances_simplified(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        adv = pro.advances_simulation(prev_year_income=120000, monthly_income=10000)
        assert adv["simplified_monthly"] == 10000.0  # 1/12 z poprzedniego roku

    def test_snapshot_diff(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        diff = pro.snapshot_diff(2022, 2023)
        assert diff["changes"]["scale_low"] == {"from": 0.17, "to": 0.12}

    def test_predict_advances(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        f = pro.predict_advances([1000, 1200, 1100], horizon=4)
        assert len(f["forecast"]) == 4
        assert all(x > 0 for x in f["forecast"])

    def test_thermo_cap(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_reliefs_optimizer as pro
        # art. 26h: limit 53 000 PLN — kwota ponad limit nie daje ulgi
        bases = {"THERMO": 100000}
        saving = pro.relief_saving("THERMO", bases)
        expected = 53000 * 1.0 * pro.SCALE_LOW
        assert round(saving, 2) == round(expected, 2)


# ═══════════════════════════════════════════════════════════════════════════
# STRUKTURA REGO P05
# ═══════════════════════════════════════════════════════════════════════════

class TestP05RegoPackages:
    def test_package_present(self):
        p = BASE_DIR / "rules" / "p05_pit_macro_innovations_v9.rego"
        assert p.exists(), "Brak pliku p05_pit_macro_innovations_v9.rego"
        text = p.read_text(encoding="utf-8")
        assert "package jdg.p05_pit_macro_innovations" in text
        assert "default decide" in text

    def test_main_jdg_wiring(self):
        """P05 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p05."""
        main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
        assert "import data.jdg.p05_pit_macro_innovations" in main
        assert '"jdg.p05_pit_macro_innovations":' in main or '"p05_pit_macro_innovations":' in main
        assert "final_verdict_p05" in main

    def test_key_rules_present(self):
        """Kluczowe reguły P05 (Sekcje 1-7) w pliku rego."""
        text = (BASE_DIR / "rules" / "p05_pit_macro_innovations_v9.rego").read_text(encoding="utf-8")
        for marker in ["form_audit_report", "form_change_simulator", "relief_audit_report",
                       "unused_relief_detector", "relief_what_if", "kup_audit_report",
                       "advance_audit_report", "art21_audit_report", "pit_thresholds_snapshot",
                       "zaliczka_recommendation", "loss_optimizer", "spouse_synergy",
                       "relief_stacking_guard", "deadline_radar", "relief_limit_drift"]:
            assert marker in text, f"Brak reguły: {marker}"

    def test_innovations_summary_15(self):
        """Sekcja 7: min. 15 genius ideas — implemented_count >= 15."""
        text = (BASE_DIR / "rules" / "p05_pit_macro_innovations_v9.rego").read_text(encoding="utf-8")
        assert '"implemented_count": 15' in text

    def test_no_reassignment_patterns(self):
        """Krytyczna zasada Rego (z review P01-P04): brak reassignment `x := x + N {cond}`."""
        text = (BASE_DIR / "rules" / "p05_pit_macro_innovations_v9.rego").read_text(encoding="utf-8")
        assert " := 0.90 {" not in text
        # brak wzorca guarded assignment w ciałach (inline else w obiektach)
        for line in text.splitlines():
            if line.strip().startswith("else") and "{" in line:
                assert not line.startswith(" "), f"Inline else w ciele: {line.strip()}"

    def test_legal_basis_present(self):
        """ADR-006: każda decyzja z _legal_basis i _routing_reason."""
        text = (BASE_DIR / "rules" / "p05_pit_macro_innovations_v9.rego").read_text(encoding="utf-8")
        count_legal = text.count("_legal_basis")
        count_routing = text.count("_routing_reason")
        # każda decyzja ma oba; liczby >= 14 (formy, ulgi x4, KUP, zaliczki, art21,
        # genius x4, główny decide) — wyszczególnione reguły z oboma polami
        assert count_legal >= 14, f"Za mało _legal_basis: {count_legal}"
        assert count_routing >= 14, f"Za mało _routing_reason: {count_routing}"
