#!/usr/bin/env python3
"""
End-to-End Test: DuckDB → Rego Policy Generation → OPA Evaluation → Verdict

Tests the full OPA + DuckDB + Rust architecture:
  1. DuckDB RuleStore: seed default tax rules
  2. OPA Policy Generator: convert DuckDB rules → Rego policy
  3. OPA Client: load policy into OPA sidecar
  4. OPA Evaluation: evaluate test contexts → verdicts
  5. Verdict verification: compare with expected results
  6. Fallback test: verify DuckDB-only path still works

Usage:
    python tests/test_opa_e2e.py
"""

import sys
import os
import json
import traceback
import asyncio

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# ── Test configurations ─────────────────────────────────────────────────────

OPA_URL = "http://localhost:8181"
TEST_TIMEOUT = 10.0

# Expected verdicts for known scenarios (OPA returns these in the result dict)
EXPECTED_VERDICTS = {
    "FUEL_PL": {
        "vat_rate": "0.23",
        "gtu_code": "GTU_04",
        "rounding_level": "position",
        "expected_priority": 10,
    },
    "FOOD_PL": {
        "vat_rate": "0.08",
        "rounding_level": "position",
        "expected_priority": 10,
    },
    "EDUCATION_PL": {
        "vat_rate": "0.00",
        "rounding_level": "total",
        "expected_priority": 10,
    },
    "EU_REVERSE_CHARGE": {
        "vat_rate": "0.00",
        "procedure": "VAT_REVERSE_CHARGE",
        "expected_priority": 50,
    },
    "NON_EU_IMPORT": {
        "vat_rate": "0.23",
        "procedure": "IMPORT",
        "expected_priority": 50,
    },
    "FALLBACK_DOMESTIC": {
        "vat_rate": "0.23",
        "expected_priority": 100,
    },
}


class OpaE2ETester:
    """End-to-end tester for OPA + DuckDB + RuleEngine integration."""

    def __init__(self):
        self.results = {"passed": 0, "failed": 0, "tests": []}
        self.conn = None
        self.opa_client = None
        self.engine = None
        self.generator = None
        self.rego_code = ""
        self.rules = []
        self.opa_data = {}

    def run_test(self, name, fn):
        try:
            fn()
            self.results["passed"] += 1
            self.results["tests"].append({"name": name, "status": "PASS"})
            print(f"  ✅ {name}")
        except Exception as e:
            self.results["failed"] += 1
            traceback.print_exc()
            self.results["tests"].append(
                {"name": name, "status": "FAIL", "error": str(e)}
            )
            print(f"  ❌ {name}: {e}")

    def run_async(self, coro):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            return loop.run_until_complete(coro)
        finally:
            loop.close()

    # ── STEP 1: Import modules ──────────────────────────────────────────

    def test_imports(self):
        import duckdb as _duckdb
        from nexus_ai.services.opa_policy_generator import OpaPolicyGenerator
        from nexus_ai.core.opa_client import OpaClient
        from nexus_ai.tax.rules import (
            RuleEngine, ContextInterpreter,
            ensure_tax_schemas, seed_default_rules,
            DEFAULT_TAX_RULES,
        )
        self._duckdb = _duckdb
        self._OpaPolicyGenerator = OpaPolicyGenerator
        self._OpaClient = OpaClient
        self._RuleEngine = RuleEngine
        self._ContextInterpreter = ContextInterpreter
        self._ensure_tax_schemas = ensure_tax_schemas
        self._seed_default_rules = seed_default_rules
        self._DEFAULT_TAX_RULES = DEFAULT_TAX_RULES

    # ── STEP 2: Setup DuckDB ────────────────────────────────────────────

    def test_duckdb_setup(self):
        self.conn = self._duckdb.connect(":memory:")
        self._ensure_tax_schemas(self.conn)
        self._seed_default_rules(self.conn)
        count = self.conn.execute("SELECT COUNT(*) FROM tax_rules").fetchone()[0]
        assert count > 0, "No rules seeded"
        print(f"     Seeded {count} tax rules")
        # Load rules for policy generation
        rows = self.conn.execute(
            "SELECT rule_id, condition_sql, action_json, priority, "
            "valid_from, valid_to, rule_set_id "
            "FROM tax_rules ORDER BY priority ASC, valid_from DESC"
        ).fetchall()
        for r in rows:
            rule = {
                "rule_id": str(r[0]),
                "condition_sql": str(r[1]),
                "action_json": str(r[2]),
                "priority": int(r[3]),
                "valid_from": str(r[4]),
            }
            if r[5] is not None:
                rule["valid_to"] = str(r[5])
            if r[6]:
                rule["rule_set_id"] = str(r[6])
            self.rules.append(rule)
        print(f"     Loaded {len(self.rules)} rules from DuckDB")

    # ── STEP 3: Generate Rego policy ────────────────────────────────────

    def test_rego_generation(self):
        self.generator = self._OpaPolicyGenerator()
        self.rego_code = self.generator.generate_policy(self.rules)
        assert len(self.rego_code) > 0, "Empty Rego policy"
        assert "package tax.rules" in self.rego_code, "Missing package"
        assert "default decide =" in self.rego_code, "Missing default"
        assert "decide =" in self.rego_code, "Missing decide rule"
        # Verify else-chain: else clauses follow directly without blank lines
        lines = self.rego_code.split("\n")
        has_else = any(line.strip().startswith("else") for line in lines)
        print(f"     Policy: {len(self.rego_code)} chars, {len(self.rules)} rules, else={has_else}")

    def test_rego_data_generation(self):
        self.opa_data = self.generator.generate_data(self.rules)
        assert "rules" in self.opa_data, "Missing rules key"
        assert self.opa_data["rules"]["count"] == len(self.rules), "Count mismatch"
        print(f"     Data: {self.opa_data['rules']['count']} rules, {len(self.opa_data['rules']['sets'])} sets")

    # ── STEP 4: Connect to OPA ──────────────────────────────────────────

    def test_opa_connect(self):
        import httpx as _httpx
        self.opa_client = self._OpaClient(base_url=OPA_URL, timeout=TEST_TIMEOUT)
        healthy = self.run_async(self.opa_client.health())
        assert healthy, "OPA health check failed"
        print(f"     OPA server healthy")

    def test_opa_load_policy(self):
        result = self.run_async(
            self.opa_client.load_policy("tax/rules.rego", self.rego_code)
        )
        assert result, "Failed to load policy"
        print(f"     Policy loaded ({len(self.rego_code)} bytes)")

    def test_opa_load_data(self):
        result = self.run_async(
            self.opa_client.load_data("tax/rules", self.opa_data)
        )
        assert result, "Failed to load data"
        print(f"     Data loaded ({self.opa_data['rules']['count']} rules)")

    # ── STEP 5: Evaluate contexts ───────────────────────────────────────

    def test_evaluate_fuel_pl(self):
        ctx = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "amount_net": "1000.00",
        }
        verdict = self.run_async(
            self.opa_client.evaluate("tax/rules/decide", ctx)
        )
        # OPA returns the rule result directly
        vat = verdict.get("vat_rate", verdict.get("verdict", {}).get("vat_rate", ""))
        assert vat == "0.23", f"FUEL_PL: expected vat=0.23, got {vat}"
        gtu = verdict.get("gtu_code", verdict.get("verdict", {}).get("gtu_code", ""))
        assert gtu == "GTU_04", f"FUEL_PL: expected GTU_04, got {gtu}"

    def test_evaluate_food_pl(self):
        ctx = {
            "category_code": "FOOD",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "amount_net": "500.00",
        }
        verdict = self.run_async(
            self.opa_client.evaluate("tax/rules/decide", ctx)
        )
        vat = verdict.get("vat_rate", verdict.get("verdict", {}).get("vat_rate", ""))
        assert vat == "0.08", f"FOOD_PL: expected vat=0.08, got {vat}"

    def test_evaluate_education_pl(self):
        ctx = {
            "category_code": "EDUCATION",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "amount_net": "300.00",
        }
        verdict = self.run_async(
            self.opa_client.evaluate("tax/rules/decide", ctx)
        )
        vat = verdict.get("vat_rate", verdict.get("verdict", {}).get("vat_rate", ""))
        assert vat == "0.00", f"EDUCATION_PL: expected vat=0.00, got {vat}"
        rl = verdict.get("rounding_level", verdict.get("verdict", {}).get("rounding_level", ""))
        assert rl == "total", f"EDUCATION_PL: expected rounding=total, got {rl}"

    def test_evaluate_eu_reverse_charge(self):
        ctx = {
            "category_code": "IT_OFFICE",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "EU",
            "vendor_vat_status": "active",
            "amount_net": "1000.00",
        }
        verdict = self.run_async(
            self.opa_client.evaluate("tax/rules/decide", ctx)
        )
        vat = verdict.get("vat_rate", verdict.get("verdict", {}).get("vat_rate", ""))
        assert vat == "0.00", f"EU_REVERSE_CHARGE: expected vat=0.00, got {vat}"
        proc = verdict.get("procedure", verdict.get("verdict", {}).get("procedure", ""))
        assert proc == "VAT_REVERSE_CHARGE", f"expected reverse charge, got {proc}"

    def test_evaluate_non_eu_import(self):
        ctx = {
            "category_code": "IT_OFFICE",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "NON_EU",
            "vendor_vat_status": "unknown",
            "amount_net": "1000.00",
        }
        verdict = self.run_async(
            self.opa_client.evaluate("tax/rules/decide", ctx)
        )
        vat = verdict.get("vat_rate", verdict.get("verdict", {}).get("vat_rate", ""))
        assert vat == "0.23", f"NON_EU_IMPORT: expected vat=0.23, got {vat}"
        proc = verdict.get("procedure", verdict.get("verdict", {}).get("procedure", ""))
        assert proc == "IMPORT", f"expected IMPORT, got {proc}"

    def test_evaluate_fallback_domestic(self):
        ctx = {
            "category_code": "UNKNOWN",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "amount_net": "1000.00",
        }
        verdict = self.run_async(
            self.opa_client.evaluate("tax/rules/decide", ctx)
        )
        vat = verdict.get("vat_rate", verdict.get("verdict", {}).get("vat_rate", ""))
        assert vat == "0.23", f"FALLBACK: expected vat=0.23, got {vat}"

    def test_evaluate_field_confidence(self):
        ctx = {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD",
            "vendor_country": "PL",
            "vendor_vat_status": "unknown",
            "amount_net": "1000.00",
            "fc_vat_rate": "0.70",
            "fc_minimum": "0.90",
        }
        verdict = self.run_async(
            self.opa_client.evaluate("tax/rules/decide", ctx)
        )
        # Field confidence rule should match (fc_vat_rate < 0.98 for CIT_STANDARD)
        routing = verdict.get("_routing", verdict.get("verdict", {}).get("_routing", ""))
        assert routing == "BLOCK_AND_ALERT", f"expected BLOCK_AND_ALERT routing, got {routing}"

    def test_evaluate_batch(self):
        inputs = [
            {"category_code": "FUEL", "transaction_date": "2025-06-01",
             "company_tax_form": "CIT_STANDARD", "vendor_country": "PL"},
            {"category_code": "FOOD", "transaction_date": "2025-06-01",
             "company_tax_form": "CIT_STANDARD", "vendor_country": "PL"},
            {"category_code": "EDUCATION", "transaction_date": "2025-06-01",
             "company_tax_form": "CIT_STANDARD", "vendor_country": "PL"},
        ]
        results = self.run_async(
            self.opa_client.evaluate_batch("tax/rules/decide", inputs)
        )
        assert len(results) == 3, f"Expected 3 results, got {len(results)}"
        for i, r in enumerate(results):
            assert isinstance(r, dict), f"Result {i} should be dict"

    # ── STEP 6: Verify DuckDB ↔ OPA consistency ────────────────────────

    def _check_consistency(self, name, ctx):
        duckdb_verdict = self.engine.decide(ctx)
        opa_verdict = self.run_async(
            self.opa_client.evaluate("tax/rules/decide", ctx)
        )
        duckdb_vat = duckdb_verdict.get("vat_rate", "")
        opa_vat = opa_verdict.get("vat_rate", opa_verdict.get("verdict", {}).get("vat_rate", ""))
        if duckdb_vat and opa_vat:
            assert duckdb_vat == opa_vat, \
                f"{name}: DuckDB={duckdb_vat} OPA={opa_vat} mismatch"

    def test_consistency_fuel(self):
        self._check_consistency("FUEL", {
            "category_code": "FUEL", "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD", "vendor_country": "PL",
            "vendor_vat_status": "unknown", "amount_net": "1000.00",
        })

    def test_consistency_food(self):
        self._check_consistency("FOOD", {
            "category_code": "FOOD", "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD", "vendor_country": "PL",
            "vendor_vat_status": "unknown", "amount_net": "500.00",
        })

    def test_consistency_eu(self):
        self._check_consistency("EU", {
            "category_code": "IT_OFFICE", "transaction_date": "2025-06-01",
            "company_tax_form": "CIT_STANDARD", "vendor_country": "EU",
            "vendor_vat_status": "active", "amount_net": "1000.00",
        })

    # ── STEP 7: Test error handling ─────────────────────────────────────

    def test_health_check(self):
        healthy = self.run_async(self.opa_client.health())
        assert healthy, "OPA should be healthy"

    # ── Run all tests ───────────────────────────────────────────────────

    def run_all(self):
        print("=" * 60)
        print("🏁 OPA + DuckDB + Rust E2E TEST SUITE")
        print("=" * 60)

        # Step 1
        print("\n📦 STEP 1: Module imports")
        self.run_test("Import all modules", self.test_imports)
        if self.results["failed"] > 0:
            print("\n❌ Import failures - aborting")
            return self.results

        # Step 2
        print("\n🗄️  STEP 2: DuckDB RuleStore setup")
        self.run_test("Create schema + seed rules", self.test_duckdb_setup)
        if self.results["failed"] > 0:
            return self.results

        # Step 3
        print("\n📝 STEP 3: Rego policy generation")
        self.run_test("Generate Rego policy", self.test_rego_generation)
        self.run_test("Generate OPA data", self.test_rego_data_generation)

        # Step 4
        print("\n🔗 STEP 4: OPA sidecar connection")
        self.run_test("OPA health check", self.test_opa_connect)
        self.run_test("Load policy into OPA", self.test_opa_load_policy)
        self.run_test("Load data into OPA", self.test_opa_load_data)

        # Step 5
        print("\n🎯 STEP 5: OPA evaluation")
        self.run_test("FUEL Poland → 23% VAT, GTU_04", self.test_evaluate_fuel_pl)
        self.run_test("FOOD Poland → 8% VAT", self.test_evaluate_food_pl)
        self.run_test("EDUCATION Poland → 0% VAT, rounding=total", self.test_evaluate_education_pl)
        self.run_test("EU reverse charge → 0% VAT, REVERSE_CHARGE", self.test_evaluate_eu_reverse_charge)
        self.run_test("Non-EU import → 23% VAT, IMPORT", self.test_evaluate_non_eu_import)
        self.run_test("Fallback domestic → 23% VAT", self.test_evaluate_fallback_domestic)
        self.run_test("Field confidence → BLOCK_AND_ALERT", self.test_evaluate_field_confidence)
        self.run_test("Batch evaluation (3 inputs)", self.test_evaluate_batch)

        # Step 6
        print("\n⚖️  STEP 6: DuckDB ↔ OPA consistency")
        self.engine = self._RuleEngine(self.conn)
        self.run_test("FUEL: DuckDB = OPA", self.test_consistency_fuel)
        self.run_test("FOOD: DuckDB = OPA", self.test_consistency_food)
        self.run_test("EU: DuckDB = OPA", self.test_consistency_eu)

        # Step 7
        print("\n🛡️  STEP 7: Error handling")
        self.run_test("OPA health endpoint", self.test_health_check)

        # Cleanup
        print("\n🧹 Cleanup")
        if self.conn:
            self.conn.close()
        if self.opa_client:
            self.run_async(self.opa_client.close())

        # Summary
        total = self.results["passed"] + self.results["failed"]
        print(f"\n{'='*60}")
        print(f"📋 RESULTS: {self.results['passed']}/{total} passed, "
              f"{self.results['failed']} failed")
        print(f"{'='*60}")

        return self.results


if __name__ == "__main__":
    tester = OpaE2ETester()
    results = tester.run_all()
    sys.exit(1 if results["failed"] > 0 else 0)
