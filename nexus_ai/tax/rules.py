"""
Tax Rule Engine — Zen-Engine Implementation.

Zintegrowany z DecisionEngine (DuckDB/SQL) — temporalne reguły
podatkowe first-match-wins z parametrizzowanym SQL.

Komponenty:
  - tax_rules table (DuckDB) — immutable, temporal rule store
  - ContextInterpreter — builds flat context dict from invoice data
  - RuleEngine — first-match-wins evaluation (Rust PriorityEngine)
  - DEFAULT_TAX_RULES — example rule set for Polish tax law

Rule evaluation (decide) uses Rust PriorityEngine via nexus_crypto:
  - SQL condition evaluation in Rust (no DuckDB temp table)
  - First-match-wins with deterministic sorting
  - Returns enriched verdict with _rule_id, _priority, _evaluated_rules

DuckDB I/O remains in Python for:
  - Temporal rule loading (valid_from/valid_to filtering)
  - Rule lifecycle (add_rule, close_rule)
"""

from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Any

import duckdb
import pendulum

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

from .exceptions import NoMatchingRuleError

# ── Rust-native PriorityEngine ───────────────────────────────────────────────

try:
    from nexus_crypto import (
        PriorityEngine as _RustPriorityEngine,
        TemporalManager as _RustTemporalManager,
    )

    _HAS_RUST_PRIORITY = True
except ImportError:
    _HAS_RUST_PRIORITY = False

    # Fallback stub — PriorityEngine
    class _RustPriorityEngine:  # type: ignore[no-redef]
        @staticmethod
        def resolve(rules_json: str, context_json: str) -> str:  # type: ignore[misc]
            raise ImportError(
                "nexus_crypto native module not available — "
                "build with: cd nexus_ai/rust && maturin develop"
            )

        @staticmethod
        def sort_rules(rules_json: str) -> str:  # type: ignore[misc]
            raise ImportError("nexus_crypto native module not available")

        @staticmethod
        def validate_priorities(rules_json: str) -> str:  # type: ignore[misc]
            raise ImportError("nexus_crypto native module not available")

    # Fallback stub — TemporalManager
    class _RustTemporalManager:  # type: ignore[no-redef]
        @staticmethod
        def filter_rules(rules_json: str, date_str: str) -> str:  # type: ignore[misc]
            raise ImportError(
                "nexus_crypto native module not available — "
                "build with: cd nexus_ai/rust && maturin develop"
            )

        @staticmethod
        def sort_by_temporal(rules_json: str) -> str:  # type: ignore[misc]
            raise ImportError("nexus_crypto native module not available")

        @staticmethod
        def validate_overlap(rules_json: str) -> str:  # type: ignore[misc]
            raise ImportError("nexus_crypto native module not available")


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
    """Deterministic, temporal, auditable rule engine.

    Uses Rust PriorityEngine for first-match-wins evaluation
    with the SQL Condition Evaluator (no DuckDB temp table).

    Rules are loaded from DuckDB with temporal filtering (via TemporalManager).

    Safety:
      - Context values are always strings (serialized to JSON for Rust).
      - No dynamic SQL execution — condition evaluation is done in Rust.
      - First-match-wins with deterministic sorting by (priority, rule_id).
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        # Use RuleStore for full schema with all indexes
        from nexus_ai.services.rule_store import RuleStore

        store = RuleStore(conn)
        store.ensure_schema()

    def decide(
        self,
        context: dict[str, Any],
        *,
        include_decision_trace: bool = False,
    ) -> dict[str, Any]:
        """Evaluate context against rules and return the first matching verdict.

        Uses TemporalManager for temporal filtering and Rust PriorityEngine
        for deterministic first-match-wins evaluation.

        The returned verdict dict includes:
          - ``_rule_id``: UUID of the winning rule
          - ``_priority``: Priority of the winning rule
          - ``_evaluated_rules``: List of all evaluated rules with
            ``rule_id``, ``condition_sql``, ``result`` (bool), and
            ``selected`` (True for the winning rule).
          - ``decision_trace``: (optional) Human-readable decision trace,
            only included when ``include_decision_trace=True``.

        Args:
            context: Flat dict from ContextInterpreter.build().
            include_decision_trace: If True, generates a human-readable
                ``decision_trace`` string in the verdict (via TraceGenerator).
                Default ``False`` to avoid overhead when only raw data is needed.

        Returns:
            The action_json of the first matching rule, enriched with
            ``_rule_id``, ``_priority``, and ``_evaluated_rules``.

        Raises:
            NoMatchingRuleError: If no rule matches the context.
        """
        # 1. Load ALL rules from DuckDB (no temporal filtering — Rust handles it)
        txn_date = context.get("transaction_date", pendulum.now().date().isoformat())

        all_rows = self._conn.execute(
            "SELECT rule_id, condition_sql, action_json, priority, "
            "valid_from, valid_to FROM tax_rules"
        ).fetchall()

        if not all_rows:
            raise NoMatchingRuleError("No tax rules found in database")

        # 2. Serialize all rules to JSON (include temporal fields for Rust TemporalManager)
        all_rules: list[dict[str, Any]] = []
        for r in all_rows:
            rule: dict[str, Any] = {
                "rule_id": str(r[0]),
                "condition_sql": str(r[1]),
                "action_json": str(r[2]),  # already JSON string from DuckDB
                "priority": int(r[3]),
                "valid_from": str(r[4]),
            }
            if r[5] is not None:
                rule["valid_to"] = str(r[5])
            all_rules.append(rule)

        all_rules_json = msgspec_dumps(all_rules, ensure_ascii=False, default=str)

        # 3. Filter temporally using Rust TemporalManager.filter_rules()
        #    (date filtering + temporal sorting — no DuckDB temporal WHERE)
        filtered_rules_json = _RustTemporalManager.filter_rules(all_rules_json, txn_date)
        filtered_rules = msgspec_loads(filtered_rules_json)

        if not filtered_rules:
            raise NoMatchingRuleError(f"No active tax rules found for date {txn_date}")

        # 4. Evaluate rules with Rust PriorityEngine.resolve()
        context_json = msgspec_dumps(context, ensure_ascii=False, default=str)
        rules_json = msgspec_dumps(filtered_rules, ensure_ascii=False, default=str)
        result_str = _RustPriorityEngine.resolve(rules_json, context_json)
        result = msgspec_loads(result_str)

        if not result.get("matched", False):
            raise NoMatchingRuleError(
                f"No matching rule for context: {msgspec_dumps(context, ensure_ascii=False)}"
            )

        # 5. Extract verdict and metadata
        verdict: dict[str, Any] = result.get("verdict", {})

        # Parse evaluated_rules_json into list
        evaluated_rules_str = result.get("evaluated_rules_json", "[]")
        evaluated_rules: list[dict[str, Any]] = []
        if evaluated_rules_str:
            try:
                parsed = msgspec_loads(evaluated_rules_str)
                if isinstance(parsed, list):
                    evaluated_rules = parsed
            except (ValueError, TypeError):
                pass

        # Attach evaluated rules to verdict
        verdict["_evaluated_rules"] = evaluated_rules

        # Optionally generate human-readable decision_trace
        if include_decision_trace:
            rule_id = verdict.get("_rule_id", "")
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

    # ── Access to formal components ────────────────────────────────────

    @property
    def temporal_manager(self):
        """Access the Rust TemporalManager for temporal filtering."""
        return _RustTemporalManager

    @property
    def priority_engine(self):
        """Access the Rust PriorityEngine."""
        return _RustPriorityEngine

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
