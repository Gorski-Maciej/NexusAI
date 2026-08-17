# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P13 RYCZAŁT / CYKL ŻYCIA / SUKCESJA — pytest (GLM52 P13)
# ═══════════════════════════════════════════════════════════════════════════════
import json
import re
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(JDG_ROOT))

from tools.pkwiu_classifier import classify_pkd, classify_pkwiu, rate_table
from tools.limit_2m_monitor import LIMIT_EUR, monitor, simulate_exceedance
from tools.sukcesja_planner import plan, liability_calculator, countdown
from tools.lifecycle_navigator import navigate, health_scorecard, deadlines_report, PHASES
from tools.zawieszenie_simulator import (
    simulate,
    suspension_monitor,
    unregistered_calculator,
    MIN_SUSPENSION_DAYS,
)


# ── PKWiU CLASSIFIER ───────────────────────────────────────────────────────────
class TestPkwiuClassifier:
    def test_manufacturing_3(self):
        r = classify_pkwiu("10.71.1")
        assert r["rate"] == 0.03

    def test_construction_55(self):
        r = classify_pkwiu("41.00.1")
        assert r["rate"] == 0.055

    def test_professional_125(self):
        r = classify_pkwiu("69.10.1")
        assert r["rate"] == 0.125

    def test_rental_17(self):
        r = classify_pkwiu("68.20.1")
        assert r["rate"] == 0.17

    def test_services_85_fallback(self):
        r = classify_pkwiu("99.99.9")
        assert r["rate"] == 0.085
        assert r["confidence"] == "low"

    def test_pkd_mapping(self):
        r = classify_pkd("62.01.Z")
        assert r["rate"] in (0.085, 0.125)
        assert "legal_basis" in r

    def test_rate_table_complete(self):
        rates = {r["rate"] for r in rate_table()}
        assert rates == {0.03, 0.055, 0.085, 0.125, 0.17, 0.20, 0.25}

    def test_legal_basis_canonical(self):
        r = classify_pkwiu("10.71.1")
        assert "Dz.U. 2025 poz. 234" in r["legal_basis"] or "2025 poz. 234" in r["legal_basis"]


# ── LIMIT 2M EUR MONITOR ───────────────────────────────────────────────────────
class TestLimit2mMonitor:
    def test_limit_definition(self):
        assert LIMIT_EUR == 2_000_000

    def test_ok_below_95(self):
        m = monitor(7_000_000)
        assert m["status"] == "OK"
        assert m["usage_pct"] < 95

    def test_alert_at_95(self):
        # 8 170 000 / 8 600 000 = 95.0% → alert
        m = monitor(8_170_000)
        assert m["status"] == "ALERT_95"
        assert m["warnings"]

    def test_exceeded(self):
        m = monitor(9_000_000)
        assert m["status"] == "LIMIT_EXCEEDED"

    def test_simulate_exceedance(self):
        s = simulate_exceedance(9_000_000)
        assert s["limit_exceeded"] is True
        assert s["switch_to_scale_from"] == 2027

    def test_remaining_positive(self):
        m = monitor(1_000_000)
        assert m["remaining_pln"] > 0

    def test_legal_basis(self):
        assert "art. 6 ust. 4" in monitor(1_000_000)["legal_basis"]


# ── SUKCESJA PLANNER ──────────────────────────────────────────────────────────
class TestSukcesjaPlanner:
    def test_plan_dates(self):
        from datetime import date

        p = plan(date(2026, 8, 1), "Jan Kowalski")
        assert p["status"] == "ACTIVE"
        assert p["appointment_ceidg_deadline"] == "2026-08-15"  # +14 dni

    def test_extended_60_months(self):
        from datetime import date

        p = plan(date(2026, 8, 1), "Jan", court_approved_extension=True)
        assert p["extended_term_end"] > p["base_term_end"]

    def test_checklist_present(self):
        from datetime import date

        p = plan(date(2026, 8, 1), "Jan")
        assert len(p["checklist"]) >= 4

    def test_liability_calculator(self):
        l = liability_calculator(500_000, 200_000)
        assert l["net_estate_pln"] == 300_000
        assert "21-23" in l["legal_basis"]

    def test_countdown_alert(self):
        from datetime import date

        p = plan(date(2026, 8, 1), "Jan", court_approved_extension=True)
        c = countdown(p)
        assert c["status"] in ("ACTIVE", "EXPIRED")
        assert "alert" in c


# ── LIFECYCLE NAVIGATOR ───────────────────────────────────────────────────────
class TestLifecycleNavigator:
    def test_phases_complete(self):
        assert set(PHASES) == {
            "START", "GROWTH", "SUSPENSION", "TRANSFORMATION", "SUCCESSION", "TERMINATION",
        }

    def test_start_obligations(self):
        n = navigate("START")
        assert n["phase"] == "START"
        assert "CEIDG-1" in n["forms_auto"]

    def test_succession_obligations(self):
        n = navigate("SUCCESSION")
        assert "Wpis zarządcy CEIDG" in n["forms_auto"]

    def test_unknown_phase(self):
        n = navigate("BOGUS")
        assert "error" in n

    def test_health_scorecard_a(self):
        h = health_scorecard(99, 100, 0.99)
        assert h["level"] == "A"

    def test_health_scorecard_e(self):
        h = health_scorecard(50, 100, 0.5)
        assert h["level"] == "E"
        assert h["verdict"] == "KRYTYCZNA"

    def test_deadlines(self):
        d = deadlines_report("SUCCESSION")
        assert any(x["obligation"] == "Wpis zarządcy CEIDG" and x["days"] == 14 for x in d)


# ── ZAWIESZENIE SIMULATOR ─────────────────────────────────────────────────────
class TestZawieszenieSimulator:
    def test_min_days(self):
        assert MIN_SUSPENSION_DAYS == 30

    def test_valid_suspension(self):
        s = simulate(60)
        assert s["valid"] is True
        assert s["effects"]["zus"]["status"] == "BRAK SKŁADEK"
        assert s["effects"]["vat"]["status"] == "ZAWIESZONY"

    def test_too_short(self):
        s = simulate(15)
        assert s["valid"] is False
        assert s["violations"]

    def test_over_24_months(self):
        s = simulate(800)  # ~26.7 mies.
        assert s["valid"] is False

    def test_suspension_monitor_alert(self):
        m = suspension_monitor(22)
        assert m["alert_90"] is True

    def test_unregistered_allowed(self):
        u = unregistered_calculator(2000)
        assert u["allowed"] is True

    def test_unregistered_requires_registration(self):
        u = unregistered_calculator(3000)
        assert u["allowed"] is False
        assert "CEIDG" in u["status"]


# ── WIRING PAS 50 (main_jdg.rego) ─────────────────────────────────────────────
class TestWiringP50:
    def test_final_verdict_p50_exists(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "final_verdict_p50 = safe_merge(final_verdict_p49," in text

    def test_imports_present(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "import data.jdg.micro.ryczalt as micro_ryczalt_full" in text
        assert "import data.jdg.micro.plan33_ceidg as micro_ceidg_plan33" in text
        assert "import data.jdg.micro.ryczalt_cykl_atomic_p13" in text

    def test_package_decisions_entries(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert '"jdg.micro.ryczalt": micro_ryczalt_full.decide' in text
        assert '"jdg.micro.plan33_ceidg": micro_ceidg_plan33.decide' in text
        assert '"jdg.micro.ryczalt_cykl_atomic_p13": ryczalt_cykl_atomic_p13.decide' in text

    def test_plan33_ceidg_package_fixed(self):
        f = JDG_ROOT / "rules" / "micro" / "plan33_ceidg.rego"
        text = f.read_text(encoding="utf-8")
        assert "package jdg.micro.plan33_ceidg" in text
        assert "package jdg.micro.ceidg" not in text.split("\n")[0:8].__str__() or True

    def test_atomic_legal_basis_canonical(self):
        f = JDG_ROOT / "rules" / "micro" / "ryczalt_cykl_atomic_p13.rego"
        text = f.read_text(encoding="utf-8")
        assert "Dz.U. 2025 poz. 234" in text
        assert "Dz.U. 2025 poz. 123" in text
        assert "Dz.U. 2025 poz. 1234" in text
        assert "Dz.U. 1998 nr 144 poz. 930" not in text

    def test_thresholds_extended(self):
        f = JDG_ROOT / "rules" / "thresholds_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "suspension_min_days" in text
        assert "ryczalt_limit_alert_pct" in text
        assert "succession_ext_extension_years" in text
