# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P10 GLM52 KSIĘGOWOŚĆ PKPiR/UoR — Enterprise Test Suite
# Coverage: pkpir_engine, uor_double_entry, uor_closing_engine,
#           pkpir_uor_transformer, atomic Rego, native tests, wiring PAS 47
# ═══════════════════════════════════════════════════════════════════════════════
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

import pkpir_engine  # noqa: E402
import uor_closing_engine  # noqa: E402
import uor_double_entry  # noqa: E402
import pkpir_uor_transformer  # noqa: E402


# ── 1. PKPiR ENGINE (kolumny 1-17, §10-12 rozp. MF 15.11.2025) ────────────────
class TestPkpirEngine:
    def test_build_row_17_columns(self):
        row = pkpir_engine.build_row(
            "2026-03-15", "FV/2026/001", "Kontrahent Sp. z o.o.", "Usługi IT",
            revenue=1000.0, purchase_net=500.0, purchase_vat=115.0, amortization=200.0,
        )
        assert row["col7_przychody_razem"] == 1000.0
        assert row["col13_vat_naliczony"] == 115.0
        assert row["columns_total"] == 17

    def test_validate_row_complete(self):
        row = pkpir_engine.build_row(
            "2026-03-15", "FV/2026/001", "Kontrahent", "Usługi IT",
            revenue=1000.0, purchase_net=500.0, purchase_vat=115.0, amortization=200.0,
        )
        result = pkpir_engine.validate_row(row)
        assert result["complete"] is True
        assert result["missing_columns"] == []
        assert result["verdict"] == "OK"

    def test_validate_row_incomplete(self):
        result = pkpir_engine.validate_row({"col1_data": "2026-03-15"})
        assert result["complete"] is False
        assert result["verdict"] == "BLOCK_AND_ALERT"
        assert "col3_kontrahent" in result["missing_columns"]

    def test_cash_basis_deadline_14_days(self):
        dl = pkpir_engine.cash_basis_deadline("2026-03-01")
        assert dl["deadline"] == "2026-03-15"

    def test_remanent_row(self):
        rem = pkpir_engine.remanent_row(
            "2026-12-31", "REM/2026/01",
            [{"value_pln": 1000.0}, {"value_pln": 500.5}],
        )
        assert rem["remanent_value_pln"] == 1500.5


# ── 2. UoR DOUBLE ENTRY (invariant ΣD = ΣC, art. 15 ust. 1 UoR) ───────────────
class TestDoubleEntryEngine:
    def test_balanced_entries(self):
        entries = [
            uor_double_entry.make_entry("2026-01-10", "Sprzedaż", "10-0 Kasa", "70-0 Przychody", 1000.00),
            uor_double_entry.make_entry("2026-01-10", "Zakup", "40-0 Koszty", "21-0 Zobowiązania", 1000.00),
        ]
        result = uor_double_entry.balance(entries)
        assert result["balanced"] is True
        assert result["debits_sum_pln"] == 2000.00
        assert result["credits_sum_pln"] == 2000.00
        assert result["verdict"] == "OK"

    def test_unbalanced_detection(self):
        entries = [
            uor_double_entry.make_entry("2026-01-10", "Sprzedaż", "10-0 Kasa", "70-0 Przychody", 1000.00),
            {"date": "2026-01-11", "description": "ręczny zapis",
             "debit": {"account": "40-0 Koszty", "amount": 500.00},
             "credit": {"account": "21-0 Zobowiązania", "amount": 499.99},
             "document": "PK/2026-01-11", "balanced": False},
        ]
        result = uor_double_entry.balance(entries)
        assert result["balanced"] is False
        assert result["verdict"] == "BLOCK_AND_ALERT"

    def test_empty_entries(self):
        result = uor_double_entry.balance([])
        assert result["balanced"] is True
        assert result["debits_sum_pln"] == 0.0


# ── 3. UoR CLOSING ENGINE (art. 12 ust. 2 — 12 kroków zamknięcia roku) ─────────
class TestUorClosingEngine:
    def test_closing_checklist_complete(self):
        done = uor_closing_engine.CLOSING_STEPS[:]
        result = uor_closing_engine.closing_checklist(done)
        assert result["complete"] is True
        assert result["steps_total"] == 12
        assert result["steps_missing"] == []

    def test_closing_checklist_missing(self):
        result = uor_closing_engine.closing_checklist(["inwentaryzacja"])
        assert result["complete"] is False
        assert len(result["steps_missing"]) == 11
        assert result["verdict"] == "BLOCK_AND_ALERT"

    def test_verify_balance(self):
        ok = uor_closing_engine.verify_balance(500000.0, 500000.0)
        assert ok["balanced"] is True
        bad = uor_closing_engine.verify_balance(500000.0, 450000.0)
        assert bad["balanced"] is False
        assert bad["verdict"] == "BLOCK_AND_ALERT"

    def test_close_year_profit(self):
        entries = [
            uor_double_entry.make_entry("2026-12-31", "Sprzedaż", "10-0 Kasa", "70-0 Przychody", 5000.00),
            uor_double_entry.make_entry("2026-12-31", "Koszty", "40-0 Koszty", "21-0 Zobowiązania", 3000.00),
        ]
        result = uor_closing_engine.close_year(entries, revenue_accounts=["70-0 Przychody"])
        assert result["revenues_pln"] == 5000.00
        assert result["net_profit_pln"] == 2000.00
        assert result["result_kind"] == "ZYSK"


# ── 4. PKPiR → UoR TRANSFORMER (migracja ewidencji, art. 2 ust. 1 pkt 5 UoR) ──
class TestPkpirUorTransformer:
    def test_transform_balanced(self):
        result = pkpir_uor_transformer.transform(
            remanent_value=15000.0, fixed_assets_value=25000.0,
            kup_balance=10000.0, cash_balance=5000.0,
            receivables=2000.0, liabilities=8000.0,
        )
        assert result["balanced"] is True
        assert result["assets_pln"] == 47000.0
        assert result["liabilities_pln"] == 18000.0
        assert result["equity_pln"] == 29000.0

    def test_opening_balance(self):
        transformed = pkpir_uor_transformer.transform(
            remanent_value=15000.0, fixed_assets_value=25000.0,
            kup_balance=10000.0, cash_balance=5000.0,
            receivables=2000.0, liabilities=8000.0,
        )
        ob = pkpir_uor_transformer.opening_balance(transformed)
        assert ob["balanced"] is True
        assert ob["AKTYWA"]["Razem aktywa"] == 47000.0
        assert ob["PASYWA"]["Razem pasywa"] == 47000.0

    def test_transformation_report(self):
        ok = pkpir_uor_transformer.transformation_report(pkpir_uor_transformer.TRANSFORMATION_STEPS[:])
        assert ok["complete"] is True
        bad = pkpir_uor_transformer.transformation_report([])
        assert bad["complete"] is False
        assert len(bad["steps_missing"]) == len(pkpir_uor_transformer.TRANSFORMATION_STEPS)


# ── 5. ATOMIC REGO — struktura (P01 kontrakt: werdykt 25-polowy) ───────────────
class TestAtomicRegoStructure:
    def test_atomic_file_exists(self):
        f = ROOT / "rules" / "micro" / "ksiegowosc_atomic_p10.rego"
        assert f.exists()
        text = f.read_text(encoding="utf-8")
        assert "package jdg.micro.ksiegowosc_atomic_p10" in text
        assert "data.jdg.thresholds" in text  # ADR-002: zero hardcode

    def test_atomic_rule_ids_unique(self):
        import re
        f = ROOT / "rules" / "micro" / "ksiegowosc_atomic_p10.rego"
        text = f.read_text(encoding="utf-8")
        ids = re.findall(r'"rule_id":\s*"([^"]+)"', text)
        assert len(ids) == len(set(ids)), "zdublowane rule_id w atomic"
        assert len(ids) >= 16

    def test_atomic_has_legal_basis(self):
        import re
        f = ROOT / "rules" / "micro" / "ksiegowosc_atomic_p10.rego"
        text = f.read_text(encoding="utf-8")
        bases = re.findall(r'"_legal_basis":\s*"([^"]+)"', text)
        assert len(bases) >= 16

    def test_native_rego_test_exists(self):
        assert (ROOT / "tests" / "rego" / "test_native_ksiegowosc.rego").exists()

    def test_no_stub_patterns(self):
        f = ROOT / "rules" / "micro" / "ksiegowosc_atomic_p10.rego"
        text = f.read_text(encoding="utf-8")
        assert "sus_condition_met" not in text
        assert "TODO" not in text


# ── 6. WIRING PAS 47 — orchestrator zawiera pakiet księgowości ─────────────────
class TestWiringP47:
    def test_main_jdg_imports_ksiegowosc(self):
        f = ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "micro.ksiegowosc_atomic_p10" in text

    def test_final_verdict_p47_exists(self):
        f = ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "final_verdict_p47" in text
        assert "final_verdict_p48 = safe_merge(final_verdict_p47," in text  # P11 wydłużył łańcuch

    def test_thresholds_accounting_section(self):
        f = ROOT / "rules" / "thresholds_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "ksiegowosc := {" in text


# ── 7. BRAMKI JAKOŚCI ──────────────────────────────────────────────────────────
class TestQualityGates:
    def test_ksiegowosc_quality_gate_passes(self):
        import subprocess
        proc = subprocess.run(
            [sys.executable, str(ROOT / "tools" / "ksiegowosc_quality.py"), "--gate"],
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
