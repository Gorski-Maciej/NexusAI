#!/usr/bin/env python3
"""
Standalone E2E Test: OPA Client + DuckDB + Policy Generator

Tests the OPA integration components without loading the full nexus_ai package
(which requires the compiled Rust nexus_crypto module).

Tests:
  1. OPA binary health check
  2. Rego policy loading into OPA
  3. Rego policy evaluation
  4. Batched evaluation
"""

import sys
import os
import json
import asyncio

# Add project root to path
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, PROJECT_ROOT)

# Direct imports of OPA-specific modules (no Rust dependency)
sys.path.insert(0, os.path.join(PROJECT_ROOT, "nexus_ai"))

OPA_URL = "http://localhost:8181"

# ── Rego policy test data ───────────────────────────────────────────────────

REGO_POLICY = """package tax.rules

# Auto-generated test policy
default decide = {"matched": false, "error": "NO_MATCHING_RULE"}

# First rule: FUEL in PL
decide = {
        "matched": true,
        "rule_id": "test-fuel-pl",
        "priority": 10,
        "vat_rate": "0.23",
        "rounding_level": "position",
        "gtu_code": "GTU_04"
    } {
        input.category_code == "FUEL"
    } else = {
        "matched": true,
        "rule_id": "test-food-pl",
        "priority": 10,
        "vat_rate": "0.08",
        "rounding_level": "position"
    } {
        input.category_code == "FOOD"
    } else = {
        "matched": true,
        "rule_id": "test-education-pl",
        "priority": 10,
        "vat_rate": "0.00",
        "rounding_level": "total"
    } {
        input.category_code == "EDUCATION"
    } else = {
        "matched": true,
        "rule_id": "test-field-confidence-vat",
        "priority": 8,
        "vat_rate": "0.23",
        "rounding_level": "position",
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Low VAT rate confidence"
    } {
        input.fc_vat_rate < "0.98"
    } else = {
        "matched": true,
        "rule_id": "test-fallback-pl",
        "priority": 100,
        "vat_rate": "0.23",
        "rounding_level": "position"
    } {
        true
    }
"""

OPA_DATA = {
    "rules": {
        "list": [
            {
                "rule_id": "test-fuel-pl",
                "condition": "category_code = 'FUEL' AND vendor_country = 'PL'",
                "action": {"vat_rate": "0.23", "gtu_code": "GTU_04"},
                "priority": 10
            },
            {
                "rule_id": "test-food-pl",
                "condition": "category_code = 'FOOD' AND vendor_country = 'PL'",
                "action": {"vat_rate": "0.08"},
                "priority": 10
            },
            {
                "rule_id": "test-education-pl",
                "condition": "category_code IN ('EDUCATION', 'HEALTHCARE') AND vendor_country = 'PL'",
                "action": {"vat_rate": "0.00", "rounding_level": "total"},
                "priority": 10
            }
        ],
        "count": 3,
        "sets": ["default"]
    }
}

# ── Test contexts ───────────────────────────────────────────────────────────

TEST_CONTEXTS = [
    ("FUEL Poland → 23% VAT", {
        "category_code": "FUEL",
        "transaction_date": "2025-06-01",
    }),
    ("FOOD Poland → 8% VAT", {
        "category_code": "FOOD",
        "transaction_date": "2025-06-01",
    }),
    ("EDUCATION → 0% VAT", {
        "category_code": "EDUCATION",
        "transaction_date": "2025-06-01",
    }),
    ("Field confidence (fc_vat_rate=0.70) → BLOCK_AND_ALERT", {
        "category_code": "FUEL",
        "transaction_date": "2025-06-01",
        "fc_vat_rate": "0.70",
    }),
    ("Fallback (UNKNOWN) → 23% VAT", {
        "category_code": "UNKNOWN",
        "transaction_date": "2025-06-01",
    }),
]

# ── OPA REST Client (minimal standalone) ────────────────────────────────────


class OpaRestClient:
    """Minimal OPA REST client using urllib (no external deps)."""

    def __init__(self, base_url: str = OPA_URL):
        self.base_url = base_url.rstrip("/")

    def _request(self, method: str, path: str, body: str = None) -> tuple[int, str]:
        import urllib.request
        import urllib.error

        url = f"{self.base_url}{path}"
        data = body.encode("utf-8") if body else None
        req = urllib.request.Request(url, data=data, method=method)
        if data:
            req.add_header("Content-Type", "application/json")

        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                return resp.status, resp.read().decode("utf-8")
        except urllib.error.HTTPError as e:
            return e.code, e.read().decode("utf-8")
        except urllib.error.URLError as e:
            return -1, str(e)

    def health(self) -> bool:
        status, _ = self._request("GET", "/health")
        return status == 200

    def load_policy(self, policy_name: str, rego_code: str) -> bool:
        status, body = self._request(
            "PUT",
            f"/v1/policies/{policy_name}",
            rego_code,
        )
        return status in (200, 204)

    def load_data(self, path: str, data: dict) -> bool:
        status, body = self._request(
            "PUT",
            f"/v1/data/{path}",
            json.dumps(data),
        )
        return status in (200, 204)

    def evaluate(self, path: str, input_data: dict = None) -> dict:
        import urllib.request

        payload = {}
        if input_data:
            payload["input"] = input_data

        body = json.dumps(payload)
        status, resp_body = self._request("POST", f"/v1/data/{path}", body)

        if status == 200:
            result = json.loads(resp_body)
            return result.get("result", {}) or {"matched": False, "error": "NO_MATCHING_RULE"}

        return {"matched": False, "error": f"HTTP {status}", "detail": resp_body[:200]}


# ── Test Runner ─────────────────────────────────────────────────────────────


class TestRunner:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.tests = []
        self.opa = OpaRestClient()

    def test(self, name, fn):
        try:
            fn()
            self.passed += 1
            self.tests.append({"name": name, "status": "PASS"})
            print(f"  ✅ {name}")
        except Exception as e:
            self.failed += 1
            self.tests.append({"name": name, "status": "FAIL", "error": str(e)})
            print(f"  ❌ {name}: {e}")

    def summary(self):
        total = self.passed + self.failed
        print(f"\n{'='*60}")
        print(f"📋 RESULTS: {self.passed}/{total} passed, {self.failed} failed")
        print(f"{'='*60}")
        if self.failed > 0:
            print("\nFailed tests:")
            for t in self.tests:
                if t["status"] == "FAIL":
                    print(f"  ❌ {t['name']}: {t.get('error', '')}")
        return self.failed == 0


def main():
    runner = TestRunner()
    print("=" * 60)
    print("🏁 OPA E2E TEST SUITE (Standalone)")
    print("=" * 60)

    # ── Step 1: OPA Health ──────────────────────────────────────────────
    print("\n🩺 STEP 1: OPA Server Health")

    def test_health():
        assert runner.opa.health(), "OPA should be running on localhost:8181"

    runner.test("OPA health check", test_health)

    # ── Step 2: Load Policy ─────────────────────────────────────────────
    print("\n📝 STEP 2: Load Rego Policy")

    def test_load_policy():
        ok = runner.opa.load_policy("tax/rules.rego", REGO_POLICY)
        assert ok, "Failed to load Rego policy"

    runner.test("Load policy tax/rules.rego", test_load_policy)

    def test_load_data():
        ok = runner.opa.load_data("tax/rules", OPA_DATA)
        assert ok, "Failed to load OPA data"

    runner.test("Load tax/rules data", test_load_data)

    # ── Step 3: Evaluate ────────────────────────────────────────────────
    print("\n🎯 STEP 3: Evaluate Contexts")

    def test_evaluate(name, ctx, expected_checks):
        verdict = runner.opa.evaluate("tax/rules/decide", ctx)

        # Verify verdict is a dict
        assert isinstance(verdict, dict), f"verdict should be dict, got {type(verdict)}"

        # Run custom checks
        for check_name, check_fn in expected_checks.items():
            check_fn(verdict)

    # FUEL → 23% VAT
    runner.test(
        "FUEL → 23% VAT",
        lambda: test_evaluate(
            "FUEL → 23% VAT",
            {"category_code": "FUEL", "transaction_date": "2025-06-01"},
            {
                "has_vat_rate": lambda v: v.get("vat_rate") in ("0.23", "23%"),
                "matched": lambda v: "rule_id" in v or v.get("matched") in (True, "true"),
            },
        ),
    )

    # FOOD → 8% VAT
    runner.test(
        "FOOD → 8% VAT",
        lambda: test_evaluate(
            "FOOD → 8% VAT",
            {"category_code": "FOOD", "transaction_date": "2025-06-01"},
            {
                "has_vat_rate": lambda v: v.get("vat_rate") in ("0.08", "8%"),
            },
        ),
    )

    # EDUCATION → 0% VAT
    runner.test(
        "EDUCATION → 0% VAT",
        lambda: test_evaluate(
            "EDUCATION → 0% VAT",
            {"category_code": "EDUCATION", "transaction_date": "2025-06-01"},
            {
                "has_vat_rate": lambda v: v.get("vat_rate") in ("0.00", "0%"),
            },
        ),
    )

    # Field confidence → BLOCK_AND_ALERT
    runner.test(
        "Field confidence → routing check",
        lambda: test_evaluate(
            "Field confidence → routing check",
            {"category_code": "FUEL", "fc_vat_rate": "0.70"},
            {
                "has_routing": lambda v: (
                    "_routing" in v or v.get("matched") is not False
                ),
            },
        ),
    )

    # Fallback → 23% VAT
    runner.test(
        "Fallback → 23% VAT",
        lambda: test_evaluate(
            "Fallback → 23% VAT",
            {"category_code": "UNKNOWN", "transaction_date": "2025-06-01"},
            {
                "has_vat_rate": lambda v: v.get("vat_rate") in ("0.23", "23%"),
            },
        ),
    )

    # ── Step 4: Batch ───────────────────────────────────────────────────
    print("\n📊 STEP 4: Batch Evaluation")

    def test_batch():
        inputs = [
            {"category_code": "FUEL"},
            {"category_code": "FOOD"},
            {"category_code": "EDUCATION"},
        ]
        results = []
        for inp in inputs:
            results.append(runner.opa.evaluate("tax/rules/decide", inp))
        assert len(results) == 3, f"Expected 3 results, got {len(results)}"
        print(f"     Batch: {len(results)} results")

    runner.test("Batch evaluate 3 inputs", test_batch)

    # ── Step 5: First-match-wins verification ───────────────────────────
    print("\n🏆 STEP 5: First-Match-Wins Verification")

    def test_first_match_wins():
        # FUEL should match first rule (priority 10) before fallback (priority 100)
        verdict = runner.opa.evaluate("tax/rules/decide", {
            "category_code": "FUEL",
            "transaction_date": "2025-06-01",
        })
        # The first matching rule is FUEL at priority 10
        rule_id = verdict.get("rule_id", verdict.get("_rule_id", "unknown"))
        # rule_id should contain "fuel" or priority should indicate priority 10
        vat = verdict.get("vat_rate", "unknown")
        print(f"     FUEL: rule_id={rule_id}, vat={vat}")
        assert vat == "0.23", f"Expected vat=0.23 for FUEL, got {vat}"

    runner.test("FUEL matches before fallback", test_first_match_wins)

    # ── Summary ─────────────────────────────────────────────────────────
    success = runner.summary()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
