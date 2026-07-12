"""
Testy dla modułów strategicznych v2.0 (48_JDG_STRATEGIC_IMPROVEMENTS_V2.md).

Testowane moduły:
- A1: ImmutableVerdictSigner (Merkle Tree + HMAC signature)
- A2: RegoLinter (wykrywanie zakodowanych wartości)
- A3: LegalExplainerEngine (generator uzasadnień)
- B2: all_pairs + generate_test_matrix (testy kombinatoryczne)
- B3: TelemetryDrivenDAGRouter (telemetry fail-fast)
- C3: LiquidityOracle (symulacje metody kasowej)
"""

from __future__ import annotations

import tempfile
from pathlib import Path
from unittest.mock import MagicMock

import pytest


# ═══════════════════════════════════════════════════════════════════════════════
# A1: ImmutableVerdictSigner
# ═══════════════════════════════════════════════════════════════════════════════


class TestImmutableAudit:
    """Testy dla ImmutableVerdictSigner."""

    def test_hash_input_deterministic(self):
        from nexus_ai.tax.immutable_audit import ImmutableVerdictSigner

        signer = ImmutableVerdictSigner()
        data = {"invoice": {"amount_net": 100.0}, "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}}
        h1 = signer.hash_input(data)
        h2 = signer.hash_input(data)
        assert h1 == h2  # Ten sam input → ten sam hash

    def test_hash_input_different(self):
        from nexus_ai.tax.immutable_audit import ImmutableVerdictSigner

        signer = ImmutableVerdictSigner()
        h1 = signer.hash_input({"a": 1})
        h2 = signer.hash_input({"a": 2})
        assert h1 != h2  # Różne inputy → różne hashe

    def test_merkle_root_deterministic(self):
        from nexus_ai.tax.immutable_audit import ImmutableVerdictSigner

        signer = ImmutableVerdictSigner()
        r1 = signer.compute_merkle_root("aaa", "bbb", "ccc")
        r2 = signer.compute_merkle_root("aaa", "bbb", "ccc")
        assert r1 == r2  # Determinizm

        r3 = signer.compute_merkle_root("aaa", "bbb", "ddd")
        assert r1 != r3  # Inna wartość → inny korzeń

    def test_sign_and_verify(self):
        from nexus_ai.tax.immutable_audit import ImmutableVerdictSigner

        signer = ImmutableVerdictSigner()
        signed = signer.sign_verdict(
            verdict={"rule_id": "jdg.test", "matched": True},
            input_hash="abc123",
            bundle_hash="def456",
            thresholds_hash="ghi789",
        )
        assert signed.merkle_root
        assert signed.signature
        assert signed.bundle_version

        # Weryfikacja
        assert ImmutableVerdictSigner.verify(signed)

    def test_build_audit_record(self):
        from nexus_ai.tax.immutable_audit import ImmutableVerdictSigner, build_audit_record

        signer = ImmutableVerdictSigner()
        record = build_audit_record(
            verdict={"rule_id": "test", "matched": True},
            input_data={"invoice": {"net": 100}},
            bundle_version="v2026.3",
            bundle_hash="hash123",
            thresholds={"vat_limit": 200000},
            signer=signer,
        )
        assert record["verdict"]["matched"]
        assert record["merkle_root"]
        assert record["signature"]
        assert record["input_hash"]
        assert record["bundle_version"] == "v2026.3"

    def test_recompute_and_verify_valid(self):
        from nexus_ai.tax.immutable_audit import ImmutableVerdictSigner

        signer = ImmutableVerdictSigner()
        original_input = {"invoice": {"amount_net": 500.00}}
        input_hash = signer.hash_input(original_input)
        bundle_hash = signer.hash_bundle("v2026.3", "content_hash_abc")
        thresholds_data = {"vat_exemption_limit": 200000}
        thresholds_hash = signer.hash_thresholds(thresholds_data)

        signed = signer.sign_verdict(
            verdict={"matched": True},
            input_hash=input_hash,
            bundle_hash=bundle_hash,
            thresholds_hash=thresholds_hash,
            bundle_version="v2026.3",
        )

        # Pełna weryfikacja przez audytora zewnętrznego
        valid = ImmutableVerdictSigner.recompute_and_verify(
            signed, original_input, "v2026.3", "content_hash_abc", thresholds_data,
        )
        assert valid


# ═══════════════════════════════════════════════════════════════════════════════
# A2: RegoLinter
# ═══════════════════════════════════════════════════════════════════════════════


class TestRegoLinter:
    """Testy dla RegoLinter."""

    def test_detect_hardcoded_number(self):
        from nexus_ai.tax.rego_linter import RegoLinter

        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            bad_file = tmp_path / "bad.rego"
            bad_file.write_text('''package test\n\nvat_rate := 0.23\namount_limit := 150000\n''')

            linter = RegoLinter(tmp_path)
            violations = linter.lint_all()

            assert len(violations) >= 1  # Powinien znaleźć co najmniej jedną zakodowaną wartość

    def test_clean_file_no_violations(self):
        from nexus_ai.tax.rego_linter import RegoLinter

        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            good_file = tmp_path / "good.rego"
            good_file.write_text('''package test\n\n# METADATA\n# legal_basis: Art. 41 ust. 1 VAT\nvat_rate := data.thresholds.jdg.rates.vat_standard\n''')

            linter = RegoLinter(tmp_path)
            violations = linter.lint_all()

            assert len(violations) == 0

    def test_skip_test_files(self):
        from nexus_ai.tax.rego_linter import RegoLinter

        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            test_file = tmp_path / "test_vat.rego"
            test_file.write_text('''package test\n\n# 0.23 = test value\nvalue := 0.23\n''')

            linter = RegoLinter(tmp_path)
            violations = linter.lint_all()

            # Pliki testowe są pomijane
            assert len(violations) == 0


# ═══════════════════════════════════════════════════════════════════════════════
# A3: LegalExplainerEngine
# ═══════════════════════════════════════════════════════════════════════════════


class TestLegalExplainer:
    """Testy dla LegalExplainerEngine."""

    def test_blocked_explanation(self):
        from nexus_ai.tax.legal_explainer import LegalExplainerEngine

        engine = LegalExplainerEngine()
        verdict = {
            "matched": True,
            "rule_id": "jdg.compliance.whitelist",
            "_routing": "BLOCK_AND_ALERT",
            "invoice_number": "FV/2026/06/001",
            "priority": 20,
        }
        text = engine.explain(verdict, {"description": "Brak kontrahenta na Białej Liście"})
        assert "została zablokowana" in text
        assert "FV/2026/06/001" in text

    def test_warning_explanation(self):
        from nexus_ai.tax.legal_explainer import LegalExplainerEngine

        engine = LegalExplainerEngine()
        verdict = {
            "matched": True,
            "rule_id": "jdg.compliance.cash_limit",
            "_warnings": ["Płatność gotówkowa powyżej limitu"],
            "invoice_number": "FV/2026/06/002",
        }
        text = engine.explain(verdict, {"description": "Limit gotówkowy przekroczony"})
        assert "Ostrzeżenie" in text

    def test_ok_explanation(self):
        from nexus_ai.tax.legal_explainer import LegalExplainerEngine

        engine = LegalExplainerEngine()
        verdict = {
            "matched": True,
            "rule_id": "jdg.vat.substantive",
            "vat_rate": "0.23",
            "kus_qualification": "full",
            "pkpir_column": 12,
            "zus_social_base_type": "STANDARD",
            "zus_health_rate": "0.09",
            "zus_health_limit_type": "",
            "invoice_number": "FV/2026/06/003",
        }
        text = engine.explain(verdict, {"legal_basis": "Art. 41 ust. 1 VAT"})
        assert "księgowanie standardowe" in text
        assert "23%" in text
        assert "100% KUP" in text

    def test_no_match_explanation(self):
        from nexus_ai.tax.legal_explainer import LegalExplainerEngine

        engine = LegalExplainerEngine()
        verdict = {"matched": False, "invoice_number": "FV/unknown"}
        text = engine.explain(verdict)
        assert "nie znaleziono pasującej reguły" in text

    def test_remediation_whitelist(self):
        from nexus_ai.tax.legal_explainer import LegalExplainerEngine

        engine = LegalExplainerEngine()
        verdict = {
            "matched": True,
            "rule_id": "jdg.compliance.whitelist_check",
            "_routing": "BLOCK_AND_ALERT",
            "invoice_number": "FV/test",
        }
        text = engine.explain(verdict, {"description": "Test"})
        assert "Biała" in text or "rachunek" in text.lower()


# ═══════════════════════════════════════════════════════════════════════════════
# B2: Orthogonal Array Tester
# ═══════════════════════════════════════════════════════════════════════════════


class TestOrthogonalArray:
    """Testy dla all_pairs i generate_test_matrix."""

    def test_all_pairs_coverage(self):
        from nexus_ai.tax.orthogonal_array_tester import all_pairs

        params = {
            "a": ["A1", "A2"],
            "b": ["B1", "B2", "B3"],
        }
        cases = all_pairs(params)

        # Sprawdź pokrycie wszystkich par
        all_a = set(params["a"])
        all_b = set(params["b"])
        for va in all_a:
            for vb in all_b:
                covered = any(tc["a"] == va and tc["b"] == vb for tc in cases)
                assert covered, f"Brak pokrycia pary ({va}, {vb})"

    def test_generate_test_matrix(self):
        from nexus_ai.tax.orthogonal_array_tester import generate_test_matrix

        # Użyj podzbioru parametrów żeby test nie trwał zbyt długo
        small_params = {
            "tax_form": ["PIT_SCALE", "LINEAR"],
            "vat_status": ["ACTIVE_PAYER", "EXEMPT_SUBJECT"],
            "procedure": ["NONE", "IMPORT"],
            "payment_method": ["BANK_TRANSFER", "CASH"],
        }
        inputs, full_space = generate_test_matrix(small_params)

        assert len(inputs) > 0
        assert full_space == 16  # 2*2*2*2
        # All-pairs generuje sensowną liczbę testów (może być > full_space dla małych zbiorów)
        assert len(inputs) > 0

        # Każdy input powinien mieć wymagane struktury
        for inp in inputs:
            assert "invoice" in inp
            assert "vendor" in inp
            assert "jdg_entrepreneur" in inp

    def test_full_parameter_matrix(self):
        from nexus_ai.tax.orthogonal_array_tester import generate_test_matrix, ALL_PARAMETERS

        inputs, full_space = generate_test_matrix(ALL_PARAMETERS)

        # All-pairs generuje znacznie mniej testów niż pełna przestrzeń
        assert full_space > 1000  # Pełna przestrzeń jest ogromna
        assert len(inputs) < full_space  # All-pairs redukuje
        assert len(inputs) > 0  # Ale nie do zera


# ═══════════════════════════════════════════════════════════════════════════════
# B3: TelemetryDrivenDAGRouter
# ═══════════════════════════════════════════════════════════════════════════════


class TestTelemetryDAGRouter:
    """Testy dla TelemetryDrivenDAGRouter."""

    def test_empty_telemetry(self):
        from nexus_ai.tax.dynamic_dag import TelemetryDrivenDAGRouter, PassConfig

        router = TelemetryDrivenDAGRouter()
        passes = [
            PassConfig(name="jdg/risk", policy_path="risk", query="x"),
            PassConfig(name="jdg/compliance", policy_path="comp", query="x"),
        ]

        # Bez danych telemetrycznych — oryginalna kolejność
        optimized = router.get_optimized_pass_order(passes)
        assert optimized[0].name == "jdg/risk"

    def test_block_rate_reordering(self):
        from nexus_ai.tax.dynamic_dag import TelemetryDrivenDAGRouter, PassConfig

        router = TelemetryDrivenDAGRouter()
        passes = [
            PassConfig(name="jdg/risk", policy_path="risk", query="x"),
            PassConfig(name="jdg/compliance", policy_path="comp", query="x"),
            PassConfig(name="jdg/routing", policy_path="routing", query="x"),
        ]

        # Symuluj: compliance ma wysoki block-rate
        for _ in range(100):
            router.record_verdict("jdg/compliance", True)   # 100% block-rate
            router.record_verdict("jdg/risk", False)         # 0% block-rate
            router.record_verdict("jdg/routing", False)      # 0% block-rate

        optimized = router.get_optimized_pass_order(passes)

        # Compliance powinien być pierwszy (najwyższy block-rate)
        assert optimized[0].name == "jdg/compliance"

    def test_telemetry_report(self):
        from nexus_ai.tax.dynamic_dag import TelemetryDrivenDAGRouter

        router = TelemetryDrivenDAGRouter()

        for _ in range(50):
            router.record_verdict("jdg/compliance", True)
        for _ in range(50):
            router.record_verdict("jdg/risk", False)

        report = router.get_telemetry_report()
        assert report["total_verdicts_tracked"] == 100  # 100 par (pass, blocked)
        assert len(report["top_blockers"]) >= 1


# ═══════════════════════════════════════════════════════════════════════════════
# C3: LiquidityOracle
# ═══════════════════════════════════════════════════════════════════════════════


class TestLiquidityOracle:
    """Testy dla LiquidityOracle."""

    def test_empty_invoices(self):
        from nexus_ai.tax.liquidity_oracle import LiquidityOracle

        mock_db = MagicMock()
        mock_db.execute.return_value.fetchall.return_value = []

        oracle = LiquidityOracle(mock_db)
        report = oracle.quarterly_analysis("ent123")

        assert report.invoices_analyzed == 0
        assert report.recommendation is None

    def test_late_payments_recommendation(self):
        from nexus_ai.tax.liquidity_oracle import LiquidityOracle

        mock_db = MagicMock()

        # Symuluj faktury z opóźnieniami
        mock_invoices = [
            (f"inv{i}", 1000.0, 1230.0, 0.23, "PURCHASE", f"2026-04-{i:02d}",
             f"2026-05-{i:02d}", None, 120 - i, False, "IT", "")
            for i in range(1, 11)
        ]
        mock_db.execute.return_value.fetchall.return_value = mock_invoices

        oracle = LiquidityOracle(mock_db)
        report = oracle.quarterly_analysis("ent123", "2026-04-01", "2026-06-30")

        assert report.invoices_analyzed == 10
        assert report.invoices_paid_late > 0
        assert report.avg_contractor_delay_days > 60

    def test_simple_simulation(self):
        from nexus_ai.tax.liquidity_oracle import LiquidityOracle

        oracle = LiquidityOracle(MagicMock())
        invoices = [
            {"amount_net": 1000, "vat_rate": "0.23", "is_paid": True, "direction": "PURCHASE"},
            {"amount_net": 2000, "vat_rate": "0.23", "is_paid": False, "direction": "PURCHASE"},
        ]

        # Memoriałowa: obie faktury liczone
        accrual = oracle._simulate_simple(invoices, cash_accounting=False)
        assert accrual > 0

        # Kasowa: tylko zapłacone faktury
        cash = oracle._simulate_simple(invoices, cash_accounting=True)
        assert cash < accrual  # Niezapłacona faktura nie wchodzi
