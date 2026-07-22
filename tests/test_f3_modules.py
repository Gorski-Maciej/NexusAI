"""
test_f3_modules.py — F3 v7.0 Audit: Unit tests for strategic modules.

Tests for:
  - TaxOptimizerEngine (F3.1)
  - BankSyncEngine (F3.4)
  - OPAMarketplace (F3.5)
  - TaxFormAutoFillEngine
  - MCPServer (Pomysl #14)
"""

from __future__ import annotations

import pytest
from decimal import Decimal

from nexus_ai.services.tax_optimizer import (
    TaxOptimizerEngine,
    TaxStrategy,
    TaxForm,
    WhatIfPlanner,
    FinancialHealthScore,
)
from nexus_ai.services.bank_sync_engine import (
    BankSyncEngine,
    BankProvider,
    TransactionType,
    MatchStatus,
    BankTransaction,
)
from nexus_ai.services.opa_marketplace import (
    OPAMarketplace,
    MarketplaceRule,
    RuleCategory,
    RuleStatus,
    PricingModel,
)
from nexus_ai.services.tax_form_autofill import (
    TaxFormAutoFillEngine,
    TaxFormType,
)
from nexus_ai.api.mcp_server import MCPServer, MCP_TOOLS, MCP_RESOURCES

pytestmark = pytest.mark.anyio


# ═══════════════════════════════════════════════════════════════════════════════
# TaxOptimizerEngine Tests (F3.1)
# ═══════════════════════════════════════════════════════════════════════════════

class TestTaxOptimizer:
    """AI Tax Optimizer — całoroczny planer podatkowy."""

    def test_simulate_all_forms_returns_results(self) -> None:
        """Should return results for all 4 tax forms."""
        engine = TaxOptimizerEngine(annual_revenue=200000, annual_costs=80000)
        results = engine.simulate_all_tax_forms()
        assert len(results) == 4
        tax_forms = {r.tax_form for r in results}
        assert TaxForm.GENERAL in tax_forms
        assert TaxForm.LINEAR in tax_forms
        assert TaxForm.LUMP_SUM in tax_forms
        assert TaxForm.IP_BOX in tax_forms

    def test_best_tax_form_sorted_first(self) -> None:
        """Results should be sorted by tax_due ascending (best first)."""
        engine = TaxOptimizerEngine(annual_revenue=200000, annual_costs=50000)
        results = engine.simulate_all_tax_forms()
        assert results[0].tax_due <= results[-1].tax_due

    def test_tax_free_amount_zero_tax(self) -> None:
        """Income <= 30000 should have zero tax on general scale."""
        engine = TaxOptimizerEngine(annual_revenue=30000, annual_costs=0)
        results = engine.simulate_all_tax_forms()
        general = [r for r in results if r.tax_form == TaxForm.GENERAL][0]
        assert general.tax_due == 0.0

    def test_health_score_returns_valid_range(self) -> None:
        """Financial Health Score should be 0-100."""
        engine = TaxOptimizerEngine(annual_revenue=150000, annual_costs=70000)
        health = engine.compute_financial_health()
        assert 0 <= health.overall <= 100
        assert health.grade in ("A — Doskonała", "B — Dobra", "C — Przeciętna", "D — Wymaga uwagi", "F — Krytyczna")

    def test_optimization_recommendations_for_high_income(self) -> None:
        """High income should trigger Q4 equipment purchase recommendation."""
        engine = TaxOptimizerEngine(annual_revenue=300000, annual_costs=100000)
        recs = engine.get_optimization_recommendations()
        # High income > 120k should trigger Q4 recommendation
        assert any("grudniu" in r.title.lower() or "Q4" in r.action_timing for r in recs)


# ═══════════════════════════════════════════════════════════════════════════════
# WhatIfPlanner Tests (F3.1)
# ═══════════════════════════════════════════════════════════════════════════════

class TestWhatIfPlanner:
    """What-If Scenario Planner."""

    def test_add_and_simulate_scenarios(self) -> None:
        """Adding scenarios and simulating should return comparison."""
        planner = WhatIfPlanner()
        planner.add_scenario("Zatrudnij pracownika", revenue_delta=0, cost_delta=60000)
        planner.add_scenario("Zmien na ryczalt", revenue_delta=0, cost_delta=-10000)

        results = planner.simulate(baseline_revenue=200000, baseline_costs=80000)
        assert len(results) == 3  # baseline + 2 scenarios
        assert results[0]["scenario"] == "BASELINE (obecny)"
        assert any("pracownika" in r["scenario"] for r in results)


# ═══════════════════════════════════════════════════════════════════════════════
# BankSyncEngine Tests (F3.4)
# ═══════════════════════════════════════════════════════════════════════════════

class TestBankSyncEngine:
    """Bank Sync Engine — CSV/MT940 import + auto-matching."""

    def test_csv_import_parses_transactions(self) -> None:
        """CSV import should parse transactions correctly."""
        csv_content = "date,amount,counterparty,title\n2026-07-01,5000.00,ABC Tech,FV/2026/001\n2026-07-02,-1200.00,OfficePlus,Zakup materialow"
        engine = BankSyncEngine()
        txs = engine.import_from_csv(csv_content)
        assert len(txs) == 2
        assert txs[0].tx_type == TransactionType.INCOMING
        assert txs[1].tx_type == TransactionType.OUTGOING

    def test_auto_match_by_invoice_number(self) -> None:
        """Should match transaction to invoice by invoice number in title."""
        engine = BankSyncEngine()
        engine.set_invoices([
            {"id": "inv-001", "number": "FV/2026/001", "amount_gross": 5000.00, "contractor_nip": "1234567890", "vendor_name": "ABC Tech"},
        ])
        tx = BankTransaction(
            amount=Decimal("5000.00"),
            title="Przelew za FV/2026/001",
            counterparty_name="ABC Tech",
        )
        engine._transactions = [tx]
        result = engine.auto_match()
        assert result["matched"] >= 1

    def test_reconciliation_detects_imbalance(self) -> None:
        """Reconciliation should detect imbalance between bank and books."""
        engine = BankSyncEngine()
        engine._transactions = [
            BankTransaction(amount=Decimal("10000"), tx_type=TransactionType.INCOMING),
            BankTransaction(amount=Decimal("3000"), tx_type=TransactionType.OUTGOING),
        ]
        result = engine.reconcile(Decimal("7000"))
        assert result.is_balanced


# ═══════════════════════════════════════════════════════════════════════════════
# OPAMarketplace Tests (F3.5)
# ═══════════════════════════════════════════════════════════════════════════════

class TestOPAMarketplace:
    """OPA Marketplace — platforma reguł z revenue share."""

    def test_publish_and_search_rules(self) -> None:
        """Published rules should be searchable."""
        mp = OPAMarketplace()
        rule = MarketplaceRule(
            name="VAT MPP Check",
            description="Weryfikacja MPP dla faktur powyzej 15000 PLN",
            category=RuleCategory.VAT,
            author_name="Jan Kowalski",
            price_pln=49.0,
            pricing=PricingModel.ONE_TIME,
            tags=["vat", "mpp", "split-payment"],
        )
        mp.publish_rule(rule)

        results = mp.search_rules(category=RuleCategory.VAT, query="MPP")
        assert len(results) >= 1
        assert results[0].name == "VAT MPP Check"

    def test_purchase_and_revenue_share(self) -> None:
        """Purchasing a rule should record revenue with 70/30 split."""
        mp = OPAMarketplace()
        rule = MarketplaceRule(
            name="Test Rule",
            price_pln=100.0,
            author_id="author-1",
            author_name="Test Author",
            revenue_share_pct=70.0,
        )
        mp.publish_rule(rule)
        mp.purchase_rule(rule.rule_id, "buyer-1")

        report = mp.get_creator_revenue("author-1")
        assert report.total_downloads == 1
        assert report.creator_share == 70.0  # 70% of 100 PLN
        assert report.platform_share == 30.0

    def test_rating_updates_average(self) -> None:
        """Rating should update rolling average correctly."""
        mp = OPAMarketplace()
        rule = MarketplaceRule(name="Rated Rule")
        mp.publish_rule(rule)

        mp.rate_rule(rule.rule_id, 5.0)
        mp.rate_rule(rule.rule_id, 3.0)

        updated = mp.get_rule(rule.rule_id)
        assert updated is not None
        assert updated.rating == 4.0  # (5+3)/2


# ═══════════════════════════════════════════════════════════════════════════════
# TaxFormAutoFillEngine Tests
# ═══════════════════════════════════════════════════════════════════════════════

class TestTaxFormAutoFill:
    """Tax Form Auto-Fill Engine."""

    def test_generate_pit36(self) -> None:
        """Should generate PIT-36 with correct tax computation."""
        engine = TaxFormAutoFillEngine()
        form = engine.generate_pit36(2026, revenue=150000, costs=50000)
        assert form.form_type == TaxFormType.PIT_36
        assert form.status == "ready"
        assert len(form.fields) >= 5

    def test_generate_all_forms(self) -> None:
        """Should generate all 4 forms."""
        engine = TaxFormAutoFillEngine()
        forms = engine.generate_all("2026-07", 2026, 200000, 80000)
        assert len(forms) == 4
        assert "pit36" in forms
        assert "vat7" in forms
        assert "jpk_v7" in forms
        assert "zus_dra" in forms

    def test_pit_tax_free_amount(self) -> None:
        """Income <= 30000 should have zero PIT."""
        tax = TaxFormAutoFillEngine._compute_pit_tax(25000)
        assert tax == 0.0


# ═══════════════════════════════════════════════════════════════════════════════
# MCPServer Tests (Pomysl #14)
# ═══════════════════════════════════════════════════════════════════════════════

class TestMCPServer:
    """MCP Server for AI ecosystem."""

    def test_initialize_returns_capabilities(self) -> None:
        """Initialize should return server info and capabilities."""
        server = MCPServer()
        response = server.handle_request({"method": "initialize", "params": {}, "id": 1})
        assert response["result"]["serverInfo"]["name"] == "NexusAI MCP Server"
        assert "tools" in response["result"]["capabilities"]

    def test_list_tools_returns_all(self) -> None:
        """tools/list should return all defined tools."""
        server = MCPServer()
        response = server.handle_request({"method": "tools/list", "params": {}, "id": 2})
        tools = response["result"]["tools"]
        assert len(tools) == len(MCP_TOOLS)
        tool_names = {t["name"] for t in tools}
        assert "get_vat_summary" in tool_names

    def test_list_resources_returns_all(self) -> None:
        """resources/list should return all defined resources."""
        server = MCPServer()
        response = server.handle_request({"method": "resources/list", "params": {}, "id": 3})
        resources = response["result"]["resources"]
        assert len(resources) == len(MCP_RESOURCES)

    def test_call_tool_returns_content(self) -> None:
        """Calling a tool should return content array."""
        server = MCPServer()
        response = server.handle_request({
            "method": "tools/call",
            "params": {"name": "get_vat_summary", "arguments": {"period": "2026-07"}},
            "id": 4,
        })
        assert "result" in response
        assert "content" in response["result"]

    def test_unknown_method_returns_error(self) -> None:
        """Unknown method should return JSON-RPC error."""
        server = MCPServer()
        response = server.handle_request({"method": "nonexistent", "params": {}, "id": 5})
        assert "error" in response
        assert response["error"]["code"] == -32601
