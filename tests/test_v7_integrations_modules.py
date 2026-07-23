"""
Testy dla modułów v7.0 INTEGRACJE ZEWNĘTRZNE.

Testowane moduły:
- NbpFxClient (real httpx z mockowanym API)
- MT940StatementParser (warunkowo — skip jeśli import chain zawiedzie)
- KsefPreSendValidator + Cross-Source Vendor Verification
- WhiteListProactiveMonitor
- BankReconciliationAI
- NbpRatePredictor + SmartRetryScheduler
- RegulatoryChangeDetector
"""

from __future__ import annotations

import pytest
from decimal import Decimal
from datetime import date
from pathlib import Path


# ═════════════════════════════════════════════════════════════════════════════
# NbpFxClient
# ═════════════════════════════════════════════════════════════════════════════

class TestNbpFxClient:
    """Testy NbpFxClient — v7.0 real API z mockiem."""

    def test_cache_invalidation(self):
        from nexus_ai.tax.nbp_client import NbpFxClient, FxRate
        import time
        client = NbpFxClient()
        client._cache["EUR:2026-07-01"] = FxRate(
            currency="EUR", rate=4.50, date="2026-07-01",
            source="NBP_TABLE_A", fetched_at=time.time(),
        )
        assert len(client._cache) == 1
        client.invalidate_cache()
        assert len(client._cache) == 0

    def test_get_cached_rate_expired(self):
        from nexus_ai.tax.nbp_client import NbpFxClient, FxRate
        import time
        client = NbpFxClient()
        client._cache["EUR:2026-06-01"] = FxRate(
            currency="EUR", rate=4.50, date="2026-06-01",
            source="NBP_TABLE_A", fetched_at=0,
        )
        result = client.get_cached_rate("EUR", "2026-06-01")
        assert result is None

    def test_convert_to_pln_pln(self):
        from nexus_ai.tax.nbp_client import NbpFxClient
        import asyncio
        async def _test():
            client = NbpFxClient()
            result = await client.convert_to_pln(100.0, "PLN", "2026-07-01")
            assert result == 100.0
        asyncio.run(_test())

    def test_last_business_day_weekend(self):
        from nexus_ai.tax.nbp_client import NbpFxClient
        result = NbpFxClient._last_business_day("2026-07-12")
        assert result == "2026-07-10"

    def test_last_business_day_holiday(self):
        from nexus_ai.tax.nbp_client import NbpFxClient
        result = NbpFxClient._last_business_day("2026-01-01")
        assert result == "2025-12-31"

    def test_nbp_available_default(self):
        from nexus_ai.tax.nbp_client import NbpFxClient
        client = NbpFxClient()
        assert client.is_nbp_available is True

    def test_close_owned_client(self):
        import asyncio
        from nexus_ai.tax.nbp_client import NbpFxClient
        async def _test():
            client = NbpFxClient()
            await client.close()
            assert client._http is None
        asyncio.run(_test())


# ═════════════════════════════════════════════════════════════════════════════
# MT940 Parser (warunkowo — import chain TigerBeetle → SQLAlchemy może fail)
# ═════════════════════════════════════════════════════════════════════════════

try:
    from nexus_ai.services.mt940_parser import MT940StatementParser, _parse_mt940_date, _parse_amount, register_mt940_parsers  # noqa: F401
    _MT940_AVAILABLE = True
except Exception:
    _MT940_AVAILABLE = False


@pytest.mark.skipif(not _MT940_AVAILABLE, reason="MT940 parser import chain requires TigerBeetle/SQLAlchemy")
class TestMT940Parser:
    """Testy MT940StatementParser."""

    SAMPLE_MT940 = """:20:REF123456
:25:PL1234567890/1234567890
:28C:1
:60F:C260701PLN10000,00
:61:2607020702CR50,00NTRFREF98765432//PAY001
Company Payment
:86:/ORDP/ACME Corp
~20Faktura FV/2026/001
~21za usługi IT
:62F:C260702PLN10050,00"""

    def test_parse_basic_mt940(self):
        from nexus_ai.services.mt940_parser import MT940StatementParser
        import tempfile
        parser = MT940StatementParser()
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".sta", delete=False, encoding="utf-8",
        ) as f:
            f.write(self.SAMPLE_MT940)
            f.flush()
            path = Path(f.name)
        try:
            transactions = parser.parse(path)
            assert len(transactions) >= 1
            tx = transactions[0]
            assert tx.amount > 0
            assert "Faktura" in tx.title or "ACME" in tx.title
        finally:
            path.unlink(missing_ok=True)

    def test_parse_mt940_date(self):
        from nexus_ai.services.mt940_parser import _parse_mt940_date
        result = _parse_mt940_date("260702")
        assert result == date(2026, 7, 2)

    def test_parse_amount(self):
        from nexus_ai.services.mt940_parser import _parse_amount
        assert _parse_amount("100,50") == Decimal("100.50")
        assert _parse_amount("10000,00") == Decimal("10000.00")

    def test_extract_counterparty_iban(self):
        from nexus_ai.services.mt940_parser import MT940StatementParser
        result = MT940StatementParser._extract_counterparty(
            "PL12345678901234567890123456/ORDP/Test"
        )
        assert result == "PL12345678901234567890123456"

    def test_register_mt940_parsers(self):
        from nexus_ai.services.mt940_parser import register_mt940_parsers
        from nexus_ai.services.bank_import import ParserFactory
        register_mt940_parsers()
        parser = ParserFactory.get_parser(Path("test.mt940"))
        assert parser is not None


# ═════════════════════════════════════════════════════════════════════════════
# KSeF Pre-Send Validator
# ═════════════════════════════════════════════════════════════════════════════

class TestKsefPreSendValidator:
    """Testy KSeF Pre-Send Validator."""

    @pytest.fixture
    def valid_invoice(self):
        return {
            "invoice_id": "INV-001",
            "invoice_number": "FV/2026/001",
            "transaction_date": "2026-07-15",
            "amount_net_grosze": 10000,
            "amount_vat_grosze": 2300,
            "vendor": {"nip": "1234567890", "name": "Sprzedawca Sp. z o.o."},
            "buyer": {"nip": "0987654321", "name": "Nabywca SA", "bank_account": "PL1234567890"},
            "vat_rate": 23,
            "gtu_code": "GTU_01",
            "category_code": "IT_OFFICE",
        }

    def test_valid_invoice_passes(self, valid_invoice):
        from nexus_ai.services.ksef_presend_validator import KsefPreSendValidator
        import asyncio
        async def _test():
            validator = KsefPreSendValidator()
            result = await validator.validate(valid_invoice)
            assert result.is_valid
            assert len(result.errors) == 0
            assert result.mandatory_fields_ok
            assert result.nip_valid
        asyncio.run(_test())

    def test_missing_mandatory_field(self, valid_invoice):
        from nexus_ai.services.ksef_presend_validator import KsefPreSendValidator
        import asyncio
        async def _test():
            validator = KsefPreSendValidator()
            invalid = {**valid_invoice, "invoice_number": ""}
            result = await validator.validate(invalid)
            assert not result.mandatory_fields_ok
            assert len(result.errors) > 0
        asyncio.run(_test())

    def test_invalid_nip_length(self, valid_invoice):
        from nexus_ai.services.ksef_presend_validator import KsefPreSendValidator
        import asyncio
        async def _test():
            validator = KsefPreSendValidator()
            invalid = {**valid_invoice, "buyer": {"nip": "123", "name": "Test"}}
            result = await validator.validate(invalid)
            assert not result.nip_valid
            assert any("długość" in e.lower() for e in result.errors)
        asyncio.run(_test())

    def test_gtu_for_category(self, valid_invoice):
        from nexus_ai.services.ksef_presend_validator import KsefPreSendValidator
        import asyncio
        async def _test():
            validator = KsefPreSendValidator()
            result = await validator.validate(valid_invoice)
            assert result.gtu_valid
        asyncio.run(_test())

    def test_wrong_gtu_for_category(self, valid_invoice):
        from nexus_ai.services.ksef_presend_validator import KsefPreSendValidator
        import asyncio
        async def _test():
            validator = KsefPreSendValidator()
            wrong = {**valid_invoice, "gtu_code": "GTU_12"}
            result = await validator.validate(wrong)
            assert not result.gtu_valid
        asyncio.run(_test())

    def test_get_nested(self):
        from nexus_ai.services.ksef_presend_validator import KsefPreSendValidator
        data = {"a": {"b": {"c": "value"}}}
        assert KsefPreSendValidator._get_nested(data, "a.b.c") == "value"
        assert KsefPreSendValidator._get_nested(data, "a.x.y", "default") == "default"


# ═════════════════════════════════════════════════════════════════════════════
# WhiteList Proactive Monitor
# ═════════════════════════════════════════════════════════════════════════════

class TestWhiteListProactiveMonitor:
    """Testy WhiteListProactiveMonitor."""

    def test_snapshot_creation(self):
        from nexus_ai.services.proactive_monitor import WhitelistSnapshot
        snap = WhitelistSnapshot(
            nip="1234567890", name="Test Corp", vat_status="active",
            account_numbers=["PL1234567890"], last_checked="2026-07-15",
        )
        assert snap.vat_status == "active"
        assert len(snap.account_numbers) == 1

    def test_payment_blocked_initial(self):
        from nexus_ai.services.proactive_monitor import WhiteListProactiveMonitor
        monitor = WhiteListProactiveMonitor()
        assert not monitor.is_payment_blocked("1234567890")

    def test_unblock_payment(self):
        from nexus_ai.services.proactive_monitor import WhiteListProactiveMonitor
        monitor = WhiteListProactiveMonitor()
        monitor._blocked_payments.add("1234567890")
        assert monitor.is_payment_blocked("1234567890")
        monitor.unblock_payment("1234567890")
        assert not monitor.is_payment_blocked("1234567890")


# ═════════════════════════════════════════════════════════════════════════════
# Bank Reconciliation AI
# ═════════════════════════════════════════════════════════════════════════════

class TestBankReconciliationAI:
    """Testy BankReconciliationAI."""

    def test_exact_amount_match(self):
        from nexus_ai.services.proactive_monitor import BankReconciliationAI
        ai = BankReconciliationAI()
        transactions = [
            {"id": "tx1", "amount": 1230.00, "title": "FV/2026/001", "counterparty_nip": "1234567890"},
        ]
        invoices = [
            {"id": "inv1", "number": "FV/2026/001", "amount_gross": 1230.00, "contractor_nip": "1234567890"},
        ]
        matches = ai.reconcile(transactions, invoices)
        assert len(matches) >= 1
        assert matches[0].confidence >= 90.0

    def test_no_match(self):
        from nexus_ai.services.proactive_monitor import BankReconciliationAI
        ai = BankReconciliationAI()
        transactions = [
            {"id": "tx1", "amount": 100.00, "title": "test", "counterparty_nip": "1111111111"},
        ]
        invoices = [
            {"id": "inv1", "number": "FV/999", "amount_gross": 99999.00, "contractor_nip": "9999999999"},
        ]
        matches = ai.reconcile(transactions, invoices)
        suggestions = ai.get_suggestions(matches)
        assert len(suggestions) == 0

    def test_fuzzy_title_match(self):
        from nexus_ai.services.proactive_monitor import BankReconciliationAI
        ai = BankReconciliationAI()
        score = ai._fuzzy_match_title("Przelew za fakturę FV/2026/042", "FV/2026/042")
        assert score >= 25.0

    def test_auto_book_threshold(self):
        from nexus_ai.services.proactive_monitor import BankReconciliationAI
        ai = BankReconciliationAI()
        transactions = [
            {"id": "tx1", "amount": 5000.00, "title": "FV/2026/001", "counterparty_nip": "1234567890"},
        ]
        invoices = [
            {"id": "inv1", "number": "FV/2026/001", "amount_gross": 5000.00, "contractor_nip": "1234567890"},
        ]
        matches = ai.reconcile(transactions, invoices)
        auto = ai.get_auto_bookable(matches)
        assert len(auto) >= 1

    def test_amount_within_tolerance(self):
        from nexus_ai.services.proactive_monitor import BankReconciliationAI
        ai = BankReconciliationAI()
        transactions = [
            {"id": "tx1", "amount": 1010.00, "title": "FV/2026/001", "counterparty_nip": "1234567890"},
        ]
        invoices = [
            {"id": "inv1", "number": "FV/2026/001", "amount_gross": 1000.00, "contractor_nip": "1234567890"},
        ]
        matches = ai.reconcile(transactions, invoices)
        assert len(matches) >= 1
        assert matches[0].confidence >= 60.0


# ═════════════════════════════════════════════════════════════════════════════
# NBP Rate Predictor + Smart Retry Scheduler
# ═════════════════════════════════════════════════════════════════════════════

class TestNbpRatePredictor:
    """Testy NbpRatePredictor."""

    def test_predict_with_data(self):
        from nexus_ai.services.rate_predictor import NbpRatePredictor
        predictor = NbpRatePredictor()
        for i in range(10):
            predictor.add_rate("EUR", f"2026-07-{i+1:02d}", 4.50 + i * 0.01, "NBP")
        pred = predictor.predict("EUR")
        assert pred.currency == "EUR"
        assert pred.predicted_rate > 0
        assert pred.confidence_interval[0] < pred.confidence_interval[1]
        assert pred.trend in ("up", "down", "stable")

    def test_anomaly_detection(self):
        from nexus_ai.services.rate_predictor import NbpRatePredictor
        import random
        predictor = NbpRatePredictor()
        random.seed(42)
        for i in range(30):
            predictor.add_rate("EUR", f"2026-06-{i+1:02d}", 4.50 + random.uniform(-0.02, 0.02), "NBP")
        alert = predictor.check_anomaly_alert("EUR", 5.50)
        assert alert is not None, f"Expected anomaly alert for rate 5.50"
        assert alert["severity"] in ("high", "medium")

    def test_no_anomaly(self):
        from nexus_ai.services.rate_predictor import NbpRatePredictor
        predictor = NbpRatePredictor()
        for i in range(10):
            predictor.add_rate("EUR", f"2026-07-{i+1:02d}", 4.50, "NBP")
        alert = predictor.check_anomaly_alert("EUR", 4.50)
        assert alert is None

    def test_optimal_transaction_day(self):
        from nexus_ai.services.rate_predictor import NbpRatePredictor
        predictor = NbpRatePredictor()
        for i in range(30):
            predictor.add_rate("EUR", f"2026-06-{i+1:02d}", 4.50 + 0.01 * (15 - abs(i - 15)), "NBP")
        days = predictor.get_optimal_transaction_day("EUR", days_ahead=3)
        assert len(days) >= 1
        assert "predicted_rate" in days[0]


class TestSmartRetryScheduler:
    """Testy SmartRetryScheduler."""

    def test_default_retry_config(self):
        from nexus_ai.services.rate_predictor import SmartRetryScheduler
        scheduler = SmartRetryScheduler()
        config = scheduler.get_retry_config("ksef")
        assert config["attempts"] >= 1
        assert config["delay_seconds"] > 0
        assert config["timeout"] > 0

    def test_critical_query_more_attempts(self):
        from nexus_ai.services.rate_predictor import SmartRetryScheduler
        scheduler = SmartRetryScheduler()
        normal = scheduler.get_retry_config("ksef", is_critical=False)
        critical = scheduler.get_retry_config("ksef", is_critical=True)
        assert critical["attempts"] >= normal["attempts"]

    def test_record_result_updates_profile(self):
        from nexus_ai.services.rate_predictor import SmartRetryScheduler
        scheduler = SmartRetryScheduler()
        for _ in range(10):
            scheduler.record_result("ksef", True, 500.0)
        profile = scheduler.get_profile("ksef")
        assert profile is not None
        assert profile.success_rate_24h > 95.0

    def test_record_failure_decreases_rate(self):
        from nexus_ai.services.rate_predictor import SmartRetryScheduler
        scheduler = SmartRetryScheduler()
        for _ in range(10):
            scheduler.record_result("white_list", True, 200.0)
        scheduler.record_result("white_list", False, 10000.0)
        profile = scheduler.get_profile("white_list")
        assert profile is not None
        assert profile.success_rate_24h < 100.0


# ═════════════════════════════════════════════════════════════════════════════
# Regulatory Change Detector
# ═════════════════════════════════════════════════════════════════════════════

class TestRegulatoryChangeDetector:
    """Testy RegulatoryChangeDetector."""

    def test_severity_assessment_critical(self):
        from nexus_ai.services.regulatory_change_detector import RegulatoryChangeDetector, SchemaDiff
        diff = SchemaDiff(added_elements=["NewField"], removed_elements=[], changed_elements=[], added_attributes=[], removed_attributes=[])
        severity = RegulatoryChangeDetector._assess_severity("ksef", "FA_VAT XSD", diff)
        assert severity == "critical"

    def test_severity_assessment_low(self):
        from nexus_ai.services.regulatory_change_detector import RegulatoryChangeDetector, SchemaDiff
        diff = SchemaDiff(added_elements=[], removed_elements=[], changed_elements=[], added_attributes=[], removed_attributes=[])
        severity = RegulatoryChangeDetector._assess_severity("nbp", "NBP API Docs", diff)
        assert severity == "low"

    def test_effort_estimation_ksef(self):
        from nexus_ai.services.regulatory_change_detector import RegulatoryChangeDetector, SchemaDiff
        diff = SchemaDiff(added_elements=["F1", "F2", "F3"], removed_elements=[], changed_elements=[], added_attributes=[], removed_attributes=[])
        effort = RegulatoryChangeDetector._estimate_effort("ksef", diff)
        assert effort >= 5.0

    def test_classify_change_field_added(self):
        from nexus_ai.services.regulatory_change_detector import RegulatoryChangeDetector, SchemaDiff
        diff = SchemaDiff(added_elements=["NewField"], removed_elements=[], changed_elements=[], added_attributes=[], removed_attributes=[])
        assert RegulatoryChangeDetector._classify_change(diff) == "field_added"

    def test_classify_change_no_diff(self):
        from nexus_ai.services.regulatory_change_detector import RegulatoryChangeDetector
        assert RegulatoryChangeDetector._classify_change(None) == "content_changed"

    def test_determine_action_critical(self):
        from nexus_ai.services.regulatory_change_detector import RegulatoryChangeDetector
        assert RegulatoryChangeDetector._determine_action("critical") == "update_schema"

    def test_get_pending_actions(self):
        from nexus_ai.services.regulatory_change_detector import RegulatoryChangeDetector, RegulatoryChange
        detector = RegulatoryChangeDetector()
        detector._changes = [
            RegulatoryChange(id="1", integration="ksef", change_type="field_added", description="test", severity="critical", detected_at="2026-07-01", source_url="http://test", action_required="update_schema"),
            RegulatoryChange(id="2", integration="nbp", change_type="content_changed", description="test", severity="low", detected_at="2026-07-01", source_url="http://test", action_required="monitor_only"),
        ]
        pending = detector.get_pending_actions()
        assert len(pending) == 1
        assert pending[0].id == "1"
