# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P12 GLM52 CROSS-BORDER / TP / CFC / MDR — Enterprise Test Suite
# Coverage: tp_documentation_engine, cfc_classifier, mdr_scorer, fx_rate_engine,
#           cbam_monitor, atomic Rego, native tests, wiring PAS 49
# ═══════════════════════════════════════════════════════════════════════════════
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

import tp_documentation_engine  # noqa: E402
import cfc_classifier  # noqa: E402
import mdr_scorer  # noqa: E402
import fx_rate_engine  # noqa: E402
import cbam_monitor  # noqa: E402


# ── 1. TP DOCUMENTATION ENGINE (art. 23m-23zf — pustynia pokrycia) ─────────────
class TestTpDocumentationEngine:
    def test_related_party_above_25(self):
        r = tp_documentation_engine.related_party_detector(share_pct=0.30)
        assert r["related_party"] is True
        assert "23m" in r["legal"]

    def test_related_party_family(self):
        r = tp_documentation_engine.related_party_detector(family_ties=True)
        assert r["related_party"] is True

    def test_related_party_below(self):
        r = tp_documentation_engine.related_party_detector(share_pct=0.10)
        assert r["related_party"] is False

    def test_doc_threshold_goods(self):
        r = tp_documentation_engine.documentation_threshold_monitor(12000000, 0, 0)
        assert r["documentation_required"] is True

    def test_doc_threshold_services(self):
        r = tp_documentation_engine.documentation_threshold_monitor(0, 3000000, 0)
        assert r["documentation_required"] is True

    def test_doc_threshold_financial(self):
        r = tp_documentation_engine.documentation_threshold_monitor(0, 0, 3000000)
        assert r["documentation_required"] is True

    def test_doc_threshold_below_all(self):
        r = tp_documentation_engine.documentation_threshold_monitor(100000, 100000, 100000)
        assert r["documentation_required"] is False

    def test_market_price_divergence_risk(self):
        r = tp_documentation_engine.market_price_benchmark(12000, 10000)
        assert r["adjustment_risk"] is True

    def test_market_price_no_risk(self):
        r = tp_documentation_engine.market_price_benchmark(10800, 10000)
        assert r["adjustment_risk"] is False

    def test_tpr_countdown(self):
        r = tp_documentation_engine.tpr_countdown("2026-03-01", today="2026-02-20")
        assert r["days_left"] == 9


# ── 2. CFC CLASSIFIER (art. 30f) ───────────────────────────────────────────────
class TestCfcClassifier:
    def test_cfc_classified(self):
        r = cfc_classifier.classify(0.60, 0.50, 0.10, cfc_income_pln=100000)
        assert r["cfc_classified"] is True
        assert r["attributed_income_pln"] == 60000

    def test_cfc_not_controlled(self):
        r = cfc_classifier.classify(0.40, 0.50, 0.10)
        assert r["cfc_classified"] is False

    def test_cfc_not_passive_enough(self):
        r = cfc_classifier.classify(0.60, 0.20, 0.10)
        assert r["cfc_classified"] is False

    def test_cfc_tax_too_high(self):
        r = cfc_classifier.classify(0.60, 0.50, 0.20)
        assert r["cfc_classified"] is False

    def test_cfc_excluded_real_activity(self):
        r = cfc_classifier.classify(0.60, 0.50, 0.10, real_economic_activity=True)
        assert r["cfc_classified"] is False
        assert "rzeczywista" in r["exclusion_reason"]


# ── 3. MDR SCORER (art. 86a-86o + sankcje KKS) ─────────────────────────────────
class TestMdrScorer:
    def test_reportable_hallmark_mbt(self):
        r = mdr_scorer.score(["A"], main_benefit_test=True)
        assert r["reportable"] is True
        assert r["probability_pct"] == 95

    def test_not_reportable(self):
        r = mdr_scorer.score([], main_benefit_test=False)
        assert r["reportable"] is False

    def test_reportable_via_benefit_threshold(self):
        r = mdr_scorer.score(["A"], tax_benefit_eur=300000)
        assert r["reportable"] is True  # MBT via 250k EUR

    def test_deadline_30_days(self):
        r = mdr_scorer.deadline_calc("2026-01-15")
        assert r["mdr1_deadline"] == "2026-02-14"
        assert r["deadline_days"] == 30

    def test_mdr1_xml_generation(self):
        r = mdr_scorer.generate_mdr1_xml("Jan", "123", "test", ["A"])
        assert "MDR-1" in r["xml"]
        assert "Jan" in r["xml"]

    def test_legal_basis_canonical(self):
        r = mdr_scorer.score(["A"], main_benefit_test=True)
        assert "Dz.U. 2025 poz. 234" in r["legal"]
        assert "Dz.U. 2025 poz. 678" in r["legal"]  # KKS sankcje


# ── 4. FX RATE ENGINE (art. 14 ust. 2c, NBP time-travel) ───────────────────────
class TestFxRateEngine:
    def test_fx_difference(self):
        r = fx_rate_engine.fx_difference(10000, "EUR", "2026-01-05", "2026-02-03")
        expected = round(10000 * (4.37 - 4.29) / 4.29 * 100) / 100
        assert r["difference_pln"] == expected

    def test_fx_rate_time_travel(self):
        r = fx_rate_engine.get_rate("EUR", "2026-01-05")
        assert r["rate"] == 4.29
        assert r["source"] == "NBP tabela A"
        assert r["fallback"] is False

    def test_fx_fallback_503(self):
        r = fx_rate_engine.get_rate("JPY", "2026-03-02")
        assert r["fallback"] is True
        assert "503" in r["alert"]

    def test_currency_conversion(self):
        r = fx_rate_engine.currency_conversion(1000, "EUR", "2026-03-02")
        assert r["amount_pln"] == 4400


# ── 5. CBAM MONITOR (UE 2023/956) + DAC8 ───────────────────────────────────────
class TestCbamMonitor:
    def test_cbam_registration_required(self):
        r = cbam_monitor.monitor("stal", 5000, 10.0)
        assert r["registration_required"] is True
        assert r["under_threshold"] is False

    def test_cbam_under_threshold_exempt(self):
        r = cbam_monitor.monitor("stal", 100, 1.0)
        assert r["under_threshold"] is True

    def test_cbam_embedded_emissions(self):
        r = cbam_monitor.monitor("stal", 5000, 10.0, importer_registered=True)
        assert r["embedded_emissions_t"] == round(10 * 1.89 * 100) / 100

    def test_cbam_quarterly_calendar(self):
        r = cbam_monitor.quarter_report_calendar(2026)
        assert r["quarterly_deadlines"]["Q1"] == "2026-04-30"
        assert r["quarterly_deadlines"]["Q4"] == "2027-01-31"

    def test_dac8_tracker(self):
        r = cbam_monitor.dac8_tracker(60000)
        assert r["dac8_reporting_due"] is True


# ── 6. ATOMIC REGO — struktura (P01 kontrakt) ──────────────────────────────────
class TestAtomicRegoStructure:
    def test_atomic_file_exists(self):
        f = ROOT / "rules" / "micro" / "crossborder_atomic_p12.rego"
        assert f.exists()
        text = f.read_text(encoding="utf-8")
        assert "package jdg.micro.crossborder_atomic_p12" in text
        assert "data.jdg.thresholds" in text  # ADR-002

    def test_atomic_rule_ids_unique(self):
        import re
        f = ROOT / "rules" / "micro" / "crossborder_atomic_p12.rego"
        text = f.read_text(encoding="utf-8")
        ids = re.findall(r'"rule_id":\s*"([^"]+)"', text)
        assert len(ids) == len(set(ids))
        assert len(ids) >= 10

    def test_atomic_has_legal_basis(self):
        import re
        f = ROOT / "rules" / "micro" / "crossborder_atomic_p12.rego"
        text = f.read_text(encoding="utf-8")
        bases = re.findall(r'"_legal_basis":\s*"([^"]+)"', text)
        assert len(bases) >= 9  # 10 reguł: 9 matched z legal_basis + 1 default no_match
        assert any("poz. 1760" in b for b in bases), "brak PIT Dz.U. 2024 poz. 1760"
        assert any("poz. 234" in b for b in bases), "brak OrdPU Dz.U. 2025 poz. 234"

    def test_native_rego_test_exists(self):
        assert (ROOT / "tests" / "rego" / "test_native_crossborder.rego").exists()

    def test_no_stub_patterns(self):
        f = ROOT / "rules" / "micro" / "crossborder_atomic_p12.rego"
        text = f.read_text(encoding="utf-8")
        assert "crossborder_condition_met" not in text
        assert "TODO" not in text


# ── 7. WIRING PAS 49 ───────────────────────────────────────────────────────────
class TestWiringP49:
    def test_main_jdg_imports_crossborder(self):
        f = ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "micro.crossborder_atomic_p12" in text
        assert "micro.tp" in text
        assert "micro.mdr" in text

    def test_final_verdict_p49_exists(self):
        f = ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "final_verdict_p49" in text
        assert "final_verdict_p50 = safe_merge(final_verdict_p49," in text  # P13 wydłużył łańcuch

    def test_thresholds_crossborder_section(self):
        f = ROOT / "rules" / "thresholds_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "crossborder := {" in text
        assert "tp_goods_transactions_pln" in text
        assert "cfc_ownership_min_pct" in text
        assert "mdr_mbt_threshold_eur" in text


# ── 8. BRAMKI JAKOŚCI ──────────────────────────────────────────────────────────
class TestQualityGates:
    def test_crossborder_quality_gate_passes(self):
        import subprocess
        proc = subprocess.run(
            [sys.executable, str(ROOT / "tools" / "crossborder_quality.py"), "--gate"],
            capture_output=True, text=True, timeout=120,
        )
        assert "BRAMKA: PASS" in proc.stdout, proc.stdout[-2000:]

    def test_validate_rules_zero_errors(self):
        import subprocess
        proc = subprocess.run(
            [sys.executable, str(ROOT / "tools" / "validate_rules.py")],
            capture_output=True, text=True, timeout=180,
        )
        assert proc.returncode == 0, proc.stdout[-2000:] + proc.stderr[-2000:]
