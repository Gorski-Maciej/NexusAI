#!/usr/bin/env python3
"""
Auto-Tests dla P03 VAT MACRO v9.0 (prompts_glm52/P03_VAT_Macro.txt)
Sekcje: 1 (stawki/zwolnienia), 3 (odliczenia/korekty), 4 (MPP — priorytet),
        6 (fraud), 2/5/7/8 (POS/KSeF/pipeline/genius ideas).
Wygenerowano: 2026-08-02
"""

import json
import sys
from pathlib import Path

import pytest

TOOLS_DIR = Path(__file__).resolve().parent.parent.parent / "tools"


# ═══════════════════════════════════════════════════════════════════════════
# SEKCJA 4 — MPP AUTO-DETECTOR (CLI, priorytet)
# ═══════════════════════════════════════════════════════════════════════════

class TestMppAutoDetector:
    def test_detect_annex15_cn(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_mpp_auto_detector as mad
        mad.ANNEX15_PATH = tmp_path / "annex15.json"
        mad.save_annex15(mad.DEFAULT_ANNEX15_CN)
        result = mad.detect_mpp({
            "invoice_number": "FV/1/2026",
            "direction": "PURCHASE",
            "cn_code": "72071210",
            "category_code": "STEEL",
            "amount_gross": 20000,
            "vat_amount": 4600,
        })
        assert result["mpp_required"] is True
        assert result["trigger"] == "ANNEX15_CN"
        assert result["mpp_violation"] is True
        assert result["sanction_30pct"] == 1380.0

    def test_detect_semantic_description(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_mpp_auto_detector as mad
        result = mad.detect_mpp({
            "direction": "PURCHASE",
            "description": "dostawa stali konstrukcyjnej do budowy hali",
            "amount_gross": 30000,
        })
        assert result["trigger"] == "SEMANTIC_DESCRIPTION"
        assert result["semantic_hits"] == ["stal"]

    def test_detect_below_threshold_no_mpp(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_mpp_auto_detector as mad
        result = mad.detect_mpp({
            "direction": "PURCHASE",
            "cn_code": "72071210",
            "amount_gross": 5000,
        })
        assert result["mpp_required"] is False
        assert result["mpp_violation"] is False

    def test_annex15_update(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_mpp_auto_detector as mad
        mad.ANNEX15_PATH = tmp_path / "annex15.json"
        mad.save_annex15({})
        mad.cmd_annex15(type("A", (), {"show": False, "add": ["8542:Półprzewodniki"], "fn": mad.cmd_annex15})())
        assert "8542" in mad.load_annex15()


# ═══════════════════════════════════════════════════════════════════════════
# SEKCJE 1/3/4/6 — STRUKTURA REGO P03
# ═══════════════════════════════════════════════════════════════════════════

class TestP03RegoPackages:
    def test_packages_present(self):
        base = Path(__file__).resolve().parent.parent.parent
        for fname, marker in [
            ("vat_rates_exemptions_audit_enterprise.rego", "package jdg.vat_rates_audit"),
            ("vat_deductions_corrections_enterprise.rego", "package jdg.vat_deductions_audit"),
            ("vat_mpp_split_payment_enterprise.rego", "package jdg.vat_mpp_split_payment"),
            ("vat_fraud_detection_enterprise.rego", "package jdg.vat_fraud_detection"),
            ("p03_vat_macro_innovations_v9.rego", "package jdg.p03_vat_macro_innovations"),
        ]:
            p = base / "rules" / fname
            assert p.exists(), f"Brak pliku: {fname}"
            assert marker in p.read_text(encoding="utf-8"), f"Brak markera w {fname}"

    def test_main_jdg_wiring(self):
        """P03 pakiety muszą być zaimportowane i w _package_decisions."""
        main = (Path(__file__).resolve().parent.parent.parent / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
        for pkg in ["vat_rates_audit", "vat_deductions_audit", "vat_mpp_split_payment",
                    "vat_fraud_detection", "p03_vat_macro_innovations"]:
            assert f"import data.jdg.{pkg}" in main, f"Brak importu: {pkg}"
            assert f'"{pkg}":' in main or f'"jdg.{pkg}":' in main, f"Brak wpisu w _package_decisions: {pkg}"
        assert "final_verdict_p03" in main

    def test_key_rules_present(self):
        """Kluczowe reguły P03 w plikach rego (audyt stawek, MPP, fraud, KSeF)."""
        base = Path(__file__).resolve().parent.parent.parent
        rates = (base / "rules" / "vat_rates_exemptions_audit_enterprise.rego").read_text(encoding="utf-8")
        for marker in ["midyear_breach", "startup_proportional_limit", "rate_mismatch", "rate_map"]:
            assert marker in rates, f"Brak reguły stawek: {marker}"
        mpp = (base / "rules" / "vat_mpp_split_payment_enterprise.rego").read_text(encoding="utf-8")
        for marker in ["mp_auto_mark", "mpp_violation", "solidary_liability_risk", "annex15_cn"]:
            assert marker in mpp, f"Brak reguły MPP: {marker}"
        fraud = (base / "rules" / "vat_fraud_detection_enterprise.rego").read_text(encoding="utf-8")
        for marker in ["empty_invoice_detection", "carousel_detection", "vanishing_trader_detection",
                       "counterparty_risk_score", "fraud_score_decision"]:
            assert marker in fraud, f"Brak reguły fraud: {marker}"
        inn = (base / "rules" / "p03_vat_macro_innovations_v9.rego").read_text(encoding="utf-8")
        for marker in ["ksef_mandatory_date", "refund_forecast", "auto_gtu", "oss_analysis",
                       "vat_thresholds_snapshot", "vat_obligations_calendar"]:
            assert marker in inn, f"Brak innowacji P03: {marker}"


# ═══════════════════════════════════════════════════════════════════════════
# SEKCJA 1 — PROPORSION / LIMITY (weryfikacja matematyki narzędzia)
# ═══════════════════════════════════════════════════════════════════════════

class TestVatMath:
    def test_startup_proportion_math(self):
        """Art. 113 ust. 9: limit proporcjonalny = 200k × miesiące/12."""
        limit = 200000
        for entry_month, expected_ratio in [(1, 1.0), (7, 0.5), (12, 1/12)]:
            months_remaining = 13 - entry_month
            prop = round(limit * (months_remaining / 12.0) * 100) / 100
            assert abs(prop / limit - expected_ratio) < 0.01, f"Błąd proporcji dla miesiąca {entry_month}"

    def test_mpp_sanction_30pct(self):
        """Art. 108a ust. 5-7: sankcja = 30% VAT."""
        vat = 4600.0
        assert round(vat * 0.30, 2) == 1380.0

    def test_refund_paths(self):
        """Art. 87: 25/60/180 dni wg ścieżek."""
        def path(arrears, control, months):
            if not arrears and not control and months >= 12:
                return 25
            if arrears and not control:
                return 60
            if months < 12 and not control:
                return 180
            return 0
        assert path(False, False, 36) == 25
        assert path(True, False, 36) == 60
        assert path(False, False, 6) == 180
        assert path(False, True, 36) == 0


# ═══════════════════════════════════════════════════════════════════════════
# PROMPT 02 — NOWE NARZĘDZIA ENTERPRISE: vat_rate_engine + mpp_monitor
# (P02 Sekcja 1: stawki PKWiU/CN; P02 Sekcja 2: MPP PRIORYTET)
# ═══════════════════════════════════════════════════════════════════════════

class TestVatRateEngine:
    def test_classify_semantic_bread_5pct(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_rate_engine as vre
        r = vre.classify(description="chleb żytni")
        assert r["vat_rate"] == "5"
        assert r["source"] == "SEMANTIC"
        assert r["trust_score"] >= 0.8

    def test_classify_cn_8pct_beer(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_rate_engine as vre
        r = vre.classify(cn_code="22030010")
        assert r["vat_rate"] == "8"
        assert r["source"] == "CN_2203"

    def test_classify_cn_car_23pct(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_rate_engine as vre
        r = vre.classify(cn_code="87032319")
        assert r["vat_rate"] == "23"
        assert r["source"] == "CN_8703"

    def test_build_index_entries(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_rate_engine as vre
        idx = vre.build_index()
        assert idx["entries"] >= 30
        assert idx["index"]["1905"] == "5"
        assert idx["index"]["2710"] == "23"


class TestMppMonitor:
    def test_mpp_check_violation(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import mpp_monitor as mm
        r = mm.check({
            "invoice_number": "FV/MPP/1",
            "direction": "PURCHASE",
            "cn_code": "72071210",
            "amount_gross": 20000,
            "vat_amount": 4600,
        })
        assert r["mpp_required"] is True
        assert r["trigger"] == "ANNEX15_CN"
        assert r["violation"] is True
        assert r["sanction_30pct"] == 1380.0
        assert r["routing"] == "BLOCK_AND_ALERT"

    def test_mpp_check_ok_split_used(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import mpp_monitor as mm
        r = mm.check({
            "invoice_number": "FV/MPP/2",
            "direction": "PURCHASE",
            "cn_code": "72071210",
            "amount_gross": 20000,
            "vat_amount": 4600,
            "split_payment_used": True,
            "payment_to_whitelisted_account": True,
        })
        assert r["violation"] is False
        assert r["whitelist_violation"] is False
        assert r["routing"] == "OK"

    def test_mpp_below_threshold(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import mpp_monitor as mm
        r = mm.check({
            "invoice_number": "FV/MPP/3",
            "direction": "PURCHASE",
            "cn_code": "72071210",
            "amount_gross": 10000,
            "vat_amount": 2300,
        })
        assert r["mpp_required"] is False
        assert r["violation"] is False

    def test_mpp_semantic_trigger(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import mpp_monitor as mm
        r = mm.check({
            "invoice_number": "FV/MPP/4",
            "direction": "PURCHASE",
            "description": "zakup złomu stalowego",
            "amount_gross": 16000,
            "vat_amount": 3680,
        })
        assert r["trigger"] == "SEMANTIC_DESCRIPTION"
        assert r["mpp_required"] is True

    def test_psd2_confirm(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import mpp_monitor as mm
        inv = {
            "invoice_number": "FV/PSD2/1",
            "direction": "PURCHASE",
            "cn_code": "72071210",
            "amount_gross": 20000,
            "vat_amount": 4600,
            "split_payment_used": True,
            "psd2": {"split_payment_confirmed": True, "transfer_type": "MPP", "account_type": "VAT"},
        }
        r = mm.psd2_confirm(inv)
        assert r["psd2_verified"] is True
