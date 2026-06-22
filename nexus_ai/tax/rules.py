"""
Tax Rule Engine — OPA + DuckDB + Rust Implementation.

Zgodnie z aa3fvcx.txt — silnik reguł podatkowych oparty na:
  - OPA (Open Policy Agent)   — deklaratywny silnik reguł (CNCF)
  - DuckDB (RuleStore)        — trwały magazyn reguł
  - Nexus-TaxEngine (Rust+PyO3) — natywny orkiestrator

Architektura:
  1. DuckDB: temporalny magazyn reguł z indeksami (valid_from, valid_to)
  2. OPA: ewaluacja reguł first-match-wins przez Rego policies
  3. Rust (nexus_crypto): obliczenia matematyczne, niezmienniki, audyt

Flow:
  DuckDB RuleStore → OpaPolicyGenerator → OPA → Verdict → Rust TaxMathEngine

Komponenty:
  - tax_rules table (DuckDB) — immutable, temporal rule store
  - ContextInterpreter — builds flat context dict from invoice data
  - RuleEngine — first-match-wins evaluation via OPA
  - OpaClient — REST API client for OPA sidecar
  - OpaPolicyGenerator — converts DuckDB rules to Rego policies
  - DEFAULT_TAX_RULES — example rule set for Polish tax law
"""

from __future__ import annotations

import json
import uuid
from decimal import Decimal
from typing import Any

import duckdb
import pendulum

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads
from nexus_ai.core.opa_client import OpaClient, OpaError
from nexus_ai.services.opa_policy_generator import OpaPolicyGenerator

from .exceptions import NoMatchingRuleError


# ── Schemas ──────────────────────────────────────────────────────────────────

TAX_RULES_SCHEMA = """
CREATE TABLE IF NOT EXISTS tax_rules (
    rule_id              VARCHAR PRIMARY KEY,
    condition_sql        VARCHAR NOT NULL,
    action_json          VARCHAR NOT NULL,
    valid_from           DATE NOT NULL,
    valid_to             DATE,
    priority             INTEGER NOT NULL DEFAULT 100,
    description_template VARCHAR,
    rule_set_id          VARCHAR NOT NULL DEFAULT '',
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by           VARCHAR NOT NULL DEFAULT 'system'
);
CREATE INDEX IF NOT EXISTS idx_tax_rules_valid
    ON tax_rules(valid_from, valid_to, priority);
CREATE INDEX IF NOT EXISTS idx_tax_rules_set
    ON tax_rules(rule_set_id);
"""

# ── Default example rules ────────────────────────────────────────────────────

DEFAULT_TAX_RULES: list[dict[str, Any]] = [
    # ◈ Highest priority — specific categories
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_04",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "description_template": "Reguła {rule_id}: kategoria {category_code} (paliwo) – VAT {vat_rate_percent}%, {income_tax_qualification_label}, GTU {gtu_code}",
        "created_by": "system",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_01",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "created_by": "system",
    },
    {
        "condition_sql": "category_code = 'FOOD' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.08",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_07",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "created_by": "system",
    },
    {
        "condition_sql": "category_code = 'BOOKS' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.05",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_01",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "created_by": "system",
    },
    {
        "condition_sql": "category_code IN ('EDUCATION', 'HEALTHCARE') AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.00",
            "rounding_level": "total",
            "income_tax_qualification": "deductible_limit",
            "gtu_code": None,
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "created_by": "system",
    },
    # ◈ Cross-border
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {
            "vat_rate": "0.00",
            "rounding_level": "total",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_12",
            "procedure": "VAT_REVERSE_CHARGE",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 50,
        "created_by": "system",
    },
    {
        "condition_sql": "vendor_country = 'NON_EU'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_13",
            "procedure": "IMPORT",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 50,
        "created_by": "system",
    },
    # ◈ ◈ ◈ FIELD CONFIDENCE RULES (Priority 8) ◈ ◈ ◈
    {
        "condition_sql": "company_tax_form = 'CIT_STANDARD' AND fc_vat_rate < '0.98' AND fc_vat_rate > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "CIT_STANDARD: VAT rate confidence {fc_vat_rate} < 0.98",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "description_template": "BLOKADA: CIT_STANDARD – niska pewność stawki VAT ({fc_vat_rate}).",
        "created_by": "system",
    },
    {
        "condition_sql": "company_tax_form = 'CIT_STANDARD' AND fc_total_net < '0.95' AND fc_total_net > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "CIT_STANDARD: net amount confidence {fc_total_net} < 0.95",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "company_tax_form = 'CIT_ESTONIAN' AND fc_vat_rate < '0.95' AND fc_vat_rate > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "CIT_ESTONIAN: VAT rate confidence {fc_vat_rate} < 0.95",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "company_tax_form = 'LINEAR' AND fc_minimum < '0.85' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "LINEAR: minimum confidence {fc_minimum} < 0.85 across fields",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "company_tax_form = 'LUMP_SUM' AND fc_vat_rate < '0.95' AND fc_vat_rate > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "LUMP_SUM: VAT rate confidence {fc_vat_rate} < 0.95",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "company_tax_form = 'LUMP_SUM' AND fc_total_net < '0.60' AND fc_total_net > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "LUMP_SUM: net amount confidence {fc_total_net} < 0.60",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "category_code = 'MIXED_AUTO' AND fc_minimum < '0.90' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "MIXED_AUTO: minimum confidence {fc_minimum} < 0.90",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "category_code = 'REPRESENTATION' AND fc_minimum < '0.95' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "REPRESENTATION: minimum confidence {fc_minimum} < 0.95",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "fc_vendor_nip < '0.80' AND fc_vendor_nip > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "Unreliable NIP: fc_vendor_nip={fc_vendor_nip}",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "fc_category_code < '0.80' AND fc_category_code > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "Low category confidence: fc_category_code={fc_category_code}",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "fc_minimum < '0.70' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "Multiple low-confidence fields detected (minimum={fc_minimum})",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    {
        "condition_sql": "company_tax_form = 'CIT_STANDARD' AND fc_minimum < '0.85' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "CIT_STANDARD: minimum confidence {fc_minimum} < 0.85 across fields",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ◈ Fallback — domestic
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 100,
        "created_by": "system",
    },
]


def ensure_tax_schemas(conn: duckdb.DuckDBPyConnection) -> None:
    """Create tax_rules table if not present."""
    conn.execute(TAX_RULES_SCHEMA)
    # Add new columns if missing (backward-compatible migration)
    try:
        conn.execute("ALTER TABLE tax_rules ADD COLUMN IF NOT EXISTS description_template VARCHAR")
    except Exception:
        pass


def seed_default_rules(conn: duckdb.DuckDBPyConnection) -> None:
    """Insert default tax rules only if table is empty (idempotent)."""
    count = conn.execute("SELECT COUNT(1) FROM tax_rules").fetchone()[0]
    if count > 0:
        return
    for rule in DEFAULT_TAX_RULES:
        conn.execute(
            """INSERT INTO tax_rules
               (rule_id, condition_sql, action_json, valid_from, valid_to,
                priority, description_template, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                uuid.uuid4().hex,
                rule["condition_sql"],
                msgspec_dumps(rule["action_json"], ensure_ascii=False),
                rule["valid_from"],
                rule["valid_to"],
                rule["priority"],
                rule.get("description_template"),  # may be None
                rule["created_by"],
            ),
        )


# ── Simulation Rule Sets ───────────────────────────────────────────────────

DEFAULT_SIMULATION_RULES: list[dict[str, Any]] = [
    # ── CIT_STANDARD ───────────────────────────────────────────────────
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_04",
            "simulated_income_tax_rate": "0.09",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "CIT_STANDARD",
        "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_01",
            "simulated_income_tax_rate": "0.09",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "CIT_STANDARD",
        "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'FOOD' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.08",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_07",
            "simulated_income_tax_rate": "0.09",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "CIT_STANDARD",
        "created_by": "simulation",
    },
    {
        "condition_sql": "category_code IN ('EDUCATION', 'HEALTHCARE') AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.00",
            "rounding_level": "total",
            "income_tax_qualification": "deductible_limit",
            "gtu_code": None,
            "simulated_income_tax_rate": "0.09",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "CIT_STANDARD",
        "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "simulated_income_tax_rate": "0.09",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 100,
        "rule_set_id": "CIT_STANDARD",
        "created_by": "simulation",
    },
    # ── CIT_ESTONIAN ──────────────────────────────────────────────────
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_04",
            "simulated_income_tax_rate": "0.10",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "CIT_ESTONIAN",
        "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_01",
            "simulated_income_tax_rate": "0.10",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "CIT_ESTONIAN",
        "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "simulated_income_tax_rate": "0.10",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 100,
        "rule_set_id": "CIT_ESTONIAN",
        "created_by": "simulation",
    },
    # ── LINEAR ──────────────────────────────────────────────────
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_04",
            "simulated_income_tax_rate": "0.19",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "LINEAR",
        "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_01",
            "simulated_income_tax_rate": "0.19",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "LINEAR",
        "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "simulated_income_tax_rate": "0.19",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 100,
        "rule_set_id": "LINEAR",
        "created_by": "simulation",
    },
    # ── LUMP_SUM ────────────────────────────────────────
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "non_deductible",
            "gtu_code": "GTU_04",
            "simulated_income_tax_rate": "0.12",
            "simulated_lump_sum_revenue_basis": True,
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "LUMP_SUM",
        "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "non_deductible",
            "gtu_code": "GTU_01",
            "simulated_income_tax_rate": "0.12",
            "simulated_lump_sum_revenue_basis": True,
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "rule_set_id": "LUMP_SUM",
        "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "non_deductible",
            "gtu_code": None,
            "simulated_income_tax_rate": "0.12",
            "simulated_lump_sum_revenue_basis": True,
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 100,
        "rule_set_id": "LUMP_SUM",
        "created_by": "simulation",
    },
    # ── Cross-border dla wszystkich zestawów ────────────────────────────
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {
            "vat_rate": "0.00",
            "rounding_level": "total",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_12",
            "procedure": "VAT_REVERSE_CHARGE",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 50,
        "rule_set_id": "CIT_STANDARD",
        "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {
            "vat_rate": "0.00",
            "rounding_level": "total",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_12",
            "procedure": "VAT_REVERSE_CHARGE",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 50,
        "rule_set_id": "CIT_ESTONIAN",
        "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {
            "vat_rate": "0.00",
            "rounding_level": "total",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_12",
            "procedure": "VAT_REVERSE_CHARGE",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 50,
        "rule_set_id": "LINEAR",
        "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {
            "vat_rate": "0.00",
            "rounding_level": "total",
            "income_tax_qualification": "non_deductible",
            "gtu_code": "GTU_12",
            "procedure": "VAT_REVERSE_CHARGE",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 50,
        "rule_set_id": "LUMP_SUM",
        "created_by": "simulation",
    },
]


def seed_simulation_rules(conn: duckdb.DuckDBPyConnection) -> None:
    """Wstaw zestawy regu³ symulacyjnych (idempotentne — usuwa TYLKO swoje zestawy)."""
    from nexus_ai.services.rule_store import RuleStore

    store = RuleStore(conn)
    store.ensure_schema()

    # Usuñ TYLKO regu³y nale¿¹ce do zestawów, które zamierzamy reseedowaæ
    known_sets = set(r["rule_set_id"] for r in DEFAULT_SIMULATION_RULES)
    for rsid in known_sets:
        store.delete_rule_set(rsid)

    for rule in DEFAULT_SIMULATION_RULES:
        store.add_rule(
            condition_sql=rule["condition_sql"],
            action=rule["action_json"],
            valid_from=rule["valid_from"],
            valid_to=rule.get("valid_to"),
            priority=rule["priority"],
            rule_set_id=rule["rule_set_id"],
            created_by=rule["created_by"],
        )


def seed_single_rule_set(conn: duckdb.DuckDBPyConnection, target_rule_set_id: str) -> int:
    """Wstaw reguły tylko dla JEDNEGO docelowego zestawu symulacyjnego.

    Args:
        conn: Połączenie DuckDB.
        target_rule_set_id: Docelowy zestaw (np. \"CIT_ESTONIAN\").

    Returns:
        Liczba wstawionych reguł.

    Raises:
        ValueError: Jeśli target_rule_set_id nie istnieje w DEFAULT_SIMULATION_RULES.
    """
    from nexus_ai.services.rule_store import RuleStore

    store = RuleStore(conn)
    store.ensure_schema()

    store.delete_rule_set(target_rule_set_id)

    target_rules = [
        r for r in DEFAULT_SIMULATION_RULES if r.get("rule_set_id") == target_rule_set_id
    ]
    if not target_rules:
        raise ValueError(f"Unknown simulation rule set: {target_rule_set_id}")

    for rule in target_rules:
        store.add_rule(
            condition_sql=rule["condition_sql"],
            action=rule["action_json"],
            valid_from=rule["valid_from"],
            valid_to=rule.get("valid_to"),
            priority=rule["priority"],
            rule_set_id=rule["rule_set_id"],
            created_by=rule["created_by"],
        )

    return len(target_rules)


def get_simulation_rule_sets() -> list[str]:
    """Zwró listê dostêpnych zestawów regu³ symulacyjnych."""
    return sorted(set(r["rule_set_id"] for r in DEFAULT_SIMULATION_RULES if r.get("rule_set_id")))


# ── Context Interpreter ──────────────────────────────────────────────────────


class ContextInterpreter:
    """Builds a flat context dict from raw normalized invoice data.

    The context is used by RuleEngine to evaluate condition_sql expressions.
    All values are stored as strings for SQL compatibility with DuckDB.
    """

    @staticmethod
    def build(invoice_data: dict[str, Any]) -> dict[str, Any]:
        """Transform raw invoice data into a rule evaluation context.

        Args:
            invoice_data: Normalized dictionary from OCR pipeline with keys:
                - category_code: str
                - transaction_date: str (YYYY-MM-DD) or pendulum.Date
                - company_tax_form: str
                - vendor_country: str (PL/EU/NON_EU)
                - vendor_vat_status: str (active/inactive/unknown)
                - vendor_pkd: str (optional)
                - amount_net: Decimal | str | float (optional)

        Returns:
            Flat dict with all values as strings.
        """
        ctx: dict[str, Any] = {}

        ctx["category_code"] = str(invoice_data.get("category_code", "UNKNOWN"))

        raw_date = invoice_data.get("transaction_date", "")
        if isinstance(raw_date, (pendulum.Date, pendulum.DateTime)):
            ctx["transaction_date"] = raw_date.isoformat()
        else:
            ctx["transaction_date"] = str(raw_date)

        ctx["company_tax_form"] = str(invoice_data.get("company_tax_form", "CIT_STANDARD"))
        ctx["vendor_country"] = str(invoice_data.get("vendor_country", "PL"))
        ctx["vendor_vat_status"] = str(invoice_data.get("vendor_vat_status", "unknown"))
        ctx["vendor_pkd"] = str(invoice_data.get("vendor_pkd", ""))

        raw_net = invoice_data.get("amount_net", "0")
        if isinstance(raw_net, Decimal):
            ctx["amount_net"] = str(raw_net)
        elif isinstance(raw_net, (int, float)):
            ctx["amount_net"] = str(Decimal(str(raw_net)))
        else:
            ctx["amount_net"] = str(raw_net)

        return ctx


# ── Rule Engine ──────────────────────────────────────────────────────────────


class RuleEngine:
    """Deterministic, temporal, auditable rule engine powered by DuckDB + OPA.

    Zgodnie z aa3fvcx.txt:
      - OPA (Open Policy Agent) jako deklaratywny silnik reguł
      - DuckDB (RuleStore) jako trwały magazyn reguł
      - Nexus-TaxEngine (Rust+PyO3) jako natywny orkiestrator

    Dwie ścieżki ewaluacji:
      **decide()** (synchroniczna) — DuckDB-only, zawsze dostępna, używana
         przez testy i istniejący kod synchroniczny.
      **decide_async()** (asynchroniczna) — próbuje OPA first, z DuckDB
         fallback. Używana przez TaxPipeline i kod asynchroniczny.

    RuleEngine zarządza cyklem życia reguł (load, eval)
    w DuckDB i opcjonalnie w OPA.
    """

    def __init__(
        self,
        conn: duckdb.DuckDBPyConnection,
        opa_client: OpaClient | None = None,
        *,
        auto_sync_policy: bool = False,
    ) -> None:
        self._conn = conn
        self._opa = opa_client or OpaClient()
        self._auto_sync = auto_sync_policy
        self._policy_generator = OpaPolicyGenerator()

        # Use RuleStore for full schema with all indexes
        from nexus_ai.services.rule_store import RuleStore

        store = RuleStore(conn)
        store.ensure_schema()

        # Auto-sync policy on first use
        self._policy_loaded = False

    # ── Asynchroniczna synchronizacja OPA ──────────────────────────────

    async def _ensure_policy(self) -> None:
        """Ensure OPA has the latest policy and data loaded.

        Generates Rego policy from DuckDB rules and loads
        both the policy code and data into OPA.
        """
        if not self._auto_sync:
            return

        try:
            # Load all active rules from DuckDB
            all_rows = self._conn.execute(
                "SELECT rule_id, condition_sql, action_json, priority, "
                "valid_from, valid_to, rule_set_id "
                "FROM tax_rules "
                "ORDER BY priority ASC, valid_from DESC, rule_id ASC"
            ).fetchall()

            rules: list[dict[str, Any]] = []
            for r in all_rows:
                rule: dict[str, Any] = {
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
                rules.append(rule)

            if not rules:
                logger.warning("[RULE-ENGINE] No rules in DuckDB — OPA will have empty policy")
                return

            # Generate Rego policy and data
            rego_code = self._policy_generator.generate_policy(rules)
            data = self._policy_generator.generate_data(rules)

            # Load into OPA
            await self._opa.load_policy("tax/rules.rego", rego_code)
            await self._opa.load_data("tax/rules", data)

            self._policy_loaded = True
            logger.info(
                "[RULE-ENGINE] OPA policy synced: %d rules, %d bytes policy",
                len(rules),
                len(rego_code),
            )
        except OpaError as exc:
            logger.warning(
                "[RULE-ENGINE] OPA sync failed: %s — falling back to DuckDB-only mode",
                exc,
            )
            self._policy_loaded = False
        except Exception as exc:
            logger.error("[RULE-ENGINE] Policy sync error: %s", exc)
            self._policy_loaded = False

    # ── Synchroniczna ścieżka: DuckDB-only (backward compat) ───────────

    def decide(
        self,
        context: dict[str, Any],
        *,
        include_decision_trace: bool = False,
    ) -> dict[str, Any]:
        """Evaluate context against DuckDB rules — synchroniczna, zawsze dostępna.

        Używa DuckDB temporal query + warunki SQL do first-match-wins.
        Jest to synchroniczna wersja dla backward compatibility z istniejącymi
        testami i kodem, który nie używa async.

        Args:
            context: Flat dict from ContextInterpreter.build().
            include_decision_trace: If True, generates a human-readable
                ``decision_trace`` string in the verdict (via TraceGenerator).

        Returns:
            The action_json of the first matching rule, enriched with
            ``_rule_id``, ``_priority``.

        Raises:
            NoMatchingRuleError: If no rule matches.
        """
        txn_date = context.get("transaction_date", pendulum.now().date().isoformat())
        txn_date_str = str(txn_date) if not isinstance(txn_date, str) else txn_date
        return self._decide_fallback(context, txn_date_str, include_decision_trace)

    # ── Asynchroniczna ścieżka: OPA → DuckDB fallback ───────────────────

    async def decide_async(
        self,
        context: dict[str, Any],
        *,
        include_decision_trace: bool = False,
    ) -> dict[str, Any]:
        """Evaluate context against OPA rules, with DuckDB fallback.

        Flow:
          1. OPA policy sync (jeśli potrzebny)
          2. OPA REST API → first-match-wins evaluation
          3. DuckDB fallback jeśli OPA niedostępne
          4. Opcjonalnie decision_trace

        Args:
            context: Flat dict from ContextInterpreter.build().
            include_decision_trace: If True, generates a human-readable
                ``decision_trace`` string.

        Returns:
            Enriched verdict dict.

        Raises:
            NoMatchingRuleError: If no rule matches and OPA unavailable.
        """
        # 1. Ensure OPA has the latest policy loaded
        if not self._policy_loaded and self._auto_sync:
            await self._ensure_policy()

        txn_date = context.get("transaction_date", pendulum.now().date().isoformat())
        txn_date_str = str(txn_date) if not isinstance(txn_date, str) else txn_date

        # 2. Try OPA evaluation first
        opa_result: dict[str, Any] | None = None
        try:
            opa_result = await self._opa.evaluate(
                path="tax/rules/decide",
                input_data=context,
            )
        except OpaError as exc:
            logger.warning(
                "[RULE-ENGINE] OPA evaluation failed: %s — falling back to DuckDB",
                exc,
            )

        # 3. If OPA returned a match, use it
        if opa_result and (opa_result.get("matched", False) or "rule_id" in opa_result):
            verdict = dict(opa_result)

            if include_decision_trace:
                rule_id = verdict.get("rule_id", "")
                if rule_id:
                    rule_rows = self._conn.execute(
                        "SELECT rule_id, condition_sql, action_json, description_template "
                        "FROM tax_rules WHERE rule_id = ?",
                        (rule_id,),
                    ).fetchall()
                    if rule_rows:
                        r = rule_rows[0]
                        rule_info = {
                            "rule_id": str(r[0]),
                            "condition_sql": str(r[1]),
                            "description_template": str(r[3]) if r[3] else None,
                        }
                        from nexus_ai.services.trace_generator import TraceGenerator

                        verdict["decision_trace"] = TraceGenerator.generate(
                            rule=rule_info,
                            context=context,
                            verdict=verdict,
                        )

            return verdict

        # 4. Fallback: evaluate directly from DuckDB (OPA unavailable)
        return self._decide_fallback(context, txn_date_str, include_decision_trace)

    def _decide_fallback(
        self,
        context: dict[str, Any],
        txn_date_str: str,
        include_decision_trace: bool = False,
    ) -> dict[str, Any]:
        """Fallback decision path — evaluates rules directly from DuckDB.

        Used when OPA is unavailable. Loads rules from DuckDB,
        converts conditions to Python expressions, and evaluates
        them against the context.

        Args:
            context: Flat dict from ContextInterpreter.build().
            txn_date_str: Transaction date string.
            include_decision_trace: If True, generates decision_trace.

        Returns:
            Enriched verdict dict.

        Raises:
            NoMatchingRuleError: If no rule matches.
        """
        all_rows = self._conn.execute(
            "SELECT rule_id, condition_sql, action_json, priority, "
            "valid_from, valid_to FROM tax_rules "
            "WHERE CAST(? AS DATE) BETWEEN valid_from "
            "AND COALESCE(valid_to, '9999-12-31') "
            "ORDER BY priority ASC, valid_from DESC, rule_id ASC",
            (txn_date_str,),
        ).fetchall()

        if not all_rows:
            raise NoMatchingRuleError(
                f"No active tax rules found for date {txn_date_str}"
            )

        # Evaluate each rule's condition against context
        for r in all_rows:
            rule_id = str(r[0])
            condition_sql = str(r[1])
            action_json = str(r[2])
            priority = int(r[3])

            # Simple condition evaluation (string-based)
            if self._evaluate_condition_simple(condition_sql, context):
                try:
                    action = json.loads(action_json)
                except (json.JSONDecodeError, TypeError):
                    action = {"vat_rate": "0.23", "rounding_level": "position"}

                verdict = dict(action)
                verdict["_rule_id"] = rule_id
                verdict["_priority"] = priority
                verdict["matched"] = True

                if include_decision_trace:
                    rule_rows = self._conn.execute(
                        "SELECT rule_id, condition_sql, action_json, description_template "
                        "FROM tax_rules WHERE rule_id = ?",
                        (rule_id,),
                    ).fetchall()
                    if rule_rows:
                        rule_info = {
                            "rule_id": str(rule_rows[0][0]),
                            "condition_sql": str(rule_rows[0][1]),
                            "description_template": str(rule_rows[0][3]) if rule_rows[0][3] else None,
                        }
                        from nexus_ai.services.trace_generator import TraceGenerator

                        verdict["decision_trace"] = TraceGenerator.generate(
                            rule=rule_info,
                            context=context,
                            verdict=verdict,
                        )

                return verdict

        raise NoMatchingRuleError(
            f"No matching rule for context: {msgspec_dumps(context, ensure_ascii=False)}"
        )

    @staticmethod
    def _evaluate_condition_simple(
        condition_sql: str,
        context: dict[str, Any],
    ) -> bool:
        """Evaluate a simple SQL condition against a context dict.

        Supports: =, !=, IN (string values), AND.
        Used as fallback when OPA is unavailable.

        Args:
            condition_sql: SQL condition string.
            context: Flat context dict.

        Returns:
            True if condition matches.
        """
        import re as _re

        # Normalize the condition
        condition = condition_sql.strip()

        # Handle empty/true conditions
        if not condition or condition.lower() == "true" or condition == "1=1":
            return True

        # Handle AND conditions (split and evaluate all)
        if " AND " in condition.upper():
            parts = _re.split(r'\s+AND\s+', condition, flags=_re.IGNORECASE)
            return all(
                RuleEngine._evaluate_condition_simple(p.strip(), context)
                for p in parts
            )

        # Handle OR conditions
        if " OR " in condition.upper():
            parts = _re.split(r'\s+OR\s+', condition, flags=_re.IGNORECASE)
            return any(
                RuleEngine._evaluate_condition_simple(p.strip(), context)
                for p in parts
            )

        # Handle IN clause: field IN ('val1', 'val2')
        in_match = _re.match(r"(\w+)\s+IN\s*\(([^)]+)\)", condition, _re.IGNORECASE)
        if in_match:
            field = in_match.group(1)
            values_str = in_match.group(2)
            values = [v.strip().strip("'\"") for v in values_str.split(",")]
            actual = str(context.get(field, ""))
            return actual in values

        # Handle NOT IN clause
        not_in_match = _re.match(r"(\w+)\s+NOT\s+IN\s*\(([^)]+)\)", condition, _re.IGNORECASE)
        if not_in_match:
            field = not_in_match.group(1)
            values_str = not_in_match.group(2)
            values = [v.strip().strip("'\"") for v in values_str.split(",")]
            actual = str(context.get(field, ""))
            return actual not in values

        # Handle < condition: field < 'value'
        lt_match = _re.match(r"(\w+)\s*<\s*'([^']*)'", condition)
        if lt_match:
            field = lt_match.group(1)
            value = lt_match.group(2)
            actual = str(context.get(field, ""))
            try:
                return float(actual) < float(value)
            except (ValueError, TypeError):
                return actual < value

        # Handle > condition
        gt_match = _re.match(r"(\w+)\s*>\s*'([^']*)'", condition)
        if gt_match:
            field = gt_match.group(1)
            value = gt_match.group(2)
            actual = str(context.get(field, ""))
            try:
                return float(actual) > float(value)
            except (ValueError, TypeError):
                return actual > value

        # Handle <= condition
        le_match = _re.match(r"(\w+)\s*<=\s*'([^']*)'", condition)
        if le_match:
            field = le_match.group(1)
            value = le_match.group(2)
            actual = str(context.get(field, ""))
            try:
                return float(actual) <= float(value)
            except (ValueError, TypeError):
                return actual <= value

        # Handle >= condition
        ge_match = _re.match(r"(\w+)\s*>=\s*'([^']*)'", condition)
        if ge_match:
            field = ge_match.group(1)
            value = ge_match.group(2)
            actual = str(context.get(field, ""))
            try:
                return float(actual) >= float(value)
            except (ValueError, TypeError):
                return actual >= value

        # Handle != condition
        ne_match = _re.match(r"(\w+)\s*!=\s*'([^']*)'", condition)
        if ne_match:
            field = ne_match.group(1)
            value = ne_match.group(2)
            actual = str(context.get(field, ""))
            return actual != value

        # Handle = condition (default)
        eq_match = _re.match(r"(\w+)\s*=\s*'([^']*)'", condition)
        if eq_match:
            field = eq_match.group(1)
            value = eq_match.group(2)
            actual = str(context.get(field, ""))
            return actual == value

        # Unrecognized condition — log and return False
        import logging as _logging
        _logging.getLogger("nexus.tax.rules").warning(
            "[RULE-ENGINE] Unknown condition format: %s", condition
        )
        return False

    # ── Policy sync ─────────────────────────────────────────────────────

    async def sync_policy(self) -> bool:
        """Force re-sync OPA policy from DuckDB rules.

        Returns:
            True if sync was successful.
        """
        self._policy_loaded = False
        await self._ensure_policy()
        return self._policy_loaded

    @property
    def opa_client(self) -> OpaClient:
        """Access to OPA client for direct OPA operations."""
        return self._opa

    # ── Rule lifecycle (immutable: append-only + close) ─────────────────

    def add_rule(
        self,
        condition_sql: str,
        action: dict[str, Any],
        valid_from: str | pendulum.Date = "2024-01-01",
        valid_to: str | pendulum.Date | None = None,
        priority: int = 100,
        created_by: str = "system",
    ) -> str:
        """Insert a new rule. Rules are never updated — only appended.

        Args:
            condition_sql: SQL WHERE expression (e.g. ``category_code = 'FUEL'``).
            action: Verdict dict (e.g. ``{\"vat_rate\": \"0.23\", ...}``).
            valid_from: Start date (ISO string or pendulum.Date).
            valid_to: End date (or None for indefinitely active).
            priority: Lower = higher priority.
            created_by: Actor identifier for audit.

        Returns:
            The UUID of the newly created rule.
        """
        rule_id = uuid.uuid4().hex
        vf = (
            valid_from.isoformat()
            if isinstance(valid_from, (pendulum.Date, pendulum.DateTime))
            else valid_from
        )
        vt = (
            valid_to.isoformat()
            if isinstance(valid_to, (pendulum.Date, pendulum.DateTime))
            else valid_to
        )

        self._conn.execute(
            """INSERT INTO tax_rules
               (rule_id, condition_sql, action_json, valid_from, valid_to,
                priority, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                rule_id,
                condition_sql,
                msgspec_dumps(action, ensure_ascii=False),
                vf,
                vt,
                priority,
                created_by,
            ),
        )
        return rule_id

    def close_rule(self, rule_id: str, valid_to: str | pendulum.Date) -> None:
        """Close a rule's validity window (sets valid_to).

        This is the only mutation allowed on existing rules,
        and only forward in time (valid_to must be > current valid_from).
        """
        vt = (
            valid_to.isoformat()
            if isinstance(valid_to, (pendulum.Date, pendulum.DateTime))
            else valid_to
        )
        self._conn.execute(
            "UPDATE tax_rules SET valid_to = ? WHERE rule_id = ?",
            (vt, rule_id),
        )
