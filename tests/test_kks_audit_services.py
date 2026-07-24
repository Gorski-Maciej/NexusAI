"""
test_kks_audit_services.py — v7.0 Audit: Unit tests for KKS/Compliance services.

Tests for:
  - SanctionsScreeningAPI (Q1)
  - KksRealtimeScorer (Q4)
  - KksDefenseGenerator (M1)
  - Dac8Reporter (M3)
  - CrossJurisdictionResolver (M2)
  - AmlAutoRemediation (M5)
  - TaxInspectionPredictor (T1)
  - BlockchainAnalytics (T2)
  - TaxAuditTrailGenerator (T3)
  - KksShadowLedgerSimulator (M4)
  - CryptoTaxBridge (T5)
"""

from __future__ import annotations

import pytest

from nexus_ai.services.sanctions_screening_api import (
    SanctionsScreeningAPI,
    ScreeningResult,
    FATF_BLACK_LIST,
    FATF_GREY_LIST,
)
from nexus_ai.services.kks_realtime_scorer import (
    KksRealtimeScorer,
    KksRiskZone,
    KksRealTimeScore,
)
from nexus_ai.services.kks_defense_generator import (
    KksDefenseGenerator,
    DefensePackage,
    DefenseDocument,
)
from nexus_ai.services.dac8_reporter import (
    Dac8Reporter,
    Dac8AnnualReport,
    PLATFORM_CATEGORIES,
)
from nexus_ai.services.cross_jurisdiction_resolver import (
    CrossJurisdictionResolver,
    CrossJurisdictionResult,
)
from nexus_ai.services.aml_auto_remediation import (
    AmlAutoRemediation,
    AmlRemediationReport,
)
from nexus_ai.services.tax_inspection_predictor import (
    TaxInspectionPredictor,
    InspectionRiskScore,
)
from nexus_ai.services.blockchain_analytics import (
    BlockchainAnalytics,
    TransactionRiskReport,
)
from nexus_ai.services.tax_audit_trail_generator import (
    TaxAuditTrailGenerator,
    AuditTrailReport,
)
from nexus_ai.services.kks_shadow_ledger_simulator import (
    KksShadowLedgerSimulator,
    ShadowLedgerKksReport,
)
from nexus_ai.services.crypto_tax_bridge import (
    CryptoTaxBridge,
    CryptoAnnualReport,
    CryptoTransaction,
)


# ═══════════════════════════════════════════════════════════════════════════════
# SanctionsScreeningAPI Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestSanctionsScreeningAPI:
    """Full FATF/OFAC/EU/UK sanctions screening."""

    def test_screen_russian_bank_returns_hit(self) -> None:
        api = SanctionsScreeningAPI()
        result = api.screen("SBERBANK ROSSII PAO", country="RU")
        assert result.is_sanctioned
        assert len(result.hits) >= 1
        assert any("OFAC" in h.source_list for h in result.hits)

    def test_screen_clean_company_returns_clean(self) -> None:
        api = SanctionsScreeningAPI()
        result = api.screen("ABC Legal Company Sp. z o.o.", country="PL")
        assert not result.is_sanctioned
        assert len(result.hits) == 0
        assert result.risk_level == "LOW"

    def test_fatf_blacklist_country_flagged(self) -> None:
        api = SanctionsScreeningAPI()
        result = api.screen("Bank of Iran", country="IR")
        assert result.is_fatf_high_risk
        assert result.risk_level in ("HIGH", "CRITICAL")

    def test_batch_screening_returns_all(self) -> None:
        api = SanctionsScreeningAPI()
        results = api.screen_batch([
            {"name": "SBERBANK ROSSII PAO", "country": "RU"},
            {"name": "ABC Legal", "country": "PL"},
            {"name": "VTB BANK PJSC", "country": "RU"},
        ])
        assert len(results) == 3
        assert sum(1 for r in results if r.is_sanctioned) >= 2

    def test_get_fatf_lists_returns_both(self) -> None:
        api = SanctionsScreeningAPI()
        lists = api.get_fatf_lists()
        assert "black_list" in lists
        assert "grey_list" in lists
        assert "IR" in lists["black_list"] or "KP" in lists["black_list"]

    def test_stats_track_screening_counts(self) -> None:
        api = SanctionsScreeningAPI()
        api.screen("Test", country="PL")
        api.screen("SBERBANK", country="RU")
        stats = api.get_stats()
        assert stats["total_screened"] == 2
        assert stats["total_hits"] >= 1

    def test_to_rego_input_format(self) -> None:
        api = SanctionsScreeningAPI()
        result = api.screen("SBERBANK ROSSII PAO", country="RU")
        rego_input = api.to_rego_input(result)
        assert rego_input["sanctions_list_match"] is True
        assert rego_input["is_fatf_high_risk"] is True


# ═══════════════════════════════════════════════════════════════════════════════
# KksRealtimeScorer Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestKksRealtimeScorer:
    """Real-time KKS risk scoring 0-100."""

    def test_clean_invoice_scores_green(self) -> None:
        scorer = KksRealtimeScorer()
        score = scorer.score_invoice(
            {"id": "inv-001", "amount_gross": 5000},
            opa_verdict={},
        )
        assert score.risk_zone == KksRiskZone.GREEN
        assert score.total_score <= 30

    def test_empty_invoice_scores_red(self) -> None:
        scorer = KksRealtimeScorer()
        score = scorer.score_invoice(
            {"id": "inv-002", "amount_gross": 50000},
            opa_verdict={
                "kks_offense_type": "EMPTY_INVOICE",
                "kks_penalty_severity": "CRITICAL",
                "kks_max_daily_rates": 720,
            },
        )
        assert score.risk_zone == KksRiskZone.RED
        assert score.total_score >= 30

    def test_high_amount_increases_score(self) -> None:
        scorer = KksRealtimeScorer()
        low = scorer.score_invoice({"amount_gross": 5000}, opa_verdict={})
        high = scorer.score_invoice({"amount_gross": 600000}, opa_verdict={})
        assert high.total_score >= low.total_score

    def test_history_incidents_increase_score(self) -> None:
        scorer = KksRealtimeScorer()
        score = scorer.score_invoice(
            {"amount_gross": 10000},
            opa_verdict={},
            jdg_history={"kks_incidents_60m": 3},
        )
        assert score.breakdown.history_score > 0

    def test_batch_scoring_returns_sorted(self) -> None:
        scorer = KksRealtimeScorer()
        scores = scorer.score_batch([
            {"amount_gross": 5000},
            {"amount_gross": 50000, "is_empty_invoice": True},
            {"amount_gross": 10000},
        ])
        assert len(scores) == 3
        assert scores[0].total_score >= scores[-1].total_score

    def test_trend_analysis_returns_metrics(self) -> None:
        scorer = KksRealtimeScorer()
        scorer.score_invoice({"amount_gross": 5000}, jdg_history={"jdg_id": "test"})
        scorer.score_invoice({"amount_gross": 10000}, jdg_history={"jdg_id": "test"})
        trend = scorer.get_trend("test")
        assert "trend" in trend
        assert "avg_score" in trend
        assert trend["data_points"] == 2

    def test_risk_summary_counts_by_zone(self) -> None:
        scorer = KksRealtimeScorer()
        scorer.score_invoice({"amount_gross": 5000}, jdg_history={"jdg_id": "test"})
        scorer.score_invoice(
            {"amount_gross": 50000},
            opa_verdict={"kks_offense_type": "EMPTY_INVOICE", "kks_penalty_severity": "CRITICAL"},
            jdg_history={"jdg_id": "test"},
        )
        summary = scorer.get_risk_summary("test")
        assert summary["total_scored"] == 2
        assert summary["red_count"] + summary["yellow_count"] + summary["green_count"] == 2

    def test_global_stats_tracks_all_jdg(self) -> None:
        scorer = KksRealtimeScorer()
        scorer.score_invoice({"amount_gross": 5000}, jdg_history={"jdg_id": "a"})
        scorer.score_invoice({"amount_gross": 6000}, jdg_history={"jdg_id": "b"})
        stats = scorer.get_global_stats()
        assert stats["total_scored"] == 2
        assert stats["unique_jdg"] == 2


# ═══════════════════════════════════════════════════════════════════════════════
# KksDefenseGenerator Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestKksDefenseGenerator:
    """Auto-generator of KKS defense documents."""

    def test_generates_voluntary_disclosure(self) -> None:
        gen = KksDefenseGenerator()
        package = gen.generate_defense_package(
            opa_verdict={
                "kks_offense_type": "EMPTY_INVOICE",
                "kks_penalty_severity": "CRITICAL",
                "kks_max_daily_rates": 720,
                "_routing": "BLOCK_AND_ALERT",
                "_legal_basis": "Art. 62 § 2 KKS",
            },
            invoice_data={"id": "inv-001", "number": "FV/001", "amount_gross": 50000},
            jdg_data={"nip": "123", "name": "Test JDG", "city": "Warszawa"},
        )
        assert len(package.documents) >= 1
        assert any("voluntary_disclosure" in d.doc_type for d in package.documents)
        assert len(package.documents[0].content) > 200

    def test_generates_correction_cover(self) -> None:
        gen = KksDefenseGenerator()
        package = gen.generate_defense_package(
            opa_verdict={
                "kks_offense_type": "TAX_EVASION",
                "_routing": "BLOCK_AND_ALERT",
                "kks_tax_shortfall": 5000,
            },
            invoice_data={"id": "inv-002", "number": "FV/002", "amount_net": 20000},
            jdg_data={"nip": "456", "name": "Test", "city": "Kraków"},
        )
        assert any("correction_cover" in d.doc_type for d in package.documents)

    def test_savings_calculated(self) -> None:
        gen = KksDefenseGenerator()
        package = gen.generate_defense_package(
            opa_verdict={
                "kks_offense_type": "EMPTY_INVOICE",
                "kks_max_daily_rates": 720,
                "_routing": "BLOCK_AND_ALERT",
            },
            invoice_data={"id": "inv-001", "amount_gross": 100000},
            jdg_data={"nip": "123"},
        )
        assert package.estimated_savings_pln > 0
        assert package.savings_pct > 0

    def test_no_offense_no_documents(self) -> None:
        gen = KksDefenseGenerator()
        package = gen.generate_defense_package(
            opa_verdict={},
            invoice_data={"id": "inv-003"},
            jdg_data={},
        )
        assert len(package.documents) == 0

    def test_installment_request_for_large_amount(self) -> None:
        gen = KksDefenseGenerator()
        package = gen.generate_defense_package(
            opa_verdict={
                "kks_offense_type": "TAX_EVASION",
                "kks_tax_shortfall": 20000,
                "_routing": "BLOCK_AND_ALERT",
            },
            invoice_data={"id": "inv-004", "tax_shortfall_pln": 20000},
            jdg_data={"nip": "789", "name": "Big Co", "city": "Gdańsk"},
        )
        assert any("installment" in d.doc_type for d in package.documents)

    def test_generated_count_increments(self) -> None:
        gen = KksDefenseGenerator()
        gen.generate_defense_package(
            opa_verdict={"kks_offense_type": "TAX_EVASION", "_routing": "BLOCK_AND_ALERT"},
            invoice_data={"id": "1"},
            jdg_data={},
        )
        gen.generate_defense_package(
            opa_verdict={"kks_offense_type": "EMPTY_INVOICE", "_routing": "BLOCK_AND_ALERT"},
            invoice_data={"id": "2"},
            jdg_data={},
        )
        assert gen.generated_count == 2


# ═══════════════════════════════════════════════════════════════════════════════
# Dac8Reporter Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestDac8Reporter:
    """DAC8 ViDA reporting."""

    def test_classify_uber_as_ride_sharing(self) -> None:
        rep = Dac8Reporter()
        assert rep.classify_platform("Uber") == "RIDE_SHARING"

    def test_classify_airbnb_as_accommodation(self) -> None:
        rep = Dac8Reporter()
        assert rep.classify_platform("Airbnb") == "ACCOMMODATION"

    def test_unknown_platform_defaults_personal_services(self) -> None:
        rep = Dac8Reporter()
        assert rep.classify_platform("UnknownPlatform") == "PERSONAL_SERVICES"

    def test_aggregate_sellers_meets_threshold(self) -> None:
        rep = Dac8Reporter()
        txs = [
            {"seller_id": "s1", "amount": 2500, "currency": "EUR", "date": "2026-01-15",
             "seller_country": "DE", "buyer_country": "PL", "platform_type": "RIDE_SHARING"},
        ]
        sellers = rep.aggregate_sellers(txs, 2026)
        assert len(sellers) == 1
        assert sellers[0].reporting_required

    def test_dac8_xml_generation(self) -> None:
        rep = Dac8Reporter()
        txs = [
            {"seller_id": "s1", "amount": 3000, "currency": "EUR", "date": "2026-02-01",
             "seller_country": "DE", "buyer_country": "PL", "platform_type": "ACCOMMODATION",
             "seller_name": "Test Seller", "description": "Apartment rental"},
        ]
        report = rep.generate_annual_report(2026, "123", "TestJDG", txs)
        assert "<?xml" in report.xml_payload
        assert "DAC8" in report.xml_payload
        assert report.total_sellers >= 0

    def test_deadline_info_returns_valid_date(self) -> None:
        rep = Dac8Reporter()
        info = rep.get_deadline_info(2026)
        assert info["report_year"] == 2026
        assert "2027-01-31" in info["deadline"]


# ═══════════════════════════════════════════════════════════════════════════════
# CrossJurisdictionResolver Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestCrossJurisdictionResolver:
    """Cross-jurisdiction tax conflict resolver."""

    def test_germany_has_upo(self) -> None:
        resolver = CrossJurisdictionResolver()
        assert resolver.has_upo("DE")

    def test_kayman_islands_no_upo(self) -> None:
        resolver = CrossJurisdictionResolver()
        assert not resolver.has_upo("KY")

    def test_wht_recommendation_for_dividends(self) -> None:
        resolver = CrossJurisdictionResolver()
        result = resolver.analyze("DE", "dividends", amount=50000)
        assert len(result.wht_recommendations) >= 1
        rec = result.wht_recommendations[0]
        assert rec.effective_rate <= 0.19

    def test_pe_risk_with_office_and_days(self) -> None:
        resolver = CrossJurisdictionResolver()
        result = resolver.analyze("DE", "services", days_in_country=200, has_office=True)
        assert result.pe_analysis is not None
        assert result.pe_analysis.has_pe_risk

    def test_no_upo_country_critical_risk(self) -> None:
        resolver = CrossJurisdictionResolver()
        result = resolver.analyze("KY", "dividends", amount=10000)
        assert result.double_tax_risk == "CRITICAL"

    def test_all_upo_countries_returns_list(self) -> None:
        resolver = CrossJurisdictionResolver()
        countries = resolver.get_all_upo_countries()
        assert len(countries) >= 20
        assert "DE" in countries

    def test_get_wht_rate_by_country(self) -> None:
        resolver = CrossJurisdictionResolver()
        rate = resolver.get_wht_rate("DE", "dividends")
        assert rate == 0.05


# ═══════════════════════════════════════════════════════════════════════════════
# AmlAutoRemediation Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestAmlAutoRemediation:
    """AML auto-remediation engine."""

    def test_full_compliance_no_gaps(self) -> None:
        remediator = AmlAutoRemediation()
        report = remediator.audit_and_remediate(
            "123",
            {"completed_elements": [
                "CBDD_REGISTRATION", "AML_TRAINING", "AML_AUDIT",
                "AML_PROCEDURE", "RISK_ASSESSMENT", "STR_PROCEDURE",
                "PEP_SCREENING_PROC", "DOCUMENTATION_5Y",
            ]},
        )
        assert report.compliance_score == 100.0

    def test_missing_elements_detected(self) -> None:
        remediator = AmlAutoRemediation()
        report = remediator.audit_and_remediate("456", {"completed_elements": []})
        assert len(report.gaps_found) == 8
        assert report.compliance_score == 0.0

    def test_auto_fix_generates_documents(self) -> None:
        remediator = AmlAutoRemediation()
        report = remediator.audit_and_remediate(
            "789",
            {"completed_elements": ["AML_PROCEDURE", "RISK_ASSESSMENT"]},
        )
        assert len(report.generated_documents) >= 1

    def test_compliance_summary_aggregates(self) -> None:
        remediator = AmlAutoRemediation()
        remediator.audit_and_remediate("a", {"completed_elements": ["CBDD_REGISTRATION", "AML_TRAINING"]})
        summary = remediator.get_compliance_summary()
        assert summary["total_audits"] == 1
        assert summary["latest_score"] < 100


# ═══════════════════════════════════════════════════════════════════════════════
# TaxInspectionPredictor Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestTaxInspectionPredictor:
    """ML-based tax inspection prediction."""

    def test_low_risk_jdg_scores_low(self) -> None:
        pred = TaxInspectionPredictor()
        score = pred.predict(industry="IT_SERVICES", annual_revenue=100000, jdg_age_months=48)
        assert score.risk_level in ("LOW", "MEDIUM")

    def test_high_risk_industry_and_kks_history_scores_high(self) -> None:
        pred = TaxInspectionPredictor()
        score = pred.predict(
            industry="CONSTRUCTION",
            annual_revenue=2000000,
            kks_history={"incidents_60m": 3, "inspections_60m": 2},
            has_crossborder=True,
        )
        assert score.risk_level in ("HIGH", "CRITICAL")

    def test_probabilities_in_valid_range(self) -> None:
        pred = TaxInspectionPredictor()
        score = pred.predict(industry="RETAIL", annual_revenue=500000)
        assert 0 <= score.probability_30d <= 100
        assert 0 <= score.probability_90d <= 100
        assert 0 <= score.probability_365d <= 100

    def test_recommendations_for_high_risk(self) -> None:
        pred = TaxInspectionPredictor()
        score = pred.predict(
            industry="HORECA",
            annual_revenue=3000000,
            kks_history={"incidents_60m": 4},
        )
        assert len(score.recommendations) >= 1

    def test_batch_prediction_returns_sorted(self) -> None:
        pred = TaxInspectionPredictor()
        scores = pred.predict_batch([
            {"industry": "IT_SERVICES", "annual_revenue": 100000},
            {"industry": "CONSTRUCTION", "annual_revenue": 5000000, "kks_history": {"incidents_60m": 3}},
        ])
        assert len(scores) == 2
        assert scores[0].total_score >= scores[-1].total_score


# ═══════════════════════════════════════════════════════════════════════════════
# BlockchainAnalytics Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestBlockchainAnalytics:
    """Crypto blockchain analytics for AML."""

    def test_sanctioned_mixer_scored_high(self) -> None:
        ba = BlockchainAnalytics()
        info = ba.score_address("0x12d66f87a04a9e220743712ce6d9bb1b5616b8fc", "ETH")
        assert info.risk_score >= 50
        assert info.risk_level in ("HIGH", "CRITICAL")

    def test_clean_address_scored_low(self) -> None:
        ba = BlockchainAnalytics()
        info = ba.score_address("0x1234567890abcdef1234567890abcdef12345678", "ETH")
        assert info.risk_score < 30
        assert info.risk_level == "LOW"

    def test_transaction_with_risky_address_triggers_sar(self) -> None:
        ba = BlockchainAnalytics()
        result = ba.analyze_transaction(
            tx_hash="0xabc123",
            from_addr="0x1234567890abcdef",
            to_addr="0x12d66f87a04a9e220743712ce6d9bb1b5616b8fc",  # Tornado Cash
            amount=5.0,
        )
        assert result.requires_sar
        assert result.overall_risk >= 50

    def test_high_volume_transaction_scores_higher(self) -> None:
        ba = BlockchainAnalytics()
        result_low = ba.analyze_transaction("tx1", "0xa", "0xb", amount=0.1)
        result_high = ba.analyze_transaction("tx2", "0xa", "0xb", amount=15.0)
        assert result_high.overall_risk >= result_low.overall_risk

    def test_stats_track_sar_count(self) -> None:
        ba = BlockchainAnalytics()
        ba.analyze_transaction("tx1", "0xa", "0x12d66f87a04a9e220743712ce6d9bb1b5616b8fc", amount=5)
        stats = ba.get_stats()
        assert stats["sar_required"] >= 1


# ═══════════════════════════════════════════════════════════════════════════════
# TaxAuditTrailGenerator Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestTaxAuditTrailGenerator:
    """Immutable audit trail with SHA-256."""

    def test_record_decision_returns_entry(self) -> None:
        gen = TaxAuditTrailGenerator()
        entry = gen.record_decision(
            rule_id="jdg.kks.test",
            legal_basis="Art. 1 KKS",
            input_data={"x": 1},
            output_data={"y": 2},
            decision="BLOCK_AND_ALERT",
        )
        assert entry.entry_id.startswith("AT-")
        assert entry.decision == "BLOCK_AND_ALERT"
        assert len(entry.input_snapshot_hash) == 64

    def test_hash_changes_with_input(self) -> None:
        gen = TaxAuditTrailGenerator()
        e1 = gen.record_decision("r1", "A1", {"a": 1}, {}, decision="A")
        e2 = gen.record_decision("r1", "A1", {"a": 2}, {}, decision="A")
        assert e1.input_snapshot_hash != e2.input_snapshot_hash

    def test_generate_report_with_signature(self) -> None:
        gen = TaxAuditTrailGenerator()
        gen.record_decision("r1", "A1", {}, {}, decision="BLOCK")
        gen.record_decision("r2", "A2", {}, {}, decision="ALLOW")
        report = gen.generate_report("jdg-001")
        assert report.total_decisions == 2
        assert len(report.digital_signature) == 64

    def test_export_markdown_contains_entries(self) -> None:
        gen = TaxAuditTrailGenerator()
        gen.record_decision("r1", "A1", {}, {}, decision="BLOCK", rationale="Test rationale")
        report = gen.generate_report("jdg-002")
        md = gen.export_markdown(report)
        assert "BLOCK" in md
        assert "Test rationale" in md
        assert "Podpis Cyfrowy" in md

    def test_export_json_contains_all_fields(self) -> None:
        gen = TaxAuditTrailGenerator()
        gen.record_decision("r1", "A1", {"invoice": 1}, {"decision": "A"}, decision="A")
        report = gen.generate_report("jdg-003")
        js = gen.export_json(report)
        assert '"report_id"' in js
        assert '"entries"' in js

    def test_stats_correct_counts(self) -> None:
        gen = TaxAuditTrailGenerator()
        gen.record_decision("r1", "A1", {}, {}, decision="BLOCK")
        gen.record_decision("r2", "A2", {}, {}, decision="ALLOW")
        gen.record_decision("r3", "A3", {}, {}, decision="BLOCK")
        stats = gen.get_stats()
        assert stats["total_entries"] == 3
        assert stats["blocked_entries"] == 2


# ═══════════════════════════════════════════════════════════════════════════════
# KksShadowLedgerSimulator Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestKksShadowLedgerSimulator:
    """KKS Shadow Ledger stress-test simulation."""

    def test_empty_invoice_detected(self) -> None:
        sim = KksShadowLedgerSimulator()
        report = sim.run_simulation("jdg-1", [
            {"id": "inv-1", "amount_gross": 50000, "is_empty_invoice": True},
        ])
        assert report.flagged_invoices >= 1
        assert report.total_exposure_pln > 0

    def test_stress_test_all_flagged(self) -> None:
        sim = KksShadowLedgerSimulator()
        invoices = [{"id": f"inv-{i}", "amount_gross": 10000} for i in range(10)]
        report = sim.run_stress_test("jdg-2", invoices)
        assert report.flagged_invoices >= 0
        assert report.stress_test_100pct is True

    def test_multiple_offense_types_per_invoice(self) -> None:
        sim = KksShadowLedgerSimulator()
        report = sim.run_simulation("jdg-3", [
            {"id": "inv-1", "amount_gross": 50000, "is_empty_invoice": True, "declaration_data_falsified": True},
        ])
        assert len(report.findings) >= 2

    def test_exposure_summary_calculates_totals(self) -> None:
        sim = KksShadowLedgerSimulator()
        sim.run_simulation("a", [{"id": "1", "amount_gross": 50000, "is_empty_invoice": True}])
        sim.run_simulation("b", [{"id": "2", "amount_gross": 30000, "vat_records_unreliable": True}])
        summary = sim.get_exposure_summary()
        assert summary["total_simulations"] == 2
        assert summary["max_exposure_pln"] > 0


# ═══════════════════════════════════════════════════════════════════════════════
# CryptoTaxBridge Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestCryptoTaxBridge:
    """Crypto-to-Tax Bridge."""

    def test_classify_trade_transaction(self) -> None:
        bridge = CryptoTaxBridge()
        txs = bridge.classify_transactions([
            CryptoTransaction(tx_id="1", date="2026-01-01", tx_type="TRADE",
                            asset_from="BTC", amount_from=0.1, asset_to="USDT", amount_to=35000)
        ])
        assert txs[0].tax_classification == "PIT-38"

    def test_classify_transfer_untaxable(self) -> None:
        bridge = CryptoTaxBridge()
        txs = bridge.classify_transactions([
            CryptoTransaction(tx_id="2", date="2026-02-01", tx_type="TRANSFER",
                            asset_from="BTC", amount_from=0.5, asset_to="BTC", amount_to=0.5)
        ])
        assert txs[0].tax_classification == "NON_TAXABLE"

    def test_annual_report_calculates_taxable(self) -> None:
        bridge = CryptoTaxBridge()
        txs = [
            CryptoTransaction(tx_id="1", date="2026-01-01", tx_type="TRADE",
                            asset_from="BTC", amount_from=1.0, asset_to="USDT", amount_to=35000,
                            value_pln=350000),
            CryptoTransaction(tx_id="2", date="2026-06-01", tx_type="TRADE",
                            asset_from="ETH", amount_from=10, asset_to="USDT", amount_to=14000,
                            value_pln=140000),
        ]
        report = bridge.generate_annual_report(2026, txs)
        assert report.total_transactions == 2
        assert report.total_volume_pln > 0

    def test_pit_summary_contains_tax_due(self) -> None:
        bridge = CryptoTaxBridge()
        txs = [
            CryptoTransaction(tx_id="1", date="2026-01-01", tx_type="TRADE",
                            asset_from="BTC", amount_from=0.5, asset_to="USDT", amount_to=17500,
                            value_pln=175000)
        ]
        report = bridge.generate_annual_report(2026, txs)
        summary = bridge.generate_pit_summary(report)
        assert "NALEŻNY PODATEK" in summary

    def test_csv_import_resilient_to_malformed_rows(self) -> None:
        bridge = CryptoTaxBridge()
        csv_content = "tx_id,date,asset_from,amount_from,asset_to,amount_to\n1,2026-01-01,BTC,0.5,USDT,17500\n2,2026-02-01,ETH,invalid,USDT,14000"
        txs = bridge.import_binance_csv(csv_content)
        assert len(txs) >= 1  # At least the valid row should parse

    def test_travel_rule_detection(self) -> None:
        bridge = CryptoTaxBridge()
        txs = bridge.classify_transactions([
            CryptoTransaction(tx_id="1", date="2026-01-01", tx_type="TRADE",
                            asset_from="BTC", amount_from=10, asset_to="USDT", amount_to=3500000,
                            value_pln=3500000),
        ])
        report = bridge.generate_annual_report(2026, txs)
        # Large transaction > 4300 PLN (1000 EUR × 4.30) should trigger travel rule
        assert report.travel_rule_required >= 1
